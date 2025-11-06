local e = aura_env
e.initialization = false

function e.getFocus()
    local focus = nil
    local party = WK.PartyStatus
    if UnitExists("focus") then
        for i = 0, 4 do
            local unitId = (i == 0) and "player" or "party" .. i
            local unitData = party and party[unitId]
            if unitData and unitData.isValid and unitData.inSight and UnitIsUnit(unitId, "focus") then
                focus = unitId
            end
        end
    end
    return focus
end

-- @param thresholdHealthPct 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @param auraName 光环或减益名称
-- @param auraType 光环或减益类型: "HELPFUL" 或 "HARMFUL",默认 "HELPFUL"
-- @param hasAura 布尔值,如果有光环名称,检查是否有这个光环 (true: 有光环, false: 无光环)
-- @param role 角色类型: "TANK" 或 "HEALER" 或 "DAMAGER"
-- @return 符合条件的单位数量
function e.getCount(thresholdHealthPct, auraName, auraType, hasAura, role)
    local count = 0
    local healthThreshold = thresholdHealthPct or 100
    local auraOrDebuffType = auraType or "HELPFUL"
    local hasAuraOrNot = (hasAura == nil) and true or hasAura
    local party = WK.PartyStatus
    for i = 0, 4 do
        local unitId = (i == 0) and "player" or "party" .. i
        local unitData = party and party[unitId]
        if unitData and unitData.isValid and unitData.inSight and (role == nil or unitData.role == role) then
            if auraName then
                local status = (auraOrDebuffType == "HELPFUL") and unitData.buff or unitData.debuff
                if hasAuraOrNot then
                    if status[auraName] and unitData.healthPct < healthThreshold then
                        count = count + 1
                    end
                else
                    if not status[auraName] and unitData.healthPct < healthThreshold then
                        count = count + 1
                    end
                end
            else
                if unitData.healthPct < healthThreshold then
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- @param dispelName 类型:"Curse", "Disease", "Magic", "Poison"
-- @param thresholdHealthPct 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @param role 角色类型: "TANK" 或 "HEALER" 或 "DAMAGER"
-- @return 符合条件的单位数量
function e.getdispelNameCount(dispelName, thresholdHealthPct, role)
    local count = 0
    local healthThreshold = thresholdHealthPct or 100
    local party = WK.PartyStatus
    for i = 0, 4 do
        local unitId = (i == 0) and "player" or "party" .. i
        local unitData = party and party[unitId]
        if unitData and unitData.isValid and unitData.inSight and (role == nil or unitData.role == role) then
            if dispelName == "Curse" then
                if unitData.hasCurse and unitData.healthPct < healthThreshold then
                    count = count + 1
                end
            end
            if dispelName == "Disease" then
                if unitData.hasDisease and unitData.healthPct < healthThreshold then
                    count = count + 1
                end
            end
            if dispelName == "Magic" then
                if unitData.hasMagic and unitData.healthPct < healthThreshold then
                    count = count + 1
                end
            end
            if dispelName == "Poison" then
                if unitData.hasPoison and unitData.healthPct < healthThreshold then
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- @param thresholdHealthPct 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @param auraName 光环或减益名称,仅支持本地化名称
-- @param auraType 光环或减益类型: "HELPFUL" 或 "HARMFUL",默认 "HELPFUL"
-- @param hasAura 布尔值, 如果有光环名称,检查是否有这个光环 (true: 有光环, false: 无光环)
-- @return 血量最低且符合条件的单位名称, 如果没有找到则返回 nil
function e.getLowestUnit(thresholdHealthPct, auraName, auraType, hasAura, role)
    local lowestUnit = nil
    local healthThreshold = thresholdHealthPct or 100

    local auraOrDebuffType = auraType or "HELPFUL"
    local hasAuraOrNot = (hasAura == nil) and true or hasAura
    local party = WK.PartyStatus
    for i = 0, 4 do
        local unitId = (i == 0) and "player" or "party" .. i
        local unitData = party and party[unitId]
        if unitData and unitData.isValid and unitData.inSight and (role == nil or unitData.role == role) then
            local currentHealthPct = unitData.healthPct
            if auraName then
                local status = (auraOrDebuffType == "HELPFUL") and unitData.buff or unitData.debuff
                if hasAuraOrNot then
                    if status[auraName] and currentHealthPct < healthThreshold then
                        healthThreshold = currentHealthPct
                        lowestUnit = unitId
                    end
                else
                    if not status[auraName] and currentHealthPct < healthThreshold then
                        healthThreshold = currentHealthPct
                        lowestUnit = unitId
                    end
                end
            else
                if currentHealthPct < healthThreshold then
                    healthThreshold = currentHealthPct
                    lowestUnit = unitId
                end
            end
        end
    end
    return lowestUnit
