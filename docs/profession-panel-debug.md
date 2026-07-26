# 专业技能面板调试记录

> 最后更新：2026-06-01（核对当前代码，约 2080 行）

## 一、已解决的问题

### 1.1 调用原生 SetSelection (已删除)

`TradeSkillFrame_SetSelection()` / `CraftFrame_SetSelection()` 是 Blizzard UI 函数，会更新被隐藏的原生面板元素导致崩溃。

**修复**: 全部删除，只用内部 `selectedIndex` 变量管理选中状态。

### 1.2 Craft 折叠处理

当前代码（OnClick L1623-1629、L1704-1716；OpenProfession L1944）：
- 顶部"全部折叠"按钮 `collapseAllBtn` 仅 TradeSkill 模式 Show，Craft 模式 Hide。
- Craft 模式下，header 行点击仍调用 `CollapseCraftSkillLine(index)` / `ExpandCraftSkillLine(index)`（含 index=0 全部）。

注：这两个 Craft 折叠函数在 Turtle 1.12 是否真实存在、调用是否报错，需游戏内实证（待游戏内实证）。早期文档曾记为"虚构函数名"，但当前代码已直接调用，故以代码为准更新本节。

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
- `spellbook.lua` 有 `setfenv`（L1），但复选框走项目助手 `CreatePanelCheckbox`（L52 `local CreateCheckbox = CreatePanelCheckbox`），模板仅用 `CooldownFrameTemplate`（L357，不崩）；全文件无 `UICheckButtonTemplate`
- 结论: `setfenv` 环境 + `UIPanelButtonTemplate` = 崩溃（模板内部脚本在错误环境中执行）

**修复**: 不使用 `UIPanelButtonTemplate`，改为 `CreateSimpleButton()` 手动创建按钮（Frame + 背景纹理 + 边框 + 文字 + 高亮）。`InputBoxTemplate` 同理改为裸 EditBox。

### 1.7 GetCraftCooldown 在 API 未就绪时崩溃 (已修复)

打开 Craft 类专业（附魔/宠物训练）时，`GetCraftCooldown(selectedIndex)` 在 API 未就绪时崩溃（历史行号 578，现已失效；当前该调用位于 UpdateDetail 内 L1408）。

**修复**: UpdateDetail 中所有 API 调用加 `pcall` 保护，失败时安全隐藏详情区。当前 `GetCraftCooldown` 已用 `pcall` 包装（L1408 `local cdOk, cd = pcall(GetCraftCooldown, selectedIndex)`）。

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

> 已被后续修订取代：右侧背景后改为 DF 深色专业背景画，难度色随之改回明亮配色。当前 `DIFFICULTY_COLORS`（tradeskill.lua L344-353）为 optimal={1.00,0.50,0.25}、medium={1.00,0.82,0.00}、trivial={0.75,0.75,0.75}，并新增 easy/header/none/used/default 项。本节描述的烧赭/深琥珀低亮度配色已不在代码中。

### 1.16 选中状态三层结构 (已修复)

原选中态仅 WHITE8X8 alpha=0.15 金色色块，几乎不可见。悬停用 spellbook_highlight.blp（47x47 图标纹理）拉伸到整行，严重变形。

**修复**: 选中态改为三层 — ①3px 金色左侧竖条（主指示）②深金背景 alpha=0.30 ③上下 1px 金色边线 alpha=0.40。悬停改为 WHITE8X8 ADD blend 自适应行宽。封装 SetButtonSelected(btn, bool) 统一控制。

**要点**: 左侧竖条是最有效的"你在这里"信号，背景色块作辅助，边线提供容器感。HIGHLIGHT 层纹理必须匹配目标尺寸，不能拉伸图标纹理到列表行。

> 已被后续修订取代：当前选中/悬停均用 vanilla `Interface\QuestFrame\UI-QuestLogTitleHighlight`（灰色 alpha mask）+ SetVertexColor 染金 + ADD blend（tradeskill.lua L638-653）。选中态为单个 `selectedOverlay`（BORDER 层），由 `SetButtonSelected(btn, bool)`（L691-693）Show/Hide；header 3-slice 背景另用 recipe-header-left/middle/right atlas（L610-635）。本节描述的"3px 竖条+背景+边线"三层结构已不在代码中，但 `SetButtonSelected` 封装名仍在用。

