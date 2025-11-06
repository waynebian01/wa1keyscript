if not Skippy and not Skippy.Group then return end
for unit, data in pairs(Skippy.Group) do
    data.inRange = UnitInRange(unit)
end
