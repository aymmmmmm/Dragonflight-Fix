-- taxi.lua — 飞行管理员航点地图(TaxiFrame)换 DF 青铜框皮
-- 照 merchant 范式：换外框 + 红关闭 + 标题，保留地图(TaxiRouteMap)/航点(TaxiButtonN)/连线不动
-- 参考 pfUI skins/blizzard/taxi.lua（1.12 验证）；TaxiFrame 无头像、无底部按钮

setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Taxi", {
    enabled = {true},
})

DFUI:NewMod("Taxi", 5, function()
    if not TaxiFrame then return end
    if TaxiFrame._dfTaxiSkinned then return end

    -- 隐藏原生背景纹理（飞行框背景艺术），地图/航点是子 frame 不受影响
    local regions = {TaxiFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local r = regions[i]
        if r:GetObjectType() == "Texture" then r:Hide() end
    end
    if TaxiFrame.DisableDrawLayer then TaxiFrame:DisableDrawLayer("BACKGROUND") end
    if TaxiCloseButton then TaxiCloseButton:Hide() end

    -- 青铜框（无头像 frameStyle=2），衬在地图之下
    local customBg = DFUI.CreatePaperDollFrame("DFUI_TaxiBg", TaxiFrame, 384, 512, 2)
    customBg:SetPoint("TOPLEFT", TaxiFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", TaxiFrame, "BOTTOMRIGHT", -32, 72)
    customBg:SetFrameLevel(TaxiFrame:GetFrameLevel() - 1)

    -- 标题（飞行管理员名，金色居中顶部）
    if TaxiMerchant then
        TaxiMerchant:SetParent(customBg)
        TaxiMerchant:ClearAllPoints()
        TaxiMerchant:SetPoint("TOP", customBg, "TOP", 0, -6)
        if TaxiMerchant.SetTextColor then TaxiMerchant:SetTextColor(1, 0.82, 0) end  -- 可能是 Frame，判空防崩
    end

    -- 红关闭
    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(TaxiFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    CenterFrame(TaxiFrame)
    HookScript(TaxiFrame, "OnShow", function() customBg:Show() end)

    TaxiFrame._dfTaxiSkinned = true
    local callbacks = {}
    DFUI:NewCallbacks("Taxi", callbacks)
end)
