# 工厂函数与复用范式总览

> 日期：2026-06-01（首版）
> 优先级：P0
> 目的：把 Dragonflight-Fix 各模块反复复用的工厂函数与结构性范式集中成一份索引。每个条目给出**函数签名 + 文件:行 + 用法要点 + 已知坑**，所有论断均以当前源码为准。
> 铁律提醒：WoW 1.12 = Lua 5.0，取长度用 `table.getn`（非 `#`）；缺 retail Texture API（`SetAtlas`/`SetHorizTile` 等），九宫格一律用 `SetTexCoord` + 拉伸实现。

---

## 一、概览

| 工厂 / 范式 | 全局符号 | 文件:行 | 一句话用途 |
|------------|---------|---------|-----------|
| 面板边框框架 | `DFUI.CreatePaperDollFrame` | `modules/panels/paperdoll.lua:82` | 金属边框 + 岩石背景 + Tab 系统的面板外框 |
| 红色窗口按钮 | `DFUI.CreateRedButton` | `modules/panels/paperdoll.lua:25` | 关闭/最小化/最大化 21×21 按钮 |
| DF 文字操作按钮 | `DFUI.CreateActionButton` | `core/tools.lua:952` | 红金属 9-slice 文字按钮 + 禁用态 |
| 动画状态条 | `CreateStatusBar` | `core/statusbar.lua:45` / 重定义 `:335` | 平滑插值 + 脉冲(pulse) + 切割(cutout) 三动画 |
| 像素级文本截断 | `DFUI.TruncateToWidth` | `core/tools.lua:1036` | UTF-8 边界截断 + 省略号 |
| 文本测宽 | `DFUI.MeasureWidth` | `core/tools.lua:1072` | 隐藏 FontString 实测渲染像素宽 |
| 数字缩写 | `FormatNumber` | `core/tools.lua:234` | 1000→1.0k，1000000→1.0M |
| 彻底杀 frame | `KillFrame` | `core/tools.lua:3` | 解事件 + 清脚本 + 隐藏 + 移屏外 |
| 软隐藏 frame | `SoftHideFrame` | `core/tools.lua:52` | 透明移屏外但**保活**（保留 UIPanel 互斥） |
| 列表行工厂 | `DFUI.CreateSocialRow` | `core/tools.lua:819` | 全自制列表的单行（列定义/选中/双击/滚轮） |
| 凹陷容器 | `DFUI.CreateRetailInset` | `core/tools.lua:459` | 大理石底 + 9-slice 凹陷描边子页面 |
| 滚动条套件 | `DFUI.CreateRetailScrollbar` | `core/tools.lua:600` | 箭头 3 态 + 滑轨 + 滑块 |
| 内框描边 | `DFUI.ApplyInnerFrame` | `core/tools.lua:281` | DF 真实纹理九宫格内框（取代线框 backdrop） |
| 全自制面板范式 | （范式，无单一函数） | `modules/panels/social.lua`（who） | vanilla 透明保活 + UI 全自制脱钩 |
| UIPanel 互斥范式 | （范式，无单一函数） | `SoftHideFrame` + `HookScript` | 原版透明保活当互斥载体，可见 panel 跟随 |

> 加载顺序：`core/tools.lua` 与 `core/statusbar.lua` 首行均 `setfenv(1, DFUI:GetEnv())`，故文件内未加 `DFUI.` 前缀的 `KillFrame` / `SoftHideFrame` / `CreateStatusBar` / `FormatNumber` / `HookScript` 等也是 DFUI 环境下的全局符号。

---

## 二、关键文件

- `modules/panels/paperdoll.lua` —— 面板外框工厂 + 红色按钮工厂（移植自 D3 `ui-tools.lua`）。
- `core/tools.lua` —— 通用工具与多数工厂的集中地（杀/隐藏、测宽截断、数字格式化、按钮、列表行、凹陷容器、滚动条、内框描边、血量解析、配色表）。
- `core/statusbar.lua` —— 动画状态条工厂 + 全局动画泵（pulse / cutout / 平滑插值）。
- `modules/bars/bars.lua` —— 动作条模块，主要消费方而非工厂提供方（消费 `KillFrame`/`HideFrameTextures`，演示 grid/spacing/字体回调范式）。

---

## 三、核心实现

### 3.1 DFUI.CreatePaperDollFrame —— 面板外框工厂

