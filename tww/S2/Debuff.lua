local index = 0
local memberWithDebuff = 0
local debuffcount = 0
local auraID1 = 194384 --救赎
local auraID2 = 114255 --圣光涌动

local debuffs = {
    "虚空裂隙", --萨拉塔斯
    "燧火创伤", --酒庄
    "",--宝库
    "", --仙林
    "", --千丝
    "", --破晨
    "", --围攻
}
-- 获取技能冷却时间的函数
local function getCooldown(spellID)
    local cooldown = C_Spell.GetSpellCooldown(spellID)
    return (cooldown.startTime > 0) and (cooldown.startTime + cooldown.duration - GetTime()) or 0
end
--获取技能充能层数的函数
local function getCharges(spellID)
    local charges = C_Spell.GetSpellCharges(spellID)
    return charges and charges.currentCharges or 0 -- 如果没有充能信息,则返回 0
end

--获取单位有害光环的函数
local function hasDebuff(unit)
    for _, debuff in ipairs(debuffs) do
        for i = 1, 40 do
            local debuffData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
            if not debuffData then break end
            if debuffData.name == debuff then
                return true
            end
        end
    end
    return false
end
--获取单位有益光环的函数
local function hasAura(unit, auraID)
    for j = 1, 40 do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, j, "HELPFUL")
        if not auraData then break end
        if auraData.spellId == auraID then
            return true
        end
    end
    return false
end

-- 检查技能冷却
local GCD = getCooldown(61304)                   -- 公共冷却
local Shield = getCooldown(17)                   -- 真言术：盾
local Rapture = getCooldown(47536)               -- 全神贯注
-- 检测技能充能
local Shine = getCharges(194509)                 --真言术：耀
--检查玩家自身光环
local hasSurge = hasAura("player", auraID2)      --圣光涌动
local PlayerhasAura = hasAura("player", auraID1) --救赎



if not UnitPlayerOrPetInRaid("player") then
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitCanAssist("player", unit) and UnitInRange(unit) then
            local hasAura1 = hasAura(unit, auraID1) --救赎
            local hasdebuff = hasDebuff(unit)
            if hasdebuff and not hasAura1 then
                debuffcount = debuffcount + 1
                memberWithDebuff = i + 1
            end
        end
    end
    if hasDebuff("player") and not PlayerhasAura then
        debuffcount = debuffcount + 1
        memberWithDebuff = 1
    end
end

-- 设置 index 值
if debuffcount >= 2 and Shine > 0 then
    index = 50
elseif debuffcount == 1 or Shine == 0 then
    local indexMapping = {
        [1] = {61, 66, 71, 76},
        [2] = {62, 67, 72, 77},
        [3] = {63, 68, 73, 78},
        [4] = {64, 69, 74, 79},
        [5] = {65, 70, 75, 80},
    }
    --61-65盾，66-70全神贯注，71-75快速治疗，76-80恢复，80-81苦修
    local indexGroup
    if hasSurge then
        indexGroup = 3
    elseif Shield <= GCD then
        indexGroup = 1
    elseif Rapture <= GCD then
        indexGroup = 2
    else
        indexGroup = 4
    end
    if indexGroup then
        index = indexMapping[memberWithDebuff] and indexMapping[memberWithDebuff][indexGroup] or index
    end
end

return index
