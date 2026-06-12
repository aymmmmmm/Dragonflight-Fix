-- worldmap.lua — 世界地图(WorldMapFrame) DF 化重构
-- 目标：金属外框做大 + CreateRetailInset 凹陷承载地图 + 顶部「世界›大陆›区域」面包屑；范围仅地图本体
-- 策略：overlay 叠加（绝不 reparent WorldMapButton / 绝不 KillFrame WorldMapFrame），
--       延迟 1s 初始化等 ShaguTweaks(字母序 S>D，后加载) 的窗口化/缩放跑完再套皮。
--       配方仿 spellbook.lua / talents.lua：金属框(CreatePaperDollFrame 金属+岩石) 比地图大一圈，
--       凹陷区(CreateRetailInset)框住地图、地图嵌凹陷里，凹陷外顶部栏放面包屑。
-- 历史：2026-04-17 首次失败回退 + 本轮前 4 版"边框贴地图"皆不对，详见 docs/worldmap-panel-design.md。

-- setfenv 守卫：core 未加载时给可读警告而非沉默崩溃（仿 tradeskill.lua）
if not (DFUI and DFUI.GetEnv) then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4040[DFUI-worldmap]|r DFUI core not loaded, abort worldmap module")
    return
end
setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")

DFUI:NewDefaults("WorldMap", {
    enabled = {true},
})

