extends LineEdit

# --- SIGNALS ---
signal command_executed(command_text, response_text)
signal reboot_requested
signal editor_requested(path)

# --- NODES ---
var output_log: RichTextLabel
var scroll_v: ScrollContainer
var VFS: Node
@onready var VFS_scene: PackedScene = preload("res://core/virtual_file_system.tscn")

# --- KERNEL STATE ---
var focus_loop_enabled = false
var cmd_history = []
var history_index = -1
var env_vars = {
	"USER": "jesse_wood",
	"HOME": "/home/jesse",
	"PWD": "/home/jesse",
	"PATH": "/bin",
	"PROMPT": "[color=#00FF41]user@gatekeeper[/color]",
	"?": "0"
}

var block_buffer = []
var nesting_depth = 0
var recursion_depth = 0
const MAX_RECURSION_DEPTH = 1000 

# --- MANUAL PAGES ---
var manual_pages = {
	"ls": "Usage: ls [flags] [directory]\nLists directory contents.\nFlags:\n  -a  Show hidden files\n  -l  Show detailed info\n  (Flags can be combined, e.g., -la)",
	"cd": "Usage: cd [path]\nChanges the current working directory.\nUse 'cd ..' to go up one level.\nUse 'cd ~' to go home.",
	"cat": "Usage: cat [file]\nReads a file and prints its content to the screen.",
	"grep": "Usage: grep [pattern] [file]\nSearch for a text pattern within a file.\nExample: grep 'password' server.log",
	"touch": "Usage: touch [file]\nCreates an empty file.",
	"mkdir": "Usage: mkdir [directory]\nCreates a new directory.",
	"mv": "Usage: mv [source] [destination]\nMoves or renames files.",
	"cp": "Usage: cp [source] [destination]\nCopies a file.",
	"rm": "Usage: rm [flags] [file]...\nDeletes files or directories.\nFlags:\n  -r  Recursive\n  -f  Force",
	"chmod": "Usage: chmod +x [file]\nMakes a script executable.",
	"nano": "Usage: nano [file]\nOpens the text editor.\nCtrl+O to Save, Ctrl+X to Exit.",
	"export": "Usage: export VAR=VALUE\nSets an environment variable.",
	"reboot": "Usage: reboot\nRestarts the kernel. Required to apply system updates.",
	"for": "Usage: for VAR in ITEM1 ITEM2; do ...; done\nLoops through a list of items.\nExample: for i in 1 2 3; do echo $i; done",
	"tree": "Usage: tree [directory]\nDisplays a recursive visual directory structure.",
	"ps": "Usage: ps\nSnapshot of current processes.",
	"kill": "Usage: kill [pid]\nTerminates the process with the given PID.",
	"sleep": "Usage: sleep [seconds]\nPauses execution for the specified time.",
	"whoami": "Usage: whoami\nPrint the current user name.",
	"exit": "Usage: exit\nCloses the terminal session.",
	"man": "Usage: man [command]\nDisplays the manual entry for a command.",
	"sh": "Usage: sh [file]\nExecutes a shell script."
}

func _ready() -> void:
	VFS = VFS_scene.instantiate()
	get_tree().root.add_child.call_deferred(VFS)
	VFS.current_path = env_vars["PWD"]
	
	MissionManager.terminal = self
	MissionManager.vfs_node = VFS
	
	_setup_node_references()
	
	text_submitted.connect(_on_command_submitted)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
	_apply_font_size(GlobalSettings.font_size)
	GlobalSettings.setting_changed.connect(func(k, v): if k == "font_size": _apply_font_size(v))
	
	focus_loop_enabled = true
	await _run_atomic_command("sh /.bashrc", true)
	grab_focus()

func _setup_node_references():
	output_log = get_tree().current_scene.find_child("RichTextLabel", true, false)
	if output_log:
		output_log.selection_enabled = true
		output_log.context_menu_enabled = false
		var parent = output_log.get_parent()
		if parent is ScrollContainer:
			scroll_v = parent

