local index = 0 --输出指令。
local lowest = 0
local lowestHealth = 100
local noRiptidelowest = 0
local noRiptidelowestHealth = 100
local tank = 0
local auraName1 = "激流"
local auraName2 = "大地之盾"
local auraName3 = "潮汐奔涌" --激流,下一个治疗波或治疗链的施法时间缩短20%；或使你的下一个治疗之涌的爆击几率提高30%。
local auraName4 = "潮汐使者" --治疗链施法缩短50%，跳转距离增加100%
local auraName5 = "浪潮汹涌" --使你的下2个治疗链额外获得10%的治疗量，并且每次弹跳的治疗效果不被削减。
local auraName6 = "元素宗师" --治疗之涌治疗量提高30%
local SpiritofRedemption = "救赎之魂" --救赎之魂
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
-- 获取单位的光环层数
local function getAuraStacks(unit, auraName)
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if auraData and auraData.name == auraName then
            return auraData.applications -- 这里返回光环的层数（stacks）
        end
    end
    return 0 -- 如果找不到指定的光环，返回0
end

-- 检查玩家是否学习了某个技能
local ElementalOrbit = IsPlayerSpell(383010) --元素环绕,可以在自己和一名盟友身上同时拥有大地之盾
local PlayerSwiftness = IsPlayerSpell(378081) --自然迅捷

--检查玩家自身光环
local PlayerEarthShield = hasAura("player", auraName2, true) --玩家大地之盾光环
local PlayerRiptid = hasAura("player", auraName1, true)      --激流
local hasTidalWaves = hasAura("player", auraName3, true)     --潮汐奔涌
local hasTidebringer = hasAura("player", auraName4, true)    --潮汐使者
local hasHighTide = hasAura("player", auraName5, true)       --浪潮汹涌
--检查玩家光环层数
local hasMaster = getAuraStacks("player", auraName6) --元素宗师

--需要检查的图腾名称
local totemNames = { "治疗之泉图腾", "暴雨图腾" }
local activeTotems = countActiveTotems(totemNames)
--图腾激活数量
local activeHealingStreamTotems = activeTotems["治疗之泉图腾"]
local activeCloudburstTotems = activeTotems["暴雨图腾"]
-- 检查技能冷却
local GCD = getCooldown(61304) -- 公共冷却
local Swiftness = getCooldown(378081) -- 自然迅捷


-- 检测技能充能
local HealingStreamTotem = getCharges(5394)               --治疗之泉图腾
local CloudburstTotem = getCharges(157153)                --暴雨图腾
local Riptide = getCharges(61295)                         --激流
--检测队伍信息
local teammateCount = 0                                   --队友数量
local eightyCount = 0                                     --生命值低于80的数量
local sixtyCount = 0                                      --生命值低于60的数量
--全局检查
local targetcanattack = UnitCanAttack("player", "target") --目标是否可以攻击
local targetisalive = not UnitIsDeadOrGhost("target")     --目标是否存活
local combat = UnitAffectingCombat("player")              --玩家是否在战斗状态

if ElementalOrbit and not PlayerEarthShield then index = 81 end

if UnitPlayerOrPetInRaid("player") then
    for i = 1, 40 do
        local unit = "raid" .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitCanAssist("player", unit) and UnitInRange(unit) then
            teammateCount = teammateCount + 1
            local unitHealth = (UnitHealth(unit) - UnitGetTotalHealAbsorbs(unit)) / UnitHealthMax(unit) * 100
        end
    end
elseif UnitPlayerOrPetInParty("player") then
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitCanAssist("player", unit) and UnitInRange(unit) then
            local unitHealth = (UnitHealth(unit) - UnitGetTotalHealAbsorbs(unit)) / UnitHealthMax(unit) * 100 --单位生命值
            local hasRiptide = hasAura(unit, auraName1, true)                                                 --激流
            local hasEarthShield = hasAura(unit, auraName2, true)                                             --大地之盾
            local istank = UnitGroupRolesAssigned(unit) == "TANK"                                             --是否是坦克

            if istank and not hasEarthShield then tank = i + 1 end
            if unitHealth < 80 then eightyCount = eightyCount + 1 end
            if playerHealth < 80 then eightyCount = eightyCount + 1 end
            if unitHealth < 60 then sixtyCount = sixtyCount + 1 end
            if playerHealth < 60 then sixtyCount = sixtyCount + 1 end

            if unitHealth < lowestHealth then
                lowestHealth = unitHealth
                lowest = i + 1
            end
            if playerHealth < lowestHealth then
                lowestHealth = playerHealth
                lowest = 1
            end
            if not hasRiptide and unitHealth < noRiptidelowestHealth then
                noRiptidelowestHealth = unitHealth
                noRiptidelowest = i + 1
            end
            if not PlayerRiptid and playerHealth < noRiptidelowestHealth then
                noRiptidelowestHealth = playerHealth
                noRiptidelowest = 1
            end
            if tank > 1 then
                index = tank + 80
            end
            --50治疗之泉图腾，51自然迅捷，61-65治疗波，66-70治疗之涌，71-75激流，76-80治疗链，80-85大地之盾
            if Swiftness == 0 and PlayerSwiftness and lowestHealth < 60 then
                index = 51
            end
            if noRiptidelowestHealth < 90 and not hasTidalWaves and Riptide >= 1 then
                index = noRiptidelowest + 70
            end
            if hasHighTide then
                if eightyCount >= 1 and HealingStreamTotem >= 1 and activeHealingStreamTotems == 0 then
                    index = 50
                end
                if eightyCount >= 3 and HealingStreamTotem >= 1 then
                    if activeHealingStreamTotems == 0 then
                        index = 50
                    elseif activeHealingStreamTotems == 1 then
                        index = lowest + 75
                    end
                end
                if sixtyCount >= 3 then
                    if HealingStreamTotem == 0 then
                        index = lowest + 75
                    else
                        index = 50
                    end
                end
            end
            if hasTidalWaves then
                if lowestHealth < 85 then
                    index = lowest + 60
                end
                if lowestHealth < 70 then
                    index = lowest + 65
                end
            end
            if not hasTidalWaves and Riptide == 0 then
                if lowestHealth < 85 then
                    index = lowest + 60
                end
                if lowestHealth < 70 then
                    index = lowest + 65
                end
            end
        end
    end
elseif not UnitPlayerOrPetInParty("player") then
    if not combat then
        index = 55
    else
    end
end

return index