### 1.17 配方行布局呼吸感 (已修复)

行高仅 16px + 1px 间距 = 极度拥挤，无图标，折叠用 `[+]/[-]` 文字噪音大。

**修复**: 行高 16→22px，间距 1→2px，MAX_RECIPE_BUTTONS 23→15。每行添加 18x18 配方产物图标。Header 上方添加 1px 分隔线。折叠图标简化为单字符 `+`/`-`。

> 当前代码具体数值已变：`MAX_RECIPE_BUTTONS=20`（L370），行高 20px、行间距 -3（L697-701），配方产物图标 20×20（`recipeIcon` L657-658）。折叠单字符 `+`/`-`（`collapseIcon` FontString，L672-677）与本节一致。

**要点**: 行数减少但呼吸感大幅提升。配方图标调用 GetTradeSkillIcon/GetCraftIcon，需在 UpdateRecipeList 中动态切换 nameText 锚点（图标存在时锚定图标右侧，否则锚定左侧 20px）。

### 1.18 底部操作区分页锚定 (已修复)

搜索框 BOTTOMLEFT(panel, 15, 8) 与操作按钮 BOTTOMRIGHT(rightPage, -25, 20) 垂直差 12px，且按钮从右向左链式排列时 +/- 按钮与全部/取消堆叠。

**修复**: 搜索+过滤锚定左页底部(leftPage, 20, 15)，操作按钮锚定右页底部(rightPage, -20, 15)。所有控件高度统一 24px。锚定链从右到左：[制作]←[取消]←[全部]←[+]←[数量]←[-]，注意 + 按钮必须用 RIGHT 锚到 [全部] 的 LEFT（不能用 LEFT 锚到输入框 RIGHT，否则挤入间隙）。

> 当前代码：操作按钮链与 24px 统一高度仍如上（L955-996，全 `CreateSimpleButton` 高 24，链 [制作]←[取消]←[全部]←[+]←[数量框]←[-]，制作锚 panel BOTTOMRIGHT -36,16）；但搜索框+"有材料"勾选已上移到左栏顶部同一行（`searchBg` 锚 leftColumn TOPLEFT 10,-15，L1003；`matsCheckbox` 锚 searchBg RIGHT，L1033），不再在左页底部。

### 1.19 Tab 系统持久化 (已修复)

原 ScanProfessions 用英文 rank 匹配（Apprentice/Journeyman 等），中文客户端全部失败。改为动态累积后，/rl 丢失。

**修复**: 
1. RegisterCurrentProfession — 每次打开专业时用 GetTradeSkillLine()/GetCraftName() 获取名称（语言无关），FindSpellByName 在法术书中查找 spellIndex
2. SaveKnownProfessions — 只存 {name} 到 DFUI:SetTempDB，通过 DFUI_PROFILES 持久化
3. 加载时用名称重新 FindSpellByName 查找（spellIndex 会变，不能直接存）
4. 遗忘专业自动清理（FindSpellByName 找不到则不加入）

**要点**: 法术书 spellIndex 不稳定（学新技能/遗忘都会变），必须按名称查找。TempDB 虽名带 Temp 但通过 SaveTempDB→DFUI_PROFILES 实现跨会话持久化。

> 注：当前 Tab 实现已改为运行时扫描法术书综合页（`ScanSpellbookForProfessions` L1833），按 `PROFESSION_SPELLS` 白名单匹配收集 `knownProfessions`，`CreateProfessionTabs` L1853 据此建 Tab。`OpenProfession` 内首次打开延迟扫描（`profScanned` 门控），不再依赖 RegisterCurrentProfession/SaveKnownProfessions 持久化路径。本节描述的 TempDB 持久化机制为早期方案，与当前代码不符，保留作演进记录。

### 1.20 配方收藏 (本轮后续新增)

右键配方行切换收藏，持久化到 `DFUI_CUR_PROFILE.TradeSkillFavorites[专业名][配方名]=true`（L413-435）。配方行左侧 8px ☆ 星标（`btn.favStar`，ReputationStar 纹理染金），详情区产物名右侧 ☆（`detailFavStar`）。

