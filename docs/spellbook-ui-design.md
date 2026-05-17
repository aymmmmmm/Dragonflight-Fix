# 法术书 UI 设计规范（2026-04-11 旧版）

> ⚠️ **过期警告**：本文是 2026-04-11 的初版（750×530 / 28 按钮 / 双页布局），实际实现已在 2026-05-01 大幅改写。
>
> **请看新版**：[`spellbook-layout-analysis.md`](./spellbook-layout-analysis.md)（550×580 / 12 按钮 / 单页 + 右侧竖向 Tab + 羊皮纸贴金属内边偏移分析）。
>
> 下文保留作为历史参考。

> 日期：2026-04-11 | 文件：`modules/panels/spellbook.lua` (660行)

本文档记录法术书面板的完整 UI 设计，作为"书本类面板"的参考模板。

## 一、整体结构

```
750 x 530 px，缩放 0.9，居中偏上 (0, 80)
┌─[职业图标]──────[Spellbook]────────────[X]─┐  ← PaperDollFrame 金属边框
│  ┌────── 木纹顶部装饰 (730x64) ──────┐     │
│  ├──────────────┬──────────────┤     │
│  │   左页背景    │   右页背景    │ [书签] │
│  │  365px 宽    │  365px 宽    │     │
│  │              │              │     │
│  │  [技能] [技能] │ [技能] [技能] │     │
│  │  [技能] [技能] │ [技能] [技能] │     │
│  │  [技能] [技能] │ [技能] [技能] │     │
│  │  [技能] [技能] │ [技能] [技能] │     │
│  │  [技能] [技能] │ [技能] [技能] │     │
│  │  [技能] [技能] │ [技能] [技能] │     │
│  │  [技能] [技能] │ [技能] [技能] │     │
│  │              │    Page 1/3 ◀ ▶│     │
│  └──────────────┴──────────────┘     │
│ [✓ Show Passive] [✓ Show Spell Ranks]      │
├─[General]─[Fire]─[Frost]─[Pet]─────────────┤  ← Tab 在底部外侧
```

## 二、配色方案

### 羊皮纸书本风格

| 元素 | RGB | 说明 |
|------|-----|------|
| 技能名称 | `(0.35, 0.20, 0.08)` | 深棕墨水色，仿古书墨迹 |
| 被动/种族/等级标签 | `(0.50, 0.35, 0.18)` | 浅棕色，次要信息 |
| 标题 "Spellbook" | `(0.94, 0.75, 0.38)` | 金色，与金属边框呼应 |
| 页码 "Page 1/3" | `(0.78, 0.57, 0.16)` | 金棕色 |
| 复选框标签 | `(0.9, 0.9, 0.9)` | 白色（位于深色边框区域） |

### 配色原则

- 羊皮纸区域用**深棕暖色调**文字（墨水色），避免白色
- 金属边框区域用**白色/金色**文字，保证对比度
- 次要信息比主要信息浅 1 级，但保持同色系

## 三、纹理清单

| 文件名 | 尺寸 | 用途 | 图层 |
|--------|------|------|------|
| `spellbook_left_page.blp` | 350KB | 右页背景（交叉使用） | ARTWORK |
| `spellbook_right_page.blp` | 350KB | 左页背景（交叉使用） | ARTWORK |
| `spellbook_top_wood.blp` | 12KB | 顶部木纹装饰 730x64 | BORDER |
| `spellbook_bookmark.blp` | 88KB | 书签装饰 50x500 | OVERLAY |
| `spellbook_actives_border.blp` | 23KB | 主动技能图标边框 47x47 | ARTWORK |
| `spellbook_passives_border.blp` | 23KB | 被动技能图标边框 47x47 | ARTWORK |
| `spellbook_highlight.blp` | 23KB | 悬浮高亮 47x47 / 最高等级光效 57x57 | HIGHLIGHT/OVERLAY |
| `UI-Classes-Circles.tga` | — | 职业图标 52x52 | ARTWORK |

所有纹理路径：`media/tex/panels/`（职业图标在 `media/tex/ui/`）

## 四、技能按钮结构

每个按钮为 160x42 的容器，内部结构：

```
┌─────────────────────────────────┐
│ ┌──────┐                        │
│ │[icon]│ 技能名称               │  ← 11pt 深棕色
│ │ 36x36│ Passive / Racial       │  ← 9pt 浅棕色（可选）
│ │[边框] │ Rank 3                 │  ← 9pt 浅棕色（可选）
│ └──────┘                        │
└─────────────────────────────────┘
```

### 按钮元素详情

