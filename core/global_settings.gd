extends Node

# Signal that UI components will connect to
signal setting_changed(key, value)

# --- CYBERPUNK PALETTE ---
var colors = {
	"background": "#050508",    # Void Black (Main background)
	"panel_bg": "#0d0e15",      # Deep Obsidian (Chat window background)
	"border": "#00ff41",        # Matrix Green (Borders)
	
	"sender_aris": "#ff0055",   # Neon Red/Pink (Antagonist)
	"sender_freya": "#00e5ff",  # Cyber Cyan (Ally)
	"sender_system": "#f1fa8c", # Warning Yellow (Kernel messages)
	"sender_default": "#bd93f9",# Electric Purple
	
	"body": "#e0e6ed",          # Ice White (High contrast for reading)
	"success": "#00ff41",       # Matrix Green
	"dim": "#6272a4",           # Muted Blue (Timestamps/Metadata)
	"objective": "#8be9fd"      # Hologram Blue (Bottom bar)
}

# Proxy property for font size
var font_size: int:
	get:
		return current_theme.font_size
	set(val):
		current_theme.font_size = clampi(val, 8, 72)
		setting_changed.emit("font_size", current_theme.font_size)

# The Resource that holds all theme data
var current_theme: ThemeConfig = ThemeConfig.new():
	set(val):
		current_theme = val
		_apply_theme()

func _ready():
	_apply_theme()

func update_font_size(delta: int):
	self.font_size += (delta * 2)

# Helper to get a color safely
func get_color(key: String) -> String:
	return colors.get(key, "#ffffff")

func _apply_theme():
	setting_changed.emit("theme", current_theme)
	setting_changed.emit("font_size", current_theme.font_size)
