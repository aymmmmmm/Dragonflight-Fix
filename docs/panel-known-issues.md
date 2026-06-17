# 面板已知问题

> 最后更新：2026-06-01

> ⚠️ **架构说明（2026-06）**：本文档第一～四节记录的是**早期"换皮 vanilla CraftFrame/TradeSkillFrame"方案**下的问题。该方案已被**全自制专业面板**取代——当前 `modules/panels/tradeskill.lua` 不再 reskin 暴雪原生框体，而是自建配方列表/详情/材料格/按钮（`currentMode`/`recipeButtons`/`UpdateRecipeList` 等），全代码无 `SkinProfessionFrame`、`listBorder`、`TradeSkillSearchBox`/`CraftFrameSearchBox` 重锚、`CraftFrame_Update`/`TradeSkillFrame_Update` hook 等旧符号。故第一～四节的根因/待办**多数已随旧架构作废**，逐节状态见下。自制专业面板的设计见 `profession-panel-design.md` / `profession-panel-debug.md`。

## 一、CraftFrame（宠物训练 Beast Training）— 训练点数不显示 ✅ 已解决（全自制面板）

### 解决方式（当前实现）

全自制面板不再依赖 Blizzard `CraftFramePointsText`，改为自建 FontString `trainingPointsText`（`tradeskill.lua:962-966`），锚在制作/学习按钮区（`SetPoint("RIGHT", cancelBtn, "LEFT", -12, 0)`），金色字。仅宠物训练模式且 `GetPetTrainingPoints()` 返回 `total>0` 时显示，文本 `"训练点: "..(total-spent)`（`tradeskill.lua:1595-1605`）。面板 `RegisterEvent("UNIT_PET_TRAINING_POINTS")`（`tradeskill.lua:2016`），事件回调刷新（`tradeskill.lua:2047`）。下方早期诊断记录仅作历史留存。

---

<details>
<summary>历史诊断记录（旧"换皮 CraftFrame"方案，已作废）</summary>

### 问题描述

打开宠物训练面板（猎人 Beast Training），训练点数（Training Points）不显示。原本应在面板底部显示剩余可用训练点数。

### 诊断结果

通过 `GetRegions()` 扫描 CraftFrame 上的所有元素：

```
1. Texture  CraftFramePortrait       hidden  ← 被我们隐藏（正常）
2. Texture  nil                      hidden  ← 被我们隐藏（正常）
3. Texture  nil                      hidden  ← 被我们隐藏（正常）
4. Texture  nil                      hidden  ← 被我们隐藏（正常）
5. FontString CraftFrameTitleText    shown   ← 标题可见（正常）
6. FontString CraftFramePointsText   hidden  ← 训练点数 ❌
7. FontString CraftFramePointsLabel  hidden  ← 训练点数标签 ❌
8. FontString CraftFrameNoResultsText hidden ← 无结果提示
```

### API 确认

```
/script GetPetTrainingPoints() → totalPoints=0, spent=0
```

API 正常返回，元素也存在（`getglobal("CraftFramePointsText")` 不为 nil）。

### 已排除的原因

| 尝试方案 | 结果 |
|---------|------|
| 在 OnShow 中调用 `pointsText:Show()` | ❌ 无效 |
| 手动 `/script CraftFramePointsText:Show()` | ❌ 无效 |
| 修改 customBg FrameLevel 为 -1（低于 CraftFrame 子元素） | ❌ 无效 |
| 手动 `ClearAllPoints` + `SetPoint` 设锚点 + `Show()` | ❌ 无效 |
| 在 customBg 上自建 FontString | 未测试（已回退） |

### 根因分析

`CraftFramePointsText` 和 `CraftFramePointsLabel` 是 Blizzard XML 定义的 FontString：
- **无默认锚点** — Blizzard 在 `CraftFrame_Update()` 中动态设置锚点
- 我们的换皮代码可能干扰了 `CraftFrame_Update()` 的执行，导致锚点从未被设置
- 手动设锚点 + Show() 也不生效，原因未明（可能有更深层的隐藏机制）

### 参考实现

**pfUI** (`_dev/pfUI-master/skins/blizzard/professions.lua`):
```lua
local points = _G[frame.."PointsText"]
if points then
    points:ClearAllPoints()
    points:SetPoint("RIGHT", create, "LEFT", -20, 0)
end
```
pfUI 将 PointsText 锚定到 CreateButton 左侧。

**DragonflightUI** (`_dev/DragonflightUI/Mixin/ProfessionFrame.mixin.lua`):
- 不使用 Blizzard 原生元素
- 自建 `DragonflightUIProfessionTrainingPointFrame`（120x18）
- 监听 `UNIT_PET_TRAINING_POINTS` 事件更新
- 仅在 `SelectedProfession == 'beast'` 时显示