func _resolve(raw_path: String) -> String:
	var expanded = raw_path
	var home = env_vars.get("HOME", "/home/jesse")
	if expanded == "~": expanded = home
	elif expanded.begins_with("~/"): expanded = home + expanded.trim_prefix("~")
	return VFS.resolve_path(expanded)

func _on_command_submitted(new_text: String) -> void:
	var line = new_text.strip_edges()
	if line == "": return
	
	if nesting_depth == 0:
		cmd_history.append(line)
		history_index = -1
		append_to_log(env_vars["PROMPT"] + ":" + VFS.current_path + "$ " + line)
	else:
		append_to_log("> " + line)
		
	var result = await process_input_line(line)
	
	MissionManager.check_mission_progress(MissionManager.TaskType.COMMAND, line, result)
	MissionManager.check_mission_progress(MissionManager.TaskType.VFS_STATE, line)
	MissionManager.check_mission_progress(MissionManager.TaskType.OUTPUT, result)
	
	command_executed.emit(line, result)
	text = ""; grab_focus()

func _split_into_segments(line: String) -> Array:
	var segments = []
	var operators = []
	var current_token = ""
	var i = 0
	var len_line = line.length()
	var paren_depth = 0
	var in_quote = false
	var quote_char = ""
	
	while i < len_line:
		var c = line[i]
		var next_c = line[i+1] if i + 1 < len_line else ""
		
		if (c == '"' or c == "'") and not in_quote:
			in_quote = true; quote_char = c; current_token += c
		elif c == quote_char and in_quote:
			in_quote = false; current_token += c
		elif c == '(':
			paren_depth += 1; current_token += c
		elif c == ')':
			paren_depth = max(0, paren_depth - 1); current_token += c
		elif not in_quote and paren_depth == 0:
			if c == ';':
				segments.append(current_token.strip_edges()); operators.append(";"); current_token = ""
			elif c == '&' and next_c == '&':
				segments.append(current_token.strip_edges()); operators.append("&&"); current_token = ""; i += 1
			elif c == '|' and next_c == '|':
				segments.append(current_token.strip_edges()); operators.append("||"); current_token = ""; i += 1
			else: current_token += c
		else: current_token += c
		i += 1
		
	segments.append(current_token.strip_edges())
	return [segments, operators]

func process_input_line(line: String, is_silent: bool = false) -> String:
	var clean_line = line.strip_edges()
	if clean_line == "" or clean_line.begins_with("#"): return ""

	var parsed = _split_into_segments(clean_line)
	var segments = parsed[0]
	var operators = parsed[1]

	var all_results = []
	
	for i in range(segments.size()):
		var cmd_segment = segments[i]
		if cmd_segment == "": continue
		
		if i > 0:
			var op = operators[i-1]
			if op == "&&" and env_vars["?"] != "0": continue
			if op == "||" and env_vars["?"] == "0": continue
			
		var result = await _run_atomic_command(cmd_segment, is_silent)
		if result != "": all_results.append(result)
		
	return " ".join(all_results) if all_results.size() > 0 else ""

func _run_atomic_command(cmd_text: String, is_silent: bool) -> String:
	var clean_cmd = cmd_text.strip_edges()
	if clean_cmd == "": return ""
	
	if recursion_depth > 0 and recursion_depth % 10 == 0:
		await get_tree().process_frame
	
	recursion_depth += 1
	if recursion_depth > MAX_RECURSION_DEPTH:
		recursion_depth -= 1
		return "bash: maximum recursion depth exceeded"
	
	var words = clean_cmd.split(" ", false) 
	if words.is_empty(): 
		recursion_depth -= 1; return ""
		
	var is_start = (words[0] == "if" or words[0] == "for")
	var is_end = (clean_cmd == "fi" or clean_cmd == "done")
	
	if nesting_depth > 0:
		if is_start: nesting_depth += 1
		if is_end: nesting_depth = max(0, nesting_depth - 1)
		block_buffer.append(clean_cmd)
		if nesting_depth == 0:
			var lines_to_exec = block_buffer.duplicate()
			block_buffer.clear()
			var block_res = await execute_block(lines_to_exec, true)
			recursion_depth -= 1
			return block_res
		recursion_depth -= 1
		return ""
	
	if is_start:
		nesting_depth = 1
		block_buffer.append(clean_cmd)
		recursion_depth -= 1
		return ""

	if "*" in clean_cmd: clean_cmd = _expand_globs(clean_cmd)
	var result = await parse_single_command(clean_cmd, is_silent)
	
	if "not found" in result or "denied" in result or "No such" in result or "cannot access" in result or "Is a directory" in result:
		env_vars["?"] = "1" 
	else:
		env_vars["?"] = "0"
	
	if not is_silent and result != "" and nesting_depth == 0:
		append_to_log(result)
	
	recursion_depth -= 1
	return result

