extends Node

var current_path = "/home/jesse"
var files = {}

func _init() -> void:
	# Standard directory structure for Gatekeeper OS
	files = {
		"/": {"type": "dir", "executable": true, "content": ""},
		"/bin": {"type": "dir", "executable": true, "content": ""},
		"/home": {"type": "dir", "executable": true, "content": ""},
		"/home/jesse": {"type": "dir", "executable": true, "content": ""},
		"/tests": {"type": "dir", "executable": true, "content": ""},
		"/tmp": {"type": "dir", "executable": true, "content": ""},
	}
	_setup_system_binaries()
	_setup_test_suite()
	_setup_user_files()

func _setup_system_binaries():
	# Boot configuration
	files["/.bashrc"] = {
		"type": "file", "executable": true,
		"content": "clear\necho [color=#50fa7b]GATEKEEPER OS v1.5.8 ONLINE[/color]\necho Welcome back, Jesse Wood.\nsh /bin/test_bash.sh"
	}
	
	# The full boot-test script
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

	# Binary Mappings for Syscalls
	files["/bin/ls"] = {"type": "file", "executable": true, "content": "syscall ls"}
	files["/bin/cat"] = {"type": "file", "executable": true, "content": "cat $1"}
	files["/bin/mkdir"] = {"type": "file", "executable": true, "content": "syscall mkdir $1"}
	files["/bin/touch"] = {"type": "file", "executable": true, "content": "syscall touch $1"}
	files["/bin/rm"] = {"type": "file", "executable": true, "content": "syscall rm $1"}
	files["/bin/grep"] = {"type": "file", "executable": true, "content": "syscall grep $1 $2"}
	files["/bin/pwd"] = {"type": "file", "executable": true, "content": "pwd"}
	files["/bin/whoami"] = {"type": "file", "executable": true, "content": "whoami"}

func _setup_test_suite():
	# RESTORED: Full Test Suite
	files["/tests/variables.sh"] = {"type": "file", "executable": true, "content": "export X=TEST_VAL\necho $X"}
	files["/tests/variables.txt"] = {"type": "file", "executable": false, "content": "TEST_VAL"}
	
	files["/tests/loops.sh"] = {"type": "file", "executable": true, "content": "for i in 1 2\ndo\necho $i\ndone"}
	files["/tests/loops.txt"] = {"type": "file", "executable": false, "content": "1\n2"}
	
	files["/tests/logic.sh"] = {"type": "file", "executable": true, "content": "if [ 1 == 1 ]\nthen\necho OK\nfi"}
	files["/tests/logic.txt"] = {"type": "file", "executable": false, "content": "OK"}
	
	files["/tests/nav.sh"] = {"type": "file", "executable": true, "content": "cd /bin\npwd"}
	files["/tests/nav.txt"] = {"type": "file", "executable": false, "content": "/bin"}
	
	files["/tests/quotes.sh"] = {"type": "file", "executable": true, "content": "echo 'Hello,World!';"}
	files["/tests/quotes.txt"] = {"type": "file", "executable": false, "content": "Hello,World!"}

func _setup_user_files():
	# PhD Research Context
	files["/home/jesse/readme.txt"] = {"type": "file", "executable": false, "content": "Marine Biomass Analysis - Research Logs v1.2\nAuthorized Personnel Only.\n Wellington 41.2924° S, 174.7787° E"}
	files["/home/jesse/.secret"] = {"type": "file", "executable": false, "content": "DeepSea_AI_2026"}

func resolve_path(target: String) -> String:
	if target == "/": return "/"
	var abs_p = target if target.begins_with("/") else (current_path + "/" + target).replace("//", "/")
	var parts = abs_p.split("/", false)
	var clean = []
	for p in parts:
		if p == "..": 
			if clean.size() > 0: clean.remove_at(clean.size() - 1)
		elif p != ".": clean.append(p)
	return "/" + "/".join(clean)
