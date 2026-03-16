local _, fu = ...
function fu.GetBlockIndexByClassIDAndSpecIndex(classID, specIndex)
    local blocks, macroList, assistant_spells, init = {}, {}, {}, false
    if classID == 5 then -- 牧师
        fu.HarmfulSpellId = 585
        fu.HelpfulSpellId = 2061
        macroList = {
            { "s1", "CTRL-NUMPAD1", "/cast [group:raid,@raid1]苦修;[@player]苦修" },
            { "s2", "CTRL-NUMPAD2", "/cast [group:raid,@raid2]苦修;[group:party,@party1]苦修" },
            { "s3", "CTRL-NUMPAD3", "/cast [group:raid,@raid3]苦修;[group:party,@party2]苦修" },
            { "s4", "CTRL-NUMPAD4", "/cast [group:raid,@raid4]苦修;[group:party,@party3]苦修" },
            { "s5", "CTRL-NUMPAD5", "/cast [group:raid,@raid5]苦修;[group:party,@party4]苦修" },
            { "s6", "CTRL-NUMPAD6", "/cast [group:raid,@raid6]苦修" },
            { "s7", "CTRL-NUMPAD7", "/cast [group:raid,@raid7]苦修" },
            { "s8", "CTRL-NUMPAD8", "/cast [group:raid,@raid8]苦修" },
            { "s9", "CTRL-NUMPAD9", "/cast [group:raid,@raid9]苦修" },
            { "s10", "CTRL-NUMPAD0", "/cast [group:raid,@raid10]苦修" },
            { "s11", "CTRL-NUMPADDECIMAL", "/cast [group:raid,@raid11]苦修" },
            { "s12", "CTRL-NUMPADPLUS", "/cast [group:raid,@raid12]苦修" },
            { "s13", "CTRL-NUMPADMINUS", "/cast [group:raid,@raid13]苦修" },
            { "s14", "CTRL-NUMPADMULTIPLY", "/cast [group:raid,@raid14]苦修" },
            { "s15", "CTRL-NUMPADDIVIDE", "/cast [group:raid,@raid15]苦修" },
            { "s16", "CTRL-F1", "/cast [group:raid,@raid16]苦修" },
            { "s17", "CTRL-F2", "/cast [group:raid,@raid17]苦修" },
            { "s18", "CTRL-F3", "/cast [group:raid,@raid18]苦修" },
            { "s19", "CTRL-F5", "/cast [group:raid,@raid19]苦修" },
            { "s20", "CTRL-F6", "/cast [group:raid,@raid20]苦修" },
            { "s21", "CTRL-F7", "/cast [group:raid,@raid21]苦修" },
            { "s22", "CTRL-F8", "/cast [group:raid,@raid22]苦修" },
            { "s23", "CTRL-F9", "/cast [group:raid,@raid23]苦修" },
            { "s24", "CTRL-F10", "/cast [group:raid,@raid24]苦修" },
            { "s25", "CTRL-F11", "/cast [group:raid,@raid25]苦修" },
            { "s26", "CTRL-F12", "/cast [group:raid,@raid26]苦修" },
            { "s27", "CTRL-,", "/cast [group:raid,@raid27]苦修" },
            { "s28", "CTRL-.", "/cast [group:raid,@raid28]苦修" },
            { "s29", "CTRL-/", "/cast [group:raid,@raid29]苦修" },
            { "s30", "CTRL-;", "/cast [group:raid,@raid30]苦修" },
            { "s31", "CTRL-'", "/cast [group:raid,@raid1]快速治疗;[@player]快速治疗" },
            { "s32", "CTRL-[", "/cast [group:raid,@raid2]快速治疗;[group:party,@party1]快速治疗" },
            { "s33", "CTRL-]", "/cast [group:raid,@raid3]快速治疗;[group:party,@party2]快速治疗" },
            { "s34", "CTRL-=", "/cast [group:raid,@raid4]快速治疗;[group:party,@party3]快速治疗" },
            { "s35", "ALT-NUMPAD1", "/cast [group:raid,@raid5]快速治疗;[group:party,@party4]快速治疗" },
            { "s36", "ALT-NUMPAD2", "/cast [group:raid,@raid6]快速治疗" },
            { "s37", "ALT-NUMPAD3", "/cast [group:raid,@raid7]快速治疗" },
            { "s38", "ALT-NUMPAD4", "/cast [group:raid,@raid8]快速治疗" },
            { "s39", "ALT-NUMPAD5", "/cast [group:raid,@raid9]快速治疗" },
            { "s40", "ALT-NUMPAD6", "/cast [group:raid,@raid10]快速治疗" },
            { "s41", "ALT-NUMPAD7", "/cast [group:raid,@raid11]快速治疗" },
            { "s42", "ALT-NUMPAD8", "/cast [group:raid,@raid12]快速治疗" },
            { "s43", "ALT-NUMPAD9", "/cast [group:raid,@raid13]快速治疗" },
            { "s44", "ALT-NUMPAD0", "/cast [group:raid,@raid14]快速治疗" },
            { "s45", "ALT-NUMPADDECIMAL", "/cast [group:raid,@raid15]快速治疗" },
            { "s46", "ALT-NUMPADPLUS", "/cast [group:raid,@raid16]快速治疗" },
            { "s47", "ALT-NUMPADMINUS", "/cast [group:raid,@raid17]快速治疗" },
            { "s48", "ALT-NUMPADMULTIPLY", "/cast [group:raid,@raid18]快速治疗" },
            { "s49", "ALT-NUMPADDIVIDE", "/cast [group:raid,@raid19]快速治疗" },
            { "s50", "ALT-F1", "/cast [group:raid,@raid20]快速治疗" },
            { "s51", "ALT-F2", "/cast [group:raid,@raid21]快速治疗" },
            { "s52", "ALT-F3", "/cast [group:raid,@raid22]快速治疗" },
            { "s53", "ALT-F5", "/cast [group:raid,@raid23]快速治疗" },
            { "s54", "ALT-F6", "/cast [group:raid,@raid24]快速治疗" },
            { "s55", "ALT-F7", "/cast [group:raid,@raid25]快速治疗" },
            { "s56", "ALT-F8", "/cast [group:raid,@raid26]快速治疗" },
            { "s57", "ALT-F9", "/cast [group:raid,@raid27]快速治疗" },
            { "s58", "ALT-F10", "/cast [group:raid,@raid28]快速治疗" },
            { "s59", "ALT-F11", "/cast [group:raid,@raid29]快速治疗" },
            { "s60", "ALT-F12", "/cast [group:raid,@raid30]快速治疗" },
            { "s61", "ALT-,", "/cast [group:raid,@raid1]真言术：盾;[@player]真言术：盾" },
            { "s62", "ALT-.", "/cast [group:raid,@raid2]真言术：盾;[group:party,@party1]真言术：盾" },
            { "s63", "ALT-/", "/cast [group:raid,@raid3]真言术：盾;[group:party,@party2]真言术：盾" },
            { "s64", "ALT-;", "/cast [group:raid,@raid4]真言术：盾;[group:party,@party3]真言术：盾" },
            { "s65", "ALT-'", "/cast [group:raid,@raid5]真言术：盾;[group:party,@party4]真言术：盾" },
            { "s66", "ALT-[", "/cast [group:raid,@raid6]真言术：盾" },
            { "s67", "ALT-]", "/cast [group:raid,@raid7]真言术：盾" },
            { "s68", "ALT-=", "/cast [group:raid,@raid8]真言术：盾" },
            { "s69", "SHIFT-NUMPAD1", "/cast [group:raid,@raid9]真言术：盾" },
            { "s70", "SHIFT-NUMPAD2", "/cast [group:raid,@raid10]真言术：盾" },
            { "s71", "SHIFT-NUMPAD3", "/cast [group:raid,@raid11]真言术：盾" },
            { "s72", "SHIFT-NUMPAD4", "/cast [group:raid,@raid12]真言术：盾" },
            { "s73", "SHIFT-NUMPAD5", "/cast [group:raid,@raid13]真言术：盾" },
            { "s74", "SHIFT-NUMPAD6", "/cast [group:raid,@raid14]真言术：盾" },
            { "s75", "SHIFT-NUMPAD7", "/cast [group:raid,@raid15]真言术：盾" },
            { "s76", "SHIFT-NUMPAD8", "/cast [group:raid,@raid16]真言术：盾" },
            { "s77", "SHIFT-NUMPAD9", "/cast [group:raid,@raid17]真言术：盾" },
            { "s78", "SHIFT-NUMPAD0", "/cast [group:raid,@raid18]真言术：盾" },
            { "s79", "SHIFT-NUMPADDECIMAL", "/cast [group:raid,@raid19]真言术：盾" },
            { "s80", "SHIFT-NUMPADPLUS", "/cast [group:raid,@raid20]真言术：盾" },
            { "s81", "SHIFT-NUMPADMINUS", "/cast [group:raid,@raid21]真言术：盾" },
            { "s82", "SHIFT-NUMPADMULTIPLY", "/cast [group:raid,@raid22]真言术：盾" },
            { "s83", "SHIFT-NUMPADDIVIDE", "/cast [group:raid,@raid23]真言术：盾" },
            { "s84", "SHIFT-F1", "/cast [group:raid,@raid24]真言术：盾" },
            { "s85", "SHIFT-F2", "/cast [group:raid,@raid25]真言术：盾" },
            { "s86", "SHIFT-F3", "/cast [group:raid,@raid26]真言术：盾" },
            { "s87", "SHIFT-F5", "/cast [group:raid,@raid27]真言术：盾" },
            { "s88", "SHIFT-F6", "/cast [group:raid,@raid28]真言术：盾" },
            { "s89", "SHIFT-F7", "/cast [group:raid,@raid29]真言术：盾" },
            { "s90", "SHIFT-F8", "/cast [group:raid,@raid30]真言术：盾" },
            { "s91", "SHIFT-F9", "/cast [group:raid,@raid1]恳求;[@player]恳求" },
            { "s92", "SHIFT-F10", "/cast [group:raid,@raid2]恳求;[group:party,@party1]恳求" },
            { "s93", "SHIFT-F11", "/cast [group:raid,@raid3]恳求;[group:party,@party2]恳求" },
            { "s94", "SHIFT-F12", "/cast [group:raid,@raid4]恳求;[group:party,@party3]恳求" },
            { "s95", "SHIFT-,", "/cast [group:raid,@raid5]恳求;[group:party,@party4]恳求" },
            { "s96", "SHIFT-.", "/cast [group:raid,@raid6]恳求" },
            { "s97", "SHIFT-/", "/cast [group:raid,@raid7]恳求" },
            { "s98", "SHIFT-;", "/cast [group:raid,@raid8]恳求" },
            { "s99", "SHIFT-'", "/cast [group:raid,@raid9]恳求" },
            { "s100", "SHIFT-[", "/cast [group:raid,@raid10]恳求" },
            { "s101", "SHIFT-]", "/cast [group:raid,@raid11]恳求" },
            { "s102", "SHIFT-=", "/cast [group:raid,@raid12]恳求" },
            { "s103", "ALT-CTRL-NUMPAD1", "/cast [group:raid,@raid13]恳求" },
            { "s104", "ALT-CTRL-NUMPAD2", "/cast [group:raid,@raid14]恳求" },
            { "s105", "ALT-CTRL-NUMPAD3", "/cast [group:raid,@raid15]恳求" },
            { "s106", "ALT-CTRL-NUMPAD4", "/cast [group:raid,@raid16]恳求" },
            { "s107", "ALT-CTRL-NUMPAD5", "/cast [group:raid,@raid17]恳求" },
            { "s108", "ALT-CTRL-NUMPAD6", "/cast [group:raid,@raid18]恳求" },
            { "s109", "ALT-CTRL-NUMPAD7", "/cast [group:raid,@raid19]恳求" },
            { "s110", "ALT-CTRL-NUMPAD8", "/cast [group:raid,@raid20]恳求" },
            { "s111", "ALT-CTRL-NUMPAD9", "/cast [group:raid,@raid21]恳求" },
            { "s112", "ALT-CTRL-NUMPAD0", "/cast [group:raid,@raid22]恳求" },
            { "s113", "ALT-CTRL-NUMPADDECIMAL", "/cast [group:raid,@raid23]恳求" },
            { "s114", "ALT-CTRL-NUMPADPLUS", "/cast [group:raid,@raid24]恳求" },
            { "s115", "ALT-CTRL-NUMPADMINUS", "/cast [group:raid,@raid25]恳求" },
            { "s116", "ALT-CTRL-NUMPADMULTIPLY", "/cast [group:raid,@raid26]恳求" },
            { "s117", "ALT-CTRL-NUMPADDIVIDE", "/cast [group:raid,@raid27]恳求" },
            { "s118", "ALT-CTRL-F1", "/cast [group:raid,@raid28]恳求" },
            { "s119", "ALT-CTRL-F2", "/cast [group:raid,@raid29]恳求" },
            { "s120", "ALT-CTRL-F3", "/cast [group:raid,@raid30]恳求" },
            { "s121", "ALT-CTRL-F5", "/cast [group:raid,@raid1]纯净术;[@player]纯净术" },
            { "s122", "ALT-CTRL-F6", "/cast [group:raid,@raid2]纯净术;[group:party,@party1]纯净术" },
            { "s123", "ALT-CTRL-F7", "/cast [group:raid,@raid3]纯净术;[group:party,@party2]纯净术" },
            { "s124", "ALT-CTRL-F8", "/cast [group:raid,@raid4]纯净术;[group:party,@party3]纯净术" },
            { "s125", "ALT-CTRL-F9", "/cast [group:raid,@raid5]纯净术;[group:party,@party4]纯净术" },
            { "s126", "ALT-CTRL-F10", "/cast [group:raid,@raid6]纯净术" },
            { "s127", "ALT-CTRL-F11", "/cast [group:raid,@raid7]纯净术" },
            { "s128", "ALT-CTRL-F12", "/cast [group:raid,@raid8]纯净术" },
            { "s129", "ALT-CTRL-,", "/cast [group:raid,@raid9]纯净术" },
            { "s130", "ALT-CTRL-.", "/cast [group:raid,@raid10]纯净术" },
            { "s131", "ALT-CTRL-/", "/cast [group:raid,@raid11]纯净术" },
            { "s132", "ALT-CTRL-;", "/cast [group:raid,@raid12]纯净术" },
            { "s133", "ALT-CTRL-'", "/cast [group:raid,@raid13]纯净术" },
            { "s134", "ALT-CTRL-[", "/cast [group:raid,@raid14]纯净术" },
            { "s135", "ALT-CTRL-]", "/cast [group:raid,@raid15]纯净术" },
            { "s136", "ALT-CTRL-=", "/cast [group:raid,@raid16]纯净术" },
            { "s137", "ALT-SHIFT-NUMPAD1", "/cast [group:raid,@raid17]纯净术" },
            { "s138", "ALT-SHIFT-NUMPAD2", "/cast [group:raid,@raid18]纯净术" },
            { "s139", "ALT-SHIFT-NUMPAD3", "/cast [group:raid,@raid19]纯净术" },
            { "s140", "ALT-SHIFT-NUMPAD4", "/cast [group:raid,@raid20]纯净术" },
            { "s141", "ALT-SHIFT-NUMPAD5", "/cast [group:raid,@raid21]纯净术" },
            { "s142", "ALT-SHIFT-NUMPAD6", "/cast [group:raid,@raid22]纯净术" },
            { "s143", "ALT-SHIFT-NUMPAD7", "/cast [group:raid,@raid23]纯净术" },
            { "s144", "ALT-SHIFT-NUMPAD8", "/cast [group:raid,@raid24]纯净术" },
            { "s145", "ALT-SHIFT-NUMPAD9", "/cast [group:raid,@raid25]纯净术" },
            { "s146", "ALT-SHIFT-NUMPAD0", "/cast [group:raid,@raid26]纯净术" },
            { "s147", "ALT-SHIFT-NUMPADDECIMAL", "/cast [group:raid,@raid27]纯净术" },
            { "s148", "ALT-SHIFT-NUMPADPLUS", "/cast [group:raid,@raid28]纯净术" },
            { "s149", "ALT-SHIFT-NUMPADMINUS", "/cast [group:raid,@raid29]纯净术" },
            { "s150", "ALT-SHIFT-NUMPADMULTIPLY", "/cast [group:raid,@raid30]纯净术" },
            { "s151", "ALT-SHIFT-NUMPADDIVIDE", "/cast 心灵震爆" },
            { "s152", "ALT-SHIFT-F1", "/cast 惩击" },
            { "s153", "ALT-SHIFT-F2", "/cast 暗言术：痛" },
            { "s154", "ALT-SHIFT-F3", "/cast 真言术：韧" },
            { "s155", "ALT-SHIFT-F5", "/cast 神圣新星" },
            { "s156", "ALT-SHIFT-F6", "/cast 苦修" },
            { "s157", "ALT-SHIFT-F7", "/cast 真言术：耀" },
            { "s158", "ALT-SHIFT-F8", "/cast 福音" },
            { "s159", "ALT-SHIFT-F9", "/cast 终极苦修" },
            { "s160", "ALT-SHIFT-F10", "/cast 绝望祷言" },
            { "s161", "ALT-SHIFT-F11", "/cast 暗言术：灭" },
            { "s162", "ALT-SHIFT-F12", "/cast 吸血鬼之触" },
            { "s163", "ALT-SHIFT-,", "/cast 暗影形态" },
            { "s164", "ALT-SHIFT-.", "/cast 暗言术：癫" },
            { "s165", "ALT-SHIFT-/", "/cast 精神鞭笞" },
            { "s166", "ALT-SHIFT-;", "/cast 虚空形态" },
            { "s167", "ALT-SHIFT-'", "/cast 虚空洪流" },
            { "s168", "ALT-SHIFT-[", "/cast 触须猛击" },
            { "s169", "ALT-SHIFT-]", "/cast 虚空冲击" },
            { "s170", "ALT-SHIFT-=", "/cast 虚空齐射" },
        }
        if specIndex == 1 then
            init = true
            blocks = {
                assistant = 11,
                target_valid = 12,
                group_type = 13,
                spell_cd = {
                    { index = 15, spellId = 17, name = "真言术：盾" },
                    { index = 16, spellId = 47540, name = "苦修" },
                    { index = 17, spellId = 194509, name = "真言术：耀" },
                    { index = 18, spellId = 527, name = "纯净术" },
                    { index = 19, spellId = 19236, name = "绝望祷言" },
                    { index = 20, spellId = 8092, name = "心灵震爆" },
                    { index = 21, spellId = 472433, name = "福音" },
                    { index = 22, spellId = 32379, name = "暗言术：灭" },
                },
                aura = {
                    ["虚空之盾"] = 23,
                    ["圣光涌动"] = 24,
                },
                group_count = 25,
                unit_start = 25,
                unit_num = 5,
                unit = {
                    ["HealthPercent"] = 1,
                    ["Role"] = 2,
                    ["dispel"] = 3,
                    aura = {
                        [4] = { 194384 },
                        [5] = { 17, 1253593 },
                    },
                }
            }
            assistant_spells = {
                [8092] = 1,  -- 心灵震爆
                [585] = 2,   -- 惩击
                [32379] = 3, -- 暗言术：灭
                [589] = 4,   -- 暗言术：痛
                [21562] = 5, -- 真言术：韧
                [47540] = 6, -- 苦修
            }
        elseif specIndex == 3 then
            init = true
            blocks = {
                assistant = 11,
                target_valid = 12,

                spell_cd = {
                    { index = 13, spellId = 8092, name = "心灵震爆" },
                    { index = 14, spellId = 32379, name = "暗言术：灭" },
                    { index = 15, spellId = 263165, name = "虚空洪流" },
                    { index = 16, spellId = 228260, name = "虚空形态" },
                    { index = 17, spellId = 1227280, name = "触须猛击" },
                    { index = 18, spellId = 19236, name = "绝望祷言" },
                }
            }
            assistant_spells = {
                [34914] = 1,    -- 吸血鬼之触
                [8092] = 2,     -- 心灵震爆
                [232698] = 3,   -- 暗影形态
                [32379] = 4,    -- 暗言术：灭
                [589] = 5,      -- 暗言术：痛
                [335467] = 6,   -- 暗言术：癫
                [21562] = 7,    -- 真言术：韧
                [15407] = 8,    -- 精神鞭笞
                [228260] = 9,   -- 虚空形态
                [263165] = 10,  -- 虚空洪流
                [1227280] = 11, -- 触须猛击
                [450983] = 12,  -- 虚空冲击
                [1242173] = 13, -- 虚空齐射
            }
        end
    end
    if classID == 6 then -- 死亡骑士
        fu.HarmfulSpellId = 47528
        macroList = {
            { "s1", "CTRL-NUMPAD1", "/cast 亡者复生" },
            { "s2", "CTRL-NUMPAD2", "/cast 亡者大军" },
            { "s3", "CTRL-NUMPAD3", "/cast 凋零缠绕" },
            { "s4", "CTRL-NUMPAD4", "/cast 天灾打击" },
            { "s5", "CTRL-NUMPAD5", "/cast 扩散" },
            { "s6", "CTRL-NUMPAD6", "/cast 爆发" },
            { "s7", "CTRL-NUMPAD7", "/cast 脓疮打击" },
            { "s8", "CTRL-NUMPAD8", "/cast 腐化" },
            { "s9", "CTRL-NUMPAD9", "/cast 黑暗突变" },
            { "s10", "CTRL-NUMPAD0", "/cast 灵魂收割" },
            { "s11", "CTRL-NUMPADDECIMAL", "/cast 灵界打击" },
            { "s12", "CTRL-NUMPADPLUS", "/cast 心脏打击" },
            { "s13", "CTRL-NUMPADMINUS", "/cast [@player]枯萎凋零" },
            { "s14", "CTRL-NUMPADMULTIPLY", "/cast 死神的抚摸" },
            { "s15", "CTRL-NUMPADDIVIDE", "/cast 符文刃舞" },
            { "s16", "CTRL-F1", "/cast 精髓分裂" },
            { "s17", "CTRL-F2", "/cast 血液沸腾" },
            { "s18", "CTRL-F3", "/cast 吸血鬼之血" },
            { "s19", "CTRL-F5", "/cast 冰封之韧" },
            { "s20", "CTRL-F6", "/cast 巫妖之躯" },
        }
        if specIndex == 1 then
            init = true
            fu.HarmfulSpellId = 47528
            blocks = {
                runes = 11,
                assistant = 12,
                target_valid = 13,
                target_health = 14,
                enemy_count = 15,
                spell_cd = {
                    { index = 16, spellId = 46584, name = "亡者复生" },
                    { index = 17, spellId = 55233, name = "吸血鬼之血" },
                    { index = 18, spellId = 48792, name = "冰封之韧" },
                    { index = 19, spellId = 49039, name = "巫妖之躯" },
                }
            }
            assistant_spells = {
                [206930] = 1, -- 心脏打击
                [43265] = 2,  -- 枯萎凋零
                [195292] = 3, -- 死神的抚摸
                [49998] = 4,  -- 灵界打击
                [49028] = 5,  -- 符文刃舞
                [195182] = 6, -- 精髓分裂
                [50842] = 7,  -- 血液沸腾
                [433895] = 8, -- 吸血鬼打击
            }
        elseif specIndex == 3 then
            init = true
            blocks = {
                runes = 11,
                assistant = 12,
                target_valid = 13,
                target_health = 14,
                enemy_count = 15,
                spell_cd = {
                    { index = 16, spellId = 46584, name = "亡者复生" },
                    { index = 17, spellId = 42650, name = "亡者大军" },
                    { index = 18, spellId = 1247378, name = "腐化" },
                    { index = 19, spellId = 1233448, name = "黑暗突变" },
                    { index = 20, spellId = 343294, name = "灵魂收割" },
                },
                spell_charge = {
                    { index = 21, spellId = 1247378, name = "腐化" },
                },
                aura = {
                    festering = 22,           -- 脓疮
                    lesser_ghoul = 23,        -- 次级食尸鬼
                    sudden_doom = 24,         -- 末日突降
                    dark_succor = 25,         -- 黑暗援助
                    forbidden_knowledge = 26, -- 禁断知识
                }
            }
            assistant_spells = {
                [46584] = 1,    -- 亡者复生
                [42650] = 2,    -- 亡者大军
                [47541] = 3,    -- 凋零缠绕
                [55090] = 4,    -- 天灾打击
                [207317] = 5,   -- 扩散
                [77575] = 6,    -- 爆发
                [85948] = 7,    -- 脓疮打击
                [1247378] = 8,  -- 腐化
                [1233448] = 10, -- 黑暗突变
                [343294] = 11,  -- 灵魂收割
            }
        end
    end
    if classID == 11 then -- 德鲁伊
        fu.HelpfulSpellId = 774
        fu.HarmfulSpellId = 5176
        fu.HarmfulRemoteSpellId = 5176
        fu.HarmfulMeleeSpellId = 1822
        if specIndex == 4 then
            init = true
            blocks = {
                assistant = 11,
                target_valid = 12,
                group_type = 13,
                stance = 14,
                spell_cd = {
                    { index = 15, spellId = 22812, name = "树皮术" },
                    { index = 16, spellId = 48438, name = "野性成长" },
                    { index = 17, spellId = 391528, name = "万灵之召" },
                    { index = 18, spellId = 18562, name = "迅捷治愈" },
                    { index = 19, spellId = 88423, name = "自然之愈" },
                    { index = 20, spellId = 102342, name = "铁木树皮" },
                    { index = 21, spellId = 132158, name = "自然迅捷" },
                    { index = 22, spellId = 29166, name = "激活" },
                },
                aura = {
                    ["节能施法"] = 23,
                    ["自然迅捷"] = 24,
                    ["丛林之魂"] = 25,
                },
                target_distance = 26,
                members_count = 27,
                unit_start = 27,
                unit_num = 7,
                unit = {
                    ["HealthPercent"] = 1,
                    ["Role"] = 2,
                    ["dispel"] = 3,
                    aura = {
                        [4] = { 33763 },                    -- 生命绽放
                        [5] = { 774, 155777, 8936, 48438 }, -- 迅捷治愈(回春术, 萌芽, 愈合, 野性生长)
                        [6] = { 8936 },                     -- 愈合
                    },
                    rejuv = 7,                              -- 回春术数量
                },
            }
            assistant_spells = {
                [22568] = 1, -- 凶猛撕咬
                [1079] = 2,  -- 割裂
                [5221] = 3,  -- 撕碎
                [1822] = 4,  -- 斜掠
                [8921] = 5,  -- 月火术
                [5176] = 6,  -- 愤怒
                [1126] = 7,  -- 野性印记
            }
        end
    end
    return blocks, macroList, assistant_spells, init
end
