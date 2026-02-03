extends Node

var current_mission_id : int = 0

enum TaskType { COMMAND, OUTPUT, VFS_STATE }

var missions = [
	{
		"sender": "Dr. Aris",
		"text": "Jesse, thanks for stepping in. Dr. Vance left her PhD thesis unfinished before her... departure. We need to clear her workspace. Start by listing her home directory.",
		"objective": "Run 'ls'",
		"type": TaskType.COMMAND,
		"value": "ls"
	},
	{
		"sender": "Dr. Aris",
		"text": "It looks empty. She must have archived everything. But Vance was paranoid—she often hid system configs. Check for hidden files.",
		"objective": "Run 'ls -a'",
		"type": TaskType.COMMAND,
		"value": "ls -a"
	},
	{
		"sender": "Dr. Aris",
		"text": "A [color=#f1fa8c].journal[/color] file? Interesting. Open it. We need to see if she left any passwords for the biomass server.",
		"objective": "Cat the .journal file",
		"type": TaskType.OUTPUT,
		"value": "something is wrong with the sensor array"
	},
	{
		"sender": "Dr. Aris",
		"text": "She was always complaining about sensors. Jesse, create a directory called [color=#50fa7b]recovery[/color]. We'll move her 'junk' there so I can audit it later.",
		"objective": "Run 'mkdir recovery'",
		"type": TaskType.VFS_STATE,
		"value": "/home/jesse/recovery"
	},
	{
		"sender": "SYSTEM (Intercepted)",
		"text": "[color=#ff5555][b]PRIVATE MSG:[/b][/color] Jesse, don't trust Aris. He's deleting my logs. Use [color=#50fa7b]mv[/color] to hide the [color=#f1fa8c]readme.txt[/color] into your new [color=#f1fa8c]recovery[/color] folder before he wipes the root.",
		"objective": "Move readme.txt to recovery/",
		"type": TaskType.VFS_STATE,
		"value": "/home/jesse/recovery/readme.txt"
	},
	# --- NEW MISSION: NAVIGATION ---
	{
		"sender": "Dr. Vance (Script Fragment)",
		"text": "They're watching the root directory. You need to move into the [color=#f1fa8c]recovery[/color] folder to work on the files safely.",
		"objective": "Run 'cd recovery' then 'pwd'",
		"type": TaskType.OUTPUT,
		"value": "/home/jesse/recovery" # Validated by the PWD output in the response
	},
	{
		"sender": "Dr. Vance (Journal Entry)",
		"text": "The biomass in the Cook Strait... it's not algae. It's [color=#ffb86c]silicon-based[/color]. Search the logs for that keyword.",
		"objective": "Run 'grep silicon readme.txt'",
		"type": TaskType.OUTPUT,
		"value": "silicon-based"
	},
	{
		"sender": "Dr. Aris",
		"text": "Jesse? I see you moved into the recovery folder. Use [color=#50fa7b]nano[/color] to open that readme. I want you to add your name to the 'Authorized Access' list at the bottom.",
		"objective": "Edit readme.txt with nano",
		"type": TaskType.COMMAND,
		"value": "nano readme.txt"
	},
	{
		"sender": "Dr. Vance (Script Fragment)",
		"text": "I've encrypted the coordinates. Duplicate the [color=#f1fa8c].secret[/color] key into the [color=#f1fa8c]tmp[/color] folder so my automated boat can find it.",
		"objective": "Run 'cp ../.secret /tmp/.secret'", # Teaching relative pathing
		"type": TaskType.VFS_STATE,
		"value": "/tmp/.secret"
	},
	{
		"sender": "Dr. Aris",
		"text": "Wait... a file copy to /tmp? What are you doing? Navigate back home and delete that [color=#f1fa8c].secret[/color] file immediately.",
		"objective": "Run 'cd ..' then 'rm .secret'",
		"type": TaskType.COMMAND,
		"value": "rm .secret"
	}
]
