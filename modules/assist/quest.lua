----------------------------------------------------------------------
-- DFUI.Assist  --  自动任务（接受 / 交还，两个独立开关）
-- 借鉴 Automatonex/Modules/QuestAutomation.lua 的稳健做法：
--   用 GossipTitleButton.type / QuestTitleButton + button:Click()，
--   不解包 GetGossip*Quests 返回值。
-- 安全：只点“任务相关”按钮，绝不自动点普通 gossip 选项（避免误进
--   商人/飞行点/训练师）。多奖励任务保留给玩家手动选。
--
-- 拆成两个 mod：autoQuestAccept（接）/ autoQuestTurnin（交），共享
-- 下面的任务状态表。GOSSIP/GREETING 每次只处理一个动作即 return，
-- 靠对话窗自动重开驱动下一个（避免点击已失效的旧按钮）。
----------------------------------------------------------------------

local L = DFUI.Assist.L

local completed = {}     -- [questTitle] = true  可交
local incomplete = {}    -- [questTitle] = true  进行中

local function alt()
    return IsAltKeyDown and IsAltKeyDown()
end

-- 去色码 / 等级前缀 / 括号后缀，得到纯任务名
local function stripText(text)
    if not text then return "" end
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x(.-)|r", "%1")
    text = string.gsub(text, "%[.*%]%s*", "")
    text = string.gsub(text, "(.+) %(.+%)", "%1")
    return text
end

local function refreshQuestState()
    local sel = GetQuestLogSelection()
    local n = GetNumQuestLogEntries()
    completed = {}
    incomplete = {}
    if n and n > 0 then
        for i = 1, n do
            SelectQuestLogEntry(i)
            local title, _, _, _, _, _, isComplete = GetQuestLogTitle(i)
            local noObjectives = GetNumQuestLeaderBoards(i) == 0
            if title then
                if isComplete or noObjectives then
                    completed[title] = true
                else
                    incomplete[title] = true
                end
            end
        end
    end
    SelectQuestLogEntry(sel)
end

-- 交还领奖：单一/无奖励自动领，多奖励留给玩家
local function takeReward()
    local n = GetNumQuestChoices()
    if n > 1 then return end           -- 多选奖励：留给玩家手动选
    if n == 1 then
        GetQuestReward(1)              -- 单选奖励：必须 GetQuestReward 选中才交得掉
    elseif QuestFrameCompleteQuestButton then
        QuestFrameCompleteQuestButton:Click()   -- 无奖励选择：点完成即可
    end
end

----------------------------------------------------------------------
-- 接受任务
----------------------------------------------------------------------
DFUI.Assist:register({
    key = "autoQuestAccept",
    title = L["autoQuestAccept"],
    desc = L["autoQuestAcceptDesc"],
    default = false,
    events = {
        GOSSIP_SHOW = function(self)
            if alt() then return end
            for i = 1, 32 do
                local b = getglobal("GossipTitleButton" .. i)
                if b and b:IsVisible() and b.type == "Available" then
                    b:Click()
                    return
                end
            end
        end,
        QUEST_DETAIL = function(self)
            if not alt() then AcceptQuest() end
        end,
        QUEST_GREETING = function(self)
            if alt() then return end
            for i = 1, 32 do
                local b = getglobal("QuestTitleButton" .. i)
                if b and b:IsVisible() then
                    local t = stripText(b:GetText())
                    if not completed[t] and not incomplete[t] then
                        b:Click()                 -- 不在日志 = 新任务，接
                        return
                    end
                end
            end
        end,
        QUEST_LOG_UPDATE = function(self)
            refreshQuestState()
        end,
    },
})

----------------------------------------------------------------------
-- 交还任务
----------------------------------------------------------------------
DFUI.Assist:register({
    key = "autoQuestTurnin",
    title = L["autoQuestTurnin"],
    desc = L["autoQuestTurninDesc"],
    default = false,
    events = {
        GOSSIP_SHOW = function(self)
            if alt() then return end
            for i = 1, 32 do
                local b = getglobal("GossipTitleButton" .. i)
                if b and b:IsVisible() and b.type == "Active" then
                    local t = stripText(b:GetText())
                    if completed[t] then
                        b:Click()                 -- 可交：点开进度窗
                        return
                    end
                end
            end
        end,
        QUEST_PROGRESS = function(self)
            if not alt() and IsQuestCompletable() then
                CompleteQuest()
            end
        end,
        QUEST_COMPLETE = function(self)
            if not alt() then takeReward() end
        end,
        QUEST_GREETING = function(self)
            if alt() then return end
            for i = 1, 32 do
                local b = getglobal("QuestTitleButton" .. i)
                if b and b:IsVisible() then
                    local t = stripText(b:GetText())
                    if completed[t] then
                        b:Click()                 -- 交
                        return
                    end
                end
            end
        end,
        QUEST_LOG_UPDATE = function(self)
            refreshQuestState()
        end,
    },
})
