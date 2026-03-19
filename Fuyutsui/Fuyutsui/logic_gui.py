# -*- coding: utf-8 -*-
"""
通用 GUI：根据职业/专精自动适配显示。
使用 CustomTkinter，背景半透明，文字保持清晰。
"""
import threading
import time
import ctypes
import customtkinter as ctk

import importlib

from utils import *
from GetPixels import get_info


def _load_logic_module(module_name: str):
    """Load a class-specific logic module from the `class/` package."""
    m = importlib.import_module(f"class.{module_name}")
    # Expected API: run_<class>_logic
    return getattr(m, f"run_{module_name.replace('_logic', '')}_logic")

run_priest_logic = _load_logic_module("priest_logic")
run_druid_logic = _load_logic_module("druid_logic")
run_paladin_logic = _load_logic_module("paladin_logic")
run_deathknight_logic = _load_logic_module("deathknight_logic")

TOGGLE_INTERVAL = 0.05
LOGIC_INTERVAL = 0.2
GUI_UPDATE_MS = 150

LOGIC_FUNCS_BY_SPEC = {
    "戒律": run_priest_logic,
    "暗影": run_priest_logic,
    "奶德": run_druid_logic,
    "守护": run_druid_logic,
    "神圣": run_paladin_logic,
    "鲜血": run_deathknight_logic,
    "邪恶": run_deathknight_logic,
}


def _default_logic(state_dict, spec_name):
    return None, "无逻辑定义", {}


toggle_key_str = "XBUTTON2"
vk_toggle = get_vk(toggle_key_str)

_state_lock = threading.Lock()
_logic_enabled = False
_state_dict = {}
_class_name = None
_spec_name = None
_current_step = ""  # 当前步骤，每次逻辑循环都会更新
_unit_info = {}  # 单位信息，供 GUI 显示

