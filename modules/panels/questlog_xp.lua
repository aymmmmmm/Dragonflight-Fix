setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("QuestLogXP", {
    enabled = {true},
})

DFUI:NewMod("QuestLogXP", 6, function()
    local DB    = _G.DFUI_QuestXPDB     -- [id]={满额经验,任务等级,满级金币铜}
    local NAMES = _G.DFUI_QuestXPNames  -- [名称]=id 或 {id,...}

    -- ===== Turtle 自定义经验衰减（源码 QuestDef.cpp Quest::XPValue）=====
    -- 放宽到任务等级 +25 才衰减，保底 10%（永不归 0），向上取整
    local function scaleXP(fullXP, pLevel, qLevel)
        if not fullXP or fullXP == 0 then return 0 end
        if not qLevel or qLevel <= 0 then return fullXP end -- 无等级特殊任务不衰减
        local diff = pLevel - qLevel
        if diff <= 25 then return fullXP
        elseif diff <= 27 then return math.ceil(fullXP * 0.8)
        elseif diff == 28 then return math.ceil(fullXP * 0.6)
        elseif diff == 29 then return math.ceil(fullXP * 0.4)
        elseif diff == 30 then return math.ceil(fullXP * 0.2)
        else return math.ceil(fullXP * 0.1) end
    end

    -- 玩家当前等级下该任务实得信息：{kind="xp"/"money", value=N} 或 nil(未知)
    local function resolve(qid, qLevel)
        if not qid or not DB then return nil end
        local e = DB[qid]
        if not e then return nil end
        local fullXP = e[1] or 0
        local lvl    = qLevel or e[2]
        local money  = e[3] or 0
        local pLevel = UnitLevel("player")
        local maxLevel = MAX_PLAYER_LEVEL or 60
        if pLevel >= maxLevel then
            return { kind = "money", value = money }
        end
        return { kind = "xp", value = scaleXP(fullXP, pLevel, lvl) }
    end

    -- 铜 -> "Xg Ys Zc"，0 返回 nil
    local function formatMoney(c)
        if not c or c <= 0 then return nil end
        local g = math.floor(c / 10000)
        local s = math.floor((c - g * 10000) / 100)
        local cc = c - g * 10000 - s * 100
        local out = ""
        if g > 0 then out = out .. g .. "g" end
        if s > 0 then out = out .. (out ~= "" and " " or "") .. s .. "s" end
        if cc > 0 then out = out .. (out ~= "" and " " or "") .. cc .. "c" end
        return out
    end

    -- ===== ID 优先：pfQuest 解析（很贵，按标题缓存）=====
    local qidByTitle = {}
    local function resolveQID(qlogid, title)
        local q = qidByTitle[title]
        if q ~= nil then return q or nil end
        local qid
        if pfDatabase and pfDatabase.GetQuestIDs then
            local qids = pfDatabase:GetQuestIDs(qlogid)
            if qids and type(qids) == "table" and table.getn(qids) > 0 then
                qid = qids[1]
            end
        end
        qidByTitle[title] = qid or false
        return qid
    end

    -- ===== 按名兜底：pfQuest 没装/解析失败时，用任务日志标题(中/英)查 name 索引 =====
    local function resolveByName(title, level)
        if not NAMES or not title then return nil end
        local v = NAMES[title]
        if not v then return nil end
        if type(v) == "number" then return v end
        for i = 1, table.getn(v) do          -- 同名多条：按运行时任务等级选
            local id = v[i]
            local e = DB and DB[id]
            if e and e[2] == level then return id end
        end
        return v[1]                            -- 无等级匹配则取第一条
    end

    -- 生成行尾文本：ID优先 -> 按名兜底 -> 扫描兜底 -> 未知
    local function resolveText(qlogid, title, level)
        local qid = resolveQID(qlogid, title)
        if not (qid and DB and DB[qid]) then   -- pfQuest 拿不到 / ID 不在表里
            local nid = resolveByName(title, level)
            if nid then qid = nid end
        end
        local info = resolve(qid, level)
        if info then
            if info.kind == "money" then
                local m = formatMoney(info.value)
                return m and ("(+" .. m .. ")") or "(+0xp)"
            end
            return "(+" .. info.value .. "xp)"
        end
        return "(+?xp)"
    end

    -- ===== 渲染 =====
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
                    fs:SetText(resolveText(questIndex, title, level))

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
