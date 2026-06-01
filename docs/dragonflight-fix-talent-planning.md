# dragonflight-fix 天赋模块 — 规划/模拟功能

> **状态：已实现** — 本文档最初为实现计划，功能已完成。以下为实现后的设计记录。

## Context

dragonflight-fix 的天赋模块 (`modules/ui/talents.lua`, 1050 行) 在原有天赋学习功能基础上，添加了天赋规划/模拟功能，让玩家在学习前先规划加点路线。

**主要修改文件**：`modules/ui/talents.lua`

## 一、数据结构

存储在 `DFUI_CUR_PROFILE['TalentPlans']`（角色级 SavedVariablesPerCharacter）：

```lua
{
    selectedPlan = 1,
    plans = {
        [1] = {
            name = "方案 1",
            points = 0,          -- 全局已分配规划点
            [1] = { points = 0, [talentId] = rank, ... },  -- 树1
            [2] = { points = 0, [talentId] = rank, ... },  -- 树2
            [3] = { points = 0, [talentId] = rank, ... },  -- 树3
        },
        -- 最多 20 个方案
    }
}
```

局部变量：`learnMode`, `planData`, `MAX_PLANS=20`, `MAX_TALENT_POINTS=51`

## 二、核心函数（规划逻辑 9 个）

| 函数 | 职责 |
|------|------|
| `CreateEmptyPlan(index)` | 构造空方案表 `{name, points=0, [1..3]={points=0}}` |
| `InitPlanData()` | 从 DFUI_CUR_PROFILE 加载/初始化规划数据结构 |
| `GetCurrentPlan()` | 返回当前选中方案表 |
| `GetPlannedTalentInfo(tab, id)` | planned 模式用规划 rank 覆盖实际 rank |
| `GetPlannedPrereqs(tab, id)` | planned 模式重新计算前置条件满足状态（依赖 branchArrays.id） |
| `PlanTalent(tab, id)` | 左键加点：校验总点<51、层级解锁、前置满足、maxRank |
| `UnplanTalent(tab, id)` | 右键减点：校验依赖天赋、下层级点数约束 |
| `ResetPlan(tab)` | 重置单树(tab!=nil)或全部(tab==nil)，需 Shift 确认 |
| `SwitchPlan(index)` | 切换方案，循环 1-20 |

### 规划模式 tooltip / spell 映射子系统（额外 3 个函数 + 缓存）

planned 模式悬停天赋时显示规划 rank 对应的法术描述，依赖外部数据表 `DFUI_TalentSpellMap`（坐标键 → spellId 列表）与 `DFUI_TalentDescriptions`（spellId → {name, rank, desc}）：

| 函数/数据 | 职责 |
|------|------|
| `CLASS_MASKS` | 职业 EN 名 → classMask 映射（与 DBC TalentTab.classMask 对应） |
| `talentSpellCache` | `[tabIndex][talentIndex] = {spellId1, ...}` 运行时缓存 |
| `BuildTalentSpellCache()` | 由 classMask + (tab,tier,col) 组键查 `DFUI_TalentSpellMap` 填充缓存；Update 首次运行时调用 |
| `GetTalentSpellForRank(tab, id, rank)` | 取指定天赋指定 rank 的 spellId |
| `ShowTalentTooltip(btn)`（CreateTalentButton 内局部） | planned 模式拼当前/下一等级描述，否则回退 `GameTooltip:SetTalent` |

## 三、UI 控件（CreateMainFrame 底部控制栏）

底部控制栏布局：
```
[Small] [●已学 ○规划] [◀ 方案 1/20 ▶] [重置]     pointsLeft
```

| 控件 | 类型 | 位置 | 说明 |
|------|------|------|------|
| learnedCB | DFUI.tools.CreateIndiCheckbox | BOTTOMLEFT, 150, 17 | "已学"模式 radio |
| plannedCB | DFUI.tools.CreateIndiCheckbox | BOTTOMLEFT, 260, 17 | "规划"模式 radio（青色标签） |
| prevPlanBtn | Button (翻页纹理) | BOTTOMLEFT, 370, 17 | ◀ 前一方案，默认隐藏 |
| planLabel | FontString | prevBtn 右侧 (LEFT, 5, 0) | "方案 1/20"，默认隐藏 |
| nextPlanBtn | Button (翻页纹理) | planLabel 右侧 (LEFT, 5, 0) | ▶ 下一方案，默认隐藏 |
| resetBtn | Button (UIPanelButtonTemplate) | BOTTOMRIGHT, -220, 17 | "重置"，默认隐藏 |