# 戒律专精技能
DISCIPLINE_SPELLS = [
    "真言术：盾", "苦修", "真言术：耀", "纯净术",
    "绝望祷言", "心灵震爆", "福音", "暗言术：灭", "奥术洪流",
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
# 守护德鲁伊技能 (config 11.3)
GUARDIAN_DRUID_SPELLS = [
    "树皮术", "生存本能", "台风", "夺魂咆哮", "化身",
    "激活", "野性之心",  "狂暴回复", "狂暴充能",
]
# 神圣骑士技能 (config 2.1)
HOLY_PALADIN_SPELLS = [
    "神圣震击", "震击充能", "审判", "圣洁鸣钟", "神圣棱镜",
    "清洁术", "盲目之光", "光环掌握", "牺牲祝福", "自由祝福",
]
# 各专精的 status_keys (config 中的状态字段)
STATUS_KEYS_BY_SPEC = {
    "戒律": ["生命值", "能量值", "有效性", "战斗", "移动", "施法", "引导",
             "虚空之盾", "圣光涌动", "目标有效", "一键辅助", "队伍类型", "队伍人数"],
    "暗影": ["生命值", "能量值", "有效性", "战斗", "移动", "施法", "引导",
             "目标有效", "一键辅助"],
    "邪恶": ["生命值", "能量值", "有效性", "战斗", "移动", "符文",
             "一键辅助", "目标有效", "目标生命值", "敌人人数", "脓疮毒镰",
             "次级食尸鬼", "末日突降", "黑暗援助", "禁断知识"],
    "鲜血": ["生命值", "能量值", "有效性", "战斗", "移动", "符文",
             "一键辅助", "目标有效", "目标生命值", "敌人人数"],
    "奶德": ["生命值", "能量值", "有效性", "战斗", "移动", "施法", "引导",
             "目标有效","目标距离", "一键辅助", "队伍类型", "姿态", "队伍人数",
             "自然迅捷", "丛林之魂", "节能施法", "连击点"],
    "守护": ["生命值", "能量值", "有效性", "战斗", "移动", "施法", "引导",
             "目标有效", "目标生命值", "敌人人数", "姿态", "一键辅助", "铁鬃",
             "回复狂暴", "塞纳留斯的梦境", "铁鬃之赐", "重殴之赐", "狂暴回复之赐", "节能施法"],
    "神圣": ["生命值", "能量值", "有效性", "战斗", "移动", "施法", "引导",
             "神圣能量", "神圣意志", "圣光灌注", "神性之手",
             "目标有效", "队伍类型", "队伍人数"],
}

# 各专精的技能列表（用于技能冷却显示）
SPELLS_BY_SPEC = {
    "戒律": DISCIPLINE_SPELLS,
    "暗影": SHADOW_SPELLS,
    "邪恶": UNHOLY_SPELLS,
    "鲜血": BLOOD_SPELLS,
    "奶德": RESTORATION_DRUID_SPELLS,
    "守护": GUARDIAN_DRUID_SPELLS,
    "神圣": HOLY_PALADIN_SPELLS,
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
    "神圣": [
        ("dispel_unit", "需驱散单位"),
        ("lowest_unit", "生命最低单位"),
        ("lowest_unit_pct", "生命最低%"),
    ],
}

# 各专精的 group 配置 (num_units, fields)
GROUP_CONFIG_BY_SPEC = {
    "戒律": (5, ["生命值", "职责", "驱散", "救赎", "真言术：盾"]),
    "奶德": (5, ["生命值", "职责", "驱散", "回春术", "愈合", "生命绽放"]),
    "神圣": (5, ["生命值", "职责", "驱散", "永恒之火", "救世道标", "圣光道标"]),
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
    global _logic_enabled, _state_dict, _class_name, _spec_name, _current_step, _unit_info
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
        if now - last_logic_time >= LOGIC_INTERVAL:
            last_logic_time = now
            state_dict = get_info()
            class_name, spec_name = None, None
            if state_dict:
                class_id = state_dict.get("职业")
                spec_id = state_dict.get("专精")
                config = load_config()
                class_name, spec_name = get_class_and_spec_name(config, class_id, spec_id)
                select_keymap_for_class(class_id)

            with _state_lock:
                _state_dict = state_dict or {}
                _class_name = class_name
                _spec_name = spec_name

        if not _logic_enabled:
            time.sleep(TOGGLE_INTERVAL)
            continue

        sd = _state_dict
        if not sd or not sd.get("有效性"):
            _current_step = "等待游戏状态"
            time.sleep(TOGGLE_INTERVAL)
            continue

        state_dict = sd
        spec_name = _spec_name
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

        logic_func = LOGIC_FUNCS_BY_SPEC.get(spec_name, _default_logic)
        action_hotkey, _current_step, unit_info_update = logic_func(state_dict, spec_name)
        if unit_info_update:
            with _state_lock:
                _unit_info = unit_info_update

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
    root.geometry("400x600")
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

    class_label = ctk.CTkLabel(inner_top, text="职业: -", font=("Microsoft YaHei", 14, "bold"), text_color=FG_LIGHT)
    class_label.pack(side="left", padx=(12, 0))
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

    # ---- 技能冷却 ----
    cooldown_frame = ctk.CTkFrame(content_frame, fg_color=BG_FRAME, corner_radius=8)
    cooldown_frame.pack(fill="x", pady=(0, 6))
    cooldown_header = ctk.CTkFrame(cooldown_frame, fg_color="transparent")
    cooldown_header.pack(fill="x", padx=12, pady=(10, 2))
    ctk.CTkLabel(cooldown_header, text="技能冷却", font=("Microsoft YaHei", 13, "bold"), text_color=FG_LIGHT).pack(side="left")
    cooldown_grid = ctk.CTkFrame(cooldown_frame, fg_color="transparent")
    cooldown_grid.pack(fill="x", padx=12, pady=(4, 10))
    cooldown_vars = {}

    COOLDOWN_PER_ROW = 3

    def update_cooldown_display(spell_list):
        """根据专精技能列表重建冷却显示，每行 3 个技能"""
        for w in cooldown_grid.winfo_children():
            w.destroy()
        cooldown_vars.clear()
        if not spell_list:
            return
        for i, name in enumerate(spell_list):
            row = i // COOLDOWN_PER_ROW
            col = (i % COOLDOWN_PER_ROW) * 2
            ctk.CTkLabel(cooldown_grid, text=name + ":", font=("Microsoft YaHei", 11), text_color=FG_DIM).grid(
                row=row, column=col, sticky="w", padx=(0, 4), pady=1)
            lbl = ctk.CTkLabel(cooldown_grid, text="-", font=("Microsoft YaHei", 11), text_color=FG_LIGHT)
            lbl.grid(row=row, column=col + 1, sticky="w", padx=(0, 16), pady=1)
            cooldown_vars[name] = lbl

    last_cooldown_spells = [None]

    # ---- Group（戒律/奶德等）----
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

    last_status_keys = [None]
    last_group_config = [None]

    def update_display():
        sync_toggle_from_logic()
        with _state_lock:
            sd = dict(_state_dict)
            enabled = _logic_enabled
            class_name = _class_name
            spec = _spec_name

        class_label.configure(text=f"职业: {class_name or '-'}")
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

        current_group_config = get_group_config_for_spec(spec)
        if last_group_config[0] != current_group_config:
            last_group_config[0] = current_group_config
            update_group_display(current_group_config[0], current_group_config[1])

        current_cooldown_spells = get_spells_for_spec(spec)
        if last_cooldown_spells[0] != current_cooldown_spells:
            last_cooldown_spells[0] = current_cooldown_spells
            update_cooldown_display(current_cooldown_spells)

        spells_data = sd.get("spells") or {}
        for name, lbl in cooldown_vars.items():
            val = spells_data.get(name)
            if val is None:
                lbl.configure(text="-", text_color=FG_DIM)
            else:
                lbl.configure(text=str(int(val)), text_color=FG_LIGHT)

        for k in status_vars:
            v = sd.get(k)
            txt = str(v) if v is not None else "-"
            status_vars[k].configure(text=txt, text_color=GREEN if v is True else (RED if v is False else FG_LIGHT))

        action_label.configure(text=f"当前步骤: {_current_step}")

        specs_with_group = ("戒律", "奶德", "神圣")
        if spec not in specs_with_group:
            group_frame.pack_forget()
        else:
            if not group_frame.winfo_ismapped():
                group_frame.pack(fill="both", expand=True, pady=(0, 6))

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
    default_group_config = get_group_config_for_spec(None)
    update_status_display(default_keys)
    update_group_display(default_group_config[0], default_group_config[1])
    last_status_keys[0] = default_keys
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
