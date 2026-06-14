-- guild_registrar.lua — 公会注册员(GuildRegistrarFrame)换 DF 青铜框皮
-- 照 merchant 范式：换外框 + 头像 + 红关闭 + NPC名字，保留公会名输入框/费用标签/按钮
-- 参考 pfUI skins/blizzard/guild_registrar.lua（1.12 验证）；双子框 GuildRegistrarGreetingFrame

setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("GuildRegistrar", {
    enabled = {true},
})

DFUI:NewMod("GuildRegistrar", 5, function()
    if not GuildRegistrarFrame then return end
    if GuildRegistrarFrame._dfGuildRegSkinned then return end

    -- 隐藏原生背景纹理（主框 + 问候子框，跳过头像）
    local portrait = GuildRegistrarFramePortrait
    DFUI.HidePanelTextures(GuildRegistrarFrame, {skip = portrait})
    DFUI.HidePanelTextures(GuildRegistrarGreetingFrame, {skip = portrait})
    if GuildRegistrarFrame.DisableDrawLayer then GuildRegistrarFrame:DisableDrawLayer("BACKGROUND") end
    if GuildRegistrarFrameCloseButton then GuildRegistrarFrameCloseButton:Hide() end

    -- 青铜框：有头像用 frameStyle=1(带孔)，无头像用 2(无孔)，自适应免露岩石
    local customBg = DFUI.CreatePaperDollFrame("DFUI_GuildRegBg", GuildRegistrarFrame, 384, 512, (portrait and 1) or 2)
    customBg:SetPoint("TOPLEFT", GuildRegistrarFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", GuildRegistrarFrame, "BOTTOMRIGHT", -32, 55)
    customBg:SetFrameLevel(GuildRegistrarFrame:GetFrameLevel() - 1)

    -- 头像（复用工厂，青铜框当圆环）
    DFUI.AttachPortrait(customBg, portrait)

    -- NPC 名字（金色居中顶部）
    if GuildRegistrarFrameNpcNameText then
        GuildRegistrarFrameNpcNameText:SetParent(customBg)
        GuildRegistrarFrameNpcNameText:ClearAllPoints()
        GuildRegistrarFrameNpcNameText:SetPoint("TOP", customBg, "TOP", 0, -6)
        GuildRegistrarFrameNpcNameText:SetTextColor(1, 0.82, 0)
    end

    -- 红关闭
    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(GuildRegistrarFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    CenterFrame(GuildRegistrarFrame)
    HookScript(GuildRegistrarFrame, "OnShow", function() customBg:Show() end)

    GuildRegistrarFrame._dfGuildRegSkinned = true
    local callbacks = {}
    DFUI:NewCallbacks("GuildRegistrar", callbacks)
end)
