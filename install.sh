#!/bin/bash
# install.sh — research-docs-skill 安装脚本
# 安装 skill + docs-hook（ARIS/代码变更后提醒运行 /docs 子命令）

set -euo pipefail

SKILL_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/docs"
HOOKS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks"
SETTINGS_FILE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== research-docs-skill 安装 ==="

# ── 1. 安装 skill ──────────────────────────────────────────

echo ""
echo "→ 安装 skill 到 $SKILL_DIR"

if [[ -d "$SKILL_DIR" ]]; then
  echo "  已存在，跳过（如需更新请手动 git pull）"
else
  mkdir -p "$SKILL_DIR"
  cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
  mkdir -p "$SKILL_DIR/references"
  cp "$SCRIPT_DIR/references/aris.md" "$SKILL_DIR/references/aris.md"
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