DFUI:NewMod("WorldMap", 6, function()
    -- 隐藏暴雪地图 chrome + 冗余导航控件（面包屑已替代）：
    --  · 12 块框架背景纸(WorldMapFrameTexture, UI-WorldMap-*) + 8 块最小化边框：地形底图在
    --    WorldMapDetailFrame 子框、不在这 20 个里，隐藏它们不动地形（阶段0 实证）。SetAlpha(0) 防 Show 恢复。
    --  · 大陆/地区下拉框：SetAlpha(0)+EnableMouse(false) 隐藏但保 API（pfQuest 可能依赖其存在）。
    --  · 缩小/放大镜按钮：Hide。
    local function hideChrome()
        for i = 1, 12 do
            local t = getglobal("WorldMapFrameTexture" .. i)
            if t then t:SetAlpha(0) end
        end
        for i = 1, 8 do
            local t = getglobal("WorldMapFrameMinimizedTexture" .. i)
            if t then t:SetAlpha(0) end
        end
        local dd = { "WorldMapContinentDropDown", "WorldMapZoneDropDown" }
        for j = 1, table.getn(dd) do
            local d = getglobal(dd[j])
            if d then d:SetAlpha(0); d:EnableMouse(false) end
        end
        local bt = { "WorldMapZoomOutButton", "WorldMapMagnifyingGlassButton" }
        for j = 1, table.getn(bt) do
            local b = getglobal(bt[j])
            if b then b:Hide() end
        end
    end

    -- 套皮入口：延迟后执行，确保 ShaguTweaks 已对地图做完窗口化/缩放
    local function ApplyWorldMapSkin()
        -- 兼容门：存在第三方完整地图替换插件时让路（与 ShaguTweaks 同门）
        if Cartographer or METAMAP_TITLE then return end
        if not WorldMapFrame or not WorldMapButton then return end
        if WorldMapFrame._dfWorldMapSkinned then return end  -- 幂等守卫
        WorldMapFrame._dfWorldMapSkinned = true

        -- 1) 隐藏暴雪 chrome + 冗余导航控件
        hideChrome()

        -- 几何参数（按实测微调）
        local SIDE, BOTM, TOPH = 22, 22, 54   -- 金属框相对地图的 左右/底/顶 外扩（顶部多留给面包屑栏）
        local INSET_OUT = 8                    -- 凹陷区比地图大多少（凹陷描边在地图外圈露出）
        local baseLevel = WorldMapFrame:GetFrameLevel()  -- 金属框/凹陷取此 level（低于地图子框，地图盖在其上）

        -- 2) 金属外框：CreatePaperDollFrame(2) 金属边 + 岩石底，做大一圈不贴地图。
        --    frame level 低于地图 → 金属边只在地图外侧露、岩石底只在凹陷外(顶部栏+四周)露，不盖地形。
        local frame = DFUI.CreatePaperDollFrame("DFUI_WorldMapBg", WorldMapFrame, 100, 100, 2)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", WorldMapButton, "TOPLEFT", -SIDE, TOPH)
        frame:SetPoint("BOTTOMRIGHT", WorldMapButton, "BOTTOMRIGHT", SIDE, -BOTM)
        frame:SetFrameLevel(baseLevel)
        frame:EnableMouse(false)
        -- 保留 frame.Bg 岩石（用户要"金属+岩石"）

        -- 3) 凹陷承载区：CreateRetailInset 框住地图（比地图大 INSET_OUT，凹陷描边在地图外圈露出）。
        --    inset level 低于地图 → 地图盖凹陷底中央、凹陷四边描线在地图四周露 = "地图嵌凹陷"。
        local inset = DFUI.CreateRetailInset(frame, {
            name = "DFUI_WorldMapInset",
            bg = "interface\\UI-Background-Rock.blp",
        })
        inset:ClearAllPoints()
        inset:SetPoint("TOPLEFT", WorldMapButton, "TOPLEFT", -INSET_OUT, INSET_OUT)
        inset:SetPoint("BOTTOMRIGHT", WorldMapButton, "BOTTOMRIGHT", INSET_OUT, -INSET_OUT)
        inset:SetFrameLevel(baseLevel)
        inset:Show()  -- CreateRetailInset 默认 Hide（未传 followFrame），必须手动显示
        if inset.bg then inset.bg:SetVertexColor(0.35, 0.32, 0.28) end  -- 暗岩石凹槽

        -- 4) 顶部面包屑导航（凹陷区上方的金属横梁/岩石条里，不盖地图）
        local CRUMB_PAD = 12
        local crumbBar = CreateFrame("Frame", "DFUI_WorldMapCrumb", frame)
        crumbBar:SetFrameLevel(frame:GetFrameLevel() + 6)  -- 抬到金属边之上
        crumbBar:SetHeight(22)
        crumbBar:SetWidth(560)
        crumbBar:EnableMouse(false)
        crumbBar:SetPoint("TOPLEFT", frame, "TOPLEFT", SIDE + 6, -26)  -- 横梁下方；位置待实测微调

        local crumbBtns, crumbSeps = {}, {}
        local function getBtn(i)
            if not crumbBtns[i] then
                crumbBtns[i] = DFUI.CreateActionButton(crumbBar, 60, "", function(self)
                    if self.dfClick then self.dfClick() end
                end, 20)
            end
            return crumbBtns[i]
        end
        local function getSep(i)
            if not crumbSeps[i] then
                local s = crumbBar:CreateFontString(nil, "OVERLAY")
                s:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
                s:SetTextColor(1.0, 0.82, 0.0)
                s:SetText("›")
                crumbSeps[i] = s
            end
            return crumbSeps[i]
        end

        local function refreshCrumb()
            for i = 1, table.getn(crumbBtns) do crumbBtns[i]:Hide() end
            for i = 1, table.getn(crumbSeps) do crumbSeps[i]:Hide() end

            local conts = { GetMapContinents() }
            local cid = GetCurrentMapContinent()
            local mid = GetCurrentMapZone()

            -- 构建层级路径节点 {label, click, cur(=当前级)}
            local nodes = {}
            table.insert(nodes, { label = "世界", cur = (not cid or cid <= 0),
                click = function() SetMapZoom(0) end })
            if cid and cid > 0 then
                table.insert(nodes, { label = conts[cid] or "大陆", cur = (not mid or mid <= 0),
                    click = function() SetMapZoom(cid) end })
            end
            if cid and cid > 0 and mid and mid > 0 then
                local zones = { GetMapZones(cid) }
                table.insert(nodes, { label = zones[mid] or "区域", cur = true, click = nil })
            end

            -- 从左到右排布
            local prev = nil
            for i = 1, table.getn(nodes) do
                local n = nodes[i]
                local b = getBtn(i)
                b.label:SetText(n.label)
                local w = (DFUI.MeasureWidth and DFUI.MeasureWidth(n.label)) or (string.len(n.label) * 8)
                b:SetWidth(w + CRUMB_PAD * 2)
                b.dfClick = n.click
                b:SetEnabledDF(not n.cur)  -- 当前级暗显不可点（"你在这里"）
                b:ClearAllPoints()
                if prev then
                    local sep = getSep(i - 1)
                    sep:ClearAllPoints()
                    sep:SetPoint("LEFT", prev, "RIGHT", 4, 0)
                    sep:Show()
                    b:SetPoint("LEFT", sep, "RIGHT", 4, 0)
                else
                    b:SetPoint("LEFT", crumbBar, "LEFT", 0, 0)
                end
                b:Show()
                prev = b
            end
        end

        local cf = CreateFrame("Frame")
        cf:RegisterEvent("WORLD_MAP_UPDATE")  -- 切大陆/区域：刷面包屑 + 重压 chrome/下拉框
        cf:SetScript("OnEvent", function() refreshCrumb(); hideChrome() end)
        refreshCrumb()  -- 初始构建

        -- 5) OnShow 兜底重压 chrome（vanilla 重开可能把背景纸/下拉框 Show 回来）
        local old = WorldMapFrame:GetScript("OnShow")
        WorldMapFrame:SetScript("OnShow", function()
            if old then old() end
            hideChrome()
        end)
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        f:UnregisterEvent("PLAYER_ENTERING_WORLD")
        local elapsed = 0
        f:SetScript("OnUpdate", function()
            elapsed = elapsed + arg1  -- 1.12 OnUpdate 经全局 arg1 传 elapsed
            if elapsed < 1.0 then return end
            f:SetScript("OnUpdate", nil)
            ApplyWorldMapSkin()
        end)
    end)
end)
