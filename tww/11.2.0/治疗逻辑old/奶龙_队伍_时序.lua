if aura_env.initialization == false then return end
local e = aura_env
local player = WK.PlayerInfo
local target = WK.TargetInfo
local spell = WK.getSpellArguments
local talents = player.talent
local UnitKey = e.UnitKey
local channel = UnitChannelInfo("player")
local aoeisComeing = WK.AoeIsComeing
local echo = C_Spell.IsSpellUsable(364343) -- 回响可用
local essence = player.Essence

local set = e.config
local hasEchoCount = e.getCount(120, "回响")
local hasReversionCount = e.getCount(120, "逆转")
local noReversion_lowestUnit = e.getLowestUnit(90, "逆转", "HELPFUL", false)
local noEcho_lowestUnit = e.getLowestUnit(100, "回响", "HELPFUL", false)
local lowestUnit = e.getLowestUnit(100)

if channel == "精神之花" and (player.empower >= e.getCount(90) or player.empower >= 3) then
    return UnitKey("macro", "精神之花")
end

if channel == "梦境吐息" then
    return UnitKey("macro", "梦境吐息")
end

if channel == "火焰吐息" then
    return UnitKey("macro", "输出")
end

if channel then return UnitKey("macro", "None") end

if spell("时空畸体", "usable") then
    if hasEchoCount == 0 then
        return UnitKey("macro", "时空畸体")
    else
        if player.buff["生命火花"] and lowestUnit then
            return UnitKey(lowestUnit, "活化烈焰")
        end
        if spell("精神之花", "usable") then
            return UnitKey("macro", "精神之花")
        end
    end
    return UnitKey("macro", "时空畸体")
end

if spell("翡翠之花", "usable") and player.buff["精华迸发"] and e.getCount(80) >= 2 then
    return UnitKey(lowestUnit, "翡翠之花")
end

if spell("逆转", "usable") and e.getLowestUnit(40) then
    return UnitKey(lowestUnit, "逆转")
end

if player.buff["生命火花"] and lowestUnit then
    return UnitKey(lowestUnit, "活化烈焰")
end

if spell("精神之花", "usable") and e.getCount(80) >= 2 then
    return UnitKey("macro", "精神之花")
end

if spell("梦境吐息", "usable") and e.getCount(90) >= set.DreamBreathCount then
    if spell("青翠之拥", "usable") then
        return UnitKey("player", "青翠之拥")
    end
    return UnitKey("macro", "梦境吐息")
end

if echo and noEcho_lowestUnit then
    return UnitKey(noEcho_lowestUnit, "回响")
end

if spell("逆转", "usable") and spell("梦境吐息", "cooldown") > 10 and noReversion_lowestUnit then
    return UnitKey(noReversion_lowestUnit, "逆转")
end

if spell("活化烈焰", "usable") and e.getLowestUnit(80) then
    return UnitKey(lowestUnit, "活化烈焰")
end

if set.Attack and player.isCombat and target.canAttack then
    return UnitKey("macro", "输出")
end

return UnitKey("macro", "None")
