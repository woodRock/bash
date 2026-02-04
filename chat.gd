extends Control

@onready var chat_log = $VBoxContainer/ScrollContainer/RichTextLabel
@onready var scroll_container = $VBoxContainer/ScrollContainer
@onready var objective_label = $VBoxContainer/ObjectivePanel/MarginContainer/ObjectiveLabel

func _ready():
	chat_log.clear()
	chat_log.bbcode_enabled = true
	
	# Listen to the Global MissionManager instead of the terminal
	MissionManager.mission_updated.connect(_on_mission_advanced)
	
	display_current_mission()

func _on_mission_advanced():
	chat_log.append_text("\n[color=#50fa7b]>> Success.[/color]")
	await get_tree().create_timer(1.0).timeout
	display_current_mission()

func display_current_mission():
	var active_missions = MissionManager.get_current_missions()
	
	if MissionManager.current_day >= MissionManager.days.size():
		chat_log.append_text("\n[color=#50fa7b]ALL CHAPTERS COMPLETE.[/color]")
		return

	var m = active_missions[MissionManager.current_mission_id]
	chat_log.append_text("\n[b][color=#f1fa8c]" + m.sender + ":[/color][/b] " + m.text + "\n")
	objective_label.text = m.objective
	_scroll_to_bottom()

func _scroll_to_bottom():
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
