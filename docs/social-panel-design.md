# 社交面板设计（Social / FriendsFrame）

> 优先级：**P0**
> 状态：**已实现**（who 查找已根治并经用户认可；好友/公会同构）
> 唯一事实源：`modules/panels/social.lua`（2062 行，单文件）
> 工厂依赖：`core/tools.lua`

---

## 一、概览

社交面板复刻 vanilla `FriendsFrame` 的「好友 / 查找 / 公会 / 团队」四个分页，做成 DF Retail 风格。
整体遵循两条贯穿全项目的范式：

1. **UIPanel 互斥保活**（见 `reference-uipanel-mutex-pattern`）：不新建独立窗口、不注册 `UIPanelWindows`，
   而是隐藏 vanilla `FriendsFrame` 的所有可见装饰，在它身上叠一个 DFUI 框体 `customBg`，
   面板显隐仍走 vanilla `ShowUIPanel/HideUIPanel(FriendsFrame)`，自定义 UI 经 `HookScript(FriendsFrame,"OnShow",...)` 被动跟随。
2. **全自制 + 数据层复用**（见 `reference-dfui-fullcustom-panel`）：
   数据仍用引擎 API（`GetFriendInfo`/`GetWhoInfo`/`GetGuildRosterInfo`/`SendWho` 等），
   但列表行、搜索框、操作按钮全部自制并**脱钩 vanilla FauxScrollFrame**，
   vanilla 子控件（按钮/EditBox/下拉/列表 button）一律隐形 + 禁鼠标，仅留 `WhoFrame`/`GuildFrame` 等当数据载体。

模块入口：`DFUI:NewMod("Social", 5, function() ... end)`（social.lua:63）。

---

## 二、关键文件与函数

| 区域 | 范围（social.lua） | 说明 |
|------|------|------|
| 模块顶层 nineslice helper | 21-61 `CreateInsetBackdrop` | 搜索框/MOTD 黑底+细边框（复制自 tradeskill 保单文件零依赖） |
| UnitPopup nil unit 守卫 | 68-83 | 包装 `_G.UnitPopup_OnUpdate` |
| 四 inset 创建 | friends 128 / who 134 / guild 237 / raid 257 | 均 `DFUI.CreateRetailInset` |
| who 防抖 | `dfuiTryWho` 156-164、`DFUI_WHO_CD` 154 | 服务器节流防连点 |
| who 搜索框 | 177-217 `DFUI_WhoSearchBox` | 替代 vanilla `WhoFrameEditBox` |
| 子 Tab skin | `skinSubTab` 269-367 + 锚定 370-396 | 好友/屏蔽 ToggleTab |
| ScrollFrame 重锚 | `reanchorScrollFrames` 424-456 | 四个 sf 双锚跟随 inset |
| 滚动条金箭头 | `keepGoldArrows` 557-602、`reanchorWhoArrows` 604-616 等 | 留箭头、清轨道/thumb |
| 主 Tab 系统 | `customBg:AddTab` 691/701/710/2042 | 好友/查找/公会/团队 |
| 自建好友 row | do-block 793-1127、`refreshFriendRows` 976 | |
| 自建 who row | do-block 1134-1473、`refreshWhoRows` 1285 | |
| 自建公会 row | do-block 1480-2014、`refreshGuildRows` 1712 | |
| 收尾 | `deferFit` 2021、`OnShow` hook 2033、`ToggleFriendsFrame` 包装 2050 | |

涉及的 `tools.lua` 工厂（均已核实存在）：

- `DFUI.CreateRetailInset(parent, opts)`（tools.lua:459）：opts 支持 `name/anchors/followFrame/followFrames`；
  `followFrames` 多个互斥 frame、`followFrame` 单个（tools.lua:535-536）。
- `DFUI.CreateSocialRow(parent, opts)`（tools.lua:819）：列定义 + hover/选中/左右键/双击/滚轮。
- `DFUI.CreateActionButton(parent, width, text, onClick, height)`（tools.lua:952）：DF 红金属按钮，带 `:SetEnabledDF(bool)`。
- `DFUI.CreatePaperDollFrame(name, parent, w, h, style)`（paperdoll.lua:82）：外框（社交用 style=1）。
- `DFUI.TruncateToWidth(text, maxW)`（tools.lua:1036）/ `DFUI.MeasureWidth(text)`（tools.lua:1072）：像素级截断/测宽。
- `hooksecurefunc(name, func, append)`（tools.lua:108）：第三参 `append` 决定顺序，见下文「坑」。

