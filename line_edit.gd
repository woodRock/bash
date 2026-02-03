extends LineEdit

# --- SIGNALS ---
signal command_executed(command_text, response_text)

# --- NODES & SCENES ---
@onready var output_log = %RichTextLabel
@onready var VFS_scene: PackedScene = preload("res://virtual_file_system.tscn")

# --- KERNEL STATE ---
var VFS 
var focus_loop_enabled = false
var cmd_history = [] 
var env_vars = {
	"USER": "jesse_wood", 
	"PWD": "/home/jesse", 
	"PATH": "/bin", 
	"PROMPT": "[color=#00FF41]user@gatekeeper[/color]"
}

# Block Parsing State
var block_buffer = []
var nesting_depth = 0
var boot_screen_timer: float = 4.0

func _ready() -> void:
	VFS = VFS_scene.instantiate()
	get_tree().root.add_child.call_deferred(VFS) 
	
	# Initial Sync
	VFS.current_path = env_vars["PWD"]
	
	text_submitted.connect(_on_command_submitted)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
	await get_tree().process_frame
	await get_tree().create_timer(boot_screen_timer).timeout 
	
	focus_loop_enabled = true
	# Subshell ensures boot tests don't leave the user in /bin
	await process_input_line("sh /.bashrc")
	grab_focus()

func _on_command_submitted(new_text: String) -> void:
	var line = new_text.strip_edges()
	if line == "": return
	
	if nesting_depth == 0:
		cmd_history.append(line)
		append_to_log(env_vars["PROMPT"] + ":" + VFS.current_path + "$ " + line)
	else:
		append_to_log("> " + line)
		
	var result = await process_input_line(line)
	command_executed.emit(line, result)
	
	text = ""; grab_focus()

func _gui_input(event: InputEvent) -> void:
	var scroll_container = output_log.get_parent() as ScrollContainer
	if not scroll_container: return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_PAGEUP:
				scroll_container.scroll_vertical -= 250
				get_viewport().set_input_as_handled()
			KEY_PAGEDOWN:
				scroll_container.scroll_vertical += 250
				get_viewport().set_input_as_handled()

func process_input_line(line: String, is_silent: bool = false) -> String:
	var clean_line = line.strip_edges()
	if clean_line == "" or clean_line.begins_with("#"): return ""
	
	var words = clean_line.split(" ")
	var is_start = words[0] == "if" or words[0] == "for"
	var is_end = clean_line == "fi" or clean_line == "done"
	
	if is_start: nesting_depth += 1
	
	var result = ""
	if nesting_depth > 0 or is_end:
		if is_end: nesting_depth = max(0, nesting_depth - 1)
		block_buffer.append(clean_line)
		
		if nesting_depth == 0:
			var full_block = block_buffer.duplicate(); block_buffer.clear()
			result = await execute_block(full_block, true)
	else:
		result = await parse_single_command(clean_line, is_silent)

	if not is_silent and result != "" and nesting_depth == 0:
		append_to_log(result)
	return result

func execute_block(lines: Array, is_silent: bool = false) -> String:
	var header = lines[0]; var body = lines.slice(1, -1); var output = []
	if header.begins_with("if"):
		var condition = header.get_slice("[", 1).get_slice("]", 0).strip_edges()
		var run = evaluate_condition(condition)
		for line in body:
			var cl = line.strip_edges()
			if cl == "then" or cl == "do": continue
			if cl == "else": run = !run; continue
			if run:
				var res = await process_input_line(line, true)
				if res != "": output.append(res)
	elif header.begins_with("for"):
		var parts = header.split(" ", false); var var_name = parts[1]; var items = parts.slice(3)
		for item in items:
			env_vars[var_name] = item
			for line in body:
				if line.strip_edges() == "do": continue
				var res = await process_input_line(line, true)
				if res != "": output.append(res)
	return "\n".join(output)

func parse_single_command(cmd_text: String, is_silent: bool = false) -> String:
	var proc = cmd_text.strip_edges()
	
	var sub_regex = RegEx.new(); sub_regex.compile("\\$\\((.*?)\\)")
	var sub_match = sub_regex.search(proc)
	while sub_match:
		var sub_res = await process_input_line(sub_match.get_string(1), true)
		proc = proc.replace(sub_match.get_string(0), sub_res.strip_edges())
		sub_match = sub_regex.search(proc)
	
	for key in env_vars.keys():
		proc = proc.replace("$" + key, str(env_vars[key]))

	var regex = RegEx.new(); regex.compile("\"([^\"]*)\"|'([^']*)'|([^\\s]+)")
	var tokens = []
	for m in regex.search_all(proc):
		var t = m.get_string(1) if m.get_string(1) != "" else (m.get_string(2) if m.get_string(2) != "" else m.get_string(3))
		if t.ends_with(";"): t = t.substr(0, t.length() - 1)
		tokens.append(t)
	
	if tokens.size() == 0: return ""
	var cmd = tokens[0].to_lower(); var args = tokens.slice(1)
	
	match cmd:
		"echo": return " ".join(args)
		"whoami": return env_vars["USER"]
		"pwd": return VFS.current_path
		"history": return "\n".join(cmd_history)
		"clear": output_log.clear(); return ""
		"export": handle_export(args); return ""
		"chmod": execute_chmod(args); return ""
		"ls", "mkdir", "touch", "rm", "grep": return await execute_syscall(tokens)
		"cat": return execute_cat(args)
		"cd": return execute_cd(args)
		"sh": return await execute_sh(args)
		"syscall": return await execute_syscall(args)
		_:
			var path = find_executable(cmd)
			if path != "": return await execute_sh([path] + args)
			return "bash: " + cmd + ": command not found"

