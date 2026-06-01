# Dragonflight-Fix 拾取模块 — 实现方案

## 概述

本文档是 `loot-module-design.md` 的实现细化，包含具体代码结构、API 调用和实现步骤。

> **注意**：本文档为初始设计方案，实际实现有所调整。最终状态请参考 `loot-module-progress.md`。
> 主要差异：
> - 实际代码使用闭包/局部函数风格（无 Setup 表）
> - roll.lua 不是独立 `DFUI:NewMod` 模块，而是通过 `DFUI.InitLootRoll` 属性函数由 loot.lua 调用
> - 事件机制：投骰使用替换 `GroupLootFrame_OpenNewFrame` 全局函数 + `CANCEL_LOOT_ROLL` 事件（非 START_LOOT_ROLL）
> - 新增了自动拾取渐隐动画（StopFade/StartFade 状态机）
> - 配置项实际 10 个（`show_quality_text` 和 `roll_scale` 未实现）

---

## 文件结构

```
modules/loot/
├── loot.lua    -- 主拾取框体 (~640 行)
└── roll.lua    -- 投骰框体 (~310 行)
```

已修改的文件：
- `Dragonflight-Fix.toc` — 添加两个文件到加载列表（line 73-74）
- `modules/frames/frames.lua` — 将 `DFUI.lootFrame` 和 `DFUI.rollAnchor` 加入 `framesToMakeMovable` 列表（line 46-48）

---

## 一、loot.lua 实现方案

### 1.1 文件骨架

```lua
-- 设置环境
setfenv(1, DFUI:GetEnv())
local T = DFUI.tools

-- 配置 defaults
DFUI:NewDefaults("Loot", {
    enabled           = {true},
    mousecursor       = {true,  "checkbox", nil, nil, "基础", 1, "拾取窗口跟随鼠标光标", nil, nil},
    autoloot          = {false, "checkbox", nil, nil, "基础", 2, "自动拾取所有物品", nil, nil},
    autopickup_bop    = {true,  "checkbox", nil, nil, "基础", 3, "单人时自动确认拾取绑定物品", nil, nil},
    scale             = {1.0,   "slider", {0.5, 1.5, 0.05}, nil, "外观", 1, "拾取窗口缩放", nil, nil},
    quality_border    = {true,  "checkbox", nil, nil, "外观", 2, "物品图标边框显示品质颜色", nil, nil},
    quality_glow      = {true,  "checkbox", nil, nil, "外观", 3, "品质物品背景高亮", nil, nil},
    glow_threshold    = {2,     "slider", {0, 5, 1}, "quality_glow", "外观", 4, "高亮最低品质 (0灰-5橙)", nil, nil},
    show_item_type    = {true,  "checkbox", nil, nil, "外观", 5, "显示物品类型信息", nil, nil},
})

DFUI:NewMod("Loot", 1, function()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        f:UnregisterEvent("PLAYER_ENTERING_WORLD")
        Setup:Init()
    end)
end)
```

### 1.2 核心变量与常量

```lua
local Setup = {}
local SLOT_HEIGHT = 28           -- 单行槽位高度
local SLOT_HEIGHT_INFO = 40      -- 带信息行的槽位高度
local ICON_SIZE = 28             -- 图标尺寸
local FRAME_MIN_WIDTH = 180      -- 框体最小宽度
local FRAME_MAX_WIDTH = 320      -- 框体最大宽度
local PADDING = 6                -- 内边距
local SLOT_SPACING = 2           -- 槽位间距

local FONT_PATH = DFUI:GetInfoOrCons("font") .. "BigNoodleTitling.ttf"
local slots = {}                 -- 槽位对象池
```

### 1.3 Init — 初始化

