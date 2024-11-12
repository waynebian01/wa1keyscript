local index = 0 --输出指令,46：选择敌人,50：耀,51：盾,52：全神贯注,53：快速治疗,54：恢复,55：耐力,56：输出
local lowest = 0
local lowestHealth = 100
local tank = 0
local auraName1 = "救赎"
local auraName2 = "恢复"
local auraName3 = "圣光涌动"
local auraName4 = "真言术：韧"
local auraName5 = "救赎之魂"
local auraName6 = "微风"
local playerHealth = UnitHealth("player") / UnitHealthMax("player") * 100
local ismoving = GetUnitSpeed("player") > 0               --检查玩家是否移动
local combat = UnitAffectingCombat("player")              --检查战斗状态
local targetcanattack = UnitCanAttack("player", "target") --检查目标是否可以攻击
local targetisalive = not UnitIsDeadOrGhost("target")     --检查目标是否存活


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


local isCastShine = isCastingSpell(194509)          --正在施放真言术：耀
-- 检查技能冷却
local GCD = getCooldown(61304)                      -- 公共冷却
local Shield = getCooldown(17)                      -- 真言术：盾
local Penance = getCooldown(47540)                  -- 苦修
local Rapture = getCooldown(47536)                  -- 全神贯注
-- 检测技能充能
local Shine = getCharges(194509)                    --真言术：耀
--检查玩家自身光环
local hasSurge = hasAura("player", auraName3, true) --圣光涌动
local hasZephyr = hasAura("player", auraName6, false) --微风
--检测队伍信息
local teammateCount = 0                             --队友数量
local RenewCount = 0                                --恢复数量
local noRedemption90 = 0                            --无救赎的数量
local noRedemption80 = 0                            --无救赎的数量

local cancast = not ismoving or hasZephyr           --是否可以施法

if UnitPlayerOrPetInRaid("player") then
    for i = 1, 40 do
        local unit = "raid" .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitCanAssist("player", unit) and UnitInRange(unit) then
            teammateCount = teammateCount + 1                               --计数队友数量
            local unitHealth = UnitHealth(unit) / UnitHealthMax(unit) * 100 --单位生命值
            local unitislowest = UnitIsUnit("target", "raid" .. lowest)     --是否是生命值最低的单位
            local hasAura1 = hasAura(unit, auraName1, true)                 --救赎
            local hasAura2 = hasAura(unit, auraName2, true)                 --恢复
            local hasAura3 = hasAura(unit, auraName4, false)                --韧
            local hasAura4 = hasAura(unit, auraName5, false)                --天使

            --定施放耀的阈值，根据队伍人数动态计算所需数量 (最小2，每5人+1，最大5)
            local setCount = 0
            setCount = math.min(5, math.max(2, math.floor((teammateCount + 4) / 5) + 1))

            --决定施放恢复的数量
            local setRenewCount = 3

            if hasAura2 then RenewCount = RenewCount + 1 end --统计恢复数量

            if not hasAura1 and not hasAura4 then            --无救赎无天使
                -- 统计生命值低于90和80的数量，以及最低生命值和单位ID
                if unitHealth < 90 then
                    noRedemption90 = noRedemption90 + 1
                end
                if unitHealth < 80 then
                    noRedemption80 = noRedemption80 + 1
                end
                if unitHealth < lowestHealth then
                    lowestHealth = unitHealth
                    lowest = i
                end
            end

            -- 检查战斗状态
            if combat then
                if noRedemption90 >= setCount and Shine >= 1 and cancast then
                    if unitislowest then
                        if not isCastShine or (noRedemption90 >= setCount + 5 and Shine == 2) then
                            index = 50
                        end
                    else
                        index = lowest + 5
                    end
                elseif noRedemption80 > 0 or (noRedemption90 >= 1 and not cancast) then
                    if unitislowest then
                        if hasSurge then
                            index = 53
                        elseif Shield <= GCD then
                            index = 51
                        elseif Rapture <= GCD then
                            index = 52
                        elseif RenewCount < setRenewCount then
                            index = 54
                        end
                    else
                        index = lowest + 5
                    end
                elseif noRedemption80 == 0 or Shine == 0 then
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
            local unitHealth = UnitHealth(unit) / UnitHealthMax(unit) * 100 --单位生命值
            local hasAura1 = hasAura(unit, auraName1, true)                 --队友救赎
            local hasAura2 = hasAura(unit, auraName4, false)                --韧
            local PlayerhasAura1 = hasAura("player", auraName1, true)       --玩家救赎
            local istank = UnitGroupRolesAssigned(unit) == "TANK"
            local reallowestHealth = 100
            local reallowest = 0

            if istank and not hasAura1 then tank = i + 1 end

            if not hasAura1 then                        --无救赎
                if unitHealth < 90 then                 --生命值低于90
                    noRedemption90 = noRedemption90 + 1 --无救赎的数量
                end
                if unitHealth < lowestHealth then       --最低生命值和单位ID
                    lowestHealth = unitHealth
                    lowest = i + 1
                end
            end
            if not PlayerhasAura1 then --处理玩家本身
                if playerHealth < 90 then
                    noRedemption90 = noRedemption90 + 1
                end
                if playerHealth < lowestHealth then --如果玩家是生命值最低的
                    lowestHealth = playerHealth
                    lowest = 1
                end
            end
            if unitHealth < reallowestHealth then
                reallowestHealth = unitHealth
                reallowest = i + 1
            end
            if playerHealth < reallowestHealth then
                reallowestHealth = playerHealth
                reallowest = 1
            end

            if not combat then
                if tank > 1 and Shield <= GCD then
                    index = tank + 60
                end
                if not hasAura2 or not hasAura("player", auraName4, false) then
                    index = 55
                end
                if reallowestHealth < 70 then
                    if Penance <= GCD then
                        index = reallowest + 80
                    end
                end
            else
                if noRedemption90 >= 2 and not isCastShine and cancast then
                    if Shine > 0 then
                        index = 50
                    end
                end
                if noRedemption90 == 1 or Shine == 0 or (noRedemption90 > 1 and not cancast) then
                    local indexMapping = {
                        [1] = { 61, 66, 71, 76 },
                        [2] = { 62, 67, 72, 77 },
                        [3] = { 63, 68, 73, 78 },
                        [4] = { 64, 69, 74, 79 },
                        [5] = { 65, 70, 75, 80 },
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
                        index = indexMapping[lowest] and indexMapping[lowest][indexGroup] or index
                    end
                end
                if (noRedemption90 == 0 or isCastShine) and targetcanattack and targetisalive then
                    index = 56
                end
            end
        end
    end
elseif not UnitPlayerOrPetInParty("player") then
    local PlayerhasAura1 = hasAura("player", auraName1, true)      --玩家救赎
    local playerhasFortitude = hasAura("player", auraName4, false) --玩家韧

    if not combat and not playerhasFortitude then
        index = 55
    end
    if combat then
        if not PlayerhasAura1 and playerHealth < 90 then
            if Shield <= GCD then
                index = 61
            end
            if hasSurge and playerHealth < 80 then
                index = 71
            end
        else
            if targetcanattack and targetisalive then
                index = 56
            end
        end
    end
end

return index
