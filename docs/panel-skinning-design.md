# 面板美化设计方案

> 日期：2026-04-05（原始设计计划）
> 复核：2026-06-01 —— 计划已基本落地，下文标注为「✅ 已实现」「⚠️ 与代码不符」处为复核补正。

## 一、目标

将暴雪原生面板替换为统一的 Dragonflight 金属边框风格，使所有 UI 面板视觉一致。

## 二、当前状态

✅ **计划已落地**：`modules/panels/` 下共 21 个 `.lua`，其中 18 个面板调用 `DFUI.CreatePaperDollFrame` 工厂换皮（paperdoll.lua 是工厂本体；scrollbar.lua、questlog_xp.lua 不调用工厂）。全部在 `Dragonflight-Fix.toc`（第 47-67 行）注册加载。下文「实现顺序 / 文件结构」描述的面板基本全部完成。

> 历史原文（设计当时）：Fix 已美化 3 个面板：GameMenu、TalentFrame、LootFrame，其余面板保持暴雪默认外观。此状态已过时。

## 三、美化前后对比

### 原生面板（美化前）
```
┌──────────────────────────┐
│ ╔══════════════════════╗  │  ← 暴雪经典石纹边框
│ ║  [头像]  面板标题    ║  │  ← 低分辨率纹理
│ ╠══════════════════════╣  │
│ ║                      ║  │  ← 原生内容区
│ ║    （面板内容）       ║  │
│ ║                      ║  │
│ ╚══════════════════════╝  │
└──────────────────────────┘
```

### DF 风格面板（美化后）
```
┌──────────────────────────┐
│ ┏━━━━━━━━━━━━━━━━━━━━━━┓ │  ← 金属质感边框（4 角 + 4 边）
│ ┃ [头像]  面板标题   [X]┃ │  ← DF 红色关闭按钮
│ ┣━[Tab1]━[Tab2]━━━━━━━━┫ │  ← DF 风格标签页（可选）
│ ┃ ░░░░░░░░░░░░░░░░░░░░ ┃ │  ← 深色岩石纹理背景
│ ┃ ░░  （面板内容）  ░░ ┃ │  ← 物品栏：DF 边框 + 高亮
│ ┃ ░░░░░░░░░░░░░░░░░░░░ ┃ │
│ ┗━━━━━━━━━━━━━━━━━━━━━━┛ │
└──────────────────────────┘
```

## 四、核心实现：PaperDollFrame 工厂函数

所有面板共用同一个工厂函数创建 DF 风格框架，保证视觉一致。

### 4.1 函数签名

```lua
-- modules/panels/paperdoll.lua:82（实际 376 行，非计划中的 ~150 行）
function DFUI.CreatePaperDollFrame(name, parent, width, height, frameStyle)
```

⚠️ 复核补正：实际签名多一个 `frameStyle` 参数（1=带头像金属框，左上角留 54x54 头像槽；2=无头像金属框；3=备用金属纹理 UIFrameMetal2x2）。

### 4.2 创建的元素

⚠️ 复核补正：四角/四边均为局部变量，统一收进 `frame.edges` 数组（8 个元素，无单独命名字段）；**没有** `frame.topLeft` / `frame.bottomLeft` 等具名字段。实际挂到 frame 上的字段只有 `frame.Bg`、`frame.portrait`（仅 frameStyle==1）、`frame.edges`、`frame.Tabs`、`frame.selectedTab`。

```
PaperDollFrame 结构（实际，对照 paperdoll.lua:82-375）
├── frame.Bg            ← 深色岩石背景纹理 UI-Background-Rock (BACKGROUND -2 层)
├── frame.portrait      ← 头像槽 54x54（仅 frameStyle==1 创建）
├── frame.edges = {     ← 8 个边框纹理（局部变量收入此数组，无具名字段）
│     左上角 75x75 (OVERLAY), 右上角 75x75 (ARTWORK),
│     左下角 32x32, 右下角 32x32,
│     顶边, 底边, 左边, 右边 }
├── frame.Tabs = {}     ← 标签页容器
├── frame.selectedTab   ← 当前选中 Tab
└── frame:AddTab(text, onClick, tabWidth, spacing)  ← 添加标签页方法（4 参，非计划的 3 参）
```

### 4.3 工厂函数实际使用的纹理素材