```lua
function Setup:Init()
    -- 1. 禁用默认 LootFrame
    LootFrame:UnregisterAllEvents()

    -- 2. 创建主框体（具名，用于 Frames 模块识别）
    local lootFrame = CreateFrame("Frame", "DFUILootFrame", UIParent)
    lootFrame:SetFrameStrata("DIALOG")
    lootFrame:SetFrameLevel(10)
    lootFrame:SetClampedToScreen(true)
    lootFrame:Hide()

    -- 应用标准 DFUI 背景
    lootFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    lootFrame:SetBackdropColor(0, 0, 0, 0.7)
    lootFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    -- 金色渐变装饰线
    T.GradientLine(lootFrame, "TOP", -1, 3)
    T.GradientLine(lootFrame, "BOTTOM", 1, 3)

    -- 缩放
    local scale = DFUI:GetTempDB("Loot", "scale") or 1.0
    lootFrame:SetScale(scale)

    -- ESC 关闭支持
    table.insert(UISpecialFrames, "DFUILootFrame")

    -- 暴露到 DFUI 全局（供 frames.lua 引用）
    DFUI.lootFrame = lootFrame

    -- 3. 注册事件
    lootFrame:RegisterEvent("LOOT_OPENED")
    lootFrame:RegisterEvent("LOOT_CLOSED")
    lootFrame:RegisterEvent("LOOT_SLOT_CLEARED")
    lootFrame:RegisterEvent("OPEN_MASTER_LOOT_LIST")
    lootFrame:RegisterEvent("UPDATE_MASTER_LOOT_LIST")
    lootFrame:RegisterEvent("LOOT_BIND_CONFIRM")

    lootFrame:SetScript("OnEvent", function()
        Setup:OnEvent(event, arg1)
    end)

    lootFrame:SetScript("OnHide", function()
        StaticPopup_Hide("CONFIRM_LOOT_DISTRIBUTION")
        CloseLoot()
    end)
end
```

### 1.4 OnEvent — 事件分发

```lua
function Setup:OnEvent(event, arg1)
    local lootFrame = DFUI.lootFrame

    if event == "LOOT_OPENED" then
        -- 自动拾取检测
        if DFUI:GetTempDB("Loot", "autoloot") then
            self:AutoLootAll()
            return
        end

        -- 钓鱼音效
        if IsFishingLoot() then
            PlaySound("FISHING REEL IN")
        end

        -- 显示框体
        lootFrame:Show()

        -- 鼠标跟随定位
        if DFUI:GetTempDB("Loot", "mousecursor") and not DFUI_FRAMEPOS["DFUILootFrame"] then
            self:PositionAtCursor()
        end

        -- 更新拾取内容
        self:UpdateLootFrame()

    elseif event == "LOOT_SLOT_CLEARED" then
        if arg1 and slots[arg1] then
            slots[arg1]:Hide()
        end

    elseif event == "LOOT_CLOSED" then
        StaticPopup_Hide("LOOT_BIND")
        lootFrame:Hide()
        if DropDownList1 and DropDownList1:IsShown() then
            CloseDropDownMenus()
        end
        for _, slot in pairs(slots) do
            slot:Hide()
        end

    elseif event == "OPEN_MASTER_LOOT_LIST" then
        ToggleDropDownMenu(1, nil, GroupLootDropDown, slots[DFUI.lootSelectedSlot], 0, 0)

    elseif event == "UPDATE_MASTER_LOOT_LIST" then
        UIDropDownMenu_Refresh(GroupLootDropDown)

    elseif event == "LOOT_BIND_CONFIRM" then
        self:HandleBindConfirm(arg1)
    end
end
```

### 1.5 UpdateLootFrame — 核心拾取渲染

