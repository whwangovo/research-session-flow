---
name: docs
description: "为科研/论文项目生成、更新、归档文档。支持 init/update/status/archive/handoff/log/aris 子命令。强制单一来源原则：实验数字→results.md，方法→methods/，论文叙事→paper-plan.md。适用于 ML/AI 研究、论文写作、实验管理场景，不适用于前后端工程项目（见 fullstack-docs）。"
argument-hint: "[init|update|status|archive|handoff|log|aris] [topic|file]"
allowed-tools: Bash(*), Read, Write, Edit, Grep, Glob, Agent
triggers:
  - handoff: 写交接/handoff/交接文档/session结束/记录一下进度/写个总结/下次继续/科研进度/实验进度
  - log: 写日志/记日志/开发日志/科研日志/实验日志
  - aris: aris/归档aris/整理aris
---

# Docs: 科研项目文档管理

操作目标：**$ARGUMENTS**

## 标准文档结构

所有项目统一使用以下结构：

```
docs/
├── README.md                    # 索引、阅读顺序、文档健康摘要（含 schema_version）
├── project/                     # 项目状态 + 论文规划
│   ├── overview.md              # 纯 dashboard：快照、工作进度、文档入口（不放结论/叙事）
│   └── paper-plan.md            # 论文唯一规划文件：叙事、章节 scope、图表、时间线
├── data/                        # 数据规范、schema、标注指南（数据密集型项目）
├── methods/                     # 方法设计、框架、消融设计
├── evaluation/                  # 评测协议、结果、分析
│   └── results.md               # 所有实验数字的唯一权威来源
├── handoffs/                    # 交接文档（唯一位置）
│   ├── resolved/                # 已完成的交接文档
│   └── YYYY-MM-DD-HHMM-slug.md
├── journal/                     # 每日开发日志（唯一位置）
│   └── YYYY-MM-DD-devlog.md
├── aris/                        # ARIS skills 产出的中文翻译版（唯一位置）
│   ├── ideas/ narrative/ planning/ experiments/ reviews/
│   ├── methods/ wiki/ paper/ findings/
│   ├── ingest-log.md            # aris 操作日志
│   └── README.md                # aris 子目录索引
├── deliverables/                # 正式交付物（可选）
└── archive/                     # 归档（唯一位置）
    ├── YYYY-MM-DD/              # 批量归档（重构/方向变更）
    │   └── _reason.md
    └── deprecated/              # 单个废弃文件
```

**命名规则**：
- 目录和文件名统一 lowercase-kebab-case
- 不用文件名版本后缀（禁止 `scope_v3.md`、`results_v2.md`）
- handoff 文件名格式：`YYYY-MM-DD-HHMM-slug.md`

**单一来源原则**（核心设计约束）：
- 实验数字只在 `evaluation/results.md` 里出现，其他文档引用链接，不复制数字
- 方法描述只在 `methods/` 里出现，其他文档引用链接，不重复描述
- 论文叙事只在 `project/paper-plan.md` 里出现，不在 overview.md 里重复
- 违反此原则会导致数字不一致

**文档 frontmatter**（每个文档顶部）：
```yaml
---
updated: YYYY-MM-DD
status: active        # active | draft | stale | archived | resolved（仅 handoff）
scope: 本文档覆盖什么
out-of-scope: 本文档不覆盖什么
---
```

**语言**：中文为主，英文技术术语保留。

---

## 子命令路由

| `$ARGUMENTS` 起始词 | 跳转 |
|---------------------|------|
| `init` | → Phase: Init |
| `migrate` | → Phase: Init（别名，同 init） |
| `update` | → Phase: Update |
| `status`（或无参数） | → Phase: Status |
| `archive` | → Phase: Archive |
| `handoff` | → Phase: Handoff |
| `log` | → Phase: Log |
| `aris` | → Phase: Aris |

---

## 共享流程

子命令通过 `执行 [Pn: 名称]` 引用以下流程。

### P1: 写前提交

检查 `git status --porcelain`。如果有未提交改动：
1. `git add -A`
2. 读取 `git diff --cached --stat`，生成 commit message：`<type>: <summary>`
3. `git commit -m "<message>"`

无改动则跳过。

### P2: 旧结构探测

扫描 `docs/` 目录，检测以下遗留模式：

