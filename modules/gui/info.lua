DFUI:NewDefaults("Gui-info", {
    enabled = {true},
})

DFUI:NewMod("Gui-info", 5, function()
    --=================
    -- SETUP
    --=================
    local Base = DFUI.gui.Base
    local panel = Base.scrollChildren[2]
    local Setup = {
        font = DFUI:GetInfoOrCons("font"),
        grid = DFUI.tools.CreateGrid(Base.scrollChildren[2], 33, 25),

        AREA_LINE = 1,

        dfFrame = nil,
        perfFrame = nil,
        scriptsFrame = nil,
        addonsFrame = nil,

        scriptTexts = {},
        statusTexts = {},
        addonTexts = {},
        perfTexts = {},
        totalText = nil,
        totalCountText = nil,
        spacesAdded = false,

        UPDATE_INTERVAL = 0.1,
        TEXT_SIZE = 14,
    }

    function Setup:DFInfo()
        if not self.dfinfo then
            self.dfFrame = CreateFrame("Frame", nil, panel)
            self.dfFrame:SetHeight(1)
            self.dfFrame:SetWidth(300)
            self.grid:AddElement(2, 2, self.dfFrame)
            self.grid:AddElement(2, 1, DFUI.tools.CreateCategoryHeader(nil, "龙飞信息"))
            self.grid:AddElement(1, 3, DFUI.tools.CreateCategoryHeader(nil, "系统", nil, 100))
            self.grid:AddElement(3, 3, DFUI.tools.CreateCategoryHeader(nil, "信息", nil, 100))
            self.grid:AddElement(1, 5, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, "插件版本:", nil, "LEFT"))
            self.grid:AddElement(3, 5, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, DFUI:GetInfoOrCons("version"), {0.5, 1, 0.5}))
            self.grid:AddElement(1, 6, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, "数据库版本:", nil, "LEFT"))
            self.grid:AddElement(3, 6, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, DFUI.DBversion, {0.5, 1, 0.5}))
            local total = 0
            for _ in pairs(DFUI.performance) do
                total = total + 1
            end
            self.grid:AddElement(1, 7, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, "上次更新:", nil, "LEFT"))
            self.grid:AddElement(3, 7, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, (DFUI_DB_SETUP and DFUI_DB_SETUP.lastVersionCheck and DFUI_DB_SETUP.lastVersionCheck.date) or "从未", {0.5, 1, 0.5}))
            self.grid:AddElement(1, 8, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, "活跃模块:", nil, "LEFT"))
            self.grid:AddElement(3, 8, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, total, {0.5, 1, 0.5}))

            local clientVersion, buildNumber, _, _ = GetBuildInfo()
            local locale = GetLocale()
            local realm = GetRealmName()

            self.grid:AddElement(1, 10, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, "客户端版本:", nil, "LEFT"))
            self.grid:AddElement(3, 10, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, clientVersion, {0.5, 0.5, 0.5}))
            self.grid:AddElement(1, 11, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, "构建号:", nil, "LEFT"))
            self.grid:AddElement(3, 11, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, buildNumber, {0.5, 0.5, 0.5}))
            self.grid:AddElement(1, 12, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, "语言:", nil, "LEFT"))
            self.grid:AddElement(3, 12, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, locale, {0.5, 0.5, 0.5}))
            self.grid:AddElement(1, 13, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, "服务器:", nil, "LEFT"))
            self.grid:AddElement(3, 13, DFUI.tools.CreateFont(self.dfFrame, self.TEXT_SIZE, realm, {0.5, 0.5, 0.5}))
            T.GradientLine(self.dfFrame, "TOP", 35)
            T.GradientLine(self.dfFrame, "TOP", -5)
            self.dfinfo = true
        end
    end

    function Setup:SupportedAddons()
        if not self.addons then
            self.addonsFrame = CreateFrame("Frame", nil, panel)
            self.addonsFrame:SetHeight(1)
            self.addonsFrame:SetWidth(300)
            self.grid:AddElement(5, 2, self.addonsFrame)
            self.grid:AddElement(5, 1, DFUI.tools.CreateCategoryHeader(nil, "支持的插件"))
            self.grid:AddElement(4, 3, DFUI.tools.CreateCategoryHeader(nil, "插件", nil, 100))
            self.grid:AddElement(6, 3, DFUI.tools.CreateCategoryHeader(nil, "状态", nil, 100))
            self.grid:AddElement(4, 5, DFUI.tools.CreateFont(self.addonsFrame, self.TEXT_SIZE, "ShaguTweaks", nil, "LEFT"))
            self.grid:AddElement(6, 5, DFUI.tools.CreateFont(self.addonsFrame, self.TEXT_SIZE, DFUI.addon1 and "已安装" or "未安装", DFUI.addon1 and {0.5, 1, 0.5} or {0.5, 0.5, 0.5}))
            self.grid:AddElement(4, 6, DFUI.tools.CreateFont(self.addonsFrame, self.TEXT_SIZE, "ShaguTweaks-extras", nil, "LEFT"))
            self.grid:AddElement(6, 6, DFUI.tools.CreateFont(self.addonsFrame, self.TEXT_SIZE, DFUI.addon2 and "已安装" or "未安装", DFUI.addon2 and {0.5, 1, 0.5} or {0.5, 0.5, 0.5}))
            self.grid:AddElement(4, 7, DFUI.tools.CreateFont(self.addonsFrame, self.TEXT_SIZE, "Bagshui", nil, "LEFT"))
            self.grid:AddElement(6, 7, DFUI.tools.CreateFont(self.addonsFrame, self.TEXT_SIZE, DFUI.addon3 and "已安装" or "未安装", DFUI.addon3 and {0.5, 1, 0.5} or {0.5, 0.5, 0.5}))

