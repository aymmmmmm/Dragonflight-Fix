# 动作条系统设计

优先级 P1。复刻 Dragonflight 风格的全套动作条：主条 + 多功能条 1-4 + 宠物条 + 变形条，外加翻页按钮、快捷键/宏文字重排、距离检测灰显与 Diablo 风格血/蓝球。

## 一、概览

动作条系统由三个独立 DFUI 模块构成，各自有自己的 `NewDefaults` / `NewMod` / `NewCallbacks`：

| 模块 | 文件 | 默认 enabled | 职责 |
|------|------|-------------|------|
| `Bars` | `modules/bars/bars.lua` | true | 主条、多功能条 1-4、宠物条、变形条、翻页、狮鹫装饰、快捷键/宏文字 |
| `RangeIndicator` | `modules/bars/range.lua` | true | 目标超出施法距离时按钮灰显/红叉 |
| `Orbs` | `modules/bars/orbs.lua` | **false**（默认禁用） | Diablo 风格血球/蓝球 |

三个模块均在 `PLAYER_ENTERING_WORLD` 后或模块加载时一次性接管 Blizzard 原生框体，之后通过事件 + OnUpdate 维护状态，通过 callbacks 响应配置面板实时改值。

## 二、关键文件

- `modules/bars/bars.lua` —— 动作条主体（1293 行，单文件）。所有逻辑封装在 `PLAYER_ENTERING_WORLD` 回调内的局部 `Setup` 表中（`bars.lua:68`），run 序在 `Setup:Run`（`bars.lua:521`）。
- `modules/bars/range.lua` —— 距离指示器（227 行）。
- `modules/bars/orbs.lua` —— 血/蓝球（388 行）。
- 贴图根：`media/tex/actionbars/`（Bars 与 RangeIndicator 共用），`media/tex/orbs/`（Orbs 专用）。已核验源码引用的贴图文件均存在于磁盘。
- 字体根：`media/fnt/`，快捷键/宏字体下拉项映射见 `helpers.getFontPath`（`bars.lua:550`）。

## 三、核心实现

### 3.1 接管 Blizzard 原生条（Bars）

- `Setup:HideBlizzard`（`bars.lua:120`）——隐藏 `MainMenuBar` / `MainMenuBarArtFrame` / `PetActionBarFrame` 纹理与鼠标，`KillFrame(ExhaustionTick)`，清空 `SlidingActionBarTexture0/1`、`BonusActionBarTexture0/1`、`ShapeshiftBar` 三段背景，并逐个隐藏 `ShapeshiftButton1-10` 的 Background/NormalTexture。
- `_G["MultiActionBar_Update"] = function() end`（`bars.lua:1283`）——空壳化 Blizzard 多功能条更新函数，防止其覆盖自定义布局。
- 隐藏选项面板里 4 个原生动作条复选框 `UIOptionsFrameCheckButton{33,34,35,36}`（`bars.lua:1285`）。

### 3.2 主条与帧结构（Bars）

- `Setup:MainBarFrames`（`bars.lua:156`）——创建 `DFUI_MainBar`（锚 `BOTTOM` of UIParent，偏移 `0,55`，宽 500 高 45）。`ActionButton1` 与 `BonusActionButton1` 重锚到其左下角。再创建 `DFUI_ActionBar`，以 `ActionButton1` 左上到 `ActionButton12` 右下两点定界。
- `Setup:MainBarBackground`（`bars.lua:236`）——左右两块 `HDActionBar.tga`（`DFUI_ActionBarLeftTexture` / `DFUI_ActionBarRightTexture`）拼成完整背景，右块用 `SetTexCoord(1,0,0,1)` 水平镜像。
- `Setup:ButtonBackgroundsAndBorders`（`bars.lua:254`）——为 12 个 `ActionButton` 各加一层 `HDActionBarBtn.tga` 背景 + `border.blp` 边框（尺寸 = 按钮宽高 +5）。
- `Setup:ButtonBorderHighlight`（`bars.lua:273`）——遍历 `buttonTypes`（`bars.lua:83`，共 8 类）×12，为每个按钮挂 `DFUI_BorderOverlay` 边框纹理，并把高亮纹理换成 `uiactionbariconframehighlight.tga`（`BlendMode="ADD"`）。
- 主条缩放/间距/网格：`callbacks.mainBarScale`（`bars.lua:1074`）、`callbacks.mainBarSpacing`（`bars.lua:1095`，仅在 grid==1 时生效）、`callbacks.mainBarGrid`（`bars.lua:1218`，依据 `layouts` 表重排并联动背景与狮鹫位置）。
- 网格布局表 `layouts`（`bars.lua:89`）：1=1×12、2=2×6、3=3×4、4=4×3、5=6×2、6=12×1（rows×cols）。slider 取值经 `math.floor(value+0.5)` 钳到 1-6。

