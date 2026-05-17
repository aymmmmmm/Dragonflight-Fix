-- Dragonflight-Fix Loot Module
-- Replaces default LootFrame with Dragonflight-styled loot window

DFUI:NewDefaults("Loot", {
    enabled           = {true},
    mousecursor       = {true,  "checkbox", nil, nil, "基础", 1, "拾取窗口跟随鼠标光标", nil, nil},
    autoloot          = {false, "checkbox", nil, nil, "基础", 2, "自动拾取所有物品", nil, nil},
    autopickup_bop    = {true,  "checkbox", nil, nil, "基础", 3, "单人时自动确认拾取绑定物品", nil, nil},
    scale             = {1.0,   "slider", {0.5, 1.5, 0.05}, nil, "外观", 1, "拾取窗口缩放", nil, nil},
    quality_border    = {true,  "checkbox", nil, nil, "外观", 2, "物品图标边框显示品质颜色", nil, nil},
    quality_glow      = {true,  "checkbox", nil, nil, "外观", 3, "品质物品背景高亮", nil, nil},
    glow_threshold    = {2,     "slider", {0, 5, 1}, "quality_glow", "外观", 4, "高亮最低品质(0灰 1白 2绿 3蓝 4紫 5橙)", nil, nil},
    show_item_type    = {true,  "checkbox", nil, nil, "外观", 5, "显示物品类型信息", nil, nil},
    roll_rarity_timer = {true,  "checkbox", nil, nil, "投骰", 1, "投骰计时条颜色匹配物品品质", nil, nil},
})

