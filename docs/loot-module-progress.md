# Dragonflight-Fix 拾取模块 — 设计、实现与踩坑总结

## 一、设计思路

### 1.1 目标
为 Dragonflight-Fix 添加拾取模块，替换默认 Blizzard 拾取窗口和投骰窗口，视觉风格与现有 Dragonflight 模块统一。

### 1.2 参考分析
对比了 XLoot（专用拾取插件，~1800行，Ace2依赖）和 pfUI（全套UI拾取模块，~1072行）：

- **采纳 pfUI 的**：简洁代码架构、注销默认框体方式、BoP 自动确认、替换全局函数方式禁用默认投骰、投骰按钮独立 Y 偏移对齐
- **采纳 XLoot 的**：品质边框/高亮多层指示、物品类型信息行、钓鱼音效
- **不采纳的**：Ace2 依赖、pfUI 内部 API、XLoot 的 tooltip 扫描方式

### 1.3 架构决策
- 遵循 `DFUI:NewMod()` + `DFUI:NewDefaults()` 模块注册模式
- 两个文件：`loot.lua`（主拾取）+ `roll.lua`（投骰）
- roll.lua 通过 `DFUI.InitLootRoll` 属性函数由 loot.lua 调用初始化（避免 setfenv 环境隔离问题）
- 集成到 `frames.lua` 的 Ctrl+Alt+Shift 移动系统
- 10 个配置选项
- 零外部依赖，仅使用 WoW API + DFUI 内部工具

---

## 二、最终成果

### 代码规模

| 文件 | 行数 | 函数数 | 说明 |
|------|------|--------|------|
| `loot.lua` | 651 | 14 + 2回调 | 主拾取框体 + 自动拾取渐隐 |
| `roll.lua` | 319 | 8 | 投骰框体（由 loot.lua 调用初始化） |
| **合计** | **970** | **24** | |

### 配置项（10个）

| 配置项 | 类型 | 默认值 | 分组 |
|--------|------|--------|------|
| enabled | bool | true | — |
| mousecursor | checkbox | true | 基础 |
| autoloot | checkbox | false | 基础 |
| autopickup_bop | checkbox | true | 基础 |
| scale | slider | 1.0 | 外观 |
| quality_border | checkbox | true | 外观 |
| quality_glow | checkbox | true | 外观 |
| glow_threshold | slider | 2 | 外观 |
| show_item_type | checkbox | true | 外观 |
| roll_rarity_timer | checkbox | true | 投骰 |

---

## 三、功能实现状态（2026-04-06 最终）

### 3.1 主拾取框体 (loot.lua) ✅ 全部完成

| 功能 | 状态 |
|------|------|
| 替换默认 LootFrame | ✅ `UnregisterAllEvents()`（pfUI 方式） |
| DFUI 风格拾取窗口 | ✅ 暗色背景 + 金色渐变线 + 内阴影 |
| 手动点击拾取 | ✅ `LootButton` + `SetSlot()` + `Enable()` |
| 品质颜色名称 | ✅ `SafeQualityColor()` nil 安全 |
| 品质边框 | ✅ 图标边框染色 + 阈值控制 |
| 品质背景高亮 | ✅ 半透明品质色条 (alpha 0.12) |
| 物品类型信息行 | ✅ `GetItemInfo()` 获取类型/子类型 |
| 动态宽度 | ✅ 220-350px 根据物品名自适应 |
| 鼠标跟随定位 | ✅ `PositionFrameAtCursor()` + 边界检测 |
| 手动拖拽后固定位置 | ✅ 检测 DFUI_FRAMEPOS 切换模式 |
| ESC 关闭 | ✅ `UISpecialFrames` 注册 |
| Ctrl 试穿 / Shift 链接 | ✅ pfUI 方式：LootSlot 始终调用 |
| Master Loot 下拉菜单 | ✅ 使用 Blizzard `GroupLootDropDown` |
| 金币格式化 | ✅ 换行符替换为逗号 |
| 钓鱼音效 | ✅ `IsFishingLoot()` 检测 |
| BoP 自动确认 | ✅ 单人模式 `ConfirmLootSlot()` |
| 自动拾取（Lua层） | ✅ DFUI设置/Shift键/arg1 |
| 自动拾取渐隐 | ✅ 5秒停留 → 3秒渐隐 |
| SuperWoW DLL兼容 | ✅ `GetNumLootItems()==0` 不显示 |
| 槽位重排 | ✅ `RelayoutSlots()` 手动拾取后剩余上移 |
| 缩放设置回调 | ✅ 实时生效 |

