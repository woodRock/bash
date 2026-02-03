extends Node

# The core state of your OS
var current_path = "/home/jesse"

# File Dictionary Structure:
# "path": {"type": "dir" or "file", "content": "string", "executable": bool}
var files = {
	"/": {"type": "dir"},
	"/bin": {"type": "dir"},
	"/home": {"type": "dir"},
	"/home/jesse": {"type": "dir"},
	"/tests": {"type": "dir"},
	"/tmp": {"type": "dir"},
}

func _ready() -> void:
	_setup_system_binaries()
	_setup_test_suite()
	_setup_user_files()

func _setup_system_binaries():
	# --- mkdir ---
	files["/bin/mkdir"] = {
		"type": "file", "executable": true,
		"content": "if [ $1 == '' ]\nthen\necho 'mkdir: missing operand'\nelse\nsyscall mkdir $1\nfi"
	}

	# --- rm ---
	files["/bin/rm"] = {
		"type": "file", "executable": true,
		"content": "if [ $1 == '' ]\nthen\necho 'rm: missing operand'\nelse\nsyscall rm $1\nfi"
	}

	# --- cp ---
	files["/bin/cp"] = {
		"type": "file", "executable": true,
		"content": "if [ $2 == '' ]\nthen\necho 'cp: missing destination'\nelse\nsyscall cp $1 $2\nfi"
	}

	# --- mv ---
	files["/bin/mv"] = {
		"type": "file", "executable": true,
		"content": "if [ $2 == '' ]\nthen\necho 'mv: missing destination'\nelse\nsyscall mv $1 $2\nfi"
	}

	# --- grep ---
	files["/bin/grep"] = {
		"type": "file", "executable": true,
		"content": "if [ $2 == '' ]\nthen\necho 'Usage: grep [PATTERN] [FILE]'\nelse\nexport RESULT=$(syscall grep $1 $2)\nif [ $RESULT == '' ]\nthen\necho ''\nelse\necho $RESULT\nfi\nfi"
	}

	# --- test_bash.sh ---
	files["/bin/test_bash.sh"] = {
		"type": "file", "executable": true,
		"content": """
echo '--- STARTING SYSTEM SELF-TEST ---'
for TEST_NAME in variables loops logic nav quotes
do
    export SCRIPT_PATH=/tests/$TEST_NAME.sh
    export EXPECT_PATH=/tests/$TEST_NAME.txt
    export ACTUAL=$(sh $SCRIPT_PATH > /dev/null)
    export EXPECTED=$(cat $EXPECT_PATH)
    if [ $ACTUAL == $EXPECTED ]
    then
        echo ✔ $TEST_NAME: PASSED
    else
        echo ✘ $TEST_NAME: FAILED
        echo "  Got: $ACTUAL"
    fi
done
echo '--- SELF-TEST COMPLETE ---'
"""
	}

func _setup_test_suite():
	files["/tests/variables.sh"] = {"type": "file", "executable": true, "content": "export FOO=bar\necho $FOO"}
	files["/tests/variables.txt"] = {"type": "file", "executable": false, "content": "bar"}
	files["/tests/loops.sh"] = {"type": "file", "executable": true, "content": "for i in 1 2\ndo\necho $i\ndone"}
	files["/tests/loops.txt"] = {"type": "file", "executable": false, "content": "1\n2"}
	files["/tests/logic.sh"] = {"type": "file", "executable": true, "content": "export KEY=secret\nif [ $KEY == secret ]\nthen\necho OK\nfi"}
	files["/tests/logic.txt"] = {"type": "file", "executable": false, "content": "OK"}
	files["/tests/nav.sh"] = {"type": "file", "executable": true, "content": "cd /bin\npwd"}
	files["/tests/nav.txt"] = {"type": "file", "executable": false, "content": "/bin"}
	files["/tests/quotes.sh"] = {"type": "file", "executable": true, "content": "echo 'Hello,World!';\necho \"DoubleQuotes\";"}
	files["/tests/quotes.txt"] = {"type": "file", "executable": false, "content": "Hello,World!\nDoubleQuotes"}

func _setup_user_files():
	files["/home/jesse/readme.txt"] = {
		"type": "file", "executable": false,
		"content": "Gatekeeper OS v1.3.5\nTry commands: grep, mkdir, rm, mv, cp, test_bash.sh"
	}

func resolve_path(target: String) -> String:
	if target == "/": return "/"
	var absolute_path = target if target.begins_with("/") else (current_path + "/" + target).replace("//", "/")
	var parts = absolute_path.split("/", false)
	var clean_parts = []
	for part in parts:
		if part == ".": continue
		if part == "..":
			if clean_parts.size() > 0: clean_parts.remove_at(clean_parts.size() - 1)
		else: clean_parts.append(part)
	return "/" + "/".join(clean_parts)
