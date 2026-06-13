# 面板美化实施进度

> 最后更新：2026-05-31（社交「查找」全自制重写完成；面板数复核）

## 一、已完成的面板（19 个）

> 复核（toc 加载 `modules\panels\*.lua` 共 21 个）：其中 `paperdoll.lua` 是工厂函数、`scrollbar.lua` 是全局滚动条换肤、`questlog_xp.lua` 是任务经验估算（非美化面板），其余 19 个均为已美化面板。下表 Phase 1~3 列出主要面板，第五节「补充已完成」列出后续追加的面板。

### Phase 1：基础设施 + 高频面板

| 面板 | 文件 | 状态 | 说明 |
|------|------|------|------|
| **工厂函数** | `modules/panels/paperdoll.lua` | ✅ 完成 | CreatePaperDollFrame + CreateRedButton + Tab 系统 |
| **角色面板** | `modules/panels/character.lua` | ✅ 完成 | 5 Tab + 品质边框 + 宠物 Tab 动态 |
| **银行** | `modules/panels/bank.lua` | ✅ 完成 | 24+6 物品栏 DF 边框 |
| **商人** | `modules/panels/merchant.lua` | ✅ 完成 | 2 Tab（商人/回购） |
| **任务对话** | `modules/panels/questframe.lua` | ✅ 完成 | 2026-06 重做：青铜框+羊皮纸+minimal滚动条+头像，共享 `questskin.lua`（见 §十） |
| **NPC 对话** | `modules/panels/gossip.lua` | ✅ 完成 | 2026-06 重做：同上，共享 `questskin.lua`（见 §十） |
| **任务日志** | `modules/panels/questlog.lua` | ✅ 完成 | 木纹+书签+左右背景 |
| **社交** | `modules/panels/social.lua` | ✅ 完成 | 4 Tab + Guild 动态禁用；「查找(Who)」已全自制重写（自建搜索框 `DFUI_WhoSearchBox` + 行挂 `whoInset` 脱离 vanilla FauxScrollFrame + `whoOffset` 自管 + 三操作按钮 + `dfuiTryWho` 客户端防抖 `DFUI_WHO_CD`），详见下方 §4.5 与「五、补充已完成」 |

### Phase 2：中频面板

| 面板 | 文件 | 状态 | 说明 |
|------|------|------|------|
| **邮件** | `modules/panels/mail.lua` | ✅ 完成 | 2 Tab + 邮件图标保留 |
| **交易** | `modules/panels/trade.lua` | ✅ 完成 | 左右双 PaperDollFrame |
| **训练师** | `modules/panels/trainer.lua` | ✅ 完成 | ADDON_LOADED 延迟 + 木纹 |
| **试穿** | `modules/panels/dressup.lua` | ✅ 完成 | 最简面板 |

### Phase 3：低频面板

| 面板 | 文件 | 状态 | 说明 |
|------|------|------|------|
| **帮助** | `modules/panels/help.lua` | ✅ 完成 | frameStyle 2 + 黑色背景 |
| **专业技能** | `modules/panels/tradeskill.lua` | ✅ 完成 | TradeSkill+Craft 共用，frameStyle 1（带头像金属框），宽框体 1069x658（`tradeskill.lua:440` `CreatePaperDollFrame(...,1069,658,1)`，文件头与 :438 注释一致），叠加 `PANEL_SCALE=0.85`（:65/:449）后等效屏幕约 908x559，全自制配方列表/详情，ADDON_LOADED 延迟 |

## 二、已修复的 Bug

### Bug 1：二次打开面板后美化消失
- **原因**：`tinsert(UISpecialFrames, ...)` 导致 ESC 关闭时 customBg 被显式 Hide，再次打开父框架时子框架不自动恢复
- **修复**：移除所有 `UISpecialFrames` 插入，改用 `HookScript(parentFrame, "OnShow", function() customBg:Show() end)`

### Bug 2：Tab 选中态凸出太高
- **原因**：选中态用 45px 纹理替代 36px 普通纹理
- **修复**：改为 39px，保留微妙的选中效果但不过分凸出（可通过 `selHeight` 变量调整）

