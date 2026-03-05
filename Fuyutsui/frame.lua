local addonName, SK = ...
local screenWidth = GetScreenWidth()
local config = {
    blockCount = 200,               -- 总色块数量
    blockWidth = screenWidth / 200, -- 色块宽度
    blockHeight = 2,                -- 色块高度
    blockSpacing = 0,               -- 色块间距
}

-- 计算 X 偏移
local function GetXOffset(index, Width, spacing)
    return index * (Width + spacing)
end

-- 核心容器：唯一的框架
local mainAnchor = CreateFrame("Frame", "SkippyMainAnchor", UIParent)
mainAnchor:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
mainAnchor:SetSize(screenWidth, config.blockHeight)
mainAnchor:SetFrameStrata("TOOLTIP") -- 确保在最上层
mainAnchor:SetFrameLevel(10000)
-- mainAnchor:Raise()   -- Increases the frame's frame level above all other frames in its strata
SK.MainAnchor = mainAnchor

function SK.CreateButton(name, key, macro)
    local frame = CreateFrame("Button", "SkippyButton_" .. name, mainAnchor, "SecureActionButtonTemplate")
    frame:SetAttribute("type", "macro")
    frame:SetAttribute("macrotext", macro)
    frame:RegisterForClicks("AnyDown", "AnyUp")
    SetOverrideBindingClick(frame, true, key, name)
    return frame
end

-- 存储纹理的数组 (1 到 255)
local pixelTextures = {}

-- 获取特定索引的纹理（如果不存在则创建）
local function creatTextureByIndex(i)
    if i <= 0 or i > config.blockCount then return nil end
    if pixelTextures[i] == nil then
        local tex = mainAnchor:CreateTexture(nil, "OVERLAY")
        tex:SetSize(config.blockWidth, config.blockHeight)
        tex:SetPoint("TOPLEFT", mainAnchor, "TOPLEFT", GetXOffset(i - 1, config.blockWidth, config.blockSpacing), 0)
        pixelTextures[i] = tex
    end
    return pixelTextures[i]
end

-- 更新或创建静态色块 (按索引)
function SK.updateOrCreatTextureByIndex(i, b)
    local tex = creatTextureByIndex(i)
    if tex then
        tex:SetColorTexture(0, i / 255, b, 1)
    end
end

for i = 1, config.blockCount do
    SK.updateOrCreatTextureByIndex(i, 0)
end

-- ==========================================
-- 绑定宏
-- ==========================================

SK.MacroCount = 0
local macroList = {}

function SK.CreateMacro(name, key, macro)
    if InCombatLockdown() then
        print("|cFFFF0000错误：不能在战斗中绑定按键|r")
        return false
    end
    local btn = macroList[name]

    if not btn then
        btn = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
        btn:SetAttribute("type", "macro")
        SetBindingClick(key, name, "LeftButton")
        SK.MacroCount = (SK.MacroCount or 0) + 1
    end
    btn:SetAttribute("macrotext1", macro)
    btn:RegisterForClicks("AnyDown")
    return true
end

-- ==========================================
-- 简单的控制开关 (可选)
-- ==========================================
-- 隐藏所有相关色块 (例如：在载入界面或非战斗状态)
function SK.SetBlocksVisible(visible)
    if visible then mainAnchor:Show() else mainAnchor:Hide() end
end
