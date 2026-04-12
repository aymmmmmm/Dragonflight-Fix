# 面板美化设计方案

> 日期：2026-04-05

## 一、目标

将暴雪原生面板替换为统一的 Dragonflight 金属边框风格，使所有 UI 面板视觉一致。

## 二、当前状态

Fix 已美化 3 个面板：GameMenu、TalentFrame、LootFrame。其余 17 个面板保持暴雪默认外观，与 DF 风格的单位框架、动作条形成视觉割裂。

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
-- modules/panels/paperdoll.lua
function DFUI.CreatePaperDollFrame(name, parent, width, height)
```

### 4.2 创建的元素

```
PaperDollFrame 结构
├── frame.Bg          ← 深色岩石背景纹理 (BACKGROUND 层)
├── frame.topLeft     ← 左上金属角 75x75 (OVERLAY 层)
├── frame.topRight    ← 右上金属角 75x75
├── frame.bottomLeft  ← 左下金属角 32x32
├── frame.bottomRight ← 右下金属角 32x32
├── frame.topEdge     ← 顶部金属边
├── frame.bottomEdge  ← 底部金属边
├── frame.leftEdge    ← 左侧金属边
├── frame.rightEdge   ← 右侧金属边
├── frame.Tabs = {}   ← 标签页容器
└── frame:AddTab(text, onClick, width)  ← 添加标签页方法
```

### 4.3 需要的纹理素材（从 D3 复制）

| 素材 | D3 路径 | 用途 |
|------|---------|------|
| UI-Background-Rock | `media/tex/interface/UI-Background-Rock.*` | 面板深色背景 |
| UIFrameMetal2x | `media/tex/interface/UIFrameMetal2x.*` | 金属边角/边框 |
| UIFrameMetal2x2 | `media/tex/interface/UIFrameMetal2x2.*` | 备用金属纹理 |
| uiframetabs | `media/tex/interface/uiframetabs.*` | Tab 标签页 |
| btn_border.blp | `media/tex/actionbars/btn_border.blp` | 物品栏边框 |
| btn_highlight_strong.blp | `media/tex/actionbars/btn_highlight_strong.blp` | 物品栏高亮 |
| HDActionBarBtn.tga | `media/tex/actionbars/HDActionBarBtn.tga` | 物品栏背景 |
| spellbook_top_wood.blp | `media/tex/panels/spellbook_top_wood.blp` | 面板顶部木纹 |
| questlog_left_bg.blp | `media/tex/panels/questlog_left_bg.blp` | 任务面板背景 |
| questlog_right_bg.blp | `media/tex/panels/questlog_right_bg.blp` | 任务面板背景 |
| spellbook_bookmark.blp | `media/tex/panels/spellbook_bookmark.blp` | 书签装饰 |

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
- 添加 4 个 DF Tab：角色 / 声望 / 技能 / PvP
- 16 个装备栏加品质颜色边框（绿/蓝/紫/橙）
- Shift+Click 装备信息 Hook

触发时机：模块加载时
```

#### SocialFrame（社交面板）— 137 行
```
美化内容：
- 隐藏暴雪社交纹理
- 创建 PaperDollFrame
- 添加 4 个 DF Tab：好友 / 谁在线 / 公会 / 团队

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

```
modules/panels/
├── paperdoll.lua        ← 工厂函数（新建，~150 行）
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

```lua
DFUI:NewDefaults("Panels", {
    enabled = {true, "checkbox", nil, nil, "面板美化", 1, "启用面板美化", nil, nil},
    bankFrame = {true, "checkbox", nil, "enabled", "面板美化", 2, "银行", nil, nil},
    merchantFrame = {true, "checkbox", nil, "enabled", "面板美化", 3, "商人", nil, nil},
    questFrame = {true, "checkbox", nil, "enabled", "面板美化", 4, "任务对话", nil, nil},
    gossipFrame = {true, "checkbox", nil, "enabled", "面板美化", 5, "NPC对话", nil, nil},
    questLogFrame = {true, "checkbox", nil, "enabled", "面板美化", 6, "任务日志", nil, nil},
    characterFrame = {true, "checkbox", nil, "enabled", "面板美化", 7, "角色面板", nil, nil},
    socialFrame = {true, "checkbox", nil, "enabled", "面板美化", 8, "社交", nil, nil},
    mailFrame = {true, "checkbox", nil, "enabled", "面板美化", 9, "邮件", nil, nil},
    tradeFrame = {true, "checkbox", nil, "enabled", "面板美化", 10, "交易", nil, nil},
    -- 第三批...
})
```

每个面板独立开关，用户可以按需启用/禁用。

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
| 工厂函数 | `DF.ui.CreatePaperDollFrame` 在 ui-tools.lua | `DFUI.CreatePaperDollFrame` 独立文件 |
| 媒体路径 | `media['tex:interface:name']` 元表 | 硬编码路径字符串 |
| 关闭按钮 | `DF.ui.CreateRedButton` | `DFUI.tools.CreateButton` 或自定义 |
| Tab 系统 | 内嵌在 PaperDollFrame 方法 | 同样内嵌 |
| 配置 | 全局开关 | **每个面板独立开关** |
| SpellBookFrame | 535 行全新重写 | **已完成** 660 行（详见 spellbook-ui-design.md） |
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