## 三、角色面板细节优化（已完成）

### 已完成

| 元素 | 状态 | 说明 |
|------|------|------|
| **荣誉/竞技场子 Tab** | ✅ v2 重写 | 自定义子Tab替代暴雪原生Tab，金属纹理（uiframetabs.blp）缩小版，彻底避免 PanelTemplates 冲突 |
| **竞技场页面美化** | ✅ 完成 | ArenaFrameTeam1-3 SetBackdrop 美化 |
| **暴雪残留 Tab 隐藏** | ✅ 完成 | HonorFrameTab1/2 + ArenaFrameTab1/2 四个全部隐藏+阻止重显 |
| **技能 Tab "全部"按钮** | ✅ 完成 | `SkillFrameExpandButtonFrame` 金属Tab纹理背景（uiframetabs.blp） |
| **称号下拉框** | ✅ 完成 | `PaperDollFrameTitlesDropdown` 暗色圆角背景框（180px）+ 箭头/文字重定位 |

#### 最终实现方案

```
荣誉/竞技场子Tab系统：
  - 隐藏暴雪4个原生Tab（HonorFrameTab1/2 + ArenaFrameTab1/2）
  - CreateSubTab() 工厂函数：缩小版金属Tab（uiframetabs.blp，24px高）
  - honorSubTab1（荣誉）: ArenaFrame:Hide() + HonorFrame:Show()
  - honorSubTab2（竞技场）: HonorFrame:Hide() + ArenaFrame:Show()
  - honorTabActive 标记控制子Tab只在荣誉主Tab选中时显示
  - LeaveHonorTab() 在切到其他主Tab时统一清理

纹理清理（StripHonorAndArena）：
  - 一次性执行（honorSkinned 标记）
  - HideBlizzardTextures(HonorFrame) + HideBlizzardTextures(ArenaFrame)
  - ArenaFrameTeam1-3 用 SetBackdrop 美化（_dfSkinned 标记）

称号下拉框（PaperDollFrameTitlesDropdown）：
  - 注意：Turtle WoW 用的是 PaperDollFrameTitlesDropdown，不是 CharacterTitleDropDown
  - SetTexture(nil) 清除背景纹理，保留文字和箭头
  - SetWidth(180) 缩短宽度
  - 箭头按钮和文字需 ClearAllPoints 重新锚定到新宽度内
  - 暗色圆角背景框（UI-Tooltip-Border, 深灰底+暖棕边框）

经验教训：
  - 不要盲猜暴雪控件名，用 pfUI-SkinDiag dump 数据确认实际名称
  - 缩小控件宽度后必须重定位子元素（按钮/文字），否则会溢出
  - 下拉框不适合用金属Tab纹理，简洁的暗色圆角边框更搭配
  - 不要随意 ClearAllPoints + SetPoint 移动整个控件位置，容易破坏布局
```

## 四、2026-04-11 批量改进

### 4.1 法术书面板（spellbook.lua）

> ⚠️ 历史条目（2026-04-11）：本小节描述的是 4.11 批改时的换皮做法，**已被 §6「全重写」取代**，下表细节不再反映现行代码。现行实现见 `docs/spellbook-ui-design.md`。仅作改动脉络留存，纠正两处与当前代码不符的描述。

| 改动 | 说明 |
|------|------|
| 复选框过滤修复 | `this:SetChecked()` → 显式变量引用，避免 setfenv 下 `this` 解析失败 |
| 原生残留隐藏 | （已重写）当前不再用 KillFrame：`spellbook.lua:76` 用 `SoftHideFrame(SpellBookFrame)`（透明保活），并循环 `:Hide()` 隐藏 `SpellBookSkillLineTab1~8` 与 `SpellBookFrameTabButton1~3`（全局名带 `Frame`，旧表误写「FrameTabButton1~3」） |
| 技能按钮右移 | 左偏移 15 → 50，避免和页面左边缘重叠 |
| 文字配色 | 白色 → 深棕墨水色 (0.35,0.20,0.08) + 浅棕 (0.50,0.35,0.18)，匹配羊皮纸 |
| 可拖动 | SetMovable + RegisterForDrag + OnDragStart/OnDragStop |

