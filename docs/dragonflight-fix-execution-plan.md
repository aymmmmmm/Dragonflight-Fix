# dragonflight-fix 优化执行方案

> 生成日期：2026-03-25
> 最近核对：2026-06-01（与当前 .toc / modules/ 代码对齐）
> 基于：dragonflight-comparison.md / dragonflight-feature-discovery.md / dragonflight-fix-optimization-guide.md / dragonflight-fix-talent-planning.md

---

## 当前状态审计（2026-06-01 复核）

下表为本方案最初的待办清单，状态已按当前代码更新：

| 项目 | 状态 | 说明 |
|------|------|------|
| 天赋规划功能 | **已完成** | talents.lua 1050 行，含规划/模拟/方案切换 |
| libs/ 3个库文件 | **已加载** | libtipscan/libspell/libdebuff 均在 .toc（LIBS 段） |
| data/debuffs.lua | **已加载** | 减益数据库已列入 .toc（DATA 段） |
| modules/unit/auras.lua | **已加载** | Buff/Debuff UI 已列入 .toc（MODULES 段），DFUI 命名空间 + 中文标签 |
| .toc 当前状态 | 见文末实际加载顺序 | 已含 libs/、debuffs.lua、auras.lua，并新增 panels/ 与 loot/ 整套（本方案未覆盖） |

> 注：当前 .toc 版本号 `## Version: 2.1`，`DFUI.DBversion = "2.0"`（core/core.lua:23）。SavedVariables 已扩展为 `DFUI_PROFILES, DFUI_DB_SETUP, DFUI_BUGS, DFUI_HealthDB`（多出 BUGS / HealthDB）。

> **本方案进度总览**：Phase 0 已完成；Phase 1 大部分完成（仅 1.4 tooltip、1.5 chat 为部分增量）；Phase 2 完成 2.4/2.6，其余未做；Phase 3 未做（但面板美化改走 `modules/panels/` 独立架构，详见 panel-skinning-progress.md）；Phase 4 部分完成（error.lua 已重写）。逐项状态见各小节标题。

---

## Phase 0: 激活已有文件 [✅ 已完成]

> debuffs.lua、libtipscan/libspell/libdebuff、auras.lua 均已加入 .toc 并使用 DFUI 命名空间 + 中文标签。以下为当时的执行步骤，留作记录。

### 0.1 更新 .toc 加载顺序

**文件**: `Dragonflight-Fix.toc`

在 `data\tables.lua` 后、`modules\bars\bars.lua` 前插入：

```
# DATA
data\tables.lua
data\debuffs.lua

# LIBS
libs\libtipscan.lua
libs\libspell.lua
libs\libdebuff.lua

# MODULES
modules\unit\auras.lua
```

**注意**: libs 必须在 debuffs.lua 之后加载（libdebuff 依赖 debuffs 数据表），auras.lua 必须在 libs 之后。

### 0.2 验证 auras.lua 兼容性

**检查项**:
1. auras.lua 是否使用 `DFUI:NewMod` / `DFUI:NewDefaults` 注册（应该是，来自 Reloaded）
2. auras.lua 的配置标签是否已中文化
3. libdebuff.lua 中的命名空间是否为 `DFUI`（而非 DF）

```bash
# 验证命名空间
grep -n "DFUI\|DF\." dragonflight-fix/modules/unit/auras.lua | head -5
grep -n "DFUI\|DF\." dragonflight-fix/libs/libdebuff.lua | head -5
```

如果是 DF 命名空间（来自 Dragonflight3），需要做 API 翻译：
- `DF:NewModule` → `DFUI:NewMod`
- `DF.profile[mod]` → `DFUI:GetTempDB(mod, key)`
- `DF.L('text')` → 中文字符串

### 0.3 中文化 auras.lua 配置标签

将 auras.lua 中所有英文配置项标签翻译为中文，例如：
- `"Enabled"` → `"启用"`
- `"Icon Size"` → `"图标大小"`
- `"Show Timer"` → `"显示计时器"`

### 0.4 验证

```bash
cd dragonflight-fix
luacheck modules/unit/auras.lua --no-color --codes --config "../-Dragonflight3/.luacheckrc"
luacheck libs/libdebuff.lua --no-color --codes --config "../-Dragonflight3/.luacheckrc"
```

