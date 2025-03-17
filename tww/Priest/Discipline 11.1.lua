--输出指令, 46：选择敌人, 50：耀, 51：盾, 52：福音, 53：快速治疗, 54：恢复, 55：耐力
local auraSurge = "圣光涌动"
local playerHealth = (UnitHealth("player") - UnitGetTotalHealAbsorbs("player")) / UnitHealthMax("player") * 100
local ismoving = GetUnitSpeed("player") > 0               --检查玩家是否移动
local combat = UnitAffectingCombat("player")              --检查战斗状态
local targetcanattack = UnitCanAttack("player", "target") --检查目标是否可以攻击
local targetisalive = not UnitIsDeadOrGhost("target")     --检查目标是否存活

if IsMounted("player") or                                 --坐骑
    UnitInVehicle("player") or                            --载具
    ChatFrame1EditBox:IsVisible() or                      --聊天框
    UnitIsDeadOrGhost("player") or                        --死亡
    UnitChannelInfo("player")                             --引导法术
then
    return 0
end

-- 检查单位是否正在施放特定法术的函数
local function isUnitCastingSpell(unitOrType, spellInput, isMultiUnit)
    local spellName
    if type(spellInput) == "number" then
        local spellInfo = C_Spell.GetSpellInfo(spellInput)
        spellName = spellInfo and spellInfo.name or nil
    else
        spellName = spellInput
    end

    if not spellName then return false end

    local units = {}
    if isMultiUnit then
        for i = 1, 40 do
            table.insert(units, unitOrType .. i)
        end
    else
        units = { unitOrType }
    end

    for _, unit in ipairs(units) do
        local castingSpellName = UnitCastingInfo(unit)
        local channelingSpellName = UnitChannelInfo(unit)
        if castingSpellName == spellName or channelingSpellName == spellName then
            return true
        end
    end
    return false
end

if isUnitCastingSpell("boss", "黑暗降临", true) then
    return 0
end

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
--有效目标
local function isValidUnit(unit)
    return UnitExists(unit) and
        not UnitIsDeadOrGhost(unit) and
        UnitCanAssist("player", unit) and
        UnitInRange(unit)
end


local _, intellect = UnitStat("player", 4)
local versatilityBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) / 100 + 1
local EvangelismValue = intellect * 60 * versatilityBonus

local isCastShine = isUnitCastingSpell("player", 194509, false)    --正在施放真言术：耀
-- 检查技能冷却
local GCD = getCooldown(61304)                                     -- 公共冷却
local Shield = getCooldown(17) <= GCD                              -- 真言术：盾
local Penance = getCooldown(47540) <= GCD                          -- 苦修
local knownEvangelism = IsPlayerSpell(472433)                      --学会了福音
local Evangelism = getCooldown(472433) <= GCD and knownEvangelism  -- 福音

-- 检测技能充能
local shineCharges = getCharges(194509)             --真言术：耀
--检查玩家自身光环
local hasSurge = hasAura("player", auraSurge, true) --圣光涌动
--检测队伍信息


