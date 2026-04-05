# dragonflight-fix 优化执行方案

> 生成日期：2026-03-25
> 基于：dragonflight-comparison.md / dragonflight-feature-discovery.md / dragonflight-fix-optimization-guide.md / dragonflight-fix-talent-planning.md

---

## 当前状态审计

| 项目 | 状态 | 说明 |
|------|------|------|
| 天赋规划功能 | **已完成** | talents.lua 591→980 行，含规划/模拟/方案切换 |
| libs/ 3个库文件 | **已复制，未加载** | libtipscan/libspell/libdebuff 在磁盘上但 .toc 未引用 |
| data/debuffs.lua | **已复制，未加载** | 933 条减益数据库在磁盘上但 .toc 未引用 |
| modules/unit/auras.lua | **已复制，未加载** | Buff/Debuff UI 在磁盘上但 .toc 未引用 |
| .toc 当前状态 | 31 个模块文件 | 无 libs/、无 debuffs.lua、无 auras.lua |

---

## Phase 0: 激活已有文件 [预计 1-2 小时]

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

## Phase 1: 高价值低成本功能 [预计 3-5 天]

### 1.1 冷却时间数字显示

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

### 1.2 物品比较（装备对比）

**来源**: `-Dragonflight3/mods/general/itemcompare.lua` (~150 行)
**创建**: `dragonflight-fix/modules/ui/itemcompare.lua`
**改动**: ~100 行新文件 + .toc 追加

**实现步骤**:
1. 读取 DF3 源码，核心逻辑：Hook `GameTooltip:SetBagItem` / `SetInventoryItem` 等
2. 新建模块，Shift 悬停时创建第二个 Tooltip 显示已穿戴装备
3. 装备槽映射表（16 个槽位: Head/Neck/Shoulder/...）

**验证**: Shift 悬停背包装备时并排显示已穿戴对比

### 1.3 职业配色方案统一管理

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

### 1.4 Tooltip 增强

**来源**: `-Dragonflight3/mods/tooltip/tooltip.lua` (304 行)
**修改**: `dragonflight-fix/modules/ui/tooltip.lua` (当前 54 行 → ~200 行)
**改动**: ~150 行追加

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

### 1.5 聊天系统增强

**来源**: `-Dragonflight3/mods/chat/chat.lua` (775 行)
**修改**: `dragonflight-fix/modules/chat/chat.lua` (当前 307 行 → ~500 行)
**改动**: ~200 行追加

**新增功能**:
- URL 自动检测并高亮（`http://` / `https://` / `www.`）
- 时间戳（`[HH:MM]` 格式）
- 频道缩写（G/P/R/BG）
- 聊天淡出控制

**注意**: 保留现有中文化逻辑，仅追加功能

### 1.6 配置版本迁移系统

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

### 1.7 GUID 追踪库

**来源**: `-Dragonflight3/libs/libguid.lua` (244 行)
**创建**: `dragonflight-fix/libs/libguid.lua`
**改动**: ~100 行修改（API 翻译 DF→DFUI）+ .toc 追加

**实现步骤**:
1. 复制 libguid.lua，将 `DF.` 引用改为 `DFUI.`
2. 伪 GUID 格式：`pGUID-name-level-class-subzone-counter`
3. 条件检测：优先 `UnitGUID`（SuperWoW），无则用伪 GUID
4. .toc 中 `libs\libdebuff.lua` 后追加 `libs\libguid.lua`

### 1.8 自定义事件库

**来源**: `-Dragonflight3/libs/libevents.lua` (~120 行)
**创建**: `dragonflight-fix/libs/libevents.lua`
**改动**: ~80 行修改 + .toc 追加

**提供事件**:
- `PLAYER_AFTER_ENTERING_WORLD`（延迟 50ms，解决原版 PLAYER_ENTERING_WORLD 时序问题）
- `SYNC_READY`（延迟 2s，确保所有模块初始化完成）

---

## Phase 2: 战斗增强功能 [预计 3-5 天]

### 2.1 挥击计时器

**来源**: `-Dragonflight3/mods/unitframes/swingtimer.lua` (~300 行)
**创建**: `dragonflight-fix/modules/unit/swingtimer.lua`
**改动**: ~200 行新文件
**依赖**: SuperWoW（条件检测 `UnitGUID ~= nil`）

