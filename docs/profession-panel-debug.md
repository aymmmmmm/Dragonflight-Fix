# 专业技能面板调试记录

> 最后更新：2026-04-13

## 一、已解决的问题

### 1.1 调用原生 SetSelection (已删除)

`TradeSkillFrame_SetSelection()` / `CraftFrame_SetSelection()` 是 Blizzard UI 函数，会更新被隐藏的原生面板元素导致崩溃。

**修复**: 全部删除，只用内部 `selectedIndex` 变量管理选中状态。

### 1.2 Craft 折叠 API 不存在 (已修复)

`CollapseCraftSkillLine` / `ExpandCraftSkillLine` 是虚构函数名。Craft 没有分类折叠 API（DragonflightUI 源码确认）。

**修复**: 折叠按钮在 Craft 模式下隐藏。

### 1.3 SetShown 不兼容 (已修复)

WoW 1.12 没有 `frame:SetShown(bool)` API。整个 Dragonflight-Fix 项目只有 tradeskill.lua 误用了 7 处。

**修复**: 全部替换为 `if cond then x:Show() else x:Hide() end`。

### 1.4 EditBox 上调用 SetBackdrop (已修复)

WoW 1.12 EditBox 可能不支持 SetBackdrop。搜索框直接在 EditBox 上调用导致崩溃。

**修复**: 拆分为 Frame 容器 (`searchBg`) 承载 Backdrop + 裸 EditBox (`searchBox`)。

### 1.5 Hide 原生面板断开 API (已修复)

`OpenProfession` 中 `TradeSkillFrame:Hide()` 触发 `TRADE_SKILL_CLOSE` 事件，API 断开后所有 `GetTradeSkillInfo()` 等调用失效。

**修复**: 改用 `SetAlpha(0) + EnableMouse(false)` 透明化，不 Hide。

### 1.6 setfenv 下 UIPanelButtonTemplate 崩溃 (已修复)

**关键发现**: `setfenv(1, DFUI:GetEnv())` 环境下 `CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")` 会崩溃。

**排查过程**:
- 通过在代码中插入 `panel.testMark` 标记进行二分定位
- 确认面板创建成功 (`DFUI_ProfessionFrame` = table)
- 确认 `OnEvent` 从未绑定 (`GetScript("OnEvent")` = nil)
- 二分结果: `testMark2=true`（配方列表+详情区通过）, `testMark3=nil`（底部操作区崩溃）
- 进一步定位: `testMark2b=nil`（在 UIPanelButtonTemplate 处崩溃）

**对比验证**:
- `frames.lua` 和 `talents.lua` 都用了 `UIPanelButtonTemplate` 且正常 —— 因为它们**没有 setfenv**
- `spellbook.lua` 有 `setfenv` 但只用了 `UICheckButtonTemplate` 和 `CooldownFrameTemplate`（这两个不崩）
- 结论: `setfenv` 环境 + `UIPanelButtonTemplate` = 崩溃（模板内部脚本在错误环境中执行）

**修复**: 不使用 `UIPanelButtonTemplate`，改为 `CreateSimpleButton()` 手动创建按钮（Frame + 背景纹理 + 边框 + 文字 + 高亮）。`InputBoxTemplate` 同理改为裸 EditBox。

### 1.7 GetCraftCooldown 在 API 未就绪时崩溃 (已修复)

打开 Craft 类专业（附魔/宠物训练）时，`GetCraftCooldown(selectedIndex)` 在 API 未就绪时崩溃（第578行）。

**修复**: UpdateDetail 中所有 API 调用加 `pcall` 保护，失败时安全隐藏详情区。

### 1.8 OnHide/CLOSE 事件循环重入 (已修复)

`panel:Hide()` → OnHide 调 `CloseTradeSkill()` → 触发 `TRADE_SKILL_CLOSE` → OnEvent 可能再调 `panel:Hide()`。

**修复**: `isClosing` 守卫标志，OnHide 入口检查 + CLOSE 事件也检查。

### 1.9 ADDON_LOADED 竞态 (已修复)

若 Blizzard_TradeSkillUI/CraftUI 在本模块之前已加载，ADDON_LOADED 不再触发，原生面板不会被透明化。

**修复**: 事件注册后立即检查 TradeSkillFrame/CraftFrame 是否已存在，`tradeSkillHooked`/`craftHooked` 防重复 hook。

### 1.10 for 循环闭包捕获 (已修复)

WoW 1.12 Lua 5.0 的 for-in 循环变量在 SetScript 闭包中捕获不可靠，导致 btn/slot 引用错误。

**修复**: 所有 SetScript 内改用 `this`（WoW 脚本处理器当前框体引用）。材料格用 `this:GetParent()`。

