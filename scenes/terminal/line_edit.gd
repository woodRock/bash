extends LineEdit

# --- SIGNALS ---
signal command_executed(command_text, response_text)
signal reboot_requested       # Notify Main.gd to trigger boot sequence
signal editor_requested(path) # Notify Main.gd to switch to Editor

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
	"PWD": "/home/jesse",
	"PATH": "/bin",
	"PROMPT": "[color=#00FF41]user@gatekeeper[/color]",
	"?": "0"
}

var block_buffer = []
var nesting_depth = 0
var recursion_depth = 0
const MAX_RECURSION_DEPTH = 1000

func _ready() -> void:
	# 1. Initialize Virtual File System
	VFS = VFS_scene.instantiate()
	get_tree().root.add_child.call_deferred(VFS)
	VFS.current_path = env_vars["PWD"]
	
	# 2. Register self with MissionManager
	MissionManager.terminal = self
	MissionManager.vfs_node = VFS
	
	_setup_node_references()
	
	text_submitted.connect(_on_command_submitted)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
	# 3. Sync Font Settings
	_apply_font_size(GlobalSettings.font_size)
	GlobalSettings.setting_changed.connect(func(k, v): if k == "font_size": _apply_font_size(v))
	
	# 4. Start Shell
	focus_loop_enabled = true
	await _run_atomic_command("sh /.bashrc", true)
	grab_focus()

func _setup_node_references():
	output_log = get_tree().current_scene.find_child("RichTextLabel", true, false)
	if output_log:
		var parent = output_log.get_parent()
		if parent is ScrollContainer:
			scroll_v = parent

func _on_command_submitted(new_text: String) -> void:
	var line = new_text.strip_edges()
	if line == "": return
	
	# Handle History & Display
	if nesting_depth == 0:
		cmd_history.append(line)
		history_index = -1
		append_to_log(env_vars["PROMPT"] + ":" + VFS.current_path + "$ " + line)
	else:
		append_to_log("> " + line)
		
	var result = await process_input_line(line)
	
	# Notify Mission Manager
	MissionManager.check_mission_progress(MissionManager.TaskType.COMMAND, line)
	MissionManager.check_mission_progress(MissionManager.TaskType.VFS_STATE, line)
	MissionManager.check_mission_progress(MissionManager.TaskType.OUTPUT, result)
	
	command_executed.emit(line, result)
	text = ""; grab_focus()

# --- INPUT PROCESSING & PARSING ---

func process_input_line(line: String, is_silent: bool = false) -> String:
	var clean_line = line.strip_edges()
	if clean_line == "" or clean_line.begins_with("#"): return ""

	# Regex to split by && or ||
	var regex = RegEx.new(); regex.compile("(&&|\\|\\|)")
	var matches = regex.search_all(clean_line)
	var segments = []; var operators = []; var last_index = 0
	
	for m in matches:
		segments.append(clean_line.substr(last_index, m.get_start() - last_index))
		operators.append(m.get_string()); last_index = m.get_end()
	segments.append(clean_line.substr(last_index))

	var all_results = []
	for i in range(segments.size()):
		var cmd_segment = segments[i].strip_edges()
		if cmd_segment == "": continue
		if i > 0:
			var op = operators[i-1]
			# Logic short-circuiting
			if (op == "&&" and env_vars["?"] != "0") or (op == "||" and env_vars["?"] == "0"):
				continue
		var result = await _run_atomic_command(cmd_segment, is_silent)
		if result != "":
			all_results.append(result)
	
	return "\n".join(all_results) if all_results.size() > 0 else ""

func _run_atomic_command(cmd_text: String, is_silent: bool) -> String:
	var clean_cmd = cmd_text.strip_edges()
	if clean_cmd == "": return ""
	
	recursion_depth += 1
	if recursion_depth > MAX_RECURSION_DEPTH:
		recursion_depth -= 1
		return "bash: maximum recursion depth exceeded"
	
	var words = clean_cmd.split(" ")
	var is_start = (words[0] == "if" or words[0] == "for")
	var is_end = (clean_cmd == "fi" or clean_cmd == "done")
	
	# Block handling (If/For loops)
	if nesting_depth > 0:
		if is_start: nesting_depth += 1
		if is_end: nesting_depth = max(0, nesting_depth - 1)
		block_buffer.append(clean_cmd)
		if nesting_depth == 0:
			var block_res = await execute_block(block_buffer.duplicate(), true)
			block_buffer.clear()
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
	env_vars["?"] = "1" if ("not found" in result or "denied" in result or "No such" in result) else "0"
	
	if not is_silent and result != "" and nesting_depth == 0:
		append_to_log(result)
	
	recursion_depth -= 1
	return result

