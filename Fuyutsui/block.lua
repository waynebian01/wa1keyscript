local _, fu = ...
local screenWidth = GetScreenWidth()
local FRAME_DEFAULT_CONFIG = {
    blockCount = 255,               -- 总色块数量
    blockWidth = screenWidth / 255, -- 色块宽度
    blockHeight = 1,                -- 色块高度
    blockSpacing = 0,               -- 色块间距
}

-- 计算 X 偏移
local function GetXOffset(index, Width, spacing)
    return index * (Width + spacing)
end

-- 创建"色条"的容器
local colorBars = CreateFrame("Frame", "FuyutsuiColorBars", UIParent)
colorBars:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
colorBars:SetSize(screenWidth, FRAME_DEFAULT_CONFIG.blockHeight)
colorBars:SetFrameStrata("TOOLTIP") -- 确保在最上层
colorBars:SetFrameLevel(10000)
-- mainAnchor:Raise()   -- Increases the frame's frame level above all other frames in its strata
fu.MainAnchor = colorBars

function fu.CreateButton(name, key, macro)
    local frame = CreateFrame("Button", "FuyutsuiButton_" .. name, colorBars, "SecureActionButtonTemplate")
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
    if i <= 0 or i > FRAME_DEFAULT_CONFIG.blockCount then return nil end
    if pixelTextures[i] == nil then
        local tex = colorBars:CreateTexture(nil, "OVERLAY")
        tex:SetSize(FRAME_DEFAULT_CONFIG.blockWidth, FRAME_DEFAULT_CONFIG.blockHeight)
        tex:SetPoint("TOPLEFT", colorBars, "TOPLEFT", GetXOffset(i - 1, FRAME_DEFAULT_CONFIG.blockWidth, FRAME_DEFAULT_CONFIG.blockSpacing), 0)
        pixelTextures[i] = tex
    end
    return pixelTextures[i]
end

-- 更新或创建静态色块 (按索引)
function fu.updateOrCreatTextureByIndex(i, b)
    local tex = creatTextureByIndex(i)
    if tex then
        tex:SetColorTexture(0, i / 255, b, 1)
    end
end

for i = 1, FRAME_DEFAULT_CONFIG.blockCount do
    fu.updateOrCreatTextureByIndex(i, 0)
end

-- ==========================================
-- 绑定宏
-- ==========================================

fu.MacroCount = 0
local macroList = {}

function fu.CreateMacro(name, key, macro)
    if InCombatLockdown() then
        print("|cFFFF0000错误：不能在战斗中绑定按键|r")
        return false
    end
    local btn = macroList[name]

    if not btn then
        btn = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
        btn:SetAttribute("type", "macro")
        SetBindingClick(key, name, "LeftButton")
        fu.MacroCount = (fu.MacroCount or 0) + 1
    end
    btn:SetAttribute("macrotext1", macro)
    btn:RegisterForClicks("AnyDown")
    return true
end

-- ==========================================
-- 简单的控制开关 (可选)
-- ==========================================
-- 隐藏所有相关色块 (例如：在载入界面或非战斗状态)
function fu.SetBlocksVisible(visible)
    if visible then colorBars:Show() else colorBars:Hide() end
end
