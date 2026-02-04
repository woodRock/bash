extends PanelContainer

# SIGNALS - LineEdit.gd expects these
signal editor_closed 
signal file_saved(path, content) # Critical for Day 3 forensics

@onready var file_label = $VBoxContainer/FileNameLabel
@onready var code_input = $VBoxContainer/CodeInput
@onready var help_label = $VBoxContainer/HelpLabel

var current_file_path = ""
var vfs_reference = null

func _ready() -> void: 
	setup_bash_highlighter()
	hide() 

func setup_bash_highlighter():
	var highlighter = CodeHighlighter.new()
	
	# 1. Colors (Dracula Palette)
	highlighter.symbol_color = Color("#5dade2")      # Blue
	highlighter.number_color = Color("#f39c12")      # Orange
	highlighter.function_color = Color("#f4d03f")    # Yellow
	highlighter.member_variable_color = Color("#a2d9ce") # Sage

	# 2. Logic Keywords
	var keywords = ["if", "then", "else", "fi", "for", "while", "do", "done", "exit", "return"]
	for word in keywords:
		highlighter.add_keyword_color(word, Color("#ff79c6")) # Pink

	# 3. System Commands
	var commands = ["ls", "cd", "cat", "touch", "nano", "pwd", "grep", "sudo", "chmod", "sleep"]
	for cmd in commands:
		highlighter.add_keyword_color(cmd, Color("#50fa7b")) # Green

	# 4. Strings and Comments
	highlighter.add_color_region("#", "", Color("#6272a4"), true)     # Muted Blue
	highlighter.add_color_region('"', '"', Color("#f1fa8c"), false)   # Yellow
	highlighter.add_color_region("'", "'", Color("#f1fa8c"), false)   # Yellow

	# 5. Variable Templates (The New Expansion Highlighting)
	# This highlights ${VAR} in bright Cyan for better forensic visibility
	highlighter.add_color_region("${", "}", Color("#8be9fd"), false)  

	code_input.syntax_highlighter = highlighter

func open_file(path: String, vfs):
	vfs_reference = vfs
	current_file_path = path
	file_label.text = " EDITING: " + path
	if vfs_reference.files.has(path):
		code_input.text = vfs_reference.files[path].get("content", "")
	show()
	code_input.grab_focus()

func _input(event):
	if not is_visible_in_tree(): return
	if event is InputEventKey and event.pressed and event.ctrl_pressed:
		# Save (Ctrl+O or Ctrl+S)
		if event.keycode == KEY_O or event.keycode == KEY_S:
			save_file()
			get_viewport().set_input_as_handled()
		# Exit (Ctrl+X)
		elif event.keycode == KEY_X:
			exit_editor()
			get_viewport().set_input_as_handled()

func save_file():
	if vfs_reference and current_file_path != "":
		var new_content = code_input.text
		vfs_reference.files[current_file_path]["content"] = new_content
		
		# CRITICAL: Notify MissionManager to check the code immediately on save
		file_saved.emit(current_file_path, new_content)
		
		help_label.text = "FILE SAVED!"
		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(func(): help_label.text = "^O Save | ^X Exit")

func exit_editor():
	hide()
	editor_closed.emit()