### 3.3 多功能条 1-4（Bars）

四条映射关系（注意 1.12 内部命名与 UI 名顺序不一致）：

| UI 名 | Blizzard frame | 按钮前缀 | 默认显示 | 默认网格 | 排列方向 |
|-------|----------------|----------|----------|----------|----------|
| 多功能条 1（左下） | `MultiBarBottomLeft` | `MultiBarBottomLeftButton` | false | 1（横排） | 水平 |
| 多功能条 2（右下） | `MultiBarBottomRight` | `MultiBarBottomRightButton` | false | 1（横排） | 水平 |
| 多功能条 3（左侧） | `MultiBarLeft` | `MultiBarLeftButton` | false | 6（竖排） | 垂直 |
| 多功能条 4（右侧） | `MultiBarRight` | `MultiBarRightButton` | true | 6（竖排） | 垂直 |

- 初始锚定：`Setup:PositionMultiBars`（`bars.lua:299`）——左下锚主条上方 `0,12`，右下锚左下上方 `0,10`，右侧条锚 UIParent 右边 `-15,-50`，左侧条仅设 strata/level。
- 显示开关：`callbacks.multiBar{One/Two/Three/Four}Show`（`bars.lua:1164`-1206）——Show/Hide 同时写 `_G["SHOW_MULTI_ACTIONBAR_{1-4}"]`，1/2 还会触发 `Setup:RepositionBars`。
- 缩放/透明：各条 `Set Scale/Alpha`（`bars.lua:634`-682）。
- 间距：`helpers.setSpacing`（`bars.lua:615`）链式锚定，水平用 `RIGHT→LEFT`，垂直用 `BOTTOM→TOP`；条 2 的间距仅在其 grid==1 时生效（`bars.lua:650`）。
- 网格：`helpers.setGridLayout`（`bars.lua:578`）。**左/右侧条（MultiBarLeft/Right）按钮顺序反转**（`isReversed`，`bars.lua:587`），index 用 `13-i` 还原，使竖排从上到下视觉正序。
- 动态重排：`Setup:RepositionBars`（`bars.lua:180`）依据 `SHOW_MULTI_ACTIONBAR_1/2` 状态把右下条、宠物条、变形条堆叠到正确锚点；前置条件 `movable==true`（`bars.lua:182`），且若 `DFUI_FRAMEPOS` 已有该 frame 的手动位置则跳过（尊重用户拖拽）。监听 `CVAR_UPDATE`，经 1 秒 OnUpdate 防抖后执行（`bars.lua:216`），并维护 `DFUI.activeScripts["BarRepositionScript"]` 标志。

### 3.4 宠物条与变形条（Bars）

- 宠物条 `Setup:PetBar`（`bars.lua:323`）——新建 `DFUI_PetBar`，将 `PetActionButton1-10` 重父锚定，间距固定 36px。
- 变形条 `Setup:ShapeshiftBar`（`bars.lua:339`）——新建 `DFUI_ShapeshiftBar`，按 `GetShapeshiftFormInfo` 统计实际形态数居中（每按钮 43px，`bars.lua:351`）。
- BonusBar 监听 `Setup:BonusBarWatcher`（`bars.lua:362`）——`UPDATE_BONUS_ACTIONBAR` 时，若 `GetBonusBarOffset()>0`（盗贼潜行 / 德鲁伊变形等占用主条）则把 12 个 `ActionButton` 透明+禁鼠标，让 `BonusActionButton` 顶上；恢复时还原。Immersion 兼容补丁：恢复 alpha 前用 `DFUI_IsImmersionLoaded()`（`bars.lua:116`）判断，Immersion 在场时不强制 alpha=1（`bars.lua:373`）。
- 缩放/间距/透明 callback：`bars.lua:952`-982。间距走 `helpers.setSpacing(..., 'horizontal', 10)`（10 按钮）。

### 3.5 翻页按钮（Bars）

- `Setup:PagingButtons`（`bars.lua:382`）——新建 `DFUI_PagingContainer`（宽=`ActionBarUpButton:GetWidth()`，高 65），默认锚 `ActionButton12` 右侧 `15,-1`。给 `ActionBarUpButton` / `ActionBarDownButton` 换三态贴图（`page_up/down_{normal,pushed,highlight}.tga`），各设为 25×25 并上下分置；`MainMenuBarPageNumber` 重父居中。
- callback：`pagingShow`（`bars.lua:827`，整体显隐含页码）、`pagingScale`（`bars.lua:843`）、`pagingSwap`（`bars.lua:1034`，交换到主条左侧）、`pagingX`（`bars.lua:1045`，依 `pagingSwap` 决定锚向）。

