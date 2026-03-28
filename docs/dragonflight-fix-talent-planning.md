# 计划：为 dragonflight-fix 天赋模块添加规划/模拟功能

## Context

dragonflight-fix 的天赋模块 (`modules/ui/talents.lua`, 591 行) 当前仅支持直接学习天赋。需要参考 SpecialTalentUI 的实现，在现有模块中添加天赋规划/模拟功能，让玩家在学习前先规划加点路线。

**唯一修改文件**：`/home/ym/new_ilabel/turtle-wow/dragonflight-fix/modules/ui/talents.lua`

## 一、数据结构

存储在 `DFRL_CUR_PROFILE['TalentPlans']`（角色级 SavedVariablesPerCharacter）：

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

新增局部变量（行 11 后）：`learnMode`, `planData`, `MAX_PLANS=20`, `MAX_TALENT_POINTS=51`

## 二、新增函数（8 个，插入在行 12-31 之间）

| 函数 | 职责 |
|------|------|
| `InitPlanData()` | 从 DFRL_CUR_PROFILE 加载/初始化规划数据结构 |
| `GetCurrentPlan()` | 返回当前选中方案表 |
| `GetPlannedTalentInfo(tab, id)` | planned 模式用规划 rank 覆盖实际 rank |
| `GetPlannedPrereqs(tab, id)` | planned 模式重新计算前置条件满足状态（依赖 branchArrays.id） |
| `PlanTalent(tab, id)` | 左键加点：校验总点<51、层级解锁、前置满足、maxRank |
| `UnplanTalent(tab, id)` | 右键减点：校验依赖天赋、下层级点数约束 |
| `ResetPlan(tab)` | 重置单树(tab!=nil)或全部(tab==nil)，需 Shift 确认 |
| `SwitchPlan(index)` | 切换方案，循环 1-20 |

## 三、UI 控件（在 CreateMainFrame 行 96-97 之间插入）

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

## 四、按钮扩展（修改 CreateTalentButton，行 270-298）

1. **新增规划点数显示**（行 274 后）：
   - `plannedRankBg`：14×12 半透明黑色底，BOTTOMLEFT (-4, -2)
   - `plannedRank`：GameFontNormalSmall，青色 (0,1,1)，居中于 bg
   - 默认隐藏，learned 模式下若有规划点则显示

2. **注册右键**（行 278 前）：`button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')`

3. **OnClick 双模式**（替换行 278-287）：
   - learned: 原逻辑 LearnTalent
   - planned: 左键 PlanTalent / 右键 UnplanTalent

4. **OnMouseWheel**（行 298 后新增）：planned 模式下滚轮加减点

## 五、Update() 改造（行 460-522）

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

- **CheckPrereqsMaxed**（行 303-312）：planned 模式调用 GetPlannedPrereqs
- **ToggleFrame**（行 541 后）：首次打开调用 InitPlanData()

## 七、实现步骤顺序

1. 添加局部变量声明（行 11 后）
2. 插入 8 个新函数（行 12-31 之间，CreateMainFrame 之前）
3. 在 CreateMainFrame 中添加 UI 控件（行 96-97 之间）
4. 扩展 CreateTalentButton（规划点数显示 + 双模式点击 + 滚轮）
5. 修改 CheckPrereqsMaxed 支持双模式
6. 改造 Update() 核心渲染循环
7. 在 ToggleFrame 中初始化 planData

## 八、验证

```bash
cd /home/ym/new_ilabel/turtle-wow/dragonflight-fix
luacheck modules/ui/talents.lua --no-color --codes
```

功能验证需在游戏内测试：
- 切换已学/规划模式
- 左键加点、右键减点、滚轮操作
- 前置依赖高亮正确
- 方案切换和重置
- 退出重进后规划数据持久化
