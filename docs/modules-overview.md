# 其余模块速览

> 优先级：**P2**
> 范围：施法条 / 背包 / 地图小地图 / 微型菜单 / 经验声望条 / 提示框 / 聊天 / 通用框架美化 / 滚动条
> 事实源：各模块 `.lua` 源码（行号以当前代码为准）

---

## 通用结构约定

这 9 个模块都遵循同一套框架（详见 `dragonflight-fix-execution-plan.md` 的核心架构）：

- `DFUI:NewDefaults("模块名", {...})` 声明配置项与默认值，每项格式为
  `{默认值, 控件类型, 控件参数, 父依赖项, 分组, 排序, 说明, 警告, nil}`。
- `DFUI:NewMod("模块名", priority, function() ... end)` 注册模块主体。
- 仅 4 个模块用 `local f = CreateFrame("Frame"); f:RegisterEvent("PLAYER_ENTERING_WORLD")` 延迟到进世界后再初始化：Bags（bags.lua:16）、Map（map.lua:46）、Xprep（xprep.lua:40）、Frames（frames.lua:7）。其余 5 个模块（Cast/Micro/Tooltip/Chat/Scrollbar）不延迟，在 `NewMod` 回调体内直接初始化（详见各节）——Cast 在体内直接 `Setup:Castbar()`（cast.lua:514），其 frame `f`（cast.lua:505）只注册 `ADDON_LOADED` 探测 ShaguTweaks，并非延迟初始化；Micro 在体内直接 `Setup:Run()`（micro.lua:357）。
- 结尾统一 `DFUI:NewCallbacks("模块名", callbacks)` 把配置回调批量注册并执行一次。
- 配置读取走 `DFUI:GetTempDB("模块名", "键")`，写入走 `DFUI:SetTempDB` / `DFUI:SetTempDBNoCallback`。
- 长期运行的 OnUpdate 脚本通过 `DFUI.activeScripts["名称"] = true/false` 标记（供性能监控）。

---

## 1. 施法条（Cast）

### 概览

完全自绘的玩家施法条，**接管并禁用** vanilla `CastingBarFrame`。支持施法/引导两种模式、推条（pushback）回退动画、三种填充方向、火花与完成闪光动画，可选显示法术图标（需 ShaguTweaks 提供 `UnitCastingInfo`）。

### 关键文件

