if not Skippy then Skippy = {} end
local spellkey = {
    ["target"] = 0,
    ["spell"] = 0,
    ["Skip"] = 0,
    ["None"] = 255,

    -- 单位
    ["player"] = 46,
    ["party1"] = 1,
    ["party2"] = 2,
    ["party3"] = 3,
    ["party4"] = 4,
    ["raid1"] = 1,
    ["raid2"] = 2,
    ["raid3"] = 3,
    ["raid4"] = 4,
    ["raid5"] = 5,
    ["raid6"] = 6,
    ["raid7"] = 7,
    ["raid8"] = 8,
    ["raid9"] = 9,
    ["raid10"] = 10,
    ["raid11"] = 11,
    ["raid12"] = 12,
    ["raid13"] = 13,
    ["raid14"] = 14,
    ["raid15"] = 15,
    ["raid16"] = 16,
    ["raid17"] = 17,
    ["raid18"] = 18,
    ["raid19"] = 19,
    ["raid20"] = 20,
    ["raid21"] = 21,
    ["raid22"] = 22,
    ["raid23"] = 23,
    ["raid24"] = 24,
    ["raid25"] = 25,
    ["raid26"] = 26,
    ["raid27"] = 27,
    ["raid28"] = 28,
    ["raid29"] = 29,
    ["raid30"] = 30,
    ["raid31"] = 31,
    ["raid32"] = 32,
    ["raid33"] = 33,
    ["raid34"] = 34,
    ["raid35"] = 35,
    ["raid36"] = 36,
    ["raid37"] = 37,
    ["raid38"] = 38,
    ["raid39"] = 39,
    ["raid40"] = 40,
    ["boss1"] = 41,
    ["boss2"] = 42,
    ["boss3"] = 43,
    ["boss4"] = 44,
    ["boss5"] = 45,

    -- 常用宏
    ["一键辅助"] = 47,
    ["饰品"] = 48,
    ["大红"] = 49,
    ["治疗石"] = 50,
    ["上个敌人"] = 51,
    ["停止施法"] = 52,
    ["种族技能"] = 53,
    ["奥术洪流"] = 53,

    --驱散技能
    ["纯净术"] = 54,
    ["净化灵魂"] = 54,
    ["自然之愈"] = 54,
    ["清洁术"] = 54,

    -- 牧师
    ["神圣之星"] = 55,
    ["治疗之环"] = 56,
    ["恢复"] = 57,
    ["强效治疗术"] = 58,
    ["联结治疗"] = 59,
    ["快速治疗"] = 60,
    ["愈合祷言"] = 61,
    ["治疗术"] = 62,
    ["绝望祷言"] = 63,
    ["苦修"] = 64,
    ["天使长"] = 65,
    ["治疗祷言"] = 66,
    ["真言术：盾"] = 67,
    ["神圣之火"] = 68,
    ["惩击"] = 69,
    ["暗影魔"] = 70,
    ["苦修target"] = 71,
    ["心灵专注"] = 72,
    ["圣言术：静"] = 73,
    ["圣言术：佑"] = 73,
    ["圣言术：罚"] = 73,
    ["渐隐术"] = 74,
    ["神圣新星"] = 75,
    ["预兆"] = 76,
    ["神圣化身"] = 77,
    ["光晕"] = 78,
    ["圣言术：灵"] = 79,

    -- 圣骑士
    ["神圣恳求"] = 55,
    ["荣耀圣令"] = 56,
    ["神圣棱镜"] = 57,
    ["神圣震击"] = 58,
    ["审判"] = 59,
    ["圣光闪现"] = 60,
    ["神圣之光"] = 61,
    ["圣光术"] = 62,
    ["圣光普照"] = 63,
    ["十字军打击"] = 64,
    ["洞察圣印"] = 65,
    ["黎明圣光"] = 66,
    ["圣光审判"] = 67,
    ["智慧审判"] = 68,
    ["奉献"] = 69,
    ["圣光道标"] = 70,
    ["智慧圣印"] = 71,
    ["光明圣印"] = 72,
    ["神恩术"] = 73,
    ["圣洁护盾"] = 74,

    -- 萨满祭司
    ["治疗之泉图腾"] = 55,
    ["暴雨图腾"] = 55,
    ["激流"] = 56,
    ["治疗链"] = 57,
    ["治疗之涌"] = 58,
    ["强效治疗波"] = 59,
    ["治疗波"] = 60,
    ["水之护盾"] = 61,
    ["大地生命武器"] = 62,
    ["元素释放"] = 63,
    ["先祖迅捷"] = 64,
    ["收回图腾"] = 65,
    ["大地之盾"] = 66,

    -- 德鲁伊
    ["生命绽放"] = 55,
    ["愈合"] = 56,
    ["滋养"] = 57,
    ["迅捷治愈"] = 58,
    ["回春术"] = 59,
    ["治疗之触"] = 60,
    ["自然迅捷"] = 61,
    ["野性成长"] = 62,
    ["万灵之召"] = 63,
    ["繁盛"] = 64,
    ["甘霖"] = 65,
    ["激活"] = 66,
    ["林莽卫士"] = 67,

    -- 武僧
    ["复苏之雾"] = 55,
    ["升腾之雾"] = 56,
    ["抚慰之雾"] = 57,
    ["真气波"] = 58,
    ["真气爆裂"] = 59,
    ["贯日击"] = 60,
    ["幻灭踢"] = 61,
    ["猛虎掌"] = 62,
    ["移花接木"] = 63,
    ["氤氲之雾"] = 64,
    ["真气酒"] = 65,
    ["神鹤引项踢"] = 66,
    ["振魂引"] = 67,
    ["雷光聚神茶"] = 68,
    ["法力茶"] = 69,
    ["禅意珠"] = 70,
}

