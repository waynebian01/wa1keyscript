local targetCanAttack = UnitCanAttack("player", "target")       -- 目标可以攻击
local mounted = IsMounted("player")                             -- 坐骑
local inVehicle = UnitInVehicle("player")                       -- 载具
local chatFrame = ChatFrame1EditBox:IsVisible()                 -- 聊天框
local targetisdead = UnitIsDeadOrGhost("target")                -- 目标死亡
local dead = UnitIsDeadOrGhost("player")                        -- 死亡
local combat = UnitAffectingCombat("player")                    -- 检查战斗状态
local spec = C_SpecializationInfo.GetSpecialization()           -- 当前专精
local specID = C_SpecializationInfo.GetSpecializationInfo(spec) -- 当前专精ID
local shapeshiftFormID = GetShapeshiftFormID()                  -- 变形形态
local stealth = C_UnitAuras.GetPlayerAuraBySpellID(5215)        -- 潜行(猫)
local vanish = C_UnitAuras.GetPlayerAuraBySpellID(11327)        -- 消失
local darkness = Wa1Key and Wa1Key.Prop.DarknessComes or false
local minRange, maxRange = WeakAuras.GetRange("target")
local interrupt = Wa1Key.Prop.Interrupt
if not maxRange then maxRange = 255 end

local travel = false
if shapeshiftFormID then
    if shapeshiftFormID == 3 or shapeshiftFormID == 4 or shapeshiftFormID == 29 or shapeshiftFormID == 27 then
        travel = true
    end
    if shapeshiftFormID == 1 and stealth then
        travel = true
    end
end
-- 获取玩家当前专精ID并检查目标是否在施法范围内
local specRangeMap = {
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

local healingClass = {
    [65] = true,
    [256] = true,
    [257] = true,
    [264] = true,
    [270] = true,
    [105] = true,
    [1468] = true,
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

local range = specRangeMap[specID] or 8                        -- 默认8码
local hekili = Hekili_GetRecommendedAbility("Primary", 1) or 0 -- 获取Hekili推荐技能
local inRange = true

if hekili and hekili > 0 then
    local spellInfo = C_Spell.GetSpellInfo(hekili)
    local inSpellRange = C_Spell.IsSpellInRange(hekili, "target")
    local isHarmful = C_Spell.IsSpellHarmful(hekili)
    if spellInfo then
        if spellInfo.maxRange == 0 then
            inRange = maxRange <= range
        else
            if isHarmful and inSpellRange == false then
                inRange = false
            end
        end
    end
end

if interrupt == 1 then
    return 254
end

if mounted or chatFrame or dead or travel or darkness then
    return 255
end

if vanish then -- 消失
    return 1
end

if validSkills[hekili] then
    return 1
end

if healingClass[specID] then
    return 1
end

if targetCanAttack and inRange and combat and not targetisdead then
    return 1
end

return 2
