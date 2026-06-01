# Dragonflight-Fix 拾取模块设计方案

## 1. 背景与目标

Dragonflight-Fix 是一个全面的现代化 UI 美化插件，目前覆盖了动作条、施法条、背包、单位框体、天赋、聊天等模块，但**缺少拾取(Loot)功能**。玩家拾取时仍使用原版 Blizzard 拾取窗口，与整体 Dragonflight 风格不统一。

**目标**：为 Dragonflight-Fix 添加拾取模块，替换默认拾取窗口，提供现代化视觉体验和实用增强功能。

---

## 2. 参考系统分析

### 2.1 XLoot（专用拾取插件，~1800 行）

**可借鉴的设计**：
- 丰富的物品信息展示：品质文字（稀有/史诗等）、物品类型/子类型（胸甲, 锁甲）
- Swift Loot 悬停自动拾取系统：鼠标悬停尸体 → 释放鼠标 → 自动拾取全部
- 一键链接拾取物品到聊天频道，支持品质阈值过滤
- 动态宽度调整，根据物品名长度自适应
- 品质边框 + 背景高亮的多层视觉指示，可设阈值
- 钓鱼拾取音效检测
- 高度可定制的颜色/缩放/布局（25+ 配置项）

**不采纳的部分**：
- Ace2 框架依赖 — Dragonflight-Fix 不使用 Ace2
- Tooltip 扫描获取物品信息的陈旧方式
- 过多的配置项增加维护复杂度

**关键代码参考**：
- 主逻辑：`Interface/AddOns/XLoot/XLoot.lua`（991 行）
  - Hook 替换默认拾取：第 90-108 行 `OnEnable()`
  - 核心拾取循环：第 420-597 行 `Update()`
  - Swift Loot 系统：第 170-313 行
  - 鼠标跟随定位：第 624-645 行 `PositionAtCursor()`
  - 链接拾取物品：第 822-945 行 `LinkLoot()` + `BuildChannelMenu()`
- 投骰：`Interface/AddOns/XLootGroup/XLootGroup.lua`（277 行）
  - 投骰框体创建：第 200-276 行 `GroupBuildRow()`
  - 倒计时动画：第 153-174 行 `RollUpdateClosure()`

### 2.2 pfUI（全套 UI 的拾取模块，~1072 行）

**可借鉴的设计**：
- 简洁的代码实现（1072 行完成全部功能，比 XLoot 少 40%）
- Master Loot 增强：按职业分组的层级菜单、银行家/附魔师角色指定
- 投骰实时监控：解析 CHAT_MSG_SYSTEM 自动判定赢家、平局重骰
- BoP 自动确认：单人模式下自动拾取绑定物品
- 品质颜色计时条：投骰倒计时条颜色匹配物品品质

**不采纳的部分**：
- pfUI 内部 API 依赖（CreateBackdrop、UpdateMovable 等）
- 并发投骰限制（最多 4 个）
- 配置项过少（仅 7 个）

**关键代码参考**：
- 拾取框体：`_dev/pfUI-master/modules/loot.lua`（750 行）
  - 事件处理：第 639-730 行
  - 框体更新：第 436-518 行 `UpdateLootFrame()`
  - Master Loot 菜单：第 222-305 行 `BuildRaidMenu()`
  - 投骰分配：第 37-220 行 `RaidRoll()` / `RequestRolls()` / `BuildSpecialRollsMenu()`
- 投骰窗口：`_dev/pfUI-master/modules/roll.lua`（322 行）
  - 投骰监控：第 16-36 行 CHAT_MSG_LOOT 解析
  - 框体外观：第 279-312 行

---

## 3. 设计原则

### 3.1 架构一致性
- 遵循 `DFUI:NewMod()` + `DFUI:NewDefaults()` 模块注册模式
- 使用 `DFUI.tools` 现有工具函数（CreateDFUIFrame、CreateFont、KillFrame 等）
- 通过 `DFUI:GetTempDB()` / `DFUI:SetTempDB()` 读写配置
- 事件驱动初始化：`PLAYER_ENTERING_WORLD` 触发模块加载

