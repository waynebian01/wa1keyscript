if not Skippy then Skippy = {} end
-- 攻击速度降低
local attackSpeedSlow = {
    ["冰霜疫病"] = true,
    ["雷霆一击"] = true,
    ["正义审判"] = true,
    ["感染伤口"] = true,
}
-- 攻强降低
local attackPowerSlow = {
    ["挫志怒吼"] = true,
    ["辩护"] = true,
    ["挫志咆哮"] = true,
    ["虚弱诅咒"] = true,
}

-- 攻击速度降低
function Skippy.AttackSpeedSlow()
    local hasCount = 0
    local noCount = 0
    if not Skippy.Nameplate then return noCount, hasCount end
    for unit, data in pairs(Skippy.Nameplate) do
        if data and data.exists and data.creatureID ~= 11 and data.aura and data.maxRange and data.maxRange <= 8 then
            local hasAttackSpeedSlow = false
            for _, aura in pairs(data.aura) do
                if attackSpeedSlow[aura.name] then
                    hasAttackSpeedSlow = true
                end
            end
            if hasAttackSpeedSlow then
                hasCount = hasCount + 1
            else
                noCount = noCount + 1
            end
        end
    end
    return noCount, hasCount
end

-- 攻强降低
function Skippy.AttackPowerSlow()
    local hasCount = 0
    local noCount = 0
    if not Skippy.Nameplate then return noCount, hasCount end
    for unit, data in pairs(Skippy.Nameplate) do
        if data and data.exists and data.creatureID ~= 11 and data.aura and data.maxRange and data.maxRange <= 8 then
            local hasAttackPowerSlow = false
            for _, aura in pairs(data.aura) do
                if attackPowerSlow[aura.name] then
                    hasAttackPowerSlow = true
                end
            end
            if hasAttackPowerSlow then
                hasCount = hasCount + 1
            else
                noCount = noCount + 1
            end
        end
    end
    return noCount, hasCount
end
