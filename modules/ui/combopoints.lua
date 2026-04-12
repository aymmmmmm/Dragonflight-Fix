DFUI:NewDefaults("ComboPoints", {
    enabled = {true, "checkbox", nil, nil, "连击点", 1, "启用自定义连击点显示", nil, nil},
    scale = {1, "slider", {0.5, 2, 0.1}, nil, "连击点", 2, "缩放大小", nil, nil},
    color = {{1, 0.8, 0}, "colour", nil, nil, "连击点", 3, "连击点颜色", nil, nil},
    yOffset = {-100, "slider", {-300, 300, 1}, nil, "连击点", 4, "Y轴偏移", nil, nil},
})

DFUI:NewMod("ComboPoints", 1, function()
    local setup = DFUI.tempDB.ComboPoints
    if not setup.enabled then return end

    local TEX_PATH = 'Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\generic\\'
    local POINT_SIZE = 30
    local POINT_SPACING = 35
    local frames = {}

    -- 隐藏原生连击点
    ComboFrame:Hide()
    ComboFrame:SetScript("OnShow", function() this:Hide() end)

    -- 创建容器
    local container = CreateFrame("Frame", "DFUI_ComboPoints", UIParent)
    container:SetWidth(175)
    container:SetHeight(POINT_SIZE)
    container:SetPoint("CENTER", UIParent, "CENTER", 0, setup.yOffset)
    container:SetFrameStrata("HIGH")

    -- 创建 5 个连击点
    for i = 1, 5 do
        local f = CreateFrame("Frame", "DFUI_ComboPoint" .. i, container)
        f:SetWidth(POINT_SIZE)
        f:SetHeight(POINT_SIZE)
        f:SetPoint("CENTER", container, "CENTER", (i - 3) * POINT_SPACING, 0)

        f.empty = f:CreateTexture(nil, "ARTWORK")
        f.empty:SetAllPoints(f)
        f.empty:SetTexture(TEX_PATH .. "combo_empty.blp")

        f.full = f:CreateTexture(nil, "OVERLAY")
        f.full:SetAllPoints(f)
        f.full:SetTexture(TEX_PATH .. "combo_full.blp")
        f.full:SetVertexColor(setup.color[1], setup.color[2], setup.color[3])
        f.full:Hide()

        f:Hide()
        frames[i] = f
    end

    container:SetScale(setup.scale)

    -- 更新显示
    local lastPoints = -1
    local function UpdateComboPoints()
        local points = GetComboPoints("target")
        if points == lastPoints then return end
        lastPoints = points
        for i = 1, 5 do
            if points == 0 then
                frames[i]:Hide()
            else
                frames[i]:Show()
                if i <= points then
                    frames[i].full:Show()
                else
                    frames[i].full:Hide()
                end
            end
        end
    end

    -- 事件监听
    local updater = CreateFrame("Frame")
    updater:RegisterEvent("PLAYER_COMBO_POINTS")
    updater:RegisterEvent("PLAYER_TARGET_CHANGED")
    updater:RegisterEvent("PLAYER_ENTERING_WORLD")
    updater:SetScript("OnEvent", UpdateComboPoints)

    -- 回调
    DFUI:NewCallbacks("ComboPoints", {
        scale_changed = function(val)
            container:SetScale(val)
        end,
        color_changed = function(val)
            for i = 1, 5 do
                frames[i].full:SetVertexColor(val[1], val[2], val[3])
            end
        end,
        yOffset_changed = function(val)
            container:ClearAllPoints()
            container:SetPoint("CENTER", UIParent, "CENTER", 0, val)
        end,
    })
end)
