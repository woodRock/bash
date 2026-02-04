extends PanelContainer

@onready var input_line = %LineEdit 

func _ready() -> void:
	GlobalSettings.setting_changed.connect(_on_setting_changed)
	_apply_font_size(GlobalSettings.font_size)
	
	if input_line:
		input_line.visible = false
		input_line.editable = false
	else:
		print("LineEdit is missing!")

func activate_terminal() -> void:
	if input_line:
		input_line.visible = true
		input_line.editable = true
		input_line.grab_focus()

func _on_setting_changed(key: String, value):
	if key == "font_size":
		_apply_font_size(value)

func _apply_font_size(new_size: int):
	# Updates the PanelContainer's local theme if needed, 
	# but primarily ensures the input line stays in sync.
	if input_line:
		input_line.add_theme_font_size_override("font_size", new_size)
