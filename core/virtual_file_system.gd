extends Node

var current_path = "/home/jesse"
var files = {}

func _init() -> void:
	reset_vfs()

func reset_vfs():
	files = {
		"/": {"type": "dir", "executable": true, "content": ""},
		"/bin": {"type": "dir", "executable": true, "content": ""},
		"/home": {"type": "dir", "executable": true, "content": ""},
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
		files["/home/jesse/readme.md"] = {
			"type": "file",
			"executable": false,
			"content": """# DEEP SEA INSTITUTE: PROJECT GATEKEEPER
> **PROPERTY OF DR. VANCE - DO NOT PURGE**

## RESEARCH LOG: ARCHIVE 09-B
Preliminary data analysis of the Wellington Harbor sediment samples indicates a **highly irregular silicon-based structure**. Unlike local carbon-based biomass, this entity demonstrates a recursive growth pattern consistent with a synthetic origin. 

[ALERT]: Local sensor arrays are picking up significant signal drift. Dr. Aris insists it is hardware fatigue, but the timestamps match the entity's expansion.

## AUTHORIZED ACCESS LOG
The following personnel are cleared for Project Gatekeeper terminal use. Please sign below to acknowledge the corporate non-disclosure agreement.

- **Dr. Aris** (Lead Administrator)
- **Dr. Vance** (Senior Research - DISMISSED)
- **Jesse Wood** (Research Assistant)

**SIGNATURE:** """
		}
		files["/home/jesse/.secret"] = {"type": "file", "executable": false, "content": "DeepSea_AI_2026"}
		files["/home/jesse/.journal"] = {"type": "file", "executable": false, "content": "something is wrong with the sensor array"}
	
	elif day_index == 1: # Day 2: The Logic Bomb
		files["/tmp/vance_recovery.sh"] = {"type": "file", "executable": false, "content": "if [ $DEBUG == 1 ]\nthen\necho Restoring hidden partitions\nfi"}
	
	elif day_index == 2: # Day 3: Harbor Logs
		files["/logs/Day_01.log"] = {"type": "file", "executable": false, "content": "Ambient: 16C"}
		files["/logs/Day_02.log"] = {"type": "file", "executable": false, "content": "Signal drift: High"}
		files["/logs/Day_03.log"] = {"type": "file", "executable": false, "content": "COORD: 41.2865S | SIGNAL: BOAT"}
		files["/logs/Day_04.log"] = {"type": "file", "executable": false, "content": "Sanitized by Aris."}

func _setup_binaries():
	# The core self-test script
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
	files["/bin/mkdir"] = {"type": "file", "executable": true, "content": "syscall mkdir $1"}
	files["/bin/touch"] = {"type": "file", "executable": true, "content": "syscall touch $1"}
	files["/bin/rm"] = {"type": "file", "executable": true, "content": "syscall rm $1"}

func _setup_tests():
	# ===== BASIC TESTS (Original) =====
	files["/tests/variables.sh"] = {"type": "file", "executable": true, "content": "export X=TEST\necho $X"}
	files["/tests/variables.txt"] = {"type": "file", "executable": false, "content": "TEST"}
	
	files["/tests/loops.sh"] = {"type": "file", "executable": true, "content": "for i in 1 2\ndo\necho $i\ndone"}
	files["/tests/loops.txt"] = {"type": "file", "executable": false, "content": "1\n2"}
	
	files["/tests/logic.sh"] = {"type": "file", "executable": true, "content": "if [ 1 == 1 ]\nthen\necho OK\nfi"}
	files["/tests/logic.txt"] = {"type": "file", "executable": false, "content": "OK"}
	
	files["/tests/nav.sh"] = {"type": "file", "executable": true, "content": "cd /bin\npwd"}
	files["/tests/nav.txt"] = {"type": "file", "executable": false, "content": "/bin"}
	
	files["/tests/quotes.sh"] = {"type": "file", "executable": true, "content": "echo Hello"}
	files["/tests/quotes.txt"] = {"type": "file", "executable": false, "content": "Hello"}
	
	# ===== COMPREHENSIVE TEST SUITE =====
	
	# 1. Variable Expansion Tests
	files["/tests/var_basic.sh"] = {"type": "file", "executable": true, "content": "export NAME=Alice\necho $NAME"}
	files["/tests/var_basic.txt"] = {"type": "file", "executable": false, "content": "Alice"}
	
	files["/tests/var_braces.sh"] = {"type": "file", "executable": true, "content": "export VAR=test\necho ${VAR}"}
	files["/tests/var_braces.txt"] = {"type": "file", "executable": false, "content": "test"}
	
	files["/tests/var_multiple.sh"] = {"type": "file", "executable": true, "content": "export A=foo\nexport B=bar\necho $A $B"}
	files["/tests/var_multiple.txt"] = {"type": "file", "executable": false, "content": "foo bar"}
	
	files["/tests/var_concat.sh"] = {"type": "file", "executable": true, "content": "export PRE=hello\nexport SUF=world\necho $PRE$SUF"}
	files["/tests/var_concat.txt"] = {"type": "file", "executable": false, "content": "helloworld"}
	
	# 2. Command Substitution Tests
	files["/tests/cmdsub_basic.sh"] = {"type": "file", "executable": true, "content": "export RESULT=$(echo test)\necho $RESULT"}
	files["/tests/cmdsub_basic.txt"] = {"type": "file", "executable": false, "content": "test"}
	
	files["/tests/cmdsub_pwd.sh"] = {"type": "file", "executable": true, "content": "cd /bin\nexport LOC=$(pwd)\necho $LOC"}
	files["/tests/cmdsub_pwd.txt"] = {"type": "file", "executable": false, "content": "/bin"}
	
	files["/tests/cmdsub_nested.sh"] = {"type": "file", "executable": true, "content": "export X=$(echo inner)\necho outer-$X"}
	files["/tests/cmdsub_nested.txt"] = {"type": "file", "executable": false, "content": "outer-inner"}
	
	# 3. For Loop Tests
	files["/tests/for_simple.sh"] = {"type": "file", "executable": true, "content": "for x in A B C\ndo\necho $x\ndone"}
	files["/tests/for_simple.txt"] = {"type": "file", "executable": false, "content": "A\nB\nC"}
	
	files["/tests/for_numbers.sh"] = {"type": "file", "executable": true, "content": "for n in 1 2 3 4 5\ndo\necho $n\ndone"}
	files["/tests/for_numbers.txt"] = {"type": "file", "executable": false, "content": "1\n2\n3\n4\n5"}
	
	files["/tests/for_vars.sh"] = {"type": "file", "executable": true, "content": "for item in red blue\ndo\nexport COLOR=$item\necho $COLOR\ndone"}
	files["/tests/for_vars.txt"] = {"type": "file", "executable": false, "content": "red\nblue"}
	
	# 4. If Statement Tests
	files["/tests/if_true.sh"] = {"type": "file", "executable": true, "content": "if [ 1 == 1 ]\nthen\necho YES\nfi"}
	files["/tests/if_true.txt"] = {"type": "file", "executable": false, "content": "YES"}
	
	files["/tests/if_false.sh"] = {"type": "file", "executable": true, "content": "if [ 1 == 2 ]\nthen\necho BAD\nfi"}
	files["/tests/if_false.txt"] = {"type": "file", "executable": false, "content": ""}
	
	files["/tests/if_else.sh"] = {"type": "file", "executable": true, "content": "if [ 1 == 2 ]\nthen\necho BAD\nelse\necho GOOD\nfi"}
	files["/tests/if_else.txt"] = {"type": "file", "executable": false, "content": "GOOD"}
	
	# 5. Nested Control Flow Tests
	files["/tests/nested_if_for.sh"] = {"type": "file", "executable": true, "content": "for x in 1 2\ndo\nif [ $x == 1 ]\nthen\necho first\nelse\necho second\nfi\ndone"}
	files["/tests/nested_if_for.txt"] = {"type": "file", "executable": false, "content": "first\nsecond"}
	
	files["/tests/nested_for_for.sh"] = {"type": "file", "executable": true, "content": "for a in X Y\ndo\nfor b in 1 2\ndo\necho $a$b\ndone\ndone"}
	files["/tests/nested_for_for.txt"] = {"type": "file", "executable": false, "content": "X1\nX2\nY1\nY2"}
	
	# 6. Logical Operators Tests
	files["/tests/and_true.sh"] = {"type": "file", "executable": true, "content": "echo A && echo B"}
	files["/tests/and_true.txt"] = {"type": "file", "executable": false, "content": "A\nB"}
	
	files["/tests/and_false.sh"] = {"type": "file", "executable": true, "content": "export X=$(echo)\necho A && echo B"}
	files["/tests/and_false.txt"] = {"type": "file", "executable": false, "content": "A\nB"}
	
	files["/tests/or_skip.sh"] = {"type": "file", "executable": true, "content": "echo A || echo B"}
	files["/tests/or_skip.txt"] = {"type": "file", "executable": false, "content": "A"}
	
	# 7. File Operations Tests
	files["/tests/cat_test.sh"] = {"type": "file", "executable": true, "content": "echo test"}
	files["/tests/cat_test.txt"] = {"type": "file", "executable": false, "content": "test"}
	
	files["/tests/pwd_test.sh"] = {"type": "file", "executable": true, "content": "cd /tmp\npwd"}
	files["/tests/pwd_test.txt"] = {"type": "file", "executable": false, "content": "/tmp"}
	
	files["/tests/nav_dot.sh"] = {"type": "file", "executable": true, "content": "cd /home/jesse\ncd .\npwd"}
	files["/tests/nav_dot.txt"] = {"type": "file", "executable": false, "content": "/home/jesse"}
	
	files["/tests/nav_dotdot.sh"] = {"type": "file", "executable": true, "content": "cd /home/jesse\ncd ..\npwd"}
	files["/tests/nav_dotdot.txt"] = {"type": "file", "executable": false, "content": "/home"}
	
	files["/tests/nav_double_dotdot.sh"] = {"type": "file", "executable": true, "content": "cd /home/jesse\ncd ../..\npwd"}
	files["/tests/nav_double_dotdot.txt"] = {"type": "file", "executable": false, "content": "/"}
	
	files["/tests/nav_relative.sh"] = {"type": "file", "executable": true, "content": "cd /home\ncd jesse\npwd"}
	files["/tests/nav_relative.txt"] = {"type": "file", "executable": false, "content": "/home/jesse"}
	
	files["/tests/nav_complex.sh"] = {"type": "file", "executable": true, "content": "cd /home/jesse\ncd ../../bin\npwd"}
	files["/tests/nav_complex.txt"] = {"type": "file", "executable": false, "content": "/bin"}
	
	# 8. Glob Expansion Tests
	files["/tests/glob_test.sh"] = {"type": "file", "executable": true, "content": "cd /tests\necho *.txt"}
	files["/tests/glob_test.txt"] = {"type": "file", "executable": false, "content": "and_false.txt and_true.txt cat_test.txt cmdsub_basic.txt cmdsub_nested.txt cmdsub_pwd.txt for_numbers.txt for_simple.txt for_vars.txt glob_test.txt if_dir.txt if_else.txt if_false.txt if_file.txt if_true.txt if_var.txt logic.txt loops.txt nested_for_for.txt nested_if_for.txt or_skip.txt pwd_test.txt quotes.txt var_basic.txt var_braces.txt var_concat.txt var_multiple.txt variables.txt"}
	
	# 9. Quote Handling Tests
	files["/tests/quote_single.sh"] = {"type": "file", "executable": true, "content": "echo 'hello world'"}
	files["/tests/quote_single.txt"] = {"type": "file", "executable": false, "content": "hello world"}
	
	files["/tests/quote_double.sh"] = {"type": "file", "executable": true, "content": "echo \"hello world\""}
	files["/tests/quote_double.txt"] = {"type": "file", "executable": false, "content": "hello world"}
	
	files["/tests/quote_var.sh"] = {"type": "file", "executable": true, "content": "export MSG=test\necho \"$MSG\""}
	files["/tests/quote_var.txt"] = {"type": "file", "executable": false, "content": "test"}
	
	# 10. Complex Integration Tests
	files["/tests/complex_pipeline.sh"] = {"type": "file", "executable": true, "content": "export A=1\nexport B=2\nfor i in $A $B\ndo\nif [ $i == 1 ]\nthen\necho first\nelse\necho second\nfi\ndone"}
	files["/tests/complex_pipeline.txt"] = {"type": "file", "executable": false, "content": "first\nsecond"}
	
	files["/tests/complex_cmdsub.sh"] = {"type": "file", "executable": true, "content": "export RES=$(echo hello)\nif [ $RES == hello ]\nthen\necho SUCCESS\nelse\necho FAIL\nfi"}
	files["/tests/complex_cmdsub.txt"] = {"type": "file", "executable": false, "content": "SUCCESS"}
	
	# 11. Edge Cases
	files["/tests/empty_var.sh"] = {"type": "file", "executable": true, "content": "export EMPTY=\necho start${EMPTY}end"}
	files["/tests/empty_var.txt"] = {"type": "file", "executable": false, "content": "startend"}
	
	files["/tests/multiline_echo.sh"] = {"type": "file", "executable": true, "content": "echo line1\necho line2\necho line3"}
	files["/tests/multiline_echo.txt"] = {"type": "file", "executable": false, "content": "line1\nline2\nline3"}
	
	# Master test runner
	files["/bin/run_all_tests.sh"] = {
		"type": "file",
		"executable": true,
		"content": """echo === COMPREHENSIVE BASH TEST SUITE ===
echo
for TEST_NAME in var_basic var_braces var_multiple var_concat cmdsub_basic cmdsub_pwd cmdsub_nested for_simple for_numbers for_vars if_true if_false if_else if_var if_file if_dir nested_if_for nested_for_for and_true or_skip pwd_test nav_dot nav_dotdot nav_double_dotdot nav_relative nav_complex quote_single quote_double quote_var complex_pipeline complex_cmdsub empty_var multiline_echo variables loops logic nav quotes
do
export ACTUAL=$(sh /tests/$TEST_NAME.sh)
export EXPECTED=$(cat /tests/$TEST_NAME.txt)
if [ $ACTUAL == $EXPECTED ]
then
echo ✓ PASS: $TEST_NAME
else
echo ✗ FAIL: $TEST_NAME
echo    Expected: $EXPECTED
echo    Actual:   $ACTUAL
fi
done
echo
echo === TEST SUITE COMPLETE ==="""}

func create_file(path: String, content: String = "", type: String = "file"):
	var parent = path.get_base_dir()
	if not files.has(parent) and parent != "/":
		pass
	files[path] = {
		"type": type,
		"executable": (type == "dir"),
		"content": content
	}
	
func move_item(from_path: String, to_path: String):
	var is_dir = files[from_path].type == "dir"
	if not is_dir:
		files[to_path] = files[from_path]
		files.erase(from_path)
	else:
		var to_erase = []
		var to_add = {}
		for p in files.keys():
			if p == from_path or p.begins_with(from_path + "/"):
				var new_path = p.replace(from_path, to_path)
				to_add[new_path] = files[p]
				to_erase.append(p)
		for p in to_erase: files.erase(p)
		for p in to_add: files[p] = to_add[p]

func resolve_path(target: String) -> String:
	var path = ""
	if target.begins_with("/"):
		path = target
	else:
		path = current_path + "/" + target
	var parts = path.split("/")
	var resolved = []
	for part in parts:
		if part == "" or part == ".": continue
		elif part == "..":
			if resolved.size() > 0: resolved.pop_back()
		else: resolved.append(part)
	return "/" + "/".join(resolved) if resolved.size() > 0 else "/"
