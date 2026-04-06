setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")

DFUI:NewDefaults("Gossip", {
    enabled = {true},
})

DFUI:NewMod("Gossip", 5, function()
    local frames = {GossipFrameGreetingPanel, GossipFrame}
    for _, frame in ipairs(frames) do
        if frame then
            local regions = {frame:GetRegions()}
            for i = 1, table.getn(regions) do
                local region = regions[i]
                if region:GetObjectType() == "Texture" then
                    local texture = region:GetTexture()
                    if texture and (string.find(texture, "QuestGreeting") or string.find(texture, "Quest%-Bot") or string.find(texture, "Quest")) then
                        region:Hide()
                    end
                end
            end
        end
    end

    if GossipFrameGreetingPanelMaterialTopLeft then GossipFrameGreetingPanelMaterialTopLeft:Hide() end
    if GossipFrameGreetingPanelMaterialTopRight then GossipFrameGreetingPanelMaterialTopRight:Hide() end
    if GossipFrameGreetingPanelMaterialBotLeft then GossipFrameGreetingPanelMaterialBotLeft:Hide() end
    if GossipFrameGreetingPanelMaterialBotRight then GossipFrameGreetingPanelMaterialBotRight:Hide() end
    GossipFrameCloseButton:Hide()

    local customBg = DFUI.CreatePaperDollFrame("DFUI_GossipBg", GossipFrame, 384, 400, 1)
    customBg:SetPoint("TOPLEFT", GossipFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", GossipFrame, "BOTTOMRIGHT", -32, 70)
    customBg:SetFrameLevel(GossipFrame:GetFrameLevel() - 1)

    local topWood = customBg:CreateTexture(nil, "BORDER")
    topWood:SetTexture(TEX .. "panels\\spellbook_top_wood.blp")
    topWood:SetPoint("TOPLEFT", customBg, "TOPLEFT", 0, -10)
    topWood:SetPoint("RIGHT", customBg, "RIGHT", 0, -60)
    topWood:SetWidth(customBg:GetWidth() - 10)
    topWood:SetHeight(64)

    GossipFramePortrait:SetParent(customBg)
    GossipFramePortrait:SetDrawLayer("ARTWORK", 0)
    GossipFramePortrait:ClearAllPoints()
    GossipFramePortrait:SetPoint("TOPLEFT", customBg, "TOPLEFT", -4, 7)

    local rightBg = customBg:CreateTexture(nil, "ARTWORK")
    rightBg:SetTexture(TEX .. "panels\\questlog_right_bg.blp")
    rightBg:SetPoint("TOPLEFT", customBg, "TOPLEFT", 5, -70)
    rightBg:SetPoint("BOTTOMRIGHT", customBg, "BOTTOMRIGHT", -24, -130)

    local bookmark = customBg:CreateTexture(nil, "OVERLAY")
    bookmark:SetTexture(TEX .. "panels\\spellbook_bookmark.blp")
    bookmark:SetWidth(40)
    bookmark:SetHeight(300)

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(GossipFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    if GossipFrameNpcNameText then
        GossipFrameNpcNameText:ClearAllPoints()
        GossipFrameNpcNameText:SetPoint("TOP", customBg, "TOP", 0, -6)
    end

    HookScript(GossipFrame, "OnShow", function()
        customBg:Show()
    end)

    local callbacks = {}
    DFUI:NewCallbacks("Gossip", callbacks)
end)
