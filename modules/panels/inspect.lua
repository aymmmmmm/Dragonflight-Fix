-- inspect.lua — 观察面板（Blizzard_InspectUI，LoadOnDemand）DF 换皮
-- 4 子页：角色(id1) / 荣誉(id2) / 竞技场(id3) / 天赋(id4，内含 Turtle 自定义 TWTalentFrame)
-- 荣誉/竞技场照搬 character.lua 玩家面板做法；天赋树 Tab 复用 DFUI.ApplySubTabSkin、
-- 滚动条复用 DFUI.AttachMinimalScrolls（questskin.lua）
setfenv(1, DFUI:GetEnv())

local TEX = DFUI:GetInfoOrCons("tex")

DFUI:NewDefaults("Inspect", {
    enabled = {true},
})

DFUI:NewMod("Inspect", 5, function()
    local skinned = false

    -- 通用纹理隐藏：保留图标/头像/高亮/状态条
    -- GetRegions 不递归：只扫直属 region，子 frame（HK/DK 数据条、TWTalentFrame 等）不受影响
    local function HideBlizzardTextures(frame)
        if not frame then return end
        local regions = {frame:GetRegions()}
        for i = 1, table.getn(regions) do
            local region = regions[i]
            if region:GetObjectType() == "Texture" then
                local name = region:GetName()
                local texture = region:GetTexture()
                local skip = false
                if name then
                    if string.find(name, "Icon") or string.find(name, "Portrait") or string.find(name, "Check") or string.find(name, "Highlight") then
                        skip = true
                    end
                end
                if texture and (string.find(texture, "Icon") or string.find(texture, "Portrait") or string.find(texture, "StatusBar")) then
                    skip = true
                end
                if not skip then
                    region:Hide()
                end
            end
        end
    end

    -- 荣誉页：重贴 4 张 Turtle 原生槽位底图（同 character.lua 玩家荣誉页做法）。
    -- 底图被 HideBlizzardTextures 连 General 底一起隐藏了；数据 FontString 本就按
    -- 这套底图的槽位锚定，按 InspectHonorFrame.xml 原生偏移贴回即精确复刻。
    -- BACKGROUND 层 → 落在数据文本之下、honorInset(marble) 之上。
    local function RepasteHonorSlots()
        if not InspectHonorFrame or InspectHonorFrame._dfHonorSlots then return end
        InspectHonorFrame._dfHonorSlots = true
        local slots = {
            {"UI-Character-Honor-TopLeft",     256, 256,  22,  -69},
            {"UI-Character-Honor-TopRight",    128, 256, 275,  -69},
            {"UI-Character-Honor-BottomLeft",  256, 128,  22, -325},
            {"UI-Character-Honor-BottomRight", 128, 128, 275, -325},
        }
        for i = 1, table.getn(slots) do
            local s = slots[i]
            local t = InspectHonorFrame:CreateTexture(nil, "BACKGROUND")
            t:SetTexture("Interface\\PaperDollInfoFrame\\" .. s[1])
            t:SetWidth(s[2]); t:SetHeight(s[3])
            t:SetPoint("TOPLEFT", InspectHonorFrame, "TOPLEFT", s[4], s[5])
        end
    end

    -- 竞技场页：队伍按钮 DF 真素材皮肤（照 character.lua ArenaFrameTeam）
    -- pcall 隔离：万一报错也绝不连累 InspectArenaFrame 显示
    local function SkinArenaTeams()
        for i = 1, 3 do
            local team = getglobal("InspectArenaFrameTeam" .. i)
            if team and not team._dfSkinned then
                team._dfSkinned = true
                local ok, err = pcall(function()
                    if team.SetBackdrop then team:SetBackdrop(nil) end
                    local MARBLE = TEX .. "interface\\ui-background-marble.blp"
                    local UF_H   = TEX .. "panels\\df\\professions\\uiframe_h.blp"
                    local UF_V   = TEX .. "panels\\df\\professions\\uiframe_v.blp"
                    local abg = team:CreateTexture(nil, "BACKGROUND")
                    abg:SetTexture(MARBLE); abg:SetAllPoints(team); abg:SetVertexColor(0.72, 0.72, 0.72)
                    local atop = team:CreateTexture(nil, "BORDER")
                    atop:SetTexture(UF_H); atop:SetTexCoord(0.0, 1.0, 0.9063, 0.9297)
                    atop:SetPoint("TOPLEFT", team, "TOPLEFT", 0, 0); atop:SetPoint("TOPRIGHT", team, "TOPRIGHT", 0, 0); atop:SetHeight(3)
                    local abot = team:CreateTexture(nil, "BORDER")
                    abot:SetTexture(UF_H); abot:SetTexCoord(0.0, 1.0, 0.8672, 0.8906)
                    abot:SetPoint("BOTTOMLEFT", team, "BOTTOMLEFT", 0, 0); abot:SetPoint("BOTTOMRIGHT", team, "BOTTOMRIGHT", 0, 0); abot:SetHeight(3)
                    local alft = team:CreateTexture(nil, "BORDER")
                    alft:SetTexture(UF_V); alft:SetTexCoord(0.4844, 0.5313, 0.0, 1.0)
                    alft:SetPoint("TOPLEFT", team, "TOPLEFT", 0, 0); alft:SetPoint("BOTTOMLEFT", team, "BOTTOMLEFT", 0, 0); alft:SetWidth(2)
                    local argt = team:CreateTexture(nil, "BORDER")
                    argt:SetTexture(UF_V); argt:SetTexCoord(0.5313, 0.4844, 0.0, 1.0)
                    argt:SetPoint("TOPRIGHT", team, "TOPRIGHT", 0, 0); argt:SetPoint("BOTTOMRIGHT", team, "BOTTOMRIGHT", 0, 0); argt:SetWidth(2)
                end)
                if not ok then DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[DFUI inspect arena skin] " .. tostring(err)) end
            end
        end
    end

    -- 天赋页：蹿层压制 + 树插画收纳 + 树 Tab 换 DF 子 tab 皮 + minimal 滚动条
    local function SkinTalents(customBg)
        if not InspectTalentsFrame or not TWTalentFrame then return end

        -- TWTalentFrame toplevel="true" 显示时自动蹿层会盖住 DF 金属框 → 压回
        if TWTalentFrame.SetToplevel then TWTalentFrame:SetToplevel(false) end

        -- 暗岩石凹陷承载树插画。levelOffset 0：压到 customBg 同级，
        -- 低于 TWTalentFrame（插画/天赋按钮天然浮其上）
        local talentInset = DFUI.CreateRetailInset(customBg, {
            name         = "DFUI_InspectTalentInset",
            anchors      = {3, -58, -6, 6},
            levelOffset  = 0,
            followFrames = {InspectTalentsFrame},
        })
        talentInset.bg:SetVertexColor(0.35, 0.32, 0.28)   -- 暗岩石凹陷底（同玩家天赋页）

        -- 树插画：弃用原生 4 拼重锚缩放（只动得了 TopLeft，其余三块锚链/尺寸对不齐 → 铺不满凹陷）
        -- → 改玩家天赋页(ui\talents.lua)同款：单张预裁 POT 整图 dfbg_<树名> SetAllPoints 铺满凹陷，
        --   素材 media\tex\talents\ 27 张全职业树齐。树名从原生 TopLeft 纹理路径解析
        --   （TWTalentFrame_Update 换树只 SetTexture → 下方 watcher 轮询跟随；名字缓存防反复 SetTexture）
        local bgPieces = {TWTalentFrameBackgroundTopLeft, TWTalentFrameBackgroundTopRight,
                          TWTalentFrameBackgroundBottomLeft, TWTalentFrameBackgroundBottomRight}
        for i = 1, 4 do
            if bgPieces[i] then bgPieces[i]:SetAlpha(0) end   -- Update 只 SetTexture 不碰 alpha，恒隐
        end
        -- ⭐ BORDER 层，不用 SetDrawLayer 第二参：1.12 下 subLevel 被静默忽略，写 ("BACKGROUND",2)
        --    会与 talentInset.bg（铺满的暗岩石）同落 BACKGROUND → 同层顺序不稳、岩石随机盖住插画。
        --    与本文件 :235 的 inspectCharBg 同一约定（bg=BACKGROUND < BORDER < 描线 ARTWORK < 圆角 OVERLAY）。
        local illust = talentInset:CreateTexture(nil, "BORDER")
        illust:SetAllPoints(talentInset)
        illust:SetAlpha(1.0)   -- 同玩家天赋页：0.9 会掺 10% 暗岩石底进画面拉低对比，提亮已烘进素材

        -- 比例修正：dfbg_* 内容 568×620(=0.917) 非等比压进 512² 画布，本面板 inset 331×361(=0.917)
        -- → 恰好全采不裁。仍走工厂而不是写死 (0,1,0,1)：inset anchors 将来一改就自动跟上，
        --   不用回头重裁素材（玩家天赋页 0.593 就是靠同一个工厂横向裁回去的）。
        local function FitIllust()
            DFUI.FitIllustCrop(illust, talentInset, DFUI.DFBG_SRC_W, DFUI.DFBG_SRC_H)
        end

        local illustName
        local function UpdateTalentIllust()
            local path = TWTalentFrameBackgroundTopLeft and TWTalentFrameBackgroundTopLeft:GetTexture()
            local _, _, name = string.find(path or "", "([^\\/]+)%-TopLeft$")
            if name == illustName then return end
            illustName = name
            if name and illust:SetTexture("Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\talents\\dfbg_" .. string.lower(name)) then
                FitIllust()     -- 换树后重设采样窗口（SetTexture 后一律重设，别赌 texcoord 是否被保留）
                illust:Show()
            else
                illust:Hide()   -- 解析失败/无对应 illust 的树 → 只留暗岩石凹陷底
            end
        end
        UpdateTalentIllust()
        -- inset 建出来时是 Hide 状态，双锚 frame 此时 GetTop 可能为 nil（上面已守卫 → no-op）
        -- → 显示时再算一次兜底。用 HookScript 不用 SetScript：工厂当前没给 inset 设 OnShow，
        --   但 followFrames 逻辑将来若改成挂 inset 自身，SetScript 会把它顶掉。
        HookScript(talentInset, "OnShow", FitIllust)

        -- 树 Tab 贴皮：灭 TabButtonTemplate 原生纹理后套 DF 子 tab 皮。
        -- PanelTemplates 切换会反复 Show 这些纹理，SetTexture(nil) 才恒隐。
        -- 位置/点击逻辑零改动；选中态文字色走 Button 状态色
        -- （PanelTemplates 选中即 Disable → 白，未选中 Enable → 金）
        for i = 1, 3 do
            local tab = getglobal("TWTalentFrameTab" .. i)
            if tab and not tab._dfSubTabSkin then
                tab._dfSubTabSkin = true
                local pieces = {"Left", "Middle", "Right", "LeftDisabled", "MiddleDisabled", "RightDisabled"}
                for j = 1, 6 do
                    local t = getglobal("TWTalentFrameTab" .. i .. pieces[j])
                    if t then t:SetTexture(nil) end
                end
                local hl = tab.GetHighlightTexture and tab:GetHighlightTexture()
                if hl then hl:SetTexture(nil) end
                DFUI.ApplySubTabSkin(tab)
                if tab.SetTextColor then tab:SetTextColor(1, 0.82, 0) end
                if tab.SetDisabledTextColor then tab:SetDisabledTextColor(1, 1, 1) end
            end
        end

        -- 选中态/宽度看门狗：tab 文字与宽度由 TWTalentFrame_Update 在观察数据
        -- 到达时异步刷新（PanelTemplates_TabResize），轻量轮询同步（仅面板可见时）
        local watcher = CreateFrame("Frame")
        local elapsed = 0
        watcher:SetScript("OnUpdate", function()
            elapsed = elapsed + (arg1 or 0)
            if elapsed < 0.2 then return end
            elapsed = 0
            if not InspectTalentsFrame:IsVisible() then return end
            UpdateTalentIllust()   -- 换树/观察数据到达 → 跟随刷插画（名字没变时零开销）
            local sel = TWTalentFrame.selectedTab
            for i = 1, 3 do
                local tab = getglobal("TWTalentFrameTab" .. i)
                if tab and tab.SetSelected then
                    tab:RefreshSubTabWidth()
                    tab:SetSelected(i == sel)
                end
            end
        end)

        -- minimal 滚动条（内含灭原生轨道/箭头/thumb + thumb 位置同步）
        if DFUI.AttachMinimalScrolls then
            DFUI.AttachMinimalScrolls(InspectTalentsFrame, {
                {sf = "TWTalentFrameScrollFrame", sb = "TWTalentFrameScrollFrameScrollBar"},
            })
        end
        -- 滚动条旁 2 块 UI-Character-ScrollBar 装饰纹理
        HideBlizzardTextures(TWTalentFrameScrollFrame)
    end

    local function SkinInspectFrame()
        if skinned or not InspectFrame then return end
        skinned = true

        -- 隐藏主框架 + 所有子框架的暴雪纹理
        HideBlizzardTextures(InspectFrame)
        HideBlizzardTextures(InspectPaperDollFrame)
        HideBlizzardTextures(InspectHonorFrame)
        if InspectTalentsFrame then HideBlizzardTextures(InspectTalentsFrame) end
        if InspectArenaFrame then HideBlizzardTextures(InspectArenaFrame) end

        -- 隐藏所有暴雪 Tab
        for i = 1, 5 do
            local tab = getglobal("InspectFrameTab" .. i)
            if tab then tab:Hide() end
        end
        if InspectFrameCloseButton then InspectFrameCloseButton:Hide() end

        local customBg = DFUI.CreatePaperDollFrame("DFUI_InspectBg", InspectFrame, 384, 512, 1)
        customBg:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", 12, -12)
        customBg:SetPoint("BOTTOMRIGHT", InspectFrame, "BOTTOMRIGHT", -32, 75)
        customBg:SetFrameLevel(InspectFrame:GetFrameLevel() + 1)
        customBg.Bg:SetDrawLayer("BACKGROUND", -1)

        -- 头像
        if InspectFramePortrait then
            InspectFramePortrait:SetParent(customBg)
            InspectFramePortrait:SetDrawLayer("BORDER", 0)
        end

        local closeButton = DFUI.CreateRedButton(customBg, "close", function() HideUIPanel(InspectFrame) end)
        closeButton:SetPoint("TOPRIGHT", customBg, "TOPRIGHT", 0, -1)
        closeButton:SetWidth(20)
        closeButton:SetHeight(20)
        closeButton:SetFrameLevel(customBg:GetFrameLevel() + 3)

        -- ===== 角色页：暗岩石凹陷 + DF 职业专属背景填充（凹陷画框 + 插画，同天赋页语言）=====
        -- levelOffset 0：凹陷压到 customBg 同级；装备槽/模型是 InspectPaperDollFrame
        -- 的子 frame(+2)天然浮在凹陷与插画之上（1.12 SetFrameLevel 不递归，绝不动它们）
        local paperdollInset = DFUI.CreateRetailInset(customBg, {
            name         = "DFUI_InspectPaperDollInset",
            anchors      = {3, -58, -6, 6},
            levelOffset  = 0,
            followFrames = {InspectPaperDollFrame},
        })
        paperdollInset.bg:SetVertexColor(0.35, 0.32, 0.28)   -- 暗岩石凹陷底（同天赋页）

        -- 职业背景图（素材同玩家角色页 characterBg，但铺满凹陷而非居中留边）：
        -- 素材复用 media\tex\character\classbg-<token>.tga（256x512 POT，内容 197x355 左上角）。
        -- 建在 paperdollInset 上（BORDER 层：bg=BACKGROUND 之上、凹陷描线=ARTWORK 之下）
        -- 随凹陷 followFrames 自动显隐，且不与 InspectPaperDollFrame 同级纹理抢层。
        -- 职业随被观察目标变化 → OnShow 按 InspectFrame.unit 刷新（token 缓存防反复 SetTexture）
        local CLASS_BG = {WARRIOR=1,PALADIN=1,HUNTER=1,ROGUE=1,PRIEST=1,SHAMAN=1,MAGE=1,WARLOCK=1,DRUID=1}
        local inspectCharBg = paperdollInset:CreateTexture(nil, "BORDER")
        -- 铺满凹陷（同天赋页 illust:SetAllPoints(inset) 做法）：描线 ARTWORK/圆角 OVERLAY 在 BORDER 之上不被盖
        inspectCharBg:SetAllPoints(paperdollInset)
        local charBgToken = nil
        local function UpdateInspectCharBg()
            local _, classToken = UnitClass(InspectFrame.unit or "target")
            if classToken == charBgToken then return end
            charBgToken = classToken
            if classToken and CLASS_BG[classToken] then
                inspectCharBg:SetTexture(TEX .. "character\\classbg-" .. string.lower(classToken) .. ".tga")
                inspectCharBg:SetTexCoord(0, 197/256, 0, 355/512)  -- 裁掉 POT 透明 padding，只显内容区
                inspectCharBg:SetVertexColor(1, 1, 1, 1)
            else
                -- 未知职业（DK/Monk/DH 等 retail 专属，1.12 不存在）→ 隐去，只留暗凹陷底
                inspectCharBg:SetTexture("Interface\\Buttons\\WHITE8X8")
                inspectCharBg:SetTexCoord(0, 1, 0, 1)
                inspectCharBg:SetVertexColor(0, 0, 0, 0.3)
            end
        end
        UpdateInspectCharBg()

        -- ===== 荣誉/竞技场页：marble 凹陷（两页共用，同玩家面板 honorInset）=====
        -- anchors 对齐槽位底图外沿（底图 x22/y-69 → 相对 customBg x10/y-57，凹陷各留 1~2px）
        local honorInset = DFUI.CreateRetailInset(customBg, {
            name         = "DFUI_InspectHonorInset",
            anchors      = {9, -55, -10, 6},
            followFrames = {InspectHonorFrame, InspectArenaFrame},
        })
        -- 抬两页跨过 honorInset：数据 FontString/槽位底图浮在 marble 之上
        if InspectHonorFrame then InspectHonorFrame:SetFrameLevel(honorInset:GetFrameLevel() + 1) end
        if InspectArenaFrame then InspectArenaFrame:SetFrameLevel(honorInset:GetFrameLevel() + 1) end

        RepasteHonorSlots()
        SkinArenaTeams()
        SkinTalents(customBg)

        -- 隐藏所有子框架的辅助函数
        local function HideAllSubFrames()
            if InspectPaperDollFrame then InspectPaperDollFrame:Hide() end
            if InspectHonorFrame then InspectHonorFrame:Hide() end
            if InspectTalentsFrame then InspectTalentsFrame:Hide() end
            if InspectArenaFrame then InspectArenaFrame:Hide() end
        end

        -- 4 个 Tab（真实 id 见 Blizzard_InspectUI.xml：竞技场=3、天赋=4）
        customBg:AddTab("角色", function()
            HideAllSubFrames()
            if InspectPaperDollFrame then InspectPaperDollFrame:Show() end
            PanelTemplates_SetTab(InspectFrame, 1)
        end, 55)

        customBg:AddTab("荣誉", function()
            HideAllSubFrames()
            if InspectHonorFrame then InspectHonorFrame:Show() end
            PanelTemplates_SetTab(InspectFrame, 2)
        end, 55)

        if InspectTalentsFrame then
            customBg:AddTab("天赋", function()
                HideAllSubFrames()
                InspectTalentsFrame:Show()
                PanelTemplates_SetTab(InspectFrame, 4)
            end, 55)
        end

        if InspectArenaFrame then
            customBg:AddTab("竞技场", function()
                HideAllSubFrames()
                InspectArenaFrame:Show()
                PanelTemplates_SetTab(InspectFrame, 3)
            end, 60)
        end

        CenterFrame(InspectFrame)
        HookScript(InspectFrame, "OnShow", function()
            customBg:Show()
            UpdateInspectCharBg()   -- 换观察目标 → 换职业背景
        end)
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function()
        if arg1 == "Blizzard_InspectUI" then
            SkinInspectFrame()
        end
    end)

    if InspectFrame then
        SkinInspectFrame()
    end

    local callbacks = {}
    DFUI:NewCallbacks("Inspect", callbacks)
end)
