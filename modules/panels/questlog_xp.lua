setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("QuestLogXP", {
    enabled = {true},
})

DFUI:NewMod("QuestLogXP", 6, function()
    if not _G.DFUI_QuestXPCache then _G.DFUI_QuestXPCache = {} end
    local cache = _G.DFUI_QuestXPCache
    local LibXP = _G.DFUI_LibQuestXP

    local function extractXP(text)
        if not text then return nil end
        if string.find(text, "经验") or string.find(text, "[Ee]xperience") or string.find(text, " XP") then
            local _, _, n = string.find(text, "(%d[%d,]*)")
            if n then
                n = string.gsub(n, ",", "")
                return tonumber(n)
            end
        end
        return nil
    end

    local function scanPanelForXP(panel)
        if not panel then return nil end
        local regions = {panel:GetRegions()}
        for i = 1, table.getn(regions) do
            local r = regions[i]
            if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                local xp = extractXP(r:GetText())
                if xp then return xp end
            end
        end
        return nil
    end

    local function captureFromQuestFrame()
        local title = GetTitleText and GetTitleText()
        if not title or title == "" then return end

        local xp = scanPanelForXP(QuestFrameDetailPanel)
                or scanPanelForXP(QuestFrameProgressPanel)
                or scanPanelForXP(QuestFrameRewardPanel)
        if xp then cache[title] = xp end
    end

    local captureDirty = false
    local capFrame = CreateFrame("Frame")
    capFrame:RegisterEvent("QUEST_DETAIL")
    capFrame:RegisterEvent("QUEST_PROGRESS")
    capFrame:RegisterEvent("QUEST_COMPLETE")
    capFrame:SetScript("OnEvent", function() captureDirty = true end)
    capFrame:SetScript("OnUpdate", function()
        if captureDirty then
            captureDirty = false
            captureFromQuestFrame()
        end
    end)

    -- 先 db，后 title 缓存；返回 number 或 nil
    local function resolveXP(qlogid, title)
        local xp
        if LibXP and pfDatabase and pfDatabase.GetQuestIDs then
            local qids = pfDatabase:GetQuestIDs(qlogid)
            if qids and type(qids) == "table" and table.getn(qids) > 0 then
                xp = LibXP.GetXPByQuestID(qids[1])
            end
        end
        if not xp then xp = cache[title] end
        return xp
    end

    -- GetQuestIDs 很贵，滚动会频繁触发刷新，按任务标题缓存解析结果
    local xpByTitle = {}

    local function ensureFS(button)
        local fs = button.dfuiXP
        if not fs then
            fs = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetJustifyH("LEFT")
            local bf = button:GetFontString() -- 字体与该行文字一致
            if bf then fs:SetFont(bf:GetFont()) end
            button.dfuiXP = fs
        end
        return fs
    end

    local function updateListXP()
        if not QuestLogFrame:IsVisible() then return end
        local n = GetNumQuestLogEntries()
        local offset = FauxScrollFrame_GetOffset(QuestLogListScrollFrame)
        for i = 1, QUESTS_DISPLAYED do
            local button = _G["QuestLogTitle"..i]
            if button then
                local fs = ensureFS(button)
                local questIndex = i + offset
                local title, level, _, isHeader
                if questIndex <= n then
                    title, level, _, isHeader = GetQuestLogTitle(questIndex)
                end
                local nameFS = button:GetFontString()
                if questIndex > n or isHeader or not title or title == "" or not nameFS then
                    fs:Hide()
                else
                    local xp = xpByTitle[title]
                    if xp == nil then
                        xp = resolveXP(questIndex, title)
                        xpByTitle[title] = xp or false
                    end
                    fs:SetText(xp and xp > 0 and ("(+"..xp.."xp)") or "(+?xp)")

                    -- 难度色（按任务等级）
                    local c = level and level > 0 and GetDifficultyColor and GetDifficultyColor(level)
                    if c then fs:SetTextColor(c.r, c.g, c.b) else fs:SetTextColor(1, 0.82, 0) end

                    -- 紧跟任务名结尾：锚到行文字 fontstring 的 LEFT + 文字宽 + 2px
                    fs:ClearAllPoints()
                    fs:SetPoint("LEFT", nameFS, "LEFT", (nameFS:GetStringWidth() or 0) + 2, 0)
                    fs:Show()
                end
            end
        end
    end

    hooksecurefunc("QuestLog_Update", updateListXP, true)
    HookScript(QuestLogFrame, "OnShow", updateListXP)
end)
