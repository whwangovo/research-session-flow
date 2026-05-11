---
name: research
description: "为科研/论文项目提供初始化 + 文档管理（init/update/status/handoff/log/aris/dashboard）。主业是 docs 和 handoff；init 一条命令完成冷启动（git + README + CLAUDE.md + gitignore + docs 全套）和已有项目的结构迁移/版本升级。强制单一来源原则：实验数字→results.md，方法→methods/，论文叙事→paper-plan.md。适用于 ML/AI 研究、论文写作、实验管理场景，不适用于前后端工程项目（见 fullstack-docs）。"
argument-hint: "[init|update|status|handoff|log|aris|dashboard] [topic|file]"
allowed-tools: Bash(*), Read, Write, Edit, Grep, Glob, Agent
triggers:
  - handoff: 写交接/handoff/交接文档/session结束/记录一下进度/写个总结/下次继续/科研进度/实验进度
  - log: 写日志/记日志/开发日志/科研日志/实验日志
  - aris: aris/归档aris/整理aris
---

# Research: 科研项目管理

操作目标：**$ARGUMENTS**

本 skill 的主业是 **docs 和 handoff**：文档结构的建立、维护、交接。`init` 一条命令覆盖从"空目录冷启动"（git + README + CLAUDE.md + .gitignore + docs 全套）到"已有项目结构迁移/版本升级"的全部路径，幂等可反复跑。

**不负责**：archive 生命周期（用 `git mv` 手动管理）、Python/Node 环境、依赖文件、CI、LICENSE。

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
│   └── docs/                    # 文档类归档入口（skill 只建空骨架，不管生命周期）
│       ├── deprecated/          # 单个废弃文档（用户手动 git mv 进来）
│       ├── scratch/             # 从 scratch/ 提升保留的快照（用户手动 mv 进来）
│       │   └── YYYY-MM/         # 按月分桶
│       └── YYYY-MM-DD-<slug>/   # 按日期整体快照（用户手动创建）
│
└── scratch/                     # 一次性 HTML 便签（项目根，gitignored）
    ├── README.md                # 唯一 git-tracked 文件：规则说明
    └── YYYY-MM-DD-<slug>.html   # 用完即删；要留快照 → archive/docs/scratch/
