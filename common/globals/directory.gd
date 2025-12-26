extends Node

class DirectoryItem:

	var itemname: String
	var permission: Permission
	var parent: String
	var contents = null
	var password: String

	@warning_ignore("shadowed_variable")
	func _init(itemname: String, contents, permission: Permission, parent: String, password: String) -> void:

		self.itemname = itemname
		self.permission = permission
		self.parent = parent
		self.contents = contents
		self.password = password

	func contents_string() -> String:
		return ""

	func trace() -> PackedStringArray:
		var trc: PackedStringArray = PackedStringArray([self.itemname])
		if self.parent != "ROOT":
			var curr: DirectoryItem = Directory.table[self.parent]
			while curr != null:
				trc.append(curr.itemname)
				curr = Directory.table[curr.parent]

		return trc


class Folder extends DirectoryItem:

	#var _contents: PackedStringArray

	@warning_ignore("shadowed_variable_base_class")
	func _init(dirname: String, contents: PackedStringArray, permission: Permission, parent: String, password: String) -> void:
		super._init(dirname, contents, permission, parent, password)

	func contents_string() -> String:
		return " ".join(self.contents)


class File extends DirectoryItem:

	#var _contents: String

	@warning_ignore("shadowed_variable_base_class")
	func _init(filename: String, contents: String, permission: Permission, parent: String, password: String) -> void:
		super._init(filename, contents, permission, parent, password)


enum Permission {
	NO_ACCESS,
	READ,
	WRITE,
}

# JSON to get simulation data
var files: FileAccess = FileAccess.open("res://common/data/files.json", FileAccess.READ)
var folders: FileAccess = FileAccess.open("res://common/data/folders.json", FileAccess.READ)

# File system is a dictionary that the user access as if it were a tree
var table = {}  # Typed dictionaries require elements
var current: Folder  # Node the file system is focused on
var home: Folder  # The root folder

var pseudo_root: Folder  # A fake folder whose child is the root folder (but root's parent is null); makes tracing easier
var failure: DirectoryItem = DirectoryItem.new("NO_ACCESS", null, Permission.NO_ACCESS, "", "")  # Returned if the operation is incomplete due to permissions


func create_directory():

	var dir = JSON.parse_string(folders.get_as_text())

	table["ROOT"] = null  # Root's "parent"

	# Create the folders
	for folder in dir:
		table[folder["name"]] = Folder.new(folder["name"], [], folder["permission"], folder["parent"], folder["password"])

	# Link them together
	for folder in dir:
		if folder["parent"] != "ROOT" and table.has(folder["parent"]):
			table[folder["parent"]].contents.append(folder["name"])
			table[folder["name"]].parent = folder["parent"]
		elif folder["parent"] == "ROOT" and table.has(folder["name"]):
			current = table[folder["name"]]
			home = current
			pseudo_root = Folder.new("PSEUDO", [folder["name"]], Permission.READ, "", "")

	var fs = JSON.parse_string(files.get_as_text())

	# Create the files; must have file extension if they share a name with a folder
	for f in fs:
		table[f["name"]] = File.new(f["name"], f["contents"], f["permission"], f["parent"], f["password"])
		# Link files to parents
		table[f["parent"]].contents.append(f["name"])


## Returns the item if successful, the failure DirectoryItem if no permissions, and null otherwise
func create_folder(path: PackedStringArray, permission: Permission, absolute: bool = false) -> DirectoryItem:

	var parent: DirectoryItem = valid_path(path.slice(0, -1), absolute)
	var dirname: String = path[-1]

	if parent == null or parent is not Folder:
		return null
	if parent.permission != Permission.WRITE:
		return failure
	if dirname in parent.contents:
		return null

	table[dirname] = Folder.new(dirname, [], permission, parent.itemname, "")
	parent.contents.append(dirname)
	return table[dirname]


