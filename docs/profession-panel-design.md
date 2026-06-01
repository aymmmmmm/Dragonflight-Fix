# 专业技能面板 UI 重构设计

> 初稿：2026-04-13 | 现状核对：2026-06-01 | 文件：`modules/panels/tradeskill.lua`（2080 行）
>
> 注：本文初稿为预实现设计稿，最终实现已大幅偏离（书本风格→DF retail 专业背景画风格）。
> 本次按当前代码逐处校正了框架尺寸、配色、纹理清单等论断。

## 一、设计目标

1. **透明化保活原生面板** — 不 KillFrame，原生面板 `SetAlpha(0)+EnableMouse(false)+移出视野` 保持 API 连接（`HideNativeFrame`，L391），自建面板覆盖其上
2. **统一 TradeSkill + Craft** — 一个面板处理所有专业，通过 Tab 切换
3. **DF retail 专业风格** — `CreatePaperDollFrame` 金属外框 + 右侧专业背景画（DF retail 10.1 `professions.blp` atlas 切片），非书本/羊皮纸
4. **功能完整** — 保留所有原生功能：配方列表/详情/材料/制作/搜索/过滤/收藏

## 二、整体框架

```
1069 x 658 px，SetScale 0.85（LAYOUT.PANEL_SCALE），可拖动；锚 UIParent TOPLEFT (30, -104)
┌─[职业图标 52x52]──── 专业名 ──────────────────────[X]─┐  ← CreatePaperDollFrame 金属外框
│  ┌──────── 熟练度条 rankBar (panel 内宽, 高18) ──────┐ │  ← (60,-38)~(-60,-38)
│  │  ██████████████░░░░░░░  专家  225 / 300          │ │
│  └────────────────────────────────────────────────────┘ │
│  ┌──────────────┬───────────────────────────────────┐   │
│  │ leftColumn   │  rightColumn (宽 763)              │   │
│  │  宽 274      │   底图=专业背景画 detailBg          │   │
│  │  配方列表    │   detailFrame=配方详情(浮于背景画上)│   │
│  │              │                                     │   │
│  │              │                                     │   │
│  └──────────────┴───────────────────────────────────┘   │
│ [搜索框][☑有材料](左栏顶部)   [-][数量][+][全部][制作][取消](panel 底部右)│
├─[锻造]─[裁缝]─[烹饪]─[急救]─[附魔]─[宠物训练]───────┤  ← Tab 锚 panel BOTTOMLEFT (8,-30)
└──────────────────────────────────────────────────────┘
```

注：左侧 52x52 是**玩家职业图标**（`UI-Classes-Circles` atlas），不随专业切换（L495-504、L1912）。
搜索框 + "有材料" 复选框在 leftColumn 顶部同行（L1003、L1033），非底部；底部仅操作按钮。

## 三、详细布局

### A. 顶部区域

```
┌─[职业图标 52x52]──────── 专业名 ────────────────────[X 关闭]─┐
│  TOPLEFT (0,3)          TOP (0,-4)              TOPRIGHT (-1,-2) │
│                                                                  │
│  ┌─ rankBar ──────────────────────────────────────────────────┐  │
│  │  TOPLEFT (60, -38)                   TOPRIGHT (-60, -38)   │  │
│  │  高度 18px | CreateInsetBackdrop 暗底 + StatusBar 蓝色fill │  │
│  │   fill 纹理 rankbar_fill_blue.tga, SetStatusBarColor(1,1,1,0.6) │  │
│  │  "专家  225 / 300"  rankText 白色 (1,1,1) 居中             │  │
│  └────────────────────────────────────────────────────────────┘  │
```

注：标题 title 默认文本 "专业技能"，打开后改为显示名（L1059）；rankName 档位为 初级/熟练/专家/大师（L1067-1071）。

### B. 左栏 — 配方列表 (leftColumn 宽 274)