### 3.2 投骰框体 (roll.lua) ✅ 全部完成

| 功能 | 状态 |
|------|------|
| 替换默认 GroupLootFrame | ✅ 替换 `_G.GroupLootFrame_OpenNewFrame`（pfUI 方式） |
| Need/Greed/Pass 按钮 | ✅ 原生纹理 + pfUI 式独立 Y 偏移对齐 |
| 倒计时状态条 | ✅ `GetLootRollTimeLeft()` + OnUpdate |
| 品质色计时条 | ✅ `roll_rarity_timer` 配置控制 |
| BoP/BoE 标识 | ✅ 红色 BoP / 绿色 BoE |
| 最多4个并发投骰 | ✅ 垂直堆叠，间距 8px |
| CANCEL_LOOT_ROLL 处理 | ✅ 按 rollID 查找并隐藏 |

### 3.3 UI 风格重构 ✅ 完成

| 改进 | 说明 |
|------|------|
| 图标放大 | loot 28→36px, roll 32→36px |
| 间距增加 | PADDING 8→12, SPACING 2→6 |
| 框体宽度 | 180-320 → 220-350 |
| Roll 布局分层 | 三行分离：名称/计时条/按钮 |
| Roll 框体高度 | 40→82px，呼吸感大幅提升 |
| 按钮对齐 | pfUI 式独立 BOTTOMLEFT + Y 偏移 |

### 3.4 已删除的功能
- 汇总浮窗（DFUILootSummary）→ 改为拾取窗口自身渐隐
- CHAT_MSG_LOOT 收集系统
- START_LOOT_ROLL 重复事件监听（导致双框体）

### 3.5 未实现的可选功能（design.md 中"可以有"级别）
- `show_quality_text` — 品质描述文字（精良/稀有/史诗）
- `roll_scale` — 投骰窗口独立缩放
- 草药采集/容器打开自动拾取（SPELLCAST_START 检测）
- 链接拾取物品到聊天频道
- Master Loot 增强菜单（按职业分组）

### 3.6 待验证的健壮性项目
- [ ] **Ctrl+Alt+Shift 拖拽移动** — 时序分析确认注册正确，但需游戏内实际测试拖拽和位置保存/恢复
- [ ] **配置面板 GUI** — 确认所有10个选项在 DFUI 设置界面中正常显示和切换，效果实时生效
- [ ] **兼容性：禁用模块** — 禁用 Loot 模块后是否正确恢复默认 Blizzard 拾取窗口
- [ ] **兼容性：XLoot 共存** — 与 XLoot 不同时启用时各自独立工作
- [ ] **多人 Master Loot 场景** — 当前使用 Blizzard 原生 GroupLootDropDown，需在团队副本中验证

---

## 四、踩坑记录（10个）

### 坑 1：`GetCVar("autoLootDefault")` 不存在 ✅
Vanilla 1.12 没有此 CVar，改用 `IsShiftKeyDown()`。

### 坑 2：默认拾取窗口仍然显示 ✅
`KillFrame()` 过度操作。方案：只用 `LootFrame:UnregisterAllEvents()`。

### 坑 3：SuperWoW DLL 层自动拾取 ✅
DLL 在 C++ 层拾取，`GetNumLootItems()` 返回 0。方案：直接 return 不显示。

### 坑 4：三层自动拾取竞争 ✅
DLL/客户端/Lua 三层。方案：统一流程，先渲染再判断。