self.grid:AddElement(4, 8,
    DFUI.tools.CreateFont(self.addonsFrame, self.TEXT_SIZE, "Immersion", nil, "LEFT")
)

self.grid:AddElement(6, 8,
    DFUI.tools.CreateFont(
        self.addonsFrame,
        self.TEXT_SIZE,
        DFUI.addon4 and "已安装" or "未安装",
        DFUI.addon4 and {0.5, 1, 0.5} or {0.5, 0.5, 0.5}
    )
)

            T.GradientLine(self.addonsFrame, "TOP", 35)
            T.GradientLine(self.addonsFrame, "TOP", -5)
            self.addons = true
        end
    end

    function Setup:Performance()
        if not self.perf then
            self.perfFrame = CreateFrame("Frame", nil, panel)
            self.perfFrame:SetHeight(1)
            self.perfFrame:SetWidth(300)
            self.grid:AddElement(2, 17 + self.AREA_LINE, self.perfFrame)
            self.grid:AddElement(2, 16 + self.AREA_LINE, DFUI.tools.CreateCategoryHeader(nil, "性能"))
            self.grid:AddElement(1, 18 + self.AREA_LINE, DFUI.tools.CreateCategoryHeader(nil, "模块", nil, 100))
            self.grid:AddElement(2, 18 + self.AREA_LINE, DFUI.tools.CreateCategoryHeader(nil, "时间 (毫秒)", nil, 100))
            self.grid:AddElement(3, 18 + self.AREA_LINE, DFUI.tools.CreateCategoryHeader(nil, "内存 (KB)", nil, 100))
            T.GradientLine(self.perfFrame, "TOP", 35)
            T.GradientLine(self.perfFrame, "TOP", -5)
            self.perf = true
        end

        local gui = {}
        local other = {}
        local totalTime = 0
        local totalMem = 0

        for modName, perfData in pairs(DFUI.performance) do
            local entry = {name = modName, data = perfData}
            totalTime = totalTime + perfData.time
            totalMem = totalMem + perfData.memory
            if string.upper(string.sub(modName, 1, 3)) == "GUI" then
                table.insert(gui, entry)
            else
                table.insert(other, entry)
            end
        end

        table.sort(gui, function(a, b) return a.data.memory > b.data.memory end)
        table.sort(other, function(a, b) return a.data.memory > b.data.memory end)

        local line = 20 + self.AREA_LINE
        if not self.perfTexts[1] then
            self.perfTexts[1] = DFUI.tools.CreateFont(self.perfFrame, self.TEXT_SIZE, "TOTAL:", {1, 0.5, 0.5}, "LEFT")
            self.perfTexts[2] = DFUI.tools.CreateFont(self.perfFrame, self.TEXT_SIZE, "", {0.5, 1, 0.5})
            self.perfTexts[3] = DFUI.tools.CreateFont(self.perfFrame, self.TEXT_SIZE, "", {0.5, 1, 0.5})
            self.grid:AddElement(1, line, self.perfTexts[1])
            self.grid:AddElement(2, line, self.perfTexts[2])
            self.grid:AddElement(3, line, self.perfTexts[3])

        end
        self.perfTexts[2]:SetText(string.format("%.2f", totalTime * 1000))
        self.perfTexts[3]:SetText(string.format("%.1f", totalMem))
        line = line + 2

        local idx = 4
        for i = 1, table.getn(gui) do
            local entry = gui[i]
            if not self.perfTexts[idx] then
                self.perfTexts[idx] = DFUI.tools.CreateFont(self.perfFrame, self.TEXT_SIZE, "", nil, "LEFT")
                self.perfTexts[idx+1] = DFUI.tools.CreateFont(self.perfFrame, self.TEXT_SIZE, "")
                self.perfTexts[idx+2] = DFUI.tools.CreateFont(self.perfFrame, self.TEXT_SIZE, "")
                self.grid:AddElement(1, line, self.perfTexts[idx])
                self.grid:AddElement(2, line, self.perfTexts[idx+1])
                self.grid:AddElement(3, line, self.perfTexts[idx+2])
            end
            self.perfTexts[idx]:SetText(entry.name)
            self.perfTexts[idx+1]:SetText(string.format("%.2f", entry.data.time * 1000))
            self.perfTexts[idx+2]:SetText(string.format("%.1f", entry.data.memory))
            line = line + 1
            idx = idx + 3
        end

        line = line + 1

        for i = 1, table.getn(other) do
            local entry = other[i]
            if not self.perfTexts[idx] then
                self.perfTexts[idx] = DFUI.tools.CreateFont(self.perfFrame, self.TEXT_SIZE, "", nil, "LEFT")
                self.perfTexts[idx+1] = DFUI.tools.CreateFont(self.perfFrame, self.TEXT_SIZE, "")
                self.perfTexts[idx+2] = DFUI.tools.CreateFont(self.perfFrame, self.TEXT_SIZE, "")
                self.grid:AddElement(1, line, self.perfTexts[idx])
                self.grid:AddElement(2, line, self.perfTexts[idx+1])
                self.grid:AddElement(3, line, self.perfTexts[idx+2])
            end
            self.perfTexts[idx]:SetText(entry.name)
            self.perfTexts[idx+1]:SetText(string.format("%.2f", entry.data.time * 1000))
            self.perfTexts[idx+2]:SetText(string.format("%.1f", entry.data.memory))
            line = line + 1
            idx = idx + 3
        end
    end

    function Setup:ActiveScripts()
        if not self.scripts then
            self.scriptsFrame = CreateFrame("Frame", nil, panel)
            self.scriptsFrame:SetHeight(1)
            self.scriptsFrame:SetWidth(300)
            self.grid:AddElement(5, 17 + self.AREA_LINE, self.scriptsFrame)
            self.grid:AddElement(5, 16 + self.AREA_LINE, DFUI.tools.CreateCategoryHeader(nil, "活跃脚本"))
            self.grid:AddElement(4, 18 + self.AREA_LINE, DFUI.tools.CreateCategoryHeader(nil, "脚本", nil, 100))
            self.grid:AddElement(6, 18 + self.AREA_LINE, DFUI.tools.CreateCategoryHeader(nil, "状态", nil, 100))
            T.GradientLine(self.scriptsFrame, "TOP", 35)
            T.GradientLine(self.scriptsFrame, "TOP", -5)
            self.scripts = true
        end

        local totalScripts = 0
        local activeCount = 0
        for _, status in pairs(DFUI.activeScripts) do
            totalScripts = totalScripts + 1
            if status then
                activeCount = activeCount + 1
            end
        end

        local line = 20 + self.AREA_LINE
        if not self.totalText then
            self.totalText = DFUI.tools.CreateFont(self.scriptsFrame, self.TEXT_SIZE, "TOTAL:", {1, 0.5, 0.5}, "LEFT")
            self.grid:AddElement(4, line, self.totalText)
        end
        if not self.totalCountText then
            self.totalCountText = DFUI.tools.CreateFont(self.scriptsFrame, self.TEXT_SIZE, "", {0.5, 1, 0.5})
            self.grid:AddElement(6, line, self.totalCountText)
        end
        self.totalCountText:SetText(activeCount .. " / " .. totalScripts)
        line = line + 2

        local gui = {}
        local other = {}

        for scriptName, status in pairs(DFUI.activeScripts) do
            if string.upper(string.sub(scriptName, 1, 3)) == "GUI" then
                table.insert(gui, scriptName)
            else
                table.insert(other, scriptName)
            end
        end

        table.sort(gui)
        table.sort(other)

        local index = 1

        for i = 1, table.getn(gui) do
            local scriptName = gui[i]
            local scriptText = self.scriptTexts[index]
            if not scriptText then
                scriptText = DFUI.tools.CreateFont(self.scriptsFrame, self.TEXT_SIZE, "", nil, "LEFT")
                self.scriptTexts[index] = scriptText
            end
            self.grid:AddElement(4, line, scriptText)
            scriptText:Show()

            local statusText = self.statusTexts[index]
            if not statusText then
                statusText = DFUI.tools.CreateFont(self.scriptsFrame, self.TEXT_SIZE, "", nil)
                self.statusTexts[index] = statusText
            end
            self.grid:AddElement(6, line, statusText)
            statusText:Show()

            scriptText:SetText(scriptName)
            scriptText:SetTextColor(1, 1, 1)

            statusText:SetText(DFUI.activeScripts[scriptName] and "ON" or "OFF")
            statusText:SetTextColor(DFUI.activeScripts[scriptName] and 0 or 0.5, DFUI.activeScripts[scriptName] and 1 or 0.5, DFUI.activeScripts[scriptName] and 0 or 0.5)

            index = index + 1
            line = line + 1
        end

        line = line + 1

        for i = 1, table.getn(other) do
            local scriptName = other[i]
            local scriptText = self.scriptTexts[index]
            if not scriptText then
                scriptText = DFUI.tools.CreateFont(self.scriptsFrame, self.TEXT_SIZE, "", nil, "LEFT")
                self.scriptTexts[index] = scriptText
            end
            self.grid:AddElement(4, line, scriptText)
            scriptText:Show()

            local statusText = self.statusTexts[index]
            if not statusText then
                statusText = DFUI.tools.CreateFont(self.scriptsFrame, self.TEXT_SIZE, "", nil)
                self.statusTexts[index] = statusText
            end
            self.grid:AddElement(6, line, statusText)
            statusText:Show()

            scriptText:SetText(scriptName)
            scriptText:SetTextColor(1, 1, 1)

            statusText:SetText(DFUI.activeScripts[scriptName] and "ON" or "OFF")
            statusText:SetTextColor(DFUI.activeScripts[scriptName] and 0 or 0.5, DFUI.activeScripts[scriptName] and 1 or 0.5, DFUI.activeScripts[scriptName] and 0 or 0.5)

            index = index + 1
            line = line + 1
        end

        for i = index, table.getn(self.scriptTexts) do
            if self.scriptTexts[i] then
                self.scriptTexts[i]:Hide()
            end
            if self.statusTexts[i] then
                self.statusTexts[i]:Hide()
            end
        end
    end

    --=================
    -- INIT
    --=================
    function Setup:Run()
        Setup.grid:Init()
        Setup:DFInfo()
        Setup:ActiveScripts()
    end

    Setup:Run()

    --=================
    -- EVENT
    --=================
    local f = CreateFrame("Frame")
    local lastUpdate = 0
    local perfDone = false
    f:SetScript("OnUpdate", function()
        -- 仅在面板可见时运行，避免不必要的 CPU 消耗
        if panel and not panel:IsVisible() then return end
        local time = GetTime()
        if time - lastUpdate >= Setup.UPDATE_INTERVAL then
            Setup:ActiveScripts()
            if not perfDone then
                Setup:Performance()
                Setup:SupportedAddons()
                perfDone = true
            end
            lastUpdate = time
        end
    end)
end)