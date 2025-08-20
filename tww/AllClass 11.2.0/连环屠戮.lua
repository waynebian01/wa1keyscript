local counter = 0
local function hasAura(auraName, unit, filter)
    return AuraUtil.FindAuraByName(auraName, unit, filter) ~= nil
end
for i = 1, 40 do
    local unit = "nameplate" .. i
    if UnitExists(unit) and UnitCanAttack("player", unit) and C_Item.IsItemInRange(32321, unit) then
        if not hasAura("锁喉", unit, "HARMFUL|PLAYER") and hasAura("连环屠戮", "player", "HELPFUL|PLAYER") then
            counter = counter + 1
        end
    end
end

return counter
