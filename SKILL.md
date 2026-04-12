---
name: docs
description: "为科研/论文项目生成、更新、归档文档。支持 init/update/status/archive/handoff/migrate/log/aris 子命令。强制单一来源原则：实验数字→results.md，方法→methods/，论文叙事→paper-plan.md。适用于 ML/AI 研究、论文写作、实验管理场景，不适用于前后端工程项目（见 fullstack-docs）。"
argument-hint: "[init|update|status|archive|handoff|migrate|log|aris] [topic|file]"
allowed-tools: Bash(*), Read, Write, Edit, Grep, Glob, Agent
file-patterns:
  - "docs/**/*.md"
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
├── README.md                    # 索引、阅读顺序、文档健康摘要
├── project/                     # 项目状态 + 论文规划（各一个文件，见下方设计原则）
│   ├── overview.md              # 纯 dashboard：快照、工作进度、文档入口（不放结论/叙事）
│   └── paper-plan.md            # 论文唯一规划文件：叙事、章节 scope、图表、时间线、审稿策略
├── data/                        # 数据规范、schema、标注指南（数据密集型项目）
├── methods/                     # 方法设计、框架、消融设计
├── evaluation/                  # 评测协议、结果、分析
│   └── results.md               # 所有实验数字的唯一权威来源
├── handoffs/                    # 交接文档（唯一位置）
│   └── YYYY-MM-DD-HHMM-slug.md
├── journal/                     # 每日开发日志（唯一位置）
│   └── YYYY-MM-DD-devlog.md
├── aris/                        # ARIS skills 产出的中文翻译版（唯一位置）
│   ├── ideas/                   # 想法报告
│   ├── narrative/               # 研究叙事
│   ├── planning/                # 论文规划
│   ├── experiments/             # 实验日志
│   ├── reviews/                 # 审稿记录
│   ├── methods/                 # 方法迭代
│   ├── wiki/                    # research-wiki 中文版
│   ├── paper/                   # 论文中文翻译版
│   ├── findings/                # 研究发现
│   ├── ingest-log.md            # aris 操作日志
│   └── README.md                # aris 子目录索引
├── deliverables/                # 正式交付物（可选，按需创建）
└── archive/                     # 归档（唯一位置）
    ├── YYYY-MM-DD/              # 批量归档（重构/方向变更）
    │   ├── _reason.md
    │   └── ...
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
- 违反此原则会导致数字不一致（如 CoT delta 在不同文件里出现 +0.4pp 和 +0.6pp 的分歧）

**文档 frontmatter**（每个文档顶部）：
```yaml
---
updated: YYYY-MM-DD
status: active        # active | draft | stale | archived
scope: 本文档覆盖什么
out-of-scope: 本文档不覆盖什么
---
```

**语言**：中文为主，英文技术术语保留。

---

## 子命令路由

根据 `$ARGUMENTS` 的第一个词路由到对应流程：

- `init` → Phase: Init
- `update` → Phase: Update
- `status` → Phase: Status（默认，无参数时也执行）
- `archive` → Phase: Archive
- `handoff` → Phase: Handoff
- `migrate` → Phase: Migrate
- `log` → Phase: Log
- `aris` → Phase: Aris
- 无参数 → Phase: Status

---

## Phase: Status

**目标**：输出文档健康报告，帮助用户在开始工作前了解文档现状。

### 步骤

1. **检测 docs/ 是否存在**
   - 不存在 → 提示用户运行 `/docs init`，结束

2. **扫描所有 .md 文件**（排除 archive/）
   - 读取每个文件的 frontmatter（`updated`, `status`）
   - 如果没有 frontmatter，从文件内容推断最后更新日期（查找 `最后更新` / `last updated` 等标记）
   - 计算距今天数（今天日期从系统获取：`date +%Y-%m-%d`）
   - 包含 `docs/aris/` 子目录下的文件（检查翻译文档的时效性）

3. **检测旧结构问题**（如果存在）：
   - 数字前缀目录（`01-project/`, `02-data/` 等）
   - SCREAMING_CASE 文件（`PROJECT_OVERVIEW.md`）
   - 重复 handoff 目录（`handoff/` 和 `handoffs/` 同时存在，或 `05-handoff/` 和 `handoffs/`）
   - 文件名版本后缀（`scope_v3.md`）
   - 归档目录不统一（`99-archive/`, `deprecated/` 在根目录等）

4. **输出报告**，格式如下：