end

-- @param auraName 光环或减益名称,仅支持本地化名称
-- @param auraType 光环或减益类型: "HELPFUL" 或 "HARMFUL",默认 "HELPFUL"
-- @param hasAura 布尔值, 如果有光环名称,检查是否有这个光环 (true: 有光环, false: 无光环)
-- @param role 角色类型: "TANK" 或 "HEALER" 或 "DAMAGER"
-- @return 最大生命值最低的单位
function e.maxHealth_lowestUnit(auraName, auraType, hasAura, role)
    local maxHealth = 9999999999
    local maxHealthUnit = nil
    local party = WK.PartyStatus
    for i = 0, 4 do
        local unitId = (i == 0) and "player" or "party" .. i
        local unitData = party and party[unitId]
        if unitData and unitData.isValid and unitData.inSight and (role == nil or unitData.role == role) then
            if auraName then
                local status = (auraType == "HELPFUL") and unitData.buff or unitData.debuff
                if hasAura then
                    if status[auraName] and unitData.maxHealth < maxHealth then
                        maxHealth = unitData.maxHealth
                        maxHealthUnit = unitId
                    end
                else
                    if not status[auraName] and unitData.maxHealth < maxHealth then
                        maxHealth = unitData.maxHealth
                        maxHealthUnit = unitId
                    end
                end
            else
                if unitData.maxHealth < maxHealth then
                    maxHealth = unitData.maxHealth
                    maxHealthUnit = unitId
                end
            end
        end
    end
    return maxHealthUnit
end

-- @return 队伍生命值平均血量
function e.averageHealth()
    local total_averageHealth = 100 -- 队伍生命值平均血量
    local total_health = 0          -- 队伍生命值总血量
    local total_maxhealth = 0       -- 队伍生命值总血量
    local party = WK.PartyStatus
    for i = 0, 4 do
        local unitId = (i == 0) and "player" or "party" .. i
        local unitData = party and party[unitId]
        if unitData and unitData.isValid and unitData.inSight then
            total_health = total_health + unitData.health
            total_maxhealth = total_maxhealth + unitData.maxHealth
        end
    end
    total_averageHealth = total_health / total_maxhealth * 100
    return total_averageHealth
end

-- @return 队伍伤害最高的单位
function e.DamageUnit()
    local damageUnit = nil
    local damage = 0
    local party = WK.PartyStatus
    for i = 0, 4 do
        local unitId = (i == 0) and "player" or "party" .. i
        local unitData = party and party[unitId]
        if unitData and unitData.isValid and unitData.inSight then
            if unitData.damage > damage then
                damage = unitData.damage
                damageUnit = unitId
            end
        end
    end
    return damageUnit
end

-- @param thresholdHealthPct 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @param RejuvenationCount 回春术数量,默认0
-- @return 队伍回春术最低的单位
function e.rejuvenation_lowestUnit(thresholdHealthPct, RejuvenationCount)
    local lowestUnit = nil
    local healthThreshold = thresholdHealthPct or 100
    local count = RejuvenationCount or 0
    local party = WK.PartyStatus
    for i = 0, 4 do
        local unitId = (i == 0) and "player" or "party" .. i
        local unitData = party and party[unitId]
        if unitData and unitData.isValid and unitData.inSight then
            local currentHealthPct = unitData.healthPct
            if count == 0 then
                if not unitData.buff["回春术"] and not unitData.buff["回春术（萌芽）"] then
                    if currentHealthPct < healthThreshold then
                        healthThreshold = currentHealthPct
                        lowestUnit = unitId
                    end
                end
            end
            if count == 1 then
                if unitData.buff["回春术"] ~= unitData.buff["回春术（萌芽）"] then
                    if currentHealthPct < healthThreshold then
                        healthThreshold = currentHealthPct
                        lowestUnit = unitId
                    end
                end
            end
            if count == 2 then
                if unitData.buff["回春术"] and unitData.buff["回春术（萌芽）"] then
                    if currentHealthPct < healthThreshold then
                        healthThreshold = currentHealthPct
                        lowestUnit = unitId
                    end
                end
            end
        end
    end
    return lowestUnit
