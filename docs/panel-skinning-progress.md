# 面板美化实施进度

> 最后更新：2026-04-06（角色面板细节美化完成）

## 一、已完成的面板（12 个）

### Phase 1：基础设施 + 高频面板

| 面板 | 文件 | 状态 | 说明 |
|------|------|------|------|
| **工厂函数** | `modules/panels/paperdoll.lua` | ✅ 完成 | CreatePaperDollFrame + CreateRedButton + Tab 系统 |
| **角色面板** | `modules/panels/character.lua` | ✅ 完成 | 5 Tab + 品质边框 + 宠物 Tab 动态 |
| **银行** | `modules/panels/bank.lua` | ✅ 完成 | 24+6 物品栏 DF 边框 |
| **商人** | `modules/panels/merchant.lua` | ✅ 完成 | 2 Tab（商人/回购） |
| **任务对话** | `modules/panels/questframe.lua` | ✅ 完成 | 木纹+右侧背景 |
| **NPC 对话** | `modules/panels/gossip.lua` | ✅ 完成 | 木纹+书签 |
| **任务日志** | `modules/panels/questlog.lua` | ✅ 完成 | 木纹+书签+左右背景 |
| **社交** | `modules/panels/social.lua` | ✅ 完成 | 4 Tab + Guild 动态禁用 |

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

## 四、已尝试但撤回的方案

| 方案 | 原因 | 教训 |
|------|------|------|
| **滚动条箭头统一** | page_up/down_*.tga 纹理直接替换暴雪滚动条箭头，效果极差 | 动作条翻页箭头纹理不适合用于滚动条小按钮，尺寸和风格完全不同。需要专门为滚动条设计的箭头纹理或方案 |

### 待解决：滚动条/箭头统一

面板内的滚动条箭头（技能、声望、任务日志、社交等）仍为暴雪默认风格，与 DF 金属面板不搭配。需要重新设计方案：
- 不能直接复用 page_up/down 纹理（太大、风格不对）
- 可能需要参考 pfUI 的 SkinScrollbar/SkinArrowButton 做法（创建小方块+简洁箭头）
- 或者寻找/制作专用的滚动条箭头纹理

## 五、未实施的面板

| 面板 | 复杂度 | 说明 |
|------|--------|------|
| SpellBookFrame（法术书） | 高 | D3 全重写 535 行；ModernSpellBook 功能更全。详见 `docs/spellbook-comparison.md` |
| MacroFrame（宏编辑器） | 中 | 18 个宏按钮美化 |
| KeyBindingFrame（按键绑定） | 低 | 标准面板 |
| WorldMapFrame（世界地图） | 高 | Map 模块已有部分实现 |
| OpenMailFrame（读信面板） | 低 | MailFrame 的子面板 |
| GameMenu（游戏菜单） | — | Fix 已有 menu.lua |
| TalentFrame（天赋） | — | Fix 已有 1077 行实现 |
| LootFrame（拾取） | — | Fix 已有 865 行实现 |

## 五、纹理素材

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

## 六、修改的配置文件

| 文件 | 修改内容 |
|------|---------|
| `Dragonflight-Fix.toc` | 添加 13 个面板文件到加载顺序 |
| `modules/gui/elem.lua` | moduleMapping 添加 12 个面板模块 |
| `modules/ui/ui.lua` | 删除旧面板代码 + 暗色模式回调，保留 SpellBook 覆盖 |
