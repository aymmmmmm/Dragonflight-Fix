-- DF-Fix 临时调试工具：鼠标悬停取素材
-- 用法：把鼠标停在目标 UI 元素上 → 在聊天框输入 /dftex 回车（输入命令不会移动鼠标）
-- 输出：光标下所有可见纹理，按图层从上到下排列： [图层] 纹理路径 @所属框体
--       含 StatusBar 的填充纹理（标记 STATUSBAR-FILL）
-- 注意：本文件不使用 setfenv，运行在普通全局环境，方便注册 slash 命令。

local LAYER_RANK = {
    BACKGROUND = 1, BORDER = 2, ARTWORK = 3, ["STATUSBAR-FILL"] = 3, OVERLAY = 4, HIGHLIGHT = 5,
}

-- 命中测试：obj 的屏幕矩形是否包含 (x,y)（x,y 已按 obj 所在框体的有效缩放换算）
local function inRect(o, x, y)
    local l, r, t, b = o:GetLeft(), o:GetRight(), o:GetTop(), o:GetBottom()
    return l and r and t and b and x >= l and x <= r and y >= b and y <= t
end

-- 递归扫描 frame 及其子框体/纹理，把命中光标的纹理收集进 out
local function scan(frame, rawX, rawY, depth, out)
    if depth > 14 or not frame then return end
    if not frame.IsVisible or not frame:IsVisible() then return end

    -- 每个框体可能有独立缩放：把原始像素光标换算到该框体的坐标空间
    local s = frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
    if not s or s == 0 then s = 1 end
    local x, y = rawX / s, rawY / s

    -- StatusBar 填充纹理
    if frame.GetObjectType and frame:GetObjectType() == "StatusBar"
       and frame.GetStatusBarTexture and inRect(frame, x, y) then
        local st = frame:GetStatusBarTexture()
        if st and st.GetTexture then
            table.insert(out, { layer = "STATUSBAR-FILL", tex = st:GetTexture(), owner = frame:GetName() })
        end
    end

    -- 普通纹理区域
    if frame.GetRegions then
        local regs = { frame:GetRegions() }
        for i = 1, table.getn(regs) do
            local reg = regs[i]
            if reg and reg.GetObjectType and reg:GetObjectType() == "Texture"
               and reg:IsVisible() and inRect(reg, x, y) then
                table.insert(out, { layer = reg:GetDrawLayer(), tex = reg:GetTexture(), owner = frame:GetName() })
            end
        end
    end

    -- 子框体
    if frame.GetChildren then
        local kids = { frame:GetChildren() }
        for i = 1, table.getn(kids) do
            scan(kids[i], rawX, rawY, depth + 1, out)
        end
    end
end

SLASH_DFTEX1 = "/dftex"
SlashCmdList["DFTEX"] = function()
    local rawX, rawY = GetCursorPosition()
    local out = {}
    scan(UIParent, rawX, rawY, 0, out)

    -- 按图层从上到下排序（最上层先打印 = 你肉眼看到的那层）
    table.sort(out, function(a, b)
        return (LAYER_RANK[a.layer] or 0) > (LAYER_RANK[b.layer] or 0)
    end)

    local n = table.getn(out)
    local sx = UIParent:GetEffectiveScale()
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[DFTex]|r 光标(" .. math.floor(rawX / sx) .. "," .. math.floor(rawY / sx) .. ")  命中 " .. n .. " 个纹理：")
    for i = 1, n do
        local e = out[i]
        local tex = e.tex
        if not tex or tex == "" then tex = "|cff888888(纯色/无文件)|r" end
        DEFAULT_CHAT_FRAME:AddMessage("  |cff66ccff[" .. e.layer .. "]|r " .. tex .. "  |cff888888@" .. (e.owner or "(匿名)") .. "|r")
    end
    if n == 0 then
        local f = GetMouseFocus()
        local fname = (f and f.GetName and f:GetName()) or "(无/匿名)"
        DEFAULT_CHAT_FRAME:AddMessage("  无命中（元素可能不可见或不在 UIParent 下）。MouseFocus=" .. fname)
    end
end

