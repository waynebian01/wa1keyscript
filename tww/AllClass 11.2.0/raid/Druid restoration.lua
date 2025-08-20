local e = aura_env
local player = e.playerinfo
if player.class ~= "德鲁伊" then return end
if player.Specialization ~= 4 or not player.inRaid or not e.initialization then return end

local r = e.raidstatus
local target = e.targetinfo
local buff = r[player.inRaidUnit] and r[player.inRaidUnit].buff or {}
local spell = e.spellinfo
local talentInfo = e.talentInfo
local UnitKey = e.UnitKey
local channel = UnitChannelInfo("player")
local casting = UnitCastingInfo("player")
local hekili = Hekili_GetRecommendedAbility("Primary", 1)      -- 获取Hekili推荐技能
local interrupt = WK_Interrupt                                 -- 打断法术即将到来
local aoeisComeing = WK_AoeIsComeing                           -- 团队AOE即将在2秒后到来
local aoeRemaining = aoeisComeing and aoeisComeing - GetTime() -- 团队AOE即将在到来的剩余时间
local highDamage = WK_HIGHDAMAGE or WK_HIGHDAMAGECAST          -- 坦克6秒内即将受到高伤害, WK_HIGHDAMAGE=4秒, WK_HIGHDAMAGECAST=2秒

local function raidInfo()
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

    for i = 1, 30 do
        local unit = "raid" .. i
        if r and r[unit] and r[unit].isAlive and r[unit].canAssist then
            r[unit].harmony = 0
            r[unit].canSwiftmend = false
            -- 生命绽放(Lifebloom)检查
            if r[unit].buff["生命绽放"] then
                t.count_Lifebloom = t.count_Lifebloom + 1
            end
            if r[unit].buff["回春术"] then
                r[unit].harmony = r[unit].harmony + 1
                r[unit].canSwiftmend = true
            end
            if r[unit].buff["愈合"] then
                r[unit].harmony = r[unit].harmony + 1
                r[unit].canSwiftmend = true
            end
            if r[unit].buff["回春术（萌芽）"] then
                r[unit].harmony = r[unit].harmony + 1
                r[unit].canSwiftmend = true
            end
            if r[unit].buff["野性成长"] then
                r[unit].harmony = r[unit].harmony + 1
                r[unit].canSwiftmend = true
            end
            if r[unit].buff["生命绽放"] then
                if e.talentInfo["祥和绽放"] then
                    r[unit].harmony = r[unit].harmony + 3
                else
                    r[unit].harmony = r[unit].harmony + 1
                end
            end
            if r[unit].inRange and r[unit].inSight then
                if r[unit].healthPct < t.lowest_Pct_Health then
                    t.lowest_Pct_Health = r[unit].healthPct
                    t.lowest_Pct_Unit = unit
                end
                if r[unit].maxHealth < t.maxHealth_lowest then
                    t.maxHealth_lowest = r[unit].maxHealth
                    t.maxHealth_lowestUnit = unit
                end

                if r[unit].canSwiftmend and r[unit].healthPct < t.swiftmend_Pct_lowestHealth then
                    t.swiftmend_Pct_lowestHealth = r[unit].healthPct
                    t.swiftmend_Pct_lowestUnit = unit
                end

                if r[unit].healthPct < 90 then t.count90 = t.count90 + 1 end
                if r[unit].healthPct < 70 then t.count70 = t.count70 + 1 end
                if r[unit].damage > t.maxDamage then
                    t.maxDamage = r[unit].damage
                    t.maxDamage_Unit = unit
                end

                if r[unit].role == "TANK" then
                    t.tank_Unit = unit
                end

                -- 无 回春术(Rejuvenation) 检查
                if not r[unit].buff["回春术"] and not r[unit].buff["回春术（萌芽）"] then
                    if r[unit].hasParticularDebuff then
                        t.hasDebuff_noRejuvenation = unit
                    end
                    if r[unit].healthPct < t.noRejuvenation_Pct_lowestHealth then
                        t.noRejuvenation_Pct_lowestHealth = r[unit].healthPct
                        t.noRejuvenation_Pct_lowestUnit = unit
                    end
                end

                -- 只有一个 回春术(Rejuvenation)检查
                if r[unit].buff["回春术"] ~= r[unit].buff["回春术（萌芽）"] then
                    if r[unit].healthPct < t.oneRejuvenation_Pct_lowestHealth then
                        t.oneRejuvenation_Pct_lowestHealth = r[unit].healthPct
                        t.oneRejuvenation_Pct_lowestUnit = unit
                    end
                end

                -- 愈合(Regrowth)检查
                if not r[unit].buff["愈合"] then
                    if r[unit].hasParticularDebuff then
                        t.hasDebuff_noRegrowth = unit
                    end
                    if r[unit].healthPct < t.noRegrowth_Pct_lowestHealth then
                        t.noRegrowth_Pct_lowestHealth = r[unit].healthPct
                        t.noRegrowth_Pct_lowestUnit = unit
                    end
                end

                -- 生命绽放(Lifebloom)检查
                if not r[unit].buff["生命绽放"] then
                    if r[unit].maxHealth < t.noLifebloom_maxHealth then
                        t.noLifebloom_maxHealth = r[unit].maxHealth
                        t.noLifebloom_maxHealth_lowestUnit = unit
                    end
                end

                if r[unit].hasCurse then
                    t.hasCurseUnit = unit
                end
                if r[unit].hasPoison then
                    t.hasPoisonUnit = unit
                end
                if r[unit].hasMagic then
                    t.hasMagicUnit = unit
                end
            end
        end
    end
    return t
