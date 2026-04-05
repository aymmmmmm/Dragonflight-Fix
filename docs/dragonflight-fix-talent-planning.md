# dragonflight-fix 天赋模块 — 规划/模拟功能

> **状态：已实现** — 本文档最初为实现计划，功能已完成。以下为实现后的设计记录。

## Context

dragonflight-fix 的天赋模块 (`modules/ui/talents.lua`, 1077 行) 在原有天赋学习功能基础上，添加了天赋规划/模拟功能，让玩家在学习前先规划加点路线。

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

## 二、核心函数（8 个）

| 函数 | 职责 |
|------|------|
| `InitPlanData()` | 从 DFUI_CUR_PROFILE 加载/初始化规划数据结构 |
| `GetCurrentPlan()` | 返回当前选中方案表 |
| `GetPlannedTalentInfo(tab, id)` | planned 模式用规划 rank 覆盖实际 rank |
| `GetPlannedPrereqs(tab, id)` | planned 模式重新计算前置条件满足状态（依赖 branchArrays.id） |
| `PlanTalent(tab, id)` | 左键加点：校验总点<51、层级解锁、前置满足、maxRank |
| `UnplanTalent(tab, id)` | 右键减点：校验依赖天赋、下层级点数约束 |
| `ResetPlan(tab)` | 重置单树(tab!=nil)或全部(tab==nil)，需 Shift 确认 |
| `SwitchPlan(index)` | 切换方案，循环 1-20 |

## 三、UI 控件（CreateMainFrame 底部控制栏）

底部控制栏布局：
```
[Small] [●已学 ○规划] [◀ 方案 1/20 ▶] [重置]     pointsLeft
```

| 控件 | 类型 | 位置 | 说明 |
|------|------|------|------|
| learnedCB | DFRL.tools.CreateIndiCheckbox | BOTTOMLEFT, 150, 17 | "已学"模式 radio |
| plannedCB | DFRL.tools.CreateIndiCheckbox | BOTTOMLEFT, 260, 17 | "规划"模式 radio（青色标签） |
| prevPlanBtn | Button (翻页纹理) | BOTTOMLEFT, 370, 19 | ◀ 前一方案，默认隐藏 |
| planLabel | FontString | prevBtn 右侧 | "方案 1/20"，默认隐藏 |
| nextPlanBtn | Button (翻页纹理) | planLabel 右侧 | ▶ 下一方案，默认隐藏 |
| resetBtn | Button (UIPanelButtonTemplate) | BOTTOMRIGHT, -120, 17 | "重置"，默认隐藏 |

方案控件在 planned 模式下才 Show，learned 模式下 Hide。

## 四、按钮扩展（CreateTalentButton）

1. **规划点数显示**：
   - `plannedRankBg`：14×12 半透明黑色底，BOTTOMLEFT (-4, -2)
   - `plannedRank`：GameFontNormalSmall，青色 (0,1,1)，居中于 bg
   - 默认隐藏，learned 模式下若有规划点则显示

2. **注册右键**：`button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')`

3. **OnClick 双模式**：
   - learned: 原逻辑 LearnTalent
   - planned: 左键 PlanTalent / 右键 UnplanTalent

4. **OnMouseWheel**：planned 模式下滚轮加减点

## 五、Update() 改造

关键修改点：

1. **预填充 branchArrays.id**（ResetBranches 后、主循环前）：遍历天赋把 talentIndex 写入 branchArrays[tab][tier][col].id，因为 GetPlannedPrereqs 需要通过 (tier,col) 反查 talentIndex

2. **条件读取天赋数据**：planned 模式调用 GetPlannedTalentInfo 获取规划 rank

3. **条件计算解锁状态**：
   - learned: pointsSpent = GetTalentTabInfo, available = UnitCharacterPoints
   - planned: pointsSpent = plan[tab].points, available = 51 - plan.points

4. **规划点数叠加显示**：learned 模式下若当前方案有规划点也用青色小字显示

5. **树点数文字**：planned 模式显示 "|cff00ffff规划X|r / 已学Y points"

6. **底部总点文字**：planned 模式显示 "已规划: X/51 剩余: Y"

7. **分支线条**：planned 模式使用 GetPlannedPrereqs 替代 GetTalentPrereqs

## 六、其他修改

- **CheckPrereqsMaxed**：planned 模式调用 GetPlannedPrereqs
- **ToggleFrame**：首次打开调用 InitPlanData()

## 七、验证

功能验证需在游戏内测试：
- 切换已学/规划模式
- 左键加点、右键减点、滚轮操作
- 前置依赖高亮正确
- 方案切换和重置
- 退出重进后规划数据持久化
