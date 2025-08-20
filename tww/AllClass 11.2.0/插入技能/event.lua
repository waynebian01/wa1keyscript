function WAdeletethis(event, unit, castGUID, spellID)
    local e = aura_env
    if not Wa1Key or not Wa1Key.Prop then return end
    if event == "UNIT_SPELLCAST_FAILED" and unit == "player" then
        local hekilispell = HekiliDisplayPrimary.Recommendations[1].actionID
        if e.spellkey[spellID] and hekilispell ~= spellID then
            local spellIsUsable = e.spellIsUsable(spellID)
            if e.spellkey[spellID].icon then
                e.iconID = e.spellkey[spellID].icon
            else
                e.iconID = 135662
            end
            if spellIsUsable then
                C_Timer.After(3, function()
                    Wa1Key.Prop.insert = 0
                    WeakAuras.ScanEvents("MY_CUSTOM_TRIGGER_UPDATE")
                end)
                Wa1Key.Prop.insert = e.spellkey[spellID].keycode
                return true
            end
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
        if e.spellkey[spellID] then
            Wa1Key.Prop.insert = 0
            return false
        end
    end
    if event == "MY_CUSTOM_TRIGGER_UPDATE" then
        -- 自定义事件处理，返回 false 以停用触发器
        return false
    end
end