```
┌─────────────────────────────────────┐
│ [±] 全部展开/折叠                    │
│ ┌─────────────────────────────────┐ │
│ │ ▸ 武器 ─────────────────────── │ │  ← 分类标题 (可折叠)
│ │   · 铜斧             ████ (灰) │ │  ← 配方行: 名称 + 难度颜色
│ │   · 铜剑             ████ (绿) │ │
│ │   · 青铜阔剑         ████ (黄) │ │
│ │   · 秘银重斧         ████ (橙) │ │
│ │ ▸ 护甲 ─────────────────────── │ │
│ │   · 铜链甲           ████ (灰) │ │
│ │   · 铜腰带           ████ (绿) │ │
│ │                                 │ │
│ │                                 │ │
│ │                          ▲      │ │
│ │                       [滚动条]   │ │
│ │                          ▼      │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘

配方行结构 (每行 20px 高, 行间距 -3):
┌──────────────────────────────────────┐
│ [难度icon] [产物图标20x20] 配方名称 [☆收藏] │
└──────────────────────────────────────┘

难度颜色 (DIFFICULTY_COLORS, L344-353; 难度图标在 tradeskill 模式用 DF atlas icon-skill-high/medium/low):
  - 橙色 optimal  (1.00, 0.50, 0.25): 最高收益
  - 金黄 medium   (1.00, 0.82, 0.00): 可能提升
  - 亮绿 easy     (0.40, 0.90, 0.40): 偶尔提升
  - 银灰 trivial  (0.75, 0.75, 0.75): 不再提升
  - header 暖金   (0.98, 0.91, 0.58): 分组标题
（注：1.12 未实现"分类筛选/装备栏位"下拉，原稿该行已删；过滤仅 "有材料" 复选框 + 搜索框）
```

### C. 右栏 — 配方详情 (rightColumn 宽 763, 底图为专业背景画 detailBg)

```
detailFrame 浮于专业背景画上 (内缩 20/18px); 主图标 47x47 at (28,-33)
┌─────────────────────────────────────┐
│                                     │
│  [物品图标 36x36]  物品名称          │  ← 品质颜色文字
│   actives_border                    │
│                                     │
│  冷却时间: 1天                       │  ← 浅棕色 (若有)
│  需求: 铁匠锤                        │  ← 浅棕色 (若有)
│  花费: 15 训练点                     │  ← 浅棕色 (宠物训练专用)
│                                     │
│  描述文本 (若有)                     │  ← 浅棕色
│  ──────────────────────────────────  │
│  材料:                               │  ← 浅暖金标签 reagentLabel (0.98,0.91,0.58), L802
│  ┌──────────────┐ ┌──────────────┐  │
│  │ [🟫] 铜锭    │ │ [🟫] 弱效   │  │  ← 材料格: 图标+名称+数量
│  │      (4/4) ✓ │ │   助熔剂    │  │     足够=白色，不足=红色
│  └──────────────┘ │      (0/1) ✗ │  │
│  ┌──────────────┐ └──────────────┘  │
│  │ [🟫] 粗糙的  │                   │
│  │   磨刀石     │                   │
│  │      (2/2) ✓ │                   │
│  └──────────────┘                   │
│                                     │
│           [-] [数量] [+]            │  ← 数量控制 (TradeSkill only)
│       [全部制作]  [制作]  [取消]     │  ← 操作按钮
└─────────────────────────────────────┘

材料格结构 (slot 180x50, iconFrame 39/40x39/40, 3 列网格 col*200 行 -8-row*65; L805-851、L1564-1568):
┌───────────────────────┐
│ [图标   ]  材料名称    │  ← 足够=白(0.95,0.90,0.78) / 不足=红(1.0,0.3,0.3)
│ [40x40  ]  (2/4)      │  ← (已有/需要), border 按品质切 slot_*.tga
│ [品质边框]            │
└───────────────────────┘
```

### D. 搜索/过滤 (左栏顶部) + 底部操作区

