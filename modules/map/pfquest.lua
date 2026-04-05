DFUI:NewDefaults("pfQuestIntegration", {
    enabled = {true, "checkbox", nil, nil, "pfQuest", 1, "启用 pfQuest 快捷按钮（需安装 pfQuest）", nil, nil},
})

DFUI:NewMod("pfQuestIntegration", 1, function()
    local setup = DFUI.tempDB.pfQuestIntegration
    if not setup.enabled then return end

    -- 检测 pfQuest 是否加载
    if not pfBrowser and not pfQuestConfig then return end

    local buttons = {}
    local btnDefs = {
        {
            icon = "Interface\\GossipFrame\\BinderGossipIcon",
            tip = "pfQuest 设置",
            click = function() if pfQuestConfig then pfQuestConfig:Show() end end,
        },
        {
            icon = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
            tip = "清除路径点",
            click = function() if pfMap then pfMap:DeleteNode("PFDB"); pfMap:UpdateNodes() end end,
        },
        {
            icon = "Interface\\Minimap\\Tracking\\None",
            tip = "pfQuest 搜索",
            click = function() if pfBrowser then pfBrowser:Show() end end,
        },
    }

    for i, def in ipairs(btnDefs) do
        local btn = CreateFrame("Button", "DFUI_pfQuest_" .. i, Minimap)
        btn:SetWidth(16)
        btn:SetHeight(16)
        btn:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", (i - 1) * 20 + 5, -20)
        btn:SetFrameStrata("MEDIUM")

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(btn)
        tex:SetTexture(def.icon)
        btn.tex = tex

        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(btn)
        hl:SetTexture(def.icon)
        hl:SetBlendMode("ADD")

        btn:SetScript("OnClick", def.click)
        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(btn, "ANCHOR_BOTTOMLEFT")
            GameTooltip:SetText(def.tip, 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        buttons[i] = btn
    end
end)
