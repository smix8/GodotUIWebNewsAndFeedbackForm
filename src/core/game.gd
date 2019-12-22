extends Node

const PersistentSave = preload("res://src/core/persistent_save.gd")
const GAME_VERSION = "Godot Web News & Feedback Demo v.1.0"
### the user folder for the project
const PERSISTENT_SAVE_FOLDER : String = "user://persistent"
### we only need one named persistent file
const PERSISTENT_NAME_TEMPLATE : String = "persistent.res"



func _ready():
	load_persistent()
	save_persistent()
	$web.version_label.text = GAME_VERSION
	var path_image = "user://persistent/news_image.png"
	var file : File = File.new()	
	if file.file_exists(path_image):
		var img = Image.new()		
		var err = img.load(path_image)
		var img_tex = ImageTexture.new()
		img_tex.create_from_image(img)
		$web.news_image.texture = img_tex



func save_persistent():
	var persistent_save := PersistentSave.new()
	persistent_save.game_version = GAME_VERSION
	for node in get_tree().get_nodes_in_group('persistent'):
		node.save(persistent_save)
	
	var directory : Directory = Directory.new()
	if not directory.dir_exists(PERSISTENT_SAVE_FOLDER):
		directory.make_dir_recursive(PERSISTENT_SAVE_FOLDER)
	
	var save_path = PERSISTENT_SAVE_FOLDER.plus_file(PERSISTENT_NAME_TEMPLATE)
	var error : int = ResourceSaver.save(save_path, persistent_save)
	if error != OK:
		print('There was an issue writing the persistent to %s' % [save_path])



func load_persistent():
	var persistent_save_file_path : String = PERSISTENT_SAVE_FOLDER.plus_file(PERSISTENT_NAME_TEMPLATE)
	var file : File = File.new()
	if not file.file_exists(persistent_save_file_path):
		print("persistent file %s doesn't exist" % persistent_save_file_path)
		save_persistent()
		return

	var save_game : Resource = load(persistent_save_file_path)
	if save_game:
		for node in get_tree().get_nodes_in_group('persistent'):
			node.load(save_game)
	else:
		print("load error - persistent file corrupted")
