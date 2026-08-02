setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("OpenMail", {
    enabled = {true},
})

DFUI:NewMod("OpenMail", 5, function()
    -- 隐藏所有暴雪纹理
    local regions = {OpenMailFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region:GetObjectType() == "Texture" then
            region:Hide()
        end
    end

    if OpenMailCloseButton then OpenMailCloseButton:Hide() end

    local customBg = DFUI.CreatePaperDollFrame("DFUI_OpenMailBg", OpenMailFrame, 384, 512, 2)
    customBg:SetPoint("TOPLEFT", OpenMailFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", OpenMailFrame, "BOTTOMRIGHT", -32, 75)
    customBg:SetFrameLevel(OpenMailFrame:GetFrameLevel())
    customBg.Bg:SetDrawLayer("BACKGROUND", -1)

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(OpenMailFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    -- 上面的全清只扫 OpenMailFrame 一层（GetRegions 不递归子 frame），漏了 OpenMailScrollFrame
    -- OVERLAY 层两条匿名 UI-Character-ScrollBar 凹槽（MailFrame.xml:1481/1494，patch-9 版）——
    -- 凹槽画在 ScrollFrame 上而非 ScrollBar 上，keepArrowsHideTrack 够不着，会和 minimal 滑块重影。
    -- 按贴图名精确匹配：同帧 BACKGROUND 层的 OpenStationeryBackgroundLeft/Right 是信纸背景，不能碰。
    DFUI.HidePanelTextures(OpenMailScrollFrame, {match = "UI%-Character%-ScrollBar"})

    -- 读信正文滚动条换 DF minimal（与发信页统一）。customBg 已是 OpenMailFrame 同级，
    -- 低于其子 frame 的 +1，本来就没有 tie，层级不动。
    DFUI.AttachMinimalScrolls(OpenMailFrame, {
        {sf = "OpenMailScrollFrame", sb = "OpenMailScrollFrameScrollBar"},
    })

    CenterFrame(OpenMailFrame)
    HookScript(OpenMailFrame, "OnShow", function()
        customBg:Show()
    end)

    local callbacks = {}
    DFUI:NewCallbacks("OpenMail", callbacks)
end)
