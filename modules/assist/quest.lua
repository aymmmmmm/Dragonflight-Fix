----------------------------------------------------------------------
-- DFUI.Assist  --  自动任务（接受 / 交还）
-- 借鉴 Automatonex/Modules/QuestAutomation.lua 的稳健做法：
--   用 GossipTitleButton.type / QuestTitleButton + button:Click()，
--   不解包 GetGossip*Quests 返回值。
-- 安全：只点“任务相关”按钮，绝不自动点普通 gossip 选项（避免误进
--   商人/飞行点/训练师）。多奖励任务保留给玩家手动选。
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

DFUI.Assist:register({
    key = "autoQuest",
    title = L["autoQuest"],
    desc = L["autoQuestDesc"],
    default = true,
    events = {
        -- NPC 对话窗：接可用任务 / 交已完成任务
        GOSSIP_SHOW = function(self)
            if alt() then return end
            for i = 1, 32 do
                local b = getglobal("GossipTitleButton" .. i)
                if b and b:IsVisible() then
                    local t = stripText(b:GetText())
                    if b.type == "Available" then
                        b:Click()
                    elseif b.type == "Active" and completed[t] then
                        b:Click()
                    end
                end
            end
        end,

        -- 任务问候窗（多任务列表）
        QUEST_GREETING = function(self)
            if alt() then return end
            for i = 1, 32 do
                local b = getglobal("QuestTitleButton" .. i)
                if b and b:IsVisible() then
                    local t = stripText(b:GetText())
                    if completed[t] then
                        b:Click()                     -- 交
                    elseif not incomplete[t] then
                        b:Click()                     -- 接（不在进行中列表 = 新任务）
                    end
                end
            end
        end,

        -- 任务详情窗：接受
        QUEST_DETAIL = function(self)
            if alt() then return end
            AcceptQuest()
        end,

        -- 任务进度窗：达成则完成
        QUEST_PROGRESS = function(self)
            if alt() then return end
            if IsQuestCompletable() then
                CompleteQuest()
            end
        end,

        -- 任务完成窗：仅单一/无奖励自动领取，多奖励留给玩家
        QUEST_COMPLETE = function(self)
            if alt() then return end
            if GetNumQuestChoices() <= 1 then
                if QuestFrameCompleteQuestButton then
                    QuestFrameCompleteQuestButton:Click()
                end
            end
        end,

        -- 维护可交/进行中任务表（供 GOSSIP/GREETING 判断）
        QUEST_LOG_UPDATE = function(self)
            refreshQuestState()
        end,
    },
})
