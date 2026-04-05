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

        allProf = DFUI_PROFILES,
        curProf = DFUI_CUR_PROFILE,

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
            leftFrame = nil,
            rightFrame = nil,
            curText = nil,
            texts = {},
            switchBtns = {},
            copyBtns = {},
            delBtns = {},
            newProfileBtn = nil,
            resetBtn = nil,
            editBox = nil,
            editBoxLabel = nil,
            exportBtn = nil,
            importBtn = nil,
            warner = nil,
            warnerFrame = nil,
            shareDialog = nil,
        }
    }

    --=================
    -- 左区：同账号快速切换
    --=================
    function Setup:BuildLeft()
        if not self.ui.leftBuilt then
            -- 大标题
            self.grid:AddElement(2, 1, DFUI.tools.CreateCategoryHeader(nil, "同账号快速切换"))

            -- 容器
            self.ui.leftFrame = CreateFrame("Frame", nil, panel)
            self.ui.leftFrame:SetHeight(1)
            self.ui.leftFrame:SetWidth(300)
            self.grid:AddElement(2, 2, self.ui.leftFrame)

            -- 小标题
            self.grid:AddElement(1, 3, DFUI.tools.CreateCategoryHeader(nil, "档案名", nil, 100))
            self.grid:AddElement(3, 3, DFUI.tools.CreateCategoryHeader(nil, "操作", nil, 100))

            -- 金色装饰线
            T.GradientLine(self.ui.leftFrame, "TOP", 35)
            T.GradientLine(self.ui.leftFrame, "TOP", -5)

            self.ui.leftBuilt = true
        end
    end

    function Setup:BuildProfileList()
        -- 清理旧列表
        for _, text in pairs(self.ui.texts) do text:Hide() end
        for _, btn in pairs(self.ui.switchBtns) do btn:Hide() end
        for _, btn in pairs(self.ui.copyBtns) do btn:Hide() end
        for _, btn in pairs(self.ui.delBtns) do btn:Hide() end
        self.ui.texts = {}
        self.ui.switchBtns = {}
        self.ui.copyBtns = {}
        self.ui.delBtns = {}

        -- 当前档案
        local char = UnitName("player")
        local curProf = self.curProf[char] or "Default"
        if not self.ui.curText then
            self.ui.curText = DFUI.tools.CreateFont(panel, self.TEXT_SIZE, "", {0.5, 1, 0.5}, "LEFT")
            self.grid:AddElement(1, 5, self.ui.curText)
        end
        self.ui.curText:SetText("当前:  |cff80ff80" .. curProf .. "|r")

        -- 排序
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

        -- 渲染列表
        local line = 7
        for _, name in ipairs(sortedProfiles) do
            -- 档案名
            local text = DFUI.tools.CreateFont(panel, self.TEXT_SIZE, name, nil, "LEFT")
            self.grid:AddElement(1, line, text)
            table.insert(self.ui.texts, text)

            -- 非 Default 档案显示操作按钮
            if name ~= "Default" then
                local profName = name

                local switchBtn = DFUI.tools.CreateButton(panel, "切换", 50, 20, true, {0.5, 1, 0.5})
                self.grid:AddElement(2, line, switchBtn)
                switchBtn.profName = profName
                switchBtn:SetScript("OnClick", function()
                    DFUI:SwitchProfile(this.profName)
                    DFUI:SaveTempDB()
                    ReloadUI()
                end)
                table.insert(self.ui.switchBtns, switchBtn)

                local copyBtn = DFUI.tools.CreateButton(panel, "复制", 50, 20, true)
                copyBtn.profName = profName
                copyBtn:SetScript("OnClick", function()
                    DFUI:LoadProfile(this.profName)
                    DFUI:SaveTempDB()
                    ReloadUI()
                end)
                table.insert(self.ui.copyBtns, copyBtn)

                local delBtn = DFUI.tools.CreateButton(panel, "删除", 50, 20, true, {1, 0.5, 0.5})
                delBtn.profName = profName
                delBtn:SetScript("OnClick", function()
                    DFUI:DeleteProfile(this.profName)
                    DFUI:SwitchProfile("Default")
                    DFUI:SaveTempDB()
                    ReloadUI()
                end)
                table.insert(self.ui.delBtns, delBtn)

                -- 复制和删除紧跟切换按钮右侧
                copyBtn:SetPoint("LEFT", switchBtn, "RIGHT", 4, 0)
                delBtn:SetPoint("LEFT", copyBtn, "RIGHT", 4, 0)
            end

            line = line + 1
        end

        self.ui._nextLine = line + 1
    end

    function Setup:BuildLeftButtons()
        local btnLine = self.ui._nextLine or 12

        if not self.ui.newProfileBtn then
            self.ui.newProfileBtn = DFUI.tools.CreateButton(panel, "新建档案", 90, 26, true)
            self.grid:AddElement(1, btnLine, self.ui.newProfileBtn)
            self.ui.newProfileBtn:SetScript("OnClick", function()
                local count = 0
                for _ in pairs(Setup.allProf) do count = count + 1 end
                if count >= 10 then
                    Setup:ShowWarning("已达到最大档案数量", {1, 0, 0})
                    return
                end
                if not Setup.ui.editBox then
                    Setup.ui.editBox = DFUI.tools.CreateEditBox(panel, 180, 26, true, nil, 10)
                    Setup.ui.editBox:SetPoint("TOPLEFT", Setup.ui.newProfileBtn, "BOTTOMLEFT", 0, -8)
                    Setup.ui.editBoxLabel = DFUI.tools.CreateFont(panel, 11, "输入名称后回车确认", {0.6, 0.6, 0.6}, "LEFT")
                    Setup.ui.editBoxLabel:SetPoint("TOPLEFT", Setup.ui.editBox, "BOTTOMLEFT", 0, -4)
                    Setup.ui.editBox:SetScript("OnEnterPressed", function()
                        local profileName = Setup.ui.editBox:GetText()
                        if profileName and profileName ~= "" then
                            DFUI:CreateProfile(profileName)
                            DFUI:SwitchProfile(profileName)
                            DFUI:SetTempDBNoCallback("Generic", "firstRun", true)
                            DFUI:SaveTempDB()
                            ReloadUI()
                        end
                        Setup.ui.editBox:Hide()
                        Setup.ui.editBoxLabel:Hide()
                        Setup.ui.editBox:SetText("")
                    end)
                end
                Setup.ui.editBox:Show()
                Setup.ui.editBoxLabel:Show()
                Setup.ui.editBox:SetFocus()
            end)
        end

        if not self.ui.resetBtn then
            self.ui.resetBtn = DFUI.tools.CreateButton(panel, "重置为默认", 90, 26, true, {1, 0.5, 0.5})
            self.ui.resetBtn:SetPoint("LEFT", self.ui.newProfileBtn, "RIGHT", 10, 0)
            self.ui.resetBtn:SetScript("OnClick", function()
                DFUI:CopyProfile(nil, Setup.default["Default"])
                DFUI:SaveTempDB()
                ReloadUI()
            end)
        end
    end

    --=================
    -- 右区：配置共享
    --=================
    function Setup:BuildRight()
        if not self.ui.rightBuilt then
            -- 大标题
            self.grid:AddElement(5, 1, DFUI.tools.CreateCategoryHeader(nil, "配置共享"))

            -- 容器
            self.ui.rightFrame = CreateFrame("Frame", nil, panel)
            self.ui.rightFrame:SetHeight(1)
            self.ui.rightFrame:SetWidth(300)
            self.grid:AddElement(5, 2, self.ui.rightFrame)

            -- 金色装饰线
            T.GradientLine(self.ui.rightFrame, "TOP", 35)
            T.GradientLine(self.ui.rightFrame, "TOP", -5)

            -- 描述文字
            self.grid:AddElement(4, 4, DFUI.tools.CreateFont(panel, self.TEXT_SIZE,
                "将当前配置生成为字符串，", {0.6, 0.6, 0.6}, "LEFT"))
            self.grid:AddElement(4, 5, DFUI.tools.CreateFont(panel, self.TEXT_SIZE,
                "复制后在其他角色或账号", {0.6, 0.6, 0.6}, "LEFT"))
            self.grid:AddElement(4, 6, DFUI.tools.CreateFont(panel, self.TEXT_SIZE,
                "粘贴即可应用。", {0.6, 0.6, 0.6}, "LEFT"))

            -- 导出按钮
            self.ui.exportBtn = DFUI.tools.CreateButton(panel, "导出配置", 100, 30, true, {0.6, 0.8, 1})
            self.grid:AddElement(4, 8, self.ui.exportBtn)
            self.ui.exportBtn:SetScript("OnClick", function()
                Setup:ShowExportDialog()
            end)

            -- 导入按钮
            self.ui.importBtn = DFUI.tools.CreateButton(panel, "导入配置", 100, 30, true, {1, 0.9, 0.5})
            self.ui.importBtn:SetPoint("LEFT", self.ui.exportBtn, "RIGHT", 10, 0)
            self.ui.importBtn:SetScript("OnClick", function()
                Setup:ShowImportDialog()
            end)

            -- 注释
            self.grid:AddElement(4, 10, DFUI.tools.CreateFont(panel, 11,
                "* 所有操作后自动重载界面", {0.4, 0.4, 0.4}, "LEFT"))
            self.grid:AddElement(4, 11, DFUI.tools.CreateFont(panel, 11,
                "* 不影响 ShaguTweaks", {0.4, 0.4, 0.4}, "LEFT"))

            self.ui.rightBuilt = true
        end
    end

    --=================
    -- 工具函数
    --=================
    function Setup:ShowWarning(msg, color)
        if not self.ui.warner then
            self.ui.warner = DFUI.tools.CreateFontWarner(panel, 14, "", color or {1, 0, 0}, true, 3)
            self.ui.warner:SetPoint("BOTTOM", self.ui.leftFrame, "BOTTOM", 0, -60)
        end
        self.ui.warner:SetTextColor(color[1], color[2], color[3])
        self.ui.warner:SetText(msg)
        self.ui.warner:Show()
        self:RestartWarnerPulse()
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

    --=================
    -- 导入/导出弹窗
    --=================
    local function CreateShareDialog()
        if Setup.ui.shareDialog then return end

        local dialog = CreateFrame("Frame", "DFUI_ShareDialog", UIParent)
        dialog:SetWidth(520)
        dialog:SetHeight(320)
        dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
        dialog:SetFrameStrata("DIALOG")
        dialog:SetFrameLevel(200)
        dialog:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        dialog:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
        dialog:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        dialog:EnableMouse(true)
        dialog:SetMovable(true)
        dialog:RegisterForDrag("LeftButton")
        dialog:SetScript("OnDragStart", function() dialog:StartMoving() end)
        dialog:SetScript("OnDragStop", function() dialog:StopMovingOrSizing() end)
        dialog:Hide()

        local title = dialog:CreateFontString(nil, "OVERLAY")
        title:SetFont(Setup.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(16), "OUTLINE")
        title:SetPoint("TOP", dialog, "TOP", 0, -12)
        dialog.title = title

        local closeBtn = DFUI.tools.CreateButton(dialog, "X", 24, 24, true, {1, 0.4, 0.4})
        closeBtn:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -6, -6)
        closeBtn:SetScript("OnClick", function() dialog:Hide() end)

        local hint = dialog:CreateFontString(nil, "OVERLAY")
        hint:SetFont(Setup.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(12), "OUTLINE")
        hint:SetPoint("TOP", title, "BOTTOM", 0, -6)
        hint:SetTextColor(0.7, 0.7, 0.7)
        dialog.hint = hint

        local scrollFrame = CreateFrame("ScrollFrame", "DFUI_ShareScrollFrame", dialog, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 14, -60)
        scrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -32, 50)

        local editBox = CreateFrame("EditBox", "DFUI_ShareEditBox", scrollFrame)
        editBox:SetWidth(460)
        editBox:SetHeight(210)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFont(Setup.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(11), "OUTLINE")
        editBox:SetTextColor(0.9, 0.9, 0.9)
        editBox:SetMaxLetters(99999)
        editBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        editBox:SetScript("OnTextChanged", function()
            scrollFrame:UpdateScrollChildRect()
        end)
        scrollFrame:SetScrollChild(editBox)
        dialog.editBox = editBox

        local status = dialog:CreateFontString(nil, "OVERLAY")
        status:SetFont(Setup.font .. "BigNoodleTitling.ttf", DFUI.tools.ScaledSize(12), "OUTLINE")
        status:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 12)
        dialog.status = status

        local importBtn = DFUI.tools.CreateButton(dialog, "确认导入", 100, 26, true, {0.5, 1, 0.5})
        importBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -40, 8)
        importBtn:SetScript("OnClick", function()
            local text = editBox:GetText()
            if not text or text == "" then
                dialog.status:SetTextColor(1, 0, 0)
                dialog.status:SetText("请先粘贴配置字符串")
                return
            end

            local profileData, err = DFUI:DeserializeProfile(text)
            if not profileData then
                dialog.status:SetTextColor(1, 0, 0)
                dialog.status:SetText("导入失败: " .. (err or "未知错误"))
                return
            end

            -- 同时更新 tempDB，防止 PLAYER_LOGOUT 的 SaveTempDB 覆盖导入数据
            DFUI.tempDB = {}
            for mod, data in pairs(profileData) do
                if mod == "_FramePos" then
                    _G.DFUI_FRAMEPOS = {}
                    for fname, pos in pairs(data) do
                        _G.DFUI_FRAMEPOS[fname] = {x = pos.x, y = pos.y}
                    end
                else
                    DFUI.tempDB[mod] = {}
                    for key, value in pairs(data) do
                        DFUI.tempDB[mod][key] = value
                    end
                end
            end

            -- 补充缺失的默认值
            for mod, def in pairs(DFUI.defaults) do
                DFUI.tempDB[mod] = DFUI.tempDB[mod] or {}
                for key, val in pairs(def) do
                    if DFUI.tempDB[mod][key] == nil then
                        DFUI.tempDB[mod][key] = val[1]
                    end
                end
            end

            ReloadUI()
        end)
        dialog.importBtn = importBtn

        Setup.ui.shareDialog = dialog
    end

    function Setup:ShowExportDialog()
        CreateShareDialog()
        local dialog = self.ui.shareDialog
        local char = UnitName("player")
        local curProf = DFUI_CUR_PROFILE[char] or "Default"

        DFUI:SaveTempDB()

        local exported = DFUI:SerializeProfile(curProf)
        if not exported then
            self:ShowWarning("导出失败：档案不存在", {1, 0, 0})
            return
        end

        dialog.title:SetText("导出配置: " .. curProf)
        dialog.hint:SetText("Ctrl+A 全选, Ctrl+C 复制, 粘贴到其他角色的导入框")
        dialog.editBox:SetText(exported)
        dialog.editBox:SetFocus()
        dialog.editBox:HighlightText(0, string.len(exported))
        dialog.importBtn:Hide()
        dialog.status:SetTextColor(0.5, 1, 0.5)
        dialog.status:SetText("共 " .. string.len(exported) .. " 字符")
        dialog:Show()
    end

    function Setup:ShowImportDialog()
        CreateShareDialog()
        local dialog = self.ui.shareDialog

        dialog.title:SetText("导入配置")
        dialog.hint:SetText("Ctrl+V 粘贴配置字符串, 然后点击确认导入")
        dialog.editBox:SetText("")
        dialog.editBox:SetFocus()
        dialog.importBtn:Show()
        dialog.status:SetText("")
        dialog:Show()
    end

    --=================
    -- INIT
    --=================
    function Setup:Run()
        Setup.grid:Init()
        self:BuildLeft()
        self:BuildProfileList()
        self:BuildLeftButtons()
        self:BuildRight()
    end

    Setup:Run()
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function() end)
end)
