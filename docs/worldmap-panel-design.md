# 世界地图（WorldMapFrame）面板美化方案 & 实施记录

> 状态：**设计阶段**（首次实施失败已回退，待重新设计）
> 最后更新：2026-04-17

---

## 一、Context

世界地图是剩余未美化面板中使用频率最高的之一，但它的情况非常特殊：**已有 6 个不同模块 hook 了 WorldMapFrame**。DFUI 的 map 模块目前只处理小地图（Minimap），完全没有触碰世界地图。本方案需要在不破坏现有功能链的前提下，给世界地图加上 DFUI 金属边框美化。

---

## 二、当前世界地图的修改链（按执行顺序）

| 顺序 | 来源 | 做了什么 |
|------|------|----------|
| 1 | ShaguPlates turtle-wow.lua | 调用 `WorldMapFrame_Maximize()` 后 stub 掉 Minimize/Maximize 函数，隐藏标题和最大化/最小化按钮 |
| 2 | ShaguTweaks turtle-wow.lua | Hook `WorldMapFrame_Maximize`，重新应用窗口模式，修正标题位置 |
| 3 | ShaguTweaks worldmap-window.lua | `PLAYER_ENTERING_WORLD` 时：0.85 缩放、可拖动、Ctrl+滚轮缩放、Shift+滚轮透明度、隐藏 BlackoutWorld、居中定位 |
| 4 | ShaguTweaks dark-ui-elements.lua | `DarkenFrame(WorldMapFrame)` 递归暗化所有纹理 |
| 5 | ShaguTweaks worldmap-coordinates.lua | WorldMapButton 底部添加光标坐标+玩家坐标 |
| 6 | ShaguTweaks worldmap-colors.lua | 队伍/团队成员职业颜色圆圈 |
| 7 | ShaguTweaks-extras worldmap-reveal.lua | Hook `WorldMapFrame_Update`，覆盖未探索区域纹理 + 揭示复选框 |
| 8 | pfQuest map.lua + route.lua | 任务图钉、路线绘制、pfQuestMapDropdown |

**DFUI 完全不在此链中** — 这是我们要填补的空白。

---

## 三、设计方案：Overlay 覆盖法

### 3.1 为什么不能全量重建（KillFrame）

- pfQuest 的 100+ 个图钉按钮直接 parent 在 WorldMapButton 上
- worldmap-reveal 的纹理 parent 在 WorldMapDetailFrame 上
- worldmap-coordinates 的框体 parent 在 WorldMapButton 上
- ShaguTweaks 已 hook 了 OnShow/OnMouseWheel/OnMouseDown/OnMouseUp
- ShaguPlates 已 stub 了 WorldMapFrame_Minimize/Maximize

全量重建会 **打断所有这些集成**。

### 3.2 采用方案

**在 WorldMapFrame 上叠加一个 DFUI 金属边框框体**，隐藏暴雪原生边框装饰，保留所有功能性子框体原封不动。

### 3.3 视觉主题：导航桌/战术台

世界地图 **不适合** 法术书/专业技能的"羊皮纸双页"美学（地图本身是彩色地形，不是文字），改用：
- **金属边框**：`CreatePaperDollFrame(frameStyle=2)`（无肖像圈）
- **岩石底纹**：仅在标题栏和底部坐标栏可见，地图区域被 WorldMapButton 自然遮盖
- **内凹边框**：`AddSubBorder()` 围绕 WorldMapButton，营造地图嵌在金属框内的视觉
- **无羊皮纸页、无书签、无木纹** — 这些是"书"的元素

---

## 四、框体结构

