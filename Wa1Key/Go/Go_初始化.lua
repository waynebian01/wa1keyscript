aura_env.travelNumber = {
    [3] = true,  -- 旅行形态
    [4] = true,  -- 水栖形态
    [16] = true, -- 幽灵狼
    [27] = true, -- 飞行形态
    [29] = true, -- 飞行形态
}

function aura_env.Go_Init()
    aura_env.target = UnitCanAttack("player", "target")                              -- 目标可以攻击
    aura_env.targetisdead = UnitIsDeadOrGhost("target")                              -- 目标死亡
    aura_env.mounted = IsMounted("player")                                           -- 坐骑
    aura_env.dead = UnitIsDeadOrGhost("player")                                      -- 死亡
    aura_env.isCombat = UnitAffectingCombat("player")                                -- 战斗状态
    aura_env.specIndex = C_SpecializationInfo.GetSpecialization()                    -- 专精索引
    aura_env.specID = C_SpecializationInfo.GetSpecializationInfo(aura_env.specIndex) -- 专精ID
    aura_env.shapeshiftFormID = GetShapeshiftFormID() or 0                           -- 变形形态
    aura_env.stealth = C_UnitAuras.GetPlayerAuraBySpellID(5215)                      -- 潜行
    aura_env.vanish = C_UnitAuras.GetPlayerAuraBySpellID(11327)                      -- 消失
    aura_env.inParty = UnitPlayerOrPetInParty("player")                              -- 队伍
    aura_env.travel = aura_env.travelNumber[aura_env.shapeshiftFormID]               -- 小德旅行形态
    aura_env.catStealth = aura_env.shapeshiftFormID == 1 and aura_env.stealth        -- 猫潜行
end

aura_env.Go_Init()

aura_env.specRangeMap = {
    -- 战士
    [71] = 8, -- 武器
    [72] = 8, -- 狂怒
    [73] = 8, -- 防护

    -- 圣骑士
    [65] = 30, -- 神圣
    [66] = 14, -- 防护
    [70] = 14, -- 惩戒

    -- 猎人
    [253] = 40, -- 野兽控制
    [254] = 40, -- 射击
    [255] = 40, -- 生存

    -- 潜行者
    [259] = 8, -- 敏锐
    [260] = 8, -- 战斗
    [261] = 8, -- 刺杀

    -- 牧师
    [256] = 40, -- 戒律
    [257] = 40, -- 神圣
    [258] = 40, -- 暗影

    -- 死亡骑士
    [250] = 8, -- 鲜血
    [251] = 8, -- 冰霜
    [252] = 8, -- 邪恶

    -- 萨满
    [262] = 40, -- 元素
    [263] = 8,  -- 增强
    [264] = 40, -- 恢复

    -- 法师
    [62] = 40, -- 奥术
    [63] = 40, -- 火焰
    [64] = 40, -- 冰霜

    -- 术士
    [265] = 40, -- 痛苦
    [266] = 40, -- 恶魔学识
    [267] = 40, -- 毁灭

    -- 武僧
    [268] = 8,  -- 酒仙
    [269] = 8,  -- 踏风
    [270] = 40, -- 织雾

    -- 德鲁伊
    [102] = 40, -- 平衡
    [103] = 8,  -- 野性
    [104] = 8,  -- 守护
    [105] = 40, -- 恢复

    -- 恶魔猎手
    [577] = 8, -- 浩劫
    [581] = 8, -- 复仇

    -- 唤魔师
    [1467] = 30, -- 湮灭
    [1468] = 30, -- 恩护
    [1473] = 30, -- 增辉
}

aura_env.healingClass = {
    [65] = true,
    [256] = true,
    [257] = true,
    [264] = true,
    [270] = true,
    [105] = true,
    [1468] = true,
}

aura_env.validSkills = {
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
    [52127] = true,  --水之护盾
    [192106] = true, -- 闪电之盾

    [1126] = true,   -- 野性印记
    [381749] = true, -- 青铜龙的祝福
    [1459] = true,   -- 奥术智慧
    [21562] = true,  -- 真言术：韧
    [6673] = true,   -- 战斗怒吼
    [883] = true,    -- 召唤宠物1
    [46584] = true,  -- 亡者复生
    --[5215] = true,	-- 潜行（猫）
}