游戏内测试：
- [ ] 插件加载无 Lua 报错
- [ ] 目标框架显示 debuff 图标
- [ ] Debuff 有倒计时数字
- [ ] 4 种减益类型颜色正确（魔法蓝/疾病棕/毒药绿/诅咒紫）
- [ ] `/dfrl` 设置界面有 Auras 配置页

---

## Phase 1: 高价值低成本功能 [大部分已完成]

> 已完成：1.1 冷却数字、1.2 物品比较、1.3 职业配色、1.6 配置迁移、1.7 GUID 库、1.8 事件库。
> 部分完成：1.4 Tooltip（当前 108 行，未达计划的 ~200 行）、1.5 聊天（当前 386 行，未达 ~500 行）。

### 1.1 冷却时间数字显示 [✅ 已完成]

> 已实现于 `modules/ui/cooldowns.lua`（.toc 已加载），DFUI 模式 + 中文标签，按剩余时间着色（<10s 红 / <60s 黄 / <300s 绿 / 5m+ 灰）。配置项：显示冷却数字 / 字号 / 最小显示时长。下为原计划。

**来源**: `-Dragonflight3/mods/general/cooldowns.lua` (~200 行)
**创建**: `dragonflight-fix/modules/ui/cooldowns.lua`
**改动**: ~150 行新文件 + .toc 追加

**实现步骤**:
1. 读取 DF3 源码，理解 Hook 逻辑（Hook `ActionButton_OnUpdate`）
2. 新建 `modules/ui/cooldowns.lua`，使用 DFUI 模式：
   ```lua
   DFUI:NewDefaults("Cooldowns", {
       enabled = {true, "启用"},
       showSeconds = {true, "显示秒数"},
       minDuration = {2, "最小显示时长(秒)"},
   })
   DFUI:NewMod("Cooldowns", 5, function()
       -- Hook ActionButton1~ActionButton120 的 OnUpdate
       -- 按冷却剩余时间着色：<10s红 / 10-59s黄 / 1-5m白 / 5m+灰
       -- 在按钮中央创建 FontString 显示秒数/分钟数
   end)
   ```
3. .toc 中 `modules\ui\errorHandler.lua` 后追加 `modules\ui\cooldowns.lua`
4. 在 `modules/gui/mods.lua` 中添加 Cooldowns 配置入口

**验证**: 动作按钮上显示冷却秒数，颜色按时段变化

### 1.2 物品比较（装备对比） [✅ 已完成]

> 已实现于 `modules/ui/itemcompare.lua`（181 行，.toc 已加载）。下为原计划。

**来源**: `-Dragonflight3/mods/general/itemcompare.lua` (~150 行)
**创建**: `dragonflight-fix/modules/ui/itemcompare.lua`
**改动**: ~100 行新文件 + .toc 追加

**实现步骤**:
1. 读取 DF3 源码，核心逻辑：Hook `GameTooltip:SetBagItem` / `SetInventoryItem` 等
2. 新建模块，Shift 悬停时创建第二个 Tooltip 显示已穿戴装备
3. 装备槽映射表（16 个槽位: Head/Neck/Shoulder/...）

**验证**: Shift 悬停背包装备时并排显示已穿戴对比

### 1.3 职业配色方案统一管理 [✅ 已完成]

> 已实现于 `modules/ui/colors.lua`（141 行，.toc 已加载）。下为原计划。

**来源**: `-Dragonflight3/mods/general/colors.lua` (~250 行)
**创建**: `dragonflight-fix/modules/ui/colors.lua`
**修改**: player.lua / target.lua / mini.lua 引用统一颜色表
**改动**: ~200 行新文件 + 3 个文件各改 10-20 行

**实现步骤**:
1. 新建 `modules/ui/colors.lua`，定义三套预设（Vanilla/TBC/Dragonflight）
2. 通过 `DFUI.classColors` 全局暴露当前配色
3. 修改 player.lua / target.lua / mini.lua 中的硬编码 `RAID_CLASS_COLORS` 引用
4. 资源条着色：法力蓝/怒气红/焦点棕/能量黄

**验证**: 切换配色预设后单位框架颜色同步变化

### 1.4 Tooltip 增强 [部分完成]

> `modules/ui/tooltip.lua` 当前 108 行（已有基础增量），尚未达到计划的 ~200 行/全部新增功能。剩余项待补。