| 元素 | 类型 | 尺寸 | 锚点 | 说明 |
|------|------|------|------|------|
| `container` | Frame | 160x42 | — | 按钮容器 |
| `iconBtn` | Button | 36x36 | LEFT +5 | 可点击/拖拽的图标按钮 |
| `icon` | Texture(BG) | 填满iconBtn | AllPoints | 技能图标 |
| `border` | Texture(ART) | 47x47 | CENTER iconBtn (-3,-2) | 主动/被动不同边框 |
| `highlight` | Texture(HL) | 47x47 | CENTER iconBtn | ADD混合悬浮高亮 |
| `maxRankHighlight` | Texture(OVL) | 57x57 | CENTER iconBtn | ADD混合α=0.3，最高等级光效 |
| `cooldown` | CooldownFrame | 填满iconBtn | AllPoints | 冷却动画 |
| `name` | FontString | 11pt | LEFT iconBtn.RIGHT +5 | 技能名称 |
| `passive` | FontString | 9pt | TOPLEFT name.BL | "Passive" 标签 |
| `racial` | FontString | 9pt | TOPLEFT lastAnchor.BL | "Racial" 标签 |
| `rank` | FontString | 9pt | TOPLEFT lastAnchor.BL | 等级/变体信息 |

### 按钮交互

- **左/右键点击**：施法 `CastSpell()`
- **拖拽**：拾取到动作条 `PickupSpell()`
- **悬浮**：显示 GameTooltip
- **按下效果**：图标偏移 (2,-2)，边框偏移 (-1,-4)

## 五、布局参数

```lua
BUTTONS_PER_PAGE = 28        -- 每页 28 个按钮（左右各 14）
COLUMN_SPACING   = 165       -- 两列间距
ROW_SPACING      = 58        -- 行间距
LEFT_OFFSET      = 50        -- 按钮距页面左边距
TOP_OFFSET       = -20       -- 按钮距页面顶部距离
```

### 左右页布局

- 左页：按钮 1-14，2 列 × 7 行，锚定 `leftPage TOPLEFT`
- 右页：按钮 15-28，2 列 × 7 行，锚定 `rightPage TOPLEFT`

### 页面纹理定位

```lua
leftPage:  TOPLEFT  spellbook (10, -60)  → BOTTOM spellbook (-5, 10)  宽365
rightPage: TOPRIGHT spellbook (-10, -60) → BOTTOM spellbook (5, 10)   宽365
topWood:   TOP spellbook (0, -20)  宽730 高64
bookmark:  TOPRIGHT leftPage (45, 0)  宽50 高500
```

## 六、功能组件

### Tab 系统（动态生成）
- 根据 `GetNumSpellTabs()` 自动创建标签页
- 每个 Tab 90px 宽，间距 2px（第二个 Tab 间距 10px）
- Pet Tab 50px 宽，间距 10px，有/无宠物动态显示/隐藏
- Tab 名称清理：去除 Turtle WoW 前缀 `Zz+`，去除 ` Combat` 后缀

### 翻页系统
- 每页 28 按钮，动态计算最大页数
- 左/右箭头按钮 27x27，带背景和 ADD 高亮
- 页码文字在右页右下角

### 过滤系统
- `filterShowPassive`：布尔变量驱动，显示/隐藏被动技能
- `filterShowRanks`：布尔变量驱动，显示所有等级/仅最高等级
- 复选框 OnClick 翻转 boolean → 重置页码 → 刷新显示
- 状态通过 `DFUI:SetTempDB()` 持久化

### 事件响应
- `SPELL_UPDATE_COOLDOWN` → 更新冷却动画
- `PET_BAR_UPDATE` / `UNIT_PET` → 刷新宠物 Tab
- `SPELLS_CHANGED` → 刷新技能列表

## 七、框架特性

```lua
-- 框体属性
SetFrameStrata("MEDIUM")
SetFrameLevel(25)
SetScale(0.9)
SetMovable(true)              -- 可拖动
RegisterForDrag("LeftButton") -- 左键拖动

-- 关闭方式
ESC 关闭（UISpecialFrames）
红色关闭按钮（CreateRedButton）

-- 音效
OnShow: igSpellBookOpen
OnHide: igSpellBookClose

-- 全局覆写
_G.ToggleSpellBook = function() ... end
```

## 八、复用指南

将此设计应用到其他书本类面板（如任务日志、天赋书等）时：

1. **框架**：`CreatePaperDollFrame(name, parent, width, height, style)` 创建金属边框
2. **内容区**：左右页纹理 + 木纹顶部 + 书签装饰
3. **配色**：羊皮纸区域用深棕墨水色，边框区域用白/金色
4. **按钮**：复用 `CreateSpellButton` 结构，替换数据源
5. **翻页**：复用 `CreatePageButton` 工厂函数
6. **Tab**：使用 `frame:AddTab()` 方法
7. **过滤**：布尔变量 + 复选框 + `SetTempDB` 持久化
8. **交互**：框体可拖动 + ESC关闭 + 音效
