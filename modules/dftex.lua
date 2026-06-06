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
--   3) 写入回读测试：两个真实 DF POT 文件(fill-white 声望 / fill-blue 技能)能否写入并回读一致
--   4) 滚动/切Tab后再 /dfbar 看 fill 是否被 vanilla 改回（验证 hook 是否压住）
-- ============================================================
local FILL_REP   = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\character\\fill-white.tga"
local FILL_SKILL = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\character\\fill-blue.tga"

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
    local function n2(v)
        if v == nil then return "nil" end
        if type(v) == "number" then return string.format("%.1f", v) end
        return tostring(v)
    end
    -- 一条 bar 的关键状态（单行）：shown / val/max / sbColor(关键:看是否被调透明) / fill 纹理 texW/层
    local function dumpBar(nm)
        local f = getglobal(nm)
        if not f then dfbar_msg("  " .. nm .. " = nil"); return end
        local val = f.GetValue and f:GetValue()
        local _, mx
        if f.GetMinMaxValues then _, mx = f:GetMinMaxValues() end
        local cr, cg, cb, ca
        if f.GetStatusBarColor then cr, cg, cb, ca = f:GetStatusBarColor() end
        local st = f.GetStatusBarTexture and f:GetStatusBarTexture()
        local tw = st and st.GetWidth and st:GetWidth()
        local tl = st and st.GetDrawLayer and st:GetDrawLayer()
        local ea = f.GetEffectiveAlpha and f:GetEffectiveAlpha()
        dfbar_msg("  " .. nm .. " shown=" .. tostring(f:IsShown())
            .. " val/max=" .. n2(val) .. "/" .. n2(mx)
            .. " sbColor=" .. n2(cr) .. "," .. n2(cg) .. "," .. n2(cb) .. "," .. n2(ca)
            .. " texW=" .. n2(tw) .. " layer=" .. tostring(tl)
            .. " fill=" .. dfbar_fillOf(f) .. " effA=" .. n2(ea))
    end
    dfbar_msg("|cffffcc00[DFBar]|r 技能/声望条:")
    dumpBar("SkillRankFrame2")
    dumpBar("ReputationBar2")

    -- 列一条 bar 的"可见(shown)"纹理层 → 找盖在 fill 之上的遮挡源 / 确认 fill 层在不在
    local function dumpLayers(nm)
        local f2 = getglobal(nm)
        if not (f2 and f2.GetRegions) then return end
        dfbar_msg("|cffffcc00[DFBar]|r " .. nm .. " 可见纹理层:")
        local rs = {f2:GetRegions()}
        for i = 1, table.getn(rs) do
            local r = rs[i]
            if r.GetObjectType and r:GetObjectType() == "Texture" and r.IsShown and r:IsShown() then
                local vr, vg, vb
                if r.GetVertexColor then vr, vg, vb = r:GetVertexColor() end
                dfbar_msg("  " .. tostring(r.GetDrawLayer and r:GetDrawLayer())
                    .. " vc=" .. n2(vr) .. "," .. n2(vg) .. "," .. n2(vb)
                    .. " " .. tostring(r:GetTexture()))
            end
        end
    end
    dumpLayers("SkillRankFrame2")
    dumpLayers("ReputationBar2")
end
