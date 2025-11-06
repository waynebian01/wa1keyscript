if aura_env.initialization == false then return end
local e                    = aura_env
local set                  = e.config
local player               = WK.PlayerInfo
local target               = WK.TargetInfo
local talents              = player.talent
local UnitKey              = e.UnitKey
local channel              = UnitChannelInfo("player")
local casting              = UnitCastingInfo("player")
local interrupt            = WK.Interrupt
local aoeisComeing         = WK.AoeIsComeing
local aoeRemaining         = aoeisComeing and aoeisComeing - GetTime() -- 团队AOE即将在到来的剩余时间

local inRange              = C_Spell.IsSpellInRange(585, "target") -- 敌对目标是否在范围内
local premonitionID        = C_Spell.GetOverrideSpell(428924) -- 预兆ID
local spell                = WK.getSpellArguments -- 获取法术参数
local PrayerCount          = e.getCount(set.PrayerValue) -- 治疗祷言数量
local HaloCount            = e.getCount(set.HaloValue) -- 光晕数量
local SanctifyCount        = e.getCount(set.SanctifyValue) -- 圣言术：灵数量
local lowestUnit           = e.getLowestUnit(100) -- 生命值最低的单位
local Heal                 = e.getLowestUnit(set.Heal) -- 治疗术
local Flash                = e.getLowestUnit(set.Flash) -- 快速治疗
local Serenity             = e.getLowestUnit(set.Serenity) -- 圣言术：静
local noMending_Tank       = e.getLowestUnit(101, "愈合祷言", "HELPFUL", false, "TANK") -- 无愈合坦克
local noMending_LowestUnit = e.getLowestUnit(101, "愈合祷言", "HELPFUL", false) -- 无愈合生命值最低的单位
local noMendingCount       = e.getCount(95, "愈合祷言", "HELPFUL", false) -- 无愈合,生命值低于95%的单位数量
local noRenew_Tank         = e.getLowestUnit(101, "恢复", "HELPFUL", false, "TANK") -- 无恢复坦克
local noRenew_LowestUnit   = e.getLowestUnit(95, "恢复", "HELPFUL", false) -- 无恢复生命值最低的单位

if channel then return UnitKey("macro", "None") end

if spell("纯净术", "usable") then
    if target.canAssist and set.DisperseFriend then
        if target.hasMagic then
            return UnitKey("macro", "纯净术")
        end
        if talents["强化纯净术"] and target.hasDisease then
            return UnitKey("target", "纯净术")
        end
    end
    if set.Disperse then
        if WK.debuffPlayer then
            return UnitKey("player", "纯净术")
        end
        if WK.debuffMintimeUnit then
            return UnitKey(WK.debuffMintimeUnit, "纯净术")
        end
        if WK.hasMagicUnit then
            return UnitKey(WK.hasMagicUnit, "纯净术")
        end
        if talents["强化纯净术"] and WK.hasDiseaseUnit then
            return UnitKey(WK.hasDiseaseUnit, "纯净术")
        end
        if WK.hasDebuffUnit then
            return UnitKey(WK.hasDebuffUnit, "纯净术")
        end
    end
end

if spell("愈合祷言", "usable") and player.buff["洞察预兆"] then
      if noMending_LowestUnit then
        return UnitKey(noMending_LowestUnit, "愈合祷言")
    end
    if noMending_Tank then
        return UnitKey(noMending_Tank, "愈合祷言")
    end
  
end

if spell("渐隐术", "usable") and (aoeisComeing or interrupt) then
    return UnitKey("macro", "渐隐术")
end

if spell("绝望祷言", "usable") and not player.buff["救赎之魂"] and player.healthPct <= 50 then
    return UnitKey("macro", "绝望祷言")
end

if player.isCombat then
    if spell("暗影魔", "usable") and player.manaPct <= 80 then
        if player.buff["能量灌注"] and target.canAttack and inRange then
            return UnitKey("target", "暗影魔")
        end
    end
    if player.buff["狂想曲"] and player.buff["狂想曲"].applications == 20 then
        if target.canAttack and target.maxRange and target.maxRange <= 10 then
            return UnitKey("macro", "神圣新星")
        end
    end
    if set.Apotheosis and spell("神圣化身", "usable") and e.averageHealth() <= set.ApotheosisValue then
        if spell("圣言术：静", "charges") < 2 and spell("圣言术：灵", "charges") < 2 then
            return UnitKey("macro", "神圣化身")
        end
    end
    if set.Premonition and spell("预兆", "usable") and spell("愈合祷言", "usable") and not player.buff["洞察预兆"] then
        if noMendingCount >= 3 then
            if set.Keep1Premonition then
                if spell("预兆", "charges") == 2 then
                    if premonitionID == 428933 or premonitionID == 440725 then -- 洞察预兆
                        return UnitKey("macro", "预兆")
                    end
                    if premonitionID == 428930 and e.averageHealth() <= 85 then -- 虔诚预兆
                        return UnitKey("macro", "预兆")
                    end
                    if premonitionID == 428934 and (aoeisComeing or e.getLowestUnit(80)) then -- 慰藉预兆
                        return UnitKey("macro", "预兆")
                    end
                end
            else
                if noMendingCount >= 3 and (premonitionID == 428933 or premonitionID == 440725) then -- 洞察预兆
                    return UnitKey("macro", "预兆")
                end
                if premonitionID == 428930 and e.averageHealth() <= 85 then -- 虔诚预兆
                    return UnitKey("macro", "预兆")
                end
                if premonitionID == 428934 and (aoeisComeing or e.getLowestUnit(80)) then -- 慰藉预兆
                    return UnitKey("macro", "预兆")
                end
            end
        end
    end
