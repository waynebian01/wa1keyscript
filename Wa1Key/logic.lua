local Go = Prop("Go")
local heal = "s" .. tostring(Prop("heal"))
local keycode = Prop("keycode")
local insert = Prop("insert")
local press = Prop("press")
local autospell = Prop("autospell")

if Go == 255 then
    return
end

if insert > 0 then
    PressKey(insert)
    return
end

if Go == 254 then
    Cast("s52")
    return
end

if Go == 1 then
    if Prop("heal") ~= 0 then
        Cast(heal)
        return
    end

    if press ~= 255 then
        PressKey(press)
        return
    end

    if keycode ~= 255 then
        PressKey(keycode)
        return
    end
end
