# dragonflight-fix 优化总体工作计划

## Context

dragonflight-fix 是面向中文 Turtle WoW 玩家的 Dragonflight 风格 UI 插件（**DFUI** 命名空间，当前 .toc 版本 **2.1**，约 81 个 Lua 文件、~52K 行）。目标是从 Dragonflight3（DF 命名空间，79 模块，47K 行）和 DragonflightReloaded（DFRL，43 文件）中借鉴优秀功能，分阶段增强 dragonflight-fix。

> **注意**：v2.0.0 已将命名空间从 DFRL 重命名为 DFUI，SavedVariables 也相应更名（`DFUI_PROFILES`/`DFUI_DB_SETUP`/`DFUI_BUGS`/`DFUI_HealthDB`/`DFUI_CUR_PROFILE`/`DFUI_FRAMEPOS`）。`core/core.lua` 含一次性命名空间迁移（DFF/DFRL → DFUI）。下文 API 示例已更新。

参考文档：`dragonflight-comparison.md`（三仓库对比）、`dfui-vs-df3-comparison.md`（DFUI vs DF3 对比）、`dragonflight-feature-discovery.md`（功能清单）、`dragonflight-fix-optimization-guide.md`（优化路线图）、`dragonflight-fix-execution-plan.md`（执行方案）、`dragonflight-fix-talent-planning.md`（天赋规划设计）；面板/拾取专项见 `panel-skinning-progress.md`、`loot-module-progress.md`

---

## 一、已完成工作

| # | 工作项 | 状态 | 说明 |
|---|--------|------|------|
| 1 | **天赋规划/模拟功能** | ✅ 已完成 | `modules/ui/talents.lua`（当前 1050 行），双模式 UI、20 方案切换、Shift 重置、滚轮操作 |
| 2 | **Buff/Debuff 系统** | ✅ 已完成 | libs 3 个库 + debuffs.lua + auras.lua 全部加入 .toc，多精度计时（玩家精确/宠物回退/目标仅GUID） |
| 3 | **冷却时间数字** | ✅ 已完成 | `modules/ui/cooldowns.lua`，从 DF3 移植 |
| 4 | **物品比较** | ✅ 已完成 | `modules/ui/itemcompare.lua`，从 DF3 移植 |
| 5 | **职业配色管理** | ✅ 已完成 | `modules/ui/colors.lua`，Vanilla/TBC/Dragonflight 三套预设 |
| 6 | **Tooltip 增强** | ✅ 已完成 | 鼠标跟随 + 目标的目标 + 距离显示 |
| 7 | **GUID 追踪库** | ✅ 已完成 | `libs/libguid.lua`，从 DF3 移植 |
| 8 | **自定义事件库** | ✅ 已完成 | `libs/libevents.lua`，从 DF3 移植 |
| 9 | **命名空间重构** | ✅ 已完成（计划外） | DFRL → DFUI，SavedVariables 全面更名 |
| 10 | **天赋描述数据库** | ✅ 已完成（计划外） | `data/talents_desc.lua`，天赋各级效果文字 |
| 11 | **暗黑血球系统** | ✅ 已完成（计划外） | `modules/bars/orbs.lua`，Diablo 风格 HP/MP 球体 |
| 12 | **配置导入导出** | ✅ 已完成（计划外） | 序列化+反序列化在 `core/core.lua`（`DFUI:SerializeProfile`/`DFUI:DeserializeProfile`）；磁盘上另有 `core/serialize.lua` 副本但**未加入 .toc**（未使用） |
| 13 | **三仓库对比分析** | ✅ 已完成 | 多份对比文档（已更新至 v2.x） |
| 14 | **拾取模块** | ✅ 已完成（计划外） | `modules/loot/loot.lua` + `roll.lua`，DF 风格拾取/投骰窗口，已入 .toc，详见 `loot-module-progress.md` |
| 15 | **面板美化批量复刻** | ✅ 已完成（原 Phase 3.4） | `modules/panels/` 共 21 文件（19 个已美化面板 + paperdoll 工厂/scrollbar/questlog_xp），详见 `panel-skinning-progress.md` |
| 16 | **怪物血量估算库** | ✅ 已完成（原 Phase 2.6 部分） | `libs/libhealth.lua` 已入 .toc，独立 SavedVariables `DFUI_HealthDB` |
| 17 | **连击点可视化** | ✅ 已完成（原 Phase 2.4） | `modules/ui/combopoints.lua` 已入 .toc |
| 18 | **任务经验估算** | ✅ 已完成（计划外） | 实际链路 = `data/questxp.lua`（纯数据表，定义全局 `DFUI_QuestXPDB`/`DFUI_QuestXPNames`，已入 .toc）→ `modules/panels/questlog_xp.lua`（直接读 `_G.DFUI_QuestXPDB`/`_G.DFUI_QuestXPNames`，已入 .toc）。注：`libs/LibQuestXP/`（`LibQuestXP-Vanilla.lua` + `db/classic_db.lua`）为磁盘孤立文件，未入 .toc，全仓库无任何 Lua 引用，**未参与运行** |
| 19 | **sounds.lua** | ⚠️ 半完成 | 存在于磁盘（`modules/menu/sounds.lua`），**未加入 .toc** |

