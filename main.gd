extends Node

# --- SCENE REFERENCES ---
# Assign these in the Inspector by dragging nodes from the Scene Tree
@export var boot_screen_node: Control
@export var terminal_node: Control
@export var editor_node: Control

# We will try to find the input line automatically, or you can link it manually
var terminal_input: LineEdit

func _ready():
	print("MAIN: Game Started.")
	
	# 1. AUTO-DISCOVER Input
	# Tries to find "LineEdit" inside the terminal node automatically
	if terminal_node:
		terminal_input = terminal_node.find_child("LineEdit", true, false)
		if terminal_input:
			print("MAIN: Found Terminal Input at: ", terminal_input.get_path())
			
			# Connect Signals safely
			if not terminal_input.is_connected("reboot_requested", _on_reboot_requested):
				terminal_input.reboot_requested.connect(_on_reboot_requested)
			if not terminal_input.is_connected("editor_requested", _on_editor_requested):
				terminal_input.editor_requested.connect(_on_editor_requested)
		else:
			push_error("MAIN ERROR: Could not find a 'LineEdit' child inside Terminal Node!")
	
	# 2. Connect Boot Signals
	if boot_screen_node:
		if not boot_screen_node.is_connected("boot_finished", _on_boot_finished):
			boot_screen_node.boot_finished.connect(_on_boot_finished)
	else:
		push_error("MAIN ERROR: Boot Screen Node is not assigned!")

	# 3. Connect Editor Signals
	if editor_node:
		if editor_node.has_signal("editor_closed"):
			if not editor_node.is_connected("editor_closed", _on_editor_closed):
				editor_node.editor_closed.connect(_on_editor_closed)
	
	# 4. Start Game Loop
	_start_boot_sequence()

func _start_boot_sequence():
	print("MAIN: Starting Boot Sequence...")
	
	# Reset Visibility
	if editor_node: editor_node.visible = false
	if terminal_node: terminal_node.visible = false
	
	if boot_screen_node:
		boot_screen_node.visible = true
		boot_screen_node.modulate.a = 1.0
		if boot_screen_node.has_method("start_boot"):
			boot_screen_node.start_boot()
		else:
			push_error("MAIN ERROR: BootScreen script missing 'start_boot' function!")

func _on_boot_finished():
	print("MAIN: Boot Finished signal received.")
	if boot_screen_node: boot_screen_node.visible = false
	
	if terminal_node:
		print("MAIN: Showing Terminal...")
		terminal_node.visible = true
		
		# Optional: Call activation logic if your terminal script has it
		if terminal_node.has_method("activate_terminal"):
			terminal_node.activate_terminal()
		
		# Force focus onto the input line
		if terminal_input:
			terminal_input.grab_focus_deferred()
	else:
		push_error("MAIN ERROR: Cannot show Terminal because terminal_node is null!")

func _on_reboot_requested():
	print("MAIN: Reboot requested.")
	_start_boot_sequence()

func _on_editor_requested(file_path):
	print("MAIN: Switching to Editor for file: ", file_path)
	if terminal_node: terminal_node.visible = false
	
	if editor_node:
		editor_node.visible = true
		if editor_node.has_method("open_file"):
			# FIX: Pass the VFS node from MissionManager as the second argument
			editor_node.open_file(file_path, MissionManager.vfs_node)
		else:
			push_error("MAIN ERROR: Editor script missing 'open_file' function!")

func _on_editor_closed():
	print("MAIN: Editor closed. Returning to Terminal.")
	if editor_node: editor_node.visible = false
	
	if terminal_node:
		terminal_node.visible = true
		if terminal_node.has_method("activate_terminal"):
			terminal_node.activate_terminal()
			
	if terminal_input: 
		terminal_input.grab_focus_deferred()