DFUI:NewMod("Loot", 1, function()
    ---------------------------------------------------------------------------
    -- Constants
    ---------------------------------------------------------------------------
    local SLOT_HEIGHT = 40
    local SLOT_HEIGHT_INFO = 52
    local ICON_SIZE = 36
    local FRAME_MIN_WIDTH = 220
    local FRAME_MAX_WIDTH = 350
    local PADDING = 12
    local SLOT_SPACING = 6
    local FONT_PATH = DFUI:GetInfoOrCons("font") .. "BigNoodleTitling.ttf"
    local FADE_DELAY = 5.0
    local FADE_DURATION = 3.0

    -- 顶部标题栏占用（CreatePaperDollFrame 内 bgTexture 上方留 21px）
    local TITLE_BAR_HEIGHT = 21

    local PROF_TEX = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\panels\\df\\professions\\"
    local SLOT_TEX_BY_QUALITY = {
        [0] = PROF_TEX .. "slot_neutral.tga",   -- 粗糙(灰)
        [1] = PROF_TEX .. "slot_neutral.tga",   -- 普通(白)
        [2] = PROF_TEX .. "slot_green.tga",     -- 优秀(绿)
        [3] = PROF_TEX .. "slot_blue.tga",      -- 精良(蓝)
        [4] = PROF_TEX .. "slot_epic.tga",      -- 史诗(紫)
        [5] = PROF_TEX .. "slot_legendary.tga", -- 传说(橙)
    }

    ---------------------------------------------------------------------------
    -- State
    ---------------------------------------------------------------------------
    local slots = {}
    local lootFrame
    local closingLoot = false         -- guard: OnHide→CloseLoot recursion
    local autoLootFading = false      -- true when auto-loot fade is active
    local autoLootPending = false     -- true between AutoLootAll() and LOOT_CLOSED

    ---------------------------------------------------------------------------
    -- Helpers
    ---------------------------------------------------------------------------
    local function GetDB(key)
        return DFUI:GetTempDB("Loot", key)
    end

    local function SafeQualityColor(quality)
        return ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[0]
    end

    local function PositionFrameAtCursor(frame, cursorX, cursorY)
        local scale = frame:GetEffectiveScale()
        local x = cursorX / scale + 8
        local y = cursorY / scale - 8

        local screenW = GetScreenWidth()
        local screenH = GetScreenHeight()
        local frameW = frame:GetWidth()
        local frameH = frame:GetHeight()

        if x + frameW > screenW then x = screenW - frameW end
        if y - frameH < 0 then y = frameH end
        if x < 0 then x = 0 end
        if y > screenH then y = screenH end

        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    end

    -- Stop any active fade and reset frame state
    local function StopFade()
        if not lootFrame then return end
        autoLootFading = false
        autoLootPending = false
        lootFrame:SetAlpha(1.0)
        lootFrame:SetScript("OnUpdate", nil)
        -- hide all slots and frame
        for i = 1, table.getn(slots) do
            if slots[i] then slots[i]:Hide() end
        end
        closingLoot = true
        lootFrame:Hide()
        closingLoot = false
    end

    -- Start fade-out: wait FADE_DELAY then fade over FADE_DURATION
    local function StartFade()
        if not lootFrame then return end
        autoLootFading = true
        lootFrame.fadeStart = GetTime() + FADE_DELAY

        lootFrame:SetScript("OnUpdate", function()
            local now = GetTime()
            if now < this.fadeStart then return end
            local elapsed = now - this.fadeStart
            if elapsed >= FADE_DURATION then
                StopFade()
            else
                this:SetAlpha(1.0 - (elapsed / FADE_DURATION))
            end
        end)
    end

    ---------------------------------------------------------------------------
    -- SetupSlotVisuals: shared visual components for loot slots
    ---------------------------------------------------------------------------
    local function SetupSlotVisuals(slot)
        slot:SetHeight(SLOT_HEIGHT)

        slot.bg = slot:CreateTexture(nil, "BACKGROUND")
        slot.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        slot.bg:SetAllPoints(slot)
        slot.bg:SetVertexColor(0.06, 0.06, 0.06, 0.35)

        slot.rarity = slot:CreateTexture(nil, "BORDER")
        slot.rarity:SetTexture("Interface\\Buttons\\WHITE8X8")
        slot.rarity:SetAllPoints(slot)
        slot.rarity:SetAlpha(0.12)
        slot.rarity:Hide()

        slot.iconFrame = CreateFrame("Frame", nil, slot)
        slot.iconFrame:SetWidth(ICON_SIZE)
        slot.iconFrame:SetHeight(ICON_SIZE)
        slot.iconFrame:SetPoint("LEFT", slot, "LEFT", 3, 0)
        slot.iconFrame:EnableMouse(false)  -- don't intercept parent Button clicks

        slot.iconBg = slot.iconFrame:CreateTexture(nil, "BACKGROUND")
        slot.iconBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        slot.iconBg:SetAllPoints(slot.iconFrame)
        slot.iconBg:SetVertexColor(0, 0, 0, 1)

        slot.iconBorder = slot:CreateTexture(nil, "OVERLAY")
        slot.iconBorder:SetTexture(PROF_TEX .. "slot_neutral.tga")
        slot.iconBorder:SetTexCoord(12/64, 51/64, 12/64, 51/64)
        slot.iconBorder:SetWidth(ICON_SIZE + 6)
        slot.iconBorder:SetHeight(ICON_SIZE + 6)
        slot.iconBorder:SetPoint("CENTER", slot.iconFrame, "CENTER", 0, 0)

        slot.icon = slot.iconFrame:CreateTexture(nil, "ARTWORK")
        slot.icon:SetTexCoord(.07, .93, .07, .93)
        slot.icon:SetPoint("TOPLEFT", slot.iconFrame, "TOPLEFT", 2, -2)
        slot.icon:SetPoint("BOTTOMRIGHT", slot.iconFrame, "BOTTOMRIGHT", -2, 2)

        slot.iconGloss = slot.iconFrame:CreateTexture(nil, "OVERLAY")
        slot.iconGloss:SetTexture("Interface\\Buttons\\WHITE8X8")
        slot.iconGloss:SetPoint("TOPLEFT", slot.iconFrame, "TOPLEFT", 2, -2)
        slot.iconGloss:SetPoint("RIGHT", slot.iconFrame, "RIGHT", -2, 0)
        slot.iconGloss:SetHeight(ICON_SIZE / 3)
        slot.iconGloss:SetGradientAlpha("VERTICAL", 1, 1, 1, 0, 1, 1, 1, 0.08)

        slot.count = slot.iconFrame:CreateFontString(nil, "OVERLAY")
        slot.count:SetFont(FONT_PATH, 12, "OUTLINE")
        slot.count:SetJustifyH("RIGHT")
        slot.count:SetPoint("BOTTOMRIGHT", slot.iconFrame, "BOTTOMRIGHT", -1, 1)
        slot.count:SetTextColor(1, 1, 1)
        slot.count:Hide()

        slot.name = slot:CreateFontString(nil, "OVERLAY")
        slot.name:SetFont(FONT_PATH, 15, "OUTLINE")
        slot.name:SetJustifyH("LEFT")
        slot.name:SetPoint("LEFT", slot.iconFrame, "RIGHT", 8, 0)
        slot.name:SetPoint("RIGHT", slot, "RIGHT", -6, 0)

        slot.info = slot:CreateFontString(nil, "OVERLAY")
        slot.info:SetFont(FONT_PATH, 11, "OUTLINE")
        slot.info:SetTextColor(0.7, 0.7, 0.7, 0.9)
        slot.info:SetJustifyH("LEFT")
        slot.info:SetPoint("TOPLEFT", slot.name, "BOTTOMLEFT", 0, -1)
        slot.info:SetPoint("RIGHT", slot, "RIGHT", -6, 0)
        slot.info:Hide()

        slot.divider = CreateFrame("Frame", nil, slot)
        slot.divider:SetHeight(1)
        slot.divider:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", 4, -1)
        slot.divider:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -4, -1)
        slot.divider:EnableMouse(false)

        local divL = slot.divider:CreateTexture(nil, "ARTWORK")
        divL:SetTexture("Interface\\Buttons\\WHITE8X8")
        divL:SetPoint("LEFT", slot.divider, "LEFT", 0, 0)
        divL:SetPoint("RIGHT", slot.divider, "CENTER", 0, 0)
        divL:SetHeight(1)
        divL:SetGradientAlpha("HORIZONTAL", 0.4, 0.35, 0.2, 0, 0.4, 0.35, 0.2, 0.3)

        local divR = slot.divider:CreateTexture(nil, "ARTWORK")
        divR:SetTexture("Interface\\Buttons\\WHITE8X8")
        divR:SetPoint("LEFT", slot.divider, "CENTER", 0, 0)
        divR:SetPoint("RIGHT", slot.divider, "RIGHT", 0, 0)
        divR:SetHeight(1)
        divR:SetGradientAlpha("HORIZONTAL", 0.4, 0.35, 0.2, 0.3, 0.4, 0.35, 0.2, 0)
    end

    local function ApplySlotQuality(slot, quality, showBorder, showGlow, glowThreshold)
        local q = (showBorder and quality and quality >= 0) and quality or 1
        slot.iconBorder:SetTexture(SLOT_TEX_BY_QUALITY[q] or SLOT_TEX_BY_QUALITY[1])

        if showGlow and quality and quality >= glowThreshold then
            local color = SafeQualityColor(quality)
            slot.rarity:SetVertexColor(color.r, color.g, color.b)
            slot.rarity:Show()
        else
            slot.rarity:Hide()
        end
    end

    ---------------------------------------------------------------------------
    -- CreateSlot: interactive loot slot
    ---------------------------------------------------------------------------
    local function CreateSlot(id)
        -- Must use "LootButton" type — LootSlot() requires this secure frame
        -- type in Vanilla 1.12 for item loot to work.
        local slot = CreateFrame("LootButton", "DFUILootSlot" .. id, lootFrame)
        slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        SetupSlotVisuals(slot)

        slot.hover = slot:CreateTexture(nil, "HIGHLIGHT")
        slot.hover:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        slot.hover:SetBlendMode("ADD")
        slot.hover:SetAllPoints(slot)
        slot.hover:SetAlpha(0.15)

        -- OnClick: follow pfUI pattern — Ctrl/Shift handled first but LootSlot
        -- always called (don't gate it behind else). This ensures the LootButton
        -- secure action fires in the correct hardware-event context.
        slot:SetScript("OnClick", function()
            if autoLootFading then return end

            if IsControlKeyDown() then
                DressUpItemLink(GetLootSlotLink(this:GetID()))
            elseif IsShiftKeyDown() then
                if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                    ChatFrameEditBox:Insert(GetLootSlotLink(this:GetID()))
                end
            end

            StaticPopup_Hide("CONFIRM_LOOT_DISTRIBUTION")
            DFUI.lootSelectedSlot = this:GetID()
            LootFrame.selectedSlot = this:GetID()
            LootFrame.selectedQuality = this.quality
            LootFrame.selectedItemName = this.name:GetText()

            LootSlot(this:GetID())
        end)

        slot:SetScript("OnEnter", function()
            if autoLootFading then return end
            if LootSlotIsItem(this:GetID()) then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetLootItem(this:GetID())
                CursorUpdate()
            end
        end)

        slot:SetScript("OnLeave", function()
            GameTooltip:Hide()
            ResetCursor()
        end)

        slots[id] = slot
        return slot
    end

    ---------------------------------------------------------------------------
    -- AutoLootAll
    ---------------------------------------------------------------------------
    local function AutoLootAll()
        local numItems = GetNumLootItems()
        if numItems and numItems > 0 then
            for i = numItems, 1, -1 do
                LootSlot(i)
            end
        end
    end

    ---------------------------------------------------------------------------
    -- HandleBindConfirm
    ---------------------------------------------------------------------------
    local function HandleBindConfirm(slot)
        if not GetDB("autopickup_bop") then return end
        if GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 then return end
        if ConfirmLootSlot then
            ConfirmLootSlot(slot)
        else
            LootSlot(slot)
        end
        StaticPopup_Hide("LOOT_BIND")
    end

    ---------------------------------------------------------------------------
    -- ResizeFrame: shared frame sizing + border color from visible slots
    ---------------------------------------------------------------------------
    local function ResizeFrame(visibleCount, maxWidth, maxQuality, slotH)
        local frameW = math.max(FRAME_MIN_WIDTH, math.min(maxWidth, FRAME_MAX_WIDTH))
        local frameH = TITLE_BAR_HEIGHT + PADDING * 2 + visibleCount * slotH
            + math.max(0, visibleCount - 1) * SLOT_SPACING
        frameH = math.max(frameH, 60)
        lootFrame:SetWidth(frameW)
        lootFrame:SetHeight(frameH)

        -- 标题随最高品质染色（替代原"backdrop 边框染色"，新框体边框为纹理拼接）
        if maxQuality and maxQuality > 1 then
            local c = SafeQualityColor(maxQuality)
            lootFrame.title:SetTextColor(c.r, c.g, c.b)
        else
            lootFrame.title:SetTextColor(0.96875, 0.8984375, 0.578125)
        end
    end

    -- Hide last visible slot's divider
    local function HideLastDivider()
        local lastVis = 0
        for i = 1, table.getn(slots) do
            if slots[i] and slots[i]:IsShown() then lastVis = i end
        end
        if lastVis > 0 then
            slots[lastVis].divider:Hide()
        end
    end

    ---------------------------------------------------------------------------
    -- UpdateLootFrame: render all loot items
    ---------------------------------------------------------------------------
    local function UpdateLootFrame()
        local numItems = GetNumLootItems()
        LootFrame.numLootItems = numItems

        local maxWidth = 0
        local maxQuality = 0
        local visibleCount = 0
        local showInfo = GetDB("show_item_type")
        local showBorder = GetDB("quality_border")
        local showGlow = GetDB("quality_glow")
        local glowThreshold = GetDB("glow_threshold") or 2
        local slotH = showInfo and SLOT_HEIGHT_INFO or SLOT_HEIGHT

        for i = 1, numItems do
            local texture, item, quantity, quality = GetLootSlotInfo(i)
            if texture then
                visibleCount = visibleCount + 1
                local slot = slots[visibleCount] or CreateSlot(visibleCount)
                local color = SafeQualityColor(quality)

                if LootSlotIsCoin(i) then
                    item = string.gsub(string.gsub(item, "\n", ", "), ", $", "")
                end

                slot.icon:SetTexture(texture)
                slot.name:SetText(item)
                slot.name:SetTextColor(color.r, color.g, color.b)
                slot.quality = quality

                if quantity and quantity > 1 then
                    slot.count:SetText(quantity)
                    slot.count:Show()
                else
                    slot.count:Hide()
                end

                ApplySlotQuality(slot, quality, showBorder, showGlow, glowThreshold)

                if showInfo and slot.info then
                    local link = GetLootSlotLink(i)
                    if link and not LootSlotIsCoin(i) then
                        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(link)
                        if itemType then
                            local infoText = itemType
                            if itemSubType and itemSubType ~= "" then
                                infoText = infoText .. " · " .. itemSubType
                            end
                            slot.info:SetText(infoText)
                            slot.info:Show()
                        else
                            slot.info:Hide()
                        end
                    else
                        slot.info:Hide()
                    end
                elseif slot.info then
                    slot.info:Hide()
                end

                slot.name:ClearAllPoints()
                if showInfo then
                    slot.name:SetPoint("TOPLEFT", slot.iconFrame, "TOPRIGHT", 6, 0)
                    slot.name:SetPoint("RIGHT", slot, "RIGHT", -4, 0)
                else
                    slot.name:SetPoint("LEFT", slot.iconFrame, "RIGHT", 6, 0)
                    slot.name:SetPoint("RIGHT", slot, "RIGHT", -4, 0)
                end

                slot:SetID(i)
                if slot.SetSlot then
                    slot:SetSlot(i)
                end
                slot:Enable()
                slot:ClearAllPoints()
                slot:SetPoint("TOPLEFT", lootFrame, "TOPLEFT",
                    PADDING, -(TITLE_BAR_HEIGHT + PADDING + (visibleCount - 1) * (slotH + SLOT_SPACING)))
                slot:SetPoint("RIGHT", lootFrame, "RIGHT", -PADDING, 0)
                slot:SetHeight(slotH)

                local nameW = (slot.name:GetStringWidth() or 0) + ICON_SIZE + PADDING * 3
                if nameW > maxWidth then maxWidth = nameW end
                if (quality or 0) > maxQuality then maxQuality = quality or 0 end

                slot.divider:Show()
                slot:Show()
            end
        end

        HideLastDivider()

        for i = visibleCount + 1, table.getn(slots) do
            if slots[i] then slots[i]:Hide() end
        end

        ResizeFrame(visibleCount, maxWidth, maxQuality, slotH)
    end

    ---------------------------------------------------------------------------
    -- RelayoutSlots: re-position visible slots after one is cleared
    ---------------------------------------------------------------------------
    local function RelayoutSlots()
        local showInfo = GetDB("show_item_type")
        local slotH = showInfo and SLOT_HEIGHT_INFO or SLOT_HEIGHT
        local visibleCount = 0
        local maxWidth = 0
        local maxQuality = 0

        for i = 1, table.getn(slots) do
            if slots[i] and slots[i]:IsShown() then
                visibleCount = visibleCount + 1
                slots[i]:ClearAllPoints()
                slots[i]:SetPoint("TOPLEFT", lootFrame, "TOPLEFT",
                    PADDING, -(TITLE_BAR_HEIGHT + PADDING + (visibleCount - 1) * (slotH + SLOT_SPACING)))
                slots[i]:SetPoint("RIGHT", lootFrame, "RIGHT", -PADDING, 0)
                slots[i].divider:Show()

                local nameW = (slots[i].name:GetStringWidth() or 0) + ICON_SIZE + PADDING * 3
                if nameW > maxWidth then maxWidth = nameW end
                local q = slots[i].quality or 0
                if q > maxQuality then maxQuality = q end
            end
        end

        HideLastDivider()

        if visibleCount > 0 then
            ResizeFrame(visibleCount, maxWidth, maxQuality, slotH)
        end
    end

    ---------------------------------------------------------------------------
    -- OnEvent: main event dispatcher
    ---------------------------------------------------------------------------
    local function OnEvent()
        if event == "LOOT_OPENED" then
            -- cancel any previous fade still running
            if autoLootFading then
                StopFade()
            end
            autoLootPending = false

            local cursorX, cursorY = GetCursorPosition()
            local itemsLeft = GetNumLootItems()

            -- SuperWoW DLL already looted everything → nothing to show
            if itemsLeft == 0 then
                return
            end

            -- fishing sound
            if IsFishingLoot() then
                PlaySound("FISHING REEL IN")
            end

            -- always show and render items first
            lootFrame:Show()
            if GetDB("mousecursor") and not DFUI_FRAMEPOS["DFUILootFrame"] then
                PositionFrameAtCursor(lootFrame, cursorX, cursorY)
            end
            UpdateLootFrame()

            -- check if auto-loot should happen at Lua level
            -- (only needed when DLL didn't handle it, i.e. items still present)
            local wantAuto = GetDB("autoloot") or IsShiftKeyDown()
                or (arg1 and arg1 ~= 0)
            if wantAuto then
                autoLootPending = true  -- keep slots visible during LOOT_SLOT_CLEARED
                AutoLootAll()
            end

        elseif event == "LOOT_SLOT_CLEARED" then
            if not arg1 then return end
            if autoLootPending or autoLootFading then return end  -- keep slots during auto-loot

            for i = 1, table.getn(slots) do
                if slots[i] and slots[i]:IsShown() and slots[i]:GetID() == arg1 then
                    slots[i]:Hide()
                    break
                end
            end
            RelayoutSlots()

        elseif event == "LOOT_CLOSED" then
            if autoLootFading then return end  -- fade handles its own cleanup

            if autoLootPending then
                -- auto-loot completed: keep frame visible, start fade
                autoLootPending = false
                StartFade()
            else
                -- manual loot: close immediately
                closingLoot = true
                StaticPopup_Hide("LOOT_BIND")
                lootFrame:Hide()
                if DropDownList1 and DropDownList1:IsShown() then
                    CloseDropDownMenus()
                end
                for i = 1, table.getn(slots) do
                    slots[i]:Hide()
                end
                closingLoot = false
            end

        elseif event == "OPEN_MASTER_LOOT_LIST" then
            if DFUI.lootSelectedSlot then
                for i = 1, table.getn(slots) do
                    if slots[i] and slots[i]:GetID() == DFUI.lootSelectedSlot then
                        ToggleDropDownMenu(1, nil, GroupLootDropDown, slots[i], 0, 0)
                        break
                    end
                end
            end

        elseif event == "UPDATE_MASTER_LOOT_LIST" then
            UIDropDownMenu_Refresh(GroupLootDropDown)

        elseif event == "LOOT_BIND_CONFIRM" then
            HandleBindConfirm(arg1)
        end
    end

    ---------------------------------------------------------------------------
    -- Init: called on PLAYER_ENTERING_WORLD
    ---------------------------------------------------------------------------
    local function Init()
        -- Disable default LootFrame (pfUI approach: UnregisterAllEvents only)
        LootFrame:UnregisterAllEvents()
        for i = 1, LOOTFRAME_NUMITEMS or 4 do
            local btn = getglobal("LootButton" .. i)
            if btn then btn:Hide() end
        end

        -- 使用 DFUI 通用窗体工厂（带金属边框 + 羊皮纸背景）
        -- frameStyle=2 = 无头像金属框，适合小窗
        lootFrame = DFUI.CreatePaperDollFrame("DFUILootFrame", UIParent,
                                              FRAME_MIN_WIDTH, 60, 2)
        lootFrame:SetFrameStrata("DIALOG")
        lootFrame:SetFrameLevel(10)
        lootFrame:SetClampedToScreen(true)
        lootFrame:Hide()

        -- 标题：物品
        lootFrame.title = lootFrame:CreateFontString(nil, "OVERLAY")
        lootFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        lootFrame.title:SetText("物品")
        lootFrame.title:SetTextColor(0.96875, 0.8984375, 0.578125)
        lootFrame.title:SetPoint("TOP", lootFrame, "TOP", 0, -4)

        -- 红色 X 关闭按钮
        local closeBtn = DFUI.CreateRedButton(lootFrame, "close", function()
            CloseLoot()
        end)
        closeBtn:SetPoint("TOPRIGHT", lootFrame, "TOPRIGHT", 0, -1)

        lootFrame:SetScale(GetDB("scale") or 1.0)
        lootFrame:SetPoint("TOP", UIParent, "CENTER", 0, 100)

        tinsert(UISpecialFrames, "DFUILootFrame")
        DFUI.lootFrame = lootFrame

        lootFrame:RegisterEvent("LOOT_OPENED")
        lootFrame:RegisterEvent("LOOT_CLOSED")
        lootFrame:RegisterEvent("LOOT_SLOT_CLEARED")
        lootFrame:RegisterEvent("OPEN_MASTER_LOOT_LIST")
        lootFrame:RegisterEvent("UPDATE_MASTER_LOOT_LIST")
        lootFrame:RegisterEvent("LOOT_BIND_CONFIRM")

        lootFrame:SetScript("OnEvent", OnEvent)

        lootFrame:SetScript("OnHide", function()
            StaticPopup_Hide("CONFIRM_LOOT_DISTRIBUTION")
            if not closingLoot and not autoLootFading then
                CloseLoot()
            end
        end)
    end

    ---------------------------------------------------------------------------
    -- Module entry point
    ---------------------------------------------------------------------------
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        f:UnregisterEvent("PLAYER_ENTERING_WORLD")
        Init()

        -- Initialize roll module (defined in roll.lua, shares Loot's enabled state)
        if DFUI.InitLootRoll then
            DFUI.InitLootRoll()
        end
    end)

    ---------------------------------------------------------------------------
    -- Callbacks
    ---------------------------------------------------------------------------
    local callbacks = {}

    callbacks.scale = function(value)
        if DFUI.lootFrame then
            DFUI.lootFrame:SetScale(value or 1.0)
        end
    end

    callbacks.mousecursor = function(value)
        if value and DFUI_FRAMEPOS then
            DFUI_FRAMEPOS["DFUILootFrame"] = nil
        end
    end

    DFUI:NewCallbacks("Loot", callbacks)
end)
