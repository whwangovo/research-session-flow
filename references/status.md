# Phase: Status

**默认子命令**（无参数时执行）。

共享流程 `[P2]`-`[P5]` 的定义见 SKILL.md `## 共享流程`。

---

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