### 待尝试方案

1. **在 customBg 上自建 FontString** — 完全不依赖 Blizzard 元素，自行创建文字显示训练点数，监听 `UNIT_PET_TRAINING_POINTS` 事件实时更新（← **此方案已采纳并落地**，见上方"解决方式"）
2. **排查 Blizzard 元素不可见的深层原因** — 检查 FontString 的 font、alpha、width/height、parent visibility 等属性，确认是否有其他隐藏机制
3. **Hook CraftFrame_Update** — 在 Blizzard 的更新函数执行后，强制设置锚点和显示

</details>

---

## 二、TradeSkill / CraftFrame — 滚动条下箭头超出内边框 ⚠️ 已随旧换皮架构作废

> 当前自制专业面板自建滚动列表（`recipeButtons` + 自管 `scrollOffset`），无 `listBorder`/`cfg.listBottomY`/`TradeSkillSearchBox` 重锚等旧符号，本节描述的内边框/箭头/搜索框取舍**不再适用**，保留作历史。

### 改动历程

1. 原始值 `+7`：箭头略微超出 listBorder
2. 首次修复改为 `-10`：边框下扩 17px，完整包住 24x24 箭头
3. 用户反馈边框过长导致搜索框溢出，回调至 `+10`

### 当前状态

`listBorder` 底部偏移为 `+10`（cfg.listBottomY 默认值 10），边框底边在 listScroll 底部上方 10px。下箭头仍会超出边框，但这是为搜索框位置让步的**有意取舍**。

已删除与 scrollbar.lua 冲突的 scrollBar 高度 hack 和 downBtn 缩小 hack。

### 同时完成: Turtle WoW 控件布局

- `TradeSkillSearchBox`：锚定到 `DFUI_TradeSkillBg BOTTOMLEFT (+15, +8)`，DF 暗色风格换皮
- `TradeSkillMatsCheckButton`：锚定到 `detailScroll TOPLEFT (+0, +14)`
- `TradeSkillSkillCheckButton`：锚定到 matsCheck 右侧 (+80, 0)

---

## 三、CraftFrame（附魔/宠物训练）— 搜索栏位置 ✅ 已修复（注：旧换皮方案，今已被全自制面板取代）

> 此节记录的是旧"换皮 CraftFrame"方案下对 vanilla `CraftFrameSearchBox`/`TradeSkillSearchBox` 的重锚结论。当前自制专业面板**不再使用** vanilla 搜索框，自建搜索逻辑。下文的元素名排查经验对"识别 Turtle 服务端注入元素"仍有参考价值，故保留。

### 根因

CraftFrame 搜索框的元素名是 `CraftFrameSearchBox`（服务端注入），之前代码误用 `CraftFrameEditBox` 导致所有换皮和定位代码静默跳过（元素为 nil）。

### 排查经验

| 元素名 | 来源 | 存在？ |
|--------|------|--------|
| `TradeSkillSearchBox` | Turtle WoW 服务端注入 | ✅ |
| `CraftFrameSearchBox` | Turtle WoW 服务端注入 | ✅ |
| `CraftFrameEditBox` | 无（pfUI 代码中的 TBC 命名猜测） | ❌ nil |

**教训**：Turtle WoW 服务端注入的 UI 元素不在客户端 Lua/XML 中，无法通过搜索代码库找到。命名规律也不统一（TradeSkill 用 `SearchBox` 后缀，但不带 `Frame`；Craft 用 `FrameSearchBox`）。必须在游戏内用 `/script DEFAULT_CHAT_FRAME:AddMessage(tostring(元素名))` 逐个验证。

### 同时修复：ShaguPlates 冲突

ShaguPlates `turtle-wow.lua` 的 Profession 皮肤会在 ADDON_LOADED 后覆盖 `TradeSkillSearchBox` 的 backdrop 和位置（`CreateBackdrop` + `SetPoint("TOP", Frame, "BOTTOM")`），但不碰 `CraftFrameSearchBox`，导致两个搜索框风格/位置不一致。通过禁用 SP Profession 皮肤解决：
```
/script ShaguPlates_config["disabled"]["skin_Profession"] = "1"
```

### 当前状态

两个面板搜索框统一由 `SkinProfessionFrame` 的 `cfg.searchBox` 参数驱动，锚定到各自 `customBg BOTTOMLEFT (15, 8)`，DF 暗色风格一致。

---

