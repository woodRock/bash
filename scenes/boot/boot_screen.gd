extends ColorRect

# --- SIGNALS ---
signal boot_finished

@onready var boot_log = $BootLog
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
	GlobalSettings.setting_changed.connect(_on_setting_changed)
	_apply_font_size(GlobalSettings.font_size)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func start_boot():
	boot_log.clear()
	run_boot_sequence()

func run_boot_sequence():
	await get_tree().process_frame
	
	for line in boot_lines:
		boot_log.append_text(line + "\n")
		# Random typing speed variation for realism
		await get_tree().create_timer(randf_range(0.05, 0.2)).timeout
	
	# Hold for a moment to let the user read "READY"
	await get_tree().create_timer(boot_screen_timer).timeout
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	# Tell Main.gd we are done
	boot_finished.emit()

# --- FONT SCALING ---
func _on_setting_changed(key: String, value):
	if key == "font_size": _apply_font_size(value)

func _apply_font_size(new_size: int):
	if boot_log:
		boot_log.add_theme_font_size_override("normal_font_size", new_size)
		boot_log.add_theme_font_size_override("bold_font_size", new_size)
		boot_log.add_theme_font_size_override("mono_font_size", new_size)
