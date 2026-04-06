# 面板美化实施进度

> 最后更新：2026-04-06（竞技场修复进行中）

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

## 三、角色面板细节优化（进行中）

### 已完成

| 元素 | 状态 | 说明 |
|------|------|------|
| **技能 Tab "全部"按钮** | ✅ 完成 | `SkillFrameExpandButtonFrame` DisableDrawLayer + `SkillFrameCollapseAllButton` 隐藏纹理 |
| **称号下拉框** | ✅ 完成 | `CharacterTitleDropDown` + Left/Middle/Right 隐藏纹理（Turtle WoW 自定义框架） |
| **荣誉 Tab 按钮** | ✅ 完成 | `HonorFrameTab1`/`Tab2` 暴雪纹理已隐藏 + HookScript 防止 Tab 切换后纹理恢复 |
| **荣誉系统性能优化** | ✅ 完成 | Region 缓存系统：首次扫描记录引用，后续直接 Hide()；统一 RefreshHonorSkin 入口消除冗余调用 |
| **ArenaFrame OnShow/OnHide Hook** | ✅ 完成 | 直接 Hook ArenaFrame 显隐事件触发美化，Tab 选中态用 ArenaFrame:IsShown() 作唯一判据 |

### 待解决

| 问题 | 状态 | 说明 |
|------|------|------|
| **竞技场页面美化** | 🔧 待验证 | ArenaFrame 已定位，子 Tab + 团队框架美化方案已实现 + 缓存优化已完成，待游戏内验证 |

#### 竞技场页面排查记录

1. HonorFrame 有 17 个子框架，包括 `HonorFrameTab1`（荣誉）和 `HonorFrameTab2`（竞技场）
2. Tab2 是 Button 类型，有 OnClick；Tab1 无 OnClick（默认选中）
3. 点击 Tab2 后所有 17 个子框架仍然 `show=1`
4. HonorFrame 可见纹理只有 1 个（`UI-PVP-Alliance` 阵营图标）

#### Dump 结果（已完成）

通过 `/script` dump `CharacterFrame:GetChildren()` 得到 15 个子框架：

| # | 框架名 | 状态 |
|---|--------|------|
| 1 | CharacterNameFrame | show |
| 2 | CharacterFrameCloseButton | hide |
| 3-7 | CharacterFrameTab1-5 | hide |
| 8 | PaperDollFrame | show |
| 9 | PetPaperDollFrame | hide |
| 10 | SkillFrame | hide |
| 11 | ReputationFrame | hide |
| 12 | HonorFrame | hide |
| **13** | **ArenaFrame** | **hide** |
| 14 | DFUI_CharacterBg | show |
| 15 | unnamed | hide |

**关键发现**：竞技场内容框架是 `ArenaFrame`，是 CharacterFrame 的直接子框架（不是 HonorFrame 的子框架）。之前全局搜索 "Arena" 未匹配是因为搜索范围限制。

#### 已修复的问题

| 问题 | 原因 | 修复方案 |
|------|------|---------|
| **暴雪原生背景残留** | 初始纹理隐藏只匹配 `UI-Character-`/`PaperDoll`，不匹配 PVP 纹理 | `StripFrameRecursive(HonorFrame)` + `SkinArenaFrame()` 递归清除 |
| **子 Tab 超出框体** | 自定义按钮锚定到 `customBg TOPLEFT(60,-60)` 与 HonorFrame 内容重叠 | 改为原地美化原生 `HonorFrameTab1`/`Tab2`（`SetBackdrop` + 覆盖 `SetHeight`） |
| **团队框架内容消失** | `DisableDrawLayer("BACKGROUND")` 后在同层创建纹理 + 对子框架 `HideBlizzardTextures` 过于激进 | 改用 `SetBackdrop` 美化团队框架，不再 `DisableDrawLayer`，不再清除子框架 |
| **选中 Tab 凸起** | 暴雪 Tab 选中时改变高度 | 覆盖 `tab.SetHeight = function() end` |

#### 当前实现方案（优化后）

```
缓存系统（StripHonorSystem）：
  - 首次调用：BuildRegionCache 递归扫描 HonorFrame/ArenaFrame/Tab 的所有纹理
    - HonorFrame: depth=2（完整递归）
    - ArenaFrame: depth=1（只到子框架，保护团队内容）
    - Tab1/Tab2: depth=2
  - 后续调用：HideAllCachedRegions 直接遍历缓存引用 Hide()，跳过字符串匹配
  - SkinArenaTeams 用 _dfSkinned 标记只执行一次

统一入口（RefreshHonorSkin）：
  - = StripHonorSystem() + UpdateHonorSubTabs()
  - 所有 Hook 共用：Tab1 OnClick / Tab2 OnClick / HonorFrame OnShow / ArenaFrame OnShow / ArenaFrame OnHide

Tab 选中态（UpdateHonorSubTabs）：
  - 唯一判据：ArenaFrame:IsShown()
  - 不再依赖 PanelTemplates_GetSelectedTab 或 HonorFrame.selectedTab
```

## 四、未实施的面板

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
