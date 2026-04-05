# Dragonflight-Fix v2.0.0 vs Dragonflight3 v1.1.5 深度对比报告

> 日期：2026-04-05 | 基于两个仓库的实际代码逐文件分析

---

## 一、项目概况

| 维度 | Dragonflight-Fix (DFUI) | Dragonflight3 (DF) |
|------|------------------------|-------------------|
| 版本 | v2.0.0 | v1.1.5 |
| 命名空间 | DFUI | DF |
| 作者 | Guzruul → Stormhand → Claude | Guzruul（原作者全新重写） |
| Lua 文件数 | 55 | 108 |
| 代码行数 | 25,924 | ~47,000 |
| 项目大小 | 75 MB | 70 MB |
| SavedVariables | 4 个 | 5 个（多 DF_LearnedData） |
| 加载方式 | `.toc` 直列 57 文件 | XML 分层清单（6 个 .xml） |
| 环境隔离 | `setfenv` 模块环境 | `setfenv` + `DRAGONFLIGHT()` 宏 |
| 配置界面 | `/dfui` | `/df` |

---

## 二、基础设施对比

### 2.1 核心框架

| 对比项 | Fix (DFUI) | D3 (DF) | 评判 |
|--------|-----------|---------|------|
| 模块注册 | `DFUI:NewMod(name, priority, fn)` | `DF:NewModule(name, priority, event, fn)` | D3 多了 event-gated 加载 |
| 默认配置 | `DFUI:NewDefaults(mod, defs)` | `DF:NewDefaults(mod, defs)` | 基本相同 |
| 配置读写 | `DFUI.tempDB[mod][key]` | `DF.profile[mod][key]` | Fix 多了 GetTempDB/SetTempDB 方法 |
| 回调系统 | `DFUI:NewCallbacks(mod, cbs)` | `DF:NewCallbacks(mod, cbs)` + 元数据驱动 GUI | **D3 胜**：回调直接驱动 GUI 生成 |
| DB 版本迁移 | 静态 "2.0"，不匹配则重置 | 版本检测 + 模块级版本追踪 | **D3 胜**：用户升级不丢配置 |
| 配置导入导出 | ✅ serialize.lua 303 行 | ✅ profiles.lua 917 行 | **Fix 胜**：校验和验证 + 更紧凑格式 |
| 黑名单检测 | ShaguTweaks / Bagshui / Immersion | ShaguTweaks 全系列 + DragonflightReloaded | 类似 |

### 2.2 库系统

| 库 | Fix | D3 | 差异 |
|----|-----|-----|------|
| libtipscan | ✅ 162 行 | ✅ 148 行 | Fix 略多 |
| libspell | ✅ 120 行 | ✅ 116 行 | 基本相同 |
| libdebuff | ✅ 396 行 | ✅ 354 行 | Fix 更完整（多精度分层） |
| libguid | ✅ 218 行 | ❌ 不存在 | **Fix 胜**：独立库，D3 可能内嵌在其他代码中 |
| libevents | ✅ 92 行 | ✅ 130 行 | D3 多了 PLAYERMODEL_READY + Hook CreateFrame 拦截 |
| libcast | ❌ | ✅ 80 行 | **D3 胜**：追踪其他玩家施法 |
| libhealcomm | ❌ | ❌（代码中无） | 两者均缺 |
| libhealth | ❌ | ❌（���码中无） | 两者均缺 |

> 注意：D3 v1.1.5 实际代码中 libguid/libhealcomm/libhealth 不存在，与之前基于旧版分析的文档有差��。

### 2.3 工具函数

