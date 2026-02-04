extends LineEdit

# --- SIGNALS ---
signal command_executed(command_text, response_text)

# --- NODES ---
var output_log: RichTextLabel
var scroll_v: ScrollContainer
var editor: Control 
var VFS: Node
@onready var VFS_scene: PackedScene = preload("res://virtual_file_system.tscn")

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
var boot_screen_timer: float = 4.0
var recursion_depth = 0
const MAX_RECURSION_DEPTH = 100

func _ready() -> void:
	VFS = VFS_scene.instantiate()
	get_tree().root.add_child.call_deferred(VFS) 
	VFS.current_path = env_vars["PWD"]
	
	MissionManager.terminal = self
	MissionManager.vfs_node = VFS
	
	_setup_node_references()
	
	text_submitted.connect(_on_command_submitted)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
	await get_tree().process_frame
	await get_tree().create_timer(boot_screen_timer).timeout 
	
	focus_loop_enabled = true
	await _run_atomic_command("sh /.bashrc", true)
	grab_focus()

func _setup_node_references():
	editor = get_tree().current_scene.find_child("Editor", true, false)
	if editor:
		if not editor.is_connected("file_saved", _on_editor_saved):
			editor.file_saved.connect(_on_editor_saved)
		if not editor.is_connected("editor_closed", _on_editor_closed):
			editor.editor_closed.connect(_on_editor_closed)
	
	output_log = get_tree().current_scene.find_child("RichTextLabel", true, false)
	if output_log:
		var parent = output_log.get_parent()
		if parent is ScrollContainer:
			scroll_v = parent

func _on_command_submitted(new_text: String) -> void:
	var line = new_text.strip_edges()
	if line == "" or (editor and editor.visible): return
	
	if nesting_depth == 0:
		cmd_history.append(line)
		history_index = -1 
		append_to_log(env_vars["PROMPT"] + ":" + VFS.current_path + "$ " + line)
	else:
		append_to_log("> " + line)
		
	# 1. Run the command first
	var result = await process_input_line(line)
	
	# 2. THEN check progress (so touch/mkdir files actually exist now)
	MissionManager.check_mission_progress(MissionManager.TaskType.COMMAND, line)
	MissionManager.check_mission_progress(MissionManager.TaskType.VFS_STATE, line)
	MissionManager.check_mission_progress(MissionManager.TaskType.OUTPUT, result)
	
	command_executed.emit(line, result)
	text = ""; grab_focus()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_TAB:
				_handle_autocomplete()
				get_viewport().set_input_as_handled()
			KEY_UP:
				_handle_history(1)
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_handle_history(-1)
				get_viewport().set_input_as_handled()

func _handle_history(direction: int):
	if cmd_history.is_empty(): return
	if history_index == -1: history_index = cmd_history.size()
	history_index = clampi(history_index - direction, 0, cmd_history.size() - 1)
	text = cmd_history[history_index]
	caret_column = text.length()

func _handle_autocomplete():
	var current_text = text.strip_edges()
	if current_text == "": return
	var tokens = current_text.split(" ")
	var last_token = tokens[-1]
	var possibilities = []
	
	if tokens.size() == 1:
		for path in VFS.files.keys():
			if path.begins_with("/bin/"):
				var cmd_name = path.get_file()
				if cmd_name.begins_with(last_token): possibilities.append(cmd_name)
	
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