```lua
function Setup:UpdateLootFrame()
    local lootFrame = DFUI.lootFrame
    local numItems = GetNumLootItems()
    LootFrame.numLootItems = numItems   -- 兼容 Blizzard API

    local maxWidth = 0
    local maxQuality = 0
    local visibleCount = 0
    local showInfo = DFUI:GetTempDB("Loot", "show_item_type")
    local slotH = showInfo and SLOT_HEIGHT_INFO or SLOT_HEIGHT

    for i = 1, numItems do
        local texture, item, quantity, quality = GetLootSlotInfo(i)
        if texture then
            visibleCount = visibleCount + 1
            local slot = slots[visibleCount] or self:CreateSlot(visibleCount)

            -- 金币特殊处理
            if LootSlotIsCoin(i) then
                item = string.gsub(string.gsub(item, "\n", ", "), ", $", "")
            end

            -- 设置图标
            slot.icon:SetTexture(texture)

            -- 设置名称 + 品质颜色
            local color = ITEM_QUALITY_COLORS[quality]
            slot.name:SetText(item)
            slot.name:SetTextColor(color.r, color.g, color.b)

            -- 数量
            if quantity and quantity > 1 then
                slot.count:SetText(quantity)
                slot.count:Show()
            else
                slot.count:Hide()
            end

            -- 品质边框
            if DFUI:GetTempDB("Loot", "quality_border") and quality and quality > 1 then
                slot.iconFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1)
            else
                slot.iconFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
            end

            -- 品质背景高亮
            local threshold = DFUI:GetTempDB("Loot", "glow_threshold") or 2
            if DFUI:GetTempDB("Loot", "quality_glow") and quality and quality >= threshold then
                slot.rarity:SetVertexColor(color.r, color.g, color.b)
                slot.rarity:Show()
            else
                slot.rarity:Hide()
            end

            -- 物品类型信息行（可选）
            if showInfo and slot.info then
                local link = GetLootSlotLink(i)
                if link and not LootSlotIsCoin(i) then
                    local _, _, _, _, _, itemType, itemSubType = GetItemInfo(link)
                    if itemType then
                        slot.info:SetText(itemType .. (itemSubType and (" · " .. itemSubType) or ""))
                        slot.info:Show()
                    else
                        slot.info:Hide()
                    end
                else
                    slot.info:Hide()
                end
            end

            -- 记录槽位映射 (显示索引 → 实际 loot 索引)
            slot:SetID(i)
            slot:Show()

            -- 布局定位
            slot:ClearAllPoints()
            slot:SetPoint("TOPLEFT", lootFrame, "TOPLEFT", PADDING, -(PADDING + (visibleCount - 1) * (slotH + SLOT_SPACING)))
            slot:SetPoint("RIGHT", lootFrame, "RIGHT", -PADDING, 0)
            slot:SetHeight(slotH)

            -- 追踪最大宽度
            local nameW = slot.name:GetStringWidth() + ICON_SIZE + PADDING * 3
            if nameW > maxWidth then maxWidth = nameW end
            if quality > maxQuality then maxQuality = quality end
        end
    end

    -- 隐藏多余槽位
    for i = visibleCount + 1, table.getn(slots) do
        if slots[i] then slots[i]:Hide() end
    end

    -- 调整框体尺寸
    local frameW = math.max(FRAME_MIN_WIDTH, math.min(maxWidth, FRAME_MAX_WIDTH))
    local frameH = PADDING * 2 + visibleCount * slotH + (visibleCount - 1) * SLOT_SPACING
    frameH = math.max(frameH, 40)

    lootFrame:SetWidth(frameW)
    lootFrame:SetHeight(frameH)

    -- 最高品质物品的框体边框染色
    if maxQuality > 1 then
        local c = ITEM_QUALITY_COLORS[maxQuality]
        lootFrame:SetBackdropBorderColor(c.r, c.g, c.b, 0.6)
    else
        lootFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end
end
```

### 1.6 CreateSlot — 创建槽位对象

