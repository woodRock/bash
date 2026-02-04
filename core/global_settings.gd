extends Node

# Signal that UI components will connect to
signal setting_changed(key, value)

# Proxy property for easy access from other scripts
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
	# Ensure the proxy property is initialized
	_apply_theme()

func update_font_size(delta: int):
	# Using 'self.font_size' triggers the setter logic above
	self.font_size += (delta * 2)

func _apply_theme():
	# Emit both the whole theme and the specific font_size for listeners
	setting_changed.emit("theme", current_theme)
	setting_changed.emit("font_size", current_theme.font_size)
