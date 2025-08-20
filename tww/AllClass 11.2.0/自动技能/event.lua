function WAdeletethis(event, arg1, arg2, arg3)
    local e = aura_env
    if arg1 == "player" then
        local darkAssist = AuraUtil.FindAuraByName("黑暗援助", arg1, "HELPFUL|PLAYER")
        local victoryRush = AuraUtil.FindAuraByName("胜利", arg1, "HELPFUL|PLAYER")
        local Blooming = e.hasAura(arg1, 429438)
        local healthPCT = UnitHealth("player") / UnitHealthMax("player")

        if healthPCT and healthPCT <= 0.75 then
            if darkAssist then
                return e.autospell(49998)
            end
            if victoryRush then
                return e.autospell(34428)
            end
            if Blooming then
                return e.autospell(8936)
            end
            if e.spellIsUsable(108238) then
                return e.autospell(108238)
            end
            if e.spellIsUsable(202168) then
                return e.autospell(202168)
            end
            if e.spellIsUsable(185311) then -- 盗贼 猩红之瓶
                return e.autospell(185311)
            end
        end
        return e.autospell(nil)
    end
end