```lua
function Setup:CreateSlot(id)
    local lootFrame = DFUI.lootFrame
    local slot = CreateFrame("Button", "DFUILootSlot" .. id, lootFrame)
    slot:SetHeight(SLOT_HEIGHT)
    slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- 图标框
    slot.iconFrame = CreateFrame("Frame", nil, slot)
    slot.iconFrame:SetWidth(ICON_SIZE)
    slot.iconFrame:SetHeight(ICON_SIZE)
    slot.iconFrame:SetPoint("LEFT", slot, "LEFT", 0, 0)
    slot.iconFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    slot.iconFrame:SetBackdropColor(0, 0, 0, 0.5)
    slot.iconFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    -- 图标材质
    slot.icon = slot.iconFrame:CreateTexture(nil, "ARTWORK")
    slot.icon:SetTexCoord(.07, .93, .07, .93)
    slot.icon:SetPoint("TOPLEFT", slot.iconFrame, "TOPLEFT", 2, -2)
    slot.icon:SetPoint("BOTTOMRIGHT", slot.iconFrame, "BOTTOMRIGHT", -2, 2)

    -- 数量文字
    slot.count = slot.iconFrame:CreateFontString(nil, "OVERLAY")
    slot.count:SetFont(FONT_PATH, 11, "OUTLINE")
    slot.count:SetJustifyH("RIGHT")
    slot.count:SetPoint("BOTTOMRIGHT", slot.iconFrame, "BOTTOMRIGHT", -1, 1)
    slot.count:Hide()

    -- 物品名称
    slot.name = slot:CreateFontString(nil, "OVERLAY")
    slot.name:SetFont(FONT_PATH, 13, "OUTLINE")
    slot.name:SetJustifyH("LEFT")
    slot.name:SetPoint("LEFT", slot.iconFrame, "RIGHT", 6, 0)
    slot.name:SetPoint("RIGHT", slot, "RIGHT", -4, 0)

    -- 物品类型信息行（金色小字）
    slot.info = slot:CreateFontString(nil, "OVERLAY")
    slot.info:SetFont(FONT_PATH, 10, "OUTLINE")
    slot.info:SetTextColor(1, 0.82, 0, 0.8)
    slot.info:SetJustifyH("LEFT")
    slot.info:SetPoint("TOPLEFT", slot.name, "BOTTOMLEFT", 0, -1)
    slot.info:SetPoint("RIGHT", slot, "RIGHT", -4, 0)
    slot.info:Hide()

    -- 品质背景条
    slot.rarity = slot:CreateTexture(nil, "BACKGROUND")
    slot.rarity:SetTexture("Interface\\Buttons\\WHITE8X8")
    slot.rarity:SetPoint("LEFT", slot.iconFrame, "RIGHT", 0, 0)
    slot.rarity:SetPoint("RIGHT", slot, "RIGHT", 0, 0)
    slot.rarity:SetPoint("TOP", slot, "TOP", 0, 0)
    slot.rarity:SetPoint("BOTTOM", slot, "BOTTOM", 0, 0)
    slot.rarity:SetAlpha(0.12)
    slot.rarity:Hide()

    -- 悬停高亮
    slot.hover = slot:CreateTexture(nil, "HIGHLIGHT")
    slot.hover:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    slot.hover:SetBlendMode("ADD")
    slot.hover:SetAllPoints(slot)
    slot.hover:SetAlpha(0.3)

    -- 槽位间分割线
    slot.divider = slot:CreateTexture(nil, "ARTWORK")
    slot.divider:SetTexture("Interface\\Buttons\\WHITE8X8")
    slot.divider:SetVertexColor(0.3, 0.3, 0.3, 0.3)
    slot.divider:SetHeight(1)
    slot.divider:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", 0, -1)
    slot.divider:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 0, -1)

    -- 点击事件
    slot:SetScript("OnClick", function()
        if IsControlKeyDown() then
            DressUpItemLink(GetLootSlotLink(this:GetID()))
        elseif IsShiftKeyDown() then
            if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                ChatFrameEditBox:Insert(GetLootSlotLink(this:GetID()))
            end
        else
            -- 保存选中信息（Master Loot 需要）
            DFUI.lootSelectedSlot = this:GetID()
            LootFrame.selectedSlot = this:GetID()
            LootFrame.selectedQuality = this.quality
            LootFrame.selectedItemName = this.name:GetText()

            LootSlot(this:GetID())
        end
    end)

    -- Tooltip
    slot:SetScript("OnEnter", function()
        if LootSlotIsItem(this:GetID()) then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetLootItem(this:GetID())
            CursorUpdate(this)
        end
    end)

    slot:SetScript("OnLeave", function()
        GameTooltip:Hide()
        ResetCursor()
    end)

    slots[id] = slot
    return slot
end
```

### 1.7 PositionAtCursor — 鼠标跟随定位

```lua
function Setup:PositionAtCursor()
    local lootFrame = DFUI.lootFrame
    local x, y = GetCursorPosition()
    local scale = lootFrame:GetEffectiveScale()
    x = x / scale
    y = y / scale

    -- 偏移到光标右下方
    x = x + 8
    y = y - 8

    -- 边界检测
    local screenW = GetScreenWidth()
    local screenH = GetScreenHeight()
    local frameW = lootFrame:GetWidth()
    local frameH = lootFrame:GetHeight()

    if x + frameW > screenW then x = screenW - frameW end
    if y - frameH < 0 then y = frameH end
    if x < 0 then x = 0 end
    if y > screenH then y = screenH end

    lootFrame:ClearAllPoints()
    lootFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end
```

### 1.8 AutoLootAll — 自动拾取

```lua
function Setup:AutoLootAll()
    local numItems = GetNumLootItems()
    for i = numItems, 1, -1 do
        LootSlot(i)
    end
end
```

在 `LOOT_OPENED` 事件中检测：
- `DFUI:GetTempDB("Loot", "autoloot")` 为 true 时自动拾取
- 或检测 `GetCVar("autoLootDefault")` 和 Shift 键状态

### 1.9 HandleBindConfirm — BoP 自动确认

```lua
function Setup:HandleBindConfirm(slot)
    if not DFUI:GetTempDB("Loot", "autopickup_bop") then return end
    if GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 then return end

    -- 单人模式，自动确认
    ConfirmLootSlot(slot)
    StaticPopup_Hide("LOOT_BIND")
end
```