| 模式 | 示例 |
|------|------|
| 编号前缀目录 | `01-project/`、`02-data/`、`05-handoff/` |
| SCREAMING_CASE 文件名 | `PROJECT_OVERVIEW.md`、`SCOPE.md` |
| 重复 handoff 目录 | `handoff/` 和 `handoffs/` 共存 |
| 文件名版本后缀 | `scope_v3.md`、`results_v2.md` |
| 非标准 archive 位置 | `99-archive/`、根级 `deprecated/` |

返回：发现列表 + `LEGACY_DETECTED` 布尔值。

### P3: README 索引同步

扫描 `docs/` 下所有活跃 `.md` 文件（排除 `archive/` 和 `handoffs/resolved/`），重建 `docs/README.md` 的索引表：

```markdown
| 路径 | 职责 | 状态 |
|------|------|------|
```

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

1. **对话上下文**（主要来源）：读取/编辑/创建的文件、运行的命令、遇到的问题、做出的决策
2. **Git 信息**（补充）：`git log --oneline -10`、`git diff HEAD~3..HEAD --stat`、`git status`
3. **项目文档**（补充，有什么读什么）：`evaluation/results.md`、`project/overview.md`

原则：具体胜于模糊。写文件名、函数名、具体数字，不写"做了一些改进"。

---

## Phase: Status

**默认子命令**（无参数时执行）。

**1. 检查 docs/ 是否存在**

- 不存在 → 输出提示：`docs/ 目录不存在，运行 /docs init 初始化`，结束
- 存在 → 继续

**2. 读取 schema 版本**

读取 `docs/README.md` frontmatter 的 `schema_version` 字段：
- 无字段 → 显示 `⚠️ schema_version 缺失（v1 或更早），建议运行 /docs init 升级`
- 有字段 → 显示 `schema v{n}`

**3. 执行 [P2: 旧结构探测]**

如果 `LEGACY_DETECTED`，在报告中列出发现的遗留模式，建议运行 `/docs init` 迁移。

**4. 文档健康扫描**

扫描 `docs/` 下所有活跃 `.md` 文件（排除 `archive/` 和 `handoffs/resolved/`），输出表格：

| 文件 | updated | 天数 | 状态 |
|------|---------|------|------|
| project/overview.md | 2026-04-01 | 20 | ✅ |
| methods/design.md | 2026-03-01 | 51 | ⚠️ 过期 |

过期阈值：`updated` 距今 >30 天。

**5. 摘要**

输出：活跃文档数、过期文档数、活跃 handoff 数、已归档 handoff 数。
如有过期文档，建议运行 `/docs update`。

---

## Phase: Init

处理三种场景：新建、迁移、已就绪。

**1. 判断场景**

- `docs/` 不存在 → **场景 A：新建**
- `docs/` 存在，执行 `[P2: 旧结构探测]`：
  - `LEGACY_DETECTED` → **场景 B：迁移**
  - 否则，读取 `docs/README.md` 的 `schema_version`：
    - 无字段或 < 当前版本 → **场景 B2：版本升级**
    - = 当前版本 → **场景 C：已就绪**

当前 schema 版本：**2**

### 场景 A：新建

**a. 项目探测**

读取 `CLAUDE.md`、`README.md`、顶层目录结构、配置文件（`pyproject.toml`、`setup.py`、`package.json`），推断项目类型和名称。

**b. 创建目录结构**

始终创建：`project/`、`handoffs/`、`handoffs/resolved/`、`archive/deprecated/`
按需创建（检测到对应代码时）：`data/`、`methods/`、`evaluation/`

**c. 生成文档骨架**

每个文档使用 frontmatter（`updated`、`status: draft`、`scope`）：

- `docs/README.md`：索引 + 阅读顺序 + archive 说明。frontmatter 含 `schema_version: 2`
- `docs/project/overview.md`：纯 dashboard（状态、进度、链接，不放结论/叙事）
- `docs/project/paper-plan.md`：论文规划骨架（定位、贡献 C1-Cn、叙事弧、章节结构、图表计划、时间线）
- 其他按需创建的目录下放 `status: draft` 骨架文件

**d. 执行 [P4: CLAUDE.md 同步]**（sync_type=`doc-section`）

### 场景 B：迁移（遗留结构 / 版本升级）

**a. 生成迁移计划**

