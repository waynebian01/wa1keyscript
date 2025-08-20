local e = aura_env
local player = e.playerinfo
if player.class ~= "德鲁伊" then return end
if not player.inParty or player.inRaid or player.Specialization ~= 4 or not e.initialization then return end

local p = e.partystatus
local target = e.targetinfo
local UnitKey = e.UnitKey
local buff = p["player"].buff
local spell = e.spellinfo
local talentInfo = e.talentInfo
local channel = UnitChannelInfo("player")
local casting = UnitCastingInfo("player")
local disperse = WK_DISPERSE         -- 驱散开关
local interrupt = WK_Interrupt       -- 打断法术即将到来
local aoeisComeing = WK_AoeIsComeing -- 团队AOE即将在2秒后到来
local inMeleeRange = C_Spell.IsSpellInRange(5221, "target")
local inRangedRange = C_Spell.IsSpellInRange(5176, "target")
local function partyInfo()
    local t = {
        count90 = 0,                            -- 90%血量的单位数量
        count70 = 0,                            -- 70%血量的单位数量
        count_Lifebloom = 0,                    -- 生命绽放的单位数量

        lowest_Pct_Unit = nil,                  -- 最低血量的单位
        lowest_Pct_Health = 100,                -- 最低血量

        swiftmend_Pct_lowestUnit = nil,         -- 迅捷治愈的单位
        swiftmend_Pct_lowestHealth = 100,       -- 迅捷治愈的最低血量

        maxHealth_lowest = 9999999999,          -- 最大血量的单位
        maxHealth_lowestUnit = nil,             -- 最大血量的单位

        noRegrowth_Pct_lowestUnit = nil,        -- 无愈合的单位
        noRegrowth_Pct_lowestHealth = 100,      -- 无愈合的最低血量

        noRejuvenation_Pct_lowestUnit = nil,    -- 无回春术的单位
        noRejuvenation_Pct_lowestHealth = 100,  -- 无回春术的最低血量

        oneRejuvenation_Pct_lowestUnit = nil,   -- 只有一个回春术的单位
        oneRejuvenation_Pct_lowestHealth = 100, -- 只有一个回春术的最低血量

        noLifebloom_maxHealth = 9999999999,     -- 无生命绽放 的最大血量
        noLifebloom_maxHealth_lowestUnit = nil, -- 无生命绽放 的最大血量的单位

        hasDebuff_noRejuvenation = nil,         -- 无回春术的单位
        hasDebuff_noRegrowth = nil,             -- 无愈合的单位

        maxDamage = 0,                          -- 最大伤害
        maxDamage_Unit = nil,                   -- 最大伤害的单位

        tank_Unit = nil,                        -- 坦克的单位

        hasCurseUnit = nil,                     -- 有诅咒的单位
        hasPoisonUnit = nil,                    -- 有中毒的单位
        hasMagicUnit = nil,                     -- 有魔法伤害的单位
    }
    for unit in pairs(p) do
        if p and p[unit] then
            -- 生命绽放(Lifebloom)检查
            if p[unit].buff["生命绽放"] then
                t.count_Lifebloom = t.count_Lifebloom + 1
            end
            if p[unit].isValid and p[unit].inSight then
                if p[unit].healthPct < t.lowest_Pct_Health then
                    t.lowest_Pct_Health = p[unit].healthPct
                    t.lowest_Pct_Unit = unit
                end
                if p[unit].maxHealth < t.maxHealth_lowest then
                    t.maxHealth_lowest = p[unit].maxHealth
                    t.maxHealth_lowestUnit = unit
                end

                if p[unit].canSwiftmend and p[unit].healthPct < t.swiftmend_Pct_lowestHealth then
                    t.swiftmend_Pct_lowestHealth = p[unit].healthPct
                    t.swiftmend_Pct_lowestUnit = unit
                end

                if p[unit].healthPct < 90 then t.count90 = t.count90 + 1 end
                if p[unit].healthPct < 70 then t.count70 = t.count70 + 1 end
                if p[unit].damage > t.maxDamage then
                    t.maxDamage = p[unit].damage
                    t.maxDamage_Unit = unit
                end

                if p[unit].role == "TANK" then
                    t.tank_Unit = unit
                end

                -- 无 回春术(Rejuvenation) 检查
                if not p[unit].buff["回春术"] and not p[unit].buff["回春术（萌芽）"] then
                    if p[unit].hasParticularDebuff then
                        t.hasDebuff_noRejuvenation = unit
                    end
                    if p[unit].healthPct < t.noRejuvenation_Pct_lowestHealth then
                        t.noRejuvenation_Pct_lowestHealth = p[unit].healthPct
                        t.noRejuvenation_Pct_lowestUnit = unit
                    end
                end

                -- 只有一个 回春术(Rejuvenation)检查
                if p[unit].buff["回春术"] ~= p[unit].buff["回春术（萌芽）"] then
                    if p[unit].healthPct < t.oneRejuvenation_Pct_lowestHealth then
                        t.oneRejuvenation_Pct_lowestHealth = p[unit].healthPct
                        t.oneRejuvenation_Pct_lowestUnit = unit
                    end
                end

                -- 愈合(Regrowth)检查
                if not p[unit].buff["愈合"] then
                    if p[unit].hasParticularDebuff then
                        t.hasDebuff_noRegrowth = unit
                    end
                    if p[unit].healthPct < t.noRegrowth_Pct_lowestHealth then
                        t.noRegrowth_Pct_lowestHealth = p[unit].healthPct
                        t.noRegrowth_Pct_lowestUnit = unit
                    end
                end

                -- 生命绽放(Lifebloom)检查
                if not p[unit].buff["生命绽放"] then
                    if p[unit].maxHealth < t.noLifebloom_maxHealth then
                        t.noLifebloom_maxHealth = p[unit].maxHealth
                        t.noLifebloom_maxHealth_lowestUnit = unit
                    end
                end

                if p[unit].hasCurse then
                    t.hasCurseUnit = unit
                end
                if p[unit].hasPoison then
                    t.hasPoisonUnit = unit
                end
                if p[unit].hasMagic then
                    t.hasMagicUnit = unit
                end
            end
        end
    end
    return t
