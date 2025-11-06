local channel = UnitChannelInfo("player")
if not Hekili or not HekiliDisplayPrimary then return end

local rec = HekiliDisplayPrimary.Recommendations[1]
local actionID = rec.actionID
local currentTime = GetTime()

local assistedID = C_AssistedCombat.GetNextCastSpell()
local keybind = aura_env.keymap[rec.keybind]

local waitTime = 0.4

if channel then
    waitTime = 0.2
end

if not channel then
    if actionID and actionID < 0 then
        Wa1Key.Prop.keycode = 254 -- 饰品
        return true
    end
    if assistedID and aura_env.assisted[assistedID] then
        Wa1Key.Prop.keycode = 253 -- 一键辅助
        return true
    end
end

if keybind then
    if rec.exact_time then
        if rec.exact_time - currentTime <= waitTime then
            Wa1Key.Prop.keycode = keybind
            return true
        else
            Wa1Key.Prop.keycode = 0
            return true
        end
    end
end

Wa1Key.Prop.keycode = 0

return true