**来源**: `-Dragonflight3/mods/tooltip/tooltip.lua` (304 行)
**修改**: `dragonflight-fix/modules/ui/tooltip.lua` (当前 108 行 → ~200 行)
**改动**: ~90 行追加

**新增功能**:
- 鼠标跟随模式
- 目标的目标显示
- 健康值条美化
- 距离显示（条件检测 `UnitXP ~= nil`，无则优雅降级）
- 自定义颜色/透明度/缩放

**实现步骤**:
1. 读取 DF3 tooltip.lua，提取各功能的 Hook 逻辑
2. 在现有 tooltip.lua 的 `NewMod` 回调中追加功能
3. 扩展 `NewDefaults` 配置项（中文标签）

### 1.5 聊天系统增强 [部分完成]

> `modules/chat/chat.lua` 当前 386 行（已较 307 行有增量），尚未达到计划的 ~500 行。剩余功能项待补。

**来源**: `-Dragonflight3/mods/chat/chat.lua` (775 行)
**修改**: `dragonflight-fix/modules/chat/chat.lua` (当前 386 行 → ~500 行)
**改动**: ~120 行追加

**新增功能**:
- URL 自动检测并高亮（`http://` / `https://` / `www.`）
- 时间戳（`[HH:MM]` 格式）
- 频道缩写（G/P/R/BG）
- 聊天淡出控制

**注意**: 保留现有中文化逻辑，仅追加功能

### 1.6 配置版本迁移系统 [✅ 已完成（实现方式不同）]

> 已实现，但未采用"版本号 + 迁移链"方案，而是 `core/core.lua` 的 `DFUI:SyncProfiles()` + `DFUI:InitTempDB()`：自动检测 defaults 结构变更，新增项合并、过时项清理、错值修正，并打印"配置已同步 +N/-N/~N"提示（core.lua:192-241）。`DFUI.DBversion = "2.0"` 仅作标识，不再用于"版本不匹配则清空"。
> 另有旧存档一次性迁移逻辑（DFF/DFRL → DFUI，core.lua:649-661）。
> 下为原计划，留作记录。

**来源**: `-Dragonflight3/core/init.lua` (行 19-85)
**修改**: `dragonflight-fix/core/core.lua`
**改动**: ~100 行修改

**实现步骤**:
1. 在 `core.lua` 的 `VersionCheckDB()` 函数中替换"版本不匹配则清空"逻辑
2. 改为：版本不匹配时遍历 `self.defaults`，合并新增配置项到现有数据，保留用户已有配置
3. 更新 `DBversion` 为语义化版本号（如 `2`），定义迁移函数链

```lua
-- 迁移链示例
local migrations = {
    [1] = function(db)
        -- v1→v2: 合并新增模块默认值
        return db
    end,
}
```

**验证**: 升级版本后用户原有配置保留，新增模块使用默认值

### 1.7 GUID 追踪库 [✅ 已完成]

> 已实现于 `libs/libguid.lua`（218 行，.toc LIBS 段已加载）。下为原计划。

**来源**: `-Dragonflight3/libs/libguid.lua` (244 行)
**创建**: `dragonflight-fix/libs/libguid.lua`
**改动**: ~100 行修改（API 翻译 DF→DFUI）+ .toc 追加

**实现步骤**:
1. 复制 libguid.lua，将 `DF.` 引用改为 `DFUI.`
2. 伪 GUID 格式：`pGUID-name-level-class-subzone-counter`
3. 条件检测：优先 `UnitGUID`（SuperWoW），无则用伪 GUID
4. .toc 中 `libs\libdebuff.lua` 后追加 `libs\libguid.lua`

### 1.8 自定义事件库 [✅ 已完成]

> 已实现于 `libs/libevents.lua`（92 行，.toc LIBS 段已加载）。下为原计划。

**来源**: `-Dragonflight3/libs/libevents.lua` (~120 行)
**创建**: `dragonflight-fix/libs/libevents.lua`
**改动**: ~80 行修改 + .toc 追加

**提供事件**:
- `PLAYER_AFTER_ENTERING_WORLD`（延迟 50ms，解决原版 PLAYER_ENTERING_WORLD 时序问题）
- `SYNC_READY`（延迟 2s，确保所有模块初始化完成）

---

## Phase 2: 战斗增强功能 [部分完成]