end
local t = partyInfo()
local maxCountUnit, maxTimeUnit, minTimeUnit = e.SortDebuffs()

if (casting or channel) and interrupt then return UnitKey("macro", "中断施法") end
if channel then return UnitKey("macro", "None") end

if not interrupt and buff["自然迅捷"] and spell["万灵之召"].usable then
    return UnitKey("macro", "万灵之召")
end

if player.isCombat then
    if aoeisComeing and spell["树皮术"].usable then
        return UnitKey("macro", "树皮术")
    end
    if spell["甘霖"].usable and p["player"].healthPct < 60 then
        return UnitKey("macro", "甘霖")
    end
    if spell["自然的守护"].usable then
        return UnitKey("macro", "自然的守护")
    end
end

if spell["自然之愈"].usable and disperse then
    if target.helper.hasCurse then
        return UnitKey("macro", "驱散目标")
    end
    if target.helper.hasPoison then
        return UnitKey("macro", "驱散目标")
    end
    if target.helper.hasMagic then
        return UnitKey("macro", "驱散目标")
    end
    if maxCountUnit then
        return UnitKey(maxCountUnit, "自然之愈")
    end
    if maxTimeUnit then
        return UnitKey(maxTimeUnit, "自然之愈")
    end
    if minTimeUnit then
        return UnitKey(minTimeUnit, "自然之愈")
    end
    if t.hasCurseUnit then
        return UnitKey(t.hasCurseUnit, "自然之愈")
    end
    if t.hasPoisonUnit then
        return UnitKey(t.hasPoisonUnit, "自然之愈")
    end
    if t.hasMagicUnit then
        return UnitKey(t.hasMagicUnit, "自然之愈")
    end
end

if spell["安抚"].usable and target.enemy.hasEnrage then
    return UnitKey("target", "安抚")