## 四、TradeSkillFrame — 下拉筛选框/折叠按钮/复选框布局未生效 ⚠️ 已随旧换皮架构作废

> 当前自制专业面板自建过滤/折叠/复选交互，不再 reanchor vanilla `TradeSkillSubClassDropDown`/`TradeSkillInvSlotDropDown`/`TradeSkillCollapseAllButton`/`MatsCheckButton`。本节及其全部"待排查方向"针对的是已废弃的旧换皮代码，保留作历史。

### 问题描述

下拉筛选框（SubClassDropDown、InvSlotDropDown）、折叠按钮（CollapseAllButton）、复选框（MatsCheckButton、SkillCheckButton）在暴雪默认位置，与 DF 金属边框布局不协调：
- 下拉框在 listBorder 外面，未与列表对齐
- 折叠按钮 [±] 堆叠在列表第一行内
- 复选框与下拉框不在同一水平线

不影响功能，仅视觉上不协调。

### 已尝试的方案

#### 方案 1：ADDON_LOADED 一次性 SetPoint（❌ 无效）

在 `SkinProfessionFrame` 中添加 ClearAllPoints + SetPoint 重定位代码（参考 pfUI `professions.lua:79-92`）：
- CollapseAllButton → BOTTOMLEFT of listScroll TOPLEFT (-5, 5)
- InvSlotDropDown → BOTTOMRIGHT of listScroll TOPRIGHT (40, 0)
- SubClassDropDown → RIGHT of InvSlotDropDown LEFT (27, 0)
- MatsCheckButton → BOTTOMLEFT of detailScroll TOPLEFT (0, 2)

结果：`/reload` 后位置未变化。

#### 方案 2：Hook TradeSkillFrame_Update + OnShow（❌ 无效）

将定位逻辑提取为 `RepositionControls()` 函数，通过以下方式反复执行：
1. Hook `_G["TradeSkillFrame_Update"]` / `_G["CraftFrame_Update"]`，在 Blizzard 更新后重新定位
2. HookScript OnShow 双保险
3. 首次立即执行一次

结果：`/reload` 后位置仍未变化。

### 已验证的信息

- 元素名正确：面板打开后 `TradeSkillCollapseAllButton`、`TradeSkillSubClassDropDown`、`TradeSkillInvSlotDropDown` 均返回有效 table
- 面板未打开时返回 nil（正常，Blizzard_TradeSkillUI 是按需加载插件）
- `setfenv` 环境下 `_G` 指向 `getfenv(0)`（真全局表），读写全局函数应正常

### 待排查方向

1. **SetPoint 是否实际执行** — 在游戏内用 `/script` 手动对单个元素执行 ClearAllPoints + SetPoint，确认 API 调用是否有效果
2. **父框架约束** — 检查元素的父框架是否通过 SetAllPoints 或双锚点约束了子元素位置
3. **FrameLevel / DrawLayer 遮挡** — 元素可能移动了但被其他层遮挡
4. **pfUI 差异** — pfUI 在重定位前先调用 `StripTextures` + `SkinCollapseButton`，并重设 scrollframe 自身的位置和尺寸（`scrollframe:SetPoint("TOPLEFT", 10, -65)` + `SetWidth(300)` + `SetHeight(365)`），我们没有动 scrollframe 本身
5. **Hook 是否安装成功** — 在游戏内验证 `_G["TradeSkillFrame_Update"]` 在 ADDON_LOADED 时是否已定义

### 当前状态

代码已保留在 `tradeskill.lua` 中（Hook + OnShow + 首次执行三重机制），不影响功能。待后续进一步排查。

---

## 五、已清理的内边框

已从所有面板中移除 `contentBg`（黑色0.3透明）+ `contentBorder`（UI-Tooltip-Border）内边框和 `AddSubBorder` 调用。

**已移除 contentBg + contentBorder 的面板（13个）：**
questlog, social, macro, bank, dressup, gossip, inspect, keybinding, mail, merchant, openmail, questframe, tradeskill

**已移除 AddSubBorder 的面板：**
- character — SkillRankFrame（技能页）
- social — WhoFrameEditBox
- tradeskill — InputBox

> 注：`AddSubBorder` 函数本身仍保留在 `core/tools.lua:86`（其他面板/降级路径仍用），此处仅指上述三处面板**移除了对它的调用**。当前 social.lua 已不调 AddSubBorder（who 改自建 `DFUI_WhoSearchBox`，`WhoFrameEditBox` 直接 `:Hide()`），tradeskill.lua 全自制无 InputBox 描边调用，character.lua SkillRankFrame 走进度条填充方案。

---

