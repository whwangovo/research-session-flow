#!/bin/bash
# docs-hook.sh — ARIS + 代码变更 → /docs 提醒
# 用法：
#   --record  : PostToolUse 调用，静默记录匹配的文件路径
#   --remind  : Stop 调用，输出汇总提醒并清空状态

set -euo pipefail

MODE="${1:-}"
STATE_FILE="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/docs-hook-state.json"
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"

# ── 工具函数 ──────────────────────────────────────────────

# 将绝对路径转为相对于 CLAUDE_PROJECT_DIR 的相对路径
to_relative() {
  local abs="$1"
  local base="${CLAUDE_PROJECT_DIR:-$PWD}"
  # 如果路径以 base 开头，截取相对部分
  if [[ "$abs" == "$base/"* ]]; then
    echo "${abs#$base/}"
  else
    echo "$abs"
  fi
}

# 匹配文件路径，返回 category（可多个，空格分隔）；无匹配返回空
classify_file() {
  local rel="$1"
  local categories=""

  # 排除 docs/ 开头的路径
  if [[ "$rel" == docs/* ]]; then
    echo ""
    return
  fi

  # ── 第一类：ARIS 产出 → aris ──
  local aris_patterns=(
    "IDEA_REPORT.md"
    "IDEA_CANDIDATES.md"
    "NARRATIVE_REPORT.md"
    "STORY.md"
    "PAPER_PLAN.md"
    "AUTO_REVIEW.md"
    "REVIEW_SUMMARY.md"
    "PAPER_IMPROVEMENT_LOG.md"
    "refine-logs/FINAL_PROPOSAL.md"
    "refine-logs/REFINEMENT_REPORT.md"
  )
  for pat in "${aris_patterns[@]}"; do
    if [[ "$rel" == "$pat" ]]; then
      categories="$categories aris"
      break
    fi
  done

  # EXPERIMENT_*.md（项目根或 refine-logs/）
  if [[ "$rel" =~ ^(refine-logs/)?EXPERIMENT_[A-Z_]+\.md$ ]]; then
    categories="$categories aris"
  fi

  # paper/sections/*.tex
  if [[ "$rel" =~ ^paper/sections/[^/]+\.tex$ ]]; then
    categories="$categories aris paper"
  fi

  # CLAIMS_FROM_RESULTS.md, findings.md → aris + results
  if [[ "$rel" == "CLAIMS_FROM_RESULTS.md" || "$rel" == "findings.md" ]]; then
    categories="$categories aris results"
  fi

  # ── 第二类：方法代码 → methods ──
  if [[ "$rel" =~ ^src/.*model.*\.py$ || "$rel" =~ ^src/.*pipeline.*\.py$ ]]; then
    categories="$categories methods"
  fi

  # ── 第三类：实验结果 → results ──
  if [[ "$rel" =~ ^results/.*\.(json|csv)$ || "$rel" =~ ^outputs/ || "$rel" =~ ^evaluation/ ]]; then
    categories="$categories results"
  fi

  # ── 第四类：项目配置 → project ──
  if [[ "$rel" == "CLAUDE.md" || "$rel" == "pyproject.toml" || "$rel" == "setup.py" || "$rel" == "package.json" ]]; then
    categories="$categories project"
  fi

  # ── 第五类：论文图表 → paper ──
  if [[ "$rel" =~ ^figures/.*\.(tex|py)$ ]]; then
    categories="$categories paper"
  fi

  # 去重并输出
  echo "$categories" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs
}

# ── --record 模式 ─────────────────────────────────────────

if [[ "$MODE" == "--record" ]]; then
  # 读取 PostToolUse JSON
  input=$(cat)

  # 提取 file_path（Write/Edit 工具）
  file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
  [[ -z "$file_path" ]] && exit 0

  rel=$(to_relative "$file_path")
  categories=$(classify_file "$rel")
  [[ -z "$categories" ]] && exit 0

  # 初始化或重置状态文件
  if [[ -f "$STATE_FILE" ]]; then
    existing_session=$(jq -r '.session_id // empty' "$STATE_FILE" 2>/dev/null || true)
    if [[ "$existing_session" != "$SESSION_ID" ]]; then
      # 不同 session，重置
      echo '{"session_id":"'"$SESSION_ID"'","files":[]}' > "$STATE_FILE"
    fi
  else
    mkdir -p "$(dirname "$STATE_FILE")"
    echo '{"session_id":"'"$SESSION_ID"'","files":[]}' > "$STATE_FILE"
  fi

  # 追加每个 category
  for cat in $categories; do
    STATE_FILE="$STATE_FILE" jq \
      --arg path "$rel" \
      --arg cat "$cat" \
      '.files += [{"path": $path, "category": $cat}]' \
      "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  done

  exit 0
fi

# ── --remind 模式 ─────────────────────────────────────────

if [[ "$MODE" == "--remind" ]]; then
  [[ ! -f "$STATE_FILE" ]] && exit 0

  files_count=$(jq '.files | length' "$STATE_FILE" 2>/dev/null || echo 0)
  [[ "$files_count" -eq 0 ]] && { rm -f "$STATE_FILE"; exit 0; }

  # 检查 docs/ 是否存在
  docs_exists=false
  [[ -d "${CLAUDE_PROJECT_DIR:-$PWD}/docs" ]] && docs_exists=true

  # 用 jq 生成每个 category 的提醒行（category:cmd:files 格式）
  reminder=$(jq -r '
    .files
    | group_by(.category)
    | map(
        . as $group |
        ($group[0].category) as $cat |
        ($group | map(.path) | unique | join(", ")) as $files |
        (if $cat == "aris"     then "/docs aris"
         elif $cat == "methods" then "/docs update methods"
         elif $cat == "results" then "/docs update results"
         elif $cat == "project" then "/docs update project"
         elif $cat == "paper"   then "/docs update"
         else "/docs status" end) as $cmd |
        "\($cat):\($cmd):\($files)"
      )
    | .[]
  ' "$STATE_FILE" 2>/dev/null || true)

  [[ -z "$reminder" ]] && { rm -f "$STATE_FILE"; exit 0; }

  line_count=$(echo "$reminder" | wc -l | tr -d ' ')

  if [[ "$line_count" -eq 1 ]]; then
    cat=$(echo "$reminder" | cut -d: -f1)
    cmd=$(echo "$reminder" | cut -d: -f2)
    files=$(echo "$reminder" | cut -d: -f3-)
    if [[ "$cat" == "aris" && "$docs_exists" == "false" ]]; then
      echo "[docs] 检测到 ARIS 产出 ($files) 但 docs/ 不存在，建议先运行 /docs init"
    else
      echo "[docs] 检测到变更 ($files) → $cmd"
    fi
  else
    echo "[docs] 检测到文档相关变更："
    while IFS= read -r line; do
      cmd=$(echo "$line" | cut -d: -f2)
      files=$(echo "$line" | cut -d: -f3-)
      echo "  · $files → $cmd"
    done <<< "$reminder"
  fi

  rm -f "$STATE_FILE"
  exit 0
fi

echo "用法: docs-hook.sh --record | --remind" >&2
exit 1
