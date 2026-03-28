setfenv(1, DFUI:GetEnv())

local Setup = {
    welcomeConfig = {
        width = 450,
        height = 400,
        timerDuration = 10,
        barWidth = 200,
        barHeight = 3,
        fadeTime = 0.4,
    },

    patchConfig = {
        width = 400,
        height = 210,
        timerDuration = 10,
        barWidth = 200,
        barHeight = 3,
        title = "|cFFFF0000Important Patch Warning|r",
        text = "Patch 2.0.11 implemented the pvp icon natively.\n\nDo not place the 'TargetingFrame' folder into\nyour WoW/Interface/ dir anymore.\nDeactivate module for Blizzard default.",
        additionalText = "",
        version = "2.0.11",
    },

    welcomeFrame = nil,
}

function Setup:TempDBForSwitching(isDarkMode)
    DFUI.tempDB = {}

    local src = isDarkMode and DFUI.profiles.darkMode or DFUI.profiles.lightMode
    if not src then return end

    for moduleName, moduleTable in pairs(src) do
        if moduleTable then
            DFUI.tempDB[moduleName] = {}
            for key, value in pairs(moduleTable) do
                if value then
                    DFUI.tempDB[moduleName][key] = value
                end
            end
        end
    end

    DFUI:TriggerAllCallbacks()
    DFUI.gui.Base:UpdateHandler()
end

function Setup:WelcomePage()
    if not self.welcomeFrame then
        self.welcomeFrame = CreateFrame("Frame", "DFUI_WelcomeFrame", UIParent)
    end
    self.welcomeFrame:SetWidth(self.welcomeConfig.width)
    self.welcomeFrame:SetHeight(self.welcomeConfig.height)
    self.welcomeFrame:SetPoint("CENTER", 0, 0)
    self.welcomeFrame:SetFrameStrata("TOOLTIP")
    self.welcomeFrame:SetToplevel(true)
    self.welcomeFrame:SetBackdrop{
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    }
    self.welcomeFrame:EnableMouse(true)

    T.GradientLine(self.welcomeFrame, "TOP", 1)
    T.GradientLine(self.welcomeFrame, "TOP", -60, nil, 200)
    T.GradientLine(self.welcomeFrame, "TOP", -290, nil, 200)
    T.GradientLine(self.welcomeFrame, "BOTTOM", -1, 3)

    local title = DFUI.tools.CreateFont(self.welcomeFrame, 18, "|cFFFFFFFF欢迎使用|r |cFFFFD700巨龙时代|r: |cFFFFF000Fix|r")
    title:SetPoint("TOP", 0, -25)

    local text = DFUI.tools.CreateFont(self.welcomeFrame, 15, "提示:\n按住 CTRL + SHIFT + ALT 移动框架。\n\n\n在报告bug之前:\n|cffff6060请禁用除巨龙时代: Fix以外的|n所有其他插件。|r\n\n90%的bug报告是由与其他插件冲突导致的。\n感谢您帮助我们保持bug报告的准确性。\n\n享受 |cFFFFD700巨龙时代|r 并别忘了更新。")
    text:SetPoint("TOP", title, "BOTTOM", 0, -40)
    text:SetWidth(380)

    local okBtn = DFUI.tools.CreateButton(self.welcomeFrame, "确定", 65, 27)
    okBtn:SetPoint("BOTTOM", 0, 60)
    okBtn:Disable()

    local menuBtn = DFUI.tools.CreateButton(self.welcomeFrame, "菜单", 65, 27)
    menuBtn:SetPoint("TOP", okBtn, "BOTTOM", 0, -10)
    menuBtn:Disable()

    local lightBtn = DFUI.tools.CreateButton(self.welcomeFrame, "浅色模式", 50, 24, true)
    lightBtn:SetPoint("RIGHT", okBtn, "LEFT", -15, -13)
    lightBtn:SetScript("OnClick", function()
        Setup:TempDBForSwitching(false)
    end)

    local darkBtn = DFUI.tools.CreateButton(self.welcomeFrame, "深色模式", 50, 24, true)
    darkBtn:SetPoint("LEFT", okBtn, "RIGHT", 15, -13)
    darkBtn:SetScript("OnClick", function()
        Setup:TempDBForSwitching(true)
    end)

    menuBtn:SetScript("OnClick", function()
        UIFrameFadeOut(self.welcomeFrame, self.welcomeConfig.fadeTime, 1, 0)
        local hideTimer = 0
        self.welcomeFrame:SetScript("OnUpdate", function()
            hideTimer = hideTimer + arg1
            if hideTimer >= self.welcomeConfig.fadeTime then
                self.welcomeFrame:Hide()
                self.welcomeFrame:SetScript("OnUpdate", nil)
                _G.SlashCmdList["DFUI"]()
            end
        end)
        local char = UnitName("player")
        DFUI_CUR_PROFILE[char .. "_firstRun"] = true
    end)

    okBtn:SetScript("OnClick", function()
        UIFrameFadeOut(self.welcomeFrame, self.welcomeConfig.fadeTime, 1, 0)
        local hideTimer = 0
        self.welcomeFrame:SetScript("OnUpdate", function()
            hideTimer = hideTimer + arg1
            if hideTimer >= self.welcomeConfig.fadeTime then
                self.welcomeFrame:Hide()
                self.welcomeFrame:SetScript("OnUpdate", nil)
            end
        end)
        local char = UnitName("player")
        DFUI_CUR_PROFILE[char .. "_firstRun"] = true
    end)

    local barWidth = self.welcomeConfig.barWidth
    local barHeight = self.welcomeConfig.barHeight
    local timerBar = self.welcomeFrame:CreateTexture(nil, "OVERLAY")
    timerBar:SetTexture("Interface\\Buttons\\WHITE8x8")
    timerBar:SetVertexColor(1, 0.82, 0)
    timerBar:SetPoint("BOTTOM", self.welcomeFrame, "BOTTOM", 0, 5)
    timerBar:SetWidth(barWidth)
    timerBar:SetHeight(barHeight)

    local elapsed = 0
    self.welcomeFrame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= self.welcomeConfig.timerDuration then
            okBtn:Enable()
            menuBtn:Enable()
            timerBar:Hide()
            self.welcomeFrame:SetScript("OnUpdate", nil)
            DFUI.activeScripts["WelcomePageScript"] = false
        else
            timerBar:SetWidth(barWidth * (1 - elapsed / self.welcomeConfig.timerDuration))
            DFUI.activeScripts["WelcomePageScript"] = true
        end
    end)
