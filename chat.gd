extends Control

@onready var chat_log = $VBoxContainer/ScrollContainer/RichTextLabel
@onready var scroll_container = $VBoxContainer/ScrollContainer
@onready var objective_label = $VBoxContainer/ObjectivePanel/MarginContainer/ObjectiveLabel

func _ready():
	chat_log.clear()
	chat_log.bbcode_enabled = true
	var terminal = get_tree().root.find_child("LineEdit", true, false)
	if terminal:
		terminal.command_executed.connect(_on_terminal_activity)
	
	await get_tree().create_timer(1.0).timeout
	display_current_mission()

func display_current_mission():
	var active_missions = MissionManager.get_current_missions()
	
	if MissionManager.current_mission_id >= active_missions.size():
		_handle_day_transition()
		return

	var m = active_missions[MissionManager.current_mission_id]
	chat_log.append_text("\n[b][color=#f1fa8c]" + m.sender + ":[/color][/b] " + m.text + "\n")
	objective_label.text = m.objective
	_scroll_to_bottom()

func _handle_day_transition():
	if MissionManager.current_day < MissionManager.days.size() - 1:
		chat_log.append_text("\n[color=#ff79c6]CONNECTION CLOSED. SHIFT ENDED.[/color]")
		await get_tree().create_timer(2.0).timeout
		
		# Move to Day 2
		MissionManager.current_day += 1
		MissionManager.current_mission_id = 0
		
		# Update VFS to Day 2 state
		var terminal = get_tree().root.find_child("LineEdit", true, false)
		if terminal and terminal.VFS:
			terminal.VFS.setup_day(MissionManager.current_day)
		
		chat_log.clear()
		chat_log.append_text("[color=#50fa7b]SYSTEM REBOOTED. DAY 2 COMMENCING...[/color]\n")
		display_current_mission()
	else:
		chat_log.append_text("\n[color=#50fa7b]ALL CHAPTERS COMPLETE.[/color]")

func _on_terminal_activity(cmd: String, response: String):
	var active_missions = MissionManager.get_current_missions()
	if MissionManager.current_mission_id >= active_missions.size(): return

	var m = active_missions[MissionManager.current_mission_id]
	var success = false

	match m.type:
		MissionManager.TaskType.COMMAND:
			if cmd.strip_edges() == m.value.strip_edges(): success = true
		MissionManager.TaskType.OUTPUT:
			if m.value.strip_edges() in response.strip_edges(): success = true
		MissionManager.TaskType.VFS_STATE:
			var terminal = get_tree().root.find_child("LineEdit", true, false)
			if terminal.VFS.files.has(terminal.VFS.resolve_path(m.value)): success = true

	if success:
		MissionManager.current_mission_id += 1
		chat_log.append_text("\n[color=#50fa7b]>> Success.[/color]")
		await get_tree().create_timer(1.0).timeout
		display_current_mission()

func _scroll_to_bottom():
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
