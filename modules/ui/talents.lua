DFUI:NewDefaults("Talents", {
    enabled = {true},
})

DFUI:NewMod("Talents", 1, function()
    local frame
    local treeFrames = {}
    local talentButtons = {}
    local branchArrays = {}
    local branchTextures = {}
    local arrowTextures = {}

    local learnMode = 'learned'  -- 'learned' 或 'planned'
    local planData = nil         -- 当前规划数据引用
    local MAX_PLANS = 20         -- 最大方案数
    local MAX_TALENT_POINTS = 51 -- 最大天赋点数（Turtle WoW）
    local Update                 -- 前向声明，Update 实际定义在后面

    local TALENT_BRANCH_TEXTURECOORDS = {
        up = {[1] = {0.12890625, 0.25390625, 0, 0.484375}, [-1] = {0.12890625, 0.25390625, 0.515625, 1.0}},
        down = {[1] = {0, 0.125, 0, 0.484375}, [-1] = {0, 0.125, 0.515625, 1.0}},
        left = {[1] = {0.2578125, 0.3828125, 0, 0.5}, [-1] = {0.2578125, 0.3828125, 0.5, 1.0}},
        right = {[1] = {0.2578125, 0.3828125, 0, 0.5}, [-1] = {0.2578125, 0.3828125, 0.5, 1.0}},
        topright = {[1] = {0.515625, 0.640625, 0, 0.5}, [-1] = {0.515625, 0.640625, 0.5, 1.0}},
        topleft = {[1] = {0.640625, 0.515625, 0, 0.5}, [-1] = {0.640625, 0.515625, 0.5, 1.0}},
        bottomright = {[1] = {0.38671875, 0.51171875, 0, 0.5}, [-1] = {0.38671875, 0.51171875, 0.5, 1.0}},
        bottomleft = {[1] = {0.51171875, 0.38671875, 0, 0.5}, [-1] = {0.51171875, 0.38671875, 0.5, 1.0}},
        tdown = {[1] = {0.64453125, 0.76953125, 0, 0.5}, [-1] = {0.64453125, 0.76953125, 0.5, 1.0}},
        tup = {[1] = {0.7734375, 0.8984375, 0, 0.5}, [-1] = {0.7734375, 0.8984375, 0.5, 1.0}}
    }

    local TALENT_ARROW_TEXTURECOORDS = {
        top = {[1] = {0, 0.5, 0, 0.5}, [-1] = {0, 0.5, 0.5, 1.0}},
        right = {[1] = {1.0, 0.5, 0, 0.5}, [-1] = {1.0, 0.5, 0.5, 1.0}},
        left = {[1] = {0.5, 1.0, 0, 0.5}, [-1] = {0.5, 1.0, 0.5, 1.0}}
    }

    -- ========== 规划模式函数 ==========

    -- 创建空方案数据结构
    local function CreateEmptyPlan(index)
        return {
            name = '方案 ' .. index,
            points = 0,
            [1] = { points = 0 },
            [2] = { points = 0 },
            [3] = { points = 0 },
        }
    end

    -- 初始化规划数据（从 SavedVariablesPerCharacter 加载）
    local function InitPlanData()
        if not DFUI_CUR_PROFILE['TalentPlans'] then
            DFUI_CUR_PROFILE['TalentPlans'] = {
                selectedPlan = 1,
                plans = {},
            }
        end
        planData = DFUI_CUR_PROFILE['TalentPlans']
        if not planData.plans[1] then
            planData.plans[1] = CreateEmptyPlan(1)
        end
        if not planData.selectedPlan or not planData.plans[planData.selectedPlan] then
            planData.selectedPlan = 1
        end
    end

    -- 获取当前选中方案表
    local function GetCurrentPlan()
        if not planData then return nil end
        return planData.plans[planData.selectedPlan]
    end

    -- 职业 → classMask 映射（与 DBC TalentTab.classMask 对应）
    local CLASS_MASKS = {
        WARRIOR = 1, PALADIN = 2, HUNTER = 4, ROGUE = 8,
        PRIEST = 16, SHAMAN = 64, MAGE = 128, WARLOCK = 256, DRUID = 1024,
    }

    -- 运行时天赋 spell 映射缓存: talentSpellCache[tabIndex][talentIndex] = { spellId1, spellId2, ... }
    local talentSpellCache = {}

    -- 构建 (tabIndex, talentIndex) → spell IDs 的映射
    local function BuildTalentSpellCache()
        if not DFUI_TalentSpellMap then return end
        local _, classEN = UnitClass('player')
        local classMask = CLASS_MASKS[classEN]
        if not classMask then return end

        for tabIndex = 1, 3 do
            talentSpellCache[tabIndex] = {}
            local numTalents = GetNumTalents(tabIndex)
            for talentIndex = 1, numTalents do
                local _, _, tier, column = GetTalentInfo(tabIndex, talentIndex)
                if tier and column then
                    local key = classMask .. '_' .. (tabIndex - 1) .. '_' .. (tier - 1) .. '_' .. (column - 1)
                    local spells = DFUI_TalentSpellMap[key]
                    if spells then
                        talentSpellCache[tabIndex][talentIndex] = spells
                    end
                end
            end
        end
    end

    -- 获取指定天赋指定 rank 的 spell ID
    local function GetTalentSpellForRank(tabIndex, talentIndex, rank)
        local spells = talentSpellCache[tabIndex] and talentSpellCache[tabIndex][talentIndex]
        if spells and rank >= 1 and rank <= table.getn(spells) then
            return spells[rank]
        end
        return nil
    end

    -- 规划模式下获取天赋信息（用规划 rank 覆盖实际 rank）
    local function GetPlannedTalentInfo(tab, id)
        local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tab, id)
        local plan = GetCurrentPlan()
        if plan and learnMode == 'planned' then
            rank = plan[tab][id] or 0
        end
        return name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq
    end

    -- 规划模式下重新计算前置条件满足状态
    local function GetPlannedPrereqs(tab, id)
        local prereqs = { GetTalentPrereqs(tab, id) }
        for i = 1, table.getn(prereqs), 3 do
            local tier, column = prereqs[i], prereqs[i + 1]
            if tier and column then
                local node = branchArrays[tab][tier][column]
                if node and node.id then
                    local _, _, _, _, pRank, pMaxRank = GetPlannedTalentInfo(tab, node.id)
                    prereqs[i + 2] = (pRank == pMaxRank) and 1 or nil
                end
            end
        end
        return unpack(prereqs)
    end

    -- 左键加点（规划模式）
    local function PlanTalent(tab, id)
        local plan = GetCurrentPlan()
        if not plan then return end
        local _, _, tier, _, _, maxRank = GetTalentInfo(tab, id)
        local plannedRank = plan[tab][id] or 0
        -- 总点数上限
        if plan.points >= MAX_TALENT_POINTS then return end
        -- 已满级
        if plannedRank >= maxRank then return end
        -- 层级解锁：该树已分配点数 >= (tier-1)*5
        if plan[tab].points < (tier - 1) * 5 then return end
        -- 前置条件检查
        local prereqs = { GetTalentPrereqs(tab, id) }
        for i = 1, table.getn(prereqs), 3 do
            local pTier, pCol = prereqs[i], prereqs[i + 1]
            if pTier and pCol then
                local node = branchArrays[tab][pTier][pCol]
                if node and node.id then
                    local pRank = plan[tab][node.id] or 0
                    local _, _, _, _, _, pMaxRank = GetTalentInfo(tab, node.id)
                    if pRank < pMaxRank then return end -- 前置未满
                end
            end
        end
        -- 执行加点
        plan[tab][id] = plannedRank + 1
        plan[tab].points = plan[tab].points + 1
        plan.points = plan.points + 1
        Update()
    end

    -- 右键减点（规划模式）
    local function UnplanTalent(tab, id)
        local plan = GetCurrentPlan()
        if not plan then return end
        local plannedRank = plan[tab][id] or 0
        if plannedRank <= 0 then return end
        local _, _, tier, _, _, maxRank = GetTalentInfo(tab, id)
        -- 检查：移除此点后，高层天赋是否仍然满足层级解锁
        local newTabPoints = plan[tab].points - 1
        for t = 1, 8 do
            for c = 1, 4 do
                local node = branchArrays[tab][t][c]
                if node and node.id and node.id ~= id then
                    local pRank = plan[tab][node.id] or 0
                    if pRank > 0 then
                        local _, _, nodeTier = GetTalentInfo(tab, node.id)
                        if (nodeTier - 1) * 5 > newTabPoints then
                            return -- 移除会破坏高层解锁
                        end
                    end
                end
            end
        end
        -- 检查：当前满级时减点是否有其他天赋依赖
        if plannedRank == maxRank then
            local numTalents = GetNumTalents(tab)
            for otherIdx = 1, numTalents do
                local otherRank = plan[tab][otherIdx] or 0
                if otherRank > 0 and otherIdx ~= id then
                    local prereqs = { GetTalentPrereqs(tab, otherIdx) }
                    for i = 1, table.getn(prereqs), 3 do
                        local pTier, pCol = prereqs[i], prereqs[i + 1]
                        if pTier and pCol then
                            local node = branchArrays[tab][pTier][pCol]
                            if node and node.id == id then
                                return -- 有其他天赋依赖此天赋
                            end
                        end
                    end
                end
            end
        end
        -- 执行减点
        plan[tab][id] = plannedRank - 1
        if plan[tab][id] == 0 then plan[tab][id] = nil end
        plan[tab].points = plan[tab].points - 1
        plan.points = plan.points - 1
        Update()
    end

    -- 重置规划（tab 非 nil 重置单树，nil 重置全部；需 Shift 确认）
    local function ResetPlan(tab)
        if not IsShiftKeyDown() then return end
        local plan = GetCurrentPlan()
        if not plan then return end
        if tab then
            local oldPoints = plan[tab].points
            plan[tab] = { points = 0 }
            plan.points = plan.points - oldPoints
        else
            plan.points = 0
            for t = 1, 3 do
                plan[t] = { points = 0 }
            end
        end
        Update()
    end

    -- 切换方案（循环 1~MAX_PLANS）
    local function SwitchPlan(index)
        if not planData then return end
        if index < 1 then index = MAX_PLANS end
        if index > MAX_PLANS then index = 1 end
        if not planData.plans[index] then
            planData.plans[index] = CreateEmptyPlan(index)
        end
        planData.selectedPlan = index
        Update()
    end

    local function CreateMainFrame()
        frame = CreateFrame('Frame', 'BLF_TalentFrame', UIParent)
        frame:SetWidth(1020)
        frame:SetHeight(600)
        frame:SetFrameStrata('HIGH')
        frame:EnableMouse(true)
        frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:SetClampedToScreen(true)
        frame:SetScript("OnMouseDown", function() this:StartMoving() end)
        frame:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)

        -- DF 金属边框（同时作为唯一背景）
        local metalBg = DFUI.CreatePaperDollFrame("DFUI_TalentBg", frame, 1020, 600, 2)
        metalBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        metalBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        metalBg:SetFrameLevel(frame:GetFrameLevel() - 1)
        -- 岩石背景偏暗以衬托天赋树
        metalBg.Bg:SetVertexColor(0.35, 0.30, 0.25)

        local closeButton = DFUI.CreateRedButton(frame, "close", function()
            pcall(PlaySound, "TalentScreenClose")
            frame:Hide()
            UpdateMicroButtons()
        end)
        closeButton:SetPoint('TOPRIGHT', metalBg, 'TOPRIGHT', 0, -1)
        closeButton:SetWidth(20)
        closeButton:SetHeight(20)
        closeButton:SetFrameLevel(frame:GetFrameLevel() + 3)

        local headerText = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
        headerText:SetText('天赋')
        headerText:SetPoint('TOP', metalBg, 'TOP', 0, -3)

        local pointsLeft = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        pointsLeft:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -10, 17)
        frame.pointsLeft = pointsLeft

        -- 已学/规划模式切换 radio
        local learnedCB = DFUI.tools.CreateIndiCheckbox(frame, nil, '已学')
        learnedCB:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 150, 17)
        learnedCB:SetChecked(true)

        local plannedCB = DFUI.tools.CreateIndiCheckbox(frame, nil, '规划')
        plannedCB:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 260, 17)
        plannedCB:SetChecked(false)
        plannedCB.label:SetTextColor(0, 1, 1)

        -- 方案导航（默认隐藏，规划模式才显示）
        local prevPlanBtn = CreateFrame('Button', nil, frame)
        prevPlanBtn:SetWidth(16)
        prevPlanBtn:SetHeight(16)
        prevPlanBtn:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 370, 17)
        prevPlanBtn:SetNormalTexture('Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up')
        prevPlanBtn:SetPushedTexture('Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down')
        prevPlanBtn:SetHighlightTexture('Interface\\Buttons\\UI-Common-MouseHilight')
        prevPlanBtn:SetScript('OnClick', function()
            if planData then SwitchPlan(planData.selectedPlan - 1) end
        end)
        prevPlanBtn:Hide()

        local planLabel = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
        planLabel:SetPoint('LEFT', prevPlanBtn, 'RIGHT', 5, 0)
        planLabel:SetText('方案 1/' .. MAX_PLANS)
        planLabel:SetTextColor(0, 1, 1)
        planLabel:Hide()

        local nextPlanBtn = CreateFrame('Button', nil, frame)
        nextPlanBtn:SetWidth(16)
        nextPlanBtn:SetHeight(16)
        nextPlanBtn:SetPoint('LEFT', planLabel, 'RIGHT', 5, 0)
        nextPlanBtn:SetNormalTexture('Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up')
        nextPlanBtn:SetPushedTexture('Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down')
        nextPlanBtn:SetHighlightTexture('Interface\\Buttons\\UI-Common-MouseHilight')
        nextPlanBtn:SetScript('OnClick', function()
            if planData then SwitchPlan(planData.selectedPlan + 1) end
        end)
        nextPlanBtn:Hide()

        local resetBtn = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
        resetBtn:SetWidth(60)
        resetBtn:SetHeight(22)
        resetBtn:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -220, 17)
        resetBtn:SetText('重置')
        resetBtn:SetScript('OnClick', function()
            ResetPlan(nil)
        end)
        resetBtn:SetScript('OnEnter', function()
            GameTooltip:SetOwner(this, 'ANCHOR_TOP')
            GameTooltip:SetText('Shift+点击 重置全部规划点')
            GameTooltip:Show()
        end)
        resetBtn:SetScript('OnLeave', function() GameTooltip:Hide() end)
        resetBtn:Hide()

        frame.prevPlanBtn = prevPlanBtn
        frame.planLabel = planLabel
        frame.nextPlanBtn = nextPlanBtn
        frame.resetBtn = resetBtn

        -- 模式切换逻辑
        local function SetPlanUIVisible(visible)
            local fn = visible and 'Show' or 'Hide'
            prevPlanBtn[fn](prevPlanBtn)
            planLabel[fn](planLabel)
            nextPlanBtn[fn](nextPlanBtn)
            resetBtn[fn](resetBtn)
        end

        learnedCB:SetScript('OnClick', function()
            learnMode = 'learned'
            learnedCB:SetChecked(true)
            plannedCB:SetChecked(false)
            SetPlanUIVisible(false)
            Update()
        end)

        plannedCB:SetScript('OnClick', function()
            learnMode = 'planned'
            plannedCB:SetChecked(true)
            learnedCB:SetChecked(false)
            SetPlanUIVisible(true)
            Update()
        end)

        local scaleCheckbox = DFUI.tools.CreateIndiCheckbox(frame, nil, 'Small')
        scaleCheckbox:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 50, 17)

        if not DFUI_CUR_PROFILE['TalentFrameSmall'] then DFUI_CUR_PROFILE['TalentFrameSmall'] = nil end
        scaleCheckbox:SetChecked(DFUI_CUR_PROFILE['TalentFrameSmall'])
        if DFUI_CUR_PROFILE['TalentFrameSmall'] then
            frame:SetScale(0.8)
        end

        scaleCheckbox:SetScript('OnClick', function()
            if this:GetChecked() then
                frame:SetScale(0.8)
                DFUI_CUR_PROFILE['TalentFrameSmall'] = 1
            else
                frame:SetScale(1.0)
                DFUI_CUR_PROFILE['TalentFrameSmall'] = nil
            end
        end)

        frame:Hide()
        table.insert(UISpecialFrames, 'BLF_TalentFrame')
    end

    local function CreateTreeFrames()
        local xOffsets = {0, 340, 680}
        for i = 1, 3 do
            local treeFrame = CreateFrame('Frame', nil, frame)
            treeFrame:SetWidth(300)
            treeFrame:SetHeight(500)
            treeFrame:SetPoint('TOPLEFT', frame, 'TOPLEFT', xOffsets[i] + 20, -50)
            -- debugframe(treeFrame)
            local header = treeFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
            header:SetPoint('TOP', treeFrame, 'TOP', 0, 20)

            local pointsText = treeFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
            pointsText:SetPoint('TOP', treeFrame, 'TOP', 0, 0)
            pointsText:SetTextColor(1, 1, 1)

            local branchFrame = CreateFrame('Frame', nil, treeFrame)
            branchFrame:SetAllPoints()

            local arrowFrame = CreateFrame('Frame', nil, treeFrame)
            arrowFrame:SetAllPoints()

            local bgTopLeft = treeFrame:CreateTexture(nil, 'BACKGROUND')
            bgTopLeft:SetWidth(200)
            bgTopLeft:SetHeight(300)
            bgTopLeft:SetPoint('TOPLEFT', treeFrame, 'TOPLEFT', 20, -30)

            local bgTopRight = treeFrame:CreateTexture(nil, 'BACKGROUND')
            bgTopRight:SetWidth(100)
            bgTopRight:SetHeight(300)
            bgTopRight:SetPoint('TOPRIGHT', treeFrame, 'TOPRIGHT', 20, -30)

            local bgBottomLeft = treeFrame:CreateTexture(nil, 'BACKGROUND')
            bgBottomLeft:SetWidth(200)
            bgBottomLeft:SetHeight(200)
            bgBottomLeft:SetPoint('BOTTOMLEFT', treeFrame, 'BOTTOMLEFT', 20, -30)

            local bgBottomRight = treeFrame:CreateTexture(nil, 'BACKGROUND')
            bgBottomRight:SetWidth(100)
            bgBottomRight:SetHeight(200)
            bgBottomRight:SetPoint('BOTTOMRIGHT', treeFrame, 'BOTTOMRIGHT', 20, -30)

            treeFrames[i] = {
                frame = treeFrame,
                header = header,
                pointsText = pointsText,
                branchFrame = branchFrame,
                arrowFrame = arrowFrame
            }

            local _, _, _, fileName = GetTalentTabInfo(i)
            local base = fileName and ('Interface\\TalentFrame\\' .. fileName .. '-') or 'Interface\\TalentFrame\\MageFire-'

            bgTopLeft:SetTexture(base .. 'TopLeft')
            bgTopLeft:SetAlpha(0.7)
            bgTopRight:SetTexture(base .. 'TopRight')
            bgTopRight:SetAlpha(0.7)
            bgBottomLeft:SetTexture(base .. 'BottomLeft')
            bgBottomLeft:SetAlpha(0.7)
            bgBottomRight:SetTexture(base .. 'BottomRight')
            bgBottomRight:SetAlpha(0.7)

            local borderTop = treeFrame:CreateTexture(nil, 'OVERLAY')
            borderTop:SetTexture('Interface\\Buttons\\WHITE8X8')
            -- borderTop:SetVertexColor(1,0.82,0, .4)
            borderTop:SetVertexColor(0,0,0, .4)
            borderTop:SetWidth(265)
            -- borderTop:SetHeight(2)
            borderTop:SetHeight(4)
            borderTop:SetPoint('TOPLEFT', bgTopLeft, 'TOPLEFT', 2, 0)

            local borderBottom = treeFrame:CreateTexture(nil, 'OVERLAY')
            borderBottom:SetTexture('Interface\\Buttons\\WHITE8X8')
            -- borderBottom:SetVertexColor(0,0,0, .9)
            borderBottom:SetGradientAlpha('VERTICAL', 0, 0, 0, .9, 0, 0, 0, 0)
            borderBottom:SetWidth(270)
            borderBottom:SetHeight(40)
            borderBottom:SetPoint('LEFT', bgBottomLeft, 'BOTTOMLEFT', 0, 100)

            local borderLeft = treeFrame:CreateTexture(nil, 'OVERLAY')
            borderLeft:SetTexture('Interface\\Buttons\\WHITE8X8')
            borderLeft:SetVertexColor(0,0,0, .4)
            borderLeft:SetWidth(4)
            borderLeft:SetHeight(420)
            borderLeft:SetPoint('TOPLEFT', bgTopLeft, 'TOPLEFT', 0, 0)

            local borderRight = treeFrame:CreateTexture(nil, 'OVERLAY')
            borderRight:SetTexture('Interface\\Buttons\\WHITE8X8')
            borderRight:SetVertexColor(0,0,0, .4)
            borderRight:SetWidth(4)
            borderRight:SetHeight(420)
            borderRight:SetPoint('TOPRIGHT', bgTopRight, 'TOPRIGHT', -30, 0)

            local whiteBottom = treeFrame:CreateTexture(nil, 'BACKGROUND')
            whiteBottom:SetTexture('Interface\\Buttons\\WHITE8X8')
            -- whiteBottom:SetVertexColor(0,0,0, .1)
            whiteBottom:SetGradientAlpha('VERTICAL', 0, 0, 0, 0, 0, 0, 0, .9)
            whiteBottom:SetWidth(270)
            whiteBottom:SetHeight(70)
            whiteBottom:SetPoint('TOP', borderBottom, 'BOTTOM', 0, 1)

            branchArrays[i] = {}
            branchTextures[i] = {}
            arrowTextures[i] = {}
            for tier = 1, 8 do
                branchArrays[i][tier] = {}
                for col = 1, 4 do
                    branchArrays[i][tier][col] = {id=nil, up=0, left=0, right=0, down=0, leftArrow=0, rightArrow=0, topArrow=0}
                end
            end
        end
    end

    local function CreateTalentButton(tabIndex, talentIndex, tier, column)
        local treeFrame = treeFrames[tabIndex].frame
        local button = CreateFrame('Button', nil, treeFrame)
        button:SetWidth(32)
        button:SetHeight(32)

        local x = (column - 1) * 63 + 35
        local y = -(tier - 1) * 63 - 50
        button:SetPoint('TOPLEFT', treeFrame, 'TOPLEFT', x + 10, y)

        local icon = button:CreateTexture(nil, 'ARTWORK')
        icon:SetAllPoints()

        local border = button:CreateTexture(nil, 'OVERLAY')
        border:SetTexture('Interface\\Buttons\\UI-ActionButton-Border')
        border:SetBlendMode('ADD')
        border:SetWidth(64)
        border:SetHeight(64)
        border:SetPoint('CENTER', button, 'CENTER', 0, 0)

        local hoverBorder = button:CreateTexture(nil, 'OVERLAY')
        hoverBorder:SetTexture('Interface\\Buttons\\UI-ActionButton-Border')
        hoverBorder:SetBlendMode('ADD')
        hoverBorder:SetWidth(64)
        hoverBorder:SetHeight(64)
        hoverBorder:SetPoint('CENTER', button, 'CENTER', 0, 0)
        hoverBorder:SetVertexColor(1, 0.82, 0)
        hoverBorder:Hide()

        local rankBg = button:CreateTexture(nil, 'OVERLAY')
        rankBg:SetTexture(0, 0, 0, .5)
        rankBg:SetWidth(37)
        rankBg:SetHeight(12)
        rankBg:SetPoint('TOP', button, 'BOTTOM', 0, -2)

        local rank = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
        rank:SetPoint('CENTER', rankBg, 'CENTER', 0, 0)

        -- 规划点数叠加显示（青色小字，已学模式下有规划点时显示）
        local plannedRankBg = button:CreateTexture(nil, 'OVERLAY')
        plannedRankBg:SetTexture(0, 0, 0, 0.6)
        plannedRankBg:SetWidth(14)
        plannedRankBg:SetHeight(12)
        plannedRankBg:SetPoint('TOPLEFT', button, 'TOPLEFT', -4, 4)
        plannedRankBg:Hide()

        local plannedRank = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
        plannedRank:SetPoint('CENTER', plannedRankBg, 'CENTER', 0, 0)
        plannedRank:SetTextColor(0, 1, 1)
        plannedRank:Hide()

        button.icon = icon
        button.border = border
        button.hoverBorder = hoverBorder
        button.rank = rank
        button.plannedRankBg = plannedRankBg
        button.plannedRank = plannedRank
        button.tabIndex = tabIndex
        button.talentIndex = talentIndex

        button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

        -- 规划模式 tooltip 构建函数
        local function ShowTalentTooltip(btn)
            GameTooltip:SetOwner(btn, 'ANCHOR_RIGHT')
            if learnMode == 'planned' and DFUI_TalentDescriptions then
                local tName, _, _, _, rank, maxRank = GetPlannedTalentInfo(btn.tabIndex, btn.talentIndex)
                if rank >= 1 then
                    -- 已点：显示当前等级
                    local spellId = GetTalentSpellForRank(btn.tabIndex, btn.talentIndex, rank)
                    local data = spellId and DFUI_TalentDescriptions[spellId]
                    if data then
                        GameTooltip:SetText(data.name, 1, 1, 1)
                        GameTooltip:AddLine(data.rank .. '    (' .. rank .. '/' .. maxRank .. ')', 1, 1, 1)
                        GameTooltip:AddLine(' ')
                        GameTooltip:AddLine('当前等级:', 0, 1, 0)
                        GameTooltip:AddLine(data.desc, 1, 0.82, 0, true)
                        -- 未满级则追加下一等级
                        if rank < maxRank then
                            local nextSpellId = GetTalentSpellForRank(btn.tabIndex, btn.talentIndex, rank + 1)
                            local nextData = nextSpellId and DFUI_TalentDescriptions[nextSpellId]
                            if nextData then
                                GameTooltip:AddLine(' ')
                                GameTooltip:AddLine('下一等级:', 0, 1, 0)
                                GameTooltip:AddLine(nextData.desc, 1, 0.82, 0, true)
                            end
                        end
                        GameTooltip:Show()
                        return
                    end
                else
                    -- 未点：只显示下一等级（rank 1）
                    local nextSpellId = GetTalentSpellForRank(btn.tabIndex, btn.talentIndex, 1)
                    local nextData = nextSpellId and DFUI_TalentDescriptions[nextSpellId]
                    if nextData then
                        GameTooltip:SetText(nextData.name, 1, 1, 1)
                        GameTooltip:AddLine('(0/' .. maxRank .. ')', 0.5, 0.5, 0.5)
                        GameTooltip:AddLine(' ')
                        GameTooltip:AddLine('下一等级:', 0, 1, 0)
                        GameTooltip:AddLine(nextData.desc, 1, 0.82, 0, true)
                        GameTooltip:Show()
                        return
                    end
                end
            end
            -- 回退到原生 tooltip
            GameTooltip:SetTalent(btn.tabIndex, btn.talentIndex)
        end

        button:SetScript('OnClick', function()
            if learnMode == 'planned' then
                -- 规划模式：左键加点，右键减点
                if arg1 == 'LeftButton' then
                    PlanTalent(this.tabIndex, this.talentIndex)
                elseif arg1 == 'RightButton' then
                    UnplanTalent(this.tabIndex, this.talentIndex)
                end
                ShowTalentTooltip(this)
            else
                -- 已学模式：左键学习天赋
                if arg1 == 'LeftButton' then
                    local _, _, talentTier, _, talentRank, talentMaxRank, _, talentMeetsPrereq = GetTalentInfo(this.tabIndex, this.talentIndex)
                    local characterPoints = UnitCharacterPoints('player')
                    local _, _, tabPointsSpent = GetTalentTabInfo(this.tabIndex)
                    local talentTierUnlocked = ((talentTier - 1) * 5 <= tabPointsSpent)
                    if talentMeetsPrereq and talentTierUnlocked and characterPoints > 0 and talentRank < talentMaxRank then
                        LearnTalent(this.tabIndex, this.talentIndex)
                    end
                end
            end
        end)

        button:SetScript('OnEnter', function()
            this.hoverBorder:Show()
            ShowTalentTooltip(this)
        end)

        button:SetScript('OnLeave', function()
            this.hoverBorder:Hide()
            GameTooltip:Hide()
        end)

        -- 滚轮加减点（仅规划模式）
        button:EnableMouseWheel(true)
        button:SetScript('OnMouseWheel', function()
            if learnMode == 'planned' then
                if arg1 > 0 then
                    PlanTalent(this.tabIndex, this.talentIndex)
                else
                    UnplanTalent(this.tabIndex, this.talentIndex)
                end
                ShowTalentTooltip(this)
            end
        end)

        return button
    end

    local function CheckPrereqsMaxed(tabIndex, talentIndex)
        local prereqs
        if learnMode == 'planned' then
            prereqs = { GetPlannedPrereqs(tabIndex, talentIndex) }
        else
            prereqs = { GetTalentPrereqs(tabIndex, talentIndex) }
        end
        for i = 1, table.getn(prereqs), 3 do
            local prereqTier, prereqColumn, prereqMaxed = prereqs[i], prereqs[i+1], prereqs[i+2]
            if prereqTier and prereqColumn and not prereqMaxed then
                return nil
            end
        end
        return 1
    end

    local function ResetBranches(tabIndex)
        for tier = 1, 8 do
            for col = 1, 4 do
                local node = branchArrays[tabIndex][tier][col]
                node.id = nil
                node.up = 0
                node.down = 0
                node.left = 0
                node.right = 0
                node.rightArrow = 0
                node.leftArrow = 0
                node.topArrow = 0
            end
        end
        for i = 1, table.getn(branchTextures[tabIndex]) do
            branchTextures[tabIndex][i]:Hide()
        end
        for i = 1, table.getn(arrowTextures[tabIndex]) do
            arrowTextures[tabIndex][i]:Hide()
        end
    end

    local function GetTexture(tabIndex, isBranch)
        local textures = isBranch and branchTextures[tabIndex] or arrowTextures[tabIndex]
        for i = 1, table.getn(textures) do
            if not textures[i]:IsVisible() then
                textures[i]:Show()
                return textures[i]
            end
        end
        local parent = isBranch and treeFrames[tabIndex].branchFrame or treeFrames[tabIndex].arrowFrame
        local layer = isBranch and 'ARTWORK' or 'OVERLAY'
        local texturePath = isBranch and 'Interface\\TalentFrame\\UI-TalentBranches' or 'Interface\\TalentFrame\\UI-TalentArrows'

        local texture = parent:CreateTexture(nil, layer)
        texture:SetTexture(texturePath)
        texture:SetWidth(32)
        texture:SetHeight(32)
        table.insert(textures, texture)
        texture:Show()
        return texture
    end

    local function SetBranchTexture(tabIndex, texCoords, xOffset, yOffset)
        local texture = GetTexture(tabIndex, true)
        texture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4])
        texture:SetPoint('TOPLEFT', treeFrames[tabIndex].branchFrame, 'TOPLEFT', xOffset+8, yOffset)
    end

    local function SetArrowTexture(tabIndex, texCoords, xOffset, yOffset)
        local texture = GetTexture(tabIndex, false)
        texture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4])
        texture:SetPoint('TOPLEFT', treeFrames[tabIndex].arrowFrame, 'TOPLEFT', xOffset+8, yOffset)
    end

    local function DrawTalentLines(tabIndex, buttonTier, buttonColumn, tier, column, requirementsMet)
        local reqMet = requirementsMet and 1 or -1
        if buttonColumn == column then

            for i = tier, buttonTier - 1 do
                branchArrays[tabIndex][i][buttonColumn].down = reqMet
                if (i + 1) <= (buttonTier - 1) then
                    branchArrays[tabIndex][i + 1][buttonColumn].up = reqMet
                end
            end
            branchArrays[tabIndex][buttonTier][buttonColumn].topArrow = reqMet
        elseif buttonTier == tier then

            local left = math.min(buttonColumn, column)
            local right = math.max(buttonColumn, column)
            for i = left, right - 1 do
                branchArrays[tabIndex][tier][i].right = reqMet
                branchArrays[tabIndex][tier][i+1].left = reqMet
            end
            if buttonColumn < column then
                branchArrays[tabIndex][buttonTier][buttonColumn].rightArrow = reqMet
            else
                branchArrays[tabIndex][buttonTier][buttonColumn].leftArrow = reqMet
            end
        end
    end

    local function SetTalentPrereqs(tabIndex, buttonTier, buttonColumn, forceDesaturated, tierUnlocked, ...)
        local requirementsMet
        if tierUnlocked and not forceDesaturated then
            requirementsMet = 1
        else
            requirementsMet = nil
        end

        for i = 1, arg.n, 3 do
            local tier = arg[i]
            local column = arg[i+1]
            local isLearnable = arg[i+2]
            if not isLearnable or forceDesaturated then
                requirementsMet = nil
            end
            if tier and column then
                DrawTalentLines(tabIndex, buttonTier, buttonColumn, tier, column, requirementsMet)
            end
        end
        return requirementsMet
    end

    local function DrawBranches(tabIndex)
        for tier = 1, 8 do
            for col = 1, 4 do
                local node = branchArrays[tabIndex][tier][col]
                local xOffset = (col - 1) * 63 + 35 + 2
                local yOffset = -(tier - 1) * 63 - 50 - 2

                if node.id then
                    if node.up ~= 0 then
                        SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS['up'][node.up], xOffset, yOffset + 32)
                    end
                    if node.down ~= 0 then
                        SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS['down'][node.down], xOffset, yOffset - 32 + 1)
                    end
                    if node.left ~= 0 then
                        SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS['left'][node.left], xOffset - 32, yOffset)
                    end
                    if node.right ~= 0 then
                        SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS['right'][node.right], xOffset + 32 + 1, yOffset)
                    end
                    if node.rightArrow ~= 0 then
                        SetArrowTexture(tabIndex, TALENT_ARROW_TEXTURECOORDS['right'][node.rightArrow], xOffset + 16 + 5, yOffset)
                    end
                    if node.leftArrow ~= 0 then
                        SetArrowTexture(tabIndex, TALENT_ARROW_TEXTURECOORDS['left'][node.leftArrow], xOffset - 16 - 5, yOffset)
                    end
                    if node.topArrow ~= 0 then
                        SetArrowTexture(tabIndex, TALENT_ARROW_TEXTURECOORDS['top'][node.topArrow], xOffset, yOffset + 16 + 5)
                    end
                else
                    if node.up ~= 0 and node.down ~= 0 then
                        SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS['up'][node.up], xOffset, yOffset)
                        SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS['down'][node.down], xOffset, yOffset - 32)
                    elseif node.left ~= 0 and node.right ~= 0 then
                        SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS['right'][node.right], xOffset + 32, yOffset)
                        SetBranchTexture(tabIndex, TALENT_BRANCH_TEXTURECOORDS['left'][node.left], xOffset + 1, yOffset)
                    end
                end
            end
        end
    end

    Update = function()
        if not frame or not frame:IsVisible() then return end

        -- 首次构建天赋 spell 映射缓存
        if not talentSpellCache[1] then
            BuildTalentSpellCache()
        end

        local isPlanned = (learnMode == 'planned')
        local plan = GetCurrentPlan()

        for tabIndex = 1, 3 do
            local name, _, realPointsSpent = GetTalentTabInfo(tabIndex)
            local pointsSpent = (isPlanned and plan) and plan[tabIndex].points or realPointsSpent

            if name then
                treeFrames[tabIndex].header:SetText(name)
                if isPlanned and plan then
                    treeFrames[tabIndex].pointsText:SetText('|cff00ffff规划' .. plan[tabIndex].points .. '|r / 已学' .. realPointsSpent .. ' points')
                else
                    treeFrames[tabIndex].pointsText:SetText(realPointsSpent .. ' points')
                end
            end

            ResetBranches(tabIndex)

            -- 预填充 branchArrays.id 并缓存 GetTalentInfo 结果（避免重复 C-bridge 调用）
            local numTalents = GetNumTalents(tabIndex)
            local talentCache = {}
            for talentIndex = 1, numTalents do
                local tName, tIcon, tTier, tCol, tRank, tMax, tExc, tPrereq = GetTalentInfo(tabIndex, talentIndex)
                talentCache[talentIndex] = { tName, tIcon, tTier, tCol, tRank, tMax, tExc, tPrereq }
                if tTier and tCol then
                    branchArrays[tabIndex][tTier][tCol].id = talentIndex
                end
            end

            for talentIndex = 1, numTalents do
                local buttonKey = tabIndex .. '_' .. talentIndex
                local button = talentButtons[buttonKey]
                if button then
                    -- 从缓存读取天赋数据
                    local cached = talentCache[talentIndex]
                    local talentName, iconTexture, tier, column, rank, maxRank = cached[1], cached[2], cached[3], cached[4], cached[5], cached[6]
                    -- 规划模式用规划 rank 覆盖
                    if isPlanned and plan then
                        rank = plan[tabIndex][talentIndex] or 0
                    end

                    if talentName then
                        button.icon:SetTexture(iconTexture)
                        button.rank:SetText(rank .. '/' .. maxRank)

                        -- 规划点数叠加显示
                        local plannedR = (plan and plan[tabIndex][talentIndex]) or 0
                        if isPlanned then
                            -- 规划模式：rank 文字用青色
                            if rank > 0 then
                                button.rank:SetTextColor(0, 1, 1)
                            else
                                button.rank:SetTextColor(1, 0.82, 0)
                            end
                            button.plannedRank:Hide()
                            button.plannedRankBg:Hide()
                        else
                            -- 已学模式：恢复默认颜色
                            button.rank:SetTextColor(1, 0.82, 0)
                            -- 若当前方案有规划点，用青色小字显示
                            if plannedR > 0 then
                                button.plannedRank:SetText('+' .. plannedR)
                                button.plannedRank:Show()
                                button.plannedRankBg:Show()
                            else
                                button.plannedRank:Hide()
                                button.plannedRankBg:Hide()
                            end
                        end

                        -- 条件计算解锁状态
                        local cp1
                        if isPlanned and plan then
                            cp1 = MAX_TALENT_POINTS - plan.points
                        else
                            cp1 = UnitCharacterPoints('player')
                        end
                        local tierUnlocked = ((tier - 1) * 5 <= pointsSpent)

                        -- 获取前置条件（缓存结果供后续 SetTalentPrereqs 使用）
                        local prereqResults
                        if isPlanned then
                            prereqResults = { GetPlannedPrereqs(tabIndex, talentIndex) }
                        else
                            prereqResults = { GetTalentPrereqs(tabIndex, talentIndex) }
                        end
                        -- 从缓存结果判断前置是否全部满足
                        local prereqsMaxed = 1
                        for pi = 1, table.getn(prereqResults), 3 do
                            if prereqResults[pi] and prereqResults[pi+1] and not prereqResults[pi+2] then
                                prereqsMaxed = nil
                                break
                            end
                        end

                        if rank == maxRank then
                            button.border:SetVertexColor(1.0, 0.82, 0, 1.0)
                            button.icon:SetDesaturated(nil)
                        elseif rank > 0 then
                            button.border:SetVertexColor(1.0, 0.82, 0, .4)
                            button.icon:SetDesaturated(nil)
                        elseif prereqsMaxed and tierUnlocked and cp1 > 0 and rank < maxRank then
                            button.border:SetVertexColor(0.1, 1.0, 0.1, .3)
                            button.icon:SetDesaturated(nil)
                        else
                            button.border:SetVertexColor(0.5, 0.5, 0.5)
                            button.icon:SetDesaturated(1)
                        end

                        -- 分支线条（复用已缓存的 prereqResults）
                        local forceDesaturated
                        if cp1 <= 0 and rank == 0 then
                            forceDesaturated = 1
                        else
                            forceDesaturated = nil
                        end
                        local tierUnlocked2 = tierUnlocked and 1 or nil
                        SetTalentPrereqs(tabIndex, tier, column, forceDesaturated, tierUnlocked2, unpack(prereqResults))
                    end
                end
            end
            DrawBranches(tabIndex)
        end

        -- 底部总点文字
        if isPlanned and plan then
            local used = plan.points
            local left = MAX_TALENT_POINTS - used
            frame.pointsLeft:SetText('|cff00ffff已规划: ' .. used .. '/' .. MAX_TALENT_POINTS .. '  剩余: ' .. left .. '|r')
        else
            local points = UnitCharacterPoints('player')
            frame.pointsLeft:SetText('Talent Points Available: |cFFFFFFFF' .. points .. '|r')
        end

        -- 更新方案标签文字
        if frame.planLabel and planData then
            frame.planLabel:SetText('方案 ' .. planData.selectedPlan .. '/' .. MAX_PLANS)
        end
    end

    local function CreateAllTalents()
        for tabIndex = 1, 3 do
            local numTalents = GetNumTalents(tabIndex)
            for talentIndex = 1, numTalents do
                local name, _, tier, column = GetTalentInfo(tabIndex, talentIndex)
                if name then
                    local button = CreateTalentButton(tabIndex, talentIndex, tier, column)
                    talentButtons[tabIndex .. '_' .. talentIndex] = button
                end
            end
        end
    end

    local function ToggleFrame()
        if not frame then
            CreateMainFrame()
            CreateTreeFrames()
            CreateAllTalents()
            InitPlanData()
        end
        if frame:IsVisible() then
            frame:Hide()
        else
            frame:Show()
            Update()
        end
    end

    local eventFrame = CreateFrame('Frame')
    eventFrame:RegisterEvent('CHARACTER_POINTS_CHANGED')
    eventFrame:RegisterEvent('PLAYER_LEVEL_UP')
    eventFrame:SetScript('OnEvent', function()
        Update()
    end)

    -- _G['SLASH_BLFTALENTS1'] = '/ttest'
    -- _G.SlashCmdList['BLFTALENTS'] = ToggleFrame

    -- keybind hook
    _G.ToggleTalentFrame = function()
        if UnitLevel('player') < 10 then
            return
        end

        if frame and frame:IsVisible() then
            pcall(PlaySound, "TalentScreenClose")
        else
            pcall(PlaySound, "TalentScreenOpen")
        end

        ToggleFrame()
        UpdateMicroButtons()
    end

    -- micromenu pushed hook
    -- totaly bad place but cant move it elsewhere because of bad code organisation
    local originalUpdateMicroButtons = UpdateMicroButtons
    _G.UpdateMicroButtons = function()
        originalUpdateMicroButtons()
        if frame and frame:IsVisible() then
            TalentMicroButton:SetButtonState('PUSHED', 1)
        else
            TalentMicroButton:SetButtonState('NORMAL')
        end
        if DFUI and DFUI.menuframe and DFUI.menuframe:IsVisible() then
            MainMenuMicroButton:SetButtonState('PUSHED', 1)
        end
    end
end)