> 已完成：2.4 连击点（`modules/ui/combopoints.lua`，已加载）、2.6 怪物血量估算（`libs/libhealth.lua`，317 行，已加载，存档变量 `DFUI_HealthDB`）。
> 未做：2.1 挥击计时器、2.2 CC 监视、2.3 距离显示、2.5 HealComm、2.7 施法追踪、2.8 全部 QoL 小功能（对应文件均未创建）。

### 2.1 挥击计时器 [未做]

**来源**: `-Dragonflight3/mods/unitframes/swingtimer.lua` (~300 行)
**创建**: `dragonflight-fix/modules/unit/swingtimer.lua`
**改动**: ~200 行新文件
**依赖**: SuperWoW（条件检测 `UnitGUID ~= nil`）

**功能**:
- 主手/副手/远程武器倒计时条
- 英勇一击/劈砍队列检测
- 躲闪加速支持
- 无 SuperWoW 时隐藏（优雅降级）

### 2.2 CC 控制监视 [未做]

**来源**: `-Dragonflight3/mods/general/nocontrol.lua` (~700 行)
**创建**: `dragonflight-fix/modules/ui/nocontrol.lua`
**改动**: ~200 行新文件

**功能**:
- 8 种 CC 类型分类（眩晕/沉默/恐惧/缚根/催眠/魅惑/致残/减速）
- 被控时屏幕中央显示控制类型图标+文字
- 可用中断法术列表提示
- 脉冲发光效果

**需中文化**: CC 类型名称、法术名称列表

### 2.3 距离显示器 [未做]

**来源**: `-Dragonflight3/mods/general/distance.lua` (~400 行)
**创建**: `dragonflight-fix/modules/ui/distance.lua`
**改动**: ~250 行新文件
**依赖**: UnitXP（条件检测 `UnitXP ~= nil`）

### 2.4 连击点可视化 [✅ 已完成]

> 已实现于 `modules/ui/combopoints.lua`（.toc 已加载），隐藏原生 ComboFrame 后自绘，DFUI 模式 + 中文标签。下为原计划。

**来源**: `-Dragonflight3/mods/general/combopoints.lua` (~100 行)
**创建**: `dragonflight-fix/modules/ui/combopoints.lua`
**改动**: ~60 行新文件

**最简单的移植**，完全独立，盗贼/猫德专用。

### 2.5 HealComm 治疗预测 [未做]

**来源**: `-Dragonflight3/libs/libhealcomm.lua` (252 行)
**创建**: `dragonflight-fix/libs/libhealcomm.lua`
**改动**: ~150 行修改

**功能**: 队伍/团队治疗预测条，需修改 player.lua 和 mini.lua 显示预测 overlay。

### 2.6 怪物血量估算 [✅ 已完成]

> 已实现于 `libs/libhealth.lua`（317 行，.toc LIBS 段已加载），缓存写入存档变量 `DFUI_HealthDB`。下为原计划。

**来源**: `-Dragonflight3/libs/libhealth.lua` (244 行)
**创建**: `dragonflight-fix/libs/libhealth.lua`
**改动**: ~80 行修改

### 2.7 施法追踪 [未做]

**来源**: `-Dragonflight3/libs/libcast.lua` (81 行)
**创建**: `dragonflight-fix/libs/libcast.lua`
**改动**: ~50 行修改

### 2.8 小而美 QoL 功能（穿插实施） [未做]

> 下表 4 个文件均未创建。

| 功能 | 创建文件 | 改动量 |
|------|---------|--------|
| 自动截图 | `modules/ui/autoscreenshot.lua` | ~80 行 |
| 卖出价值 | `modules/ui/sellvalue.lua` | ~120 行 |
| 自动下坐骑/姿态舞蹈 | `modules/ui/tweaks.lua` | ~80 行 |
| 任务追踪增强 | `modules/ui/questtracker.lua` | ~150 行 |

---

## Phase 3: 视觉增强 [未做 / 面板改走独立架构]

> 3.1 环境边框、3.2 全局暗化、3.3 姓名板的对应文件（ambient.lua / darkui.lua / nameplates/）均未创建。
> 3.4 面板美化未按本计划的"逐文件移植 DF3 panels"路线，而是改用 `modules/panels/` 独立架构（已实现 19 个面板文件：bank/character/spellbook/tradeskill/social/mail/merchant/questlog 等），由专属设计文档跟踪（panel-skinning-progress.md、spellbook-* 系列、profession-panel-* 等）。本节计划已被该架构取代，留作背景。

