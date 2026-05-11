# Phase: Init

`/research init [<project-name>]`

一条命令覆盖从"空目录冷启动"到"已有项目结构迁移/版本升级"的全部路径，幂等，可反复跑。

共享流程 `[P2]`-`[P5]` 的定义见 SKILL.md `## 共享流程`。

---

**1. 判断场景**

- `docs/` 不存在 → **场景 A：新建**（完整冷启动）
- `docs/` 存在，执行 `[P2: 旧结构探测]`：
  - `LEGACY_DETECTED` → **场景 B：迁移**
  - 否则，读取 `docs/README.md` 的 `schema_version`：
    - 无字段或 < 当前版本 → **场景 B2：版本升级**
    - = 当前版本 → **场景 C：已就绪**

当前 schema 版本：**3**

## 场景 A：新建（完整冷启动）

**a. 项目信息**

- 项目名：`$ARGUMENTS` 第二个 token（如 `/research init my-paper`） > `basename $PWD`
- 描述：不问，用 placeholder `"科研项目"`，用户进去自己改 README / CLAUDE.md
- 读取 `CLAUDE.md`、`README.md`、顶层目录、配置文件（`pyproject.toml`、`setup.py`、`package.json`），用于按需创建子目录

**b. git 初始化**

- 有 `.git/` → 跳过
- 无 `.git/` → `git init -b main`

**c. 根 `.gitignore`（幂等）**

**原则**：默认本地化。gitignore 的逻辑是"哪些内容需要跟协作者共享"，而不是"哪些要排除"——默认全部本地，要共享的用 `!` 白名单单独豁免。

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

## 场景 B：迁移（遗留结构 / 版本升级）

**a. 生成迁移计划**

根据 `[P2]` 的发现，生成具体操作列表（仅限可自动迁移项）：
- 目录重命名（`01-project/` → `project/`）
- 文件重命名（`PROJECT_OVERVIEW.md` → `overview.md`）
- handoff 目录合并（`handoff/` + `05-handoff/` → `handoffs/`）
- 补建缺失的标准目录（含 v3 新增：`docs/dashboards/`、`archive/docs/`、`scratch/`）

展示计划给用户，**等待确认**（使用 `AskUserQuestion`）。

**b. 执行迁移**

用户确认后：
- 使用 `git mv` 执行重命名（保留 git 历史）
- 补建缺失目录（含 v3 新增：`docs/dashboards/`、`archive/docs/`、`scratch/`）
- 更新 `.gitignore`（参照场景 A.c）
- 在 `docs/README.md` frontmatter 中写入 `schema_version: 3`

**c. 执行 [P3: README 索引同步]**
**d. 执行 [P4: CLAUDE.md 同步]**（sync_type=`doc-section`）

## 场景 B2：版本升级

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

## 场景 C：已就绪

输出：`docs/ 已是 schema v3，无需操作。运行 /research status 查看文档健康状态。`
