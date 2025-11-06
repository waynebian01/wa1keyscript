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

local damageUnit     = e.DamageUnit()
local noR_lowestUnit = e.getLowestUnit(100, "救赎", "HELPFUL", false)
local renew          = e.getCount(set.RenewCount, 95, "恢复", "HELPFUL", false)

if channel then return UnitKey("macro", "None") end

if talents["熵能裂隙"] then
    if player.isCombat then
        if hekili == 10060 and damageUnit then
            return UnitKey(damageUnit, "能量灌注")
        end
        if spell("福音", "usable") and e.getCount(5, 85, "福音") then
            return UnitKey("macro", "福音")
        end
        if spell("真言术：耀", "usable") then
            if casting == "真言术：耀" then
                if e.getCount(set.VWShineCount + 5, 95, "救赎", "HELPFUL", false) then
                    return UnitKey(noR_lowestUnit, "真言术：耀")
                end
            else
                if e.getCount(set.VWShineCount, 95, "救赎", "HELPFUL", false) then
                    return UnitKey(noR_lowestUnit, "真言术：耀")
                end
            end
        end
        if spell("纯净术", "usable") then
            if WK.RaidDebuffUnit then
                return UnitKey(WK.RaidDebuffUnit, "纯净术")
            end
        end
        if spell("真言术：盾", "usable") then
            if noR_lowestUnit then
                return UnitKey(noR_lowestUnit, "真言术：盾")
            end
        end

        if spell("快速治疗", "usable") and player.buff["圣光涌动"] then
            if noR_lowestUnit then
                return UnitKey(noR_lowestUnit, "快速治疗")
            end
        end

        if spell("恢复", "usable") and not renew and noR_lowestUnit then
            return UnitKey(noR_lowestUnit, "恢复")
        end

        if target.canAttack and inRange then
            return UnitKey("macro", "输出")
        else
            return UnitKey("macro", "上个敌人")
        end
    end
    return UnitKey("macro", "None")
end
