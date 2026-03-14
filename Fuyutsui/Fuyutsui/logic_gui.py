# -*- coding: utf-8 -*-
"""
通用 GUI：根据职业/专精自动适配显示。
使用 CustomTkinter，背景半透明，文字保持清晰。
"""
import threading
import time
import ctypes
import customtkinter as ctk

from utils import *
from GetPixels import get_info

TOGGLE_INTERVAL = 0.05
LOGIC_INTERVAL = 0.2
GUI_UPDATE_MS = 150

toggle_key_str = "XBUTTON2"
vk_toggle = get_vk(toggle_key_str)

_state_lock = threading.Lock()
_logic_enabled = False
_state_dict = {}
_spec_name = None
_current_step = ""  # 当前步骤，每次逻辑循环都会更新
_unit_info = {}  # 单位信息，供 GUI 显示

# 戒律专精技能
DISCIPLINE_SPELLS = [
    "真言术：盾", "苦修", "真言术：耀", "纯净术",
    "绝望祷言", "心灵震爆", "福音", "暗言术：灭",
]
# 暗影专精技能
SHADOW_SPELLS = [
    "心灵震爆", "暗言术：灭", "虚空洪流",
    "虚空形态", "触须猛击", "绝望祷言",
]
# 邪恶专精技能 (config 6.3)
UNHOLY_SPELLS = [
    "亡者复生", "亡者大军", "腐化", "腐化2", "黑暗突变",
    "灵魂收割",
]
# 鲜血专精技能 (config 6.1)
BLOOD_SPELLS = [
    "亡者复生", "吸血鬼之血", "冰封之韧", "巫妖之躯",
]
# 奶德/恢复德鲁伊技能 (config 11.4)
RESTORATION_DRUID_SPELLS = [
    "树皮术", "野性成长", "万灵之召", "迅捷治愈",
    "自然之愈", "铁木树皮", "自然迅捷", "激活",
]

# 各专精的 status_keys (config 中的状态字段)
STATUS_KEYS_BY_SPEC = {
    "戒律": ["生命值", "能量值", "有效性", "战斗", "移动", "施法", "引导",
             "虚空之盾", "圣光涌动", "目标有效", "一键辅助"],
    "暗影": ["生命值", "能量值", "有效性", "战斗", "移动", "施法", "引导",
             "目标有效", "一键辅助"],
    "邪恶": ["生命值", "能量值", "有效性", "战斗", "移动", "符文",
             "一键辅助", "目标有效", "目标生命值", "敌人人数", "脓疮毒镰",
             "次级食尸鬼", "末日突降", "黑暗援助", "禁断知识"],
    "鲜血": ["生命值", "能量值", "有效性", "战斗", "移动", "符文",
             "一键辅助", "目标有效", "目标生命值", "敌人人数"],
    "奶德": ["生命值", "能量值", "有效性", "战斗", "移动", "施法", "引导",
             "目标有效","目标距离", "一键辅助", "队伍类型", "姿态", "队伍人数",
             "自然迅捷", "丛林之魂", "节能施法"],
}

# 各专精的技能列表（用于技能冷却显示）
SPELLS_BY_SPEC = {
    "戒律": DISCIPLINE_SPELLS,
    "暗影": SHADOW_SPELLS,
    "邪恶": UNHOLY_SPELLS,
    "鲜血": BLOOD_SPELLS,
    "奶德": RESTORATION_DRUID_SPELLS,
}

# 各专精的单位信息 keys（用于 unit_info 区域）
UNIT_INFO_KEYS_BY_SPEC = {
    "戒律": [
        ("dispel_unit", "需驱散单位"),
        ("lowest_unit", "生命最低单位"),
        ("lowest_unit_pct", "生命最低%"),
        ("no_atonement_unit", "无救赎单位"),
        ("no_atonement_pct", "无救赎生命%"),
        ("no_shield_lowest_unit", "无盾生命最低单位"),
        ("no_shield_lowest_pct", "无盾生命最低%"),
        ("no_shield_unit", "无盾单位"),
        ("no_shield_pct", "无盾生命%"),
        ("no_atonement_count_90", "90%以下无救赎人数"),
    ],
    "奶德": [
        ("dispel_unit", "需驱散单位"),
        ("lowest_unit", "生命最低单位"),
        ("lowest_unit_pct", "生命最低%"),
        ("no_rejuv_unit", "无回春单位"),
        ("no_rejuv_pct", "无回春生命%"),

    ],
}

# 各专精的 group 配置 (num_units, fields)
GROUP_CONFIG_BY_SPEC = {
    "戒律": (5, ["生命值", "职责", "驱散", "救赎", "真言术：盾"]),
    "奶德": (7, ["生命值", "职责", "驱散", "回春术", "愈合", "生命绽放"]),
}


def get_unit_info_keys_for_spec(spec):
    """根据专精返回单位信息 keys"""
    return UNIT_INFO_KEYS_BY_SPEC.get(spec, UNIT_INFO_KEYS_BY_SPEC["戒律"])


def get_group_config_for_spec(spec):
    """根据专精返回 (num_units, fields)"""
    return GROUP_CONFIG_BY_SPEC.get(spec, GROUP_CONFIG_BY_SPEC["戒律"])


