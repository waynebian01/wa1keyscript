if not Skippy then Skippy = {} end
local spellkey = {
    ["target"] = 0,
    ["spell"] = 0,
    ["Skip"] = 0,
    ["None"] = 255,
    ["player"] = 1,
    ["party1"] = 2,
    ["party2"] = 3,
    ["party3"] = 4,
    ["party4"] = 5,
    ["raid1"] = 2,
    ["raid2"] = 3,
    ["raid3"] = 4,
    ["raid4"] = 5,
    ["raid5"] = 6,
    ["raid6"] = 7,
    ["raid7"] = 8,
    ["raid8"] = 9,
    ["raid9"] = 10,
    ["raid10"] = 11,
    ["raid11"] = 12,
    ["raid12"] = 13,
    ["raid13"] = 14,
    ["raid14"] = 15,
    ["raid15"] = 16,
    ["raid16"] = 17,
    ["raid17"] = 18,
    ["raid18"] = 19,
    ["raid19"] = 20,
    ["raid20"] = 21,
    ["raid21"] = 22,
    ["raid22"] = 23,
    ["raid23"] = 24,
    ["raid24"] = 25,
    ["raid25"] = 26,
    ["raid26"] = 27,
    ["raid27"] = 28,
    ["raid28"] = 29,
    ["raid29"] = 30,
    ["raid30"] = 31,
    ["boss1"] = 32,
    ["boss2"] = 33,
    ["placeholder1"] = 34,
    ["boss3"] = 35,
    ["boss4"] = 36,
    ["boss5"] = 37,

    -- 常用宏
    ["stopcasting"] = 38,
    ["lastenemy"] = 39,
    ["trinket"] = 40,
    ["red"] = 41,
    ["驱散"] = 42,

    -- 神圣牧师
    ["圣言术：静"] = 43,
    ["圣言术：佑"] = 43,
    ["圣言术：罚"] = 43,
    ["神圣之星"] = 44,
    ["治疗之环"] = 45,
    ["placeholder2"] = 46,
    ["恢复"] = 47,
    ["强效治疗术"] = 48,
    ["联结治疗"] = 49,
    ["快速治疗"] = 50,
    ["愈合祷言"] = 51,
    ["治疗术"] = 52,

    -- 圣骑士
    ["洞察圣印"] = 43,
    ["神圣恳求"] = 44,
    ["荣耀圣令"] = 45,
    ["神圣棱镜"] = 47,
    ["神圣震击"] = 48,
    ["审判"] = 49,
    ["圣光术"] = 52,
    ["圣光闪现"] = 50,
    ["神圣之光"] = 51,
    ["圣光普照"] = 53,
    ["十字军打击"] = 54,

    -- 萨满祭司
    ["大地之盾"] = 43,
    ["治疗之泉图腾"] = 44,
    ["激流"] = 45,
    ["治疗链"] = 47,
    ["治疗之涌"] = 48,
    ["强效治疗波"] = 49,
    ["治疗波"] = 50,
    ["水之护盾"] = 51,
    ["大地生命武器"] = 52,
    ["元素释放"] = 53,

    -- 德鲁伊
    ["野性成长"] = 43,
    ["生命绽放"] = 44,
    ["愈合"] = 45,
    ["滋养"] = 47,
    ["迅捷治愈"] = 48,
    ["回春术"] = 49,
    ["治疗之触"] = 50,
    ["自然迅捷"] = 51,
    -- 武僧
    ["禅意珠"] = 43,
    ["复苏之雾"] = 44,
    ["升腾之雾"] = 45,

    ["抚慰之雾"] = 47,
    ["真气波"] = 48,
    ["真气爆裂"] = 49,
    ["贯日击"] = 50,
    ["幻灭踢"] = 51,
    ["猛虎掌"] = 52,
    ["移花接木"] = 53,
    ["氤氲之雾"] = 54,
    ["真气酒"] = 55,
    ["神鹤引项踢"] = 56,
    ["振魂引"] = 57,
    ["法力茶"] = 58,
    ["雷光聚神茶"] = 59,
}

