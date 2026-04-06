setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")

DFUI:NewDefaults("Character", {
    enabled = {true},
    showItemRarity = {true, "checkbox", nil, nil, "面板美化", 1, "显示装备品质边框", nil, nil},
})

DFUI:NewMod("Character", 5, function()
    local frames = {PaperDollFrame, PetPaperDollFrame, SkillFrame, ReputationFrame, HonorFrame}
    for _, frame in ipairs(frames) do
        if frame then
            local regions = {frame:GetRegions()}
            for i = 1, table.getn(regions) do
                local region = regions[i]
                if region:GetObjectType() == "Texture" then
                    local texture = region:GetTexture()
                    if texture and (string.find(texture, "UI%-Character%-") or string.find(texture, "PaperDoll")) then
                        region:Hide()
                    end
                end
            end
        end
    end

    CharacterFrameTab1:Hide()
    CharacterFrameTab2:Hide()
    CharacterFrameTab3:Hide()
    CharacterFrameTab4:Hide()
    CharacterFrameTab5:Hide()
    CharacterFrameCloseButton:Hide()
    PetPaperDollCloseButton:Hide()
    SkillFrameCancelButton:Hide()

    -- 通用：隐藏框架所有暴雪背景纹理，保留图标/按钮相关
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

    -- 缓存系统：首次扫描记录需隐藏的 Region 引用，后续直接遍历缓存
    local hiddenRegionCache = {}
    local cacheBuilt = false

    local function BuildRegionCache(frame, depth)
        if not frame then return end
        depth = depth or 0
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
                    table.insert(hiddenRegionCache, region)
                end
            end
        end
        if depth < 2 then
            local children = {frame:GetChildren()}
            for i = 1, table.getn(children) do
                BuildRegionCache(children[i], depth + 1)
            end
        end
    end

    local function HideAllCachedRegions()
        for i = 1, table.getn(hiddenRegionCache) do
            hiddenRegionCache[i]:Hide()
        end
    end

    -- ArenaFrame 团队框架美化（只执行一次）
    local function SkinArenaTeams()
        if not ArenaFrame then return end
        for i = 1, 3 do
            local team = getglobal("ArenaFrameTeam" .. i)
            if team and not team._dfSkinned then
                HideBlizzardTextures(team)
                team:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1,
                })
                team:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
                team:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
                team._dfSkinned = true
            end
        end
    end

    -- 统一入口：构建缓存 + 隐藏所有暴雪纹理 + DisableDrawLayer
    local function StripHonorSystem()
        if not cacheBuilt then
            BuildRegionCache(HonorFrame)
            if ArenaFrame then
                BuildRegionCache(ArenaFrame, 1) -- depth=1: 只缓存自身+子框架，不递归孙框架（保护团队内容）
            end
            -- Tab 按钮的纹理也缓存
            BuildRegionCache(HonorFrameTab1, 2)
            BuildRegionCache(HonorFrameTab2, 2)
            cacheBuilt = true
        end
        HideAllCachedRegions()
        if HonorFrame then HonorFrame:DisableDrawLayer("BACKGROUND") end
        if ArenaFrame then ArenaFrame:DisableDrawLayer("BACKGROUND") end
        SkinArenaTeams()
    end

    -- 技能 Tab："全部"按钮
    if SkillFrameExpandButtonFrame then
        SkillFrameExpandButtonFrame:DisableDrawLayer("BACKGROUND")
    end
    HideBlizzardTextures(SkillFrameCollapseAllButton)

    -- 称号下拉框（Turtle WoW 自定义）
    if CharacterTitleDropDown then
        HideBlizzardTextures(CharacterTitleDropDown)
        for _, suffix in ipairs({"Left", "Middle", "Right"}) do
            local tex = getglobal("CharacterTitleDropDown" .. suffix)
            if tex then tex:Hide() end
        end
    end

    _G.PetTab_Update = function() end

    local customBg = DFUI.CreatePaperDollFrame("DFUI_CharacterBg", CharacterFrame, 384, 512, 1)
    customBg:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 12, -12)
    customBg:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -32, 75)
    customBg:SetFrameLevel(CharacterFrame:GetFrameLevel() + 1)
    customBg.Bg:SetDrawLayer("BACKGROUND", -1)

    CharacterFramePortrait:SetParent(customBg)
    CharacterFramePortrait:SetDrawLayer("BORDER", 0)

    local characterBg = customBg:CreateTexture(nil, "OVERLAY")
    characterBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    characterBg:SetPoint("TOPLEFT", customBg, "TOPLEFT", 55, -60)
    characterBg:SetPoint("BOTTOMRIGHT", customBg, "BOTTOMRIGHT", -55, 60)
    characterBg:SetVertexColor(0, 0, 0, 0.3)
    characterBg:Hide()

    local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(CharacterFrame) end)
    closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
    closeButton:SetWidth(20)
    closeButton:SetHeight(20)
    closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

    -- Tabs
    customBg:AddTab("角色", function()
        characterBg:Show()
        CharacterFrame_ShowSubFrame("PaperDollFrame")
        PanelTemplates_SetTab(CharacterFrame, 1)
    end, 70)

    local petTab = customBg:AddTab("宠物", function()
        characterBg:Hide()
        CharacterFrame_ShowSubFrame("PetPaperDollFrame")
        PanelTemplates_SetTab(CharacterFrame, 2)
    end, 55)

    customBg:AddTab("声望", function()
        characterBg:Hide()
        CharacterFrame_ShowSubFrame("ReputationFrame")
        PanelTemplates_SetTab(CharacterFrame, 3)
    end, 70)

    function customBg:UpdatePetTab()
        if HasPetUI() then
            petTab:Show()
        else
            petTab:Hide()
            if customBg.Tabs[3] then
                customBg.Tabs[3]:ClearAllPoints()
                customBg.Tabs[3]:SetPoint("BOTTOMLEFT", customBg.Tabs[1], "BOTTOMRIGHT", 4, 0)
            end
        end
        if HasPetUI() and customBg.Tabs[3] then
            customBg.Tabs[3]:ClearAllPoints()
            customBg.Tabs[3]:SetPoint("BOTTOMLEFT", petTab, "BOTTOMRIGHT", 4, 0)
        end
    end

    customBg:AddTab("技能", function()
        characterBg:Hide()
        CharacterFrame_ShowSubFrame("SkillFrame")
        PanelTemplates_SetTab(CharacterFrame, 4)
    end, 55)

    customBg:AddTab("荣誉", function()
        characterBg:Hide()
        CharacterFrame_ShowSubFrame("HonorFrame")
        PanelTemplates_SetTab(CharacterFrame, 5)
    end, 55)

    -- 荣誉/竞技场子 Tab：原地美化 HonorFrameTab1/Tab2
    local function SkinHonorSubTab(tab)
        if not tab then return end
        HideBlizzardTextures(tab)
        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        tab:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
        tab:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.6)
        tab:SetHeight(22)
        -- 冻结尺寸+位置，阻止暴雪 PanelTemplates 修改任何布局属性
        tab.SetHeight = function() end
        tab.SetWidth = function() end
        tab.ClearAllPoints = function() end
        tab.SetPoint = function() end
    end

    local function UpdateHonorSubTabs()
        -- 用 ArenaFrame 可见性作为唯一判据（最可靠）
        local arenaShown = ArenaFrame and ArenaFrame:IsShown()
        for i = 1, 2 do
            local tab = getglobal("HonorFrameTab" .. i)
            if tab then
                local selected = (i == 1 and not arenaShown) or (i == 2 and arenaShown)
                if selected then
                    tab:SetBackdropColor(0.25, 0.25, 0.25, 0.9)
                    tab:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
                else
                    tab:SetBackdropColor(0.12, 0.12, 0.12, 0.7)
                    tab:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
                end
            end
        end
    end

    -- 统一刷新：缓存隐藏 + Tab 样式更新（所有 hook 共用）
    local function RefreshHonorSkin()
        StripHonorSystem()
        UpdateHonorSubTabs()
    end

    SkinHonorSubTab(HonorFrameTab1)
    SkinHonorSubTab(HonorFrameTab2)

    -- Hook：Tab 点击 + HonorFrame/ArenaFrame 显示，统一调用 RefreshHonorSkin
    if HonorFrameTab1 then
        HookScript(HonorFrameTab1, "OnClick", RefreshHonorSkin)
    end
    if HonorFrameTab2 then
        HookScript(HonorFrameTab2, "OnClick", RefreshHonorSkin)
    end
    HookScript(HonorFrame, "OnShow", RefreshHonorSkin)
    if ArenaFrame then
        HookScript(ArenaFrame, "OnShow", RefreshHonorSkin)
        HookScript(ArenaFrame, "OnHide", RefreshHonorSkin)
    end
    RefreshHonorSkin()

    -- 宠物 Tab 动态
    customBg:RegisterEvent("PET_UI_UPDATE")
    customBg:RegisterEvent("PET_BAR_UPDATE")
    customBg:RegisterEvent("UNIT_PET")
    customBg:SetScript("OnEvent", function()
        if event == "PET_UI_UPDATE" or event == "PET_BAR_UPDATE" or (event == "UNIT_PET" and arg1 == "player") then
            customBg:UpdatePetTab()
        end
    end)
    customBg:UpdatePetTab()

    HookScript(CharacterFrame, "OnShow", function()
        customBg:Show()
    end)

    -- ToggleCharacter Hook
    local originalToggleCharacter = _G.ToggleCharacter
    _G.ToggleCharacter = function(tab)
        originalToggleCharacter(tab)
        if CharacterFrame:IsVisible() and customBg.Tabs then
            local tabIndex = nil
            local hasPet = HasPetUI()

            if tab == "PaperDollFrame" then
                tabIndex = 1
            elseif tab == "PetPaperDollFrame" and hasPet then
                tabIndex = 2
            elseif tab == "ReputationFrame" then
                tabIndex = hasPet and 3 or 2
            elseif tab == "SkillFrame" then
                tabIndex = hasPet and 4 or 3
            elseif tab == "HonorFrame" then
                tabIndex = hasPet and 5 or 4
            end

            local selectedTab = customBg.Tabs[tabIndex]
            if selectedTab then
                selectedTab:GetScript("OnClick")()
            end
        end
    end

    -- 装备品质边框
    local highlightTex = TEX .. "actionbars\\uiactionbariconframehighlight.tga"
    local slots = {"Head", "Neck", "Shoulder", "Shirt", "Chest", "Waist", "Legs", "Feet", "Wrist", "Hands", "Finger0", "Finger1", "Trinket0", "Trinket1", "Back", "MainHand", "SecondaryHand", "Ranged", "Tabard", "Ammo"}
    local slotButtons = {}

    for _, slot in ipairs(slots) do
        local button = getglobal("Character" .. slot .. "Slot")
        if button then
            table.insert(slotButtons, button)
            local icon = getglobal("Character" .. slot .. "SlotIconTexture")
            if icon then
                local hl = button:CreateTexture(nil, "HIGHLIGHT")
                hl:SetPoint("TOPLEFT", icon, "TOPLEFT", -6, 6)
                hl:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 6, -6)
                hl:SetTexture(highlightTex)
                hl:SetBlendMode("ADD")
                button:SetHighlightTexture(hl)

                button.qualityBorder = CreateFrame("Frame", nil, button)
                button.qualityBorder:SetAllPoints(icon)
                button.qualityBorderTex = button.qualityBorder:CreateTexture(nil, "OVERLAY")
                button.qualityBorderTex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                button.qualityBorderTex:SetBlendMode("ADD")
                button.qualityBorderTex:SetPoint("TOPLEFT", button.qualityBorder, "TOPLEFT", -14, 14)
                button.qualityBorderTex:SetPoint("BOTTOMRIGHT", button.qualityBorder, "BOTTOMRIGHT", 14, -14)
                button.qualityBorder:Hide()
            end
        end
    end

    local function UpdateQualityBorders(enabled)
        local colors = {{0.62,0.62,0.62}, {1,1,1}, {0,1,0}, {0,0.44,0.87}, {0.64,0.21,0.93}, {1,0.5,0}}
        for _, button in pairs(slotButtons) do
            if button.qualityBorder then
                if enabled then
                    local quality = GetInventoryItemQuality("player", button:GetID())
                    if quality and quality > 1 then
                        local c = colors[quality + 1] or {1, 1, 1}
                        button.qualityBorderTex:SetVertexColor(c[1], c[2], c[3], 0.7)
                        button.qualityBorder:Show()
                    else
                        button.qualityBorder:Hide()
                    end
                else
                    button.qualityBorder:Hide()
                end
            end
        end
    end

    local inventoryFrame = CreateFrame("Frame")
    inventoryFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    inventoryFrame:SetScript("OnEvent", function()
        if event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
            if DFUI.tempDB["Character"] and DFUI.tempDB["Character"]["showItemRarity"] then
                UpdateQualityBorders(true)
            end
        end
    end)

    local callbacks = {}
    callbacks.showItemRarity = function(value)
        UpdateQualityBorders(value)
    end
    DFUI:NewCallbacks("Character", callbacks)
end)
