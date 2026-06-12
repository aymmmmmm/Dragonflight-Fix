setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Gossip", {
    enabled = {true},
})

DFUI:NewMod("Gossip", 5, function()
    -- 原生材质四角（按 region 对象直接隐藏，比按贴图名可靠）
    if GossipFrameGreetingPanelMaterialTopLeft then GossipFrameGreetingPanelMaterialTopLeft:Hide() end
    if GossipFrameGreetingPanelMaterialTopRight then GossipFrameGreetingPanelMaterialTopRight:Hide() end
    if GossipFrameGreetingPanelMaterialBotLeft then GossipFrameGreetingPanelMaterialBotLeft:Hide() end
    if GossipFrameGreetingPanelMaterialBotRight then GossipFrameGreetingPanelMaterialBotRight:Hide() end

    -- 共通换皮（与接任务/任务日志同款，视觉统一）
    local customBg = DFUI.SkinQuestStyleFrame(GossipFrame, {
        name     = "DFUI_GossipBg",
        panels   = {GossipFrameGreetingPanel, GossipFrame},
        portrait = GossipFramePortrait,
        nameText = GossipFrameNpcNameText,
        onClose  = function() HideUIPanel(GossipFrame) end,
    })

    -- minimal 滚动条接管闲聊内容 ScrollFrame（GossipGreetingScrollFrame 普通 ScrollFrame）
    DFUI.AttachMinimalScrolls(GossipFrame, {
        {sf = "GossipGreetingScrollFrame", sb = "GossipGreetingScrollFrameScrollBar"},
    })

    -- 告别按钮重定位（选项按钮 GossipTitleButton* 在 scrollchild 内随 scroll，不动）
    local gb = getglobal("GossipFrameGreetingGoodbyeButton")
    if gb and customBg then
        gb:ClearAllPoints()
        gb:SetPoint("BOTTOMRIGHT", customBg, "BOTTOMRIGHT", -26, 14)
    end

    local callbacks = {}
    DFUI:NewCallbacks("Gossip", callbacks)
end)
