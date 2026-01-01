-- CLEU:UNIT_DIED
function Unitinfo_event_combatlog(event, timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags,
                                  sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    if subEvent == "UNIT_DIED" and (Skippy.state.inParty or Skippy.state.inRaid) then
        for k, v in pairs(Skippy.Group) do
            if v.GUID == destGUID then
                v.isDead = true
            end
        end
    end
end