### 3.1 环境边框 [未做]

**来源**: `-Dragonflight3/mods/general/ambient.lua` (~280 行)
**创建**: `dragonflight-fix/modules/ui/ambient.lua`

屏幕 4 边渐变条纹：正常黑色 / 战斗红色 / 休息青色。

### 3.2 全局暗化主题 [未做]

**来源**: `-Dragonflight3/mods/general/darkui.lua` (~220 行)
**创建**: `dragonflight-fix/modules/ui/darkui.lua`

替代当前逐模块的 `chatDarkMode` / `mapDarkMode` 等分散实现。

### 3.3 姓名板系统（分步实施） [未做]

**来源**: `-Dragonflight3/mods/nameplates/` (nameplates.lua 28K)

分 3 步：
1. **MVP**: 生命条美化 + 职业着色 (~500 行)
2. **增强**: 距离指示 + Debuff 显示 (~400 行)
3. **完整**: 焦点火力 + 高级功能 (~300 行)

### 3.4 面板美化（按使用频率分批） [已改走 modules/panels/ 独立架构]

> 实际实现未逐文件移植 DF3 panels，而是在 `modules/panels/` 下重建（见 .toc PANELS 段，已含 bank/character/spellbook/tradeskill/social/mail/merchant/questlog/trainer/dressup/inspect/macro/keybinding 等 19 个文件）。进度与坑位由专属文档跟踪：panel-skinning-progress.md、panel-known-issues.md、spellbook-* 系列、profession-panel-* 系列、worldmap-panel-design.md。下表为原 DF3 移植计划，仅留作参考。

**来源（参考）**: `-Dragonflight3/mods/panels/`

| 批次 | 面板 | 来源行数 | 当前对应 |
|------|------|---------|--------|
| 第 1 批 | bank.lua (银行) | 88 | ✅ modules/panels/bank.lua (88 行) |
| 第 1 批 | spellbook.lua (法术书) | 534 | ✅ modules/panels/spellbook.lua (1192 行，自制重建) |
| 第 2 批 | characterframe.lua (角色面板) | 260 | ✅ modules/panels/character.lua (820 行) |
| 第 2 批 | turtlepanels.lua (Turtle专属) | 240 | 见 panels/ 各 Turtle 相关文件 |
| 第 3 批 | worldmap/questlog/lootframe 等 | 各 80-330 | questlog/questframe 已建；战利品另见 Phase 5 |

---

## Phase 4: 自身优化 [部分完成]

### 4.1 修复 3 个已知 BUG [仍待办]

| BUG | 位置 | 状态 | 修复方案 |
|-----|------|------|---------|
| 暴雪高亮闪烁 | `chat.lua:3`（showButtons 项 BUG 备注仍在） | 未修 | 检查 ChatFrame highlight 锚点位置 |
| 斜杠命令未实现 | `map.lua:41`（textColor 项 BUG 备注仍在） | 未修 | 注册斜杠命令或移除注释 |
| 档案删除+残留 | `gui/prof.lua` | 待游戏内实证 | 修复双击事件和输入框清理逻辑 |

### 4.2 错误处理改进 [✅ 已完成（实现方式不同）]

> `core/error.lua` 已重写为 286 行：除聊天节流外，新增 BUG 抓取缓冲（feed "诊断"面板，存档变量 `DFUI_BUGS`）、来源黑名单 `SOURCE_BLOCKLIST`、订阅者通知模型、自动 toast 提示。未采用计划的"WARNING/ERROR/CRITICAL 三级"措辞，但"节流后改为缓冲而非完全静默"的目标已达成。注意 `max_errors = 2`（error.lua:2）仍在用于聊天去刷屏。下为原计划。

**修改**: `core/error.lua` (45 行 → ~100 行)

当前问题：仅节流 2 次后完全抑制所有错误。
改进：分层报告（WARNING 抑制 / ERROR 显示前 5 次 / CRITICAL 始终显示）。

### 4.3 施法条增强 [部分完成]

> `modules/cast/cast.lua` 当前 676 行，已注册 `SPELLCAST_CHANNEL_START/STOP/UPDATE` 并维护 channeling 状态（cast.lua:181-183、297-300）。Channel 中断红闪 / tick 指示器是否齐备待游戏内实证。下为原计划。

