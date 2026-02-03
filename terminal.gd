extends PanelContainer

# Use the %UniqueName for your LineEdit here
@onready var input_line = %LineEdit 

func _ready() -> void:
	# Start hidden/disabled
	if input_line:
		input_line.visible = false
		input_line.editable = false

func activate_terminal() -> void:
	if input_line:
		input_line.visible = true
		input_line.editable = true
		if input_line.has_method("enable_focus_loop"):
			input_line.enable_focus_loop()