func parse_single_command(cmd_text: String, is_silent: bool = false) -> String:
	var proc = cmd_text.strip_edges()
	
	var redirect_to = ""
	var append_mode = false
	if " >> " in proc:
		var r_parts = proc.split(" >> ", true, 1)
		proc = r_parts[0].strip_edges(); redirect_to = r_parts[1].strip_edges(); append_mode = true
	elif " > " in proc:
		var r_parts = proc.split(" > ", true, 1)
		proc = r_parts[0].strip_edges(); redirect_to = r_parts[1].strip_edges(); append_mode = false

	# 1. COMMAND SUBSTITUTION
	var cmd_sub_regex = RegEx.new()
	cmd_sub_regex.compile("\\$\\(([^)]+)\\)")
	
	# Iterate search matches manually to handle recursion properly
	while true:
		var match_res = cmd_sub_regex.search(proc)
		if not match_res: break
		
		var sub_cmd = match_res.get_string(1)
		var sub_result = await process_input_line(sub_cmd, true)
		sub_result = strip_bbcode(sub_result).replace("\n", " ") 
		
		# Safer replacement: erase range and insert
		proc = proc.erase(match_res.get_start(), match_res.get_end() - match_res.get_start())
		proc = proc.insert(match_res.get_start(), sub_result.strip_edges())
	
	# 2. VARIABLE EXPANSION
	var expand_vars = func(input_str: String) -> String:
		var result_str = input_str
		var sub_regex = RegEx.new(); sub_regex.compile("\\$\\{(\\w+):(\\d+):(\\d+)\\}")
		for m in sub_regex.search_all(result_str):
			var var_name = m.get_string(1); var offset = int(m.get_string(2)); var length = int(m.get_string(3))
			var val = str(env_vars.get(var_name, "")); var sliced = val.substr(offset, length)
			result_str = result_str.replace(m.get_string(), sliced)
		var var_regex = RegEx.new(); var_regex.compile("\\$\\{(\\w+)\\}|\\$(\\w+|\\?)")
		var matches = var_regex.search_all(result_str)
		for i in range(matches.size() - 1, -1, -1):
			var m = matches[i]
			var var_name = m.get_string(1) if m.get_string(1) != "" else m.get_string(2)
			result_str = result_str.erase(m.get_start(), m.get_end() - m.get_start())
			result_str = result_str.insert(m.get_start(), str(env_vars.get(var_name, "")))
		return result_str

	proc = expand_vars.call(proc)
	if redirect_to != "": redirect_to = expand_vars.call(redirect_to)

	var regex = RegEx.new(); regex.compile("\"([^\"]*)\"|'([^']*)'|([^\\s]+)")
	var tokens = []
	for m in regex.search_all(proc):
		var t = m.get_string(1) if m.get_string(1) != "" else (m.get_string(2) if m.get_string(2) != "" else m.get_string(3))
		tokens.append(t)
	if tokens.size() == 0: return ""
	
	var cmd = tokens[0].to_lower()
	var args = tokens.slice(1)
	var final_result = ""
	
	match cmd:
		"echo": 
			if args.size() == 3 and args[1] == "+":
				final_result = str(int(args[0]) + int(args[2]))
			else: final_result = " ".join(args)
		"pwd": final_result = VFS.current_path
		"clear": clear_output(); final_result = ""
		"export": handle_export(args); final_result = ""
		"chmod": execute_chmod(args); final_result = ""
		"reboot": clear_output(); reboot_requested.emit(); final_result = "System rebooting..."
		"nano":
			if args.size() > 0:
				var path = _resolve(args[0]); editor_requested.emit(path); final_result = ""
			else: final_result = "nano: missing filename"
		"help":
			final_result = "AVAILABLE COMMANDS:\n[color=#bd93f9]filesystem:[/color] ls, cd, pwd, mkdir, touch, rm, cp, mv, tree\n[color=#bd93f9]system:[/color]     cat, grep, chmod, export, reboot, ps, kill, whoami, exit\n[color=#bd93f9]tools:[/color]      nano, sh, sleep\n\nType 'man [command]' for detailed usage."
		"man":
			if args.size() > 0:
				var topic = args[0]
				final_result = manual_pages[topic] if manual_pages.has(topic) else "No manual entry for " + topic
			else: final_result = "What manual page do you want?"
		"sleep":
			if args.size() > 0:
				await get_tree().create_timer(float(args[0])).timeout; final_result = ""
			else: final_result = "usage: sleep [seconds]"
		"exit": get_tree().quit(); final_result = ""

		"ls", "mkdir", "touch", "rm", "grep", "cp", "mv", "tree", "unlock", "ps", "kill", "whoami": 
			final_result = await execute_syscall(tokens)
		"cat": final_result = execute_cat(args)
		"cd": final_result = execute_cd(args)
		"sh": final_result = await execute_sh(args, is_silent)
		_:
			var path = find_executable(cmd)
			if path != "": final_result = await execute_sh([path] + args, is_silent)
			else: final_result = "bash: " + cmd + ": command not found"

	if redirect_to != "":
		var p = _resolve(redirect_to)
		if append_mode:
			var existing = ""
			if VFS.files.has(p): existing = VFS.files[p].content
			var separator = "\n" if (existing != "" and not existing.ends_with("\n")) else ""
			VFS.create_file(p, existing + separator + final_result, "file")
		else:VFS.create_file(p, final_result, "file")
		return ""
	return final_result

