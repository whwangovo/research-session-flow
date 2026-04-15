#!/bin/bash
# install.sh — research-docs-skill 安装脚本
# 安装 skill + docs-hook（ARIS/代码变更后提醒运行 /docs 子命令）
#
# 用法：
#   ./install.sh                安装（已存在则跳过 skill 覆盖）
#   ./install.sh --update       git pull --ff-only 拉取最新并覆盖 skill / hook；
#                               工作区有未提交修改时会中止
#   ./install.sh --force        强制同步到远程（git fetch + reset --hard），
#                               丢弃本地对 skill / hook / references 的任何改动

set -euo pipefail

UPDATE=0
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --update) UPDATE=1 ;;
    --force)  FORCE=1 ;;
    -h|--help)
      sed -n '2,9p' "$0"; exit 0 ;;
    *)
      echo "未知参数: $arg" >&2; exit 1 ;;
  esac
done
OVERWRITE=$(( UPDATE | FORCE ))

SKILL_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/docs"
HOOKS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks"
SETTINGS_FILE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== research-docs-skill 安装 ==="

# ── 0. 同步仓库（--update / --force） ──────────────────────
if [[ "$OVERWRITE" -eq 1 ]]; then
  echo ""
  echo "→ 同步仓库 ($SCRIPT_DIR)"
  if [[ ! -d "$SCRIPT_DIR/.git" ]]; then
    echo "  ⚠️  $SCRIPT_DIR 不是 git 仓库，跳过同步" >&2
  elif [[ "$FORCE" -eq 1 ]]; then
    # 强制同步到远程 upstream，丢弃本地所有改动
    BRANCH=$(git -C "$SCRIPT_DIR" branch --show-current)
    UPSTREAM=$(git -C "$SCRIPT_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "origin/$BRANCH")
    echo "  fetch + reset --hard $UPSTREAM （丢弃本地修改）"
    git -C "$SCRIPT_DIR" fetch "${UPSTREAM%%/*}"
    git -C "$SCRIPT_DIR" reset --hard "$UPSTREAM"
    echo "  完成"
  else
    # --update: 要求工作区干净
    if ! git -C "$SCRIPT_DIR" diff --quiet || ! git -C "$SCRIPT_DIR" diff --cached --quiet; then
      echo "  ⚠️  工作区有未提交修改，已中止。" >&2
      echo "       · 若要保留本地修改：请先 commit / stash 后再重试 --update" >&2
      echo "       · 若要丢弃本地修改、强制同步到远程最新：改用 --force" >&2
      exit 1
    fi
    git -C "$SCRIPT_DIR" pull --ff-only
    echo "  完成"
  fi
fi

# ── 1. 安装 skill ──────────────────────────────────────────

echo ""
echo "→ 安装 skill 到 $SKILL_DIR"

if [[ -d "$SKILL_DIR" && "$OVERWRITE" -ne 1 ]]; then
  echo "  已存在，跳过（--update 拉取最新并覆盖；--force 强制同步到远程）"
else
  mkdir -p "$SKILL_DIR/references"
  cp -f "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
  cp -f "$SCRIPT_DIR/references/aris.md" "$SKILL_DIR/references/aris.md"
  echo "  完成"
fi

# ── 2. 安装 hook 脚本 ──────────────────────────────────────

echo ""
echo "→ 安装 docs-hook.sh 到 $HOOKS_DIR"

mkdir -p "$HOOKS_DIR"
cp "$SCRIPT_DIR/scripts/docs-hook.sh" "$HOOKS_DIR/docs-hook.sh"
chmod +x "$HOOKS_DIR/docs-hook.sh"
echo "  完成"

# ── 3. 更新 settings.json ──────────────────────────────────

echo ""
echo "→ 更新 $SETTINGS_FILE"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# 检查 jq 是否可用
if ! command -v jq &>/dev/null; then
  echo "  ⚠️  未找到 jq，请手动将以下内容添加到 settings.json 的 hooks 字段："
  cat <<'EOF'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/docs-hook.sh --record", "timeout": 3 }]
      }
    ],
    "Stop": [
      {
        "matcher": "*",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/docs-hook.sh --remind", "timeout": 5 }]
      }
    ]
  }
}
EOF
  exit 0
fi

# 检查是否已有 docs-hook 配置
if jq -e '.hooks.Stop[]?.hooks[]? | select(.command | contains("docs-hook.sh"))' "$SETTINGS_FILE" &>/dev/null; then
  echo "  已存在，跳过"
else
  # 合并 hooks 配置
  HOOK_PATCH=$(cat <<'EOF'
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/docs-hook.sh --record", "timeout": 3 }]
    }
  ],
  "Stop": [
    {
      "matcher": "*",
      "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/docs-hook.sh --remind", "timeout": 5 }]
    }
  ]
}
EOF
)
  # 深度合并：如果已有 hooks 字段则合并数组，否则直接设置
  jq --argjson patch "$HOOK_PATCH" '
    if .hooks then
      .hooks.PostToolUse = ((.hooks.PostToolUse // []) + $patch.PostToolUse) |
      .hooks.Stop = ((.hooks.Stop // []) + $patch.Stop)
    else
      .hooks = $patch
    end
  ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
  echo "  完成"
fi

echo ""
echo "✓ 安装完成。重启 Claude Code 后生效。"
echo ""
echo "使用方式："
echo "  /docs init       初始化文档结构"
echo "  /docs status     文档健康检查"
echo "  /docs aris       归档 ARIS 产出"