## 六、飞行管理员面板（taxi.lua）— 头像始终不对 ❌ 未解决（2026-06-13，盲改 5+ 轮失败，待截图）

### 问题描述

飞行管理员航点地图面板（`taxi.lua`）的头像（左上金属环里那张脸）用户反复反馈"不对"。用户明确要求"完全照搬 gossip 的头像和金属框"。即使代码层面已用 gossip 同一套机制，用户仍说"没改好"。**已解决：地图内容显示、inset 距离**；**未解决：头像**。

### 已尝试的方案（按时间顺序，全部被否）

| # | 做法 | 用户反馈 |
|---|------|---------|
| 1 | 工厂 `portraitUnit` 分支：`customBg.portrait`(工厂 OVERLAY 槽) `SetPortraitTexture("player")` + 60px + `AttachPortrait(-4,8)` | 偏下/没入孔 |
| 2 | 改 54px @ (-4,10)（factory `portraitSize`/`portraitY` 选项） | 尺寸不对/没在框内 |
| 3 | 加层级修复：`portrait:SetDrawLayer("BORDER")` + `edges[1]:SetDrawLayer("OVERLAY",7)`（金属环顶到头像上） | 还是在金属环下面/不对 |
| 4 | 独立 BORDER 纹理 `dfTaxiFace`，尺寸=`GossipFramePortrait:GetWidth()`，(-4,8)，去掉 edges 提层 | 仍不对 |
| 5 | 改 **NPC 脸**（`SetPortraitTexture` 用 `target`/`player` 兜底）+ 用 gossip **同一个 `DFUI.AttachPortrait`** 逐字照搬 | 仍没改好 |

### 当前代码状态（taxi.lua `ApplyTaxiTweaks`）

`bg.dfTaxiPortrait`（在 customBg 上 CreateTexture）→ `SetPortraitTexture(target/player)` → `DFUI.AttachPortrait(bg, bg.dfTaxiPortrait)`（= gossip 工厂里那一行，BORDER + (-4,8)，不 resize），尺寸初始化=`GossipFramePortrait:GetWidth()`。金属环 = `CreatePaperDollFrame` frameStyle=1 的 topLeft 角（与 gossip 同一工厂、同一角）。隐了工厂空槽 `bg.portrait` 与上一版 `bg.dfTaxiFace` 防重影。

### 核心障碍

**全程盲改（看不到游戏画面）**。理论上现在 taxi 头像与 gossip 用的是同一个 `DFUI.AttachPortrait` 函数 + 同尺寸 + NPC 脸 + 同金属环，几何应逐字一致，但用户仍说不对。存在**无法靠推理定位的视觉差异**。

### 待排查方向（下次必须先做，别再盲改）

1. **先要截图**：taxi 面板 + gossip 面板并排对比。盲改已 5+ 轮全废，无截图不要再动代码。
2. **游戏内 dump 真实几何对比**：`bg.dfTaxiPortrait` vs `GossipFramePortrait` 的 `GetWidth/GetHeight/GetPoint/GetDrawLayer`，以及两个 `customBg` 的实际尺寸——验证"代码一致"是否真的"渲染一致"。
3. **确认 NPC 脸取到没**：`UnitExists("target")` 在 `TAXIMAP_OPENED` 时是否=飞行管理员（若飞行管理员直接开地图不弹对话，目标可能不是它）。
4. **怀疑点**：GossipFrame 与 TaxiFrame 尺寸不同 → 两个 customBg 尺寸不同 → 头像在环中的相对位置是否真的一样？（理论上锚点相对 TOPLEFT 固定，但需实测证伪）。
5. **可能根本不是 taxi 代码问题**：用户期望的"对"也许与 gossip 实际渲染不符，需用户明确指认作为样板的面板/截图。

### 不要破坏（已确认 OK，与头像无关）

- 地图内容：靠工厂 `_dfQuestSkinned` **set-once 守护**（绝不每次开飞行重跑换皮，否则地图消失，见本节上方第十节教训 / `panel-skinning-progress.md`）。
- inset 距离：用户认可当前 `IN_R=-16`。
- 架构：守护 + `ApplyTaxiTweaks`（只动自家 frame、不碰 TaxiFrame region/地图）→ 安全 `/reload` 调参。

---

## 十一、训练师面板（ClassTrainerFrame）— 技能列表名字偏右 ✅ 已解决（2026-06-17）

### 解决方式（当前实现）

**真因**：与金属框几何无关。Turtle 把列表每行（header 行如"武器" + 技能行如"冲锋"，共用 `ClassTrainerSkillN` 槽）的**名字 FontString 摆到行最右**，左边大片空；header 的 `+/−` 折叠按钮在行左缘、锚点本就正确。症结 = 名字离 `+/−` 太远，不是框太窄。

