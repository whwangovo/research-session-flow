# Phase: Handoff

每次跑 `/research handoff` 都执行固定流程：resolve 已完成的历史 handoff → 新建当前 handoff。不区分 session。

共享流程 `[P2]`-`[P5]` 的定义见 SKILL.md `## 共享流程`。

---

**1. 定位 handoff 目录**

按优先级探测：`docs/handoffs` > `docs/05-handoff` > `docs/handoff`。都不存在则创建 `docs/handoffs/` 和 `docs/handoffs/resolved/`。

使用非标准目录时，在输出末尾提示用户运行 `/research init` 迁移。

**2. 扫描活跃 handoff，resolve 已完成的**

读取 handoff 目录下所有 `*.md`（排除 `resolved/`）。对每个文件读"下一步"，对比本次 session 对话上下文判断 todo 是否全部完成：

- 全部完成 → 更新 frontmatter `status: resolved`，整体 `mv` 到 `resolved/`
- 有未完成项 → 不动

**3. 执行 [P5: Session 素材收集]**

**4. 新建当前 handoff**

文件路径：`$HANDOFF_DIR/YYYY-MM-DD-HHMM-{slug}.md`，slug 来自本 session 主题。

**frontmatter 模板**：

```yaml
---
updated: YYYY-MM-DD
status: active
scope: session 交接
---
```

**正文模板**：

```markdown
## 已完成
<具体到文件和函数>

## 当前状态
<项目整体状态快照>

## 关键决策
<本 session 做出的重要决策及理由>

## 下一步
<祈使句：读 X → 运行 Y → 做 Z>

## 注意事项
<陷阱、未解决的问题、临时方案>
```

**5. 执行 [P4: CLAUDE.md 同步]**（sync_type=`handoff`）

**6. 输出**

把 handoff 内容输出给用户确认。如有 resolved 的旧 handoff，一并报告。