根据 `[P2]` 的发现，生成具体操作列表：
- 目录重命名（`01-project/` → `project/`）
- 文件重命名（`PROJECT_OVERVIEW.md` → `overview.md`）
- handoff 目录合并（`handoff/` + `05-handoff/` → `handoffs/`）
- 版本后缀文件归档（`scope_v3.md` → `archive/deprecated/`）
- 非标准 archive 统一（`99-archive/` → `archive/`）
- 补建缺失的标准目录

展示计划给用户，**等待确认**（使用 `AskUserQuestion`）。

**b. 执行迁移**

用户确认后：
- 使用 `git mv` 执行重命名（保留 git 历史）
- 补建缺失目录
- 在 `docs/README.md` frontmatter 中写入 `schema_version: 2`

**c. 执行 [P3: README 索引同步]**
**d. 执行 [P4: CLAUDE.md 同步]**（sync_type=`doc-section`）

### 场景 B2：版本升级

轻量迁移：
1. 补建 v2 新增的标准目录（如有）
2. 在 `docs/README.md` frontmatter 中写入 `schema_version: 2`
3. 执行 `[P3: README 索引同步]`

### 场景 C：已就绪

输出：`docs/ 已是 schema v2，无需操作。运行 /docs status 查看文档健康状态。`

---

## Phase: Update

`/docs update [results|methods|project]`

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

如果无参数更新时发现文档内容已完全过时（对应的代码/实验已不存在），提示用户是否归档：
- 列出候选文件
- 用户确认后 `git mv` 到 `archive/deprecated/`

**4. 执行 [P3: README 索引同步]**
**5. 执行 [P4: CLAUDE.md 同步]**（sync_type 按更新类别选择：`findings` / `project`）

---

## Phase: Archive

`/docs archive <file>`

单文件归档，不再支持 `archive stale`（该功能已并入 update）。

1. 验证文件存在于 `docs/` 下（不含 `archive/`）
2. `git mv <file> docs/archive/deprecated/`
3. 执行 `[P3: README 索引同步]`

---

## Phase: Handoff

**1. 定位 handoff 目录**

按优先级探测：`docs/handoffs` > `docs/05-handoff` > `docs/handoff`。
找到后使用该目录；都不存在则创建 `docs/handoffs/` 和 `docs/handoffs/resolved/`。

如果使用的是非标准目录（`05-handoff`、`handoff`），在输出末尾提示用户运行 `/docs init` 迁移。

**2. 回顾活跃 handoff**

读取 handoff 目录下所有 `*.md`（排除 `resolved/`）。对每个文件：
- 读取"下一步"部分
- 对比 `git log --oneline -20` 和当前项目状态
- 如果所有 todo 已完成：更新 frontmatter `status: resolved`，`git mv` 到 `resolved/`

**3. 执行 [P5: Session 素材收集]**

**4. 执行 [P1: 写前提交]**

**5. 生成 handoff 文件**

文件名：`$HANDOFF_DIR/YYYY-MM-DD-HHMM-{slug}.md`

```markdown
---
updated: YYYY-MM-DD
status: active
scope: session 交接
---

## 已完成
<本次 session 完成的工作，具体到文件和函数>

## 当前状态
<项目整体状态快照>

## 关键决策
<本次做出的重要决策及理由>

## 下一步
<祈使句格式：读 X → 运行 Y → 做 Z>

## 注意事项
<陷阱、未解决的问题、临时方案>
```

**6. 执行 [P4: CLAUDE.md 同步]**（sync_type=`handoff`）

**7. 输出**

把 handoff 内容输出给用户确认。如有 resolved 的旧 handoff，一并报告。

---

## Phase: Log

`/docs log [YYYY-MM-DD]`

**1. 确定日期**

有参数 → 使用指定日期；无参数 → 使用今天日期。

**2. 执行 [P5: Session 素材收集]**

**3. 读取已有日志**

如果 `docs/journal/YYYY-MM-DD-devlog.md` 已存在，读取内容避免重复。

**4. 执行 [P1: 写前提交]**

**5. 写入文件**

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

**6. 输出**

把写入的日志内容输出给用户确认。

---

## Phase: Aris

详细流程见 `${CLAUDE_SKILL_DIR}/references/aris.md`。读取该文件后按其中步骤执行。

索引更新步骤（原 step h）改为：执行 `[P3: README 索引同步]` + 更新 `docs/aris/README.md`。
