function aura_env.getChakraCooldown()
    local chakra = { 81209, 81208, 81206 } -- 脉轮：罚, 佑, 静 ; 共享冷却的技能
    local cooldown = 0
    for _, spellID in pairs(chakra) do
        local spellInfo = Skippy.GetSpellInfo(spellID)
        if spellInfo and spellInfo.cooldown and spellInfo.cooldown > 0 then
            if cooldown <= spellInfo.cooldown then
                cooldown = spellInfo.cooldown
            end
        end
    end
    return cooldown
end
