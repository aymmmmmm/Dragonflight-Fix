# Dragonflight-Fix docs 总索引

> 本文件是 `Dragonflight-Fix/docs/` 整个文档库的入口索引，按功能域分组。
> 事实源 = 代码（插件根 `Interface/AddOns/Dragonflight-Fix`）；写作 / 同步 / 归档约定见 [docs-maintenance.md](docs-maintenance.md)。
> 行号会漂移，引用以「函数名 + 文件路径」为准。WoW 1.12 = Lua 5.0：取长度用 `table.getn`，缺 retail Texture API。

---

## 一、顶层规划与对比

- [dragonflight-fix-work-plan.md](dragonflight-fix-work-plan.md) — DFUI 优化总体工作计划：从 DF3 / Reloaded 借鉴功能分阶段增强（命名空间 DFRL→DFUI 迁移见 `core/core.lua`）
- [dragonflight-fix-execution-plan.md](dragonflight-fix-execution-plan.md) — 优化执行方案 + 待办状态审计（2026-06-01 按当前 `.toc`/`modules/` 复核）
- [dragonflight-fix-optimization-guide.md](dragonflight-fix-optimization-guide.md) — 优化参考指南：逐项标注从 Reloaded / DF3 借鉴功能的当前完成状态
- [dragonflight-feature-discovery.md](dragonflight-feature-discovery.md) — 三仓库功能深度挖掘清单（含「隐藏宝石」，已落地项标 ✅）
- [dragonflight-comparison.md](dragonflight-comparison.md) — fix / Reloaded / DF3 三仓库代码架构 + 功能覆盖深度对比
- [dfui-vs-df3-comparison.md](dfui-vs-df3-comparison.md) — Dragonflight-Fix v2.1 vs Dragonflight3 v1.1.5 深度对比报告
- [dragonflight-review-reflection.md](dragonflight-review-reflection.md) — v2.0.0 全面回顾与反思（对照 4 份 `_dev/` 参考包，Tier 1/2 缺口现状已补注）
- [modules-overview.md](modules-overview.md) — 其余 P2 模块速览：施法条/背包/地图小地图/微型菜单/经验声望条/提示框/聊天/通用美化/滚动条

## 二、面板美化（modules/panels/）

- [panel-skinning-design.md](panel-skinning-design.md) — 面板美化总设计：统一 DF 金属边框风格（工厂本体 `paperdoll.lua`）
- [panel-skinning-progress.md](panel-skinning-progress.md) — 面板美化实施进度表（19 个已美化面板，分 Phase）
- [panel-known-issues.md](panel-known-issues.md) — 面板已知问题（一～四节为旧「换皮 vanilla」方案遗留，多数随全自制 `tradeskill.lua` 作废）
- [profession-panel-design.md](profession-panel-design.md) — 专业技能面板 UI 重构设计（全自制，DF retail 专业背景画风格，`modules/panels/tradeskill.lua`）
- [profession-panel-debug.md](profession-panel-debug.md) — 专业技能面板调试记录（已解决问题 + 选中态/折叠/训练点修复，`tradeskill.lua`）
- [social-panel-design.md](social-panel-design.md) — 社交面板设计：好友/查找/公会/团队四 tab DF 复刻（`modules/panels/social.lua`，UIPanel 互斥保活）
- [guild-panel-design.md](guild-panel-design.md) — 公会面板设计：全自制 row 脱钩 vanilla 双 mode 视图（`social.lua` 公会逻辑块）
- [worldmap-panel-design.md](worldmap-panel-design.md) — 世界地图面板美化方案（设计阶段，首次实施回退；已有 6 模块 hook WorldMapFrame）
- [spellbook-layout-analysis.md](spellbook-layout-analysis.md) — 法术书布局新基线（550×580 / 右侧竖向 Tab / 羊皮纸贴金属内边，`modules/panels/spellbook.lua`）
- [spellbook-inner-border-problem.md](spellbook-inner-border-problem.md) — 法术书羊皮纸内框排障记录（已放弃独立内框，改 retail 整张拼图直出）
- [spellbook-comparison.md](spellbook-comparison.md) — D3 SpellBook vs ModernSpellBook 架构对比分析（外部插件调研）

## 三、单位框体与光环（modules/unit/）

- [unit-frames-design.md](unit-frames-design.md) — 单位框体设计：玩家/目标/宠物/ToT/小队/PvP 复刻（`player.lua`/`target.lua`/`mini.lua`/`pvp.lua` + `core/statusbar.lua`）
- [auras-implementation.md](auras-implementation.md) — 光环系统代码级实现：计时分层落地 + libdebuff + 四色分类 + buff bar（`modules/unit/auras.lua`）
- [aura-timer-design.md](aura-timer-design.md) — 光环计时器设计原则：按单位类型分层计时 + LookupDuration 回退规则

## 四、动作条与施法（modules/bars/）

- [actionbars-design.md](actionbars-design.md) — 动作条系统设计：Bars / RangeIndicator / Orbs 三模块（`modules/bars/bars.lua`/`range.lua`/`orbs.lua`）

## 五、拾取（modules/loot/）

- [loot-module-progress.md](loot-module-progress.md) — 拾取模块设计、实现与踩坑总结（**当前权威**，取代下方两份归档稿）

## 六、天赋（modules/ui/）

- [dragonflight-fix-talent-planning.md](dragonflight-fix-talent-planning.md) — 天赋规划/模拟功能设计（已实现，`modules/ui/talents.lua`，数据存 `DFUI_CUR_PROFILE['TalentPlans']`）

## 七、配置与发版

- [config-system.md](config-system.md) — 配置系统总架构：`DFUI.defaults` / `tempDB` / SavedVariables 三层数据流
- [profile-export-import-lessons.md](profile-export-import-lessons.md) — 档案导入导出经验：setfenv 影子变量导致 `_FramePos` 不生效根因（`core.lua` RunMods/GetEnv）
- [frame-position-export-design.md](frame-position-export-design.md) — 框架位置导出设计（**未实现的设计方案**，AbsToRel/RelToAbs 待落地）
- [release-workflow.md](release-workflow.md) — 发版流程：纯手工，无 CI，语义化 git tag + GitHub Release

## 八、工厂与范式

- [factory-functions.md](factory-functions.md) — 工厂函数与复用范式总览（`CreatePaperDollFrame`/`CreateRedButton` 等，函数签名 + 文件:行 + 已知坑）

## 九、文档自身

- [docs-maintenance.md](docs-maintenance.md) — 文档维护规范：事实源=代码、待实证标注、归档约定

---

## 十、_archive/ 已归档

> 内容已被现行文档取代，仅作历史排障留存。顶层同名文件为重定向桩，正文在 `_archive/`。

- [_archive/loot-module-design.md](_archive/loot-module-design.md) — 拾取模块初版设计稿（已被 `loot-module-progress.md` 取代）
- [_archive/loot-module-implementation.md](_archive/loot-module-implementation.md) — 拾取模块初版实现细化（已被 `loot-module-progress.md` 取代）
- [_archive/spellbook-ui-design.md](_archive/spellbook-ui-design.md) — 法术书 UI 旧设计稿（2026-04-11，750×530/28 按钮，已被 `spellbook-layout-analysis.md` 取代）

顶层重定向桩（指向上述 `_archive/` 正文，保留以防外部链接失效）：
[loot-module-design.md](loot-module-design.md) · [loot-module-implementation.md](loot-module-implementation.md) · [spellbook-ui-design.md](spellbook-ui-design.md)
