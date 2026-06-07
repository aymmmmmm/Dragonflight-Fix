setfenv(1, DFUI:GetEnv())

-- ═══════════════════════════════════════════════════════════════
-- 法术书「未学技能」数据层
--   1.12/Turtle API 无法凭空枚举未学法术或其可学等级，唯一来源 = 训练师窗口。
--   监听 TRAINER_SHOW，扫描职业训练师（vanilla 一次列出该职业 1-60 级全部可
--   训练法术，含等级不够的灰色项 + 各级 LevelReq），写入独立 SavedVariables
--   DFUI_TrainerSpells[class]（按职业共享，同职业小号复用）。
--   再与已学法术做差集 → 未学清单 + 已学法术的"下一等级所需等级"。
--   移植自 _dev/ModernSpellBook/Spellbook/MSB_TrainerData.lua，去掉 MSB 框架依赖。
-- ═══════════════════════════════════════════════════════════════

-- 内存引用，PLAYER_ENTERING_WORLD 时指向 DFUI_TrainerSpells[class]
local trainerDB = nil
-- 计算缓存，TRAINER_SHOW 采集 / SPELLS_CHANGED / 进世界 时失效
local unlearnedCache = nil

local function InvalidateCache()
    unlearnedCache = nil
end

local function Trim(s)
    if not s then return s end
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

-- rank 文本 → 数字（"Rank 5"/"等级 5"/"5" → 5；"Passive"/无 → 0）
local function RankNum(r)
    if not r then return 0 end
    local _, _, d = string.find(r, "(%d+)")
    return tonumber(d) or 0
end

-- tab/分类名归一化：去 Turtle 的 Zz 前缀 + 去 " Combat" + trim + 小写
local function NormName(s)
    if not s then return "" end
    s = string.gsub(s, "^[Zz]+(%u)", "%1")
    s = string.gsub(s, " Combat", "")
    s = Trim(s)
    return string.lower(s)
end

-- 右侧收藏 tab（坐骑/小伙伴/玩具）—— 不作为未学法术容器
local function IsRightSideTabName(name)
    if not name then return false end
    return string.find(name, "坐骑") or string.find(name, "坐騎") or string.find(name, "[Mm]ount")
        or string.find(name, "小伙伴") or string.find(name, "小夥伴") or string.find(name, "[Cc]ompanion")
        or string.find(name, "玩具") or string.find(name, "[Tt]oy")
end

-- =================== 采集 =====================================
local function CaptureTrainerData()
    if not trainerDB then return end
    if not GetNumTrainerServices then return end
    local num = GetNumTrainerServices()
    if not num or num == 0 then return end

    -- 职业分类集合：天赋树名 + 法术书 tab 名 + 通用 —— 用于判定"是否职业训练师"
    -- 及"哪些 service 表头是有效职业分类"（武器/防御等非职业表头会被排除）
    local classCats = {}
    if GetNumTalentTabs then
        for t = 1, GetNumTalentTabs() do
            local n = GetTalentTabInfo(t)
            if n then classCats[Trim(n)] = true end
        end
    end
    for i = 1, GetNumSpellTabs() do
        local n = GetSpellTabInfo(i)
        if n then classCats[Trim(n)] = true end
    end
    classCats[GENERAL or "General"] = true

    -- 判定职业训练师：任一 service 表头匹配职业分类
    local isClass = false
    for i = 1, num do
        local ok, nm = pcall(GetTrainerServiceInfo, i)
        if ok and nm and classCats[Trim(nm)] then
            isClass = true
            break
        end
    end
    if not isClass then return end

    -- 开全部过滤器，确保灰色（等级/技能不够）未来法术也被列出
    pcall(function()
        if SetTrainerServiceTypeFilter then
            SetTrainerServiceTypeFilter("available", 1, 0)
            SetTrainerServiceTypeFilter("unavailable", 1, 0)
            SetTrainerServiceTypeFilter("used", 1, 0)
        end
    end)
    num = GetNumTrainerServices()

    local curHeader = GENERAL or "General"
    local curValid = true
    local captured = 0

    for i = 1, num do
        local ok, nm, rk = pcall(GetTrainerServiceInfo, i)
        local name = ok and nm and Trim(nm) or nil
        local rank = ok and rk and Trim(rk) or ""

        if name and name ~= "" then
            local icon = ""
            if GetTrainerServiceIcon then
                local iok, ic = pcall(GetTrainerServiceIcon, i)
                if iok then icon = ic or "" end
            end

            if (not icon) or icon == "" or icon == 0 then
                -- 分类表头（无图标）：匹配职业分类才有效，否则其下技能跳过（武器/防御/制毒等）
                curHeader = name
                curValid = classCats[name] and true or false
            elseif curValid then
                local levelReq = 0
                if GetTrainerServiceLevelReq then
                    local lok, lv = pcall(GetTrainerServiceLevelReq, i)
                    if lok then levelReq = lv or 0 end
                end
                trainerDB[name .. "|" .. rank] = {
                    name     = name,
                    rank     = rank,
                    rankNum  = RankNum(rank),
                    levelReq = levelReq,
                    icon     = icon,
                    category = curHeader,
                }
                captured = captured + 1
            end
        end
    end

    trainerDB._captured = true
    InvalidateCache()

    if captured > 0 and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[DFUI 法术书]|r 已采集 " .. captured .. " 条可学法术")
    end

    -- 法术书若开着，立即刷新
    if DFUI.RefreshSpellbookFromTrainer then DFUI.RefreshSpellbookFromTrainer() end
