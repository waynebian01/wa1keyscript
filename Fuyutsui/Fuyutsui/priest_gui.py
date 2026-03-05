# -*- coding: utf-8 -*-
"""
牧师通用 GUI：根据职业/专精自动适配显示，支持戒律与暗影。
"""
import threading
import time
import ctypes
import tkinter as tk
from tkinter import ttk

from utils import (
    load_config,
    get_class_and_spec_name,
    select_keymap_for_class,
    get_unit_with_dispel_type,
    get_lowest_health_unit,
    get_lowest_health_unit_without_aura,
    count_units_without_aura_below_health,
    get_hotkey,
    send_key_to_wow,
    get_vk,
)
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
_last_action = ""
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


def _run_priest_loop():
    """后台运行的牧师主循环（戒律+暗影自动适配）"""
    global _logic_enabled, _state_dict, _spec_name, _last_action, _unit_info
    prev_pressed = False
    last_logic_time = 0.0

    while True:
        current_pressed = (ctypes.windll.user32.GetAsyncKeyState(vk_toggle) & 0x8000) != 0
        if current_pressed and not prev_pressed:
            with _state_lock:
                _logic_enabled = not _logic_enabled
            _last_action = "逻辑 " + ("开启" if _logic_enabled else "关闭")
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
            time.sleep(TOGGLE_INTERVAL)
            continue

        spells = state_dict.get("spells") or {}
        assistant_value = state_dict.get("一键辅助")
        target_valid = state_dict.get("目标有效")
        combat = state_dict.get("战斗")
        moving = state_dict.get("移动")
        action_hotkey = None

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
                _last_action = "在引导,不执行任何操作"
                action_hotkey = None
            elif spells.get("绝望祷言") == 0 and state_dict.get("生命值") < 50:
                _last_action = "施放 绝望祷言"
                action_hotkey = get_hotkey(0, "绝望祷言")
            elif spells.get("纯净术") == 0 and dispel_unit is not None:
                _last_action = f"施放 纯净术 on {dispel_unit}"
                action_hotkey = get_hotkey(int(dispel_unit), "纯净术")
            elif spells.get("真言术：耀") == 0 and state_dict.get("施法") == 0 and no_atonement_count_90 >= 3:
                _last_action = "施放 真言术：耀"
                action_hotkey = get_hotkey(0, "真言术：耀")
            elif spells.get("福音") == 0 and spells.get("真言术：耀") > 3 and no_atonement_count_90 >= 3:
                _last_action = "施放 福音"
                action_hotkey = get_hotkey(0, "福音")
            elif state_dict.get("圣光涌动") and no_atonement_unit is not None and no_atonement_pct is not None and no_atonement_pct < 90:
                _last_action = f"施放 快速治疗 on {no_atonement_unit}"
                action_hotkey = get_hotkey(int(no_atonement_unit), "快速治疗")
            elif state_dict.get("圣光涌动") and lowest_unit is not None and lowest_unit_pct is not None and lowest_unit_pct < 90:
                _last_action = f"施放 快速治疗 on {lowest_unit}"
                action_hotkey = get_hotkey(int(lowest_unit), "快速治疗")
            elif spells.get("真言术：盾") == 0 and no_atonement_unit is not None:
                _last_action = f"施放 真言术：盾 on {no_atonement_unit}"
                action_hotkey = get_hotkey(int(no_atonement_unit), "真言术：盾")
            elif spells.get("真言术：盾") == 0 and no_shield_lowest_unit is not None:
                _last_action = f"施放 真言术：盾 on {no_shield_lowest_unit}"
                action_hotkey = get_hotkey(int(no_shield_lowest_unit), "真言术：盾")
            elif spells.get("真言术：盾") == 0 and no_shield_unit is not None:
                _last_action = f"施放 真言术：盾 on {no_shield_unit}"
                action_hotkey = get_hotkey(int(no_shield_unit), "真言术：盾")
            elif spells.get("真言术：耀") == 0 and state_dict.get("施法") == 0 and no_atonement_count_90 >= 1:
                _last_action = "施放 真言术：耀"
                action_hotkey = get_hotkey(0, "真言术：耀")
            elif spells.get("福音") == 0 and spells.get("真言术：耀") > 3 and no_atonement_count_90 >= 1:
                _last_action = "施放 福音"
                action_hotkey = get_hotkey(0, "福音")
            elif lowest_unit is not None and lowest_unit_pct is not None and lowest_unit_pct < 70 and not state_dict.get("虚空之盾"):
                _last_action = f"施放 苦修 on {lowest_unit}"
                action_hotkey = get_hotkey(int(lowest_unit), "苦修")
            elif target_valid and combat:
                if assistant_value == 4:
                    _last_action = "施放 暗言术：痛"
                    action_hotkey = get_hotkey(0, "暗言术：痛")
                elif spells.get("暗言术：灭") == 0:
                    _last_action = "施放 暗言术：灭"
                    action_hotkey = get_hotkey(0, "暗言术：灭")
                elif not moving and spells.get("心灵震爆") == 0:
                    _last_action = "施放 心灵震爆"
                    action_hotkey = get_hotkey(0, "心灵震爆")
                elif spells.get("苦修") == 0 and not state_dict.get("虚空之盾"):
                    _last_action = "施放 苦修"
                    action_hotkey = get_hotkey(0, "苦修")
                elif not moving:
                    _last_action = "施放 惩击"
                    action_hotkey = get_hotkey(0, "惩击")
            elif assistant_value == 5:
                _last_action = "施放 真言术：韧"
                action_hotkey = get_hotkey(0, "真言术：韧")

        elif spec_name == "暗影":
            with _state_lock:
                _unit_info = {}
            if state_dict.get("引导") == 1:
                _last_action = "在引导,不执行任何操作"
            elif spells.get("绝望祷言") == 0 and state_dict.get("生命值") < 50:
                _last_action = "施放 绝望祷言"
                action_hotkey = get_hotkey(0, "绝望祷言")
            elif assistant_value == 7:
                _last_action = "施放 真言术：韧"
                action_hotkey = get_hotkey(0, "真言术：韧")
            elif assistant_value == 3:
                _last_action = "施放 暗影形态"
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
                    _last_action = f"施放 {tup[0]}"
                    action_hotkey = get_hotkey(0, tup[1])

        if action_hotkey:
            send_key_to_wow(action_hotkey)

        time.sleep(TOGGLE_INTERVAL)

