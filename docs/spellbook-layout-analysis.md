# 法术书布局迭代 & frame 视觉边对齐分析

> 日期：2026-05-01 | 文件：`modules/panels/spellbook.lua` (~970 行)
>
> 本次迭代覆盖：右侧竖向 Tab、坐骑/小伙伴/玩具 Tab 整合、按钮放大、羊皮纸贴金属内边。
> 旧文档 `spellbook-ui-design.md`（2026-04-11，750×530 / 28 按钮版）已过时，本文为新基线。

## 一、当前最终参数

### Frame 与羊皮纸

| 元素 | 值 | 备注 |
|---|---|---|
| `CreatePaperDollFrame` 几何尺寸 | 550 × 580 | frame 内部坐标系 |
| mainPage 纹理 | 514 × 571 | TOPLEFT(3, -25) |
| rightStrip 纹理 | 45 × 571 | TOPLEFT 紧贴 mainPage TOPRIGHT |
| **羊皮纸总覆盖** | x = 3..562 / y = -25..-596 | 比 frame 几何边大！见第三节分析 |

mainPage/rightStrip 都在 `ARTWORK` 层。**职业图标移到 `OVERLAY` 层**，否则被拉伸后的羊皮纸覆盖（同 ARTWORK 层 vanilla 1.12 不保证后绘制压上面）。

### 按钮布局

| 元素 | 值 |
|---|---|
| BUTTONS_PER_PAGE | 12（6 行 × 2 列） |
| 容器尺寸 | 200 × 60 |
| 图标 iconBtn | 50 × 50 |
| border / highlight | 67 × 67 |
| maxRankHighlight | 80 × 80 |
| COLUMN_SPACING | 220 |
| ROW_SPACING | 72 |
| 首列锚点 | TOPLEFT(115, -75)（相对 spellbook 主框） |
| 第二列实际 x | 115 + 220 = 335 |
| OnMouseDown 缩放 icon | 51 |
| OnMouseUp 复位 icon | 50 |

### 右侧竖向 Tab（坐骑/小伙伴/玩具）

| 元素 | 值 |
|---|---|
| Tab 几何 | 36 宽 × 90 高 |
| topCap | 36 × 36，TOPLEFT(0, 0) |
| midSeg | 36 宽 × 自动伸长（topCap.bottom 到 botCap.top） |
| botCap | 36 × 36，BOTTOMLEFT(0, 0) |
| 选中态 cap | 39 宽 × 36 高（外伸 +3px 表现"延长"动画） |
| Tab 锚点 | TOPLEFT spellbook TOPRIGHT (0, -90/-180/-270) |
| 文字 | UTF-8 切字符 + `\n` 竖排，CENTER(-3, 0)，GameFontNormalSmall |

底部金属 Tab 素材 `uiframetabs.blp` 通过 8-arg `SetTexCoord` 旋转：
- topCap：横向 right (圆角 BR) → 90° CCW（用户调试结论：CW 圆角朝向反了）
- midSeg：横向 middle → 90° CCW
- botCap：横向 left (圆角 BL) → 90° CCW（圆角落在 BR）
- 选中态/Hover 同样三段，用 selected/highlight 的 atlas 段

### 移除的复杂路径

第一轮试图扫包+tooltip 匹配做小伙伴/玩具的 ~150 行代码已删除（`CollectMounts`/`CollectInventoryItems`/`tipScanner`/`BAG_UPDATE`/`isItem` 分支等）。原因：用户指出 Turtle 服务端把这 3 个集合做成了真正的 SpellTab，**直接用 tabIndex 当普通 SpellTab 用就行**。

`CreateDynamicTabs` 现在做 2 件事：
1. 遍历 `GetSpellTabInfo`：是右侧 kind（坐骑/小伙伴/玩具）→ 存到 `spellbook.rightTabIndices[kind]`，不进底部
2. 普通 → AcquireTab 进底部 Tab 池

右侧 Tab onClick 只查 `rightTabIndices[kind]` 拿真实 tabIndex，按 `BOOKTYPE_SPELL` + `selectedTabIndex=tabIdx` 走 `CollectSpells`，跟职业 Tab 完全同路径。

## 二、操作笔记（用户调试出来的微调值）

