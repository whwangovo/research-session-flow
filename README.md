# research-session-flow

一个 [Claude Code](https://claude.ai/code) skill，用于科研项目的初始化、文档维护、session 交接与日终收束。

---

科研项目的文档问题，往往不是从一开始就乱的。

跑到第三次实验迭代的时候，发现 results.md、paper-plan 和邮件附件里各有一个 accuracy，三个数字没有一个一样。改到 V7 版本，已经不记得 V3 和 V4 到底改了什么、哪次跑出来的结果还算数。session 结束前忘了写交接，第二天重新打开项目，光是回忆"上次做到哪"就花了半小时。工作区还堆着二十个未提交文件，git log 已经一周没动。

这些不是粗心，是科研项目没有文档结构的必然结果。

`research-session-flow` 是一个面向 Claude Code 的科研项目管理 skill。设计上有三条硬规则：

- **单一来源**：`results.md` 是实验数字的唯一权威，`paper-plan.md` 是论文叙事的唯一权威，方法描述、版本日志各归其位
- **handoff append-only**：每次 `/research handoff` 新建一份文件，不回改历史；历史 handoff 的"下一步"全部完成后自动 resolve 归档
- **handoff 轻，log 重**：handoff 纯文本快速收束不碰 git；log 做日终完整收束，包含分组 commit

---

## 支持的子命令

| 子命令 | 说明 |
|--------|------|
| `init` | 初始化。幂等覆盖三种场景：空目录冷启动（git + README + CLAUDE.md + gitignore + docs 全套）/ 旧结构迁移 / 版本升级 |
| `handoff` | 每次新建一份 session 交接；"下一步"全完成的历史 handoff 自动搬到 `resolved/` |
| `log` | 日终收尾：写当天开发日志 + 按语义类别分组 commit 未提交改动 |
| `update` | 更新过期文档 |
| `status` | 文档健康检查（默认子命令） |
| `aris` | 归档 ARIS 产出为中文版，并生成合并完整版 |
| `dashboard` | HTML 交互看板管理（list / new / render / status） |

## 触发关键词

- **handoff**：说"写交接"、"交接文档"、"session 结束"、"记录一下进度"时自动触发
- **log**：说"写日志"、"记日志"、"开发日志"时自动触发
- **aris**：说"aris"、"归档aris"、"整理aris"时自动触发

## 标准文档结构

```
项目根/
├── docs/
│   ├── README.md
│   ├── project/
│   │   ├── overview.md        # 项目 dashboard
│   │   └── paper-plan.md      # 论文规划（唯一）
│   ├── data/
│   ├── methods/
│   ├── evaluation/
│   │   └── results.md         # 实验数字唯一来源
│   ├── dashboards/            # HTML 交互看板（含 render/ 生成器）
│   ├── handoffs/
│   │   ├── resolved/          # 已完成的交接文档
│   │   └── YYYY-MM-DD-HHMM-slug.md
│   ├── journal/               # 每日开发日志
│   └── aris/
├── archive/
│   └── docs/                  # 文档归档入口（用户手动管理）
│       ├── deprecated/
│       └── scratch/
├── scratch/                   # 一次性 HTML 便签（gitignored）
│   └── README.md
├── CLAUDE.md                  # Claude Code 入口
└── AGENTS.md                  # Codex 入口（内容：@ CLAUDE.md）
```

## 安装

```bash
git clone https://github.com/whwangovo/research-session-flow
cd research-session-flow
./install.sh
```

安装脚本会：
1. 将 skill 同时复制到 `~/.claude/skills/research/`（Claude Code）和 `~/.codex/skills/research/`（Codex）
2. 检测并清理旧 `docs` skill 安装（旧 skill 目录和 hook 脚本给出手动清理提示；`settings.json` 里的旧 hook 条目自动清除）

重启 Claude Code / Codex 后生效。

### 更新

在 clone 的仓库目录下重跑：

```bash
./install.sh --update        # 拉取最新并更新（工作区脏会中止）
./install.sh --force         # 强制同步到远程，丢弃本地修改
```

## 两条核心工作流

### handoff：session 闭环

`/research handoff` 是每个 session 的收尾动作。核心语义：

- **append-only**：每次执行新建一份 handoff 文件，不回改历史
- **自动 resolve**：扫描活跃 handoff，"下一步"全部完成的整体 `mv` 到 `resolved/`
- **不碰 git**：纯文本收束，耗时可控
- **自动同步 CLAUDE.md**：`## Last Handoff` 节指向活跃 handoff，新 session 打开项目直接看到上次停在哪

handoff 的五段固定结构：已完成 / 当前状态 / 关键决策 / 下一步 / 注意事项。「下一步」用祈使句（读 X → 运行 Y → 做 Z），新 session 第一件事就能对照执行。

### log：日终收束

`/research log` 是一天收尾，把散落的工作归拢：

1. **写 devlog**：`docs/journal/YYYY-MM-DD-devlog.md`（不存在则建，存在则追加）
2. **分组 commit**：按语义类别自动分组当天所有未提交改动，每组一个 commit

分组映射（按 conventional commits 风格）：

| 类别 | 匹配 | commit 前缀 |
|------|------|-----------|
| docs | `docs/**`、`README.md`、`CLAUDE.md` | `docs:` |
| 方法代码 | `src/**`、`method/**` | `feat:` / `refactor:` / `fix:` |
| 实验结果 | `evaluation/**`、`data/output/**`、`results/**` | `results:` |
| 测试 | `tests/**` | `test:` |
| 配置 / 依赖 | `pyproject.toml`、`package.json`、`.gitignore` | `chore:` |
| 论文 | `paper/**` | `paper:` |

分组 ≥3 或文件数 ≥10 时会展示计划让你确认；否则直接执行。commit 语言 / 风格自动跟随仓库 `git log -10` 的历史习惯。敏感文件（`.env` / `*.key` / `*.pem` / `credentials*`）自动跳过并警告。

**顺序关键**：先写 devlog → 再 commit。这样当天日志本身会进入 `docs:` 分组，日终 `git status` 完全干净。

## 使用

在 Claude Code 中直接说：

```
/research init my-paper      # 空目录冷启动，或已有项目补全/升级
/research handoff            # 写当前 session 交接
/research log                # 日终：写日志 + 分组 commit
/research status             # 文档健康检查
/research aris               # 翻译归档 ARIS 产出
```

典型一天的节奏：若干次 `handoff` 分散在 session 之间 → 一次 `log` 在当天结束时做总收束。
