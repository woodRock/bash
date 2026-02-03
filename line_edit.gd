extends LineEdit

@onready var output_log = %RichTextLabel
@onready var VFS_scene: PackedScene = preload("res://virtual_file_system.tscn")

var VFS 
var focus_loop_enabled = false
var env_vars = {
	"USER": "jesse_wood", 
	"PWD": "/", 
	"PATH": "/bin",
	"PROMPT": "[color=#00FF41]user@gatekeeper[/color]"
}

var block_buffer = []
var nesting_depth = 0

func _ready() -> void:
	VFS = VFS_scene.instantiate()
	get_tree().root.call_deferred("add_child", VFS) 
	text_submitted.connect(_on_command_submitted)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)

func _on_command_submitted(new_text: String) -> void:
	var line = new_text.strip_edges()
	if nesting_depth == 0:
		append_to_log(env_vars["PROMPT"] + ":" + VFS.current_path + "$ " + line)
	else:
		append_to_log("> " + line)
	await process_input_line(line)
	text = ""; deselect(); editable = true; caret_column = 0
	await get_tree().create_timer(0.01).timeout
	grab_focus()

func process_input_line(line: String, is_silent: bool = false) -> String:
	var clean_line = line.strip_edges()
	if clean_line == "" or clean_line.begins_with("#"): return ""
	var is_start = clean_line.begins_with("if ") or clean_line.begins_with("for ")
	var is_end = clean_line == "fi" or clean_line == "done"
	if is_start: nesting_depth += 1
	if is_end: nesting_depth -= 1

	var result = ""
	if nesting_depth > 0 or is_end:
		block_buffer.append(clean_line)
		if nesting_depth == 0:
			var full_block = block_buffer.duplicate()
			block_buffer.clear()
			result = await execute_block(full_block, true)
	else:
		result = await parse_single_command(clean_line, is_silent)

	if not is_silent and result != "" and nesting_depth == 0:
		append_to_log(result)
	return result

func execute_block(lines: Array, is_silent: bool = false) -> String:
	var header = lines[0]
	var body = lines.slice(1, -1) 
	var collective_output = []
	if header.begins_with("if"):
		var condition = header.get_slice("[", 1).get_slice("]", 0).strip_edges()
		var condition_passed = evaluate_condition(condition)
		var run_current_branch = condition_passed
		for line in body:
			var clean_line = line.strip_edges()
			if clean_line == "then": continue
			if clean_line == "else":
				run_current_branch = !condition_passed
				continue
			if run_current_branch:
				var res = await process_input_line(line, true)
				if res != "": collective_output.append(res)
	elif header.begins_with("for"):
		var parts = header.split(" ", false)
		var var_name = parts[1]
		var items = parts.slice(3)
		for item in items:
			env_vars[var_name] = item
			for line in body:
				if line.strip_edges() == "do": continue
				var res = await process_input_line(line, true)
				if res != "": collective_output.append(res)
	return "\n".join(collective_output)

func parse_single_command(cmd_text: String, is_silent: bool = false) -> String:
	var processed_text = cmd_text.strip_edges()
	if processed_text.begins_with("#!"): return ""
	var locally_silent = is_silent
	if "> /dev/null" in processed_text:
		locally_silent = true
		processed_text = processed_text.replace("> /dev/null", "").strip_edges()

	# 1. Substitution $(cmd)
	var sub_regex = RegEx.new()
	sub_regex.compile("\\$\\((.*?)\\)")
	var sub_match = sub_regex.search(processed_text)
	while sub_match:
		var inner_cmd = sub_match.get_string(1)
		var sub_result = await process_input_line(inner_cmd, true)
		processed_text = processed_text.replace(sub_match.get_string(0), sub_result.strip_edges())
		sub_match = sub_regex.search(processed_text)

	# 2. Variable Expansion $VAR
	for key in env_vars.keys():
		processed_text = processed_text.replace("$" + key, str(env_vars[key]))

	# 3. Regex Tokenizing (The Advanced approach)
	var regex = RegEx.new()
	regex.compile("\"([^\"]*)\"|'([^']*)'|([^\\s]+)")
	var clean_tokens = []
	for m in regex.search_all(processed_text):
		var t = m.get_string(1) if m.get_string(1) != "" else (m.get_string(2) if m.get_string(2) != "" else m.get_string(3))
		if t.ends_with(";"): t = t.substr(0, t.length() - 1)
		if t != "": clean_tokens.append(t)

	if clean_tokens.size() == 0: return ""
	var cmd = clean_tokens[0].to_lower()
	var args = clean_tokens.slice(1)
	
	match cmd:
		"echo": return " ".join(args)
		"whoami": return env_vars["USER"]
		"pwd": return VFS.current_path
		"ls": return execute_ls()
		"cat": return execute_cat(args)
		"touch": execute_touch(args); return ""
		"chmod": execute_chmod(args); return ""
		"syscall": return await execute_syscall(args)
		"sleep": await get_tree().create_timer(args[0].to_float() if args.size() > 0 else 1.0).timeout; return ""
		"nano": await execute_nano(args); return ""
		"cd": execute_cd(args); return ""
		"export": handle_export(args); return ""
		"clear": output_log.clear(); return ""
		"sh": return await execute_sh(args, true) 
		_:
			var script_path = find_executable(cmd)
			if script_path != "": return await execute_sh([script_path] + args, true)
			return "bash: " + cmd + ": command not found"