**要点**: 收藏态在 `RebuildRecipeData` 中预计算进 `item.isFav`（L1187），渲染只读缓存；右键 OnClick 调 `ToggleFavorite` + `UpdateRecipeList`（走 Rebuild 刷新缓存）。

### 1.21 滚轮卡顿 — 数据/渲染分离 + 图标常驻池 (本轮后续新增)

`UpdateRecipeList` 拆为 `RebuildRecipeData()`（全表扫描+过滤+图标预取+难度色/收藏态预计算进 `recipeCache`）与 `RenderRecipeButtons()`（仅读缓存按 `scrollOffset` 绘制 20 按钮）。滚轮 `OnMouseWheel`（L1764）只调 Render，clamp 在 Render 内。

**要点**:
- 数据真变化的调用点（搜索/过滤/折叠/TRADE_SKILL_UPDATE 事件）走 `UpdateRecipeList`（Rebuild+Render 包装），滚动只走 Render。
- 按钮级 diff：btn 缓存 `_lastIcon/_lastSkillKey/_lastFontSize/_lastLayoutMode`，仅值变化才 SetTexture/ApplyAtlas/SetFont/重锚；空槽与 OnHide 清缓存防脏值。
- 图标常驻池 `iconKeep[path]=隐藏1×1纹理`（L568、OnUpdate L1989）：为每个唯一图标路径建持久隐藏纹理持有引用，防纹理缓存逐出（解决"上滚卡/下滚不卡"不对称卡顿）。分帧建（每帧 6 张），跨开关持久保留。

> 详细根因/演进见项目记忆 `project_tradeskill_scroll_perf`（三轮修复，第三轮已用户实测确认有效）。

### 1.22 两个专业 Tab 同时高亮 (已修复 2026-07-26)

现象：打开面板后底部两个 tab 同时是选中态（如"急救"+"炼金术"），且整局不消失。

**根因（两个 bug 叠加）**：
1. `paperdoll.lua` 的 `AddTab` 工厂末尾无条件"自动选中第一个 tab"（`numTabs == 0` → `SetSelected(true)` + `frame.selectedTab = tab`）。`CreateProfessionTabs` 首建时 tab 池为空，全部走新建分支 → 第 1 个专业 tab 被工厂选中。
2. `CreateProfessionTabs` 随后对匹配当前专业的 tab 再 `SetSelected(true)`，但只覆盖 `panel.selectedTab` 引用、**没有反选**第 1 个 tab。而全代码的反选都只针对 `panel.selectedTab` 这一个引用 → 第 1 个 tab 变成"孤儿选中"，再没人关得掉。

**修复**：新增 `SelectTabExclusive(tab)`（遍历 `panel.Tabs` 全量 `SetSelected(t == tab)`，传 nil = 全灭，范式同 `spellbook.lua` 的 `SelectRightTab`），替换全部三处"单引用反选"：`AcquireTab` 的 OnClick、`CreateProfessionTabs` 首建高亮（改为循环结束后统一选中）、`OpenProfession` 的 pendingTab / 名字匹配两个分支（后者补 `break`）。同时 `AcquireTab` 把 OnClick 绑定与 `SetSelected(false)` 复位移出 if/else，两条路径（新建 / 池复用）统一执行 —— 当场抵消工厂的自动选中。

**要点**：`AddTab` 的"自动选中第一个"被 character/inspect/mail/macro/merchant/social 六个面板依赖（都默认停第 1 页），**不能改工厂**，只能在调用方做互斥。选中态没有可查询接口（`tab:SetSelected` 无状态缓存），只靠一个 `selectedTab` 引用记录 → 引用一被覆盖旧 tab 就失联，这类 tab 系统一律用"全量互斥"而非"反选上一个"。

### 1.23 新学专业需 /reload 才出现 (已修复 2026-07-26)

现象：第一次学会"生存"（或任意新专业）后 tab 里没有它，必须 `/reload`。

**根因（两道锁，一个会话只扫描/构建一次）**：
- 锁 A `profScanned`：`ScanSpellbookForProfessions` 只要扫到 ≥1 个专业就永久置位，此后再不重扫法术书。
- 锁 B `if table.getn(panel.Tabs) == 0 then CreateProfessionTabs() end`：`panel.Tabs` 只有 `ReleaseAllTabs()` 清空，而它只被 `CreateProfessionTabs` 自己调用 → 首建后该分支恒假，成死代码。
- 事件层无兜底：只注册了 TRADE_SKILL_*/CRAFT_*，没有 `LEARNED_SPELL_IN_TAB`/`SKILL_LINES_CHANGED`。