| 工具 | Fix | D3 | 评判 |
|------|-----|-----|------|
| 字符串工具 | 内嵌在各模块 | `DF.data` 独立模块（split/trim/join/startswith） | **D3 胜**：统一复用 |
| 数学工具 | 无独立模块 | `DF.math` 207 行（lerp/clamp/normalize/colorGradient） | **D3 胜**：丰富实用 |
| Hook 系统 | 内嵌 hooksecurefunc | `DF.hooks` 独立模块（Hook/HookSecureFunc/WrapHandler/HookScript） | **D3 胜**：完整 Hook 框架 |
| 定时器 | `DFUI_Libs.delay/every` | `DF.timers.delay/every/pause/resume/cancel` | **D3 胜**：多了 pause/resume |
| UI 构建器 | `DFUI.tools.Create*` 系列 | `DF.ui` 独立模块 + ui-tools.lua | 类似 |
| 动画系统 | `statusbar.lua` 287 行 | `animations.lua` 120+ 行 | Fix statusbar 更完整，D3 更通用 |
| 日期/时间 | 无 | `DF.date` 模块（24h/12h/日历） | **D3 胜** |
| 媒体路径 | 硬编码拼接 | 元表自动解析（`tex:path` / `font:name`） | **D3 胜**：更优雅 |

### 2.4 数据表

| 数据 | Fix | D3 | 差异 |
|------|-----|-----|------|
| 主表 | tables.lua 820 行 | gamedata.lua **6,118 行** | **D3 胜**：7.5 倍，含大量法术/NPC/物品数据 |
| 减益数据库 | debuffs.lua 959 行 | 内含在 gamedata.lua | Fix 独立文件更清晰 |
| 天赋描述 | talents_desc.lua **1,833 行** | ❌ | **Fix 独有** |
| 图集坐标 | ❌ | atlas.lua 13 行 | D3 有 |

---

## 三、功能矩阵

### 3.1 共有功能

| 功能模块 | Fix 行数 | D3 行数 | Fix 特色 | D3 特色 |
|---------|---------|---------|---------|---------|
| **动作条** | bars 1,550 行 | actionbars 2,163 行 | 鹰身人装饰定位 | stackbuttons 物品堆叠计数器 |
| **施法条** | cast 728 行 | cast 1,208 行 | 火花/闪光动画 | spark trail 特效 + lag 指示器 |
| **单位框架(玩家)** | player 1,084 行 | unitframes-tools 2,725 行(共用) | 血量伤害切割动画 + 能量 tick | 战斗发光 + 宠物幸福度 |
| **单位框架(目标)** | target 716 行 | 同上(共用) | 目标的目标 | PvP 指示器 |
| **单位框架(小队)** | mini 1,033 行 | 同上(共用) | 完整小队框架 | party1-4 独立 |
| **Buff 系统** | auras **2,338 行** | buffs 483 行 | **多精度分层计时** + 永久光环过滤 | 基础 buff/debuff 显示 |
| **聊天** | chat 386 行 | chat 551 行 | 暗色模式滑块 | class 颜色 + 频道缩写 |
| **Tooltip** | tooltip 107 行 | tooltip 286 行 | 基础增强 | HP 条纹理选择 + 隐藏战斗中 |
| **小地图** | map 994 + collect 991 | minimap 529+420+175 | 坐标收集器 | 旋转动画层 + 日夜指示器 |
| **背包** | bags 199 行 | bags 2,180 行 | 基础 | OneBag 模式 + 搜索 + 自动售灰 |
| **菜单** | menu 309 + micro 475 | micromenu 439 行 | addons 面板 + sounds 管理 | 按钮网格布局 |
| **经验/声望** | xprep 472 行 | xprep 670 行 | 基础 | 脉冲动画 + 仅获取时显示 |
| **冷却数字** | cooldowns 148 行 | cooldowns 151 行 | 基本相同 | 颜色分段略不同(green vs white) |
| **物品比较** | itemcompare 181 行 | itemcompare 153 行 | **多语言支持**(6 语言) | 基础对比 |
| **职业配色** | colors 137 行 | colors 75 行 | 3 套预设 + power 颜色 | 基础配色 |
| **错误处理** | errorHandler 42 行 | error 94 行 | 节流抑制 | 缓存去重 + OOC 过滤 |
| **首次运行** | first 223 行 | firstrun 109 行 | 法律合规欢迎页 | 简单设置向导 |

### 3.2 D3 独有功能

