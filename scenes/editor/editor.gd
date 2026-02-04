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

func _ready() -> void: 
	# Connect to global reactive settings
	GlobalSettings.setting_changed.connect(_on_setting_changed)
	_apply_font_size(GlobalSettings.font_size)
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
			# Default to no highlighting for unknown types
			code_input.syntax_highlighter = null

func get_bash_highlighter() -> CodeHighlighter:
	var h = CodeHighlighter.new()
	# Dracula Palette Colors
	h.symbol_color = Color("#5dade2")
	h.number_color = Color("#f39c12")
	h.function_color = Color("#f4d03f")
	h.member_variable_color = Color("#a2d9ce")

	var keywords = ["if", "then", "else", "fi", "for", "while", "do", "done", "exit", "return"]
	for word in keywords: h.add_keyword_color(word, Color("#ff79c6"))

	var commands = ["ls", "cd", "cat", "touch", "nano", "pwd", "grep", "sudo", "chmod", "sleep"]
	for cmd in commands: h.add_keyword_color(cmd, Color("#50fa7b"))

	# Comments and Strings
	h.add_color_region("#", "", Color("#6272a4"), true)
	h.add_color_region('"', '"', Color("#f1fa8c"), false)
	h.add_color_region("'", "'", Color("#f1fa8c"), false)
	
	# Shell variable expansion highlighting
	h.add_color_region("${", "}", Color("#8be9fd"), false)  
	return h

func get_markdown_highlighter() -> CodeHighlighter:
	var h = CodeHighlighter.new()
	
	# Dracula Markdown Palette
	h.symbol_color = Color("#ff79c6") # Pink syntax markers
	
	# Headers
	h.add_color_region("# ", "", Color("#50fa7b"), true) 
	h.add_color_region("## ", "", Color("#50fa7b"), true)
	h.add_color_region("### ", "", Color("#50fa7b"), true)
	
	# Inline Code and Blocks
	h.add_color_region("`", "`", Color("#f1fa8c"), false)
	h.add_color_region("```", "```", Color("#f1fa8c"), false)
	
	# Emphasis (Bold/Italic)
	h.add_color_region("**", "**", Color("#ffb86c"), false) 
	h.add_color_region("*", "*", Color("#bd93f9"), false)   
	
	# Lists and Blockquotes
	h.add_color_region("- ", "", Color("#8be9fd"), true)
	h.add_color_region("> ", "", Color("#6272a4"), true)
	
	return h

# --- EDITOR CORE ---

func open_file(path: String, vfs):
	vfs_reference = vfs
	current_file_path = path
	file_label.text = " EDITING: " + path
	
	# Determine highlighting logic before showing content
	apply_highlighter_for_file(path)
	
	if vfs_reference.files.has(path):
		code_input.text = vfs_reference.files[path].get("content", "")
	
	show()
	code_input.grab_focus()

func _input(event):
	if not is_visible_in_tree(): return
	
	if event is InputEventKey and event.pressed and event.ctrl_pressed:
		# Standard Terminal Editor Shortcuts
		if event.keycode == KEY_O or event.keycode == KEY_S:
			save_file()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_X:
			exit_editor()
			get_viewport().set_input_as_handled()

func save_file():
	if vfs_reference and current_file_path != "":
		var new_content = code_input.text
		vfs_reference.files[current_file_path]["content"] = new_content
		
		# Notify MissionManager to check content tasks
		file_saved.emit(current_file_path, new_content)
		
		help_label.text = "FILE SAVED!"
		get_tree().create_timer(1.0).timeout.connect(func(): 
			help_label.text = "^O Save | ^X Exit"
		)

func exit_editor():
	hide()
	editor_closed.emit()

# --- REACTIVE UI LOGIC ---

func _on_setting_changed(key: String, value):
	if key == "font_size":
		_apply_font_size(value)

func _apply_font_size(new_size: int):
	# Update the main text input area
	code_input.add_theme_font_size_override("font_size", new_size)
	
	# Update secondary UI labels
	file_label.add_theme_font_size_override("font_size", new_size)
	
	# Keep help text slightly smaller but legible
	help_label.add_theme_font_size_override("font_size", clampi(new_size - 4, 8, 72))