---

## 三、核心实现

### 3.1 外框与四 inset

- `customBg = DFUI.CreatePaperDollFrame("DFUI_FriendsBg", FriendsFrame, 384, 512, 1)`（social.lua:96），
  锚 FriendsFrame 内缩；标题「社交」+ 右上自制关闭按钮（`DFUI.CreateRedButton` → `HideUIPanel(FriendsFrame)`）。
- vanilla 装饰（`FriendsFrameTopLeft` 等四角、`FriendsFrameTab1..4`、`FriendsFrameCloseButton`）全部 `:Hide()`（85-94）。
- 四个分页各一个 `CreateRetailInset`，靠 `followFrame(s)` 跟随对应 vanilla 子 Frame 的 OnShow/OnHide：
  - friends（128）：`followFrames = {FriendsListFrame, IgnoreListFrame}`（屏蔽模式切到独立 `IgnoreListFrame`，nil 守卫）。
  - who（134）：`followFrame = WhoFrame`，底部留 80px 给搜索框。
  - guild（237）：`followFrame = GuildFrame`，底部留 98px（比好友多 18，留按钮/状态行）。
  - raid（257）：`followFrame = RaidFrame`（团队页仅建 inset，未做自建列表）。

### 3.2 主 Tab 系统

`customBg:AddTab(label, onClick, width)` 建四个主分页（好友/查找/公会/团队）。每个 onClick 统一：
`hideDropDown()` → 设 `FriendsFrame.selectedTab` → `FriendsFrame_ShowSubFrame(...)` → `PanelTemplates_SetTab` → `FriendsFrame_Update()` → `deferFit()`（social.lua:691-717、2042）。

- **公会 Tab 门控**：`UpdateGuildTab`（719）依 `IsInGuild()` Enable/Disable，并由 `GUILD_ROSTER_UPDATE` 事件实时同步（737）。
- **降级保护**：`safeTabClick(tabIndex)`（729）在未入会却点公会页（脚本绕过 EnableMouse）时退到好友页。
- **入口收口**：包装 `_G.ToggleFriendsFrame`（2050），仅当「已可见再切 Tab」时手动 `safeTabClick`，避免与 OnShow 路径双触发。

### 3.3 子 Tab（好友 / 屏蔽）

vanilla 1.12 在好友/屏蔽两个 ScrollFrame 上方各有一组 ToggleTab，共 4 个：
`FriendsFrameToggleTab1/2`（好友模式）、`IgnoreFrameToggleTab1/2`（屏蔽模式），两组互斥显隐由 vanilla 自管。
DFUI 只做视觉 skin（`skinSubTab` 269-367）+ 重锚到对应 inset 顶（376-389），**不接管切换逻辑**，每组选中态用 `tab.dfSetSelected(defaultSelected)` 一次定死（370-373）。
切子 Tab 时 hook OnClick 隐藏 dropdown（393-396）并 `refreshFriendRows()`（1068-1069）。

### 3.4 全自制列表（脱钩 vanilla FauxScrollFrame）

三页列表（好友/查找/公会）同构，核心铁律：**行 parent 挂自有 inset/host，绝不挂 vanilla ScrollFrame**。
原因：vanilla `FauxScrollFrame_Update` 在「结果数 ≤ 可显示数」时 `frame:Hide()` 整个滚动框，
寄生其上的自制行会被连带隐藏（who「按名搜结果少→列表消失」根因，见第四节）。

每页结构一致：