**修改**: `modules/cast/cast.lua` (676 行)

- 添加 Channel 中断红色闪烁动画
- 添加 Channel tick 指示器

### 4.4 单位框架增强

**修改**: player.lua / target.lua

- 战斗状态指示（`PLAYER_REGEN_DISABLED/ENABLED` 事件）
- 目标断线检测（灰色遮罩）
- 威胁指示框

### 4.5 字体路径去重

**修改**: `core/tools.lua` + player.lua / target.lua / mini.lua / cast.lua / bars.lua

提取字体路径映射到 `DFUI.tools.GetFont(name)`:
```lua
function DFUI.tools.GetFont(name)
    return 'Interface\\AddOns\\Dragonflight-Fix\\media\\fonts\\' .. name
end
```

替换 5 个文件中的重复路径拼接。

---

## .toc 当前实际加载顺序（2026-06-01 复核）

下为当前 `Dragonflight-Fix.toc` 实际内容（与计划"最终目标"不同：已新增 panels/ 与 loot/ 整套、bars/orbs、talents_desc/questxp 数据、gui/bugs+superwow；未引入 libhealcomm/libcast 及未实现的 Phase 2/3 模块）。`← PhaseX` 标记仅供溯源。

```
# CORE
core\core.lua
core\error.lua
core\tools.lua
core\statusbar.lua
core\compat.lua
core\first.lua

# DATA
data\tables.lua
data\debuffs.lua          ← Phase 0
data\talents_desc.lua
data\questxp.lua

# LIBS
libs\libtipscan.lua       ← Phase 0
libs\libspell.lua         ← Phase 0
libs\libdebuff.lua        ← Phase 0
libs\libguid.lua          ← Phase 1.7
libs\libevents.lua        ← Phase 1.8
libs\libhealth.lua        ← Phase 2.6

# MODULES
modules\bars\bars.lua
modules\bars\range.lua
modules\bars\orbs.lua
modules\cast\cast.lua
modules\chat\chat.lua
modules\bags\bags.lua
modules\map\map.lua
modules\map\collect.lua
modules\menu\menu.lua
modules\menu\addons.lua
modules\micro\micro.lua
modules\frames\frames.lua
# --- panels（Phase 3.4 改走的独立面板架构）---
modules\panels\paperdoll.lua
modules\panels\scrollbar.lua
modules\panels\bank.lua
modules\panels\character.lua
modules\panels\merchant.lua
modules\panels\questframe.lua
modules\panels\gossip.lua
modules\panels\questlog.lua
modules\panels\questlog_xp.lua
modules\panels\social.lua
modules\panels\mail.lua
modules\panels\trade.lua
modules\panels\trainer.lua
modules\panels\tradeskill.lua
modules\panels\dressup.lua
modules\panels\help.lua
modules\panels\openmail.lua
modules\panels\inspect.lua
modules\panels\macro.lua
modules\panels\spellbook.lua
modules\panels\keybinding.lua
# --- ui ---
modules\ui\ui.lua
modules\ui\tooltip.lua         ← Phase 1.4（部分）
modules\ui\talents.lua
modules\ui\errorHandler.lua
modules\ui\cooldowns.lua       ← Phase 1.1
modules\ui\itemcompare.lua     ← Phase 1.2
modules\ui\colors.lua          ← Phase 1.3
modules\ui\combopoints.lua     ← Phase 2.4
# --- unit ---
modules\unit\player.lua
modules\unit\target.lua
modules\unit\mini.lua
modules\unit\pvp.lua
modules\unit\auras.lua         ← Phase 0
modules\xprep\xprep.lua
modules\track\track.lua
# --- loot（本方案未覆盖，独立设计文档跟踪）---
modules\loot\loot.lua
modules\loot\roll.lua

# GUI
modules\gui\tools.lua
modules\gui\base.lua
modules\gui\elem.lua
modules\gui\home.lua
modules\gui\homeb.lua
modules\gui\info.lua
modules\gui\bugs.lua
modules\gui\prof.lua
modules\gui\mods.lua
modules\gui\shag.lua
modules\gui\superwow.lua
```

