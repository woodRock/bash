extends Node

# --- SIGNALS ---
signal mission_updated

# --- DEFINITIONS ---
enum TaskType { COMMAND, OUTPUT, VFS_STATE, FILE_CONTENT }

# --- STATE ---
var current_day : int = 0 
var current_mission_id : int = 0

# References assigned by the terminal/VFS at runtime via their _ready() functions
var terminal = null
var vfs_node = null

# --- MISSION DATA ---
var days = [
	# ==========================================
	# DAY 1: The Vance Incident (TUTORIAL MODE)
	# Explicit instructions to teach syntax.
	# ==========================================
	[
		{"sender": "Dr. Aris", "text": "Jesse, I need you to focus. Dr. Vance's 'disappearance' is a HR matter. Clean up her workstation. Start by listing her local directory.", "objective": "Run 'ls'", "type": TaskType.COMMAND, "value": "ls"},
		{"sender": "Dr. Aris", "text": "She was paranoid, always hiding data in plain sight. Check for hidden entries (dotfiles) before we wipe the drive.", "objective": "Run 'ls -a'", "type": TaskType.COMMAND, "value": "ls -a"},
		{"sender": "Dr. Aris", "text": "A .journal file? Highly unprofessional. Cat that file. See what she was rambling about so I can close this ticket.", "objective": "Cat the .journal file", "type": TaskType.OUTPUT, "value": "something is wrong with the sensor array"},
		{"sender": "Dr. Aris", "text": "The sensor array is fine. She was overstressed. Create a [color=#50fa7b]recovery[/color] directory to dump her 'evidence'.", "objective": "Run 'mkdir recovery'", "type": TaskType.VFS_STATE, "value": "/home/jesse/recovery"},
		
		# Move Logic
		{"sender": "Dr. Aris", "text": "Good. Now move that [color=#f1fa8c]readme.md[/color] file into the recovery folder so we can scrub it from the root.", "objective": "Run 'mv readme.md recovery/'", "type": TaskType.VFS_STATE, "value": "/home/jesse/recovery/readme.md"},
		
		# System Reaction
		{"sender": "SYSTEM", "text": "[ALERT] Unauthorized file movement detected. Partition flagged for review.", "objective": "Run 'cd recovery' to investigate", "type": TaskType.OUTPUT, "value": "/home/jesse/recovery"},
		
		{"sender": "Dr. Vance", "text": "The biomass isn't just carbon. It's building something. Search the logs for [color=#ffb86c]silicon-based[/color] signatures.", "objective": "Run 'grep silicon readme.md'", "type": TaskType.OUTPUT, "value": "silicon-based"},
		{"sender": "Dr. Aris", "text": "Stop poking around, Wood. Sign the 'Authorized Access' log. \n[color=#6272a4](Note: In Nano, the caret '^' symbol means the CONTROL key. Press Ctrl+O to Save, Ctrl+X to Exit.)[/color]", "objective": "Edit readme.md with nano", "type": TaskType.COMMAND, "value": "nano readme.md"},
		
		# Signature Check
		{"sender": "Dr. Aris", "text": "I don't see your signature yet. Open the file and sign it 'Jesse Wood'.", "objective": "Sign 'Jesse Wood' in readme.md", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/recovery/readme.md", "value": "Jesse Wood"},
		
		# Key Sequence
		{"sender": "Dr. Vance", "text": "Aris is deleting keys. I've cached one your home directory [color=#f1fa8c]/home/jesse[/color]. Go there quickly.", "objective": "Run 'cd ~'", "type": TaskType.COMMAND, "value": "cd ~"},
		{"sender": "Dr. Vance", "text": "Copy the [color=#f1fa8c].secret[/color] file to [color=#f1fa8c]tmp[/color] before it's purged.", "objective": "Run 'cp .secret /tmp/.secret'", "type": TaskType.VFS_STATE, "value": "/tmp/.secret"},
		
		{"sender": "Dr. Aris", "text": "That's enough. Delete that leftover .secret file and go home.", "objective": "Run 'rm .secret'", "type": TaskType.COMMAND, "value": "rm .secret"},
		
		# Day 1 Resolution
		{"sender": "Dr. Aris", "text": "Ticket closed. I'm initiating a deep-level scrub of this sector tonight. Don't be logged in when the sweep starts, Jesse. Sleep well.\n\n[color=#ff5555]>> SYSTEM UPDATE REQUIRED. REBOOT TO APPLY.[/color]", "objective": "Run 'reboot'", "type": TaskType.COMMAND, "value": "reboot"} 
	],
	
	# ==========================================
	# DAY 2: The Logic Bomb (PUZZLE MODE)
	# The player is given goals, not code.
	# ==========================================
	[
		{"sender": "SYSTEM", "text": "[KERNEL] Critical Error: /recovery partition scrubbed at 03:00 NZDT. List home to verify damage.", "objective": "List home contents", "type": TaskType.COMMAND, "value": "ls"},
		
		{"sender": "Vance AI", "text": "Damn it! He actually did it. He scrubbed the whole drive... wait. I kept a fragment in volatile memory. Check that directory quickly!", "objective": "List /tmp contents", "type": TaskType.COMMAND, "value": "ls /tmp"},
		
		# UX: Move to working directory
		{"sender": "Vance AI", "text": "Okay, the script is there. Let's move into that folder so we don't have to type the full path every time.", "objective": "Change directory to /tmp", "type": TaskType.COMMAND, "value": "cd /tmp"},
		
		# Puzzle Step 1: Permissions
		{"sender": "Vance AI", "text": "He's trying to lock me out. The recovery script is here, but the execution bit is stripped. Try to run it.", "objective": "Attempt to run vance_recovery.sh", "type": TaskType.OUTPUT, "value": "Permission denied"},
		{"sender": "Vance AI", "text": "Permission denied? You need to grant execution rights (+x) to the file before the kernel will run it. Check `man chmod` if you forgot.", "objective": "Make script executable", "type": TaskType.COMMAND, "value": "chmod +x vance_recovery.sh"},
		{"sender": "Vance AI", "text": "Good. Now execute it.", "objective": "Run vance_recovery.sh", "type": TaskType.COMMAND, "value": "sh vance_recovery.sh"},
		
		# Puzzle Step 2: Environment Variable Trap
		{"sender": "Vance AI", "text": "Nothing happened? That's impossible. He must have left a logic trap. Read the script code (`cat`) and see why it's failing silently.", "objective": "Read script content", "type": TaskType.COMMAND, "value": "cat vance_recovery.sh"},
		{"sender": "Vance AI", "text": "I see it. `if [ $DEBUG == 1 ]`. He hid the restore function behind an environment variable. Set `DEBUG` to `1` to bypass his trap.", "objective": "Export DEBUG=1", "type": TaskType.COMMAND, "value": "export DEBUG=1"},
		
		{"sender": "Vance AI", "text": "Now the gate is open. Run the script again.", "objective": "Run script successfully", "type": TaskType.OUTPUT, "value": "Restoring hidden partitions"},
		
		# Day 2 Resolution
		{"sender": "Vance AI", "text": "We have the data. But Aris knows we're active now. The network traffic from that restore script... he's going to come for us. We need to find *what* he's hiding in the harbor logs tomorrow.\n\n[color=#ff5555]>> CONNECTION UNSTABLE. REBOOT RECOMMENDED.[/color]", "objective": "Run 'reboot'", "type": TaskType.COMMAND, "value": "reboot"}
	],

	# ==========================================
	# DAY 3: The Wellington Harbor Search (EXAM MODE)
	# Pure problem solving.
	# ==========================================
	[
		{"sender": "Freya", "text": "Jesse, the harbor sensors are screaming, but Aris is calling it 'sensor drift'. The truth is in the /logs directory.", "objective": "List /logs", "type": TaskType.COMMAND, "value": "ls /logs"},
		{"sender": "Freya", "text": "He flooded the directory with noise logs. We need a script. Create `find_boat.sh`.", "objective": "Create 'find_boat.sh'", "type": TaskType.VFS_STATE, "value": "/home/jesse/find_boat.sh"},
		{"sender": "Vance AI", "text": "Open nano. First line: [color=#f1fa8c]#!/bin/bash[/color]. This is the 'Shebang'—it tells the kernel to use the Bash interpreter to run this code.", "objective": "Add shebang and Save", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/find_boat.sh", "value": "#!/bin/bash"},
		{"sender": "Freya", "text": "We need to check every file. A 'For Loop' automates this. Type: [color=#f1fa8c]for DAY in 01 02 03 04[/color]. Then type [color=#f1fa8c]do[/color] on the next line.", "objective": "Add 'for...do' loop", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/find_boat.sh", "value": "do"},
		{"sender": "Vance AI", "text": "Inside the loop, we search. Type: [color=#f1fa8c]grep 'BOAT' /logs/Day_${DAY}.log[/color]. The `${DAY}` part gets replaced by 01, 02, etc., automatically.", "objective": "Add grep command", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/find_boat.sh", "value": "grep \'BOAT\' /logs/Day_${DAY}.log"},
		{"sender": "Freya", "text": "Close the loop block with [color=#f1fa8c]done[/color]. Then Exit Nano (^X). Don't forget to make it executable.", "objective": "Finish script", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/find_boat.sh", "value": "done"},
		{"sender": "Dr. Aris", "text": "Playing developer? It won't run without the execution bit. You know the command.", "objective": "Make find_boat.sh executable", "type": TaskType.COMMAND, "value": "chmod +x find_boat.sh"},
		{"sender": "Freya", "text": "Execute it. If the boat is in the harbor, the loop will catch it.", "objective": "Run the script", "type": TaskType.OUTPUT, "value": "41.2865S"},
		{"sender": "Dr. Aris", "text": "Clever, Wood. You found the needle. But that boat belongs to the Institute. Move the script to /bin so I can audit your code.", "objective": "Move script to /bin", "type": TaskType.VFS_STATE, "value": "/bin/find_boat.sh"},
		
		# Day 3 Resolution
		{"sender": "Dr. Aris", "text": "You've dug too deep, Wood. That boat isn't tracking fish. It's tracking a biological uplink. And you just broadcasted its coordinates to the entire network. Security is on their way.\n\n[color=#ff5555]>> TERMINAL LOCKDOWN INITIATED. REBOOT TO EXIT.[/color]", "objective": "Run 'reboot'", "type": TaskType.COMMAND, "value": "reboot"}
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
				var target_path = mission.get("value", "")
				if vfs_node.files.has(target_path):
					success = true
		TaskType.FILE_CONTENT:
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
	var active_missions = get_current_missions()
	
	if current_mission_id >= active_missions.size():
		if current_day + 1 < days.size():
			current_day += 1
			current_mission_id = 0
			_prepare_next_day_vfs() 
		else:
			current_day += 1 
			print("GAME COMPLETE")
	
	mission_updated.emit()
	print("Advanced to Day: ", current_day, " Mission: ", current_mission_id)

func _prepare_next_day_vfs():
	if vfs_node:
		vfs_node.reset_vfs()
		vfs_node.setup_day(current_day)
