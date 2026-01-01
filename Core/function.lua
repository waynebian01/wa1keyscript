-- 常用函数
if not Skippy then Skippy = {} end

local function existsUnit(data)
    return data.inRange and data.canAssist and data.inSight and not data.isDead
end

local function makeAuraSet(auraTable)
    local set = {}
    for _, name in ipairs(auraTable or {}) do
        set[name] = true
    end
    return set
end

-- @param castTime 施法剩余时间, 默认0.4秒
-- @return boolean 法术在最后指定时间内完成施法返回true, 否则返回false
function Skippy.IsFinishedCasting(castTime)
    castTime = castTime or 0.4
    local currentTime = GetTime()
    if Skippy.state.cast and Skippy.state.castInfo then
        if (Skippy.state.castInfo.endTimeMS / 1000) - currentTime >= castTime then
            return false
        end
    end
    return true
end

-- @param castTime 施法剩余时间, 默认0.4秒
-- @return boolean 引导法术在最后指定时间内完成施法返回true, 否则返回false
function Skippy.IsFinishedChanneling(channelTime)
    channelTime = channelTime or 0.4
    local currentTime = GetTime()
    if Skippy.state.channel and Skippy.state.channelInfo then
        if Skippy.state.channelInfo.endTimeMS / 1000 - currentTime >= channelTime then
            return false
        end
    end
    return true
end

-- @param unit 单位名称，如：party1、raid2...
-- @return 是否可以协助
function Skippy.IsUnitCanAssist(unit)
    if not Skippy.Group or not unit then return false end
    local data = Skippy.Group[unit]
    if data and data.exists and data.inRange and data.canAssist and data.inSight and not data.isDead then
        return true
    end
    return false
end

-- @param range 范围
-- @return 指定范围内敌人数量（筛选后，图腾不包含在内）
function Skippy.GetEnemyCount(range)
    local count = 0
    if not Skippy.Nameplate then return count end
    for unit, data in pairs(Skippy.Nameplate) do
        if data and data.exists and data.creatureID ~= 11 and data.maxRange and data.maxRange <= range then
            count = count + 1
        end
    end
    return count
end

-- @param range 范围
-- @param creatureType 生物类型
-- @return 指定范围内敌人数量
function Skippy.GetEnemyCountWithCreatureType(range, creatureType)
    local count = 0
    if not Skippy.Nameplate then return count end
    for unit, data in pairs(Skippy.Nameplate) do
        if data and data.exists and data.maxRange and data.maxRange <= range and data.creatureType == creatureType then
            count = count + 1
        end
    end
    return count
end

-- @param range 范围
-- @param auraName 光环名称
-- @return 指定范围内敌人数量（未筛选，图腾也包含在内）
function Skippy.GetEnemyCountWithoutAura(range, auraName)
    local count = 0
    if not Skippy.Nameplate then return count end
    for unit, data in pairs(Skippy.Nameplate) do
        if data and data.exists and data.aura and data.maxRange and data.maxRange <= range then
            local hasAura = false

            for _, aura in pairs(data.aura) do
                if aura.name == auraName then
                    hasAura = true
                    break
                end
            end

            if not hasAura then
                count = count + 1
            end
        end
    end
    return count
end

-- @param range 范围
-- @param auraName 光环名称
-- @return 指定范围内敌人数量（未筛选，图腾也包含在内）
function Skippy.GetEnemyCountWithoutPlayerAura(range, auraName)
    local count = 0
    if not Skippy.Nameplate then return count end
    for unit, data in pairs(Skippy.Nameplate) do
        if data and data.exists and data.aura and data.maxRange and data.maxRange <= range then
            local hasAura = false
            for _, aura in pairs(data.aura) do
                if aura.name == auraName and aura.sourceUnit == "player" then
                    hasAura = true
                    break
                end
            end
            if not hasAura then
                count = count + 1
            end
        end
    end
    return count
end