### 坑 5：手动拾取无法点击 ✅
四个子原因。方案：`LootButton` + `SetSlot()` + `Enable()` + `EnableMouse(false)` + 始终调用 `LootSlot()`。

### 坑 6：汇总浮窗误触发 ✅
时间猜测不可靠。方案：删除汇总浮窗，改为拾取窗口自身渐隐。

### 坑 7：自动拾取渐隐不生效 ✅
`LOOT_SLOT_CLEARED` 在 `AutoLootAll()` 期间隐藏所有槽位。方案：`autoLootPending` 标志阻止。

### 坑 8：Roll 模块从未执行 ✅
`setfenv` 环境隔离导致 `_G.DFUI_InitLootRoll` 不可见。方案：改用 `DFUI.InitLootRoll`（表属性函数）。

### 坑 9：投骰框体重复显示 ✅
`GroupLootFrame_OpenNewFrame` + `START_LOOT_ROLL` 双重触发。方案：移除 `START_LOOT_ROLL` 监听。

### 坑 10：投骰按钮不对齐 ✅
WoW 原生 `UI-GroupLoot-Dice/Coin/Pass` 纹理内置 padding 不一致。方案：pfUI 式独立 `BOTTOMLEFT` 绝对定位 + 逐个 Y 偏移补偿（Need=9, Greed=8, Pass=10）。

---

## 五、关键代码位置（最终版本）

### loot.lua (651行)

| 功能 | 位置 | 说明 |
|------|------|------|
| 模块注册 + defaults | 4-15 | 10个配置项 |
| SafeQualityColor | 62 | nil 安全品质色 |
| PositionFrameAtCursor | 66 | 鼠标跟随 + 边界检测 |
| StopFade / StartFade | 86-116 | 自动拾取渐隐状态机 |
| SetupSlotVisuals | ~122-204 | 槽位视觉构建 |
| ApplySlotQuality | ~206-222 | 品质边框/高亮应用 |
| CreateSlot | ~224-280 | LootButton 交互槽位 |
| AutoLootAll | ~282-292 | 自动拾取 |
| HandleBindConfirm | ~294-306 | BoP 自动确认 |
| UpdateLootFrame | ~308-420 | 核心渲染 |
| RelayoutSlots | ~422-468 | 手动拾取后重排 |
| OnEvent | ~473-558 | 事件分发 |
| Init | ~564-614 | 初始化 |
| Callbacks | ~636-649 | scale/mousecursor 回调 |

### roll.lua (319行)

| 功能 | 位置 | 说明 |
|------|------|------|
| DFUI.InitLootRoll | 5 | 入口函数 |
| DisableAllButtons | ~54 | 禁用三按钮 |
| CreateRollButton | ~63 | 按钮工厂 |
| CreateRollFrame | ~83-242 | 投骰框体创建 |
| UpdateRollFrame | ~223-260 | 数据填充 |
| OnCancelRoll | ~264 | 取消投骰 |
| OnStartRoll | ~277 | 开始投骰 |
| GroupLootFrame_OpenNewFrame | ~305 | 全局函数替换 |

---

## 六、经验教训

1. **setfenv 环境隔离**：跨文件通信必须通过 `DFUI` 表属性，不能用全局变量
2. **不要重复注册事件**：替换全局函数已覆盖对应事件，同时监听会双重触发
3. **WoW 原生纹理尺寸不一致**：GroupLoot 按钮纹理各有不同内置 padding，需逐个 Y 偏移补偿（pfUI 方案）
4. **LootButton 帧类型**：Vanilla `LootSlot()` 需要 `LootButton` + `SetSlot()` 安全上下文
5. **SetBackdrop 隐式启用鼠标**：子 Frame 的 `SetBackdrop()` 会拦截父 Button 点击
6. **三层拾取竞争**：DLL/客户端/Lua 需统一流程
7. **UI 呼吸感**：图标 36px + PADDING 12 + SPACING 6 比 28/8/2 舒适得多
8. **Roll 框体分层**：82px 高度三行分离（名称/计时条/按钮）比 40px 单行塞满好得多
