-- CLEU:UNIT_DIED, CLEU:SPELL_MISSED
function CLEU(event, timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID,
           destName, destFlags, destRaidFlags, ...)
    -- 处理单位死亡
    if subEvent == "UNIT_DIED" then
        for k, v in pairs(Skippy.Group) do
            if v.GUID == destGUID then
                print(k)
                v.isDead = UnitIsDeadOrGhost(k)
            end
        end
    end

    -- 处理技能免疫
    if subEvent == "SPELL_MISSED" then
        if sourceGUID == UnitGUID("player") and destGUID == UnitGUID("target") then
            -- 在 SPELL_MISSED 中，... 的第 1 个值是 spellId，第 4 个值是 missType
            local spellId, spellName, spellSchool, missType, isOffHand, amountMissed, critical = ...

            if missType == "IMMUNE" then
                local immuneTable = Skippy.Units["target"].immuneSpells
                local isAlreadyKnown = false
                for i = 1, #immuneTable do
                    if immuneTable[i] == spellId then
                        isAlreadyKnown = true
                        break
                    end
                end

                if not isAlreadyKnown then
                    table.insert(immuneTable, spellId)
                end
            end
        end
    end
end
