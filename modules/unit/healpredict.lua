-- ═══════════════════════════════════════════════════════════════
-- 治疗预读 (Incoming Heal Prediction) 表现层
-- 数据来自 libs/libpredict.lua, 这里只负责节流轮询 + 往血条上刷值
-- ═══════════════════════════════════════════════════════════════

DFUI:NewDefaults("HealPredict", {
    enabled = {true},

    showPlayer = {true, "checkbox", nil, nil, "显示范围", 1, "在玩家框架显示治疗预读", nil, nil},
    showTarget = {true, "checkbox", nil, nil, "显示范围", 2, "在目标框架显示治疗预读", "只有自己、宠物、小队和团队成员才有绝对血量, 其他目标(怪物/非小队玩家)不会显示", nil},
    showParty = {true, "checkbox", nil, nil, "显示范围", 3, "在小队框架显示治疗预读", nil, nil},
    showFocus = {true, "checkbox", nil, nil, "显示范围", 4, "在焦点框架显示治疗预读", nil, nil},

    predictColor = {{0, 1, 0}, "colour", nil, nil, "外观", 5, "预读条颜色", nil, nil},
    predictAlpha = {0.6, "slider", {0.2, 1, 0.05}, nil, "外观", 6, "预读条透明度", nil, nil},
    predictOverheal = {20, "slider", {0, 25, 1}, nil, "外观", 7, "允许超出满血线的百分比", "设为 0 则预读条不会画到血条外面", nil},
})

