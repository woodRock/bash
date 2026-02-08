extends Node

# --- SIGNALS ---
signal mission_updated

# --- DEFINITIONS ---
enum TaskType { COMMAND, OUTPUT, VFS_STATE, FILE_CONTENT }

# --- STATE ---
var current_day : int = 0
var current_mission_id : int = 0
var terminal = null
var vfs_node = null

# --- MISSION DATA ---

var days = [
	# ==========================================
	# DAY 0: TUTORIAL
	# Mood: Atmospheric, Safe.
	# ==========================================
	[
		{"music": "gatekeeper", "sender": "SYSTEM", "text": "Initializing Gatekeeper OS v4.0...\nUser detected. Welcome, Administrator.", "objective": "Type anything", "type": TaskType.COMMAND, "value": "*"},
		{"sender": "SYSTEM", "text": "This interface requires manual command input. To view the available command list, type [color=#f1fa8c]help[/color].", "objective": "Run 'help'", "type": TaskType.COMMAND, "value": "help"},
		{"sender": "SYSTEM", "text": "All standard Unix-like commands are supported. To understand specific command parameters, use the manual. Check the manual for 'ls' now.", "objective": "Run 'man ls'", "type": TaskType.COMMAND, "value": "man ls"},
		{"sender": "SYSTEM", "text": "The manual indicates 'ls' lists directory contents. Verify your current location.", "objective": "Run 'ls'", "type": TaskType.COMMAND, "value": "ls"},
		{"sender": "SYSTEM", "text": "Standard listing hides configuration files. Use the [color=#f1fa8c]-a[/color] flag to reveal all files.", "objective": "Run 'ls -a'", "type": TaskType.COMMAND, "value": "ls -a"},
		{"sender": "SYSTEM", "text": "Excellent. You can combine flags for detailed views. Try [color=#f1fa8c]ls -la[/color] to see hidden files with details.", "objective": "Run 'ls -la'", "type": TaskType.COMMAND, "value": "ls -la"},
		{"sender": "SYSTEM", "text": "Tutorial complete. Loading user profile...\n\n[color=#50fa7b]>> SYSTEM READY. WELCOME, JESSE.[/color]", "objective": "Type 'reboot'", "type": TaskType.COMMAND, "value": "reboot"}
	],

	# ==========================================
	# DAY 1: THE VANCE INCIDENT
	# Mood: Mystery -> Horror Reveal -> Action
	# ==========================================
	[
		{"music": "gatekeeper", "sender": "Dr. Aris", "text": "Jesse, I need you to focus. Dr. Vance's 'disappearance' is a HR matter. Clean up her workstation. Start by listing her local directory.", "objective": "List directory contents", "type": TaskType.COMMAND, "value": "ls"},
		{"sender": "Dr. Aris", "text": "She was paranoid, always hiding data in plain sight. Check for hidden entries (dotfiles) before we wipe the drive.", "objective": "List all files (hidden)", "type": TaskType.COMMAND, "value": "ls -a"},
		{"sender": "Dr. Aris", "text": "A .journal file? Highly unprofessional. [color=#f1fa8c]cat[/color] that file. See what she was rambling about.", "objective": "Concatenate .journal file", "type": TaskType.OUTPUT, "value": "something is wrong with the sensor array"},
		{"sender": "Dr. Aris", "text": "The sensor array is fine. She was overstressed. Create a [color=#50fa7b]recovery[/color] directory to dump her 'evidence'.", "objective": "Make directory 'recovery'", "type": TaskType.VFS_STATE, "value": "/home/jesse/recovery"},
		{"sender": "Dr. Aris", "text": "Good. Now move that [color=#f1fa8c]readme.md[/color] file into the recovery folder so we can scrub it from the root.", "objective": "Move readme to recovery", "type": TaskType.VFS_STATE, "value": "/home/jesse/recovery/readme.md"},
		{"sender": "SYSTEM", "text": "[ALERT] Unauthorized file movement detected. Partition flagged for review.", "objective": "Change directory to recovery", "type": TaskType.COMMAND, "value": "cd recovery"},
		
		# THEME: ENTITY
		{"music": "entity", "sender": "Dr. Vance", "text": "The biomass isn't just carbon. It's building something. Search the logs for [color=#ffb86c]silicon-based[/color] signatures.", "objective": "Grep for 'silicon'", "type": TaskType.OUTPUT, "value": "silicon-based"},
		
		# BACK TO NORMAL
		{"music": "gatekeeper", "sender": "Dr. Aris", "text": "Stop poking around, Wood. Sign the 'Authorized Access' log. \n[color=#6272a4](Note: In Nano, the caret '^' symbol means the CONTROL key. Press Ctrl+O to Save, Ctrl+X to Exit.)[/color]", "objective": "Open readme with nano", "type": TaskType.COMMAND, "value": "nano readme.md"},
		{"sender": "Dr. Aris", "text": "I don't see your signature yet. Open the file and sign it 'Jesse Wood'.", "objective": "Write 'Jesse Wood' in file", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/recovery/readme.md", "value": "Jesse Wood"},
		
		{"sender": "Dr. Vance", "text": "Aris is deleting keys. I've cached one your home directory [color=#f1fa8c]/home/jesse[/color]. Go there quickly.", "objective": "Change directory to ~", "type": TaskType.COMMAND, "value": "cd ~"},
		{"sender": "Dr. Vance", "text": "Copy the [color=#f1fa8c].secret[/color] file to [color=#f1fa8c]tmp[/color] before it's purged.", "objective": "Copy .secret to /tmp", "type": TaskType.VFS_STATE, "value": "/tmp/.secret"},
		{"sender": "Dr. Aris", "text": "That's enough. Delete that leftover .secret file and go home.", "objective": "Remove .secret file", "type": TaskType.COMMAND, "value": "rm .secret"},
		{"sender": "Dr. Aris", "text": "Ticket closed. I'm initiating a deep-level scrub of this sector tonight. Sleep well.\n\n[color=#ff5555]>> SYSTEM UPDATE REQUIRED. REBOOT TO APPLY.[/color]", "objective": "System Reboot", "type": TaskType.COMMAND, "value": "reboot"} 
	],
	
	# ==========================================
	# DAY 2: THE LOGIC BOMB
	# Mood: Investigation -> Hacking (Action)
	# ==========================================
	[
		{"music": "gatekeeper", "sender": "SYSTEM", "text": "[KERNEL] Critical Error: /recovery partition scrubbed at 03:00 NZDT. List home to verify damage.", "objective": "List directory contents", "type": TaskType.COMMAND, "value": "ls"},
		{"sender": "Vance AI", "text": "Damn it! He actually did it. He scrubbed the whole drive... wait. I kept a fragment in volatile memory. Check that directory quickly!", "objective": "List contents of /tmp", "type": TaskType.COMMAND, "value": "ls /tmp"},
		{"sender": "Vance AI", "text": "Okay, the script is there. Let's move into that folder so we don't have to type the full path every time.", "objective": "Change directory to /tmp", "type": TaskType.COMMAND, "value": "cd /tmp"},
		
		# THEME: HACKING
		# NOTE: Objective says "Execute", but the game expects it to fail first.
		{"music": "hacking", "sender": "Vance AI", "text": "He's trying to lock me out. The recovery script is here, but the execution bit is stripped. Try to run it.", "objective": "Execute recovery script", "type": TaskType.OUTPUT, "value": "Permission denied"},
		{"sender": "Vance AI", "text": "Permission denied? You need to grant execution rights (+x) to the file before the kernel will run it. Check [color=#f1fa8c]man chmod[/color] if you forgot.", "objective": "Add execute permission", "type": TaskType.COMMAND, "value": "chmod +x vance_recovery.sh"},
		{"sender": "Vance AI", "text": "Good. Now execute it.", "objective": "Execute recovery script", "type": TaskType.COMMAND, "value": "sh vance_recovery.sh"},
		{"sender": "Vance AI", "text": "Nothing happened? That's impossible. He must have left a logic trap. Read the script code ([color=#f1fa8c]cat[/color]) and see why it's failing silently.", "objective": "Concatenate script file", "type": TaskType.COMMAND, "value": "cat vance_recovery.sh"},
		{"sender": "Vance AI", "text": "I see it. `if [ $DEBUG == 1 ]`. He hid the restore function behind an environment variable. Set `DEBUG` to `1` to bypass his trap.", "objective": "Export DEBUG variable", "type": TaskType.COMMAND, "value": "export DEBUG=1"},
		{"sender": "Vance AI", "text": "Now the gate is open. Run the script again.", "objective": "Execute recovery script", "type": TaskType.OUTPUT, "value": "Restoring hidden partitions"},
		
		# BACK TO NORMAL
		{"music": "gatekeeper", "sender": "Vance AI", "text": "We have the data. But Aris knows we're active now. The network traffic from that restore script... he's going to come for us.\n\n[color=#ff5555]>> CONNECTION UNSTABLE. REBOOT RECOMMENDED.[/color]", "objective": "System Reboot", "type": TaskType.COMMAND, "value": "reboot"}
	],

	# ==========================================
	# DAY 3: THE HARBOR SEARCH
	# Mood: Scripting (Focus) -> Horror Reveal
	# ==========================================
	[
		{"music": "gatekeeper", "sender": "Freya", "text": "Jesse, the harbor sensors are screaming, but Aris is calling it 'sensor drift'. The truth is in the /logs directory.", "objective": "List contents of /logs", "type": TaskType.COMMAND, "value": "ls /logs"},
		
		# THEME: HACKING
		{"music": "hacking", "sender": "Freya", "text": "He flooded the directory with noise logs. We need a script. Create `find_boat.sh`.", "objective": "Create file 'find_boat.sh'", "type": TaskType.VFS_STATE, "value": "/home/jesse/find_boat.sh"},
		{"sender": "Vance AI", "text": "Open nano. First line: [color=#f1fa8c]#!/bin/bash[/color].", "objective": "Write interpreter header", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/find_boat.sh", "value": "#!/bin/bash"},
		{"sender": "Freya", "text": "We need to check every file. A 'For Loop' automates this. Type: [color=#f1fa8c]for DAY in 01 02 03 04[/color]. Then type [color=#f1fa8c]do[/color] on the next line.", "objective": "Write iteration loop", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/find_boat.sh", "value": "do"},
		{"sender": "Vance AI", "text": "Inside the loop, we search. Type: [color=#f1fa8c]grep 'BOAT' /logs/Day_${DAY}.log[/color].", "objective": "Write grep command", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/find_boat.sh", "value": "grep \'BOAT\' /logs/Day_${DAY}.log"},
		{"sender": "Freya", "text": "Close the loop block with [color=#f1fa8c]done[/color]. Then Exit Nano (^X).", "objective": "Close loop and save", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/find_boat.sh", "value": "done"},
		{"sender": "Dr. Aris", "text": "Playing developer? It won't run without the execution bit. You know the command.", "objective": "Add execute permission", "type": TaskType.COMMAND, "value": "chmod +x find_boat.sh"},
		{"sender": "Freya", "text": "Execute it. If the boat is in the harbor, the loop will catch it.", "objective": "Execute script", "type": TaskType.OUTPUT, "value": "41.2865S"},
		
		# THEME: ENTITY
		{"music": "entity", "sender": "Dr. Aris", "text": "Clever, Wood. You found the needle. But that boat belongs to the Institute. Move the script to /bin so I can audit your code.", "objective": "Move script to /bin", "type": TaskType.VFS_STATE, "value": "/bin/find_boat.sh"},
		{"sender": "Dr. Aris", "text": "You've dug too deep. That boat is tracking a biological uplink. Security is on their way.\n\n[color=#ff5555]>> TERMINAL LOCKDOWN INITIATED. REBOOT TO EXIT.[/color]", "objective": "System Reboot", "type": TaskType.COMMAND, "value": "reboot"}
	],
	
	# ==========================================
	# DAY 4: THE JAILBREAK
	# Mood: High Focus Hacking
	# ==========================================
	[
		{"music": "gatekeeper", "sender": "SYSTEM", "text": "[LOCKDOWN] Connection severed. Sandbox active.", "objective": "Print working directory", "type": TaskType.COMMAND, "value": "pwd"},
		{"sender": "Freya", "text": "Aris has rotated the encryption keys. I've intercepted a dump of 50 potential keys.", "objective": "List directory contents", "type": TaskType.COMMAND, "value": "ls"},
		{"sender": "Freya", "text": "They are in [color=#f1fa8c]access_codes.txt[/color]. You need to automate it.", "objective": "Concatenate code dump", "type": TaskType.COMMAND, "value": "cat access_codes.txt"},
		
		# THEME: HACKING
		{"music": "hacking", "sender": "Vance AI", "text": "Create a script `breaker.sh`. Iterate through the file contents. Feed every single line into the `unlock` command.", "objective": "Create 'breaker.sh'", "type": TaskType.VFS_STATE, "value": "/sandbox/breaker.sh"},
		{"sender": "Vance AI", "text": "Use the command substitution `$(cat ...)` to feed the loop.", "objective": "Write injection logic", "type": TaskType.FILE_CONTENT, "file": "/sandbox/breaker.sh", "value": "$(cat access_codes.txt)"},
		{"sender": "SYSTEM", "text": "Awaiting handshake...", "objective": "Execute script", "type": TaskType.OUTPUT, "value": "ACCESS GRANTED"},
		
		# BACK TO NORMAL
		{"music": "gatekeeper", "sender": "Freya", "text": "We're in. That was fast. I'm securing the connection now. Aris will be furious you broke out of his sandbox.\n\n[color=#50fa7b]>> JAILBREAK SUCCESSFUL. REBOOT TO RESTORE ROOT ACCESS.[/color]", "objective": "System Reboot", "type": TaskType.COMMAND, "value": "reboot"}
	],
	
	# ==========================================
	# DAY 5: THE HUNTER
	# Mood: Analysis -> Coding Battle -> Cosmic Horror
	# ==========================================
	[
		{"music": "gatekeeper", "sender": "SYSTEM", "text": "WARNING: Network throughput anomaly detected.", "objective": "List running processes", "type": TaskType.COMMAND, "value": "ps"},
		{"sender": "Freya", "text": "I see it. `system_d`. It's a mimetic virus. It clones the name of standard system processes so you can't distinguish it in the process list.", "objective": "Change directory to /proc", "type": TaskType.COMMAND, "value": "cd /proc"},
		{"sender": "Vance AI", "text": "Standard system daemons run in `MODE=IDLE`. The virus will be running in `MODE=HUNTER`.", "objective": "List process directories", "type": TaskType.COMMAND, "value": "ls"},
		{"sender": "Freya", "text": "You can't kill them randomly. Check the environment.", "objective": "Concatenate environment file", "type": TaskType.COMMAND, "value": "cat"},
		{"sender": "Vance AI", "text": "Go back to your home folder before we write the solution.", "objective": "Change directory to ~", "type": TaskType.COMMAND, "value": "cd ~"},
		
		# THEME: HACKING
		{"music": "hacking", "sender": "Vance AI", "text": "Write `cleaner.sh`. Loop through the PIDs in `/proc`. Check the `environ` file for the HUNTER signature. Kill only the positive match.", "objective": "Write kill logic", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/cleaner.sh", "value": "environ"},
		{"sender": "SYSTEM", "text": "Analyzing...", "objective": "Execute script", "type": TaskType.OUTPUT, "value": "terminated"},
		{"sender": "Freya", "text": "Target destroyed. Run `ps` to confirm the kill.", "objective": "List running processes", "type": TaskType.COMMAND, "value": "ps"},
		
		# THEME: ENTITY
		{"music": "entity", "sender": "SYSTEM", "text": "[SECURITY ALERT] Threat neutralized. Escalating privileges.\n[color=#50fa7b]>> ROOT ACCESS GRANTED.[/color]", "objective": "Print user identity", "type": TaskType.COMMAND, "value": "whoami"},
		{"sender": "Vance AI", "text": "Root access... Jesse, the [color=#f1fa8c]/root[/color] directory is finally open. The truth is inside.", "objective": "List /root contents", "type": TaskType.COMMAND, "value": "ls /root"},
		{"sender": "Vance AI", "text": "Go inside. We need to see this up close.", "objective": "Change directory to /root", "type": TaskType.COMMAND, "value": "cd /root"},
		{"sender": "Freya", "text": "Project Omega? Read it. Quickly, before Aris notices.", "objective": "Concatenate project_omega.txt", "type": TaskType.COMMAND, "value": "cat project_omega.txt"},
		{"sender": "Freya", "text": "Oh my god. We need to save this evidence before he wipes the drive. Copy it to your home directory! HURRY!", "objective": "Copy file to ~", "type": TaskType.COMMAND, "value": "*"}, 
		{"sender": "Dr. Aris", "text": "You found the truth. But you'll never leave with it. I am severing the physical hardline.\n\n[color=#ff5555][KERNEL PANIC] CONNECTION RESET BY PEER (Error 0xDEADBEEF)[/color]\n\n[color=#bd93f9]THANK YOU FOR PLAYING THE DEMO[/color]\n\nCreated with Godot Engine.\nType 'exit' to close.", "objective": "Exit terminal", "type": TaskType.COMMAND, "value": "exit"}
	]
]

# --- CORE LOGIC ---

func _ready():
	# Trigger initial music
	_check_music_trigger()

func get_current_missions():
	if current_day < days.size():
		return days[current_day]
	return []

func check_mission_progress(type: TaskType, input_value: String, response_text: String = ""):
	if current_day >= days.size(): return
	var active_missions = get_current_missions()
	if current_mission_id >= active_missions.size(): return
	
	var mission = active_missions[current_mission_id]
	var success = false
	
	if mission.get("type") != type: return
	
	if _validate_task(mission, type, input_value, response_text):
		success = true

	if success:
		_advance()

func _validate_task(mission, type, input_value, response_text):
	# COMMAND: Check if input starts with required string
	if type == TaskType.COMMAND:
		# If error present, fail immediately
		if "No such file" in response_text or "permission denied" in response_text.to_lower():
			return false
			
		var required = mission.get("value", "")
		if required == "*": return true
		
		# 1. Normalize delimiters
		var regex = RegEx.new()
		regex.compile("(&&|\\|\\||;)")
		var normalized = regex.sub(input_value, ";", true)
		var segments = normalized.split(";")
		
		for seg in segments:
			var clean = seg.strip_edges().replace("  ", " ")
			if clean.begins_with(required):
				return true
				
	# OUTPUT: Check if response contains string
	if type == TaskType.OUTPUT:
		if mission.get("value", "") in input_value: return true
		
	# VFS: Check if file exists
	if type == TaskType.VFS_STATE:
		if vfs_node and vfs_node.files.has(mission.get("value")): return true
		
	# FILE_CONTENT: Check inside file
	if type == TaskType.FILE_CONTENT:
		var path = mission.get("file", "")
		if vfs_node and vfs_node.files.has(path):
			if mission.get("value") in vfs_node.files[path].content:
				return true
				
	return false

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
	
	# Check music on every step
	_check_music_trigger()
	
	mission_updated.emit()
	print("Advanced to Day: ", current_day, " Mission: ", current_mission_id)

func _prepare_next_day_vfs():
	if vfs_node:
		vfs_node.reset_vfs()

func _check_music_trigger():
	if current_day >= days.size(): return
	var active_missions = get_current_missions()
	if current_mission_id >= active_missions.size(): return
	var mission = active_missions[current_mission_id]
	
	if mission.has("music"):
		MusicManager.transition_to(mission["music"], 2.0)