function Skippy.UnitHeal(unit, spell)
    local output = ""
    local spellInfo = C_Spell.GetSpellInfo(spell)
    if not Wa1Key or not Wa1Key.Prop then
        output = output .. "Wa1Key不存在"
        Skippy.txt = output
        return true
    end
    if unit == nil then
        output = output .. "单位: 错误"
        Skippy.txt = output
        return true
    end
    if not spellkey[unit] then
        output = output .. "单位: " .. unit .. "不存在"
    end

    if not spellkey[spell] then
        output = output .. "技能: " .. spell .. "不存在"
    end

    if not spellkey[spell] or not spellkey[unit] then
        Wa1Key.Prop.heal = 255
        Skippy.txt = output
        return true
    end

    if unit == "None" then
        Skippy.txt = "休息..."
        Skippy.iconID = 133036
        Wa1Key.Prop.heal = 255
        return true
    elseif unit == "Skip" then
        Skippy.txt = "跳过治疗..."
        Skippy.iconID = 133036
        Wa1Key.Prop.heal = 0
        return true
    elseif unit == "spell" or unit == "target" then
        Wa1Key.Prop.heal = spellkey[spell]
        if spellInfo and spellInfo.iconID then
            Skippy.iconID = spellInfo.iconID
        else
            Skippy.iconID = 133036
        end
    else
        if UnitIsUnit(unit, "focus") then
            Wa1Key.Prop.heal = spellkey[spell]
        else
            Wa1Key.Prop.heal = spellkey[unit]
        end
        if spellInfo and spellInfo.iconID then
            Skippy.iconID = spellInfo.iconID
        else
            Skippy.iconID = 133036
        end
    end

    output = output ..
        "焦点: " .. unit .. "(" .. spellkey[unit] .. ")" .. " \n技能: " .. spell .. "(" .. spellkey[spell] .. ")"
    Skippy.txt = output
    return true
end

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

--@param range 范围
--@return 范围内敌人数量
function Skippy.GetEnemyCount(range)
    local count = 0
    for i = 1, 10 do
        local unit = "nameplate" .. i
        local minRange, maxRange = WeakAuras.GetRange(unit)
        if maxRange then
            if maxRange <= range then
                count = count + 1
            end
        end
    end
    return count
end

--@param auraName 光环名称
--@return 玩家光环信息
function Skippy.GetPlayerAuras(auraName)
    local playerindex

    if Skippy.state.inParty then
        playerindex = Skippy.Group.player.aura
    elseif Skippy.state.inRaid then
        playerindex = Skippy.Units.player.aura
    else
        playerindex = Skippy.Units.player.aura
    end

    if not playerindex then return nil end

    for _, aura in pairs(playerindex) do
        if aura.name == auraName and aura.sourceUnit == "player" then
            return aura
        end
    end

    return nil
end

--@return 玩家信息
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

-- @return 血量最低的单位, 血量百分比
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

-- @return 除玩家外血量最低的单位, 血量百分比
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

-- @param unit 单位名称
-- @return 除指定单位外血量最低的单位, 血量百分比
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

-- @param role1 职责，如 "TANK", "HEALER", "DAMAGER"
-- @param role2 职责，如 "TANK", "HEALER", "DAMAGER"
-- @param role3 职责，如 "TANK", "HEALER", "DAMAGER"
-- @return 指定职责中血量最低的单位, 血量百分比
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

-- @param auraName 单一光环名称
-- @return 有指定光环血量最低的单位, 血量百分比
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

-- @param auraName 单一光环名称,
-- @return 有来自于玩家光环血量最低的单位, 血量百分比
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

function Skippy.GetLowestUnitWithAuraAndWithoutPlayerAuras(auraName, PlayerAuraName)
    local lowestUnit = nil
    local lowestHealth = 101
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

-- @param auraName
-- @return 没有来自于玩家光环血量最低的单位, 血量百分比
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

-- @param auraName 单一光环名称,
-- @param role 职责，如 "TANK", "HEALER", "DAMAGER"
-- @return 有来自于玩家光环血量最低的单位, 血量百分比
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
-- @return 没有来自于玩家光环血量最低的单位, 血量百分比
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
-- @return 没有指定光环的单位, 血量百分比
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
-- @return 没有指定光环的单位, 血量百分比
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
function Skippy.GetUnitAndAuraWithPlayerAura(auraName)
    for unit, data in pairs(Skippy.Group) do
        if existsUnit(data) then
            for _, aura in pairs(data.aura) do
                if aura.name == auraName and aura.sourceUnit == "player" then
                    return unit, aura
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
-- @return health     number  血量百分比（0~100）
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
-- @return health     number  血量百分比（0~100）
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

-- @param healthThreshold 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
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

-- @param healthThreshold 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
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

-- @param healthThreshold 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
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

-- @param healthThreshold 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
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

-- @param healthThreshold 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
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
