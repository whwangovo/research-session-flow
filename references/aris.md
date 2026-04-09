# Phase: Aris

**目标**：扫描 ARIS skills 产出的英文文档，翻译为中文，归档到 `docs/aris/` 统一管理。

**参数**：`/docs aris [--dry-run]`

## ARIS 产出路径注册表

| 扫描位置 | 目标文件 | 归入 `docs/aris/` 子目录 |
|---------|---------|------------------------|
| 项目根 | `IDEA_REPORT.md`, `IDEA_CANDIDATES.md` | `ideas/` |
| 项目根 | `NARRATIVE_REPORT.md`, `STORY.md` | `narrative/` |
| 项目根 | `PAPER_PLAN.md`, `refine-logs/FINAL_PROPOSAL.md` | `planning/` |
| 项目根 + `refine-logs/` | `EXPERIMENT_LOG.md`, `EXPERIMENT_TRACKER.md`, `EXPERIMENT_PLAN.md`, `CLAIMS_FROM_RESULTS.md` | `experiments/` |
| 项目根 + `refine-logs/` | `AUTO_REVIEW.md`, `REVIEW_SUMMARY.md` | `reviews/` |
| `refine-logs/` | `REFINEMENT_REPORT.md` | `methods/` |
| `research-wiki/` | `papers/`, `ideas/`, `gap_map.md`, `index.md` 等 | `wiki/` |
| `paper/` | `sections/*.tex` 内容 | `paper/` |
| 项目根 | `findings.md` | `findings/` |

**跳过的文件**（运行时状态，不属于文档）：
- `REFINE_STATE.json`、`REVIEW_STATE.json`
- `paper/` 原始 LaTeX 文件（保持原位不动，仅翻译内容到 `docs/aris/paper/`）
- `figures/`（与 paper 编译绑定，保持原位）

## 执行流程

**a. 扫描**

按注册表扫描所有已知路径，收集存在的 ARIS 产出文件列表。

如果使用 `--dry-run`，输出将要处理的文件列表和目标路径，不执行任何写入，然后结束。

**b. 翻译**

逐个读取文件内容，将英文翻译为中文：
- 保留专业术语原文标注，格式：`中文术语(English Term)`，如 "注意力机制(attention mechanism)"
- 保留表格、代码块、公式等结构化内容的格式
- 对 `paper/sections/*.tex`：提取正文内容翻译为中文 markdown，忽略 LaTeX 排版命令

**c. 写入**

在 `docs/aris/` 对应子目录下创建中文版文件：
- 文件名格式：`YYYY-MM-DD-HHMM-slug.md`（与 handoff 命名规范一致）
- slug 为原文件名的简短描述，如 `IDEA_REPORT.md` → `2026-04-09-1530-想法报告.md`
- 每个文件添加 frontmatter：

```yaml
---
updated: YYYY-MM-DD
status: active
scope: ARIS 产出翻译
source: aris
ingested: YYYY-MM-DD HH:MM
original_path: 原始文件相对路径
translated: true
---
```

- 已有同名内容时：生成新的带时间戳文件，不覆盖旧版
- 按需创建子目录（如 `docs/aris/ideas/` 不存在则创建）

**d. 清理**

将项目根目录散落的 ARIS 产出文件（不含 `refine-logs/`、`research-wiki/`、`paper/` 目录）移入 `docs/archive/aris-raw/`，保留原始英文版备查。

**e. 日志**

在 `docs/aris/ingest-log.md` 追加本次操作记录：

```markdown
## YYYY-MM-DD HH:MM

处理文件：
- IDEA_REPORT.md → docs/aris/ideas/YYYY-MM-DD-HHMM-想法报告.md
- AUTO_REVIEW.md → docs/aris/reviews/YYYY-MM-DD-HHMM-审稿记录.md
- ...
```

**f. 更新索引**

- 更新 `docs/aris/README.md`：列出所有子目录及其中的文件
- 更新 `docs/README.md`：确保包含 `aris/` 目录的引用条目

**g. 输出**

输出本次处理的文件列表和目标路径，供用户确认。
