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

-- ============================================================
-- /wmdump : 世界地图纹理结构调查（重构阶段0 临时工具，调查完删除）
--   dump WorldMapFrame / WorldMapButton / WorldMapDetailFrame 三框的直属
--   Texture region：名字/路径/图层/尺寸/屏幕矩形/显隐/alpha，并列三框直接子框名
--   目的：区分 chrome(要隐藏的暴雪边框) vs 地图底图(必须保留)，定隐藏策略
--   用法：打开世界地图、稳定显示后再 /wmdump —— 绝不在登录瞬间跑
--         (ShaguTweaks 缩放/窗口化未应用时屏幕矩形会失真)
-- ============================================================
local function wm_msg(s) DEFAULT_CHAT_FRAME:AddMessage(s) end

local function wm_num(v)
    if v == nil then return "?" end
    return tostring(math.floor(v + 0.5))
end

local function wm_dumpFrame(name)
    local f = getglobal(name)
    if not f then wm_msg("|cffff6666"..name.." = nil|r"); return end
    wm_msg("|cffffcc00===== "..name.." =====|r shown="..tostring(f:IsShown())
        .." level="..tostring(f.GetFrameLevel and f:GetFrameLevel()))
    if not f.GetRegions then return end
    local regs = { f:GetRegions() }
    local n = table.getn(regs)
    local texCount = 0
    for i = 1, n do
        local r = regs[i]
        if r and r.GetObjectType and r:GetObjectType() == "Texture" then
            texCount = texCount + 1
            local layer, sub = r:GetDrawLayer()
            local tex = r:GetTexture()
            if not tex or tex == "" then tex = "|cff888888(纯色/无文件)|r" end
            wm_msg("  |cff66ccff["..tostring(layer).."."..tostring(sub or 0).."]|r "
                ..(r:GetName() or "(匿名)")
                .."  "..wm_num(r:GetWidth()).."x"..wm_num(r:GetHeight())
                .."  rect L"..wm_num(r:GetLeft()).." R"..wm_num(r:GetRight())
                .." T"..wm_num(r:GetTop()).." B"..wm_num(r:GetBottom())
                .."  a"..tostring(r.GetAlpha and r:GetAlpha()).." vis"..tostring(r.IsVisible and r:IsVisible()))
            wm_msg("      tex="..tex)
        end
    end
    wm_msg("  |cff888888共 "..texCount.." 个 Texture region|r")
end

SLASH_WMDUMP1 = "/wmdump"
-- 路径去掉公共前缀 Interface\WorldMap\，只留文件名/子路径，输出更短
local function wm_short(tex)
    if not tex then return "(纯色)" end
    local s = string.gsub(tex, "^[Ii]nterface\\[Ww]orld[Mm]ap\\", "WM\\")
    return s
end

SlashCmdList["WMDUMP"] = function()
    local f = WorldMapFrame
    if not f or not f.GetRegions then wm_msg("|cffff6666WorldMapFrame nil|r"); return end
    wm_msg("|cffffcc00[WMDump]|r WorldMapFrame 各 region [图层] 名字 -> 路径(WM\\=Interface\\WorldMap\\)：")
    local regs = { f:GetRegions() }
    local c = 0
    for i = 1, table.getn(regs) do
        local r = regs[i]
        if r and r.GetObjectType and r:GetObjectType() == "Texture" then
            c = c + 1
            wm_msg("  |cff66ccff["..tostring(r:GetDrawLayer()).."]|r "
                ..(r:GetName() or "(匿名)").." -> "..wm_short(r:GetTexture()))
        end
    end
    wm_msg("  |cff888888WorldMapFrame 共 "..c.." 个|r")
    -- 佐证：地形底图是否在 DetailFrame 子框
    local d = WorldMapDetailFrame
    if d and d.GetRegions then
        local dr = { d:GetRegions() }
        local dc, first = 0, nil
        for i = 1, table.getn(dr) do
            local r = dr[i]
            if r and r.GetObjectType and r:GetObjectType() == "Texture" then
                dc = dc + 1
                if not first then first = r:GetTexture() end
            end
        end
        wm_msg("|cffffcc00WorldMapDetailFrame:|r "..dc.." 个 region，首个 -> "..wm_short(first))
    end
end