func parse_single_command(cmd_text: String, is_silent: bool = false) -> String:
	var proc = cmd_text.strip_edges()
	
	# Redirection >
	var redirect_to = ""
	if " > " in proc:
		var r_parts = proc.split(" > ", true, 1)
		proc = r_parts[0].strip_edges()
		redirect_to = r_parts[1].strip_edges()

	# Subshell $(...)
	var cmd_sub_regex = RegEx.new()
	cmd_sub_regex.compile("\\$\\(([^)]+)\\)")
	var cmd_matches = cmd_sub_regex.search_all(proc)
	for i in range(cmd_matches.size() - 1, -1, -1):
		var m = cmd_matches[i]
		var sub_cmd = m.get_string(1)
		var sub_result = await _run_atomic_command(sub_cmd, true)
		proc = proc.erase(m.get_start(), m.get_end() - m.get_start())
		proc = proc.insert(m.get_start(), sub_result.strip_edges())
	
	# Variables $VAR
	var var_regex = RegEx.new(); var_regex.compile("\\$\\{(\\w+)\\}|\\$(\\w+)")
	var matches = var_regex.search_all(proc)
	for i in range(matches.size() - 1, -1, -1):
		var m = matches[i]
		var var_name = m.get_string(1) if m.get_string(1) != "" else m.get_string(2)
		proc = proc.erase(m.get_start(), m.get_end() - m.get_start())
		proc = proc.insert(m.get_start(), str(env_vars.get(var_name, "")))

	# Tokenize
	var regex = RegEx.new(); regex.compile("\"([^\"]*)\"|'([^']*)'|([^\\s]+)")
	var tokens = []
	for m in regex.search_all(proc):
		var t = m.get_string(1) if m.get_string(1) != "" else (m.get_string(2) if m.get_string(2) != "" else m.get_string(3))
		if t.ends_with(";"): t = t.substr(0, t.length() - 1)
		tokens.append(t)
	if tokens.size() == 0: return ""
	
	var cmd = tokens[0].to_lower()
	var args = tokens.slice(1)
	var final_result = ""
	
	match cmd:
		"echo": final_result = " ".join(args)
		"pwd": final_result = VFS.current_path
		"clear": 
			clear_output()
			final_result = ""
		"export": 
			handle_export(args)
			final_result = ""
		"chmod": 
			execute_chmod(args)
			final_result = ""
			
		# --- SCENE SWITCHING COMMANDS ---
		"reboot":
			clear_output()
			reboot_requested.emit()
			final_result = "System rebooting..."
		"nano":
			if args.size() > 0:
				# FIX: Resolve the absolute path relative to current PWD
				# OLD: var path = args[0] 
				var path = VFS.resolve_path(args[0]) 
				
				editor_requested.emit(path) 
				final_result = ""
			else:
				final_result = "nano: missing filename"
		# --- FILESYSTEM SYSCALLS ---
		"ls", "mkdir", "touch", "rm", "grep", "cp", "mv": 
			final_result = await execute_syscall(tokens)
		"cat": 
			final_result = execute_cat(args)
		"cd": 
			final_result = execute_cd(args)
		"sh": 
			final_result = await execute_sh(args)
		_:
			# Try to find executable in /bin
			var path = find_executable(cmd)
			if path != "": final_result = await execute_sh([path] + args)
			else: final_result = "bash: " + cmd + ": command not found"

	if redirect_to != "":
		var p = VFS.resolve_path(redirect_to)
		VFS.create_file(p, final_result, "file")
		return ""
	return final_result

# --- SYSCALL IMPLEMENTATIONS ---

