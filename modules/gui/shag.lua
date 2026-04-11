DFUI:NewDefaults("Gui-shag", {
    enabled = {true},

})

DFUI:NewMod("Gui-shag", 3, function()
    local Base = DFUI.gui.Base
    local panel = Base.scrollChildren[5]
    local Setup = {
        font = DFUI:GetInfoOrCons("font"),

        metadata = {},
        checkboxes = {},
        descriptionLabels = {},
        headers = {},

        DESCRIPTION_FONT_SIZE = 15,
        HEADER_TOP_SPACING = 40,
        HEADER_BOTTOM_SPACING = 25,
        CHECKBOX_ROW_SPACING = 45,
        MODULE_SPACING = 25,
    }

    local f = CreateFrame("Frame")
    f:RegisterEvent("VARIABLES_LOADED")
    f:SetScript("OnEvent", function()
        if DFUI.gui.shaguCore == true or DFUI.gui.shaguExtras == true then
            Setup:MetaData()
            Setup:Elements()
        else
            local waitFrame = CreateFrame("Frame")
            waitFrame.elapsed = 0
            waitFrame:SetScript("OnUpdate", function()
                this.elapsed = this.elapsed + arg1
                if (DFUI.gui.shaguCore == true or DFUI.gui.shaguExtras == true) or this.elapsed > 3 then
                    this:SetScript("OnUpdate", nil)
                    if DFUI.gui.shaguCore == true or DFUI.gui.shaguExtras == true then
                        Setup:MetaData()
                        Setup:Elements()
                    end
                end
            end)
        end
    end)

    function Setup:MetaData()
        if DFUI.gui.shaguCoreData then
            for elementName, valueTable in pairs(DFUI.gui.shaguCoreData) do

                self.metadata[elementName] = {
                    elementType = valueTable[2],
                    elementTypeMeta = valueTable[3],
                    category = valueTable[5],
                    categoryIndex = valueTable[6],
                    description = valueTable[7],
                    extraDescription = valueTable[8],
                    module = "core"
                }
            end
        end

        if DFUI.gui.shaguExtrasData then
            for elementName, valueTable in pairs(DFUI.gui.shaguExtrasData) do

                self.metadata[elementName] = {
                    elementType = valueTable[2],
                    elementTypeMeta = valueTable[3],
                    category = valueTable[5],
                    categoryIndex = valueTable[6],
                    description = valueTable[7],
                    extraDescription = valueTable[8],
                    module = "extras"
                }
            end
        end

        local count = 0
        for _ in pairs(self.metadata) do
            count = count + 1
        end


    end

    function Setup:Elements()

        local PANEL_WIDTH = 680
        local PANEL_INSET = 15
        local PANEL_GAP = 12
        local HEADER_AREA = 50
        local ITEM_SPACING = 45
        local PANEL_PAD = 15

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

        local groups = {}

        for key, data in pairs(self.metadata) do
            local module = data.module or "other"
            local cat = data.category or "Other"

            if not groups[module] then groups[module] = {} end
            if not groups[module][cat] then groups[module][cat] = {} end

            table.insert(groups[module][cat], {key = key, data = data})
        end

        local yPos = 65

        local moduleOrder = {"core", "extras"}

        for _, module in ipairs(moduleOrder) do
            if groups[module] then

                local moduleTitle = module == "core" and "ShaguTweaks" or "ShaguTweaks Extras"
                local moduleHeader = panel:CreateFontString(nil, "OVERLAY")
                moduleHeader:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(22), "OUTLINE")
                moduleHeader:SetPoint("TOP", panel, "TOP", 0, -yPos)
                moduleHeader:SetText(moduleTitle)
                moduleHeader:SetTextColor(1, 0.82, 0)
                yPos = yPos + 30

                T.GradientLine(panel, "TOP", -yPos, 1, 500)
                yPos = yPos + 12

                local categoryNames = {}
                for categoryName in pairs(groups[module]) do
                    table.insert(categoryNames, categoryName)
                end
                table.sort(categoryNames)

                for _, category in ipairs(categoryNames) do
                    local elements = groups[module][category]

                    table.sort(elements, function(a, b)
                        return (a.data.categoryIndex or 999) < (b.data.categoryIndex or 999)
                    end)

                    local elemCount = table.getn(elements)
                    local panelHeight = HEADER_AREA + elemCount * ITEM_SPACING + PANEL_PAD

                    local catPanel = CreateCategoryPanel(panel, PANEL_WIDTH, panelHeight)
                    catPanel:SetPoint("TOP", panel, "TOP", 0, -yPos)

                    -- panel header
                    local catTitle = catPanel:CreateFontString(nil, "OVERLAY")
                    catTitle:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(16), "OUTLINE")
                    catTitle:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -10)
                    catTitle:SetText(category)
                    catTitle:SetTextColor(1, 0.82, 0)

                    local countFont = catPanel:CreateFontString(nil, "OVERLAY")
                    countFont:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(11), "OUTLINE")
                    countFont:SetPoint("LEFT", catTitle, "RIGHT", 8, 0)
                    countFont:SetText("(" .. elemCount .. ")")
                    countFont:SetTextColor(0.54, 0.48, 0.35)

                    local sep = catPanel:CreateTexture(nil, "ARTWORK")
                    sep:SetTexture("Interface\\Buttons\\WHITE8X8")
                    sep:SetHeight(1)
                    sep:SetWidth(PANEL_WIDTH - 30)
                    sep:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -32)
                    sep:SetVertexColor(0.48, 0.33, 0.09, 0.25)

                    self.headers[category] = catPanel

                    -- render elements inside panel
                    local innerY = HEADER_AREA - 10
                    for i, element in ipairs(elements) do
                        local desc = catPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        desc:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.DESCRIPTION_FONT_SIZE), "OUTLINE")
                        desc:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -innerY)
                        desc:SetText(element.data.description or element.key)
                        desc:SetTextColor(.9, .9, .9)
                        self.descriptionLabels[element.key] = desc

                        local cb = DFUI.tools.CreateShaguCheckbox(catPanel, "DFUI_Shagu_" .. element.key, element.key)
                        cb:SetPoint("TOPRIGHT", catPanel, "TOPRIGHT", -100, -innerY)
                        self.checkboxes[element.key] = cb

                        innerY = innerY + ITEM_SPACING
                    end

                    yPos = yPos + panelHeight + PANEL_GAP
                end
            elseif module == "extras" and not DFUI.gui.shaguExtrasData then
                local txt = panel:CreateFontString(nil, "OVERLAY")
                txt:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(30), "OUTLINE")
                txt:SetPoint("TOP", panel, "TOP", 10, -yPos-50)
                txt:SetText("缺少SHAGU TWEAKS EXTRAS\n安装以获取更多选项")
                txt:SetTextColor(1, 0.5, 0.5)
                local f3 = CreateFrame("Frame")
                f3.t = 0
                f3:SetScript("OnUpdate", function()
                    this.t = this.t + arg1
                    if this.t >= 0.5 then
                        txt:SetAlpha(txt:GetAlpha() > 0.5 and 0.3 or 1)
                        this.t = 0
                    end
                end)
            end
        end
    end
end)