| 功能 | 文件 | 行数 | 用户价值 | 移植难度 |
|------|------|------|---------|---------|
| **姓名板系统** | nameplates/ (2 文件) | **1,385** | 极高 — PvP 核心 | 高 |
| **面板美化** | panels/ (21 文件) | **1,767** | 高 — 视觉统一 | 低-中/个 |
| **Raid 框架** | raid.lua + interact | **1,625** | 高 — 团本需求 | 高 |
| **CC 控制监视** | nocontrol.lua | **697** | 高 — PvP 必备 | 低-中 |
| **Dock 信息栏** | dock.lua | **842** | 中 — 信息集中 | 中 |
| **EditMode 编辑模式** | editmode.lua | **495** | 中 — 框架拖拽 | 低 |
| **距离显示器** | distance.lua | **321** | 高 — 猎人/PvP | 中 |
| **挥击计时器** | (非当前版本) | — | 高 — 近战核心 | — |
| **连击点** | combopoints.lua | **101** | 中 — 盗贼/猫德 | 极低 |
| **Intellisense** | intellisense.lua | **705** | 低 — 中文兼容存疑 | 中 |
| **性能监控** | performance.lua | **490** | 低 — 开发用 | 低 |
| **Frame 检查器** | frameinspect.lua | **196** | 低 — 开发用 | 低 |
| **悬停绑定** | hoverbind.lua | **237** | 中 — 快捷操作 | 低 |
| **卖出价值** | sellvalue.lua | **160** | 中 — 背包整理 | 低 |
| **任务追踪增强** | questtracker.lua | **264** | 中 — QoL | 低 |
| **自动截图** | (未在当前版本) | — | 低 — 趣味 | — |
| **libcast 施法追踪** | libcast.lua | **80** | 中 — 目标施法条 | 极低 |
| **Slash 命令扫描** | slashscan.lua | **173** | 低 — 调试 | 低 |
| **What's New** | whatsnew.lua | **138** | 低 — 更新通知 | 极低 |
| **pfQuest 集成** | mixins/pfquest.lua | **70** | 中 — Turtle 实用 | 极低 |
| **Turtle 混入** | mixins/turtle.lua | **52** | 中 — 服务器适配 | 极低 |

### 3.3 Fix 独有功能

| 功能 | 文件 | 行数 | 说明 |
|------|------|------|------|
| **天赋规划系统** | talents.lua | **1,077** | 20 方案 + 前置验证 + 滚轮操作，D3 完全没有 |
| **天赋描述数据库** | talents_desc.lua | **1,833** | 天赋各级效果文字，D3 无 |
| **暗黑血球系统** | orbs.lua | **388** | Diablo 风格 HP/MP 球体，D3 无 |
| **配置导入导出** | serialize.lua | **303** | 序列化+校验和，D3 有 profiles.lua 但格式不同 |
| **多精度 Buff 计时** | auras.lua | **2,338** | 玩家精确/宠物回退/目标仅GUID 分层策略 |
| **完整中文本地化** | 全插件 | — | 所有配置项、提示、UI 文字内联中文 |
| **ShaguTweaks 兼容面板** | gui/shag.lua | — | 逐模块开关 ShaguTweaks 冲突项 |
| **libguid 独立库** | libguid.lua | **218** | D3 代码中未找到等效实现 |

---

## 四、优劣分析

### Fix v2.0.0 优势

1. **Buff/Debuff 系统远超 D3** — Fix 2,338 行 vs D3 483 行，多精度分层计时（GetPlayerBuffTimeLeft / GUID / LookupDuration）、永久光环过滤、4 色减益类型、双模式计时样式。D3 仅有基础 buff 显示。
2. **天赋系统独一无二** — 20 方案规划/模拟 + 天赋描述数据库，三个仓库中唯一拥有。
3. **中文本地化最完整** — 所有配置项、UI 文字内联中文，D3 有 zhCN.lua 但覆盖不如 Fix 全面。
4. **单位框架完成度高** — 玩家/目标/小队框架全部实现且功能丰富（血量切割动画、能量 tick 等）。
5. **配置导入导出更可靠** — 校验和验证 + `_G.` 显式全局写入（吸取了 setfenv 影子变量教训）。
6. **暗黑血球** — Diablo 风格 HP/MP 球体，视觉特色功能。
7. **即用性强** — 中文玩家开箱即用，无需额外配置。