def get_status_keys_for_spec(spec):
    """根据专精返回要显示的状态字段，专精未知时用戒律"""
    return STATUS_KEYS_BY_SPEC.get(spec, STATUS_KEYS_BY_SPEC["戒律"])


def get_spells_for_spec(spec):
    """根据专精返回要显示冷却的技能列表"""
    return SPELLS_BY_SPEC.get(spec, DISCIPLINE_SPELLS)


def _run_priest_loop():
    """后台运行的牧师主循环（戒律+暗影自动适配）"""
    global _logic_enabled, _state_dict, _spec_name, _current_step, _unit_info
    prev_pressed = False
    last_logic_time = 0.0

    while True:
        current_pressed = (ctypes.windll.user32.GetAsyncKeyState(vk_toggle) & 0x8000) != 0
        if current_pressed and not prev_pressed:
            with _state_lock:
                _logic_enabled = not _logic_enabled
            _current_step = "逻辑 " + ("开启" if _logic_enabled else "关闭")
        prev_pressed = current_pressed

        now = time.time()
        if not _logic_enabled:
            time.sleep(TOGGLE_INTERVAL)
            continue

        if now - last_logic_time < LOGIC_INTERVAL:
            time.sleep(TOGGLE_INTERVAL)
            continue
        last_logic_time = now

        state_dict = get_info()
        spec_name = None
        if state_dict:
            class_id = state_dict.get("职业")
            spec_id = state_dict.get("专精")
            config = load_config()
            _, spec_name = get_class_and_spec_name(config, class_id, spec_id)
            select_keymap_for_class(class_id)

        with _state_lock:
            _state_dict = state_dict or {}
            _spec_name = spec_name

        if not state_dict or not state_dict.get("有效性"):
            _current_step = "等待游戏状态"
            time.sleep(TOGGLE_INTERVAL)
            continue

        spells = state_dict.get("spells") or {}
        health_value = state_dict.get("生命值")
        energy_value = state_dict.get("能量值")
        assistant_value = state_dict.get("一键辅助")
        target_valid = state_dict.get("目标有效")
        combat = state_dict.get("战斗")
        casting = state_dict.get("施法")
        channeling = state_dict.get("引导")
        moving = state_dict.get("移动")
        action_hotkey = None
        _current_step = "无操作"  # 每轮重置，确保显示本轮决策

        if spec_name == "戒律":
            dispel_unit, dispel_data = get_unit_with_dispel_type(state_dict, 1)
            lowest_unit, lowest_unit_pct = get_lowest_health_unit(state_dict, 100)
            no_atonement_unit, no_atonement_pct = get_lowest_health_unit_without_aura(state_dict, "救赎", 100)
            no_shield_lowest_unit, no_shield_lowest_pct = get_lowest_health_unit_without_aura(state_dict, "真言术：盾", 100)
            no_shield_unit, no_shield_pct = get_lowest_health_unit_without_aura(state_dict, "真言术：盾", 101)
            no_atonement_count_90 = count_units_without_aura_below_health(state_dict, "救赎", 99)
            with _state_lock:
                _unit_info = {
                    "dispel_unit": dispel_unit,
                    "lowest_unit": lowest_unit,
                    "lowest_unit_pct": lowest_unit_pct,
                    "no_atonement_unit": no_atonement_unit,
                    "no_atonement_pct": no_atonement_pct,
                    "no_shield_lowest_unit": no_shield_lowest_unit,
                    "no_shield_lowest_pct": no_shield_lowest_pct,
                    "no_shield_unit": no_shield_unit,
                    "no_shield_pct": no_shield_pct,
                    "no_atonement_count_90": no_atonement_count_90,
                }

            if state_dict.get("引导") > 0:
                _current_step = "0. 在引导,不执行任何操作"
                action_hotkey = None
            elif spells.get("绝望祷言") == 0 and health_value < 50:
                _current_step = "2. 施放 绝望祷言"
                action_hotkey = get_hotkey(0, "绝望祷言")
            elif spells.get("纯净术") == 0 and dispel_unit is not None:
                _current_step = f"3. 施放 纯净术 on {dispel_unit}"
                action_hotkey = get_hotkey(int(dispel_unit), "纯净术")
            elif spells.get("福音") == 0 and no_atonement_count_90 >= 3:
                _current_step = "5. 施放 福音"
                action_hotkey = get_hotkey(0, "福音")
            elif spells.get("真言术：耀") == 0 and state_dict.get("施法") == 0 and no_atonement_count_90 >= 3:
                _current_step = "4. 施放 真言术：耀"
                action_hotkey = get_hotkey(0, "真言术：耀")
            elif state_dict.get("圣光涌动") and no_atonement_unit is not None and no_atonement_pct is not None and no_atonement_pct < 90:
                _current_step = f"6. 施放 快速治疗 on {no_atonement_unit}, 无救赎生命低于90%的单位"
                action_hotkey = get_hotkey(int(no_atonement_unit), "快速治疗")
            elif state_dict.get("圣光涌动") and lowest_unit is not None and lowest_unit_pct is not None and lowest_unit_pct < 90:
                _current_step = f"7. 施放 快速治疗 on {lowest_unit}, 生命最低的单位"
                action_hotkey = get_hotkey(int(lowest_unit), "快速治疗")
            elif spells.get("真言术：盾") == 0 and no_atonement_unit is not None:
                _current_step = f"8. 施放 真言术：盾 on {no_atonement_unit}, 无救赎单位"
                action_hotkey = get_hotkey(int(no_atonement_unit), "真言术：盾")
            elif spells.get("真言术：盾") == 0 and no_shield_lowest_unit is not None:
                _current_step = f"9. 施放 真言术：盾 on {no_shield_lowest_unit}, 无盾生命最低的单位"
                action_hotkey = get_hotkey(int(no_shield_lowest_unit), "真言术：盾")
            elif spells.get("真言术：盾") == 0 and no_shield_unit is not None:
                _current_step = f"10. 施放 真言术：盾 on {no_shield_unit}, 无盾单位"
                action_hotkey = get_hotkey(int(no_shield_unit), "真言术：盾")
            elif spells.get("福音") == 0 and no_atonement_count_90 >= 1:
                _current_step = "5. 施放 福音"
                action_hotkey = get_hotkey(0, "福音")
            elif spells.get("真言术：耀") == 0 and state_dict.get("施法") == 0 and no_atonement_count_90 >= 1:
                _current_step = "4. 施放 真言术：耀"
                action_hotkey = get_hotkey(0, "真言术：耀")
            elif spells.get("苦修") == 0 and not state_dict.get("虚空之盾") and lowest_unit is not None and lowest_unit_pct is not None and lowest_unit_pct < 70:
                _current_step = f"13. 施放 苦修 on {lowest_unit}, 生命最低的单位"
                action_hotkey = get_hotkey(int(lowest_unit), "苦修")
            elif target_valid and combat:
                if assistant_value == 4:
                    _current_step = "14. 施放 暗言术：痛"
                    action_hotkey = get_hotkey(0, "暗言术：痛")
                elif spells.get("暗言术：灭") == 0:
                    _current_step = "15. 施放 暗言术：灭"
                    action_hotkey = get_hotkey(0, "暗言术：灭")
                elif not moving and spells.get("心灵震爆") == 0:
                    _current_step = "16. 施放 心灵震爆"
                    action_hotkey = get_hotkey(0, "心灵震爆")
                elif spells.get("苦修") == 0 and not state_dict.get("虚空之盾"):
                    _current_step = "17. 施放 苦修"
                    action_hotkey = get_hotkey(0, "苦修")
                elif not moving:
                    _current_step = "18. 施放 惩击"
                    action_hotkey = get_hotkey(0, "惩击")
                else:
                    _current_step = "战斗中-无匹配技能"
            elif assistant_value == 5:
                _current_step = "19. 施放 真言术：韧"
                action_hotkey = get_hotkey(0, "真言术：韧")
            else:
                _current_step = "20. 无匹配技能"

        elif spec_name == "暗影":
            with _state_lock:
                _unit_info = {}
            if state_dict.get("引导") > 0:
                _current_step = "在引导,不执行任何操作"
            elif spells.get("绝望祷言") == 0 and health_value < 50:
                _current_step = "施放 绝望祷言"
                action_hotkey = get_hotkey(0, "绝望祷言")
            elif assistant_value == 7:
                _current_step = "施放 真言术：韧"
                action_hotkey = get_hotkey(0, "真言术：韧")
            elif assistant_value == 3:
                _current_step = "施放 暗影形态"
                action_hotkey = get_hotkey(0, "暗影形态")
            elif combat and target_valid:
                action_map = {
                    1: ("吸血鬼之触", "吸血鬼之触"),
                    2: ("心灵震爆", "心灵震爆"),
                    4: ("暗言术：灭", "暗言术：灭"),
                    5: ("暗言术：痛", "暗言术：痛"),
                    6: ("暗言术：癫", "暗言术：癫"),
                    8: ("精神鞭笞", "精神鞭笞"),
                    9: ("虚空形态", "虚空形态"),
                    10: ("虚空洪流", "虚空洪流"),
                    11: ("触须猛击", "触须猛击"),
                    12: ("虚空冲击", "虚空冲击"),
                    13: ("虚空齐射", "虚空齐射"),
                }
                tup = action_map.get(assistant_value)
                if tup:
                    _current_step = f"施放 {tup[0]}"
                    action_hotkey = get_hotkey(0, tup[1])
                else:
                    _current_step = "战斗中-无匹配技能"

        elif spec_name == "奶德":
            dispel_unit_magic, _ = get_unit_with_dispel_type(state_dict, 1)
            dispel_unit_curse, _ = get_unit_with_dispel_type(state_dict, 2)
            dispel_unit_poison, _ = get_unit_with_dispel_type(state_dict, 4)
            lowest_unit, lowest_unit_pct = get_lowest_health_unit(state_dict, 100)
            swiftmend_lowest_unit, swiftmend_lowest_pct = get_lowest_health_unit_with_aura(state_dict, "迅捷治愈", health_threshold=101)
            no_regrowth_lowest_unit, no_regrowth_lowest_pct = get_lowest_health_unit_without_aura(state_dict, "愈合", health_threshold=101)
            no_rejuv_unit, no_rejuv_pct = get_lowest_health_unit_with_aura_count(state_dict, "回春术", 0, health_threshold=101)
            one_rejuv_unit, one_rejuv_pct = get_lowest_health_unit_with_aura_count(state_dict, "回春术", 1, health_threshold=101)
            no_lifebloom_tank, no_lifebloom_tank_pct = get_unit_with_role_and_without_aura_name(state_dict, 1, "生命绽放", reverse=False)
            has_lifebloom_unit, has_lifebloom_duration = get_unit_with_aura(state_dict, "生命绽放")
            count_units_below_health_90 = count_units_below_health(state_dict, 90)
            count_units_below_health_70 = count_units_below_health(state_dict, 70)
            
            with _state_lock:
                _unit_info = {
                    "dispel_unit_magic": dispel_unit_magic,
                    "lowest_unit": lowest_unit,
                    "swiftmend_lowest_unit": swiftmend_lowest_unit,
                    "swiftmend_lowest_pct": swiftmend_lowest_pct,
                    "no_regrowth_lowest_unit": no_regrowth_lowest_unit,
                    "no_regrowth_lowest_pct": no_regrowth_lowest_pct,
                    "no_rejuv_unit": no_rejuv_unit,
                    "no_rejuv_pct": no_rejuv_pct,
                    "one_rejuv_unit": one_rejuv_unit,
                    "one_rejuv_pct": one_rejuv_pct,
                    "no_lifebloom_tank": no_lifebloom_tank,
                }

            if state_dict.get("引导") > 0:
                _current_step = "在引导,不执行任何操作"
                action_hotkey = None
            elif spells.get("自然之愈") == 0 and dispel_unit_magic is not None:
                _current_step = f"施放 自然之愈 on {dispel_unit_magic}"
                action_hotkey = get_hotkey(int(dispel_unit_magic), "自然之愈")
            elif spells.get("自然之愈") == 0 and dispel_unit_curse is not None:
                _current_step = f"施放 自然之愈 on {dispel_unit_curse}"
                action_hotkey = get_hotkey(int(dispel_unit_curse), "自然之愈")
            elif spells.get("自然之愈") == 0 and dispel_unit_poison is not None:
                _current_step = f"施放 自然之愈 on {dispel_unit_poison}"
                action_hotkey = get_hotkey(int(dispel_unit_poison), "自然之愈")
            elif has_lifebloom_unit is not None and has_lifebloom_duration is not None and has_lifebloom_duration < 3:
                _current_step = f"施放 生命绽放 on {has_lifebloom_unit}"
                action_hotkey = get_hotkey(int(has_lifebloom_unit), "生命绽放")
            elif no_lifebloom_tank is not None:
                _current_step = f"施放 生命绽放 on {no_lifebloom_tank}"
                action_hotkey = get_hotkey(int(no_lifebloom_tank), "生命绽放")
            elif spells.get("激活") == 0 and combat and state_dict.get("姿态") == 0 and energy_value < 80:
                _current_step = f"施放 激活"
                action_hotkey = get_hotkey(0, "激活")
            elif state_dict.get("丛林之魂") and no_rejuv_unit is not None and no_rejuv_pct is not None:
                _current_step = f"施放 回春术 on {no_rejuv_unit}"
                action_hotkey = get_hotkey(int(no_rejuv_unit), "回春术")
            elif state_dict.get("丛林之魂") and one_rejuv_unit is not None and one_rejuv_pct is not None:
                _current_step = f"施放 回春术 on {one_rejuv_unit}"
                action_hotkey = get_hotkey(int(one_rejuv_unit), "回春术")
            elif spells.get("迅捷治愈") == 0 and swiftmend_lowest_unit is not None and swiftmend_lowest_pct is not None and swiftmend_lowest_pct < 90:
                _current_step = f"施放 迅捷治愈 on {swiftmend_lowest_unit}"
                action_hotkey = get_hotkey(int(swiftmend_lowest_unit), "迅捷治愈")
            elif spells.get("野性成长") == 0 and count_units_below_health_90 >= 2:
                _current_step = "施放 野性成长"
                action_hotkey = get_hotkey(0, "野性成长")            
            elif spells.get("万灵之召") == 0 and count_units_below_health_70 >= 2:
                _current_step = "施放 万灵之召"
                action_hotkey = get_hotkey(0, "万灵之召")
            elif casting == 0 and state_dict.get("节能施法") and no_regrowth_lowest_unit is not None and no_regrowth_lowest_pct is not None and no_regrowth_lowest_pct < 90:
                _current_step = f"施放 愈合 on {no_regrowth_lowest_unit}"
                action_hotkey = get_hotkey(int(no_regrowth_lowest_unit), "愈合")
            elif state_dict.get("自然迅捷") and no_regrowth_lowest_unit is not None and no_regrowth_lowest_pct is not None and no_regrowth_lowest_pct < 70:
                _current_step = f"施放 自然迅捷 on {no_regrowth_lowest_unit}"
                action_hotkey = get_hotkey(int(no_regrowth_lowest_unit), "愈合")
            elif spells.get("自然迅捷") == 0 and no_regrowth_lowest_unit is not None and no_regrowth_lowest_pct is not None and no_regrowth_lowest_pct < 70:
                _current_step = f"施放 自然迅捷"
                action_hotkey = get_hotkey(0, "自然迅捷")
            elif one_rejuv_unit is not None and one_rejuv_pct is not None and one_rejuv_pct < 80:
                _current_step = f"施放 回春术 on {one_rejuv_unit}"
                action_hotkey = get_hotkey(int(one_rejuv_unit), "回春术")
            elif no_rejuv_unit is not None and no_rejuv_pct is not None and no_rejuv_pct < 95:
                _current_step = f"施放 回春术 on {no_rejuv_unit}"
                action_hotkey = get_hotkey(int(no_rejuv_unit), "回春术")
            elif casting == 0 and no_regrowth_lowest_unit is not None and no_regrowth_lowest_pct is not None and no_regrowth_lowest_pct < 70:
                _current_step = f"施放 愈合 on {no_regrowth_lowest_unit}"
                action_hotkey = get_hotkey(int(no_regrowth_lowest_unit), "愈合")
            elif assistant_value == 7:
                _current_step = f"施放 野性印记"
                action_hotkey = get_hotkey(0, "野性印记")
            elif combat and target_valid:
                if state_dict.get("目标距离") == 1:
                    if state_dict.get("姿态") != 1:
                        _current_step = f"施放 猎豹形态"
                        action_hotkey = get_hotkey(0, "猎豹形态")
                    elif state_dict.get("姿态") == 1:
                        action_map = {
                            1: ("凶猛撕咬", "凶猛撕咬"),
                            2: ("割裂", "割裂"),
                            3: ("撕碎", "撕碎"),
                            4: ("斜掠", "斜掠"),
                        }
                        tup = action_map.get(assistant_value)
                        if tup:
                            _current_step = f"施放 {tup[0]}"
                            action_hotkey = get_hotkey(0, tup[1])
                        else:
                            _current_step = "战斗中-无匹配技能"
                elif state_dict.get("目标距离") == 2:
                    if assistant_value == 5:
                        _current_step = f"施放 月火术"
                        action_hotkey = get_hotkey(0, "月火术")
                    elif  assistant_value == 6:
                        _current_step = f"施放 愤怒"
                        action_hotkey = get_hotkey(0, "愤怒")
            else:
                _current_step = "无匹配技能"

        elif spec_name == "鲜血":
            with _state_lock:
                _unit_info = {}
            if state_dict.get("引导") > 0:
                _current_step = "在引导,不执行任何操作"
                action_hotkey = None
            elif combat and target_valid:
                action_map = {
                    1: ("心脏打击", "心脏打击"),
                    2: ("枯萎凋零", "枯萎凋零"),
                    3: ("死神的抚摸", "死神的抚摸"),
                    4: ("灵界打击", "灵界打击"),
                    5: ("符文刃舞", "符文刃舞"),
                    6: ("精髓分裂", "精髓分裂"),
                    7: ("血液沸腾", "血液沸腾"),
                    8: ("吸血鬼打击", "心脏打击"),
                }
                tup = action_map.get(assistant_value)
                if tup:
                    _current_step = f"施放 {tup[0]}"
                    action_hotkey = get_hotkey(0, tup[1])
                else:
                    _current_step = "战斗中-无匹配技能"
            else:
                _current_step = "非战斗状态,不执行任何操作"
                action_hotkey = None

        elif spec_name == "邪恶":
            with _state_lock:
                _unit_info = {}
            if state_dict.get("引导") > 0:
                _current_step = "在引导,不执行任何操作"
                action_hotkey = None
            elif not combat:
                _current_step = "非战斗状态,不执行任何操作"
                action_hotkey = None
            elif not target_valid:
                _current_step = "目标无效,不执行任何操作"
                action_hotkey = None
            elif combat and target_valid:
                if assistant_value == 1:
                    _current_step = "施放 亡者复生"
                    action_hotkey = get_hotkey(0, "亡者复生")
                elif state_dict.get("黑暗援助") == 1 and state_dict.get("生命值") <= 80:
                    _current_step = "施放 灵界打击"
                    action_hotkey = get_hotkey(0, "灵界打击")
                elif state_dict.get("生命值") <= 30 and state_dict.get("能量值") >= 40:
                    _current_step = "施放 灵界打击"
                    action_hotkey = get_hotkey(0, "灵界打击")
                elif assistant_value == 6:
                    _current_step = "施放 爆发"
                    action_hotkey = get_hotkey(0, "爆发")
                elif spells.get("黑暗突变") == 0:
                    _current_step = "施放 黑暗突变"
                    action_hotkey = get_hotkey(0, "黑暗突变")
                elif spells.get("腐化") == 0 and spells.get("腐化2") < 2:
                    _current_step = "施放 腐化"
                    action_hotkey = get_hotkey(0, "腐化")
                elif spells.get("灵魂收割") == 0 and state_dict.get("目标生命值") < 20:
                    _current_step = "施放 灵魂收割"
                    action_hotkey = get_hotkey(0, "灵魂收割")
                elif spells.get("腐化") == 0 and spells.get("黑暗突变") > 15:
                    _current_step = "施放 腐化2"
                    action_hotkey = get_hotkey(0, "腐化")
                elif state_dict.get("脓疮毒镰") == 1:
                    _current_step = "施放 脓疮打击"
                    action_hotkey = get_hotkey(0, "脓疮打击")
                elif (state_dict.get("末日突降") == 1 or state_dict.get("能量值") >= 80) and state_dict.get("敌人人数") < 3:
                    _current_step = "施放 凋零缠绕"
                    action_hotkey = get_hotkey(0, "凋零缠绕")
                elif (state_dict.get("末日突降") == 1 or state_dict.get("能量值") >= 80) and state_dict.get("敌人人数") >= 3:
                    _current_step = "施放 扩散"
                    action_hotkey = get_hotkey(0, "扩散")
                elif state_dict.get("禁断知识") == 1 and state_dict.get("能量值") >= 30 and state_dict.get("敌人人数") < 3:
                    _current_step = "施放 凋零缠绕"
                    action_hotkey = get_hotkey(0, "凋零缠绕")
                elif state_dict.get("禁断知识") == 1 and state_dict.get("能量值") >= 30 and state_dict.get("敌人人数") >= 3:
                    _current_step = "施放 扩散"
                    action_hotkey = get_hotkey(0, "扩散")
                elif state_dict.get("次级食尸鬼") == 0:
                    _current_step = "施放 脓疮打击"
                    action_hotkey = get_hotkey(0, "脓疮打击")
                elif  state_dict.get("次级食尸鬼") > 0:
                    _current_step = "施放 天灾打击"
                    action_hotkey = get_hotkey(0, "天灾打击")
                elif state_dict.get("能量值") >= 30:
                    _current_step = "施放 凋零缠绕"
                    action_hotkey = get_hotkey(0, "凋零缠绕")
                else:
                    _current_step = "战斗中-无匹配技能"
            else:
                _current_step = "非战斗状态,不执行任何操作"
                action_hotkey = None
        
        if action_hotkey:
            send_key_to_wow(action_hotkey)
        time.sleep(TOGGLE_INTERVAL)

