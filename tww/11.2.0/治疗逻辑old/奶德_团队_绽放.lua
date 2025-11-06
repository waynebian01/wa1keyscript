if aura_env.initialization == false then return end
local e = aura_env
local player = WK.PlayerInfo
local target = WK.TargetInfo
local spell = WK.getSpellArguments
local talents = player.talent
local UnitKey = aura_env.UnitKey
local channel = UnitChannelInfo("player")
local casting = UnitCastingInfo("player")
local inMeleeRange = C_Spell.IsSpellInRange(5221, "target")
local inRangedRange = C_Spell.IsSpellInRange(5176, "target")

local set = aura_env.config
local lowestUnit = e.getLowestUnit(100)
local noCenarion_tank = e.getLowestUnit(200, "塞纳里奥结界", "HELPFUL", false, "TANK") -- 坦克的单位
local noLifelowest = e.maxHealth_lowestUnit("生命绽放", "HELPFUL", false) -- 无生命绽放 的最大血量的单位
local regrowth = e.getLowestUnit(set.Regrowth, "愈合", "HELPFUL", false) -- 愈合阈值
local regrowthClear = e.getLowestUnit(set.RegrowthClear, "愈合", "HELPFUL", false) -- 愈合(节能施法)阈值
local rejuvenation = e.rejuvenation_lowestUnit(set.Rejuvenation, 0) -- 回春术阈值
local rejuvenation2 = e.rejuvenation_lowestUnit(set.Rejuvenation2, 1) -- 回春术(萌芽)阈值
local swiftmend = e.swiftmend_lowestUnit(set.Swiftmend) -- 可以迅捷治愈生命值最低的单位
local averageHealth = e.averageHealth()

if channel then return UnitKey("macro", "None") end

if player.buff["自然迅捷"] and spell("万灵之召", "usable") then
    return UnitKey("macro", "万灵之召")
end

if talents["繁盛"] and spell("繁盛", "usable") and not spell("万灵之召", "usable") then
    if spell("野性成长", "usable") and not player.isMoving then
        return UnitKey("macro", "野性成长")
    else
        return UnitKey("macro", "繁盛")
    end
end

if player.isCombat then
    if spell("甘霖", "usable") and player.healthPct < 60 then
        return UnitKey("macro", "甘霖")
    end
    if spell("自然的守护", "usable") and set.Attack then
        return UnitKey("macro", "自然的守护")
    end
end

if spell("自然之愈", "usable") then
    if WK.RaidDebuffUnit then
        return UnitKey(WK.RaidDebuffUnit, "自然之愈")
    end
end

if e.getCount(5, 75) then
    if spell("激活", "usable") and set.Innervate and averageHealth <= 80 then
        return UnitKey(e.getPlayer(), "激活")
    end
    if talents["林莽卫士"] and spell("林莽卫士", "charges") > 0 then
        return UnitKey(e.getLowestUnit(100), "林莽卫士")
    end
    if casting ~= "愈合" and spell("自然迅捷", "usable") then
        return UnitKey("macro", "自然迅捷")
    end
end

if player.buff["自然迅捷"] and not spell("万灵之召", "usable") and spell("愈合", "usable") and lowestUnit then
    return UnitKey(lowestUnit, "愈合")
end

if spell("迅捷治愈", "usable") and swiftmend then
    return UnitKey(swiftmend, "迅捷治愈")
end

if e.getCount(set.WildGrowthCount, set.WildGrowth) then
    if talents["林莽卫士"] and spell("林莽卫士", "charges") > 1 then
        return UnitKey(lowestUnit, "林莽卫士")
    end
    if spell("野性成长", "usable") and not player.isMoving then
        return UnitKey("macro", "野性成长")
    end
end

if talents["林莽卫士"] and spell("林莽卫士", "charges") == 3 and e.getLowestUnit(90) then
    return UnitKey(lowestUnit, "林莽卫士")
end

if set.Efflorescence and player.isCombat and talents["百花齐放"] and not player.buff["百花齐放"] and spell("百花齐放", "usable") then
    return UnitKey("macro", "百花齐放")
end

if spell("愈合", "usable") and not player.isMoving and casting ~= "愈合" then
    if player.buff["节能施法"] and regrowthClear then
        return UnitKey(regrowthClear, "愈合")
    end
    if regrowth then
        return UnitKey(regrowth, "愈合")
    end
end

if spell("生命绽放", "usable") then
    if talents["蔓生绽放"] then
        if not player.buff["生命绽放"] then
            return UnitKey(e.getPlayer(), "生命绽放")
        end
        if not e.getCount(2, 200, "生命绽放", "HELPFUL", true) and noLifelowest then
            return UnitKey(noLifelowest, "生命绽放")
        end
    else
        if not player.buff["生命绽放"] then
            return UnitKey(e.getPlayer(), "生命绽放")
        end
    end
end

if talents["塞纳里奥结界"] and spell("塞纳里奥结界", "usable") and noCenarion_tank then
    return UnitKey(noCenarion_tank, "塞纳里奥结界")
end

if not e.getCount(10, 200, "回春术") then
    if rejuvenation then
        return UnitKey(rejuvenation, "回春术")
    end
    if talents["萌芽"] and rejuvenation2 then
        return UnitKey(rejuvenation2, "回春术")
    end
end

if set.Attack and player.isCombat then
    if target.canAttack then
        if talents["杀手本能"] then
            if inMeleeRange then
                return UnitKey("macro", "输出")
            end
            if inRangedRange then
                if target.debuff["月火术"] then
                    return UnitKey("target", "愤怒")
                else
                    return UnitKey("target", "月火术")
                end
            end
        else
            return UnitKey("macro", "输出")
        end
    else
        return UnitKey("macro", "上个敌人")
    end
end

return UnitKey("macro", "None")