---

## 二、未完成工作清单

### Phase 0：激活磁盘上已有文件 — ✅ 已完成

~~任务 0.1~~ — .toc 已更新，libs/debuffs/auras 全部加载
~~任务 0.2~~ — auras.lua 已中文化，命名空间已迁移至 DFUI

**遗留**：`modules/menu/sounds.lua` 存在磁盘但未加入 .toc

---

### Phase 1：高价值低成本功能 — ✅ 7/8 已完成（仅 1.6 配置版本迁移未实现）

| 任务 | 状态 | 说明 |
|------|------|------|
| ~~1.1 冷却时间数字~~ | ✅ 已完成 | `modules/ui/cooldowns.lua` |
| ~~1.2 物品比较~~ | ✅ 已完成 | `modules/ui/itemcompare.lua` |
| ~~1.3 职业配色~~ | ✅ 已完成 | `modules/ui/colors.lua` |
| ~~1.4 Tooltip 增强~~ | ✅ 已完成 | `modules/ui/tooltip.lua` |
| ~~1.5 聊天系统增强~~ | ✅ 已完成 | `chat.lua` 已实现 URL 检测（可点击+复制弹框）+ 时间戳（含颜色配置），见 `chatURLDetect`/`chatTimestamps` 配置项 |
| **1.6 配置版本迁移** | ❌ 未实现 | Phase 1 唯一未完成项。注：`core/core.lua` 仅有命名空间迁移（DFF/DFRL → DFUI），无"配置结构版本号"迁移逻辑 |
| ~~1.7 GUID 追踪库~~ | ✅ 已完成 | `libs/libguid.lua` |
| ~~1.8 自定义事件库~~ | ✅ 已完成 | `libs/libevents.lua` |

---

### Phase 2：战斗增强 + 实用工具 — 部分完成（2.4 ✅、2.6 部分 ✅；2.1/2.2/2.3/2.5/2.7 ❌ 未启动）

**任务 2.1** — 挥击计时器 — ❌ 未启动（`modules/unit/swingtimer.lua` 不存在）
- 来源：`-Dragonflight3/mods/unitframes/swingtimer.lua` (~300行)
- 创建：`modules/unit/swingtimer.lua` (~200行)
- 依赖：SuperWoW（无则隐藏）
- 效果：主手/副手/远程倒计时条，英勇一击队列检测

**任务 2.2** — CC 控制监视 — ❌ 未启动（`modules/ui/nocontrol.lua` 不存在）
- 来源：`-Dragonflight3/mods/general/nocontrol.lua` (~700行)
- 创建：`modules/ui/nocontrol.lua` (~200行)
- 效果：被控时屏幕显示控制类型 + 可用中断提示 + 脉冲发光

**任务 2.3** — 距离显示器 — ❌ 未启动（`modules/ui/distance.lua` 不存在）
- 来源：`-Dragonflight3/mods/general/distance.lua` (~400行)
- 创建：`modules/ui/distance.lua` (~250行)
- 依赖：UnitXP（无则隐藏）

