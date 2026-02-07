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
	# DAY 0: SYSTEM INITIALIZATION (TUTORIAL)
	# ==========================================
	[
		{"sender": "SYSTEM", "text": "Initializing Gatekeeper OS v4.0...\nUser detected. Welcome, Administrator.", "objective": "Initialize", "type": TaskType.COMMAND, "value": "*"},
		{"sender": "SYSTEM", "text": "This interface requires manual command input. To view the available command list, type [color=#f1fa8c]help[/color].", "objective": "Run 'help'", "type": TaskType.COMMAND, "value": "help"},
		{"sender": "SYSTEM", "text": "All standard Unix-like commands are supported. To understand specific command parameters, use the manual. Check the manual for 'ls' now.", "objective": "Run 'man ls'", "type": TaskType.COMMAND, "value": "man ls"},
		{"sender": "SYSTEM", "text": "The manual indicates 'ls' lists directory contents. Verify your current location.", "objective": "Run 'ls'", "type": TaskType.COMMAND, "value": "ls"},
		{"sender": "SYSTEM", "text": "Standard listing hides configuration files. Use the [color=#f1fa8c]-a[/color] flag to reveal all files.", "objective": "Run 'ls -a'", "type": TaskType.COMMAND, "value": "ls -a"},
		{"sender": "SYSTEM", "text": "Excellent. You can combine flags for detailed views. Try [color=#f1fa8c]ls -la[/color] to see hidden files with details.", "objective": "Run 'ls -la'", "type": TaskType.COMMAND, "value": "ls -la"},
		{"sender": "SYSTEM", "text": "Tutorial complete. Loading user profile...\n\n[color=#50fa7b]>> SYSTEM READY. WELCOME, JESSE.[/color]", "objective": "Type 'reboot' when you ready", "type": TaskType.COMMAND, "value": "reboot"}
	],

	# ==========================================
	# DAY 1: The Vance Incident
	# ==========================================
	[
		{"sender": "Dr. Aris", "text": "Jesse, I need you to focus. Dr. Vance's 'disappearance' is a HR matter. Clean up her workstation. Start by listing her local directory.", "objective": "Run 'ls'", "type": TaskType.COMMAND, "value": "ls"},
		{"sender": "Dr. Aris", "text": "She was paranoid, always hiding data in plain sight. Check for hidden entries (dotfiles) before we wipe the drive.", "objective": "Run 'ls -a'", "type": TaskType.COMMAND, "value": "ls -a"},
		{"sender": "Dr. Aris", "text": "A .journal file? Highly unprofessional. [color=#f1fa8c]cat[/color] that file. See what she was rambling about so I can close this ticket.", "objective": "Cat the .journal file", "type": TaskType.OUTPUT, "value": "something is wrong with the sensor array"},
		{"sender": "Dr. Aris", "text": "The sensor array is fine. She was overstressed. Create a [color=#50fa7b]recovery[/color] directory to dump her 'evidence'.", "objective": "Run 'mkdir recovery'", "type": TaskType.VFS_STATE, "value": "/home/jesse/recovery"},
		
		# Move Logic
		{"sender": "Dr. Aris", "text": "Good. Now move that [color=#f1fa8c]readme.md[/color] file into the recovery folder so we can scrub it from the root.", "objective": "Run 'mv readme.md recovery/'", "type": TaskType.VFS_STATE, "value": "/home/jesse/recovery/readme.md"},
		
		# System Reaction
		{"sender": "SYSTEM", "text": "[ALERT] Unauthorized file movement detected. Partition flagged for review.", "objective": "Run 'cd recovery' to investigate", "type": TaskType.COMMAND, "value": "cd recovery"},
		
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
	# DAY 2: The Logic Bomb
	# ==========================================
	[
		{"sender": "SYSTEM", "text": "[KERNEL] Critical Error: /recovery partition scrubbed at 03:00 NZDT. List home to verify damage.", "objective": "List home contents", "type": TaskType.COMMAND, "value": "ls"},
		{"sender": "Vance AI", "text": "Damn it! He actually did it. He scrubbed the whole drive... wait. I kept a fragment in volatile memory. Check that directory quickly!", "objective": "List /tmp contents", "type": TaskType.COMMAND, "value": "ls /tmp"},
		{"sender": "Vance AI", "text": "Okay, the script is there. Let's move into that folder so we don't have to type the full path every time.", "objective": "Change directory to /tmp", "type": TaskType.COMMAND, "value": "cd /tmp"},
		{"sender": "Vance AI", "text": "He's trying to lock me out. The recovery script is here, but the execution bit is stripped. Try to run it.", "objective": "Attempt to run vance_recovery.sh", "type": TaskType.OUTPUT, "value": "Permission denied"},
		{"sender": "Vance AI", "text": "Permission denied? You need to grant execution rights (+x) to the file before the kernel will run it. Check [color=#f1fa8c]man chmod[/color] if you forgot.", "objective": "Make script executable", "type": TaskType.COMMAND, "value": "chmod +x vance_recovery.sh"},
		{"sender": "Vance AI", "text": "Good. Now execute it.", "objective": "Run vance_recovery.sh", "type": TaskType.COMMAND, "value": "sh vance_recovery.sh"},
		{"sender": "Vance AI", "text": "Nothing happened? That's impossible. He must have left a logic trap. Read the script code ([color=#f1fa8c]cat[/color]) and see why it's failing silently.", "objective": "Read script content", "type": TaskType.COMMAND, "value": "cat vance_recovery.sh"},
		{"sender": "Vance AI", "text": "I see it. `if [ $DEBUG == 1 ]`. He hid the restore function behind an environment variable. Set `DEBUG` to `1` to bypass his trap. See [color=#f1fa8c]man export[/color] to jog your memory.", "objective": "Set environment variable", "type": TaskType.COMMAND, "value": "export DEBUG=1"},
		{"sender": "Vance AI", "text": "Now the gate is open. Run the script again.", "objective": "Run script successfully", "type": TaskType.OUTPUT, "value": "Restoring hidden partitions"},
		{"sender": "Vance AI", "text": "We have the data. But Aris knows we're active now. The network traffic from that restore script... he's going to come for us. We need to find *what* he's hiding in the harbor logs tomorrow.\n\n[color=#ff5555]>> CONNECTION UNSTABLE. REBOOT RECOMMENDED.[/color]", "objective": "Run 'reboot'", "type": TaskType.COMMAND, "value": "reboot"}
	],

	# ==========================================
	# DAY 3: The Wellington Harbor Search
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
		{"sender": "Dr. Aris", "text": "You've dug too deep, Wood. That boat isn't tracking fish. It's tracking a biological uplink. And you just broadcasted its coordinates to the entire network. Security is on their way.\n\n[color=#ff5555]>> TERMINAL LOCKDOWN INITIATED. REBOOT TO EXIT.[/color]", "objective": "Run 'reboot'", "type": TaskType.COMMAND, "value": "reboot"}
	],
	
	# ==========================================
	# DAY 4: The Jailbreak
	# ==========================================
	[
		{"sender": "SYSTEM", "text": "[LOCKDOWN] Connection severed. Sandbox active.", "objective": "Check status", "type": TaskType.COMMAND, "value": "pwd"},
		{"sender": "Freya", "text": "Aris has rotated the encryption keys. I've intercepted a dump of 50 potential keys, but I don't know which one is active.", "objective": "List files", "type": TaskType.COMMAND, "value": "ls"},
		{"sender": "Freya", "text": "They are in [color=#f1fa8c]access_codes.txt[/color]. If you try to type them manually, the system will lock you out before you hit the tenth one. You need to automate it.", "objective": "Read the codes", "type": TaskType.COMMAND, "value": "cat access_codes.txt"},
		{"sender": "Vance AI", "text": "Create a script `breaker.sh`. Iterate through the file contents. Feed every single line into the `unlock` command.", "objective": "Script the solution", "type": TaskType.VFS_STATE, "value": "/sandbox/breaker.sh"},
		{"sender": "Vance AI", "text": "Use the command substitution `$(cat ...)` to feed the loop.", "objective": "Write loop logic", "type": TaskType.FILE_CONTENT, "file": "/sandbox/breaker.sh", "value": "$(cat access_codes.txt)"},
		{"sender": "SYSTEM", "text": "Awaiting handshake...", "objective": "Run the script", "type": TaskType.OUTPUT, "value": "ACCESS GRANTED"},
		{"sender": "Freya", "text": "We're in. That was fast. I'm securing the connection now. Aris will be furious you broke out of his sandbox.\n\n[color=#50fa7b]>> JAILBREAK SUCCESSFUL. REBOOT TO RESTORE ROOT ACCESS.[/color]", "objective": "Run 'reboot'", "type": TaskType.COMMAND, "value": "reboot"}
	],
	
	# ==========================================
	# DAY 5: The Hunter
	# ==========================================
	[
		{"sender": "SYSTEM", "text": "WARNING: Network throughput anomaly detected.", "objective": "Check running processes", "type": TaskType.COMMAND, "value": "ps"},
		{"sender": "Freya", "text": "I see it. `system_d`. It's a mimetic virus. It clones the name of standard system processes so you can't distinguish it in the process list.", "objective": "Navigate to /proc", "type": TaskType.COMMAND, "value": "cd /proc"},
		{"sender": "Vance AI", "text": "It can clone the name, but not the environment. Standard system daemons run in `MODE=IDLE`. The virus will be running in `MODE=HUNTER`.", "objective": "List the PIDs", "type": TaskType.COMMAND, "value": "ls"},
		{"sender": "Freya", "text": "You can't kill them randomly. If you kill a real system daemon, the kernel panics and we lose the connection. You have to be surgical.", "objective": "Check a process environment", "type": TaskType.COMMAND, "value": "cat"},
		{"sender": "Vance AI", "text": "We shouldn't work inside the process directory. Go back to your home folder before we write the solution.", "objective": "Return home", "type": TaskType.COMMAND, "value": "cd ~"},
		{"sender": "Vance AI", "text": "Write `cleaner.sh`. Loop through the PIDs in `/proc`. Check the `environ` file for the HUNTER signature. Kill only the positive match.", "objective": "Script the logic", "type": TaskType.FILE_CONTENT, "file": "/home/jesse/cleaner.sh", "value": "environ"},
		{"sender": "SYSTEM", "text": "Analyzing...", "objective": "Run script", "type": TaskType.OUTPUT, "value": "terminated"},
		{"sender": "Freya", "text": "Target destroyed. Run `ps` to confirm the kill.", "objective": "Verify Kill", "type": TaskType.COMMAND, "value": "ps"},
		{"sender": "SYSTEM", "text": "[SECURITY ALERT] Threat neutralized. Escalating privileges.\n[color=#50fa7b]>> ROOT ACCESS GRANTED.[/color]", "objective": "Check privileges", "type": TaskType.COMMAND, "value": "whoami"},
		{"sender": "Vance AI", "text": "Root access... Jesse, the [color=#f1fa8c]/root[/color] directory is finally open. The truth is inside.", "objective": "List root", "type": TaskType.COMMAND, "value": "ls /root"},
		{"sender": "Vance AI", "text": "Go inside. We need to see this up close.", "objective": "Navigate to root", "type": TaskType.COMMAND, "value": "cd /root"},
		{"sender": "Freya", "text": "Project Omega? Read it. Quickly, before Aris notices.", "objective": "Read the file", "type": TaskType.COMMAND, "value": "cat project_omega.txt"},
		{"sender": "Freya", "text": "Oh my god. We need to save this evidence before he wipes the drive. Copy it to your home directory! HURRY!", "objective": "Panic copy", "type": TaskType.COMMAND, "value": "*"}, 
		{"sender": "Dr. Aris", "text": "You found the truth. But you'll never leave with it. I am severing the physical hardline.\n\n[color=#ff5555][KERNEL PANIC] CONNECTION RESET BY PEER (Error 0xDEADBEEF)[/color]\n\n[color=#bd93f9]THANK YOU FOR PLAYING THE DEMO[/color]\n\nCreated with Godot Engine.\nType 'exit' to close.", "objective": "End", "type": TaskType.COMMAND, "value": "exit"}
	]
]

# --- CORE LOGIC ---

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

	match type:
		TaskType.COMMAND:
			# FIX: If command resulted in an error, do NOT progress
			if "No such file" in response_text or "permission denied" in response_text.to_lower():
				return

			var required_val = mission.get("value", "")
			
			if required_val == "*":
				success = true
			else:
				# 1. Regex substitute to normalize delimiters (&&, ||) into ;
				var regex = RegEx.new()
				regex.compile("(&&|\\|\\||;)")
				var normalized_input = regex.sub(input_value, ";", true)
				
				# 2. Split by the semicolon
				var raw_segments = normalized_input.split(";")
				
				for seg in raw_segments:
					# 3. Normalize spaces
					var clean_seg = seg.strip_edges()
					while "  " in clean_seg:
						clean_seg = clean_seg.replace("  ", " ")
					
					# 4. Strict check
					if clean_seg.begins_with(required_val):
						success = true
						break

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
