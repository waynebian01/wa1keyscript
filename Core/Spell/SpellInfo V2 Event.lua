-- SPELL_UPDATE_COOLDOWN,SPELL_UPDATE_CHARGES,PLAYER_TALENT_UPDATE,TRAIT_CONFIG_UPDATED,PLAYER_ENTERING_WORLD,GLYPH_ADDED,GLYPH_REMOVED,GLYPH_UPDATED

function Skippy.Event(event, arg1, arg2, arg3)
    if event == "SPELL_UPDATE_COOLDOWN" and arg1 then
        aura_env.UpdateSpellCooldown(arg1)
    elseif event == "SPELL_UPDATE_CHARGES" then
        aura_env.UpdateSpellCharges()
    elseif event == "PLAYER_TALENT_UPDATE" then
        aura_env.GetSpellBookInfo()
        aura_env.GetTalentInfo()
    elseif event == "TRAIT_CONFIG_UPDATED" then
        aura_env.GetSpellBookInfo()
        aura_env.GetTalentInfo()
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            aura_env.GetSpellBookInfo()
            aura_env.GetTalentInfo()
        end)
    elseif event == "GLYPH_ADDED" then
        aura_env.GetGlyphInfo()
    elseif event == "GLYPH_REMOVED" then
        aura_env.GetGlyphInfo()
    elseif event == "GLYPH_UPDATED" then
        aura_env.GetGlyphInfo()
    end
end