### 1.10 Callbacks — 设置变更回调

```lua
local callbacks = {}

callbacks.scale = function(value)
    if DFUI.lootFrame then
        DFUI.lootFrame:SetScale(value or 1.0)
    end
end

callbacks.mousecursor = function(value)
    -- 重新启用鼠标跟随时，清除保存的固定位置
    if value and DFUI_FRAMEPOS then
        DFUI_FRAMEPOS["DFUILootFrame"] = nil
    end
end

DFUI:NewCallbacks("Loot", callbacks)
```

---

## 二、roll.lua 实现方案

### 2.1 文件骨架（实际实现）

```lua
-- roll.lua 不使用 setfenv，不注册独立模块
-- 通过 DFUI 表属性函数导出，由 loot.lua 的 Init 调用

DFUI.InitLootRoll = function()
    -- 所有常量、状态、函数定义在闭包内
    -- ...
end
```

在 loot.lua 的 PLAYER_ENTERING_WORLD 回调中调用：
```lua
if DFUI.InitLootRoll then
    DFUI.InitLootRoll()
end
```

### 2.2 常量与变量

```lua
local RollSetup = {}
local MAX_ROLLS = 4              -- 最大并发投骰数
local ROLL_WIDTH = 340           -- 投骰框宽度
local ROLL_HEIGHT = 36           -- 投骰框高度
local ROLL_SPACING = 6           -- 投骰框间距
local ICON_SIZE = 32             -- 图标尺寸
local BUTTON_SIZE = 24           -- Need/Greed/Pass 按钮尺寸

local FONT_PATH = DFUI:GetInfoOrCons("font") .. "BigNoodleTitling.ttf"
local rollFrames = {}            -- 投骰框对象池
```

### 2.3 Setup（实际实现）

```lua
-- 在 DFUI.InitLootRoll 闭包内部：

-- 创建锚点框体（用于整体定位和 Ctrl+Alt+Shift 移动）
local anchor = CreateFrame("Frame", "DFUIRollAnchor", UIParent)
anchor:SetWidth(ROLL_WIDTH)
anchor:SetHeight(ROLL_HEIGHT)
anchor:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
DFUI.rollAnchor = anchor

-- 预创建 4 个投骰框
for i = 1, MAX_ROLLS do
    rollFrames[i] = CreateRollFrame(i)
    rollFrames[i]:SetPoint("TOP", anchor, "TOP", 0, -(i - 1) * (ROLL_HEIGHT + ROLL_SPACING))
    rollFrames[i]:Hide()
end

-- 替换全局函数（pfUI 方式）— 处理 START_LOOT_ROLL
_G.GroupLootFrame_OpenNewFrame = function(id, rollTime)
    OnStartRoll(id, rollTime)
end

-- 仅监听 CANCEL_LOOT_ROLL 事件（不监听 START_LOOT_ROLL，避免重复触发）
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CANCEL_LOOT_ROLL")
eventFrame:SetScript("OnEvent", function()
    if event == "CANCEL_LOOT_ROLL" then
        OnCancelRoll(arg1)
    end
end)
```

> **注意**：不能同时替换 `GroupLootFrame_OpenNewFrame` 和监听 `START_LOOT_ROLL`，否则会触发双重处理导致显示两个投骰框体（坑9）。

### 2.4 CreateRollFrame — 创建单个投骰框