## Returns the item if successful, the failure DirectoryItem if no permissions, and null otherwise
func create_file(path: PackedStringArray, permission: Permission, absolute: bool = false) -> DirectoryItem:

	var parent: DirectoryItem = valid_path(path.slice(0, -1), absolute)
	var filename: String = path[-1]

	if parent == null or parent is not Folder:
		return null
	if parent.permission != Permission.WRITE:
		return failure
	if filename in parent.contents:
		return null

	table[filename] = File.new(filename, "", permission, parent.itemname, "")
	parent.contents.append(filename)
	return table[filename]


## Ignores file permissions; returns true if the path exists.
func path_exists(path: PackedStringArray, absolute: bool = false) -> bool:

	var start: DirectoryItem = null
	if absolute:
		start = pseudo_root  # Start at pseudo_root since we check the current folder's children
	else:
		start = current

	var path_pos: int = 0
	for folder in path:
		match folder:
			".":
				start = start
			"..":
				if start.parent != "ROOT":
					start = table[start.parent]
				else:
					return false
			var folder_name:
				if folder_name in start.contents:
					if table[folder_name] is Folder:
						start = table[folder_name]
					elif table[folder_name] is File:
						if path[-1] == folder_name and path_pos == len(path) - 1:  # Final elemnt in the path can be a file
							start = table[folder_name]
						else:
							return false
				else:
					return false

		path_pos += 1

	return true


## Returns the node if accessible (checks permissions); returns null if the node does not exist; returns failure node if no permissions.
func valid_path(path: PackedStringArray, absolute: bool = false) -> DirectoryItem:

	var start: DirectoryItem = null
	if absolute:
		start = pseudo_root
	else:
		start = current

	var path_pos: int = 0
	for folder in path:
		match folder:
			".":
				start = start
			"..":
				if start.parent != "ROOT":
					start = table[start.parent]
				else:
					return null
			var folder_name:
				if folder_name in start.contents:

					if table[folder_name].permission == Permission.NO_ACCESS:
						return failure

					if table[folder_name] is Folder:
						start = table[folder_name]
					elif table[folder_name] is File:
						if path[-1] == folder_name and path_pos == len(path) - 1:  # Final elemnt in the path can be a file
							start = table[folder_name]
						else:
							return null
				else:
					return null

		path_pos += 1

	return start


## Returns the item if successful, the failure DirectoryItem if no permissions, and null otherwise
func change_dir(path: PackedStringArray, absolute: bool = false) -> DirectoryItem:
	var end = valid_path(path, absolute)
	if end != null:
		if end.permission != Permission.NO_ACCESS:
			current = end
	return end


func change_permission(path: PackedStringArray, permission: Permission, password: String, absolute: bool = false) -> DirectoryItem:

	var start: DirectoryItem = null
	if absolute:
		start = pseudo_root
	else:
		start = current

	var path_pos: int = 0
	for folder in path:
		match folder:
			".":
				start = start
			"..":
				if start.parent != "ROOT":
					start = table[start.parent]
				else:
					return null
			var folder_name:
				if folder_name in start.contents:

					if table[folder_name].permission == Permission.NO_ACCESS and path_pos < len(path) - 1:
						return failure

					if table[folder_name] is Folder:
						start = table[folder_name]
					elif table[folder_name] is File:
						if path[-1] == folder_name and path_pos == len(path) - 1:  # Final elemnt in the path can be a file
							start = table[folder_name]
						else:
							return null
				else:
					return null

		path_pos += 1

	if password == start.password:
		start.permission = permission
	else:
		return failure

	return start


## Returns the metadata of the children for a specific node as a Dictionary
func get_contents_metadata(node: Folder) -> Dictionary:

	var contents: Dictionary = {}
	for item in node.contents:

		var diritem: DirectoryItem = table[item]

		if diritem is Folder:
			contents[item] = [diritem.permission, "Folder"]
		elif diritem is File:
			contents[item] = [diritem.permission, "File"]

	return contents