func execute_sh(args: Array, is_silent: bool = false) -> String:
	if args.size() == 0: return ""
	var p = _resolve(args[0])
	if VFS.files.has(p):
		if not VFS.files[p].get("executable", false): return "bash: " + args[0] + ": Permission denied"
		var saved_nesting = nesting_depth
		var saved_buffer = block_buffer.duplicate()
		var saved_recursion = recursion_depth
		nesting_depth = 0; block_buffer.clear(); recursion_depth = 0 
		var outs = []
		var lines = VFS.files[p].content.split("\n", false)
		for line in lines:
			var res = await process_input_line(line.strip_edges(), is_silent)
			if res != "": outs.append(res)
		nesting_depth = saved_nesting; block_buffer = saved_buffer; recursion_depth = saved_recursion
		if not is_silent: return ""
		return " ".join(outs)
	return "sh: " + args[0] + ": not found"

func execute_cd(args: Array) -> String:
	var raw_input = args[0] if args.size() > 0 else "~"
	var p = _resolve(raw_input)
	if VFS.files.has(p) and VFS.files[p].type == "dir":
		VFS.current_path = p; env_vars["PWD"] = p; return ""
	return "cd: No such directory"

func execute_cat(args: Array) -> String:
	if args.size() == 0: return ""
	var p = _resolve(args[0])
	return VFS.files[p].content if VFS.files.has(p) else "cat: No such file"

