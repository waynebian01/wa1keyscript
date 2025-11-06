if aura_env.initialization == false then return end
local e              = aura_env
local player         = WK.PlayerInfo
local target         = WK.TargetInfo
local spell          = WK.getSpellArguments
local talents        = player.talent
local UnitKey        = e.UnitKey
local channel        = UnitChannelInfo("player")
local casting        = UnitCastingInfo("player")
local premonitionID  = C_Spell.GetOverrideSpell(428924)
local inRange        = C_Spell.IsSpellInRange(585, "target")
local hekili         = Hekili_GetRecommendedAbility("Primary", 1) -- 获取Hekili推荐技能
local set            = e.config

local lowestUnit     = e.getLowestUnit(100)
local noR_lowestUnit = e.getLowestUnit(100, "救赎", "HELPFUL", false)
local noS_lowestUnit = e.getLowestUnit(100, "真言术：盾", "HELPFUL", false)
local noS_Tank       = e.getLowestUnit(100, "真言术：盾", "HELPFUL", false, "TANK")


if channel then return UnitKey("macro", "None") end

if talents["预兆"] then
    if player.isCombat then
        if hekili == 10060 and e.DamageUnit() then
            return UnitKey(e.DamageUnit(), "能量灌注")
        end
        if spell("福音", "usable") and e.getCount(5, 85, "福音") then
            return UnitKey("macro", "福音")
        end
        if spell("真言术：耀", "usable") then
            if casting == "真言术：耀" then
                if e.getCount(set.OracleShineCount + 5, 95, "救赎", "HELPFUL", false) then
                    return UnitKey(noR_lowestUnit, "真言术：耀")
                end
            else
                if e.getCount(set.OracleShineCount, 95, "救赎", "HELPFUL", false) then
                    return UnitKey(noR_lowestUnit, "真言术：耀")
                end
            end
        end
        if spell("纯净术", "usable") then
            if WK.RaidDebuffUnit then
                return UnitKey(WK.RaidDebuffUnit, "纯净术")
            end
        end
        if player.buff["祸福相倚"] then
            if player.buff["祸福相倚"].applications < 4 then
                if spell("苦修", "usable") then
                    if target.canAttack and inRange then
                        return UnitKey("target", "苦修")
                    else
                        return UnitKey("macro", "上个敌人")
                    end
                end
            else
                if spell("真言术：盾", "usable") then
                    if e.getLowestUnit(40, "真言术：盾", "HELPFUL", false) then
                        return UnitKey(noS_lowestUnit, "真言术：盾")
                    end
                    if noR_lowestUnit then
                        return UnitKey(noR_lowestUnit, "真言术：盾")
                    end
                end
            end
        else
            if spell("苦修", "usable") then
                if target.canAttack and inRange then
                    return UnitKey("target", "苦修")
                else
                    return UnitKey("macro", "上个敌人")
                end
            end
        end
        if spell("快速治疗", "usable") and player.buff["圣光涌动"] and casting ~= "快速治疗" then
            if noR_lowestUnit then
                return UnitKey(noR_lowestUnit, "快速治疗")
            end
        end

        if player.buff["洞察预兆"] then
            if target.canAttack and inRange then
                if hekili ~= 585 and hekili ~= 589 then
                    return UnitKey("target", "惩击")
                end
            else
                return UnitKey("macro", "上个敌人")
            end
        end

        if player.buff["狂想曲"] and player.buff["狂想曲"].applications == 20 then
            if target.canAttack and target.maxRange and target.maxRange <= 10 then
                return UnitKey("macro", "神圣新星")
            end
        end

        if target.canAttack and inRange then
            return UnitKey("macro", "输出")
        else
            return UnitKey("macro", "上个敌人")
        end
    end
    return UnitKey("macro", "None")
end