### 3.6 快捷键与宏文字（Bars）

- `Setup:HotkeyMacroText`（`bars.lua:417`）——隐藏原生 `<name>HotKey`，为每个按钮新建 `<name>DFUI_KeybindText`（FontString），从 `GetBindingKey(commandMap[buttonType]..i)` 取绑定并压缩显示（`BUTTON→M`、`SHIFT-→S-`、`SPACE→SP`、`NUMPAD→NP-`、`MOUSEWHEELUP/DOWN→MWU/MWD` 等，`bars.lua:438`）。
- `commandMap`（`bars.lua:420`）把按钮前缀映射到绑定命令名；注意宠物按钮用 `BONUSACTIONBUTTON`、变形按钮用 `SHAPESHIFTBUTTON`、BonusActionButton 复用 `ACTIONBUTTON`。
- 宏名沿用原生 `<name>Name` FontString，仅改字体/颜色，不重建。
- 绑定变化监听 `DFUI_HotkeyBinding` 帧的 `UPDATE_BINDINGS` 事件（`bars.lua:479`），触发 `UpdateHotkeys`。
- 文字相关 callbacks：颜色/显隐/缩放/偏移见 `bars.lua:847`-950，字体切换 `callbacks.hotkeyFont`（`bars.lua:1151`）走 `helpers.getFontPath`。默认快捷键金色 `{1,0.82,0}`、宏白色，字号基准 hotkey 10、macro 9，乘以各自 scale。

### 3.7 狮鹫/双足飞龙装饰（Bars）

- `Setup:Gryphoons`（`bars.lua:490`）——`DFUI_GryphonContainer` 覆盖 actionBarFrame，左右各一 180×180 纹理。按 `UnitFactionGroup("player")` 选 `GryphonNew.tga`（联盟）或 `WyvernNew.tga`（部落），右侧 `SetTexCoord(1,0,0,1)` 镜像。
- callbacks：显隐/缩放/位置/透明（`bars.lua:684`-763）、翻转 `flipGryphoon`（`bars.lua:984`）、替换备选材质 `altGryphoon`（`bars.lua:997`，用 `altGyph.tga`/`altWyv.tga`）。

### 3.8 深色模式与配色（Bars）

- `callbacks.barsDarkMode`（`bars.lua:765`）/ `callbacks.barsColor`（`bars.lua:797`）——按 `intensity` 把基础色衰减 `c*(1-intensity)`，统一 `SetVertexColor` 应用到狮鹫、左右背景、12 个边框纹理及所有按钮的 `DFUI_BorderOverlay`。
- `callbacks.highlightColor`（`bars.lua:1208`）——改全部按钮高亮纹理顶点色。

### 3.9 距离检测灰显（RangeIndicator）

- 模块独立，贴图同样在 `media/tex/actionbars/`。
- `Setup:KillBlizz`（`range.lua:24`）——把 `ActionButton_UpdateHotkeys` 置空，避免原生逻辑干扰。
- `Setup:CreateIndicatorTexture`（`range.lua:28`）——每按钮挂一个指示器，两种形态：
  - 简单模式（`indicatorSimple`）：FontString "•"，红 `{1,0.2,0.2}` 或暗 `{0,0,0}`，锚右上。
  - 纹理模式（默认）：`indicator_.tga`，红 `{1,0,0}` 或暗 `{0,0,0}`，覆盖整个按钮居中。
- 距离判定 `Setup:CheckButtonRange`（`range.lua:66`）：按钮不可见 / 无 paged slot / 无目标 / 目标不可攻击 → 一律返回 true（不灰显）；否则 `IsActionInRange(slot)==0` 才视为超距。槽位用 `ActionButton_GetPagedID(button)`（`range.lua:71`）。
- 显隐切换 `Setup:UpdateIndicatorVisibility`（`range.lua:92`）：带淡入淡出（`indicatorFade`，用 `UIFrameFadeIn/Out` 0.2s）或瞬时显隐，用 `.showing` 标志避免重复触发。
- 性能：按钮引用一次性缓存 `Setup:GetCachedButtons`（`range.lua:120`，`while` 探测直到 nil），避免每帧 getglobal+字符串拼接。事件 `PLAYER_TARGET_CHANGED`/`ACTIONBAR_SLOT_CHANGED`/`SPELLS_CHANGED`（`range.lua:203`）+ OnUpdate 每 0.1s 轮询（`range.lua:212`），并维护 `DFUI.activeScripts["RangeIndicatorScript"]`。
- callbacks：`indicatorAlpha`/`indicatorDark`/`indicatorFade`/`indicatorSimple`（`range.lua:161`-197），切换 simple 时销毁重建指示器。

### 3.10 Diablo 风格血/蓝球（Orbs，默认禁用）

