# research-docs-skill

一个 [Claude Code](https://claude.ai/code) skill，用于科研项目的文档生成、更新与归档管理。

---

科研项目的文档问题，往往不是从一开始就乱的。

跑到第三次实验迭代的时候，发现 results.md、paper-plan 和邮件附件里各有一个 accuracy，三个数字没有一个一样。改到 V7 版本，已经不记得 V3 和 V4 到底改了什么、哪次跑出来的结果还算数。session 结束前忘了写交接，第二天重新打开项目，光是回忆"上次做到哪"就花了半小时。

这些不是粗心，是科研项目没有文档结构的必然结果。

`research-docs-skill` 是一个面向 Claude Code 的文档管理 skill，通过强制单一来源原则解决这个问题——`results.md` 是实验数字的唯一权威，`paper-plan.md` 是论文叙事的唯一权威，方法描述、版本日志各归其位，不再散落。无论是日常更新、session 交接还是 ARIS 归档，一条指令完成，进度随时可接续。

---

## 功能

统一管理科研项目文档结构，强制执行**单一来源原则**（实验数字、方法描述、论文叙事各有唯一权威文件），避免多文件数字不一致。

## 支持的子命令

| 子命令 | 说明 |
|--------|------|
| `init` | 初始化标准文档结构 |
| `update` | 更新指定文档 |
| `status` | 文档健康检查 |
| `archive` | 归档旧文档 |
| `handoff` | 生成交接文档（session 结束时使用） |
| `migrate` | 迁移旧结构到标准结构 |
| `log` | 写开发日志 |
| `aris` | 归档 ARIS 产出为中文版，并生成合并完整版 |

## 触发关键词

- **handoff**：说"写交接"、"交接文档"、"session 结束"、"记录一下进度"时自动触发
- **log**：说"写日志"、"记日志"、"开发日志"时自动触发
- **aris**：说"aris"、"归档aris"、"整理aris"时自动触发

## 标准文档结构

```
docs/
├── README.md
├── project/
│   ├── overview.md        # 项目 dashboard
│   └── paper-plan.md      # 论文规划（唯一）
├── data/
├── methods/
├── evaluation/
│   └── results.md         # 实验数字唯一来源
├── handoffs/
├── journal/
├── aris/
└── archive/
```

## 安装

将此仓库克隆到 Claude Code skills 目录：

```bash
git clone https://github.com/$(gh api user -q .login)/research-docs-skill ~/.claude/skills/docs
```

或手动复制 `SKILL.md` 到 `~/.claude/skills/docs/SKILL.md`。

## 使用

在 Claude Code 中直接说：

```
/docs init
/docs handoff
/docs status
```