func execute_sh(args: Array) -> String:
	if args.size() == 0: return ""
	var p = VFS.resolve_path(args[0])
	if VFS.files.has(p):
		if not VFS.files[p].get("executable", false):
			return "bash: " + args[0] + ": Permission denied"
			
		var prev_pwd = VFS.current_path
		var prev_env = env_vars.duplicate()
		
		var outputs = []
		var content = VFS.files[p].get("content", "")
		for line in content.split("\n", false):
			var res = await process_input_line(line, true)
			if res != "" and res != null: outputs.append(res)
			
		VFS.current_path = prev_pwd
		env_vars = prev_env
		return "\n".join(outputs)
	return "sh: " + args[0] + ": not found"

func execute_syscall(args: Array) -> String:
	if args.size() == 0: return ""
	match args[0]:
		"ls":
			var out = []
			var show_hidden = false
			for arg in args:
				if arg == "-a": show_hidden = true
			
			for p in VFS.files.keys():
				if p.begins_with(VFS.current_path) and p != VFS.current_path:
					var rel = p.trim_prefix(VFS.current_path).trim_prefix("/")
					if not "/" in rel:
						if rel.begins_with(".") and not show_hidden: continue
						var is_dir = VFS.files[p].type == "dir"
						var col = "#5dade2" if is_dir else "#ffffff"
						out.append("[color=" + col + "]" + rel + ("/" if is_dir else "") + "[/color]")
			return "  ".join(out)
			
		"mkdir":
			if args.size() < 2: return "mkdir: missing operand"
			var p = VFS.resolve_path(args[1])
			VFS.files[p] = {"type": "dir", "executable": true, "content": ""}
			return ""
			
		"touch":
			if args.size() < 2: return "touch: missing file operand"
			var p = VFS.resolve_path(args[1])
			if not VFS.files.has(p):
				VFS.files[p] = {"type": "file", "executable": false, "content": ""}
			return ""
			
		"rm":
			if args.size() < 2: return "rm: missing operand"
			var p = VFS.resolve_path(args[1])
			if VFS.files.has(p):
				VFS.files.erase(p)
				return ""
			return "rm: cannot remove '" + args[1] + "': No such file"
			
		"grep":
			if args.size() < 3: return "usage: grep [pattern] [file]"
			var pat = args[1].to_lower(); var p = VFS.resolve_path(args[2])
			if VFS.files.has(p):
				var matches = []
				for l in VFS.files[p].get("content", "").split("\n"):
					if pat in l.to_lower(): matches.append(l)
				return "\n".join(matches)
	return ""

func execute_cat(args: Array) -> String:
	if args.size() == 0: return ""
	var p = VFS.resolve_path(args[0])
	if VFS.files.has(p):
		if VFS.files[p].type == "dir": return "cat: " + args[0] + ": Is a directory"
		return VFS.files[p].get("content", "")
	return "cat: " + args[0] + ": No such file"

func execute_cd(args: Array) -> String:
	var target = args[0] if args.size() > 0 else "/home/jesse"
	var p = VFS.resolve_path(target)
	if VFS.files.has(p) and VFS.files[p].type == "dir":
		VFS.current_path = p
		env_vars["PWD"] = p
		return ""
	return "cd: " + target + ": No such directory"

func execute_chmod(args: Array):
	if args.size() < 2: return
	var path = VFS.resolve_path(args[1])
	if VFS.files.has(path) and "+x" in args[0]:
		VFS.files[path]["executable"] = true

func find_executable(cmd: String) -> String:
	for p in env_vars["PATH"].split(":", false):
		var target = VFS.resolve_path(p + "/" + cmd)
		if VFS.files.has(target): return target
	return ""

func handle_export(args: Array):
	var pair = " ".join(args).split("=", true, 1)
	if pair.size() == 2:
		env_vars[pair[0]] = pair[1].strip_edges().replace('"', '').replace("'", "")

func evaluate_condition(cond: String) -> bool:
	var exp = cond
	for k in env_vars.keys(): exp = exp.replace("$" + k, str(env_vars[k]))
	if "==" in exp:
		var s = exp.split("==")
		return s[0].strip_edges().replace('"', '') == s[1].strip_edges().replace('"', '')
	return false

func append_to_log(msg: String) -> void:
	output_log.append_text(msg + "\n")
	await get_tree().process_frame
	
	var scroll_container = output_log.get_parent() as ScrollContainer
	if scroll_container:
		var v_bar = scroll_container.get_v_scroll_bar()
		scroll_container.set_deferred("scroll_vertical", v_bar.max_value)

func _on_focus_changed(node: Control) -> void:
	if focus_loop_enabled and node != self: call_deferred("grab_focus")
