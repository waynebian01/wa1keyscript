if aura_env.initialization == false then return end
local e                = aura_env
local player           = WK.PlayerInfo
local target           = WK.TargetInfo
local spell            = WK.getSpellArguments
local talents          = player.talent
local UnitKey          = e.UnitKey
local casting          = UnitCastingInfo("player")
local hekili           = Hekili_GetRecommendedAbility("Primary", 1) -- 获取Hekili推荐技能
local aoeisComeing     = WK.AoeIsComeing
local aoeRemaining     = aoeisComeing and aoeisComeing - GetTime()  -- 团队AOE即将在到来的剩余时间
local inRange          = C_Spell.IsSpellInRange(275773, "target")   -- 审判
local inMeleeRange     = C_Spell.IsSpellInRange(35395, "target")    -- 十字军打击
local righteous        = C_Spell.IsSpellUsable(415091)              -- 盾击可用

local set              = e.config
local holyShockUnit    = e.getLowestUnit(set.HolyShock)     -- 神圣震击
local flashUnit        = e.getLowestUnit(set.Flash)         -- 圣光闪现
local flashInfusion    = e.getLowestUnit(set.FlashInfusion) -- 圣光闪现(圣光灌注)
local lowestUnit       = e.getLowestUnit(100)
local noDawnlightUnit  = e.noDawnlight_Unit(set.EternalFlame)
local eternalFlameUnit = e.getLowestUnit(set.EternalFlame)

if hekili == 96231 and inMeleeRange then
    return UnitKey("macro", "输出")
end

if spell("清洁术", "usable") then
    if set.DisperseFriend and target.canAssist then
        if target.hasMagic then
            return UnitKey("target", "清洁术")
        end
        if talents["强化清洁术"] then
            if target.hasDisease or target.hasPoison then
                return UnitKey("target", "清洁术")
            end
        end
    end
    if set.Disperse then
        if WK.debuffPlayer then
            return UnitKey("player", "清洁术")
        end
        if WK.debuffMintimeUnit then
            return UnitKey(WK.debuffMintimeUnit, "清洁术")
        end
        if WK.hasMagicUnit then
            return UnitKey(WK.hasMagicUnit, "清洁术")
        end
        if talents["强化清洁术"] then
            if WK.hasDiseaseUnit then
                return UnitKey(WK.hasDiseaseUnit, "清洁术")
            end
            if WK.hasPoisonUnit then
                return UnitKey(WK.hasPoisonUnit, "清洁术")
            end
        end
        if WK.hasDebuffUnit then
            return UnitKey(WK.hasDebuffUnit, "清洁术")
        end
    end
end
if talents["美德道标"] and spell("美德道标", "usable") then
    if e.getCount(set.Virtue) >= set.VirtueCount or aoeisComeing then
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
end

if spell("神圣棱镜", "usable") and target.canAttack and e.getCount(set.Prism) >= set.PrismCount then
    return UnitKey("macro", "神圣棱镜")
end

if spell("圣洁鸣钟", "usable") and e.getCount(set.DivineToll) >= set.DivineTollCount then
    return UnitKey("macro", "圣洁鸣钟")
end

if spell("仲夏祝福", "usable") then
    local overrideSpellID = C_Spell.GetOverrideSpell(388007)
    if player.isCombat then
        if overrideSpellID == 388007 and e.DamageUnit() and player.inCombatTime > 5 then
            return UnitKey(e.DamageUnit(), "仲夏祝福")
        end
        if overrideSpellID == 388010 then -- 暮秋祝福
            return UnitKey("player", "仲夏祝福")
        end
        if overrideSpellID == 388013 then -- 阳春祝福
            return UnitKey("player", "仲夏祝福")
        end
    end
    if overrideSpellID == 388011 then -- 凛冬祝福
        return UnitKey("player", "仲夏祝福")
    end
end

if spell("圣光闪现", "usable") and player.buff["圣光灌注"] and flashInfusion then
    return UnitKey(flashInfusion, "圣光闪现")
end

if player.HolyPower >= 3 or player.buff["神圣意志"] or (player.buff["闪耀正义"] and player.buff["闪耀正义"].spellId == 414445) then
    if noDawnlightUnit then
        return UnitKey(noDawnlightUnit, "荣耀圣令")
    end
    if eternalFlameUnit then
        return UnitKey(eternalFlameUnit, "荣耀圣令")
    end
end

if player.HolyPower == 5 then
    if talents["闪耀正义"] and righteous and target.canAttack then
        return UnitKey("target", "正义盾击")
    else
        if lowestUnit then
            return UnitKey(lowestUnit, "荣耀圣令")
        end
    end
end

if spell("神圣震击", "usable") and holyShockUnit then
    return UnitKey(holyShockUnit, "神圣震击")
end

if spell("圣光闪现", "usable") and flashUnit then
    return UnitKey(flashUnit, "圣光闪现")
end

if player.isCombat and target.canAttack and inRange then
    if spell("愤怒之锤", "usable") and target.healthPct <= 20 then
        return UnitKey("target", "愤怒之锤")
    end
    if spell("审判", "usable") then
        return UnitKey("target", "审判")
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
end

return UnitKey("macro", "None")