```lua
function RollSetup:CreateRollFrame(id)
    local frame = CreateFrame("Frame", "DFUIRollFrame" .. id, UIParent)
    frame:SetWidth(ROLL_WIDTH)
    frame:SetHeight(ROLL_HEIGHT)
    frame:SetFrameStrata("DIALOG")

    -- 标准 DFUI 背景
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    -- 底部金色渐变线
    T.GradientLine(frame, "BOTTOM", 1, 2)

    -- 物品图标
    frame.iconFrame = CreateFrame("Frame", nil, frame)
    frame.iconFrame:SetWidth(ICON_SIZE)
    frame.iconFrame:SetHeight(ICON_SIZE)
    frame.iconFrame:SetPoint("LEFT", frame, "LEFT", 4, 0)
    frame.iconFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    frame.iconFrame:SetBackdropColor(0, 0, 0, 0.5)

    frame.icon = frame.iconFrame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetTexCoord(.07, .93, .07, .93)
    frame.icon:SetPoint("TOPLEFT", 2, -2)
    frame.icon:SetPoint("BOTTOMRIGHT", -2, 2)

    -- 图标 Tooltip + Ctrl 试穿 + Shift 链接
    frame.iconBtn = CreateFrame("Button", nil, frame.iconFrame)
    frame.iconBtn:SetAllPoints(frame.iconFrame)
    frame.iconBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetLootRollItem(this:GetParent():GetParent().rollID)
    end)
    frame.iconBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.iconBtn:SetScript("OnClick", function()
        if IsControlKeyDown() then
            DressUpItemLink(GetLootRollItemLink(this:GetParent():GetParent().rollID))
        elseif IsShiftKeyDown() then
            if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                ChatFrameEditBox:Insert(GetLootRollItemLink(this:GetParent():GetParent().rollID))
            end
        end
    end)

    -- 物品名称
    frame.itemName = frame:CreateFontString(nil, "OVERLAY")
    frame.itemName:SetFont(FONT_PATH, 12, "OUTLINE")
    frame.itemName:SetJustifyH("LEFT")
    frame.itemName:SetPoint("LEFT", frame.iconFrame, "RIGHT", 6, 4)
    frame.itemName:SetPoint("RIGHT", frame, "RIGHT", -80, 0)

    -- 倒计时条
    frame.timer = CreateFrame("StatusBar", nil, frame)
    frame.timer:SetPoint("LEFT", frame.iconFrame, "RIGHT", 4, -6)
    frame.timer:SetPoint("RIGHT", frame, "RIGHT", -80, 0)
    frame.timer:SetHeight(6)
    frame.timer:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.timer:SetStatusBarColor(0.8, 0.8, 0.8, 0.8)
    frame.timer:SetMinMaxValues(0, 1)

    -- 倒计时条背景
    frame.timerBg = frame.timer:CreateTexture(nil, "BACKGROUND")
    frame.timerBg:SetAllPoints(frame.timer)
    frame.timerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.timerBg:SetVertexColor(0, 0, 0, 0.4)

    -- 倒计时 OnUpdate
    frame.timer:SetScript("OnUpdate", function()
        if not this:GetParent().rollID then return end
        local left = GetLootRollTimeLeft(this:GetParent().rollID)
        local _, max = this:GetMinMaxValues()
        if left < 0 or left > max then left = 0 end
        this:SetValue(left)
    end)

    -- Need 按钮
    frame.needBtn = self:CreateRollButton(frame, "LEFT", frame.timer, "RIGHT", 4, 6,
        "Interface\\Buttons\\UI-GroupLoot-Dice-Up",
        "Interface\\Buttons\\UI-GroupLoot-Dice-Down",
        "Interface\\Buttons\\UI-GroupLoot-Dice-Highlight",
        function() RollOnLoot(this:GetParent().rollID, 1) end,
        NEED
    )

    -- Greed 按钮
    frame.greedBtn = self:CreateRollButton(frame, "LEFT", frame.needBtn, "RIGHT", 2, 0,
        "Interface\\Buttons\\UI-GroupLoot-Coin-Up",
        "Interface\\Buttons\\UI-GroupLoot-Coin-Down",
        "Interface\\Buttons\\UI-GroupLoot-Coin-Highlight",
        function() RollOnLoot(this:GetParent().rollID, 2) end,
        GREED
    )

    -- Pass 按钮
    frame.passBtn = self:CreateRollButton(frame, "LEFT", frame.greedBtn, "RIGHT", 2, 0,
        "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
        "Interface\\Buttons\\UI-GroupLoot-Pass-Down",
        nil,
        function() RollOnLoot(this:GetParent().rollID, 0) end,
        PASS
    )

    return frame
end
```

### 2.5 CreateRollButton — 投骰按钮工厂

```lua
function RollSetup:CreateRollButton(parent, point, relativeTo, relPoint, xOff, yOff,
                                      normalTex, pushedTex, highlightTex, onClick, tooltipText)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(BUTTON_SIZE)
    btn:SetHeight(BUTTON_SIZE)
    btn:SetPoint(point, relativeTo, relPoint, xOff, yOff)
    btn:SetNormalTexture(normalTex)
    if pushedTex then btn:SetPushedTexture(pushedTex) end
    if highlightTex then btn:SetHighlightTexture(highlightTex) end

    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltipText or "")
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return btn
end
```

### 2.6 OnStartRoll / OnCancelRoll — 事件处理

