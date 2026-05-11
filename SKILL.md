---
name: research
description: "为科研/论文项目提供初始化 + 文档管理（init/update/status/handoff/log/aris/dashboard）。init 一条命令完成冷启动（git + README + CLAUDE.md + gitignore + docs 全套）和已有项目的结构迁移/版本升级。强制单一来源原则：实验数字→results.md，方法→methods/，论文叙事→paper-plan.md。适用于 ML/AI 研究、论文写作、实验管理场景，不适用于前后端工程项目（见 fullstack-docs）。"
argument-hint: "[init|update|status|handoff|log|aris|dashboard] [topic|file]"
allowed-tools: Bash(*), Read, Write, Edit, Grep, Glob, Agent
triggers:
  - handoff: 写交接/handoff/交接文档/session结束/记录一下进度/写个总结/下次继续/科研进度/实验进度
  - log: 写日志/记日志/开发日志/科研日志/实验日志
  - aris: aris/归档aris/整理aris
---

# Research: 科研项目管理

操作目标：**$ARGUMENTS**

## 标准文档结构

所有项目统一使用以下结构（**schema v3**）：

```
项目根/
├── docs/                        # 活跃文档（MD 记忆层 + dashboards 界面层）
│   ├── README.md                # 索引、阅读顺序、文档健康摘要（含 schema_version）
│   ├── project/                 # 项目状态 + 论文规划
│   │   ├── overview.md          # 纯 dashboard：快照、工作进度、文档入口（不放结论/叙事）
│   │   └── paper-plan.md        # 论文唯一规划文件：叙事、章节 scope、图表、时间线
│   ├── data/                    # 数据规范、schema、标注指南（数据密集型项目）
│   ├── methods/                 # 方法设计、框架、消融设计
│   ├── evaluation/              # 评测协议、结果、分析
│   │   └── results.md           # 实验数字的被引用权威（人工校对，来自 dashboards）
│   ├── dashboards/              # HTML 交互看板（界面层，唯一位置）
│   │   ├── README.md            # dashboard 索引 + 刷新命令
│   │   ├── <slug>.html          # 生成产物（inline data，双击可看）
│   │   └── render/              # 生成器脚本
│   │       └── <slug>.py        # 与 <slug>.html 成对
│   ├── handoffs/                # 交接文档（唯一位置）
│   │   ├── resolved/            # 已完成的交接文档
│   │   └── YYYY-MM-DD-HHMM-slug.md
│   ├── journal/                 # 每日开发日志（唯一位置）
│   │   └── YYYY-MM-DD-devlog.md
│   ├── aris/                    # ARIS skills 产出的中文翻译版（唯一位置）
│   │   ├── ideas/ narrative/ planning/ experiments/ reviews/
│   │   ├── methods/ wiki/ paper/ findings/
│   │   ├── ingest-log.md        # aris 操作日志
│   │   └── README.md            # aris 子目录索引
│   └── deliverables/            # 正式交付物（可选）
│
├── archive/                     # 归档总入口（v3 统一到项目根）
│   └── docs/                    # 文档类归档入口
│       ├── deprecated/          # 单个废弃文档（用户手动 git mv 进来）
│       ├── scratch/             # 从 scratch/ 提升保留的快照（用户手动 mv 进来）
│       │   └── YYYY-MM/         # 按月分桶
│       └── YYYY-MM-DD-<slug>/   # 按日期整体快照（用户手动创建）
│
└── scratch/                     # 一次性 HTML 便签（项目根，gitignored）
    ├── README.md                # 唯一 git-tracked 文件：规则说明
    └── YYYY-MM-DD-<slug>.html   # 用完即删；要留快照 → archive/docs/scratch/
```

**三档 HTML 归位（v3 心智模型）**：

| 档 | 触发条件 | 位置 | git |
|---|---|---|---|
| L3 长期工具 | 写回 / 复杂 join / 多人长期用 | 独立 app（如 Next.js） | yes |
| L2 看板 | 重复使用、有数据源、值得维护生成器 | `docs/dashboards/` | yes |
| L1 便签 | 一次性、用完即走 | `scratch/`（项目根） | no |

**命名规则**：
- 目录和文件名统一 lowercase-kebab-case
- 不用文件名版本后缀（禁止 `scope_v3.md`、`results_v2.md`）
- handoff 文件名格式：`YYYY-MM-DD-HHMM-slug.md`
- dashboard 成对命名：`dashboards/<slug>.html` ↔ `dashboards/render/<slug>.py`
- scratch 用日期前缀：`scratch/YYYY-MM-DD-<slug>.html`

**单一来源原则**（核心设计约束）：

数字权威链：

```
json / eval 产物（源头）
    ↓ 机器渲染
docs/dashboards/*.html（最新、可交互，不被论文或其他文档引用）
    ↓ 人工校对摘抄
docs/evaluation/results.md（被引用权威）
    ↓ 链接
其他文档（禁止硬编码数字）
```

- 实验数字只在 `evaluation/results.md` 里作为**被引用权威**出现；dashboard 是机器产物，不能被引用
- 方法描述只在 `methods/` 里出现，其他文档引用链接，不重复描述
- 论文叙事只在 `project/paper-plan.md` 里出现，不在 overview.md 里重复
- `scratch/` 永远不进数字权威链——它是临时界面，不是记忆
- 违反此原则会导致数字不一致

**文档 frontmatter**（每个文档顶部）：
```yaml
---
updated: YYYY-MM-DD
status: active        # active | draft | stale | archived | resolved（仅 handoff）
scope: 本文档覆盖什么
out-of-scope: 本文档不覆盖什么
session_id: xxx       # 仅 handoff：标识产出该文件的 session，immutable 约束的基础
---
```

