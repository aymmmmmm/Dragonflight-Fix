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

    local xpLabel = QuestLogDetailScrollChildFrame:CreateFontString(
        "DFUI_QuestLogXPText", "OVERLAY", "QuestFont"
    )
    xpLabel:Hide()

    local function updateXPDisplay()
        if not QuestLogFrame:IsVisible() then return end

        local qlogid = GetQuestLogSelection()
        if not qlogid or qlogid == 0 then xpLabel:Hide(); return end

        local title = GetQuestLogTitle(qlogid)
        if not title or title == "" then xpLabel:Hide(); return end

        local xp
        if LibXP and pfDatabase and pfDatabase.GetQuestIDs then
            local qids = pfDatabase:GetQuestIDs(qlogid)
            if qids and type(qids) == "table" and table.getn(qids) > 0 then
                xp = LibXP.GetXPByQuestID(qids[1])
            end
        end

        if not xp then xp = cache[title] end

        local rewardTitle = QuestLogRewardTitleText
        if not (rewardTitle and rewardTitle:IsShown()) then
            xpLabel:Hide()
            return
        end

        local bodyFS = QuestLogObjectivesText or QuestLogQuestDescription or rewardTitle
        local r, g, b = bodyFS:GetTextColor()
        xpLabel:SetTextColor(r, g, b)
        xpLabel:SetText("经验值: " .. (xp or "?"))

        local lowest = rewardTitle
        local lowestY = rewardTitle:GetBottom()
        for i = 1, 10 do
            local item = _G["QuestLogItem"..i]
            if item and item:IsShown() then
                local y = item:GetBottom()
                if y and lowestY and y < lowestY then
                    lowest = item
                    lowestY = y
                end
            end
        end
        local children = {QuestLogDetailScrollChildFrame:GetChildren()}
        for i = 1, table.getn(children) do
            local child = children[i]
            local name = child and child:IsShown() and child.GetName and child:GetName()
            if name and string.find(name, "Money") then
                local y = child:GetBottom()
                if y and lowestY and y < lowestY then
                    lowest = child
                    lowestY = y
                end
            end
        end

        xpLabel:ClearAllPoints()
        xpLabel:SetPoint("LEFT", rewardTitle, "LEFT", 0, 0)
        xpLabel:SetPoint("TOP", lowest, "BOTTOM", 0, -8)
        xpLabel:Show()
    end

    local dirty = true
    HookScript(QuestLogFrame, "OnShow", function() dirty = true end)

    local lastSelection = -1
    local updater = CreateFrame("Frame")
    updater:SetScript("OnUpdate", function()
        if not QuestLogFrame:IsVisible() then return end
        local cur = GetQuestLogSelection() or 0
        if cur ~= lastSelection or dirty then
            lastSelection = cur
            dirty = false
            updateXPDisplay()
        end
    end)
end)
