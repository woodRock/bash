extends PanelContainer

# --- SIGNALS ---
signal editor_closed 
signal file_saved(path, content)

# --- NODES ---
@onready var file_label = $VBoxContainer/FileNameLabel
@onready var code_input = $VBoxContainer/CodeInput
@onready var help_label = $VBoxContainer/HelpLabel

# --- STATE ---
var current_file_path = ""
var vfs_reference = null
# FIXED: Removed BBCode tags for standard Label compatibility
const SHORTCUT_TEXT = "^O Write Out    ^X Exit" 

func _ready() -> void: 
	# Connect to global reactive settings
	GlobalSettings.setting_changed.connect(_on_setting_changed)
	_apply_font_size(GlobalSettings.font_size)
	
	# Apply Cyberpunk Styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1e1e2e")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color("#bd93f9")
	add_theme_stylebox_override("panel", style)
	
	# SETUP FOOTER
	# FIXED: Removed 'bbcode_enabled' assignment
	help_label.text = SHORTCUT_TEXT
	
	hide() 

# --- HIGHLIGHTER FACTORY ---

func apply_highlighter_for_file(path: String):
	var extension = path.get_extension().to_lower()
	
	match extension:
		"sh", "bashrc":
			code_input.syntax_highlighter = get_bash_highlighter()
		"md", "txt":
			code_input.syntax_highlighter = get_markdown_highlighter()
		_:
			code_input.syntax_highlighter = null

func get_bash_highlighter() -> CodeHighlighter:
	var h = CodeHighlighter.new()
	h.symbol_color = Color("#5dade2")
	h.number_color = Color("#f39c12")
	h.function_color = Color("#f4d03f")
	h.member_variable_color = Color("#a2d9ce")

	var keywords = ["if", "then", "else", "fi", "for", "while", "do", "done", "exit", "return", "export"]
	for word in keywords: h.add_keyword_color(word, Color("#ff79c6"))

	var commands = ["ls", "cd", "cat", "touch", "nano", "pwd", "grep", "sudo", "chmod", "sleep", "mv", "cp", "rm", "reboot"]
	for cmd in commands: h.add_keyword_color(cmd, Color("#50fa7b"))

	h.add_color_region("#", "", Color("#6272a4"), true)
	h.add_color_region('"', '"', Color("#f1fa8c"), false)
	h.add_color_region("'", "'", Color("#f1fa8c"), false)
	h.add_color_region("${", "}", Color("#8be9fd"), false)  
	return h

func get_markdown_highlighter() -> CodeHighlighter:
	var h = CodeHighlighter.new()
	h.symbol_color = Color("#ff79c6")
	h.add_color_region("# ", "", Color("#50fa7b"), true) 
	h.add_color_region("## ", "", Color("#50fa7b"), true)
	h.add_color_region("### ", "", Color("#50fa7b"), true)
	h.add_color_region("`", "`", Color("#f1fa8c"), false)
	h.add_color_region("- ", "", Color("#8be9fd"), true)
	h.add_color_region("> ", "", Color("#6272a4"), true)
	return h

# --- EDITOR CORE ---

func open_file(path: String, vfs = null):
	show()
		
	if vfs:
		vfs_reference = vfs
	elif MissionManager.vfs_node:
		vfs_reference = MissionManager.vfs_node
	else:
		push_error("EDITOR ERROR: No VFS provided and MissionManager.vfs_node is null!")
		code_input.text = "# ERROR: Virtual File System not connected."
		return

	current_file_path = path
	file_label.text = " NANO 2.4  File: " + path
	help_label.text = SHORTCUT_TEXT
	
	apply_highlighter_for_file(path)
	
	if vfs_reference.files.has(path):
		code_input.text = vfs_reference.files[path].get("content", "")
	else:
		code_input.text = ""
	
	code_input.grab_focus()
	code_input.set_caret_column(code_input.text.length())

func _input(event):
	if not is_visible_in_tree(): return
	
	if event is InputEventKey and event.pressed:
		var is_ctrl = event.ctrl_pressed or event.command_or_control_autoremap
		
		if is_ctrl:
			if event.keycode == KEY_O or event.keycode == KEY_S:
				save_file()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_X:
				exit_editor()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			exit_editor()
			get_viewport().set_input_as_handled()

func save_file():
	if vfs_reference and current_file_path != "":
		var new_content = code_input.text
		
		if vfs_reference.files.has(current_file_path):
			vfs_reference.files[current_file_path]["content"] = new_content
		else:
			vfs_reference.create_file(current_file_path, new_content, "file")
		
		MissionManager.check_mission_progress(MissionManager.TaskType.FILE_CONTENT, current_file_path)
		file_saved.emit(current_file_path, new_content)
		
		# FIXED: Removed BBCode tags
		help_label.text = "[ WROTE " + str(new_content.split("\n").size()) + " LINES ]"
		await get_tree().create_timer(1.0).timeout
		help_label.text = SHORTCUT_TEXT

func exit_editor():
	hide()
	editor_closed.emit()

# --- REACTIVE UI LOGIC ---

func _on_setting_changed(key: String, value):
	if key == "font_size":
		_apply_font_size(value)

func _apply_font_size(new_size: int):
	code_input.add_theme_font_size_override("font_size", new_size)
	file_label.add_theme_font_size_override("font_size", new_size)
	help_label.add_theme_font_size_override("font_size", clampi(new_size - 4, 8, 72))
