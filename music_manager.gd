extends Node

# 1. LINK THE NODES
# Make sure your MusicManager scene has AudioStreamPlayer nodes 
# named exactly like this:
@onready var tracks = {
	"gatekeeper": $Gatekeeper,
	"hacking": $Hacking,
	"entity": $Entity
}

var current_track: String = ""

func _ready():
	# 2. START EVERYTHING SILENTLY
	# We start all tracks at -80dB so they remain perfectly synced
	for name in tracks:
		tracks[name].volume_db = -80.0
		tracks[name].play()
	
	# Optional: Print to confirm it loaded
	print("Audio System Initialized. Tracks: ", tracks.keys())

func transition_to(track_name: String, fade_time: float = 2.0): # Increased default time to 2.0s for smoothness
	if current_track == track_name:
		return

	if not tracks.has(track_name):
		print("ERROR: Music track not found: ", track_name)
		return

	print("🎚️ DJ Crossfading to: ", track_name)
	
	var tween = create_tween()
	tween.set_parallel(true) 
	
	for name in tracks:
		var player = tracks[name]
		
		if name == track_name:
			# 1. THE FADE IN (Exponential Ease OUT)
			# We want the volume to jump up from -80 to -10 very quickly, 
			# then slowly settle at 0. This ensures we hear the new track immediately.
			if not player.playing: 
				player.play()
			
			tween.tween_property(player, "volume_db", 0.0, fade_time)\
				.set_trans(Tween.TRANS_EXPO)\
				.set_ease(Tween.EASE_OUT)
				
		else:
			# 2. THE FADE OUT (Exponential Ease IN)
			# We want the volume to stay loud (0 to -10) for a long time,
			# then crash down to -80 at the very end.
			tween.tween_property(player, "volume_db", -80.0, fade_time)\
				.set_trans(Tween.TRANS_EXPO)\
				.set_ease(Tween.EASE_IN)

	current_track = track_name

# Helper to kill audio (e.g. for the 'kill 808' command)
func silence_all(fade_time: float = 0.5):
	var tween = create_tween()
	tween.set_parallel(true)
	for name in tracks:
		tween.tween_property(tracks[name], "volume_db", -80.0, fade_time)
	current_track = "silence"