-- 定义 UnitInfo 函数，用于统计队伍或团队中的单位信息
local function UnitInfo(mode, threshold)
    local HasRedemptionCount = 0         -- 统计有“救赎”光环且血量低于阈值的单位数量
    local NoRedemptionCount = 0          -- 统计没有“救赎”光环且血量低于阈值的单位数量
    local tank = 0                       -- 存储无“救赎”坦克的单位索引，默认值为 0
    local NoFortitudeCount = 0           -- 统计没有“真言术：韧”光环的单位数量
    local RenewCount = 0                 -- 统计有“恢复”光环的单位数量
    local LowestNoRedemption = 0         -- 存储血量最低且无“救赎”光环的单位索引，默认值为 0
    local LowestNoRedemptionHealth = 100 -- 存储血量最低且无“救赎”光环的单位血量百分比，默认值为 100%
    local LowestUnit = 0                 -- 存储血量最低的单位索引（不检测光环），默认值为 0
    local LowestHealth = 100             -- 存储血量最低单位的血量百分比（不检测光环），默认值为 100%
    local EvangelismCount = 0            --满足“福音”治疗量的单位

    -- 定义光环名称常量，避免外部依赖
    local auraName1 = "救赎" -- 光环名称：救赎
    local auraName2 = "恢复" -- 光环名称：恢复
    local auraName3 = "真言术：韧" -- 光环名称：真言术：韧
    local auraName4 = "救赎之魂" -- 光环名称：救赎之魂

    local playerHealthPercent = (UnitHealth("player") - UnitGetTotalHealAbsorbs("player")) / UnitHealthMax("player") *
        100
    local playerHasRedemption = hasAura("player", auraName1, true)
    local playerHasFortitude = hasAura("player", auraName3, false)
    local playerHasRenew = hasAura("player", auraName2, true)

    if mode == "raid" then
        for i = 1, 40 do
            local unit = "raid" .. i
            if isValidUnit(unit) then                                 -- 检查单位是否有效（存在、存活、可协助且在范围内）
                local unitHealth = (UnitHealth(unit) - UnitGetTotalHealAbsorbs(unit)) / UnitHealthMax(unit) * 100
                local hasRedemption = hasAura(unit, auraName1, true)  -- 是否有救赎光环（仅玩家施放）
                local hasFortitude = hasAura(unit, auraName3, false)  -- 是否有真言术：韧光环
                local hasRenew = hasAura(unit, auraName2, true)       -- 是否有恢复光环（仅玩家施放）
                local hasSpirit = hasAura(unit, auraName4, false)     -- 是否有救赎之魂光环
                local istank = UnitGroupRolesAssigned(unit) == "TANK" -- 是否为坦克角色
                local RaidLossHealth = math.max(0,
                    UnitHealthMax(unit) - UnitHealth(unit) - UnitGetTotalHealAbsorbs(unit))
                if hasRedemption then
                    HasRedemptionCount = HasRedemptionCount + 1
                end

                if not hasRedemption and not hasSpirit then
                    if unitHealth < threshold then
                        NoRedemptionCount = NoRedemptionCount + 1
                    end

                    if unitHealth < LowestNoRedemptionHealth then
                        LowestNoRedemptionHealth = unitHealth
                        LowestNoRedemption = i + 5 -- 索引 6-46
                    end
                end

                if not hasFortitude then
                    NoFortitudeCount = NoFortitudeCount + 1
                end

                if hasRenew then
                    RenewCount = RenewCount + 1
                end

                if istank and not hasRedemption then
                    tank = i + 5 -- 索引 6-46
                end

                if unitHealth < LowestHealth then
                    LowestHealth = unitHealth
                    LowestUnit = i + 5 -- 索引 6-46
                end
                if not HasRedemptionCount == 0 then
                    local AverageEvangelism = EvangelismValue / HasRedemptionCount --"福音"的平均治疗量
                    if AverageEvangelism < RaidLossHealth then
                        EvangelismCount = EvangelismCount + 1
                    end
                end
            end
        end
    elseif mode == "party" then
        if playerHasRedemption then
            HasRedemptionCount = HasRedemptionCount + 1
        end
        if not playerHasRedemption and playerHealthPercent < threshold then
            NoRedemptionCount = NoRedemptionCount + 1
            LowestNoRedemption = 1
            LowestNoRedemptionHealth = playerHealthPercent
        end
        if not playerHasFortitude then
            NoFortitudeCount = NoFortitudeCount + 1
        end
        if playerHasRenew then
            RenewCount = RenewCount + 1
        end
        if playerHealthPercent < LowestHealth then
            LowestHealth = playerHealthPercent
            LowestUnit = 1
        end

        -- 再统计小队成员
        for i = 1, 4 do
            local unit = "party" .. i
            if isValidUnit(unit) and not UnitIsUnit(unit, "player") then -- 避免重复统计玩家
                local unitHealth = (UnitHealth(unit) - UnitGetTotalHealAbsorbs(unit)) / UnitHealthMax(unit) * 100
                local hasRedemption = hasAura(unit, auraName1, true)
                local hasFortitude = hasAura(unit, auraName3, false)
                local hasRenew = hasAura(unit, auraName2, true)
                local istank = UnitGroupRolesAssigned(unit) == "TANK"
               
                if hasRedemption then
                    HasRedemptionCount = HasRedemptionCount + 1
                end
                if not hasRedemption then
                    if unitHealth < threshold then
                        NoRedemptionCount = NoRedemptionCount + 1
                    end
                    if unitHealth < LowestNoRedemptionHealth then
                        LowestNoRedemptionHealth = unitHealth
                        LowestNoRedemption = i + 1
                    end
                end
                if not hasFortitude then
                    NoFortitudeCount = NoFortitudeCount + 1
                end
                if hasRenew then
                    RenewCount = RenewCount + 1
                end
                if istank and not hasRedemption then
                    tank = i + 1
                end
                if unitHealth < LowestHealth then
                    LowestHealth = unitHealth
                    LowestUnit = i + 1
                end
            end
        end
        local playerLossHealth = math.max(0,
            UnitHealthMax("player") - UnitHealth("player") - UnitGetTotalHealAbsorbs("player"))
        local partyLossHealth1 = isValidUnit("party1") and
            math.max(0, UnitHealthMax("party1") - UnitHealth("party1") - UnitGetTotalHealAbsorbs("party1")) or 0
        local partyLossHealth2 = isValidUnit("party2") and
            math.max(0, UnitHealthMax("party2") - UnitHealth("party2") - UnitGetTotalHealAbsorbs("party2")) or 0
        local partyLossHealth3 = isValidUnit("party3") and
            math.max(0, UnitHealthMax("party3") - UnitHealth("party3") - UnitGetTotalHealAbsorbs("party3")) or 0
        local partyLossHealth4 = isValidUnit("party4") and
            math.max(0, UnitHealthMax("party4") - UnitHealth("party4") - UnitGetTotalHealAbsorbs("party4")) or 0
        if HasRedemptionCount > 0 then
            local AverageEvangelism = EvangelismValue / HasRedemptionCount
            if AverageEvangelism < partyLossHealth1 then EvangelismCount = EvangelismCount + 1 end
            if AverageEvangelism < partyLossHealth2 then EvangelismCount = EvangelismCount + 1 end
            if AverageEvangelism < partyLossHealth3 then EvangelismCount = EvangelismCount + 1 end
            if AverageEvangelism < partyLossHealth4 then EvangelismCount = EvangelismCount + 1 end
            if AverageEvangelism < playerLossHealth then EvangelismCount = EvangelismCount + 1 end
        end
    else
        -- 无效模式，返回默认值
        return 0, 0, 0, 0, 100, 0, 100, 0, 0
    end

    return HasRedemptionCount, NoRedemptionCount, LowestNoRedemption, LowestNoRedemptionHealth, NoFortitudeCount,
        LowestUnit, LowestHealth, tank, RenewCount, EvangelismCount
