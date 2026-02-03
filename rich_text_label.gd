extends RichTextLabel

@export var type_speed: float = 0.5 # Characters per second (adjustable)

func typewriter_append(text_to_add: String):
	# 1. Add the text immediately
	append_text(text_to_add + "\n")
	
	# 2. Reset visibility to hidden for the NEW text only
	# Since we want the WHOLE log to stay visible, we animate the 'visible_ratio'
	# starting from where the old text ended.
	
	# To keep it simple and bug-free, we will animate the 'visible_characters' 
	# but force a redraw first.
	await get_tree().process_frame # Wait 1 frame so Godot updates character count
	
	var total_chars = get_total_character_count()
	var new_chars = text_to_add.length()
	var start_chars = total_chars - new_chars
	
	var tween = create_tween()
	visible_characters = start_chars
	
	# Animate from the end of the last message to the end of the new one
	tween.tween_property(self, "visible_characters", total_chars, 0.2) # Fixed duration for snappiness