```
## docs 健康报告 — {项目名} ({今天日期})

### 活跃文档
| 文件 | 上次更新 | 状态 |
|------|---------|------|
| project/overview.md | 2026-04-01 (5天前) | ✅ active |
| evaluation/results.md | 2026-03-01 (36天前) | ⚠️ stale |

### 结构问题
- ⚠️ 检测到重复 handoff 目录：`05-handoff/` 和 `handoffs/`，建议运行 `/docs migrate`
- ⚠️ 检测到文件名版本后缀：`SCOPE_v3.md`

### 摘要
- 活跃文档：X 个，其中 Y 个 stale（>30天未更新）
- 建议：[具体建议]
```

---

## Phase: Init

**目标**：为新项目初始化标准文档结构。

### 步骤

1. **检测是否已有 docs/**
   - 已有且非空 → 提示用户使用 `/docs migrate` 迁移旧结构，不要覆盖

2. **读取项目信息**：
   - `CLAUDE.md`（项目概述、pipeline、目标 venue）
   - `README.md`（项目简介）
   - 代码目录结构（`ls` 或 Glob 扫描顶层目录）
   - `pyproject.toml` / `setup.py` / `package.json`（如有）

3. **推断项目类型**，决定需要哪些子目录：
   - 有数据处理代码 → 创建 `data/`
   - 有模型/方法代码 → 创建 `methods/`
   - 有评测代码 → 创建 `evaluation/`
   - 始终创建：`project/`, `handoffs/`, `archive/deprecated/`

4. **创建目录结构**（`mkdir -p`）

5. **生成初始文档**，每个文档包含 frontmatter + 骨架内容：

   **`docs/README.md`**：
   ```markdown
   ---
   updated: {今天}
   status: active
   ---
   # {项目名} Docs

   ## 目录结构
   | 路径 | 职责 |
   |------|------|
   | `project/overview.md` | 项目状态 dashboard：快照、工作进度、文档入口（不放结论/叙事） |
   | `project/paper-plan.md` | 论文唯一规划文件：叙事、章节 scope、图表、时间线、审稿策略 |
   ...

   ## 推荐阅读顺序
   1. [项目总览](project/overview.md)
   ...

   ## 归档说明
   - `archive/deprecated/`：单个废弃文件
   - `archive/YYYY-MM-DD/`：批量归档（含 `_reason.md` 说明原因）
   ```

   **`docs/project/overview.md`**：纯 dashboard。根据 CLAUDE.md 内容生成，包含项目快照表、工作状态矩阵、文档入口链接。**不放**实验结论（链接到 results.md）、**不放**论文叙事（链接到 paper-plan.md）。

   **`docs/project/paper-plan.md`**：论文规划骨架。包含论文定位、核心贡献（C1-Cn）、叙事主线、章节结构（每节 scope + 引用来源）、图表计划、时间线。章节 scope 里引用 results.md 和 methods/ 获取数字和方法定义，不嵌入具体数字。

   **其他文档**：生成带 frontmatter 的骨架，标注 `status: draft`。

6. **输出**：列出创建的文件，提示下一步（填充内容或运行 `/docs update`）

---

## Phase: Update

**目标**：更新文档内容，使其与项目当前状态一致。

参数解析：
- `/docs update` → 更新所有 stale 文档
- `/docs update results` → 只更新 evaluation/ 下的文档
- `/docs update methods` → 只更新 methods/ 下的文档
- `/docs update project` → 只更新 project/ 下的文档

### 步骤

1. **确定更新范围**（根据参数）

2. **对每个目标文档**：
   a. 读取当前文档内容
   b. 读取相关代码/数据文件（根据文档类型判断）：
      - `evaluation/results.md` → 读取实验输出目录、结果文件
      - `methods/*.md` → 读取对应的 pipeline 代码
      - `project/overview.md` → 读取 CLAUDE.md、git log（最近 10 条）；只更新状态/进度，不引入实验数字
      - `project/paper-plan.md` → 读取 CLAUDE.md、results.md 的结论摘要；章节 scope 里用链接引用数字，不硬编码
   c. 对比文档内容与实际状态，找出过期信息
   d. 更新文档内容（保留结构，只更新过期部分）
   e. **单一来源检查**：如果更新后的文档包含硬编码实验数字（pass rate、delta pp 等），将其替换为对 results.md 的链接引用
   f. 更新 frontmatter 的 `updated` 日期，`status` 改为 `active`

3. **更新 `docs/README.md`** 的索引表（确保路径和描述准确）

4. **输出**：列出更新了哪些文件，每个文件改了什么

---

## Phase: Archive

**目标**：将文档移入归档区。

参数解析：
- `/docs archive stale` → 归档所有 stale 文档
- `/docs archive docs/methods/old-method.md` → 归档指定文件
- `/docs archive 2026-04-06 "方向调整，放弃 X 路线"` → 批量归档到日期目录

### 步骤

**单文件归档**（`archive <file>`）：
1. 确认文件存在
2. 目标路径：`docs/archive/deprecated/{filename}`
3. 用 `git mv`（如果是 git 仓库）或普通 `mv`
4. 更新 `docs/README.md`，从索引中移除该文件
5. 输出确认

**批量归档 stale**（`archive stale`）：
1. 运行 Status 扫描，找出所有 stale 文档
2. 列出将要归档的文件，**等待用户确认**
3. 确认后，逐个 `git mv` 到 `docs/archive/deprecated/`
4. 更新 README.md

**批量归档到日期目录**（`archive YYYY-MM-DD "reason"`）：
1. 创建 `docs/archive/YYYY-MM-DD/`
2. 询问用户要归档哪些文件（或接受文件列表参数）
3. 移动文件
4. 生成 `docs/archive/YYYY-MM-DD/_reason.md`：
   ```markdown
   # 归档原因

   日期：YYYY-MM-DD
   原因：{reason}

   ## 归档文件
   - {file1}：原路径 {original_path}
   - ...
   ```
5. 更新 README.md

---

## Phase: Handoff

**目标**：在 session 结束时生成交接文档。

### 步骤

1. **获取时间戳**：`date +%Y-%m-%d-%H%M`

2. **重建 session 内容**（主要来源）：从对话历史重建，不要让用户自己总结。关注：
   - 读取、编辑或创建了哪些文件
   - 运行了哪些命令及其结果
   - 遇到了什么问题、如何解决的
   - 用户说想要什么 vs 实际交付了什么

   具体胜于模糊："修复了登录 bug" 没用，"修复了 `auth/middleware.ts:42` JWT 过期未检查" 才有用。

3. **读取 git 信息**（补充来源，如果是 git 仓库）：
   ```bash
   git log --oneline -10
   git diff HEAD~3..HEAD --stat
   ```
   用于补充 session 内容遗漏的变更，或验证文件路径准确性。

4. **读取当前项目状态**（补充来源）：
   - `docs/evaluation/results.md`（如有）
   - `docs/project/overview.md`
   - 最近修改的文件（`git status`）

5. **生成 slug**：从 session 主题提取 2-4 个关键词，用 `-` 连接（中文转拼音首字母或用英文关键词）。如果 session 主题不明确，从 git log 最近提交信息提取。

6. **Git commit（写文档前）**：在生成交接文档之前，先提交当前工作区的改动：
   ```bash
   git diff --cached --quiet && git diff --quiet || (
     git add -A
     git commit -m "<根据 git diff 自动生成的 message>"
   )
   ```
   message 生成规则：读取 `git diff HEAD`，根据实际改动生成 `<type>: <summary>`，type 从 feat/fix/refactor/chore/test 中选最合适的。没有未提交改动则跳过。

7. **生成 `docs/handoffs/YYYY-MM-DD-HHMM-{slug}.md`**：

```markdown
---
updated: YYYY-MM-DD
status: active
---
# Handoff: {slug} — {YYYY-MM-DD HH:MM}

## 完成了什么

{根据 git log 和文件变更总结}

## 当前状态

{项目当前状态，关键指标，未解决的问题}

## 关键决策

{本次 session 做出的重要决策，以及原因}

## 下一步

{具体的下一步行动，包含命令或文件路径}

## 注意事项

{需要特别注意的坑、依赖、环境问题等}
```

8. **输出**：文件路径 + 内容预览

---

## Phase: Migrate

**目标**：将旧结构迁移到标准结构。

### 步骤

1. **检测旧结构**（运行 Status 的结构检测部分）

2. **生成迁移计划**（只输出计划，不执行）：

```
## 迁移计划

### 目录重命名
- `01-project/` → `project/`
- `02-data/` → `data/`
- `03-methods/` → `methods/`
- `04-evaluation/` → `evaluation/`

### 文件重命名
- `PROJECT_OVERVIEW.md` → `project/overview.md`
- `SCOPE.md` → `project/scope.md`
- `SCOPE_v3.md` → archive/deprecated/SCOPE_v3.md（旧版本归档）

### handoff 目录合并
- `05-handoff/*.md` → `handoffs/`（保留文件名）
- `handoff/*.md` → `handoffs/`（保留文件名）
- 删除空目录 `05-handoff/`, `handoff/`

### 归档目录统一
- `99-archive/` → `archive/`
- `deprecated/`（根目录）→ `archive/deprecated/`

### CLAUDE.md 路径更新
- 更新所有对旧路径的引用

共 X 个文件移动，Y 个文件重命名。
```

3. **等待用户确认**（`AskUserQuestion`：是否执行迁移？）

4. **执行迁移**（用户确认后）：
   - 优先用 `git mv`（保留历史）
   - 创建新目录
   - 移动文件
   - 更新 CLAUDE.md 中的路径引用（用 Edit 工具）
   - 生成新的 `docs/README.md`
   - 为旧归档目录生成 `archive/YYYY-MM-DD/_reason.md`（说明这是迁移前的快照）

5. **输出**：迁移完成摘要，提示运行 `/docs status` 验证

---

## CLAUDE.md 同步

CLAUDE.md 是给 Claude 的操作指南，保持精简。各命令触发的同步范围：

| 命令 | 同步内容 |
|------|---------|
| `init` | 新增 `## Documentation` 节（如不存在），写入 docs 路径索引 |
| `update` / `update results` | 更新 `Core finding` 和 `Paper narrative` 行 |
| `update project` | 更新 `Project Overview` 摘要段 |
| `migrate` | 更新 `## Documentation` 节中的路径引用 |
| `status` / `archive` / `handoff` / `log` | 不修改 CLAUDE.md |

**同步规则**：
- 只更新，不重写——用 Edit 精确替换对应字段，不动其他内容
- 内容来源：从 `docs/project/overview.md` 或 `docs/evaluation/results.md` 提取摘要，压缩成 1-2 行
- 不降级：如果 CLAUDE.md 里的字段比 docs 更新，保留 CLAUDE.md 的版本
- 不同步：pipeline 命令、架构描述、API 配置——这些是稳定的操作配置

**init 时新增的 Documentation 节模板**：
```markdown
## Documentation
Project docs at `docs/` — see `docs/README.md` for index.
Key files: `docs/project/overview.md` (status), `docs/evaluation/results.md` (results).
```

---

## Phase: Log

**目标**：将今天的开发进展写入 `docs/journal/YYYY-MM-DD-devlog.md`，每天一个文件。

**触发词**：用户说"写日志"、"记日志"、"log"、"开发日志"、`/docs log`。

### 步骤

**a. 确定日志日期**

```python
from datetime import datetime, timedelta
now = datetime.now()
# 中午 12:00 之前算前一天（熬夜场景）
log_date = now.date() if now.hour >= 12 else now.date() - timedelta(days=1)
log_file = f"docs/journal/{log_date}-devlog.md"
```

**b. 收集素材**

按优先级读取以下来源（有什么读什么，不强求全部存在）：

1. 对话上下文：当前 session 里用户提到的工作内容（主要来源）
2. 对应日期的 handoff 文档：`docs/handoffs/` 下文件名以 `log_date` 开头的文件（补充细节）
3. 对应日期的 git commits：`git log --oneline --after="<log_date> 00:00" --before="<log_date+1> 00:00" --format="%h %s"`（补充遗漏变更；熬夜场景下跨天，需同时查 log_date 和 log_date+1）

**c. 生成日志内容**

风格要求：
- **第一人称，口语化**，像工程师写给自己看的笔记，不是正式报告
- **有血有肉**：说清楚做了什么、为什么、遇到了什么问题、怎么解决的
- **不流水账**：不要逐条列 commit，要有叙事线
- **结尾可选**：如果有明确的下一步，加一句"明天："
- 长度：150-300 字，不强求，内容决定长度

**d. Git commit（写文档前）**

在写日志文件之前，先提交当前工作区的改动：

```bash
git diff --cached --quiet && git diff --quiet || (
  git add -A
  git commit -m "<根据 git diff 自动生成的 message，反映实际代码/配置改动>"
)
```

message 生成规则：
- 读取 `git diff HEAD`，根据改动内容生成一句话 commit message
- 格式：`<type>: <summary>`，type 从 feat/fix/refactor/chore/test 中选最合适的
- 如果没有未提交改动，跳过此步

**e. 写入文件**

- 目录：`docs/journal/`（不存在则创建）
- 文件名：`YYYY-MM-DD-devlog.md`（用 log_date，不是当前时间）
- 如果文件**不存在**：创建新文件，使用下方模板
- 如果文件**已存在**（同一天第二次调用）：在文件末尾追加新内容，用 `---` 分隔

**f. 输出**

把写入的日志内容输出给用户确认，不需要额外说明。

### 单日文件模板（首次创建时使用）

```markdown
---
date: YYYY-MM-DD
---

<正文>

明天：<下一步>（可选）
```

### 同天追加格式

```markdown
（原有内容）

---

<追加内容>
```

---

## Phase: Aris

详细流程见 `${CLAUDE_SKILL_DIR}/references/aris.md`。读取该文件后按其中步骤执行。
