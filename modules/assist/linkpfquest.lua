----------------------------------------------------------------------
-- DFUI.Assist  --  Ctrl+点击任务条发英文任务链接
-- 移植 Automatonex pfQuestSendLink。在任务日志里 Ctrl+点击任务标题，
-- 向聊天编辑框插入英文名任务链接。英文名直接读 pfQuest 自带的
-- pfDB["quests"]["enUS"]，无需额外数据库。
--
-- 软依赖 pfQuest：缺 pfQuest 数据则勾选时提示一次并优雅降级。
-- pfUI.api.rgbhex 用自有难度色函数替代（DFUI 非 pfUI 环境）。
----------------------------------------------------------------------

setfenv(1, DFUI:GetEnv())   -- 跑在 DFUI.env：hooksecurefunc 等 env 内助手才可见（assist 文件无此行会取到 nil）

local L = DFUI.Assist.L
local warned = false

local function rgbhex(r, g, b)
    return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

local function diffHex(level)
    local fn = GetDifficultyColor or GetQuestDifficultyColor
    if fn then
        local c = fn(level)
        if type(c) == "table" and c.r then return rgbhex(c.r, c.g, c.b) end
    end
    return "|cffffff00"   -- 默认黄色
end

local function insertQuestLink(qid, fallback)
    local data = pfDB and pfDB["quests"]
    if not data then
        if not warned then
            DFUI.Assist.Print(L["linkNoPfQuest"])
            warned = true
        end
        return
    end
    qid = qid or 0
    local enName = data["enUS"] and data["enUS"][qid] and data["enUS"][qid]["T"]
    enName = enName or fallback or UNKNOWN
    local level = (data["data"] and data["data"][qid] and data["data"][qid]["lvl"]) or 0

    ChatFrameEditBox:Show()
    if qid > 0 and pfQuest_config and pfQuest_config["questlinks"] == "1" then
        ChatFrameEditBox:Insert(diffHex(level) .. "|Hquest:" .. qid .. ":" .. level .. "|h[" .. enName .. "]|h|r")
    else
        ChatFrameEditBox:Insert("[" .. enName .. "]")
    end
end

DFUI.Assist:register({
    key = "linkPfQuest",
    title = L["linkPfQuest"],
    desc = L["linkPfQuestDesc"],
    default = false,
    load = function(self)
        if type(QuestLogTitleButton_OnClick) ~= "function" then return end

        hooksecurefunc("QuestLogTitleButton_OnClick", function(button)
            if not DFUI.Assist:IsEnabled("linkPfQuest") then return end
            if not IsControlKeyDown() then return end
            if this.isHeader then return end
            if not (ChatFrameEditBox and ChatFrameEditBox:IsVisible()) then return end

            local scrollFrame = EQL3_QuestLogListScrollFrame
                or ShaguQuest_QuestLogListScrollFrame or QuestLogListScrollFrame
            local offset = scrollFrame and FauxScrollFrame_GetOffset(scrollFrame) or 0
            local questIndex = this:GetID() + offset

            local title
            if pfQuestCompat and pfQuestCompat.GetQuestLogTitle then
                title = pfQuestCompat.GetQuestLogTitle(questIndex)
            else
                title = GetQuestLogTitle(questIndex)
            end

            local qid = 0
            if pfDatabase and pfDatabase.GetQuestIDs then
                local ids = pfDatabase:GetQuestIDs(questIndex)
                qid = (ids and tonumber(ids[1])) or 0
            end

            insertQuestLink(qid, title)
        end, true)   -- POST-hook：原版选中任务后再插链接
    end,
})
