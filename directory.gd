extends Node

class DirectoryItem:

	var itemname: String
	var permission: Permission
	var parent: String
	var contents = null

	func _init(itemname: String, contents, permission: Permission, parent: String) -> void:

		self.itemname = itemname
		self.permission = permission
		self.parent = parent
		self.contents = contents

	func contents_string() -> String:
		return ""

	func trace() -> PackedStringArray:

		var trace: PackedStringArray = PackedStringArray([self.itemname])
		if self.parent != "ROOT":
			var curr: DirectoryItem = Directory.table[self.parent]
			while curr != null:
				trace.append(curr.itemname)
				curr = Directory.table[curr.parent]

		return trace


class Folder extends DirectoryItem:

	#var contents: PackedStringArray

	func _init(dirname: String, contents: PackedStringArray, permission: Permission, parent: String) -> void:
		super._init(dirname, contents, permission, parent)

	func contents_string() -> String:
		return " ".join(self.contents)


class File extends DirectoryItem:

	#var contents: String

	func _init(filename: String, contents: String, permission: Permission, parent: String) -> void:
		super._init(filename, contents, permission, parent)


enum Permission {
	READ,
	WRITE,
	NO_ACCESS,
}

var table = {}  # Typed dictionaries require elements
var files: FileAccess = FileAccess.open("res://files.json", FileAccess.READ)
var folders: FileAccess = FileAccess.open("res://folders.json", FileAccess.READ)
var current: Folder
var failure: DirectoryItem = DirectoryItem.new("NO ACCESS", null, 2, "")  # Returned if the operation is incomplete due to permissions

func create_directory():

	var dir = JSON.parse_string(folders.get_as_text())

	table["ROOT"] = null  # Root's "parent"

	# Create the folders
	for folder in dir:
		table[folder["name"]] = Folder.new(folder["name"], [], folder["permission"], folder["parent"])

	# Link them together
	for folder in dir:
		if folder["parent"] != "ROOT" and table.has(folder["parent"]):
			table[folder["parent"]].contents.append(folder["name"])
			table[folder["name"]].parent = folder["parent"]
		elif folder["parent"] == "ROOT" and table.has(folder["name"]):
			current = table[folder["name"]]

	var fs = JSON.parse_string(files.get_as_text())

	# Create the files; must have file extension if they share a name with a folder
	for f in fs:
		table[f["name"]] = File.new(f["name"], f["contents"], f["permission"], f["parent"])
		# Link files to parents
		table[f["parent"]].contents.append(f["name"])


func create_folder(path: PackedStringArray, permission: Permission) -> DirectoryItem:

	var parent: DirectoryItem = valid_path(path.slice(0, -1))
	var dirname: String = path[-1]

	if parent == null or parent is not Folder:
		return null
	if parent.permission != Permission.WRITE:
		return failure
	if dirname in parent.contents:
		return null

	table[dirname] = Folder.new(dirname, [], permission, parent.itemname)
	parent.contents.append(dirname)
	return table[dirname]


func create_file(path: PackedStringArray, permission: Permission) -> DirectoryItem:

	var parent: DirectoryItem = valid_path(path.slice(0, -1))
	var filename: String = path[-1]

	if parent == null or parent is not Folder:
		return null
	if parent.permission != Permission.WRITE:
		return failure
	if filename in parent.contents:
		return null

	table[filename] = File.new(filename, "", permission, parent.itemname)
	parent.contents.append(filename)
	return table[filename]


func path_exists(path: PackedStringArray) -> bool:

	var start: DirectoryItem = current
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
			var name:
				if name in start.contents:
					if table[name] is Folder:
						start = table[name]
					elif table[name] is File:
						if path[-1] == name and path_pos == len(path) - 1:  # Final elemnt in the path can be a file
							start = table[name]
						else:
							return false
				else:
					return false

		path_pos += 1

	return true


func valid_path(path: PackedStringArray) -> DirectoryItem:

	var start: DirectoryItem = current
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
			var name:
				if name in start.contents:

					if table[name].permission == Permission.NO_ACCESS:
						return failure

					if table[name] is Folder:
						start = table[name]
					elif table[name] is File:
						if path[-1] == name and path_pos == len(path) - 1:  # Final elemnt in the path can be a file
							start = table[name]
						else:
							return null
				else:
					return null

		path_pos += 1

	return start


func change_dir(path: PackedStringArray) -> int:

	var end = valid_path(path)
	if end != null and end is not File:
		if end.itemname == "NO ACCESS":
			return 2

		current = end
		return 1

	else:
		return 0


func change_permission(path: PackedStringArray, permission: Permission) -> DirectoryItem:
	return null
	#var start: DirectoryItem = current
	#var path_pos: int = 0
#
	#for folder in path:
		#match folder:
			#".":
				#start = start
			#"..":
				#if start.parent != "ROOT":
					#start = table[start.parent]
				#else:
					#return null
			#var name:
				#if name in start.contents:
#
					#if table[name].permission == Permission.NO_ACCESS:
						#return failure
#
					#if table[name] is Folder:
						#start = table[name]
					#elif table[name] is File:
						#if path[-1] == name:  # Final elemnt in the path can be a file
							#start = table[name]
				#else:
					#return failure
#
		#path_pos += 1
#
	#return start