**语言**：中文为主，英文技术术语保留。

---

## 子命令路由

根据 `$ARGUMENTS` 起始词，读取对应 reference 文件后按其中步骤执行。所有 reference 位于 `${CLAUDE_SKILL_DIR}/references/`。

| `$ARGUMENTS` 起始词 | 详细流程 |
|---------------------|---------|
| `init` | `references/init.md` |
| `update` | `references/update.md` |
| `status`（或无参数） | `references/status.md` |
| `dashboard` | `references/dashboards.md` |
| `handoff` | `references/handoff.md` |
| `log` | `references/log.md` |
| `aris` | `references/aris.md` |

**设计原则：handoff 轻，log 重**。`handoff` 纯对话收束，不碰 git；`log` 做一天的收尾，写日志 + 分组 commit 当天所有未提交改动。

---

## 共享流程

各子命令通过 `执行 [Pn: 名称]` 引用以下流程。

### P2: 旧结构探测

扫描项目根和 `docs/` 目录，检测以下遗留模式：

| 模式 | 示例 | 建议 |
|------|------|------|
| 编号前缀目录 | `01-project/`、`02-data/`、`05-handoff/` | init 迁移 |
| SCREAMING_CASE 文件名 | `PROJECT_OVERVIEW.md`、`SCOPE.md` | init 迁移 |
| 重复 handoff 目录 | `handoff/` 和 `handoffs/` 共存 | init 迁移 |
| 文件名版本后缀 | `scope_v3.md`、`results_v2.md` | 报告（由用户手动 `git mv` 到 `archive/docs/deprecated/`） |
| 非标准 archive 位置 | `docs/99-archive/`、根级 `deprecated/` | 报告（由用户手动迁移到 `archive/docs/`） |
| **v2 残留：`docs/archive/` 存在** | v3 把文档归档搬到项目根 `archive/docs/` | 报告（由用户手动 `git mv docs/archive/* archive/docs/`） |
| **v3 缺失：`docs/dashboards/` 不存在** | v3 新增的界面层目录 | init 补建 |
| **v3 缺失：项目根 `scratch/` 不存在** | v3 新增的一次性 HTML 便签区 | init 补建（带 .gitignore） |
| **v3 缺失：项目根 `archive/docs/` 不存在** | v3 新增的文档归档入口骨架 | init 补建（带 .gitkeep） |
| **dashboard 无对应生成器** | `docs/dashboards/foo.html` 存在但无 `render/foo.py` | 报告，提醒补生成器或删除 |
| **HTML 生成器散落 `scripts/`** | `scripts/render_*.py`、`scripts/dashboard_*.py` | 报告，建议搬到 `docs/dashboards/render/` |
| **HTML 散落项目根** | 项目根的 `dashboard.html`、`*.html`（非 skill 约定位置） | 报告，建议进 `docs/dashboards/` 或 `scratch/` |

返回：发现列表 + `LEGACY_DETECTED` 布尔值。

### P3: README 索引同步

扫描 `docs/` 下所有活跃文档（排除 `handoffs/resolved/`，`archive/` 已不在 `docs/` 下），重建 `docs/README.md` 的索引表：

**扫描范围**：
- 所有 `.md` 文件
- `docs/dashboards/*.html`（界面层产物）

**索引表格式**（含"类型"列）：

```markdown
| 路径 | 类型 | 职责 | 状态 |
|------|------|------|------|
| project/overview.md | MD | 项目状态 dashboard | active |
| evaluation/results.md | MD | 实验数字被引用权威 | active |
| dashboards/results.html | HTML | 最新结果交互看板（刷新：`/research dashboard render results`） | active |
```

类型枚举：`MD` / `HTML`。

保留 `docs/README.md` 的 frontmatter（含 `schema_version`）不变，只更新索引部分。

### P4: CLAUDE.md 同步

**步骤 1：探测状态**

读取项目根 `CLAUDE.md`，判断当前状态：
- `missing`：文件不存在
- `no-section`：文件存在但无 `## Documentation` 也无 `## Last Handoff`
- `has-doc`：有 `## Documentation` 节
- `has-handoff`：有 `## Last Handoff` 节

**步骤 2：按 sync_type 执行**

| sync_type | 触发者 | 操作 |
|-----------|--------|------|
| `doc-section` | init | 新增或更新 `## Documentation` 节，指向 `docs/README.md` 和关键文件 |
| `findings` | update results | 在 `## Documentation` 节内更新 Core finding / Paper narrative 行 |
| `project` | update project | 在 `## Documentation` 节内更新 Project Overview 摘要 |
| `handoff` | handoff | 新增或更新 `## Last Handoff` 节，列出活跃 handoff 链接 |

状态为 `missing` 时：先创建最小 CLAUDE.md（项目名 + 一行描述），再执行对应操作。
状态为 `no-section` 时：在文件末尾追加对应节。
状态为 `has-doc` 或 `has-handoff` 时：定位到对应节，原地更新内容。

**规则**：只更新目标节，不动其他内容。`## Documentation` 和 `## Last Handoff` 可共存。

### P5: Session 素材收集

按优先级收集当前 session 的工作内容：

1. **对话上下文**（唯一来源）：读取/编辑/创建的文件、运行的命令、遇到的问题、做出的决策
2. **项目文档**（补充，有什么读什么）：`evaluation/results.md`、`project/overview.md`

原则：具体胜于模糊。写文件名、函数名、具体数字，不写"做了一些改进"。不访问 git，session 对话本身就是权威来源。