1. **隐藏 vanilla 列表 button**：`hideVanillaButton/hideVanillaWhoBtn/hideVanillaGuildBtn` 用 `SetAlpha(0)+EnableMouse(false)`（部分加 `Hide()`），并清空子 FontString 文本——vanilla `*List_Update` 会循环 `Show()`，alpha0 让其怎么 Show 都视觉透明。
2. **建足量行 frame**：`FRIEND_ROWS/WHO_ROWS/GUILD_ROWS = 24`，实际显示行数由 inset 真高 floor 出来（解耦 vanilla `FRIENDS_TO_DISPLAY`/`WHOS_TO_DISPLAY`/`GUILDMEMBERS_TO_DISPLAY`）。
   - 好友行挂中间容器 `friendRowHost`（905，切 tab 时整体一次 Hide/Show 消批量 reflow）；who/guild 行直接挂 `whoInset`/`guildInset`。
3. **几何自管**：`layoutRows/layoutWhoRows/layoutGuildRows` 用 `GetTop-GetBottom` 取真高（1.12 双锚无 SetHeight 时 `GetHeight` 返回脏值，见 `reference-wow112-frame-size-pitfalls`），固定行高 18px（`FIXED_ROW_H*`），逐行绝对锚避开 vanilla 链锚累计漂移。
4. **offset 自管**：upvalue `friendOffset/whoOffset/guildOffset`（提到行创建前声明供 `onWheel` 闭包捕获），滚轮翻页 `onWheel` 自调 offset±arg1 + `refresh*Rows()`，删去 `FauxScrollFrame_GetOffset/SetOffset`。
   - **offset 钳位**：每次 refresh 取 `maxOff = max(0, numTotal - visibleRows)`，`off > maxOff` 时回钳（防新查询结果骤减时旧偏移越界）。
5. **渲染**：`refresh*Rows` 循环 `idx = off + i` 读引擎 API 填行；
   职业色经本地 `*CLASS_TOKEN` 反查表（localized class → token → `RAID_CLASS_COLORS`，含 zhCN/enUS 硬编码兜底，`LOCALIZED_CLASS_NAMES_MALE/FEMALE` 存在时合并）；
   等级色用 `GetDifficultyColor`；离线行职业色 + alpha 0.5。
6. **vanilla scrollbar 协同**：留金箭头（`keepGoldArrows`/`reanchor*Arrows`，纹理 `Interface\ChatFrame\UI-ChatIcon-ScrollDown-*`），清轨道/thumb；好友页额外覆盖 vanilla scrollbar `maxV`（1051-1057，因 vanilla 用 `FRIENDS_TO_DISPLAY×16` 算，与实际行高不符）。

### 3.5 查找（Who）专项

**结果路由**：DFUI 全程经 `hooksecurefunc("SendWho", ...)`（144-149）在 SendWho 前置 `SetWhoToUI(1)`，让结果进 UI 数据源而非聊天框。

**防抖 `dfuiTryWho`（156-164）+ `DFUI_WHO_CD`（154）**：
Turtle 服务器对连续 who 查询有冷却，**连点 SendWho 会反复重置服务器冷却 → "等多久都查不到"**。
客户端用 upvalue `dfuiLastWho` 记上次时间戳，`GetTime()-dfuiLastWho < DFUI_WHO_CD` 时**静默拦下不发**（不重置冷却），过窗口才 `SetWhoToUI(1)+SendWho(text)`。
`DFUI_WHO_CD` 是全局变量、默认 5、可 `/script DFUI_WHO_CD=8` 调整以匹配服务器实际冷却。
搜索框 OnEnterPressed（211）与「刷新」按钮（1446）都走 `dfuiTryWho`。

**自建搜索框 `DFUI_WhoSearchBox`（177）**：挂 whoInset 下方预留区，黑底（`CreateInsetBackdrop`）+ 搜索图标 + placeholder「查找」，隐藏 vanilla `WhoFrameEditBox`（217）。1.12 `SendWho` 原生支持 `n-名字 / z-区域 / c-职业 / g-公会 / 数字=等级` 筛选语法，单框透传覆盖。

**第4列分类下拉（地区/公会/种族）**：用 `WhoFrameColumnHeader2` 当触发器（1414），点击弹 `FriendsDropDown`（`displayMode="MENU"` + `initialize` + `UIDropDownMenu_AddButton` + `ToggleDropDownMenu`），选项设 `whoSortType` + `SortWho(v)` 服务器重排 + `refreshWhoRows`。第4列内容纯客户端读 `GetWhoInfo` 不同字段（guild/race/zone，1312）。

