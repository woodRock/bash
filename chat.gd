extends Control

@onready var chat_log = $VBoxContainer/ScrollContainer/RichTextLabel
@onready var scroll_container = $VBoxContainer/ScrollContainer
@onready var objective_label = $VBoxContainer/ObjectivePanel/MarginContainer/ObjectiveLabel

func _ready():
	chat_log.clear()
	# Ensure BBCode is on programmatically
	chat_log.bbcode_enabled = true
	
	var terminal = get_tree().root.find_child("LineEdit", true, false)
	if terminal:
		terminal.command_executed.connect(_on_terminal_activity)
	
	await get_tree().create_timer(1.5).timeout
	display_current_mission()

func display_current_mission():
	if MissionManager.current_mission_id >= MissionManager.missions.size():
		return

	var m = MissionManager.missions[MissionManager.current_mission_id]
	
	# We use [color=black] or [color=#000000] to ensure it shows against the grey panel
	var sender_txt = "[b][color=black]" + m.sender + ":[/color][/b] "
	var body_txt = "[color=#1a1a1a]" + m.text + "[/color]" # Dark charcoal text
	
	# Append both parts
	chat_log.append_text(sender_txt + body_txt + "\n\n")
	objective_label.text = m.objective
	
	_scroll_to_bottom()

func _on_terminal_activity(cmd: String, response: String):
	var m = MissionManager.missions[MissionManager.current_mission_id]
	if m.type == MissionManager.TaskType.COMMAND and cmd.strip_edges() == m.value:
		complete_task()

func complete_task():
	chat_log.append_text("[color=#008000]>> MISSION VERIFIED.[/color]\n")
	MissionManager.current_mission_id += 1
	await get_tree().create_timer(0.5).timeout
	display_current_mission()

func _scroll_to_bottom():
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