-- /wmsize : 核对地图各层与 DFUI 边框/羊皮纸的真实屏幕矩形（看边框是否贴合地图）
SLASH_WMSIZE1 = "/wmsize"
SlashCmdList["WMSIZE"] = function()
    local function sz(name)
        local f = getglobal(name)
        if not f then wm_msg("  |cffff6666" .. name .. " = nil|r"); return end
        wm_msg("  " .. name .. ": " .. wm_num(f.GetWidth and f:GetWidth()) .. "x" .. wm_num(f.GetHeight and f:GetHeight())
            .. "  lvl" .. tostring(f.GetFrameLevel and f:GetFrameLevel())
            .. "  L" .. wm_num(f.GetLeft and f:GetLeft()) .. " R" .. wm_num(f.GetRight and f:GetRight())
            .. " T" .. wm_num(f.GetTop and f:GetTop()) .. " B" .. wm_num(f.GetBottom and f:GetBottom()))
    end
    wm_msg("|cffffcc00[WMSize]|r 地图各层 vs DFUI 边框/羊皮纸 真实矩形：")
    sz("WorldMapFrame")
    sz("WorldMapButton")
    sz("WorldMapDetailFrame")
    sz("DFUI_WorldMapBg")
    sz("DFUI_WorldMapInset")
    sz("pfQuestMapDropdown")
    sz("shagutweaks_mapreveal_onmap")
end

-- ============================================================
-- /dftexfix : TGA 纹理偶发缺图 诊断+止血
--   /dftexfix          → dump：MOTD 层级 tie 证据 + 4 个社交 inset 边线 + 天赋插画状态
--   /dftexfix heal     → SetTexture(nil)→原路径 强制重设并报告（低频手动，非每帧）
--   /dftexfix auto N   → 天赋插画开面板自愈：0=关 1=仅 GetTexture 为 nil 时 2=强制
-- 根因背景：未压缩 TGA 偶发解码/上传失败且 set-once 粘滞（BLP 从未失败）；
-- heal 能否救活 = 二期 TGA→BLP2 ARGB 转换的决策实验
-- ============================================================
local TFX_TEX = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\"
local TFX_H   = TFX_TEX .. "panels\\df\\professions\\uiframe_h.blp"
local TFX_V   = TFX_TEX .. "panels\\df\\professions\\uiframe_v.blp"
local TFX_C   = TFX_TEX .. "interface\\generalframeinsetborders.blp"
-- UV 与 core/tools.lua CreateRetailInset(486-508 边/547-550 角)一致；那边改这边必须同步
local TFX_EDGE = {
    {"top",   TFX_H, 0, 1, 0.9063, 0.9297},
    {"bot",   TFX_H, 0, 1, 0.8672, 0.8906},
    {"left",  TFX_V, 0.4844, 0.5313, 0, 1},
    {"right", TFX_V, 0.5313, 0.4844, 0, 1},
}
local TFX_CORNER = {
    {"tl", TFX_C, 0.703125, 0.828125, 0.03125, 0.28125},
    {"tr", TFX_C, 0.859375, 0.984375, 0.03125, 0.28125},
    {"bl", TFX_C, 0.328125, 0.453125, 0.6875,  0.9375},
    {"br", TFX_C, 0.515625, 0.640625, 0.6875,  0.9375},
}
local TFX_INSETS = {"DFUI_FriendsInset", "DFUI_WhoInset", "DFUI_GuildInset", "DFUI_RaidInset"}

local function tfx_msg(s) DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[DFTexFix]|r " .. s) end
local function tfx_lvl(f) return tostring(f and f.GetFrameLevel and f:GetFrameLevel() or "?") end
local function tfx_short(p)
    if not p then return "|cffff6666nil|r" end
    local _, _, tail = string.find(tostring(p), "([^\\]+)$")
    return tail or tostring(p)
end