func process_input_line(line: String, is_silent: bool = false) -> String:
	var clean_line = line.strip_edges()
	if clean_line == "" or clean_line.begins_with("#"): return ""

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
				var expanded_items = []
				for item in items:
					if item.begins_with("$"):
						var var_name_to_expand = item.trim_prefix("$")
						if var_name_to_expand.begins_with("{"):
							var_name_to_expand = var_name_to_expand.trim_prefix("{").trim_suffix("}")
						var value = str(env_vars.get(var_name_to_expand, ""))
						if value != "":
							expanded_items.append(value)
					else:
						expanded_items.append(item)
				items = expanded_items
			
			for item in items:
				env_vars[var_name] = item
				var processed_body = []
				var i = 0
				while i < body.size():
					var line = body[i]
					var stripped = line.strip_edges()
					if stripped in ["do", ""]: 
						i += 1
						continue
					var words = stripped.split(" ", false)
					if words.size() > 0 and (words[0] == "if" or words[0] == "for"):
						var nested_lines = [stripped]
						var nested_depth = 1
						i += 1
						while i < body.size() and nested_depth > 0:
							var nested_line = body[i]
							var nested_stripped = nested_line.strip_edges()
							nested_lines.append(nested_stripped)
							var nested_words = nested_stripped.split(" ", false)
							if nested_words.size() > 0:
								if nested_words[0] == "if" or nested_words[0] == "for":
									nested_depth += 1
								elif nested_stripped == "fi" or nested_stripped == "done":
									nested_depth -= 1
							i += 1
						processed_body.append({"type": "block", "lines": nested_lines})
					else:
						processed_body.append({"type": "command", "line": line})
						i += 1
				
				for item_data in processed_body:
					if item_data.type == "block":
						var nested_result = await execute_block(item_data.lines, true)
						if nested_result != "": output.append(nested_result)
					else:
						var res = await _run_atomic_command(item_data.line, true)
						if res != "": output.append(res)
	
	if output.size() > 0: return "\n".join(output)
	return ""

func evaluate_condition(cond: String) -> bool:
	var exp = cond.strip_edges()
	if exp.begins_with("["): exp = exp.trim_prefix("[").trim_suffix("]").strip_edges()
	
	var cmd_sub_regex = RegEx.new()
	cmd_sub_regex.compile("\\$\\(([^)]+)\\)")
	var cmd_matches = cmd_sub_regex.search_all(exp)
	for i in range(cmd_matches.size() - 1, -1, -1):
		var m = cmd_matches[i]
		var sub_cmd = m.get_string(1)
		var sub_result = await _run_atomic_command(sub_cmd, true)
		exp = exp.erase(m.get_start(), m.get_end() - m.get_start())
		exp = exp.insert(m.get_start(), sub_result.strip_edges())
	
	var var_regex = RegEx.new(); var_regex.compile("\\$\\{(\\w+)\\}|\\$(\\w+)")
	var matches = var_regex.search_all(exp)
	for i in range(matches.size() - 1, -1, -1):
		var m = matches[i]
		var var_name = m.get_string(1) if m.get_string(1) != "" else m.get_string(2)
		exp = exp.erase(m.get_start(), m.get_end() - m.get_start())
		exp = exp.insert(m.get_start(), str(env_vars.get(var_name, "")))
	if exp.begins_with("-d "):
		var p = VFS.resolve_path(exp.get_slice(" ", 1))
		return VFS.files.has(p) and VFS.files[p].type == "dir"
	if exp.begins_with("-f "):
		var p = VFS.resolve_path(exp.get_slice(" ", 1))
		return VFS.files.has(p) and VFS.files[p].type == "file"
	if "==" in exp:
		var s = exp.split("==")
		if s.size() == 2: return s[0].strip_edges().replace('"', '') == s[1].strip_edges().replace('"', '')
	return false