路径前缀均为 `Interface\AddOns\Dragonflight-Fix\media\tex\`（paperdoll.lua 内 `local TEX`）。⚠️ 复核补正：以下为 `CreatePaperDollFrame` / `CreateRedButton` 实际 `SetTexture` 的文件，原计划列出的 btn_border / spellbook_* 等不在工厂函数内（部分由各面板自行加载，见 §5）。

| 素材 | 实际路径 | 用途 |
|------|---------|------|
| UI-Background-Rock.blp | `interface\UI-Background-Rock.blp` | 面板深色岩石背景 |
| UIFrameMetal2x.blp | `interface\UIFrameMetal2x.blp` | 四角金属（TexCoord 裁切，frameStyle 1/2） |
| UIFrameMetal2x2.blp | `interface\UIFrameMetal2x2.blp` | 备用金属纹理（frameStyle 3） |
| UIFrameMetalHorizontal2x.BLP | `interface\UIFrameMetalHorizontal2x.BLP` | 上下水平边 |
| UIFrameMetalVertical2x.BLP | `interface\UIFrameMetalVertical2x.BLP` | 左右垂直边 |
| uiframetabs.blp | `interface\uiframetabs.blp` | Tab 标签条（三段拼接 + 选中/高亮态） |
| redbutton2x.BLP | `interface\redbutton2x.BLP` | 关闭/最小化/最大化按钮（`DFUI.CreateRedButton`） |

> 物品栏边框/高亮由各面板单独 `SetTexture`，例如 bank.lua 用 `actionbars\border.blp`（边框）+ `actionbars\HDActionBarBtn.tga`（高亮/背景），并非工厂函数职责。

## 五、每个面板的美化逻辑

所有面板遵循统一的 5 步模式：

```
Step 1: 隐藏暴雪纹理  — 遍历 GetRegions()，按纹理名 Hide
Step 2: 隐藏暴雪按钮  — CloseButton、Tab 等
Step 3: 创建 DF 背景   — DFUI.CreatePaperDollFrame(...)
Step 4: 重定位原生元素  — 头像、标题、内容区重新锚定到 DF 框架
Step 5: 美化物品栏     — 给 ItemButton 加 DF 边框和高亮（如有）
```

### 5.1 第一批：高频面板（5 个，~440 行）

#### BankFrame（银行）— 88 行
```
美化内容：
- 隐藏暴雪银行纹理
- 创建 384x512 PaperDollFrame
- 24 个银行物品栏 + 6 个银行背包栏加 DF 边框
- 重定位头像和标题

触发时机：BankFrame:OnShow
```

#### MerchantFrame（商人）— 77 行
```
美化内容：
- 隐藏暴雪商人纹理
- 创建 PaperDollFrame
- 添加 2 个 DF Tab：商人 / 回购
- 重定位头像和标题

触发时机：模块加载时
```

#### QuestFrame（任务对话）— 67 行
```
美化内容：
- 隐藏暴雪任务对话纹理
- 创建 PaperDollFrame + 顶部木纹 + 右侧背景
- 重定位 NPC 名字、对话文本

触发时机：模块加载时
```

#### GossipFrame（NPC 对话）— 71 行
```
美化内容：
- 隐藏暴雪 Gossip 纹理
- 创建 PaperDollFrame + 顶部木纹 + 书签装饰
- 重定位头像

触发时机：模块加载时
```

#### QuestLogFrame（任务日志）— 137 行
```
美化内容：
- 隐藏暴雪任务日志纹理
- 创建 PaperDollFrame + 多层纹理（木纹 + 左/右背景 + 书签）
- 10 个任务物品栏加 DF 边框
- Hook QuestLog_Update 刷新物品品质边框

触发时机：模块加载时
```

### 5.2 第二批：中频面板（5 个，~560 行）

#### CharacterFrame（角色面板）— 223 行
```
美化内容：
- 隐藏暴雪角色面板纹理
- 创建 PaperDollFrame
- 添加 5 个 DF Tab：角色 / 宠物 / 声望 / 技能 / 荣誉（character.lua:410/417/424/447/455；「宠物」Tab 由 UpdatePetTab 按 HasPetUI 动态显隐）
- 16 个装备栏加品质颜色边框（绿/蓝/紫/橙）
- Shift+Click 装备信息 Hook

触发时机：模块加载时
```

#### SocialFrame（社交面板）— 137 行
```
美化内容：
- 隐藏暴雪社交纹理
- 创建 PaperDollFrame
- 添加 4 个 DF Tab：好友 / 查找 / 公会 / 团队（social.lua:691/701/710/2042）

触发时机：模块加载时
```

#### MailFrame + OpenMailFrame（邮件）— 111 行
```
美化内容：
- 隐藏暴雪邮件纹理
- 两个 PaperDollFrame（收件箱 + 读信）
- 添加 2 个 DF Tab：收件箱 / 发信

触发时机：模块加载时
```

#### TradeFrame（交易面板）— 71 行
```
美化内容：
- 隐藏暴雪交易纹理
- 创建左右两个 185x460 PaperDollFrame
- 重定位双方头像和名字