local function tfx_dump()
    -- ① 公会 MOTD：层级 tie 实证（GuildFrame lvl == DFUI_FriendsBg lvl 即 tie；修复后 NotesText 父应为 DFUI_GuildInset）
    local nt = GuildFrameNotesText
    if nt then
        local p = nt.GetParent and nt:GetParent()
        tfx_msg("NotesText type=" .. (nt.GetObjectType and nt:GetObjectType() or "?")
            .. " parent=" .. tostring(p and p.GetName and p:GetName() or "(匿名)")
            .. " parentLvl=" .. tfx_lvl(p))
    else
        tfx_msg("GuildFrameNotesText = |cffff6666nil|r")
    end
    tfx_msg("lvl: FriendsFrame=" .. tfx_lvl(FriendsFrame)
        .. " FriendsBg=" .. tfx_lvl(DFUI_FriendsBg)
        .. " GuildFrame=" .. tfx_lvl(GuildFrame)
        .. " GuildInset=" .. tfx_lvl(DFUI_GuildInset))
    -- ② 4 个社交 inset：IsShown + 边线纹理（判别 per-file 还是 per-region 失败）
    for i = 1, 4 do
        local f = getglobal(TFX_INSETS[i])
        if f then
            local e = f.edges
            tfx_msg(TFX_INSETS[i] .. " shown=" .. tostring(f:IsShown())
                .. " top=" .. tfx_short(e and e.top:GetTexture())
                .. " left=" .. tfx_short(e and e.left:GetTexture())
                .. " bg=" .. tfx_short(f.bg and f.bg:GetTexture()))
        else
            tfx_msg(TFX_INSETS[i] .. " = |cffff6666nil|r")
        end
    end
    -- ③ 天赋 3 张插画（懒创建，未开过面板则 nil）
    for i = 1, 3 do
        local ins = getglobal("DFUI_TalentInset" .. i)
        if ins and ins.illust then
            tfx_msg("illust" .. i .. " now=" .. tfx_short(ins.illust:GetTexture())
                .. " want=" .. tfx_short(ins.illustPath))
        else
            tfx_msg("DFUI_TalentInset" .. i .. (ins and " 无illust字段" or " = nil（先开一次天赋面板）"))
        end
    end
    -- ④ MOTD 边框 8 块（与 raid 边线同两份 TGA 文件，per-file 判别的对照组）
    local mb = DFUI_GuildMotdBg
    if mb and mb.dfBorderTex then
        local bad = 0
        for i = 1, table.getn(mb.dfBorderTex) do
            if not mb.dfBorderTex[i][1]:GetTexture() then bad = bad + 1 end
        end
        tfx_msg("GuildMotdBg 边框 8 块中 GetTexture=nil 的有 " .. bad .. " 块")
    end
end

-- 重设一个纹理：nil 断开引用 → 原路径重挂 → 补 UV（防 SetTexture 重置 TexCoord）
local function tfx_reset(tex, path, a, b, c, d)
    if not (tex and tex.SetTexture) then return "无对象" end
    local before = tfx_short(tex:GetTexture())
    tex:SetTexture(nil)
    local ok = tex:SetTexture(path)
    if a then tex:SetTexCoord(a, b, c, d) end
    return before .. " ret=" .. tostring(ok) .. " now=" .. tfx_short(tex:GetTexture())
end

local function tfx_heal()
    for i = 1, 3 do
        local ins = getglobal("DFUI_TalentInset" .. i)
        if ins and ins.illust and ins.illustPath then
            tfx_msg("illust" .. i .. ": " .. tfx_reset(ins.illust, ins.illustPath, 0, 1, 0, 1))
        end
    end
    for i = 1, 4 do
        local f = getglobal(TFX_INSETS[i])
        if f then
            if f.edges then
                for j = 1, 4 do
                    local e = TFX_EDGE[j]
                    local r = tfx_reset(f.edges[e[1]], e[2], e[3], e[4], e[5], e[6])
                    if j == 1 then tfx_msg(TFX_INSETS[i] .. ".top: " .. r) end
                end
            end
            if f.corners then
                for j = 1, 4 do
                    local e = TFX_CORNER[j]
                    tfx_reset(f.corners[e[1]], e[2], e[3], e[4], e[5], e[6])
                end
            end
        end
    end
    local mb = DFUI_GuildMotdBg
    if mb and mb.dfBorderTex then
        for i = 1, table.getn(mb.dfBorderTex) do
            local p = mb.dfBorderTex[i]
            tfx_reset(p[1], p[2], p[3][1], p[3][2], p[3][3], p[3][4])
        end
        tfx_msg("GuildMotdBg 边框已重设")
    end
    tfx_msg("重设完毕——请肉眼核对插画/边线是否回来（GetTexture 非 nil 不代表已渲染）")
end

SLASH_DFTEXFIX1 = "/dftexfix"
SlashCmdList["DFTEXFIX"] = function(msg)
    local _, _, cmd, arg = string.find(msg or "", "^(%a*)%s*(%d*)")
    if cmd == "heal" then
        tfx_heal()
    elseif cmd == "auto" then
        local v = tonumber(arg) or 0
        if DFUI_CUR_PROFILE then
            DFUI_CUR_PROFILE['TexFixAutoHeal'] = (v > 0) and v or nil
            tfx_msg("天赋插画开面板自愈 = " .. v .. "（0关 1仅缺图时 2强制），跨会话持久")
        else
            tfx_msg("|cffff6666DFUI_CUR_PROFILE 尚未初始化|r")
        end
    else
        tfx_dump()
    end
end
