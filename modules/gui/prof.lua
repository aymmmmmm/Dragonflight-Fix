DFUI:NewDefaults("Gui-prof", {
    enabled = {true},

})

DFUI:NewMod("Gui-prof", 4, function()
    --=================
    -- SETUP
    --=================
    local pairs = pairs

    local Base = DFUI.gui.Base
    local panel = Base.scrollChildren[3]
    local Setup = {
        grid = DFUI.tools.CreateGrid(Base.scrollChildren[3], 33, 25),
        headers = false,

        allProf = DFUI_PROFILES,
        curProf = DFUI_CUR_PROFILE,
        tempProfile = {},

        default = (function()
            local sanitized = {["Default"] = {}}
            for prof, data in pairs(DFUI.defaults) do
                sanitized["Default"][prof] = {}
                for key, value in pairs(data) do
                    sanitized["Default"][prof][key] = value[1]
                end
            end
            return sanitized
        end)(),

        font = DFUI:GetInfoOrCons("font"),
        TEXT_SIZE = 14,

        ui = {
            frame = nil,
            curText = nil,
            spacer = nil,
            usageText = nil,
            texts = {},
            copyBtns = {},
            delBtns = {},
            switchBtns = {},
            newProfileBtn = nil,
            resetBtn = nil,
            warner = nil
        }
    }


    function Setup:ListFrame()
        if not self.headers then
            self.grid:AddElement(2, 1, DFUI.tools.CreateCategoryHeader(nil, "管理"))
            self.headers = true
        end

        if not self.ui.usageText then
            self.ui.usageText = DFUI.tools.CreateFont(panel, 14, "使用说明:\n\n\n1) 新建档案: 创建并切换到新档案\n\n2) 切换: 更改活跃档案\n\n3) 复制: 将所有设置复制到活跃档案\n\n4) 删除: 删除档案并切换回默认\n\n5) 重置: 将活跃档案重置为默认设置\n\n\n不影响ShaguTweaks\n\nBUG: 新建档案后双击删除\n\nBUG: 输入档案名称残留", {.5, .5, .5}, "LEFT")
            self.grid:AddElement(5, 4, self.ui.usageText)
        end
        if not self.ui.frame then
            self.ui.frame = CreateFrame("Frame", nil, panel)
            self.ui.frame:SetWidth(300)
            self.ui.frame:SetHeight(400)
            self.grid:AddElement(2, 3, self.ui.frame)
            T.GradientLine(self.ui.frame, "TOP", 20, 2)
            T.GradientLine(self.ui.frame, "TOP", 60, 2)
            T.GradientLine(self.ui.frame, "BOTTOM", 0)
        end

        local char = UnitName("player")
        local curProf = self.curProf[char] or "Default"
        if not self.ui.curText then
            self.ui.curText = self.ui.frame:CreateFontString(nil, "OVERLAY")
            self.ui.curText:SetFont(self.font .. "BigNoodleTitling.ttf", self.TEXT_SIZE, "OUTLINE")
            self.ui.curText:SetPoint("TOPLEFT", self.ui.frame, "TOPLEFT", 10, -10)
        end
        self.ui.curText:SetText("当前:   |cff80ff80" .. curProf .. "|r")
        for _, text in pairs(self.ui.texts) do
            text:Hide()
        end
        for _, btn in pairs(self.ui.copyBtns) do
            btn:Hide()
        end
        for _, btn in pairs(self.ui.delBtns) do
            btn:Hide()
        end
        for _, btn in pairs(self.ui.switchBtns) do
            btn:Hide()
        end

        self.ui.texts = {}
        self.ui.copyBtns = {}
        self.ui.delBtns = {}
        self.ui.switchBtns = {}
        local yOffset = -50
        local profCount = 0
        local sortedProfiles = {}
        for name in pairs(self.allProf) do
            if name ~= "Default" then
                table.insert(sortedProfiles, name)
            end
        end
        table.sort(sortedProfiles, function(a, b)
            return string.lower(a) < string.lower(b)
        end)
        table.insert(sortedProfiles, 1, "Default")

        for _, name in ipairs(sortedProfiles) do
            profCount = profCount + 1

            local text = self.ui.frame:CreateFontString(nil, "OVERLAY")
            text:SetFont(self.font .. "BigNoodleTitling.ttf", self.TEXT_SIZE, "OUTLINE")
            text:SetPoint("TOPLEFT", self.ui.frame, "TOPLEFT", 10, yOffset)
            text:SetText(name)
            table.insert(self.ui.texts, text)
            if name ~= "Default" then
                local profName = name
                local switchBtn = DFUI.tools.CreateButton(self.ui.frame, "切换", 50, 20, true, {0.5, 1, 0.5})
                switchBtn:SetPoint("TOPLEFT", self.ui.frame, "TOPLEFT", 125, yOffset)
                switchBtn.profName = profName
                switchBtn:SetScript("OnClick", function()
                    local clickedName = this.profName
                    DFUI:SwitchProfile(clickedName)
                    Setup:Update()
                    if DFUI.gui.Base.UpdateHandler then
                        DFUI.gui.Base:UpdateHandler()
                    end
                    if not Setup.ui.warner then
                        Setup.ui.warner = DFUI.tools.CreateFontWarner(panel, 14, "", {0, 1, 0}, true, 3)
                        Setup.ui.warner:SetPoint("TOP", Setup.ui.frame, "BOTTOM", 0, 25)
                    end
                    Setup.ui.warner:SetTextColor(0, 1, 0)
                    Setup.ui.warner:SetText("已切换到 " .. clickedName)
                    Setup.ui.warner:Show()
                    Setup:RestartWarnerPulse()
                end)
                table.insert(self.ui.switchBtns, switchBtn)
                local copyBtn = DFUI.tools.CreateButton(self.ui.frame, "复制", 50, 20, true)
                copyBtn:SetPoint("TOPLEFT", self.ui.frame, "TOPLEFT", 180, yOffset)
                copyBtn.profName = profName
                copyBtn:SetScript("OnClick", function()
                    local clickedName = this.profName
                    DFUI:LoadProfile(clickedName)
                    Setup:Update()
                    if DFUI.gui.Base.UpdateHandler then
                        DFUI.gui.Base:UpdateHandler()
                    end
                    if not Setup.ui.warner then
                        Setup.ui.warner = DFUI.tools.CreateFontWarner(panel, 14, "", {1, 1, 0}, true, 3)
                        Setup.ui.warner:SetPoint("TOP", Setup.ui.frame, "BOTTOM", 0, 25)
                    end
                    Setup.ui.warner:SetTextColor(1, 1, 0)
                    Setup.ui.warner:SetText("已从 " .. clickedName .. " 复制档案")
                    Setup.ui.warner:Show()
                    Setup:RestartWarnerPulse()
                end)
                table.insert(self.ui.copyBtns, copyBtn)
                local delBtn = DFUI.tools.CreateButton(self.ui.frame, "删除", 50, 20, true, {1, 0.5, 0.5})
                delBtn:SetPoint("TOPLEFT", self.ui.frame, "TOPLEFT", 235, yOffset)
                delBtn.profName = profName
                delBtn:SetScript("OnClick", function()
                    local clickedName = this.profName
                    DFUI:DeleteProfile(clickedName)
                    DFUI:SwitchProfile("Default")
                    DFUI.gui.Base:UpdateHandler()
                    Setup:Update()
                    if not Setup.ui.warner then
                        Setup.ui.warner = DFUI.tools.CreateFontWarner(panel, 14, "", {1, 0, 0}, true, 3)
                        Setup.ui.warner:SetPoint("TOP", Setup.ui.frame, "BOTTOM", 0, 25)
                    end
                    Setup.ui.warner:SetTextColor(1, 0, 0)
                    Setup.ui.warner:SetText(clickedName .. " 已删除")
                    Setup.ui.warner:Show()
                    Setup:RestartWarnerPulse()
                end)
                table.insert(self.ui.delBtns, delBtn)
            end

            yOffset = yOffset - 20
        end


    end

    function Setup:RestartWarnerPulse()
        if not self.ui.warnerFrame then
            self.ui.warnerFrame = CreateFrame("Frame")
        end
        self.ui.warnerFrame.elapsed = 0
        self.ui.warnerFrame.totalTime = 3
        self.ui.warnerFrame.direction = -1
        self.ui.warnerFrame.alpha = 1
        self.ui.warnerFrame:SetScript("OnUpdate", function()
            if not Setup.ui.warner:IsVisible() then
                this:SetScript("OnUpdate", nil)
                return
            end
            this.elapsed = this.elapsed + arg1
            this.alpha = this.alpha + this.direction * arg1 * 2
            if this.alpha <= 0.3 then
                this.alpha = 0.3
                this.direction = 1
            elseif this.alpha >= 1 then
                this.alpha = 1
                this.direction = -1
            end
            Setup.ui.warner:SetAlpha(this.alpha)
            if this.totalTime > 0 and this.elapsed >= this.totalTime then
                Setup.ui.warner:Hide()
                this:SetScript("OnUpdate", nil)
            end
        end)
    end

    function Setup:Update()
        Setup:ListFrame()
    end

    function Setup:ExtraButtons()
        if not self.ui.newProfileBtn then
            self.ui.newProfileBtn = DFUI.tools.CreateButton(panel, "新建档案", 100, 30, true)
            self.ui.newProfileBtn:SetPoint("TOPLEFT", self.ui.frame, "TOPRIGHT", 20, -25)
            self.ui.newProfileBtn:SetScript("OnClick", function()
                local count = 0
                for _ in pairs(self.allProf) do
                    count = count + 1
                end
                if count >= 10 then
                    if not Setup.ui.warner then
                        Setup.ui.warner = DFUI.tools.CreateFontWarner(panel, 14, "", {1, 0, 0}, true, 3)
                        Setup.ui.warner:SetPoint("TOP", Setup.ui.frame, "BOTTOM", 0, 25)
                    end
                    Setup.ui.warner:SetTextColor(1, 0, 0)
                    Setup.ui.warner:SetText("已达到最大档案数量")
                    Setup.ui.warner:Show()
                    Setup:RestartWarnerPulse()
                    return
                end
                if not self.ui.editBox then
                    self.ui.editBox = DFUI.tools.CreateEditBox(panel, 200, 30, true, nil, 10)
                    self.ui.editBox:SetPoint("TOP", self.ui.frame, "BOTTOM", 0, -6)
                    self.ui.editBoxLabel = DFUI.tools.CreateFontWarner(panel, 14, "输入档案名称", {.9, .9, .9})
                    self.ui.editBoxLabel:SetPoint("TOP", Setup.ui.frame, "BOTTOM", 0, -45)
                    self.ui.editBox:SetScript("OnEnterPressed", function()
                        local profileName = self.ui.editBox:GetText()
                        if profileName and profileName ~= "" then
                            DFUI:CreateProfile(profileName)
                            DFUI:SwitchProfile(profileName)
                            DFUI:SetTempDBNoCallback("Generic", "firstRun", true)
                            Setup:Update()
                            if DFUI.gui.Base.UpdateHandler then
                                DFUI.gui.Base:UpdateHandler()
                            end

                            if not Setup.ui.warner then
                                Setup.ui.warner = DFUI.tools.CreateFontWarner(panel, 14, "", {0, 1, 0}, true, 3)
                                Setup.ui.warner:SetPoint("TOP", Setup.ui.frame, "BOTTOM", 0, 25)
                            end
                            Setup.ui.warner:SetTextColor(0, 1, 0)
                            Setup.ui.warner:SetText("新档案已创建")
                            Setup.ui.warner:Show()
                            Setup:RestartWarnerPulse()
                        end
                        self.ui.editBox:Hide()
                        self.ui.editBoxLabel:Hide()
                        self.ui.editBox:SetText("")
                    end)
                end
                self.ui.editBox:Show()
                self.ui.editBoxLabel:Show()
                self.ui.editBox:SetFocus()
            end)

        end
        if not self.ui.resetBtn then
            self.ui.resetBtn = DFUI.tools.CreateButton(panel, "重置", 100, 30, true, {1, 0.5, 0.5})
            self.ui.resetBtn:SetPoint("TOPLEFT", self.ui.newProfileBtn, "BOTTOMLEFT", 0, -10)
            self.ui.resetBtn:SetScript("OnClick", function()
                local success, _ = pcall(function()
                    DFUI:CopyProfile(nil, Setup.default["Default"])
                    DFUI.gui.Base:UpdateHandler()
                end)
                if success then
                    if not Setup.ui.warner then
                        Setup.ui.warner = DFUI.tools.CreateFontWarner(panel, 14, "", {0, 1, 0}, true, 3)
                        Setup.ui.warner:SetPoint("TOP", Setup.ui.frame, "BOTTOM", 0, 25)
                    end
                    Setup.ui.warner:SetTextColor(0, 1, 0)
                    Setup.ui.warner:SetText("当前档案已重置")
                    Setup.ui.warner:Show()
                    Setup:RestartWarnerPulse()
                else
                    if not Setup.ui.warner then
                        Setup.ui.warner = DFUI.tools.CreateFontWarner(panel, 14, "", {1, 0, 0}, true, 3)
                        Setup.ui.warner:SetPoint("TOP", Setup.ui.frame, "BOTTOM", 0, 25)
                    end
                    Setup.ui.warner:SetTextColor(1, 0, 0)
                    Setup.ui.warner:SetText("档案重置失败")
                    Setup.ui.warner:Show()
                    Setup:RestartWarnerPulse()
                end
            end)

        end
    end

    --=================
    -- INIT
    --=================
    function Setup:Run()
        Setup.grid:Init()
        self:ListFrame()
        self:ExtraButtons()
        self:Update()
    end

    Setup:Run()
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function() end)
end)