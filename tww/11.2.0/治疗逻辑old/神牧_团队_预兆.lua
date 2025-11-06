if aura_env.initialization == false then return end
local e                    = aura_env
local player               = WK.PlayerInfo
local target               = WK.TargetInfo
local spell                = WK.getSpellArguments
local talents              = player.talent
local UnitKey              = e.UnitKey
local channel              = UnitChannelInfo("player")
local casting              = UnitCastingInfo("player")
local premonitionID        = C_Spell.GetOverrideSpell(428924)
local inRange              = C_Spell.IsSpellInRange(585, "target")
local angle                = C_UnitAuras.GetPlayerAuraBySpellID(27827)

local set                  = e.config
local CircleCount          = e.getCount(set.PrayerCircleCount, set.PrayerCircleValue) -- 治疗祷言(分秒必争)数量
local PrayerCount          = e.getCount(set.PrayerCount, set.PrayerValue) -- 治疗祷言数量
local HaloCount            = e.getCount(set.HaloCount, set.HaloValue) -- 光晕数量
local SanctifyCount        = e.getCount(set.SanctifyCount, set.SanctifyValue) -- 圣言术：灵数量
local useMendingCount      = e.getCount(3, 80)
local Heal                 = e.getLowestUnit(set.Heal) -- 治疗术
local Flash                = e.getLowestUnit(set.Flash) -- 快速治疗
local Serenity             = e.getLowestUnit(set.Serenity) -- 圣言术：静
local lowestUnit80         = e.getLowestUnit(80) -- 生命值最低的单位80%
local noMending_Tank       = e.getLowestUnit(101, "愈合祷言", "HELPFUL", false, "TANK") -- 无愈合坦克
local noMending_LowestUnit = e.getLowestUnit(90, "愈合祷言", "HELPFUL", false) -- 无愈合生命值最低的单位
local noRenew_Tank         = e.getLowestUnit(101, "恢复", "HELPFUL", false, "TANK") -- 无恢复坦克
local noRenew_LowestUnit   = e.getLowestUnit(95, "恢复", "HELPFUL", false) -- 无恢复生命值最低的单位
local lowestUnit           = e.getLowestUnit(100) -- 生命值最低的单位

if channel then return UnitKey("macro", "None") end

if angle then
    if spell("愈合祷言", "usable") and noMending_LowestUnit then
        return UnitKey(noMending_LowestUnit, "愈合祷言")
    end
    if spell("恢复", "usable") and talents["恢复增效"] and noRenew_LowestUnit then
        return UnitKey(noRenew_LowestUnit, "恢复")
    end
    if talents["光晕"] and spell("光晕", "usable") and HaloCount then
        return UnitKey("macro", "光晕")
    end
    if spell("治疗祷言", "usable") and e.getCount(2, 90) then
        return UnitKey(lowestUnit, "治疗祷言")
    end
    if spell("快速治疗", "usable") and lowestUnit then
        return UnitKey(lowestUnit, "快速治疗")
    end
end

if spell("绝望祷言", "usable") and player.healthPct <= 50 then
    return UnitKey("macro", "绝望祷言")
end

if player.isCombat then
    if player.manaPct <= 90 then
        if spell("奥术洪流", "usable") then
            return UnitKey("macro", "奥术洪流")
        end
        if spell("暗影魔", "usable") then
            if target.canAttack and inRange then
                return UnitKey("macro", "暗影魔")
            else
                return UnitKey("macro", "上个敌人")
            end
        end
    end
    if player.healthPct <= 80 then
        if spell("渐隐术", "usable") then
            return UnitKey("macro", "渐隐术")
        end
        if talents["天使壁垒"] and not player.buff["防护圣光"] and casting ~= "快速治疗" then
            return UnitKey(e.getPlayer(), "快速治疗")
        end
        if spell("神圣新星", "usable") and player.buff["狂想曲"] and player.buff["狂想曲"].applications == 20 then
            return UnitKey("macro", "神圣新星")
        end
        if spell("快速治疗", "usable") and player.buff["圣光涌动"] then
            return UnitKey(e.getPlayer(), "快速治疗")
        end
    end

    if spell("纯净术", "usable") then
        if WK.RaidDebuffUnit then
            return UnitKey(WK.RaidDebuffUnit, "纯净术")
        end
    end
    if spell("神圣新星", "usable") and player.buff["狂想曲"] and player.buff["狂想曲"].applications == 20 then
        if target.canAttack and target.maxRange and target.maxRange <= 10 then
            return UnitKey("macro", "神圣新星")
        end
    end
    if set.Premonition and spell("预兆", "usable") and spell("愈合祷言", "usable") and useMendingCount and not player.buff["洞察预兆"] then
        if set.Keep1Premonition then
            if spell("预兆", "charges") == 2 then
                if set.Insight and premonitionID == 428933 then -- 洞察预兆
                    return UnitKey("macro", "预兆")
                end
                if set.Clairvoyance and premonitionID == 440725 then -- 远见预兆
                    return UnitKey("macro", "预兆")
                end
                if premonitionID == 428930 and e.averageHealth() <= set.Piety then -- 虔诚预兆
                    return UnitKey("macro", "预兆")
                end
                if premonitionID == 428934 and lowestUnit <= set.Solace then -- 慰藉预兆
                    return UnitKey("macro", "预兆")
                end
            end
        else
            if set.Insight and premonitionID == 428933 then -- 洞察预兆
                return UnitKey("macro", "预兆")
            end
            if set.Clairvoyance and premonitionID == 440725 then -- 远见预兆
                return UnitKey("macro", "预兆")
            end
            if premonitionID == 428930 and e.averageHealth() <= set.Piety then -- 虔诚预兆
                return UnitKey("macro", "预兆")
            end
            if premonitionID == 428934 and e.getLowestUnit(85) then -- 慰藉预兆
                return UnitKey("macro", "预兆")
            end
        end
    end
    if set.Apotheosis and spell("神圣化身", "usable") and e.averageHealth() <= set.ApotheosisValue then
        if spell("圣言术：静", "charges") < 2 and spell("圣言术：灵", "charges") < 2 then
            return UnitKey("macro", "神圣化身")
        end
    end
