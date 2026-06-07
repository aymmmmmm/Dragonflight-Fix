DFUI:NewDefaults("Gui-assist", {
    enabled = { true },
})

DFUI:NewMod("Gui-assist", 3, function()
    local TAB = 17
    DFUI.Assist.tabIndex = TAB

    local SS = DFUI.tools.ScaledSize
    local fontPath = DFUI:GetInfoOrCons("font")
    local L = DFUI.Assist.L

    local DESC_COLOR = { 1, 0.82, 0 }
    local GOLD = { 1, 0.82, 0 }
    local PANEL_WIDTH = 680
    local PANEL_INSET = 15
    local ROW_H = 42

    -- 分组：key 前缀 -> 标题
    local GROUPS = {
        { prefix = "auto", title = L["grpAuto"] },
        { prefix = "safe", title = L["grpSafety"] },
        { prefix = "ui",   title = L["grpUI"] },
    }

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

    -- 复选框行：读写 DFUI 档案 Assist 段；即时同步运行时 db
    local function AddCheckboxRow(catPanel, innerY, key, label, desc)
        local cb = DFUI.tools.CreateIndiCheckbox(catPanel, nil, label)
        cb:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -innerY)
        cb:SetChecked(DFUI:GetTempDB("Assist", key))
        cb:SetScript("OnClick", function()
            local v = this:GetChecked() and true or false
            DFUI:SetTempDB("Assist", key, v)
            if DFUI.Assist.db then DFUI.Assist.db[key] = v end
        end)
        if desc then
            local d = DFUI.tools.CreateFont(catPanel, 10, desc, DESC_COLOR, "LEFT")
            d:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET + 28, -(innerY + 20))
        end
        return cb
    end

    local function rollModeText()
        local m = DFUI:GetTempDB("Assist", "rollMode") or 2
        if m == 1 then return L["rollMode"] .. ": " .. L["rollNeed"] end
        if m == 0 then return L["rollMode"] .. ": " .. L["rollPass"] end
        return L["rollMode"] .. ": " .. L["rollGreed"]
    end

    local function BuildPanel()
        if DFUI.Assist.guiBuilt then return end
        local Base = DFUI.gui.Base
        if not Base or not Base.scrollChildren then return end
        local panel = Base.scrollChildren[TAB]
        if not panel then return end
        DFUI.Assist.guiBuilt = true

        -- 页标题由 DFUI base.lua 的 panelTitle 统一显示（SelectTab 设为 tab 名），此处不再自画
        local yPos = 12

        -- 重载界面按钮（右上角，兜底需重载才生效的更改，如模块管理页启停）
        local reloadBtn = DFUI.tools.CreateButton(panel, "重载界面", 100, 20, false, GOLD)
        reloadBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -20, -10)
        reloadBtn:SetScript("OnClick", function() ReloadUI() end)

        T.GradientLine(panel, "TOP", -yPos, 1, 500)
        yPos = yPos + 16

        -- 总开关 masterOn
        local master = DFUI.tools.CreateIndiCheckbox(panel, nil, L["masterOn"])
        master:SetPoint("TOPLEFT", panel, "TOPLEFT", 60, -yPos)
        master:SetChecked(DFUI:GetTempDB("Assist", "masterOn") ~= false)
        master:SetScript("OnClick", function()
            local v = this:GetChecked() and true or false
            DFUI:SetTempDB("Assist", "masterOn", v)
            if DFUI.Assist.db then DFUI.Assist.db.masterOn = v end
        end)
        yPos = yPos + 36

        -- 各分组
        for gi = 1, table.getn(GROUPS) do
            local grp = GROUPS[gi]

            local members = {}
            for i = 1, table.getn(DFUI.Assist.order) do
                local key = DFUI.Assist.order[i]
                if string.find(key, "^" .. grp.prefix) then
                    table.insert(members, key)
                end
            end

            if table.getn(members) > 0 then
                local catHeight = 44 + table.getn(members) * ROW_H + 10
                local catPanel = CreateCategoryPanel(panel, PANEL_WIDTH, catHeight)
                catPanel:SetPoint("TOP", panel, "TOP", 0, -yPos)

                local catTitle = catPanel:CreateFontString(nil, "OVERLAY")
                catTitle:SetFont(fontPath .. "BigNoodleTitling.ttf", SS(16), "OUTLINE")
                catTitle:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -10)
                catTitle:SetText(grp.title)
                catTitle:SetTextColor(GOLD[1], GOLD[2], GOLD[3])

                local sep = catPanel:CreateTexture(nil, "ARTWORK")
                sep:SetTexture("Interface\\Buttons\\WHITE8X8")
                sep:SetHeight(1)
                sep:SetWidth(PANEL_WIDTH - 30)
                sep:SetPoint("TOPLEFT", catPanel, "TOPLEFT", PANEL_INSET, -34)
                sep:SetVertexColor(0.48, 0.33, 0.09, 0.25)

                local iy = 44
                for mi = 1, table.getn(members) do
                    local key = members[mi]
                    local mod = DFUI.Assist.modules[key]
                    local label = (mod and mod.title) or key
                    local desc = mod and mod.desc
                    AddCheckboxRow(catPanel, iy, key, label, desc)

                    -- autoRoll 行右侧加模式切换按钮
                    if key == "autoRoll" then
                        local rb = DFUI.tools.CreateButton(catPanel, rollModeText(), 130, 22, false, GOLD)
                        rb:SetPoint("TOPRIGHT", catPanel, "TOPRIGHT", -PANEL_INSET, -iy)
                        rb:SetScript("OnClick", function()
                            local m = DFUI:GetTempDB("Assist", "rollMode") or 2
                            m = math.mod(m + 1, 3)
                            DFUI:SetTempDB("Assist", "rollMode", m)
                            if DFUI.Assist.db then DFUI.Assist.db.rollMode = m end
                            this:SetText(rollModeText())
                        end)
                    end

                    iy = iy + ROW_H
                end

                yPos = yPos + catHeight + 12
            end
        end

        -- panel 高度 = 实际内容高度，DFUI 滚动条据此自动覆盖（功能增多自动加长）
        panel:SetHeight(yPos + 40)

        -- 若辅助 tab 当前正显示，立即刷新滚动范围，使滚动条即时生效
        local Base2 = DFUI.gui.Base
        if Base2 and Base2.selectedTab == TAB and Base2.scrollFrame then
            Base2.scrollRange = Base2.scrollFrame:GetVerticalScrollRange()
            if Base2.slider then
                Base2.slider:SetMinMaxValues(0, Base2.scrollRange)
            end
        end
    end

    -- 延迟构建（等 base 建好 scrollChildren[17]），仿 superwow.lua
    local f = CreateFrame("Frame")
    f:RegisterEvent("VARIABLES_LOADED")
    f:SetScript("OnEvent", function()
        local wait = CreateFrame("Frame")
        wait.elapsed = 0
        wait:SetScript("OnUpdate", function()
            this.elapsed = this.elapsed + arg1
            if this.elapsed > 0.5 then
                this:SetScript("OnUpdate", nil)
                BuildPanel()
            end
        end)
    end)
end)