func execute_syscall(args: Array) -> String:
	if args.size() == 0: return ""
	var cmd = args[0]
	match cmd:
		"ls":
			var show_hidden = false; var long_format = false; var targets = [] 
			for i in range(1, args.size()):
				if args[i].begins_with("-"):
					for char in args[i].substr(1):
						if char == "a": show_hidden = true
						elif char == "l": long_format = true
				else: targets.append(_resolve(args[i]))
			if targets.is_empty(): targets.append(VFS.current_path)
			var all_out = []
			for target in targets:
				if "*" in target:
					all_out.append("ls: cannot access '" + target + "': No such directory"); continue
				if not VFS.files.has(target): 
					all_out.append("ls: cannot access '" + target + "': No such directory"); continue
				var dir_files = []
				for p in VFS.files.keys():
					if p.begins_with(target) and p != target:
						var rel = p.trim_prefix(target).trim_prefix("/")
						if not "/" in rel:
							if not show_hidden and rel.begins_with("."): continue
							dir_files.append({"path": p, "rel": rel})
				dir_files.sort_custom(func(a, b): return a.rel < b.rel)
				for f in dir_files:
					var data = VFS.files[f.path]; var rel = f.rel
					if long_format:
						var perms = "drwxr-xr-x" if data.type == "dir" else ("-rwxr-xr-x" if data.get("executable", false) else "-rw-r--r--")
						var size = str(data.content.length())
						var owner = "root" if f.path.begins_with("/root") or f.path.begins_with("/bin") else "jesse"
						var date = "Oct 26 09:00"
						var col = "#ffffff"
						if data.type == "dir": col = "#5dade2"
						elif data.get("executable", false): col = "#50fa7b"
						all_out.append("%s %s %s %5s %s [color=%s]%s[/color]" % [perms, owner, owner, size, date, col, rel])
					else:
						var col = "#ffffff"
						if data.type == "dir": col = "#5dade2"
						elif data.get("executable", false): col = "#50fa7b"
						all_out.append("[color=" + col + "]" + rel + "[/color]")
			return "\n".join(all_out) if long_format else " ".join(all_out)
		
		"tree":
			var target = VFS.current_path
			if args.size() > 1: target = _resolve(args[1])
			if not VFS.files.has(target): return "tree: " + args[1] + ": No such directory"
			var out_arr = []
			out_arr.append("[color=#5dade2]" + (target if target == "/" else target.get_file()) + "[/color]")
			_recursive_tree(target, "", out_arr)
			return "\n".join(out_arr)
			
		"mkdir":
			if args.size() < 2: return "mkdir: missing operand"
			VFS.create_file(_resolve(args[1]), "", "dir"); return ""
		"touch":
			if args.size() < 2: return "touch: missing file operand"
			var p = _resolve(args[1])
			if not VFS.files.has(p): VFS.create_file(p, "", "file"); return ""
		
		"rm":
			var recursive = false; var force = false; var targets = []
			for i in range(1, args.size()):
				if args[i].begins_with("-"):
					for char in args[i].substr(1):
						if char == "r" or char == "R": recursive = true
						elif char == "f": force = true
				else: targets.append(_resolve(args[i]))
			if targets.is_empty(): return "" if force else "rm: missing operand"
			var output_errs = []
			for t in targets:
				if not VFS.files.has(t):
					# FIX: use full path 't', not t.get_file()
					if not force: output_errs.append("rm: " + t + ": No such file")
					continue
				var is_dir = (VFS.files[t].type == "dir")
				if is_dir:
					if recursive: _recursive_delete(t)
					else: output_errs.append("rm: cannot remove '" + t.get_file() + "': Is a directory")
				else: VFS.files.erase(t)
			return "\n".join(output_errs)

		"cp":
			if args.size() < 3: return "cp: missing destination"
			var s = _resolve(args[1]); var d = _resolve(args[2])
			if VFS.files.has(s): 
				if VFS.files.has(d) and VFS.files[d].type == "dir": d = d + "/" + s.get_file()
				VFS.files[d] = VFS.files[s].duplicate(); return ""
			return "cp: " + args[1] + ": No such file"
		"mv":
			if args.size() < 3: return "mv: missing destination"
			var s_path = _resolve(args[1]); var d_path = _resolve(args[2])
			if not VFS.files.has(s_path): return "mv: " + args[1] + ": No such file"
			if VFS.files.has(d_path) and VFS.files[d_path].type == "dir": d_path = d_path + ("/" if not d_path.ends_with("/") else "") + s_path.get_file()
			VFS.move_item(s_path, d_path); return ""
		"grep":
			if args.size() < 3: return "usage: grep [pattern] [file]"
			var pat = args[1].to_lower(); var p = _resolve(args[2])
			if VFS.files.has(p):
				var ms = []
				for l in VFS.files[p].content.split("\n"):
					if pat in l.to_lower(): ms.append(l)
				return " ".join(ms)
			return "grep: " + args[2] + ": No such file"
		"unlock":
			if args.size() < 2: return "Usage: unlock [key]"
			if args[1] == "NODE-7777-X" or args[1] == "CORRECT-KEY-777": return "ACCESS GRANTED. FIREWALL DISABLED."
			else: return "Access Denied: " + args[1]
		"ps":
			if not VFS.files.has("/proc"): return "Error: /proc filesystem not mounted."
			var out = ["[color=#bd93f9]  PID TTY          TIME CMD[/color]"]
			for path in VFS.files.keys():
				if path.begins_with("/proc/") and path.ends_with("/cmdline"):
					var pid = path.get_slice("/", 2); var proc_cmd = VFS.files[path].content 
					out.append("%5s ?        00:00:00 %s" % [pid, proc_cmd])
			return "\n".join(out)
		"kill":
			if args.size() < 2: return "kill: usage: kill [pid]"
			var pid = args[1]; var proc_dir = "/proc/" + pid
			if not VFS.files.has(proc_dir): return "kill: (" + pid + ") - No such process"
			var env_file = proc_dir + "/environ"; var env_content = ""
			if VFS.files.has(env_file): env_content = VFS.files[env_file].content
			if env_content == "MODE=HUNTER": _recursive_delete(proc_dir); return "[SYSTEM] Process " + pid + " terminated."
			elif env_content == "MODE=IDLE": return "[KERNEL PANIC] CRITICAL PROCESS KILLED. SYSTEM HALTED."
			else: return "kill: permission denied"
		"whoami":
			if MissionManager.current_day == 5 and MissionManager.current_mission_id >= 8: return "root"
			return env_vars["USER"]
	return ""

