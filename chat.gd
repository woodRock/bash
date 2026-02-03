extends Control

@onready var chat_log = $VBoxContainer/ScrollContainer/RichTextLabel
@onready var scroll_container = $VBoxContainer/ScrollContainer
@onready var objective_label = $VBoxContainer/ObjectivePanel/MarginContainer/ObjectiveLabel

func _ready():
	chat_log.clear()
	chat_log.bbcode_enabled = true
	
	# Connect to the Gatekeeper Terminal signal
	var terminal = get_tree().root.find_child("LineEdit", true, false)
	if terminal:
		if not terminal.is_connected("command_executed", _on_terminal_activity):
			terminal.command_executed.connect(_on_terminal_activity)
	
	await get_tree().create_timer(1.5).timeout
	display_current_mission()

func display_current_mission():
	if MissionManager.current_mission_id >= MissionManager.missions.size():
		chat_log.append_text("\n[color=#50fa7b][b]SYSTEM:[/b] All research objectives met for today.[/color]")
		objective_label.text = "Objective: Complete"
		return

	var m = MissionManager.missions[MissionManager.current_mission_id]
	var narrative = "\n[b][color=#f1fa8c]" + m.sender + ":[/color][/b] " + m.text + "\n"
	chat_log.append_text(narrative)
	objective_label.text = m.objective
	
	_scroll_to_bottom()

func _on_terminal_activity(cmd: String, response: String):
	if MissionManager.current_mission_id >= MissionManager.missions.size():
		return

	var m = MissionManager.missions[MissionManager.current_mission_id]
	var success = false

	# ADVANCED VALIDATION LOGIC
	match m.type:
		MissionManager.TaskType.COMMAND:
			# Check command without leading/trailing whitespace
			if cmd.strip_edges() == m.value.strip_edges():
				success = true
		
		MissionManager.TaskType.OUTPUT:
			# FIX: Strip the response to remove trailing newlines (\n) from VFS content
			var clean_response = response.strip_edges()
			var target_value = m.value.strip_edges()
			if target_value in clean_response:
				success = true
				
		MissionManager.TaskType.VFS_STATE:
			var terminal = get_tree().root.find_child("LineEdit", true, false)
			if terminal and terminal.VFS:
				var target_path = terminal.VFS.resolve_path(m.value)
				if terminal.VFS.files.has(target_path):
					success = true

	if success:
		complete_task()

func complete_task():
	chat_log.append_text("\n[color=#50fa7b]>> Connection confirmed. Decrypting...[/color]")
	MissionManager.current_mission_id += 1
	
	await get_tree().create_timer(1.2).timeout
	display_current_mission()

func _scroll_to_bottom():
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