# 暗色主题配色
BG_DARK = "#1e1e1e"
BG_FRAME = "#2d2d2d"
FG_LIGHT = "#e0e0e0"
FG_DIM = "#a0a0a0"
GREEN = "#4ec9b0"
RED = "#f14c4c"


def create_gui():
    root = tk.Tk()
    root.title("冬月")
    root.geometry("700x850")
    root.resizable(True, True)
    root.attributes("-topmost", True)
    root.configure(bg=BG_DARK)

    style = ttk.Style()
    style.theme_use("clam")
    style.configure(".", background=BG_FRAME, foreground=FG_LIGHT)
    style.configure("TFrame", background=BG_FRAME)
    style.configure("TLabelframe", background=BG_FRAME, foreground=FG_LIGHT)
    style.configure("TLabelframe.Label", background=BG_FRAME, foreground=FG_LIGHT, font=("Microsoft YaHei", 9))
    style.configure("TLabel", background=BG_FRAME, foreground=FG_LIGHT)
    style.configure("TCheckbutton", background=BG_FRAME, foreground=FG_LIGHT)
    style.configure("Title.TLabel", font=("Microsoft YaHei", 11, "bold"), background=BG_FRAME, foreground=FG_LIGHT)
    style.configure("Status.TLabel", font=("Consolas", 9), background=BG_FRAME, foreground=FG_LIGHT)
    style.configure("Group.TLabel", font=("Consolas", 9), background=BG_FRAME, foreground=FG_LIGHT)
    style.configure("StatusTrue.TLabel", font=("Consolas", 9), background=BG_FRAME, foreground=GREEN)
    style.configure("StatusFalse.TLabel", font=("Consolas", 9), background=BG_FRAME, foreground=RED)
    style.configure("StatusOn.TLabel", font=("Consolas", 9), background=BG_FRAME, foreground=GREEN)
    style.configure("StatusOff.TLabel", font=("Consolas", 9), background=BG_FRAME, foreground=RED)

    main_frame = ttk.Frame(root, padding="10 10 10 10")
    main_frame.pack(fill=tk.BOTH, expand=True)

    # ---- 1. 职业/专精 + 开关 ----
    top_frame = ttk.LabelFrame(main_frame, text="职业 / 专精", padding="5 5 5 5")
    top_frame.pack(fill=tk.X, pady=(0, 5))

    spec_label = ttk.Label(top_frame, text="专精: -", style="Title.TLabel")
    spec_label.pack(side=tk.LEFT, padx=5, pady=3)

    toggle_var = tk.BooleanVar(value=False)

    def on_toggle():
        with _state_lock:
            global _logic_enabled
            _logic_enabled = toggle_var.get()
        status_text = "开启" if _logic_enabled else "关闭"
        status_label.config(text=f"状态: {status_text}")

    ttk.Checkbutton(
        top_frame,
        text="逻辑开启 (也可用 X2 切换)",
        variable=toggle_var,
        command=on_toggle,
    ).pack(side=tk.RIGHT, padx=5, pady=3)

    def sync_toggle_from_logic():
        with _state_lock:
            v = _logic_enabled
        if toggle_var.get() != v:
            toggle_var.set(v)
            status_label.config(text=f"状态: {'开启' if v else '关闭'}")

    # ---- 2. 状态区域 ----
    status_frame = ttk.LabelFrame(main_frame, text="实时状态", padding="5 5 5 5")
    status_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 5))

    status_label = ttk.Label(status_frame, text="状态: 关闭", style="Status.TLabel")
    status_label.pack(anchor=tk.W)

    status_grid = ttk.Frame(status_frame)
    status_grid.pack(fill=tk.X, pady=2)

    status_keys = [
        "生命值", "能量值",
        "有效性", "战斗", "移动", "施法", "引导",
        "虚空之盾", "圣光涌动", "目标有效", "一键辅助",
    ]
    status_vars = {}
    for i, k in enumerate(status_keys):
        row, col = i // 3, (i % 3) * 2
        ttk.Label(status_grid, text=k + ":").grid(row=row, column=col, sticky=tk.W, padx=(0, 2))
        lbl = ttk.Label(status_grid, text="-", style="Status.TLabel", width=6)
        lbl.grid(row=row, column=col + 1, sticky=tk.W)
        status_vars[k] = lbl

    action_label = ttk.Label(status_frame, text="最近动作: -", style="Status.TLabel")
    action_label.pack(anchor=tk.W, pady=(5, 0))

    # ---- 单位信息 ----
    unit_info_frame = ttk.LabelFrame(main_frame, text="单位信息", padding="5 5 5 5")
    unit_info_frame.pack(fill=tk.X, pady=(0, 5))

    UNIT_INFO_KEYS = [
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
    ]
    unit_info_vars = {}
    unit_info_grid = ttk.Frame(unit_info_frame)
    unit_info_grid.pack(fill=tk.X)
    for i, (key, label_cn) in enumerate(UNIT_INFO_KEYS):
        row, col = i // 3, (i % 3) * 2
        ttk.Label(unit_info_grid, text=label_cn + ":").grid(row=row, column=col, sticky=tk.W, padx=(0, 2))
        lbl = ttk.Label(unit_info_grid, text="-", style="Status.TLabel", width=8)
        lbl.grid(row=row, column=col + 1, sticky=tk.W)
        unit_info_vars[key] = lbl
    unit_info_frame.pack(fill=tk.X, pady=(0, 5))

    # ---- 3. 技能冷却（根据专精动态显示）----
    spells_frame = ttk.LabelFrame(main_frame, text="技能冷却", padding="5 5 5 5")
    spells_frame.pack(fill=tk.X, pady=(0, 5))

    spells_grid = ttk.Frame(spells_frame)
    spells_grid.pack(fill=tk.X)

    spell_widgets = {}  # spell_name -> label

    def build_spell_row(name):
        lbl = ttk.Label(spells_grid, text="-", style="Status.TLabel", width=4)
        spell_widgets[name] = lbl
        return lbl

    # ---- 4. Group 1-5（戒律专精显示）----
    group_frame = ttk.LabelFrame(main_frame, text="Group 1-5", padding="5 5 5 5")
    group_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 5))

    headers = ["", "生命值", "职责", "驱散", "救赎", "盾"]
    for c, h in enumerate(headers):
        ttk.Label(group_frame, text=h, style="Title.TLabel").grid(
            row=0, column=c, padx=5, pady=2, sticky=tk.W
        )

    group_vars = {}
    for i in range(1, 6):
        row = i
        key = str(i)
        ttk.Label(group_frame, text=f"Unit {i}").grid(row=row, column=0, padx=5, pady=2, sticky=tk.W)
        group_vars[key] = {}
        for j, field in enumerate(["生命值", "职责", "驱散", "救赎", "真言术：盾"]):
            lbl = ttk.Label(group_frame, text="-", style="Group.TLabel", width=6)
            lbl.grid(row=row, column=j + 1, padx=5, pady=2, sticky=tk.W)
            group_vars[key][field] = lbl

    def update_spells_display(current_spells):
        """根据当前专精显示的技能列表更新 UI"""
        for w in spells_grid.winfo_children():
            w.destroy()

        spell_vars_local = {}
        for i, name in enumerate(current_spells):
            row, col = i // 4, (i % 4) * 2
            ttk.Label(spells_grid, text=name + ":").grid(row=row, column=col, sticky=tk.W, padx=(0, 2))
            lbl = ttk.Label(spells_grid, text="-", style="Status.TLabel", width=4)
            lbl.grid(row=row, column=col + 1, sticky=tk.W)
            spell_vars_local[name] = lbl
        spell_widgets.clear()
        spell_widgets.update(spell_vars_local)

    def update_display():
        sync_toggle_from_logic()
        with _state_lock:
            sd = dict(_state_dict)
            enabled = _logic_enabled
            spec = _spec_name

        status_text = "开启" if enabled else "关闭"
        status_label.configure(style="StatusOn.TLabel" if enabled else "StatusOff.TLabel", text=f"状态: {status_text}")

        spec_label.config(text=f"专精: {spec or '-'}")

        for k in status_keys:
            v = sd.get(k)
            txt = str(v) if v is not None else "-"
            if v is True:
                status_vars[k].configure(style="StatusTrue.TLabel", text=txt)
            elif v is False:
                status_vars[k].configure(style="StatusFalse.TLabel", text=txt)
            else:
                status_vars[k].configure(style="Status.TLabel", text=txt)

        action_label.config(text=f"最近动作: {_last_action}")

        with _state_lock:
            ui = dict(_unit_info)
        for key, _ in UNIT_INFO_KEYS:
            v = ui.get(key)
            txt = str(v) if v is not None else "-"
            unit_info_vars[key].config(text=txt)
        if spec == "暗影":
            unit_info_frame.pack_forget()
        else:
            if not unit_info_frame.winfo_ismapped():
                unit_info_frame.pack(fill=tk.X, pady=(0, 5))

        spells = sd.get("spells") or {}
        if spec == "暗影":
            current_spell_list = SHADOW_SPELLS
            group_frame.pack_forget()
        else:
            current_spell_list = DISCIPLINE_SPELLS
            group_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 5))

        if not spell_widgets or set(spell_widgets.keys()) != set(current_spell_list):
            update_spells_display(current_spell_list)

        for name, lbl in spell_widgets.items():
            v = spells.get(name)
            lbl.config(text=str(v) if v is not None else "-")

        group = sd.get("group") or {}
        for i in range(1, 6):
            key = str(i)
            data = group.get(key) or {}
            for field in ["生命值", "职责", "驱散", "救赎", "真言术：盾"]:
                v = data.get(field)
                lbl = group_vars[key][field]
                lbl.config(text=str(v) if v is not None else "-")

        root.after(GUI_UPDATE_MS, update_display)

    update_spells_display(DISCIPLINE_SPELLS)
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