> 注：`talents.lua` 在 .toc 实际位于 `modules\ui\` 段（非计划文末误写的独立条目）；CORE 段实际顺序为 core.lua 先于 error.lua。

> 尚未引入：`libs\libhealcomm.lua`(2.5)、`libs\libcast.lua`(2.7)，以及 Phase 2.1/2.2/2.3/2.8、Phase 3.1/3.2/3.3 对应的全部模块文件。

---

## 每个模块的标准模板

所有新增模块统一使用此模式：

```lua
-- 注册默认配置（中文描述）
DFUI:NewDefaults("ModuleName", {
    enabled = {true, "启用"},
    -- 其他配置项...
})

-- 注册模块
DFUI:NewMod("ModuleName", priority, function()
    local setup = DFUI.tempDB.ModuleName
    if not setup.enabled then return end

    -- 条件检测（示例：SuperWoW 依赖）
    local hasSuperWoW = (UnitGUID ~= nil)
    if not hasSuperWoW then return end

    -- 模块实现...
end)

-- 可选：注册配置变化回调
DFUI:NewCallbacks("ModuleName", {
    enabled_changed = function(value)
        -- 响应开关切换
    end,
})
```

---

## API 翻译速查（DF3 → DFUI）

从 Dragonflight3 移植代码时的对照表：

```lua
-- 模块系统
DF:NewModule(mod, pri, evt, fn)  → DFUI:NewMod(mod, pri, fn)
DF:NewDefaults(mod, defs)        → DFUI:NewDefaults(mod, defs)  -- 注意值格式 {default, "描述"}
DF:NewCallbacks(mod, cbs)        → DFUI:NewCallbacks(mod, cbs)

-- 配置读写
DF.profile[mod][opt]             → DFUI.tempDB[mod][opt]  或  DFUI:GetTempDB(mod, opt)
DF.setups.mod                    → 直接用局部变量

-- Hook 系统
DF.hooks.HookScript(f, s, fn)   → HookScript(f, s, fn)  -- WoW 原生
DF.hooks.HookSecureFunc(n, fn)  → DFUI.env.hooksecurefunc(n, fn)
DF.common.KillFrame(f)          → f:Hide(); f:SetScript('OnShow', function() this:Hide() end)

-- UI 工具
DF.ui.Font(parent, size, ...)   → parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
DF.ui.Frame(parent, ...)        → CreateFrame('Frame', nil, parent)

-- 本地化
DF.L('English text')            → "中文文字"  -- 直接内联中文

-- 媒体资源路径
media['tex:actionbars:icon']    → 'Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\actionbars\\icon'
media['font:Expressway.ttf']    → 'Interface\\AddOns\\Dragonflight-Fix\\media\\fonts\\Expressway.ttf'

-- 服务器/依赖检测
DF.others.superWoW              → (UnitGUID ~= nil)
DF.others.unitXP                → (UnitXP ~= nil)
DF.others.isTurtle              → (GetRealmName() or ''):find('Turtle')
```

---

## 执行优先级总览

```
Week 1:  Phase 0 (激活已有文件) → Phase 1.1-1.3 (冷却数字/装备对比/职业配色)     [✅ 完成]
Week 2:  Phase 1.4-1.6 (Tooltip/聊天/配置迁移) → Phase 1.7-1.8 (GUID/事件库)     [1.4/1.5 部分，其余完成]
Week 3:  Phase 2.1-2.4 (挥击/CC监视/距离/连击点)                                  [仅 2.4 完成]
Week 4:  Phase 2.5-2.8 (HealComm/血量/施法/QoL小功能)                             [仅 2.6 完成]
Week 5+: Phase 3 (视觉增强) + Phase 4 (自身优化)，穿插进行                         [Phase3 未做/改架构; Phase4 部分]
```

> 本方案外的额外进展（不在原计划内）：`modules/loot/`（loot.lua + roll.lua，战利品/掷骰）、`modules/bars/orbs.lua`、`modules/panels/` 19 个面板、`modules/gui/bugs.lua`（诊断面板）与 `modules/gui/superwow.lua`、LibQuestXP 任务经验库。后续待办优先级建议：补完 1.4/1.5 → 取 Phase 2 剩余战斗增强（2.1 挥击 / 2.2 CC / 2.3 距离）→ Phase 4.1 两个 BUG（chat 高亮 / map 斜杠命令）。

每个 Phase 完成后在游戏内验证：
1. 插件加载无 Lua 报错
2. `/dfrl` 设置界面有对应配置页
3. 逐功能验证（见各 Phase 验证项）
4. 性能测试：主城 40 人场景下帧率 ≥ 30 FPS
