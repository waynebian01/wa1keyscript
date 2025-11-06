local Go = Prop("Go")
local heal = Prop("heal")
local keycode = Prop("keycode")
local insert = Prop("insert")
local autospell = Prop("autospell")

if Go == 255 then
    return
end

if insert > 0 then
    PressKey(insert)
    return
end

if Go == 254 then
    Cast("38")
    return
end

if Go == 1 then
    if heal ~= 0 then
        Cast(tostring(heal))
        return
    end

    if keycode == 254 then
        Cast("40")
        return
    end

    if keycode ~= 255 then
        PressKey(keycode)
        return
    end
end