- `modules/cast/cast.lua`
- 纹理：`media\tex\castbar\`（`CastingBarBackground.blp`、`CastingBarStandard3.blp`、`CastingBarFrame.blp`、`CastingBarFrameDropShadow.blp`、`CastingBarFrameFlash.tga`），火花用 vanilla `Interface\CastingBar\UI-CastingBar-Spark`（cast.lua:54-59）

### 核心实现（函数名 + 文件:行）

- `Setup:Castbar(parent)` cast.lua:92 — 隐藏并清空 `CastingBarFrame` 的 OnEvent/OnUpdate（cast.lua:93-95），新建 `DFUICastbar`，注册 8 个 `SPELLCAST_*` 事件（cast.lua:176-183），暴露为 `DFUI.castbar` / `DFUI.castbar.bar`。
- `Setup:UpdateBarVisual(progress)` cast.lua:201 — 按 `fillDirection`（left/right/center）用 `SetWidth` + `SetTexCoord` 绘制进度，并定位火花；center 模式用两个火花。
- `Setup:OnUpdate(elapsed)` cast.lua:267 — 平滑插值 currentProgress、处理推条回退、闪光淡出、剩余时间文字格式化。
- `Setup:HandleEvent(event, arg1, arg2)` cast.lua:385 — 处理 START/STOP/FAILED/INTERRUPTED/DELAYED 及 CHANNEL 系列事件，设置颜色（完成绿、失败红）。
- 回调集 cast.lua:519-675：`castDarkMode`/`castColor`/`setFillDirection`/`barWidth`/`barHeight`/`fontSize`/`castFont`/`showIcon` 等；字体走 `GetFontPath`。
- 图标支持 `callbacks.showIcon` cast.lua:633 — 建独立 OnUpdate 帧轮询 `UnitCastingInfo`/`UnitChannelInfo`（来自 ShaguTweaks）。

### 已知坑或限制

- 强依赖 vanilla 的 `SPELLCAST_*` 事件（1.12 本身**无目标施法条事件**），故只能做玩家施法条。
- `showIcon` 仅在 ShaguTweaks 已加载并暴露 `UnitCastingInfo` 时生效，否则 `UnitCastingInfo` 为 nil，OnUpdate 内部判空跳过（cast.lua:496-512、638）。
- `UpdateBarVisual` 注释明确：宽度设 0 会让 center 模式出错，故下限钳到 0.1（cast.lua:208）。
- 推条/插值的视觉平滑度属运行期表现，**待游戏内实证**。

---

## 2. 背包（Bags）

### 概览

对 vanilla 背包栏（主背包 + 4 个角色背包槽 + 钥匙环）做 DF 风格换肤，新增背包折叠切换按钮、空位计数文字、悬停显隐、缩放/透明度调节。不接管背包内容窗口（仍是 vanilla `ContainerFrame`）。

### 关键文件

- `modules/bags/bags.lua`
- 纹理：`media\tex\bags\`（`bigbag`、`bigbagHighlight`、`bagslots2x`、`bagslotCutout`、`expand`、`KeyRing-Bag-Icon`），字体 `media\fnt\Myriad-Pro.ttf`（bags.lua:21-22）

### 核心实现（函数名 + 文件:行）

- `Setup:MainBag()` bags.lua:36 — 重定位 `MainMenuBarBackpackButton`，换主背包图标/高亮/边框（`bagslotCutout`）。
- `Setup:SmallBags()` bags.lua:67 — 给 `CharacterBag0Slot`…`CharacterBag3Slot` 设统一 atlas TexCoord、边框、图标。
- `Setup:KeyRing()` bags.lua:137 — 换钥匙环按钮纹理与图标（先判 `if not KeyRingButton then return`）。
- `Setup:BagToggleButton()` bags.lua:195 — 建 `DFUIBagToggleButton`（暴露为 `DFUI.bagToggleButton`），点击翻转 `toggleBags`。
- `Setup:UpdateBagSlotIcons()` bags.lua:219 / `Setup:UpdateKeyRingButtonVisibility()` bags.lua:234 — 刷新背包槽图标与钥匙环可见性。
- `Setup:KeyRingHook()` bags.lua:247 — `hooksecurefunc("MainMenuBar_UpdateKeyRing", ...)` 防 vanilla 重新显示钥匙环。
- 回调集 bags.lua:272-580：`bagDarkMode`/`bagColor`/`toggleBags`/`bagScale`/`bagAlpha`/`showBags`/`freeSlots`/`showToggle`/`hoverShow`（`hoverShow` 在 bags.lua:486-580，为该回调集末项）。
- `freeSlots` bags.lua:432 — 内部 `GetBagFreeAndTotal` 遍历 `0..NUM_BAG_SLOTS`，注册 `BAG_UPDATE` 刷新空位文字。
- 覆写 `SetItemButtonCount` bags.lua:582 — 修正背包按钮数字层级。

### 已知坑或限制

- 整模块在 `PLAYER_ENTERING_WORLD` 内初始化（bags.lua:14-18）。
- `showBags` 关闭分支的 `KeyRingButton:Hide()`（bags.lua:427）已加 `if KeyRingButton then` 判空（2026-06-01 修），与全文其余约 20 处守卫一致。
- `hoverShow` 用 `UIFrameFadeIn/Out` 做淡入淡出，依赖 vanilla 全局函数。

---

## 3. 地图小地图（Map）

### 概览

本模块体量最大，覆盖小地图全套：隐藏 vanilla 边框 + 自绘 DF 圆形/方形边框与阴影、顶部信息面板（区域名 + 本地/服务器时间）、自定义缩放按钮、邮件/追踪/耐久/任务追踪/Buff 重定位、`/track` 斜杠命令与独立可拖动追踪按钮 `DFUI_TrackBtn`，以及对 PizzaWorldBuffs / LFT / EBC 第三方插件的整合。

### 关键文件

- `modules/map/map.lua`
- 纹理：`media\tex\minimap\`（`uiminimapborder.tga`、`uiminimapshadow.tga`、`uiminimap_toppanel.tga`、`map_dragonflight_square2.tga`、`ZoomIn32/ZoomOut32` 系列、`mail.tga`、`dfui_collector_toggle.tga` 等）

### 核心实现（函数名 + 文件:行）

- `Setup:HideBlizzard()` map.lua:63 — 重定位 Minimap、隐藏 `MinimapBorder`/`MinimapBorderTop`/`MinimapToggleButton`、`KillFrame(MinimapShopFrame)`。
- `Setup:Minimap()` map.lua:79 — 自绘边框/阴影纹理，开启滚轮缩放（`MinimapZoomIn:Click()`）。
- `Setup:TopPanel()` map.lua:96 — 建 `MinimapTopPanel`（暴露 `DFUI.topPanel`），托管 `MinimapZoneText` 与自建时间 FontString，OnUpdate 每 5 秒刷新时间，时间框带 Local/Server tooltip。
- `Setup:ZoomButtons()` map.lua:156、`Setup:Mail()` map.lua:178、`Setup:Buffs()` map.lua:189、`Setup:Tracker()` map.lua:209、`Setup:Durability()` map.lua:218、`Setup:Questlog()` map.lua:225（暴露 `DFUI.questframe`）、`Setup:LFT()` map.lua:239、`Setup:EBC()` map.lua:254 — 各自重定位/换肤对应原生框体。
- `Setup:PizzaWorldBuffs()` map.lua:264 / 内部 `PWBInit(color)` map.lua:267 — 建 `DFUI_PWB_Panel`，hook PWB `updateFrames` 重排联盟/部落文字行并可选着色，附带小地图折叠按钮。
- 回调集 map.lua:513-721：`mapSize`/`mapAlpha`/`mapShadow`/`showZoom`/`mapSquare`/`topPanel*`/`zoneText*`/`time*`/`timeFormat12h`/`showSunMoon`/`textColor` 等；`mapSquare` 切换圆/方遮罩（`SetMaskTexture`）。
- `/track` 斜杠命令 map.lua:729 — 扫描法术书追踪类技能弹下拉菜单。
- 独立追踪按钮 `DFUI_TrackBtn` map.lua:786 起 — 右键弹菜单、左键拖动、`ScanTrackBtn`/`UpdateTrackBtnIcon`，监听 `MINIMAP_UPDATE_TRACKING` 等事件刷新图标。

### 已知坑或限制

- `mapSize` 默认项自带警告：**"Bug: 设置后移动角色(无法修复)"**（map.lua:7）。
- `textColor`（PizzaWorldBuffs 着色）默认项警告：**"BUG: 斜杠命令尚未实现 - 即将修复"**（map.lua:41）。
- `Setup:Buffs()` 对 `BuffButton32` 做存在性判断（Turtle 1.18 扩展槽，1.17 无，map.lua:202-206）。
- PWB / LFT / EBC 整合均带存在性判断，未装则跳过；`/track` 与追踪按钮的实际命中（关键字 + 纹理双重匹配）**待游戏内实证**。

---

## 4. 微型菜单（Micro）

### 概览

重排并换肤右下角微型菜单按钮（角色/法术书/天赋/任务/社交/世界地图/主菜单/帮助），在社交按钮后插入自建 PvP / LFT / EBC 三个按钮；提供灰/彩两套图标、低等级天赋占位按钮、网络状态面板（MS/带宽/FPS + 延迟指示灯），并接管 vanilla 帧率显示。

### 关键文件

- `modules/micro/micro.lua`
- 纹理：`media\tex\micromenu\`（灰图集 `uimicromenu2x.tga`、彩图目录 `color_micro\`、`Latency{Green,Yellow,Red}.tga`）

### 核心实现（函数名 + 文件:行）

- `Setup:CreateContainer()` micro.lua:43 — 建 `DFUIMicroMenuContainer`（暴露 `DFUI.microMenuContainer`）。
- `Setup:BlizzardButtons()` micro.lua:51 — 收集 8 个 vanilla 微型按钮。
- `Setup:PvPButton()` micro.lua:71 / `Setup:LFTButton()` micro.lua:97 / `Setup:EBCButton()` micro.lua:117 — 建三个自定义按钮及 tooltip/OnClick。
- `Setup:LowLevelTalentButton()` micro.lua:140 — 等级 <10 显示禁用天赋占位（`DFUILowLevelTalentsButton`），按 `PLAYER_LEVEL_UP` 切换。
- `Setup:ArrangeButtons()` micro.lua:185 — 在 index 5（社交）后插入三按钮，统一定位/尺寸并换角色按钮纹理。
- `Setup:HideOtherUI()` micro.lua:237、`Setup:DisableBlizzardFPS()` micro.lua:247、`Setup:NetStats()` micro.lua:261 — 隐藏冗余原生 UI、隐藏 vanilla 帧率文字、建 `DFUI_NetStatsFrame`（暴露 `DFUI.netStatsFrame`）与延迟指示灯，hook `ToggleFramerate` 控制显隐。
- 回调集 micro.lua:367-655：`microDarkMode`/`microColor`/`microScale`/`microAlpha`/`microSpacing`/`switchColor`（灰/彩切换，含 11 个按钮的 TexCoord 表）/`smallFPS`。

### 已知坑或限制

- `switchColor` 假设 `Setup.buttons` 索引 2..11 存在并大量硬编码 TexCoord（micro.lua:431-618）；按钮顺序依赖 `ArrangeButtons` 插入逻辑。
- 自建按钮（PvP/LFT/EBC）调用 `ShowTWBGQueueMenu`/`LFT_Toggle`/`ShowEBCMinimapDropdown` 等 Turtle/第三方全局函数，缺失时**点击行为待游戏内实证**。
- NetStats / 延迟指示灯仅在按 CTRL+R（`ToggleFramerate`）后显示（micro.lua:325）。

---

## 5. 经验声望条（Xprep）

### 概览

替换 vanilla 经验条与声望监视条，自绘两条独立 `StatusBar`（经验条在底部 25px、声望条 5px 处），带半透明背景、左右半幅边框纹理、休息经验蓝色、声望阵营态颜色、文字（常显/悬停/获得时 5 秒）、自动追踪获得声望的阵营。

### 关键文件

- `modules/xprep/xprep.lua`
- 纹理：`media\tex\xprep\`（`main.tga`、`border_half.tga`），背景借 vanilla `Interface\TargetingFrame\UI-StatusBar`（xprep.lua:45、82、88）

### 核心实现（函数名 + 文件:行）

- `Setup:BlizzardBars()` xprep.lua:71 — `KillFrame` 掉 `MainMenuBarPerformanceBarFrame`/`MainMenuExpBar`/`ReputationWatchBar`。
- `Setup:XPBar()` xprep.lua:77 — 建 `DFUI_XPBar`（暴露 `DFUI.xpBar`），左右各一条半幅边框（`border_half.tga`，右侧 `SetTexCoord(1,0,0,1)` 镜像）。
- `Setup:UpdateXPBar()` xprep.lua:112 — `UnitXP/UnitXPMax/GetXPExhaustion`，60 级隐藏，休息经验蓝色，文字含百分比与 rested%。
- `Setup:RepBar()` xprep.lua:150 — 建 `DFUI_RepBar`（暴露 `DFUI.repBar`）。
- `Setup:UpdateRepBar()` xprep.lua:178 — `GetWatchedFactionInfo`，standing 1..8 分色，文字用 `FACTION_STANDING_LABEL{n}`。
- 回调集 xprep.lua:247-502：`showXpBar`/`xpBar{Width,Height,Alpha,TextSize}`/`hoverXP`/`showXpOnGain`/`showXpText`/`rep*` 同构 + `autoTrack`/`bgAlpha`。
- `autoTrack` xprep.lua:446 — 注册 `CHAT_MSG_COMBAT_FACTION_CHANGE`，用 `FACTION_STANDING_INCREASED` 本地化模板构造 pattern 提取阵营名后 `SetWatchedFactionIndex`。
- 事件帧 xprep.lua:505 — `PLAYER_XP_UPDATE`/`PLAYER_LEVEL_UP`/`UPDATE_FACTION`/`UPDATE_EXHAUSTION` 驱动刷新；`showXpOnGain` 用 OnUpdate 倒计时 5 秒隐藏。

### 已知坑或限制

- ~~`autoTrack` 英文串字面量匹配~~ **已修（2026-06-01）**：改用 WoW 内置 `FACTION_STANDING_INCREASED` 模板（`%s→(.+)`、`%d→%d+`）+ `string.find` 捕获（Lua5.0 无 `string.match`），兼容 zhCN/enUS 等任意客户端语言。
- 经验文字中的 rested 文案为硬编码英文 `% rested`（xprep.lua:146）；与项目"改 UI 文字须同步 zhCN"约定存在缺口（本文档仅记录，不在此修改）。

---

## 6. 提示框（Tooltip）

### 概览

最小模块：让 GameTooltip 可选跟随鼠标、加 X/Y 偏移，并在 tooltip 上追加"目标的目标"和"距离"两行增强信息。**不做整体换肤**。

### 关键文件

- `modules/ui/tooltip.lua`（注意路径在 `ui/` 下，非 `tooltip/`）

### 核心实现（函数名 + 文件:行）

- `callbacks.toolTipMouse` tooltip.lua:19 — 开启时给 GameTooltip 装 OnUpdate，按 `GetCursorPosition`/`GetEffectiveScale` 实时贴光标。
- hook `GameTooltip_SetDefaultAnchor` tooltip.lua:43 — 非跟随模式下用 X/Y 偏移修正默认锚点。
- hook `GameTooltip` 的 `OnShow` tooltip.lua:73 — 取 `mouseover` 单位，追加"目标: 〈职业色名字〉"（`showTargetTarget`）与"距离: %.1f 码"（`showDistance`，`pcall(UnitXP, 'distanceBetween', ...)`）。
- `GetClassColorHex(unit)` tooltip.lua:62 — 经 `DFUI:GetClassColor` 取职业色十六进制。

### 已知坑或限制

- 该模块**未走 PLAYER_ENTERING_WORLD 延迟**，在 `NewMod` 回调内直接 hook。
- 距离功能依赖 UnitXP 扩展：代码注释明确 **"1.17 后 UnitXP_SP3 不再支持 'distanceBetween'"**，故用 `pcall` 静默兜底（tooltip.lua:91-98），实际能否取到距离**待游戏内实证**。
- 单位识别用 `mouseover` 代替 1.12 不存在的 `GameTooltip:GetUnit()`（tooltip.lua:78-79）。
- `showTargetTarget`/`showDistance` 的回调为空函数（tooltip.lua:103-104），开关实时生效靠 OnShow 内读 `setup`（即 `DFUI.tempDB.Tooltip`）。

---

## 7. 聊天（Chat）

### 概览

聊天框按钮换肤（DF 自绘 / vanilla 原版二选一）+ 显隐 + 着色 + 淡出，外加三项聊天增强：URL 检测可点击、时间戳、频道名缩写。增强功能通过包裹各 ChatFrame 的 `AddMessage` 实现过滤器链。

### 关键文件

- `modules/chat/chat.lua`
- 纹理：`DFUI:GetInfoOrCons("tex") .. "chat\\"`（`chat_menu`、`chat_up`、`chat_down`、`chat_down_full`，chat.lua:17、146-149）

### 核心实现（函数名 + 文件:行）

- `Setup:ChatFrame()` chat.lua:20 — `ChatFrame1Tab:SetClampedToScreen(true)`。
- `ApplyChatButtonColor(r,g,b)` chat.lua:36 / `ColorButtonTextures` chat.lua:27 — 给 5 个聊天窗的 Tab 三段纹理与上/下/到底按钮统一着色。
- 回调集 chat.lua:54-385：`chatDarkMode`/`chatColor`/`showButtons`/`blizzardButtons`（DF↔vanilla 纹理切换）/`fadeChat`（`SetFadeDuration`+`SetTimeVisible`，遍历 `NUM_CHAT_WINDOWS`）。
- `RebuildAddMessageHooks()` chat.lua:212 — 备份并覆写每个 ChatFrame 的 `AddMessage`，应用 `chatFilters` 过滤器链。
- URL 引擎：`urlPatterns` chat.lua:232（8 条 Lua 5.0 模式）/ `FormatURLLink` chat.lua:243 / `HandleURLs` chat.lua:251；hook `SetItemRef` chat.lua:262 处理 `url:` 链接点击，弹 `DFUI_URLCopyDialog` 复制框。
- 频道缩写：`AbbreviateChannels()` chat.lua:301 / `RestoreChannels()` chat.lua:331 — 改写 `CHAT_*_GET` 全局格式串为 [G]/[P]/[R] 等。
- 增强开关回调 chat.lua:341-382：`chatTimestamps`/`chatTimestampColor`/`chatURLDetect`/`chatURLColor`/`chatAbbreviate`。

### 已知坑或限制

- `showButtons` 默认项自带警告：**"BUG: 暴雪高亮在错误位置闪烁 - 即将修复"**（chat.lua:3）。
- AddMessage 包裹是侵入式：若其他插件也包裹同一 `AddMessage`，链顺序与兼容性**待游戏内实证**（与 ShaguTweaks 等共存须验证）。
- 频道缩写改全局 `CHAT_*_GET`，是进程级副作用，关闭时靠 `channelOriginals` 还原。

---

## 8. 通用框架美化（Frames）

### 概览

**不是换肤模块**，而是"全局移动框体"工具：把一批 DFUI 自建框体与 vanilla 框体统一加成可拖动，提供 CTRL+SHIFT+ALT 触发的网格 + 黄色高亮覆盖层 + 方向微调按钮（U/L/R/D），并把位置持久化到 `DFUI_FRAMEPOS`，支持档案切换时恢复。

### 关键文件

- `modules/frames/frames.lua`
- SavedVariable：`DFUI_FRAMEPOS`（持久化各框体 `{x, y}`）

### 核心实现（函数名 + 文件:行）

- `framesToMakeMovable` 表 frames.lua:11 — 列举可移动目标（PlayerFrame/TargetFrame/动作条/`DFUI.xpBar`/`DFUI.repBar`/`DFUI.castbar`/`DFUI.microMenuContainer`/Minimap/`DFUI.topPanel`/Buff 按钮等），运行期再 `table.insert` 血球/追踪按钮/`BuffButton32`（frames.lua:51-59）。
- `SaveFramePosition(frame)` frames.lua:62 / `RestoreFramePositions()` frames.lua:70 — 读写 `DFUI_FRAMEPOS`；恢复时跳过 `DFUI_AuraAnchor_*`（由 auras.lua 控制）。
- `DFUI:RestoreFramePositions()` frames.lua:87 — 暴露给档案切换调用。
- 网格 frames.lua:92-133 — 64 等分线，中线金色。
- `MakeFrameMovable(frame)` frames.lua:136 — 建 TOOLTIP 层黄色 overlay 拖拽 + 四向微调按钮 `CreateDirectionButton` frames.lua:177；`controlFrame` OnUpdate 每 0.1s 检测三键组合显隐网格/overlay（并临时显示 castbar/帧率/netStats 便于定位）。

### 已知坑或限制

- 编辑模式触发键为 **CTRL+SHIFT+ALT**（frames.lua:206、254）。
- `framesToMakeMovable` 引用了大量 `DFUI.*` 句柄，依赖其他模块**先于本模块**注册这些句柄（本模块 priority=2，frames.lua:5）；空句柄在 `MakeFrameMovable` 入口判空跳过（frames.lua:137、267）。
- 部分被注释代码（如 `BuffButton8:Show()`、TargetFrame 显隐）标注 "doesnt work yet"（frames.lua:221-222、230-231），属未启用。
- 动作条移动后会写 `actionbars/movable=false`（frames.lua:170-173）。

---

## 9. 滚动条（Scrollbar）

### 概览

全局滚动条 / 箭头 / 下拉框 / 翻页箭头换肤，铸铁青铜色调，匹配 Fix 金属边框风格。提供可复用的 `DFUI.Skin*` 工厂函数，并对一批 vanilla 面板的滚动条按名批量应用（延迟 + ADDON_LOADED 兜底）。

### 关键文件

- `modules/panels/scrollbar.lua`（开头 `setfenv(1, DFUI:GetEnv())`，scrollbar.lua:4）
- 纹理：vanilla `Interface\Buttons\WHITE8X8`（scrollbar.lua:14）、`Interface\ChatFrame\UI-ChatIcon-ScrollDown-*`（scrollbar.lua:33-35）、`Interface\Buttons\UI-Common-MouseHilight`（scrollbar.lua:36）、`Interface\Tooltips\UI-Tooltip-Border`（scrollbar.lua:153，`SkinDropDown` 的 edgeFile）

### 核心实现（函数名 + 文件:行）

- `SkinArrowButton(button, direction)` scrollbar.lua:38 — 24×24，按 up/down 翻转 TexCoord，换 ChatIcon 箭头纹理。
- `DFUI.SkinScrollbar(scrollbar)` scrollbar.lua:84 — 换上下箭头、隐藏原生 Top/Middle/Bottom 轨道纹理、建青铜滑块（thumb）+ 暗色轨道背景框；用 `_dfScrollSkinned` 防重复换肤。
- `DFUI.SkinDropDown(dropdown)` scrollbar.lua:132 — 隐藏 vanilla 下拉框 Left/Middle/Right，加暗色背景框。
- `DFUI.SkinPageButton(button, size)` scrollbar.lua:165 — 翻页箭头复位为亮金本色（去青铜）。
- `NudgeArrowTextures(button, dx, dy)` scrollbar.lua:235 — 只移动按钮内纹理不动帧本身。
- `ApplyAll()` scrollbar.lua:255 + 目标表 `scrollbarTargets`/`dropdownTargets`/`pageButtonTargets`（scrollbar.lua:185-230）— 任务/对话/NPC/训练师/邮件/团队/专业技能等面板滚动条按名换肤；商人翻页 32×32、邮件翻页 24×24。
- 应用时机 scrollbar.lua:272-301 — `PLAYER_ENTERING_WORLD` 延迟 0.5s 跑一次，`ADDON_LOADED` 延迟 0.2s 兜底再跑（处理按需加载面板）。

### 已知坑或限制

- 角色面板技能/声望滚动条、社交（好友/屏蔽/查找/公会）**刻意不接管**，保留 vanilla 亮金箭头（由 character.lua / social.lua 处理；scrollbar.lua:186、197、260）。
- 换肤目标是**硬编码名字表**，名字拼错或面板改名会静默失效（入口 `if frame then`）。
- 各面板换肤后实际视觉一致性属运行期表现，**待游戏内实证**。

---

> 各模块配置项的完整默认值/分组/警告以对应 `.lua` 顶部 `DFUI:NewDefaults` 为准；本速览只摘录关键项。