**底部三按钮**：刷新 / 添加好友 / 组队邀请（1446-1463），加好友/组队作用于选中行 `mySelectedWhoName`，未选中禁用（`updateWhoButtons` 1466）；`WHO_LIST_UPDATE` 事件清旧选中（1338-1343）。

**vanilla 清场**：遍历 `WhoFrame` 直接子 Button（排除 ColumnHeader）alpha0+EnableMouse(false)（223-235，不硬编码按钮名）；`WhoFrameTotals` 重锚到 whoInset 底外做统计行（171-175，文字由 vanilla `WhoList_Update` 自动 SetText）。

### 3.6 公会（Guild）专项

- **roster 含离线**：`SetGuildRosterShowOffline(1)`（1499）+ OnShow 调 `GuildRoster()`（1831），否则 `GetNumGuildMembers()` 只含在线。客户端再用 `guildShowOffline` 开关过滤显示，复用 vanilla `GuildFrameLFGButton`（Turtle 的「显示离线成员」复选框，hook 其 OnClick 读勾选态，1924-1974）。
- **两 mode**：玩家状态（职业/区域）↔ 公会状态（注释/最后上线）。vanilla 用两个互斥子 Frame `GuildPlayerStatusFrame`/`GuildStatusFrame`，`isGuildStatusMode()`（1648）以 `GuildStatusFrame:IsShown()` 作信号（**`GetChecked` 不可用**，见 memory `project-guild-two-mode-align`）。整套 vanilla 公会状态视图 `GuildStatusFrame` 用 `suppressGuildStatusFrame()`（1665）SetAlpha(0)+EnableMouse(false)（含子）压制、保留 IsShown 作信号。
- **切 mode 刷新延迟一帧**：`deferGuildRefresh`（1816）`deferOneFrame(refreshGuildRows)`，等两 Frame 切换完成、IsShown 稳定再读 mode（否则切回时 PSF:Show 早于 GSF:Hide，gMode 误读 → 卡在公会状态）。
- **搜索框 `DFUI_GuildSearchBox`（1877）**：纯客户端按名字即时过滤（`guildSearchText`，OnTextChanged 直接 refresh，**无防抖**——本地 roster 不涉网络）；锚到 vanilla `GuildFrameSearchBox` 原位并隐藏之。
- **「最后上线」**：retail `RecentTimeDate` 在 1.12 不存在，自写 `guildLastOnlineText`（1652）格式化 `GetGuildRosterLastOnline` 四返回值。
- **底部三按钮**（公会信息/添加成员/公会控制）：vanilla 三按钮（`GuildFrameGuildInformationButton`/`GuildFrameAddMemberButton`/`GuildFrameControlButton`）保留功能（alpha0+禁鼠标，不 Hide），自制按钮 `SetAllPoints` 跟随原位、`onClick` 转发 vanilla `:Click()`、`SetEnabledDF` 镜像 vanilla `IsEnabled()` 权限态（1979-2012）。
- **区域列头 H2 宽度兜底**：vanilla 多入口（点成员开 `GuildMemberDetailFrame`/滚动/拖条）会反复把 `GuildFrameColumnHeader2` 改回 vanilla 宽（~105），`guildInset:SetScript("OnUpdate")`（649）每帧检测 >98 就把宽/位/对齐设回 92（见 memory `project-guild-h2-resize`）。

### 3.7 UIDropDownMenu / UnitPopup 修复

1. **UnitPopup nil unit 守卫**（68-83）：vanilla `UnitPopup_OnUpdate` 内部 `CheckInteractDistance(unit,...)`，
   `unit=nil` 时报 Usage 错。包装 `_G.UnitPopup_OnUpdate`：取 `UIDROPDOWNMENU_OPEN_MENU` 对应 menu，
   `menu.unit` 不存在则直接 return。
   - **注意 setfenv 坑**：`setfenv(1, DFUI:GetEnv())` 后写 `UnitPopup_OnUpdate = X` 只写进 DFUI.env 不写 `_G`，
     必须显式 `_G.UnitPopup_OnUpdate = X`；且要把 `DropDownList1/2` 已注册的旧 handler 替换为新版（77-82）。