end
if spell("愈合祷言", "usable") then
    if noMending_Tank then
        return UnitKey(noMending_Tank, "愈合祷言")
    end
    if noMending_LowestUnit then
        return UnitKey(noMending_LowestUnit, "愈合祷言")
    end
end

if spell("恢复", "usable") and talents["恢复增效"] then
    if noRenew_Tank then
        return UnitKey(noRenew_Tank, "恢复")
    end
    if noRenew_LowestUnit then
        return UnitKey(noRenew_LowestUnit, "恢复")
    end
end

if spell("光晕", "usable") and HaloCount >= set.HaloCount then
    return UnitKey("macro", "光晕")
end

if talents["共鸣圣言"] then
    if player.buff["共鸣圣言"] then
        if player.isMoving then
            if spell("快速治疗", "usable") and player.buff["圣光涌动"] and Flash then
                return UnitKey(Flash, "快速治疗")
            end
        else
            if spell("治疗祷言", "usable") and casting ~= "治疗祷言" and PrayerCount >= set.PrayerCount then
                return UnitKey("macro", "治疗祷言")
            end
            if spell("治疗术", "usable") and casting ~= "治疗术" and player.buff["织光者"] and Heal then
                return UnitKey(Heal, "治疗术")
            end
            if spell("快速治疗", "usable") and casting ~= "快速治疗" and Flash then
                return UnitKey(Flash, "快速治疗")
            end
        end
    else
        if set.Sanctify and spell("圣言术：灵", "usable") and SanctifyCount >= set.SanctifyCount then
            return UnitKey("macro", "圣言术：灵")
        end
        if spell("圣言术：静", "usable") and Serenity then
            return UnitKey(Serenity, "圣言术：静")
        end
    end
    if not spell("圣言术：静", "usable") then
        if set.Sanctify then
            if not spell("圣言术：灵", "usable") then
                if spell("治疗祷言", "usable") and casting ~= "治疗祷言" and PrayerCount >= set.PrayerCount then
                    return UnitKey("macro", "治疗祷言")
                end
                if spell("治疗术", "usable") and casting ~= "治疗术" and player.buff["织光者"] and Heal then
                    return UnitKey(Heal, "治疗术")
                end
                if spell("快速治疗", "usable") and casting ~= "快速治疗" and Flash then
                    return UnitKey(Flash, "快速治疗")
                end
            end
        else
            if spell("治疗祷言", "usable") and casting ~= "治疗祷言" and PrayerCount >= set.PrayerCount then
                return UnitKey("macro", "治疗祷言")
            end
            if spell("治疗术", "usable") and casting ~= "治疗术" and player.buff["织光者"] and Heal then
                return UnitKey(Heal, "治疗术")
            end
            if spell("快速治疗", "usable") and casting ~= "快速治疗" and Flash then
                return UnitKey(Flash, "快速治疗")
            end
        end
    end
else
    if set.Sanctify and spell("圣言术：灵", "usable") and SanctifyCount >= set.SanctifyCount then
        return UnitKey("macro", "圣言术：灵")
    end
    if spell("圣言术：静", "usable") and Serenity then
        return UnitKey(Serenity, "圣言术：静")
    end
    if spell("治疗祷言", "usable") and casting ~= "治疗祷言" and PrayerCount >= set.PrayerCount then
        return UnitKey("macro", "治疗祷言")
    end
    if spell("治疗术", "usable") and casting ~= "治疗术" and player.buff["织光者"] and Heal then
        return UnitKey(Heal, "治疗术")
    end
    if spell("快速治疗", "usable") and casting ~= "快速治疗" and Flash then
        return UnitKey(Flash, "快速治疗")
    end
end

if player.isCombat and set.Attack and target.canAttack and inRange then
    if spell("暗言术：痛", "usable") and not target.debuff["暗言术：痛"] then
        return UnitKey("target", "暗言术：痛")
    end
    if spell("神圣之火", "usable") then
        return UnitKey("target", "神圣之火")
    end
    if spell("圣言术：罚", "usable") then
        return UnitKey("target", "圣言术：罚")
    end
    if spell("惩击", "usable") then
        return UnitKey("target", "惩击")
    end
end

return UnitKey("macro", "None")