func _handle_autocomplete():
	var current_text = text.strip_edges()
	if current_text == "": return
	var tokens = text.split(" "); var last_token = tokens[-1]
	var possibilities = []; var is_command = (tokens.size() == 1)
	if is_command:
		for cmd in manual_pages.keys(): if cmd.begins_with(last_token): possibilities.append(cmd)
	var dir_path = VFS.current_path; var prefix = last_token
	if "/" in last_token: dir_path = _resolve(last_token.get_base_dir()); prefix = last_token.get_file(); if last_token.ends_with("/"): prefix = ""
	if VFS.files.has(dir_path):
		for path in VFS.files.keys():
			if path.begins_with(dir_path) and path != dir_path:
				var rel = path.trim_prefix(dir_path).trim_prefix("/")
				if not "/" in rel and rel.begins_with(prefix): possibilities.append(rel)
	var distinct = []
	for p in possibilities: if not p in distinct: distinct.append(p)
	if distinct.size() == 1:
		var completed = distinct[0]
		if "/" in last_token: tokens[-1] = last_token.get_base_dir() + "/" + completed
		else: tokens[-1] = completed
		text = " ".join(tokens)
		if VFS.files.has(_resolve(tokens[-1])) and VFS.files[_resolve(tokens[-1])].type == "dir": text += "/"
		caret_column = text.length()
	elif distinct.size() > 1: append_to_log("\n" + "  ".join(distinct))