### 4.2 所有面板统一改动（13个文件）
| 改动 | 说明 |
|------|------|
| ~~统一内边框~~（已撤销） | 4.11 时给 12 个面板加了 contentBg(黑色0.3) + contentBorder(UI-Tooltip-Border, edgeSize=16, 色 0.6/0.55/0.5)，**现已全部移除**——当前 `modules/panels/` 全目录无 `contentBg`/`contentBorder` 调用（已 Grep 复核为 0 命中），详见 `docs/panel-known-issues.md §五`（从 13 个面板移除） |
| 统一居中 | 17 个面板添加 CenterFrame() 钩子，打开时屏幕居中 |

### 4.3 工具函数（core/tools.lua）
| 函数 | 说明 |
|------|------|
| CenterFrame(frame) | OnShow 时 ClearAllPoints + SetPoint CENTER |
| AddSubBorder(parent, frame, inset) | 仅描边无背景，edgeSize=16，颜色与 contentBorder 统一 |

### 4.4 专业技能面板（tradeskill.lua）

> ⚠️ 历史条目：本小节为旧「换皮 TradeSkillFrame/CraftFrame」方案下的改动，该方案已被**全自制专业面板**取代（见 `docs/panel-known-issues.md` 架构说明）。下表多数符号（InputBox 描边、ListScrollFrame 重锚等）在当前 `tradeskill.lua` 已不存在，仅作脉络留存。

| 改动 | 说明 |
|------|------|
| 可拖动 | SetMovable + RegisterForDrag（当前实现 `tradeskill.lua:445-448` 仍在面板上保留） |
| 技能列表描边 | （旧换皮）ListScrollFrame 手动定位(TOPLEFT -17,9 / BOTTOMRIGHT +26,27) 包住滚动条——全自制面板自建配方列表，已无此符号 |
| ~~InputBox 描边~~（已撤销） | 旧换皮用 AddSubBorder 给制作数量输入框加描边；**现已移除**——tradeskill 全自制无 vanilla InputBox 描边调用（`docs/panel-known-issues.md §五` 记载已移除该 AddSubBorder 调用） |
| 标题上移 | （旧换皮）TitleText 重定位到 TOP, frame, TOP, 0, -8 |
| FrameLevel 修正 | （旧换皮）customBg 从 +1 改为 -1，防止遮挡原生内容 |

### 4.5 其他面板小改
| 面板 | 改动 |
|------|------|
| social.lua | （旧）WhoFrameEditBox 添加描边 —— 已被后续「查找(Who)」全自制重写取代：vanilla `WhoFrameEditBox` 改为 `:Hide()`，新建 `DFUI_WhoSearchBox`（详见「五、补充已完成」） |
| character.lua | SkillRankFrame 在技能页 OnShow 动态添加描边 |

### 4.6 新增文档
| 文档 | 内容 |
|------|------|
| docs/spellbook-ui-design.md | 法术书 UI 完整设计规范（配色/纹理/布局/复用指南） |
| docs/panel-known-issues.md | 已知问题（CraftFrame 训练点数不显示等） |

### 4.7 关键教训
- **改之前先确认改的是什么** — 分清"标题文字位置"和"内边框偏移"，避免改错对象
- **描边只加边不加背景** — AddSubBorder 初版错误地加了 bgFile 覆盖原内容，二版修正为仅 edgeFile
- **描边尺寸要和外层统一** — edgeSize 必须和 contentBorder 一致（16），否则不和谐
- **ScrollFrame 描边要考虑滚动条宽度** — 右侧需 +26px 包住 ~20px 宽的滚动条
- **不给大面积区域加描边** — ScrollFrame 加描边显得笨重，只给小控件（RankFrame/InputBox/EditBox）加

## 五、已尝试但撤回的方案

