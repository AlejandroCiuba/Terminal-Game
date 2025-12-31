extends Control
# Programs are packedscenes and inherit from Program
# Each command is designed to be self-contained
# Directory simulation is separate from the Terminal UI
const MAX_DISPLAY_LENGTH = 75

var can_end: bool = false

var max_scroll: float = 0.0
const rapid_scroll_wait: float = 1.0
var rapid_scroll_press: float = 0.0
var can_rapid_scroll: bool = false

var cmd_hst: PackedStringArray = PackedStringArray(["", "cat README.txt"])
var hstind: int = 0

var curr: Node = null
var program: Node = null

@export var line: PackedScene

# Programs the terminal can access; they are split between full-screen and inline programs
@export var write_program: PackedScene
@export var password_program: PackedScene

@export var preamble: String = "hng43@desktop:"
@export var path: String = "~"
@export var postfix: String = "$"

@warning_ignore("unused_signal")
signal on_enter


func get_cmdline() -> LineEdit:
	return curr.get_child(1)


func enter_program(inline: bool = false):
	if inline:
		%Lines.add_child(program)
	else:
		%Lines.visible = false
		self.add_child(program)
	program.exited.connect(_on_exit_subprogram)
	self.set_process(false)


func _on_exit_program():
	program.exited.disconnect(_on_exit_program)
	(func (): program.free()).call_deferred()
	_on_exit_subprogram()


func _on_exit_subprogram():
	%Lines.visible = true
	set_process(true)
	set_focus()


func set_focus():
	curr.get_child(1).grab_focus()


func error():
	writeline("No such File or Directory")


func header():
	curr.get_child(0).text = preamble + path + postfix


func newline():
	if curr != null:
		curr.get_child(1).editable = false
	curr = line.instantiate()
	%Lines.add_child(curr)


func newline_with_header():
	newline()
	header()


func writeline(text: String, hdr: bool = false):
	newline()
	if hdr:
		header()
	curr.get_child(1).text = text


func fetch_item(dirpath: String) -> Directory.DirectoryItem:
	if dirpath == "":
		return Directory.current
	else:
		var split: PackedStringArray = dirpath.split("/")
		if split[0] == "~":
			return Directory.valid_path(dirpath.split("/"), true)
		else:
			return Directory.valid_path(dirpath.split("/"))


func process_command(input: Array):
	match input:
		["ls"]:
			ls("", "")
		["ls", var args]:
			if args.begins_with("-"):  # Commands assume flags have been parsed correctly by the process_command function
				ls("", args)
			else:
				ls(args, "")
		["ls", var pth, var args]:
			ls(pth, args)
		["cd", var pth]:
			cd(pth)
		["cd"]:
			cd("~")
		["cat", var pth]:
			cat(pth)
		["echo", ..]:
			echo(input)
		["mkdir", var args]:
			mkdir(args)
		["touch", var args]:
			touch(args)
		["nano", var file]:
			nano(file)
		["chmod", var file, var perms]:
			await chmod(file, perms)
		["run", var file]:
			run(file)
		["rm", var file]:
			remove(file)
		["clear"]:
			clear()


func clear():
	curr = null
	for child in %Lines.get_children():
		child.free()


func remove(file: String):
	if file != "~" or not can_end:
		writeline("Files are not removable on this operating system")
		return
		
	Manager.change_scene("res://scenes/end_screen.tscn")


func run(file: String):
	# Fetch the directory item
	var node: Directory.DirectoryItem = fetch_item(file)

	if node == null:
		writeline("File does not exist.")
		return

	elif node is Directory.Folder:
		writeline(node.itemname + " is a Directory")
		return

	elif node is Directory.File:
		writeline(node.itemname + " is a non-executable File")
		return
		
	elif node.permission == Directory.Permission.NO_ACCESS:
		writeline("No permission to run executable at location")
		return

	# Command successful, launch program
	if curr != null:
		curr.get_child(1).editable = false

	program = node.contents.instantiate()
	program.exited.connect(_on_exit_program)

	enter_program()


func chmod(file: String, perms: String):

	program = password_program.instantiate()
	enter_program(true)
	var pwd: String = await program.password

	var num_perm: int = 0
	if perms == "READ":
		num_perm = Directory.Permission.READ
	elif perms == "WRITE":
		num_perm = Directory.Permission.WRITE
	elif perms == "NO_ACCESS":
		num_perm = Directory.Permission.NO_ACCESS
	else:
		writeline("Permission type does not exist")
		return

	var node: Directory.DirectoryItem = Directory.change_permission(file.split("/"), num_perm, pwd)

	if node == null:
		writeline("File or Directory does not exist")
	elif node.permission == Directory.Permission.NO_ACCESS:
		writeline("Incorrect Permissions")
	else:
		writeline("Permissions changed")
		if node.itemname == "cat-bag.txt":  # Triggers win condition
			can_end = true


func nano(file: String):

	# Fetch the directory item
	var node: Directory.DirectoryItem = fetch_item(file)

	if node == null:

		touch(file)
		node = fetch_item(file)

		if node == null:
			writeline("File could not be created.")
			return

	elif node is Directory.Folder:
		writeline(node.itemname + " is a Directory")
		return
	
	elif node.permission == Directory.Permission.NO_ACCESS:
		writeline("No permission to edit file")
		return

	# Command successful, launch program
	if curr != null:
		curr.get_child(1).editable = false

	program = write_program.instantiate()
	program.file = node

	enter_program()


