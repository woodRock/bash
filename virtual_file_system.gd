extends Node

var current_path = "/home/jesse"
var files = {}

func _init() -> void:
	reset_vfs()

func reset_vfs():
	files = {
		"/": {"type": "dir", "executable": true, "content": ""},
		"/bin": {"type": "dir", "executable": true, "content": ""},
		"/home/jesse": {"type": "dir", "executable": true, "content": ""},
		"/logs": {"type": "dir", "executable": true, "content": ""},
		"/tests": {"type": "dir", "executable": true, "content": ""},
		"/tmp": {"type": "dir", "executable": true, "content": ""},
	}
	_setup_binaries()
	_setup_tests()
	setup_day(MissionManager.current_day)

func setup_day(day_index: int):
	if day_index == 0: # Day 1: Vance Disappearance
		files["/home/jesse/readme.txt"] = {"type": "file", "executable": false, "content": "Preliminary data: silicon-based structure."}
		files["/home/jesse/.secret"] = {"type": "file", "executable": false, "content": "DeepSea_AI_2026"}
		files["/home/jesse/.journal"] = {"type": "file", "executable": false, "content": "something is wrong with the sensor array"}
	
	elif day_index == 1: # Day 2: The Logic Bomb
		files["/tmp/vance_recovery.sh"] = {"type": "file", "executable": false, "content": "if [ $DEBUG == 1 ]\nthen\necho Restoring hidden partitions\nfi"}
	
	elif day_index == 2: # Day 3: Harbor Logs
		files["/logs/Day_01.log"] = {"type": "file", "executable": false, "content": "Ambient: 16C"}
		files["/logs/Day_02.log"] = {"type": "file", "executable": false, "content": "Signal drift: High"}
		files["/logs/Day_03.log"] = {"type": "file", "executable": false, "content": "COORD: 41.2865S | SIGNAL: BOAT"}
		files["/logs/Day_04.log"] = {"type": "file", "executable": false, "content": "Sanitized by Aris."}
		files["/home/jesse/find_boat.sh"] = {"type": "file", "executable": false, "content": ""}

func _setup_binaries():
	# RE-FIXED test_bash.sh: Standardized subshell syntax
	files["/bin/test_bash.sh"] = {
		"type": "file", 
		"executable": true, 
		"content": "echo --- STARTING KERNEL SELF-TEST ---\nfor T in variables loops logic nav quotes\ndo\nexport ACTUAL=$(sh /tests/$T.sh)\nexport EXPECTED=$(cat /tests/$T.txt)\nif [ $ACTUAL == $EXPECTED ]\nthen\necho PASS: $T\nelse\necho FAIL: $T\nfi\ndone\necho --- SELF-TEST COMPLETE ---"
	}
	
	files["/bin/ls"] = {"type": "file", "executable": true, "content": "syscall ls"}
	files["/bin/cat"] = {"type": "file", "executable": true, "content": "cat $1"}
	files["/bin/nano"] = {"type": "file", "executable": true, "content": "syscall nano $1"}
	files["/bin/grep"] = {"type": "file", "executable": true, "content": "syscall grep $1 $2"}
	files["/bin/chmod"] = {"type": "file", "executable": true, "content": "syscall chmod $1 $2"}
	files["/bin/mv"] = {"type": "file", "executable": true, "content": "syscall mv $1 $2"}

func _setup_tests():
	# Subshell/Variable Expansion test
	files["/tests/variables.sh"] = {"type": "file", "executable": true, "content": "export X=TEST\necho $X"}
	files["/tests/variables.txt"] = {"type": "file", "executable": false, "content": "TEST"}
	
	# Loop test
	files["/tests/loops.sh"] = {"type": "file", "executable": true, "content": "for i in 1 2\ndo\necho $i\ndone"}
	files["/tests/loops.txt"] = {"type": "file", "executable": false, "content": "1\n2"}
	
	# Conditional Logic test
	files["/tests/logic.sh"] = {"type": "file", "executable": true, "content": "if [ 1 == 1 ]\nthen\necho OK\nfi"}
	files["/tests/logic.txt"] = {"type": "file", "executable": false, "content": "OK"}
	
	# PWD/Nav test
	files["/tests/nav.sh"] = {"type": "file", "executable": true, "content": "cd /bin\npwd"}
	files["/tests/nav.txt"] = {"type": "file", "executable": false, "content": "/bin"}
	
	# Quoting test
	files["/tests/quotes.sh"] = {"type": "file", "executable": true, "content": "echo Hello"}
	files["/tests/quotes.txt"] = {"type": "file", "executable": false, "content": "Hello"}

func resolve_path(target: String) -> String:
	if target.begins_with("/"): return target
	return ("/" + current_path + "/" + target).replace("//", "/")