**同源连带症状**（一并修好）：
- 生存的 craft 误报兜底（`GetCraftName()` 乱报时回退查 `knownProfessions` 里的"生存"）依赖该表已有生存条目 → 刚学会时即使从法术书施法打开，`activeProfName` 也会退化成误报的 apiName，背景图与收藏 key 全错。
- tab 的 `CastSpell(captured.spellIndex, ...)` 闭包捕获的是建 tab 那一刻的法术书索引；学任何新法术都会让后续索引整体位移 → 点旧 tab 施错法术。

**修复**：新增 `RefreshProfessionTabs()` —— 重扫法术书，用 `ProfListKey()`（专业名拼串）对比集合：没变只就地刷新各 tab 的 `spellIndex`（保住 tab 引用），变了才 `CreateProfessionTabs()` 重建。`OpenProfession` 里替换掉 `profScanned` 门控与死代码分支（调用点必须**早于**专业身份判定，craft 误报兜底要读新鲜的 `knownProfessions`）。tab 改为携带 `tab.spellIndex` 字段、OnClick 读字段而非闭包捕获值。额外注册 `LEARNED_SPELL_IN_TAB`/`SKILL_LINES_CHANGED`，面板开着时当场刷新。

**要点**：
- `ReleaseAllTabs()` 会把 `pendingTab`/`activeTab`/`panel.selectedTab` 三个引用清 nil，而 `OpenProfession` 后面要用 `pendingTab` 定高亮 —— 重建前必须**先存名字（profName）、重建后按名字找回**（`FindTabByProfName`），否则点 tab 打开专业时高亮与"防重复点击关闭"逻辑一起失效。
- 去掉 `profScanned` 后要补显式守卫：扫描结果为空但之前有值（法术书数据没就绪，`GetSpellTabInfo(1)` 返回 nil）时保留旧表直接返回，否则会把已建好的 tab 全洗掉 —— 这是原门控顺带提供的保护。
- 顺带补 `CRAFT_CAPABLE` 缺失的珠宝加工/Jewelcrafting：`PROFESSION_SPELLS` 早已含珠宝但信任表没同步，珠宝若走 Craft API 会被判成"误报"→ 兜底强行认成生存。

### 1.24 §1.10 闭包捕获坑复发 —— tab 点击全部串到同一个专业 (已修复 2026-07-26)

现象：修完 §1.22/§1.23 后出现回归 —— 打开面板恒定高亮同一个 tab（用户只有两个主专业时表现为"默认第二个专业选中"），且**点任何 tab 打开的都是同一个专业**（内容也错，不只是高亮）。

**根因**：§1.23 为了让 `spellIndex` 可被 `RefreshProfessionTabs` 就地刷新，把点击回调里的
`CastSpell(captured.spellIndex, ...)` 改成了 `CastSpell(tab.spellIndex, ...)`。
`captured` 是 `local captured = prof` —— **闭包创建前已赋值**；
`tab` 是 `local tab` → `tab = AcquireTab(..., function() ... tab ... end, ...)` —— **闭包在参数位构造时 `tab` 还是 nil，赋值发生在 AcquireTab 返回之后**。这正是 §1.10 记录的"for 循环体内 local 在 SetScript 闭包中捕获不可靠"最容易翻车的形态：捕获一串，所有 tab 的回调都指向同一个 frame → 施同一个专业的法术 + 高亮同一个 tab。

**修复**：按 §1.10 的既有解法，点击路径彻底不依赖闭包捕获：
- `AcquireTab` 的 OnClick 脚本内一律用 `this`：`SelectTabExclusive(this)`；
- 业务回调挂到 tab 字段 `tab.dfOnClick = onClick`，脚本里 `this.dfOnClick(this)` 带参调用；
- `CreateProfessionTabs` 的回调签名改为 `function(self)`，内部 `activeTab == self` / `pendingTab = self` / `CastSpell(self.spellIndex, ...)` 全走参数。

