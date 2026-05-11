# Phase: Handoff

**核心约束**：handoff 是 session 粒度的 immutable append-only 日志。

- **同 session 内**多次跑 `/research handoff` → **原地更新**当前 session 的那一个文件（重写 5 段内容反映迄今所有工作）
- **跨 session** → 别人 session 的 handoff 内容**只读**，当前 session 唯一能做的事是"整体 mv 到 `resolved/`"（当下一步在本 session 里完成时）
- **禁止**：修改别人 session 的 handoff 文件内容；合并不同 session 的 handoff；删除 handoff（只能 resolve）

实现上靠 frontmatter `session_id` 字段区分同/跨 session。

共享流程 `[P2]`-`[P5]` 的定义见 SKILL.md `## 共享流程`。

---

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