**任务 2.4** — 连击点可视化 — ✅ 已完成
- 创建：`modules/ui/combopoints.lua`（已入 .toc，含缩放/颜色/Y偏移配置，隐藏原生 ComboFrame）
- 效果：盗贼/猫德专用，完全独立

**任务 2.5** — HealComm 治疗预测 — ❌ 未启动（`libs/libhealcomm.lua` 不存在）
- 来源：`-Dragonflight3/libs/libhealcomm.lua` (252行)
- 创建：`libs/libhealcomm.lua`
- 需改：player.lua / mini.lua 显示预测 overlay

**任务 2.6** — 怪物血量估算 + 施法追踪 — ⚠️ 部分完成
- ✅ `libs/libhealth.lua` 已完成并入 .toc（置信加权收敛版 v2，独立 SavedVariables `DFUI_HealthDB`）
- ❌ `libs/libcast.lua` 未启动（不存在）

**任务 2.7** — QoL 小功能（穿插实施）— ❌ 未启动（autoscreenshot/sellvalue/tweaks/questtracker 均不存在）
- 自动截图：`modules/ui/autoscreenshot.lua` (~80行)
- 卖出价值：`modules/ui/sellvalue.lua` (~120行)
- 自动下坐骑/姿态：`modules/ui/tweaks.lua` (~80行)
- 任务追踪增强：`modules/ui/questtracker.lua` (~150行)

---

### Phase 3：视觉增强

**任务 3.1** — 环境边框：屏幕边缘渐变（正常黑/战斗红/休息青）— ❌ 未启动（无对应模块文件）
**任务 3.2** — 全局暗化主题：替代逐模块 darkMode 分散实现 — ❌ 未启动（仍为逐模块 darkMode）
**任务 3.3** — 姓名板系统（分步：MVP 职业着色 → Debuff 显示 → 高级功能）— ❌ 未启动（无 nameplate 模块文件）
**任务 3.4** — 面板美化 — ✅ 已大致完成
- `modules/panels/` 共 21 文件，其中 19 个为已美化面板（角色/银行/商人/任务对话/NPC对话/任务日志/社交/邮件/交易/训练师/试穿/帮助/专业技能/法术书/键位/宏/检视/打开邮件/任务追踪等），外加 `paperdoll.lua` 工厂、`scrollbar.lua` 滚动条换肤、`questlog_xp.lua` 经验估算
- 详见 `panel-skinning-progress.md`、`panel-known-issues.md`

---

### Phase 4：自身优化（穿插进行）

| 任务 | 文件 | 内容 |
|------|------|------|
| 4.1 修复 3 个已知 BUG | chat.lua / map.lua / gui/prof.lua | 高亮闪烁/斜杠命令/档案删除 |
| 4.2 错误处理改进 | core/error.lua | 分层报告替代 2 次后静默 |
| 4.3 施法条增强 | modules/cast/cast.lua | Channel 中断动画 + tick 指示 |
| 4.4 单位框架增强 | player.lua / target.lua | 战斗状态/断线检测/威胁指示 |
| 4.5 字体路径去重 | core/tools.lua + 5 个模块 | ✅ 已提取全局 `GetFontPath(fontName, fallback)`（`core/tools.lua:188`，基于 `DFUI_FONT_PATHS` 表；非原计划的 `DFUI.tools.GetFont`） |

---

## 三、技术方案

### 移植模式

所有新模块统一使用 DFUI 注册模式：
```lua
DFUI:NewDefaults("ModuleName", {
    enabled = {true, "启用"},
})
DFUI:NewMod("ModuleName", priority, function()
    local setup = DFUI.tempDB.ModuleName
    if not setup.enabled then return end
    -- 条件检测示例
    local hasSuperWoW = (UnitGUID ~= nil)
    -- 实现...
end)
```

### DF3→DFUI API 翻译

```lua
DF:NewModule(m,p,e,fn) → DFUI:NewMod(m,p,fn)
DF.profile[m][k]       → DFUI.tempDB[m][k]
DF.L('text')           → "中文文字"
media['tex:path']      → 'Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\path'
DF.others.superWoW     → (UnitGUID ~= nil)
DF.others.unitXP       → (UnitXP ~= nil)
```

