# 公会面板设计

> 优先级：**P0**
> 状态：**已实现**（用户认可）
> 事实源：`modules/panels/social.lua`（社交面板三 tab 同一文件，公会逻辑集中在 `local refreshGuildRows` 的 `do` 块，约 1479–2014 行）

---

## 一、概览

社交面板「公会」tab 与好友 / 查找一致，采用 **全自制 row 脱钩 vanilla** 范式：

- 可见 UI 是 DFUI 自建的 `guildInset`（`DFUI.CreateRetailInset`，social.lua:237）+ 24 个自建 row（`DFUI_GuildRow1..24`，`DFUI.CreateSocialRow`），完全独立于 vanilla 的两套公会视图。
- vanilla 的 `GuildFrameButton1..N`、`GuildStatusFrame` 全部 `SetAlpha(0)` + `EnableMouse(false)` 透明保活（不 `Hide`），保留它们当数据载体 / `:Click()` 程序触发 / mode 信号。
- 列头 `GuildFrameColumnHeader1..4` 被 `SetParent(guildInset)` 重锚到自建容器（vanilla 列头 parent 是 `GuildPlayerStatusFrame`，公会状态 mode 会随之隐藏，必须 reparent 才两 mode 都显示）。

四个核心子问题：玩家/公会两 mode 对齐、H2 列头宽度兜底、底部三按钮复刻、1.12 roster API 坑。

---

## 二、关键文件

| 文件 | 用途 |
|------|------|
| `modules/panels/social.lua` | 公会 tab 全部逻辑（本文档唯一事实源） |
| `core/tools.lua` | `HookScript`、`DFUI.CreateRetailInset`、`DFUI.CreateSocialRow`、`DFUI.CreateActionButton`、`DFUI.TruncateToWidth`、`hooksecurefunc`（new-before-old 顺序） |
| `modules/panels/paperdoll.lua` | `DFUI.CreatePaperDollFrame`（社交外框 `customBg`，parent=FriendsFrame，social.lua:96） |

---

## 三、核心实现

### 3.1 玩家/公会两 mode 对齐

**架构真相**：vanilla 的「玩家状态 / 公会状态」不是同一套 button 切列，而是**两个独立互斥的子 Frame**——`GuildPlayerStatusFrame`（玩家视图）与 `GuildStatusFrame`（公会视图），由 `GuildFrameGuildListToggleButton` 切换显隐。DFUI 自建 row 独立于二者一直显示，需自己判 mode 并切数据列。

- **mode 信号**：`isGuildStatusMode()`（social.lua:1648–1650）= `GuildStatusFrame and GuildStatusFrame:IsShown()`。公会状态 = true / 玩家状态 = false。
  > 记忆教训：`GuildFrameGuildListToggleButton:GetChecked()` 它不是标准 CheckButton，不能用来判 mode（待游戏内实证当前 Turtle 客户端表现）。当前代码只用 `IsShown()` 判 mode。
- **压制 vanilla 公会视图**：`suppressGuildStatusFrame()`（social.lua:1665–1673）对 `GuildStatusFrame` 及其子 `SetAlpha(0)` + `EnableMouse(false)`，保留 `IsShown` 作信号；`refreshGuildRows` 每次先调它。
- **列对照**（`refreshGuildRows` 内 `gMode` 分支，social.lua:1751–1782）：

  | 列 | 玩家状态 | 公会状态 |
  |----|----------|----------|
  | title | 名字 | 名字 |
  | lvl | 等级 level（难度色） | 官阶 rank（灰白，TruncateToWidth 62） |
  | class | 职业 class（职业色） | 注释 note（灰白，TruncateToWidth 48） |
  | zoneText | 区域 zone | 在线="在线"绿 / 离线=`guildLastOnlineText(idx)` |

- **「最后上线」格式化**：`guildLastOnlineText(idx)`（social.lua:1652–1661），底层 `GetGuildRosterLastOnline(idx)` 返回 `year, month, day, hour`，自写中文「X 年/个月/天/小时前 / 刚刚」。retail 的 `RecentTimeDate` 在 1.12 不存在。
- **列头随 mode SetText**：`refreshGuildRows` 末尾 `relayoutHdr`（social.lua:1797–1806）：Header4 = col3「职业↔注释」、Header2 = col4「区域↔最后上线」、Header3 = col2「等级↔官阶」、Header1 = 名字（不变）。每次刷新强制 fontstring `SetPoint("LEFT", h, "LEFT", 0,0)` + `SetJustifyH("LEFT")`，否则 vanilla `GuildStatus_Update` 会把列头改回 CENTER 对齐。
- **触发刷新（事件层 + 兜底层）**：
  - `HookScript(GuildStatusFrame / GuildPlayerStatusFrame, "OnShow", deferGuildRefresh)`（social.lua:1817–1818）——切 mode 即两 Frame 切显隐，OnShow 触发。
  - `HookScript(GuildFrameGuildListToggleButton, "OnClick", deferGuildRefresh)`（social.lua:1820–1822）——OnShow 时机不可靠时的兜底。
  - `hooksecurefunc("GuildStatus_Update", refreshGuildRows)`（social.lua:1811）。
  - `deferGuildRefresh`（social.lua:1816）走 `deferOneFrame`：延迟一帧等 vanilla 切换完成、`IsShown` 稳定后再读 mode。否则切回时 `PSF:Show` 可能早于 `GSF:Hide`，`gMode` 读到旧值卡在公会状态。

