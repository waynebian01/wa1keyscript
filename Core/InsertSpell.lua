function Insert(event, unit, castGUID, spellID)
    if not Skippy or not Skippy.spellkey or not Wa1Key or not Wa1Key.Prop then return end
    if event == "UNIT_SPELLCAST_FAILED" and unit == "player" then
        local spellname = C_Spell.GetSpellName(spellID)
        if Skippy.spellkey[spellID] and aura_env.config[spellname] then
            local spellIsUsable = Skippy.IsUsableSpell(spellID)
            aura_env.insert = Skippy.spellkey[spellID]
            if spellIsUsable then
                Wa1Key.Prop.insert = Skippy.spellkey[spellID].keycode
                C_Timer.After(3, function()
                    aura_env.insert = nil
                    Wa1Key.Prop.insert = 0
                    return false
                end)
                return true
            end
        end
    end
    if (event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_SUCCEEDED") and unit == "player" then
        local spellname = C_Spell.GetSpellName(spellID)
        if Skippy.spellkey[spellID] and aura_env.config[spellname] then
            Wa1Key.Prop.insert = 0
            aura_env.insert = nil
            return false
        end
    end
end
