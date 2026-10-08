# AGENTS.md — OB_Note Vault

本目录是 Obsidian 知识库根目录（vault）。

> **通用规范不写在这里。** 笔记骨架、写作风格、实验报告措辞、index/log 格式、ingest/query/lint
> 操作，全部见 skill **`obsidian-notes`**。本文档只记录**本 vault 的本地事实**。

## 目录结构

| 路径 | 内容 |
| --- | --- |
| `C++/` `DB/` `DIP/` `ML/` `FA/` `CN/` `Python/` `算法设计/` | 各学科笔记，按章节一篇 |
| `db Lab/` | 数据库实验课章节笔记 |
| `<学科>/Source/` | 该学科课件的图片附件（**只读，勿改**） |
| `Source/` | vault 级原始资料（**只读**） |
| `归档/` | 历史内容，不纳入索引 |
| `templates/` | `Header Index.md`（目录 TOC 模板）、`repo-cover.md`（实验报告封面模板） |
| `index.md` | 内容索引，按学科分区 |
| `log.md` | 操作日志，只追加 |
| `LLM Wiki.md` | 知识库方法论原文 |

## 本 vault 的约定

- **学科分区名以 `index.md` 现有写法为准**。新增学科时记得补建 `## 📁` 分区——
  历史上多次漏建（如 CN 学科曾整块缺失），这是最高频的失误。
- **实验报告封面**用 `templates/repo-cover.md`：班级「计科1班」、姓名「韩宇」、学号「24319050」。
- **图片**放对应学科的 `Source/` 下，用 `![[image.png]]` 嵌入。
- **不纳入索引**：作业文件（文件名含 `作业` / `Lab` / `Report` / `实验`）、`Source/`、`归档/`。
- 笔记 frontmatter 字段固定为 `tags` / `课程` / `章节` / `教材`，**不要引入英文别名**，否则 Dataview 查不全。

## 维护入口

新增或修改笔记后，按 skill `obsidian-notes` 的 `references/vault-maintenance.md` 回填：

- `index.md` —— 条目、最后更新日期、笔记总数
- `log.md` —— 追加一条 `## [日期] ingest | 描述`

---

_本文件与 `CLAUDE.md` 是同一份文件的硬链接（内容始终一致，改任一即改另一个）。_