func touch(args: String):

	var split: PackedStringArray = args.split("/")
	var file: Directory.DirectoryItem = null

	if split[0] == "~":
		file = Directory.create_file(split, Directory.Permission.WRITE, true)
	else:
		file = Directory.create_file(split, Directory.Permission.WRITE)

	if file == null:
		writeline("Operation Failed.")
	elif file.permission == Directory.Permission.NO_ACCESS:
		writeline("No permission to make file at location")


func mkdir(args: String):

	var split: PackedStringArray = args.split("/")
	var folder: Directory.DirectoryItem = null

	if split[0] == "~":
		folder = Directory.create_folder(split, Directory.Permission.WRITE, true)
	else:
		folder = Directory.create_folder(split, Directory.Permission.WRITE)

	if folder == null:
		writeline("Operation Failed.")
	elif folder.permission == Directory.Permission.NO_ACCESS:
		writeline("No permission to make Directory at location")


func echo(text: Array):
	var ln: String = " ".join(PackedStringArray(text.slice(1)))
	writeline(ln)


func cat(dirpath: String):

	# Fetch the directory item
	var node: Directory.DirectoryItem = fetch_item(dirpath)

	if node == null:
		error()
		return

	if node.permission == Directory.Permission.NO_ACCESS:
		writeline("No permission to view file contents")
		return

	if node is Directory.Folder:
		writeline(node.itemname + " is a Directory")
		return

	var contents: PackedStringArray = node.contents.split("\n")
	print_debug(contents)

	var display: TextEdit = TextEdit.new()
	display.theme = load("res://common/style/terminal.tres")
	display.editable = false
	display.text = "\n".join(contents)
	display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	display.scroll_fit_content_height = true
	display.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	%Lines.add_child(display)


func cd(dirpath: String):

	var split: PackedStringArray = dirpath.split("/")
	var node: Directory.DirectoryItem
	if split[0] == "~":
		node = Directory.change_dir(split, true)
	else:
		node = Directory.change_dir(split)

	if node == null:
		writeline("No such Directory")
	elif node.permission == Directory.Permission.NO_ACCESS:
		writeline("No permission to enter Directory")
	else:
		var trace: PackedStringArray = Directory.current.trace()
		trace.reverse()
		path = "/".join(trace)


func ls(dirpath: String, args: String):

	# Fetch the directory item
	var node: Directory.DirectoryItem = fetch_item(dirpath)

	if node == null:
		error()
		return

	if node.permission == Directory.Permission.NO_ACCESS:
		writeline("No permission to view contents")
		return

	if node is Directory.File:
		writeline(node.itemname)
		return

	var text: String = ""
	var index: int = 0

	if "l" in args:
		
		var contents: Dictionary = Directory.get_contents_metadata(node)
		var max_count: int = contents.keys().map(func (item): return len(item)).max()
		var spaces: int = max_count if max_count > 8 else 8
		# TABS DON'T WORK IN LINEEDIT
		writeline("Permission        Name\tType".replace("\t", " ".repeat(spaces + 4)))
		for item in contents:
			text = ("%d\t1%s\t2%s" % [contents[item][0], item, contents[item][1]])\
			.replace("\t1", " ".repeat(21)).replace("\t2", " ".repeat(spaces - len(item) + 7))
			writeline(text)

	else:

		var contents: Array = node.contents
		for item in contents:

			print_debug(item)
			text += " " + item
			index += 1

			if index % 3 == 0 or index == len(contents):
				writeline(text)
				text = ""


func _on_scrollbar_changed():
	if max_scroll != %ScrollContainer.get_v_scroll_bar().max_value:
		max_scroll = %ScrollContainer.get_v_scroll_bar().max_value
		%ScrollContainer.scroll_vertical = max_scroll


func _ready() -> void:
	Directory.create_directory()
	#newline_with_header()
	writeline("cat README.txt", true)
	set_focus()
	# https://www.reddit.com/r/godot/comments/qhbi8y/how_to_scroll_a_scrollcontainer_to_the_bottom/
	%ScrollContainer.get_v_scroll_bar().changed.connect(_on_scrollbar_changed)
	max_scroll = %ScrollContainer.get_v_scroll_bar().max_value
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_caret_up") or (event.is_action("ui_text_caret_up") and can_rapid_scroll):
		hstind = (hstind - 1) % len(cmd_hst)
		get_cmdline().text = cmd_hst[hstind]
		get_cmdline().caret_column = get_cmdline().text.length()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_text_caret_down") or (event.is_action("ui_text_caret_down") and can_rapid_scroll):
		hstind = (hstind + 1) % len(cmd_hst)
		get_cmdline().text = cmd_hst[hstind]
		get_cmdline().caret_column = get_cmdline().text.length()
		get_viewport().set_input_as_handled()


# _process over _input for set_focus()
func _process(delta: float) -> void:
	
	if Input.is_action_pressed("ui_text_caret_up") or Input.is_action_pressed("ui_text_caret_down"):
		rapid_scroll_press += delta
	elif Input.is_action_just_released("ui_text_caret_up") or Input.is_action_just_released("ui_text_caret_up"):
		can_rapid_scroll = false
		rapid_scroll_press = 0
	if rapid_scroll_press >= rapid_scroll_wait:
		can_rapid_scroll = true

	if Input.is_action_just_pressed("new_line"):
		cmd_hst.append(curr.get_child(1).text)
		var text = Array(curr.get_child(1).text.split(" "))
		await process_command(text)
		newline_with_header()
		set_focus()
		
