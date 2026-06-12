setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("QuestDialog", {
    enabled = {true},
})

DFUI:NewMod("QuestDialog", 5, function()
    -- 共通换皮（青铜金属框/岩石底/羊皮纸/凹陷/头像/红关闭，同任务日志/商人）
    local customBg = DFUI.SkinQuestStyleFrame(QuestFrame, {
        name     = "DFUI_QuestBg",
        panels   = {QuestFrameDetailPanel, QuestFrameProgressPanel, QuestFrameRewardPanel, QuestFrameGreetingPanel, QuestFrame},
        portrait = QuestFramePortrait,
        nameText = QuestFrameNpcNameText,
        onClose  = function() HideUIPanel(QuestFrame) end,
    })

    -- minimal 滚动条接管 4 个详情 ScrollFrame（哪个 panel 可见才更新）
    DFUI.AttachMinimalScrolls(QuestFrame, {
        {sf = "QuestDetailScrollFrame",   sb = "QuestDetailScrollFrameScrollBar"},
        {sf = "QuestProgressScrollFrame", sb = "QuestProgressScrollFrameScrollBar"},
        {sf = "QuestRewardScrollFrame",   sb = "QuestRewardScrollFrameScrollBar"},
        {sf = "QuestGreetingScrollFrame", sb = "QuestGreetingScrollFrameScrollBar"},
    })

    -- 底部按钮重定位（锚 customBg 落在金属框内；左：接受/完成；右：拒绝/告别/取消）
    -- vanilla 详情页 Decline 锚定 Accept，且 panel OnShow 时重设 → hook 各 panel OnShow 在 vanilla 之后重定位
    local function place(name, left)
        local b = getglobal(name)
        if b and customBg then
            b:ClearAllPoints()
            b:SetFrameLevel(customBg:GetFrameLevel() + 20)  -- 提到 scrollframe 文字之上，防被奖励/任务文字盖住
            if left then
                b:SetPoint("BOTTOMLEFT", customBg, "BOTTOMLEFT", 6, 14)
            else
                b:SetPoint("BOTTOMRIGHT", customBg, "BOTTOMRIGHT", -26, 14)
            end
        end
    end
    local function repositionButtons()
        place("QuestFrameAcceptButton", true)
        place("QuestFrameDeclineButton", false)
        place("QuestFrameCompleteButton", true)
        place("QuestFrameCompleteQuestButton", true)
        place("QuestFrameGoodbyeButton", false)
        place("QuestFrameGreetingGoodbyeButton", false)
        place("QuestFrameCancelButton", false)
    end
    repositionButtons()
    if not QuestFrame._dfBtnHooked then   -- 守护：reload 不重复叠加 panel OnShow hook
        QuestFrame._dfBtnHooked = true
        local btnPanels = {"QuestFrameDetailPanel", "QuestFrameProgressPanel", "QuestFrameRewardPanel", "QuestFrameGreetingPanel"}
        for i = 1, table.getn(btnPanels) do
            local p = getglobal(btnPanels[i])
            if p then HookScript(p, "OnShow", repositionButtons) end
        end
    end

    -- 奖励/进度物品 hover：retail 极简，隐藏原生 HIGHLIGHT region
    local itemPrefixes = {"QuestRewardItem", "QuestProgressItem", "QuestDetailItem"}
    for _, prefix in ipairs(itemPrefixes) do
        for i = 1, 10 do
            local item = getglobal(prefix .. i)
            if item then
                for _, region in ipairs({item:GetRegions()}) do
                    if region.GetDrawLayer and region:GetDrawLayer() == "HIGHLIGHT" then
                        region:SetTexture(nil)
                        region:Hide()
                    end
                end
            end
        end
    end

    local callbacks = {}
    DFUI:NewCallbacks("QuestDialog", callbacks)
end)
