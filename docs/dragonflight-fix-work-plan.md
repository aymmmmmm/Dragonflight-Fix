# dragonflight-fix 优化总体工作计划

## Context

dragonflight-fix 是面向中文 Turtle WoW 玩家的 Dragonflight 风格 UI 插件（DFRL 命名空间，38 个 Lua 文件，~20K 行）。目标是从 Dragonflight3（DF 命名空间，79 模块，47K 行）和 DragonflightReloaded（同 DFRL，43 文件）中借鉴优秀功能，分阶段增强 dragonflight-fix。

参考文档：`dragonflight-comparison.md`（三仓库对比）、`dragonflight-feature-discovery.md`（功能清单）、`dragonflight-fix-optimization-guide.md`（优化路线图）、`dragonflight-fix-execution-plan.md`（执行方案）、`dragonflight-fix-talent-planning.md`（天赋规划设计）

---

## 一、已完成工作

| # | 工作项 | 状态 | 说明 |
|---|--------|------|------|
| 1 | **天赋规划/模拟功能** | ✅ 已完成 | `modules/ui/talents.lua` 591→983 行，含 9 个新函数、双模式 UI、20 方案切换、Shift 重置、滚轮操作、talentCache 优化 |
| 2 | **Buff/Debuff 库文件复制** | ⚠️ 半完成 | `libs/libtipscan.lua`(127行) `libspell.lua`(119行) `libdebuff.lua`(366行) 已在磁盘，**但未加入 .toc** |
| 3 | **减益数据库复制** | ⚠️ 半完成 | `data/debuffs.lua`(959行,933条) 已在磁盘，**但未加入 .toc** |
| 4 | **光环系统复制** | ⚠️ 半完成 | `modules/unit/auras.lua`(1648行) 已在磁盘，使用 DFRL 命名空间，**但未加入 .toc** |
| 5 | **sounds.lua** | ⚠️ 半完成 | `modules/menu/sounds.lua`(1010行) 存在于磁盘，**未加入 .toc** |
| 6 | **三仓库对比分析** | ✅ 已完成 | 5 份分析文档 |

---

## 二、未完成工作清单

### Phase 0：激活磁盘上已有文件（即时可做）

**任务 0.1** — 更新 .toc 加载顺序

修改 `Dragonflight-Fix.toc`，在对应位置插入已存在但未加载的文件：

```
# DATA 区域追加
data\debuffs.lua

# LIBS 区域新增（在 DATA 和 MODULES 之间）
libs\libtipscan.lua
libs\libspell.lua
libs\libdebuff.lua

# MODULES 区域追加
modules\unit\auras.lua      （在 modules\unit\pvp.lua 之后）
modules\menu\sounds.lua     （在 modules\menu\addons.lua 之后）
```

**任务 0.2** — 验证 auras.lua 兼容性与中文化

- 确认 auras.lua 的 `DFRL:NewDefaults` 配置标签已中文化
- 确认 libdebuff 对 debuffs.lua 数据表的引用路径正确
- 确认 sounds.lua 是否需要依赖调整

**预期效果**：插件加载后立即获得完整的 Buff/Debuff 显示系统（图标 + 计时器 + 4 色减益类型 + 冷却螺旋）

---

### Phase 1：高价值低成本功能

**任务 1.1** — 冷却时间数字显示
- 来源：`-Dragonflight3/mods/general/cooldowns.lua` (~200行)
- 创建：`modules/ui/cooldowns.lua` (~150行)
- 技术：Hook `ActionButton_OnUpdate`，按冷却时段着色（<10s红/10-59s黄/1-5m白/5m+灰）
- 效果：动作按钮直接显示 CD 秒数，替代 OmniCC 等独立插件

**任务 1.2** — 物品比较（装备对比）
- 来源：`-Dragonflight3/mods/general/itemcompare.lua` (~150行)
- 创建：`modules/ui/itemcompare.lua` (~100行)
- 技术：Hook `GameTooltip:SetBagItem` 等，Shift 悬停时创建第二 Tooltip
- 效果：Shift 悬停装备时并排显示已穿戴对比