-- @param auraName 光环名称或光环ID
-- @param byPlayerOnly 是否只返回玩家光环,默认true
-- @return 玩家光环信息
function Skippy.GetPlayerAuras(spellIdentifier, byPlayerOnly)
    if not Skippy.state.auras then return nil end
    for _, aura in pairs(Skippy.state.auras) do
        if byPlayerOnly == false then
            if type(spellIdentifier) == "string" and aura.name == spellIdentifier then
                return aura
            end
            if type(spellIdentifier) == "number" and aura.spellId == spellIdentifier then
                return aura
            end
        end
        if byPlayerOnly == nil or byPlayerOnly == true then
            if aura.sourceUnit == "player" then
                if type(spellIdentifier) == "string" and aura.name == spellIdentifier then
                    return aura
                end
                if type(spellIdentifier) == "number" and aura.spellId == spellIdentifier then
                    return aura
                end
            end
        end
    end
    return nil
end

-- @param auraName 光环名称或光环ID
-- @return 玩家光环信息
function Skippy.GetPlayerAurasByTable(auraTable)
    local playerindex

    if Skippy.state.inRaid then
        playerindex = Skippy.Units.player.aura
    elseif Skippy.state.inParty then
        playerindex = Skippy.Group.player.aura
    else
        playerindex = Skippy.Units.player.aura
    end

    if not playerindex then return nil end
    local auraSet = makeAuraSet(auraTable)

    for _, aura in pairs(playerindex) do
        if aura.sourceUnit == "player" and auraSet[aura.name] then
            return true
        end
    end
    return false
end

-- @return 玩家信息
function Skippy.GetPlayerInfo()
    local playerindex
    if Skippy.state.inParty then
        playerindex = Skippy.Group.player
    elseif Skippy.state.inRaid then
        playerindex = Skippy.Units.player
    else
        playerindex = Skippy.Units.player
    end
    if not playerindex then return nil end
    return playerindex
end

function Skippy.GetTargetAuras(spellIdentifier)
    local target = Skippy.Units.target
    if not target or not target.exists then return nil end
    if target.aura then
        for _, aura in pairs(target.aura) do
            if type(spellIdentifier) == "string" and aura.name == spellIdentifier then
                return aura
            end
            if type(spellIdentifier) == "number" and aura.spellId == spellIdentifier then
                return aura
            end
        end
    end
    return nil
end

function Skippy.GetTargetAurasByPlayer(spellIdentifier)
    local target = Skippy.Units.target
    if not target or not target.exists then return nil end
    if target.aura then
        for _, aura in pairs(target.aura) do
            if aura.sourceUnit == "player" then
                if type(spellIdentifier) == "string" and aura.name == spellIdentifier then
                    return aura
                end
                if type(spellIdentifier) == "number" and aura.spellId == spellIdentifier then
                    return aura
                end
            end
        end
    end
    return nil
end

--return Group所有存活成员的平均血量百分比
function Skippy.GetAverageHealthPct()
    local totalHealth = 0
    local totalMaxHealth = 0
    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) then
            totalHealth = totalHealth + data.health
            totalMaxHealth = totalMaxHealth + data.maxHealth
        end
    end
    return totalHealth / totalMaxHealth * 100
end

-- @return 生命值最低的单位, 生命值百分比
function Skippy.GetLowestUnit()
    local lowestUnit = nil
    local lowestHealth = 100
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) then
            if percentHealth < lowestHealth then
                lowestHealth = percentHealth
                lowestUnit = unit
            end
        end
    end
    return lowestUnit, lowestHealth
end

-- @return 除玩家外生命值最低的单位, 生命值百分比
function Skippy.GetLowestUnitWithoutPlayer()
    local lowestUnit = nil
    local lowestHealth = 100
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) and unit ~= "player" then
            if percentHealth < lowestHealth then
                lowestHealth = percentHealth
                lowestUnit = unit
            end
        end
    end
    return lowestUnit, lowestHealth
end