```
WorldMapFrame (原生，保持不变)
├── DFUI_WorldMapBg (新建, CreatePaperDollFrame frameStyle=2)
│   ├── 金属九宫格边框 (UIFrameMetal2x 四角+边条)
│   ├── 岩石底纹 (UI-Background-Rock.blp)
│   ├── 标题 "世界地图" (FRIZQT__ 13pt, 0.95/0.90/0.80)
│   ├── 关闭按钮 (CreateRedButton)
│   └── 地图内凹边框 (AddSubBorder 围绕 WorldMapButton)
│
├── WorldMapButton (不动! 所有叠加层依赖它)
│   ├── WorldMapDetailFrame (地图底图+揭示纹理)
│   ├── pfQuest 图钉和路线
│   ├── ShaguTweaks 坐标显示 (重新设置字体/颜色)
│   └── 揭示复选框 (保持位置)
│
├── WorldMapContinentDropDown (重定位 + SkinDropDown)
├── WorldMapZoneDropDown (重定位 + SkinDropDown)
├── WorldMapFrameAreaLabel (保留, 重设字体)
├── WorldMapFrameAreaDescription (保留)
│
├── WorldMapFrameMiniBorder* (全部 SetAlpha(0) 隐藏)
├── WorldMapFrameCloseButton (SetAlpha(0) + EnableMouse(false))
├── WorldMapFrameSizeUp/DownButton (隐藏)
└── WorldMapMagnifyingGlassButton (隐藏)
```

---

## 五、需要隐藏的元素

| 元素 | 方式 | 原因 |
|------|------|------|
| WorldMapFrameMiniBorderLeft/Right/Top/Bottom | `SetAlpha(0)` | 暴雪装饰边框，用金属边框替代 |
| WorldMapFrameCloseButton | `SetAlpha(0)` + `EnableMouse(false)` | 用 CreateRedButton 替代 |
| WorldMapFrameSizeUpButton | `Hide()` | 窗口模式不需要 |
| WorldMapFrameSizeDownButton | `Hide()` | 窗口模式不需要 |
| WorldMapMagnifyingGlassButton | `Hide()` | 视觉噪音 |
| WorldMapZoomOutButton | `Hide()` | 如存在则隐藏 |
| WorldMapFrameTitle | 已被 ShaguPlates 隐藏 | 不需要额外处理 |
| WorldMapFrameMaximize/MinimizeButton | 已被 ShaguPlates 隐藏 | 不需要额外处理 |

**注意**：用 `SetAlpha(0)` 而不是 `Hide()`，防止其他插件 `Show()` 后恢复可见。

---

## 六、需要保留并重新样式化的元素

### 6.1 下拉框
```lua
DFUI.SkinDropDown(WorldMapContinentDropDown)  -- 已有现成函数
DFUI.SkinDropDown(WorldMapZoneDropDown)
-- 重定位到 DFUI 标题栏区域
WorldMapContinentDropDown:ClearAllPoints()
WorldMapContinentDropDown:SetPoint("TOPLEFT", overlay, "TOPLEFT", 50, -5)
WorldMapZoneDropDown:ClearAllPoints()
WorldMapZoneDropDown:SetPoint("LEFT", WorldMapContinentDropDown, "RIGHT", -15, 0)
-- pfQuest 下拉框（如存在）
if pfQuestMapDropdown then DFUI.SkinDropDown(pfQuestMapDropdown) end
```

### 6.2 坐标显示（ShaguTweaks 创建的）
```lua
-- 重设字体和颜色，匹配 DFUI 风格
if WorldMapButton.coords and WorldMapButton.coords.text then
    WorldMapButton.coords.text:SetFont("Fonts\\FRIZQT__.TTF", 11)
    WorldMapButton.coords.text:SetTextColor(0.90, 0.85, 0.75)
end
if WorldMapButton.player and WorldMapButton.player.text then
    WorldMapButton.player.text:SetFont("Fonts\\FRIZQT__.TTF", 11)
    WorldMapButton.player.text:SetTextColor(0.90, 0.85, 0.75)
end
```

### 6.3 区域标签
```lua
WorldMapFrameAreaLabel:SetFont("Fonts\\FRIZQT__.TTF", 32, "OUTLINE")
```

---

## 七、关键技术问题

### 7.1 加载时序

