# 面板已知问题

> 最后更新：2026-04-12

## 一、CraftFrame（宠物训练 Beast Training）— 训练点数不显示

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

1. **在 customBg 上自建 FontString** — 完全不依赖 Blizzard 元素，自行创建文字显示训练点数，监听 `UNIT_PET_TRAINING_POINTS` 事件实时更新
2. **排查 Blizzard 元素不可见的深层原因** — 检查 FontString 的 font、alpha、width/height、parent visibility 等属性，确认是否有其他隐藏机制
3. **Hook CraftFrame_Update** — 在 Blizzard 的更新函数执行后，强制设置锚点和显示

---

## 二、TradeSkill / CraftFrame — 滚动条下箭头超出内边框 ⚠️ 已知取舍

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

## 三、CraftFrame（附魔/宠物训练）— 搜索栏位置 ✅ 已修复

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

## 四、TradeSkillFrame — 下拉筛选框/折叠按钮/复选框布局未生效

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