func parse_single_command(cmd_text: String, is_silent: bool = false) -> String:
	var proc = cmd_text.strip_edges()
	
	# Detect Redirection
	var redirect_to = ""
	if " > " in proc:
		var r_parts = proc.split(" > ", true, 1)
		proc = r_parts[0].strip_edges()
		redirect_to = r_parts[1].strip_edges()

	# Command Substitution
	var cmd_sub_regex = RegEx.new()
	cmd_sub_regex.compile("\\$\\(([^)]+)\\)")
	var cmd_matches = cmd_sub_regex.search_all(proc)
	for i in range(cmd_matches.size() - 1, -1, -1):
		var m = cmd_matches[i]
		var sub_cmd = m.get_string(1)
		var sub_result = await _run_atomic_command(sub_cmd, true)
		proc = proc.erase(m.get_start(), m.get_end() - m.get_start())
		proc = proc.insert(m.get_start(), sub_result.strip_edges())
	
	# Variable Expansion
	var var_regex = RegEx.new(); var_regex.compile("\\$\\{(\\w+)\\}|\\$(\\w+)")
	var matches = var_regex.search_all(proc)
	for i in range(matches.size() - 1, -1, -1):
		var m = matches[i]
		var var_name = m.get_string(1) if m.get_string(1) != "" else m.get_string(2)
		proc = proc.erase(m.get_start(), m.get_end() - m.get_start())
		proc = proc.insert(m.get_start(), str(env_vars.get(var_name, "")))

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
			if output_log: output_log.clear()
			final_result = ""
		"export": 
			handle_export(args)
			final_result = ""
		"chmod": 
			execute_chmod(args)
			final_result = ""
		"ls", "mkdir", "touch", "rm", "grep", "nano", "cp", "mv": 
			final_result = await execute_syscall(tokens)
		"cat": final_result = execute_cat(args)
		"cd": final_result = execute_cd(args)
		"sh": final_result = await execute_sh(args)
		_:
			var path = find_executable(cmd)
			if path != "": final_result = await execute_sh([path] + args)
			else: final_result = "bash: " + cmd + ": command not found"

	if redirect_to != "":
		var p = VFS.resolve_path(redirect_to)
		VFS.create_file(p, final_result, "file")
		return ""
	return final_result

func execute_syscall(args: Array) -> String:
	if args.size() == 0: return ""
	var cmd = args[0]
	match cmd:
		"ls":
			var target = VFS.current_path
			if args.size() > 1: target = VFS.resolve_path(args[1])
			if not VFS.files.has(target): return "ls: cannot access '" + args[1] + "': No such directory"
			var out = []
			for p in VFS.files.keys():
				if p.begins_with(target) and p != target:
					var rel = p.trim_prefix(target).trim_prefix("/")
					if not "/" in rel:
						var data = VFS.files[p]
						var col = "#ffffff"
						if data.type == "dir": col = "#5dade2"
						elif data.get("executable", false): col = "#50fa7b"
						out.append("[color=" + col + "]" + rel + "[/color]")
			return "  ".join(out)
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
			
			if not VFS.files.has(s_path):
				return "mv: cannot stat '" + args[1] + "': No such file or directory"
			
			# If destination is an existing directory, move source INTO it
			if VFS.files.has(d_path) and VFS.files[d_path].type == "dir":
				# Manual path join: ensures no double slashes
				var file_name = s_path.get_file()
				if d_path.ends_with("/"):
					d_path = d_path + file_name
				else:
					d_path = d_path + "/" + file_name

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
		"nano":
			if editor and args.size() > 1: editor.open_file(VFS.resolve_path(args[1]), VFS)
			return ""
	return ""

func execute_sh(args: Array) -> String:
	if args.size() == 0: return ""
	var p = VFS.resolve_path(args[0])
	if VFS.files.has(p):
		if not VFS.files[p].get("executable", false): return "bash: " + args[0] + ": Permission denied"
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

func append_to_log(msg: String) -> void:
	if output_log: output_log.append_text(msg + "\n")
	await get_tree().process_frame
	if scroll_v: scroll_v.set_deferred("scroll_vertical", scroll_v.get_v_scroll_bar().max_value)

func _on_editor_saved(path: String, content: String):
	VFS.files[path].content = content
	MissionManager.check_mission_progress(3, path)

func _on_editor_closed():
	focus_loop_enabled = true; grab_focus(); MissionManager.check_mission_progress(3, "")

func _on_focus_changed(node: Control) -> void:
	if focus_loop_enabled and node != self and not (editor and editor.visible): 
		call_deferred("grab_focus")
