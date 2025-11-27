extends Control
# Programs are packedscenes and inherit from Program
# Each command is designed to be self-contained
# Directory simulation is separate from the Terminal UI

@export var line: PackedScene
@export var write_program: PackedScene
@export var password_program: PackedScene

@export var preamble: String = "hng43@desktop:"
@export var path: String = "~"
@export var postfix: String = "$"

signal on_enter

var curr: Node = null
var program: Node = null


func _on_enter_program(inline: bool = false):

	if inline:
		%Lines.add_child(program)
	else:
		%Lines.visible = false
		self.add_child(program)

	program.exited.connect(_on_exit_subprogram)
	self.set_process(false)


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


func writeline(text: String, header: bool = false):

	newline()
	if header:
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
			ls("")
		["ls", var path]:
			ls(path)
		["cd", var path]:
			cd(path)
		["cat", var path]:
			cat(path)
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
		["clear"]:
			clear()


func clear():

	curr = null
	for child in %Lines.get_children():
		child.free()


func chmod(file: String, perms: String):

	program = password_program.instantiate()
	_on_enter_program(true)
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
	elif node.itemname == "NO ACCESS":
		writeline("Incorrect Permissions")
	else:
		writeline("Permissions changed")


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

	# Command successful, launch program
	if curr != null:
		curr.get_child(1).editable = false

	program = write_program.instantiate()
	program.file = node

	_on_enter_program()


func touch(args: String):

	var split: PackedStringArray = args.split("/")
	var file: Directory.DirectoryItem = null

	if split[0] == "~":
		file = Directory.create_file(split, Directory.Permission.WRITE, true)
	else:
		file = Directory.create_file(split, Directory.Permission.WRITE)

	if file == null:
		writeline("Operation Failed.")
	elif file.itemname == "NO ACCESS":
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
	elif folder.itemname == "NO ACCESS":
		writeline("No permission to make Directory at location")


func echo(text: Array):
	var line: String = " ".join(PackedStringArray(text.slice(1)))
	writeline(line)


func cat(dirpath: String):

	# Fetch the directory item
	var node: Directory.DirectoryItem = fetch_item(dirpath)

	if node == null:
		error()
		return

	if node.itemname == "NO ACCESS":
		writeline("No permission to view file contents")
		return

	if node is Directory.Folder:
		writeline(node.itemname + " is a Directory")
		return

	var contents: PackedStringArray = node.contents.split("\n")
	print_debug(contents)

	for line in contents:
		writeline(line)


func cd(dirpath: String):

	var split: PackedStringArray = dirpath.split("/")
	var success: int = -1
	if split[0] == "~":
		success = Directory.change_dir(split, true)
	else:
		success = Directory.change_dir(split)

	if success == 0:
		writeline("No such Directory")
	elif success == 2:
		writeline("No permission to enter Directory")

	else:
		var trace: PackedStringArray = Directory.current.trace()
		trace.reverse()
		path = "/".join(trace)


func ls(dirpath: String):

	# Fetch the directory item
	var node: Directory.DirectoryItem = fetch_item(dirpath)

	if node == null:
		error()
		return

	if node.itemname == "NO ACCESS":
		writeline("No permission to view contents")
		return

	if node is Directory.File:
		writeline(node.itemname)
		return

	var contents: Array = node.contents
	var text: String = ""
	var index: int = 0
	for item in contents:

		print_debug(item)
		text += " " + item
		index += 1

		if index % 3 == 0 or index == len(contents):
			writeline(text)
			text = ""


func _ready() -> void:

	Directory.create_directory()
	newline_with_header()
	set_focus()


func _process(delta: float) -> void:

	if Input.is_action_just_pressed("new_line"):

		var text = Array(curr.get_child(1).text.split(" "))

		await process_command(text)
		newline_with_header()
		set_focus()
