extends Control
# Programs are packedscenes and inherit from Program
# Each command is designed to be self-contained
# Directory simulation is separate from the Terminal UI

@export var line: PackedScene
@export var write_program: PackedScene

@export var preamble: String = "hng43@desktop:"
@export var path: String = "~"
@export var postfix: String = "$"

signal on_enter

var curr: Node = null
var program: Node = null


func _on_enter_program():

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
		["clear"]:
			clear()


func nano(file: String):

	# Fetch the directory item
	var node: Directory.DirectoryItem = fetch_item(file)

	if node == null:
		error()
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


func clear():

	curr = null
	for child in %Lines.get_children():
		child.free()


func touch(args: String):
	Directory.create_file(args.split("/"), Directory.Permission.WRITE)


func mkdir(args: String):
	Directory.create_folder(args.split("/"), Directory.Permission.WRITE)


func echo(text: Array):
	var line: String = " ".join(PackedStringArray(text.slice(1)))
	writeline(line)


func cat(dirpath: String):

	# Fetch the directory item
	var node: Directory.DirectoryItem = fetch_item(dirpath)

	if node == null:
		error()
		return

	elif node is Directory.Folder:
		writeline(node.itemname + " is a Directory")
		return

	var contents: PackedStringArray = node.contents.split("\n")
	print_debug(contents)

	for line in contents:
		writeline(line)


func cd(dirpath: String):

	var success: bool = Directory.change_dir(dirpath.split("/"))

	if not success:
		writeline("No such Directory")

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

	elif node is Directory.File:
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

		process_command(text)
		newline_with_header()
		set_focus()
