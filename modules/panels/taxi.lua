-- taxi.lua — 飞行管理员航点地图(TaxiFrame)换 DF 青铜框皮（共享 SkinQuestStyleFrame 工厂）
-- TaxiFrame 可能 LoadOnDemand(登录时不存在)：延迟到 ADDON_LOADED / TAXIMAP_OPENED(打开飞行)时再换皮
-- 工厂选项：hideMatch="Taxi"(只隐边框留地图) / skipParchment(露地图不要羊皮纸) /
--   insetLevelOffset=8(描边浮地图上) / portraitUnit="player"(玩家头像)；无底部按钮、选点自动飞
-- 铁律：换皮靠工厂 _dfQuestSkinned 守护"只在地图绘制前跑一次"——绝不每次开飞行重跑(会隐掉已画好的地图内容,守护是地图保命机制非仅防泄漏)
--   装饰微调(头像/inset 几何)放 ApplyTaxiTweaks：只动自家 frame、不碰 TaxiFrame region/地图，可安全每次重应用(支持 /reload 调参)

setfenv(1, DFUI:GetEnv())

DFUI:NewDefaults("Taxi", {
    enabled = {true},
})

DFUI:NewMod("Taxi", 5, function()
    -- ▼ inset 锚点可调（改完 /reload 即时生效）
    local IN_L, IN_T, IN_R, IN_B = 6, -60, -16, 12  -- inset 锚点 左/上/右/下
    -- ▲

    -- 装饰重应用：只动自家 frame（头像/inset），绝不碰 TaxiFrame region 或地图 → 守护早返回(含 /reload)后可安全重应用
    local function ApplyTaxiTweaks(bg)
        if not bg then return end
        -- 头像完全照搬 gossip：① NPC(飞行管理员=当前目标)的脸 ② gossip 工厂用的同一个 DFUI.AttachPortrait（BORDER+(-4,8)），金属环框住
        if not bg.dfTaxiPortrait then
            bg.dfTaxiPortrait = bg:CreateTexture(nil, "ARTWORK")
            local gs = GossipFramePortrait and GossipFramePortrait:GetWidth()
            if not gs or gs < 10 then gs = 60 end
            bg.dfTaxiPortrait:SetWidth(gs)
            bg.dfTaxiPortrait:SetHeight(gs)
        end
        SetPortraitTexture(bg.dfTaxiPortrait, UnitExists("target") and "target" or "player")  -- NPC 脸，取不到目标兜底玩家
        if bg.portrait   then bg.portrait:Hide()   end   -- 隐工厂空槽
        if bg.dfTaxiFace then bg.dfTaxiFace:Hide() end   -- 隐上一版残留纹理，防重影
        DFUI.AttachPortrait(bg, bg.dfTaxiPortrait)       -- ← gossip 工厂里那一行，逐字照搬
        -- inset 微调
        local inset = getglobal("DFUI_TaxiBgInset")
        if inset then
            inset:ClearAllPoints()
            inset:SetPoint("TOPLEFT",     bg, "TOPLEFT",     IN_L, IN_T)
            inset:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", IN_R, IN_B)
        end
    end

    local function SkinTaxi()
        if not TaxiFrame then return end
        -- vanilla 飞行框关闭按钮真名 TaxiCloseButton（非 TaxiFrameCloseButton），工厂按名推导拿不到，必须显式隐
        if TaxiCloseButton then TaxiCloseButton:Hide() end
        -- 工厂 set-once 守护：只在 ADDON_LOADED（地图绘制前）真正换皮一次；之后早返回已存在 customBg。
        --   绝不每次重跑——重跑在地图绘制后会破坏航点地图内容（守护=地图保命机制）
        local bg = DFUI.SkinQuestStyleFrame(TaxiFrame, {
            name             = "DFUI_TaxiBg",
            width            = 384,
            height           = 512,
            panels           = {TaxiFrame},
            hideMatch        = "Taxi",       -- 只隐边框艺术，绝不全隐：保留 TaxiRouteMap/航点/连线
            skipParchment    = true,         -- inset 露航点地图，不要羊皮纸
            insetLevelOffset = 8,            -- 抬高 inset 描边浮于高 level 地图之上、bg 隐藏不挡地图
            nameText         = TaxiMerchant, -- 飞行管理员名（工厂内 SetTextColor 判空兜底）
            onClose          = function() HideUIPanel(TaxiFrame) end,
        })
        -- 装饰微调每次安全重应用（含 /reload 守护早返回后）——只动自家 frame，不碰地图
        ApplyTaxiTweaks(bg)
    end

    -- TaxiFrame 可能 LoadOnDemand：已存在则即时换，否则等 addon 加载 / 飞行打开
    if TaxiFrame then SkinTaxi() end
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:RegisterEvent("TAXIMAP_OPENED")
    f:SetScript("OnEvent", function() SkinTaxi() end)

    local callbacks = {}
    DFUI:NewCallbacks("Taxi", callbacks)
end)
