extends RichTextLabel

func _ready() -> void:
	GlobalSettings.setting_changed.connect(_on_setting_changed)
	_apply_font_size(GlobalSettings.font_size)

func typewriter_append(text_to_add: String):
	append_text(text_to_add + "\n")
	await get_tree().process_frame 
	
	var total_chars = get_total_character_count()
	var new_chars = text_to_add.length()
	var start_chars = total_chars - new_chars
	
	var tween = create_tween()
	visible_characters = start_chars
	tween.tween_property(self, "visible_characters", total_chars, 0.2)

func _on_setting_changed(key: String, value):
	if key == "font_size":
		_apply_font_size(value)

func _apply_font_size(new_size: int):
	add_theme_font_size_override("normal_font_size", new_size)
	add_theme_font_size_override("bold_font_size", new_size)
	add_theme_font_size_override("mono_font_size", new_size)
