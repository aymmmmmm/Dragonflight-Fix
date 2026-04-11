DFUI:NewDefaults("Gui-superwow", {
    enabled = {true},
})

DFUI:NewDefaults("SuperWoW", {
    enabled = {true},
    autoloot = {false},
    shiftloot = {false},
    clickthrough = {false},
    fov = {1.5},
    backgroundsound = {false},
    lootSparkle = {false},
    selectionCircleStyle = {1},
    uncapSounds = {false},
    macroExtend = {true},
    spellLink = {true},
    mouseoverCast = {true},
    guidCombatText = {true},
    enchantLink = {true},
    chatBubbles = {true},
})

DFUI:NewMod("Gui-superwow", 3, function()
    local Base = DFUI.gui.Base
    local panel = Base.scrollChildren[13]
    local SS = DFUI.tools.ScaledSize
    local fontPath = DFUI:GetInfoOrCons("font")

    local Setup = {
        init = false,
        lootFrame = nil,
        controls = {},

        -- original function refs for hooks
        origSetItemRef = nil,
        origSpellButton_OnClick = nil,
        origUnitFrame_OnEnter = nil,
        origUnitFrame_OnLeave = nil,
        origCombatText_AddMessage = nil,
    }

    --=================
    -- SUPERWOW FUNCTIONS
    --=================

    function Setup:ApplyAutoloot()
        if not SUPERWOW_VERSION then return end

        -- clean up previous OnUpdate
        if self.lootFrame then
            self.lootFrame:SetScript("OnUpdate", nil)
            self.lootFrame = nil
        end

        local shiftloot = DFUI:GetTempDB("SuperWoW", "shiftloot")
        local autoloot = DFUI:GetTempDB("SuperWoW", "autoloot")

        if shiftloot then
            self.lootFrame = CreateFrame("Frame")
            self.lootFrame:SetScript("OnUpdate", function()
                if IsShiftKeyDown() then
                    SetAutoloot(1)
                else
                    SetAutoloot(0)
                end
            end)
        elseif autoloot then
            SetAutoloot(1)
        else
            SetAutoloot(0)
        end
    end

    function Setup:ApplyClickthrough()
        if not SUPERWOW_VERSION then return end
        local val = DFUI:GetTempDB("SuperWoW", "clickthrough")
        Clickthrough(val and 1 or 0)
    end

    function Setup:ApplyFov()
        if not SUPERWOW_VERSION then return end
        local val = DFUI:GetTempDB("SuperWoW", "fov")
        SetCVar("FoV", val or 1.5)
    end

    function Setup:ApplyBackgroundSound()
        if not SUPERWOW_VERSION then return end
        local val = DFUI:GetTempDB("SuperWoW", "backgroundsound")
        SetCVar("BackgroundSound", val and "1" or "0")
    end

    function Setup:ApplyLootSparkle()
        if not SUPERWOW_VERSION then return end
        local val = DFUI:GetTempDB("SuperWoW", "lootSparkle")
        SetCVar("LootSparkle", val and "1" or "0")
    end

    function Setup:ApplySelectionCircle()
        if not SUPERWOW_VERSION then return end
        local val = DFUI:GetTempDB("SuperWoW", "selectionCircleStyle")
        SetCVar("SelectionCircleStyle", tostring(val or 1))
    end

    function Setup:ApplyUncapSounds()
        if not SUPERWOW_VERSION then return end
        local val = DFUI:GetTempDB("SuperWoW", "uncapSounds")
        if val then
            SetCVar("UncapSounds", "1")
            SetCVar("SoundSoftwareChannels", "64")
            SetCVar("SoundMaxHardwareChannels", "64")
        else
            SetCVar("UncapSounds", "0")
            SetCVar("SoundSoftwareChannels", "12")
            SetCVar("SoundMaxHardwareChannels", "12")
        end
    end

    function Setup:GetSpellLink(id)
        local spellname = SpellInfo(id)
        return "\124cffffffff\124Henchant:" .. id .. "\124h[" .. spellname .. "]\124h\124r"
    end

    function Setup:ApplyMacroExtend()
        if not SUPERWOW_VERSION then return end
        if DFUI:GetTempDB("SuperWoW", "macroExtend") then
            MacroFrame_LoadUI()
            if MacroFrameText then
                MacroFrameText:SetMaxLetters(511)
            end
            MACROFRAME_CHAR_LIMIT = "已使用 %d/511 个字符"
        end
    end

    function Setup:ApplyChatBubbles()
        if not SUPERWOW_VERSION then return end
        if DFUI:GetTempDB("SuperWoW", "chatBubbles") then
            OPTION_TOOLTIP_PARTY_CHAT_BUBBLES = "显示密语、小队、团队和战场聊天文本在角色头顶的气泡中。"
            PARTY_CHAT_BUBBLES_TEXT = "显示密语和团队聊天气泡"
        end
    end

    function Setup:InstallHooks()
        if not SUPERWOW_VERSION then return end

        self:ApplyMacroExtend()
        self:ApplyChatBubbles()

        -- Hook SetItemRef: convert spell: to enchant: (checks enchantLink setting)
        if not self.origSetItemRef then
            self.origSetItemRef = SetItemRef
            SetItemRef = function(link, text, button)
                if DFUI:GetTempDB("SuperWoW", "enchantLink") then
                    link = gsub(link, "spell:", "enchant:")
                end
                Setup.origSetItemRef(link, text, button)
            end
        end

        -- Hook SpellButton_OnClick: shift-click spell link in chat (checks spellLink setting)
        if not self.origSpellButton_OnClick and SpellButton_OnClick then
            self.origSpellButton_OnClick = SpellButton_OnClick
            SpellButton_OnClick = function(drag)
                if DFUI:GetTempDB("SuperWoW", "spellLink") and (not drag) and IsShiftKeyDown() and ChatFrameEditBox:IsVisible() and (not MacroFrame or not MacroFrame:IsVisible()) then
                    local bookId = SpellBook_GetSpellID(this:GetID())
                    local _, _, spellID = GetSpellName(bookId, SpellBookFrame.bookType)
                    local link = Setup:GetSpellLink(spellID)
                    ChatFrameEditBox:Insert(link)
                else
                    Setup.origSpellButton_OnClick(drag)
                end
            end
        end

        -- Hook UnitFrame_OnEnter/OnLeave: mouseover casting (checks mouseoverCast setting)
        if not self.origUnitFrame_OnEnter and UnitFrame_OnEnter then
            self.origUnitFrame_OnEnter = UnitFrame_OnEnter
            UnitFrame_OnEnter = function()
                Setup.origUnitFrame_OnEnter()
                if DFUI:GetTempDB("SuperWoW", "mouseoverCast") and this.unit then
                    SetMouseoverUnit(this.unit)
                end
            end
        end

        if not self.origUnitFrame_OnLeave and UnitFrame_OnLeave then
            self.origUnitFrame_OnLeave = UnitFrame_OnLeave
            UnitFrame_OnLeave = function()
                Setup.origUnitFrame_OnLeave()
                if DFUI:GetTempDB("SuperWoW", "mouseoverCast") then
                    SetMouseoverUnit()
                end
            end
        end

        -- Hook CombatText_AddMessage: GUID -> name conversion (checks guidCombatText setting)
        if not self.origCombatText_AddMessage and CombatText_AddMessage then
            self.origCombatText_AddMessage = CombatText_AddMessage
            CombatText_AddMessage = function(message, scrollFunction, r, g, b, displayType, isStaggered)
                if DFUI:GetTempDB("SuperWoW", "guidCombatText") then
                    local newMessage = gsub(message, "(%s%[)(0x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x)(%])", function(bracket1, hex, bracket2)
                        if UnitIsUnit(hex, "player") then return nil
                        else
                            local _, class = UnitClass(hex)
                            if not class then return " [" .. UnitName(hex) .. "]" end
                            local c = RAID_CLASS_COLORS[class]
                            if not c then return " [" .. UnitName(hex) .. "]" end
                            local color = string.format("ff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
                            return " [|c" .. color .. UnitName(hex) .. "|r]"
                        end
                    end)
                    return Setup.origCombatText_AddMessage(newMessage, scrollFunction, r, g, b, displayType, isStaggered)
                else
                    return Setup.origCombatText_AddMessage(message, scrollFunction, r, g, b, displayType, isStaggered)
                end
            end
        end
    end

    --=================
    -- GUI HELPERS
    --=================

    local PANEL_WIDTH = 680
    local PANEL_INSET = 15
    local ITEM_HEIGHT = 28
    local DESC_COLOR = {0.54, 0.48, 0.35}
    local GOLD_COLOR = {1, 0.82, 0}

    local function CreateCategoryPanel(parent, width, height)
        local bg = CreateFrame("Frame", nil, parent)
        bg:SetWidth(width)
        bg:SetHeight(height)
        bg:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        bg:SetBackdropColor(0.10, 0.07, 0.03, 0.4)
        bg:SetBackdropBorderColor(0.48, 0.33, 0.09, 0.3)
        return bg
    end

    -- Create a checkbox row inside a category panel, returns checkbox and inner yOffset consumed
    local function AddCheckboxRow(catPanel, innerY, key, label, desc, onClick)
        local cb = DFUI.tools.CreateIndiCheckbox(catPanel, nil, label)
        cb:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -innerY)
        cb:SetChecked(DFUI:GetTempDB("SuperWoW", key))

        local consumed = ITEM_HEIGHT
        if desc then
            local descFont = DFUI.tools.CreateFont(catPanel, 10, desc, DESC_COLOR, "LEFT")
            descFont:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET + 28, -(innerY + 20))
            consumed = consumed + 14
        end

        if onClick then
            cb:SetScript("OnClick", onClick)
        else
            local k = key
            cb:SetScript("OnClick", function()
                local checked = this:GetChecked() and true or false
                DFUI:SetTempDB("SuperWoW", k, checked)
            end)
        end

        return cb, consumed
    end

    -- Create a slider row inside a category panel, returns slider and inner yOffset consumed
    local function AddSliderRow(catPanel, innerY, key, label, desc, minVal, maxVal, step, fmt, onChanged)
        -- label space above slider
        local labelGap = 15
        local slider = DFUI.tools.CreateIndiSlider(catPanel, nil, label, minVal, maxVal, step)
        slider:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -(innerY + labelGap))
        slider:SetValue(DFUI:GetTempDB("SuperWoW", key) or minVal)
        slider.updateValueText()

        if onChanged then
            slider:SetScript("OnValueChanged", onChanged)
        end

        slider:EnableMouseWheel(true)
        local s = step
        slider:SetScript("OnMouseWheel", function()
            local value = this:GetValue()
            local lo, hi = this:GetMinMaxValues()
            if arg1 > 0 then
                value = math.min(value + s, hi)
            else
                value = math.max(value - s, lo)
            end
            this:SetValue(value)
        end)

        local consumed = labelGap + 28
        if desc then
            local descFont = DFUI.tools.CreateFont(catPanel, 10, desc, DESC_COLOR, "LEFT")
            descFont:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -(innerY + consumed))
            consumed = consumed + 16
        end

        return slider, consumed
    end

    --=================
    -- BUILD PANEL
    --=================

    function Setup:BuildPanel()
        if self.init then return end
        self.init = true

        local yPos = 10
        local hasSuperWoW = SUPERWOW_VERSION

        -- Status line
        local statusFont = DFUI.tools.CreateFont(panel, 13, "", DESC_COLOR, "CENTER")
        statusFont:SetPoint("TOP", panel, "TOP", 0, -yPos)
        if hasSuperWoW then
            statusFont:SetText("SuperWoW v" .. tostring(SUPERWOW_VERSION) .. " 已检测到")
            statusFont:SetTextColor(0.4, 1, 0.4)
        else
            statusFont:SetText("未检测到 SuperWoW — 请在登录器中开启增强模式")
            statusFont:SetTextColor(1, 0.4, 0.4)
        end
        yPos = yPos + 22

        T.GradientLine(panel, "TOP", -yPos, 1, 500)
        yPos = yPos + 18

        if not hasSuperWoW then
            local warnFont = DFUI.tools.CreateFontWarner(panel, 18, "所有功能不可用", {1, 0.5, 0.5}, true)
            warnFont:SetPoint("TOP", panel, "TOP", 0, -yPos - 40)
            return
        end

        -- Reload button (top)
        local reloadBtn = DFUI.tools.CreateButton(panel, "重载界面", 160, 28, false, GOLD_COLOR)
        reloadBtn:SetPoint("TOP", panel, "TOP", 0, -yPos)
        reloadBtn:SetScript("OnClick", function() ReloadUI() end)
        yPos = yPos + 42

        T.GradientLine(panel, "TOP", -yPos, 1, 500)
        yPos = yPos + 8

        --=============================
        -- Category 1: 拾取设置
        --=============================
        local cat1InnerY = 50
        local cat1Items = {}

        -- Pre-declare for mutual exclusion
        local cbAutoloot, cbShiftloot
        local consumed

        -- Calculate panel height: header(50) + 4 items
        -- autoloot(28) + shiftloot(28+14) + clickthrough(28+14) + sparkle(28) + padding
        local cat1Height = 50 + 28 + 42 + 42 + 28 + 15

        local cat1Panel = CreateCategoryPanel(panel, PANEL_WIDTH, cat1Height)
        cat1Panel:SetPoint("TOP", panel, "TOP", 0, -yPos)

        -- Category header
        local cat1Title = cat1Panel:CreateFontString(nil, "OVERLAY")
        cat1Title:SetFont(fontPath .. "BigNoodleTitling.ttf", SS(16), "OUTLINE")
        cat1Title:SetPoint("TOPLEFT", cat1Panel, "TOPLEFT", PANEL_INSET, -10)
        cat1Title:SetText("拾取设置")
        cat1Title:SetTextColor(GOLD_COLOR[1], GOLD_COLOR[2], GOLD_COLOR[3])

        local cat1Desc = DFUI.tools.CreateFont(cat1Panel, 11, "自动拾取、穿透尸体、闪光效果", DESC_COLOR, "LEFT")
        cat1Desc:SetPoint("TOPLEFT", cat1Panel, "TOPLEFT", PANEL_INSET + 1, -28)

        local cat1Sep = cat1Panel:CreateTexture(nil, "ARTWORK")
        cat1Sep:SetTexture("Interface\\Buttons\\WHITE8X8")
        cat1Sep:SetHeight(1)
        cat1Sep:SetWidth(PANEL_WIDTH - 30)
        cat1Sep:SetPoint("TOPLEFT", cat1Panel, "TOPLEFT", PANEL_INSET, -44)
        cat1Sep:SetVertexColor(0.48, 0.33, 0.09, 0.25)

        local iy = cat1InnerY

        -- Autoloot
        cbAutoloot = DFUI.tools.CreateIndiCheckbox(cat1Panel, nil, "自动拾取")
        cbAutoloot:SetPoint("TOPLEFT", cat1Panel, "TOPLEFT", PANEL_INSET, -iy)
        cbAutoloot:SetChecked(DFUI:GetTempDB("SuperWoW", "autoloot"))
        iy = iy + ITEM_HEIGHT

        -- Shift loot
        cbShiftloot, consumed = AddCheckboxRow(cat1Panel, iy, "shiftloot", "Shift手动拾取模式", "按住Shift拾取物品，不按Shift就自动拾取")
        iy = iy + consumed

        -- Mutual exclusion scripts
        cbAutoloot:SetScript("OnClick", function()
            local checked = this:GetChecked() and true or false
            DFUI:SetTempDB("SuperWoW", "autoloot", checked)
            if checked then
                DFUI:SetTempDB("SuperWoW", "shiftloot", false)
                cbShiftloot:SetChecked(false)
            end
            Setup:ApplyAutoloot()
        end)
        cbShiftloot:SetScript("OnClick", function()
            local checked = this:GetChecked() and true or false
            DFUI:SetTempDB("SuperWoW", "shiftloot", checked)
            if checked then
                DFUI:SetTempDB("SuperWoW", "autoloot", false)
                cbAutoloot:SetChecked(false)
            end
            Setup:ApplyAutoloot()
        end)

        -- Clickthrough
        local cbClick
        cbClick, consumed = AddCheckboxRow(cat1Panel, iy, "clickthrough", "点击穿透尸体", "允许你点击穿透尸体以拾取下面的尸体", function()
            local checked = this:GetChecked() and true or false
            DFUI:SetTempDB("SuperWoW", "clickthrough", checked)
            Setup:ApplyClickthrough()
        end)
        iy = iy + consumed

        -- Loot Sparkle
        local cbSparkle
        cbSparkle, consumed = AddCheckboxRow(cat1Panel, iy, "lootSparkle", "战利品闪光效果", nil, function()
            local checked = this:GetChecked() and true or false
            DFUI:SetTempDB("SuperWoW", "lootSparkle", checked)
            Setup:ApplyLootSparkle()
        end)

        yPos = yPos + cat1Height + 12

        --=============================
        -- Category 2: 视觉设置
        --=============================
        -- FoV slider(15+28+16) + Circle slider(15+28+16) + header(50) + padding
        local cat2Height = 50 + (15 + 28 + 16) + (15 + 28 + 16) + 15

        local cat2Panel = CreateCategoryPanel(panel, PANEL_WIDTH, cat2Height)
        cat2Panel:SetPoint("TOP", panel, "TOP", 0, -yPos)

        local cat2Title = cat2Panel:CreateFontString(nil, "OVERLAY")
        cat2Title:SetFont(fontPath .. "BigNoodleTitling.ttf", SS(16), "OUTLINE")
        cat2Title:SetPoint("TOPLEFT", cat2Panel, "TOPLEFT", PANEL_INSET, -10)
        cat2Title:SetText("视觉设置")
        cat2Title:SetTextColor(GOLD_COLOR[1], GOLD_COLOR[2], GOLD_COLOR[3])

        local cat2Desc = DFUI.tools.CreateFont(cat2Panel, 11, "视野范围、选择光圈样式", DESC_COLOR, "LEFT")
        cat2Desc:SetPoint("TOPLEFT", cat2Panel, "TOPLEFT", PANEL_INSET + 1, -28)

        local cat2Sep = cat2Panel:CreateTexture(nil, "ARTWORK")
        cat2Sep:SetTexture("Interface\\Buttons\\WHITE8X8")
        cat2Sep:SetHeight(1)
        cat2Sep:SetWidth(PANEL_WIDTH - 30)
        cat2Sep:SetPoint("TOPLEFT", cat2Panel, "TOPLEFT", PANEL_INSET, -44)
        cat2Sep:SetVertexColor(0.48, 0.33, 0.09, 0.25)

        iy = 50

        -- FoV slider
        local sliderFov
        sliderFov, consumed = AddSliderRow(cat2Panel, iy, "fov", "视野范围 (需重载)", "改变游戏的视野范围。需要重载UI才能生效", 0.1, 3.14, 0.05, "%.2f")
        sliderFov:SetScript("OnValueChanged", function()
            local newValue = this:GetValue()
            local rounded = math.floor(newValue * 100 + 0.5) / 100
            sliderFov.valueText:SetText(string.format("%.2f", rounded))
            DFUI:SetTempDB("SuperWoW", "fov", rounded)
        end)
        iy = iy + consumed

        -- Selection circle slider
        local circleStyles = {
            [1] = "默认不完整圆",
            [2] = "完整圆形",
            [3] = "带箭头圆形",
            [4] = "经典朝向圆形",
        }

        local circleDescFont -- forward declare

        local sliderCircle
        sliderCircle, consumed = AddSliderRow(cat2Panel, iy, "selectionCircleStyle", "选择光圈样式", nil, 1, 4, 1, "%d")

        -- Replace the desc with a dynamic style name
        circleDescFont = DFUI.tools.CreateFont(cat2Panel, 10, circleStyles[DFUI:GetTempDB("SuperWoW", "selectionCircleStyle") or 1] or "", DESC_COLOR, "LEFT")
        circleDescFont:SetPoint("TOPLEFT", cat2Panel, "TOPLEFT", PANEL_INSET, -(iy + 15 + 28))

        sliderCircle:SetScript("OnValueChanged", function()
            local newValue = this:GetValue()
            local rounded = math.floor(newValue + 0.5)
            sliderCircle.valueText:SetText(string.format("%d", rounded))
            DFUI:SetTempDB("SuperWoW", "selectionCircleStyle", rounded)
            Setup:ApplySelectionCircle()
            if circleDescFont then
                circleDescFont:SetText(circleStyles[rounded] or "")
            end
        end)

        yPos = yPos + cat2Height + 12

        --=============================
        -- Category 3: 声音设置
        --=============================
        local cat3Height = 50 + 42 + 42 + 10

        local cat3Panel = CreateCategoryPanel(panel, PANEL_WIDTH, cat3Height)
        cat3Panel:SetPoint("TOP", panel, "TOP", 0, -yPos)

        local cat3Title = cat3Panel:CreateFontString(nil, "OVERLAY")
        cat3Title:SetFont(fontPath .. "BigNoodleTitling.ttf", SS(16), "OUTLINE")
        cat3Title:SetPoint("TOPLEFT", cat3Panel, "TOPLEFT", PANEL_INSET, -10)
        cat3Title:SetText("声音设置")
        cat3Title:SetTextColor(GOLD_COLOR[1], GOLD_COLOR[2], GOLD_COLOR[3])

        local cat3Desc = DFUI.tools.CreateFont(cat3Panel, 11, "背景声音、声音通道限制", DESC_COLOR, "LEFT")
        cat3Desc:SetPoint("TOPLEFT", cat3Panel, "TOPLEFT", PANEL_INSET + 1, -28)

        local cat3Sep = cat3Panel:CreateTexture(nil, "ARTWORK")
        cat3Sep:SetTexture("Interface\\Buttons\\WHITE8X8")
        cat3Sep:SetHeight(1)
        cat3Sep:SetWidth(PANEL_WIDTH - 30)
        cat3Sep:SetPoint("TOPLEFT", cat3Panel, "TOPLEFT", PANEL_INSET, -44)
        cat3Sep:SetVertexColor(0.48, 0.33, 0.09, 0.25)

        iy = 50

        -- Background sound
        local cbBgSound
        cbBgSound, consumed = AddCheckboxRow(cat3Panel, iy, "backgroundsound", "背景声音", "即使窗口位于后台，也允许游戏声音播放", function()
            local checked = this:GetChecked() and true or false
            DFUI:SetTempDB("SuperWoW", "backgroundsound", checked)
            Setup:ApplyBackgroundSound()
        end)
        iy = iy + consumed

        -- Uncapped sounds
        local cbUncap
        cbUncap, consumed = AddCheckboxRow(cat3Panel, iy, "uncapSounds", "无限制声音", "移除硬编码限制，允许更多声音同时播放 (通道设为64)", function()
            local checked = this:GetChecked() and true or false
            DFUI:SetTempDB("SuperWoW", "uncapSounds", checked)
            Setup:ApplyUncapSounds()
        end)

        yPos = yPos + cat3Height + 12

        --=============================
        -- Category 4: 增强功能
        --=============================
        local enhFeatures = {
            {key = "macroExtend",    label = "宏框架511字符",       desc = "将宏文本框字符数限制从255提升至511"},
            {key = "spellLink",      label = "Shift点击法术链接",   desc = "在法术书中Shift+点击法术可链接到聊天框"},
            {key = "mouseoverCast",  label = "鼠标悬停施法",        desc = "鼠标悬停在单位框架上时设置mouseover目标"},
            {key = "guidCombatText", label = "GUID战斗文本",        desc = "将战斗文本中的GUID自动转换为带职业颜色的角色名"},
            {key = "enchantLink",    label = "Enchant链接转换",     desc = "自动将spell:链接转换为enchant:链接以正确显示"},
            {key = "chatBubbles",    label = "增强聊天气泡",        desc = "聊天气泡显示密语、小队、团队和战场消息"},
        }

        local enhCount = table.getn(enhFeatures)
        -- Each feature: checkbox(28) + desc(14) = 42, header(50), note(22), padding
        local cat4Height = 50 + enhCount * 42 + 22 + 10

        local cat4Panel = CreateCategoryPanel(panel, PANEL_WIDTH, cat4Height)
        cat4Panel:SetPoint("TOP", panel, "TOP", 0, -yPos)

        local cat4Title = cat4Panel:CreateFontString(nil, "OVERLAY")
        cat4Title:SetFont(fontPath .. "BigNoodleTitling.ttf", SS(16), "OUTLINE")
        cat4Title:SetPoint("TOPLEFT", cat4Panel, "TOPLEFT", PANEL_INSET, -10)
        cat4Title:SetText("增强功能")
        cat4Title:SetTextColor(GOLD_COLOR[1], GOLD_COLOR[2], GOLD_COLOR[3])

        local cat4Count = cat4Panel:CreateFontString(nil, "OVERLAY")
        cat4Count:SetFont(fontPath .. "BigNoodleTitling.ttf", SS(11), "OUTLINE")
        cat4Count:SetPoint("LEFT", cat4Title, "RIGHT", 8, 0)
        cat4Count:SetText("(" .. enhCount .. ")")
        cat4Count:SetTextColor(DESC_COLOR[1], DESC_COLOR[2], DESC_COLOR[3])

        local cat4Desc = DFUI.tools.CreateFont(cat4Panel, 11, "宏、法术链接、鼠标悬停施法等客户端增强", DESC_COLOR, "LEFT")
        cat4Desc:SetPoint("TOPLEFT", cat4Panel, "TOPLEFT", PANEL_INSET + 1, -28)

        local cat4Sep = cat4Panel:CreateTexture(nil, "ARTWORK")
        cat4Sep:SetTexture("Interface\\Buttons\\WHITE8X8")
        cat4Sep:SetHeight(1)
        cat4Sep:SetWidth(PANEL_WIDTH - 30)
        cat4Sep:SetPoint("TOPLEFT", cat4Panel, "TOPLEFT", PANEL_INSET, -44)
        cat4Sep:SetVertexColor(0.48, 0.33, 0.09, 0.25)

        iy = 50
        for _, feat in ipairs(enhFeatures) do
            local cb
            cb, consumed = AddCheckboxRow(cat4Panel, iy, feat.key, feat.label, feat.desc)
            iy = iy + consumed
        end

        -- Note at bottom
        local enhNote = DFUI.tools.CreateFont(cat4Panel, 10, "宏框架、聊天气泡更改需重载UI生效，其余实时生效", GOLD_COLOR, "LEFT")
        enhNote:SetPoint("TOPLEFT", cat4Panel, "TOPLEFT", PANEL_INSET, -iy)

        yPos = yPos + cat4Height + 12
    end

    --=================
    -- INIT
    --=================

    local f = CreateFrame("Frame")
    f:RegisterEvent("VARIABLES_LOADED")
    f:SetScript("OnEvent", function()
        -- small delay to ensure SUPERWOW_VERSION is set
        local waitFrame = CreateFrame("Frame")
        waitFrame.elapsed = 0
        waitFrame:SetScript("OnUpdate", function()
            this.elapsed = this.elapsed + arg1
            if this.elapsed > 0.5 then
                this:SetScript("OnUpdate", nil)

                -- Build GUI panel
                Setup:BuildPanel()

                -- Apply settings if SuperWoW is present
                if SUPERWOW_VERSION then
                    Setup:ApplyAutoloot()
                    Setup:ApplyClickthrough()
                    Setup:ApplyFov()
                    Setup:ApplyBackgroundSound()
                    Setup:ApplyLootSparkle()
                    Setup:ApplySelectionCircle()
                    Setup:ApplyUncapSounds()
                    Setup:InstallHooks()
                end

                -- Enable/disable tab 13
                if DFUI.gui.Base and DFUI.gui.Base.tabButtons and DFUI.gui.Base.tabButtons[13] then
                    local tab = DFUI.gui.Base.tabButtons[13]
                    if SUPERWOW_VERSION then
                        tab:Enable()
                        tab:GetFontString():SetTextColor(.7, .7, .7, 1)
                        tab:SetScript("OnClick", function()
                            DFUI.gui.Base:SelectTab(13)
                        end)
                        tab:SetScript("OnEnter", function()
                            if 13 ~= DFUI.gui.Base.selectedTab then
                                tab.highlight:Show()
                            end
                        end)
                        tab:SetScript("OnLeave", function()
                            if 13 ~= DFUI.gui.Base.selectedTab then
                                tab.highlight:Hide()
                            end
                        end)
                    end
                end
            end
        end)
    end)

    DFUI.gui.SuperWoW = Setup
end)
