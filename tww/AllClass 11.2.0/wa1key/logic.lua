local keymap = {
    [1] = 0x31, -- 1
    [2] = 0x32, -- 2
    [3] = 0x33, -- 3
    [4] = 0x34, -- 4
    [5] = 0x35, -- 5
    [6] = 0x36, -- 6
    [7] = 0x37, -- 7
    [8] = 0x38, -- 8
    [9] = 0x39, -- 9
    [10] = 0x30, -- 10
    
    [13] = 0x70, -- F1
    [14] = 0x71, -- F2
    [15] = 0x72, -- F3
    [16] = 0x73, -- F4
    [17] = 0x74, -- F5
    [18] = 0x75, -- F6
    [19] = 0x76, -- F7
    [20] = 0x77, -- F8
    [21] = 0x78, -- F9
    [22] = 0x79, -- F10
    [23] = 0x7A, -- F11
    [24] = 0x7B, -- F12
    
    [81] = 0x51, -- Q
    [87] = 0x57, -- W
    [69] = 0x45, -- E
    [82] = 0x52, -- R
    [84] = 0x54, -- T
    [89] = 0x59, -- Y
    [85] = 0x55, -- U
    [73] = 0x49, -- I
    [79] = 0x4F, -- O
    [80] = 0x50, -- P
    [65] = 0x41, -- A
    [83] = 0x53, -- S
    [68] = 0x44, -- D
    [70] = 0x46, -- F
    [71] = 0x47, -- G
    [72] = 0x48, -- H
    [74] = 0x4A, -- J
    [75] = 0x4B, -- K
    [76] = 0x4C, -- L
    [90] = 0x5A, -- Z
    [88] = 0x58, -- X
    [67] = 0x43, -- C
    [86] = 0x56, -- V
    [66] = 0x42, -- B
    [78] = 0x4E, -- N
    [77] = 0x4D, -- M
    
    [25] = 0x60, -- N0
    [26] = 0x61, -- N1
    [27] = 0x62, -- N2
    [28] = 0x63, -- N3
    [29] = 0x64, -- N4
    [30] = 0x65, -- N5
    [31] = 0x66, -- N6
    [32] = 0x67, -- N7
    [33] = 0x68, -- N8
    [34] = 0x69, -- N9
    [35] = 0x6A, -- N*
    [36] = 0x6B, -- N+
    [37] = 0x6D, -- N-
    [38] = 0x6E, -- N.
    [39] = 0x6F, -- N/
    
    [40] = 0x20, -- Space
    [12] = 0xBB, -- =
    [11] = 0xBD, -- -
    [41] = 0xDB, -- [
    [42] = 0xDD, -- ]
    [43] = 0xDC, -- \
    [44] = 0xBA, -- ;
    [45] = 0xDE, -- '
    [46] = 0xBC, -- ,
    [47] = 0xBE, -- .
    [48] = 0xBF, -- /
}

local Go = Prop("Go")
local validSkills = Prop("validSkills")

local keycode = Prop("keycode")
local key = keymap[keycode]

local insert = Prop("insert")
local insertCode = keymap[insert]

local healing = Prop("healing")

local autospell = Prop("autospell")
local autospellcode = keymap[autospell]

if Go == 255 then
    return
end

if Prop("red") == 1 then
    Cast("49")
end
if Prop("stone") == 1 then
    Cast("50")
end

if insert > 0 then
    PressKey(insertCode)
    return
end

if Go == 2 and validSkills == 1 then
    PressKey(key)
    return
end

if healing > 0 and healing < 46 then
    Select(healing)
    return
end

if healing >= 46 then
    Cast(tostring(healing))
    return
end

if Go == 1 then
    if autospell > 0 then
        PressKey(autospellcode)
        return
    end
    if keycode == 253 then
        Cast("assisted")
        return
    end
    if keycode == 254 then
        Cast("trinket")
        return
    end
    if keycode > 0 and keycode <= 100 then
        PressKey(key)
        return
    end
end