这样既保留了"索引存字段、可运行时刷新"的能力，又不引入任何循环内 local 的捕获。

**要点（第二次踩，写死）**：本文件的 SetScript 回调**一律走 `this`**。判断标准不是"是不是 for 循环变量"，而是"回调里引用的变量是不是外层循环体作用域的 local" —— 尤其是**闭包先构造、变量后赋值**这种写法（`local x; x = f(function() ... x ... end)`），风险最高。需要按 tab/按钮区分身份时，把数据挂成 frame 字段（`tab.profName` / `tab.spellIndex`），回调用 `this.字段` 取。

**顺带修**：tab 池复用时原来只 `tab.Text:SetText(text)`，不重算宽度 —— 旧代码 tab 永不重建碰不到，§1.23 让 tab 会重建后就暴露（学新专业后 tab 宽度停留在上一个标签）。给 `paperdoll.lua` 的 `AddTab` 加了纯增量方法 `tab:SetLabel(newText)`（改文字 + 重算 tab 宽度 + 同步 left/right/leftSel/rightSel/hlLeft/hlRight 六个边缘纹理宽度，否则拼不拢露缝），`AcquireTab` 复用路径改调它。工厂既有行为未变。

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
| `CooldownFrameTemplate` | ✅ | spellbook.lua（L357，有 setfenv）验证 |
| `UIPanelButtonTemplate` | ❌ 崩溃 | tradeskill.lua 二分定位 |
| `InputBoxTemplate` | ⚠️ 未验证 | 已替换为裸 EditBox 规避 |

> 注：spellbook.lua 复选框走项目助手 `CreatePanelCheckbox`（L52）而非 `UICheckButtonTemplate`，全文件无该模板，故不再作为 setfenv 兼容性证据列入本表。`UICheckButtonTemplate` 在 setfenv 下是否可用属"待游戏内实证"。

### 代码架构

```
tradeskill.lua 结构 (行号对应当前代码，约 2080 行):

1-58:      setfenv 守卫 + TGA/Atlas 切片表 + ATLAS_SIZE/LAYOUT 常量
69-128:    ATLAS 表 + ApplyAtlas + sanity 校验
130-341:   CreateInsetBackdrop / CreateMinimalScrollbar helper
343-359:   DIFFICULTY_COLORS + NewDefaults
361+:      NewMod("TradeSkill", 5, function() … end) 主体
  365-435:   状态变量 + HideNativeFrame + 收藏机制 (GetFavTable/IsFavorite/ToggleFavorite)
  437-545:   面板框架 + 左右分栏 + 专业背景画 + 图标/标题/关闭 + 熟练度条
  547-705:   左页配方列表 (collapseAllBtn + 按钮池 + iconKeep/warmQueue 图标常驻池)
  707-885:   右页配方详情 (主图标 + 材料格工厂 + QUALITY_TGA)
  887-1037:  底部操作区 (CreateSimpleButton 手动按钮 + 裸 EditBox + 搜索框 + 复选框)
  1040-1606: 数据函数: UpdateRankBar / RebuildRecipeData / RenderRecipeButtons
             / UpdateRecipeList(包装) / UpdateDetail (全 local function)
  1608-1771: SetScript 统一绑定 (在函数定义之后) + 滚轮 OnMouseWheel
  1773-1872: Tab 系统 (tabPool / ScanSpellbookForProfessions / CreateProfessionTabs)
  1874-1977: OpenProfession + OnShow/OnHide
  1979-2004: OnUpdate (节流 flush + Layer C 图标分帧常驻)
  2006+:     事件系统 + ADDON_LOADED hook + UISpecialFrames 注册

关键设计:
  - 所有数据函数为 local function，非 panel:Method()
  - 所有 SetScript 在函数定义之后绑定
  - 滚轮卡顿已拆为 RebuildRecipeData(数据/缓存) + RenderRecipeButtons(渲染)，
    滚动只调 Render；UpdateRecipeList 仍为 Rebuild+Render 包装（详见专项性能记录）
  - 不使用 UIPanelButtonTemplate（setfenv 不兼容），关闭键用 DFUI.CreateRedButton
  - 不使用 SetShown（WoW 1.12 不存在）
  - 不 Hide 原生面板（断开 API），用 SetAlpha(0)+移出屏幕透明化
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
