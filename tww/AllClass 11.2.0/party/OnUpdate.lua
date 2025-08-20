local e = aura_env
if e.initialization then
    e.updateUnitRange()     -- 更新单位距离
    e.updateCooldown()      -- 更新技能冷却
    e.updatePartyValidity() -- 队友是否有效
    e.updatePartyDamage()   -- 更新队伍伤害
end
