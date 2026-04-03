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

        for _, module in pairs(moduleOrder) do
            if groups[module] then

                local moduleTitle = module == "core" and "ShaguTweaks" or "ShaguTweaks Extras"
                local moduleHeader = DFUI.tools.CreateCategoryHeader(panel, moduleTitle, nil, 300, 50, 30)
                moduleHeader:SetPoint("TOP", panel, "TOP", -200, -yPos)
                yPos = yPos + self.HEADER_TOP_SPACING + self.HEADER_BOTTOM_SPACING

                local categoryNames = {}
                for categoryName in pairs(groups[module]) do
                    table.insert(categoryNames, categoryName)
                end
                table.sort(categoryNames)

                for _, category in pairs(categoryNames) do
                    local elements = groups[module][category]

                table.sort(elements, function(a, b)
                    return (a.data.categoryIndex or 999) < (b.data.categoryIndex or 999)
                end)
                local header = DFUI.tools.CreateCategoryHeader(panel, category)
                header:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -yPos)
                self.headers[category] = header
                yPos = yPos + self.HEADER_TOP_SPACING + self.HEADER_BOTTOM_SPACING

                for i, element in pairs(elements) do

                    -- create description label on left
                    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    desc:SetFont(self.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(self.DESCRIPTION_FONT_SIZE), "OUTLINE")
                    desc:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -yPos)
                    desc:SetText(element.data.description or element.key)
                    desc:SetTextColor(.9, .9, .9)
                    self.descriptionLabels[element.key] = desc

                    -- create checkbox on right
                    local cb = DFUI.tools.CreateShaguCheckbox(panel, "DFUI_Shagu_" .. element.key, element.key)
                    cb:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -150, -yPos)
                    self.checkboxes[element.key] = cb
                    yPos = yPos + self.CHECKBOX_ROW_SPACING
                end

                    yPos = yPos + self.MODULE_SPACING
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