extends Control

# --- NODES ---
@onready var title_label = $VBoxContainer/HeaderPanel/Label
@onready var chat_log = $VBoxContainer/ScrollContainer/RichTextLabel
@onready var scroll_container = $VBoxContainer/ScrollContainer
@onready var objective_label = $VBoxContainer/ObjectivePanel/MarginContainer/ObjectiveLabel

# --- NARRATIVE DATA ---
var chapter_titles = [
	"THE VANCE INCIDENT",
	"THE LOGIC BOMB",
	"THE WELLINGTON HARBOR SEARCH"
]

func _ready():
	chat_log.clear()
	chat_log.bbcode_enabled = true
	chat_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# 1. Connect Signals
	GlobalSettings.setting_changed.connect(_on_setting_changed)
	MissionManager.mission_updated.connect(_on_mission_advanced)
	
	# 2. Apply Initial Look
	_apply_font_size(GlobalSettings.font_size)
	_apply_cyberpunk_theme()
	
	# 3. Determine Start State
	if MissionManager.current_mission_id == 0 and MissionManager.current_day == 0:
		_play_boot_sequence()
	else:
		display_current_mission()

func _on_mission_advanced():
	# SNAPSHOT STATE
	var mission_id_at_start = MissionManager.current_mission_id
	var day_at_start = MissionManager.current_day
	
	# 1. Game Complete
	if MissionManager.current_day >= MissionManager.days.size():
		var success_col = GlobalSettings.get_color("success")
		chat_log.append_text("\n[center][color=" + success_col + "]― UPLINK VERIFIED ―[/color][/center]")
		await get_tree().create_timer(0.5).timeout
		_trigger_game_complete()
		return

	# 2. New Chapter (Trigger Boot)
	if mission_id_at_start == 0 and day_at_start > 0:
		chat_log.clear()
		_play_boot_sequence()
		return

	# 3. Standard Advance
	var success_col = GlobalSettings.get_color("success")
	chat_log.append_text("\n[center][color=" + success_col + "]― UPLINK VERIFIED ―[/color][/center]")
	
	await get_tree().create_timer(1.0).timeout
	
	# GUARD: If state changed (e.g. reboot happened), abort
	if MissionManager.current_mission_id != mission_id_at_start:
		return
	
	display_current_mission()

func _play_boot_sequence():
	objective_label.text = "INITIALIZING..."
	chat_log.clear()
	
	var dim_col = GlobalSettings.get_color("dim")
	var sys_text = "\n[center][color=" + dim_col + "]ESTABLISHING SECURE CONNECTION...[/color][/center]"
	await _animate_text_append(sys_text, 0.3)
	
	var success_col = GlobalSettings.get_color("success")
	var login_text = "[center][color=" + dim_col + "]AUTHENTICATING USER: [/color][b][color=" + success_col + "]JESSE_WOOD[/color][/b][/center]"
	await _animate_text_append(login_text, 0.3)
	
	var day_idx = MissionManager.current_day
	var title = "UNKNOWN CHAPTER"
	if day_idx < chapter_titles.size():
		title = chapter_titles[day_idx]
	
	var obj_col = GlobalSettings.get_color("objective")
	var chapter_line = "\n[center][b][color=" + obj_col + "]CHAPTER " + str(day_idx + 1) + ": " + title + "[/color][/b][/center]\n"
	await _animate_text_append(chapter_line, 0.8)
	
	await get_tree().create_timer(0.5).timeout
	display_current_mission()

func display_current_mission():
	if MissionManager.current_day >= MissionManager.days.size():
		_trigger_game_complete()
		return

	var active_missions = MissionManager.get_current_missions()
	var m = active_missions[MissionManager.current_mission_id]
	
	var sender_col = GlobalSettings.get_color("sender_default")
	match m.sender:
		"Dr. Aris": sender_col = GlobalSettings.get_color("sender_aris")
		"Freya": sender_col = GlobalSettings.get_color("sender_freya")
		"Vance AI": sender_col = GlobalSettings.get_color("sender_freya")
		"SYSTEM": sender_col = GlobalSettings.get_color("sender_system")
	
	var body_col = GlobalSettings.get_color("body")
	var dim_col = GlobalSettings.get_color("dim")
	
	# Calculated timestamp size
	var ts_size = max(14, GlobalSettings.font_size - 2)
	var timestamp_str = "09:4" + str(randi() % 9) + "::" + str(randi() % 59)
	var timestamp_bb = "[color=" + dim_col + "][font_size=" + str(ts_size) + "]" + timestamp_str + "[/font_size][/color]"
	
	var header = "\n" + timestamp_bb + " [b][color=" + sender_col + "]" + m.sender + "[/color][/b]"
	chat_log.append_text(header) 
	
	var message_body = "\n[indent][color=" + body_col + "]" + m.text + "[/color][/indent]\n"
	_animate_text_append(message_body)
	
	objective_label.text = ">> OBJECTIVE: " + m.objective
	_scroll_to_bottom()

func _trigger_game_complete():
	var success_col = GlobalSettings.get_color("success")
	var dim_col = GlobalSettings.get_color("dim")
	
	var complete_text = "\n[center][b][color=" + success_col + "]ALL CHAPTERS COMPLETE.[/color][/b][/center]"
	complete_text += "\n[center][color=" + dim_col + "]TERMINAL CONNECTION SEVERED[/color][/center]"
	
	chat_log.append_text(complete_text)
	
	objective_label.text = ">>> SYSTEM OFFLINE <<<"
	objective_label.add_theme_color_override("font_color", Color(GlobalSettings.get_color("sender_system")))
	_scroll_to_bottom()

func _animate_text_append(new_text: String, duration: float = 0.5):
	var start_index = chat_log.get_total_character_count()
	chat_log.append_text(new_text)
	await get_tree().process_frame
	
	var total_chars = chat_log.get_total_character_count()
	
	var tween = create_tween()
	chat_log.visible_characters = start_index
	tween.tween_property(chat_log, "visible_characters", total_chars, duration).set_trans(Tween.TRANS_LINEAR)
	await tween.finished

func _on_setting_changed(key: String, value):
	if key == "font_size": _apply_font_size(value)
	elif key == "theme": _apply_cyberpunk_theme()

func _apply_cyberpunk_theme():
	var bg_color = GlobalSettings.get_color("panel_bg")
	var border_color = GlobalSettings.get_color("border")
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(bg_color)
	
	style_box.border_width_left = 1
	style_box.border_width_top = 1
	style_box.border_width_right = 1
	style_box.border_width_bottom = 1
	
	style_box.border_color = Color(border_color)
	style_box.set_corner_radius_all(4)
	style_box.content_margin_left = 12
	style_box.content_margin_right = 12
	style_box.content_margin_top = 12
	style_box.content_margin_bottom = 12
	
	chat_log.add_theme_stylebox_override("normal", style_box)
	objective_label.add_theme_color_override("font_color", Color(GlobalSettings.get_color("objective")))

# --- THIS IS THE FUNCTION THAT WAS MISSING ---
func _apply_font_size(new_size: int):
	if title_label:
		title_label.add_theme_font_size_override("font_size", new_size)
	
	if chat_log:
		chat_log.add_theme_font_size_override("normal_font_size", new_size)
		chat_log.add_theme_font_size_override("bold_font_size", new_size)
		chat_log.add_theme_font_size_override("mono_font_size", new_size)
		chat_log.add_theme_font_size_override("italics_font_size", new_size)
	
	if objective_label:
		objective_label.add_theme_font_size_override("font_size", new_size)

func _scroll_to_bottom():
	await get_tree().process_frame
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