func _recursive_tree(base_path: String, prefix: String, out: Array):
	var children = []
	for p in VFS.files.keys():
		if p == base_path: continue
		if p.begins_with(base_path):
			var rel = p.trim_prefix(base_path)
			if rel.begins_with("/"): rel = rel.trim_prefix("/")
			if not "/" in rel and rel != "": children.append(p)
	children.sort()
	for i in range(children.size()):
		var child_full = children[i]; var is_last = (i == children.size() - 1)
		var connector = "└── " if is_last else "├── "; var node_name = child_full.get_file()
		var node_data = VFS.files[child_full]; var col = "#ffffff"
		if node_data.type == "dir": col = "#5dade2"
		elif node_data.get("executable", false): col = "#50fa7b"
		out.append(prefix + connector + "[color=" + col + "]" + node_name + "[/color]")
		if node_data.type == "dir":
			var next_prefix = prefix + ("    " if is_last else "│   ")
			_recursive_tree(child_full, next_prefix, out)

func _recursive_delete(target_path: String):
	var to_erase = []
	for p in VFS.files.keys():
		if p == target_path or p.begins_with(target_path + "/"): to_erase.append(p)
	for p in to_erase: VFS.files.erase(p)

func execute_chmod(args: Array):
	if args.size() < 2: return
	var path = _resolve(args[1])
	if VFS.files.has(path) and "+x" in args[0]: VFS.files[path]["executable"] = true

func handle_export(args: Array):
	var pair = " ".join(args).split("=", true, 1)
	if pair.size() == 2: env_vars[pair[0].strip_edges()] = pair[1].strip_edges().replace('"', '')

func find_executable(cmd: String) -> String:
	var target = VFS.resolve_path("/bin/" + cmd)
	return target if VFS.files.has(target) else ""

func execute_block(lines: Array, is_silent: bool = false) -> String:
	var header = lines[0]; var body = lines.slice(1, -1); var output = []
	var cmd_sub_regex = RegEx.new(); cmd_sub_regex.compile("\\$\\(([^)]+)\\)")
	var cmd_matches = cmd_sub_regex.search_all(header)
	for i in range(cmd_matches.size() - 1, -1, -1):
		var m = cmd_matches[i]; var sub_cmd = m.get_string(1)
		var sub_result = await _run_atomic_command(sub_cmd, true)
		sub_result = strip_bbcode(sub_result).replace("\n", " ").strip_edges()
		header = header.erase(m.get_start(), m.get_end() - m.get_start())
		header = header.insert(m.get_start(), sub_result)
	var var_regex = RegEx.new(); var_regex.compile("\\$\\{(\\w+)\\}|\\$(\\w+|\\?)")
	var matches = var_regex.search_all(header)
	for i in range(matches.size() - 1, -1, -1):
		var m = matches[i]; var var_name = m.get_string(1) if m.get_string(1) != "" else m.get_string(2)
		header = header.erase(m.get_start(), m.get_end() - m.get_start())
		header = header.insert(m.get_start(), str(env_vars.get(var_name, "")))
	if header.begins_with("if"):
		var condition = ""; if "[" in header and "]" in header:
			var start_idx = header.find("["); var end_idx = header.rfind("]")
			if start_idx != -1 and end_idx != -1: condition = header.substr(start_idx + 1, end_idx - start_idx - 1).strip_edges()
		var run = await evaluate_condition(condition)
		for line in body:
			var cl = line.strip_edges()
			if nesting_depth == 0:
				if cl in ["then", "do", ""]: continue
				if cl == "else": run = !run; continue
			if run or nesting_depth > 0:
				var res = await _run_atomic_command(line, true); if run and res != "": output.append(res)
	elif header.begins_with("for"):
		var words_header = header.split(" ", false)
		if words_header.size() >= 2:
			var var_name = words_header[1]; var items = []
			var in_index = words_header.find("in")
			if in_index != -1 and in_index < words_header.size() - 1:
				for item in words_header.slice(in_index + 1): items.append(item)
			for item in items:
				env_vars[var_name] = item
				for line in body:
					var stripped = line.strip_edges()
					if nesting_depth == 0 and (stripped in ["do", "done", ""]): continue
					var res = await _run_atomic_command(line, true); if res != "": output.append(res)
	return " ".join(output) if output.size() > 0 else ""