**功能**:
- 主手/副手/远程武器倒计时条
- 英勇一击/劈砍队列检测
- 躲闪加速支持
- 无 SuperWoW 时隐藏（优雅降级）

### 2.2 CC 控制监视

**来源**: `-Dragonflight3/mods/general/nocontrol.lua` (~700 行)
**创建**: `dragonflight-fix/modules/ui/nocontrol.lua`
**改动**: ~200 行新文件

**功能**:
- 8 种 CC 类型分类（眩晕/沉默/恐惧/缚根/催眠/魅惑/致残/减速）
- 被控时屏幕中央显示控制类型图标+文字
- 可用中断法术列表提示
- 脉冲发光效果

**需中文化**: CC 类型名称、法术名称列表

### 2.3 距离显示器

**来源**: `-Dragonflight3/mods/general/distance.lua` (~400 行)
**创建**: `dragonflight-fix/modules/ui/distance.lua`
**改动**: ~250 行新文件
**依赖**: UnitXP（条件检测 `UnitXP ~= nil`）

### 2.4 连击点可视化

**来源**: `-Dragonflight3/mods/general/combopoints.lua` (~100 行)
**创建**: `dragonflight-fix/modules/ui/combopoints.lua`
**改动**: ~60 行新文件

**最简单的移植**，完全独立，盗贼/猫德专用。

### 2.5 HealComm 治疗预测

**来源**: `-Dragonflight3/libs/libhealcomm.lua` (252 行)
**创建**: `dragonflight-fix/libs/libhealcomm.lua`
**改动**: ~150 行修改

**功能**: 队伍/团队治疗预测条，需修改 player.lua 和 mini.lua 显示预测 overlay。

### 2.6 怪物血量估算

**来源**: `-Dragonflight3/libs/libhealth.lua` (244 行)
**创建**: `dragonflight-fix/libs/libhealth.lua`
**改动**: ~80 行修改

### 2.7 施法追踪

**来源**: `-Dragonflight3/libs/libcast.lua` (81 行)
**创建**: `dragonflight-fix/libs/libcast.lua`
**改动**: ~50 行修改

### 2.8 小而美 QoL 功能（穿插实施）

| 功能 | 创建文件 | 改动量 |
|------|---------|--------|
| 自动截图 | `modules/ui/autoscreenshot.lua` | ~80 行 |
| 卖出价值 | `modules/ui/sellvalue.lua` | ~120 行 |
| 自动下坐骑/姿态舞蹈 | `modules/ui/tweaks.lua` | ~80 行 |
| 任务追踪增强 | `modules/ui/questtracker.lua` | ~150 行 |

---

## Phase 3: 视觉增强 [预计 5-7 天]

### 3.1 环境边框

**来源**: `-Dragonflight3/mods/general/ambient.lua` (~280 行)
**创建**: `dragonflight-fix/modules/ui/ambient.lua`

屏幕 4 边渐变条纹：正常黑色 / 战斗红色 / 休息青色。

### 3.2 全局暗化主题

**来源**: `-Dragonflight3/mods/general/darkui.lua` (~220 行)
**创建**: `dragonflight-fix/modules/ui/darkui.lua`

替代当前逐模块的 `chatDarkMode` / `mapDarkMode` 等分散实现。

### 3.3 姓名板系统（分步实施）

**来源**: `-Dragonflight3/mods/nameplates/` (nameplates.lua 28K)

分 3 步：
1. **MVP**: 生命条美化 + 职业着色 (~500 行)
2. **增强**: 距离指示 + Debuff 显示 (~400 行)
3. **完整**: 焦点火力 + 高级功能 (~300 行)

### 3.4 面板美化（按使用频率分批）

**来源**: `-Dragonflight3/mods/panels/`

| 批次 | 面板 | 来源行数 | 优先级 |
|------|------|---------|--------|
| 第 1 批 | bank.lua (银行) | 88 | 最简单入门 |
| 第 1 批 | spellbook.lua (法术书) | 534 | 高频使用 |
| 第 2 批 | characterframe.lua (角色面板) | 260 | |
| 第 2 批 | turtlepanels.lua (Turtle专属) | 240 | Turtle WoW 特有 |
| 第 3 批 | worldmap/questlog/lootframe 等 | 各 80-330 | 按需 |

