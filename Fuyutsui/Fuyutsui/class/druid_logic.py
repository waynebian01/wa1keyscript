# -*- coding: utf-8 -*-
"""德鲁伊职业的逻辑决策（奶德 / 守护）。"""

from utils import (
    get_hotkey,
    get_unit_with_dispel_type,
    get_lowest_health_unit,
    get_lowest_health_unit_without_aura,
    get_lowest_health_unit_with_aura,
    get_lowest_health_unit_with_aura_count,
    get_unit_with_role_and_without_aura_name,
    get_unit_with_aura,
    count_units_below_health,
)


def run_druid_logic(state_dict, spec_name):
    spells = state_dict.get("spells") or {}
    health_value = state_dict.get("生命值")
    energy_value = state_dict.get("能量值")
    assistant_value = state_dict.get("一键辅助")
    target_valid = state_dict.get("目标有效")
    combat = state_dict.get("战斗")
    casting = state_dict.get("施法")
    channeling = state_dict.get("引导")

    action_hotkey = None
    current_step = "无匹配技能"
    unit_info = {}

    if spec_name == "守护":
        if channeling > 0:
            current_step = "在引导,不执行任何操作"
            return None, current_step, unit_info

        if combat and target_valid:
            if state_dict.get("姿态") != 5:
                current_step = "施放 熊形态"
                action_hotkey = get_hotkey(0, "熊形态")
            elif health_value < 85 and energy_value > 10 and spells.get("狂暴充能") < 3:
                current_step = "施放 狂暴充能"
                action_hotkey = get_hotkey(0, "狂暴回复")
            elif health_value < 60 and energy_value > 10 and spells.get("狂暴回复") < 1:
                current_step = "施放 狂暴回复"
                action_hotkey = get_hotkey(0, "狂暴回复")
            elif ((state_dict.get("铁鬃") < 2 and energy_value > 40) or energy_value > 80):
                current_step = "施放 铁鬃"
                action_hotkey = get_hotkey(0, "铁鬃")
            elif state_dict.get("节能施法") > 0 and spells.get("狂暴回复") > 15:
                current_step = "施放 愈合"
                action_hotkey = get_hotkey(1, "愈合")
            else:
                action_map = {
                    1: ("摧折", "摧折"),
                    2: ("明月普照", "明月普照"),
                    3: ("月火术", "月火术"),
                    4: ("横扫", "横扫"),
                    5: ("熊形态", "熊形态"),
                    6: ("痛击", "痛击"),
                    7: ("裂伤", "裂伤"),
                    8: ("野性印记", "野性印记"),
                }
                tup = action_map.get(assistant_value)
                if tup:
                    current_step = f"施放 {tup[0]}"
                    action_hotkey = get_hotkey(0, tup[1])
                else:
                    current_step = "战斗中-无匹配技能"
        else:
            current_step = "非战斗状态,不执行任何操作"

    elif spec_name == "奶德":
        dispel_unit_magic, _ = get_unit_with_dispel_type(state_dict, 1)
        dispel_unit_curse, _ = get_unit_with_dispel_type(state_dict, 2)
        dispel_unit_poison, _ = get_unit_with_dispel_type(state_dict, 4)
        lowest_unit, lowest_unit_pct = get_lowest_health_unit(state_dict, 100)
        swiftmend_lowest_unit, swiftmend_lowest_pct = get_lowest_health_unit_with_aura(state_dict, "迅捷治愈", health_threshold=101)
        no_regrowth_lowest_unit, no_regrowth_lowest_pct = get_lowest_health_unit_without_aura(state_dict, "愈合", health_threshold=101)
        no_rejuv_unit, no_rejuv_pct = get_lowest_health_unit_with_aura_count(state_dict, "回春术", 0, health_threshold=101)
        one_rejuv_unit, one_rejuv_pct = get_lowest_health_unit_with_aura_count(state_dict, "回春术", 1, health_threshold=101)
        no_lifebloom_tank, _ = get_unit_with_role_and_without_aura_name(state_dict, 1, "生命绽放", reverse=False)
        has_lifebloom_unit, has_lifebloom_duration = get_unit_with_aura(state_dict, "生命绽放")
        count_units_below_health_90 = count_units_below_health(state_dict, 90)
        count_units_below_health_70 = count_units_below_health(state_dict, 70)

        unit_info = {
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

        if channeling > 0:
            current_step = "在引导,不执行任何操作"
        elif spells.get("自然之愈") == 0 and dispel_unit_magic is not None:
            current_step = f"施放 自然之愈 on {dispel_unit_magic}"
            action_hotkey = get_hotkey(int(dispel_unit_magic), "自然之愈")
        elif spells.get("自然之愈") == 0 and dispel_unit_curse is not None:
            current_step = f"施放 自然之愈 on {dispel_unit_curse}"
            action_hotkey = get_hotkey(int(dispel_unit_curse), "自然之愈")
        elif spells.get("自然之愈") == 0 and dispel_unit_poison is not None:
            current_step = f"施放 自然之愈 on {dispel_unit_poison}"
            action_hotkey = get_hotkey(int(dispel_unit_poison), "自然之愈")
        elif has_lifebloom_unit is not None and has_lifebloom_duration is not None and has_lifebloom_duration < 3:
            current_step = f"施放 生命绽放 on {has_lifebloom_unit}"
            action_hotkey = get_hotkey(int(has_lifebloom_unit), "生命绽放")
        elif no_lifebloom_tank is not None:
            current_step = f"施放 生命绽放 on {no_lifebloom_tank}"
            action_hotkey = get_hotkey(int(no_lifebloom_tank), "生命绽放")
        elif casting == 0 and 0 < state_dict.get("节能施法") < 5 and no_regrowth_lowest_unit is not None and no_regrowth_lowest_pct is not None and no_regrowth_lowest_pct < 90:
            current_step = f"施放 愈合 on {no_regrowth_lowest_unit}"
            action_hotkey = get_hotkey(int(no_regrowth_lowest_unit), "愈合")
        elif spells.get("激活") == 0 and combat and state_dict.get("姿态") == 0 and energy_value < 80:
            current_step = "施放 激活"
            action_hotkey = get_hotkey(0, "激活")
        elif state_dict.get("丛林之魂") is not None and state_dict.get("丛林之魂") > 0 and no_rejuv_unit is not None and no_rejuv_pct is not None:
            current_step = f"施放 回春术 on {no_rejuv_unit}"
            action_hotkey = get_hotkey(int(no_rejuv_unit), "回春术")
        elif spells.get("迅捷治愈") == 0 and swiftmend_lowest_unit is not None and swiftmend_lowest_pct is not None and swiftmend_lowest_pct < 90:
            current_step = f"施放 迅捷治愈 on {swiftmend_lowest_unit}"
            action_hotkey = get_hotkey(int(swiftmend_lowest_unit), "迅捷治愈")
        elif spells.get("野性成长") == 0 and count_units_below_health_90 >= 2:
            current_step = "施放 野性成长"
            action_hotkey = get_hotkey(0, "野性成长")
        elif spells.get("万灵之召") == 0 and count_units_below_health_70 >= 2:
            current_step = "施放 万灵之召"
            action_hotkey = get_hotkey(0, "万灵之召")
        elif casting == 0 and 4 < state_dict.get("节能施法") < 15 and no_regrowth_lowest_unit is not None and no_regrowth_lowest_pct is not None and no_regrowth_lowest_pct < 80:
            current_step = f"施放 愈合 on {no_regrowth_lowest_unit}"
            action_hotkey = get_hotkey(int(no_regrowth_lowest_unit), "愈合")
        elif spells.get("自然迅捷") == 255 and no_regrowth_lowest_unit is not None and no_regrowth_lowest_pct is not None and no_regrowth_lowest_pct < 70:
            current_step = f"施放 自然迅捷 on {no_regrowth_lowest_unit}"
            action_hotkey = get_hotkey(int(no_regrowth_lowest_unit), "愈合")
        elif spells.get("自然迅捷") == 0 and no_regrowth_lowest_unit is not None and no_regrowth_lowest_pct is not None and no_regrowth_lowest_pct < 70:
            current_step = "施放 自然迅捷"
            action_hotkey = get_hotkey(0, "自然迅捷")
        elif one_rejuv_unit is not None and one_rejuv_pct is not None and one_rejuv_pct < 80:
            current_step = f"施放 回春术 on {one_rejuv_unit}"
            action_hotkey = get_hotkey(int(one_rejuv_unit), "回春术")
        elif no_rejuv_unit is not None and no_rejuv_pct is not None and no_rejuv_pct < 95:
            current_step = f"施放 回春术 on {no_rejuv_unit}"
            action_hotkey = get_hotkey(int(no_rejuv_unit), "回春术")
        elif casting == 0 and no_regrowth_lowest_unit is not None and no_regrowth_lowest_pct is not None and no_regrowth_lowest_pct < 70:
            current_step = f"施放 愈合 on {no_regrowth_lowest_unit}"
            action_hotkey = get_hotkey(int(no_regrowth_lowest_unit), "愈合")
        elif assistant_value == 7:
            current_step = "施放 野性印记"
            action_hotkey = get_hotkey(0, "野性印记")
        elif combat and target_valid:
            if assistant_value == 4:
                current_step = "施放 斜掠"
                action_hotkey = get_hotkey(0, "斜掠")
            elif state_dict.get("目标距离") == 1:
                if state_dict.get("姿态") != 1:
                    current_step = "施放 猎豹形态"
                    action_hotkey = get_hotkey(0, "猎豹形态")
                elif state_dict.get("姿态") == 1 and state_dict.get("连击点") <= 1 and spells.get("野性之心") == 0:
                    current_step = "施放 野性之心"
                    action_hotkey = get_hotkey(0, "野性之心")
                elif state_dict.get("姿态") == 1:
                    action_map = {
                        1: ("凶猛撕咬", "凶猛撕咬"),
                        2: ("割裂", "割裂"),
                        3: ("撕碎", "撕碎"),
                        4: ("斜掠", "斜掠"),
                    }
                    tup = action_map.get(assistant_value)
                    if tup:
                        current_step = f"施放 {tup[0]}"
                        action_hotkey = get_hotkey(0, tup[1])
                    else:
                        current_step = "战斗中-无匹配技能"
            elif state_dict.get("目标距离") == 2:
                if assistant_value == 5:
                    current_step = "施放 月火术"
                    action_hotkey = get_hotkey(0, "月火术")
                elif assistant_value == 6:
                    current_step = "施放 愤怒"
                    action_hotkey = get_hotkey(0, "愤怒")
        else:
            current_step = "无匹配技能"

    return action_hotkey, current_step, unit_info