**问题**：DFUI（Dragonflight-Fix）按字母顺序在 ShaguTweaks 之前加载（D < S）。

**方案**：延迟初始化
```lua
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    f:UnregisterEvent("PLAYER_ENTERING_WORLD")
    local elapsed = 0
    f:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed < 1.0 then return end
        f:SetScript("OnUpdate", nil)
        ApplyWorldMapSkin()
    end)
end)
```
✅ **验证通过**：延迟 1 秒的方案在实测中工作正常。

### 7.2 FrameLevel 层级管理

**原设计**：`overlay:SetFrameLevel(WorldMapFrame:GetFrameLevel())`（同级）

**实测发现**：同级时金属边框被 WorldMapButton（更高层级的子框体）遮挡。

**修正**：提升到 `WorldMapFrame:GetFrameLevel() + 10`
✅ **验证通过**：金属边框在实测中正确显示。

### 7.3 Ctrl+滚轮缩放兼容性

ShaguTweaks 通过 `WorldMapFrame:SetScale()` 改变缩放。DFUI overlay 作为 WorldMapFrame 的子框体会自动跟随缩放 — **无需特殊处理**。

### 7.4 兼容性保护

```lua
-- 与其他地图插件冲突检测（复用 ShaguTweaks 的同一套检查）
if Cartographer then return end
if METAMAP_TITLE then return end
```

---

## 八、尺寸计算

WorldMapButton 默认大小 ≈ 1002×668。ShaguTweaks 设置 WorldMapFrame 为 `WorldMapButton:GetWidth() + 15` × `WorldMapButton:GetHeight() + 55`，即 ≈ 1017×723。

DFUI overlay 需要包裹整个 WorldMapFrame 并留出金属边框空间：
```lua
-- 动态锚定到 WorldMapButton（最稳定的参考点）
overlay:SetPoint("TOPLEFT", WorldMapButton, "TOPLEFT", -30, 42)
overlay:SetPoint("BOTTOMRIGHT", WorldMapButton, "BOTTOMRIGHT", 30, -38)
```

**不使用固定宽高** — 用锚点自适应，这样 Ctrl+滚轮改变 scale 时 overlay 也能正确跟随。

---

## 九、禁止操作

1. **禁止 `KillFrame(WorldMapFrame)`** — 会摧毁整个地图子系统
2. **禁止 reparent `WorldMapButton`** — pfQuest/坐标/揭示全部依赖它的父子关系
3. **禁止 override `WorldMapFrame_Update`** — worldmap-reveal 已 hook，再叠 hook 风险高
4. **禁止修改 `WorldMapFrame` 尺寸** — ShaguTweaks 按 WorldMapButton 尺寸设置，坐标/图钉依赖
5. **禁止提升 FrameStrata 超过 MEDIUM** — 会遮挡 tooltip 和下拉菜单
6. **禁止使用羊皮纸/书签/木纹纹理** — 地图不是"书"，使用纯金属+岩石美学

---

## 十、关键文件

| 文件 | 用途 |
|------|------|
| `modules/panels/paperdoll.lua` | CreatePaperDollFrame(frameStyle=2) + CreateRedButton |
| `modules/panels/scrollbar.lua` | DFUI.SkinDropDown() |
| `core/tools.lua` | HookScript, AddSubBorder, CenterFrame |
| `modules/panels/character.lua` | **参考实现** — 同为 overlay 模式（隐藏暴雪纹理+叠加 PaperDollFrame） |
| `ShaguTweaks/mods/worldmap-window.lua` | 了解 OnShow 行为和缩放逻辑 |
| `Dragonflight-Fix.toc` | 添加 `modules\panels\worldmap.lua` |
| `modules/gui/elem.lua` | moduleMapping 添加 WorldMap |

---

## 十一、第一次实施记录（2026-04-17，已回退）

### 已尝试的实现
- `modules/panels/worldmap.lua` 创建（171 行）
- `Dragonflight-Fix.toc` 添加加载项
- `modules/gui/elem.lua` moduleMapping 添加 `["WorldMap"] = {11, 25}`

