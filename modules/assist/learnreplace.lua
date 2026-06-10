----------------------------------------------------------------------
-- DFUI.Assist  --  学会法术通知 + 替换动作条
-- 移植 Automatonex Lern2Spell。学到更高等级法术后，把动作条上仍是
-- 旧等级的对应按钮自动替换成新学的最高等级，并聊天提示。
--
-- 原版依赖 Ace SpecialEvents-LearnSpell + Gratuity；DFUI 自包含，
-- 改为自实现法术书快照 diff（LEARNED_SPELL_IN_TAB 触发）+ libtipscan
-- 读动作条按钮当前法术名/等级。
----------------------------------------------------------------------

local L = DFUI.Assist.L
local scanner = DFUI_Libs.libtipscan:GetScanner("DFUIAssistLearn")

local snapshot = nil   -- { [spellName] = 最高 rank 数字 }

-- 扫法术书，返回 name -> 最高 rank 数字
local function buildSnapshot()
    local snap = {}
    for t = 1, GetNumSpellTabs() do
        local _, _, offset, num = GetSpellTabInfo(t)
        for id = offset + 1, offset + num do
            local sname, srank = GetSpellName(id, BOOKTYPE_SPELL)
            if sname then
                local _, _, n = string.find(srank or "", "(%d+)$")
                n = tonumber(n) or 1
                if not snap[sname] or n > snap[sname] then snap[sname] = n end
            end
        end
    end
    return snap
end

-- 找某法术当前最高等级的法术书索引 + 等级串
local function findMaxRank(name)
    local bestIdx, bestNum, bestStr
    for t = 1, GetNumSpellTabs() do
        local _, _, offset, num = GetSpellTabInfo(t)
        for id = offset + 1, offset + num do
            local sname, srank = GetSpellName(id, BOOKTYPE_SPELL)
            if sname == name then
                local _, _, n = string.find(srank or "", "(%d+)$")
                n = tonumber(n) or 1
                if not bestNum or n > bestNum then
                    bestNum, bestIdx, bestStr = n, id, srank
                end
            end
        end
    end
    return bestIdx, bestStr
end

-- 把动作条上同名旧等级按钮替换成新学最高等级
local function replaceOnBars(name)
    local newIdx, newStr = findMaxRank(name)
    if not newIdx then return end
    for btn = 1, 120 do
        if HasAction(btn) and not GetActionText(btn) then
            scanner:SetAction(btn)
            local bname, brank = scanner:GetLine(1)
            if bname == name and (brank or "") ~= (newStr or "") then
                PickupSpell(newIdx, BOOKTYPE_SPELL)
                PlaceAction(btn)
                if CursorHasSpell() or CursorHasItem() then ClearCursor() end
                DFUI.Assist.Print(string.format(L["learnReplaceFmt"], btn, name, newStr or "?"))
            end
        end
    end
end

DFUI.Assist:register({
    key = "autoLearnReplace",
    title = L["autoLearnReplace"],
    desc = L["autoLearnReplaceDesc"],
    default = false,
    load = function(self)
        snapshot = buildSnapshot()
    end,
    events = {
        LEARNED_SPELL_IN_TAB = function(self)
            if UnitAffectingCombat("player") then return end
            local current = buildSnapshot()
            if not snapshot then snapshot = current; return end
            for name, num in pairs(current) do
                if num > (snapshot[name] or 0) then
                    replaceOnBars(name)
                end
            end
            snapshot = current
        end,
    },
})