### 3.2 H2 列头宽度 OnUpdate 每帧兜底与列宽天花板

**问题**：点公会成员 / 点滚动箭头 / 拖滚动条后，区域列头 `GuildFrameColumnHeader2` 宽度被 vanilla 多入口反复改回 ~105，导致右锚下文字左缘左移。数据行不跳（自建 row 独立），只列头跳。根因之一：`onGuildLeftClick` 里 `GuildMemberDetailFrame:Show()`（social.lua:1512）在 `refreshGuildRows`（已设回 H2）之后才跑，把 H2 覆盖回 vanilla 值。

**根治（通用兜底）**：`guildInset:SetScript("OnUpdate", ...)`（social.lua:649–658）每帧轻检测——

```lua
local h2 = GuildFrameColumnHeader2
if h2 and (h2:GetWidth() or 0) > 98 then        -- 阈值 98
    h2:ClearAllPoints()
    h2:SetPoint("BOTTOMRIGHT", guildInset, "TOPRIGHT", -13, -24)
    h2:SetWidth(92)                              -- 目标宽 92
    local fs = h2.GetFontString and h2:GetFontString()
    if fs then fs:ClearAllPoints(); fs:SetPoint("LEFT", h2, "LEFT", 0, 0); fs:SetJustifyH("LEFT") end
end
```

逐个 hook 堵不完（尤其 `GuildMemberDetailFrame:Show` 在我们的 hook 之后才跑），改用每帧兜底覆盖所有入口；偏移最多 1 帧、肉眼无感。同一套「设回三件套」（ClearAllPoints + SetPoint BOTTOMRIGHT + SetWidth + fontstring LEFT 对齐）在 `applyGuildColWidths`（social.lua:1705–1709）和 `onGuildLeftClick`（social.lua:1515–1519）也重复写一遍。

**列宽天花板约束**：OnUpdate 判别靠「width > 98」，阈值必须卡在 (正常 H2 宽, vanilla ~105) 之间——

- 正常 H2 = 92，不能接近 ~100，否则与 vanilla 105 撞，无法区分「我设的」和「被改坏的」→ **区域列宽有硬上限**。
- 加宽区域列时三处联动：①数据宽（`zoneText` width，applyGuildColWidths:1685=68）②H2 width（applyGuildColWidths:1708=92）③OnUpdate 阈值（social.lua:651=98）。漏改阈值则正常 H2 一超旧阈值就被每帧误设回。
- 突破上限的唯一办法：把判别从阈值改成精确目标比对（`if abs(w-目标)>1`），当前未做。

> 注：social.lua:1863–1872 首次重锚把 Header1 宽设为 `90+5`、Header3 `24+4`、Header4 `78+4`，而 `applyGuildColWidths`（每次刷新）设 Header1=95 / Header3=68 / Header4=50 / H2=92。两处数值不完全一致（首次 vs 刷新后），刷新后的 `applyGuildColWidths` 为最终生效值。

### 3.3 底部三按钮复刻范式

vanilla 1.12 GuildFrame 底部三按钮全局名（social.lua:1979–1980）：

- `GuildFrameGuildInformationButton`（公会信息）
- `GuildFrameAddMemberButton`（添加成员，按邀请权限 enable）
- `GuildFrameControlButton`（公会控制，仅 GM enable）

**复刻替换范式**（social.lua:1979–2012）：

1. vanilla 三按钮 `SetAlpha(0)` + `EnableMouse(false)`，**不 Hide**——保留供 `:Click()` 程序触发与 `IsEnabled()` 读权限态。
2. 自制 `DFUI.CreateActionButton`（DF 红金属风）onClick 转发 `clickVanilla(b)` = `b:Click()`，复用 vanilla 原逻辑（弹窗/popup），不重写。
3. 精确贴 vanilla 原位+原尺寸：`gBtnInfo:SetAllPoints(GuildFrameGuildInformationButton)`（活锚，vanilla 后续重定位也同步；创建时给的宽度 100 被 SetAllPoints 覆盖）。按钮文字取 `vanilla:GetText()`，nil 兜底中文。
4. enable 镜像：`updateGuildButtons()`（social.lua:2006–2010）`gBtn:SetEnabledDF(vEnabled(vanillaBtn))`，`vEnabled` 判 `IsEnabled()==1 或 true`；挂在 `refreshGuildRows` 末尾（social.lua:1808）随刷新更新。