- 默认 `enabled = {false}`（`orbs.lua:6`）。贴图来源：Roth_UI（MIT）+ BeardleysDiabloOrbsVanilla，根目录 `media/tex/orbs/`。
- 启动时清理旧版本残留键 `staleKeys`（`orbs.lua:27`）。
- `CreateOrb`（`orbs.lua:39`）——单个球 150px（`ORB_SIZE`），分层：`bg`(orb_bg) → `fill`(orb_filling21) → `innerShadow` → `frame`(左/右不同) → `gloss`(0.35 alpha) → `lowGlow`(放大 1.4×) → `text`。鼠标悬停走 tooltip。
- 填充 `orb:SetFillValue`（`orbs.lua:100`）——按百分比 `SetHeight(ORB_SIZE*pct)` + `SetTexCoord(0,1,1-pct,1)`（自底向上裁切，1.12 无 StatusBar 用此 TexCoord 方案）；用 `lastPct`（×1000 取整）做变化检测跳过冗余更新。
- 锚定：血球锚 `DFUI_ActionBar`（无则 `MainMenuBar`）左侧 `45+xOff,10+yOff`，蓝球锚右侧（`orbs.lua:151`、`RepositionOrbs` `orbs.lua:169`）。`PLAYER_ENTERING_WORLD` 时清除 `DFUI_FRAMEPOS` 中两球条目并重锚，防 Frames 模块覆盖（`orbs.lua:246`）。
- 数据更新：事件 `UNIT_HEALTH/MAXHEALTH/MANA/RAGE/ENERGY/FOCUS/DISPLAYPOWER`（`orbs.lua:207`），`UpdateHealth`（`orbs.lua:218`）/`UpdatePower`（`orbs.lua:232`）带 `lastHP/lastMP` 缓存。蓝球颜色按 `UnitPowerType("player")` 取 `DFUI.powerColors`（Colors 模块未加载时用内置 fallback，`orbs.lua:186`）。
- 低血量警告：`SetLowAlert`（`orbs.lua:293`）低于 `lowHealthAlert` 阈值（默认 0.25）时显示 `orb_lowhp_glow.tga` 并启动呼吸脉冲（`StartGlowPulse` `orbs.lua:277`，`OnUpdate` 用 `sin` 调 alpha）；脉冲 OnUpdate 仅在需要时挂载。
- 文字格式 `orb:UpdateText`（`orbs.lua:120`）：`percent`/`current`/`current/max` 三种。
- callbacks（`orbs.lua:309`-385）：球缩放/透明/偏移、边框显隐/缩放/独立左右偏移、高光、文字显隐/字号/格式、低血阈值、总开关 `showOrbs`。

## 四、已知坑与限制

- **1.12 = Lua 5.0**：源码遍历用 `for i=1,12` 显式循环与 `ipairs(buttonTypes)`，不存在 `#` 长度操作符；引用本系统代码时取长度须用 `table.getn`。
- **缺 retail Texture API**：背景/狮鹫的镜像靠 `SetTexCoord(1,0,0,1)`，球填充靠 `SetHeight`+`SetTexCoord`，均非 `SetAtlas`/`SetHorizTile`（1.12 不存在）。
- **多功能条 3/4 按钮反转**：竖排两条在 `setGridLayout` 里用 `isReversed`（`bars.lua:587`），改这两条布局时勿假设按钮 index 与视觉顺序一致。
- **间距 callback 与网格耦合**：主条 `mainBarSpacing` 与条 2 `multiBarTwoSpacing` 仅在对应 grid==1 时生效（`bars.lua:1097`、`bars.lua:650`），非横排时调间距无效——属预期行为。
- **BonusBar 抢占主条**：盗贼潜行/德鲁伊变形等使 `GetBonusBarOffset()>0` 时，主条 12 键被透明禁用、由 BonusActionButton 顶替（`bars.lua:362`）；这是原版行为的复刻，非 bug。
- **Orbs 默认禁用**：需在配置面板手动开启；其锚点依赖 `DFUI_ActionBar` 存在（Bars 模块先于 Orbs 建立），否则回退 `MainMenuBar`。
- **Orbs 与 Frames 模块位置冲突**：靠 `PLAYER_ENTERING_WORLD` 清 `DFUI_FRAMEPOS` 两球条目兜底（`orbs.lua:246`）。
- **WoW 1.12 血量真实性**：Orbs 直接读 `UnitHealth("player")`（自身玩家准确）。若未来扩展到其他单位，需注意 SuperWoW 不接管 UnitHealth，估算须另引 libhealth。
- 运行期表现（淡入淡出实际观感、各条堆叠后是否遮挡、Immersion 共存效果、低血脉冲频率）**待游戏内实证**。
