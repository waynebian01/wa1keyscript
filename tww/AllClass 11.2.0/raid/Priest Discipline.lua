local e = aura_env
local player = e.playerinfo
if player.class ~= "牧师" then return end
if player.Specialization ~= 1 or not player.inRaid or not e.initialization then return end

local r = e.raidstatus
local target = e.targetinfo
local buff = r[player.inRaidUnit] and r[player.inRaidUnit].buff or {}
local spell = e.spellinfo
local talentInfo = e.talentInfo
local UnitKey = e.UnitKey
local channel = UnitChannelInfo("player")
local casting = UnitCastingInfo("player")
local hekili = Hekili_GetRecommendedAbility("Primary", 1)      -- 获取Hekili推荐技能
local interrupt = WK_Interrupt                                 -- 打断法术即将到来
local aoeisComeing = WK_AoeIsComeing                           -- 团队AOE即将在2秒后到来
local aoeRemaining = aoeisComeing and aoeisComeing - GetTime() -- 团队AOE即将在到来的剩余时间
local highDamage = WK_HIGHDAMAGE or WK_HIGHDAMAGECAST          -- 坦克6秒内即将受到高伤害, WK_HIGHDAMAGE=4秒, WK_HIGHDAMAGECAST=2秒

