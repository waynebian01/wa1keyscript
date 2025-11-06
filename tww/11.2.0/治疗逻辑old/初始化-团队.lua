local e = aura_env
e.initialization = false

function e.getPlayer()
    local player = nil
    local raid = WK.RaidStatus
    for i = 1, 30 do
        local unit = "raid" .. i
        if raid and raid[unit] then
            if UnitIsUnit(unit, "player") then
                player = unit
            end
        end
    end
    return player
end

function e.getFocus()
    local focus = nil
    local raid = WK.RaidStatus
    if UnitExists("focus") then
        for i = 1, 30 do
            local unit = "raid" .. i
            if raid and raid[unit] then
                if UnitIsUnit(unit, "focus") then
                    focus = unit
                end
            end
        end
    end
    return focus
end

-- @param number 大于此数量,就退出循环返回true,默认0
-- @param thresholdHealthPct 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @param auraName 光环或减益名称
-- @param auraType 光环或减益类型: "HELPFUL" 或 "HARMFUL",默认 "HELPFUL"
-- @param hasAura 布尔值, 如果有光环名称,检查是否有这个光环 (true: 有光环, false: 无光环)
-- @param role 角色类型: "TANK" 或 "HEALER" 或 "DAMAGER"
-- @return 布尔值,符合条件的单位数量大于等于number
function e.getCount(number, thresholdHealthPct, auraName, auraType, hasAura, role)
    local num = number or 0
    local count = 0
    local healthThreshold = thresholdHealthPct or 100
    local auraOrDebuffType = auraType or "HELPFUL"
    local hasAuraOrNot = (hasAura == nil) and true or hasAura
    local raid = WK.RaidStatus
    for i = 1, 30 do
        local unit = "raid" .. i
        if raid and raid[unit] then
            local unitData = raid and raid[unit]
            if unitData.isValid and unitData.inSight and (role == nil or unitData.combatRole == role) then
                if auraName then
                    local status = (auraOrDebuffType == "HELPFUL") and unitData.buff or unitData.debuff
                    if hasAuraOrNot then
                        if status[auraName] and unitData.healthPct < healthThreshold then
                            count = count + 1
                            if count >= num then
                                return true
                            end
                        end
                    else
                        if not status[auraName] and unitData.healthPct < healthThreshold then
                            count = count + 1
                            if count >= num then
                                return true
                            end
                        end
                    end
                else
                    if unitData.healthPct < healthThreshold then
                        count = count + 1
                        if count >= num then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
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
    local raid = WK.RaidStatus
    for i = 1, 30 do
        local unit = "raid" .. i
        if raid and raid[unit] then
            local unitData = raid and raid[unit]
            if unitData.isValid and unitData.inSight and (role == nil or unitData.combatRole == role) then
                local currentHealthPct = unitData.healthPct
                if auraName then
                    local status = (auraOrDebuffType == "HELPFUL") and unitData.buff or unitData.debuff
                    if hasAuraOrNot then
                        if status[auraName] and currentHealthPct < healthThreshold then
                            healthThreshold = currentHealthPct
                            lowestUnit = unit
                        end
                    else
                        if not status[auraName] and currentHealthPct < healthThreshold then
                            healthThreshold = currentHealthPct
                            lowestUnit = unit
                        end
                    end
                else
                    if currentHealthPct < healthThreshold then
                        healthThreshold = currentHealthPct
                        lowestUnit = unit
                    end
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
    local maxHealth = math.huge
    local maxHealthUnit = nil
    local raid = WK.RaidStatus
    for i = 1, 30 do
        local unit = "raid" .. i
        if raid and raid[unit] then
            local unitData = raid and raid[unit]
            if unitData.isValid and unitData.inSight and (role == nil or unitData.combatRole == role) then
                local currentMaxHealth = unitData.maxHealth
                if auraName then
                    local status = (auraType == "HELPFUL") and unitData.buff or unitData.debuff
                    if hasAura then
                        if status[auraName] and currentMaxHealth < maxHealth then
                            maxHealth = currentMaxHealth
                            maxHealthUnit = unit
                        end
                    end
                else
                    if currentMaxHealth < maxHealth then
                        maxHealth = currentMaxHealth
                        maxHealthUnit = unit
                    end
                end
            end
        end
    end
    return maxHealthUnit
end

-- @return 团队生命值平均血量
function e.averageHealth()
    local total_averageHealth = 100 -- 团队生命值平均血量
    local total_health = 0          -- 团队生命值总血量
    local total_maxhealth = 0       -- 团队生命值总血量
    local raid = WK.RaidStatus
    for i = 1, 30 do
        local unit = "raid" .. i
        if raid and raid[unit] then
            local unitData = raid and raid[unit]
            if unitData.isValid and unitData.inSight then
                total_health = total_health + unitData.health
                total_maxhealth = total_maxhealth + unitData.maxHealth
            end
        end
    end
    total_averageHealth = total_health / total_maxhealth * 100
    return total_averageHealth