end

if aoeisComeing then
    if not interrupt and spell["野性成长"].usable and not player.isMoving then
        return UnitKey("macro", "野性成长")
    end
end
if t.count70 >= 2 then
    if spell["激活"].usable then
        return UnitKey("macro", "激活")
    end
    if talentInfo["林莽卫士"] and spell["林莽卫士"].charges > 0 then
        return UnitKey(t.lowest_Pct_Unit, "林莽卫士")
    end
end
if not interrupt and casting ~= "愈合" and spell["自然迅捷"].usable and t.count90 >= 3 and t.count70 >= 1 then
    return UnitKey("macro", "自然迅捷")
end

if buff["自然迅捷"] and spell["愈合"].usable and t.lowest_Pct_Unit then
    return UnitKey(t.lowest_Pct_Unit, "愈合")
end

if t.count90 >= 2 then
    if talentInfo["林莽卫士"] and spell["林莽卫士"].charges > 1 then
        return UnitKey(t.lowest_Pct_Unit, "林莽卫士")
    end
    if not interrupt and spell["野性成长"].usable and not player.isMoving then
        return UnitKey("macro", "野性成长")
    end
end

if talentInfo["林莽卫士"] and spell["林莽卫士"].charges == 3 and t.lowest_Pct_Health < 90 then
    return UnitKey(t.lowest_Pct_Unit, "林莽卫士")
end

if spell["迅捷治愈"].usable and t.swiftmend_Pct_lowestHealth < 80 then
    return UnitKey(t.swiftmend_Pct_lowestUnit, "迅捷治愈")
end

if not interrupt and spell["愈合"].usable and buff["节能施法"] and not player.isMoving and casting ~= "愈合" then
    if t.noRegrowth_Pct_lowestHealth < 90 then
        return UnitKey(t.noRegrowth_Pct_lowestUnit, "愈合")
    end
    if t.lowest_Pct_Health < 80 then
        return UnitKey(t.lowest_Pct_Unit, "愈合")
    end
end

if not interrupt and spell["生命绽放"].usable and t.noLifebloom_maxHealth_lowestUnit then
    if talentInfo["蔓生绽放"] then
        if t.count_Lifebloom < 2 then
            return UnitKey(t.noLifebloom_maxHealth_lowestUnit, "生命绽放")
        end
    else
        if t.count_Lifebloom == 0 then
            return UnitKey(t.noLifebloom_maxHealth_lowestUnit, "生命绽放")
        end
    end
end

if talentInfo["塞纳里奥结界"] and spell["塞纳里奥结界"].usable and t.tank_Unit then
    return UnitKey(t.tank_Unit, "塞纳里奥结界")
end

if t.noRejuvenation_Pct_lowestHealth < 95 then
    return UnitKey(t.noRejuvenation_Pct_lowestUnit, "回春术")
end

if talentInfo["萌芽"] and t.oneRejuvenation_Pct_lowestHealth < 80 then
    return UnitKey(t.oneRejuvenation_Pct_lowestUnit, "回春术")
end

if not interrupt and spell["愈合"].usable and t.lowest_Pct_Health < 80 and casting ~= "愈合" then
    return UnitKey(t.lowest_Pct_Unit, "愈合")
end

if player.isCombat and target.CanAttack then
    if inMeleeRange then
        return UnitKey("macro", "输出")
    end
    if inRangedRange then
        if target.enemy.debuff["月火术"] then
            return UnitKey("macro", "愤怒")
        else
            return UnitKey("macro", "月火术")
        end
    end
end

if player.isCombat and target.CanAttack then
    if talentInfo["杀手本能"] then
        if inMeleeRange then
            return UnitKey("macro", "输出")
        end
        if inRangedRange then
            if target.enemy.debuff["月火术"] then
                return UnitKey("macro", "愤怒")
            else
                return UnitKey("macro", "月火术")
            end
        end
    else
        return UnitKey("macro", "输出")
    end
end

return UnitKey("macro", "None")
