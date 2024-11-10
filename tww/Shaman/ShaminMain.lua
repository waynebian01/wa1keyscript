local index = 0 --输出指令,46：选择敌人,50：耀,51：盾,52：全神贯注,53：快速治疗,54：恢复,55：耐力,56：输出
local lowest = 0
local lowestHealth = 100
local tank = 0
local auraName1 = "激流"
local auraName2 = "大地之盾"
local auraName3 = "涌动"
local auraName4 = "天怒"
local auraName5 = "救赎之魂"
local playerHealth = UnitHealth("player") / UnitHealthMax("player") * 100

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

-- 检查技能冷却
local GCD = getCooldown(61304)                      -- 公共冷却
local Shield = getCooldown(17)                      -- 真言术：盾
local Penance = getCooldown(47540)                  -- 苦修
local Rapture = getCooldown(47536)                  -- 全神贯注
-- 检测技能充能
local Cloudburst = getCharges(157153)                    --暴雨图腾

--检查玩家自身光环
local hasSurge = hasAura("player", auraName3, true) --圣光涌动
--检测队伍信息
local teammateCount = 0                             --队友数量
local RenewCount = 0                                --恢复数量
local noRedemptionCount = 0                         --无救赎的数量
--检查目标信息
local targetcanattack = UnitCanAttack("player", "target")
local targetisalive = not UnitIsDeadOrGhost("target") --玩家当前目标是否存活
--检查战斗状态
local combat = UnitAffectingCombat("player")

if UnitPlayerOrPetInRaid("player") then
    for i = 1, 40 do
        local unit = "raid" .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitCanAssist("player", unit) and UnitInRange(unit) then
            teammateCount = teammateCount + 1                               --计数队友数量
            local unitHealth = UnitHealth(unit) / UnitHealthMax(unit) * 100 --单位生命值
            local hasAura1 = hasAura(unit, auraName1, true)                 --救赎
            local hasAura2 = hasAura(unit, auraName2, true)                 --恢复
            local hasAura3 = hasAura(unit, auraName4, false)                --韧
            local hasAura4 = hasAura(unit, auraName5, false)                --天使

            --根据队友数量决定施放耀的阈值，根据队伍人数动态计算所需数量 (最小2，每5人+1，最大5)
            local setCount = 0
            setCount = math.min(5, math.max(2, math.floor((teammateCount + 4) / 5) + 1))

            --根据队友数量决定是否施放恢复的数量
            local setRenewCount = 0
            if teammateCount > 1 then
                setRenewCount = teammateCount <= 5 and 2 or teammateCount <= 15 and 3 or 4
            end

            if hasAura2 then RenewCount = RenewCount + 1 end --统计恢复数量

            if not hasAura1 and not hasAura4 then            --无救赎无天使
                if unitHealth < 90 then                      --统计生命值低于90数量
                    noRedemptionCount = noRedemptionCount + 1
                end
                if unitHealth < lowestHealth then --最低生命值和生命值最低单位ID
                    lowestHealth = unitHealth
                    lowest = i
                end
            end
            if combat then
                if (noRedemptionCount > 0 and noRedemptionCount < setCount) or
                    (noRedemptionCount >= setCount and RenewCount <= setRenewCount) then
                    if not UnitIsUnit("target", "raid" .. lowest) then
                        index = lowest + 5
                    end
                    if UnitIsUnit("target", "raid" .. lowest) then
                        if not hasAura("target", auraName1, true) then
                            if noRedemptionCount >= setCount then
                                if Shine >= 1 then
                                    index = 50
                                elseif Shine == 0 then
                                    if Shield <= GCD then
                                        index = 51
                                    elseif Rapture <= GCD then
                                        index = 52
                                    elseif hasSurge then
                                        index = 53
                                    elseif RenewCount < setRenewCount then
                                        index = 54
                                    end
                                end
                            elseif noRedemptionCount > 0 and noRedemptionCount < setCount then
                                if Shield <= GCD then
                                    index = 51
                                elseif Rapture <= GCD then
                                    index = 52
                                elseif hasSurge then
                                    index = 53
                                elseif RenewCount < setRenewCount then
                                    index = 54
                                end
                            end
                        end
                    end
                else
                    if targetcanattack and targetisalive then
                        index = 56
                    else
                        index = 46
                    end
                end
            end
            if not combat then
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
            local isCastShine = isCastingSpell(194509)
            if istank and not hasAura1 then
                tank = i + 1
            end
            if not hasAura1 then                              --无救赎
                if unitHealth < 90 then                       --生命值低于90
                    noRedemptionCount = noRedemptionCount + 1 --无救赎的数量
                end
                if unitHealth < lowestHealth then             --最低生命值和单位ID
                    lowestHealth = unitHealth
                    lowest = i + 1
                end
            end
            if not PlayerhasAura1 then --处理玩家本身
                if playerHealth < 90 then
                    noRedemptionCount = noRedemptionCount + 1
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
            end

            if combat then
                if noRedemptionCount >= 2 and not isCastShine then
                    if Shine > 0 then
                        index = 50
                    end
                end
                if noRedemptionCount == 1 or Shine == 0 then
                    local indexMapping = {
                        [1] = { 61, 66, 71, 76 },
                        [2] = { 62, 67, 72, 77 },
                        [3] = { 63, 68, 73, 78 },
                        [4] = { 64, 69, 74, 79 },
                        [5] = { 65, 70, 75, 80 },
                    }
                    --61-65盾，66-70全神贯注，71-75快速治疗，76-80恢复，80-81苦修
                    local indexGroup
                    if Shield <= GCD then
                        indexGroup = 1
                    elseif Rapture <= GCD then
                        indexGroup = 2
                    elseif hasSurge then
                        indexGroup = 3
                    else
                        indexGroup = 4
                    end

                    if indexGroup then
                        index = indexMapping[lowest] and indexMapping[lowest][indexGroup] or index
                    end
                end
                if (noRedemptionCount == 0 or isCastShine) and targetcanattack and targetisalive then
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