**修复**（`trainer.lua` `ShiftRow`）：对每行只重锚名字 FontString → `r:SetPoint("LEFT", btn, "LEFT", NAME_GUTTER_X, 0)`（默认 22，顶部常量，留白给 `+/−`），名字对齐到行左缘。**只动 FontString region，绝不动行 button**（动 button 会把 `+/−` 一起拖跑，它锚点本来是对的）；`+/−` 是行的独立元素，只重锚 FontString 天然不碰它。绝对锚幂等，挂 OnShow + 0.1s OnUpdate 防 Turtle 刷新复位。`/trdump [行号]` 重做为 dump 行结构（regions 类型/文字/左缘/锚点 + 子 frame），用于精修留白。

**教训**：列表"超框"先怀疑**行内文本被服务端摆偏**，而非金属框尺寸；盲改 8+ 轮的根因 = 没要截图，一张 `_dev/ui/debug.png` 即定位。下方为已作废的错误排查记录（"金属框几何"方向，保留作历史）。

**同会话续（宽度 + marble）**：① customBg 右边距 `-8 → -32` 对齐 `SkinQuestStyleFrame`（闲聊/社交等 384 宽面板；底距保留 60 不动按钮）。之前 `-8` 是"金属框几何"错方向遗留的硬贴右缘，已作废。② 列表凹陷改用 `CreateRetailInset` 工厂默认 marble 填充、详情凹陷 `bg:Hide()` 不填充（删了没人用的 `ROCK` 常量）；marble 未染色偏亮，若不搭暗框给 `listInset.bg` 加顶点色压暗即可。③ **职业/专业训练师共用 `ClassTrainerFrame`**（全仓库唯一训练师框，已 grep 核实），三项改动均为框级、`SkinClassTrainerFrame` 一次对两者生效。

<details>
<summary>历史诊断记录（错误方向"金属框几何"，已作废）</summary>

### 问题描述

`modules/panels/trainer.lua` 整体 DF 美化后（金属框 + NPC 头像/名 + 暗岩石双凹陷 + minimal 滑块 + 列表行/详情换皮，功能均正常），**技能列表仍超出训练师金属框边框**。

### 已尝试（均未根治）

1. `customBg` 右边距 `-32 → -12 → -40`（据 `/trdump` 实测收右边贴住内容右缘）
2. 凹陷 `listInset`/`detailInset` 从「锚 customBg 猜测偏移」改为「锚 vanilla `ClassTrainerListScrollFrame`/`ClassTrainerDetailScrollFrame` 本身」（自对齐跟随真实内容）

### `/trdump` 实测坐标（整窗 ClassTrainerFrame 384×512，左上为原点）

```
ClassTrainerFrame   384x512   锚 UIParent TOPLEFT (0,-104)   ← CenterFrame 未居中(独立小问题)
customBg(金属框)              x:[12,344]  (BR offset -40)
ListScrollFrame(vanilla列表) 296x184  锚 ClassTrainerFrame TOPRIGHT(-67,-96) → 实落 [21,317]×[96,280]
Skill1(行)                   293x16   锚 ClassTrainerFrame TOPLEFT(22,-100)  → 实落 [22,315]
DetailScrollFrame            296x119  锚 ListScrollFrame BOTTOMLEFT(0,-8)
```

### 分析与疑点

- **水平方向行 `[22,315]` 在金属框 `[12,344]` 内，不该超出** → 超出大概率来自：
  1. **垂直方向**：列表/详情向下超出金属框底部（customBg 底 ≈452，需核对列表/详情实际底 vs 452）
  2. **金属框边框纹理厚度**：`CreatePaperDollFrame` frameStyle=1 的金属边有占位宽度，行可能触/压到边框
  3. **未重启**：改 `customBg -40` 后若只 `/reload`，`_dfTrainerSkinned` 守护挡 skin 重应用 → 改动没生效

### 下次必做（勿盲改）

1. 重启 WoW.exe 后 `/trdump` 确认 `customBg p2 BR = -40` 已应用
2. 给 `/trdump` 增打：每行 Y、列表底/详情底 vs customBg 底、金属框内沿坐标
3. 或先要截图，标出"超出"的具体方位（上/下/左/右）
4. 诊断命令 `/trdump` 已可用（**setfenv 模块必须 `_G.SLASH_xxx`/`_G.SlashCmdList` 注册**，裸写落 DFUI env 表 → `_G` 读不到 → 命令失效；照 `trainerdata.lua` 范式）

</details>
