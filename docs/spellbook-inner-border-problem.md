# SpellBook 羊皮纸内框问题记录

> 状态：**未解决**，当前代码是被否决的纯金色实心方案（"一坨💩"）

## 目标

给 spellbook.lua 的羊皮纸（mainPage + rightStrip）加一圈**细致的内边框**，提升视觉质感、避免边缘"尖锐呆板"。要求：
- 保持 retail 真实纹理质感（柔边、渐变、不对称）
- 不能用纯色实心方块（太丑）
- 不能用 DF-Fix 自己的 UIFrameMetal2x（不合适）

## 尝试过的所有方案

### 方案 1：4 条深棕色细线（纯色 SetTexture(r,g,b,a)）
- 实现：`BORDER_COLOR = (0.18, 0.10, 0.05, 0.85)`，4 条 2-3px 实线
- 结果：**可见但用户否决** — 觉得太死板，不像 retail
- 评价：可作 baseline，确认 child frame + 纯色路径工作

### 方案 2：retail UI-Frame Inner NineSlice（atlas 切片，6×6 角 + 3px 边）
- 来源：retail `nineslicelayouts.lua` 的 `InsetFrameTemplate` 配置
- 用了 retail atlas：
  - `interface/framegeneral/uiframe.blp` (atlas 948, 128×128) → 4 corners
  - `interface/framegeneral/uiframevertical.blp` (atlas 949, 64×256) → left/right tiles
  - `interface/framegeneral/uiframehorizontal.blp` (atlas 950, 256×128) → top/bottom tiles
- 已解码到 DF-Fix：
  - `media/tex/interface/uiframe_inner.tga`
  - `media/tex/interface/uiframe_inner_vertical.tga`
  - `media/tex/interface/uiframe_inner_horizontal.tga`
- 用 SetTexCoord 切出 8 元素：`UI-Frame-InnerTopLeft`, `InnerTopRight`, `InnerBotLeftCorner`, `InnerBotRight`, `_InnerTopTile`, `_InnerBotTile`, `!InnerLeftTile`, `!InnerRightTile`
- 显示尺寸：corner 6×6, edge 3px 厚
- 结果：**完全看不到** — 太小+太暗，被羊皮纸自带深边吞没

### 方案 3：DF-Fix 的 UIFrameMetal2x 缩小复用（"双层金边"思路）
- 实现：8 元素，TOP_C=38, BOT_C=16, edge_thick=38/16
- 用同款金属 atlas + 同款 TexCoord，只改尺寸/锚点
- 结果：**纹理不合适** — 用户否决，金属感不对

### 方案 4：retail UI-Frame 大元素（不是 Inner 系列，是 Main 元素）
- 元素清单（同 atlas 948/949/950，不同 TexCoord）：
  - TopLeftCornerNoPortrait 34×33
  - TopCornerRight 33×33
  - BotCornerLeft 14×14
  - BotCornerRight 11×11
  - TopTileStreaks 256×43（带流光）
  - Bot 256×9
  - LeftTile 16×256
  - RightTile 10×256
- 验证 atlas 像素：100% 有内容（partial alpha + 暗色 RGB ~22-30）
- 结果：**完全看不到**
  - 4 panel 角（spellbook_panel_*）覆盖了 + 暗色被深 parchment 边吞没

### 方案 5：方案 4 + child frame 提高 FrameLevel +5
- 创建 `borderFrame = CreateFrame("Frame", nil, spellbook)`，FrameLevel + 5
- 8 元素挂载到 borderFrame
- 红色诊断（SetTexture(1,0,0,1)）确认**位置和层级正常**
- 但 retail UI-Frame 元素仍 invisible

### 方案 6：方案 5 + 整体 3x 放大 + ADD blend + SetVertexColor(2.5, 2.0, 1.0)
- 试图用 BlendMode("ADD") 和 vertex color > 1 提亮
- 结果：**Vanilla 1.12 SetVertexColor 数值被 clamp 到 ≤1**，提亮无效
- ADD blend 对 partial alpha 暗色纹理也只能轻微提亮

### 方案 7（当前代码）：retail 不对称尺寸 + 纯金色实心
- 8 元素都用 `SetTexture(0.55, 0.42, 0.18, 1)` 深金色实心
- 保留 retail 形状不对称（顶角厚 102×99，底角薄 42×42 等）
- 结果：**用户否决，"一坨💩"** — 大块金色实心难看

## 根本技术问题