方案控件在 planned 模式下才 Show，learned 模式下 Hide。

## 四、按钮扩展（CreateTalentButton）

1. **规划点数显示**（已学模式下叠加显示当前方案的规划点）：
   - `plannedRankBg`：14×12 半透明黑色底 (alpha 0.6)，TOPLEFT (-4, 4)
   - `plannedRank`：GameFontNormalSmall，青色 (0,1,1)，居中于 bg，文字格式 `+N`
   - 默认隐藏，learned 模式下若有规划点则显示（planned 模式下始终隐藏）

2. **注册右键**：`button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')`

3. **OnClick 双模式**：
   - learned: 原逻辑 LearnTalent
   - planned: 左键 PlanTalent / 右键 UnplanTalent

4. **OnMouseWheel**：planned 模式下滚轮加减点

## 五、Update() 改造

关键修改点：

1. **预填充 branchArrays.id**（ResetBranches 后、主循环前）：遍历天赋把 talentIndex 写入 branchArrays[tab][tier][col].id，因为 GetPlannedPrereqs 需要通过 (tier,col) 反查 talentIndex

2. **条件读取天赋数据**：主循环（talents.lua:876-881）从 `talentCache[talentIndex]` 取出实际 rank 后，planned 模式内联覆盖为规划 rank：`if isPlanned and plan then rank = plan[tabIndex][talentIndex] or 0 end`（不调用 GetPlannedTalentInfo）。GetPlannedTalentInfo 仅供 GetPlannedPrereqs(talents.lua:133) 与 ShowTalentTooltip(talents.lua:580) 读取规划 rank，不参与 Update 主循环

3. **条件计算解锁状态**：
   - learned: pointsSpent = GetTalentTabInfo, available = UnitCharacterPoints
   - planned: pointsSpent = plan[tab].points, available = 51 - plan.points

4. **规划点数叠加显示**：learned 模式下若当前方案有规划点也用青色小字显示

5. **树点数文字**：planned 模式显示 "|cff00ffff规划X|r / 已学Y points"

6. **底部总点文字**：planned 模式显示 "已规划: X/51 剩余: Y"

7. **分支线条**：planned 模式使用 GetPlannedPrereqs 替代 GetTalentPrereqs（结果缓存进 `prereqResults` 复用给 SetTalentPrereqs）

8. **性能缓存**：每树主循环前把 `GetTalentInfo` 结果存进局部 `talentCache[talentIndex]`（避免重复 C-bridge 调用）；Update 首次运行时 `if not talentSpellCache[1] then BuildTalentSpellCache()` 构建 tooltip 法术映射

## 六、其他修改

- **CheckPrereqsMaxed**：planned 模式调用 GetPlannedPrereqs
- **ToggleFrame**：首次打开调用 InitPlanData()

## 七、已知问题（wontfix）

- **专精职业背景未铺满 treeFrame**（CreateTreeFrames）：每树 4 张分块背景 `bgTopLeft/TopRight/BottomLeft/BottomRight`（路径 `Interface\TalentFrame\<fileName>-*`）的 SetPoint 均带 `(20, -30)` 偏移（426/431/436/441 行），叠加 borderRight 的 `-30`（492 行），使背景整块平移：左露白 20px、顶露白 30px、右/下溢出。4 块拼接尺寸 200+100 宽 × 300+200 高 = 300×500 恰为 treeFrame，去掉偏移即可严丝合缝。
- **状态**：根因已定位，但用户试改归零后回复"恢复之前状态"，已全部反向恢复原值，归类 wontfix；今后勿主动铺满，若再动须先就底部渐变 `whiteBottom` + 剩余点数文字的运行时观感确认。

## 八、验证

功能验证需在游戏内测试：
- 切换已学/规划模式
- 左键加点、右键减点、滚轮操作
- 前置依赖高亮正确
- 方案切换和重置
- 退出重进后规划数据持久化