-- @param unit 单位名称，如：party1、raid2...
-- @return 除指定单位外生命值最低的单位, 生命值百分比
function Skippy.GetLowestUnitWithoutUnit(unitName)
    unitName = unitName or "player"
    local lowestUnit = nil
    local lowestHealth = 100
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) and unit ~= unitName then
            if percentHealth < lowestHealth then
                lowestHealth = percentHealth
                lowestUnit = unit
            end
        end
    end
    return lowestUnit, lowestHealth
end

-- 假设函数名修改为更贴切的名称，反映其查找 'Count' 个光环的单位
-- @param auraTable 光环名称列表,如：{ "回春术", "回春术（萌芽）" }
-- @param Count 指定光环数量,默认0
-- @return 有指定光环生命值最低的单位, 生命值百分比
function Skippy.GetLowestUnitWithExactAuraCount(auraTable, Count)
    Count = Count or 0
    local lowestUnit = nil
    local lowestHealth = 100
    local auraSet = makeAuraSet(auraTable)
    for unit, data in pairs(Skippy.Group) do
        local auraCount = 0
        if existsUnit(data) then
            local percentHealth = data.realPercentHealth
            for _, aura in pairs(data.aura) do
                if aura.sourceUnit == "player" and auraSet[aura.name] then
                    auraCount = auraCount + 1
                end
            end

            if auraCount == Count and percentHealth < lowestHealth then
                lowestHealth = percentHealth
                lowestUnit = unit
            end
        end
    end
    return lowestUnit, lowestHealth
end

-- @param role1 职责，如 "TANK", "HEALER", "DAMAGER"
-- @param role2 职责，如 "TANK", "HEALER", "DAMAGER"
-- @param role3 职责，如 "TANK", "HEALER", "DAMAGER"
-- @return 指定职责中生命值最低的单位, 生命值百分比
function Skippy.GetLowestUnitWithRoles(role1, role2, role3)
    local lowestUnit = nil
    local lowestHealth = 100
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        local role = data.role
        if existsUnit(data) then
            if (role1 and role == role1) or (role2 and role == role2) or (role3 and role == role3) then
                if percentHealth < lowestHealth then
                    lowestHealth = percentHealth
                    lowestUnit = unit
                end
            end
        end
    end
    return lowestUnit, lowestHealth
end

-- @param auraName 光环名称，如："恢复"、"暗言术：痛"
-- @return 有指定光环生命值最低的单位, 生命值百分比
function Skippy.GetLowestUnitWithAura(auraName)
    local lowestUnit = nil
    local lowestHealth = 100
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) then
            for _, aura in pairs(data.aura) do
                if aura.name == auraName then
                    if percentHealth < lowestHealth then
                        lowestHealth = percentHealth
                        lowestUnit = unit
                    end
                end
            end
        end
    end
    return lowestUnit, lowestHealth
end

-- @param auraName 光环名称，如："恢复"、"暗言术：痛"
-- @return 没有指定光环生命值最低的单位, 生命值百分比
function Skippy.GetLowestUnitWithoutAura(auraName)
    local lowestUnit = nil
    local lowestHealth = 100
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) then
            local hasAura = false
            for _, aura in pairs(data.aura) do
                if aura.name == auraName then
                    hasAura = true
                    break
                end
            end
            if not hasAura then
                if percentHealth < lowestHealth then
                    lowestHealth = percentHealth
                    lowestUnit = unit
                end
            end
        end
    end
    return lowestUnit, lowestHealth
end

-- @param auraName 光环名称，如："恢复"
-- @return 有来自于玩家光环生命值最低的单位, 生命值百分比
function Skippy.GetLowestUnitWithPlayerAura(auraName)
    local lowestUnit = nil
    local lowestHealth = 100
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) then
            for _, aura in pairs(data.aura) do
                if aura.sourceUnit == "player" and aura.name == auraName then
                    if percentHealth < lowestHealth then
                        lowestHealth = percentHealth
                        lowestUnit = unit
                    end
                end
            end
        end
    end
    return lowestUnit, lowestHealth
end