### D3 v1.1.5 优势

1. **模块覆盖面最广** — 108 文件 vs 55 文件，多 21 个面板美化 + 姓名板 + Raid 框架 + CC 监视等。
2. **架构更工业化** — XML 分层加载、`DRAGONFLIGHT()` 环境宏、元数据驱动 GUI 生成、媒体路径元表解析。
3. **工具链完善** — 独立 DF.data/DF.math/DF.hooks/DF.timers 模块，代码复用度高。
4. **数据表巨大** — gamedata.lua 6,118 行，法术/NPC/物品查表远超 Fix。
5. **姓名板系统** — 1,385 行完整实现，6 优先级着色 + debuff 显示 + 焦点火力指示。
6. **面板美化全面** — 21 个系统面板统一 DF 风格（银行/法术书/天赋/角色/社交/邮件...）。
7. **CC 控制监视** — 697 行，8 种 CC 类型 + 可用中断提示 + 脉冲发光。
8. **开发工具** — Frame Inspector、SafeBoot、Slash Scanner、性能监控面板。
9. **Dock 信息栏** — 842 行，屏幕底部 6 组件信息面板（FPS/金币/耐久/弹药...）。

---

## 五、D3 可借鉴功能清单

### P1 — 高价值（建议优先移植）

| 功能 | D3 源路径 | 行数 | 移植难度 | 说明 |
|------|---------|------|---------|------|
| **姓名板系统** | `mods/nameplates/nameplates.lua` + `nameplates-tools.lua` | 1,385 | 高 | PvP 核心需求，建议分步：MVP 职业着色 → Debuff 显示 → 高级功能 |
| **配置版本迁移** | `core/init.lua` 行 19-85 | ~70 | 极低 | Fix 目前升级会重置配置，用户体验差。修改 `core/core.lua` 的 VersionCheckDB |
| **libcast 施法追踪** | `libs/libcast.lua` | 80 | 极低 | 追踪其他玩家施法，目标施法条的基础 |
| **CC 控制监视** | `mods/general/nocontrol.lua` | 697 | 低-中 | PvP 必备，被控时屏幕提示 + 可用中断列表 |

### P2 — 中价值（第二批）

| 功能 | D3 源路径 | 行数 | 移植难度 | 说明 |
|------|---------|------|---------|------|
| **面板美化（第一批）** | `mods/panels/bank.lua` | 87 | 极低 | 银行面板，最简单入门 |
| | `mods/panels/spellbook.lua` | 534 | 低 | 法术书，高频使用 |
| | `mods/panels/gamemenu.lua` | 322 | 低 | ESC 菜单 |
| **距离显示器** | `mods/general/distance.lua` | 321 | 中 | 依赖 UnitXP，猎人/PvP 实用 |
| **连击���** | `mods/general/combopoints.lua` | 101 | 极低 | 盗贼/猫德专用，完全独立 |
| **卖出价值** | `mods/general/sellvalue.lua` | 160 | ��� | Tooltip 显示 NPC 售价 |
| **悬停绑定** | `mods/general/hoverbind.lua` | 237 | 低 | 鼠标悬停按钮时绑键 |
| **任务追踪增强** | `mods/general/questtracker.lua` | 264 | 低 | 任务等级颜色 + 进度百分比 |
| **Dock 信息栏** | `mods/general/dock.lua` | 842 | 中-高 | 6 组件面板，代码量较大 |
| **pfQuest 集成** | `mixins/pfquest.lua` | 70 | 极低 | Turtle 服务器实用 |
| **Turtle 混入** | `mixins/turtle.lua` | 52 | 极低 | 隐藏多余按钮 + 天赋 Tab 等 |

### P3 — 低价值（远期可选）

