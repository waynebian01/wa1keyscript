local debuff = {
    ["燃烧之烙"] = true,
    ["吸血鬼的拥抱"] = true,
    [52493] = true,
    [53317] = true, -- 撕裂
    [48880] = true, -- 撕裂
    [53030] = true, -- 中毒
    [53601] = true, -- 投掷
    [55521] = true, -- 中毒
    [55249] = true, --
    [55276] = true,
    [54956] = true,
}

local function existsUnit(data)
    return data and data.inRange and data.canAssist and data.inSight and not data.isDead
end

-- 获取没有盾的最低血量单位和坦克最低血量单位
function aura_env.GetNoShieldUnit()
    local shield = {
        lowestUnit = nil,
        lowestHealth = 100,
        tankUnit = nil,
        tankHealth = 100,
        hasDebuffUnit = nil,
        hasDebuffHealth = 100,
    }

    if not Skippy.Group then return shield end

    for unit, data in pairs(Skippy.Group) do
        local hasShield = false
        local canShield = true
        local hasDebuff = false
        if existsUnit(data) then
            for _, aura in pairs(data.aura) do
                if aura.sourceUnit == "player" and aura.name == "真言术：盾" then
                    hasShield = true
                end
                if aura.name == "虚弱灵魂" then
                    canShield = false
                end
                if debuff[aura.name] or debuff[aura.spellId] then
                    hasDebuff = true
                end
            end

            if not hasShield and canShield then
                if data.percentHealth < shield.lowestHealth then
                    shield.lowestHealth = data.percentHealth
                    shield.lowestUnit = unit
                end
                if data.role == "TANK" then
                    shield.tankUnit = unit
                    shield.tankHealth = data.percentHealth
                end
                if hasDebuff and data.percentHealth < shield.hasDebuffHealth then
                    shield.hasDebuffHealth = data.percentHealth
                    shield.hasDebuffUnit = unit
                end
            end
        end
    end
    return shield
end