-- @param auraName
-- @return 没有来自于玩家光环生命值最低的单位, 生命值百分比
function Skippy.GetLowestUnitWithoutPlayerAuras(auraName)
    local lowestUnit = nil
    local lowestHealth = 100
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) then
            local hasPlayerAura = false
            for _, aura in pairs(data.aura) do
                if aura.name == auraName and aura.sourceUnit == "player" then
                    hasPlayerAura = true
                    break
                end
            end
            if not hasPlayerAura then
                if percentHealth < lowestHealth then
                    lowestHealth = percentHealth
                    lowestUnit = unit
                end
            end
        end
    end
    return lowestUnit, lowestHealth
end

function Skippy.GetLowestUnitWithAuraAndWithoutPlayerAuras(auraName, PlayerAuraName)
    local lowestUnit = nil
    local lowestHealth = 100
    for unit, data in pairs(Skippy.Group) do
        -- 1. 检查单位是否存活且可用 (Exists and Available)
        if existsUnit(data) then
            local percentHealth = data.percentHealth
            local hasPlayerAura = false
            local hasAura = false
            -- 2. 检查光环 (Aura Check)
            for _, aura in pairs(data.aura) do
                if not hasPlayerAura and aura.name == PlayerAuraName and aura.sourceUnit == "player" then
                    hasPlayerAura = true
                    if hasAura then
                        break
                    end
                end

                if not hasAura and aura.name == auraName then
                    hasAura = true
                    if hasPlayerAura then
                        break
                    end
                end
            end

            -- 3. 主逻辑检查 (Main Logic Check)
            if not hasPlayerAura and hasAura then
                if percentHealth < lowestHealth then
                    lowestHealth = percentHealth
                    lowestUnit = unit
                end
            end
        end
    end

    return lowestUnit, lowestHealth
end

function Skippy.GetLowestUnitWithAuraTableAndWithoutPlayerAuras(auraTable, PlayerAuraName)
    local lowestUnit = nil
    local lowestHealth = 101
    local auraSet = makeAuraSet(auraTable)
    for unit, data in pairs(Skippy.Group) do
        -- 1. 检查单位是否存活且可用 (Exists and Available)
        if existsUnit(data) then
            local percentHealth = data.percentHealth
            local hasPlayerAura = false
            local hasAura = false
            -- 2. 检查光环 (Aura Check)
            for _, aura in pairs(data.aura) do
                if not hasPlayerAura and aura.name == PlayerAuraName and aura.sourceUnit == "player" then
                    hasPlayerAura = true
                    if hasAura then
                        break
                    end
                end
                if not hasAura and auraSet[aura.name] then
                    hasAura = true
                    if hasPlayerAura then
                        break
                    end
                end
            end

            -- 3. 主逻辑检查 (Main Logic Check)
            if not hasPlayerAura and hasAura then
                if percentHealth < lowestHealth then
                    lowestHealth = percentHealth
                    lowestUnit = unit
                end
            end
        end
    end

    return lowestUnit, lowestHealth
end

-- @param auraName 单一光环名称,
-- @param role 职责，如 "TANK", "HEALER", "DAMAGER"
-- @return 有来自于玩家光环生命值最低的单位, 生命值百分比
function Skippy.GetLowestUnitWithPlayerAuraAndRole(auraName, role)
    local lowestUnit = nil
    local lowestHealth = 100
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) and (role and data.role == role) then
            for _, aura in pairs(data.aura) do
                if aura.name == auraName and aura.sourceUnit == "player" then
                    if percentHealth < lowestHealth then
                        lowestHealth = percentHealth
                        lowestUnit = unit
                    end
                end
            end
        end
    end
    return lowestUnit, lowestHealth
end

-- @param auraName
-- @param role 角色类型，如 "TANK", "HEALER", "DAMAGER"
-- @return 没有来自于玩家光环生命值最低的单位, 生命值百分比
function Skippy.GetLowestUnitWithoutPlayerAurasAndRole(auraName, role)
    local lowestUnit = nil
    local lowestHealth = 100
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) and data.role == role then
            local hasPlayerAura = false
            for _, aura in pairs(data.aura) do
                if aura.name == auraName and aura.sourceUnit == "player" then
                    hasPlayerAura = true
                    break
                end
            end
            if not hasPlayerAura then
                if percentHealth < lowestHealth then
                    lowestHealth = percentHealth
                    lowestUnit = unit
                end
            end
        end
    end
    return lowestUnit, lowestHealth