> `Button:Click()` 在 1.12 可用（程序触发，不需 EnableMouse；被禁用按钮不触发——与权限态一致）。

### 3.4 1.12 roster API 坑

- **`GetNumGuildMembers()` 受 `SetGuildRosterShowOffline` 影响**：返回当前 roster 缓存里的成员数，若设为不含离线 → 只返回在线数，当「总人数」用会错（总数=在线数雷同）。
  - 解法：`SetGuildRosterShowOffline(1)` 设标志（持久），分别在 row do 块初始化（social.lua:1499）和 `guildInset` OnShow（social.lua:1830，防 vanilla dropdown 改回）调用。
  - `GuildRoster()` 拉取含离线的最新 roster（异步，经 `GUILD_ROSTER_UPDATE` 回调），在 OnShow 调用（social.lua:1831）。事件由 `refreshFrameGuild`（social.lua:1824–1826）监听 `GUILD_ROSTER_UPDATE` → `refreshGuildRows`。
- **`GetGuildRosterInfo(i)` 返回序**（social.lua:1743）：`name, rank, rankIndex, level, class, zone, note, officernote, online, status`。online 是第 9 个返回值。
- **在线数自己累加**（`refreshGuildRows`，social.lua:1722–1724）：遍历 `GetGuildRosterInfo(gi)` 取第 9 个 online，`if onl then numOnline = numOnline + 1`，不受搜索 / 显示离线过滤影响。底部统计 `guildTotalsText`「成员 N 在线 M」（social.lua:1730–1733）。
- **客户端二次过滤**：`guildShowOffline`（social.lua:1552，默认 true）控制是否在列表显示离线成员，接管 vanilla `GuildFrameLFGButton`（Turtle 的「显示离线」勾选框，复用不自制，social.lua:1924–1974），hook 其 OnClick 读 `GetChecked()` 更新 `guildShowOffline` 并刷新。

---

## 四、面板互斥与生命周期

公会 tab 不单独管理互斥；整个社交面板沿用 UIPanel 互斥模式：vanilla `FriendsFrame` 保活当载体，可见 `customBg` 经 `HookScript(FriendsFrame, "OnShow", ...)`（social.lua:2033 起）跟随。`safeTabClick` 在公会 Tab 未入会（`IsInGuild()` 为假）时降级到好友 Tab（social.lua:729–733）；`UpdateGuildTab`（social.lua:719–726）按 `IsInGuild()` enable/disable 公会 Tab，并监听 `GUILD_ROSTER_UPDATE`（social.lua:736–738）实时同步。

---

## 五、已知坑与限制

1. **列宽硬上限**：3.2 所述，OnUpdate 阈值判别法使区域列宽无法接近 ~100，加宽需三处联动（数据宽 / H2 宽 / 阈值）。
2. **首次重锚与刷新后列宽数值不一致**：social.lua:1863–1872（首次）vs :1690–1708（applyGuildColWidths 刷新后）。以刷新后为准；首次值仅影响面板首开到第一次刷新之间的瞬态。
3. **跨客户端事件依赖弱点**（记忆条目记录，未实证）：mode 切换重渲染挂在 vanilla `GuildPlayerStatusFrame/GuildStatusFrame` 的 OnShow 与 `GuildFrameGuildListToggleButton` OnClick 上。这些事件的存在与触发依赖具体客户端版本，曾有「朋友 git 下载切回玩家状态卡死、本机不复现」报告。当前代码用「OnShow + ToggleButton OnClick + GuildStatus_Update + GUILD_ROSTER_UPDATE 事件」多路触发，**未**加状态轮询看门狗（曾试加后应用户要求回退）。是否需要状态轮询防御**待游戏内实证**。
4. **`GuildFrameGuildListToggleButton:GetChecked()` 不可靠**：记忆记录它非标准 CheckButton、`GetChecked()` 恒 nil，故 mode 判定一律用 `GuildStatusFrame:IsShown()`。当前 Turtle 客户端实际表现**待游戏内实证**。
5. **`onWheel` 翻页用全局 `arg1`**：1.12 OnMouseWheel 第一参经 `arg1` 传递（social.lua:1586–1592）；`maxOff` 算法依赖 `guildNumShown` / `visibleRowsGuild` 由 `refreshGuildRows` / `layoutGuildRows` 维护。
6. **依赖 vanilla 全局 frame 存在性**：底部三按钮、列头、`GuildFrameLFGButton`、`GuildFrameSearchBox` 等代码均有 `if frame then` 守卫；若某 Turtle 客户端缺失对应全局，相关功能静默降级，**待游戏内实证**各全局在当前客户端是否齐备（记忆曾记 `GuildFramePlayerStatusDropDown` 在 Turtle 不存在，当前代码未引用该名）。