```

**archive 的生命周期由用户手动管理**（`git mv`）。skill 只在 `init` 时建空骨架目录（带 `.gitkeep`），之后什么时候归档、什么时候快照、什么时候把 `scratch/*.html` 提升到 `dashboards/`，全看你。

**三档 HTML 归位（v3 心智模型）**：

| 档 | 触发条件 | 位置 | git |
|---|---|---|---|
| L3 长期工具 | 写回 / 复杂 join / 多人长期用 | 独立 app（如 Next.js，skill 不管） | yes |
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

| `$ARGUMENTS` 起始词 | 跳转 |
|---------------------|------|
| `init` | → Phase: Init |
| `new` | → Phase: Init（别名，同 init） |
| `migrate` | → Phase: Init（别名，同 init） |
| `update` | → Phase: Update |
| `status`（或无参数） | → Phase: Status |
| `archive` | → Phase: Status（**archive 生命周期由用户手动管理，此处为别名**） |
| `dashboard` | → Phase: Dashboard |
| `handoff` | → Phase: Handoff |
| `log` | → Phase: Log |
| `aris` | → Phase: Aris |

**关于 `archive`**：本 skill 不再提供 archive 子命令。归档请用 `git mv <file> archive/docs/deprecated/`，批量快照用 `cp -r docs/ archive/docs/YYYY-MM-DD-<slug>/`。`/research archive` 当作 `/research status` 的别名执行，并在输出末尾提示一句"archive 由用户手动管理"。

---

## 共享流程

子命令通过 `执行 [Pn: 名称]` 引用以下流程。

> **设计原则：handoff 轻，log 重**。`handoff` 是每次 session 的闭环，纯对话收束，**不碰 git**；`log` 是一天的收尾，做完整收束——写日志 + 分组 commit 当天所有未提交改动。commit 在 log 里是 deliberate 的集中动作，不会散落在每次 handoff。

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

**本轮语义**：旧文档迁移（schema v1→v2 的 `01-` / `PROJECT_` / `handoff` 类）会在 init 场景 B 自动执行；其他（文件名版本后缀、v2 残留 `docs/archive/`、非标准 archive 位置）**不自动执行**，只在报告里建议，由用户手动处理。

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

---

## Phase: Status

**默认子命令**（无参数时执行，或 `archive` 别名时执行）。

**1. 检查 docs/ 是否存在**

- 不存在 → 输出提示：`docs/ 目录不存在，运行 /research init 初始化（冷启动或已有项目迁移）`，结束
- 存在 → 继续

**2. 读取 schema 版本**

读取 `docs/README.md` frontmatter 的 `schema_version` 字段：
- 无字段 → 显示 `⚠️ schema_version 缺失（v1 或更早），建议运行 /research init 升级`
- 有字段 → 显示 `schema v{n}`

**3. 执行 [P2: 旧结构探测]**

如果 `LEGACY_DETECTED`，在报告中列出发现的遗留模式，建议运行 `/research init` 迁移（迁移范围仅限 v1→v2/v3 的自动可迁项；archive 类遗留仍需手动处理）。

**4. 文档健康扫描**

扫描 `docs/` 下所有活跃 `.md` 文件（排除 `archive/` 和 `handoffs/resolved/`），输出表格：

| 文件 | updated | 天数 | 状态 |
|------|---------|------|------|
| project/overview.md | 2026-04-01 | 20 | ✅ |
| methods/design.md | 2026-03-01 | 51 | ⚠️ 过期 |

过期阈值：`updated` 距今 >30 天。

**5. 摘要**

输出：活跃文档数、过期文档数、活跃 handoff 数、已归档 handoff 数。
如有过期文档，建议运行 `/research update`。

**6. archive 别名提示**

如果是通过 `$ARGUMENTS = archive` 进来的，在输出末尾追加：

```
ℹ️  archive 生命周期由用户手动管理。常用命令：
    · 单文件归档：git mv <file> archive/docs/deprecated/
    · 整段快照：cp -r docs/ archive/docs/$(date +%Y-%m-%d)-<slug>/
    · scratch 快照保留：mv scratch/<file>.html archive/docs/scratch/$(date +%Y-%m)/
```

---

## Phase: Init

`/research init [<project-name>]`

一条命令覆盖从"空目录冷启动"到"已有项目结构迁移/版本升级"的全部路径，幂等，可反复跑。

**non-goals**：
- 不管 Python / Node 环境（venv、conda、npm install）
- 不管依赖文件（pyproject.toml、package.json、requirements.txt）
- 不管 CI / pre-commit / GitHub Actions
- 不管 LICENSE

**1. 判断场景**

- `docs/` 不存在 → **场景 A：新建**（完整冷启动）
- `docs/` 存在，执行 `[P2: 旧结构探测]`：
  - `LEGACY_DETECTED` → **场景 B：迁移**
  - 否则，读取 `docs/README.md` 的 `schema_version`：
    - 无字段或 < 当前版本 → **场景 B2：版本升级**
    - = 当前版本 → **场景 C：已就绪**

当前 schema 版本：**3**

### 场景 A：新建（完整冷启动）

**a. 项目信息**

- 项目名：`$ARGUMENTS` 第二个 token（如 `/research init my-paper`） > `basename $PWD`
- 描述：不问，用 placeholder `"科研项目"`，用户进去自己改 README / CLAUDE.md
- 读取 `CLAUDE.md`、`README.md`、顶层目录、配置文件（`pyproject.toml`、`setup.py`、`package.json`），用于按需创建子目录

**b. git 初始化**

- 有 `.git/` → 跳过
- 无 `.git/` → `git init -b main`

**c. 根 `.gitignore`（幂等）**

**原则**：默认本地化。gitignore 的逻辑是"哪些内容需要跟协作者共享"，而不是"哪些要排除"——默认全部本地，要共享的用 `!` 白名单单独豁免。docs/archive/paper/data 都是私人或 submodule 管理，默认不进 git。

不存在则创建，存在则逐行检查并追加缺失行。

**基础块**（始终写入）：

```
# OS / editor
.DS_Store

# Python
__pycache__/
*.py[cod]
.venv/
.ipynb_checkpoints/

# env / secrets
.env

# logs
/logs/

# local workspace (not shared by default)
/docs/
/archive/

# scratch (dir ignored except its README)
/scratch/*
!/scratch/README.md

# external / large / submodule-managed
/paper/
/data/

# *.json 默认不推（data 里实验结果等），按需白名单
*.json
!package.json
!package-lock.json
!pyproject.toml
!tsconfig*.json

# To share specific files from ignored dirs:
# change  /foo/  →  /foo/*   then add  !/foo/path/to/file
```

**条件注入**（按探测结果追加）：

- 探测到 `package.json` 或 `node_modules/` → 追加 Node 块：

  ```
  # Node
  node_modules/
  .next/
  .turbo/
  dist/
  build/
  npm-debug.log*
  yarn-debug.log*
  yarn-error.log*
  ```

- 探测到 `*.tex` 文件（不依赖 `paper/` 目录名，因为 `paper/` 常是 submodule） → 追加 LaTeX 构建产物块：

  ```
  # LaTeX
  *.aux
  *.log
  *.out
  *.fls
  *.fdb_latexmk
  *.synctex.gz
  *.bbl
  *.blg
  # *.pdf 已由 /paper/ 或用户自行处理；LaTeX 块不额外忽略 PDF
  ```

- 探测到 `requirements.txt` / `pyproject.toml` 含 `torch|tensorflow|jax|transformers`，或已存在 `hf_staging/` / `analysis/` → 追加 ML 产物块：

  ```
  # ML artifacts
  /analysis/
  /hf_staging/
  ```

  （注：`/data/` 和 `/logs/` 已在基础块）

**d. 根 `README.md`**

只在不存在时创建，已存在跳过。模板：

```markdown
# <project-name>

科研项目

## 结构

- `docs/` — 项目文档（索引：`docs/README.md`）
- `scratch/` — 一次性 HTML 便签（gitignored）
- `archive/docs/` — 文档归档入口（由用户手动管理）

## 文档

见 `docs/README.md`。
```

**e. 根 `CLAUDE.md`（最小骨架）**

只在不存在时创建最小骨架，已存在跳过（后面 P4 会处理 `## Documentation` 节注入）：

```markdown
# <project-name>

科研项目
```

**f. 创建目录结构**

始终创建（v3）：
- `docs/project/`、`docs/handoffs/`、`docs/handoffs/resolved/`
- `docs/dashboards/`、`docs/dashboards/render/`（v3：HTML 界面层）
- 项目根 `archive/docs/deprecated/`、`archive/docs/scratch/`（v3：空骨架，带 `.gitkeep`）
- 项目根 `scratch/`（v3：一次性 HTML 便签）

按需创建（检测到对应代码时）：`docs/data/`、`docs/methods/`、`docs/evaluation/`

**g. 生成文档骨架**

每个文档使用 frontmatter（`updated`、`status: draft`、`scope`）：

- `docs/README.md`：索引 + 阅读顺序 + archive 说明（archive 说明指向项目根 `archive/docs/`，并注明"归档由用户手动管理"）。frontmatter 含 `schema_version: 3`
- `docs/project/overview.md`：纯 dashboard（状态、进度、链接，不放结论/叙事）
- `docs/project/paper-plan.md`：论文规划骨架（定位、贡献 C1-Cn、叙事弧、章节结构、图表计划、时间线）
- `docs/dashboards/README.md`：dashboard 索引 + 刷新命令说明
- `scratch/README.md`：说明 scratch 的三条规则（一次性、不被引用、要留快照自己手动 `mv` 到 `archive/docs/scratch/YYYY-MM/`）
- 其他按需创建的目录下放 `status: draft` 骨架文件

**h. 执行 [P4: CLAUDE.md 同步]**（sync_type=`doc-section`）

**i. 输出**

- 列出新建 / 跳过的文件
- 下一步建议：
  1. `git add -A && git commit -m "chore: initial scaffold"` 做首个提交
  2. 跑 `/research handoff` 记录项目起点
  3. 按需往 `docs/{data,methods,evaluation}/` 塞初稿

### 场景 B：迁移（遗留结构 / 版本升级）

**a. 生成迁移计划**

根据 `[P2]` 的发现，生成具体操作列表（仅限可自动迁移项）：
- 目录重命名（`01-project/` → `project/`）
- 文件重命名（`PROJECT_OVERVIEW.md` → `overview.md`）
- handoff 目录合并（`handoff/` + `05-handoff/` → `handoffs/`）
- 补建缺失的标准目录（含 v3 新增：`docs/dashboards/`、`archive/docs/`、`scratch/`）

展示计划给用户，**等待确认**（使用 `AskUserQuestion`）。

> **不自动迁移**的项（只在输出末尾报告建议命令）：
> - 文件名版本后缀（`scope_v3.md` → `archive/docs/deprecated/`）
> - v2 残留 `docs/archive/*` → `archive/docs/`
> - 非标准 archive 位置（`docs/99-archive/` 等）
>
> 这些由用户手动 `git mv` 处理，skill 不触碰。

**b. 执行迁移**

用户确认后：
- 使用 `git mv` 执行重命名（保留 git 历史）
- 补建缺失目录（含 v3 新增：`docs/dashboards/`、`archive/docs/`、`scratch/`）
- 更新 `.gitignore`（参照场景 A.c）
- 在 `docs/README.md` frontmatter 中写入 `schema_version: 3`

**c. 执行 [P3: README 索引同步]**
**d. 执行 [P4: CLAUDE.md 同步]**（sync_type=`doc-section`）

### 场景 B2：版本升级

轻量迁移（适用 v1/v2 → v3）：
1. 补建 v3 新增的标准目录（幂等，已存在跳过）：
   - `docs/dashboards/`、`docs/dashboards/render/`
   - 项目根 `archive/docs/deprecated/`、`archive/docs/scratch/`（带 `.gitkeep`）
   - 项目根 `scratch/` + `scratch/README.md`
2. 更新项目根 `.gitignore`（参照场景 A.c）
3. 写 `docs/dashboards/README.md` 骨架（若不存在）
4. 在 `docs/README.md` frontmatter 中写入 `schema_version: 3`
5. 执行 `[P3: README 索引同步]`
6. **不自动迁移** `docs/archive/*`——在输出末尾报告：

   ```
   ⚠️ 检测到 docs/archive/ 仍存在（v2 语义）。v3 语义下文档归档在项目根 archive/docs/。
      如需迁移，手动执行：
        git mv docs/archive/deprecated/* archive/docs/deprecated/
        git mv docs/archive/* archive/docs/    # 快照目录
        rmdir docs/archive/
   ```

### 场景 C：已就绪

输出：`docs/ 已是 schema v3，无需操作。运行 /research status 查看文档健康状态。`

---

## Phase: Update

`/research update [results|methods|project]`

**1. 确定更新范围**

- 有参数 → 只更新指定类别
- 无参数 → 更新所有过期文档（`updated` 距今 >30 天）

**2. 逐文档更新**

对每个目标文档：
1. 读取当前文档内容
2. 读取对应的 source-of-truth（代码、实验输出、git log）
3. 对比差异，只修改过期/不一致的部分
4. 强制单一来源原则：如发现硬编码实验数字，替换为指向 `results.md` 的链接
5. 更新 frontmatter `updated` 日期

**3. 过期文档归档提示**

如果无参数更新时发现文档内容已完全过时（对应的代码/实验已不存在），在输出末尾列出候选文件并建议命令：

```
ℹ️  以下文档已完全过时，建议手动归档：
    git mv <file> archive/docs/deprecated/
```

skill 不自动执行归档。

**4. 执行 [P3: README 索引同步]**
**5. 执行 [P4: CLAUDE.md 同步]**（sync_type 按更新类别选择：`findings` / `project`）

---

## Phase: Handoff

**核心约束**：handoff 是 session 粒度的 immutable append-only 日志。

- **同 session 内**多次跑 `/research handoff` → **原地更新**当前 session 的那一个文件（重写 5 段内容反映迄今所有工作）
- **跨 session** → 别人 session 的 handoff 内容**只读**，当前 session 唯一能做的事是"整体 mv 到 `resolved/`"（当下一步在本 session 里完成时）
- **禁止**：修改别人 session 的 handoff 文件内容；合并不同 session 的 handoff；删除 handoff（只能 resolve）

实现上靠 frontmatter `session_id` 字段区分同/跨 session。

**1. 定位 handoff 目录**

按优先级探测：`docs/handoffs` > `docs/05-handoff` > `docs/handoff`。
找到后使用该目录；都不存在则创建 `docs/handoffs/` 和 `docs/handoffs/resolved/`。

如果使用的是非标准目录（`05-handoff`、`handoff`），在输出末尾提示用户运行 `/research init` 迁移。

**2. 取当前 session_id**

读环境变量 `$CLAUDE_SESSION_ID`（Claude Code 运行时注入）。
- 有值 → 记为 `CUR_SID`
- 无值（本地调试或非 Claude Code 环境）→ 用 `$(date +%Y%m%d-%H%M%S)-local` 兜底，记为 `CUR_SID`

**3. 扫描活跃 handoff 并分流**

读取 handoff 目录下所有 `*.md`（排除 `resolved/`）。对每个文件读 frontmatter：

| 文件 session_id vs CUR_SID | 处理 |
|----------------------------|------|
| **相同** | 归为"当前 session 的 handoff"（最多一个，多个视为异常并警告）—— step 5 会原地重写它 |
| **不同，或字段缺失** | 归为"历史 handoff"——step 4 处理 |

**4. 处理历史 handoff（只读 + 可能 resolve）**

对每个"历史 handoff"：
- 读"下一步"部分
- 对比**本次 session 的对话上下文**（做了什么、改了什么、决定了什么），判断每条 todo 是否在本 session 内完成
- 所有 todo 已完成 → 更新 frontmatter `status: resolved`，整体 `mv` 到 `resolved/`
- 否则 → **不动**（连 `updated` 字段也不改）

> **历史 handoff 内容只读**：永远不修改 `## 已完成` / `## 当前状态` / `## 关键决策` / `## 下一步` / `## 注意事项` 五段正文；唯一合法的写入是 frontmatter `status: resolved` + 文件移动。
>
> **跨 session 悄悄完成不归本 skill 管**：只看本次 session 对话上下文。

**5. 执行 [P5: Session 素材收集]**

**6. 写当前 session 的 handoff**

**a. 如果 step 3 发现了当前 session 的 handoff**（同 `session_id` 匹配）：

原地**重写**该文件：
- 文件名保持不变
- frontmatter 更新 `updated` 为当天日期
- 5 段内容全部重写，反映**迄今为止本 session** 所有工作（不是"追加"，是"当前全量"）

**b. 否则（当前 session 第一次跑 handoff）**：

新建文件 `$HANDOFF_DIR/YYYY-MM-DD-HHMM-{slug}.md`，slug 来自本 session 的主题。

**frontmatter 模板**：

```yaml
---
updated: YYYY-MM-DD
status: active
scope: session 交接
session_id: $CUR_SID
---
```

**正文模板**：

```markdown
## 已完成
<本 session 迄今完成的工作，具体到文件和函数>

## 当前状态
<项目整体状态快照>

## 关键决策
<本 session 做出的重要决策及理由>

## 下一步
<祈使句格式：读 X → 运行 Y → 做 Z>

## 注意事项
<陷阱、未解决的问题、临时方案>
```

**7. 执行 [P4: CLAUDE.md 同步]**（sync_type=`handoff`）

**8. 输出**

把 handoff 内容输出给用户确认。如有 resolved 的旧 handoff，一并报告。

---

## Phase: Log

`/research log [YYYY-MM-DD]`

**1. 确定日期**

有参数 → 使用指定日期；无参数 → 使用今天日期。

**2. 执行 [P5: Session 素材收集]**

**3. 读取已有日志**

如果 `docs/journal/YYYY-MM-DD-devlog.md` 已存在，读取内容避免重复。

**4. 写入文件**

目录：`docs/journal/`（不存在则创建）
文件名：`YYYY-MM-DD-devlog.md`

- 文件**不存在**：创建新文件

```markdown
---
date: YYYY-MM-DD
---

<正文>

明天：<下一步>（可选）
```

- 文件**已存在**：在末尾追加，用 `---` 分隔

```markdown
（原有内容）

---

<追加内容>
```

**5. 分组 commit（日终收束）**

log 是一天收尾，负责把当天散落的未提交改动**分组** commit，commit 粒度反映工作类别而非时间顺序。

**a. 扫描未提交改动**

`git status --porcelain` 拿到修改/新增文件列表。全空则跳过本步。

**b. 推断历史风格**

`git log --oneline -10` 读最近 commit，抓两件事：
- 语言：中文 / 英文
- 格式：conventional commits（`feat:` / `fix:`）/ 普通描述

后续 commit message 按同风格写，保持仓库一致。

**c. 按语义类别分组**

按文件路径 + 内容性质分组，每组对应一个 commit。推荐映射：

| 类别 | 匹配 | commit 前缀（conventional 风格） |
|------|------|--------------------------------|
| docs | `docs/**`、`README.md`、`CLAUDE.md`、根 `*.md` | `docs:` |
| 方法代码 | `src/**`、`method/**` | `feat:` / `refactor:` / `fix:`（看 diff 性质） |
| 实验结果 | `evaluation/**`、`data/output/**`、`results/**` | `results:` 或 `chore: update results` |
| 测试 | `tests/**`、`test_*.py` | `test:` |
| 配置 / 依赖 | `pyproject.toml`、`package.json`、`.gitignore`、`uv.lock` | `chore:` |
| 论文 | `paper/**` | `paper:` 或按仓库历史风格 |
| 其他 | 以上不匹配 | 单独一组 `chore: misc` 或按实际判断 |

当天的 devlog 文件（step 4 写的）**一定进 docs 组**，保证日志和当天 commit 一起推。

**d. 展示计划**

如果分组 ≥3 个，或总文件数 ≥10，用 `AskUserQuestion` 展示计划让用户确认：

```
将创建 N 个 commit：
  1. docs: <subject> — <files...>
  2. feat: <subject> — <files...>
  3. chore: <subject> — <files...>
继续 / 调整分组 / 取消
```

分组 ≤2 且文件 <10 → 直接执行，不问。

**e. 执行 commit**

对每组：
1. `git add <文件列表>`（精确 add，不用 `-A`）
2. `git commit -m "<prefix>: <subject>"`
   - subject 来自本次 session 对话上下文（做了什么），不是机械描述
   - 跟随步骤 b 推断的语言和格式

**f. 冲突与失败处理**

- pre-commit hook 失败 → 报错停下，不自动 retry、不 `--no-verify`、不 amend；用户自己处理后重跑 `/research log`
- 文件有冲突标记（`<<<<<<<`）→ 跳过该文件，在输出提醒
- 远程有新 commit（`git status` 显示 behind）→ **不 push**，log 不管 push

**g. 敏感文件拦截**

跳过并警告以下文件（不自动 commit）：`.env`、`*.key`、`*.pem`、`credentials*`、`secrets*`。如果这些出现在 `git status`，输出提醒让用户自己决定。

**6. 输出**

把写入的日志内容 + 本次 commit 列表输出给用户确认。

> **不做 push**：推不推到远程是独立的 deliberate 动作，log 只负责本地归拢。

---

## Phase: Dashboard

`/research dashboard [list|new <slug>|render <slug>|status]`

HTML 交互看板管理。详细流程见 `${CLAUDE_SKILL_DIR}/references/dashboards.md`。读取该文件后按其中步骤执行。

子命令速览：

| 子命令 | 行为 |
|-------|------|
| `list`（或无参数） | 列出 `docs/dashboards/*.html` 和对应 `render/<slug>.py`，显示上次渲染时间 |
| `new <slug>` | 创建 `render/<slug>.py` 骨架 + 占位 `<slug>.html`（成对） |
| `render <slug>` | 跑 `render/<slug>.py`，覆盖 `<slug>.html` |
| `status` | 检查每个 dashboard 的 stale 状态（生成器 mtime / html mtime / 源数据 mtime） |

**硬约定**（写入生成器模板）：
- HTML 双击可打开（`file://`），不依赖 dev server
- 数据 inline 进 `<script>`，不做 fetch
- 样式用 Tailwind CDN 或极简内联 CSS
- 每次 render 完整覆盖 html，不增量

## Phase: Aris

详细流程见 `${CLAUDE_SKILL_DIR}/references/aris.md`。读取该文件后按其中步骤执行。

索引更新步骤：执行 `[P3: README 索引同步]` + 更新 `docs/aris/README.md`。

清理步骤（step f）：**不自动归档**。skill 只列出"项目根散落的原始英文 ARIS 文件"，并给出手动命令建议；是否执行、何时执行由用户决定。
