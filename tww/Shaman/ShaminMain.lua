local index = 0 --输出指令。
local lowest = 0
local lowestHealth = 100
local tank = 0
local auraName1 = "激流"
local auraName2 = "大地之盾"
local auraName3 = "潮汐奔涌" --下一个治疗波或治疗链的施法时间缩短20%；或使你的下一个治疗之涌的爆击几率提高30%。
local auraName4 = "天怒"
local auraName5 = "救赎之魂"
local auraName6 = "浪潮汹涌" --使你的下2个治疗链额外获得10%的治疗量，并且每次弹跳的治疗效果不被削减。
local playerHealth = (UnitHealth("player") - UnitGetTotalHealAbsorbs("player")) / UnitHealthMax("player") * 100

-- 获取技能冷却时间的函数
local function getCooldown(spellID)
    local cooldown = C_Spell.GetSpellCooldown(spellID)
    return (cooldown.startTime > 0) and (cooldown.startTime + cooldown.duration - GetTime()) or 0
end
--获取技能充能层数的函数
local function getCharges(spellID)
    local charges = C_Spell.GetSpellCharges(spellID)
    return charges and charges.currentCharges or 0
end
-- 检查玩家是否正在施放特定法术的函数
local function isCastingSpell(spellID)
    local spellName = C_Spell.GetSpellInfo(spellID)
    local castingSpellName, _, _, _, _, _, _, _, _ = UnitCastingInfo("player")
    local channelingSpellName, _, _, _, _, _, _, _ = UnitChannelInfo("player")

    if castingSpellName == spellName or channelingSpellName == spellName then
        return true
    else
        return false
    end
end
--获取单位光环的函数
local function hasAura(unit, auraName, onlyPlayerCast)
    for j = 1, 40 do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, j, "HELPFUL")
        if not auraData then break end
        if auraData.name == auraName then
            if onlyPlayerCast then
                return auraData.sourceUnit == "player"
            else
                return true
            end
        end
    end
    return false
end
--获取激活图腾数量的函数
local function countActiveTotems(totemNames)
    local activeTotems = {}
    for _, totemName in ipairs(totemNames) do
        activeTotems[totemName] = 0
    end

    for i = 1, 4 do
        local haveTotem, totemName = GetTotemInfo(i)
        if haveTotem and activeTotems[totemName] ~= nil then
            activeTotems[totemName] = activeTotems[totemName] + 1
        end
    end

    return activeTotems
end

-- 检查玩家是否学习了某个技能的函数
local function IsPlayerSpell(spellID)
    return IsPlayerSpell(spellID)
end

-- 检查玩家是否学习了某个技能
local ElementalOrbit = IsPlayerSpell(383010)       --元素环绕,可以在自己和一名盟友身上同时拥有大地之盾
local ImprovedPurifySpirit = IsPlayerSpell(192222) --强化净化灵魂,净化灵魂会额外移除所有诅咒效果。
local WindShear = IsPlayerSpell(57994)             --风剪
local TremorTotem = IsPlayerSpell(8143)            --战栗图腾
local Hex = IsPlayerSpell(51514)                   --妖术
local Purge = IsPlayerSpell(370)                   --净化术
local GreaterPurge = IsPlayerSpell(51886)          --强效净化术
local EarthShield = IsPlayerSpell(974)             --大地之盾
local PoisonCleansingTotem = IsPlayerSpell(383013) --清毒图腾

--需要检查的图腾名称
local totemNames = { "治疗之泉图腾", "暴雨图腾" }
local activeTotems = countActiveTotems(totemNames)
--图腾激活数量
local activeHealingStreamTotems = activeTotems["治疗之泉图腾"]
local activeCloudburstTotems = activeTotems["暴雨图腾"]
-- 检查技能冷却
local GCD = getCooldown(61304) -- 公共冷却

-- 检测技能充能
local HealingStreamTotem = getCharges(5394)               --治疗之泉图腾
local CloudburstTotem = getCharges(157153)                --暴雨图腾
local Riptide = getCharges(61295)                         --激流
--检查玩家自身光环
local hasSurge = hasAura("player", auraName2, true)       --大地之盾
--检测队伍信息
local teammateCount = 0                                   --队友数量
local eightyCount = 0                                     --生命值低于80的数量
local sixtyCount = 0                                      --生命值低于60的数量
--全局检查
local targetcanattack = UnitCanAttack("player", "target") --目标是否可以攻击
local targetisalive = not UnitIsDeadOrGhost("target")     --目标是否存活
local combat = UnitAffectingCombat("player")              --玩家是否在战斗状态

if UnitPlayerOrPetInRaid("player") then
    for i = 1, 40 do
        local unit = "raid" .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitCanAssist("player", unit) and UnitInRange(unit) then
            teammateCount = teammateCount + 1
            local unitHealth = (UnitHealth(unit) - UnitGetTotalHealAbsorbs(unit)) / UnitHealthMax(unit) * 100

            if not hasAura5 then        --无天使
                if unitHealth < 80 then --统计生命值低于90数量
                    eightyCount = eightyCount + 1
                end
                if unitHealth < 60 then --统计生命值低于60数量
                    sixtyCount = sixtyCount + 1
                end
                if unitHealth < lowestHealth then --最低生命值和生命值最低单位ID
                    lowestHealth = unitHealth
                    lowest = i
                end
            end
            if combat then
                if eightyCount > 5 then
                    if not UnitIsUnit("target", "raid" .. lowest) then
                        index = lowest + 5
                    else
                        if not isCastingSpell(197995) then
                            index = 50
                        end
                    end
                else
                    if targetcanattack and targetisalive then
                        index = 56
                    else
                        index = 46
                    end
                end
            else
                if not hasAura3 then
                    index = 55
                end
            end
        end
    end
elseif UnitPlayerOrPetInParty("player") then
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitCanAssist("player", unit) and UnitInRange(unit) then
        end
    end
elseif not UnitPlayerOrPetInParty("player") then
    if not combat then
        index = 55
    else
    end
end

return index