**任务 1.3** — 职业配色方案统一管理
- 来源：`-Dragonflight3/mods/general/colors.lua` (~250行)
- 创建：`modules/ui/colors.lua` (~200行)
- 修改：player.lua / target.lua / mini.lua 各改 10-20 行引用 `DFRL.classColors`
- 效果：Vanilla/TBC/Dragonflight 三套预设可切换，资源条统一着色

**任务 1.4** — Tooltip 增强
- 来源：`-Dragonflight3/mods/tooltip/tooltip.lua` (304行)
- 修改：`modules/ui/tooltip.lua` 54→~200行
- 新增：鼠标跟随、目标的目标、健康值条、距离显示（UnitXP 条件降级）

**任务 1.5** — 聊天系统增强
- 来源：`-Dragonflight3/mods/chat/chat.lua` (775行)
- 修改：`modules/chat/chat.lua` 306→~500行
- 新增：URL 检测高亮、时间戳 `[HH:MM]`、频道缩写、聊天淡出

**任务 1.6** — 配置版本迁移系统
- 来源：`-Dragonflight3/core/init.lua` (行19-85)
- 修改：`core/core.lua` 的 `VersionCheckDB()` 函数
- 技术：版本不匹配时合并新增配置到现有数据，而非清空重置
- 效果：升级版本后用户配置不丢失

**任务 1.7** — GUID 追踪库
- 来源：`-Dragonflight3/libs/libguid.lua` (244行)
- 创建：`libs/libguid.lua` (~100行修改，DF→DFRL 翻译)
- 技术：优先 `UnitGUID`(SuperWoW)，无则伪 GUID；120 秒过期清理

**任务 1.8** — 自定义事件库
- 来源：`-Dragonflight3/libs/libevents.lua` (~120行)
- 创建：`libs/libevents.lua` (~80行修改)
- 提供：`PLAYER_AFTER_ENTERING_WORLD`(延迟50ms)、`SYNC_READY`(延迟2s)

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
| 4.5 字体路径去重 | core/tools.lua + 5 个模块 | 提取 `DFRL.tools.GetFont(name)` |

---

## 三、技术方案

### 移植模式

所有新模块统一使用 DFRL 注册模式：
```lua
DFRL:NewDefaults("ModuleName", {
    enabled = {true, "启用"},
})
DFRL:NewMod("ModuleName", priority, function()
    local setup = DFRL.tempDB.ModuleName
    if not setup.enabled then return end
    -- 条件检测示例
    local hasSuperWoW = (UnitGUID ~= nil)
    -- 实现...
end)
```

### DF3→DFRL API 翻译

```lua
DF:NewModule(m,p,e,fn) → DFRL:NewMod(m,p,fn)
DF.profile[m][k]       → DFRL.tempDB[m][k]
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

完成全部 Phase 后，dragonflight-fix 将从 **38 文件 / ~20K 行** 增长到 **~55 文件 / ~30K 行**，功能覆盖从"基础 UI 替换"提升至"全面战斗辅助 + 视觉增强"：

| 维度 | 当前 | 目标 |
|------|------|------|
| Buff/Debuff 显示 | 完全缺失 | 完整系统（图标+计时+4色+冷却螺旋） |
| 冷却时间 | 无 | 按钮直接显示 CD 秒数 |
| 装备对比 | 无 | Shift 悬停并排对比 |
| 职业颜色 | 硬编码散落 | 统一管理，3 套预设 |
| Tooltip | 仅锚点调整 | 目标的目标+距离+健康条 |
| 聊天 | 基础 | URL+时间戳+频道缩写 |
| 天赋 | 仅学习 | 规划/模拟/20 方案（已完成） |
| 挥击计时 | 无 | 主手/副手/远程倒计时 |
| CC 监视 | 无 | 屏幕提示+可用中断 |
| 距离显示 | 无 | 实时目标距离 |
| 治疗预测 | 无 | HealComm 队伍预测条 |
| 配置升级 | 重置丢失 | 自动迁移保留 |

---

## 五、验证方式

每个 Phase 完成后：
1. `luacheck` 静态检查无新增错误
2. 游戏内加载无 Lua 报错
3. `/dfrl` 设置界面有对应配置页
4. 逐功能验证对应效果
5. 主城 40 人场景帧率 ≥ 30 FPS