end

if spell("愈合祷言", "usable") then
    if lowestUnit80 then
        return UnitKey(lowestUnit80, "愈合祷言")
    end
    if noMending_LowestUnit then
        return UnitKey(noMending_LowestUnit, "愈合祷言")
    end
    if noMending_Tank then
        return UnitKey(noMending_Tank, "愈合祷言")
    end
end

if spell("恢复", "usable") and talents["恢复增效"] then
    if noRenew_LowestUnit then
        return UnitKey(noRenew_LowestUnit, "恢复")
    end
    if noRenew_Tank then
        return UnitKey(noRenew_Tank, "恢复")
    end
end

if spell("光晕", "usable") and HaloCount then
    return UnitKey("macro", "光晕")
end

if spell("治疗祷言", "usable") and player.buff["分秒必争"] and CircleCount then
    return UnitKey(lowestUnit, "治疗祷言")
end

if set.Sanctify and spell("圣言术：灵", "usable") then
    if SanctifyCount then
        if talents["祷言之环"] then
            if not player.buff["祷言之环"] then
                return UnitKey("macro", "圣言术：灵")
            end
        else
            return UnitKey("macro", "圣言术：灵")
        end
    end
    if talents["永恒圣洁"] and player.buff["神圣化身"] then
        if e.getCount(3, 90) then
            return UnitKey("macro", "圣言术：灵")
        end
    end
end

if spell("圣言术：静", "usable") then
    if talents["持久圣言"] then
        if Serenity then
            if noRenew_LowestUnit then
                return UnitKey(noRenew_LowestUnit, "圣言术：静")
            else
                return UnitKey(Serenity, "圣言术：静")
            end
        end
    else
        if Serenity then
            return UnitKey(Serenity, "圣言术：静")
        end
    end
end

if player.buff["圣洁"] then
    if spell("治疗祷言", "usable") and CircleCount then
        return UnitKey(lowestUnit, "治疗祷言")
    end
    if spell("治疗术", "usable") and Heal then
        return UnitKey(Heal, "治疗术")
    end
end

if spell("快速治疗", "usable") and player.buff["圣光涌动"] and Flash then
    return UnitKey(Flash, "快速治疗")
end

if spell("治疗祷言", "usable") and PrayerCount then
    if talents["祷言之环"] then
        if player.buff["祷言之环"] or not spell("圣言术：灵", "usable") then
            return UnitKey(lowestUnit, "治疗祷言")
        end
    else
        return UnitKey(lowestUnit, "治疗祷言")
    end
end

if spell("治疗术", "usable") and player.buff["织光者"] and Heal then
    return UnitKey(Heal, "治疗术")
end

if spell("恢复", "usable") and not talents["恢复增效"] then
    if noRenew_Tank then
        return UnitKey(noRenew_Tank, "恢复")
    end
    if noRenew_LowestUnit then
        return UnitKey(noRenew_LowestUnit, "恢复")
    end
end

if casting == "治疗祷言" or casting == "治疗术" or casting == "快速治疗" then
    return UnitKey("macro", "None")
end

if player.isCombat then
    if target.canAttack and inRange then
        if set.Attack then
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
    else
        return UnitKey("macro", "上个敌人")
    end
end

return UnitKey("macro", "None")