end

-- @param auraName
-- @param role 角色类型，如 "TANK", "HEALER", "DAMAGER"
-- @return 没有光环的单位
function Skippy.GetUnitWithAura(auraName)
    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) then
            for _, aura in pairs(data.aura) do
                if aura.name == auraName then
                    return unit, data.percentHealth
                end
            end
        end
    end
    return nil, nil
end

-- @param auraName
-- @return 没有指定光环的单位, 生命值百分比
function Skippy.GetUnitWithoutAura(auraName)
    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) then
            local hasAura = false
            for _, aura in pairs(data.aura) do
                if aura.name == auraName then
                    hasAura = true
                    break
                end
            end
            if not hasAura then
                return unit, data.percentHealth
            end
        end
    end
    return nil, nil
end

-- @param auraName
-- @param role 角色类型，如 "TANK", "HEALER", "DAMAGER"
-- @return 没有光环的单位
function Skippy.GetUnitWithAuraAndRole(auraName, role)
    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) and data.role == role then
            for _, aura in pairs(data.aura) do
                if aura.name == auraName then
                    return unit, data.percentHealth
                end
            end
        end
    end
    return nil, nil
end

-- @param auraName
-- @param role 角色类型，如 "TANK", "HEALER", "DAMAGER"
-- @return 没有指定光环的单位, 生命值百分比
function Skippy.GetUnitWithoutAuraAndRole(auraName, role)
    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) and data.role == role then
            local hasAura = false
            for _, aura in pairs(data.aura) do
                if aura.name == auraName then
                    hasAura = true
                    break
                end
            end
            if not hasAura then
                return unit, data.percentHealth
            end
        end
    end
    return nil, 100
end

-- @param auraName
-- @return 有来自于玩家光环的单位
function Skippy.GetUnitWithPlayerAura(auraName)
    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) then
            for _, aura in pairs(data.aura) do
                if aura.name == auraName and aura.sourceUnit == "player" then
                    return unit, data.percentHealth
                end
            end
        end
    end
    return nil, nil
end

-- @param auraName
-- @return 没有来自于玩家光环的单位
function Skippy.GetUnitWithoutPlayerAura(auraName)
    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) then
            local hasPlayerAura = false
            for _, aura in pairs(data.aura) do
                if aura.name == auraName and aura.sourceUnit == "player" then
                    hasPlayerAura = true
                    break
                end
            end
            if not hasPlayerAura then
                return unit, data.percentHealth
            end
        end
    end
    return nil, nil
end

-- @param auraName
-- @param role 角色类型，如 "TANK", "HEALER", "DAMAGER"
-- @return 没有来自于玩家光环的单位
function Skippy.GetUnitWithPlayerAurasAndRole(auraName, role)
    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) and data.role == role then
            for _, aura in pairs(data.aura) do
                if aura.name == auraName and aura.sourceUnit == "player" then
                    return unit, data.percentHealth
                end
            end
        end
    end
    return nil, nil
end

-- @param auraName
-- @return 有来自于玩家光环的单位, 光环信息
function Skippy.GetUnitAndAuraWithPlayerAura(spellIdentifier)
    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) then
            for _, aura in pairs(data.aura) do
                if aura.sourceUnit == "player" then
                    if type(spellIdentifier) == "string" and aura.name == spellIdentifier then
                        return unit, aura
                    end
                    if type(spellIdentifier) == "number" and aura.spellId == spellIdentifier then
                        return unit, aura
                    end
                end
            end
        end
    end
    return nil, nil
end