### 3.2 视觉统一性
- 暗色背景 `{0, 0, 0, 0.5}` + 灰色边框 `{0.3, 0.3, 0.3, 0.8}`
- 金色装饰线 `{1, 0.82, 0}` 配合 `T.GradientLine()`
- 使用 `BigNoodleTitling.ttf` 字体，通过 `T.CreateFont()` 创建
- 标准 Backdrop 模式：`WHITE8X8` + `UI-Tooltip-Border`
- 品质颜色使用 WoW 内置 `ITEM_QUALITY_COLORS` 表

### 3.3 功能取舍
- **必须有**：替换默认拾取窗口、品质视觉指示、鼠标跟随定位、ESC 关闭
- **应该有**：自动拾取、BoP 自动确认、投骰窗口美化
- **可以有**：Master Loot 增强、链接拾取、投骰监控
- **不做**：过度配置化（控制在 10-15 个选项内）

### 3.4 零依赖
- 不引入 Ace2 或任何外部库
- 仅使用 WoW API + DFUI 内部工具
- 保持与现有 Dragonflight-Fix 模块相同的依赖层级

---

## 4. 模块结构

```
modules/
└── loot/
    ├── loot.lua          -- 主拾取框体（替换默认 LootFrame）
    └── roll.lua          -- 投骰框体（替换默认 GroupLootFrame）
```

在 `Dragonflight-Fix.toc` 中添加：
```
modules\loot\loot.lua
modules\loot\roll.lua
```

---

## 5. 框体移动集成 (Ctrl+Alt+Shift)

### 5.1 现有机制

Dragonflight-Fix 通过 `modules/frames/frames.lua` 实现统一的框体移动系统：

1. **触发方式**：同时按住 `Ctrl + Alt + Shift` 三个修饰键
2. **视觉反馈**：显示金色 overlay 覆盖层 (`{1, 0.82, 0, 0.5}`) + 全屏网格线
3. **拖拽移动**：overlay 的 `OnMouseDown` → `frame:StartMoving()`
4. **位置保存**：`OnMouseUp` → `SaveFramePosition(frame)` → 写入 `DFUI_FRAMEPOS[frameName]`
5. **位置恢复**：`PLAYER_ENTERING_WORLD` → `RestoreFramePositions()` → 从 `DFUI_FRAMEPOS` 读取

### 5.2 拾取框体集成方案

拾取框体 `pfDFLootFrame` 需要注册到 `framesToMakeMovable` 列表中：

```lua
-- 在 loot.lua 中创建具名框体
local lootFrame = CreateFrame("Frame", "pfDFLootFrame", UIParent)

-- 在 frames.lua 的 framesToMakeMovable 列表中添加：
DFUI.lootFrame,         -- 拾取框体
```

**移动与鼠标跟随的交互逻辑**：
- 默认：拾取框体跟随鼠标光标出现（`mousecursor` 选项）
- 如果玩家通过 Ctrl+Alt+Shift 手动拖拽过位置 → `DFUI_FRAMEPOS["pfDFLootFrame"]` 存在
- 此时切换为固定位置模式，不再跟随光标
- 玩家可在设置中重新启用鼠标跟随（清除保存的位置）

**投骰框体** `pfDFRollFrame` 同理注册到移动列表，支持 Ctrl+Alt+Shift 拖拽。

### 5.3 方向微调

框体进入移动模式后，overlay 四角会显示 U/D/L/R 方向按钮（`CreateDirectionButton`），每次点击移动 1px，用于精确对齐。

---

## 6. 功能设计

### 6.1 主拾取框体 (loot.lua)

#### 6.1.1 模块注册

