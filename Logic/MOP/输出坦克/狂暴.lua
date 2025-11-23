if not Skippy or not Skippy.Units or not Skippy.state then return end
if Skippy.state.class ~= "战士" or Skippy.state.specID ~= 72 then return end

local enemyCount = Skippy.GetEnemyCount(8)
local target = Skippy.Units.target

if target.exists and target.canAttack then
    aura_env.info()
    if target.percentHealth < 20 then
        return Skippy.PressKey(aura_env.Execute())
    elseif enemyCount == 1 then
        return Skippy.PressKey(aura_env.SingleTarget())
    elseif enemyCount >= 2 then
        return Skippy.PressKey(aura_env.MultiTarget())
    end
    return Skippy.PressKey("None")
end

return Skippy.PressKey("None")
