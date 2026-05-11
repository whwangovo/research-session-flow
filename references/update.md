# Phase: Update

`/research update [results|methods|project]`

共享流程 `[P2]`-`[P5]` 的定义见 SKILL.md `## 共享流程`。

---

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

**4. 执行 [P3: README 索引同步]**
**5. 执行 [P4: CLAUDE.md 同步]**（sync_type 按更新类别选择：`findings` / `project`）
