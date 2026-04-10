setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Inspect", {
    enabled = {true},
})

DFUI:NewMod("Inspect", 5, function()
    local skinned = false

    -- 通用纹理隐藏：保留图标/头像/高亮
    local function HideBlizzardTextures(frame)
        if not frame then return end
        local regions = {frame:GetRegions()}
        for i = 1, table.getn(regions) do
            local region = regions[i]
            if region:GetObjectType() == "Texture" then
                local name = region:GetName()
                local texture = region:GetTexture()
                local skip = false
                if name then
                    if string.find(name, "Icon") or string.find(name, "Portrait") or string.find(name, "Check") or string.find(name, "Highlight") then
                        skip = true
                    end
                end
                if texture and (string.find(texture, "Icon") or string.find(texture, "Portrait") or string.find(texture, "StatusBar")) then
                    skip = true
                end
                if not skip then
                    region:Hide()
                end
            end
        end
    end

    local function SkinInspectFrame()
        if skinned or not InspectFrame then return end
        skinned = true

        -- 隐藏主框架 + 所有子框架的暴雪纹理
        HideBlizzardTextures(InspectFrame)
        HideBlizzardTextures(InspectPaperDollFrame)
        HideBlizzardTextures(InspectHonorFrame)

        -- 隐藏所有暴雪 Tab（Turtle WoW 可能有 3 个）
        for i = 1, 5 do
            local tab = getglobal("InspectFrameTab" .. i)
            if tab then tab:Hide() end
        end
        if InspectFrameCloseButton then InspectFrameCloseButton:Hide() end

        local customBg = DFUI.CreatePaperDollFrame("DFUI_InspectBg", InspectFrame, 384, 512, 1)
        customBg:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", 12, -12)
        customBg:SetPoint("BOTTOMRIGHT", InspectFrame, "BOTTOMRIGHT", -32, 75)
        customBg:SetFrameLevel(InspectFrame:GetFrameLevel() - 1)
        customBg.Bg:SetDrawLayer("BACKGROUND", -1)

        -- 头像
        if InspectFramePortrait then
            InspectFramePortrait:SetParent(customBg)
            InspectFramePortrait:SetDrawLayer("BORDER", 0)
        end

        local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(InspectFrame) end)
        closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
        closeButton:SetWidth(20)
        closeButton:SetHeight(20)
        closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

        customBg:AddTab("角色", function()
            if InspectPaperDollFrame then InspectPaperDollFrame:Show() end
            if InspectHonorFrame then InspectHonorFrame:Hide() end
        end, 70)

        customBg:AddTab("荣誉", function()
            if InspectPaperDollFrame then InspectPaperDollFrame:Hide() end
            if InspectHonorFrame then InspectHonorFrame:Show() end
        end, 70)

        HookScript(InspectFrame, "OnShow", function()
            customBg:Show()
        end)
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function()
        if arg1 == "Blizzard_InspectUI" then
            SkinInspectFrame()
        end
    end)

    if InspectFrame then
        SkinInspectFrame()
    end

    local callbacks = {}
    DFUI:NewCallbacks("Inspect", callbacks)
end)