```
搜索框 searchBg 140x22 锚 leftColumn TOPLEFT (10,-15); "有材料" 复选框在其右 (RIGHT +14)
（无 "可学" 复选框，原稿该项未实现）

panel 底部右侧操作按钮 (createBtn 锚 panel BOTTOMRIGHT (-36,16)，向左链锚):
│  [训练点](宠物训练)  [-][数量框][+] [全部] [取消] [制作]        │
│  数量控制(-/+/输入框/全部) 仅 TradeSkill 模式显示 (L1580-1584)   │
│  制作按钮文字: 宠物训练="学习"(隐藏取消)，其他="制作"            │
├─[锻造]─[裁缝]─[烹饪]─[急救]─[附魔]─[宠物训练]─────────────────-┤
│  Tab 系统: AcquireTab() 复用池, 锚 panel BOTTOMLEFT (8,-30)      │
│  扫描法术书综合页 ScanSpellbookForProfessions() 发现所有专业     │
│  点击 Tab → CastSpell(spellIndex, BOOKTYPE_SPELL) (L1865)        │
└──────────────────────────────────────────────────────────────────┘
```

## 四、配色方案

DF retail 三档色值分级（深色专业背景画上, 文字多加 OUTLINE 保可读）:

| 元素 | RGB | 说明 |
|------|-----|------|
| 配方名称 (列表) | 难度颜色 | 橙/金黄/亮绿/银灰 (见 §B 难度色) |
| 分类标题 header | `(0.98, 0.91, 0.58)` | 暖金 (DIFFICULTY_COLORS.header) |
| 标题 title | `(1.00, 0.82, 0.00)` | 纯金 (16pt) |
| 详情产物名 detailName | `(1.00, 0.82, 0.00)` | 纯金 (18pt) |
| 副信息 subText/Points/reagentLabel | `(0.98, 0.91, 0.58)` | 暖金 |
| 冷却 cooldown/材料正文 | `(0.95, 0.90, 0.80)` | 暖象牙 |
| 描述 detailDesc | `(0.90, 0.86, 0.72)` | 退色暖象牙 |
| 熟练度条文字 rankText | `(1, 1, 1)` | 白色 |
| 材料不足 | `(1.00, 0.30, 0.30)` | 红色 |

## 五、纹理清单

DF retail 专业素材（`media/tex/panels/df/professions/`，全 retail BLP 解码 TGA，非 spellbook）:

| 纹理 | 用途 |
|------|------|
| `atlas_main.tga` (2048×1024, retail professions.blp) | recipe-active/hover overlay、header 3-slice、难度图标 icon-skill-* |
| `bg_<专业>.tga` (13 张 = 12 专业 + bg_default, retail professionbackgroundart) | 右栏专业背景画 detailBg, PROF_BG_KEY 动态加载；初始与 fallback 用 bg_default (L486 初始 / L1898 按 bgKey 切换, bgKey 未命中回落 "default" L1897) |
| `slot_blue/green/neutral/epic/legendary.tga` | 主图标 + 材料格品质边框 (QUALITY_TGA) |
| `rankbar_fill_blue.tga` (256×16, retail uiframebars) | 熟练度 StatusBar fill |
| `uiframe_corner/v/h.tga` (retail InsetFrameTemplate) | CreateInsetBackdrop 凹陷内框 8 元素 |
| `scroll_thumb_*/track_*.tga`、`uiactionbar_atlas.tga` | CreateMinimalScrollbar 滚动条素材（**当前未实例化**, L560 注释滚动条待重做; 滚轮可用：listFrame:EnableMouseWheel(true) L1763 + OnMouseWheel handler L1764。注：L560 源码注释里写的 "L1727" 是过期行号） |

注：外层金属框 `CreatePaperDollFrame`(UIFrameMetal2x.blp) + 关闭按钮 `CreateRedButton` 为共享 helper, 不在本面板范围。

## 六、Tab 系统

扫描法术书发现专业，复用池生成 Tab:

