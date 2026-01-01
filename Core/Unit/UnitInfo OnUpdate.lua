if not Skippy then return end
if Skippy.Group then
    for unit, data in pairs(Skippy.Group) do
        data.inRange = UnitInRange(unit)
        data.canAssist = UnitCanAssist("player", unit)
    end
end
if Skippy.Nameplate then
    for unit, data in pairs(Skippy.Nameplate) do
        local minRange, maxRange = WeakAuras.GetRange(unit)
        data.minRange = minRange
        data.maxRange = maxRange
    end
end
