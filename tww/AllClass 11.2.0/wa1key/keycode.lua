local assisted = {
    [205636] = true, -- 自然之力(树人)
    [46565] = true,  -- 枯萎凋零
    [152280] = true, -- 亵渎
    [190356] = true, -- 暴风雪
    [153561] = true, -- 流星
    [2120] = true,   -- 烈焰风暴
    [368847] = true, -- 火焰风暴
}
local validSkills = {
    [2823] = true,   --夺命药膏
    [3408] = true,   --减速药膏
    [5761] = true,   --迟钝药膏
    [8679] = true,   --致伤药膏
    [315584] = true, --速效药膏
    [381637] = true, --萎缩药膏
    [381664] = true, --增效药膏

    [462854] = true, -- 天怒
    [382021] = true, -- 大地生命武器
    [974] = true,    -- 大地之盾
    [52127] = true,  -- 水之护盾
    [192106] = true, -- 闪电之盾

    [1126] = true,   -- 野性印记
    [381749] = true, -- 青铜龙的祝福
    [1459] = true,   -- 奥术智慧
    [21562] = true,  -- 真言术：韧
    [6673] = true,   -- 战斗怒吼
    [883] = true,    -- 召唤宠物1
    [46584] = true,  -- 亡者复生
    --[5215] = true,   -- 潜行（猫）
}
local keymap = {
    -- 数字键 1-9,功能键 F1-F12, 字母键 A-Z, 数字键盘 0-9, 特殊键 Space, [, ], \, ;, ', ,, ., /
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["0"] = 10,
    ["-"] = 11,
    ["="] = 12,

    -- 功能键 F1-F12
    ["F1"] = 13,
    ["F2"] = 14,
    ["F3"] = 15,
    ["F4"] = 16,
    ["F5"] = 17,
    ["F6"] = 18,
    ["F7"] = 19,
    ["F8"] = 20,
    ["F9"] = 21,
    ["F10"] = 22,
    ["F11"] = 23,
    ["F12"] = 24,

    -- 字母键
    ["Q"] = 81,
    ["W"] = 87,
    ["E"] = 69,
    ["R"] = 82,
    ["T"] = 84,
    ["Y"] = 89,
    ["U"] = 85,
    ["I"] = 73,
    ["O"] = 79,
    ["P"] = 80,
    ["A"] = 65,
    ["S"] = 83,
    ["D"] = 68,
    ["F"] = 70,
    ["G"] = 71,
    ["H"] = 72,
    ["J"] = 74,
    ["K"] = 75,
    ["L"] = 76,
    ["Z"] = 90,
    ["X"] = 88,
    ["C"] = 67,
    ["V"] = 86,
    ["B"] = 66,
    ["N"] = 78,
    ["M"] = 77,

    -- 数字键盘
    ["N0"] = 25,
    ["N1"] = 26,
    ["N2"] = 27,
    ["N3"] = 28,
    ["N4"] = 29,
    ["N5"] = 30,
    ["N6"] = 31,
    ["N7"] = 32,
    ["N8"] = 33,
    ["N9"] = 34,
    ["N*"] = 35,
    ["N+"] = 36,
    ["N-"] = 37,
    ["N."] = 38,
    ["N/"] = 39,

    -- 特殊键
    ["Space"] = 40,
    ["["] = 41,
    ["]"] = 42,
    ["\\"] = 43,
    [";"] = 44,
    ["'"] = 45,
    [","] = 46,
    ["."] = 47,
    ["/"] = 48
}

local channel, _, _, startTimeMS, _, _, _, _, isEmpowered = UnitChannelInfo("player")
if not Hekili then
    Hekili = 0
    print("没有安装Hekili,请安装或启用Hekili插件")
    return 0
end
if Hekili == 0 then
    return 0
end
local recommendation = HekiliDisplayPrimary.Recommendations[1]
local actionID = recommendation.actionID
local list = recommendation.list

local assistedID = C_AssistedCombat.GetNextCastSpell()
local keybind = keymap[recommendation.keybind]
local delay = recommendation.delay
local wait = recommendation.wait
if list and list == "item" then
    return 254
end
if assistedID and assisted[assistedID] then
    return 110
end
if keybind then
    if validSkills[actionID] then
        Wa1Key.Prop.validSkills = 1
    else
        Wa1Key.Prop.validSkills = 0
    end
    if channel then
        if isEmpowered then
            local channeltime = GetTime() - (startTimeMS / 1000)
            if channeltime > recommendation.time then
                return keybind
            else
                return 0
            end
        else
            if delay == 0 then
                return keybind
            else
                return 0
            end
        end
    end
    if wait < 200 then
        return keybind
    else
        return 0
    end
    return keybind
end

return 0
