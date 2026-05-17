DFUI:NewDefaults("Gui-bugs", {
    enabled = {true},
})

DFUI:NewMod("Gui-bugs", 5, function()
    --=================
    -- SETUP
    --=================
    local Base = DFUI.gui.Base
    local panel = Base.scrollChildren[16]
    if not panel then return end

    local SS = DFUI.tools.ScaledSize
    local fontPath = DFUI:GetInfoOrCons("font") .. "BigNoodleTitling.ttf"

    local Setup = {
        font = DFUI:GetInfoOrCons("font"),
        grid = DFUI.tools.CreateGrid(panel, 33, 25),

        toolbarFrame = nil,
        listFrame = nil,
        detailFrame = nil,

        rowPool = {},
        ROW_HEIGHT = 18,
        MAX_ROWS_VISIBLE = 30,
        selectedIdx = nil,

        countText = nil,
        cbOnlyDFUI = nil,
        cbAutoToast = nil,
        detailEdit = nil,
    }

    local function isDFUISrc(src)
        return src == "Dragonflight-Fix" or src == "DFUI"
    end

    function Setup:GetVisibleList()
        local prefs = DFUI.errors.prefs
        if prefs.onlyDFUI then
            return DFUI.errors.GetFiltered(true)
        end
        return DFUI.errors.list
    end

    function Setup:UpdateCount()
        local list = DFUI.errors.list
        local total = table.getn(list)
        local dfui = 0
        for i = 1, total do
            if isDFUISrc(list[i].src) then dfui = dfui + 1 end
        end
        if self.countText then
            self.countText:SetText("共 |cffffd100" .. total .. "|r 条    其中 DFUI |cffff5555" .. dfui .. "|r 条")
        end
    end

    function Setup:FillDetail(entry)
        if not self.detailEdit then return end
        if not entry then
            self.detailEdit:SetText("")
            return
        end
        local stamp = entry.date or "??:??:??"
        local body = "[" .. stamp .. "]  ×" .. (entry.n or 1) .. "  来源: " .. (entry.src or "?") .. "\n\n"
            .. (entry.msg or "") .. "\n\n--- Stack ---\n" .. (entry.stack or "(空)")
        self.detailEdit:SetText(body)
        self.detailEdit:HighlightText(0, -1)
        self.detailEdit:SetFocus()
    end

    function Setup:CreateRow()
        local row = CreateFrame("Button", nil, self.listInner)
        row:SetHeight(self.ROW_HEIGHT)
        row:SetWidth(self.listInner:GetWidth())

        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetTexture("Interface\\Buttons\\WHITE8X8")
        hl:SetAllPoints(row)
        hl:SetVertexColor(1, 0.82, 0, 0.15)
        hl:Hide()
        row.selected = hl

        local hover = row:CreateTexture(nil, "HIGHLIGHT")
        hover:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        hover:SetAllPoints(row)
        hover:SetBlendMode("ADD")

        row.timeFS = row:CreateFontString(nil, "OVERLAY")
        row.timeFS:SetFont(fontPath, SS(11), "OUTLINE")
        row.timeFS:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.timeFS:SetWidth(70)
        row.timeFS:SetJustifyH("LEFT")

        row.countFS = row:CreateFontString(nil, "OVERLAY")
        row.countFS:SetFont(fontPath, SS(11), "OUTLINE")
        row.countFS:SetPoint("LEFT", row.timeFS, "RIGHT", 4, 0)
        row.countFS:SetWidth(40)
        row.countFS:SetJustifyH("LEFT")

        row.srcFS = row:CreateFontString(nil, "OVERLAY")
        row.srcFS:SetFont(fontPath, SS(11), "OUTLINE")
        row.srcFS:SetPoint("LEFT", row.countFS, "RIGHT", 4, 0)
        row.srcFS:SetWidth(120)
        row.srcFS:SetJustifyH("LEFT")

        row.msgFS = row:CreateFontString(nil, "OVERLAY")
        row.msgFS:SetFont(fontPath, SS(11), "OUTLINE")
        row.msgFS:SetPoint("LEFT", row.srcFS, "RIGHT", 4, 0)
        row.msgFS:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.msgFS:SetJustifyH("LEFT")
        row.msgFS:SetTextColor(0.7, 0.7, 0.7)

        return row
    end

    function Setup:RefreshList()
        if not self.listInner then return end
        local list = self:GetVisibleList()
        local n = table.getn(list)

        -- 反向显示：最新在最上
        for i = 1, self.MAX_ROWS_VISIBLE do
            local row = self.rowPool[i]
            local entryIdx = n - i + 1
            local entry = list[entryIdx]
            if entry then
                if not row then
                    row = self:CreateRow()
                    row:SetPoint("TOPLEFT", self.listInner, "TOPLEFT", 0, -(i-1) * self.ROW_HEIGHT)
                    row:SetScript("OnClick", function()
                        Setup.selectedIdx = this.entryIdx
                        Setup:FillDetail(this.entry)
                        Setup:RefreshList()
                    end)
                    self.rowPool[i] = row
                end
                row.entry = entry
                row.entryIdx = entryIdx
                row.timeFS:SetText(entry.date or "")
                row.countFS:SetText("×" .. (entry.n or 1))
                row.srcFS:SetText(entry.src or "?")
                if isDFUISrc(entry.src) then
                    row.srcFS:SetTextColor(1, 0.4, 0.4)
                else
                    row.srcFS:SetTextColor(0.7, 0.7, 0.7)
                end
                local short = entry.msg or ""
                if string.len(short) > 60 then
                    short = string.sub(short, 1, 60) .. "..."
                end
                short = string.gsub(short, "\n", " ")
                row.msgFS:SetText(short)
                if Setup.selectedIdx == entryIdx then
                    row.selected:Show()
                else
                    row.selected:Hide()
                end
                row:Show()
            elseif row then
                row:Hide()
            end
        end

        self:UpdateCount()
    end

    function Setup:Toolbar()
        if self.toolbar then return end
        self.toolbarFrame = CreateFrame("Frame", nil, panel)
        self.toolbarFrame:SetWidth(820)
        self.toolbarFrame:SetHeight(110)
        self.toolbarFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -10)

        local title = DFUI.tools.CreateCategoryHeader(nil, "Bug 抓取", nil, 200)
        title:SetParent(self.toolbarFrame)
        title:SetPoint("TOPLEFT", self.toolbarFrame, "TOPLEFT", 0, 0)

        local hint = DFUI.tools.CreateFont(self.toolbarFrame, 11,
            "捕获 Lua 错误，点条目右侧可选中复制 (Ctrl+C)。最近 50 条，跨重载保留。",
            {0.7, 0.7, 0.7}, "LEFT")
        hint:SetPoint("TOPLEFT", self.toolbarFrame, "TOPLEFT", 0, -28)

        -- ============ 第一行：主要操作 ============
        local ROW1_Y = -48
        local btnClear = DFUI.tools.CreateButton(self.toolbarFrame, "清空记录", 90, 22, true, {1, 0.5, 0.5})
        btnClear:SetPoint("TOPLEFT", self.toolbarFrame, "TOPLEFT", 0, ROW1_Y)
        btnClear:SetScript("OnClick", function()
            DFUI.errors.Clear()
            Setup.selectedIdx = nil
            Setup:FillDetail(nil)
            Setup:RefreshList()
        end)

        local btnCopyAll = DFUI.tools.CreateButton(self.toolbarFrame, "复制全部", 90, 22, true, {0.7, 1, 0.7})
        btnCopyAll:SetPoint("TOPLEFT", self.toolbarFrame, "TOPLEFT", 100, ROW1_Y)
        btnCopyAll:SetScript("OnClick", function()
            local list = Setup:GetVisibleList()
            local n = table.getn(list)
            local out = {}
            for i = n, 1, -1 do
                local e = list[i]
                table.insert(out, "[" .. (e.date or "") .. "] x" .. (e.n or 1) .. " " .. (e.src or "?") .. "\n" .. (e.msg or "") .. "\n" .. (e.stack or ""))
            end
            if Setup.detailEdit then
                Setup.detailEdit:SetText(table.concat(out, "\n\n========\n\n"))
                Setup.detailEdit:HighlightText(0, -1)
                Setup.detailEdit:SetFocus()
            end
        end)

        self.cbOnlyDFUI = DFUI.tools.CreateIndiCheckbox(self.toolbarFrame, "DFUIBugCbOnlyDFUI", "只看 DFUI")
        self.cbOnlyDFUI:SetPoint("TOPLEFT", self.toolbarFrame, "TOPLEFT", 210, ROW1_Y)
        self.cbOnlyDFUI:SetChecked(DFUI.errors.prefs.onlyDFUI and true or false)
        self.cbOnlyDFUI:SetScript("OnClick", function()
            DFUI.errors.prefs.onlyDFUI = this:GetChecked() and true or false
            Setup:RefreshList()
        end)

        self.cbAutoToast = DFUI.tools.CreateIndiCheckbox(self.toolbarFrame, "DFUIBugCbAutoToast", "新错误屏幕弹通知")
        self.cbAutoToast:SetPoint("TOPLEFT", self.toolbarFrame, "TOPLEFT", 330, ROW1_Y)
        self.cbAutoToast:SetChecked(DFUI.errors.prefs.autoToast and true or false)
        self.cbAutoToast:SetScript("OnClick", function()
            DFUI.errors.prefs.autoToast = this:GetChecked() and true or false
        end)

        self.countText = DFUI.tools.CreateFont(self.toolbarFrame, 12, "", {0.7, 0.7, 0.7}, "LEFT")
        self.countText:SetPoint("TOPRIGHT", self.toolbarFrame, "TOPRIGHT", -10, -5)

        -- ============ 第二行：诊断 ============
        local ROW2_Y = -78
        local diagLabel = DFUI.tools.CreateFont(self.toolbarFrame, 11, "诊断:", {1, 0.82, 0}, "LEFT")
        diagLabel:SetPoint("TOPLEFT", self.toolbarFrame, "TOPLEFT", 0, ROW2_Y - 4)

        local btnTestReal = DFUI.tools.CreateButton(self.toolbarFrame, "测试·触发", 90, 22, true, {0.7, 0.9, 1})
        btnTestReal:SetPoint("TOPLEFT", self.toolbarFrame, "TOPLEFT", 40, ROW2_Y)
        btnTestReal:SetScript("OnClick", function()
            local stamp = GetTime()
            local h = geterrorhandler and geterrorhandler()
            local isOurs = (h == DFUI.errors._handler)
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd100DFUI 诊断:|r 当前错误处理器=" .. (isOurs and "|cff00ff00我方|r" or "|cffff0000被劫持|r"))
            if h then h("DFUI test (via handler) " .. stamp) end
        end)

        local btnTestDirect = DFUI.tools.CreateButton(self.toolbarFrame, "测试·直写", 90, 22, true, {1, 0.9, 0.5})
        btnTestDirect:SetPoint("TOPLEFT", self.toolbarFrame, "TOPLEFT", 140, ROW2_Y)
        btnTestDirect:SetScript("OnClick", function()
            if DFUI.errors.TestRecord then
                DFUI.errors.TestRecord("DFUI-Test", "DFUI 直写测试 " .. GetTime())
            end
        end)

        local btnReclaim = DFUI.tools.CreateButton(self.toolbarFrame, "抢回处理器", 100, 22, true, {1, 0.5, 0.5})
        btnReclaim:SetPoint("TOPLEFT", self.toolbarFrame, "TOPLEFT", 240, ROW2_Y)
        btnReclaim:SetScript("OnClick", function()
            if DFUI.errors.Reclaim then
                DFUI.errors.Reclaim()
                DEFAULT_CHAT_FRAME:AddMessage("|cffffd100DFUI:|r 已重新抢回 seterrorhandler")
            end
        end)

        T.GradientLine(self.toolbarFrame, "BOTTOM", -5)

        self.toolbar = true
    end

    function Setup:ListPanel()
        if self.listBuilt then return end
        local container = CreateFrame("Frame", nil, panel)
        container:SetWidth(420)
        container:SetHeight(self.ROW_HEIGHT * self.MAX_ROWS_VISIBLE + 30)
        container:SetPoint("TOPLEFT", self.toolbarFrame, "BOTTOMLEFT", 0, -10)

        local header = DFUI.tools.CreateCategoryHeader(nil, "错误列表", nil, 180)
        header:SetParent(container)
        header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)

        local colHeader = container:CreateFontString(nil, "OVERLAY")
        colHeader:SetFont(fontPath, SS(11), "OUTLINE")
        colHeader:SetPoint("TOPLEFT", container, "TOPLEFT", 4, -28)
        colHeader:SetText("|cffffd100时间        计数    来源              消息|r")

        self.listInner = CreateFrame("Frame", nil, container)
        self.listInner:SetWidth(420)
        self.listInner:SetHeight(self.ROW_HEIGHT * self.MAX_ROWS_VISIBLE)
        self.listInner:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -46)

        self.listFrame = container
        self.listBuilt = true
    end

    function Setup:DetailPanel()
        if self.detailBuilt then return end
        local container = CreateFrame("Frame", nil, panel)
        container:SetWidth(380)
        container:SetHeight(self.ROW_HEIGHT * self.MAX_ROWS_VISIBLE + 30)
        container:SetPoint("TOPLEFT", self.toolbarFrame, "BOTTOMLEFT", 440, -10)

        local header = DFUI.tools.CreateCategoryHeader(nil, "详情 (Ctrl+A 全选 / Ctrl+C 复制)", nil, 280)
        header:SetParent(container)
        header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)

        local scroll = CreateFrame("ScrollFrame", "DFUIBugDetailScroll", container)
        scroll:SetWidth(380)
        scroll:SetHeight(self.ROW_HEIGHT * self.MAX_ROWS_VISIBLE - 30)
        scroll:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -28)
        scroll:EnableMouseWheel(true)
        scroll:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        scroll:SetBackdropColor(0, 0, 0, 0.5)
        scroll:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        local edit = CreateFrame("EditBox", "DFUIBugDetailEdit", scroll)
        edit:SetMultiLine(true)
        edit:SetMaxLetters(99999)
        edit:SetWidth(360)
        edit:SetHeight(self.ROW_HEIGHT * self.MAX_ROWS_VISIBLE - 30)
        edit:SetFontObject(ChatFontNormal)
        edit:SetTextColor(1, 1, 1)
        edit:SetAutoFocus(false)
        edit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        edit:SetScript("OnTextChanged", function()
            local sf = scroll
            local h = this:GetHeight()
            if h then sf:UpdateScrollChildRect() end
        end)
        scroll:SetScrollChild(edit)

        scroll:SetScript("OnMouseWheel", function()
            local cur = this:GetVerticalScroll()
            local delta = arg1 * 20
            local newPos = cur - delta
            if newPos < 0 then newPos = 0 end
            local max = this:GetVerticalScrollRange()
            if newPos > max then newPos = max end
            this:SetVerticalScroll(newPos)
        end)

        self.detailEdit = edit
        self.detailBuilt = true
    end

    --=================
    -- INIT
    --=================
    function Setup:Run()
        Setup:Toolbar()
        Setup:ListPanel()
        Setup:DetailPanel()
        Setup:RefreshList()

        DFUI.errors.Subscribe(function()
            Setup:RefreshList()
        end)
    end

    Setup:Run()

    -- 加载确认（用户在聊天框能看到这行说明 bugs.lua 完整跑完）
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100DFUI:|r 诊断面板已加载 (Bug 抓取 v2)")
    end
end)