```
首次 OpenProfession 调 ScanSpellbookForProfessions(): 扫综合页(GetSpellTabInfo(1)),
  用 PROFESSION_SPELLS 白名单匹配专业法术名(中英文) → knownProfessions (含 spellIndex/texture)
TRADE_SKILL_SHOW → currentMode="tradeskill", 当前专业名 GetTradeSkillLine()
CRAFT_SHOW       → currentMode="craft", 当前专业名 GetCraftName() (附魔/急救/熔炼/宠物训练等)

Tab 排列: 按 knownProfessions 顺序 AcquireTab(), 锚 panel BOTTOMLEFT (8,-30)
点击 Tab → 已选中则跳过; 否则 CastSpell(spellIndex, BOOKTYPE_SPELL) 触发原生 SHOW 事件
当前专业 Tab 高亮 (SetSelected)
PROF_API_TO_SPELL: 采矿→熔炼映射 (L403); PROF_DISPLAY_NAME: 训练野兽→宠物技能 (L408)
```

## 七、TradeSkill vs Craft API 差异

| API | TradeSkill | Craft |
|-----|-----------|-------|
| 获取配方数 | `GetNumTradeSkills()` | `GetNumCrafts()` |
| 获取配方信息 | `GetTradeSkillInfo(i)` | `GetCraftInfo(i)` |
| 获取材料数 | `GetTradeSkillNumReagents(i)` | `GetCraftNumReagents(i)` |
| 获取材料信息 | `GetTradeSkillReagentInfo(i,j)` | `GetCraftReagentInfo(i,j)` |
| 制作 | `DoTradeSkill(i, num)` | `DoCraft(i)` |
| 冷却 | `GetTradeSkillCooldown(i)` | `GetCraftCooldown(i)` |
| 描述 | `GetTradeSkillDescription(i)` | `GetCraftDescription(i)` |
| 数量控制 | 有 (Decrement/Increment/InputBox/CreateAll) | 无 (单次制作) |
| 训练点数 | 无 | `GetPetTrainingPoints()` |
| 展开事件 | `TRADE_SKILL_SHOW` / `TRADE_SKILL_CLOSE` | `CRAFT_SHOW` / `CRAFT_CLOSE` |

## 八、数据流

```
用户打开专业 (快捷键/图标)
  ↓
原生事件 TRADE_SKILL_SHOW 或 CRAFT_SHOW
  ↓
OnEvent 处理器 (OpenProfession):
  1. 原生面板已透明化保活 (ADDON_LOADED hook OnShow → HideNativeFrame)
  2. 识别当前专业类型 (currentMode = tradeskill / craft)
  3. 获取专业名/熟练度 (UpdateRankBar)，切右栏专业背景画 (detailBg, PROF_BG_KEY)
  4. 首次扫描法术书 + 创建/更新 Tab 高亮
  5. 收集配方数据 → recipeCache[] (RebuildRecipeData: 扫描+过滤+图标预取)
  6. 渲染左栏配方列表 (RenderRecipeButtons, 仅读缓存)
  7. 自动选中第一个非 header → 渲染右栏详情 (UpdateDetail)
  ↓
用户交互:
  - 点击配方 → 更新右页详情
  - 点击 Tab → CastSpell 切换专业 → 新的 SHOW 事件
  - 搜索/过滤 → 重新筛选 filteredRecipes → 刷新列表
  - 制作 → DoTradeSkill / DoCraft
  - 关闭 → Hide 面板
```

## 九、验证计划

1. 打开任意 TradeSkill 专业 → 新面板显示，原生面板隐藏
2. 打开 CraftFrame 专业 (附魔/宠物训练) → 同一面板显示，Tab 切换
3. 配方列表正确显示分类、折叠、难度颜色
4. 选中配方 → 右页显示物品图标、名称、材料、需求
5. 制作按钮功能正常 (单个制作、批量制作、全部制作)
6. 搜索框过滤配方列表
7. 复选框过滤 (有材料/可学) 正常
8. Tab 切换专业正常
9. 宠物训练显示训练点数
10. 熟练度条正确显示等级/进度
11. ESC 关闭、拖动、音效正常