| 方案 | 原因 | 教训 |
|------|------|------|
| **滚动条箭头统一** | page_up/down_*.tga 纹理直接替换暴雪滚动条箭头，效果极差 | 动作条翻页箭头纹理不适合用于滚动条小按钮，尺寸和风格完全不同。需要专门为滚动条设计的箭头纹理或方案 |

### 已落地：滚动条/箭头统一（scrollbar.lua）

上述"撤回的纹理直替"方案已被独立模块 `modules/panels/scrollbar.lua`（`DFUI:NewMod("Scrollbar", ...)`）取代，思路与 pfUI 一致——着色 + 重纹理而非整图替换：

- `DFUI.SkinArrowButton`：箭头改用 `Interface\ChatFrame\UI-ChatIcon-ScrollDown-*`（up 箭头 TexCoord 垂直翻转），24×24。
- `DFUI.SkinScrollbar`：隐藏原生轨道 Top/Bottom/Middle，新建近黑轨道背景 + 暖棕边框，滑块改 `WHITE8X8` + 青铜 VertexColor（宽 8）。
- `DFUI.SkinDropDown`：隐藏 vanilla Left/Middle/Right，套暗色圆角背景框。
- `DFUI.SkinPageButton`：翻页箭头复位亮金本色（去青铜着色）。
- 批量目标：`scrollbarTargets`（任务日志/对话/NPC/公会信息/频道/训练师/邮件/帮助/团队/专业附魔）+ `dropdownTargets` + `pageButtonTargets`（商人 32px、邮件 24px）。
- 角色面板技能/声望滚动条与社交好友/公会滚动条**不接管**，保留 vanilla 原生亮金箭头（由 character.lua / social.lua 各自处理）。
- 触发：`PLAYER_ENTERING_WORLD` 延迟 0.5s + `ADDON_LOADED` 延迟 0.2s 两路 `ApplyAll()`。

## 六、补充已完成（计入第一节 19 个）

以下面板继 Phase 1~3 之后陆续完成，已计入第一节面板总数。源码均在 `modules/panels/` 并由 `Dragonflight-Fix.toc` 加载。

| 面板 | 文件 | 状态 | 说明 |
|------|------|------|------|
| **法术书** | `spellbook.lua` | ✅ 已完成 | 全重写，详见 `docs/spellbook-ui-design.md` |
| **宏编辑器** | `macro.lua` | ✅ 已完成 | 18 个宏按钮美化 + 内边框 |
| **按键绑定** | `keybinding.lua` | ✅ 已完成 | frameStyle 2 + 内边框 |
| **观察面板** | `inspect.lua` | ✅ 已完成 | 内边框 + 居中 |
| **读信面板** | `openmail.lua` | ✅ 已完成 | frameStyle 2 + 内边框 |

### 社交「查找(Who)」全自制重写（social.lua）

vanilla 寄生方案（行挂 `WhoListScrollFrame` 这一 FauxScrollFrame）会在结果 ≤17 时被 `FauxScrollFrame_Update` 连带 `Hide()` → 具名搜索列表全灭。已改为完全自制（自己查、自己显示，用户已认可）：

- 行 parent 改挂 `whoInset`（`CreateRetailInset` 创建），脱离 vanilla 滚动框，不再被连带隐藏。
- 滚动偏移自管：upvalue `whoOffset`，滚轮 `onWheel` 自增减后调 `refreshWhoRows`。
- 自建搜索框 `DFUI_WhoSearchBox`（parent=`whoInset`）替代 vanilla `WhoFrameEditBox`（后者改 `:Hide()`）。
- 底部三操作按钮用 `DFUI.CreateActionButton` 工厂重建。
- 客户端防抖 `dfuiTryWho(text)`：`GetTime()-dfuiLastWho < DFUI_WHO_CD`（默认 5s，`/script DFUI_WHO_CD=N` 可调）则拦下不发，避免连点 `SendWho` 重置 Turtle 服务器 who 节流。
- 列头/上下箭头/`WhoFrameTotals` 重锚到 `whoInset`，vanilla `WhoFrame` 透明保活作数据载体。
- 留尾：好友/公会列表仍寄生 `FriendsFrameFriendsScrollFrame`/`GuildListScrollFrame`，同 FauxScrollFrame-Hide 隐患未暴露，可按 who 模板一致化（待游戏内实证）。