| 功能 | D3 源路径 | 行数 | 移植难度 | 说明 |
|------|---------|------|---------|------|
| **面板美化（后续批次）** | `mods/panels/` 剩余 18 文件 | ~1,200 | 低/个 | 按使用频率分批 |
| **EditMode 网格** | `mods/general/editmode.lua` | 495 | 低 | 拖拽对齐网格 |
| **Raid 框架** | `mods/unitframes/raid.lua` | 1,605 | 高 | 仅 40 人团本需要 |
| **性能监控** | `mods/gui/performance.lua` | 490 | 低 | 开发向，普通玩家不需要 |
| **Intellisense** | `mods/chat/intellisense.lua` | 705 | 中 | 中文输入法兼容性存疑 |
| **What's New** | `mods/general/whatsnew.lua` | 138 | 极低 | 版本更新通知 |

### 不建议移植

| 功能 | 原因 |
|------|------|
| Polyfill (SetSize) | Fix tools.lua 已有等效 |
| Slash Scanner | 调试工具，玩家无直接价值 |
| Frame Inspector | 同上 |
| Sync 同步系统 | 需服务器端支持 |
| Bubbles 浮动文字 | D3 自身也注释掉了 |

---

## 六、API 翻译速查（DF3 → DFUI）

```lua
-- 模块系统
DF:NewModule(mod, pri, evt, fn)  → DFUI:NewMod(mod, pri, fn)     -- 去掉 event 参数
DF:NewDefaults(mod, defs)        → DFUI:NewDefaults(mod, defs)
DF:NewCallbacks(mod, cbs)        → DFUI:NewCallbacks(mod, cbs)
DF:SetConfig(mod, opt, val)      → DFUI:SetTempDB(mod, opt, val)

-- 配置读写
DF.profile[mod][opt]             → DFUI.tempDB[mod][opt]
DF.setups.mod                    → 直接用局部变量

-- Hook 系统
DF.hooks.Hook(tbl, name, fn)    → 直接替换函数
DF.hooks.HookSecureFunc(t,n,fn) → DFUI.env.hooksecurefunc(t, n, fn)
DF.hooks.HookScript(f, s, fn)   → HookScript(f, s, fn)
DF.hooks.WrapHandler(g,s,w)     → 手动实现 getter/setter 包装
DF.common.KillFrame(f)          → f:Hide(); f:SetScript('OnShow', function() this:Hide() end)

-- UI 工具
DF.ui.Font(parent, size, ...)   → parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
DF.ui.Frame(parent, ...)        → CreateFrame('Frame', nil, parent)

-- 数学/数据工具（D3 有独立模块，Fix 需内联或新建）
DF.math.lerp(a, b, t)           → 内联: a + (b - a) * t
DF.math.clamp(x, min, max)      → 内联: math.max(min, math.min(max, x))
DF.math.colorGradient(p,...)    → 内联实现或复制
DF.data.split(str, delim)       → 内联实现
DF.data.copy(tbl)               → 内联实现

-- 本地化
DF.L('English text')            → "中文文字"    -- 直接内联中文

-- 媒体路径
media['tex:actionbars:icon']    → 'Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\actionbars\\icon'
media['font:Expressway.ttf']    → 'Interface\\AddOns\\Dragonflight-Fix\\media\\fonts\\Expressway.ttf'

-- 依赖检测
DF.others.superWoW              → (UnitGUID ~= nil)
DF.others.unitXP                → (UnitXP ~= nil)
DF.others.server == 'turtle'    → (GetRealmName() or ''):find('Turtle')
DF.others.pfQuest               → IsAddOnLoaded and IsAddOnLoaded('pfQuest')

-- 定时器
DF.timers.delay(sec, fn)        → DFUI_Libs.delay(sec, fn)
DF.timers.every(sec, fn)        → DFUI_Libs.every(sec, fn)
DF.timers.cancel(id)            �� DFUI_Libs.cancel(id)
```

---

## 七、结论

**Fix 在用户体验层面已超越 D3**：中文化 + 天赋规划 + 多精度 Buff 计时 + 配置导入导出 + 血球系统，这些功能 D3 没有或远不如 Fix。

**D3 在工程质量和功能覆盖面上领先**：工具链模块化、姓名板、面板美化 21 个、CC 监视、Dock 信息栏等。

**最优路线**：以 Fix 为主体，从 D3 按优先级借鉴缺失模块。P1 的姓名板 + 配置迁移 + libcast + CC 监视完成后，Fix 将在功能完整度上也超越 D3。