```lua
DFUI:NewDefaults("Loot", {
    enabled           = {true},
    mousecursor       = {true, "checkbox", nil, nil, "基础", 1, "拾取窗口跟随鼠标光标（手动拖拽位置后自动切换为固定模式）"},
    autoloot          = {false, "checkbox", nil, nil, "基础", 2, "悬停尸体时自动拾取所有物品"},
    autopickup_bop    = {true, "checkbox", nil, nil, "基础", 3, "单人时自动确认拾取绑定物品"},
    scale             = {1.0, "slider", {0.5, 1.5, 0.05}, nil, "外观", 1, "拾取窗口缩放"},
    quality_border    = {true, "checkbox", nil, nil, "外观", 2, "物品边框显示品质颜色"},
    quality_glow      = {true, "checkbox", nil, nil, "外观", 3, "稀有及以上品质物品背景高亮"},
    glow_threshold    = {2, "dropdown", {"0|灰色", "1|白色", "2|绿色", "3|蓝色", "4|紫色", "5|橙色"}, "quality_glow", "外观", 4, "背景高亮的最低品质"},
    show_quality_text = {false, "checkbox", nil, nil, "外观", 5, "显示品质描述文字（精良/稀有/史诗等）"},
    show_item_type    = {true, "checkbox", nil, nil, "外观", 6, "显示物品类型（武器/护甲/任务物品等）"},
})

DFUI:NewMod("Loot", 1, function() ... end)
```

#### 6.1.2 替换默认拾取窗口

参考 pfUI 的方式（比 XLoot 更简洁）：

```
事件流程：
LOOT_OPENED → 隐藏默认 LootFrame → 显示自定义框体 → 填充物品槽
LOOT_SLOT_CLEARED → 隐藏对应槽位
LOOT_CLOSED → 隐藏自定义框体
OPEN_MASTER_LOOT_LIST → 打开 Master Loot 下拉菜单
LOOT_BIND_CONFIRM → 自动确认 BoP（如果单人且已启用）
```

替换方式：注销默认 LootFrame 的所有事件（参考 pfUI 第 732 行），而非 XLoot 的多层 Hook 方式。

#### 6.1.3 框体布局

```
┌─────────────────────────────────────┐
│ ═══════════ 金色渐变线 ═══════════  │  ← T.GradientLine("TOP")
│                                     │
│  ┌────┐                             │
│  │icon│ 沃金之眼               x3   │  ← 物品名(品质色) + 数量
│  │28px│ 任务物品 · 精良              │  ← 物品类型 + 品质文字(金色小字)
│  └────┘                             │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │  ← 半透明分割线
│  ┌────┐                             │
│  │icon│ 锋利的爪子             x5   │
│  │28px│ 商品                         │
│  └────┘                             │
│  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄   │
│  ┌────┐                             │
│  │ $ │ 2银 35铜                     │  ← 金币行
│  └────┘                             │
│                                     │
│ ═══════════ 金色渐变线 ═══════════  │  ← T.GradientLine("BOTTOM")
└─────────────────────────────────────┘
  ↑                                 ↑
  最小宽度 180px      最大宽度 320px (动态)

  ● 背景：DFUI 标准暗色 {0,0,0,0.7} + 边框 {0.3,0.3,0.3,0.8}
  ● 品质 ≥ 阈值的物品：图标边框染色 + 半透明品质色背景条
  ● 悬停：QuestTitleHighlight 高亮 + GameTooltip 物品提示
  ● 左键：拾取物品  右键：关闭窗口
  ● Ctrl+Alt+Shift：进入移动模式，拖拽固定位置
```

**视觉风格参考（与现有 DFUI 模块统一）**：

| 元素 | 样式 | 来源 |
|------|------|------|
| 背景 | `WHITE8X8` + `UI-Tooltip-Border`, 暗色半透明 | 标准 DFUI Backdrop |
| 装饰线 | 金色渐变 `{1, 0.82, 0}` | `T.GradientLine()` |
| 字体 | `BigNoodleTitling.ttf`, OUTLINE | `T.CreateFont()` |
| 图标裁切 | TexCoord `.07, .93, .07, .93` | 去除 Blizzard 图标边框 |
| 品质色 | `ITEM_QUALITY_COLORS[quality]` | WoW 内置表 |
| 分割线 | `WHITE8X8` 1px, `{0.3, 0.3, 0.3, 0.3}` | 极淡灰色 |
| 信息文字 | 金色 `{1, 0.82, 0, 0.8}`, 小一号字体 | DFUI 金色标准 |
| 悬停高亮 | `UI-QuestTitleHighlight` | DFUI 标准高亮 |
| 移动 overlay | 金色半透明 `{1, 0.82, 0, 0.5}` | Frames 模块统一样式 |