### 1.11 SetCraftItem 单参数崩溃 (已修复)

`GameTooltip:SetCraftItem(index)` 只传一个参数触发 ShaguTweaks vendor-values.lua hook 中 `GetCraftReagentItemLink(skill, nil)` 崩溃。

**修复**: 配方产物 tooltip 改用 `GameTooltip:SetCraftSpell(index)`，材料 tooltip 保持 `SetCraftItem(index, reagentIndex)`。

### 1.12 UpdateDetail 前向声明 (已修复)

`UpdateRecipeList` 内调用 `UpdateDetail`，但后者在代码中定义更晚。Lua 5.0 编译时 UpdateDetail 解析为全局查找 → nil 崩溃。

**修复**: 在 UpdateRecipeList 前加 `local UpdateDetail` 前向声明，后面改为 `UpdateDetail = function()`。

### 1.13 折叠 header 被 pending 过滤 (已修复)

折叠状态 header 的子项被 API 隐藏，不出现在循环中，header 的 pending 标记不会被清除 → 被过滤掉。

**修复**: 折叠状态 (`isExpanded = false`) 的 header 直接设 `pending = false`。

### 1.14 连续 header 被过滤 (已修复)

采矿列表 `全部(header) → 商品(header) → 子项...`，"全部"后面紧跟另一个 header，中间无子项，永远不会被确认。

**修复**: 遇到新 header 时，如果上一个 header 仍 pending，先确认它。

## 二、当前状态

面板功能基本完成。UI 已按法术书风格重构（熟练度条移入左页、操作按钮移入右页底部、职业圆形图标）。

### 已验证

1. [x] 打开 TradeSkill 类专业 → 新面板显示
2. [x] 打开 Craft 类专业 → 新面板显示
3. [x] 配方列表正确渲染（含折叠/展开）
4. [x] 选中配方 → 详情区显示
5. [x] 制作按钮可用
6. [x] 搜索/过滤功能
7. [x] 关闭面板无报错

### 待修

1. [ ] "全部" header 文字不显示（逻辑正确但视觉不可见，DEBUG 输出已清理，问题仍存在）

### 已修复（本轮 — UI 重构 2026-04-13）

- [x] Tab 系统中文客户端不工作 — 改为 RegisterCurrentProfession 动态累积 + TempDB 持久化
- [x] 清理 DEBUG 输出代码
- [x] 难度颜色与羊皮纸背景混叠不可读
- [x] 选中状态几乎不可见
- [x] 配方行极度拥挤无呼吸感
- [x] 底部控件垂直不统一+堆叠风险
- [x] 悬停效果拉伸变形

### 1.15 难度颜色羊皮纸对比度 (已修复)

原色 optimal(1.0,0.5,0.1)/medium(1.0,1.0,0.0)/trivial(0.5,0.5,0.5) 在金色羊皮纸背景上几乎不可读。

**修复**: 全部调深 — optimal→(0.80,0.25,0.00) 烧赭色、medium→(0.72,0.55,0.00) 深琥珀、trivial→(0.40,0.36,0.32) 暖灰褐。所有配方文字加 OUTLINE 描边提供 1px 黑边分离背景。

**要点**: 羊皮纸背景偏金黄暖色，黄色系文字必须大幅拉低亮度和饱和度才有对比度。OUTLINE 是最轻量的可读性增强手段，不需要额外阴影帧。

### 1.16 选中状态三层结构 (已修复)

原选中态仅 WHITE8X8 alpha=0.15 金色色块，几乎不可见。悬停用 spellbook_highlight.blp（47x47 图标纹理）拉伸到整行，严重变形。

**修复**: 选中态改为三层 — ①3px 金色左侧竖条（主指示）②深金背景 alpha=0.30 ③上下 1px 金色边线 alpha=0.40。悬停改为 WHITE8X8 ADD blend 自适应行宽。封装 SetButtonSelected(btn, bool) 统一控制。

**要点**: 左侧竖条是最有效的"你在这里"信号，背景色块作辅助，边线提供容器感。HIGHLIGHT 层纹理必须匹配目标尺寸，不能拉伸图标纹理到列表行。

### 1.17 配方行布局呼吸感 (已修复)

行高仅 16px + 1px 间距 = 极度拥挤，无图标，折叠用 `[+]/[-]` 文字噪音大。

**修复**: 行高 16→22px，间距 1→2px，MAX_RECIPE_BUTTONS 23→15。每行添加 18x18 配方产物图标。Header 上方添加 1px 分隔线。折叠图标简化为单字符 `+`/`-`。

