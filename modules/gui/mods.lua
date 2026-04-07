DFUI:NewDefaults("Gui-mods", {
    enabled = {true},

})

DFUI:NewMod("Gui-mods", 3, function()
    --=================
    -- SETUP
    --=================
    local Base = DFUI.gui.Base
    local panel = Base.scrollChildren[4]
    local SS = DFUI.tools.ScaledSize
    local fontPath = DFUI:GetInfoOrCons("font")

    local Setup = {
        TEXT_SIZE = 14,
        PANEL_WIDTH = 680,
        PANEL_INSET = 60,
        CHECKBOX_H_SPACING = 135,
        CHECKBOX_V_SPACING = 28,
        CHECKBOXES_PER_ROW = 5,
        CHECKBOX_LEFT_PAD = 15,
        CAT_GAP = 12,
        init = false
    }

    -- 分类定义
    local categories = {
        {name = "单位框架", desc = "玩家、目标、宠物、队伍的血条与Buff显示", modules = {"Player", "Target", "Mini", "Auras", "PVPIcon"}},
        {name = "动作条", desc = "技能栏、球体、距离指示、连击点、冷却数字", modules = {"Bars", "Orbs", "RangeIndicator", "ComboPoints", "Cooldowns"}},
        {name = "常驻UI", desc = "地图、施法条、经验条、菜单、聊天、提示框等", modules = {"Map", "Cast", "Xprep", "Micro", "Chat", "Tooltip", "Bags", "Loot"}},
        {name = "面板皮肤", desc = "为暴雪原版窗口添加巨龙时代风格外观", modules = {"Bank", "Character", "Talents", "Merchant", "Mail", "Trade", "Trainer", "QuestLog", "QuestDialog", "Gossip", "Social", "DressUp", "Help"}, hasSelectAll = true},
        {name = "全局设置", desc = "职业颜色、界面行为、装备对比等全局选项", modules = {"Colors", "Ui", "Frames", "ItemCompare"}},
        {name = "系统", desc = "菜单、插件管理、版本更新、pfQuest集成", modules = {"Menu", "Addons", "UpdateNotifier", "pfQuestIntegration"}},
    }

    -- 创建分类背景面板
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

    function Setup:Modules()
        if self.init then return end
        self.init = true

        local yPos = 10

        -- 页面标题
        local titleFont = panel:CreateFontString(nil, "OVERLAY")
        titleFont:SetFont(fontPath .. "BigNoodleTitling.ttf", SS(22), "OUTLINE")
        titleFont:SetPoint("TOP", panel, "TOP", 0, -yPos)
        titleFont:SetText("模块管理")
        titleFont:SetTextColor(1, 0.82, 0)
        yPos = yPos + 28

        -- 描述
        local descFont = DFUI.tools.CreateFont(panel, 13, "启用或禁用各功能模块，更改需要重载界面后生效", {0.54, 0.48, 0.35}, "CENTER")
        descFont:SetPoint("TOP", panel, "TOP", 0, -yPos)
        yPos = yPos + 22

        -- 装饰线
        T.GradientLine(panel, "TOP", -yPos, 1, 500)
        yPos = yPos + 18

        -- 重载按钮
        local reloadBtn = DFUI.tools.CreateButton(panel, "重载界面", 160, 28, false, {1, 0.82, 0})
        reloadBtn:SetPoint("TOP", panel, "TOP", 0, -yPos)
        reloadBtn:SetScript("OnClick", function()
            ReloadUI()
        end)
        yPos = yPos + 42

        -- 装饰线
        T.GradientLine(panel, "TOP", -yPos, 1, 500)
        yPos = yPos + 8

        -- 兜底：未归类模块
        local categorized = {}
        for _, cat in ipairs(categories) do
            for _, modName in ipairs(cat.modules) do
                categorized[modName] = true
            end
        end
        local uncategorized = {}
        for modName, _ in pairs(DFUI.modules) do
            if not categorized[modName] and not string.find(string.upper(modName), "GUI") then
                table.insert(uncategorized, modName)
            end
        end
        if table.getn(uncategorized) > 0 then
            table.sort(uncategorized)
            table.insert(categories, {name = "其他", desc = "未分类的模块", modules = uncategorized})
        end

        -- 渲染各分类
        for catIdx, cat in ipairs(categories) do
            yPos = yPos + self.CAT_GAP

            -- 计算该分类有多少个有效模块
            local validModules = {}
            for mi = 1, table.getn(cat.modules) do
                if DFUI.modules[cat.modules[mi]] then
                    table.insert(validModules, cat.modules[mi])
                end
            end
            local modCount = table.getn(validModules)
            if modCount == 0 then
                -- 跳过空分类
            else
                local totalRows = math.ceil(modCount / self.CHECKBOXES_PER_ROW)

                -- 分类背景面板高度: 标题(30) + 描述(18) + checkbox行 + 内边距
                local panelHeight = 30 + 18 + totalRows * self.CHECKBOX_V_SPACING + 20
                local catPanel = CreateCategoryPanel(panel, self.PANEL_WIDTH, panelHeight)
                catPanel:SetPoint("TOP", panel, "TOP", 0, -yPos)

                -- 分类标题（面板内左上）
                local headerFont = catPanel:CreateFontString(nil, "OVERLAY")
                headerFont:SetFont(fontPath .. "BigNoodleTitling.ttf", SS(16), "OUTLINE")
                headerFont:SetPoint("TOPLEFT", catPanel, "TOPLEFT", 15, -10)
                headerFont:SetText(cat.name)
                headerFont:SetTextColor(1, 0.82, 0)

                -- 模块数量标签
                local countFont = catPanel:CreateFontString(nil, "OVERLAY")
                countFont:SetFont(fontPath .. "BigNoodleTitling.ttf", SS(11), "OUTLINE")
                countFont:SetPoint("LEFT", headerFont, "RIGHT", 8, 0)
                countFont:SetText("(" .. modCount .. ")")
                countFont:SetTextColor(0.54, 0.48, 0.35)

                -- 全选/全不选按钮
                local catCheckboxes = {}
                local catModuleNames = {}

                if cat.hasSelectAll then
                    local toggleBtn = DFUI.tools.CreateButton(catPanel, "全选/全不选", 90, 20, false, {0.91, 0.84, 0.64})
                    toggleBtn:SetPoint("TOPRIGHT", catPanel, "TOPRIGHT", -12, -9)
                    toggleBtn:SetScript("OnClick", function()
                        local allChecked = true
                        for ci = 1, table.getn(catCheckboxes) do
                            if not catCheckboxes[ci]:GetChecked() then
                                allChecked = false
                                break
                            end
                        end
                        local newState = not allChecked
                        for ci = 1, table.getn(catModuleNames) do
                            DFUI:SetTempDBNoCallback(catModuleNames[ci], "enabled", newState)
                        end
                        for ci = 1, table.getn(catCheckboxes) do
                            catCheckboxes[ci]:SetChecked(newState)
                        end
                    end)
                end

                -- 分类描述（标题下方）
                local catDesc = catPanel:CreateFontString(nil, "OVERLAY")
                catDesc:SetFont(fontPath .. "BigNoodleTitling.ttf", SS(11), "OUTLINE")
                catDesc:SetPoint("TOPLEFT", catPanel, "TOPLEFT", 16, -28)
                catDesc:SetText(cat.desc)
                catDesc:SetTextColor(0.54, 0.48, 0.35)

                -- 分隔线（标题+描述 与 checkbox 之间）
                local sepLine = catPanel:CreateTexture(nil, "ARTWORK")
                sepLine:SetTexture("Interface\\Buttons\\WHITE8X8")
                sepLine:SetHeight(1)
                sepLine:SetWidth(self.PANEL_WIDTH - 30)
                sepLine:SetPoint("TOPLEFT", catPanel, "TOPLEFT", 15, -44)
                sepLine:SetVertexColor(0.48, 0.33, 0.09, 0.25)

                -- 渲染 checkbox（在面板内部定位）
                local cbStartY = 52
                for ci = 1, modCount do
                    local modName = validModules[ci]
                    local col = math.mod(ci - 1, self.CHECKBOXES_PER_ROW)
                    local row = math.floor((ci - 1) / self.CHECKBOXES_PER_ROW)

                    local checkbox = DFUI.tools.CreateCheckbox(catPanel, nil, modName, "enabled", true)
                    checkbox.label:SetText(modName)
                    checkbox.label:SetTextColor(0.78, 0.76, 0.71)

                    local xPos = self.CHECKBOX_LEFT_PAD + col * self.CHECKBOX_H_SPACING
                    local yOffset = cbStartY + row * self.CHECKBOX_V_SPACING
                    checkbox:SetPoint("TOPLEFT", catPanel, "TOPLEFT", xPos, -yOffset)

                    if cat.hasSelectAll then
                        table.insert(catCheckboxes, checkbox)
                        table.insert(catModuleNames, modName)
                    end
                end

                yPos = yPos + panelHeight
            end
        end
    end

    --=================
    -- INIT
    --=================
    function Setup:Run()
        Setup:Modules()
    end

    Setup:Run()
end)