# --- System Bridge ---

func execute_syscall(args: Array) -> String:
	if args.size() < 2: return "syscall: missing arguments"
	var action = args[0]
	var path = VFS.resolve_path(args[1])
	match action:
		"mkdir": if not VFS.files.has(path): VFS.files[path] = {"type": "dir"}
		"rm":
			if VFS.files.has(path) and path != "/":
				var keys = VFS.files.keys()
				for k in keys: if k.begins_with(path): VFS.files.erase(k)
		"cp", "mv":
			if args.size() < 3: return "syscall error"
			var src = VFS.resolve_path(args[1])
			var dst = VFS.resolve_path(args[2])
			if VFS.files.has(src):
				VFS.files[dst] = VFS.files[src].duplicate()
				if action == "mv": VFS.files.erase(src)
		"grep":
			if args.size() < 3: return ""
			var pattern = args[1].to_lower()
			var target = VFS.resolve_path(args[2])
			if VFS.files.has(target):
				var content = VFS.files[target].get("content", "")
				var matches = []
				for line in content.split("\n"):
					if pattern in line.to_lower(): matches.append(line)
				return "\n".join(matches)
	return ""

func find_executable(cmd: String) -> String:
	var local = VFS.resolve_path(cmd)
	if VFS.files.has(local): return local
	for p in env_vars["PATH"].split(":", false):
		var target = VFS.resolve_path(p + "/" + cmd)
		if VFS.files.has(target): return target
	return ""

func execute_chmod(args: Array):
	if args.size() < 2: return
	var path = VFS.resolve_path(args[1])
	if VFS.files.has(path) and args[0].ends_with("x"): VFS.files[path]["executable"] = true

func execute_sh(args: Array, is_silent: bool = false) -> String:
	var path = VFS.resolve_path(args[0])
	if VFS.files.has(path):
		if not VFS.files[path].get("executable", false): return "Permission denied"
		var old_p = VFS.current_path; var old_e = env_vars.duplicate()
		for i in range(args.size()-1): env_vars[str(i+1)] = args[i+1]
		var results = []
		for line in VFS.files[path].content.split("\n", false):
			var res = await process_input_line(line, is_silent)
			if res != "": results.append(res)
		VFS.current_path = old_p; env_vars = old_e
		return "\n".join(results)
	return "sh: not found"

func execute_ls():
	var out = []
	for p in VFS.files.keys():
		if p.begins_with(VFS.current_path) and p != VFS.current_path:
			var rel = p.trim_prefix(VFS.current_path).trim_prefix("/")
			if not "/" in rel:
				var col = "#5dade2" if VFS.files[p].type == "dir" else ("#50fa7b" if VFS.files[p].get("executable") else "#ffffff")
				out.append("[color=" + col + "]" + rel + ("/" if VFS.files[p].type == "dir" else "") + "[/color]")
	return "  ".join(out)

func execute_cat(args):
	var p = VFS.resolve_path(args[0]) if args.size() > 0 else ""
	return VFS.files[p].get("content", "") if VFS.files.has(p) else "cat: error"

func execute_cd(args):
	var p = VFS.resolve_path(args[0] if args.size() > 0 else "/")
	if VFS.files.has(p) and VFS.files[p].type == "dir": VFS.current_path = p

func execute_touch(args):
	var p = VFS.resolve_path(args[0])
	if not VFS.files.has(p): VFS.files[p] = {"type": "file", "content": "", "executable": false}

func handle_export(args):
	var pair = " ".join(args).split("=", true, 1)
	if pair.size() == 2: env_vars[pair[0]] = pair[1].strip_edges().replace('"', '').replace("'", "")

func execute_nano(args):
	var p = VFS.resolve_path(args[0])
	if not VFS.files.has(p): execute_touch(args)
	var ed = get_tree().root.find_child("Editor", true, false)
	if ed:
		focus_loop_enabled = false; ed.open_file(p, VFS)
		await ed.editor_closed; focus_loop_enabled = true; grab_focus()

func append_to_log(msg):
	output_log.append_text(msg + "\n")
	await get_tree().process_frame
	output_log.scroll_to_line(output_log.get_line_count())

func _on_focus_changed(node):
	if focus_loop_enabled and node != self: call_deferred("grab_focus")