```lua
function RollSetup:OnStartRoll(rollID, rollTime)
    -- 找到第一个空闲的投骰框
    for i = 1, MAX_ROLLS do
        if not rollFrames[i]:IsShown() then
            local frame = rollFrames[i]
            frame.rollID = rollID

            -- 获取物品信息
            local texture, name, count, quality, bop = GetLootRollItemInfo(rollID)
            local color = ITEM_QUALITY_COLORS[quality]

            -- 填充显示
            frame.icon:SetTexture(texture)
            frame.iconFrame:SetBackdropBorderColor(color.r, color.g, color.b, 1)
            frame.itemName:SetText((count > 1 and count .. "x " or "") .. name)
            frame.itemName:SetTextColor(color.r, color.g, color.b)

            -- 框体边框品质色
            frame:SetBackdropBorderColor(color.r, color.g, color.b, 0.6)

            -- 倒计时条
            frame.timer:SetMinMaxValues(0, rollTime)
            frame.timer:SetValue(rollTime)

            -- 计时条品质色（可选）
            if DFUI:GetTempDB("Loot", "roll_rarity_timer") then
                frame.timer:SetStatusBarColor(color.r, color.g, color.b, 0.8)
            else
                frame.timer:SetStatusBarColor(0.8, 0.8, 0.8, 0.8)
            end

            -- 重置按钮状态
            frame.needBtn:Enable()
            frame.greedBtn:Enable()
            frame.passBtn:Enable()

            frame:Show()
            return
        end
    end
end

function RollSetup:OnCancelRoll(rollID)
    for i = 1, MAX_ROLLS do
        if rollFrames[i].rollID == rollID then
            rollFrames[i]:Hide()
            rollFrames[i].rollID = nil
            return
        end
    end
end
```

---

## 三、已有文件修改

### 3.1 Dragonflight-Fix.toc

在模块加载区域末尾（`modules\track\track.lua` 之后，GUI 模块之前）添加：

```
modules\loot\loot.lua
modules\loot\roll.lua
```

### 3.2 modules/frames/frames.lua

在 `framesToMakeMovable` 列表末尾添加：

```lua
DFUI.lootFrame,         -- 拾取框体
DFUI.rollAnchor,        -- 投骰框锚点
```

注意：frames.lua 的优先级是 2，loot.lua 优先级是 1，所以 loot 模块函数先执行。
但两者的实际初始化都在 `PLAYER_ENTERING_WORLD` 事件中，执行顺序取决于事件注册顺序。
如果 `DFUI.lootFrame` 在 frames.lua 读取时仍为 nil，需要延迟检查或 nil 保护。
**需要验证**：如果 frames 先于 loot 处理事件，则 DFUI.lootFrame 可能还是 nil。

**安全方案**：在 frames.lua 中使用延迟检查：

```lua
-- 在 framesToMakeMovable 列表构建之后、MakeFrameMovable 循环之前添加：
if DFUI.lootFrame then
    table.insert(framesToMakeMovable, DFUI.lootFrame)
end
if DFUI.rollAnchor then
    table.insert(framesToMakeMovable, DFUI.rollAnchor)
end
```

**备选方案**：loot.lua 在初始化完成后自行调用 `MakeFrameMovable`，但这需要将该函数暴露到 DFUI 全局。
更简洁的做法是将 loot.lua 的优先级改为 2（与 frames 相同），并确保在 toc 中 loot 排在 frames 之前。

---

## 四、实现步骤

### 步骤 1：创建文件 + 模块注册
- 创建 `modules/loot/loot.lua` — 文件骨架 + NewDefaults + NewMod
- 创建 `modules/loot/roll.lua` — 文件骨架 + NewMod
- 修改 `.toc` 添加文件引用
- **验证**：游戏加载无报错

### 步骤 2：主拾取框体基础功能
- 实现 `Setup:Init()` — 禁用默认 LootFrame，创建自定义框体
- 实现 `Setup:OnEvent()` — 事件分发
- 实现 `Setup:CreateSlot()` — 创建槽位（图标 + 名称 + 数量）
- 实现 `Setup:UpdateLootFrame()` — 渲染拾取物品
- 实现 `Setup:PositionAtCursor()` — 鼠标跟随
- **验证**：击杀怪物可看到自定义拾取窗口，点击可拾取

### 步骤 3：视觉增强
- 品质边框颜色
- 品质背景高亮条
- 物品类型信息行
- 动态宽度
- 金币格式化
- 分割线
- **验证**：不同品质物品显示正确颜色，信息行内容正确

