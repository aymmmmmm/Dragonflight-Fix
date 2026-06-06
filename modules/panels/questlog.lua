setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")

DFUI:NewDefaults("QuestLog", {
    enabled = {true},
})

DFUI:NewMod("QuestLog", 5, function()
    local regions = {QuestLogFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture and string.find(texture, "QuestLog") and not string.find(texture, "Highlight") and not string.find(texture, "Check") then
                region:Hide()
            end
        end
    end

    QuestLogFrameCloseButton:Hide()

    local customBg = DFUI.CreatePaperDollFrame("DFUI_QuestLogBg", QuestLogFrame, 384, 400, 1)
    customBg:SetPoint("TOPLEFT", QuestLogFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", QuestLogFrame, "BOTTOMRIGHT", -91, 50)
    customBg:SetFrameLevel(QuestLogFrame:GetFrameLevel() - 1)

    CenterFrame(QuestLogFrame)
    HookScript(QuestLogFrame, "OnShow", function()
        customBg:Show()
    end)

    -- 顶部木纹已移除：外层统一用 customBg 的岩石底(UI-Background-Rock,同制造面板)

    local bookIcon = customBg:CreateTexture(nil, "ARTWORK")
    bookIcon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon")
    bookIcon:SetPoint("TOPLEFT", customBg, "TOPLEFT", -3, 6)
    bookIcon:SetWidth(56)
    bookIcon:SetHeight(56)

    local leftBg = customBg:CreateTexture(nil, "ARTWORK")
    leftBg:SetTexture(TEX .. "panels\\questlog_left_bg.blp")
    leftBg:SetPoint("TOPLEFT", customBg, "TOPLEFT", 1, -60)
    leftBg:SetPoint("BOTTOM", customBg, "BOTTOM", 0, -310)
    leftBg:SetPoint("RIGHT", customBg, "CENTER", 0, 0)

    local rightBg = customBg:CreateTexture(nil, "ARTWORK")
    rightBg:SetTexture(TEX .. "panels\\questlog_right_bg.blp")
    rightBg:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", -25, -60)
    rightBg:SetPoint("BOTTOM", customBg, "BOTTOM", 0, -173)
    rightBg:SetPoint("LEFT", customBg, "CENTER", 0, 0)

    -- 内容区凹陷槽(DF retail inset)：框住羊皮纸阅读区；bg 隐藏→中间羊皮纸填充不变；外层露 customBg 岩石底
    local contentInset = DFUI.CreateRetailInset(customBg, {
        name        = "DFUI_QuestLogInset",
        anchors     = {1, -60, -25, 6},   -- 左1 顶-60 右-25(羊皮纸右缘) 底+6；滚动条在槽外右侧岩石条
        followFrame = QuestLogFrame,
    })
    contentInset.bg:Hide()                 -- 中间填充不变(露底下 leftBg/rightBg 羊皮纸)

    local bookmark = customBg:CreateTexture(nil, "OVERLAY")
    bookmark:SetTexture(TEX .. "panels\\spellbook_bookmark.blp")
    bookmark:SetPoint("TOP", customBg, "TOP", 7, -55)
    bookmark:SetWidth(50)
    bookmark:SetHeight(400)

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(QuestLogFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    -- 底部三按钮(放弃/共享/退出)链式锚定(Push←Abandon, Exit←Push)，移最左 Abandon 整排跟随左移 2px
    -- 写死 15(=vanilla 17-2) 防 reload 累积偏移
    if QuestLogFrameAbandonButton then
        QuestLogFrameAbandonButton:ClearAllPoints()
        QuestLogFrameAbandonButton:SetPoint("BOTTOMLEFT", QuestLogFrame, "BOTTOMLEFT", 15, 59)
    end

    -- 「追踪任务」(QuestLogTrack,含红色单选)往右20下5：vanilla 锚 ExpandButtonFrame RIGHT (5,10)→(25,5)；写死防累积
    if QuestLogTrack and QuestLogExpandButtonFrame then
        QuestLogTrack:ClearAllPoints()
        QuestLogTrack:SetPoint("LEFT", QuestLogExpandButtonFrame, "RIGHT", 25, 5)
    end

    -- 物品栏 hover：retail 极简思路，hover 时不显示任何高亮（Hide 原生 layer=HIGHLIGHT region）
    for i = 1, 10 do
        local item = getglobal("QuestLogItem" .. i)
        if item then
            for _, region in ipairs({item:GetRegions()}) do
                if region.GetDrawLayer and region:GetDrawLayer() == "HIGHLIGHT" then
                    region:SetTexture(nil)
                    region:Hide()
                end
            end
        end
    end

    -- ============================================================
    -- DF minimal 滚动条：左页任务列表(FauxScrollFrame) + 右页任务详情(ScrollFrame)
    -- 范式同 character.lua 接管 vanilla scroll：隐藏原生箭头/轨道，自建 minimal sb 驱动 vanilla offset
    -- ============================================================
    local function KeepArrowsHideTrack(sbName)
        local sbar = getglobal(sbName)
        if not sbar then return end
        sbar._dfScrollSkinned = true   -- 抢占，挡 scrollbar.lua 青铜换肤
        sbar:Show(); sbar:SetAlpha(1)
        local top = getglobal(sbName .. "Top")
        local mid = getglobal(sbName .. "Middle")
        local bot = getglobal(sbName .. "Bottom")
        if top and top.SetTexture then top:SetTexture(nil); top:Hide() end
        if mid and mid.SetTexture then mid:SetTexture(nil); mid:Hide() end
        if bot and bot.SetTexture then bot:SetTexture(nil); bot:Hide() end
        local thumb = sbar.GetThumbTexture and sbar:GetThumbTexture()
        if thumb then thumb:SetTexture(nil) end
        local function hideArrow(btn)
            if not btn then return end
            btn._dfScrollSkinned = true
            btn:SetAlpha(0); btn:EnableMouse(false)
        end
        hideArrow(getglobal(sbName .. "ScrollUpButton"))
        hideArrow(getglobal(sbName .. "ScrollDownButton"))
    end

    -- 左页列表（FauxScrollFrame）：走 vanilla scrollbar Slider API 驱动 offset（SetValue 触发 QuestLog_Update）
    local function setFauxOffset(sbar, newOff, maxOff)
        if newOff < 0 then newOff = 0 elseif newOff > maxOff then newOff = maxOff end
        local lo, hi = sbar:GetMinMaxValues()
        sbar:SetValue((maxOff > 0) and (lo + newOff / maxOff * (hi - lo)) or lo)
    end
    local function fauxOffsetOf(sbar, maxOff)
        local lo, hi = sbar:GetMinMaxValues()
        if hi <= lo or maxOff <= 0 then return 0 end
        local o = math.floor((sbar:GetValue() - lo) / (hi - lo) * maxOff + 0.5)
        if o < 0 then return 0 elseif o > maxOff then return maxOff end
        return o
    end

    local listSB, detailSB

    if QuestLogListScrollFrame and QuestLogListScrollFrameScrollBar then
        KeepArrowsHideTrack("QuestLogListScrollFrameScrollBar")
        HookScript(QuestLogListScrollFrameScrollBar, "OnShow", function()
            KeepArrowsHideTrack("QuestLogListScrollFrameScrollBar")
        end)
        listSB = DFUI.CreateMinimalScrollbar(QuestLogListScrollFrame, QuestLogListScrollFrameScrollBar, {
            xOffset = -3, scale = 0.8, arrowTopPad = 0, arrowBotPad = 0, topInset = 8, botInset = 8, gap = 7,
            onScrollDelta = function(d)
                local m = math.max(0, GetNumQuestLogEntries() - QUESTS_DISPLAYED)
                setFauxOffset(QuestLogListScrollFrameScrollBar, fauxOffsetOf(QuestLogListScrollFrameScrollBar, m) + d, m)
            end,
            onScrollAbs = function(r)
                local m = math.max(0, GetNumQuestLogEntries() - QUESTS_DISPLAYED)
                setFauxOffset(QuestLogListScrollFrameScrollBar, math.floor(r * m + 0.5), m)
            end,
        })
    end

    -- 右页详情（普通 ScrollFrame）：直接驱动 SetVerticalScroll
    if QuestLogDetailScrollFrame and QuestLogDetailScrollFrameScrollBar then
        KeepArrowsHideTrack("QuestLogDetailScrollFrameScrollBar")
        HookScript(QuestLogDetailScrollFrameScrollBar, "OnShow", function()
            KeepArrowsHideTrack("QuestLogDetailScrollFrameScrollBar")
        end)
        local function setDetailScroll(v)
            local sf = QuestLogDetailScrollFrame
            local range = sf:GetVerticalScrollRange()
            if v < 0 then v = 0 elseif v > range then v = range end
            sf:SetVerticalScroll(v)
        end
        detailSB = DFUI.CreateMinimalScrollbar(QuestLogDetailScrollFrame, QuestLogDetailScrollFrameScrollBar, {
            xOffset = 2, scale = 0.8, arrowTopPad = 0, arrowBotPad = 0, topInset = 8, botInset = 8, gap = 7,  -- 右移对齐木质槽（原 -3）
            onScrollDelta = function(d)
                setDetailScroll(QuestLogDetailScrollFrame:GetVerticalScroll() + d * 24)
            end,
            onScrollAbs = function(r)
                setDetailScroll(r * QuestLogDetailScrollFrame:GetVerticalScrollRange())
            end,
        })
    end

    -- thumb 同步：独立节流 OnUpdate(0.1s)，读 vanilla 状态反推，不碰任何 update 链路
    if listSB or detailSB then
        local syncT = 0
        CreateFrame("Frame"):SetScript("OnUpdate", function()
            syncT = syncT + (arg1 or 0)
            if syncT < 0.1 then return end
            syncT = 0
            if not QuestLogFrame:IsVisible() then return end
            if listSB then
                local total = GetNumQuestLogEntries()
                local m = math.max(0, total - QUESTS_DISPLAYED)
                if m <= 0 then            -- 任务数不足一屏：无需滚动，整条隐藏（retail 行为，免滑块撑满成灰条）
                    listSB:Hide()
                else
                    listSB:Show()
                    listSB.UpdateThumb(fauxOffsetOf(QuestLogListScrollFrameScrollBar, m), m, QUESTS_DISPLAYED, total)
                end
            end
            if detailSB then
                local sf = QuestLogDetailScrollFrame
                local range = sf:GetVerticalScrollRange()
                if range <= 0 then        -- 详情内容不足一屏：无需滚动，整条隐藏（消除右侧"灰蒙蒙"的满格滑块）
                    detailSB:Hide()
                else
                    detailSB:Show()
                    local t, b = sf:GetTop(), sf:GetBottom()
                    local vis = (t and b and (t - b) > 0) and (t - b) or sf:GetHeight()
                    detailSB.UpdateThumb(sf:GetVerticalScroll(), range, vis, vis + range)
                end
            end
        end)
    end

    local callbacks = {}
    DFUI:NewCallbacks("QuestLog", callbacks)
end)