```lua
-- modules/panels/paperdoll.lua:82
function DFUI.CreatePaperDollFrame(name, parent, width, height, frameStyle)
```

构造一个 DF 金属边框面板：**4 角 + 4 边**金属拼接（局部变量，统一收进 `frame.edges` 数组，8 元素，无具名字段）+ 岩石背景 `frame.Bg` + 内置 Tab 系统。

- `frameStyle` 取值（`paperdoll.lua:87-119`）：
  - `1` 带头像金属框，左上角 TexCoord 切到带头像版，并额外建 54×54 `frame.portrait`（`:110-116`）。
  - `2` 无头像金属框（左上角切到无头像 TexCoord）。
  - `3` 备用金属纹理：`metalTex` 用 `UIFrameMetal2x2`、横边用 `UIFrameMetalHorizontal2x2`（`:87-88`）。
- 纹理路径前缀：`Interface\AddOns\Dragonflight-Fix\media\tex\`（`paperdoll.lua:4`）。用到 `interface\UIFrameMetal2x.blp`、`...Horizontal2x.BLP`、`...Vertical2x.BLP`、`UI-Background-Rock.blp`、`uiframetabs.blp`。
- 背景锚点 `TOPLEFT(2,-21) → BOTTOMRIGHT(-2,2)`（`:99-100`）；顶角 75×75、底角 32×32（**不对称设计**，顶厚底薄）。
- 挂到 frame 的字段仅：`frame.Bg`、`frame.portrait`（仅 style 1）、`frame.edges`、`frame.Tabs`、`frame.selectedTab`。

**Tab 系统**（`frame:AddTab(text, onClick, tabWidth, spacing)`，`paperdoll.lua:187`）：
- 三段式拼接（左 + 中 + 右），纹理 `uiframetabs.blp`。未选中态高 36px、选中态高 39px（`selHeight`，`:219`）。
- 高亮 ADD blend、alpha 0.4（`:252-253` 等）。
- 自动宽度：未传 `tabWidth` 时 = 文字宽 + 50（`:281-285`）。
- 文字色：选中白 `(1,1,1)`、未选中金 `(1,0.82,0)`（`:307`/`:318`）。
- 返回的 tab 附 `tab:SetSelected(bool)` / `tab:Enable()` / `tab:Disable()`（`:296`/`:322`/`:333`）。
- 点击播 `igCharacterInfoTab` 音效并切换 `frame.selectedTab`（`:353-361`）；首个 tab 自动选中（`:366-369`）。

### 3.2 DFUI.CreateRedButton —— 红色窗口按钮

```lua
-- modules/panels/paperdoll.lua:25
function DFUI.CreateRedButton(parent, buttonType, onClick)
```

- `buttonType` ∈ `"close"` / `"minimize"` / `"maximize"`；非法值返回 `nil`（`:26-27`）。
- 21×21，纹理 `interface\redbutton2x.BLP`（`:23`），normal/pushed/highlight 三态由 `BUTTON_TEXCOORDS` 表切片（`:7-21`）；highlight ADD blend。
- 附 `button:SwitchType(newType)` 运行时换类型（`:55`）。

### 3.3 DFUI.CreateActionButton —— DF 文字操作按钮

```lua
-- core/tools.lua:952
function DFUI.CreateActionButton(parent, width, text, onClick, height)
```

- 红金属 emboss **9-slice 三段**拼接：leftCap 12 + middle 拉伸 + rightCap 12（`makeSlice`，`:960-977`）。素材 `media\tex\panels\df\professions\btn_{up,down,hl}.tga`（128×32 POT，现成贴图，无需重启）。
- TexCoord：`AB_TC_L={2/128,14/128,2/32,22/32}`、`AB_TC_M={14/128,64/128,...}`、`AB_TC_R={64/128,78/128,...}`（`:948-950`，右边界抠到 78/128 以含全右边框线）。
- 默认高 24（`height` 可覆盖，`:954`）；金色 OUTLINE 文字，字号随高度缩放 `floor(h/24*16+0.5)`（`:990`）。
- 按下态：`OnMouseDown/Up` 整体换 `btn_down.tga`（1.12 不支持多纹理 `SetPushedTexture`，`:981-987`）。
- 禁用态：`btn:SetEnabledDF(on)`（`:1004`）—— slice 变暗 `SetVertexColor(0.4)` + 高亮 alpha 0 + label 转灰 + `dfDisabled` flag 屏蔽 OnClick/OnMouseDown。**注意是 `SetEnabledDF`，不是 vanilla `Enable/Disable`**（避免冲突）。

### 3.4 CreateStatusBar —— 动画状态条工厂（脉冲 / 切割）

```lua
-- 原始定义 core/statusbar.lua:45
-- 末尾 :335 包装重定义（同名，含动画泵自启）
function CreateStatusBar(parent, width, height, animConfig)
```

返回一个由 BACKGROUND `bar.bg` + ARTWORK `bar.fill` 组成的条，**填充靠 `SetTexCoord` + `SetWidth` 实现**（`bar:Update`，`:78-95`；retail 无 StatusBar 填充快捷 API）。

三套独立动画，由 `animConfig` 默认全开（`:73-76`，`barAnim`/`pulse`/`cutout` 显式传 `false` 才关）：

1. **平滑插值（barAnim）**：`SetValue` 改目标 `val`，显示值 `val_` 每帧朝目标 lerp，速率 `ANIMATION_RATE=6`（`:7`，`UpdateBarAnimations`，`:228-251`，帧率无关并对大 dt 钳制）。
2. **脉冲(pulse)**：仅**掉值**时触发（`val < oldVal`，`:148-149`），fill 颜色在 `baseColor↔pulseColor` 间淡入淡出，时长 `PULSE_DURATION=0.3`、淡入占比 `PULSE_FADE_IN=0.1`、淡出曲线指数 `PULSE_CURVE=0.7`（`:8-10`，`UpdatePulseAnimations`，`:253-291`）。**回血/回蓝不闪**（设计如此）。
3. **切割(cutout)**：掉值时从对象池取一张纹理覆盖在"失去的那段"上并淡出，时长 `CUTOUT_DURATION=0.3`、`CUTOUT_ALPHA=1`（`:11-12`，`UpdateCutoutAnimations`，`:293-307`）。对象池 `AcquireCutoutTexture`/`ReleaseCutoutTexture`（`:17-42`）避免永久纹理分配泄漏。

配置方法（均挂在返回的 bar 上）：`SetValue(val, instant)`、`SetInstant`、`SetBarAnimation`、`SetPulseAnimation`、`SetCutoutAnimation`、`SuppressCutout(duration)`、`SetTextures(fill, bg)`、`SetFillColor`、`SetCutoutColor`、`SetPulseColor`、`SetBgColor`、`SetFillDirection('LEFT_TO_RIGHT'|'RIGHT_TO_LEFT')`（`:97-222`）。

**动画泵**：单个共享 `Frame` 的 OnUpdate（`AnimateOnUpdate`，`:312-323`），三个动画表（`animations`/`pulses`/`cutouts`，均 `__mode="k"` 弱表，`:3-5`）全空时自动卸 OnUpdate；`:335` 的重定义包装把 `SetValue` 后接 `EnsureAnimating()`（`:325-331`）重新挂泵，且重置时钟避免空闲后首帧大 dt 跳变。

### 3.5 DFUI.TruncateToWidth / DFUI.MeasureWidth —— 文本测宽与截断

```lua
-- core/tools.lua:1036
function DFUI.TruncateToWidth(text, maxW, font)
-- core/tools.lua:1072
function DFUI.MeasureWidth(text, font)
```

- 1.12 无原生省略号截断，靠**隐藏 FontString 实测 `GetStringWidth`**（`dfuiGetMeasureFS`，`:1024-1033`，按 font 缓存测量 FontString，缺省 `GameFontNormalSmall`）。
- 截断按 **UTF-8 字符边界**逐字符步进（lead byte：≥240→4 字节、≥224→3 字节即中文 BMP、≥192→2 字节，`:1056-1058`）；预算 = `maxW - 省略号宽`。
- 省略号优先单字符 `…`（U+2026），若字体缺字形（测宽 0）退回三点 `...`（`:1046-1049`）。
- 结果缓存 `truncCache`（key=`text\1maxW\1font`，`:1035-1044`），切 tab / 列表反复刷新可跳过整个逐字符循环。
- `MeasureWidth` 复用同一测量 FontString，颜色码 `|cff..|r` 不计宽（`:1072-1077`）；典型用于给可变后缀（如 status 列）预留宽度。

### 3.6 FormatNumber —— 数字缩写

```lua
-- core/tools.lua:234
function FormatNumber(num)
```

`>=1000000 → "%.1fM"`、`>=1000 → "%.1fk"`、否则 `tostring(num)`（`:234-242`）。注意只缩写、不做千分位；小于 1000 原样字符串。

### 3.7 KillFrame / SoftHideFrame —— 两种隐藏语义（关键区别）

```lua
-- core/tools.lua:3
function KillFrame(frame)
-- core/tools.lua:52
function SoftHideFrame(frame)
```

- `KillFrame`（`:3-48`）：`UnregisterAllEvents` + `Hide` + 清一组脚本（OnShow…OnValueChanged，`:15-19`，逐个 `pcall` 取脚本后置 nil）+ `SetParent(UIParent)` + `ClearAllPoints` + `SetAlpha(0)` + 禁鼠标/键盘。**彻底脱离**，frame 退出 UIPanel 系统。
- `SoftHideFrame`（`:52-58`）：仅 `SetAlpha(0)` + 禁鼠标 + 移屏外 `TOPLEFT(UIParent, -10000, 10000)`，**不 Hide、不清事件/脚本**。目的是让 frame 继续活在 UIPanel 互斥系统里（见 3.10）。
- **选型铁律**：要做 UIPanel 互斥载体的原版 frame 必须用 `SoftHideFrame`，不可用 `KillFrame`（`KillFrame` 含 `Hide` → 原版脱离 UIPanel 系统 → 互斥失效）。

### 3.8 DFUI.CreateSocialRow —— 全自制列表行工厂

```lua
-- core/tools.lua:819
function DFUI.CreateSocialRow(parent, opts)
```

Friend / Who / Guild 等列表共用的单行（`Button`）工厂，column-driven、左右双向链锚：

- `opts.columns` 数组（用 `table.getn` 遍历，`:875`）：每列 `type="texture"|"fontstring"`、`anchor="LEFT"|"RIGHT"`、`width`/`offsetX`/`color` 等。LEFT 列从 `row.LEFT` 起正向链锚，RIGHT 列从 `row.RIGHT` 起反向链锚（`:893-908`）；子元素挂 `row[col.name]`。
- 字体色取自 `DFUI.SocialRowColors`（`core/tools.lua:776-784`，main/next_/dim/online/offline/afk/dnd）。
- 内置 hover 高亮（`UI-QuestTitleHighlight` ADD，`:857-861`）、选中态 `row:SetSelected(bool)`（蓝半透 ADD，`:864-870`/`:931-933`）。
- 左右键分发 + **自实现双击**（GetTime 记上次左键，<0.4s 视为双击，`:914-929`）。
- **滚轮**（`:831-854`）：对 vanilla ScrollFrame parent 走 `SetVerticalScroll`，对普通 Frame parent（全自制列表）跳过滚动仅调 `opts.onWheel` 翻页；**绕开** vanilla `ScrollFrameTemplate_OnMouseWheel`（访问 FauxScrollFrame 没设的 `scrollBar` 字段会 nil 报错）。

### 3.9 全自制面板范式（vanilla 透明保活 + UI 脱钩）

无单一函数，是结构性范式。**权威范例：`modules/panels/social.lua` 的 who do-block**（消费 `DFUI.CreateSocialRow` + `DFUI.CreateActionButton` + `DFUI.CreateRetailScrollbar`）。

核心原则：
1. **数据层复用引擎 API**（`SendWho`/`GetWhoInfo`/`GetNumWhoResults`/`SortWho` 等），无副作用、绕不过。
2. **UI 层全自制并与 vanilla 脱钩**：vanilla 框架（如 `WhoFrame`）透明保活当数据载体 + 事件源 + 互斥载体，但隐藏其所有可见子控件（按钮/下拉/EditBox/列表按钮）并拦截鼠标。
3. **铁律：自制行的 parent 必须挂自有 inset，绝不挂 vanilla `FauxScrollFrame`** —— `FauxScrollFrame_Update` 在「结果数 ≤ 可显示数」时会 `Hide()` 整个滚动框，连带隐藏寄生其上的自制行。
4. **offset 自管**：用 upvalue 维护翻页 offset + 滚轮翻页，不用 `FauxScrollFrame_GetOffset/SetOffset`。
5. 行高/可见行数用 `GetTop-GetBottom` 计算（1.12 `GetHeight` 在双锚冲突或未 reflow 时返回错值）。

通用坑：
- 隐藏 vanilla 可见控件时遍历 `GetChildren()` 只处理 Button 会漏 **下拉/EditBox（它们是 Frame）**，需单独 `Hide()+SetAlpha(0)+EnableMouse(false)`。
- vanilla 控件盖在自制控件上会拦截鼠标 → 自制 OnClick 收不到点击，根治 = 隐藏拦截源。
- 纯 `Texture` 无按下态，靠 parent Button 的 `OnMouseDown/Up` 手动切纹理驱动。
- 新增 TGA/BLP 贴图须重启 WoW.exe 才识别（`/reload` 无效）。

### 3.10 UIPanel 互斥范式（原版透明保活当载体）

无单一函数；工具是 `SoftHideFrame`（`core/tools.lua:52`）+ 全局 `HookScript` polyfill（`core/tools.lua:100-106`）。

DF-Fix 的主面板（技能书/制造/角色/社交）可见 UI 都是新建独立 frame，**都不注册 `UIPanelWindows`**；面板间互斥靠背后保活的原版 frame 提供。正确模式：
1. 原版 frame **透明保活**：`SoftHideFrame` 或等效（`SetAlpha(0)` + 移屏外 + `EnableMouse(false)`），**不 `Hide()`**。
2. 开关统一走 `ShowUIPanel(原版)` / `HideUIPanel(原版)`。
3. 可见 panel 经 `HookScript(原版, "OnShow"/"OnHide", ...)` 被动跟随显隐（单向数据流）。

两个反模式（都会破坏互斥）：
1. `KillFrame(原版)`（含 `Hide`）→ 原版脱离 UIPanel 系统 → 可见 panel 只能独立 `:Show()` → 与所有走 UIPanel 的面板同屏穿插。
2. 把**可见 frame** 注册进 `UIPanelWindows` → `ShowUIPanel` 时 `UIParent_ManageFramePositions` 接管位置、覆盖自定义 `SetPoint`、破坏拖动（1.12 无 retail 的 `SetAttribute("UIPanelLayout-...")` 可声明自管位置）。

> 注：技能书覆写 `ToggleSpellBook` 走 `Show/HideUIPanel` 后，还需 `UnregisterAllEvents` + 清原版 OnShow/OnHide，否则 vanilla `SpellBookFrame` OnShow 会重复播 `igSpellBookOpen`。具体落点见 social.lua / 技能书模块，本文不重复行号。

---

## 四、辅助工厂（同在 core/tools.lua，补充列出）

- `DFUI.ApplyInnerFrame(frame, opts)`（`:281`）—— DF 真实纹理九宫格内框，取代 `SetBackdrop` + `UI-Tooltip-Border` 线框。`preset` ∈ auto/hairline/small/medium/large（auto 按 `frame:GetHeight` 选档，`:303-309`）；总开关 `DFUI.APPLY_INNER_FRAME_ENABLED`（`:257`），关闭时降级到 `AddSubBorder`。返回 borderFrame 挂 `.corners`/`.edges`/`.bg`。
- `DFUI.CreateRetailInset(parent, opts)`（`:459`）—— 大理石底 + 4 边凹陷描线 + 4 角圆角的凹陷子页面，支持 `followFrame`/`followFrames` 跟随显隐（`:536-551`）。返回 inset 挂 `.bg`/`.edges`/`.corners`。
- `DFUI.CreateRetailScrollbar(parent, listFrame, opts)`（`:584`）—— ui-scrollbar 整图系列（箭头 4 态原生纹理 + knob 滑块 + sliderbar 轨道，零 UV）；回调 `onScrollDelta(±1)` / `onScrollAbs(0..1)`；返回 sb 附 `sb.UpdateThumb(scrollOff, maxOff, visRows, totalRows)`（点调用，无 self）。
- 小工具：`HideFrameTextures(frame)`（`:60`，隐藏所有 Texture region）、`AddSubBorder(parent, frame, inset)`（`:86`，UI-Tooltip-Border 描边兜底）、`CreatePanelCheckbox(parent, text)`（`:220`）、`HookScript(f, script, func)`（`:100`，链式脚本 polyfill）。

---

## 五、已知坑与限制

1. **Lua 5.0**：所有遍历列定义/对象池用 `table.getn`（`tools.lua:875`、`statusbar.lua:23`），勿改成 `#`，否则全文件不加载。
2. **填充全靠 SetTexCoord + SetWidth**：`CreateStatusBar` 与所有九宫格工厂均无 retail `SetAtlas`/`SetHorizTile`，靠 UV 切片 + 拉伸。改 UV 必须对照实际贴图尺寸。
3. **KillFrame vs SoftHideFrame 不可混用**：互斥载体必用 `SoftHideFrame`；要彻底干掉的孤立 frame（如 `bars.lua:129` `KillFrame(ExhaustionTick)`）才用 `KillFrame`。
4. **pulse 只在掉值触发**：回血/回蓝不闪是设计行为，非 bug。
5. **新增贴图须重启**：`CreateActionButton` 等用现成 `btn_*.tga` 故免重启；若自加新 TGA/BLP，须重启 WoW.exe，`/reload` 不识别。
6. **TGA 须 POT**：1.12 下 TGA 宽高都须为 2 的幂，非 POT 会被静默丢弃。
6b. **⭐ `SetDrawLayer` 的第二参（subLevel）在 1.12 被静默忽略**（2026-07-26 定案）——**不报错**，纯视觉错，比 nil method 更难定位。同一 frame 内两个纹理若都落在同一 layer，绘制顺序**不稳定**，会随机互盖。
   - **案例（天赋插画"时有时无/大块发黑"的真根因）**：`modules/ui/talents.lua` 的插画写 `SetDrawLayer('BACKGROUND', 2)` 想排在 `inset.bg`（`CreateRetailInset` 铺满的暗岩石，BACKGROUND）之上 → subLevel 被忽略、两者同层 → 岩石随机盖住插画。这个 bug 从 `582dd3d`（引入 inset 那一刻）起潜伏至今，期间被误判成"大 TGA 加载失败"、"未压缩纹理显存不足"，换素材/换格式全部无效。**修法：插画改 `CreateTexture(nil,'BORDER')`**，层序 `bg(BACKGROUND) < 插画(BORDER) < edges(ARTWORK) < corners(OVERLAY)`。
   - **同形先例**：`modules/panels/character.lua:182,188`（岩石 BACKGROUND / 羊皮纸 BORDER，注释已写"1.12 不可靠"）、`modules/panels/inspect.lua:235`（inspectCharBg 用 BORDER）。
   - **通用规则**：**同 frame 内排序一律用不同 draw layer 分离，绝不赌 subLevel**。`BACKGROUND < BORDER < ARTWORK < OVERLAY < HIGHLIGHT`。
   - **待审计清单**（本项目还有 38 处两参数 `SetDrawLayer`，目前看着正常、暂不动；哪个面板出现"随机被盖"就按上面套路修）：同 frame 内确有同层竞争者的高危点 = `spellbook.lua:140,147`（`ARTWORK,2` vs inset.edges `ARTWORK/0`）、`trade.lua:115`（`BACKGROUND,-8` vs 金银铜图标）、`bags.lua:116,123 / 171,190`、`mini.lua:315,325,338`、`focus.lua:139,148`、`paperdoll.lua:97`。
7. **GetHeight 不可靠**：`ApplyInnerFrame` 的 auto preset 依赖 `frame:GetHeight`（`:304`）——若 frame 在 SetSize/双锚冲突或未 reflow 时调用会选错档；算尺寸优先 `GetTop-GetBottom`。
8. **`CreateRetailScrollbar` 内含调试遗留**：箭头纹理目前被 `SetVertexColor(1,0,0,1)` 染红（`tools.lua:624`，注释标 DEBUG），且 track 3-slice 被注释掉（`:649`）——视为"待清理/待游戏内复核"状态，复用前先确认其当前视觉。
9. **运行期视觉/尺寸须实测**：`CreatePaperDollFrame` 内部 `SetWidth/SetHeight` 与 `TOPLEFT+BOTTOMRIGHT` 双锚在 1.12 冲突（固定尺寸优先，BOTTOMRIGHT 被忽略）——宽框体须单锚 + 动态算尺寸传入；暴雪原框实际尺寸（`.pub` 加密看不到 XML）一律**待游戏内实证**（`GetWidth/GetHeight`）。
