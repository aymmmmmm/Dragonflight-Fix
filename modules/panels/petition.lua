-- petition.lua — 请愿签名窗(PetitionFrame)换 DF 青铜框皮
-- 照 merchant 范式：换外框 + 头像 + 红关闭 + NPC名字，保留签名列表与 Sign/Cancel/Rename/Request 按钮
-- 参考 pfUI skins/blizzard/petition.lua（1.12 验证）

setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Petition", {
    enabled = {true},
})

DFUI:NewMod("Petition", 5, function()
    if not PetitionFrame then return end
    if PetitionFrame._dfPetitionSkinned then return end

    -- 隐藏原生背景纹理（跳过头像，避免误隐）
    local portrait = PetitionFramePortrait
    local regions = {PetitionFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local r = regions[i]
        if r:GetObjectType() == "Texture" and r ~= portrait then r:Hide() end
    end
    if PetitionFrame.DisableDrawLayer then PetitionFrame:DisableDrawLayer("BACKGROUND") end
    if PetitionFrameCloseButton then PetitionFrameCloseButton:Hide() end

    -- 青铜框（带头像孔 frameStyle=1）
    local customBg = DFUI.CreatePaperDollFrame("DFUI_PetitionBg", PetitionFrame, 384, 512, 1)
    customBg:SetPoint("TOPLEFT", PetitionFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", PetitionFrame, "BOTTOMRIGHT", -32, 55)
    customBg:SetFrameLevel(PetitionFrame:GetFrameLevel() - 1)

    -- 头像（照 merchant，青铜框当圆环）
    if portrait then
        portrait:SetParent(customBg)
        portrait:SetDrawLayer("BORDER", 0)
        portrait:ClearAllPoints()
        portrait:SetPoint("TOPLEFT", customBg, "TOPLEFT", -4, 8)
    end

    -- NPC 名字框（PetitionNpcNameFrame 是 Frame，整体重锚顶部）
    if PetitionNpcNameFrame then
        PetitionNpcNameFrame:SetParent(customBg)
        PetitionNpcNameFrame:ClearAllPoints()
        PetitionNpcNameFrame:SetPoint("TOP", customBg, "TOP", 0, -6)
    end

    -- 红关闭
    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(PetitionFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    CenterFrame(PetitionFrame)
    HookScript(PetitionFrame, "OnShow", function() customBg:Show() end)

    PetitionFrame._dfPetitionSkinned = true
    local callbacks = {}
    DFUI:NewCallbacks("Petition", callbacks)
end)
