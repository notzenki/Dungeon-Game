extends Control

const LVL_BTN = preload("res://scene/lvl_btn.tscn")

@export_dir var dir_path
@onready var grid = $FlowContainer

func select_name(level_name: String):
	var final_name
	var extention = '.tscn'
	match level_name:
		"lvl1.tscn":
			final_name = 'The crypt'
		"lvl2.tscn":
				final_name = 'The Wilderness'
		_:
			final_name = level_name
	return str(final_name)

func get_levels(path) -> void:
	var dir = DirAccess.open(path)
	if dir:
		print('dir exist')
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				print("Found file: " + file_name)
				var formated_path = dir.get_current_dir() + '/' + file_name
				create_level_btn(formated_path, select_name(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()		
	else:
		print("An error occurred when trying to access the path.")

func create_level_btn(lvl_path: String, lvl_name:String) -> void:
	var btn = LVL_BTN.instantiate()
	print(lvl_path)
	btn.text = lvl_name
	btn.level_path = lvl_path
	grid.add_child(btn)

# -----------------------------------------------
func _ready():
	get_levels(dir_path)