DFUI:NewMod("HealPredict", 2, function()
    -- 数据层没加载(例如 libpredict.lua 有语法错) → 静默软失败, 不拖垮别的模块
    local lib = DFUI_Libs and DFUI_Libs.libpredict
    if not lib then return end

    local bars = DFUI.predictBars
    local SLOTS = {"player", "target", "party1", "party2", "party3", "party4"}
    local slotEnabled = {}

    local INTERVAL = 0.1
    local acc = 0

    local function CurrentColor()
        local c = DFUI:GetTempDB("HealPredict", "predictColor") or {0, 1, 0}
        local a = DFUI:GetTempDB("HealPredict", "predictAlpha")
        if a == nil then a = 0.6 end
        return c, a
    end

    local function EnsureLayer(bar)
        if not bar then return nil end
        if not bar.predict then
            bar:EnablePrediction()
            -- 惰性创建的条(血条若晚于本模块建立)要立刻补上当前配置,
            -- 否则会一直用工厂默认色, 直到用户手动动一次设置
            local c, a = CurrentColor()
            bar:SetPredictionColor(c[1], c[2], c[3], a)
            bar:SetPredictionOverheal(DFUI:GetTempDB("HealPredict", "predictOverheal") or 20)
        end
        return bar
    end

    local function ApplyOne(bar, unit)
        if not EnsureLayer(bar) then return end

        if not unit or not UnitExists(unit) then
            bar:SetPrediction(0)
            return
        end

        -- ★ 量纲守卫: 预读量是绝对值, 而 1.12 里只有自己/宠物/小队/团队
        -- 的 UnitHealth 才是绝对值, 其余单位返回的是 0-100 百分比。
        -- 不守就会用 amount/100 算出爆炸宽度。
        local trueUnit = DFUI.ResolveToTrueUnit and DFUI.ResolveToTrueUnit(unit)
        if not trueUnit then
            bar:SetPrediction(0)
            return
        end

        if UnitIsDeadOrGhost(trueUnit) or not UnitIsConnected(trueUnit) then
            bar:SetPrediction(0)
            return
        end

        local maxHP = UnitHealthMax(trueUnit)
        if not maxHP or maxHP <= 0 then
            bar:SetPrediction(0)
            return
        end

        bar:SetPrediction(lib:UnitGetIncomingHeals(trueUnit) or 0)
    end

    -- ═══ 轮询器 ═══
    -- libpredict 不发事件(预读量的变化与血量无关: 别人开始/取消施法、预读到期
    -- 都不会触发 UNIT_HEALTH), 所以只能轮询。但血条几何由 bar:Update() 自动
    -- 带着预读条走, 轮询只负责刷数值, 很轻。
    local poller = CreateFrame("Frame")
    poller:Hide()
    poller:SetScript("OnUpdate", function()
        acc = acc + (arg1 or 0)     -- 1.12: OnUpdate 的 elapsed 在全局 arg1
        if acc < INTERVAL then return end
        acc = 0

        lib:Sweep()

        for i = 1, table.getn(SLOTS) do
            local slot = SLOTS[i]
            if slotEnabled[slot] then ApplyOne(bars[slot], slot) end
        end
        if slotEnabled.focus then ApplyOne(bars.focus, DFUI.predictFocus) end

        -- 没有任何预读在途了就睡掉。注意上面这一轮已经把所有条 SetPrediction(0),
        -- 不会留残条。
        if not lib:HasAny() then
            DFUI.activeScripts["HealPredictPoller"] = false
            poller:Hide()
        end
    end)

    DFUI.activeScripts["HealPredictPoller"] = false

    -- 收到/发出任何预读时唤醒
    lib.OnHealAdded = function()
        DFUI.activeScripts["HealPredictPoller"] = true
        poller:Show()
    end

    -- ═══ 配置 ═══

    local function SetSlot(slot, on)
        slotEnabled[slot] = (on and true) or false
        if not on then
            local bar = bars[slot]
            if bar and bar.predict then bar:SetPrediction(0) end
        end
    end

    local function ApplyColor()
        local c, a = CurrentColor()
        for _, bar in pairs(bars) do
            if EnsureLayer(bar) then bar:SetPredictionColor(c[1], c[2], c[3], a) end
        end
    end

    local callbacks = {
        showPlayer = function(value) SetSlot("player", value) end,
        showTarget = function(value) SetSlot("target", value) end,
        showFocus  = function(value) SetSlot("focus", value) end,
        showParty  = function(value)
            for i = 1, 4 do SetSlot("party" .. i, value) end
        end,

        predictColor = function() ApplyColor() end,
        predictAlpha = function() ApplyColor() end,

        predictOverheal = function(value)
            for _, bar in pairs(bars) do
                if EnsureLayer(bar) then bar:SetPredictionOverheal(value or 20) end
            end
        end,
    }

    DFUI:NewCallbacks("HealPredict", callbacks)

    -- ═══ 诊断 ═══
    -- 模块跑在 setfenv 环境里, 新建全局必须走 _G, 否则只写进 DFUI.env
    _G.SLASH_DFUIHEALPREDICT1 = "/dfheal"
    _G.SlashCmdList["DFUIHEALPREDICT"] = function()
        local out = DEFAULT_CHAT_FRAME
        out:AddMessage("|cff00ff00[DFUI 治疗预读]|r")

        if lib.sender.enabled then
            out:AddMessage("  广播: |cff00ff00自己发送|r")
        else
            out:AddMessage("  广播: |cffffff00已让给 " .. (lib.activeSender or "其他插件") .. "|r (纯接收模式)")
        end
        out:AddMessage("  轮询: " .. (poller:IsShown() and "|cff00ff00运行中|r" or "休眠"))

        local n = 0
        for slot, bar in pairs(bars) do
            if bar and bar.predict then n = n + 1 end
        end
        out:AddMessage("  已接入血条: " .. n .. " 条")

        local found = false
        for i = 1, table.getn(SLOTS) do
            local slot = SLOTS[i]
            if UnitExists(slot) then
                local tu = DFUI.ResolveToTrueUnit and DFUI.ResolveToTrueUnit(slot)
                local amt = tu and lib:UnitGetIncomingHeals(tu) or 0
                if amt > 0 then
                    out:AddMessage("  " .. slot .. " (" .. (UnitName(slot) or "?") .. "): |cff00ff00+" .. math.floor(amt) .. "|r")
                    found = true
                end
            end
        end
        if not found then out:AddMessage("  当前没有预读在途") end
    end
end)