-- ============================================================
-- /dfbar : 进度条根因诊断
--   1) 活体 dump 错误日志（看 Character mod 是否抛错被 pcall 吞掉 → bar 块没跑）
--   2) 当前声望/技能条的 StatusBar fill 纹理路径
--   3) 写入回读测试：NPOT(fill-white 256×17) vs POT(rankbar_blue 256×16) 谁能“吃进去”
--   4) 留 NPOT 让你肉眼看渲染 + 滚动/切Tab后再 /dfbar 看是否被 vanilla 改回
-- ============================================================
local FILL_NPOT = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\character\\fill-white.tga"
local FILL_POT  = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\panels\\df\\professions\\rankbar_fill_blue.tga"

local function dfbar_msg(s) DEFAULT_CHAT_FRAME:AddMessage(s) end

local function dfbar_fillOf(f)
    if f and f.GetStatusBarTexture then
        local st = f:GetStatusBarTexture()
        if st and st.GetTexture then return st:GetTexture() or "(nil路径)" end
    end
    return "(无fill)"
end

local function dfbar_dumpErr(tag, list)
    if type(list) ~= "table" then return end
    local c = table.getn(list)
    local from = c - 4
    if from < 1 then from = 1 end
    for i = from, c do
        local e = list[i]
        local t = e
        if type(e) == "table" then t = e.msg or e.message or e.text or e.error or e[1] end
        if t then dfbar_msg("  |cffff6666[" .. tag .. i .. "]|r " .. string.sub(tostring(t), 1, 220)) end
    end
end

SLASH_DFBAR1 = "/dfbar"
SlashCmdList["DFBAR"] = function()
    -- 1) 错误日志
    local nDisk = 0
    if type(DFUI_BUGS) == "table" and type(DFUI_BUGS.entries) == "table" then nDisk = table.getn(DFUI_BUGS.entries) end
    local nLive = 0
    if DFUI and DFUI.errors and type(DFUI.errors.list) == "table" then nLive = table.getn(DFUI.errors.list) end
    dfbar_msg("|cffffcc00[DFBar]|r 错误日志: DFUI_BUGS.entries=" .. nDisk .. "  DFUI.errors.list=" .. nLive)
    dfbar_dumpErr("BUGS", DFUI_BUGS and DFUI_BUGS.entries)
    dfbar_dumpErr("live", DFUI and DFUI.errors and DFUI.errors.list)

    -- 2) 当前状态
    dfbar_msg("|cffffcc00[DFBar]|r 当前 fill 纹理:")
    local names = { "SkillRankFrame1", "SkillRankFrame2", "ReputationBar1", "ReputationBar2" }
    for i = 1, table.getn(names) do
        local nm = names[i]
        local f = getglobal(nm)
        if f then
            local ot = f.GetObjectType and f:GetObjectType() or "?"
            local shown = f.IsShown and f:IsShown()
            dfbar_msg("  " .. nm .. " [" .. ot .. "] shown=" .. tostring(shown) .. " fill=" .. dfbar_fillOf(f))
        else
            dfbar_msg("  " .. nm .. " = nil")
        end
    end

    -- 3) 写入回读测试
    local probe = getglobal("SkillRankFrame1")
    if probe and probe.SetStatusBarTexture then
        probe:SetStatusBarTexture(FILL_NPOT)
        local g1 = dfbar_fillOf(probe)
        probe:SetStatusBarTexture(FILL_POT)
        local g2 = dfbar_fillOf(probe)
        probe:SetStatusBarTexture(FILL_NPOT) -- 留 NPOT
        dfbar_msg("|cffffcc00[DFBar]|r 写入测试 @SkillRankFrame1:")
        dfbar_msg("  setNPOT(fill-white)   回读 = " .. g1)
        dfbar_msg("  setPOT (rankbar_blue) 回读 = " .. g2)
        dfbar_msg("  |cff88ff88已留 NPOT。请①看 SkillRankFrame1 是否有填充渲染 ②滚动技能列表或切Tab后再 /dfbar 看 fill 是否被改回 vanilla|r")
    else
        dfbar_msg("  SkillRankFrame1 不可写(非 StatusBar?)")
    end
end