2. **右键菜单自制**：三页 `onRightClick` 均不调 vanilla `UnitPopup_ShowMenu`（避免上述 nil unit 报错），
   改自填 `FriendsDropDown.initialize`（悄悄话/邀请/屏蔽 等）+ `ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")`。
3. **隐藏拦截源**：vanilla `WhoFrameDropDown`（ColumnHeader2 的子 Frame，UIDropDownMenu 类）盖在列头上拦鼠标，
   导致自制 OnClick 收不到点击 + 露出 vanilla 灰下拉 → `Hide()+SetAlpha(0)+EnableMouse(false)`，
   连其内部 `WhoFrameDropDownButton` 一并处理（1436-1441）。
4. **菜单残留**：切主 Tab / 子 Tab 前都 `HideDropDownMenu(1)`（`hideDropDown`/`_subTabHideDD`）。

---

## 四、已知坑 / 限制

1. **FauxScrollFrame Hide 寄生（已根治）**：早期自制行 parent 挂 vanilla `WhoListScrollFrame`，
   `FauxScrollFrame_Update` 在结果 ≤17 时 `frame:Hide()` 连带隐藏行 → 按名搜结果少时列表整片消失。
   根治 = 行改挂 `whoInset`/`guildInset`/`friendRowHost`，offset 自管。好友/公会同源隐患已一并改为自制。
2. **who 服务器节流（已根治）**：连点 SendWho 反复重置服务器冷却 → 等多久都查不到。
   根治 = `dfuiTryWho` 客户端防抖（`DFUI_WHO_CD`）。vanilla 同受服务器节流，只是原版没人连搜。
3. **hooksecurefunc 顺序**：默认 new-before-old（先自制后 vanilla，tools.lua:121-124），
   `append=true` 为 old-before-new。`WhoList_Update` 用 `append=true`（1334），
   让 `hideVanillaWhoBtn`（在 `refreshWhoRows` 内）永远在 vanilla 显示**之后**收尾，否则有查询时 vanilla 残留文字盖住自制列表。
   `FriendsList_Update`（1062）/`GuildStatus_Update`（1811）用默认顺序。
4. **1.12 / Lua 5.0**：全文取长度用 `table.getn`（无 `#`）；
   `onWheel`/`OnUpdate` handler 第一参是 `elapsed` 非 `self`，滚轮量用全局 `arg1`，frame 引用用闭包 upvalue。
5. **GetHeight 脏值**：inset 双锚无 SetHeight 时 `GetHeight` 返回错值，所有 layout 改用 `GetTop-GetBottom`（fallback GetHeight）。
6. **vanilla Button SetWidth 不缩内嵌纹理**：列表 button / 列头 fit 高度时只 `SetHeight` 不 `SetWidth`，
   `fitButtons`（743）显式注释了此坑（见 `reference-vanilla-button-setwidth-pitfall`）。
7. **新增贴图需重启**：子 Tab 纹理 `media\tex\interface\uiframetabs.blp` 等若新增需重启 WoW.exe，`/reload` 不识别（`feedback-addon-new-files-restart`）。
8. **共存**：与 ShaguTweaks 共存——它 hook 同样的 `FriendsList_Update` 改 vanilla button 文字，但 button 已 alpha0 故无视觉影响。
9. **团队页**：仅建 `raidInset`（257）跟随 `RaidFrame`，未做自建列表，沿用 vanilla 团队 UI。

---

## 五、待游戏内实证

- `DFUI_WHO_CD` 默认 5 秒是否匹配 Turtle 实际服务器冷却（可能需玩家按服调大）。
- 公会区域列头 H2 的 `OnUpdate` 每帧兜底是否会与其他公会插件（修改同列头宽度者）来回拉扯。
- 子 Tab 在「好友/屏蔽」频繁切换下的选中态视觉与 vanilla 互斥显隐是否始终一致（代码注释明示「如有切换显示问题待 dump 后定向修复」，677-679）。
- 团队页（RaidFrame）当前未自制，与四 inset 底对齐的视觉一致性。