func evaluate_condition(cond: String) -> bool:
	var exp = cond.strip_edges()
	var var_regex = RegEx.new(); var_regex.compile("\\$\\{(\\w+)\\}|\\$(\\w+|\\?)")
	var matches = var_regex.search_all(exp)
	for i in range(matches.size() - 1, -1, -1):
		var m = matches[i]; var var_name = m.get_string(1) if m.get_string(1) != "" else m.get_string(2)
		exp = exp.erase(m.get_start(), m.get_end() - m.get_start())
		exp = exp.insert(m.get_start(), str(env_vars.get(var_name, "")))
	if exp.begins_with("-d "): return VFS.files.has(_resolve(exp.get_slice(" ", 1))) and VFS.files[_resolve(exp.get_slice(" ", 1))].type == "dir"
	if exp.begins_with("-f "): return VFS.files.has(_resolve(exp.get_slice(" ", 1))) and VFS.files[_resolve(exp.get_slice(" ", 1))].type == "file"
	# FIX: Explicit check for double vs single equals to match Bash strictness
	if "==" in exp: var s = exp.split("=="); if s.size() == 2: return s[0].strip_edges().replace('"', '') == s[1].strip_edges().replace('"', '')
	if "=" in exp: var s = exp.split("="); if s.size() == 2: return s[0].strip_edges().replace('"', '') == s[1].strip_edges().replace('"', '')
	return false

func _expand_globs(line: String) -> String:
	var parts = line.split(" "); var new_parts = []
	for p in parts:
		if "*" in p:
			var matches = []
			var base_dir = VFS.current_path; var pattern = p
			if "/" in p: base_dir = _resolve(p.get_base_dir()); pattern = p.get_file()
			var regex_pattern = "^" + pattern.replace(".", "\\.").replace("*", ".*") + "$"
			var regex = RegEx.new(); regex.compile(regex_pattern)
			for file_path in VFS.files.keys():
				if file_path.begins_with(base_dir):
					var rel = file_path.trim_prefix(base_dir).trim_prefix("/")
					if not "/" in rel and regex.search(rel) and rel != "":
						if "/" in p: matches.append(file_path)
						else: matches.append(rel)
			if matches.size() > 0: matches.sort(); new_parts.append_array(matches); continue
		new_parts.append(p)
	return " ".join(new_parts)

func clear_output(): if output_log: output_log.clear()

func append_to_log(msg: String) -> void:
	if output_log: output_log.append_text(msg + "\n")
	await get_tree().process_frame
	if scroll_v: if output_log.get_selected_text() == "": scroll_v.set_deferred("scroll_vertical", scroll_v.get_v_scroll_bar().max_value)

func grab_focus_deferred(): grab_focus(); caret_column = text.length()

func _apply_font_size(new_size: int): add_theme_font_size_override("font_size", new_size)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed:
			match event.keycode:
				KEY_L: clear_output(); 
				KEY_A: caret_column = 0; 
				KEY_E: caret_column = text.length(); 
				KEY_U: text = ""
				KEY_D: if text == "": get_tree().quit()
				KEY_EQUAL: GlobalSettings.update_font_size(1); 
				KEY_MINUS: GlobalSettings.update_font_size(-1)
			get_viewport().set_input_as_handled()
		else:
			match event.keycode:
				KEY_TAB: _handle_autocomplete(); get_viewport().set_input_as_handled()
				KEY_UP: _handle_history(1); get_viewport().set_input_as_handled()
				KEY_DOWN: _handle_history(-1); get_viewport().set_input_as_handled()

func _handle_history(direction: int):
	if cmd_history.is_empty(): return
	if history_index == -1: history_index = cmd_history.size()
	history_index = clampi(history_index - direction, 0, cmd_history.size() - 1)
	text = cmd_history[history_index]; caret_column = text.length()

func _on_focus_changed(node: Control) -> void:
	if focus_loop_enabled and node != self and is_visible_in_tree(): call_deferred("grab_focus")

func strip_bbcode(text: String) -> String:
	var regex = RegEx.new(); regex.compile("\\[/?[^\\]]+\\]")
	return regex.sub(text, "", true)