## 七、未实施的面板

| 面板 | 复杂度 | 说明 |
|------|--------|------|
| WorldMapFrame（世界地图） | 未实施 | Map 模块已有部分实现，详见 `docs/worldmap-panel-design.md` |
| GameMenu（游戏菜单） | — | Fix 已有 menu.lua |
| TalentFrame（天赋） | — | Fix 已有实现（含天赋规划） |
| LootFrame（拾取） | — | Fix 已有实现，详见 `docs/loot-module-progress.md` |
| AuctionFrame（拍卖行） | 高 | **TODO**（2026-06-12 用户确认列待办）：大型多 Tab（浏览/竞拍/拍卖）+ 大表格，结构最复杂、工作量最大，后续单独实施 |

## 八、纹理素材

### 从 D3 复制的纹理（`media/tex/`）

```
interface/
  UI-Background-Rock.blp       ← 岩石背景
  UIFrameMetal2x.blp            ← 金属角
  UIFrameMetal2x2.blp           ← 金属角（备用）
  UIFrameMetalHorizontal2x.BLP  ← 水平边框
  UIFrameMetalHorizontal2x2.blp
  UIFrameMetalVertical2x.BLP    ← 垂直边框
  uiframetabs.blp               ← Tab 标签页
  redbutton2x.BLP               ← 红色按钮

panels/
  spellbook_top_wood.blp        ← 木纹顶部
  questlog_left_bg.blp          ← 任务日志左页
  questlog_right_bg.blp         ← 任务日志右页
  spellbook_bookmark.blp        ← 书签装饰
```

## 九、修改的配置文件

| 文件 | 修改内容 |
|------|---------|
| `Dragonflight-Fix.toc` | `modules\panels\*.lua` 共 21 个文件已加入加载顺序（含工厂 paperdoll、全局换肤 scrollbar、任务经验 questlog_xp） |
| `modules/gui/elem.lua` | moduleMapping 添加面板模块（待实证：具体条数以源码为准） |
| `modules/ui/ui.lua` | 删除旧面板代码 + 暗色模式回调，保留 SpellBook 覆盖 |

## 十、2026-06-13 接任务/闲聊重做 + 4 个 NPC 面板新增

### 接任务(QuestFrame)/闲聊(GossipFrame) 重做
旧「木纹+局部羊皮纸」风格推翻，照任务日志(questlog.lua)统一为青铜框风格，抽共享 helper `modules/panels/questskin.lua`：
- `DFUI.SkinQuestStyleFrame(frame, opts)` → 返回 customBg：`CreatePaperDollFrame`(青铜框+岩石底) + 单张羊皮纸(`questlog_right_bg.blp`，`SetTexCoord(0,1,0,0.70)` 裁掉图下~30%黑边) + `CreateRetailInset` 凹陷槽 + 头像照 merchant(青铜框当圆环、不加独立金环) + NPC名字金色居中 + `CreateRedButton` 红关闭。
- `DFUI.AttachMinimalScrolls(ownerFrame, specs)`：照 questlog 详情页范式接管普通 ScrollFrame 的 minimal 滚动条（箭头+滑块**常显**，range=0 时滑块占满/箭头变暗），含 `_dfMinimalScrolls` 守护防 reload 累积。
- `questframe.lua`：接管 4 个详情 ScrollFrame + 6 按钮重定位（锚 customBg + `SetFrameLevel(+20)` 防被奖励/任务文字盖 + hook 各 panel OnShow 在 vanilla 重设 Decline 锚后重定位，`_dfBtnHooked` 守护）+ 物品 hover 极简隐藏。
- `gossip.lua`：接管 GossipGreetingScrollFrame + 告别按钮重定位。

