local e = aura_env
if e.initialization then
    e.updateUnitRange()  -- 更新单位距离
    e.updateCooldown()   -- 更新技能冷却
    e.updateRaidStatus() -- 更新团队状态
end