#### 6.1.4 物品槽位组件

每个槽位（高度 ~36px，含信息行时 ~48px）包含：
- **图标框** — 28x28 带 backdrop，品质边框颜色
- **物品名** — `T.CreateFont()`，品质颜色文字，左对齐
- **数量** — 图标右下角叠加显示（数量 > 1 时）
- **品质条** — 半透明品质色覆盖条（alpha 0.12），参考 pfUI 的 rarity indicator
- **悬停高亮** — 标准 QuestTitleHighlight 材质
- **信息行**（可选）— 物品类型 + 品质文字，较小字号，金色 `{1, 0.82, 0, 0.8}`

#### 6.1.5 鼠标跟随定位

参考 XLoot 的 `PositionAtCursor()` 实现：
- 获取光标屏幕坐标，转换为 UI 坐标
- 边界检测：确保框体不超出屏幕
- 偏移：光标右下方 (8, -8) 像素

#### 5.1.6 自动拾取 (Auto Loot)

简化版 Swift Loot，不需要 XLoot 那样复杂的鼠标事件链：
- 检测 `LOOT_OPENED` 时，如果开启自动拾取或按住 Shift
- 遍历所有槽位调用 `LootSlot(i)`
- 背包满时通过 `UI_ERROR_MESSAGE` 事件停止
- 草药采集/容器打开时自动触发（检测 SPELLCAST_START）

#### 5.1.7 BoP 自动确认

参考 pfUI 的实现：
- `LOOT_BIND_CONFIRM` 事件触发时
- 检测是否单人（`GetNumPartyMembers() == 0` 且 `GetNumRaidMembers() == 0`）
- 单人时自动调用 `ConfirmLootSlot(slot)`

#### 5.1.8 金币格式化

将金币多行文本转为单行：`"金\n银\n铜"` → `"金, 银, 铜"`

#### 5.1.9 钓鱼检测

参考 XLoot：`IsFishingLoot()` 为真时播放 `PlaySound("FISHING REEL IN")`

---

### 6.2 投骰框体 (roll.lua)

#### 6.2.1 模块注册

投骰设置合并到 Loot 模块的 defaults 中：

```lua
-- 追加到 Loot defaults
roll_scale        = {1.0, "slider", {0.5, 1.5, 0.05}, nil, "投骰", 1, "投骰窗口缩放"},
roll_rarity_timer = {true, "checkbox", nil, nil, "投骰", 2, "计时条颜色匹配物品品质"},
```

#### 6.2.2 框体布局

```
┌──────────────────────────────────────────────────────┐
│  ┌────┐                                              │
│  │icon│  沃金之眼（品质色）      [🎲][💰][❌]         │
│  │32px│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░  45s            │
│  └────┘                                              │
│ ═══════════════ 金色渐变线 ═══════════════════════   │
└──────────────────────────────────────────────────────┘
       ↕ 4px 间距
┌──────────────────────────────────────────────────────┐
│  ┌────┐                                              │
│  │icon│  蓝龙邮戒（品质色）      [🎲][💰][❌]         │
│  │32px│  ▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░  30s            │
│  └────┘                                              │
│ ═══════════════ 金色渐变线 ═══════════════════════   │
└──────────────────────────────────────────────────────┘

  ● 图标 32x32，品质边框
  ● Need/Greed/Pass 三按钮：WoW 内置 UI-GroupLoot-Dice/Coin/Pass 材质
  ● 倒计时条：UI-StatusBar 材质，颜色可选匹配品质或固定色
  ● 最多 4 个并发投骰窗口，垂直堆叠，间距 4px
  ● 点击按钮后该按钮高亮，其余灰显
  ● 背景/边框/装饰线与主拾取框体统一
  ● 支持 Ctrl+Alt+Shift 拖拽移动（注册到 framesToMakeMovable）
```

#### 6.2.3 事件处理

```
START_LOOT_ROLL → 创建投骰框体，填充物品信息，启动倒计时
CANCEL_LOOT_ROLL → 移除对应投骰框体
```

倒计时通过 `OnUpdate` 脚本实现，参考 XLootGroup 的 `RollUpdateClosure()`。

---