### 4 个 NPC 面板新增（照 merchant 范式，frame 名取自 pfUI skins/blizzard/，1.12 验证）
| 文件 | 面板 | 保留的特殊内容 |
|---|---|---|
| `taxi.lua` | 飞行管理员 TaxiFrame | 航点地图/航点/连线 ✅；**共享 SkinQuestStyleFrame** 工厂；头像 ❌ **未解决**（盲改 5+ 轮失败，详见 `panel-known-issues.md §六`，下次先要截图） |
| `petition.lua` | 请愿签名 PetitionFrame | 签名列表 + Sign/Cancel/Rename/Request 按钮 |
| `guild_registrar.lua` | 公会注册 GuildRegistrarFrame | 公会名输入框/费用标签/按钮（双子框 +GreetingFrame） |
| `tabard.lua` | 战袍设计 TabardFrame | 3D模型 TabardModel + 颜色器 Customization1..5 |

基础换皮（青铜外框 + 红关闭 + 标题 + 头像），内部功能控件保留 vanilla 位置。**待游戏内实测调**（petition/guild_registrar/tabard 适用）：① portrait 存在性（无则改 frameStyle=2 免头像孔露岩石）② customBg 锚点是否包住固定尺寸内容（战袍模型等）③ 底部按钮是否掉出框外。隐藏纹理时跳过 portrait 避免误隐。

> **taxi.lua 已对齐工厂（2026-06-13）**：原手搓平行实现已废除，改为复用 `SkinQuestStyleFrame`。工厂新增 4 个向后兼容选项 `hideMatch`/`skipParchment`/`insetLevelOffset`/`portraitUnit`（taxi 传 `"Taxi"`/`true`/`8`/`"player"`），缺省值保证 quest/gossip **逐字节零回归**；另把 `nameText:SetTextColor` 判空收进工厂（兜底 TaxiMerchant）。**收益**：自动获得 `_dfQuestSkinned` 幂等守护 → 修掉原"无守护"版每次 `TAXIMAP_OPENED` 重建 frame + 叠 OnShow hook 的双重泄漏；红关闭 level 随工厂统一 +5。taxi 侧仅保留显式 `TaxiCloseButton:Hide()`（真名非 `TaxiFrameCloseButton`，工厂推导拿不到）。待实测项①③对 taxi 已落定（frameStyle=1+玩家头像、无底部按钮选点自动飞），仅②地图区锚点覆盖仍需游戏内目测。

> **⚠️ taxi 血泪教训：守护是"地图保命机制"，不只是防泄漏（2026-06-13）**。曾为 /reload 调参在 SkinTaxi 开头加"清 `_dfQuestSkinned`、每次开飞行重跑工厂"的旁路 → **航点地图内容消失**。根因：`_dfQuestSkinned` 守护保证整套换皮**只在 `ADDON_LOADED`（地图绘制前）跑一次**；旁路让换皮在每次 `TAXIMAP_OPENED`（地图绘制后）重跑，破坏已画好的地图（pfUI/DragonflightUI 同样只 skin 一次）。**正确做法**：换皮严守 set-once；装饰性可调项（头像尺寸/位置/层级、inset 锚点、金属角层级）抽进 `ApplyTaxiTweaks(bg)`——**只动自家 frame（`customBg.portrait`/`getglobal("DFUI_TaxiBgInset")`/`customBg.edges`），绝不碰 TaxiFrame region/地图**，每次 SkinTaxi（含守护早返回/`/reload`）安全重应用 → 既能 /reload 调参又不伤地图。tunable 数值在 taxi 顶部常量单一来源；工厂只留结构性选项（hideMatch/skipParchment/insetLevelOffset/portraitUnit），几何微调不进工厂。头像"浮在金属上"用 `bg.portrait:SetDrawLayer("BORDER")` + 金属角 `edges[1]:SetDrawLayer("OVERLAY",7)` 压到环下。

### 待办
- 拍卖行 AuctionFrame：见 §七（大型多 Tab，工作量最大，单独实施）
