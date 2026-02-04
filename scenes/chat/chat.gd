extends Control

# --- NODES ---
@onready var title_label = $VBoxContainer/HeaderPanel/Label
@onready var chat_log = $VBoxContainer/ScrollContainer/RichTextLabel
@onready var scroll_container = $VBoxContainer/ScrollContainer
@onready var objective_label = $VBoxContainer/ObjectivePanel/MarginContainer/ObjectiveLabel

func _ready():
	# Initial UI Setup
	chat_log.clear()
	chat_log.bbcode_enabled = true
	# Ensure text wraps properly for long forensics logs
	chat_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# 1. Connect to Global Font Scaling
	GlobalSettings.setting_changed.connect(_on_setting_changed)
	
	# 2. Apply initial font size from GlobalSettings
	_apply_font_size(GlobalSettings.font_size)
	
	# 3. Listen to the Global MissionManager
	MissionManager.mission_updated.connect(_on_mission_advanced)
	
	display_current_mission()

func _on_mission_advanced():
	# Print success marker immediately
	chat_log.append_text("\n[color=#50fa7b]>> Success.[/color]")
	
	# CRITICAL: Check for game completion BEFORE the await timer
	if MissionManager.current_day >= MissionManager.days.size():
		await get_tree().create_timer(0.5).timeout # Short dramatic pause
		_trigger_game_complete()
		return
		
	# Standard mission delay for typewriter impact
	await get_tree().create_timer(1.0).timeout
	display_current_mission()

func display_current_mission():
	# Double check end state during initial display calls
	if MissionManager.current_day >= MissionManager.days.size():
		_trigger_game_complete()
		return

	var active_missions = MissionManager.get_current_missions()
	var m = active_missions[MissionManager.current_mission_id]
	
	# Build header for Dr. Aris, Vance, or Freya
	var header = "[b][color=#f1fa8c]" + m.sender + ":[/color][/b] "
	chat_log.append_text("\n" + header) 
	
	var message_body = m.text + "\n"
	_animate_text_append(message_body)
	
	# Update the UI objective bar
	objective_label.text = m.objective
	_scroll_to_bottom()

func _trigger_game_complete():
	# Using a bright cyan (#8be9fd) or pure white for maximum contrast if green fails
	var complete_text = "\n[b][color=#8be9fd]ALL CHAPTERS COMPLETE.[/color][/b]"
	complete_text += "\n[color=#f8f8f2]TERMINAL CLEAR - LOG OFF[/color]"
	
	_animate_text_append(complete_text)
	
	# Update the UI objective bar to something very obvious
	objective_label.text = ">>> SYSTEM OFFLINE <<<"
	objective_label.add_theme_color_override("font_color", Color("#ff5555")) # Alert Red
	
	_scroll_to_bottom()
	
func _animate_text_append(new_text: String):
	var start_index = chat_log.get_total_character_count()
	chat_log.append_text(new_text)
	await get_tree().process_frame
	
	var total_chars = chat_log.get_total_character_count()
	
	var tween = create_tween()
	chat_log.visible_characters = start_index
	# Standard typewriter speed
	tween.tween_property(chat_log, "visible_characters", total_chars, 0.5).set_trans(Tween.TRANS_LINEAR)

# --- FONT SCALING LOGIC ---

func _on_setting_changed(key: String, value):
	if key == "font_size":
		_apply_font_size(value)

func _apply_font_size(new_size: int):
	# Update the title label
	title_label.add_theme_font_size_override("font_size", new_size)
	
	# Update the Chat Log (RichTextLabel) with full styling support
	chat_log.add_theme_font_size_override("normal_font_size", new_size)
	chat_log.add_theme_font_size_override("bold_font_size", new_size)
	chat_log.add_theme_font_size_override("mono_font_size", new_size)
	chat_log.add_theme_font_size_override("italics_font_size", new_size)
	
	# Update the Objective Label
	objective_label.add_theme_font_size_override("font_size", new_size)

func _scroll_to_bottom():
	# Multi-frame wait ensures the RichTextLabel has finished resizing after content update
	await get_tree().process_frame
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
