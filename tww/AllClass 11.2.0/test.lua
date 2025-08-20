local getRange = {
    { 5,   37727 },
    { 6,   63427 },
    { 8,   34368 },
    { 10,  32321 },
    { 15,  33069 },
    { 20,  10645 },
    { 25,  24268 },
    { 30,  835 },
    { 35,  24269 },
    { 40,  28767 },
    { 45,  23836 },
    { 50,  116139 },
    { 60,  32825 },
    { 70,  41265 },
    { 80,  35278 },
    { 100, 33119 },
}

local function isUnitInRange(unit, range)
    for _, rangeData in ipairs(getRange) do
        local maxRange, itemID = unpack(rangeData)
        if maxRange == range then
            return C_Item.IsItemInRange(itemID, unit)
        end
    end
    return false
end

aura_env.isUnitInRange = isUnitInRange
