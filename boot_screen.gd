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
	# Force the boot screen to be full screen immediately
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# High Z-index if in a CanvasLayer, or just ensure it's the last child
	run_boot_sequence()

func run_boot_sequence():
	await get_tree().process_frame # Wait for UI to settle
	
	for line in boot_lines:
		boot_log.append_text(line + "\n")
		# Visual feedback for the "hacker" feel
		await get_tree().create_timer(randf_range(0.05, 0.2)).timeout
	
	await get_tree().create_timer(boot_screen_timer).timeout
	
	# Transition
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	if terminal_node and terminal_node.has_method("activate_terminal"):
		terminal_node.activate_terminal()
	
	queue_free()
