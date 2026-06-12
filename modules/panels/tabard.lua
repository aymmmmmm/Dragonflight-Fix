-- tabard.lua — 公会战袍设计器(TabardFrame)换 DF 青铜框皮
-- 照 merchant 范式：换外框 + 头像 + 红关闭 + NPC名字，保留 3D 模型(TabardModel)与颜色器(Customization1..5)
-- 参考 pfUI skins/blizzard/tabard.lua（1.12 验证）

setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Tabard", {
    enabled = {true},
})

DFUI:NewMod("Tabard", 5, function()
    if not TabardFrame then return end
    if TabardFrame._dfTabardSkinned then return end

    -- 隐藏原生背景纹理（主框 + 费用框，跳过头像）
    local portrait = TabardFramePortrait
    local regions = {TabardFrame:GetRegions()}
    for i = 1, table.getn(regions) do
        local r = regions[i]
        if r:GetObjectType() == "Texture" and r ~= portrait then r:Hide() end
    end
    if TabardFrame.DisableDrawLayer then TabardFrame:DisableDrawLayer("BACKGROUND") end
    if TabardFrameCostFrame then
        local cr = {TabardFrameCostFrame:GetRegions()}
        for i = 1, table.getn(cr) do
            local r = cr[i]
            if r:GetObjectType() == "Texture" then r:Hide() end
        end
    end
    if TabardFrameCloseButton then TabardFrameCloseButton:Hide() end

    -- 青铜框（带头像孔 frameStyle=1），衬在模型/颜色器之下
    local customBg = DFUI.CreatePaperDollFrame("DFUI_TabardBg", TabardFrame, 384, 512, 1)
    customBg:SetPoint("TOPLEFT", TabardFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", TabardFrame, "BOTTOMRIGHT", -32, 72)
    customBg:SetFrameLevel(TabardFrame:GetFrameLevel() - 1)

    -- 头像（照 merchant，青铜框当圆环）
    if portrait then
        portrait:SetParent(customBg)
        portrait:SetDrawLayer("BORDER", 0)
        portrait:ClearAllPoints()
        portrait:SetPoint("TOPLEFT", customBg, "TOPLEFT", -4, 8)
    end

    -- NPC 名字（金色居中顶部）
    if TabardFrameNameText then
        TabardFrameNameText:SetParent(customBg)
        TabardFrameNameText:ClearAllPoints()
        TabardFrameNameText:SetPoint("TOP", customBg, "TOP", 0, -6)
        TabardFrameNameText:SetTextColor(1, 0.82, 0)
    end

    -- 红关闭
    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(TabardFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    CenterFrame(TabardFrame)
    HookScript(TabardFrame, "OnShow", function() customBg:Show() end)

    TabardFrame._dfTabardSkinned = true
    local callbacks = {}
    DFUI:NewCallbacks("Tabard", callbacks)
end)
