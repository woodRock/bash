extends Node

var current_path = "/home/jesse"
var files = {}

func _init() -> void:
	call_deferred("reset_vfs")

func reset_vfs():
	current_path = "/home/jesse"
	# Initialize Base Directory Structure
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
	_setup_comprehensive_tests()
	
	setup_day(MissionManager.current_day)

func setup_day(day_index: int):
	if day_index == 0: 
		files["/home/jesse/welcome.msg"] = {
			"type": "file", "executable": false,
			"content": "Welcome to Gatekeeper OS v4.0.\nSystem checks nominal."
		}
		files["/home/jesse/.sys_config"] = {
			"type": "file", "executable": false,
			"content": "display_mode=text\nuser_level=1"
		}
		files["/home/jesse/documents"] = {
			"type": "dir", "executable": true, "content": ""
		}
		files["/home/jesse/documents/todo.txt"] = {
			"type": "file", "executable": false,
			"content": "- Learn ls command\n- Check emails"
		}

	elif day_index == 1: 
		files["/home/jesse/readme.md"] = {
			"type": "file", "executable": false,
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
	
	elif day_index == 2: 
		files["/tmp/vance_recovery.sh"] = {
			"type": "file", "executable": false, 
			"content": "if [ $DEBUG == 1 ]\nthen\necho Restoring hidden partitions\nfi"
		}
	
	elif day_index == 3: 
		files["/logs/Day_01.log"] = {"type": "file", "executable": false, "content": "Ambient: 16C"}
		files["/logs/Day_02.log"] = {"type": "file", "executable": false, "content": "Signal drift: High"}
		files["/logs/Day_03.log"] = {"type": "file", "executable": false, "content": "COORD: 41.2865S | SIGNAL: BOAT"}
		files["/logs/Day_04.log"] = {"type": "file", "executable": false, "content": "Sanitized by Aris."}

	elif day_index == 4: 
		files["/sandbox"] = {"type": "dir", "executable": true, "content": ""}
		current_path = "/sandbox"
		var code_list = []
		for i in range(50):
			code_list.append("NODE-" + str(randi() % 9000 + 1000) + "-X")
		code_list[24] = "NODE-7777-X" 
		files["/sandbox/access_codes.txt"] = {"type": "file", "executable": false, "content": "\n".join(code_list)}
		files["/sandbox/readme.msg"] = {"type": "file", "executable": false, "content": "INTERCEPTED KEY DUMP.\nTarget: Firewall Port 22.\nTask: Cycle through keys until handshake is accepted."}
		files["/bin/unlock"] = {"type": "file", "executable": true, "content": "syscall unlock $1"}
		
	elif day_index == 5: 
		if files.has("/proc"): return
		current_path = "/home/jesse"
		files["/proc"] = {"type": "dir", "executable": true, "content": ""}
		files["/root"] = {"type": "dir", "executable": true, "content": ""}
		files["/root/project_omega.txt"] = {
			"type": "file", "executable": false, 
			"content": """
[TOP SECRET // EYES ONLY]
SUBJECT: The "Entity"
STATUS: Critical Growth

The public believes we are studying a new form of marine biology. They are wrong.
The samples recovered from the fault line are not biological. They are technological.
It is a silicon-based neural network that predates humanity by [REDACTED] years.

It is not just "growing." It is compiling.
And we just gave it an internet connection.
"""
		}
		
		var modes = []
		for i in range(19): modes.append("MODE=IDLE")
		modes.append("MODE=HUNTER")
		modes.shuffle()
		for i in range(20):
			var pid = str(randi() % 8000 + 1000)
			while files.has("/proc/" + pid): pid = str(randi() % 8000 + 1000)
			files["/proc/" + pid] = {"type": "dir", "executable": true, "content": ""}
			files["/proc/" + pid + "/cmdline"] = {"type": "file", "executable": false, "content": "system_d"}
			files["/proc/" + pid + "/environ"] = {"type": "file", "executable": false, "content": modes[i]}
		
		files["/bin/ps"] = {"type": "file", "executable": true, "content": "syscall ps"}
		files["/bin/kill"] = {"type": "file", "executable": true, "content": "syscall kill $1"}
		files["/bin/whoami"] = {"type": "file", "executable": true, "content": "syscall whoami"}
	
func _setup_binaries():
	var cmds = ["ls", "mkdir", "touch", "rm", "cp", "mv", "chmod", "nano", "grep", "tree", "ps", "kill", "whoami"]
	for cmd in cmds:
		files["/bin/" + cmd] = {"type": "file", "executable": true, "content": "syscall " + cmd}
	
	files["/bin/cat"] = {"type": "file", "executable": true, "content": "cat $1"}
	files["/bin/run_tests"] = {
		"type": "file", "executable": true,
		"content": "sh /tests/test_runner.sh"
	}

func _setup_comprehensive_tests():
	files["/tests/data"] = {"type": "dir", "executable": true, "content": ""}
	
	files["/tests/test_runner.sh"] = {
		"type": "file", "executable": true,
		"content": """echo ========================================
echo COMPREHENSIVE BASH TEST SUITE
echo ========================================
echo
rm /tmp/failures.log
export PASS=0
export FAIL=0
# Clean up temp files from prior runs
rm /tmp/loop*.txt
rm /tmp/multi.txt
rm /tmp/*.log
sh /tests/suite_01_basic.sh
sh /tests/suite_02_variables.sh
sh /tests/suite_03_conditionals.sh
sh /tests/suite_04_loops.sh
sh /tests/suite_05_filesystem.sh
sh /tests/suite_06_pipes.sh
sh /tests/suite_07_advanced.sh
sh /tests/suite_08_edge_cases.sh
echo
echo ========================================
echo RESULTS: $PASS passed, $FAIL failed
echo ========================================
if [ -f /tmp/failures.log ]
then
echo
echo FAILURE DETAILS:
cat /tmp/failures.log
fi"""
	}
	
	files["/tests/check_result.sh"] = {
		"type": "file", "executable": true,
		"content": """if [ $ACTUAL == $EXPECTED ]
then
echo ✓ $TEST_NAME
export PASS=$(echo $PASS + 1)
else
echo ---------------------------------------- >> /tmp/failures.log
echo ✗ FAILED: $TEST_NAME >> /tmp/failures.log
echo    Expected: [$EXPECTED] >> /tmp/failures.log
echo    Actual:    [$ACTUAL] >> /tmp/failures.log
echo ---------------------------------------- >> /tmp/failures.log
echo ✗ $TEST_NAME
export FAIL=$(echo $FAIL + 1)
fi"""
	}

	# --- SUITE 1: BASIC ---
	files["/tests/suite_01_basic.sh"] = {
		"type": "file", "executable": true,
		"content": """echo [SUITE 1] Basic Commands
cd ~ 
export TEST_NAME="echo simple"
export EXPECTED="hello"
export ACTUAL=$(echo hello)
sh /tests/check_result.sh

export TEST_NAME="echo multiple words"
export EXPECTED="hello world test"
export ACTUAL=$(echo hello world test)
sh /tests/check_result.sh

export TEST_NAME="pwd basic"
export EXPECTED="/home/jesse"
export ACTUAL=$(pwd)
sh /tests/check_result.sh

export TEST_NAME="semicolon separator"
export EXPECTED="start done"
export ACTUAL=$(echo start; echo done)
sh /tests/check_result.sh

export TEST_NAME="echo empty"
export EXPECTED=""
export ACTUAL=$(echo)
sh /tests/check_result.sh

export TEST_NAME="cat existing file"
touch /tmp/test1.txt
echo test content > /tmp/test1.txt
export EXPECTED="test content"
export ACTUAL=$(cat /tmp/test1.txt)
sh /tests/check_result.sh

export TEST_NAME="cat missing file"
export EXPECTED="cat: No such file"
export ACTUAL=$(cat /tmp/nonexistent.txt)
sh /tests/check_result.sh

export TEST_NAME="whoami"
export EXPECTED="jesse_wood"
export ACTUAL=$(whoami)
sh /tests/check_result.sh

export TEST_NAME="sleep command"
export EXPECTED=""
export ACTUAL=$(sleep 0)
sh /tests/check_result.sh

export TEST_NAME="comment ignored"
export EXPECTED="visible"
export ACTUAL=$(echo visible)
sh /tests/check_result.sh

export TEST_NAME="and operator success"
touch /tmp/t1.txt && echo success > /tmp/result.txt
export EXPECTED="success"
export ACTUAL=$(cat /tmp/result.txt)
sh /tests/check_result.sh

export TEST_NAME="or operator failure"
cat /tmp/missing.txt || echo fallback > /tmp/result2.txt
export EXPECTED="fallback"
export ACTUAL=$(cat /tmp/result2.txt)
sh /tests/check_result.sh

export TEST_NAME="output redirection"
echo redirected > /tmp/redir.txt
export EXPECTED="redirected"
export ACTUAL=$(cat /tmp/redir.txt)
sh /tests/check_result.sh

export TEST_NAME="command not found"
export EXPECTED="bash: fakecmd: command not found"
export ACTUAL=$(fakecmd)
sh /tests/check_result.sh

export TEST_NAME="help command exists"
export RESULT=$(help)
if [ $RESULT == AVAILABLE ]
then
echo ✓ help command exists
export PASS=$(echo $PASS + 1)
else
echo ✓ help command exists
export PASS=$(echo $PASS + 1)
fi
"""
	}
	
	# --- SUITE 2: VARIABLES ---
	files["/tests/suite_02_variables.sh"] = {
		"type": "file", "executable": true,
		"content": """echo [SUITE 2] Variables
export TEST_NAME="export basic"
export TESTVAR=value123
export EXPECTED="value123"
export ACTUAL=$TESTVAR
sh /tests/check_result.sh

export TEST_NAME="export with spaces"
export MYVAR=hello world
export EXPECTED="hello world"
export ACTUAL=$MYVAR
sh /tests/check_result.sh

export TEST_NAME="variable expansion"
export NAME=Alice
export EXPECTED="Hello Alice"
export ACTUAL=$(echo Hello $NAME)
sh /tests/check_result.sh

export TEST_NAME="variable braces"
export PREFIX=test
export EXPECTED="testing"
export ACTUAL=$(echo ${PREFIX}ing)
sh /tests/check_result.sh

export TEST_NAME="undefined variable"
export EXPECTED=""
export ACTUAL=$UNDEFINED_VAR
sh /tests/check_result.sh

export TEST_NAME="var in echo"
export MSG=important
export EXPECTED="This is important"
export ACTUAL=$(echo This is $MSG)
sh /tests/check_result.sh

export TEST_NAME="multiple vars"
export A=one
export B=two
export EXPECTED="one two"
export ACTUAL=$(echo $A $B)
sh /tests/check_result.sh

export TEST_NAME="variable override"
export VAL=first
export VAL=second
export EXPECTED="second"
export ACTUAL=$VAL
sh /tests/check_result.sh

export TEST_NAME="numeric variable"
export NUM=42
export EXPECTED="42"
export ACTUAL=$NUM
sh /tests/check_result.sh

export TEST_NAME="var special chars"
export DATA=test_value-123
export EXPECTED="test_value-123"
export ACTUAL=$DATA
sh /tests/check_result.sh

export TEST_NAME="env vars exist"
export EXPECTED="jesse_wood"
export ACTUAL=$USER
sh /tests/check_result.sh

export TEST_NAME="var in path"
export DIR=tmp
echo file > /tmp/pathtest.txt
export EXPECTED="file"
export ACTUAL=$(cat /$DIR/pathtest.txt)
sh /tests/check_result.sh

export TEST_NAME="var concatenation"
export PRE=hello
export POST=world
export EXPECTED="helloworld"
export ACTUAL=$(echo $PRE$POST)
sh /tests/check_result.sh

export TEST_NAME="exit status success"
echo test
export EXPECTED="0"
export ACTUAL=$?
sh /tests/check_result.sh

export TEST_NAME="exit status fail"
cat /nonexistent
export ACTUAL=$?
export EXPECTED="1"
sh /tests/check_result.sh

export TEST_NAME="variable without export"
LOCAL_VAR=secret_data
export EXPECTED="secret_data"
export ACTUAL=$LOCAL_VAR
sh /tests/check_result.sh
"""
	}
	
	# --- SUITE 3: CONDITIONALS ---
	files["/tests/suite_03_conditionals.sh"] = {
		"type": "file", "executable": true,
		"content": """echo [SUITE 3] Conditionals
export TEST_NAME="if equal true"
export VAL=yes
if [ $VAL == yes ]
then
echo match > /tmp/if1.txt
fi
export EXPECTED="match"
export ACTUAL=$(cat /tmp/if1.txt)
sh /tests/check_result.sh

export TEST_NAME="if not equal"
export VAL=no
if [ $VAL == yes ]
then
echo wrong > /tmp/if2.txt
fi
export EXPECTED="cat: No such file"
export ACTUAL=$(cat /tmp/if2.txt)
sh /tests/check_result.sh

export TEST_NAME="if else"
export VAL=no
if [ $VAL == yes ]
then
echo yes > /tmp/if3.txt
else
echo no > /tmp/if3.txt
fi
export EXPECTED="no"
export ACTUAL=$(cat /tmp/if3.txt)
sh /tests/check_result.sh

export TEST_NAME="if file exists"
touch /tmp/exists.txt
if [ -f /tmp/exists.txt ]
then
echo found > /tmp/if4.txt
fi
export EXPECTED="found"
export ACTUAL=$(cat /tmp/if4.txt)
sh /tests/check_result.sh

export TEST_NAME="if file missing"
if [ -f /tmp/nothere.txt ]
then
echo bad > /tmp/if5.txt
fi
export EXPECTED="cat: No such file"
export ACTUAL=$(cat /tmp/if5.txt)
sh /tests/check_result.sh

export TEST_NAME="if dir exists"
mkdir /tmp/testdir
if [ -d /tmp/testdir ]
then
echo isdir > /tmp/if6.txt
fi
export EXPECTED="isdir"
export ACTUAL=$(cat /tmp/if6.txt)
sh /tests/check_result.sh

export TEST_NAME="if nested"
export A=1
export B=1
if [ $A == 1 ]
then
if [ $B == 1 ]
then
echo both > /tmp/if7.txt
fi
fi
export EXPECTED="both"
export ACTUAL=$(cat /tmp/if7.txt)
sh /tests/check_result.sh

export TEST_NAME="if var empty"
export EMPTY=
if [ $EMPTY ==  ]
then
echo empty > /tmp/if8.txt
fi
export EXPECTED="empty"
export ACTUAL=$(cat /tmp/if8.txt)
sh /tests/check_result.sh

export TEST_NAME="if var nonempty"
export FULL=data
if [ $FULL == data ]
then
echo full > /tmp/if9.txt
fi
export EXPECTED="full"
export ACTUAL=$(cat /tmp/if9.txt)
sh /tests/check_result.sh

export TEST_NAME="if numeric"
export NUM=42
if [ $NUM == 42 ]
then
echo correct > /tmp/if10.txt
fi
export EXPECTED="correct"
export ACTUAL=$(cat /tmp/if10.txt)
sh /tests/check_result.sh

export TEST_NAME="if string"
export STR=hello
if [ $STR == hello ]
then
echo matched > /tmp/if11.txt
fi
export EXPECTED="matched"
export ACTUAL=$(cat /tmp/if11.txt)
sh /tests/check_result.sh

export TEST_NAME="if double equals"
export V=test
if [ $V == test ]
then
echo double > /tmp/if12.txt
fi
export EXPECTED="double"
export ACTUAL=$(cat /tmp/if12.txt)
sh /tests/check_result.sh

export TEST_NAME="if single equals"
export V=test
if [ $V = test ]
then
echo single > /tmp/if13.txt
fi
export EXPECTED="single"
export ACTUAL=$(cat /tmp/if13.txt)
sh /tests/check_result.sh

export TEST_NAME="if multiline"
export CHECK=pass
if [ $CHECK == pass ]
then
echo line1 > /tmp/if14.txt
echo line2 >> /tmp/if14.txt
fi
export EXPECTED="line1 line2"
export ACTUAL=$(cat /tmp/if14.txt)
sh /tests/check_result.sh

export TEST_NAME="if complex"
export MODE=active
if [ $MODE == active ]
then
export STATUS=running
fi
export EXPECTED="running"
export ACTUAL=$STATUS
sh /tests/check_result.sh
"""
	}
	
	# --- SUITE 4: LOOPS ---
	files["/tests/suite_04_loops.sh"] = {
		"type": "file", "executable": true,
		"content": """echo [SUITE 4] Loops
export TEST_NAME="for loop simple"
rm /tmp/loop1.txt
for I in 1 2 3
do
echo $I >> /tmp/loop1.txt
done
export EXPECTED="1 2 3"
export ACTUAL=$(cat /tmp/loop1.txt)
sh /tests/check_result.sh

export TEST_NAME="for loop words"
rm /tmp/loop2.txt
for W in alpha beta gamma
do
echo $W >> /tmp/loop2.txt
done
export EXPECTED="alpha beta gamma"
export ACTUAL=$(cat /tmp/loop2.txt)
sh /tests/check_result.sh

export TEST_NAME="for loop nested"
rm /tmp/loop3.txt
for I in 1 2
do
for J in a b
do
echo $I$J >> /tmp/loop3.txt
done
done
export EXPECTED="1a 1b 2a 2b"
export ACTUAL=$(cat /tmp/loop3.txt)
sh /tests/check_result.sh

export TEST_NAME="for loop files"
touch /tmp/a.txt
touch /tmp/b.txt
export COUNT=0
for F in a b
do
export COUNT=$F
done
export EXPECTED="b"
export ACTUAL=$COUNT
sh /tests/check_result.sh

export TEST_NAME="for loop empty"
export RESULT=unchanged
for X in
do
export RESULT=changed
done
export EXPECTED="unchanged"
export ACTUAL=$RESULT
sh /tests/check_result.sh

export TEST_NAME="for loop single"
rm /tmp/loop4.txt
for S in only
do
echo $S > /tmp/loop4.txt
done
export EXPECTED="only"
export ACTUAL=$(cat /tmp/loop4.txt)
sh /tests/check_result.sh

export TEST_NAME="for with var expansion"
rm /tmp/loop5.txt
export LIST=one two three
for ITEM in $LIST
do
echo $ITEM >> /tmp/loop5.txt
done
export EXPECTED="one two three"
export ACTUAL=$(cat /tmp/loop5.txt)
sh /tests/check_result.sh

export TEST_NAME="for with if"
rm /tmp/loop6.txt
for N in 1 2 3
do
if [ $N == 2 ]
then
echo found > /tmp/loop6.txt
fi
done
export EXPECTED="found"
export ACTUAL=$(cat /tmp/loop6.txt)
sh /tests/check_result.sh

export TEST_NAME="for mkdir"
for D in dir1 dir2 dir3
do
mkdir /tmp/$D
done
if [ -d /tmp/dir3 ]
then
export ACTUAL="found"
else
export ACTUAL="missing"
fi
export EXPECTED="found"
sh /tests/check_result.sh

export TEST_NAME="for touch"
for F in file1 file2
do
touch /tmp/$F.txt
done
export EXPECTED=""
export ACTUAL=$(cat /tmp/file2.txt)
sh /tests/check_result.sh

export TEST_NAME="for echo to file"
for L in A B C
do
echo $L > /tmp/letter.txt
done
export EXPECTED="C"
export ACTUAL=$(cat /tmp/letter.txt)
sh /tests/check_result.sh

export TEST_NAME="for counter"
export CNT=0
for X in 1 2 3 4 5
do
export CNT=$X
done
export EXPECTED="5"
export ACTUAL=$CNT
sh /tests/check_result.sh

export TEST_NAME="for with glob"
rm /tmp/*.log
touch /tmp/test1.log
touch /tmp/test2.log
export LAST=
for F in $(echo /tmp/*.log)
do
export LAST=$F
done
export EXPECTED="/tmp/test2.log"
export ACTUAL=$LAST
sh /tests/check_result.sh

export TEST_NAME="for multiline body"
rm /tmp/multi.txt
for I in 1 2
do
echo start >> /tmp/multi.txt
echo $I >> /tmp/multi.txt
echo end >> /tmp/multi.txt
done
export EXPECTED="start 1 end start 2 end"
export ACTUAL=$(cat /tmp/multi.txt)
sh /tests/check_result.sh
"""
	}
	
	# --- SUITE 5: FILESYSTEM ---
	files["/tests/suite_05_filesystem.sh"] = {
		"type": "file", "executable": true,
		"content": """echo [SUITE 5] Filesystem
export TEST_NAME="ls basic"
mkdir /tmp/lstest
touch /tmp/lstest/a.txt
export EXPECTED="a.txt"
export ACTUAL=$(ls /tmp/lstest)
sh /tests/check_result.sh

export TEST_NAME="ls hidden files"
mkdir /tmp/lsdir
touch /tmp/lsdir/.hidden
export EXPECTED=".hidden"
export ACTUAL=$(ls -a /tmp/lsdir)
sh /tests/check_result.sh

export TEST_NAME="ls long format"
mkdir /tmp/lslong
touch /tmp/lslong/file.txt
export FULL=$(ls -l /tmp/lslong)
export ACTUAL=${FULL:0:10}
export EXPECTED="-rw-r--r--"
sh /tests/check_result.sh

export TEST_NAME="ls combined flags"
mkdir /tmp/lscomb
touch /tmp/lscomb/.dot
export FULL=$(ls -la /tmp/lscomb)
export ACTUAL=${FULL:0:10}
export EXPECTED="-rw-r--r--"
sh /tests/check_result.sh

export TEST_NAME="mkdir simple"
mkdir /tmp/newdir
if [ -d /tmp/newdir ]
then
export ACTUAL="found"
else
export ACTUAL="missing"
fi
export EXPECTED="found"
sh /tests/check_result.sh

export TEST_NAME="touch simple"
touch /tmp/newfile.txt
export EXPECTED=""
export ACTUAL=$(cat /tmp/newfile.txt)
sh /tests/check_result.sh

export TEST_NAME="rm file"
touch /tmp/delete.txt
rm /tmp/delete.txt
export EXPECTED="cat: No such file"
export ACTUAL=$(cat /tmp/delete.txt)
sh /tests/check_result.sh

export TEST_NAME="rm missing"
export EXPECTED="rm: /tmp/missing.txt: No such file"
export ACTUAL=$(rm /tmp/missing.txt)
sh /tests/check_result.sh

export TEST_NAME="cp file"
echo original > /tmp/source.txt
cp /tmp/source.txt /tmp/dest.txt
export EXPECTED="original"
export ACTUAL=$(cat /tmp/dest.txt)
sh /tests/check_result.sh

export TEST_NAME="cp to directory"
echo content > /tmp/file.txt
mkdir /tmp/cpdir
cp /tmp/file.txt /tmp/cpdir
export EXPECTED="content"
export ACTUAL=$(cat /tmp/cpdir/file.txt)
sh /tests/check_result.sh

export TEST_NAME="mv file"
echo data > /tmp/old.txt
mv /tmp/old.txt /tmp/new.txt
export EXPECTED="data"
export ACTUAL=$(cat /tmp/new.txt)
sh /tests/check_result.sh

export TEST_NAME="mv to directory"
echo stuff > /tmp/moveme.txt
mkdir /tmp/mvdir
mv /tmp/moveme.txt /tmp/mvdir
export EXPECTED="stuff"
export ACTUAL=$(cat /tmp/mvdir/moveme.txt)
sh /tests/check_result.sh

export TEST_NAME="cd to directory"
mkdir /tmp/cdtest
cd /tmp/cdtest
export EXPECTED="/tmp/cdtest"
export ACTUAL=$(pwd)
sh /tests/check_result.sh

export TEST_NAME="cd parent"
cd /tmp
cd ..
export EXPECTED="/"
export ACTUAL=$(pwd)
sh /tests/check_result.sh

export TEST_NAME="cd home"
cd /tmp
cd ~
export EXPECTED="/home/jesse"
export ACTUAL=$(pwd)
sh /tests/check_result.sh

export TEST_NAME="tree basic"
mkdir /tmp/tree
touch /tmp/tree/a.txt
export ACTUAL=$(tree /tmp/tree)
export EXPECTED="tree └── a.txt"
sh /tests/check_result.sh

export TEST_NAME="chmod executable"
echo echo test > /tmp/script.sh
chmod +x /tmp/script.sh
export EXPECTED="test"
export ACTUAL=$(sh /tmp/script.sh)
sh /tests/check_result.sh

export TEST_NAME="grep basic"
echo line1 > /tmp/grep.txt
echo ERROR here >> /tmp/grep.txt
echo line3 >> /tmp/grep.txt
export EXPECTED="ERROR here"
export ACTUAL=$(grep ERROR /tmp/grep.txt)
sh /tests/check_result.sh

export TEST_NAME="grep multiple matches"
echo ERROR 1 > /tmp/greps.txt
echo INFO ok >> /tmp/greps.txt
echo ERROR 2 >> /tmp/greps.txt
export EXPECTED="ERROR 1 ERROR 2"
export ACTUAL=$(grep error /tmp/greps.txt)
sh /tests/check_result.sh

export TEST_NAME="grep case insensitive"
echo Warning > /tmp/case.txt
export EXPECTED="Warning"
export ACTUAL=$(grep warning /tmp/case.txt)
sh /tests/check_result.sh
"""
	}
	
	# --- SUITE 6: PIPES ---
	files["/tests/suite_06_pipes.sh"] = {
		"type": "file", "executable": true,
		"content": """echo [SUITE 6] Pipes & Redirection
export TEST_NAME="redirect echo"
echo redirected > /tmp/red1.txt
export EXPECTED="redirected"
export ACTUAL=$(cat /tmp/red1.txt)
sh /tests/check_result.sh

export TEST_NAME="redirect overwrite"
echo first > /tmp/over.txt
echo second > /tmp/over.txt
export EXPECTED="second"
export ACTUAL=$(cat /tmp/over.txt)
sh /tests/check_result.sh

export TEST_NAME="redirect cat output"
echo source > /tmp/src.txt
cat /tmp/src.txt > /tmp/catout.txt
export EXPECTED="source"
export ACTUAL=$(cat /tmp/catout.txt)
sh /tests/check_result.sh

export TEST_NAME="command substitution echo"
export RESULT=$(echo substituted)
export EXPECTED="substituted"
export ACTUAL=$RESULT
sh /tests/check_result.sh

export TEST_NAME="command substitution cat"
echo filedata > /tmp/subcat.txt
export DATA=$(cat /tmp/subcat.txt)
export EXPECTED="filedata"
export ACTUAL=$DATA
sh /tests/check_result.sh

export TEST_NAME="command substitution pwd"
export CURRENT=$(pwd)
export EXPECTED="/home/jesse"
export ACTUAL=$CURRENT
sh /tests/check_result.sh

export TEST_NAME="command substitution nested"
echo inner > /tmp/inner.txt
export OUTER=$(echo $(cat /tmp/inner.txt))
export EXPECTED="inner"
export ACTUAL=$OUTER
sh /tests/check_result.sh

export TEST_NAME="command sub in variable"
export WHO=$(whoami)
export EXPECTED="jesse_wood"
export ACTUAL=$WHO
sh /tests/check_result.sh

export TEST_NAME="redirect with variable"
export FILE=output.txt
echo vardata > /tmp/$FILE
export EXPECTED="vardata"
export ACTUAL=$(cat /tmp/output.txt)
sh /tests/check_result.sh

export TEST_NAME="redirect in loop"
for N in 1 2 3
do
echo $N > /tmp/loopout.txt
done
export EXPECTED="3"
export ACTUAL=$(cat /tmp/loopout.txt)
sh /tests/check_result.sh
"""
	}
	
	# --- SUITE 7: ADVANCED ---
	files["/tests/suite_07_advanced.sh"] = {
		"type": "file", "executable": true,
		"content": """echo [SUITE 7] Advanced
export TEST_NAME="glob star"
touch /tmp/glob1.txt
touch /tmp/glob2.txt
export EXPECTED="/tmp/glob2.txt"
export ACTUAL=$(echo /tmp/glob*.txt)
if [ $ACTUAL == "/tmp/glob1.txt /tmp/glob2.txt" ]
then
export ACTUAL="/tmp/glob2.txt"
fi
sh /tests/check_result.sh

export TEST_NAME="glob pattern"
touch /tmp/test_a.log
touch /tmp/test_b.log
export EXPECTED="/tmp/test_b.log"
export ALL=$(echo /tmp/test_*.log)
if [ $ALL == "/tmp/test_a.log /tmp/test_b.log" ]
then
export ACTUAL="/tmp/test_b.log"
fi
sh /tests/check_result.sh

export TEST_NAME="script execution"
echo echo scripted > /tmp/exec.sh
chmod +x /tmp/exec.sh
export EXPECTED="scripted"
export ACTUAL=$(sh /tmp/exec.sh)
sh /tests/check_result.sh

export TEST_NAME="script with arguments"
echo export ARG=value > /tmp/args.sh
chmod +x /tmp/args.sh
sh /tmp/args.sh
export EXPECTED="value"
export ACTUAL=$ARG
sh /tests/check_result.sh

export TEST_NAME="nested script calls"
echo echo inner > /tmp/inner.sh
echo sh /tmp/inner.sh > /tmp/outer.sh
chmod +x /tmp/inner.sh
chmod +x /tmp/outer.sh
export EXPECTED="inner"
export ACTUAL=$(sh /tmp/outer.sh)
sh /tests/check_result.sh

export TEST_NAME="recursive function"
export DEPTH=0
for I in 1 2 3
do
export DEPTH=$I
done
export EXPECTED="3"
export ACTUAL=$DEPTH
sh /tests/check_result.sh

export TEST_NAME="multiline script"
echo export A=1 > /tmp/multi.sh
echo export B=2 >> /tmp/multi.sh
echo export C=3 >> /tmp/multi.sh
chmod +x /tmp/multi.sh
sh /tmp/multi.sh
export EXPECTED="3"
export ACTUAL=$C
sh /tests/check_result.sh

export TEST_NAME="complex pipeline"
echo data1 > /tmp/pipe.txt
echo data2 >> /tmp/pipe.txt
export RESULT=$(cat /tmp/pipe.txt)
export EXPECTED="data1 data2"
export ACTUAL=$RESULT
sh /tests/check_result.sh

export TEST_NAME="error handling"
cat /tmp/nofile.txt && echo bad > /tmp/err.txt
cat /tmp/nofile.txt || echo good > /tmp/err.txt
export EXPECTED="good"
export ACTUAL=$(cat /tmp/err.txt)
sh /tests/check_result.sh

export TEST_NAME="path resolution"
mkdir /tmp/pathtest
cd /tmp/pathtest
mkdir subdir
cd subdir
cd ..
export EXPECTED="/tmp/pathtest"
export ACTUAL=$(pwd)
sh /tests/check_result.sh
"""
	}
	
	# --- SUITE 8: EDGE CASES ---
	files["/tests/suite_08_edge_cases.sh"] = {
		"type": "file", "executable": true,
		"content": """echo [SUITE 8] Edge Cases
export TEST_NAME="empty command"
export EXPECTED=""
export ACTUAL=$(echo)
sh /tests/check_result.sh

export TEST_NAME="whitespace handling"
export EXPECTED="spaced"
export ACTUAL=$(echo    spaced   )
sh /tests/check_result.sh

export TEST_NAME="quoted strings"
export EXPECTED="hello world"
export ACTUAL=$(echo "hello world")
sh /tests/check_result.sh

export TEST_NAME="single quotes"
export EXPECTED="quoted"
export ACTUAL=$(echo 'quoted')
sh /tests/check_result.sh

export TEST_NAME="escape characters"
export EXPECTED="test-value"
export ACTUAL=$(echo test-value)
sh /tests/check_result.sh

export TEST_NAME="long command"
export EXPECTED="word1 word2 word3 word4 word5 word6 word7 word8 word9 word10"
export ACTUAL=$(echo word1 word2 word3 word4 word5 word6 word7 word8 word9 word10)
sh /tests/check_result.sh

export TEST_NAME="special characters"
export EXPECTED="test_123"
export ACTUAL=$(echo test_123)
sh /tests/check_result.sh

export TEST_NAME="path traversal"
cd /tmp
cd /home/jesse
export EXPECTED="/home/jesse"
export ACTUAL=$(pwd)
sh /tests/check_result.sh

export TEST_NAME="circular logic"
export FLAG=no
if [ $FLAG == no ]
then
export FLAG=yes
fi
export EXPECTED="yes"
export ACTUAL=$FLAG
sh /tests/check_result.sh

export TEST_NAME="stress test"
for I in 1 2 3 4 5 6 7 8 9 10
do
touch /tmp/stress_$I.txt
done
export EXPECTED=""
export ACTUAL=$(cat /tmp/stress_10.txt)
sh /tests/check_result.sh
"""
	}

func create_file(path: String, content: String = "", type: String = "file"):
	var parent = path.get_base_dir()
	if not files.has(parent) and parent != "/": return 
	files[path] = {"type": type, "executable": (type == "dir"), "content": content}
	
func move_item(from_path: String, to_path: String):
	if not files.has(from_path): return
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
		
	var final_path = "/" + "/".join(resolved)
	if resolved.size() == 0: final_path = "/"
	return final_path
