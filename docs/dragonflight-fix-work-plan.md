# dragonflight-fix 优化总体工作计划

## Context

dragonflight-fix 是面向中文 Turtle WoW 玩家的 Dragonflight 风格 UI 插件（**DFUI** 命名空间，51 个 Lua 文件，~25K 行，v2.0.0）。目标是从 Dragonflight3（DF 命名空间，79 模块，47K 行）和 DragonflightReloaded（DFRL，43 文件）中借鉴优秀功能，分阶段增强 dragonflight-fix。

> **注意**：v2.0.0 已将命名空间从 DFRL 重命名为 DFUI，SavedVariables 也相应更名。下文 API 示例已更新。

参考文档：`dragonflight-comparison.md`（三仓库对比）、`dragonflight-feature-discovery.md`（功能清单）、`dragonflight-fix-optimization-guide.md`（优化路线图）、`dragonflight-fix-execution-plan.md`（执行方案）、`dragonflight-fix-talent-planning.md`（天赋规划设计）

---

## 一、已完成工作

| # | 工作项 | 状态 | 说明 |
|---|--------|------|------|
| 1 | **天赋规划/模拟功能** | ✅ 已完成 | `modules/ui/talents.lua` 591→1077 行，含 8 个核心函数、双模式 UI、20 方案切换、Shift 重置、滚轮操作 |
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
| 12 | **配置导入导出** | ✅ 已完成（计划外） | 序列化+校验和+跨角色同步 |
| 13 | **三仓库对比分析** | ✅ 已完成 | 9 份文档（已更新至 v2.0.0） |
| 14 | **sounds.lua** | ⚠️ 半完成 | 存在于磁盘，**未加入 .toc** |

---

## 二、未完成工作清单

### Phase 0：激活磁盘上已有文件 — ✅ 已完成

~~任务 0.1~~ — .toc 已更新，libs/debuffs/auras 全部加载
~~任务 0.2~~ — auras.lua 已中文化，命名空间已迁移至 DFUI

**遗留**：`modules/menu/sounds.lua` 存在磁盘但未加入 .toc

---

### Phase 1：高价值低成本功能 — ✅ 7/8 已完成

| 任务 | 状态 | 说明 |
|------|------|------|
| ~~1.1 冷却时间数字~~ | ✅ 已完成 | `modules/ui/cooldowns.lua` |
| ~~1.2 物品比较~~ | ✅ 已完成 | `modules/ui/itemcompare.lua` |
| ~~1.3 职业配色~~ | ✅ 已完成 | `modules/ui/colors.lua` |
| ~~1.4 Tooltip 增强~~ | ✅ 已完成 | `modules/ui/tooltip.lua` |
| 1.5 聊天系统增强 | ⚠️ 需确认 | chat.lua 已有暗色模式等，URL/时间戳需确认 |
| **1.6 配置版本迁移** | ❌ 未实现 | Phase 1 唯一未完成项 |
| ~~1.7 GUID 追踪库~~ | ✅ 已完成 | `libs/libguid.lua` |
| ~~1.8 自定义事件库~~ | ✅ 已完成 | `libs/libevents.lua` |

---

### Phase 2：战斗增强 + 实用工具

**任务 2.1** — 挥击计时器
- 来源：`-Dragonflight3/mods/unitframes/swingtimer.lua` (~300行)
- 创建：`modules/unit/swingtimer.lua` (~200行)
- 依赖：SuperWoW（无则隐藏）
- 效果：主手/副手/远程倒计时条，英勇一击队列检测

**任务 2.2** — CC 控制监视
- 来源：`-Dragonflight3/mods/general/nocontrol.lua` (~700行)
- 创建：`modules/ui/nocontrol.lua` (~200行)
- 效果：被控时屏幕显示控制类型 + 可用中断提示 + 脉冲发光

**任务 2.3** — 距离显示器
- 来源：`-Dragonflight3/mods/general/distance.lua` (~400行)
- 创建：`modules/ui/distance.lua` (~250行)
- 依赖：UnitXP（无则隐藏）

**任务 2.4** — 连击点可视化
- 来源：`-Dragonflight3/mods/general/combopoints.lua` (~100行)
- 创建：`modules/ui/combopoints.lua` (~60行)
- 效果：盗贼/猫德专用，完全独立

**任务 2.5** — HealComm 治疗预测
- 来源：`-Dragonflight3/libs/libhealcomm.lua` (252行)
- 创建：`libs/libhealcomm.lua`
- 需改：player.lua / mini.lua 显示预测 overlay