end

if UnitPlayerOrPetInRaid("player") then
    local teammateCount = 0 --队友数量
    for i = 1, 40 do
        local unit = "raid" .. i
        if isValidUnit(unit) then
            local HasRedemptionCount, NoRedemptionCount, LowestNoRedemption, LowestNoRedemptionHealth, NoFortitudeCount, LowestUnit, LowestHealth, tank, RenewCount, EvangelismCount =
                UnitInfo("raid", 90)
            local unitislowest = UnitIsUnit("target", "raid" .. LowestHealth) --是否是生命值最低的单位
            --定施放耀的阈值，根据队伍人数动态计算所需数量 (最小2，每5人+1，最大5)
            local setCount = 0
            setCount = math.min(5, math.max(2, math.floor((teammateCount + 4) / 5) + 1))

            --决定施放恢复的数量
            local setRenewCount = 3
            if combat then
                if NoRedemptionCount >= setCount and shineCharges >= 1 and not ismoving then
                    if unitislowest then
                        if not isCastShine or (NoRedemptionCount >= setCount + 5 and shineCharges == 2) then
                            return 50
                        end
                    else
                        return LowestUnit + 5
                    end
                elseif NoRedemptionCount > 0 or (NoRedemptionCount >= 1 and ismoving) then
                    if unitislowest then
                        if hasSurge then
                            return 53
                        elseif Shield then
                            return 51
                        elseif RenewCount < setRenewCount then
                            return 54
                        end
                    else
                        return LowestUnit + 5
                    end
                elseif NoRedemptionCount == 0 or shineCharges == 0 then
                    if targetcanattack and targetisalive then
                        return 0
                    else
                        return 46
                    end
                end
            else
                if NoFortitudeCount ~= 0 then
                    return 55
                end
            end
        end
    end
elseif UnitPlayerOrPetInParty("player") then
    local HasRedemptionCount, NoRedemptionCount, LowestNoRedemption, LowestNoRedemptionHealth, NoFortitudeCount, LowestUnit, LowestHealth, tank, RenewCount, EvangelismCount =
        UnitInfo("party", 92)
    if not combat then
        if NoFortitudeCount ~= 0 then
            return 55
        end
        if tank > 1 and Shield then
            return tank + 60
        end
        if LowestHealth < 70 and Penance then
            return LowestUnit + 80 --80-85苦修
        end
    else
        if NoRedemptionCount == 0 then
            return 0
        end
        if Evangelism and EvangelismCount >= 3 then
            return 52
        end
        if NoRedemptionCount >= 2 and shineCharges >= 1 and not isCastShine and not ismoving then
            return 50
        end
        if NoRedemptionCount == 1 or shineCharges == 0 or ismoving then
            local indexMapping = {
                [1] = { 61, 71, 76 },
                [2] = { 62, 72, 77 },
                [3] = { 63, 73, 78 },
                [4] = { 64, 74, 79 },
                [5] = { 65, 75, 80 },
            }
            --61-65盾，71-75快速治疗，76-80恢复
            local indexGroup
            if hasSurge then
                indexGroup = 2
            elseif Shield then
                indexGroup = 1
            else
                indexGroup = 3
            end
            if indexGroup then
                return indexMapping[LowestNoRedemption] and indexMapping[LowestNoRedemption][indexGroup]
            end
        end
    end
elseif not UnitPlayerOrPetInParty("player") then
    local PlayerhasAura1 = hasAura("player", "救赎", true) --玩家救赎
    local playerhasFortitude = hasAura("player", "真言术：韧", false) --玩家韧

    if not combat and not playerhasFortitude then
        return 55
    end
    if combat then
        if not PlayerhasAura1 and playerHealth < 90 then
            if Shield then
                return 61
            end
            if hasSurge and playerHealth < 80 then
                return 71
            end
            return 0
        end
    end
end

return 0
