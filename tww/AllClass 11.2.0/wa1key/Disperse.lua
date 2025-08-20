-- 缓存变量，避免重复计算
local mounted = IsMounted("player")             -- 坐骑
local inVehicle = UnitInVehicle("player")       -- 载具
local chatFrame = ChatFrame1EditBox:IsVisible() -- 聊天框
local dead = UnitIsDeadOrGhost("player")        -- 死亡
local channel = UnitChannelInfo("player")       -- 施法状态

if mounted or inVehicle or chatFrame or dead then
    return 0
end

-- 排除特定的Debuff名称
local excludedDebuffs = {
    ["动能胶质炸药"] = true,
    ["不稳定的腐蚀"] = true,
    ["震地回响"] = true,
    ["烈焰震击"] = true,
    ["虚弱灵魂"] = true,
    ["虚弱光环"] = true,
    ["最后一击"] = true,
    ["饕餮虚空"] = true,
    ["灵魂枯萎"] = true,
    ["巨口蛙毒"] = true,
    ["培植毒药"] = true
}

-- 检查玩家是否学习了某法术
local function hasLearnedSpell(spellID)
    return spellID and IsPlayerSpell(spellID) or false
end

-- 检查玩家是否学习了多个法术中的任意一个
local function hasLearnedAnySpell(spellIDs)
    for _, spellID in ipairs(spellIDs) do
        if hasLearnedSpell(spellID) then
            return true
        end
    end
    return false
end
local function getCharges(spellID)
    local charges = C_Spell.GetSpellCharges(spellID)
    return charges and charges.currentCharges or 0
end

-- 创建一个技能ID表
local learnedSpellIDs = {
    475,    -- 解除诅咒
    527,    -- 纯净术
    213634, -- 净化疾病
    2782,   -- 清除腐蚀
    88423,  -- 自然之愈
    77130,  -- 净化灵魂
    51886,  -- 净化灵魂
    4987,   -- 清洁术
    213644, -- 清毒术
    115450, -- 清创生血
    218164, -- 清创生血
}

-- 获取已学会的技能ID和充能数量
local function getLearnedSpellInfo()
    for _, spellID in ipairs(learnedSpellIDs) do
        if hasLearnedSpell(spellID) then
            local charges = getCharges(spellID)
            return charges
        end
    end
    return 0
end

local learnedSpellInfo = getLearnedSpellInfo()

-- 各法术的驱散能力映射
local dispelAbilities = {
    Magic = { 527, 360823, 4987, 115450, 88423, 77130 },              -- 魔法驱散
    Disease = { 390632, 213634, 393024, 213644, 388874, 218164 },     -- 疾病驱散
    Curse = { 383016, 51886, 392378, 2782, 475 },                     -- 诅咒驱散
    Poison = { 392378, 2782, 393024, 213644, 388874, 218164, 365585 } -- 中毒驱散
}

-- 动态生成驱散能力
local dispelCapabilities = {}
for debuffType, spellIDs in pairs(dispelAbilities) do
    dispelCapabilities[debuffType] = hasLearnedAnySpell(spellIDs)
end

-- 检查是否可以驱散指定类型的debuff
local function canDispelType(debuffType)
    return dispelCapabilities[debuffType] or false
end

-- 检查单位是否有可驱散的Debuff
local function hasDispellableDebuff(unit)
    for j = 1, 40 do
        local debuffData = C_UnitAuras.GetAuraDataByIndex(unit, j, "HARMFUL")
        if not debuffData then break end

        local name = debuffData.name
        local debuffType = debuffData.dispelName

        if excludedDebuffs[name] then
            -- 直接跳过当前循环
        elseif debuffType and canDispelType(debuffType) then
            return true
        end
    end
    return false
end
-- 检查单位是否有可驱散的Debuff
local function hasDebuff(unit)
    for j = 1, 40 do
        local debuffData = C_UnitAuras.GetAuraDataByIndex(unit, j, "HARMFUL")
        if not debuffData then break end
        local name = debuffData.name
        local debuffType = debuffData.dispelName
        if debuffType and canDispelType(debuffType) then
            return true
        end
    end
    return false
end

if learnedSpellInfo == 1 and not channel then
    if hasDispellableDebuff("player") then -- 优先检查自己
        return 1
    end
    -- 检查小队成员
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitInRange(unit) and UnitCanAssist("player", unit) then
            if hasDispellableDebuff(unit) then
                return i + 85
            end
        end
    end
    if hasDebuff("target") and UnitExists("target") and not UnitIsDeadOrGhost("target") and UnitInRange("target") and UnitCanAssist("player", "target") then
        return 86
    end
end

return 0