### 步骤 4：自动拾取 + BoP 确认
- `Setup:AutoLootAll()`
- `Setup:HandleBindConfirm()`
- Shift 键 / CVar 检测
- **验证**：开启选项后自动拾取生效，单人 BoP 无弹窗

### 步骤 5：投骰框体
- `RollSetup:Init()` — 禁用默认投骰框，创建自定义框
- `RollSetup:CreateRollFrame()` — 图标 + 名称 + 三按钮 + 倒计时条
- `RollSetup:OnStartRoll()` / `OnCancelRoll()` — 事件处理
- **验证**：组队副本投骰窗口正常显示，按钮可点击

### 步骤 6：框体移动集成
- 修改 `frames.lua` 将拾取/投骰框加入移动列表
- 测试 Ctrl+Alt+Shift 拖拽
- 测试位置保存/恢复
- **验证**：移动后重新登录位置保持

### 步骤 7：Callbacks 配置响应
- 缩放实时变更
- 鼠标跟随切换
- 其他选项实时生效
- **验证**：修改设置后立即生效

---

## 五、关键 API 参考

### WoW Loot API

| API | 返回值 | 用途 |
|-----|--------|------|
| `GetNumLootItems()` | number | 拾取物品数量 |
| `GetLootSlotInfo(slot)` | texture, item, quantity, quality, locked | 物品信息 |
| `GetLootSlotLink(slot)` | itemLink | 物品链接 |
| `LootSlotIsItem(slot)` | boolean | 是否是物品（非金币） |
| `LootSlotIsCoin(slot)` | boolean | 是否是金币 |
| `LootSlot(slot)` | — | 拾取指定槽位 |
| `ConfirmLootSlot(slot)` | — | 确认拾取绑定物品 |
| `CloseLoot()` | — | 关闭拾取窗口 |
| `IsFishingLoot()` | boolean | 是否是钓鱼拾取 |
| `GetItemInfo(link)` | name, link, quality, iLevel, reqLevel, type, subType, ... | 物品详细信息 |

### WoW Roll API

| API | 返回值 | 用途 |
|-----|--------|------|
| `GetLootRollItemInfo(rollID)` | texture, name, count, quality, bop | 投骰物品信息 |
| `GetLootRollItemLink(rollID)` | itemLink | 投骰物品链接 |
| `GetLootRollTimeLeft(rollID)` | seconds | 投骰剩余时间 |
| `RollOnLoot(rollID, type)` | — | 投骰 (1=Need, 2=Greed, 0=Pass) |

### DFUI 框架 API

| API | 用途 |
|-----|------|
| `DFUI:NewDefaults(mod, defaults)` | 注册模块默认设置 |
| `DFUI:NewMod(name, prio, func)` | 注册模块 |
| `DFUI:GetTempDB(mod, key)` | 读取设置 |
| `DFUI:SetTempDB(mod, key, value)` | 写入设置 |
| `DFUI:NewCallbacks(mod, callbacks)` | 注册设置变更回调 |
| `DFUI:GetInfoOrCons("font")` | 获取字体路径前缀 |
| `DFUI:GetEnv()` | 获取模块环境 |
| `DFUI.tools.GradientLine(f, anchor, y, h)` | 创建金色渐变线 |
| `DFUI.tools.CreateFont(parent, size, text, color, align)` | 创建字体 |
| `DFUI.tools.CreateDFUIFrameName(parent, w, h, grad, alpha, mouse, name)` | 创建具名 DFUI 框体 |
| `KillFrame(frame)` | 完全禁用框体 |
| `HookScript(f, script, func)` | 追加脚本 |

---

## 六、风险与注意事项

1. **事件执行顺序**：loot.lua 和 frames.lua 都监听 `PLAYER_ENTERING_WORLD`，需确保 loot 先初始化
2. **GetLootSlotInfo 索引**：Vanilla 1.12 中索引从 1 开始（pfUI 代码中从 0 遍历是兼容写法，需实际测试）
3. **LootFrame 全局变量**：某些 Blizzard 代码可能检查 `LootFrame.numLootItems` 等字段，需保持赋值兼容
4. **Master Loot 下拉菜单**：使用 Blizzard 内置 `GroupLootDropDown`，无需自行实现
5. **ConfirmLootSlot vs LootSlot**：Vanilla 1.12 可能没有 `ConfirmLootSlot`，需检查 API 存在性
6. **投骰框默认数量**：Vanilla 默认只有 `GroupLootFrame1` 到 `GroupLootFrame4`，4 个上限足够