### 问题 A：Vanilla 1.12 渲染限制
- `SetVertexColor` 数值被 clamp 到 [0, 1]，无法 > 1 提亮
- `SetBlendMode("ADD")` 在 partial alpha 暗色纹理上效果有限
- `SetVertexColor(0.5, 0.4, 0.2, 1)` 只能让纹理变更暗，无法提亮
- 结果：**任何"暗色 + partial alpha"的 retail 纹理在 1.12 都难以提亮显示**

### 问题 B：羊皮纸边缘自带深色
- spellbook-page-1.tga 的角落像素 RGBA ~(24, 41, 46, 255) — 深teal
- 任何深色 partial alpha 纹理叠加上去都看不出对比
- retail 用这些 UI-Frame 元素是设计在**亮色背景**上做暗色描边（如 InsetFrameTemplate 的浅色 marble 背景）

### 问题 C：4 panel 角覆盖 OVERLAY 层
- `spellbook_panel_topleft/topright/botleft/botright` 在 spellbook 主框 OVERLAY 层
- 256/128 native 大尺寸，覆盖羊皮纸大部分边缘
- 同 OVERLAY 层导致后续添加的内框纹理被它们的不透明深色内容覆盖
- 解决：用 child frame + 高 FrameLevel（已验证有效）

## 当前代码状态（spellbook.lua line ~118-178）

```lua
-- 3c. 用 child frame 提高层级（这步是对的，保留）
local borderFrame = CreateFrame("Frame", nil, spellbook)
borderFrame:SetAllPoints(spellbook)
borderFrame:SetFrameStrata("MEDIUM")
borderFrame:SetFrameLevel(spellbook:GetFrameLevel() + 5)

-- 8 元素纯金色实心（这是被否决的，需替换）
local GOLD_R, GOLD_G, GOLD_B = 0.55, 0.42, 0.18
-- 顶角 102×99 / 99×99，底角 42×42 / 33×33
-- 顶边 129px 厚，底边 27px，左 48px，右 30px
-- 全部 SetTexture(GOLD_R, GOLD_G, GOLD_B, 1)
```

## 推荐的下一步方向（未尝试）

### 方向 A：放弃内框，专注于 4 panel 角的精修
- 把 `spellbook_panel_*` 4 个 dark wood 角重新调位置/尺寸
- 让它们严贴羊皮纸 4 角，作为唯一边框装饰
- 不再加内框 NineSlice

### 方向 B：用 spell button border 纹理（spellbook_actives_border.blp）
- 这是 retail 设计在**亮色背景**上的金属边框，应该足够亮可见
- 切成 4 corners + 4 edges 模拟 NineSlice
- 未试过

### 方向 C：手工绘制纯色 NineSlice（多色组合）
- 不用 retail 纹理，纯色但**多层**：
  - 外层深棕色描边 2px
  - 中层金色描边 1px
  - 内层亮米色高光 1px
- 模拟 retail 的"相邻不同颜色窄线"效果
- 用 6 条线即可（不是 4 条）

### 方向 D：直接放弃内框
- 用户 4 个 panel 角 + 羊皮纸自带深 teal 边 已经够用
- 说"内框"想法本身可能就不必要

## 给下一个会话的建议

1. **不要再尝试 retail UI-Frame Inner 系列** — Vanilla 1.12 确认无法显示这种暗色 partial-alpha 纹理
2. **保留 child frame + FrameLevel +5 的 borderFrame 结构** — 这是必需的（防被 panel 角覆盖）
3. **优先用纯色多层组合或 spell button border 纹理** — 已知可见
4. **4 panel 角和内框二选一** — 不要同时存在（会冲突视觉）
5. **如果用户继续不满意，建议放弃内框** — 接受 retail 视觉差异，集中精力做 Phase 2（右侧 SkillLine Tab + 底部收藏 Tab）

## 相关文件

- 代码：`E:\turtlewow\Interface\AddOns\Dragonflight-Fix\modules\panels\spellbook.lua`（当前 spellbook.lua line ~118-178）
- 已解码 atlas TGA：
  - `media/tex/interface/uiframe_inner.tga` (128×128)
  - `media/tex/interface/uiframe_inner_vertical.tga` (64×256)
  - `media/tex/interface/uiframe_inner_horizontal.tga` (256×128)
- 已解码 4 panel 角：
  - `media/tex/panels/spellbook_panel_{topleft,topright,botleft,botright}.tga`
- retail 参考：`E:\turtlewow\_references\dragonflight_ui\_wtl_extract\interface\framegeneral\` 和 `interface\spellbook\`
