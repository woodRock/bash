extends Node

var current_mission_id : int = 0

enum TaskType { COMMAND, OUTPUT, VFS_STATE }

# Using "text" consistently to avoid the "message" key error
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
	}
]
