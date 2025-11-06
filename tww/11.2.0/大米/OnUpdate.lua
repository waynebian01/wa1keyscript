-- 检测施法情况，返回剩余时间（毫秒）
local function checkCasting(spellList)
    local minTimeLeftMs = nil
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) then
            local _, _, _, startTimeMS, endTimeMS, _, _, _, spellId = UnitCastingInfo(unit)
            if spellId and spellList[spellId] then
                local timeLeftMs = endTimeMS - (GetTime() * 1000) -- 转换为毫秒
                if timeLeftMs > 0 and (minTimeLeftMs == nil or timeLeftMs < minTimeLeftMs) then
                    minTimeLeftMs = timeLeftMs
                end
            end
        end
    end
    return minTimeLeftMs
end

aoeisComeing = checkCasting(aura_env.AOESpellList)
InterruptRemainingMs = checkCasting(aura_env.InterruptSpellList)
