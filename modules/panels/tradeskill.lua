-- tradeskill.lua — 专业技能面板（TradeSkillFrame / CraftFrame）DF 金属边框换皮
-- TradeSkillFrame 实际尺寸 767x512，frameStyle=2（无头像），不动控件位置

setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("TradeSkill", {
    enabled = {true},
})

DFUI:NewMod("TradeSkill", 5, function()

    local function SkinProfessionFrame(cfg)
        -- A：隐藏暴雪纹理（反向匹配，参考 character.lua HideBlizzardTextures）
        -- 隐藏所有纹理，只跳过内容相关的（Icon/Check/Highlight/StatusBar）
        -- 不跳过 Portrait（frameStyle=2 不需要头像）
        local regions = {cfg.frame:GetRegions()}
        for i = 1, table.getn(regions) do
            local region = regions[i]
            if region:GetObjectType() == "Texture" then
                local name = region:GetName()
                local texture = region:GetTexture()
                local skip = false
                if name then
                    if string.find(name, "Icon") or string.find(name, "Check") or string.find(name, "Highlight") then
                        skip = true
                    end
                end
                if texture and (string.find(texture, "Icon") or string.find(texture, "StatusBar")) then
                    skip = true
                end
                if not skip then
                    region:Hide()
                end
            end
        end

        if cfg.closeBtn then cfg.closeBtn:Hide() end

        -- B：创建 DF 金属边框（frameStyle=2 无头像，适合宽矮框体）
        -- 单锚点 + 固定尺寸，避免双锚点与 SetWidth/SetHeight 冲突
        local bgW = cfg.frame:GetWidth() - 10   -- 左右各缩 5
        local bgH = cfg.frame:GetHeight() - 70  -- 顶缩 5，底缩 65
        local customBg = DFUI.CreatePaperDollFrame("DFUI_" .. cfg.name .. "Bg", cfg.frame, bgW, bgH, 2)
        customBg:SetPoint("TOPLEFT", cfg.frame, "TOPLEFT", 5, -5)
        customBg:SetFrameLevel(cfg.frame:GetFrameLevel() + 1)
        customBg.Bg:SetDrawLayer("BACKGROUND", -1)

        -- C：内容区黑色背景
        local contentBg = customBg:CreateTexture(nil, "BORDER")
        contentBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        contentBg:SetPoint("TOPLEFT", customBg, "TOPLEFT", 3, -20)
        contentBg:SetPoint("BOTTOMRIGHT", customBg, "BOTTOMRIGHT", -3, 3)
        contentBg:SetVertexColor(0, 0, 0, 0.3)

        -- D：关闭按钮
        local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(cfg.frame) end)
        closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
        closeButton:SetWidth(20)
        closeButton:SetHeight(20)
        closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

        -- E：OnShow 钩子
        HookScript(cfg.frame, "OnShow", function()
            customBg:Show()
        end)
    end

    -- TradeSkillFrame
    local tradeSkillSkinned = false
    local function SkinTradeSkill()
        if tradeSkillSkinned or not TradeSkillFrame then return end
        tradeSkillSkinned = true
        SkinProfessionFrame({
            name = "TradeSkill",
            frame = TradeSkillFrame,
            closeBtn = _G["TradeSkillFrameCloseButton"],
        })
    end

    -- CraftFrame
    local craftSkinned = false
    local function SkinCraft()
        if craftSkinned or not CraftFrame then return end
        craftSkinned = true
        SkinProfessionFrame({
            name = "Craft",
            frame = CraftFrame,
            closeBtn = _G["CraftFrameCloseButton"],
        })
    end

    -- 监听按需加载
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function()
        if arg1 == "Blizzard_TradeSkillUI" then SkinTradeSkill() end
        if arg1 == "Blizzard_CraftUI" then SkinCraft() end
    end)

    if TradeSkillFrame then SkinTradeSkill() end
    if CraftFrame then SkinCraft() end

    local callbacks = {}
    DFUI:NewCallbacks("TradeSkill", callbacks)
end)
