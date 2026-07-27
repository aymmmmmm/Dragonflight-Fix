DFUI:NewDefaults("Player", {
    enabled = {true},
    playerDarkMode = {0, "slider", {0, 1, 0.1}, nil, "外观", 1, "调整深色模式强度", nil, nil},
    playerColor = {{1, 1, 1}, "colour", nil, nil, "外观", 2, "更改玩家颜色", nil, nil},
    eliteBorder = {"standard", "dropdown", {"standard", "rare", "elite", "rare-elite", "boss", "dfui evolved", "dfui nebula"}, nil, "外观", 3, "更改玩家框架的材质", nil, nil},
    frameScale = {1, "slider", {0.7, 1.3, 0.1}, nil, "外观", 4, "调整框架大小", nil, nil},
    classPortrait = {false, "checkbox", nil, nil, "外观", 5, "启用2D职业头像图标", nil, nil},
    frameHide = {false, "checkbox", nil, nil, "外观", 6, "满血且非战斗时隐藏框架", nil, nil},
    textShow = {true, "checkbox", nil, nil, "文字", 7, "显示生命值和法力值文字", nil, nil},
    textMaxShow = {true, "checkbox", nil, "textShow", "文字", 8, "显示最大生命值和法力值文字", nil, nil},
    noPercent = {true, "checkbox", nil, "textShow", "文字", 9, "仅显示当前数值，不显示百分比", nil, nil},
    textColoringHealth = {false, "checkbox", nil, "textShow", "文字", 10, "根据生命值百分比从白色到红色着色文字", nil, nil},
    textColoringResource = {false, "checkbox", nil, "textShow", "文字", 11, "根据资源(法力/怒气/能量)百分比从白色到红色着色文字", nil, nil},
    frameFont = {"FRIZQT__.TTF", "dropdown", {
        "FRIZQT__.TTF",
        "Expressway",
        "Homespun",
        "Hooge",
        "Myriad-Pro",
        "Prototype",
        "PT-Sans-Narrow-Bold",
        "PT-Sans-Narrow-Regular",
        "RobotoMono",
        "BigNoodleTitling",
        "Continuum",
        "DieDieDie"
    }, nil, "文字", 12, "更改玩家框架使用的字体", nil, nil},
    healthSize = {15, "slider", {8, 20, 1}, "textShow", "文字", 13, "生命值文字字体大小", nil, nil},
    manaSize = {9, "slider", {8, 20, 1}, "textShow", "文字", 14, "法力值文字字体大小", nil, nil},
    nameSize = {9, "slider", {6, 16, 1}, nil, "文字", 15, "名字文字字体大小", nil, nil},
    levelSize = {9, "slider", {6, 16, 1}, nil, "文字", 16, "等级文字字体大小", nil, nil},
    classColor = {false, "checkbox", nil, nil, "生命值条", 17, "根据职业着色生命值条", nil, nil},
    enablePulse = {true, "checkbox", nil, nil, "生命值条", 18, "启用生命值条脉冲动画", nil, nil},
    pulseColor = {{1, 1, 1}, "colour", nil, "enablePulse", "生命值条", 19, "脉冲动画颜色", nil, nil},
    enableCutout = {true, "checkbox", nil, nil, "生命值条", 20, "启用生命值条切割动画", nil, nil},
    cutoutColor = {{1, 0, 0}, "colour", nil, "enableCutout", "生命值条", 21, "伤害切割效果颜色", nil, nil},
    energyTick = {true, "checkbox", nil, nil, "生命值条", 22, "显示能量和法力回复指示器", nil, nil},
    combatGlow = {true, "checkbox", nil, nil, "战斗效果", 23, "启用战斗脉冲动画", nil, nil},
    glowSpeed = {1, "slider", {0.4, 5, 0.1}, "combatGlow", "战斗效果", 24, "调整战斗脉冲速度", nil, nil},
    glowAlpha = {1, "slider", {0.1, 1, 0.1}, "combatGlow", "战斗效果", 25, "调整战斗脉冲最大透明度", nil, nil},
    restingGlow = {true, "checkbox", nil, nil, "休息效果", 26, "启用休息发光动画", nil, nil},
    restingSpeed = {1, "slider", {0.4, 5, 0.1}, "restingGlow", "休息效果", 27, "调整休息脉冲速度", nil, nil},
    restingAlpha = {1, "slider", {0.1, 1, 0.1}, "restingGlow", "休息效果", 28, "调整休息脉冲最大透明度", nil, nil},
    restingColor = {{0, 1, 1}, "colour", nil, "restingGlow", "休息效果", 29, "更改休息发光动画的颜色", nil, nil},
})