function Skippy.UnitHeal(unit, spell)
    local output = ""
    local spellInfo = C_Spell.GetSpellInfo(spell)
    if not Wa1Key or not Wa1Key.Prop then
        output = output .. "Wa1Key不存在"
        Skippy.txt = output
        return true
    end
    if unit == nil then
        output = output .. "单位: 错误"
        Skippy.txt = output
        return true
    end
    if not spellkey[unit] then
        output = output .. "单位不存在"
    end

    if not spellkey[spell] then
        output = output .. "技能: 不存在"
    end

    if not spellkey[spell] or not spellkey[unit] then
        Wa1Key.Prop.heal = 255
        Skippy.txt = output
        return true
    end

    if unit == "None" then
        Skippy.txt = "休息..."
        Skippy.iconID = 133036
        Wa1Key.Prop.heal = 255
        return true
    elseif unit == "Skip" then
        Skippy.txt = "跳过治疗..."
        Skippy.iconID = 133036
        Wa1Key.Prop.heal = 0
        return true
    elseif unit == "spell" or unit == "target" then
        Wa1Key.Prop.heal = spellkey[spell]
        if spellInfo and spellInfo.iconID then
            Skippy.iconID = spellInfo.iconID
            Skippy.castTime = spellInfo.castTime
        else
            Skippy.iconID = 133036
        end
    else
        if UnitIsUnit(unit, "focus") then
            Wa1Key.Prop.heal = spellkey[spell]
        else
            Wa1Key.Prop.heal = spellkey[unit]
        end
        if spellInfo and spellInfo.iconID then
            Skippy.iconID = spellInfo.iconID
            Skippy.castTime = spellInfo.castTime
        else
            Skippy.iconID = 133036
        end
    end

    output = output ..
        "目标:" .. unit .. "(" .. spellkey[unit] .. ")" ..
        "\n技能:" .. spell .. "(" .. spellkey[spell] .. ")"
    Skippy.txt = output
    return true
end

function Skippy.PressKey(spellIdentifier)
    if not Wa1Key or not Wa1Key.Prop then
        Skippy.txt = "Wa1Key不存在"
        return true
    end

    if spellIdentifier == "None" or not spellIdentifier then
        Wa1Key.Prop.press = 255
        Skippy.txt = "无计可施"
        Skippy.iconID = 133036
        return true
    end

    local spellInfo = C_Spell.GetSpellInfo(spellIdentifier)

    if not spellInfo then
        Skippy.txt = "技能: 不存在"
        Skippy.iconID = 133036
        return true
    end

    for key, data in pairs(Skippy.spellkey) do
        if type(spellIdentifier) == "number" and data.spellId == spellIdentifier then
            Wa1Key.Prop.press = data.keycode
            Skippy.iconID = data.icon
            Skippy.txt = "技能: " .. data.name .. "\n按键: " .. data.key .. "\nCode: " .. data.keycode
            return true
        end
        if type(spellIdentifier) == "string" and data.name == spellIdentifier then
            Wa1Key.Prop.press = data.keycode
            Skippy.iconID = data.icon
            Skippy.txt = "技能: " .. data.name .. "\n按键: " .. data.key .. "\nCode: " .. data.keycode
            return true
        end
    end
    Wa1Key.Prop.press = 255
    Skippy.txt = "无计可施"
    Skippy.iconID = 133036
    return true
end
