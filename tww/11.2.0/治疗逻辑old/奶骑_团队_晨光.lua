if aura_env.initialization == false then return end
local e                = aura_env
local player           = WK.PlayerInfo
local target           = WK.TargetInfo
local spell            = WK.getSpellArguments
local talents          = player.talent
local UnitKey          = e.UnitKey
local casting          = UnitCastingInfo("player")
local inRange          = C_Spell.IsSpellInRange(275773, "target") -- 审判
local inMeleeRange     = C_Spell.IsSpellInRange(35395, "target")  -- 十字军打击
local righteous        = C_Spell.IsSpellUsable(415091)            -- 盾击可用

local set              = e.config
local lowestUnit       = e.getLowestUnit(100)
local holyShockUnit    = e.getLowestUnit(set.HolyShock)     -- 神圣震击
local flashUnit        = e.getLowestUnit(set.Flash)         -- 圣光闪现
local flashInfusion    = e.getLowestUnit(set.FlashInfusion) -- 圣光闪现(圣光灌注)
local noDawnlightUnit  = e.noDawnlight_Unit(set.EternalFlame)
local eternalFlameUnit = e.getLowestUnit(set.EternalFlame)
local averageHealth    = e.averageHealth()
local focus            = e.getFocus()
local isPlayer         = e.getPlayer()

if player.isCombat then
    if spell("清洁术", "usable") then
        if WK.RaidDebuffUnit then
            return UnitKey(WK.RaidDebuffUnit, "纯净术")
        end
    end
    if spell("仲夏祝福", "usable") then
        local overrideSpellID = C_Spell.GetOverrideSpell(388007)
        if overrideSpellID == 388007 then
            if UnitExists("focus") then
                return UnitKey(focus, "仲夏祝福")
            else
                return UnitKey(e.DamageUnit(), "仲夏祝福")
            end
        end
        if overrideSpellID == 388011 or overrideSpellID == 388010 or overrideSpellID == 388013 then -- 凛冬祝福
            return UnitKey(isPlayer, "仲夏祝福")
        end
    end
end

if talents["美德道标"] and spell("美德道标", "usable") and e.getCount(set.VirtueCount, set.Virtue) then
    if set.HolyLight then
        if casting == "圣光术" then
            return UnitKey("macro", "美德道标")
        else
            return UnitKey(lowestUnit, "圣光术")
        end
    else
        if player.buff["圣光灌注"] then
            if casting == "圣光闪现" then
                return UnitKey("macro", "美德道标")
            else
                return UnitKey(lowestUnit, "圣光闪现")
            end
        else
            return UnitKey("macro", "美德道标")
        end
    end
end

if player.buff["觉醒"] and player.buff["觉醒"].spellId == 414193 then
    if target.canAttack and inRange then
        return UnitKey("target", "审判")
    else
        return UnitKey("macro", "上个敌人")
    end
end

if spell("复仇之怒", "usable") and not player.buff["复仇之怒"] and averageHealth <= set.Avenging then
    return UnitKey("macro", "复仇之怒")
end

if player.isCombat then
    if spell("神圣棱镜", "usable") and e.getCount(set.PrismCount, set.Prism) then
        if target.canAttack and inRange then
            return UnitKey("target", "神圣棱镜")
        else
            return UnitKey("macro", "上个敌人")
        end
    end
    if player.buff["崇圣"] and spell("愤怒之锤", "usable") then
        if target.canAttack and inRange then
            return UnitKey("target", "愤怒之锤")
        else
            return UnitKey("macro", "上个敌人")
        end
    end
end

if spell("圣洁鸣钟", "usable") and player.HolyPower <= 1 and e.getCount(set.DivineTollCount, set.DivineToll) then
    return UnitKey("macro", "圣洁鸣钟")
end


if player.HolyPower >= 3 or player.buff["神圣意志"] then
    if set.Dawn and spell("黎明之光", "usable") and player.buff["永恒圣光"] and player.buff["永恒圣光"].applications == 9 and eternalFlameUnit then
        return UnitKey("macro", "黎明之光")
    end
    if noDawnlightUnit then
        return UnitKey(noDawnlightUnit, "荣耀圣令")
    end
    if eternalFlameUnit then
        return UnitKey(eternalFlameUnit, "荣耀圣令")
    end
end

if spell("圣光闪现", "usable") and player.buff["圣光灌注"] and flashInfusion then
    return UnitKey(flashInfusion, "圣光闪现")
end

if player.HolyPower == 5 then
    if talents["闪耀正义"] and righteous then
        if target.canAttack then
            return UnitKey("target", "正义盾击")
        else
            return UnitKey("macro", "上个敌人")
        end
    else
        if lowestUnit then
            return UnitKey(lowestUnit, "荣耀圣令")
        end
    end
end

if spell("神圣震击", "usable") and holyShockUnit then
    return UnitKey(holyShockUnit, "神圣震击")
end

if casting ~= "圣光闪现" and spell("圣光闪现", "usable") and not player.buff["圣光灌注"] and flashUnit then
    return UnitKey(flashUnit, "圣光闪现")
end


if player.isCombat and player.HolyPower < 5 then
    if target.canAttack and inRange then
        if spell("愤怒之锤", "usable") and target.healthPct <= 20 then
            return UnitKey("target", "愤怒之锤")
        end
        if spell("十字军打击", "usable") and inMeleeRange then
            return UnitKey("target", "十字军打击")
        end
        if spell("神圣震击", "charges") == 2 then
            return UnitKey("target", "神圣震击")
        end
        if spell("奉献", "usable") and inMeleeRange then
            return UnitKey("target", "奉献")
        end
    else
        return UnitKey("macro", "上个敌人")
    end
end

return UnitKey("macro", "None")