end

function Setup:PatchWarning()
    local patchFrame = CreateFrame("Frame", "DFUI_WelcomeFrame", UIParent)
    patchFrame:SetWidth(self.patchConfig.width)
    patchFrame:SetHeight(self.patchConfig.height)
    patchFrame:SetPoint("TOP", 0, -5)
    patchFrame:SetBackdrop{ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"}
    patchFrame:EnableMouse(true)

    T.GradientLine(patchFrame, "TOP", -0)
    T.GradientLine(patchFrame, "BOTTOM", 0)

    local title = DFUI.tools.CreateFont(patchFrame, 18, self.patchConfig.title)
    title:SetPoint("TOP", 0, -20)

    local fullText = self.patchConfig.text
    if self.patchConfig.additionalText ~= "" then
        fullText = fullText .. "\n\n|cFFFF0000" .. self.patchConfig.additionalText .. "|r"
    end

    local text = DFUI.tools.CreateFont(patchFrame, 15, fullText)
    text:SetPoint("TOP", title, "BOTTOM", 0, -16)
    text:SetWidth(380)

    local okBtn = DFUI.tools.CreateButton(patchFrame, "确定", 120, 24)
    okBtn:SetPoint("BOTTOM", 0, 20)
    okBtn:Disable()

    okBtn:SetScript("OnClick", function()
        patchFrame:Hide()
        DFUI:SetTempDBNoCallback("Generic", "patchWarnVersion", self.patchConfig.version)
    end)

    local barWidth = self.patchConfig.barWidth
    local barHeight = self.patchConfig.barHeight
    local timerBar = patchFrame:CreateTexture(nil, "OVERLAY")
    timerBar:SetTexture("Interface\\Buttons\\WHITE8x8")
    timerBar:SetVertexColor(1, 0.82, 0)
    timerBar:SetPoint("BOTTOM", okBtn, "TOP", 0, 10)
    timerBar:SetWidth(barWidth)
    timerBar:SetHeight(barHeight)

    local elapsed = 0
    patchFrame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= self.patchConfig.timerDuration then
            okBtn:Enable()
            timerBar:Hide()
            patchFrame:SetScript("OnUpdate", nil)
            DFUI.activeScripts["PatchWarningScript"] = false
        else
            timerBar:SetWidth(barWidth * (1 - elapsed / self.patchConfig.timerDuration))
            DFUI.activeScripts["PatchWarningScript"] = true
        end
    end)
end

DFUI.activeScripts["WelcomePageScript"] = false
DFUI.activeScripts["PatchWarningScript"] = false

-- init
local f = CreateFrame("Frame")
f:RegisterEvent("VARIABLES_LOADED")
f:SetScript("OnEvent", function()
    local char = UnitName("player")
    if not DFUI_CUR_PROFILE[char .. "_firstRun"] then
        Setup:WelcomePage()
    end

    -- local seenVersion = DFUI:GetTempValue("Generic", "patchWarnVersion")
    -- if seenVersion ~= Setup.patchConfig.version then
    --     -- Setup:PatchWarning()
    -- end
end)
