if not Skippy then Skippy = {} end
local spellkey = {
    ["target"] = 0,
    ["spell"] = 0,
    ["Skip"] = 0,
    ["None"] = 255,

    -- 单位
    ["player"] = 46,
    ["party1"] = 1,
    ["party2"] = 2,
    ["party3"] = 3,
    ["party4"] = 4,
    ["raid1"] = 1,
    ["raid2"] = 2,
    ["raid3"] = 3,
    ["raid4"] = 4,
    ["raid5"] = 5,
    ["raid6"] = 6,
    ["raid7"] = 7,
    ["raid8"] = 8,
    ["raid9"] = 9,
    ["raid10"] = 10,
    ["raid11"] = 11,
    ["raid12"] = 12,
    ["raid13"] = 13,
    ["raid14"] = 14,
    ["raid15"] = 15,
    ["raid16"] = 16,
    ["raid17"] = 17,
    ["raid18"] = 18,
    ["raid19"] = 19,
    ["raid20"] = 20,
    ["raid21"] = 21,
    ["raid22"] = 22,
    ["raid23"] = 23,
    ["raid24"] = 24,
    ["raid25"] = 25,
    ["raid26"] = 26,
    ["raid27"] = 27,
    ["raid28"] = 28,
    ["raid29"] = 29,
    ["raid30"] = 30,
    ["raid31"] = 31,
    ["raid32"] = 32,
    ["raid33"] = 33,
    ["raid34"] = 34,
    ["raid35"] = 35,
    ["raid36"] = 36,
    ["raid37"] = 37,
    ["raid38"] = 38,
    ["raid39"] = 39,
    ["raid40"] = 40,
    ["boss1"] = 41,
    ["boss2"] = 42,
    ["boss3"] = 43,
    ["boss4"] = 44,
    ["boss5"] = 45,

    -- 常用宏
    ["一键辅助"] = 47,
    ["饰品"] = 48,
    ["大红"] = 49,
    ["治疗石"] = 50,
    ["上个敌人"] = 51,
    ["停止施法"] = 52,
    ["种族技能"] = 53,

    --驱散技能
    ["纯净术"] = 54,
    ["净化灵魂"] = 54,
    ["自然之愈"] = 54,
    ["清洁术"] = 54,

    -- 牧师
    ["神圣之星"] = 55,
    ["治疗之环"] = 56,
    ["恢复"] = 57,
    ["强效治疗术"] = 58,
    ["联结治疗"] = 59,
    ["快速治疗"] = 60,
    ["愈合祷言"] = 61,
    ["治疗术"] = 62,
    ["绝望祷言"] = 63,
    ["苦修"] = 64,
    ["天使长"] = 65,
    ["治疗祷言"] = 66,
    ["真言术：盾"] = 67,
    ["神圣之火"] = 68,
    ["惩击"] = 69,
    ["暗影魔"] = 70,
    ["苦修target"] = 71,
    ["心灵专注"] = 72,
    ["圣言术：静"] = 73,
    ["圣言术：佑"] = 73,
    ["圣言术：罚"] = 73,
    ["渐隐术"] = 74,
    ["神圣新星"] = 75,
    ["预兆"] = 76,
    ["神圣化身"] = 77,
    ["光晕"] = 78,
    ["圣言术：灵"] = 79,

    -- 圣骑士
    ["神圣恳求"] = 55,
    ["荣耀圣令"] = 56,
    ["神圣棱镜"] = 57,
    ["神圣震击"] = 58,
    ["审判"] = 59,
    ["圣光闪现"] = 60,
    ["神圣之光"] = 61,
    ["圣光术"] = 62,
    ["圣光普照"] = 63,
    ["十字军打击"] = 64,
    ["洞察圣印"] = 65,

    -- 萨满祭司

    ["治疗之泉图腾"] = 55,
    ["暴雨图腾"] = 55,
    ["激流"] = 56,
    ["治疗链"] = 57,
    ["治疗之涌"] = 58,
    ["强效治疗波"] = 59,
    ["治疗波"] = 60,
    ["水之护盾"] = 61,
    ["大地生命武器"] = 62,
    ["元素释放"] = 63,
    ["先祖迅捷"] = 64,
    ["收回图腾"] = 65,
    ["大地之盾"] = 66,

    -- 德鲁伊
    ["生命绽放"] = 66,
    ["愈合"] = 56,
    ["滋养"] = 57,
    ["迅捷治愈"] = 58,
    ["回春术"] = 59,
    ["治疗之触"] = 60,
    ["自然迅捷"] = 61,
    ["野性成长"] = 62,

    -- 武僧
    ["复苏之雾"] = 55,
    ["升腾之雾"] = 56,
    ["抚慰之雾"] = 57,
    ["真气波"] = 58,
    ["真气爆裂"] = 59,
    ["贯日击"] = 60,
    ["幻灭踢"] = 61,
    ["猛虎掌"] = 62,
    ["移花接木"] = 63,
    ["氤氲之雾"] = 64,
    ["真气酒"] = 65,
    ["神鹤引项踢"] = 66,
    ["振魂引"] = 67,
    ["雷光聚神茶"] = 68,
    ["法力茶"] = 69,
    ["禅意珠"] = 70,
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
        output = output .. "单位不存在"
    end

    if not spellkey[spell] then
        output = output .. "技能: 不存在"
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
            Skippy.castTime = spellInfo.castTime
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
            Skippy.castTime = spellInfo.castTime
        else
            Skippy.iconID = 133036
        end
    end

    output = output ..
        "焦点: " .. unit .. "(" .. spellkey[unit] .. ")" .. " \n技能: " .. spell .. "(" .. spellkey[spell] .. ")"
    Skippy.txt = output
    return true
end

function Skippy.PressKey(spellIdentifier)
    local output = ""

    if not Wa1Key or not Wa1Key.Prop then
        output = output .. "Wa1Key不存在"
        Skippy.txt = output
        return true
    end

    if spellIdentifier == "None" or not spellIdentifier then
        Wa1Key.Prop.press = 255
        Skippy.txt = "无计可施"
        Skippy.iconID = 133036
        return true
    end

    local spellInfo = C_Spell.GetSpellInfo(spellIdentifier)

    if not spellInfo then
        Skippy.txt = "技能: " .. spellIdentifier .. "不存在"
        Skippy.iconID = 133036
        return true
    end

    for key, data in pairs(Skippy.spellkey) do
        if type(spellIdentifier) == "number" and key == spellIdentifier then
            Wa1Key.Prop.press = data.keycode
            Skippy.iconID = data.icon
            Skippy.txt = "技能: " .. data.name .. "\n按键: " .. data.key .. "\nCode: " .. data.keycode
            return true
        end
        if type(spellIdentifier) == "string" and data.name == spellIdentifier then
            Wa1Key.Prop.press = data.keycode
            Skippy.iconID = data.icon
            Skippy.txt = "技能: " .. data.name .. "\n按键: " .. data.key .. "\nCode: " .. data.keycode
            return true
        end
    end

    return true
end

local function existsUnit(data)
    return data.inRange and data.canAssist and data.inSight and not data.isDead
end

local function makeAuraSet(auraTable)
    local set = {}
    local count = 0
    for _, name in ipairs(auraTable or {}) do
        set[name] = true
        count = count + 1
    end
    return set, count
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

-- @param range 范围
-- @return 指定范围内敌人数量（未筛选，图腾也包含在内）
function Skippy.GetEnemyCount(range)
    local count = 0
    for unit, data in pairs(Skippy.Nameplate) do
        if data.maxRange and data.maxRange <= range then
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
    for unit, data in pairs(Skippy.Nameplate) do
        if data.maxRange and data.maxRange <= range then
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
    for unit, data in pairs(Skippy.Nameplate) do
        if data.maxRange and data.maxRange <= range then
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
-- @return 玩家光环信息
function Skippy.GetPlayerAuras(spellIdentifier)
    local playerindex

    if Skippy.state.inRaid then
        playerindex = Skippy.Units.player.aura
    elseif Skippy.state.inParty then
        playerindex = Skippy.Group.player.aura
    else
        playerindex = Skippy.Units.player.aura
    end

    if not playerindex then return nil end

    for _, aura in pairs(playerindex) do
        if aura.sourceUnit == "player" then
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

-- @param auraTable 光环名称列表,如：{ "回春术", "回春术（萌芽）" }
-- @param Count 指定光环数量,默认0
-- @return 有指定光环生命值最低的单位, 生命值百分比
function Skippy.GetLowestUnitWithDifferentAuraCount(auraTable, Count)
    Count = Count or 0
    local auraCount = 0
    local lowestUnit = nil
    local lowestHealth = 100
    local auraSet, SetCount = makeAuraSet(auraTable)
    for unit, data in pairs(Skippy.Group) do
        local percentHealth = data.percentHealth
        if existsUnit(data) then
            for _, aura in pairs(data.aura) do
                if auraSet[aura.name] and aura.sourceUnit == "player" then
                    auraCount = auraCount + 1
                    if auraCount >= SetCount then
                        break
                    end
                end
            end
            if auraCount == Count and percentHealth < lowestHealth then
                lowestHealth = percentHealth
                lowestUnit = unit
                break
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
