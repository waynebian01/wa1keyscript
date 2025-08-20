function WA(event, unit, castGUID, spellID)
    if event == "UNIT_SPELLCAST_START" then
        local name, _, _, startTimeMS, endTimeMS = UnitCastingInfo(unit)
        if aura_env.AOESpellList[spellID] then
            aura_env.AoeInfo[castGUID] = {
                name = name,
                startTime = startTimeMS / 1000,
                endTime = endTimeMS / 1000,

            }
        end
    elseif event == "UNIT_SPELLCAST_STOP" then
        if aura_env.AOESpellList[spellID] then
            aura_env.AoeInfo[castGUID] = nil
        end
    end
end

function WAdeletethis()
    local e = aura_env
    local output = ""
    for k, v in pairs(e.AoeInfo) do
        output = output ..
            tostring(k) .. ": \n" ..
            tostring(v.name) .. " \n " ..
            tostring(v.startTime) .. " \n " ..
            tostring(v.endTime) .. " \n " ..
            tostring(v.duration) .. "\n"
    end
    for k, v in pairs(e.InterruptCastingTimes) do
        output = output ..
            tostring(k) .. ": \n" ..
            tostring(v.name) .. " \n " ..
            tostring(v.startTime) .. " \n " ..
            tostring(v.endTime) .. " \n " ..
            tostring(v.duration) .. "\n"
    end
    return output
end
