DFUI_LibQuestXP = DFUI_LibQuestXP or {}

function DFUI_LibQuestXP.GetAdjustedXP(xp, qLevel)
    if not xp or xp == 0 then return 0 end

    local charLevel = UnitLevel("player")
    if charLevel >= MAX_PLAYER_LEVEL then return 0 end

    if not qLevel then return xp end

    local diffFactor = 2 * (qLevel - charLevel) + 20
    if diffFactor < 1 then
        diffFactor = 1
    elseif diffFactor > 10 then
        diffFactor = 10
    end

    xp = xp * diffFactor / 10
    if xp <= 100 then
        xp = 5 * math.floor((xp + 2) / 5)
    elseif xp <= 500 then
        xp = 10 * math.floor((xp + 5) / 10)
    elseif xp <= 1000 then
        xp = 25 * math.floor((xp + 12) / 25)
    else
        xp = 50 * math.floor((xp + 25) / 50)
    end

    return math.floor(xp)
end

function DFUI_LibQuestXP.GetXPByQuestID(questID)
    if not questID or not DFUI_LibQuestXPDB then return nil end
    local entry = DFUI_LibQuestXPDB[questID]
    if not entry then return nil end
    return DFUI_LibQuestXP.GetAdjustedXP(entry.xp, entry.level)
end
