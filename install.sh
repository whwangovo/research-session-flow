#!/bin/bash
# install.sh — research skill 安装脚本
# 安装 research skill 到 ~/.claude/skills/research/；清理旧 docs 安装。
#
# 用法：
#   ./install.sh                安装（已存在则跳过覆盖）
#   ./install.sh --update       git pull --ff-only 拉取最新并覆盖；
#                               工作区有未提交修改时会中止
#   ./install.sh --force        强制同步到远程（git fetch + reset --hard），
#                               丢弃本地对 skill / references 的任何改动

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

SKILL_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/research"
HOOKS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks"
SETTINGS_FILE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
OLD_SKILL_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/docs"
OLD_HOOK_FILE="$HOOKS_DIR/docs-hook.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== research skill 安装 ==="

# ── 0. 同步仓库（--update / --force） ──────────────────────
if [[ "$OVERWRITE" -eq 1 ]]; then
  echo ""
  echo "→ 同步仓库 ($SCRIPT_DIR)"
  if [[ ! -d "$SCRIPT_DIR/.git" ]]; then
    echo "  ⚠️  $SCRIPT_DIR 不是 git 仓库，跳过同步" >&2
  elif [[ "$FORCE" -eq 1 ]]; then
    BRANCH=$(git -C "$SCRIPT_DIR" branch --show-current)
    UPSTREAM=$(git -C "$SCRIPT_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "origin/$BRANCH")
    echo "  fetch + reset --hard $UPSTREAM （丢弃本地修改）"
    git -C "$SCRIPT_DIR" fetch "${UPSTREAM%%/*}"
    git -C "$SCRIPT_DIR" reset --hard "$UPSTREAM"
    echo "  完成"
  else
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
  cp -f "$SCRIPT_DIR/references/init.md" "$SKILL_DIR/references/init.md"
  cp -f "$SCRIPT_DIR/references/update.md" "$SKILL_DIR/references/update.md"
  cp -f "$SCRIPT_DIR/references/status.md" "$SKILL_DIR/references/status.md"
  cp -f "$SCRIPT_DIR/references/handoff.md" "$SKILL_DIR/references/handoff.md"
  cp -f "$SCRIPT_DIR/references/log.md" "$SKILL_DIR/references/log.md"
  cp -f "$SCRIPT_DIR/references/aris.md" "$SKILL_DIR/references/aris.md"
  cp -f "$SCRIPT_DIR/references/dashboards.md" "$SKILL_DIR/references/dashboards.md"
  echo "  完成"
fi

# ── 2. 清理旧 docs 安装 ─────────────────────────────────────

echo ""
echo "→ 检查旧 docs 安装"

cleanup_needed=0

if [[ -d "$OLD_SKILL_DIR" ]]; then
  echo "  ⚠️  检测到旧 skill 目录：$OLD_SKILL_DIR"
  echo "       建议手动清理：rm -rf \"$OLD_SKILL_DIR\""
  cleanup_needed=1
fi

if [[ -f "$OLD_HOOK_FILE" ]]; then
  echo "  ⚠️  检测到旧 hook 脚本：$OLD_HOOK_FILE"
  echo "       建议手动清理：rm \"$OLD_HOOK_FILE\""
  cleanup_needed=1
fi

# settings.json 里的旧 hook 条目自动清除（留着会报错，因为脚本已不存在）
if [[ -f "$SETTINGS_FILE" ]] && command -v jq &>/dev/null; then
  if jq -e '.. | .command? // empty | select(type == "string") | select(contains("docs-hook.sh"))' "$SETTINGS_FILE" &>/dev/null; then
    echo "  → settings.json 中检测到旧 docs-hook.sh hook 条目，自动清除"
    jq '
      def clean_hooks:
        map(
          .hooks = (.hooks | map(select((.command // "") | contains("docs-hook.sh") | not)))
          | select(.hooks | length > 0)
        );
      if .hooks.PostToolUse then .hooks.PostToolUse = (.hooks.PostToolUse | clean_hooks) else . end
      | if .hooks.Stop then .hooks.Stop = (.hooks.Stop | clean_hooks) else . end
      | if .hooks.PostToolUse == [] then del(.hooks.PostToolUse) else . end
      | if .hooks.Stop == [] then del(.hooks.Stop) else . end
      | if .hooks == {} then del(.hooks) else . end
    ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    echo "    完成"
    cleanup_needed=1
  fi
elif [[ -f "$SETTINGS_FILE" ]]; then
  if grep -q "docs-hook.sh" "$SETTINGS_FILE" 2>/dev/null; then
    echo "  ⚠️  settings.json 中存在 docs-hook.sh hook 条目，但未安装 jq"
    echo "       建议 brew install jq 后重跑本脚本，或手动编辑 settings.json 移除含 docs-hook.sh 的 hooks 条目"
    cleanup_needed=1
  fi
fi

if [[ "$cleanup_needed" -eq 0 ]]; then
  echo "  无遗留，跳过"
fi

# ── 3. 完成提示 ─────────────────────────────────────────────

echo ""
echo "✓ 安装完成。重启 Claude Code 后生效。"
echo ""
echo "使用方式："
echo "  /research init [<name>]        初始化（冷启动 / 迁移 / 升级，幂等）"
echo "  /research status               文档健康检查"
echo "  /research handoff              写 session 交接文档"
echo "  /research aris                 归档 ARIS 产出"
