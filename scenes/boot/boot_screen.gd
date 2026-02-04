extends ColorRect

@onready var boot_log = $BootLog
@export var terminal_node: Control 
@export var boot_screen_timer: float = 2.0

var boot_lines = [
	"GATEKEEPER BIOS v4.0.2...",
	"CHECKING RAM................ [ OK ]",
	"MOUNTING VIRTUAL FILESYSTEM... [ OK ]",
	"INITIALIZING NETWORK PROTOCOLS... [ OK ]",
	"DECRYPTING USER KERNEL...",
	"WELCOME, JESSE WOOD.",
	"READY."
]

func _ready():
	# 1. Connect to the global signal
	GlobalSettings.setting_changed.connect(_on_setting_changed)
	
	# 2. Apply the initial size from the singleton
	_apply_font_size(GlobalSettings.font_size)
	
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	run_boot_sequence()

# --- REACTIVE LOGIC ---

func _on_setting_changed(key: String, value):
	if key == "font_size":
		_apply_font_size(value)

func _apply_font_size(new_size: int):
	if boot_log:
		boot_log.add_theme_font_size_override("normal_font_size", new_size)
		boot_log.add_theme_font_size_override("bold_font_size", new_size)
		boot_log.add_theme_font_size_override("mono_font_size", new_size)

# --- BOOT LOGIC ---

func run_boot_sequence():
	await get_tree().process_frame 
	
	for line in boot_lines:
		boot_log.append_text(line + "\n")
		await get_tree().create_timer(randf_range(0.05, 0.2)).timeout
	
	await get_tree().create_timer(boot_screen_timer).timeout
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	if terminal_node and terminal_node.has_method("activate_terminal"):
		terminal_node.activate_terminal()
	
	queue_free()
