DFUI:NewDefaults("Gui-elem", {
    enabled = {true},
})

DFUI:NewMod("Gui-elem", 3, function()

    --=================
    -- SETUP THE BEAST
    --=================
    local pairs = pairs
    local ipairs = ipairs
    local table = table
    local string = string
    local type = type
    local tonumber = tonumber

    local Base = DFUI.gui.Base
    local Setup = {
        font = DFUI:GetInfoOrCons("font"),

        metadata = {},
        checkboxes = {},
        sliders = {},
        dropdowns = {},
        colours = {},
        descriptionLabels = {},
        extraDescriptionLabels = {},
        headers = {},
        moduleHeaders = {},
        dependenciesSetup = false,
        tabPositions = {},
        configCache = {},

        DESCRIPTION_FONT_SIZE = 15,
        EXTRA_DESCRIPTION_FONT_SIZE = 11,
        VALUE_FONT_SIZE = 14,

        MODULE_TOP_SPACING = 40,
        MODULE_BOTTOM_SPACING = 40,
        HEADER_TOP_SPACING = 40,
        HEADER_BOTTOM_SPACING = 25,
        CHECKBOX_TOP_SPACING = 25,
        CHECKBOX_ROW_SPACING = 25,
        SLIDER_TOP_SPACING = 25,
        SLIDER_ROW_SPACING = 25,
        DROPDOWN_TOP_SPACING = 17,
        DROPDOWN_ROW_SPACING = 25,
        COLOUR_TOP_SPACING = 25,
        COLOUR_ROW_SPACING = 25,
        MODULE_SPACING = 25,
                --             [1] = "Home",
                --             [2] = "Info",
                --             [3] = "Profiles",
                --             [4] = "Modules",
                --             [5] = "ShaguTweaks",

                --             [6] = "Actionbars",
                --             [7] = "Bags",
                --             [8] = "Castbar",
                --             [9] = "Chat",
                --             [10] = "Interface",
                --             [11] = "Micromenu",
                --             [12] = "Minimap",
                --             [13] = "Tooltip",
                --             [14] = "Unitframes",
                --             [15] = "Xprep",
        moduleMapping = {
            ["Bars"]    = {7, 1},
            ["RangeIndicator"]    = {7, 2},
            ["Cooldowns"] = {7, 3},
            ["Orbs"]    = {7, 4},
            ["Bags"]    = {8, 1},
            ["Cast"]    = {9, 1},
            ["Chat"]    = {10, 1},
            ["GUI-Dragonflight"]   = {11, 1},
            ["Errors"]      = {11, 2},
            ["Tooltip"]      = {11, 3},
            ["Ui"]      = {11, 4},
            ["ItemCompare"] = {11, 5},
            ["Character"] = {11, 6},
            ["Bank"]    = {11, 7},
            ["Merchant"] = {11, 8},
            ["QuestDialog"] = {11, 9},
            ["Gossip"]  = {11, 10},
            ["QuestLog"] = {11, 11},
            ["Social"]  = {11, 12},
            ["Mail"]    = {11, 13},
            ["Trade"]   = {11, 14},
            ["Trainer"] = {11, 15},
            ["DressUp"] = {11, 16},
            ["Help"]    = {11, 17},
            ["Scrollbar"] = {11, 18},
            ["OpenMail"] = {11, 19},
            ["Inspect"] = {11, 20},
            ["Macros"] = {11, 21},
            ["SpellBook"] = {11, 22},
            ["KeyBinding"] = {11, 23},
            ["TradeSkill"] = {11, 24},
            ["Micro"]   = {12, 1},
            ["Collector"] = {13, 1},
            ["Map"]     = {13, 2},
            ["Player"]  = {14, 1},
            ["PVPIcon"]  = {14, 2},
            ["Target"]  = {14, 3},
            ["Mini"]    = {14, 4},
            ["Colors"]  = {14, 5},
            ["Auras"]   = {14, 6},
            ["Xprep"]   = {15, 1},
        },

        -- 分类显示位置覆盖：将某模块的特定分类渲染到另一个模块的 tab 位置
        -- 格式: ["源模块名.分类名"] = {"目标模块名", 显示顺序}
        categoryOverride = {
            ["Auras.玩家"]  = {"Player", 6},
            ["Auras.目标"]  = {"Target", 6},
            ["Auras.宠物"]  = {"Mini", 6},
            ["Auras.队伍"]  = {"Mini", 7},
        },
    }

    function Setup:MetaData()

        for moduleName, defaults in pairs(DFUI.defaults) do
            for elementName, valueTable in pairs(defaults) do
                if elementName ~= "enabled" and table.getn(valueTable) > 1 then

                    local typeMeta = valueTable[3]
                    if valueTable[2] == "slider" and type(typeMeta) == "table" then
                        typeMeta = {
                            min = typeMeta[1],
                            max = typeMeta[2],
                            step = typeMeta[3]
                        }
                    elseif valueTable[2] == "dropdown" and type(typeMeta) == "table" then
                        typeMeta = {
                            items = typeMeta
                        }
                    end

                    self.metadata[moduleName .. "." .. elementName] = {
                        elementType = valueTable[2],
                        elementTypeMeta = typeMeta,
                        dependency = valueTable[4],
                        category = valueTable[5],
                        categoryIndex = valueTable[6],
                        description = valueTable[7],
                        extraDescription = valueTable[8],
                        status = valueTable[9]
                    }
                end
            end
        end

        local count = 0
        for _ in pairs(self.metadata) do
            count = count + 1
        end


    end

    function Setup:Elements()

        -- group elements by module and category
        local moduleElements = {}
        local moduleCategories = {}

        -- process each module directly from dfui.defaults
        for moduleName, defaults in pairs(DFUI.defaults) do
            if self.moduleMapping[moduleName] then
                local enabledValue = DFUI.tempDB[moduleName] and DFUI.tempDB[moduleName].enabled
                if enabledValue == true then
                local tabIndex = self.moduleMapping[moduleName][1]

                if not moduleElements[moduleName] then
                    moduleElements[moduleName] = {}
                    moduleCategories[moduleName] = {}
                end

                for elementName, valueTable in pairs(defaults) do
                    if elementName ~= "enabled" and table.getn(valueTable) > 1 then
                        local metaKey = moduleName .. "." .. elementName
                        local data = self.metadata[metaKey]

                        if data then
                            -- 检查分类覆盖：是否需要将此分类渲染到其他模块下
                            local overrideKey = moduleName .. "." .. (data.category or "default")
                            local override = self.categoryOverride and self.categoryOverride[overrideKey]

                            local renderModule = moduleName
                            local renderTab = tabIndex
                            local renderCatIndex = data.categoryIndex or 1

                            if override then
                                renderModule = override[1]
                                renderCatIndex = override[2]
                                if self.moduleMapping[renderModule] then
                                    renderTab = self.moduleMapping[renderModule][1]
                                end
                                -- 确保目标模块的容器存在
                                if not moduleElements[renderModule] then
                                    moduleElements[renderModule] = {}
                                    moduleCategories[renderModule] = {}
                                end
                            end

                            if data.category then
                                local categoryKey = renderTab .. "_" .. renderModule .. "_" .. data.category
                                if not moduleCategories[renderModule][categoryKey] then
                                    moduleCategories[renderModule][categoryKey] = {
                                        category = data.category,
                                        tabIndex = renderTab,
                                        categoryIndex = renderCatIndex
                                    }
                                end
                            end

                            if data.elementType == "checkbox" or data.elementType == "slider" or data.elementType == "dropdown" or data.elementType == "colour" then
                                local categoryKey = renderTab .. "_" .. renderModule .. "_" .. (data.category or "default")

                                if not moduleElements[renderModule][categoryKey] then
                                    moduleElements[renderModule][categoryKey] = {}
                                end

                                table.insert(moduleElements[renderModule][categoryKey], {
                                    name = elementName,
                                    data = data,
                                    module = moduleName,
                                    tabIndex = renderTab
                                })
                            end
                        end
                    end
                end
                end
            end
        end

        -- create sorted list of modules by their order
        local sortedModules = {}
        for moduleName, moduleData in pairs(self.moduleMapping) do
            if moduleElements[moduleName] then
                table.insert(sortedModules, {
                    name = moduleName,
                    order = moduleData[2] -- second value is the order
                })
            end
        end
        table.sort(sortedModules, function(a, b)
            return a.order < b.order
        end)

        -- module display names for tab 14 (unit frames) module headers
        local moduleDisplayNames = {
            ["Player"]  = "玩家框架",
            ["PVPIcon"] = "PVP图标",
            ["Target"]  = "目标框架",
            ["Mini"]    = "小型框架",
            ["Colors"]  = "配色设置",
            ["Auras"]   = "光环设置",
            ["Bars"]    = "动作条",
            ["RangeIndicator"] = "距离指示器",
            ["Cooldowns"] = "冷却数字",
            ["Orbs"]    = "血球/蓝球",
        }

        -- card panel constants (matching superwow.lua / mods.lua style)
        local PANEL_WIDTH = 800
        local PANEL_INSET = 15
        local PANEL_GAP = 12
        local HEADER_AREA = 50   -- title(10) + desc(28) + sep(44) + pad to 50
        local ITEM_SPACING = 50  -- per element row
        local PANEL_PAD = 15     -- bottom padding

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
            bg:SetBackdropColor(0.05, 0.04, 0.02, 0.7)
            bg:SetBackdropBorderColor(0.30, 0.25, 0.15, 0.4)
            return bg
        end

        local function AddPanelHeader(catPanel, title, desc)
            local titleFont = catPanel:CreateFontString(nil, "OVERLAY")
            titleFont:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(16), "OUTLINE")
            titleFont:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -10)
            titleFont:SetText(title)
            titleFont:SetTextColor(1, 0.82, 0)

            if desc then
                local descFont = catPanel:CreateFontString(nil, "OVERLAY")
                descFont:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(11), "OUTLINE")
                descFont:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET + 1, -28)
                descFont:SetText(desc)
                descFont:SetTextColor(0.54, 0.48, 0.35)
            end

            local sep = catPanel:CreateTexture(nil, "ARTWORK")
            sep:SetTexture("Interface\\Buttons\\WHITE8X8")
            sep:SetHeight(1)
            sep:SetWidth(PANEL_WIDTH - 30)
            sep:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -44)
            sep:SetVertexColor(0.48, 0.33, 0.09, 0.25)
        end

        -- Dependency state helper (shared by all element types)
        local function ApplyDependencyState(element, descLabel, extraDescLabel, dependencyEnabled, elementType)
            if not dependencyEnabled then
                if elementType == "checkbox" then
                    if element and element.Disable then element:Disable() end
                    if element and element.label then element.label:SetTextColor(0.5, 0.5, 0.5) end
                elseif elementType == "slider" or elementType == "colour" then
                    if element and element.Disable then
                        element:Disable()
                    elseif element then
                        element.isDisabled = true
                        element:EnableMouse(false)
                        element:SetBackdropColor(0.5, 0.5, 0.5, 1)
                        element:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                        local t = element:GetThumbTexture()
                        if t then t:SetVertexColor(0.5, 0.5, 0.5) end
                    end
                    if element and element.label then element.label:SetTextColor(0.5, 0.5, 0.5) end
                    if element and element.valueText then element.valueText:SetTextColor(0.5, 0.5, 0.5) end
                elseif elementType == "dropdown" then
                    if element and element.Disable then element:Disable() end
                    if element and element.text then element.text:SetTextColor(0.5, 0.5, 0.5) end
                end
                if descLabel then descLabel:SetTextColor(0.5, 0.5, 0.5) end
                if extraDescLabel then extraDescLabel:SetTextColor(0.5, 0.5, 0.5) end
            else
                if elementType == "checkbox" then
                    if element and element.Enable then element:Enable() end
                    if element and element.label then element.label:SetTextColor(1, 1, 1) end
                elseif elementType == "slider" or elementType == "colour" then
                    if element and element.Enable then
                        element:Enable()
                    elseif element then
                        element.isDisabled = false
                        element:EnableMouse(true)
                        element:SetBackdropColor(1, 1, 1, 1)
                        element:SetBackdropBorderColor(1, 1, 1, 1)
                        local t = element:GetThumbTexture()
                        if t then t:SetVertexColor(1, 1, 1) end
                    end
                    if element and element.label then element.label:SetTextColor(1, 1, 1) end
                    if element and element.valueText then element.valueText:SetTextColor(1, 1, 1) end
                elseif elementType == "dropdown" then
                    if element and element.Enable then element:Enable() end
                    if element and element.text then element.text:SetTextColor(1, 1, 1) end
                end
                if descLabel then descLabel:SetTextColor(.9, .9, .9) end
                if extraDescLabel then extraDescLabel:SetTextColor(1, 0.5, 0.5) end
            end
        end

        -- process each module in order
        for _, moduleInfo in ipairs(sortedModules) do
            local moduleName = moduleInfo.name
            local tabIndex = self.moduleMapping[moduleName][1]
            local scrollChild = Base.scrollChildren[tabIndex]

            if not self.tabPositions[tabIndex] then
                self.tabPositions[tabIndex] = -10
            end

            local sortedCategories = {}
            for categoryKey, categoryData in pairs(moduleCategories[moduleName] or {}) do
                table.insert(sortedCategories, {key = categoryKey, data = categoryData})
            end
            table.sort(sortedCategories, function(a, b)
                local aIndex = tonumber(a.data.categoryIndex) or 999
                local bIndex = tonumber(b.data.categoryIndex) or 999
                return aIndex < bIndex
            end)

            for _, categoryInfo in ipairs(sortedCategories) do
                local categoryKey = categoryInfo.key
                local categoryData = categoryInfo.data

                local elements = moduleElements[moduleName][categoryKey] or {}
                table.sort(elements, function(a, b)
                    local aIndex = tonumber(a.data.categoryIndex) or 999
                    local bIndex = tonumber(b.data.categoryIndex) or 999
                    return aIndex < bIndex
                end)

                local elemCount = table.getn(elements)
                if elemCount == 0 then
                    -- skip empty categories
                else
                    -- calculate panel height
                    local panelHeight = HEADER_AREA + elemCount * ITEM_SPACING + PANEL_PAD

                    -- create card panel
                    local yPos = self.tabPositions[tabIndex]

                    if not self.headers[categoryKey] then
                        local displayName = moduleDisplayNames[moduleName] or moduleName
                        local catTitle = categoryData.category or ""
                        -- For multi-module tabs, prepend module name
                        local panelTitle = catTitle
                        if (tabIndex == 7 or tabIndex == 14) then
                            local modDisplay = moduleDisplayNames[moduleName]
                            if modDisplay and catTitle ~= "" then
                                panelTitle = modDisplay .. " - " .. catTitle
                            elseif modDisplay then
                                panelTitle = modDisplay
                            end
                        end

                        local catPanel = CreateCategoryPanel(scrollChild, PANEL_WIDTH, panelHeight)
                        catPanel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 25, yPos)

                        AddPanelHeader(catPanel, panelTitle, nil)

                        self.headers[categoryKey] = catPanel

                        -- render elements inside panel
                        local innerY = HEADER_AREA
                        for _, element in ipairs(elements) do
                            local elementName = element.name
                            local data = element.data
                            local elementModule = element.module

                            local currentValue = self:GetCache(elementModule, elementName)
                            local dependencyEnabled = true
                            if data.dependency then
                                local depValue = self:GetCache(elementModule, data.dependency)
                                dependencyEnabled = depValue == true
                            end

                            if data.elementType == "checkbox" then
                                local elementKey = elementModule .. "." .. elementName
                                if not self.checkboxes[elementKey] then
                                    local descLabel = catPanel:CreateFontString(nil, "BACKGROUND")
                                    descLabel:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.DESCRIPTION_FONT_SIZE), "OUTLINE")
                                    descLabel:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -innerY - 5)
                                    descLabel:SetText(data.description or "")
                                    descLabel:SetTextColor(.9,.9,.9)

                                    if data.extraDescription then
                                        local extraDescLabel = catPanel:CreateFontString(nil, "BACKGROUND")
                                        extraDescLabel:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.EXTRA_DESCRIPTION_FONT_SIZE), "OUTLINE")
                                        extraDescLabel:SetPoint("LEFT", descLabel, "RIGHT", 10, 0)
                                        extraDescLabel:SetText(data.extraDescription)
                                        extraDescLabel:SetTextColor(1, 0.5, 0.5)
                                        self.extraDescriptionLabels[elementKey] = extraDescLabel
                                    end

                                    local checkbox = DFUI.tools.CreateCheckbox(catPanel, nil, elementModule, elementName)
                                    checkbox:SetPoint("TOPRIGHT", catPanel, "TOPRIGHT", -166, -innerY)
                                    checkbox:SetChecked(currentValue)
                                    if checkbox.label then
                                        checkbox.label:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.VALUE_FONT_SIZE), "OUTLINE")
                                    end

                                    self.checkboxes[elementKey] = checkbox
                                    self.descriptionLabels[elementKey] = descLabel
                                end
                                ApplyDependencyState(self.checkboxes[elementModule .. "." .. elementName], self.descriptionLabels[elementModule .. "." .. elementName], self.extraDescriptionLabels[elementModule .. "." .. elementName], dependencyEnabled, "checkbox")

                            elseif data.elementType == "slider" then
                                local elementKey = elementModule .. "." .. elementName
                                if not self.sliders[elementKey] then
                                    local descLabel = catPanel:CreateFontString(nil, "BACKGROUND")
                                    descLabel:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.DESCRIPTION_FONT_SIZE), "OUTLINE")
                                    descLabel:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -innerY - 5)
                                    descLabel:SetText(data.description or "")
                                    descLabel:SetTextColor(.9,.9,.9)

                                    if data.extraDescription then
                                        local extraDescLabel = catPanel:CreateFontString(nil, "BACKGROUND")
                                        extraDescLabel:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.EXTRA_DESCRIPTION_FONT_SIZE), "OUTLINE")
                                        extraDescLabel:SetPoint("LEFT", descLabel, "RIGHT", 10, 0)
                                        extraDescLabel:SetText(data.extraDescription)
                                        extraDescLabel:SetTextColor(1, 0.5, 0.5)
                                        self.extraDescriptionLabels[elementKey] = extraDescLabel
                                    end

                                    local typeMeta = data.elementTypeMeta
                                    local slider = DFUI.tools.CreateSlider(catPanel, nil, elementModule, elementName, typeMeta.min, typeMeta.max, typeMeta.step)
                                    slider:SetPoint("TOPRIGHT", catPanel, "TOPRIGHT", -50, -innerY)
                                    slider:SetValue(currentValue)
                                    if slider.label then
                                        slider.label:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.VALUE_FONT_SIZE), "OUTLINE")
                                    end

                                    self.sliders[elementKey] = slider
                                    self.descriptionLabels[elementKey] = descLabel
                                end
                                ApplyDependencyState(self.sliders[elementModule .. "." .. elementName], self.descriptionLabels[elementModule .. "." .. elementName], self.extraDescriptionLabels[elementModule .. "." .. elementName], dependencyEnabled, "slider")

                            elseif data.elementType == "dropdown" then
                                local elementKey = elementModule .. "." .. elementName
                                if not self.dropdowns[elementKey] then
                                    local descLabel = catPanel:CreateFontString(nil, "BACKGROUND")
                                    descLabel:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.DESCRIPTION_FONT_SIZE), "OUTLINE")
                                    descLabel:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -innerY - 5)
                                    descLabel:SetText(data.description or "")
                                    descLabel:SetTextColor(.9,.9,.9)

                                    if data.extraDescription then
                                        local extraDescLabel = catPanel:CreateFontString(nil, "BACKGROUND")
                                        extraDescLabel:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.EXTRA_DESCRIPTION_FONT_SIZE), "OUTLINE")
                                        extraDescLabel:SetPoint("LEFT", descLabel, "RIGHT", 10, 0)
                                        extraDescLabel:SetText(data.extraDescription)
                                        extraDescLabel:SetTextColor(1, 0.5, 0.5)
                                        self.extraDescriptionLabels[elementKey] = extraDescLabel
                                    end

                                    local typeMeta = data.elementTypeMeta
                                    local dropdown = DFUI.tools.CreateDropDown(catPanel, nil, elementModule, elementName, typeMeta.items)
                                    dropdown:SetPoint("TOPRIGHT", catPanel, "TOPRIGHT", -50, -innerY)
                                    if dropdown.text then
                                        dropdown.text:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.VALUE_FONT_SIZE), "OUTLINE")
                                    end

                                    self.dropdowns[elementKey] = dropdown
                                    self.descriptionLabels[elementKey] = descLabel
                                end
                                ApplyDependencyState(self.dropdowns[elementModule .. "." .. elementName], self.descriptionLabels[elementModule .. "." .. elementName], self.extraDescriptionLabels[elementModule .. "." .. elementName], dependencyEnabled, "dropdown")

                            elseif data.elementType == "colour" then
                                local elementKey = elementModule .. "." .. elementName
                                if not self.colours[elementKey] then
                                    local descLabel = catPanel:CreateFontString(nil, "BACKGROUND")
                                    descLabel:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.DESCRIPTION_FONT_SIZE), "OUTLINE")
                                    descLabel:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -innerY - 5)
                                    descLabel:SetText(data.description or "")
                                    descLabel:SetTextColor(.9,.9,.9)

                                    if data.extraDescription then
                                        local extraDescLabel = catPanel:CreateFontString(nil, "BACKGROUND")
                                        extraDescLabel:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.EXTRA_DESCRIPTION_FONT_SIZE), "OUTLINE")
                                        extraDescLabel:SetPoint("LEFT", descLabel, "RIGHT", 10, 0)
                                        extraDescLabel:SetText(data.extraDescription)
                                        extraDescLabel:SetTextColor(1, 0.5, 0.5)
                                        self.extraDescriptionLabels[elementKey] = extraDescLabel
                                    end

                                    local colour = DFUI.tools.CreateColour(catPanel, nil, elementModule, elementName)
                                    colour:SetPoint("TOPRIGHT", catPanel, "TOPRIGHT", -50, -innerY)
                                    if colour.label then
                                        colour.label:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.VALUE_FONT_SIZE), "OUTLINE")
                                    end

                                    self.colours[elementKey] = colour
                                    self.descriptionLabels[elementKey] = descLabel
                                end
                                ApplyDependencyState(self.colours[elementModule .. "." .. elementName], self.descriptionLabels[elementModule .. "." .. elementName], self.extraDescriptionLabels[elementModule .. "." .. elementName], dependencyEnabled, "colour")
                            end

                            innerY = innerY + ITEM_SPACING
                        end
                    end

                    self.tabPositions[tabIndex] = yPos - panelHeight - PANEL_GAP
                end
            end
        end

        -- dynamically adjust scrollChild heights based on actual content
        for tabIndex, yOffset in pairs(self.tabPositions) do
            local scrollChild = Base.scrollChildren[tabIndex]
            if scrollChild then
                local neededHeight = math.abs(yOffset) + 50
                if neededHeight > scrollChild:GetHeight() then
                    scrollChild:SetHeight(neededHeight)
                end
            end
        end

    end

    function Setup:DependencyHandler()

        if not self.dependenciesSetup then
            for moduleName, defaults in pairs(DFUI.defaults) do
                if self.moduleMapping[moduleName] then
                    for elementName, valueTable in pairs(defaults) do
                        if elementName ~= "enabled" and table.getn(valueTable) > 1 then
                            local metaKey = moduleName .. "." .. elementName
                            local data = self.metadata[metaKey]

                            if data and data.dependency then

                                local elementKey = moduleName .. "." .. elementName
                                local depKey = moduleName .. "." .. data.dependency
                                local dep = self.checkboxes[elementKey] or self.sliders[elementKey] or self.dropdowns[elementKey] or self.colours[elementKey]
                                local ctrl = self.checkboxes[depKey] or self.sliders[depKey] or self.dropdowns[depKey] or self.colours[depKey]

                                if ctrl and dep then

                                    local click = ctrl:GetScript("OnClick")
                                    local capDep = dep
                                    local capCtrl = ctrl
                                    local capMod = moduleName
                                    local capName = elementName
                                    local capCtrlName = data.dependency
                                    local capDesc = self.descriptionLabels[elementKey]
                                    local capExtraDesc = self.extraDescriptionLabels[elementKey]

                                    capCtrl:SetScript("OnClick", function()

                                if click then
                                    click()
                                end

                                local enabled = capCtrl:GetChecked()

                                if not enabled then
                                    if capDep.SetChecked then
                                        capDep.originalChecked = capDep:GetChecked()
                                        capDep:SetChecked(false)
                                        DFUI:SetTempDB(capMod, capName, false)
                                    elseif capDep.SetValue and not self.colours[capMod .. "." .. capName] then
                                        local def = DFUI.defaults[capMod][capName][1]
                                        capDep:SetValue(def)
                                        DFUI:SetTempDB(capMod, capName, def)
                                    elseif capDep.text then
                                        local def = DFUI.defaults[capMod][capName][1]
                                        capDep.text:SetText(def)
                                        DFUI:SetTempDB(capMod, capName, def)
                                    elseif self.colours[capMod .. "." .. capName] then
                                        local def = DFUI.defaults[capMod][capName][1]
                                        capDep:SetValue(1)
                                        DFUI:SetTempDB(capMod, capName, def)
                                    end
                                    if capDep.Disable then
                                        capDep:Disable()
                                    elseif capDep.SetScript then
                                        capDep.isDisabled = true
                                        capDep:EnableMouse(false)
                                        capDep.originalMouseWheel = capDep:GetScript("OnMouseWheel")
                                        capDep:SetScript("OnMouseWheel", nil)
                                        if capDep.valueText then
                                            capDep.valueText:SetTextColor(0.5, 0.5, 0.5)
                                        end
                                        capDep:SetBackdropColor(0.5, 0.5, 0.5, 1)
                                        capDep:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                                        local thumb = capDep:GetThumbTexture()
                                        if thumb then
                                            thumb:SetVertexColor(0.5, 0.5, 0.5)
                                        end
                                    end
                                    if capDep.label then
                                        capDep.label:SetTextColor(0.5, 0.5, 0.5)
                                    end
                                    if capDep.text then
                                        capDep.text:SetTextColor(0.5, 0.5, 0.5)
                                    end
                                    if capDesc then
                                        capDesc:SetTextColor(0.5, 0.5, 0.5)
                                    end
                                    if capExtraDesc then
                                        capExtraDesc:SetTextColor(0.5, 0.5, 0.5)
                                    end
                                else
                                    if capDep.Enable then
                                        capDep:Enable()
                                        if capDep.SetChecked and capDep.originalChecked then
                                            capDep:SetChecked(capDep.originalChecked)
                                            DFUI:SetTempDB(capMod, capName, capDep.originalChecked)
                                        end
                                    elseif capDep.SetScript then
                                        capDep.isDisabled = false
                                        capDep:EnableMouse(true)
                                        if capDep.originalMouseWheel then
                                            capDep:SetScript("OnMouseWheel", capDep.originalMouseWheel)
                                        end
                                        if capDep.valueText then
                                            capDep.valueText:SetTextColor(1, 1, 1)
                                        end
                                        capDep:SetBackdropColor(1, 1, 1, 1)
                                        capDep:SetBackdropBorderColor(1, 1, 1, 1)
                                        local thumb = capDep:GetThumbTexture()
                                        if thumb then
                                            thumb:SetVertexColor(1, 1, 1)
                                        end
                                    end
                                    if capDep.label then
                                        capDep.label:SetTextColor(.9,.9,.9)
                                    end
                                    if capDep.text then
                                        capDep.text:SetTextColor(1, 1, 1)
                                    end
                                    if capDesc then
                                        capDesc:SetTextColor(.9,.9,.9)
                                    end
                                    if capExtraDesc then
                                        capExtraDesc:SetTextColor(1, 0.5, 0.5)
                                    end
                                end
                            end)
                                end
                            end
                        end
                    end
                end
            end
            self.dependenciesSetup = true
        end
    end

    function Setup:UpdateHandler()
        self.configCache = {}

        local all = {}
        for name, element in pairs(self.checkboxes) do
            all[name] = {element = element, type = "checkbox"}
        end
        for name, element in pairs(self.sliders) do
            all[name] = {element = element, type = "slider"}
        end
        for name, element in pairs(self.dropdowns) do
            all[name] = {element = element, type = "dropdown"}
        end
        for name, element in pairs(self.colours) do
            all[name] = {element = element, type = "colour"}
        end

        for elementKey, data in pairs(all) do
            local element = data.element

            local module = nil
            local name = nil
            for mod, _ in pairs(self.moduleMapping) do
                local modPrefix = mod .. "."
                if string.sub(elementKey, 1, string.len(modPrefix)) == modPrefix then
                    module = mod
                    name = string.sub(elementKey, string.len(modPrefix) + 1)
                    break
                end
            end

            if module and name then
                local metaKey = module .. "." .. name
                local meta = self.metadata[metaKey]
                local value = self:GetCache(module, name)

                if data.type == "checkbox" then
                    element:SetChecked(value)
                elseif data.type == "slider" then
                    element:SetValue(value)
                elseif data.type == "dropdown" then
                    if element.text then element.text:SetText(value) end
                elseif data.type == "colour" then
                    if type(value) == "table" and table.getn(value) >= 3 then
                        for i = 1, 30 do
                            local color = element.BASIC_COLORS and element.BASIC_COLORS[i]
                            if color and color[1] == value[1] and color[2] == value[2] and color[3] == value[3] then
                                element:SetValue(i)
                                break
                            end
                        end
                    end
                end

                local enabled = true
                if meta and meta.dependency then
                    enabled = self:GetCache(module, meta.dependency) == true
                end

                local r, g, b = enabled and .9 or 0.5, enabled and .9 or 0.5, enabled and .9 or 0.5

                if element.label then
                    element.label:SetTextColor(r, g, b)
                end
                if element.valueText then
                    element.valueText:SetTextColor(enabled and 1 or 0.5, enabled and 1 or 0.5, enabled and 1 or 0.5)
                end
                if element.text then
                    element.text:SetTextColor(enabled and 1 or 0.5, enabled and 1 or 0.5, enabled and 1 or 0.5)
                end
                if self.descriptionLabels[elementKey] then
                    self.descriptionLabels[elementKey]:SetTextColor(r, g, b)
                end
                if self.extraDescriptionLabels[elementKey] then
                    self.extraDescriptionLabels[elementKey]:SetTextColor(enabled and 1 or 0.5, enabled and 0.5 or 0.5, enabled and 0.5 or 0.5)
                end

                if enabled then
                    if element.Enable then
                        element:Enable()
                    else
                        element.isDisabled = false
                        element:EnableMouse(true)
                        element:SetBackdropColor(1, 1, 1, 1)
                        element:SetBackdropBorderColor(1, 1, 1, 1)
                        local t = element:GetThumbTexture()
                        if t then t:SetVertexColor(1, 1, 1) end
                    end
                else
                    if element.Disable then
                        element:Disable()
                    else
                        element.isDisabled = true
                        element:EnableMouse(false)
                        element:SetBackdropColor(0.5, 0.5, 0.5, 1)
                        element:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                        local t = element:GetThumbTexture()
                        if t then t:SetVertexColor(0.5, 0.5, 0.5) end
                    end
                end

            end
        end

        DFUI:TriggerAllCallbacks()
    end

    function Setup:GetCache(moduleName, key)
        local cacheKey = moduleName .. "." .. key
        if self.configCache[cacheKey] == nil then
            if DFUI.tempDB[moduleName] and DFUI.tempDB[moduleName][key] ~= nil then
                self.configCache[cacheKey] = DFUI:GetTempDB(moduleName, key)
            else
                return nil
            end
        end
        return self.configCache[cacheKey]
    end

    Base.UpdateHandler = function()
        Setup:UpdateHandler()
    end

    --=================
    -- INIT THE BEAST
    --=================
    function Setup:Run()
        Setup:MetaData()
        Setup:Elements()
        Setup:DependencyHandler()
    end

    Setup:Run()

    --=================
    -- CALLBACKS
    --=================
end)