func execute_syscall(args: Array) -> String:
	if args.size() == 0: return ""
	var cmd = args[0]
	match cmd:
		"ls":
			var show_hidden = false
			var long_format = false
			var target = VFS.current_path
			for i in range(1, args.size()):
				if args[i] == "-a": show_hidden = true
				elif args[i] == "-l": long_format = true
				else: target = VFS.resolve_path(args[i])
			
			if not VFS.files.has(target): return "ls: cannot access '" + target + "': No such directory"
			var out = []
			for p in VFS.files.keys():
				if p.begins_with(target) and p != target:
					var rel = p.trim_prefix(target).trim_prefix("/")
					if not "/" in rel:
						if not show_hidden and rel.begins_with("."): continue
						var data = VFS.files[p]
						var display_text = ""
						if long_format:
							var type_char = "d" if data.type == "dir" else "-"
							var exec_char = "x" if data.get("executable", false) else "-"
							display_text = type_char + "rw-rw-" + exec_char + " jesse_wood staff 1024 "
						
						# Color Coding
						var col = "#ffffff"
						if data.type == "dir": col = "#5dade2" # Blue for dir
						elif data.get("executable", false): col = "#50fa7b" # Green for exe
						display_text += "[color=" + col + "]" + rel + "[/color]"
						out.append(display_text)
			return "\n".join(out) if long_format else "  ".join(out)
			
		"mkdir":
			if args.size() < 2: return "mkdir: missing operand"
			VFS.create_file(VFS.resolve_path(args[1]), "", "dir")
			return ""
			
		"touch":
			if args.size() < 2: return "touch: missing file operand"
			var p = VFS.resolve_path(args[1])
			if not VFS.files.has(p): VFS.create_file(p, "", "file")
			return ""
			
		"rm":
			if args.size() < 2: return "rm: missing operand"
			var p = VFS.resolve_path(args[1])
			if VFS.files.has(p): VFS.files.erase(p); return ""
			return "rm: " + args[1] + ": No such file"
			
		"cp":
			if args.size() < 3: return "cp: missing destination"
			var s = VFS.resolve_path(args[1]); var d = VFS.resolve_path(args[2])
			if VFS.files.has(s): VFS.files[d] = VFS.files[s].duplicate(); return ""
			return "cp: " + args[1] + ": No such file"
			
		"mv":
			if args.size() < 3: return "mv: missing destination"
			var s_path = VFS.resolve_path(args[1])
			var d_path = VFS.resolve_path(args[2])
			
			if not VFS.files.has(s_path): return "mv: " + args[1] + ": No such file"
			
			# Logic: If moving to a folder, append filename to path
			if VFS.files.has(d_path) and VFS.files[d_path].type == "dir":
				var file_name = s_path.get_file()
				d_path = d_path + ("/" if not d_path.ends_with("/") else "") + file_name
				
			VFS.move_item(s_path, d_path)
			return ""
			
		"grep":
			if args.size() < 3: return "usage: grep [pattern] [file]"
			var pat = args[1].to_lower(); var p = VFS.resolve_path(args[2])
			if VFS.files.has(p):
				var ms = []
				for l in VFS.files[p].content.split("\n"):
					if pat in l.to_lower(): ms.append(l)
				return "\n".join(ms)
			return "grep: " + args[2] + ": No such file"
			
	return ""

func execute_sh(args: Array) -> String:
	if args.size() == 0: return ""
	var p = VFS.resolve_path(args[0])
	if VFS.files.has(p):
		if not VFS.files[p].get("executable", false): return "bash: " + args[0] + ": Permission denied"
		
		# Context Switching for Script Execution
		var saved_nesting = nesting_depth
		var saved_buffer = block_buffer.duplicate()
		nesting_depth = 0; block_buffer.clear()
		
		var outs = []
		var lines = VFS.files[p].content.split("\n", false)
		for line in lines:
			var res = await process_input_line(line.strip_edges(), true)
			if res != "": outs.append(res)
			
		nesting_depth = saved_nesting; block_buffer = saved_buffer
		return "\n".join(outs)
	return "sh: " + args[0] + ": not found"

func execute_cd(args: Array) -> String:
	var p = VFS.resolve_path(args[0] if args.size() > 0 else "/home/jesse")
	if VFS.files.has(p) and VFS.files[p].type == "dir":
		VFS.current_path = p; env_vars["PWD"] = p; return ""
	return "cd: No such directory"

func execute_cat(args: Array) -> String:
	if args.size() == 0: return ""
	var p = VFS.resolve_path(args[0])
	return VFS.files[p].content if VFS.files.has(p) else "cat: No such file"

func execute_chmod(args: Array):
	if args.size() < 2: return
	var path = VFS.resolve_path(args[1])
	if VFS.files.has(path) and "+x" in args[0]: VFS.files[path]["executable"] = true

func handle_export(args: Array):
	var pair = " ".join(args).split("=", true, 1)
	if pair.size() == 2: env_vars[pair[0]] = pair[1].strip_edges().replace('"', '')

func find_executable(cmd: String) -> String:
	var target = VFS.resolve_path("/bin/" + cmd)
	return target if VFS.files.has(target) else ""

# --- BLOCK EXECUTION (Loops/Ifs) ---