按钮内容左上角偏移：从最初 (100, -72) 经过多轮 → 最终 (115, -75)。
羊皮纸贴金属内边：左 +4 / 右 +13 / 下 +21 / 上 0 不变。
右侧 Tab 旋转：topCap 经过 CW → 加 180° → 等价 CCW 才对。

## 三、根因分析：frame 几何尺寸 ≠ 视觉尺寸

### 现象

法术书初始 mainPage 510×550 / rightStrip 32×550，按 frame 几何边 (550×580) 算应该贴边。但视觉上**右侧差 ~13px、下侧差 ~21px、左侧差 ~4px** 的"金属内边框"露在外面。

### 根因

`paperdoll.lua` 的 `CreatePaperDollFrame` 把金属边框纹理（UIFrameMetal2x）**用偏移量画到 frame 几何边外**：

```lua
topLeft   :SetPoint("TOPLEFT",     frame, "TOPLEFT",     -13, 16)  -- 外延 13/16
topRight  :SetPoint("TOPRIGHT",    frame, "TOPRIGHT",      4, 16)  -- 外延  4/16
bottomLeft:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  -13, -3)  -- 外延 13/3
bottomRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",  4, -3)  -- 外延  4/3
```

**金属"视觉外边"**：x = -13..554，y = +16..-583（frame 几何 0..550 / 0..-580 之外多包了一圈）。

**金属"视觉内边"**（金属带终止、应贴羊皮纸的位置）位于金属带宽度内，**不等于 frame 几何边**。经实测：

| 边 | 几何 frame 边 | 金属视觉内边 | 偏差 |
|---|---|---|---|
| 左 | x = 0   | x ≈ +3    | +3  |
| 右 | x = 550 | x ≈ +562  | +12 |
| 上 | y = 0   | y ≈ -25   | -25（被原 mainPage TOPLEFT(7, -25) 凑巧抵消） |
| 下 | y = -580 | y ≈ -596 | +16 |

### 不对称的来源

`paperdoll.lua` 的金属角锚点本身就**不对称**：左/下角用 -13 / -3，右/上角用 +4 / +16。这是 retail Dragonflight 边框设计特征——书脊在左上更厚、右下更薄，模仿"书页装订"。

所以羊皮纸要贴金属内边时，必须**反向不对称地外伸**：
- 左 +4（mainPage 锚 7→3，宽 +4）
- 右 +13（rightStrip 宽 32→45）
- 下 +21（mainPage/rightStrip 高 550→571）
- 上 0（top 偏移 16 + 25px 上空凑巧对齐）

### 副作用：图层冲突

mainPage 往左拉 4px 后，覆盖到职业图标的 x 范围 (0..52)。两者都在 ARTWORK 层 → 1.12 同层先创建的反而压在后创建上面（不保证后绘制覆盖前）→ 图标被吃。

**修法**：职业图标 ARTWORK → OVERLAY，强制压在所有 ARTWORK 之上。

### 真正干净的修法（未做）

直接改 `paperdoll.lua::CreatePaperDollFrame`：
- 让 frame 几何尺寸 = 金属视觉外边尺寸（用户传进来的 width/height 就是真实视觉边）
- 内部用 `SetClampRectInsets` 或重新设计金属角锚点，把金属画在 frame 几何边内侧
- 让羊皮纸/内容直接按几何边贴

但 `CreatePaperDollFrame` 是工厂函数，被 paperdoll/talents/macro/trainer/tradeskill **全部面板**共享。改它要回归测所有面板。**spellbook 这种局部硬编码偏移更稳。**

## 四、待办（如果未来要继续打磨）

1. **顶部对齐**：当前 top 是 25px 上空（写死的 mainPage TOPLEFT y=-25）。如果想让 mainPage 顶也贴金属内边，需要把 y 从 -25 调到约 -16（金属上内边）；但顶上有职业图标 + 标题文字，挤掉它们。
2. **首行 y=-75 是经验值**：图标 50 高 + 容器 60 高 + 顶部 25 上空 → 大约 -75 让首行不顶到金属。如果改容器高度需要重算。
3. **第二列右溢**：col 1 起点 x=335 + 容器 200 = x=535，离 frame 右 550 还有 15px——如果 COLUMN_SPACING 加大或容器加宽就会被切。
4. **如其他面板（trainer/macro 等）也要贴内边**：建议参考本次的偏移表抽出常量到 `paperdoll.lua` 头部，比如 `INNER_INSET = { left=3, right=12, top=16, bottom=16 }`。
