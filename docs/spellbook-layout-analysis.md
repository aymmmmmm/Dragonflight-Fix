# 法术书布局迭代 & frame 视觉边对齐分析

> 日期：2026-05-01（2026-06-01 复核参数）| 文件：`modules/panels/spellbook.lua` (~1193 行)
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
| 图标 iconBtn | 48 × 48（icon `SetTexCoord(0.08,0.92,0.08,0.92)` 裁切 8%） |
| border | 91 × 84，纹理 `spellbook_parts.tga`，CENTER(1, 0) |
| highlight / pushedFlash | `SetAllPoints(iconBtn)`，纹理 `ButtonHilight-Square`，ADD |
| COLUMN_SPACING | 225（retail spellbookframe.xml 第二列 x=225） |
| ROW_SPACING | 72 |
| 首列锚点 | TOPLEFT(115, -75)（相对 spellbook 主框） |
| 第二列实际 x | 115 + 225 = 340 |
| OnMouseDown 缩放 icon | 49，border CENTER(2, -2) |
| OnMouseUp 复位 icon | 48，border CENTER(1, 0) |

> **2026-06-01 复核更正**：原表 iconBtn 50×50 / border·highlight 共用 67×67 / COLUMN_SPACING 220 均已过时。当前 iconBtn=48；border 用 `spellbook_parts.tga` 的 atlas 段 `SetTexCoord(0.00390625,0.27734375,0.44140625,0.69531250)` 撑成 91×84；highlight 与 pushedFlash 改用 `SetAllPoints(iconBtn)` 跟随按钮（不再硬编尺寸）；COLUMN_SPACING=225。**`maxRankHighlight` 已整块删除**（详见第五节）。

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

法术书初始 mainPage 510×550 / rightStrip 47×550（`spellbook.lua:123` 注释记录 `45  -- 47 - 2`），按 frame 几何边 (550×580) 算应该贴边。但视觉上**右侧差 ~13px、下侧差 ~21px、左侧差 ~4px** 的"金属内边框"露在外面。

> 注：rightStrip 的历史起点本文早期稿写作 32，与代码内注释记录的前值 47 不符；当前最终值 45 双方一致。前值具体数字以代码注释为准（47），32 系叙述瑕疵，演进细节待游戏内实证。

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
- 右 +13（rightStrip 宽 →45；代码注释记录前值为 47，本文早期稿误写 32，以代码为准）
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
3. **第二列右溢**：列索引 0-based（`spellbook.lua:528-531` 用 `col = math.mod(i-1, 2)`），首列 col=0 在 x=115，第二列 col=1 起点 x=340（115+225）+ 容器 200 = x=540，离 frame 右 550 仅剩 10px——如果 COLUMN_SPACING 加大或容器加宽就会被切。
4. **如其他面板（trainer/macro 等）也要贴内边**：建议参考本次的偏移表抽出常量到 `paperdoll.lua` 头部，比如 `INNER_INSET = { left=3, right=12, top=16, bottom=16 }`。

## 五、参数演进备注（2026-06-01 复核补）

- **`maxRankHighlight` 已删除**：Turtle 1.12 `GetSpellName(idx, BOOKTYPE_SPELL)` 只暴露每个法术的最高等级条目，低等级根本不进可枚举索引，"max-rank 金光晕"前提不成立。当前 `CreateSpellButton`/`UpdateSpellDisplay` 已无 maxRankHighlight 贴图与 Show/Hide 块。`UpdateSpellDisplay` 内仍按 `name+variant` 做 `maxRanks` 去重（`spellbook.lua:556-571`），勾选「显示法术等级」时跳过去重展开全部条目，但因 API 合并，多数法术两态等价。
- **复选框已可用**：`显示被动技能`/`显示法术等级` 改用 boolean 变量 `filterShowPassive`/`filterShowRanks` 驱动过滤（`spellbook.lua:176-179`），`OnClick` 翻转 boolean + `SetTempDB` 持久化 + `UpdateSpellDisplay()` 刷新（`spellbook.lua:894-919`），不再依赖 `GetChecked`。早期"点了不刷新"已解决。
- **金色新学高亮 newGlow**：图标四周外扩 2px，叠 3 层 `ButtonHilight-Square` 染金（`SetVertexColor(1,0.82,0)` / `SetAlpha(0.8)`），按 `newSpells[name]` 集合显隐；点击/悬停即清（`spellbook.lua:395-410`）。本文初版未覆盖该特性。