func execute_block(lines: Array, is_silent: bool = false) -> String:
	var header = lines[0]; var body = lines.slice(1, -1); var output = []
	if header.begins_with("if"):
		var condition = ""
		if "[" in header and "]" in header:
			var start_idx = header.find("[")
			var end_idx = header.rfind("]")
			if start_idx != -1 and end_idx != -1:
				condition = header.substr(start_idx + 1, end_idx - start_idx - 1).strip_edges()
		
		var run = await evaluate_condition(condition)
		for line in body:
			var cl = line.strip_edges()
			if cl in ["then", "do", ""]: continue
			if cl == "else": run = !run; continue
			if run:
				var res = await _run_atomic_command(line, true)
				if res != "": output.append(res)
				
	elif header.begins_with("for"):
		var words_header = header.split(" ", false)
		if words_header.size() >= 2:
			var var_name = words_header[1]
			var items = []
			var in_index = words_header.find("in")
			if in_index != -1 and in_index < words_header.size() - 1:
				items = words_header.slice(in_index + 1)
				# Expand {1..3} or variables here if needed
				var expanded_items = []
				for item in items:
					expanded_items.append(item) # Simplified expansion
				items = expanded_items
			
			for item in items:
				env_vars[var_name] = item
				# Simple loop body execution
				for line in body:
					var stripped = line.strip_edges()
					if stripped in ["do", "done", ""]: continue
					var res = await _run_atomic_command(line, true)
					if res != "": output.append(res)
	
	if output.size() > 0: return "\n".join(output)
	return ""

func evaluate_condition(cond: String) -> bool:
	# Basic condition evaluator for if [ $VAR == 1 ]
	var exp = cond.strip_edges()
	
	# Replace variables
	var var_regex = RegEx.new(); var_regex.compile("\\$\\{(\\w+)\\}|\\$(\\w+)")
	var matches = var_regex.search_all(exp)
	for i in range(matches.size() - 1, -1, -1):
		var m = matches[i]
		var var_name = m.get_string(1) if m.get_string(1) != "" else m.get_string(2)
		exp = exp.erase(m.get_start(), m.get_end() - m.get_start())
		exp = exp.insert(m.get_start(), str(env_vars.get(var_name, "")))
		
	if "==" in exp:
		var s = exp.split("==")
		if s.size() == 2: return s[0].strip_edges().replace('"', '') == s[1].strip_edges().replace('"', '')
	return false

# --- UTILITIES ---

func _expand_globs(line: String) -> String:
	var parts = line.split(" ")
	var new_parts = []
	for p in parts:
		if "*" in p:
			var matches = []
			var pattern = "^" + p.replace(".", "\\.").replace("*", ".*") + "$"
			var regex = RegEx.new(); regex.compile(pattern)
			for file_path in VFS.files.keys():
				var rel = file_path.trim_prefix(VFS.current_path).trim_prefix("/")
				if not "/" in rel and regex.search(rel): matches.append(rel)
			if matches.size() > 0:
				new_parts.append(" ".join(matches))
				continue
		new_parts.append(p)
	return " ".join(new_parts)

func _handle_autocomplete():
	var current_text = text.strip_edges()
	if current_text == "": return
	var tokens = current_text.split(" ")
	var last_token = tokens[-1]
	var possibilities = []
	
	# Check /bin
	for path in VFS.files.keys():
		if path.begins_with("/bin/"):
			var cmd_name = path.get_file()
			if cmd_name.begins_with(last_token): possibilities.append(cmd_name)
	
	# Check current directory
	for path in VFS.files.keys():
		if path.begins_with(VFS.current_path):
			var file_name = path.trim_prefix(VFS.current_path).trim_prefix("/")
			if not "/" in file_name and file_name.begins_with(last_token):
				possibilities.append(file_name)
				
	if possibilities.size() == 1:
		tokens[-1] = possibilities[0]
		text = " ".join(tokens)
		caret_column = text.length()
	elif possibilities.size() > 1:
		append_to_log("\n" + "  ".join(possibilities))

func clear_output():
	if output_log: output_log.clear()

func append_to_log(msg: String) -> void:
	if output_log: output_log.append_text(msg + "\n")
	await get_tree().process_frame
	if scroll_v: scroll_v.set_deferred("scroll_vertical", scroll_v.get_v_scroll_bar().max_value)

func grab_focus_deferred():
	grab_focus()
	caret_column = text.length()

func _apply_font_size(new_size: int):
	add_theme_font_size_override("font_size", new_size)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed:
			match event.keycode:
				KEY_L: clear_output()
				KEY_A: caret_column = 0
				KEY_E: caret_column = text.length()
				KEY_U: text = ""
				KEY_EQUAL: GlobalSettings.update_font_size(1)
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
	text = cmd_history[history_index]
	caret_column = text.length()

func _on_focus_changed(node: Control) -> void:
	# Keep focus on terminal unless specific UI elements (like Editor) are active
	if focus_loop_enabled and node != self and is_visible_in_tree():
		call_deferred("grab_focus")