---

## Phase 4: 自身优化 [穿插进行]

### 4.1 修复 3 个已知 BUG

| BUG | 位置 | 修复方案 |
|-----|------|---------|
| 暴雪高亮闪烁 | `chat.lua:3` | 检查 ChatFrame highlight 锚点位置 |
| 斜杠命令未实现 | `map.lua:41` | 注册 `/dfrlmap` 命令或移除注释 |
| 档案删除+残留 | `gui/prof.lua` | 修复双击事件和输入框清理逻辑 |

### 4.2 错误处理改进

**修改**: `core/error.lua` (45 行 → ~100 行)

当前问题：仅节流 2 次后完全抑制所有错误。
改进：分层报告（WARNING 抑制 / ERROR 显示前 5 次 / CRITICAL 始终显示）。

### 4.3 施法条增强

**修改**: `modules/cast/cast.lua` (729 行)

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

## .toc 最终目标加载顺序

```
# CORE
core\error.lua
core\core.lua
core\tools.lua
core\statusbar.lua
core\compat.lua
core\first.lua

# DATA
data\tables.lua
data\debuffs.lua

# LIBS (按依赖顺序)
libs\libtipscan.lua
libs\libspell.lua
libs\libdebuff.lua
libs\libguid.lua          ← Phase 1.7
libs\libevents.lua        ← Phase 1.8
libs\libhealcomm.lua      ← Phase 2.5
libs\libhealth.lua        ← Phase 2.6
libs\libcast.lua          ← Phase 2.7

# MODULES
modules\bars\bars.lua
modules\bars\range.lua
modules\cast\cast.lua
modules\chat\chat.lua
modules\bags\bags.lua
modules\map\map.lua
modules\map\collect.lua
modules\menu\menu.lua
modules\menu\addons.lua
modules\micro\micro.lua
modules\frames\frames.lua
modules\ui\ui.lua
modules\ui\tooltip.lua
modules\ui\talents.lua
modules\ui\errorHandler.lua
modules\ui\cooldowns.lua       ← Phase 1.1
modules\ui\itemcompare.lua     ← Phase 1.2
modules\ui\colors.lua          ← Phase 1.3
modules\ui\nocontrol.lua       ← Phase 2.2
modules\ui\distance.lua        ← Phase 2.3
modules\ui\combopoints.lua     ← Phase 2.4
modules\ui\autoscreenshot.lua  ← Phase 2.8
modules\ui\sellvalue.lua       ← Phase 2.8
modules\ui\tweaks.lua          ← Phase 2.8
modules\ui\questtracker.lua    ← Phase 2.8
modules\ui\ambient.lua         ← Phase 3.1
modules\ui\darkui.lua          ← Phase 3.2
modules\unit\player.lua
modules\unit\target.lua
modules\unit\mini.lua
modules\unit\pvp.lua
modules\unit\auras.lua         ← Phase 0
modules\unit\swingtimer.lua    ← Phase 2.1
modules\xprep\xprep.lua
modules\track\track.lua

# GUI
modules\gui\tools.lua
modules\gui\base.lua
modules\gui\elem.lua
modules\gui\home.lua
modules\gui\homeb.lua
modules\gui\info.lua
modules\gui\prof.lua
modules\gui\mods.lua
modules\gui\shag.lua
```

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
Week 1:  Phase 0 (激活已有文件) → Phase 1.1-1.3 (冷却数字/装备对比/职业配色)
Week 2:  Phase 1.4-1.6 (Tooltip/聊天/配置迁移) → Phase 1.7-1.8 (GUID/事件库)
Week 3:  Phase 2.1-2.4 (挥击/CC监视/距离/连击点)
Week 4:  Phase 2.5-2.8 (HealComm/血量/施法/QoL小功能)
Week 5+: Phase 3 (视觉增强) + Phase 4 (自身优化)，穿插进行
```

每个 Phase 完成后在游戏内验证：
1. 插件加载无 Lua 报错
2. `/dfrl` 设置界面有对应配置页
3. 逐功能验证（见各 Phase 验证项）
4. 性能测试：主城 40 人场景下帧率 ≥ 30 FPS