**要点**: 行数减少但呼吸感大幅提升。配方图标调用 GetTradeSkillIcon/GetCraftIcon，需在 UpdateRecipeList 中动态切换 nameText 锚点（图标存在时锚定图标右侧，否则锚定左侧 20px）。

### 1.18 底部操作区分页锚定 (已修复)

搜索框 BOTTOMLEFT(panel, 15, 8) 与操作按钮 BOTTOMRIGHT(rightPage, -25, 20) 垂直差 12px，且按钮从右向左链式排列时 +/- 按钮与全部/取消堆叠。

**修复**: 搜索+过滤锚定左页底部(leftPage, 20, 15)，操作按钮锚定右页底部(rightPage, -20, 15)。所有控件高度统一 24px。锚定链从右到左：[制作]←[取消]←[全部]←[+]←[数量]←[-]，注意 + 按钮必须用 RIGHT 锚到 [全部] 的 LEFT（不能用 LEFT 锚到输入框 RIGHT，否则挤入间隙）。

### 1.19 Tab 系统持久化 (已修复)

原 ScanProfessions 用英文 rank 匹配（Apprentice/Journeyman 等），中文客户端全部失败。改为动态累积后，/rl 丢失。

**修复**: 
1. RegisterCurrentProfession — 每次打开专业时用 GetTradeSkillLine()/GetCraftName() 获取名称（语言无关），FindSpellByName 在法术书中查找 spellIndex
2. SaveKnownProfessions — 只存 {name} 到 DFUI:SetTempDB，通过 DFUI_PROFILES 持久化
3. 加载时用名称重新 FindSpellByName 查找（spellIndex 会变，不能直接存）
4. 遗忘专业自动清理（FindSpellByName 找不到则不加入）

**要点**: 法术书 spellIndex 不稳定（学新技能/遗忘都会变），必须按名称查找。TempDB 虽名带 Temp 但通过 SaveTempDB→DFUI_PROFILES 实现跨会话持久化。

## 三、设计决策总结

### 原生面板处理: SetAlpha(0) 方案

| 方案 | 说明 | 状态 |
|------|------|------|
| KillFrame | 彻底杀死 | ❌ 不可用 — API 依赖框架"打开"状态 |
| Hide | 隐藏 | ❌ 不可用 — 触发 CLOSE 事件断开 API |
| SetAlpha(0) | 透明+禁用鼠标 | ✅ 当前方案 — API 保持连接 |
| SetAlpha(0)+移出屏幕 | 透明+禁用+SetPoint(-10000) | ✅ 当前实际方案 — 双保险 |

### setfenv 兼容性

| 模板 | setfenv 下可用 | 来源 |
|------|---------------|------|
| `UICheckButtonTemplate` | ✅ | spellbook.lua 验证 |
| `CooldownFrameTemplate` | ✅ | spellbook.lua 验证 |
| `UIPanelButtonTemplate` | ❌ 崩溃 | tradeskill.lua 二分定位 |
| `InputBoxTemplate` | ⚠️ 未验证 | 已替换为裸 EditBox 规避 |

### 代码架构

```
tradeskill.lua 结构:

1-36:     常量、工厂函数、模块声明
37-51:    状态变量
53-136:   面板框架 + 页面纹理 + 图标/标题 + 熟练度条
138-253:  左页配方列表 (按钮池)
255-312:  右页配方详情 (图标/材料格)
314-405:  底部操作区 (手动按钮 + 裸 EditBox + 复选框)
407-555:  数据函数: UpdateRankBar / UpdateRecipeList / UpdateDetail (local function)
557-800:  SetScript 统一绑定 (在函数定义之后)
802-960:  Tab 系统 + OpenProfession + OnShow/OnHide
962+:     事件系统 + ADDON_LOADED hook

关键设计:
  - 所有数据函数为 local function，非 panel:Method()
  - 所有 SetScript 在函数定义之后绑定
  - 不使用 UIPanelButtonTemplate（setfenv 不兼容）
  - 不使用 SetShown（WoW 1.12 不存在）
  - 不 Hide 原生面板（断开 API），用 SetAlpha(0) 透明化
  - API 调用加 pcall 保护
```

## 四、参考实现对比

| 维度 | 当前实现 | pfUI | DragonflightUI |
|------|---------|------|----------------|
| 原生面板 | SetAlpha(0) 透明化 | 换皮复用 | 让原生显示，自建覆盖 |
| 按钮创建 | 手动 (无模板) | SkinButton | 模板 + Mixin |
| 配方选中 | 内部 selectedIndex | hooksecurefunc(SetSelection) | 内部 selectedSkill |
| API 保护 | pcall | 无 | 条件检查 |
| 折叠 | 原生 CollapseTradeSkillSubClass | 原生 | 自建折叠状态 |