### .toc 当前加载顺序（实测，77 条加载项；磁盘 .lua 总数 81）

> 实测：`Dragonflight-Fix.toc` 中未注释的 `.lua` 加载项共 **77** 条；磁盘 `.lua` 文件总数为 **81**，差额 4 个为未入 .toc 的孤立文件：`core/serialize.lua`、`modules/menu/sounds.lua`、`libs/LibQuestXP/LibQuestXP-Vanilla.lua`、`libs/LibQuestXP/db/classic_db.lua`。

当前 `Dragonflight-Fix.toc` 实际结构（以 .toc 为准，下为概览）：
```
core\core → error → tools → statusbar → compat → first
data\tables → debuffs → talents_desc → questxp
libs\libtipscan → libspell → libdebuff → libguid → libevents → libhealth
  （libhealcomm / libcast 尚未引入）
  （另：libs\LibQuestXP\* 为孤立文件，未入 .toc、无任何 Lua 引用，未参与运行；任务经验走 data\questxp.lua 纯数据表）
modules\bars(bars/range/orbs) → cast → chat → bags → map(map/collect)
  → menu(menu/addons；sounds.lua 在磁盘但未入 .toc) → micro → frames
modules\panels\(paperdoll/scrollbar/bank/character/merchant/questframe/gossip/
  questlog/questlog_xp/social/mail/trade/trainer/tradeskill/dressup/help/
  openmail/inspect/macro/spellbook/keybinding)
modules\ui\(ui/tooltip/talents/errorHandler/cooldowns/itemcompare/colors/combopoints)
modules\unit\(player/target/mini/pvp/auras)
modules\xprep → track
modules\loot\(loot/roll)
modules\gui\(tools/base/elem/home/homeb/info/bugs/prof/mods/shag/superwow)
```
> 待加入的未来文件：`nocontrol` / `distance` / `swingtimer` / `libhealcomm` / `libcast` 及 QoL 模块。

---

## 四、最终效果

从 v1.3.3 的 **38 文件 / ~20K 行** 已增长到当前 **~81 文件 / ~52K 行**（含面板美化与拾取模块大批量新增）。完成剩余 Phase 后预计继续增长。

| 维度 | v1.3.3 | 当前现状 | 剩余目标 |
|------|--------|---------|---------|
| Buff/Debuff | 完全缺失 | ✅ 多精度分层计时 | — |
| 冷却时间 | 无 | ✅ 按钮 CD 秒数 | — |
| 装备对比 | 无 | ✅ Shift 悬停对比 | — |
| 职业颜色 | 硬编码 | ✅ 3 套预设 | — |
| Tooltip | 仅锚点 | ✅ 目标+距离 | — |
| 天赋 | 仅学习 | ✅ 规划/20 方案 | — |
| 血球系统 | 无 | ✅ Diablo 风格 | — |
| 配置同步 | 无 | ✅ 导入导出（core.lua） | — |
| 聊天 | 基础 | ✅ URL+时间戳 | — |
| 连击点 | 无 | ✅ 自定义可视化 | — |
| 血量估算 | 无 | ✅ libhealth（怪物血量） | — |
| 面板美化 | 无 | ✅ 19 面板 DF 换肤 | — |
| 拾取窗口 | 原生 | ✅ DF 风格拾取/投骰 | — |
| 配置版本迁移 | 重置丢失 | ❌ | 自动迁移保留（注：仅有命名空间迁移） |
| 挥击计时 | 无 | ❌ | 主手/副手倒计时 |
| CC 监视 | 无 | ❌ | 屏幕提示+中断 |
| 距离显示 | 无 | ❌ | 实时目标距离 |
| 治疗预测 | 无 | ❌ | HealComm 预测条 |
| 姓名板 | 无 | ❌ | 职业着色+Debuff |
| 环境边框 | 无 | ❌ | 屏幕边缘渐变 |

---

## 五、验证方式

每个 Phase 完成后：
1. `luacheck` 静态检查无新增错误
2. 游戏内加载无 Lua 报错
3. `/dfui` 设置界面有对应配置页
4. 逐功能验证对应效果
5. 主城 40 人场景帧率 ≥ 30 FPS