触发时机：模块加载时
```

### 5.3 第三批：低频面板（7 个，~450 行）

| 面板 | 行数 | 说明 |
|------|------|------|
| ClassTrainerFrame | 108 | 训练师 |
| MacroFrame | 99 | 宏编辑器，18 按钮美化 |
| MerchantFrame Buyback | — | 已含在 MerchantFrame |
| KeyBindingFrame | 66 | 按键绑定 |
| DressUpFrame | 45 | 试穿预览（最简单） |
| HelpFrame | 47 | 帮助 |
| WorldMapFrame | 134 | 世界地图（Fix 已有部分实现） |

## 六、文件结构

> ✅ 复核：下列文件均已落地（见 .toc 第 47-67 行），实际还多出 `scrollbar.lua`、`questlog_xp.lua`、`inspect.lua`、`tradeskill.lua`、`spellbook.lua` 等。paperdoll.lua 实际 376 行（非计划 ~150 行）。

```
modules/panels/
├── paperdoll.lua        ← 工厂函数（376 行，含 CreateRedButton + CreatePaperDollFrame + AddTab）
├── bank.lua             ← 银行（新建）
├── merchant.lua         ← 商人（新建）
├── questframe.lua       ← 任务对话（新建）
├── gossip.lua           ← NPC 对话（新建）
├── questlog.lua         ← 任务日志（新建）
├── character.lua        ← 角色面板（新建）
├── social.lua           ← 社交（新建）
├── mail.lua             ← 邮件（新建）
├── trade.lua            ← 交易（新建）
├── trainer.lua          ← 训练师（新建）
├── macro.lua            ← 宏（新建）
├── keybinding.lua       ← 按键绑定（新建）
├── dressup.lua          ← 试穿（新建）
└── help.lua             ← 帮助（新建）

media/tex/
├── interface/           ← 金属边框纹理（从 D3 复制）
│   ├── UI-Background-Rock.*
│   ├── UIFrameMetal2x.*
│   ├── UIFrameMetal2x2.*
│   └── uiframetabs.*
└── panels/              ← 面板专用纹理（从 D3 复制）
    ├── spellbook_top_wood.blp
    ├── questlog_left_bg.blp
    ├── questlog_right_bg.blp
    └── spellbook_bookmark.blp
```

## 七、配置项

⚠️ 复核补正：实际**未**采用计划中的单一 `NewDefaults("Panels", {...})` 集中表。落地方案是**每个面板独立 `NewDefaults` 命名空间**，多数仅一个 `enabled = {true}` 开关。例如 bank.lua:5：

```lua
DFUI:NewDefaults("Bank", {
    enabled = {true},
})
```

各面板命名空间（实测）：`Bank` / `Character` / `Merchant` / `QuestDialog` / `Gossip` / `QuestLog` / `QuestLogXP` / `Social` / `Mail` / `OpenMail` / `Trade` / `Trainer` / `TradeSkill` / `DressUp` / `Help` / `Inspect` / `Macros` / `SpellBook` / `KeyBinding` / `Scrollbar`。每个面板仍是独立开关，可按需启用/禁用，只是没有统一的「面板美化」父开关。

## 八、实现顺序

```
Phase 1: 基础设施
  └── paperdoll.lua 工厂函数 + 纹理素材复制

Phase 2: 第一批（高频，5 个面板）
  └── bank → merchant → questframe → gossip → questlog

Phase 3: 第二批（中频，5 个面板）
  └── character → social → mail → trade

Phase 4: 第三批（低频，6 个面板）
  └── trainer → macro → keybinding → dressup → help → worldmap
```

## 九、与 D3 的差异

| 项 | D3 | Fix 实现 |
|----|-----|---------|
| 工厂函数 | `DF.ui.CreatePaperDollFrame` 在 ui-tools.lua | `DFUI.CreatePaperDollFrame` 独立文件 modules/panels/paperdoll.lua |
| 媒体路径 | `media['tex:interface:name']` 元表 | `local TEX` 前缀 + 相对路径字符串拼接 |
| 关闭按钮 | `DF.ui.CreateRedButton` | `DFUI.CreateRedButton(parent, buttonType, onClick)`（paperdoll.lua:25，buttonType=close/minimize/maximize） |
| Tab 系统 | 内嵌在 PaperDollFrame 方法 | 同样内嵌 |
| 配置 | 全局开关 | **每个面板独立开关** |
| SpellBookFrame | 全新重写（535 行为 D3 设计期估值） | **已完成**，spellbook.lua 当前 1192 行（660 为 Fix 设计期估值，与现状不符；详见 spellbook-ui-design.md） |
| TalentFrame | 536 行重写 | Fix 已有自己的实现（+天赋规划） |

## 十、验证

每个面板完成后：
1. 打开对应面板，确认暴雪原生纹理全部隐藏
2. 金属边框正确显示，无纹理错位
3. Tab 切换正常（如有）
4. 物品栏/按钮有 DF 边框和高亮（如有）
5. 关闭按钮可用
6. `/dfui` 设置中可独立开关该面板
7. 关闭该面板设置后恢复暴雪默认外观
