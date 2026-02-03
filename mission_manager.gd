extends Node

enum TaskType { COMMAND, OUTPUT, VFS_STATE }

var current_day : int = 0
var current_mission_id : int = 0

# Missions grouped by Day
var days = [
	# DAY 1: The Vance Incident
	[
		{"sender": "Dr. Aris", "text": "Jesse, start by listing her home directory.", "objective": "Run 'ls'", "type": TaskType.COMMAND, "value": "ls"},
		{"sender": "Dr. Aris", "text": "Check for hidden files.", "objective": "Run 'ls -a'", "type": TaskType.COMMAND, "value": "ls -a"},
		{"sender": "Dr. Aris", "text": "Open the .journal file.", "objective": "Cat the .journal file", "type": TaskType.OUTPUT, "value": "something is wrong with the sensor array"},
		{"sender": "Dr. Aris", "text": "Create a directory called [color=#50fa7b]recovery[/color].", "objective": "Run 'mkdir recovery'", "type": TaskType.VFS_STATE, "value": "/home/jesse/recovery"},
		{"sender": "SYSTEM", "text": "Hide the [color=#f1fa8c]readme.txt[/color] into [color=#f1fa8c]recovery[/color].", "objective": "Move readme.txt to recovery/", "type": TaskType.VFS_STATE, "value": "/home/jesse/recovery/readme.txt"},
		{"sender": "Dr. Vance", "text": "Move into the [color=#f1fa8c]recovery[/color] folder.", "objective": "Run 'cd recovery'", "type": TaskType.OUTPUT, "value": "/home/jesse/recovery"},
		{"sender": "Dr. Vance", "text": "Search logs for [color=#ffb86c]silicon-based[/color].", "objective": "Run 'grep silicon readme.txt'", "type": TaskType.OUTPUT, "value": "silicon-based"},
		{"sender": "Dr. Aris", "text": "Add your name to the 'Authorized Access' list.", "objective": "Edit readme.txt with nano", "type": TaskType.COMMAND, "value": "nano readme.txt"},
		{"sender": "Dr. Vance", "text": "Copy the [color=#f1fa8c].secret[/color] key to [color=#f1fa8c]tmp[/color].", "objective": "Run 'cp ../.secret /tmp/.secret'", "type": TaskType.VFS_STATE, "value": "/tmp/.secret"},
		{"sender": "Dr. Aris", "text": "Navigate home and delete [color=#f1fa8c].secret[/color].", "objective": "Run 'rm .secret'", "type": TaskType.COMMAND, "value": "rm .secret"}
	],
	# DAY 2: The Logic Bomb
	[
		{"sender": "SYSTEM", "text": "Morning, Jesse. Aris wiped the recovery folder overnight. List your home directory to see the damage.", "objective": "Run 'ls -l'", "type": TaskType.COMMAND, "value": "ls -l"},
		{"sender": "Vance AI", "text": "I intercepted a backup. Check the /tmp directory.", "objective": "Run 'ls /tmp'", "type": TaskType.COMMAND, "value": "ls /tmp"},
		{"sender": "Vance AI", "text": "Try running my recovery script.", "objective": "Run 'sh /tmp/vance_recovery.sh'", "type": TaskType.OUTPUT, "value": "Permission denied"},
		{"sender": "Vance AI", "text": "He's locked execution. Force it.", "objective": "Run 'chmod +x /tmp/vance_recovery.sh'", "type": TaskType.COMMAND, "value": "chmod +x /tmp/vance_recovery.sh"},
		{"sender": "Vance AI", "text": "The script has a logic gate. Export the DEBUG variable to bypass it.", "objective": "Run 'export DEBUG=1'", "type": TaskType.COMMAND, "value": "export DEBUG=1"},
		{"sender": "Vance AI", "text": "Now, run the script again. Let's get your files back.", "objective": "Run 'sh /tmp/vance_recovery.sh'", "type": TaskType.OUTPUT, "value": "Restoring hidden partitions"}
	]
]

func get_current_missions():
	return days[current_day]