end

-- @return 团队伤害最高的单位
function e.DamageUnit()
    local damageUnit = nil
    local damage = 0
    local raid = WK.RaidStatus
    for i = 1, 30 do
        local unit = "raid" .. i
        if raid and raid[unit] then
            local unitData = raid and raid[unit]
            if unitData.isValid and unitData.inSight then
                local currentDamage = unitData.damage
                if currentDamage > damage then
                    damage = currentDamage
                    damageUnit = unit
                end
            end
        end
    end
    return damageUnit
end

-- @param thresholdHealthPct 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @param RejuvenationCount 回春术数量,默认0
-- @return 团队回春术最低的单位
function e.rejuvenation_lowestUnit(thresholdHealthPct, RejuvenationCount)
    local lowestUnit = nil
    local healthThreshold = thresholdHealthPct or 100
    local count = RejuvenationCount or 0
    local raid = WK.RaidStatus
    for i = 1, 30 do
        local unit = "raid" .. i
        if raid and raid[unit] then
            local unitData = raid and raid[unit]
            if unitData.isValid and unitData.inSight then
                local currentHealthPct = unitData.healthPct
                if count == 0 then
                    if not unitData.buff["回春术"] and not unitData.buff["回春术（萌芽）"] then
                        if currentHealthPct < healthThreshold then
                            healthThreshold = currentHealthPct
                            lowestUnit = unit
                        end
                    end
                end
                if count == 1 then
                    if unitData.buff["回春术"] ~= unitData.buff["回春术（萌芽）"] then
                        if currentHealthPct < healthThreshold then
                            healthThreshold = currentHealthPct
                            lowestUnit = unit
                        end
                    end
                end
                if count == 2 then
                    if unitData.buff["回春术"] and unitData.buff["回春术（萌芽）"] then
                        if currentHealthPct < healthThreshold then
                            healthThreshold = currentHealthPct
                            lowestUnit = unit
                        end
                    end
                end
            end
        end
    end
    return lowestUnit
end

-- @param thresholdHealthPct 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @return 团队迅捷治愈最低的单位
function e.swiftmend_lowestUnit(thresholdHealthPct)
    local lowestUnit = nil
    local healthThreshold = thresholdHealthPct or 100
    local raid = WK.RaidStatus
    for i = 1, 30 do
        local unit = "raid" .. i
        if raid and raid[unit] then
            local unitData = raid and raid[unit]
            if unitData.isValid and unitData.inSight then
                local currentHealthPct = unitData.healthPct
                if unitData.buff["愈合"] or unitData.buff["野性成长"] or unitData.buff["回春术"] or unitData.buff["回春术（萌芽）"] then
                    if currentHealthPct < healthThreshold then
                        healthThreshold = currentHealthPct
                        lowestUnit = unit
                    end
                end
            end
        end
    end
    return lowestUnit
end

-- @param thresholdHealthPct 血量百分比阈值, 只找到生命值低于这个百分比的单位,默认100
-- @return 团队没有晨光且生命值最低的单位
function e.noDawnlight_Unit(thresholdHealthPct)
    local lowestUnit = nil
    local healthThreshold = thresholdHealthPct or 100
    local raid = WK.RaidStatus
    for i = 1, 30 do
        local unit = "raid" .. i
        if raid and raid[unit] then
            local unitData = raid and raid[unit]
            if unitData.isValid and unitData.inSight then
                local currentHealthPct = unitData.healthPct
                if not (unitData.buff["晨光"] and unitData.buff["晨光"].spellId == 431381) then
                    if currentHealthPct < healthThreshold then
                        healthThreshold = currentHealthPct
                        lowestUnit = unit
                    end
                end
            end
        end
    end
    return lowestUnit
end

C_Timer.After(2, function()
    local raid = WK and WK.RaidStatus
    local targetinfo = WK and WK.TargetInfo
    local playerinfo = WK and WK.PlayerInfo

    if raid then
        print("1.团队信息已加载")
    else
        print("1.团队信息未加载")
        C_Timer.After(1, function()
            raid = WK and WK.RaidStatus
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
            e.text = "单位错误\n请RL修复错误"
            return true
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
            unitname = "无目标"
        elseif unit == "target" then
            unitname = "目标"
        else
            if raid[unit] then
                code = raid[unit].index or unit:match("(%d+)")
                unitname = raid[unit].name or GetUnitName(unit, true) or "未知"
            end
        end
        Wa1Key.Prop.Healing = {
            ["type"] = "raid",
            ["unit"] = unit,
            ["code"] = code,
            ["spell"] = spell,
        }
        text = unit .. "\n目标:" .. unitname .. "\n技能:" .. spell .. "\n代码:" .. code
        e.text = text
        return true
    end

    if raid and targetinfo and playerinfo then
        print("团队初始化已完成")
        e.initialization = true
    end
end)
