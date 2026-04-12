-- tradeskill.lua — 专业技能面板（TradeSkillFrame / CraftFrame）DF 金属边框换皮
-- TradeSkillFrame 实际尺寸 767x512，frameStyle=2（无头像）
-- 控件定位通过 Hook *Frame_Update 实现，对抗 Blizzard 每次刷新时的位置覆盖

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

        -- 拖动支持
        cfg.frame:SetMovable(true)
        cfg.frame:EnableMouse(true)
        cfg.frame:RegisterForDrag("LeftButton")
        cfg.frame:SetScript("OnDragStart", function() cfg.frame:StartMoving() end)
        cfg.frame:SetScript("OnDragStop", function() cfg.frame:StopMovingOrSizing() end)

        -- B：创建 DF 金属边框（frameStyle=2 无头像，适合宽矮框体）
        -- 单锚点 + 固定尺寸，避免双锚点与 SetWidth/SetHeight 冲突
        local bgW = cfg.frame:GetWidth() - 10   -- 左右各缩 5
        local bgH = cfg.frame:GetHeight() - 70  -- 顶缩 5，底缩 65
        local customBg = DFUI.CreatePaperDollFrame("DFUI_" .. cfg.name .. "Bg", cfg.frame, bgW, bgH, 2)
        customBg:SetPoint("TOPLEFT", cfg.frame, "TOPLEFT", 5, -5)
        customBg:SetFrameLevel(cfg.frame:GetFrameLevel() - 1)
        customBg.Bg:SetDrawLayer("BACKGROUND", -1)

        -- D：关闭按钮
        local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(cfg.frame) end)
        closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
        closeButton:SetWidth(20)
        closeButton:SetHeight(20)
        closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

        -- E：列表边框
        local listScroll = getglobal(cfg.name .. "ListScrollFrame")
        local listBorder
        if listScroll then
            listBorder = CreateFrame("Frame", "DFUI_" .. cfg.name .. "ListBorder", customBg)
            listBorder:SetPoint("TOPLEFT", listScroll, "TOPLEFT", -19, cfg.listTopY or 10)
            listBorder:SetPoint("BOTTOMRIGHT", listScroll, "BOTTOMRIGHT", 27, cfg.listBottomY or 10)
            listBorder:SetFrameLevel(listScroll:GetFrameLevel() + 1)
            listBorder:SetBackdrop({
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 16,
            })
            listBorder:SetBackdropBorderColor(0.6, 0.55, 0.5, 1)
        end

        -- E2：下拉框一次性换皮（视觉，不涉及定位）
        local subClassDD = getglobal(cfg.name .. "SubClassDropDown")
        local invSlotDD = getglobal(cfg.name .. "InvSlotDropDown")
        if invSlotDD then DFUI.SkinDropDown(invSlotDD) end
        if subClassDD then DFUI.SkinDropDown(subClassDD) end

        -- E3：ExpandButtonFrame 背景隐藏
        local expandFrame = getglobal(cfg.name .. "ExpandButtonFrame")
        if expandFrame then
            expandFrame:DisableDrawLayer("BACKGROUND")
        end

        -- E4：控件定位函数 — 在 Blizzard Update 后重新定位，对抗覆盖
        local function RepositionControls()
            local collapseAll = getglobal(cfg.name .. "CollapseAllButton")
            if collapseAll and listScroll then
                collapseAll:ClearAllPoints()
                collapseAll:SetPoint("BOTTOMLEFT", listScroll, "TOPLEFT", -5, 5)
            end
            if invSlotDD and listBorder then
                invSlotDD:ClearAllPoints()
                invSlotDD:SetPoint("BOTTOMRIGHT", listBorder, "TOPRIGHT", 15, 0)
            end
            if subClassDD and invSlotDD then
                subClassDD:ClearAllPoints()
                subClassDD:SetPoint("RIGHT", invSlotDD, "LEFT", 27, 0)
            end
            if expandFrame then
                expandFrame:DisableDrawLayer("BACKGROUND")
            end
        end

        -- Hook Blizzard Update 函数，在其执行后重新定位控件
        local updateFuncName = cfg.name .. "Frame_Update"
        if _G[updateFuncName] then
            local origUpdate = _G[updateFuncName]
            _G[updateFuncName] = function()
                origUpdate()
                RepositionControls()
            end
        end

        -- 同时 Hook OnShow，确保面板每次打开时也重新定位
        HookScript(cfg.frame, "OnShow", function()
            RepositionControls()
        end)

        -- 首次立即执行一次
        RepositionControls()

        -- F：标题上移
        local titleText = getglobal(cfg.name .. "FrameTitleText")
        if titleText then
            titleText:ClearAllPoints()
            titleText:SetPoint("TOP", cfg.frame, "TOP", 0, -8)
        end

        -- G：搜索框换皮
        if cfg.searchBox then
            local searchBox = _G[cfg.searchBox]
            if searchBox then
                searchBox:DisableDrawLayer("BACKGROUND")
                searchBox:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    edgeSize = 10,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 },
                })
                searchBox:SetBackdropColor(0.06, 0.06, 0.06, 0.85)
                searchBox:SetBackdropBorderColor(0.35, 0.32, 0.28, 0.7)
                searchBox:ClearAllPoints()
                searchBox:SetPoint("BOTTOMLEFT", customBg, "BOTTOMLEFT",
                    15 + (cfg.searchBoxOffsetX or 0),
                    8 + (cfg.searchBoxOffsetY or 0))
                searchBox:SetWidth(330)
                searchBox:SetHeight(22)
            end
        end

        -- H：居中 + OnShow 钩子
        CenterFrame(cfg.frame)
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
            searchBox = "TradeSkillSearchBox",
        })

        -- Turtle WoW 复选框：Hook TradeSkillFrame_Update 重新定位
        local detailScroll = getglobal("TradeSkillDetailScrollFrame")
        local matsCheck = _G["TradeSkillMatsCheckButton"]
        local skillCheck = _G["TradeSkillSkillCheckButton"]

        local function RepositionCheckboxes()
            if matsCheck and detailScroll then
                matsCheck:ClearAllPoints()
                matsCheck:SetPoint("BOTTOMLEFT", detailScroll, "TOPLEFT", 0, 2)
            end
            if skillCheck and matsCheck then
                skillCheck:ClearAllPoints()
                skillCheck:SetPoint("LEFT", matsCheck, "RIGHT", 80, 0)
            end
        end

        -- 叠加 Hook（SkinProfessionFrame 已 hook 过 TradeSkillFrame_Update）
        if _G["TradeSkillFrame_Update"] then
            local prevUpdate = _G["TradeSkillFrame_Update"]
            _G["TradeSkillFrame_Update"] = function()
                prevUpdate()
                RepositionCheckboxes()
            end
        end
        RepositionCheckboxes()
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
            listTopY = 12,   -- 边框顶部上移 2px
            searchBox = "CraftFrameSearchBox",
            searchBoxOffsetX = 0,
            searchBoxOffsetY = 0,
        })
        -- 保留原生训练点数显示（CraftFrame_Update 会自动管理）
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