end
local t = raidInfo()

if (casting or channel) and interrupt then return UnitKey("macro", "中断施法") end
if channel then return UnitKey("macro", "None") end

if player.isCombat then
    if aoeisComeing and spell["树皮术"].usable then
        return UnitKey("macro", "树皮术")
    end
    if spell["甘霖"].usable and r["player"].healthPct < 60 then
        return UnitKey("macro", "甘霖")
    end
    if spell["自然的守护"].usable then
        return UnitKey("macro", "自然的守护")
    end
end
if spell["安抚"].usable and target.enemy.hasEnrage then
    return UnitKey("target", "安抚")
end
if spell["自然之愈"].usable then
    if target.helper.hasCurse then
        return UnitKey("macro", "驱散目标")
    end
    if target.helper.hasPoison then
        return UnitKey("macro", "驱散目标")
    end
    if target.helper.hasMagic then
        return UnitKey("macro", "驱散目标")
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

if buff["自然迅捷"] and spell["愈合"].usable then
    return UnitKey(t.lowest_Pct_Unit, "愈合")
end

if aoeisComeing then
    if not interrupt and spell["野性成长"].usable and not player.isMoving then
        return UnitKey("macro", "野性成长")
    end
end
if t.count70 >= 3 then
    if spell["激活"].usable then
        return UnitKey("macro", "激活")
    end
    if talentInfo["林莽卫士"] and spell["林莽卫士"].charges > 0 then
        return UnitKey(t.lowest_Pct_Unit, "林莽卫士")
    end
end
if not interrupt and t.count70 >= 2 and spell["万灵之召"].usable then
    if spell["自然迅捷"].usable then
        return UnitKey("macro", "自然迅捷")
    end
    return UnitKey("macro", "万灵之召")
end

if buff["自然迅捷"] and spell["愈合"].usable then
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
    if target.inRange_5 then
        return UnitKey("macro", "输出")
    end
    if target.inRange_30 then
        if target.enemy.debuff["月火术"] then
            return UnitKey("macro", "愤怒")
        else
            return UnitKey("macro", "月火术")
        end
    end
end
return UnitKey("macro", "None")
