extends Node

var current_mission_id : int = 0

enum TaskType { COMMAND, OUTPUT, VFS_STATE }

var missions = [
	{
		"sender": "Dr. Aris",
		"text": "Jesse, glad you're in. Let's verify the environment. List the files in your current directory.",
		"objective": "Run 'ls'",
		"type": TaskType.COMMAND,
		"value": "ls"
	},
	{
		"sender": "Dr. Aris",
		"text": "Hidden configs are key to the biomass logs. Use [color=#50fa7b]ls -a[/color] to find the hidden recovery key.",
		"objective": "Run 'ls -a'",
		"type": TaskType.COMMAND,
		"value": "ls -a"
	},
	{
		"sender": "Dr. Aris",
		"text": "Now, read that hidden key's content. We need the specific code string inside.",
		"objective": "Cat the .secret file",
		"type": TaskType.OUTPUT,
		"value": "DeepSea_AI_2026"
	},
	# --- NEW MISSIONS ---
	{
		"sender": "Dr. Aris",
		"text": "We need to keep these logs organized. Create a new directory named [color=#50fa7b]backups[/color] to store our previous simulation runs.",
		"objective": "Run 'mkdir backups'",
		"type": TaskType.VFS_STATE,
		"value": "/home/jesse/backups"
	},
	{
		"sender": "Dr. Aris",
		"text": "Good work. Now, let's prepare a new data capture. Create an empty file named [color=#50fa7b]capture_01.log[/color] inside that new backups folder.",
		"objective": "Run 'touch backups/capture_01.log'",
		"type": TaskType.VFS_STATE,
		"value": "/home/jesse/backups/capture_01.log"
	},
	{
		"sender": "Dr. Aris",
		"text": "Wait, I think there's a reference to a 'Wellington' coordinate in your [color=#50fa7b]readme.txt[/color]. Can you use [color=#50fa7b]grep[/color] to find the line containing 'Wellington'?",
		"objective": "Run 'grep Wellington readme.txt'",
		"type": TaskType.OUTPUT,
		"value": "Wellington"
	},
	{
		"sender": "Dr. Aris",
		"text": "The capture file was a mistake; it's corrupting the backup sequence. Remove the [color=#50fa7b]capture_01.log[/color] file immediately.",
		"objective": "Run 'rm backups/capture_01.log'",
		"type": TaskType.COMMAND, # Or VFS_STATE with a check for file absence if you prefer
		"value": "rm backups/capture_01.log"
	},
	{
		"sender": "Dr. Aris",
		"text": "Final check for the morning. Navigate into the [color=#50fa7b]backups[/color] directory and confirm your current location.",
		"objective": "Run 'cd backups' then 'pwd'",
		"type": TaskType.OUTPUT,
		"value": "/home/jesse/backups"
	}
]