end

-- =================== 计算未学 / 下一级 =========================
local function ComputeUnlearned()
    local result = { byTab = {}, nextRank = {}, captured = false }
    if not trainerDB then return result end
    result.captured = trainerDB._captured and true or false

    -- 1. 已学集合：每个法术名的最高已学 rank；同时建 spell tab 归一名 → index 映射
    local knownHighest = {}
    local tabByNorm = {}
    local fallbackTab = nil
    local numTabs = GetNumSpellTabs()
    for ti = 1, numTabs do
        local tname, _, offset, num = GetSpellTabInfo(ti)
        if tname and num then
            if not IsRightSideTabName(tname) then
                tabByNorm[NormName(tname)] = ti
                if not fallbackTab then fallbackTab = ti end
            end
            for s = 1, num do
                local sn, sr = GetSpellName(offset + s, BOOKTYPE_SPELL)
                if sn then
                    local rn = RankNum(sr)
                    if not knownHighest[sn] or rn > knownHighest[sn] then
                        knownHighest[sn] = rn
                    end
                end
            end
        end
    end

    -- 2. 按法术名聚合训练师条目
    local byName = {}
    for key, e in pairs(trainerDB) do
        if type(e) == "table" and e.name then
            byName[e.name] = byName[e.name] or {}
            table.insert(byName[e.name], e)
        end
    end

    -- 3. 每法术折叠成"下一个可学 rank"（比当前已学最高 rank 高的最低 rank）
    for name, list in pairs(byName) do
        local highest = knownHighest[name]   -- nil = 完全未学
        local nextEntry = nil
        for _, e in ipairs(list) do
            if (not highest) or e.rankNum > highest then
                if not nextEntry or e.rankNum < nextEntry.rankNum then
                    nextEntry = e
                end
            end
        end
        if nextEntry then
            if highest then
                -- 已学但有更高 rank → 标注已学法术的"下一等级所需角色等级"
                result.nextRank[name] = nextEntry.levelReq
            else
                -- 完全未学 → 伪记录，归入其分类对应的 tab（匹配不上落 fallback）
                local ti = tabByNorm[NormName(nextEntry.category)] or fallbackTab
                if ti then
                    result.byTab[ti] = result.byTab[ti] or {}
                    table.insert(result.byTab[ti], {
                        index       = nil,
                        name        = name,
                        rank        = nextEntry.rank,
                        variant     = nil,
                        variantRank = 0,
                        texture     = nextEntry.icon,
                        isPassive   = false,
                        isRacial    = false,
                        tabIndex    = ti,
                        isUnlearned = true,
                        levelReq    = nextEntry.levelReq or 0,
                    })
                end
            end
        end
    end

    -- 4. 每 tab 未学列表按可学等级升序
    for _, list in pairs(result.byTab) do
        table.sort(list, function(a, b) return (a.levelReq or 0) < (b.levelReq or 0) end)
    end

    return result
end

-- 供 spellbook.lua 调用：返回 { byTab = {[tabIndex]={伪记录...}}, nextRank = {[name]=lvl}, captured }
function DFUI:GetSpellbookUnlearned()
    if not unlearnedCache then unlearnedCache = ComputeUnlearned() end
    return unlearnedCache
end

-- =================== 事件 / 延迟 ==============================
-- 自建一次性延迟（1.12 无 C_Timer）：TRAINER_SHOW 瞬间 service 列表可能未就绪，延迟读
local delayer = CreateFrame("Frame")
delayer:Hide()
local delayElapsed = 0
delayer:SetScript("OnUpdate", function()
    delayElapsed = delayElapsed + arg1
    if delayElapsed >= 0.3 then
        delayer:Hide()
        CaptureTrainerData()
    end
end)

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("TRAINER_SHOW")
ev:RegisterEvent("SPELLS_CHANGED")
ev:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        -- 必须经 _G 写真实全局：本文件 setfenv 到 DFUI.env，其 metatable 只有 __index 无 __newindex，
        -- 裸写 DFUI_TrainerSpells=... 会落到 env 表而非 _G，导致 SavedVariables 永不落盘（reload 后丢失）
        _G.DFUI_TrainerSpells = _G.DFUI_TrainerSpells or {}
        local _, class = UnitClass("player")
        class = class or "UNKNOWN"
        _G.DFUI_TrainerSpells[class] = _G.DFUI_TrainerSpells[class] or {}
        trainerDB = _G.DFUI_TrainerSpells[class]
        InvalidateCache()
    elseif event == "TRAINER_SHOW" then
        delayElapsed = 0
        delayer:Show()
    elseif event == "SPELLS_CHANGED" then
        InvalidateCache()
    end
end)
