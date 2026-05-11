# Phase: Log

`/research log [YYYY-MM-DD]`

共享流程 `[P2]`-`[P5]` 的定义见 SKILL.md `## 共享流程`。

---

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