-- @param auraName
-- @param role 角色类型，如 "TANK", "HEALER", "DAMAGER"
-- @return 没有来自于玩家光环的单位
function Skippy.GetUnitWithoutPlayerAurasAndRole(auraName, role)
    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) and data.role == role then
            local hasPlayerAura = false
            for _, aura in pairs(data.aura) do
                if aura.name == auraName and aura.sourceUnit == "player" then
                    hasPlayerAura = true
                    break
                end
            end
            if not hasPlayerAura then
                return unit, data.percentHealth
            end
        end
    end
    return nil, 100
end

-- @param auraTable   table   光环名称列表，如 { "恢复", "真言术：韧", "牺牲之手" }
-- @return unit       string  单位ID（如 "party1"）
-- @return health     number  生命值百分比（0~100）
function Skippy.GetLowestUnitWithAnyAuras(auraTable)
    local auraSet = makeAuraSet(auraTable)
    local lowestUnit = nil
    local lowestHealth = 100

    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) then
            local percentHealth = data.percentHealth
            local hasRequiredAura = false
            for _, aura in pairs(data.aura) do
                if auraSet[aura.name] then
                    hasRequiredAura = true
                    break
                end
            end

            if hasRequiredAura and percentHealth < lowestHealth then
                lowestHealth = percentHealth
                lowestUnit = unit
            end
        end
    end

    return lowestUnit, lowestHealth
end

-- @param auraTable   table   光环名称列表，如 { "恢复", "真言术：韧", "牺牲之手" }
-- @return unit       string  单位ID（如 "party1"）
-- @return health     number  生命值百分比（0~100）
function Skippy.GetLowestUnitWithAnyPlayerAuras(auraTable)
    local auraSet = makeAuraSet(auraTable)
    local lowestUnit = nil
    local lowestHealth = 100

    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) then
            local hasRequiredAura = false
            for _, aura in pairs(data.aura) do
                if aura.sourceUnit == "player" and auraSet[aura.name] then
                    hasRequiredAura = true
                    break
                end
            end

            if hasRequiredAura and data.percentHealth < lowestHealth then
                lowestHealth = data.percentHealth
                lowestUnit = unit
            end
        end
    end

    return lowestUnit, lowestHealth
end

-- @param healthThreshold 生命值百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @return 符合条件的单位数量
function Skippy.GetCount(healthThreshold)
    healthThreshold = healthThreshold or 100
    local count = 0
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) and percentHealth < healthThreshold then
            count = count + 1
        end
    end
    return count
end

-- @param healthThreshold 生命值百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @param auraName 单一光环名称
-- @return 符合条件的单位数量
function Skippy.GetCountWithPlayerAura(healthThreshold, auraName)
    healthThreshold = healthThreshold or 100
    local count = 0
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) then
            for _, aura in pairs(data.aura) do
                if aura.name == auraName and aura.sourceUnit == "player" and percentHealth < healthThreshold then
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- @param healthThreshold 生命值百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @param auraName 单一光环名称
-- @param role 角色类型，如 "TANK", "HEALER", "DAMAGER"
-- @return 符合条件的单位数量
function Skippy.GetCountWithPlayerAuraAndRole(healthThreshold, auraName, role)
    healthThreshold = healthThreshold or 100
    local count = 0
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) and data.role == role then
            for _, aura in pairs(data.aura) do
                if aura.name == auraName and aura.sourceUnit == "player" and percentHealth < healthThreshold then
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- @param healthThreshold 生命值百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @param auraName 单一光环名称
-- @return 符合条件的单位数量
function Skippy.GetCountWithoutPlayerAura(healthThreshold, auraName)
    healthThreshold = healthThreshold or 100
    local count = 0
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) then
            local hasPlayerAura = false
            for _, aura in pairs(data.aura) do
                if aura.name == auraName and aura.sourceUnit == "player" then
                    hasPlayerAura = true
                    break
                end
            end
            if not hasPlayerAura then
                if percentHealth < healthThreshold then
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- @param healthThreshold 生命值百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @param auraTable 光环名称列表，如 { "恢复", "真言术：韧", "牺牲之手" }
-- @return 符合条件的单位数量
function Skippy.GetCountWithAnyAuras(healthThreshold, auraTable)
    healthThreshold = healthThreshold or 100
    local auraSet = makeAuraSet(auraTable)
    local count = 0

    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) and data.percentHealth < healthThreshold then
            local hasRequiredAura = false
            for _, aura in pairs(data.aura) do
                if auraSet[aura.name] then
                    hasRequiredAura = true
                    break
                end
            end
            if hasRequiredAura then
                count = count + 1
            end
        end
    end
    return count
