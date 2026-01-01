local Go = Prop("Go")
local heal = "s" .. tostring(Prop("heal"))
local hekili = Prop("HekiliCode")
local insert = Prop("insert")
local press = Prop("press")
local autospell = Prop("autospell")
local fish = Prop("fish")
local follow = Prop("follow")

if Go == 255 then -- 什么也不做
    return
end

if insert > 0 then -- 插入技能
    PressKey(insert)
    return
end

if Go == 254 then -- 中断施法
    Cast("s52")
    return
end

if follow == 2 then -- 取消跟随
    Cast("stopfollow")
end
if follow == 1 then -- 跟随单位
    Cast("follow")
end

-- 治疗技能，1-46为选择单位，47及以上为施放技能
if Prop("heal") ~= 0 then
    Cast(heal)
    return
end

-- 可以对地方单位输出时Go=1，输出技能
if Go == 1 then
    if press ~= 0 then
        PressKey(press)
        return
    end

    if hekili == 254 then --饰品
        Cast("s48")
        return
    end

    if hekili ~= 0 then
        PressKey(hekili)
        return
    end
end

if fish == 2 then
    Cast("鱼饵")
    return
end

if fish == 1 then
    Cast("抛竿")
    return
end