### 验证通过的部分
- ✅ 模块正确加载
- ✅ 延迟 1 秒初始化触发 `ApplySkin` 成功
- ✅ FrameLevel +10 让金属边框正确可见
- ✅ DFUI 金属框能正确叠加在 WorldMapFrame 之上

### 遇到的关键问题（导致回退）

**问题：暴雪原生 chrome 的隐藏边界找不到**

尝试过的两种策略都失败：

**策略 A — 保守隐藏**（按名称/纹理路径关键词匹配）：
```lua
if name and (string.find(name, "MiniBorder") or string.find(name, "Background")) then
    hide = true
end
```
- 结果：**暴雪 chrome 仍大量可见**，与 DFUI 金属框堆叠。说明 WorldMapFrame 有很多其他名字的装饰纹理没被匹配到。

**策略 B — 激进隐藏**（无差别 SetAlpha(0) 所有直属纹理）：
```lua
local regions = {WorldMapFrame:GetRegions()}
for i = 1, table.getn(regions) do
    local region = regions[i]
    if region:GetObjectType() == "Texture" then
        region:SetAlpha(0)
    end
end
```
- 结果：**地图底图也消失了**。说明 WoW 1.12（或 Turtle WoW 客户端）的地图底图纹理**直接挂在 WorldMapFrame 上**，和其他面板（CharacterFrame 等）行为不同。

### 核心教训

1. **WorldMapFrame ≠ CharacterFrame** — 不能套用 character.lua 的隐藏策略，因为 character.lua 能用"无差别隐藏所有纹理"是因为 CharacterFrame 的内容都在子框体里。WorldMapFrame 的地图内容**直接**在自身。

2. **需要先调查再实施** — 下次重新设计前必须先在游戏里用调试代码列出 `WorldMapFrame:GetRegions()` 的**全部纹理路径**，才能精确区分"chrome 装饰"和"map content"。

---

## 十二、下次尝试的指导方针

### 第一步：调查

在实施任何隐藏之前，先写调试代码输出 `WorldMapFrame:GetRegions()` 的全部纹理：
```lua
local regions = {WorldMapFrame:GetRegions()}
for i = 1, table.getn(regions) do
    local r = regions[i]
    if r:GetObjectType() == "Texture" then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "[%d] name=%s tex=%s size=%dx%d",
            i,
            r:GetName() or "unnamed",
            r:GetTexture() or "notex",
            r:GetWidth() or 0, r:GetHeight() or 0))
    end
end
```

打开地图后看聊天框输出，人工分析：
- 哪些是边框/装饰（应隐藏）
- 哪些是地图底图（必须保留）
- 是否能按"尺寸/位置"区分（边框通常在四周，底图在中间）
- 是否能按纹理路径前缀区分（如 `Interface\WorldMap\` 开头的是底图）

### 第二步：基于调查结果制定白名单/黑名单

根据调查出的实际情况，选择：
- **白名单**：只隐藏名字/路径**明确匹配**的装饰纹理
- **黑名单**：跳过名字/路径匹配"地图内容"关键词的，其他隐藏
- **坐标区分**：如果通过名字路径都无法区分，用纹理的位置/尺寸判断（如面积 > X% 的保留）

### 第三步：保守实施，充分测试

- 每次只改一个策略
- 测试：地图底图 + 区域名 overlay + 图钉 + 坐标 + 揭示纹理都要检查
- 切换大陆/区域时也要确认不会把底图挡住

---

## 十三、当前状态

- 所有已尝试的代码**已回退**
- `modules/panels/worldmap.lua` — **不存在**
- `Dragonflight-Fix.toc` — **无 worldmap 加载项**
- `modules/gui/elem.lua` — **无 WorldMap 映射**
- 世界地图回到原生（ShaguTweaks + ShaguPlates + pfQuest）状态
- 本文档保留作为下次实施的起点