## 7. 配置选项汇总

| 选项 | 类型 | 默认值 | 说明 | 实现状态 |
|------|------|--------|------|----------|
| enabled | checkbox | true | 启用拾取模块 | ✅ |
| mousecursor | checkbox | true | 跟随鼠标光标 | ✅ |
| autoloot | checkbox | false | 悬停自动拾取 | ✅ |
| autopickup_bop | checkbox | true | 单人自动确认 BoP | ✅ |
| scale | slider | 1.0 | 框体缩放 (0.5-1.5) | ✅ |
| quality_border | checkbox | true | 品质颜色边框 | ✅ |
| quality_glow | checkbox | true | 品质背景高亮 | ✅ |
| glow_threshold | slider | 2(绿色) | 高亮最低品质（实现为 slider 而非 dropdown） | ✅ |
| show_item_type | checkbox | true | 显示物品类型 | ✅ |
| roll_rarity_timer | checkbox | true | 投骰计时条品质色 | ✅ |
| ~~show_quality_text~~ | ~~checkbox~~ | ~~false~~ | ~~显示品质描述~~ | 未实现（可选） |
| ~~roll_scale~~ | ~~slider~~ | ~~1.0~~ | ~~投骰窗口缩放~~ | 未实现（可选） |

实际 10 个配置选项。`show_quality_text` 和 `roll_scale` 为可选功能，暂未实现。

---

## 8. 实现顺序与完成状态

### 阶段一：基础拾取框体 ✅ 已完成
1. ✅ 模块注册 + defaults 定义
2. ✅ 替换默认 LootFrame（注销事件）
3. ✅ 创建自定义拾取框体（暗色背景 + 金色渐变线）
4. ✅ 物品槽位渲染（图标 + 品质色名称 + 数量）
5. ✅ 鼠标跟随定位 + 边界检测
6. ✅ 左键拾取 + 右键关闭
7. ✅ ESC 关闭支持

### 阶段二：视觉增强 ✅ 已完成
1. ✅ 品质边框颜色
2. ✅ 品质背景高亮条
3. ✅ 物品类型信息行
4. ✅ 动态宽度调整
5. ✅ 金币格式化
6. ✅ 钓鱼音效

### 阶段三：自动拾取 ✅ 已完成
1. ✅ 自动拾取开关（Shift 键检测 + DFUI 设置）
2. ✅ 背包满错误处理
3. ✅ BoP 自动确认（单人模式）
4. ✅ 自动拾取渐隐动画（5秒停留 + 3秒渐隐）

### 阶段四：投骰框体 ✅ 已完成
1. ✅ 投骰框体创建 + 布局
2. ✅ Need/Greed/Pass 按钮
3. ✅ 倒计时状态条动画
4. ✅ 品质颜色计时条
5. ✅ 并发投骰堆叠（最多4个）
6. ✅ BoP/BoE 标识

### 阶段五：配置集成 🔧 部分完成
1. ✅ defaults 注册（自动出现在 GUI 配置面板）
2. ✅ scale / mousecursor 回调（实时生效）
3. 待验证：Ctrl+Alt+Shift 拖拽移动

---

## 9. 验证方法

1. ✅ **基础拾取**：击杀怪物 → 拾取窗口应为 Dragonflight 风格 → 点击物品可正常拾取 → ESC/右键可关闭
2. ✅ **品质显示**：拾取不同品质物品 → 边框/高亮/文字颜色应正确匹配品质
3. ✅ **鼠标跟随**：在屏幕不同位置拾取 → 窗口应出现在光标附近且不超出屏幕
4. ✅ **自动拾取**：开启选项后 → Shift+右键拾取应自动获取所有物品
5. ✅ **BoP 确认**：单人拾取绑定物品 → 应自动确认无需弹窗
6. ✅ **投骰窗口**：组队副本掉落 → Need/Greed/Pass 按钮可正常点击 → 倒计时条动画流畅
7. 待验证 **配置面板**：打开 DFUI 设置 → 拾取分类下所有选项可正常切换 → 效果实时生效
8. 待验证 **兼容性**：与 XLoot 不同时启用时独立工作 → 禁用模块后恢复默认拾取窗口