**任务 2.6** — 怪物血量估算 + 施法追踪
- 来源：`-Dragonflight3/libs/libhealth.lua`(244行) + `libcast.lua`(81行)
- 创建：`libs/libhealth.lua` + `libs/libcast.lua`

**任务 2.7** — QoL 小功能（穿插实施）
- 自动截图：`modules/ui/autoscreenshot.lua` (~80行)
- 卖出价值：`modules/ui/sellvalue.lua` (~120行)
- 自动下坐骑/姿态：`modules/ui/tweaks.lua` (~80行)
- 任务追踪增强：`modules/ui/questtracker.lua` (~150行)

---

### Phase 3：视觉增强

**任务 3.1** — 环境边框：屏幕边缘渐变（正常黑/战斗红/休息青）
**任务 3.2** — 全局暗化主题：替代逐模块 darkMode 分散实现
**任务 3.3** — 姓名板系统（分步：MVP 职业着色 → Debuff 显示 → 高级功能）
**任务 3.4** — 面板美化（分批：银行→法术书→角色面板→Turtle 专属→其余）

---

### Phase 4：自身优化（穿插进行）

| 任务 | 文件 | 内容 |
|------|------|------|
| 4.1 修复 3 个已知 BUG | chat.lua / map.lua / gui/prof.lua | 高亮闪烁/斜杠命令/档案删除 |
| 4.2 错误处理改进 | core/error.lua | 分层报告替代 2 次后静默 |
| 4.3 施法条增强 | modules/cast/cast.lua | Channel 中断动画 + tick 指示 |
| 4.4 单位框架增强 | player.lua / target.lua | 战斗状态/断线检测/威胁指示 |
| 4.5 字体路径去重 | core/tools.lua + 5 个模块 | 提取 `DFUI.tools.GetFont(name)` |

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

### .toc 最终加载顺序

Phase 0~2 全部完成后的 .toc 结构（共 ~55 个文件）：
```
core\error.lua → core.lua → tools.lua → statusbar.lua → compat.lua → first.lua
data\tables.lua → debuffs.lua
libs\libtipscan → libspell → libdebuff → libguid → libevents → libhealcomm → libhealth → libcast
modules\bars → cast → chat → bags → map → menu(+sounds) → micro → frames
modules\ui\(ui/tooltip/talents/errorHandler/cooldowns/itemcompare/colors/nocontrol/distance/combopoints/...)
modules\unit\(player/target/mini/pvp/auras/swingtimer)
modules\xprep → track
modules\gui\(tools/base/elem/home/homeb/info/prof/mods/shag)
```

---

## 四、最终效果

v2.0.0 已从 **38 文件 / ~20K 行** 增长到 **51 文件 / ~25K 行**。完成全部 Phase 后预计 ~60 文件 / ~32K 行。

| 维度 | v1.3.3 | v2.0.0 现状 | 全部完成目标 |
|------|--------|------------|-------------|
| Buff/Debuff | 完全缺失 | ✅ 多精度分层计时 | — |
| 冷却时间 | 无 | ✅ 按钮 CD 秒数 | — |
| 装备对比 | 无 | ✅ Shift 悬停对比 | — |
| 职业颜色 | 硬编码 | ✅ 3 套预设 | — |
| Tooltip | 仅锚点 | ✅ 目标+距离 | — |
| 天赋 | 仅学习 | ✅ 规划/20 方案 | — |
| 血球系统 | 无 | ✅ Diablo 风格 | — |
| 配置同步 | 无 | ✅ 导入导出 | — |
| 聊天 | 基础 | ⚠️ 需确认增强 | URL+时间戳 |
| 配置版本迁移 | 重置丢失 | ❌ | 自动迁移保留 |
| 挥击计时 | 无 | ❌ | 主手/副手倒计时 |
| CC 监视 | 无 | ❌ | 屏幕提示+中断 |
| 距离显示 | 无 | ❌ | 实时目标距离 |
| 治疗预测 | 无 | ❌ | HealComm 预测条 |
| 姓名板 | 无 | ❌ | 职业着色+Debuff |

---

## 五、验证方式

每个 Phase 完成后：
1. `luacheck` 静态检查无新增错误
2. 游戏内加载无 Lua 报错
3. `/dfui` 设置界面有对应配置页
4. 逐功能验证对应效果
5. 主城 40 人场景帧率 ≥ 30 FPS
