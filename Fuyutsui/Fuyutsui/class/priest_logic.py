# -*- coding: utf-8 -*-
"""牧师职业的逻辑决策（戒律 / 暗影）。"""

from utils import (
    get_hotkey,
    get_unit_with_dispel_type,
    get_lowest_health_unit,
    get_lowest_health_unit_without_aura,
    count_units_without_aura_below_health,
)


def run_priest_logic(state_dict, spec_name):
    spells = state_dict.get("spells") or {}
    health_value = state_dict.get("生命值")
    energy_value = state_dict.get("能量值")
    assistant_value = state_dict.get("一键辅助")
    target_valid = state_dict.get("目标有效")
    combat = state_dict.get("战斗")
    casting = state_dict.get("施法")
    channeling = state_dict.get("引导")
    moving = state_dict.get("移动")

    # 默认返回：无操作
    action_hotkey = None
    current_step = "无匹配技能"
    unit_info = {}

    if spec_name == "戒律":
        dispel_unit, _ = get_unit_with_dispel_type(state_dict, 1)
        lowest_unit, lowest_unit_pct = get_lowest_health_unit(state_dict, 100)
        no_atonement_unit, no_atonement_pct = get_lowest_health_unit_without_aura(state_dict, "救赎", 100)
        no_shield_lowest_unit, no_shield_lowest_pct = get_lowest_health_unit_without_aura(state_dict, "真言术：盾", 100)
        no_shield_unit, no_shield_pct = get_lowest_health_unit_without_aura(state_dict, "真言术：盾", 101)
        no_atonement_count_90 = count_units_without_aura_below_health(state_dict, "救赎", 99)

        unit_info = {
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

        if channeling > 0:
            current_step = "引导,不执行任何操作"
        elif spells.get("绝望祷言") == 0 and health_value < 50:
            current_step = "施放 绝望祷言"
            action_hotkey = get_hotkey(0, "绝望祷言")
        elif spells.get("纯净术") == 0 and dispel_unit is not None:
            current_step = f"施放 纯净术 on {dispel_unit}"
            action_hotkey = get_hotkey(int(dispel_unit), "纯净术")
        elif spells.get("奥术洪流") == 0 and energy_value <= 90:
            current_step = "施放 奥术洪流"
            action_hotkey = get_hotkey(0, "奥术洪流")
        elif spells.get("福音") == 0 and no_atonement_count_90 >= 3:
            current_step = "施放 福音"
            action_hotkey = get_hotkey(0, "福音")
        elif spells.get("真言术：耀") == 0 and casting == 0 and no_atonement_count_90 >= 3:
            current_step = "施放 真言术：耀"
            action_hotkey = get_hotkey(0, "真言术：耀")
        elif state_dict.get("圣光涌动") and no_atonement_unit is not None and no_atonement_pct is not None and no_atonement_pct < 90:
            current_step = f"施放 快速治疗 on {no_atonement_unit}, 无救赎生命低于90%的单位"
            action_hotkey = get_hotkey(int(no_atonement_unit), "快速治疗")
        elif state_dict.get("圣光涌动") and lowest_unit is not None and lowest_unit_pct is not None and lowest_unit_pct < 90:
            current_step = f"施放 快速治疗 on {lowest_unit}, 生命最低的单位"
            action_hotkey = get_hotkey(int(lowest_unit), "快速治疗")
        elif spells.get("真言术：盾") == 0 and no_atonement_unit is not None:
            current_step = f"施放 真言术：盾 on {no_atonement_unit}, 无救赎单位"
            action_hotkey = get_hotkey(int(no_atonement_unit), "真言术：盾")
        elif spells.get("真言术：盾") == 0 and no_shield_lowest_unit is not None:
            current_step = f"施放 真言术：盾 on {no_shield_lowest_unit}, 无盾生命最低的单位"
            action_hotkey = get_hotkey(int(no_shield_lowest_unit), "真言术：盾")
        elif spells.get("真言术：盾") == 0 and no_shield_unit is not None:
            current_step = f"施放 真言术：盾 on {no_shield_unit}, 无盾单位"
            action_hotkey = get_hotkey(int(no_shield_unit), "真言术：盾")
        elif spells.get("福音") == 0 and no_atonement_count_90 >= 1:
            current_step = "施放 福音"
            action_hotkey = get_hotkey(0, "福音")
        elif spells.get("真言术：耀") == 0 and casting == 0 and no_atonement_count_90 >= 1 and state_dict.get("队伍类型") == 46:
            current_step = "施放 真言术：耀"
            action_hotkey = get_hotkey(0, "真言术：耀")
        elif spells.get("苦修") == 0 and not state_dict.get("虚空之盾") and lowest_unit is not None and lowest_unit_pct is not None and lowest_unit_pct < 70:
            current_step = f"施放 苦修 on {lowest_unit}, 生命最低的单位"
            action_hotkey = get_hotkey(int(lowest_unit), "苦修")
        elif target_valid and combat:
            if assistant_value == 4:
                current_step = "施放 暗言术：痛"
                action_hotkey = get_hotkey(0, "暗言术：痛")
            elif spells.get("暗言术：灭") == 0:
                current_step = "施放 暗言术：灭"
                action_hotkey = get_hotkey(0, "暗言术：灭")
            elif not moving and spells.get("心灵震爆") == 0:
                current_step = "施放 心灵震爆"
                action_hotkey = get_hotkey(0, "心灵震爆")
            elif spells.get("苦修") == 0 and not state_dict.get("虚空之盾"):
                current_step = "施放 苦修"
                action_hotkey = get_hotkey(0, "苦修")
            elif not moving:
                current_step = "施放 惩击"
                action_hotkey = get_hotkey(0, "惩击")
            else:
                current_step = "战斗中-无匹配技能"
        elif assistant_value == 5:
            current_step = "施放 真言术：韧"
            action_hotkey = get_hotkey(0, "真言术：韧")

    elif spec_name == "暗影":
        # 暗影逻辑比较简单，不需要 unit_info
        if channeling > 0:
            current_step = "在引导,不执行任何操作"
        elif spells.get("绝望祷言") == 0 and health_value < 50:
            current_step = "施放 绝望祷言"
            action_hotkey = get_hotkey(0, "绝望祷言")
        elif assistant_value == 7:
            current_step = "施放 真言术：韧"
            action_hotkey = get_hotkey(0, "真言术：韧")
        elif assistant_value == 3:
            current_step = "施放 暗影形态"
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
                current_step = f"施放 {tup[0]}"
                action_hotkey = get_hotkey(0, tup[1])
            else:
                current_step = "战斗中-无匹配技能"

    return action_hotkey, current_step, unit_info
