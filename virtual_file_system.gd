extends Node

var current_path = "/home/jesse"
var files = {}

func _init() -> void:
	reset_vfs()

func reset_vfs():
	# Standard directory structure for Gatekeeper OS
	files = {
		"/": {"type": "dir", "executable": true, "content": ""},
		"/bin": {"type": "dir", "executable": true, "content": ""},
		"/home/jesse": {"type": "dir", "executable": true, "content": ""},
		"/tests": {"type": "dir", "executable": true, "content": ""},
		"/tmp": {"type": "dir", "executable": true, "content": ""},
	}
	_setup_system_binaries()
	_setup_test_suite() # Restored
	setup_day(MissionManager.current_day)

func setup_day(day_index: int):
	# This function handles narrative state changes without wiping /bin or /tests
	if day_index == 0:
		files["/home/jesse/readme.txt"] = {
			"type": "file", 
			"executable": false, 
			"content": "Biomass Analysis Log: Wellington Coast.\nPreliminary data suggests a dense [color=#ffb86c]silicon-based[/color] structure beneath the algae beds.\n\n--- AUTHORIZED ACCESS LIST ---\n1. Dr. Elara Vance\n2. Dr. Aris\n3. "
		}
		files["/home/jesse/.secret"] = {"type": "file", "executable": false, "content": "DeepSea_AI_2026"}
		files["/home/jesse/.journal"] = {"type": "file", "executable": false, "content": "March 02: something is wrong with the sensor array"}
	
	elif day_index == 1:
		# Day 2 State: recovery folder is "gone", script appears in /tmp
		files["/home/jesse/readme.txt"] = {"type": "file", "executable": false, "content": "Biomass Analysis Log... [LOCKED BY ADMIN]"}
		files["/tmp/.backup_readme"] = {
			"type": "file", 
			"executable": false, 
			"content": "Biomass Analysis Log: Wellington Coast.\nPreliminary data suggests a dense [color=#ffb86c]silicon-based[/color] structure beneath the algae beds.\n\n--- AUTHORIZED ACCESS LIST ---\n1. Dr. Elara Vance\n2. Dr. Aris\n3. Jesse Wood"
		}
		files["/tmp/vance_recovery.sh"] = {
			"type": "file",
			"executable": false, # Requires chmod +x
			"content": """if [ $DEBUG == 1 ]
then
    echo [color=#50fa7b]DEBUG MODE ACTIVE. Restoring hidden partitions...[/color]
    syscall mkdir /home/jesse/recovery
    syscall mv /tmp/.backup_readme /home/jesse/recovery/readme.txt
else
    echo [color=#ff5555]ERROR: Security handshake failed. Unauthorized execution.[/color]
fi"""
		}

func _setup_system_binaries():
	files["/.bashrc"] = {
		"type": "file", "executable": true,
		"content": "clear\necho [color=#50fa7b]GATEKEEPER OS v1.5.8 ONLINE[/color]\necho Welcome back, Jesse.\nsh /bin/test_bash.sh"
	}
	
	files["/bin/test_bash.sh"] = {
		"type": "file", "executable": true,
		"content": """echo '--- SYSTEM SELF-TEST ---'
for T in variables loops logic nav quotes
do
    export ACTUAL=$(sh /tests/$T.sh > /dev/null)
    export EXPECTED=$(cat /tests/$T.txt)
    if [ $ACTUAL == $EXPECTED ]
    then
        echo ✔ $T: PASSED
    else
        echo ✘ $T: FAILED
    fi
done
echo '--- SELF-TEST COMPLETE ---'"""
	}

	# --- SYSCALL BINARY MAPPINGS ---
	files["/bin/ls"] = {"type": "file", "executable": true, "content": "syscall ls"}
	files["/bin/cat"] = {"type": "file", "executable": true, "content": "cat $1"}
	files["/bin/nano"] = {"type": "file", "executable": true, "content": "syscall nano $1"}
	files["/bin/grep"] = {"type": "file", "executable": true, "content": "syscall grep $1 $2"}
	files["/bin/pwd"] = {"type": "file", "executable": true, "content": "pwd"}
	files["/bin/mkdir"] = {"type": "file", "executable": true, "content": "syscall mkdir $1"}
	files["/bin/touch"] = {"type": "file", "executable": true, "content": "syscall touch $1"}
	files["/bin/rm"] = {"type": "file", "executable": true, "content": "syscall rm $1"}
	files["/bin/cp"] = {"type": "file", "executable": true, "content": "syscall cp $1 $2"}
	files["/bin/mv"] = {"type": "file", "executable": true, "content": "syscall mv $1 $2"}
	files["/bin/chmod"] = {"type": "file", "executable": true, "content": "syscall chmod $1 $2"}

func _setup_test_suite():
	# Restored full test suite logic for the bash kernel
	files["/tests/variables.sh"] = {"type": "file", "executable": true, "content": "export X=TEST\necho $X"}
	files["/tests/variables.txt"] = {"type": "file", "executable": false, "content": "TEST"}
	files["/tests/loops.sh"] = {"type": "file", "executable": true, "content": "for i in 1 2\ndo\necho $i\ndone"}
	files["/tests/loops.txt"] = {"type": "file", "executable": false, "content": "1\n2"}
	files["/tests/logic.sh"] = {"type": "file", "executable": true, "content": "if [ 1 == 1 ]\nthen\necho OK\nfi"}
	files["/tests/logic.txt"] = {"type": "file", "executable": false, "content": "OK"}
	files["/tests/nav.sh"] = {"type": "file", "executable": true, "content": "cd /bin\npwd"}
	files["/tests/nav.txt"] = {"type": "file", "executable": false, "content": "/bin"}
	files["/tests/quotes.sh"] = {"type": "file", "executable": true, "content": "echo 'Hello,World!';"}
	files["/tests/quotes.txt"] = {"type": "file", "executable": false, "content": "Hello,World!"}

func resolve_path(target: String) -> String:
	if target.begins_with("/"): return target
	var abs_p = (current_path + "/" + target).replace("//", "/")
	var parts = abs_p.split("/", false)
	var clean = []
	for p in parts:
		if p == "..": 
			if clean.size() > 0: clean.remove_at(clean.size() - 1)
		elif p != ".": clean.append(p)
	return "/" + "/".join(clean)
