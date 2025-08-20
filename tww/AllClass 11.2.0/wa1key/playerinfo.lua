local targetCanAttack = UnitCanAttack("player", "target") -- 目标可以攻击
local mounted = IsMounted("player")                       -- 坐骑
local inVehicle = UnitInVehicle("player")                 -- 载具
local chatFrame = ChatFrame1EditBox:IsVisible()           -- 聊天框
local targetisdead = UnitIsDeadOrGhost("target")          -- 目标死亡
local dead = UnitIsDeadOrGhost("player")                  -- 死亡
local combat = UnitAffectingCombat("player")              -- 检查战斗状态
local specID = GetSpecializationInfo(GetSpecialization()) -- 当前专精
local shapeshiftFormID = GetShapeshiftFormID()
local stealth = AuraUtil.FindAuraByName("潜行", "player", "HELPFUL|PLAYER")
local vanish = AuraUtil.FindAuraByName("消失", "player", "HELPFUL|PLAYER")
local darkness = Wa1Key and Wa1Key.Prop.DarknessComes or false
local travel = false
if shapeshiftFormID then
    if shapeshiftFormID == 3 or shapeshiftFormID == 4 or shapeshiftFormID == 29 or shapeshiftFormID == 27 then
        travel = true
    end
    if shapeshiftFormID == 1 and stealth then
        travel = true
    end
end

local specRangeMap = {
    -- 战士
    [71] = 8, -- 武器
    [72] = 8, -- 狂怒
    [73] = 8, -- 防护

    -- 圣骑士
    [65] = 8, -- 神圣
    [66] = 8, -- 防护
    [70] = 8, -- 惩戒

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

-- 获取玩家当前专精ID并检查目标是否在施法范围内
local function IsTargetInRange(target)
    local range = specRangeMap[specID] or 8        -- 默认8码
    if range == 8 then
        return C_Item.IsItemInRange(34368, target) -- 8码检测物品
    elseif range == 30 then
        return C_Item.IsItemInRange(835, target)   -- 30码检测物品
    elseif range == 40 then
        return C_Item.IsItemInRange(28767, target) -- 40码检测物品
    end
    return false
end

local inRange = IsTargetInRange("target")

if mounted or inVehicle or chatFrame or dead or travel or darkness then
    return 255
end

if targetCanAttack and inRange and combat and not targetisdead then
    return 1
end

if vanish then
    return 1
end

return 2