DFUI:NewMod("Player", 1, function()
    local Setup = {
        texpath = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\unitframes\\",
        texpath2 = "Interface\\AddOns\\Dragonflight-Fix\\media\\tex\\ui\\",
        fontpath = "Interface\\AddOns\\Dragonflight-Fix\\media\\fnt\\",

        hideFrame = nil,
        combatOverlay = nil,
        combatOverlayTex = nil,
        combatGlow = {
            fadeSpeed = 1.0,
            alphaMin = 0,
            alphaMax = 1.0,
        },

        restingOverlay = nil,
        restingOverlayTex = nil,
        restingGlow = {
            fadeSpeed = 1.0,
            alphaMin = 0,
            alphaMax = 1.0,
            color = {0, 1, 1},
        },

        texts = {
            healthPercent = nil,
            healthValue = nil,
            healthPercentShow = true,
            manaPercent = nil,
            manaValue = nil,
            manaPercentShow = true,
            config = {
                font = "Fonts\\FRIZQT__.TTF",
                healthFontSize = 12,
                manaFontSize = 9,
                nameFontSize = 9,
                levelFontSize = 9,
                outline = "NONE",
                nameColor = {1, .82, 0},
                levelColor = {1, .82, 0},
                healthColor = {1, 1, 1},
                manaColor = {1, 1, 1},
            }
        }
    }

    
    function Setup:HealthBar()
        if PlayerFrameHealthBar then
            PlayerFrameHealthBar:Hide()
            PlayerFrameHealthBar.Show = function() end
        end
        if PlayerFrameHealthBarText then
            PlayerFrameHealthBarText:Hide()
            PlayerFrameHealthBarText.Show = function() end
        end
        if PlayerFrameHealthBarTextLeft then
            PlayerFrameHealthBarTextLeft:Hide()
            PlayerFrameHealthBarTextLeft.Show = function() end
        end
        if PlayerFrameHealthBarTextRight then
            PlayerFrameHealthBarTextRight:Hide()
            PlayerFrameHealthBarTextRight.Show = function() end
        end
        self.healthBar = CreateStatusBar(PlayerFrame, 130, 30)
        self.healthBar:SetPoint('TOPLEFT', PlayerFrame, 'TOPLEFT', 100, -29)
        self.healthBar:SetTextures(self.texpath .. 'healthDF2.tga')
        self.healthBar.max = UnitHealthMax('player')
        self.healthBar:SetValue(UnitHealth('player'))
        local cutoutColor = DFUI:GetTempDB('Player', 'cutoutColor')
        local pulseColor = DFUI:GetTempDB('Player', 'pulseColor')
        self.healthBar:SetCutoutColor(cutoutColor[1], cutoutColor[2], cutoutColor[3], 1)
        self.healthBar:SetPulseColor(pulseColor[1], pulseColor[2], pulseColor[3], 1)
        DFUI.predictBars.player = self.healthBar
    end

    function Setup:HealthBarText()
        PlayerFrameHealthBarText:ClearAllPoints()
        PlayerFrameHealthBarText:SetText("")
        local cfg = self.texts.config
        self.texts.healthTextFrame = CreateFrame("Frame", nil, PlayerFrame)
        self.texts.healthTextFrame:SetAllPoints(self.healthBar)
        self.texts.healthTextFrame:SetFrameStrata(PlayerFrame:GetFrameStrata())
        self.texts.healthTextFrame:SetFrameLevel(PlayerFrame:GetFrameLevel() + 2)
        self.texts.healthPercent = self.texts.healthTextFrame:CreateFontString(nil)
        self.texts.healthPercent:SetFont(cfg.font, cfg.healthFontSize, "OUTLINE")
        self.texts.healthPercent:SetPoint('LEFT', self.healthBar, 'LEFT', 5, 0)
        self.texts.healthValue = self.texts.healthTextFrame:CreateFontString(nil)
        self.texts.healthValue:SetFont(cfg.font, cfg.healthFontSize, "OUTLINE")
        -- 护盾模块要在生命值文字后追加吸收量; texts 存在本闭包的 local Setup 里,
        -- 外部拿不到, 所以和 predictBars 一样注册出去
        DFUI.unitTexts.player = self.texts
    end

    function Setup:ManaBar()
        if PlayerFrameManaBar then
            PlayerFrameManaBar:Hide()
            PlayerFrameManaBar.Show = function() end
        end
        if PlayerFrameManaBarText then
            PlayerFrameManaBarText:Hide()
            PlayerFrameManaBarText.Show = function() end
        end
        if PlayerFrameManaBarTextLeft then
            PlayerFrameManaBarTextLeft:Hide()
            PlayerFrameManaBarTextLeft.Show = function() end
        end
        if PlayerFrameManaBarTextRight then
            PlayerFrameManaBarTextRight:Hide()
            PlayerFrameManaBarTextRight.Show = function() end
        end
        self.manaBar = CreateStatusBar(PlayerFrame, 130, 12)
        self.manaBar:SetPoint('TOPLEFT', PlayerFrame, 'TOPLEFT', 100, -53)
        self.manaBar:SetTextures(self.texpath .. 'UI-HUD-UnitFrame-Player-PortraitOn-Bar-Mana-Status.tga')
        self.manaBar.max = UnitManaMax('player')
        self.manaBar:SetValue(UnitMana('player'))
        local r, g, b = GetPowerColor(UnitPowerType('player'))
        self.manaBar:SetFillColor(r, g, b, 1)
        local cutoutColor = DFUI:GetTempDB('Player', 'cutoutColor')
        local pulseColor = DFUI:GetTempDB('Player', 'pulseColor')
        self.manaBar:SetCutoutColor(cutoutColor[1], cutoutColor[2], cutoutColor[3], 1)
        self.manaBar:SetPulseColor(pulseColor[1], pulseColor[2], pulseColor[3], 1)
    end

    function Setup:ManaBarText()
        PlayerFrameManaBarText:SetText("")
        PlayerFrameManaBarText:ClearAllPoints()
        local cfg = self.texts.config
        self.texts.manaTextFrame = CreateFrame("Frame", nil, PlayerFrame)
        self.texts.manaTextFrame:SetAllPoints(self.manaBar)
        self.texts.manaTextFrame:SetFrameStrata(PlayerFrame:GetFrameStrata())
        self.texts.manaTextFrame:SetFrameLevel(PlayerFrame:GetFrameLevel() + 2)
        self.texts.manaPercent = self.texts.manaTextFrame:CreateFontString(nil)
        self.texts.manaPercent:SetFont(cfg.font, cfg.manaFontSize, cfg.outline)
        self.texts.manaPercent:SetPoint('LEFT', self.manaBar, 'LEFT', 5, 0)
        self.texts.manaValue = self.texts.manaTextFrame:CreateFontString(nil)
        self.texts.manaValue:SetFont(cfg.font, cfg.manaFontSize, cfg.outline)
    end

    function Setup:FrameTextures()
        PlayerFrameTexture:SetTexture(self.texpath .. "UI-TargetingFrameDF.blp")
        PlayerFrameTexture:SetWidth(256)
        PlayerFrameTexture:SetHeight(128)
        PlayerFrameTexture:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 0, 0)
        PlayerFrameTexture:SetDrawLayer("BACKGROUND")
        PlayerFrameBackground:SetTexture(self.texpath .. "UI-TargetingFrameDF-Background.blp")
        PlayerFrameBackground:SetWidth(256)
        PlayerFrameBackground:SetHeight(128)
        PlayerFrameBackground:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 0, 0)
        PlayerFrameBackground:SetDrawLayer("BACKGROUND")
        PlayerStatusTexture:SetTexture("")
    end

    function Setup:Portrait()
        PlayerFrame.portrait:SetHeight(62)
        PlayerFrame.portrait:SetWidth(62)
    end

    function Setup:NameText()
        local cfg = self.texts.config
        PlayerFrame.name:ClearAllPoints()
        PlayerFrame.name:SetPoint("LEFT", PlayerFrame, "LEFT", 80, 25)
        PlayerFrame.name:SetFont(cfg.font, cfg.nameFontSize, cfg.outline)
        PlayerFrame.name:SetTextColor(unpack(cfg.nameColor))
    end

    function Setup:LevelText()
        local cfg = self.texts.config
        PlayerLevelText:ClearAllPoints()
        PlayerLevelText:SetPoint("RIGHT", PlayerFrame, "RIGHT", -14, 25)
        PlayerLevelText:SetFont(cfg.font, cfg.levelFontSize, cfg.outline)
        PlayerLevelText:SetTextColor(unpack(cfg.levelColor))
    end

    function Setup:CombatGlow()
        function _G.PlayerFrame_UpdateStatus() end
        PlayerAttackGlow:SetTexture("")
        -- 保留 PlayerAttackIcon 原生纹理(Interface\CharacterFrame\UI-StateIcon)与 TexCoord,
        -- 仅重新锚到蓝条下方,显隐由 Setup:StateIcons() 自管
        PlayerAttackIcon:ClearAllPoints()
        PlayerAttackIcon:SetPoint("TOPLEFT", Setup.manaBar, "BOTTOMLEFT", -60, 20)
        PlayerAttackIcon:SetWidth(24)
        PlayerAttackIcon:SetHeight(24)
        -- 收紧 bottom 到 0.49 裁掉剑下方黑边(参考 TWThreat 同图集用法)
        PlayerAttackIcon:SetTexCoord(0.5, 1.0, 0, 0.49)
        PlayerAttackIcon:Hide()
        Setup.combatOverlay = CreateFrame("Frame", nil, PlayerFrame)
        Setup.combatOverlay:SetAllPoints(PlayerFrame)
        Setup.combatOverlay:SetFrameStrata("MEDIUM")
        Setup.combatOverlayTex = Setup.combatOverlay:CreateTexture(nil, "OVERLAY")
        Setup.combatOverlayTex:SetTexture(Setup.texpath.. "UI-Player-Status.blp")
        Setup.combatOverlayTex:SetPoint("CENTER", PlayerFrame, "CENTER", 45, -21)
        Setup.combatOverlayTex:SetVertexColor(1, 0, 0)
        Setup.combatOverlayTex:SetBlendMode("ADD")
        Setup.combatOverlayTex:SetAlpha(0)
    end

    function Setup:RestingGlow()
        PlayerRestGlow:SetTexture("")
        -- 保留 PlayerRestIcon 原生 Zzz 纹理与 TexCoord,与攻击图标共用蓝条下方位置(二者互斥)
        PlayerRestIcon:ClearAllPoints()
        PlayerRestIcon:SetPoint("TOPLEFT", Setup.manaBar, "BOTTOMLEFT", -60, 20)
        PlayerRestIcon:SetWidth(24)
        PlayerRestIcon:SetHeight(24)
        PlayerRestIcon:Hide()
        Setup.restingOverlay = CreateFrame("Frame", nil, PlayerFrame)
        Setup.restingOverlay:SetAllPoints(PlayerFrame)
        Setup.restingOverlayTex = Setup.restingOverlay:CreateTexture(nil, "OVERLAY")
        Setup.restingOverlayTex:SetTexture(Setup.texpath.. "UI-Player-Status.blp")
        Setup.restingOverlayTex:SetPoint("CENTER", PlayerFrame, "CENTER", 45, -21)
        Setup.restingOverlayTex:SetVertexColor(Setup.restingGlow.color[1], Setup.restingGlow.color[2], Setup.restingGlow.color[3])
        Setup.restingOverlayTex:SetBlendMode("ADD")
        Setup.restingOverlayTex:SetAlpha(0)
    end

    -- 状态图标显隐:复用 vanilla 原生 PlayerAttackIcon(剑)/PlayerRestIcon(Zzz),
    -- 二者互斥(战斗优先),纹理与 TexCoord 在 CombatGlow/RestingGlow 中已就位
    function Setup:UpdateStateIcons()
        if UnitAffectingCombat("player") then
            PlayerRestIcon:Hide()
            PlayerAttackIcon:Show()
        else
            PlayerAttackIcon:Hide()
            if IsResting() and PlayerFrame:IsShown() then
                PlayerRestIcon:Show()
            else
                PlayerRestIcon:Hide()
            end
        end
    end

    function Setup:StateIcons()
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:RegisterEvent("PLAYER_REGEN_DISABLED")
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
        f:RegisterEvent("PLAYER_UPDATE_RESTING")
        f:SetScript("OnEvent", function()
            Setup:UpdateStateIcons()
        end)

        -- 图标呼吸:对当前显示的剑/Zzz 做 alpha 脉冲(0.45~1.0),沿用插件 this.tick 限频风格
        local pulseTime = 0
        f:SetScript("OnUpdate", function()
            local now = GetTime()
            if (this.tick or 0) > now then
                DFUI.activeScripts["StateIconPulse"] = false
                return
            end
            this.tick = now + 0.01

            local icon = (PlayerAttackIcon:IsShown() and PlayerAttackIcon)
                or (PlayerRestIcon:IsShown() and PlayerRestIcon)
            if not icon then
                DFUI.activeScripts["StateIconPulse"] = false
                return
            end

            pulseTime = pulseTime + arg1
            icon:SetAlpha(0.45 + 0.55 * (0.5 + 0.5 * math.sin(pulseTime * 3)))
            DFUI.activeScripts["StateIconPulse"] = true
        end)

        Setup:UpdateStateIcons()
    end

    function Setup:EnergyTick()
        self.energyTickFrame = CreateFrame('Frame', nil, self.manaBar)
        self.energyTickFrame:SetAllPoints(self.manaBar)
        self.energyTickFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
        self.energyTickFrame:RegisterEvent('UNIT_DISPLAYPOWER')
        self.energyTickFrame:RegisterEvent('UNIT_ENERGY')
        self.energyTickFrame:RegisterEvent('UNIT_MANA')
        self.energyTickFrame:SetScript('OnEvent', function()
            if UnitPowerType('player') == 0 then
                this.mode = 'MANA'
                this:Show()
            elseif UnitPowerType('player') == 3 then
                this.mode = 'ENERGY'
                this:Show()
            else
                this:Hide()
            end

            if event == 'PLAYER_ENTERING_WORLD' then
                this.lastMana = UnitMana('player')
            end

            if (event == 'UNIT_MANA' or event == 'UNIT_ENERGY') and arg1 == 'player' then
                this.currentMana = UnitMana('player')
                local diff = 0
                if this.lastMana then
                    diff = this.currentMana - this.lastMana
                end

                if this.mode == 'MANA' and diff < 0 then
                    this.target = 5
                elseif this.mode == 'MANA' and diff > 0 then
                    if this.max ~= 5 and diff > (this.badtick and this.badtick*1.2 or 5) then
                        this.target = 2
                    else
                        this.badtick = diff
                    end
                elseif this.mode == 'ENERGY' and diff > 0 then
                    this.target = 2
                end
                this.lastMana = this.currentMana
            end
        end)

        self.energyTickFrame.spark = self.energyTickFrame:CreateTexture(nil, 'OVERLAY')
        self.energyTickFrame.spark:SetTexture('Interface\\CastingBar\\UI-CastingBar-Spark')
        self.energyTickFrame.spark:SetHeight(27)
        self.energyTickFrame.spark:SetWidth(17)
        self.energyTickFrame.spark:SetBlendMode('ADD')
    end

    function Setup:Run()
        self:FrameTextures()
        self:HealthBar()
        self:HealthBarText()
        self:ManaBar()
        self:ManaBarText()
        self:Portrait()
        self:LevelText()
        self:NameText()
        self:CombatGlow()
        self:RestingGlow()
        self:StateIcons()
        self:EnergyTick()
    end

    -- callbacks
    local callbacks = {}

    callbacks.playerDarkMode = function(value)
        local intensity = DFUI:GetTempDB("Player", "playerDarkMode")
        local playerColor = DFUI:GetTempDB("Player", "playerColor")
        local r, g, b = playerColor[1] * (1 - intensity), playerColor[2] * (1 - intensity), playerColor[3] * (1 - intensity)
        local color = value and {r, g, b} or {1, 1, 1}

        PlayerFrameTexture:SetVertexColor(color[1], color[2], color[3])
        PlayerFrameBackground:SetVertexColor(color[1], color[2], color[3])
    end

    callbacks.playerColor = function(value)
        local intensity = DFUI:GetTempDB("Player", "playerDarkMode")
        local r, g, b = value[1] * (1 - intensity), value[2] * (1 - intensity), value[3] * (1 - intensity)

        PlayerFrameTexture:SetVertexColor(r, g, b)
        PlayerFrameBackground:SetVertexColor(r, g, b)
    end

    callbacks.textMaxShow = function(value)
        Setup.texts.showMaxValues = value
        callbacks.textShow(DFUI:GetTempDB("Player", "textShow"))
    end

    callbacks.textShow = function(value)
        if value then
            local health = UnitHealth("player")
            local maxHealth = UnitHealthMax("player")
            local healthPercent = maxHealth > 0 and math.floor((health / maxHealth) * 100) or 0

            local mana = UnitMana("player")
            local maxMana = UnitManaMax("player")
            local manaPercent = maxMana > 0 and math.floor((mana / maxMana) * 100) or 0

            if Setup.texts.healthPercentShow then
                Setup.texts.healthPercent:SetText(healthPercent .. "%")
                Setup.texts.healthPercent:Show()
            else
                Setup.texts.healthPercent:SetText("")
                Setup.texts.healthPercent:Hide()
            end

            if Setup.texts.manaPercentShow then
                Setup.texts.manaPercent:SetText(manaPercent .. "%")
                Setup.texts.manaPercent:Show()
            else
                Setup.texts.manaPercent:SetText("")
                Setup.texts.manaPercent:Hide()
            end

            Setup.texts.healthValue:SetText(health .. (Setup.texts.showMaxValues and "/" .. maxHealth or ""))
            Setup.texts.manaValue:SetText(mana .. (Setup.texts.showMaxValues and "/" .. maxMana or ""))
            Setup.texts.healthValue:Show()
            Setup.texts.manaValue:Show()

            if not Setup.texts.healthPercentShow then
                Setup.texts.healthValue:ClearAllPoints()
                Setup.texts.healthValue:SetPoint('CENTER', Setup.healthBar, 'CENTER', -3, 1)
            else
                Setup.texts.healthValue:ClearAllPoints()
                Setup.texts.healthValue:SetPoint('RIGHT', Setup.healthBar, 'RIGHT', -5, 1)
            end

            if not Setup.texts.manaPercentShow then
                Setup.texts.manaValue:ClearAllPoints()
                Setup.texts.manaValue:SetPoint('CENTER', Setup.manaBar, 'CENTER', -3, 0)
            else
                Setup.texts.manaValue:ClearAllPoints()
                Setup.texts.manaValue:SetPoint('RIGHT', Setup.manaBar, 'RIGHT', -5, 0)
            end
        else
            Setup.texts.healthPercent:Hide()
            Setup.texts.healthValue:Hide()
            Setup.texts.manaPercent:Hide()
            Setup.texts.manaValue:Hide()
        end
    end

    callbacks.frameFont = function(value)
        local fontPath = GetFontPath(value)

        Setup.texts.config.font = fontPath
        Setup.texts.healthPercent:SetFont(fontPath, Setup.texts.config.healthFontSize, "OUTLINE")
        Setup.texts.healthValue:SetFont(fontPath, Setup.texts.config.healthFontSize, "OUTLINE")
        Setup.texts.manaPercent:SetFont(fontPath, Setup.texts.config.manaFontSize, "OUTLINE")
        Setup.texts.manaValue:SetFont(fontPath, Setup.texts.config.manaFontSize, "OUTLINE")
        Setup:NameText()
        Setup:LevelText()
    end

    callbacks.noPercent = function(value)
        Setup.texts.healthPercentShow = not value
        Setup.texts.manaPercentShow = not value

        callbacks.textShow(DFUI:GetTempDB("Player", "textShow"))
    end

    callbacks.textColoringHealth  = function(value)
        if value then
            local healthPercent = UnitHealthMax("player") > 0 and (UnitHealth("player") / UnitHealthMax("player")) or 1
            Setup.texts.healthValue:SetTextColor(1, healthPercent, healthPercent)
            Setup.texts.healthPercent:SetTextColor(1, healthPercent, healthPercent)
        else
            local hc = Setup.texts.config.healthColor
            Setup.texts.healthValue:SetTextColor(hc[1], hc[2], hc[3])
            Setup.texts.healthPercent:SetTextColor(hc[1], hc[2], hc[3])
        end
    end

    callbacks.textColoringResource = function(value)
        if value then
            local manaPercent = UnitManaMax("player") > 0 and (UnitMana("player") / UnitManaMax("player")) or 1
            Setup.texts.manaValue:SetTextColor(1, manaPercent, manaPercent)
            Setup.texts.manaPercent:SetTextColor(1, manaPercent, manaPercent)
        else
            local mc = Setup.texts.config.manaColor
            Setup.texts.manaValue:SetTextColor(mc[1], mc[2], mc[3])
            Setup.texts.manaPercent:SetTextColor(mc[1], mc[2], mc[3])
        end
    end

    callbacks.healthSize = function(value)
        Setup.texts.config.healthFontSize = value
        Setup.texts.healthPercent:SetFont(Setup.texts.config.font, value, "OUTLINE")
        Setup.texts.healthValue:SetFont(Setup.texts.config.font, value, "OUTLINE")
    end

    callbacks.manaSize = function(value)
        Setup.texts.config.manaFontSize = value
        Setup.texts.manaPercent:SetFont(Setup.texts.config.font, value, "OUTLINE")
        Setup.texts.manaValue:SetFont(Setup.texts.config.font, value, "OUTLINE")
    end

    callbacks.nameSize = function(value)
        Setup.texts.config.nameFontSize = value
        PlayerFrame.name:SetFont(Setup.texts.config.font, value, Setup.texts.config.outline)
    end

    callbacks.levelSize = function(value)
        Setup.texts.config.levelFontSize = value
        PlayerLevelText:SetFont(Setup.texts.config.font, value, Setup.texts.config.outline)
    end

    callbacks.classColor = function(value)
        if Setup.healthBar then
            if value then
                local _, class = UnitClass('player')
                local color = DFUI:GetClassColor(class)
                if color then
                    Setup.healthBar:SetFillColor(color.r, color.g, color.b, 1)
                else
                    Setup.healthBar:SetFillColor(0, 1, 0, 1)
                end
            else
                Setup.healthBar:SetFillColor(0, 1, 0, 1)
            end
        end
    end

    callbacks.cutoutColor = function(value)
        if Setup.healthBar then
            Setup.healthBar:SetCutoutColor(value[1], value[2], value[3], 1)
        end
        if Setup.manaBar then
            Setup.manaBar:SetCutoutColor(value[1], value[2], value[3], 1)
        end
    end

    callbacks.pulseColor = function(value)
        if Setup.healthBar then
            Setup.healthBar:SetPulseColor(value[1], value[2], value[3], 1)
        end
        if Setup.manaBar then
            Setup.manaBar:SetPulseColor(value[1], value[2], value[3], 1)
        end
    end

    callbacks.enablePulse = function(value)
        if Setup.healthBar then
            Setup.healthBar:SetPulseAnimation(value)
        end
        if Setup.manaBar then
            Setup.manaBar:SetPulseAnimation(value)
        end
    end

    callbacks.enableCutout = function(value)
        if Setup.healthBar then
            Setup.healthBar:SetCutoutAnimation(value)
        end
        if Setup.manaBar then
            Setup.manaBar:SetCutoutAnimation(value)
        end
    end

    callbacks.frameHide = function(value)
        if Setup.hideFrame then
            Setup.hideFrame:UnregisterAllEvents()
            Setup.hideFrame:SetScript("OnEvent", nil)
            Setup.hideFrame = nil
        end

        local function updatePlayerFrameAndResting()
            local health = UnitHealth("player")
            local maxHealth = UnitHealthMax("player")
            local inCombat = UnitAffectingCombat("player")

            if health == maxHealth and not inCombat then
                PlayerFrame:Hide()
            else
                PlayerFrame:Show()
                Setup:UpdateStateIcons()
            end
        end

        if value then
            Setup.hideFrame = CreateFrame("Frame")
            Setup.hideFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
            Setup.hideFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
            Setup.hideFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            Setup.hideFrame:RegisterEvent("UNIT_HEALTH")
            Setup.hideFrame:SetScript("OnEvent", function()
                updatePlayerFrameAndResting()
            end)

            updatePlayerFrameAndResting()
        else
            PlayerFrame:Show()
            Setup:UpdateStateIcons()
        end
    end

    callbacks.classPortrait = function(value)
        if value then
            local CLASS_ICON_TCOORDS = {
                ["WARRIOR"] = { 0, 0.25, 0, 0.25 },
                ["MAGE"] = { 0.25, 0.49609375, 0, 0.25 },
                ["ROGUE"] = { 0.49609375, 0.7421875, 0, 0.25 },
                ["DRUID"] = { 0.7421875, 0.98828125, 0, 0.25 },
                ["HUNTER"] = { 0, 0.25, 0.25, 0.5 },
                ["SHAMAN"] = { 0.25, 0.49609375, 0.25, 0.5 },
                ["PRIEST"] = { 0.49609375, 0.7421875, 0.25, 0.5 },
                ["WARLOCK"] = { 0.7421875, 0.98828125, 0.25, 0.5 },
                ["PALADIN"] = { 0, 0.25, 0.5, 0.75 },
                ["DEATHKNIGHT"] = { 0.25, .5, 0.5, .75 },
            }

            DFUI.UpdatePortraits = function(frame)
                if not frame or not frame.unit then return end

                local _, class = UnitClass(frame.unit)
                class = UnitIsPlayer(frame.unit) and class or nil

                if class and frame.portrait then
                    local iconCoords = CLASS_ICON_TCOORDS[class]
                    frame.portrait:SetTexture(Setup.texpath2 .."UI-Classes-Circles.tga")
                    frame.portrait:SetTexCoord(unpack(iconCoords))
                elseif not class and frame.portrait then
                    frame.portrait:SetTexCoord(0, 1, 0, 1)
                end
            end

            -- hook UnitFrame_Update
            hooksecurefunc("UnitFrame_Update", function()
                DFUI.UpdatePortraits(this)
            end, true)

            -- event handler
            DFUI.portraitEvents = CreateFrame("Frame")
            DFUI.portraitEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
            DFUI.portraitEvents:RegisterEvent("UNIT_PORTRAIT_UPDATE")
            DFUI.portraitEvents:RegisterEvent("PLAYER_TARGET_CHANGED")
            DFUI.portraitEvents:SetScript("OnEvent", function()
                DFUI.UpdatePortraits(PlayerFrame)
                DFUI.UpdatePortraits(TargetFrame)
                DFUI.UpdatePortraits(PartyMemberFrame1)
                DFUI.UpdatePortraits(PartyMemberFrame2)
                DFUI.UpdatePortraits(PartyMemberFrame3)
                DFUI.UpdatePortraits(PartyMemberFrame4)
            end)

            -- init
            DFUI.UpdatePortraits(PlayerFrame)
            DFUI.UpdatePortraits(TargetFrame)
            DFUI.UpdatePortraits(PartyMemberFrame1)
            DFUI.UpdatePortraits(PartyMemberFrame2)
            DFUI.UpdatePortraits(PartyMemberFrame3)
            DFUI.UpdatePortraits(PartyMemberFrame4)

            -- tot update (throttled to 0.2s)
            DFUI.totPortraitFrame = CreateFrame("Frame", nil, TargetFrame)
            DFUI.totPortraitFrame.nextUpdate = 0
            DFUI.totPortraitFrame:SetScript("OnUpdate", function()
                local now = GetTime()
                if now < this.nextUpdate then return end
                this.nextUpdate = now + 0.2
                DFUI.UpdatePortraits(TargetofTargetFrame)
                DFUI.activeScripts["PortraitUpdateScript"] = true
            end)
        else
            -- disable class portraits
            -- restore original function by setting hook function to nothing
            DFUI.UpdatePortraits = function() end

            -- unregister events
            if DFUI.portraitEvents then
                DFUI.portraitEvents:UnregisterAllEvents()
                DFUI.portraitEvents:SetScript("OnEvent", nil)
            end

            -- remove target of target updates
            if DFUI.totPortraitFrame then
                DFUI.totPortraitFrame:SetScript("OnUpdate", nil)
                DFUI.activeScripts["PortraitUpdateScript"] = false
            end

            -- reset portraits to default
            local function ResetPortrait(frame)
                if frame and frame.portrait then
                    frame.portrait:SetTexCoord(0, 1, 0, 1)
                    SetPortraitTexture(frame.portrait, frame.unit)
                end
            end

            ResetPortrait(PlayerFrame)
            ResetPortrait(TargetFrame)
            ResetPortrait(PartyMemberFrame1)
            ResetPortrait(PartyMemberFrame2)
            ResetPortrait(PartyMemberFrame3)
            ResetPortrait(PartyMemberFrame4)
            ResetPortrait(TargetofTargetFrame)
        end
    end

    callbacks.frameScale = function(value)
        PlayerFrame:SetScale(value)
    end

    callbacks.combatGlow = function (value)
        if not Setup.combatOverlay or not Setup.combatOverlayTex then return end

        local pulseTime = 0
        local pulseDuration = 1 / Setup.combatGlow.fadeSpeed

        if value then
            Setup.combatOverlay:SetScript("OnUpdate", function()
                local now = GetTime()
                if (this.tick or 0) > now then
                    DFUI.activeScripts["CombatGlowScript"] = false
                    return
                end
                this.tick = now + 0.01

                local elapsed = arg1
                if not UnitAffectingCombat("player") then
                    local alpha = Setup.combatOverlayTex:GetAlpha()
                    alpha = alpha - (Setup.combatGlow.fadeSpeed * elapsed * 2)
                    if alpha < 0 then alpha = 0 end
                    Setup.combatOverlayTex:SetAlpha(alpha)
                    DFUI.activeScripts["CombatGlowScript"] = true
                    return
                end

                pulseTime = pulseTime + elapsed
                if pulseTime > pulseDuration then
                    pulseTime = pulseTime - pulseDuration
                end
                local progress = pulseTime / pulseDuration
                local alpha = Setup.combatGlow.alphaMin + (Setup.combatGlow.alphaMax - Setup.combatGlow.alphaMin) * (0.5 + 0.5 * math.sin(progress * 2 * math.pi))
                Setup.combatOverlayTex:SetAlpha(alpha)
                DFUI.activeScripts["CombatGlowScript"] = true
            end)
        else
            Setup.combatOverlay:SetScript("OnUpdate", nil)
            Setup.combatOverlayTex:SetAlpha(0)
        end

        if not Setup.combatGlowEventFrame then
            Setup.combatGlowEventFrame = CreateFrame("Frame")
            Setup.combatGlowEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
            Setup.combatGlowEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            Setup.combatGlowEventFrame:SetScript("OnEvent", function()
                if event == "PLAYER_REGEN_DISABLED" then
                    currentAlpha = Setup.combatGlow.alphaMin
                    fadeDirection = 1
                elseif event == "PLAYER_REGEN_ENABLED" then
                    fadeDirection = -1
                end
            end)
        end
    end

    callbacks.glowSpeed = function(value)
        Setup.combatGlow.fadeSpeed = value
        callbacks.combatGlow(DFUI:GetTempDB("Player", "combatGlow"))
    end

    callbacks.glowAlpha = function(value)
        Setup.combatGlow.alphaMax = value
        callbacks.combatGlow(DFUI:GetTempDB("Player", "combatGlow"))
    end

    callbacks.restingGlow = function(value)
        if not Setup.restingOverlay or not Setup.restingOverlayTex then return end

        local pulseTime = 0
        local pulseDuration = 1 / Setup.restingGlow.fadeSpeed

        if value then
            Setup.restingOverlay:SetScript("OnUpdate", function()
                local now = GetTime()
                if (this.tick or 0) > now then
                    DFUI.activeScripts["RestingGlowScript"] = false
                    return
                end
                this.tick = now + 0.01

                local elapsed = arg1
                if not IsResting() then
                    local alpha = Setup.restingOverlayTex:GetAlpha()
                    alpha = alpha - (Setup.restingGlow.fadeSpeed * elapsed * 2)
                    if alpha < 0 then alpha = 0 end
                    Setup.restingOverlayTex:SetAlpha(alpha)
                    DFUI.activeScripts["RestingGlowScript"] = true
                    return
                end

                pulseTime = pulseTime + elapsed
                if pulseTime > pulseDuration then
                    pulseTime = pulseTime - pulseDuration
                end
                local progress = pulseTime / pulseDuration

                local alpha = Setup.restingGlow.alphaMin + (Setup.restingGlow.alphaMax - Setup.restingGlow.alphaMin) * (0.5 + 0.5 * math.sin(progress * 2 * math.pi))
                Setup.restingOverlayTex:SetAlpha(alpha)
                DFUI.activeScripts["RestingGlowScript"] = true
            end)
        else
            Setup.restingOverlay:SetScript("OnUpdate", nil)
            Setup.restingOverlayTex:SetAlpha(0)
        end

        if not Setup.restingGlowEventFrame then
            Setup.restingGlowEventFrame = CreateFrame("Frame")
            Setup.restingGlowEventFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
            Setup.restingGlowEventFrame:SetScript("OnEvent", function()
                currentAlpha = Setup.restingGlow.alphaMin
                fadeDirection = 1
            end)
        end
    end

    callbacks.restingSpeed = function(value)
        Setup.restingGlow.fadeSpeed = value
        callbacks.restingGlow(DFUI:GetTempDB("Player", "restingGlow"))
    end

    callbacks.restingAlpha = function(value)
        Setup.restingGlow.alphaMax = value
        callbacks.restingGlow(DFUI:GetTempDB("Player", "restingGlow"))
    end

    callbacks.restingColor = function (value)
        Setup.restingGlow.color = value
        Setup.restingOverlayTex:SetVertexColor(value[1], value[2], value[3])
    end

    callbacks.energyTick = function(value)
        if not Setup.energyTickFrame then return end

        if value then
            Setup.energyTickFrame:SetScript('OnUpdate', function()
                if this.target then
                    this.start, this.max = GetTime(), this.target
                    this.target = nil
                end

                if not this.start then return end

                this.current = GetTime() - this.start

                if this.current > this.max then
                    this.start, this.max, this.current = GetTime(), 2, 0
                end

                local pos = 130 * (this.current / this.max)
                this.spark:SetPoint('LEFT', pos - 8.5, 0)
            end)
        else
            Setup.energyTickFrame:SetScript('OnUpdate', nil)
        end
    end

    callbacks.eliteBorder = function(value)
        local tex
        if value == "rare" then
            tex = Setup.texpath .. "UI-TargetingFrame-Rare.blp"
        elseif value == "elite" then
            tex = Setup.texpath .. "UI-TargetingFrame-Elite.blp"
        elseif value == "rare-elite" then
            tex = Setup.texpath .. "UI-TargetingFrame-RareElite.blp"
        elseif value == "boss" then
            tex = Setup.texpath .. "UI-TargetingFrame-Boss.blp"
        elseif value == "dfui nebula" then
            tex = Setup.texpath .. "guzruul_nebula_v1.tga"
        elseif value == "dfui evolved" then
            tex = Setup.texpath .. "guzruul_evolved_v1.tga"
        else
            tex = Setup.texpath .. "UI-TargetingFrameDF.blp"
        end
        PlayerFrameTexture:SetTexture(tex)
    end

    -- 把血/蓝条的取值刷新独立出来, 供事件处理器和重试帧共用
    local function RefreshPlayerBars()
        if Setup.healthBar then
            Setup.healthBar.max = UnitHealthMax('player')
            Setup.healthBar:SetValue(UnitHealth('player'))
        end
        if Setup.manaBar then
            Setup.manaBar.max = UnitManaMax('player')
            local mana = UnitMana('player')
            Setup.manaBar:SetValue(mana > 0 and mana or 0.001)
            local r, g, b = GetPowerColor(UnitPowerType('player'))
            Setup.manaBar:SetFillColor(r, g, b, 1)
        end
    end

    -- 进图/reload 后单位上限是延迟可用的。站桩时血蓝数值都不变, 不会有任何
    -- UNIT_HEALTH/UNIT_MANA 来兜底, 一旦建条那一刻撞上 UnitHealthMax == 0
    -- 就永久空条 —— 每 0.5s 补刷一次直到上限就绪(最多 8s)。
    local barRetry = CreateFrame("Frame")
    barRetry:Hide()
    barRetry.elapsed = 0
    barRetry.nextAt = 0.5
    barRetry:SetScript("OnUpdate", function()
        this.elapsed = this.elapsed + (arg1 or 0)   -- 1.12: OnUpdate 的 elapsed 在全局 arg1
        if this.elapsed < this.nextAt then return end
        this.nextAt = this.elapsed + 0.5

        RefreshPlayerBars()

        if UnitHealthMax('player') > 0 or this.elapsed > 8 then
            this:Hide()
            DFUI.activeScripts["PlayerBarRetry"] = false
        end
    end)
    DFUI.activeScripts["PlayerBarRetry"] = false

    -- event handler
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UNIT_MANA")
    f:RegisterEvent("UNIT_RAGE")
    f:RegisterEvent("UNIT_ENERGY")
    f:RegisterEvent("UNIT_FOCUS")
    f:RegisterEvent("UNIT_HEALTH")
    -- 上限事件不能少: reload 后 UnitHealthMax 先返回 0、稍后才补真值, 而补真值时
    -- 发的是 UNIT_MAXHEALTH 而不是 UNIT_HEALTH。不听就没有重绘时机, 条会停在 0 宽。
    -- 注意能量/怒气的上限走各自独立的事件, 不会发 UNIT_MAXMANA
    f:RegisterEvent("UNIT_MAXHEALTH")
    f:RegisterEvent("UNIT_MAXMANA")
    f:RegisterEvent("UNIT_MAXRAGE")
    f:RegisterEvent("UNIT_MAXENERGY")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:SetScript("OnEvent", function()
        if event == "PLAYER_ENTERING_WORLD" then
            Setup:Run()
            DFUI:NewCallbacks("Player", callbacks)
            f:UnregisterEvent("PLAYER_ENTERING_WORLD")
            -- 建条那一刻上限可能还是 0, 挂上重试直到就绪
            barRetry.elapsed = 0
            barRetry.nextAt = 0.5
            barRetry:Show()
            DFUI.activeScripts["PlayerBarRetry"] = true
        end

        if event == "PLAYER_REGEN_ENABLED" or
        event == "PLAYER_REGEN_DISABLED" or
        arg1 == "player" then
            RefreshPlayerBars()
            callbacks.textShow(DFUI:GetTempDB("Player", "textShow"))
            callbacks.textColoringHealth(DFUI:GetTempDB("Player", "textColoringHealth"))
            callbacks.textColoringResource(DFUI:GetTempDB("Player", "textColoringResource"))
            -- classColor only changes on login/settings, not per health/mana tick
            if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
                callbacks.classColor(DFUI:GetTempDB("Player", "classColor"))
            end
        end
    end)
end)