end

-- @param healthThreshold 生命值百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @param subgroup 小队编号，如1、2、3、4，默认玩家所在小队
-- @return 只计算玩家所在小队符合条件的单位数量
function Skippy.GetCountInSubGroup(healthThreshold, subgroup)
    healthThreshold = healthThreshold or 100
    local count = 0
    local sub = subgroup or Skippy.Units.player.subgroup
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) and data.subgroup == sub then
            if percentHealth < healthThreshold then
                count = count + 1
            end
        end
    end
    return count
end

-- 特殊函数,适用于团本欧米茄5号boss
-- @param auraName
-- @param auraName2
-- @return Units 找到有2个debuff的单位,并返回单位和debuff层数
function Skippy.GetUnitWithAuraAndAuraCount(auraName, auraName2)
    local units = {}

    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) then
            local hasAura1 = false
            local hasAura2 = false
            local count = 0

            for _, aura in pairs(data.aura) do
                if aura.name == auraName then
                    hasAura1 = true
                elseif aura.name == auraName2 then
                    hasAura2 = true
                    count = aura.applications or 0
                end
            end

            if hasAura1 and hasAura2 then
                table.insert(units, {
                    unit = unit,
                    count = count, -- auraName 的层数
                })
            end
        end
    end

    return units
end

function Skippy.FindRejuvenation()
    local noRejuUnit, noRejuHealth = nil, 100
    local oneRejuUnit, oneRejuHealth = nil, 100

    for unit, data in pairs(Skippy.Group) do
        local health = data.realPercentHealth
        if existsUnit(data) then
            local hasReju = false
            local hasGerm = false
            for _, aura in pairs(data.aura) do
                if aura.sourceUnit == "player" then
                    if aura.spellId == 774 then
                        hasReju = true
                    elseif aura.spellId == 155777 then
                        hasGerm = true
                    end
                end
            end
            if not hasReju and not hasGerm and health < noRejuHealth then
                noRejuHealth = health
                noRejuUnit = unit
            end

            if hasReju ~= hasGerm and health < oneRejuHealth then
                oneRejuHealth = health
                oneRejuUnit = unit
            end
        end
    end
    return noRejuUnit, noRejuHealth, oneRejuUnit, oneRejuHealth
end

-- @param dispelName "Curse", "Disease", "Magic", "Poison", and "". "" 是激怒效果.
-- @return 有指定驱散的单位
function Skippy.GetUnitHasDebuffWithdispelName(dispelName)
    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) then
            for _, aura in pairs(data.aura) do
                if aura.isHarmful and aura.dispelName == dispelName then
                    return unit
                end
            end
        end
    end
    return nil
end

-- @param dispelName "Curse", "Disease", "Magic", "Poison", and "". "" 是激怒效果.
-- @param blacklistTable, 不驱散黑名单里的debuff
-- @return 有指定驱散的单位
function Skippy.GetUnitHasDebuffWithdispelNameAndWithoutTable(dispelName, blacklistTable)
    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) then
            for _, aura in pairs(data.aura) do
                local inBlacklist = false
                for k, v in pairs(blacklistTable) do
                    if type(k) == "string" and aura.name == k then
                        inBlacklist = true
                        break
                    end
                    if type(k) == "number" and aura.spellId == k then
                        inBlacklist = true
                        break
                    end
                end
                if not inBlacklist and aura.isHarmful and aura.dispelName == dispelName then
                    return unit
                end
            end
        end
    end
    return nil
end