end

-- @param thresholdHealthPct 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @return 队伍迅捷治愈最低的单位
function e.swiftmend_lowestUnit(thresholdHealthPct)
    local lowestUnit = nil
    local healthThreshold = thresholdHealthPct or 100
    local party = WK.PartyStatus
    for i = 0, 4 do
        local unitId = (i == 0) and "player" or "party" .. i
        local unitData = party and party[unitId]
        if unitData and unitData.isValid and unitData.inSight then
            local currentHealthPct = unitData.healthPct
            if unitData.buff["愈合"] or unitData.buff["野性成长"] or unitData.buff["回春术"] or unitData.buff["回春术（萌芽）"] then
                if currentHealthPct < healthThreshold then
                    healthThreshold = currentHealthPct
                    lowestUnit = unitId
                end
            end
        end
    end
    return lowestUnit
end

-- @param thresholdHealthPct 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @return 队伍没有晨光且生命值最低的单位
function e.noDawnlight_Unit(thresholdHealthPct)
    local lowestUnit = nil
    local healthThreshold = thresholdHealthPct or 100
    local party = WK.PartyStatus
    for i = 0, 4 do
        local unitId = (i == 0) and "player" or "party" .. i
        local unitData = party and party[unitId]
        if unitData and unitData.isValid and unitData.inSight then
            local currentHealthPct = unitData.healthPct
            if not (unitData.buff["晨光"] and unitData.buff["晨光"].spellId == 431381) then
                if currentHealthPct < healthThreshold then
                    healthThreshold = currentHealthPct
                    lowestUnit = unitId
                end
            end
        end
    end
    return lowestUnit
end

C_Timer.After(2, function()
    local party = WK and WK.PartyStatus
    local targetinfo = WK and WK.TargetInfo
    local playerinfo = WK and WK.PlayerInfo
    if party then
        print("1.队伍信息已加载")
    else
        print("1.队伍信息未加载")
        C_Timer.After(1, function()
            party = WK and WK.PartyStatus
        end)
    end
    if targetinfo then
        print("2.目标信息已加载")
    else
        print("2.目标信息未加载")
        C_Timer.After(1, function()
            targetinfo = WK and WK.TargetInfo
        end)
    end
    if playerinfo then
        print("3.玩家信息已加载")
    else
        print("3.玩家信息未加载")
        C_Timer.After(1, function()
            playerinfo = WK and WK.PlayerInfo
        end)
    end

    function e.UnitKey(unit, spell)
        if not Wa1Key or not Wa1Key.Prop then return end
        if not unit then
            e.text = "单位错误"
            return
        end

        local unitname = "未知"
        local code = 0
        local text = ""

        local info = C_Spell.GetSpellInfo(spell)
        if info then
            e.icon = info.iconID
        else
            if spell == "输出" then
                e.icon = 135274
            else
                e.icon = nil
            end
        end

        if unit == "macro" then
            code = 0
            unitname = "无目标"
        elseif unit == "target" then
            unitname = "目标"
            code = 0
        else
            if party[unit] then
                code = party[unit].index or unit:match("(%d+)")
                unitname = party[unit].name
            end
        end
        Wa1Key.Prop.Healing = {
            ["type"] = "party",
            ["unit"] = unit,
            ["code"] = code,
            ["spell"] = spell,
        }
        text = unit .. "\n目标:" .. unitname .. "\n技能:" .. spell .. "\n代码:" .. code
        e.text = text
        return true
    end

    if party and targetinfo and playerinfo then
        print("队伍初始化已完成")
        e.initialization = true
    end
end)
