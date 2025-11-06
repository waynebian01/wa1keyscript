if aura_env.initialization == false then return end
local e = aura_env
local player = WK.PlayerInfo
local target = WK.TargetInfo
local spell = WK.getSpellArguments
local talents = player.talent
local UnitKey = e.UnitKey
local channel = UnitChannelInfo("player")
local casting = UnitCastingInfo("player")
local echo = C_Spell.IsSpellUsable(364343) -- 回响可用
local isPlayer = e.getPlayer()

local set = e.config
local lowestUnit = e.getLowestUnit(100)
local hasDream_lowest = e.getLowestUnit(100, "梦境吐息")
local noReversion_lowest = e.getLowestUnit(90, "逆转", "HELPFUL", false)
local noEcho_lowest = e.getLowestUnit(100, "回响", "HELPFUL", false)
local hasEchoCount = e.getCount(5, 120, "回响")
local dreamBreathCount = e.getCount(set.DreamBreathCount, set.DreamBreath)
local StasisCount = e.getCount(set.StasisCount, set.Stasis)

if channel == "梦境吐息" then
    return UnitKey("macro", "梦境吐息")
end

if channel == "精神之花" and player.empower >= 3 then
    return UnitKey("macro", "精神之花")
end

if channel then return UnitKey("macro", "None") end

if player.buff["静滞"] and player.buff["静滞"].spellId == 370537 then -- 储存技能
    if spell("梦境吐息", "usable") then
        return UnitKey("macro", "梦境吐息")
    end
    if spell("焚身", "usable") and hasDream_lowest then
        return UnitKey(isPlayer, "焚身")
    end
end

if player.buff["静滞"] and player.buff["静滞"].spellId == 370562 and player.buff["静滞"].expirationTime <= GetTime() + 3 then
    if spell("青翠之拥", "usable") then
        return UnitKey(isPlayer, "青翠之拥")
    end
    return UnitKey("macro", "静滞")
end

if StasisCount then
    if player.buff["静滞"] and player.buff["静滞"].spellId == 370562 and player.buff["伊瑟拉之唤"] then -- 释放技能
        return UnitKey("macro", "静滞")
    end
    if spell("梦境吐息", "usable") and spell("焚身", "usable") and spell("静滞", "usable") and not player.buff["静滞"] then
        if spell("青翠之拥", "usable") then
            return UnitKey(isPlayer, "青翠之拥")
        end
        if player.buff["伊瑟拉之唤"] then
            return UnitKey("macro", "静滞")
        end
    end
end

if spell("焚身", "usable") and not (player.buff["静滞"] and player.buff["静滞"].spellId == 370537) then
    if player.buff["梦境吐息"] and dreamBreathCount then
        if spell("静滞", "cooldown") > 40 then
            return UnitKey(isPlayer, "焚身")
        end
        if spell("焚身", "charges") == 2 then
            if spell("静滞", "cooldown") > 20 then
                return UnitKey(isPlayer, "焚身")
            end
            if spell("梦境吐息", "cooldown") > 20 then
                return UnitKey(isPlayer, "焚身")
            end
        end
    end
end

if spell("梦境吐息", "usable") and dreamBreathCount then
    if spell("青翠之拥", "usable") then
        return UnitKey(isPlayer, "青翠之拥")
    end
    return UnitKey("macro", "梦境吐息")
end

if player.buff["精华迸发"] and not spell("梦境吐息", "usable") and e.getCount(5, 70) then
    return UnitKey(lowestUnit, "翡翠之花")
end

if echo and noEcho_lowest then
    return UnitKey(noEcho_lowest, "回响")
end

if spell("时空畸体", "usable") and player.isCombat then
    return UnitKey("macro", "时空畸体")
end

if spell("精神之花", "usable") and not spell("梦境吐息", "usable") and not spell("焚身", "usable") and e.getCount(3, 70) then
    return UnitKey("macro", "精神之花")
end

if spell("逆转", "usable") and hasEchoCount and noReversion_lowest then
    return UnitKey(noReversion_lowest, "逆转")
end

if set.Attack and player.isCombat then
    if target.canAttack then
        return UnitKey("macro", "输出")
    else
        return UnitKey("macro", "上个敌人")
    end
end

return UnitKey("macro", "None")
