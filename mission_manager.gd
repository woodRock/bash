extends Node

# --- SIGNALS ---
signal mission_updated

# --- DEFINITIONS ---
enum TaskType { COMMAND, OUTPUT, VFS_STATE, FILE_CONTENT }

# --- STATE ---
var current_day : int = 0 # 0 = Day 1, 1 = Day 2, 2 = Day 3
var current_mission_id : int = 0

# References assigned by the terminal/VFS at runtime via their _ready() functions
var terminal = null
var vfs_node = null

# --- MISSION DATA ---
var days = [
	# DAY 1: The Vance Incident
	[
		{"sender": "Dr. Aris", "text": "Jesse, I need you to focus. Dr. Vance's 'disappearance' is a HR matter. Clean up her workstation. Start by listing her local directory.", "objective": "Run 'ls'", "type": TaskType.COMMAND, "value": "ls"},
		{"sender": "Dr. Aris", "text": "She was paranoid, always hiding data in plain sight. Check for hidden entries before we wipe the drive.", "objective": "Run 'ls -a'", "type": TaskType.COMMAND, "value": "ls -a"},
		{"sender": "Dr. Aris", "text": "A .journal file? Highly unprofessional. See what she was rambling about so I can close this ticket.", "objective": "Cat the .journal file", "type": TaskType.OUTPUT, "value": "something is wrong with the sensor array"},
		{"sender": "Dr. Aris", "text": "The sensor array is fine. She was overstressed. Create a [color=#50fa7b]recovery[/color] directory to dump her 'evidence'.", "objective": "Run 'mkdir recovery'", "type": TaskType.VFS_STATE, "value": "/home/jesse/recovery"},
		{"sender": "SYSTEM", "text": "[ALERT] Unauthorized file movement: readme.txt shifted to recovery partition.", "objective": "Move readme.txt to recovery/", "type": TaskType.VFS_STATE, "value": "/home/jesse/recovery/readme.txt"},
		{"sender": "Dr. Vance", "text": "Jesse... if you're reading this, they're watching the root level. Go deeper into the [color=#f1fa8c]recovery[/color] folder. Don't let Aris see.", "objective": "Run 'cd recovery'", "type": TaskType.OUTPUT, "value": "/home/jesse/recovery"},
		{"sender": "Dr. Vance", "text": "The biomass isn't just carbon. It's building something. Search the logs for [color=#ffb86c]silicon-based[/color] signatures.", "objective": "Run 'grep silicon readme.txt'", "type": TaskType.OUTPUT, "value": "silicon-based"},
		{"sender": "Dr. Aris", "text": "Stop poking around, Wood. You're here to assist, not investigate. Sign the 'Authorized Access' log in that readme.", "objective": "Edit readme.txt with nano", "type": TaskType.COMMAND, "value": "nano readme.txt"},
		{"sender": "Dr. Vance", "text": "Aris is deleting keys. I've cached one. Copy the [color=#f1fa8c].secret[/color] file to [color=#f1fa8c]tmp[/color] before it's purged.", "objective": "Run 'cp ../.secret /tmp/.secret'", "type": TaskType.VFS_STATE, "value": "/tmp/.secret"},
		{"sender": "Dr. Aris", "text": "That's enough. Delete that leftover .secret file and go home.", "objective": "Run 'rm .secret'", "type": TaskType.COMMAND, "value": "rm .secret"}
	],
	
	# DAY 2: The Logic Bomb
	[
		{"sender": "SYSTEM", "text": "[KERNEL] Critical Error: /recovery partition scrubbed at 03:00 NZDT. List home to verify damage.", "objective": "Run 'ls -l'", "type": TaskType.COMMAND, "value": "ls -l"},
		{"sender": "Vance AI", "text": "I am a sub-process of her original research. I managed to hide a backup in the /tmp/ directory. Look quickly.", "objective": "Run 'ls /tmp'", "type": TaskType.COMMAND, "value": "ls /tmp"},
		{"sender": "Vance AI", "text": "He's trying to lock me out. The recovery script is there, but the execution bit is stripped.", "objective": "Run 'sh /tmp/vance_recovery.sh'", "type": TaskType.OUTPUT, "value": "Permission denied"},
		{"sender": "Vance AI", "text": "He's watching the permission logs. Change it anyway. We need that data back.", "objective": "Run 'chmod +x /tmp/vance_recovery.sh'", "type": TaskType.COMMAND, "value": "chmod +x /tmp/vance_recovery.sh"},
		{"sender": "Vance AI", "text": "There is a logic gate in the script—a kill switch Aris installed. Export the DEBUG variable to 1 to bypass his protocol.", "objective": "Run 'export DEBUG=1'", "type": TaskType.COMMAND, "value": "export DEBUG=1"},
		{"sender": "Vance AI", "text": "Now, run the script again. The hidden partitions are coming back online.", "objective": "Run 'sh /tmp/vance_recovery.sh'", "type": TaskType.OUTPUT, "value": "Restoring hidden partitions"}
	],

	# DAY 3: The Wellington Harbor Search
	[
		{"sender": "Freya", "text": "Jesse, the harbor sensors are screaming, but Aris is calling it 'sensor drift'. The truth is in the /logs directory.", "objective": "Run 'ls /logs'", "type": TaskType.COMMAND, "value": "ls /logs"},
		{"sender": "Freya", "text": "He flooded the directory with noise logs to hide the boat's signature. We need an automated search script.", "objective": "Run 'touch find_boat.sh'", "type": TaskType.VFS_STATE, "value": "/home/jesse/find_boat.sh"},
		{"sender": "Vance AI", "text": "Open nano. First, add the shebang: [color=#f1fa8c]#!/bin/bash[/color] to the first line and Save (^O).", "objective": "Add shebang and Save", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/find_boat.sh", "value": "#!/bin/bash"},
		{"sender": "Freya", "text": "Start the loop: [color=#f1fa8c]for DAY in 01 02 03 04[/color]. Then on the next line, type [color=#f1fa8c]do[/color] to open the block.", "objective": "Add 'for...do' and Save", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/find_boat.sh", "value": "do"},
		{"sender": "Vance AI", "text": "Now the core: [color=#f1fa8c]grep 'BOAT' /logs/Day_${DAY}.log[/color]. This uses string templating to find the hull signal.", "objective": "Add 'grep' line and Save", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/find_boat.sh", "value": "grep \'BOAT\' /logs/Day_${DAY}.log"},
		{"sender": "Freya", "text": "Close the loop block with [color=#f1fa8c]done[/color]. Then exit nano and make it executable.", "objective": "Add 'done', exit, and chmod +x", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/find_boat.sh", "value": "done"},
		{"sender": "Dr. Aris", "text": "Playing developer? It won't run without the execution bit. You know the command.", "objective": "Run 'chmod +x find_boat.sh'", "type": TaskType.COMMAND, "value": "chmod +x find_boat.sh"},
		{"sender": "Freya", "text": "Execute it. If the boat is in the harbor, we'll see coordinates around 41.28S range.", "objective": "Run 'sh find_boat.sh'", "type": TaskType.OUTPUT, "value": "41.2865S"},
		{"sender": "Dr. Aris", "text": "Clever, Wood. You've found a needle in a haystack. But that boat belongs to the Institute. Move the script to /bin.", "objective": "Move find_boat.sh to /bin", "type": TaskType.VFS_STATE, "value": "/bin/find_boat.sh"}
	],
]

# --- CORE LOGIC ---

func get_current_missions():
	if current_day < days.size():
		return days[current_day]
	return []

func check_mission_progress(type: TaskType, input_value: String):
	if current_day >= days.size(): return
	var active_missions = get_current_missions()
	if current_mission_id >= active_missions.size(): return
	
	var mission = active_missions[current_mission_id]
	var success = false

	match type:
		TaskType.COMMAND:
			var clean_input = input_value.strip_edges().replace("//", "/")
			if mission.get("value", "") in clean_input: 
				success = true
		
		TaskType.OUTPUT:
			if mission.get("value", "") in input_value: 
				success = true
		
		TaskType.VFS_STATE:
			if vfs_node:
				var target_path = vfs_node.resolve_path(mission.get("value", ""))
				if vfs_node.files.has(target_path):
					success = true
		
		TaskType.FILE_CONTENT:
			# Only check 'file' and 'value' if we are actually looking at content
			var target_file = mission.get("file", "")
			var required_val = mission.get("value", "")
			
			if vfs_node and vfs_node.files.has(target_file):
				var content = vfs_node.files[target_file].content
				if required_val in content:
					success = true

	if success:
		_advance()

func _advance():
	current_mission_id += 1
	
	# Handle day transitions
	if current_mission_id >= days[current_day].size():
		current_day += 1
		current_mission_id = 0
		if vfs_node:
			vfs_node.setup_day(current_day)
	
	# IMPORTANT: Emit the signal so your UI knows to update!
	mission_updated.emit()
	print("Advanced to Mission ID: ", current_mission_id, " on Day: ", current_day)
