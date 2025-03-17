-- 排除特定的Debuff名称
local excludedDebuffs = {
    ["动能胶质炸药"] = true,
    ["不稳定的腐蚀"] = true,
    ["震地回响"] = true,
    ["震地"] = true,
    ["烈焰震击"] = true,
    ["虚弱灵魂"] = true,
    ["虚弱光环"] = true,
    ["最后一击"] = true,
    ["灵魂枯萎"] = true,
    ["巨口蛙毒"] = true,
    ["培植毒药"] = true,
}

-- 特殊优先处理的Debuff（按需扩展）
local priorityDebuffs = {
    [440313] = true -- 示例特殊ID
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

-- 各法术的驱散能力映射
local dispelAbilities = {
    Magic = { 527, 360823, 4987, 115450, 88423 },                   -- 魔法驱散
    Disease = { 390632, 213634, 393024, 213644, 388874, 218164 },   -- 疾病驱散
    Curse = { 383016, 51886, 392378, 2782, 475 },                   -- 诅咒驱散
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
        local spellId = debuffData.spellId

        -- 排除无需驱散的Debuff
        if excludedDebuffs[name] then
            -- 直接跳过当前循环
        elseif debuffType and canDispelType(debuffType) then
            return true
        elseif priorityDebuffs[spellId] then
            return true
        end
    end
    return false
end

-- 优先检查自己
if hasDispellableDebuff("player") then
    return 1
end
-- 检查小队成员
for i = 1, 4 do
    local unit = "party" .. i
    if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitInRange(unit) and UnitCanAssist("player", unit) then
        if hasDispellableDebuff(unit) then
            return i + 1
        end
    end
end