# CustomTkinter 配色：深灰主题，文字高对比度
BG_DARK = "#1e1e1e"
BG_FRAME = "#2d2d2d"
FG_LIGHT = "#eaeaea"
GREEN = "#00d9a5"
RED = "#ff6b6b"
FG_DIM = "#94a3b8"
WINDOW_ALPHA = 1.0   # 1.0=文字不透明；若需背景半透明可调低（整窗同透明度）


def create_gui():
    ctk.set_appearance_mode("dark")
    ctk.set_default_color_theme("dark-blue")

    root = ctk.CTk()
    root.title("冬月")
    root.geometry("380x450")
    root.resizable(True, True)
    root.attributes("-topmost", True)
    root.configure(fg_color=BG_DARK)
    # 背景半透明，文字使用高对比度颜色保持清晰
    root.attributes("-alpha", WINDOW_ALPHA)

    main_frame = ctk.CTkFrame(root, fg_color="transparent")
    main_frame.pack(fill="both", expand=True, padx=12, pady=12)

    # ---- 1. 职业/专精 + 开关 ----
    top_frame = ctk.CTkFrame(main_frame, fg_color=BG_FRAME, corner_radius=8)
    top_frame.pack(fill="x", pady=(0, 6))

    inner_top = ctk.CTkFrame(top_frame, fg_color="transparent")
    inner_top.pack(fill="x", padx=12, pady=10)

    ctk.CTkLabel(inner_top, text="职业 / 专精", font=("Microsoft YaHei", 14, "bold"), text_color=FG_LIGHT).pack(side="left")

    spec_label = ctk.CTkLabel(inner_top, text="专精: -", font=("Microsoft YaHei", 14, "bold"), text_color=FG_LIGHT)
    spec_label.pack(side="left", padx=(12, 0))

    toggle_var = ctk.BooleanVar(value=False)

    def on_toggle():
        with _state_lock:
            global _logic_enabled
            _logic_enabled = toggle_var.get()
        status_label.configure(text=f"状态: {'开启' if _logic_enabled else '关闭'}",
                              text_color=GREEN if _logic_enabled else RED)

    ctk.CTkCheckBox(
        inner_top,
        text="逻辑开启 (也可用 X2 切换)",
        variable=toggle_var,
        command=on_toggle,
        font=("Microsoft YaHei", 12),
        text_color=FG_LIGHT,
        fg_color=BG_DARK,
    ).pack(side="right")

    def sync_toggle_from_logic():
        with _state_lock:
            v = _logic_enabled
        if toggle_var.get() != v:
            toggle_var.set(v)
            status_label.configure(text=f"状态: {'开启' if v else '关闭'}",
                                  text_color=GREEN if v else RED)

    # ---- 2. 状态区域（未检测到职业时不显示）----
    content_frame = ctk.CTkFrame(main_frame, fg_color="transparent")
    # 不 pack content_frame，等检测到职业后再显示

    status_frame = ctk.CTkFrame(content_frame, fg_color=BG_FRAME, corner_radius=8)

    status_frame.pack(fill="both", expand=True, pady=(0, 6))

    status_header = ctk.CTkFrame(status_frame, fg_color="transparent")
    status_header.pack(fill="x", padx=12, pady=(10, 2))
    ctk.CTkLabel(status_header, text="实时状态", font=("Microsoft YaHei", 13, "bold"), text_color=FG_LIGHT).pack(side="left")
    status_label = ctk.CTkLabel(status_header, text="状态: 关闭", font=("Microsoft YaHei", 12), text_color=RED)
    status_label.pack(side="right")

    status_grid = ctk.CTkFrame(status_frame, fg_color="transparent")
    status_grid.pack(fill="x", padx=12, pady=4)

    status_vars = {}

    def update_status_display(keys):
        for w in status_grid.winfo_children():
            w.destroy()
        status_vars.clear()
        for i, k in enumerate(keys):
            row, col = i // 3, (i % 3) * 2
            ctk.CTkLabel(status_grid, text=k + ":", font=("Microsoft YaHei", 12), text_color=FG_DIM).grid(
                row=row, column=col, sticky="w", padx=(0, 4), pady=1)
            lbl = ctk.CTkLabel(status_grid, text="-", font=("Microsoft YaHei", 12), text_color=FG_LIGHT)
            lbl.grid(row=row, column=col + 1, sticky="w", padx=(0, 16), pady=1)
            status_vars[k] = lbl

    action_label = ctk.CTkLabel(status_frame, text="当前步骤: -", font=("Microsoft YaHei", 12), text_color=FG_LIGHT)
    action_label.pack(anchor="w", padx=12, pady=(8, 10))

    # ---- 单位信息 ----
    unit_info_frame = ctk.CTkFrame(content_frame, fg_color=BG_FRAME, corner_radius=8)
    unit_info_frame.pack(fill="x", pady=(0, 6))
    ctk.CTkLabel(unit_info_frame, text="单位信息", font=("Microsoft YaHei", 13, "bold"), text_color=FG_LIGHT).pack(
        anchor="w", padx=12, pady=(10, 2))

    unit_info_vars = {}
    unit_info_grid = ctk.CTkFrame(unit_info_frame, fg_color="transparent")
    unit_info_grid.pack(fill="x", padx=12, pady=10)

    def update_unit_info_display(keys):
        """根据专精动态重建单位信息区域"""
        for w in unit_info_grid.winfo_children():
            w.destroy()
        unit_info_vars.clear()
        for i, (key, label_cn) in enumerate(keys):
            row, col = i // 3, (i % 3) * 2
            ctk.CTkLabel(unit_info_grid, text=label_cn + ":", font=("Microsoft YaHei", 11), text_color=FG_DIM).grid(
                row=row, column=col, sticky="w", padx=(0, 4), pady=1)
            lbl = ctk.CTkLabel(unit_info_grid, text="-", font=("Microsoft YaHei", 11), text_color=FG_LIGHT)
            lbl.grid(row=row, column=col + 1, sticky="w", padx=(0, 12), pady=1)
            unit_info_vars[key] = lbl

    # ---- 3. 技能冷却 ----
    spells_frame = ctk.CTkFrame(content_frame, fg_color=BG_FRAME, corner_radius=8)
    spells_frame.pack(fill="x", pady=(0, 6))

    ctk.CTkLabel(spells_frame, text="技能冷却", font=("Microsoft YaHei", 13, "bold"), text_color=FG_LIGHT).pack(
        anchor="w", padx=12, pady=(10, 2))
    spells_grid = ctk.CTkFrame(spells_frame, fg_color="transparent")
    spells_grid.pack(fill="x", padx=12, pady=(0, 10))

    spell_widgets = {}

    # ---- 4. Group（戒律/奶德等）----
    group_frame = ctk.CTkFrame(content_frame, fg_color=BG_FRAME, corner_radius=8)
    group_frame.pack(fill="both", expand=True, pady=(0, 6))
    group_grid = ctk.CTkFrame(group_frame, fg_color="transparent")
    group_grid.pack(fill="both", expand=True, padx=12, pady=10)
    group_vars = {}

    def update_group_display(num_units, fields):
        """根据专精动态重建 group 表格"""
        for w in group_grid.winfo_children():
            w.destroy()
        group_vars.clear()
        headers = [""] + fields
        for c, h in enumerate(headers):
            ctk.CTkLabel(group_grid, text=h, font=("Microsoft YaHei", 12, "bold"), text_color=FG_LIGHT).grid(
                row=0, column=c, padx=8, pady=2, sticky="w")
        for i in range(1, num_units + 1):
            row = i
            key = str(i)
            ctk.CTkLabel(group_grid, text=f"Unit {i}", font=("Microsoft YaHei", 11), text_color=FG_DIM).grid(
                row=row, column=0, padx=8, pady=2, sticky="w")
            group_vars[key] = {}
            for j, field in enumerate(fields):
                lbl = ctk.CTkLabel(group_grid, text="-", font=("Microsoft YaHei", 11), text_color=FG_LIGHT)
                lbl.grid(row=row, column=j + 1, padx=8, pady=2, sticky="w")
                group_vars[key][field] = lbl

    def update_spells_display(current_spells):
        for w in spells_grid.winfo_children():
            w.destroy()
        spell_widgets.clear()
        for i, name in enumerate(current_spells):
            row, col = i // 4, (i % 4) * 2
            ctk.CTkLabel(spells_grid, text=name + ":", font=("Microsoft YaHei", 11), text_color=FG_DIM).grid(
                row=row, column=col, sticky="w", padx=(0, 4), pady=1)
            lbl = ctk.CTkLabel(spells_grid, text="-", font=("Microsoft YaHei", 11), text_color=FG_LIGHT)
            lbl.grid(row=row, column=col + 1, sticky="w", padx=(0, 12), pady=1)
            spell_widgets[name] = lbl

    last_status_keys = [None]
    last_spell_list = [None]
    last_unit_info_keys = [None]
    last_group_config = [None]

    def update_display():
        sync_toggle_from_logic()
        with _state_lock:
            sd = dict(_state_dict)
            enabled = _logic_enabled
            spec = _spec_name

        spec_label.configure(text=f"专精: {spec or '-'}")
        if spec is None:
            if content_frame.winfo_ismapped():
                content_frame.pack_forget()
            root.after(GUI_UPDATE_MS, update_display)
            return
        if not content_frame.winfo_ismapped():
            content_frame.pack(fill="both", expand=True, pady=(0, 6))

        status_label.configure(text=f"状态: {'开启' if enabled else '关闭'}",
                              text_color=GREEN if enabled else RED)

        current_status_keys = get_status_keys_for_spec(spec)
        if last_status_keys[0] != current_status_keys:
            last_status_keys[0] = current_status_keys
            update_status_display(current_status_keys)

        current_unit_info_keys = get_unit_info_keys_for_spec(spec)
        if last_unit_info_keys[0] != current_unit_info_keys:
            last_unit_info_keys[0] = current_unit_info_keys
            update_unit_info_display(current_unit_info_keys)

        current_group_config = get_group_config_for_spec(spec)
        if last_group_config[0] != current_group_config:
            last_group_config[0] = current_group_config
            update_group_display(current_group_config[0], current_group_config[1])

        for k in status_vars:
            v = sd.get(k)
            txt = str(v) if v is not None else "-"
            status_vars[k].configure(text=txt, text_color=GREEN if v is True else (RED if v is False else FG_LIGHT))

        action_label.configure(text=f"当前步骤: {_current_step}")

        with _state_lock:
            ui = dict(_unit_info)
        for key in unit_info_vars:
            v = ui.get(key)
            unit_info_vars[key].configure(text=str(v) if v is not None else "-")
        specs_with_unit_info = ("戒律", "奶德")
        if spec not in specs_with_unit_info:
            unit_info_frame.pack_forget()
        else:
            if not unit_info_frame.winfo_ismapped():
                unit_info_frame.pack(fill="x", pady=(0, 6), before=spells_frame)

        spells = sd.get("spells") or {}
        current_spell_list = get_spells_for_spec(spec)
        specs_with_group = ("戒律", "奶德")
        if spec not in specs_with_group:
            group_frame.pack_forget()
        else:
            if not group_frame.winfo_ismapped():
                group_frame.pack(fill="both", expand=True, pady=(0, 6))

        if last_spell_list[0] != current_spell_list:
            last_spell_list[0] = current_spell_list
            update_spells_display(current_spell_list)

        for name, lbl in list(spell_widgets.items()):
            v = spells.get(name)
            lbl.configure(text=str(v) if v is not None else "-")

        group = sd.get("group") or {}
        num_units, fields = get_group_config_for_spec(spec)
        for i in range(1, num_units + 1):
            key = str(i)
            data = group.get(key) or {}
            for field in fields:
                if key in group_vars and field in group_vars[key]:
                    v = data.get(field)
                    group_vars[key][field].configure(text=str(v) if v is not None else "-")

        root.after(GUI_UPDATE_MS, update_display)

    default_keys = get_status_keys_for_spec(None)
    default_spells = get_spells_for_spec(None)
    default_unit_keys = get_unit_info_keys_for_spec(None)
    default_group_config = get_group_config_for_spec(None)
    update_status_display(default_keys)
    update_unit_info_display(default_unit_keys)
    update_group_display(default_group_config[0], default_group_config[1])
    update_spells_display(default_spells)
    last_status_keys[0] = default_keys
    last_spell_list[0] = default_spells
    last_unit_info_keys[0] = default_unit_keys
    last_group_config[0] = default_group_config
    root.after(0, update_display)

    def start_worker():
        try:
            _run_priest_loop()
        except Exception as e:
            print("Worker error:", e)

    worker = threading.Thread(target=start_worker, daemon=True)
    worker.start()

    root.mainloop()


if __name__ == "__main__":
    create_gui()
