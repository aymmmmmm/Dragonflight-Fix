# 文档维护规范

本文件定义 `Dragonflight-Fix/docs/` 下文档的写作、同步、归档约定。所有维护者（含 AI）必须遵守。

---

## 一、核心原则：事实源 = 代码

文档是代码的镜像，不是设想的蓝图。

- 每一条 API 名、函数名、文件路径、行号、坐标、SavedVariables 名、配置项 key，**都必须能在当前源码里查到对应**。
- 查不到对应实现的论断，标注 **「待实证」**，绝不臆造接口。
- 项目记忆（memory）条目反映的是**写入时**状态。引用记忆里命名的文件 / 函数 / flag 前，必须先在当前代码复核其仍然存在。
- 行号、行数会随代码改动漂移。引用时优先用「函数名 + 文件路径」定位，行号仅作辅助，发现不符立即更新或改标注。

### WoW 1.12 / Lua 5.0 约束（写代码示例时遵守）

- 取长度用 `table.getn(tbl)`，**不能用 `#tbl`**（5.0 无长度操作符，`#` 会让整文件不加载）。
- 缺失大量 retail Texture API（`SetAtlas` / `SetHorizTile` / `SetVertTile` 等），复刻时改用 `SetTexCoord` + 拉伸。文档示例不得出现这些不存在的 API。
- 没有 `io` / `os` / `require`，用 WoW 专属全局函数。

---

## 二、改代码 ↔ 改文档 同步检查清单

### 每次改某模块代码

- [ ] 该模块是否有关联设计 / 进度 / 调试文档？有则同步更新（函数名、路径、行为描述、已知问题状态）。
- [ ] 改动涉及的 API / 配置项 / SavedVariables 名，文档里的引用是否还准确？
- [ ] 修复了文档「已知问题 / 待实证」里的某项？把它从「未解决」挪到「已解决」并写明根因与方案。
- [ ] 改了 UI 文字？同步 zhCN 本地化（铁律），并在相关文档体现。

### 每个 Phase / 大功能完成

- [ ] 更新 `dragonflight-fix-work-plan.md`：把对应任务标 ✅，补「说明」列（落地文件 + 行为）。
- [ ] 新增模块 / 文件入 `.toc` 了吗？work-plan 里注明「已入 .toc」或「⚠️ 磁盘存在但未入 .toc（未参与运行）」——两者运行后果不同，必须区分。
- [ ] 新功能是否需要新建设计 / 进度文档？建后在 work-plan 的「参考文档」段补链接。

### 提交前自检

- [ ] 文档里新出现的每条事实，是否都在代码里查证过（或标了「待实证」）？
- [ ] 全中文，沿用既有术语与风格，简明扼要不灌水。

---

## 三、文档分类约定

按文档用途归类，命名沿用既有模式 `<模块>-<类别>.md`：

| 类别 | 后缀 / 关键词 | 内容 | 范例 |
|------|--------------|------|------|
| **对比** | `-comparison` | 与 DF3 / DFRL / retail 等参照物的差异分析 | `dragonflight-comparison.md`、`dfui-vs-df3-comparison.md`、`spellbook-comparison.md` |
| **设计** | `-design` | 模块设计方案、架构、纹理 / 布局规范 | `panel-skinning-design.md`、`unit-frames-design.md`、`social-panel-design.md` |
| **进度** | `-progress`、`work-plan`、`execution-plan` | 任务清单、完成状态、阶段计划 | `dragonflight-fix-work-plan.md`、`panel-skinning-progress.md`、`loot-module-progress.md` |
| **调试** | `-debug`、`-problem`、`-issues`、`-analysis` | 具体 bug 排查、根因定位、布局分析、已知问题 | `profession-panel-debug.md`、`spellbook-inner-border-problem.md`、`panel-known-issues.md` |
| **参考** | `-overview`、`factory-functions`、`*-system` 等 | 工厂函数、配置系统、模块总览等可复用速查 | `modules-overview.md`、`factory-functions.md`、`config-system.md` |

约定：
- 同一模块允许多类文档并存（如 `spellbook-*` 有 comparison / layout-analysis / inner-border-problem）。
- 跨模块的总索引 / 计划信息集中在 `dragonflight-fix-work-plan.md`，新文档建好后在其「参考文档」段挂链接。

---

## 四、归档约定

文档被新文档取代后，**移入 `_archive/` 并在原位留 stub**，不要直接删除（保留历史可追溯，避免外部链接 404）。

步骤：
1. 把完整旧文档移入 `docs/_archive/`（文件名不变）。
2. 在 `docs/` 原路径留一个 stub，仅含标题 + 一行指引，格式照既有范例：

```markdown
# 法术书 UI 设计规范（已归档）

⚠️ 本文档已归档至 _archive/，内容已被 spellbook-layout-analysis.md 取代，详见该文档。
```

3. 标题后缀加「（已归档）」，正文一行写明：归档去向 + 取代它的文档名。
4. 更新 work-plan 等处指向旧文档的链接，改指向新文档。

现有 stub 范例：`loot-module-design.md`、`loot-module-implementation.md`、`spellbook-ui-design.md`（对应 `_archive/` 同名完整件）。

---

## 五、一句话总则

代码改了文档就得改；说不清的标「待实证」，不臆造；旧的不删，归档留 stub。
