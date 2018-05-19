extends TileMap

func _ready():
	var ParentGrid = get_parent()
	
	var i = 0
	for tile in get_used_cells():
		var path = ""
		
		match get_cell(tile.x, tile.y):
			1: path = "res://Prefabs/ObjectAttempt.tscn"
			3: path = "res://Prefabs/Egg.tscn"
		
		if (path != ""):
			var scene = load(path)
			var scene_instance = scene.instance()
			scene_instance.set_name("object" + str(i))
			scene_instance.set_position(map_to_world(tile))
			ParentGrid.call_deferred("add_child", scene_instance)
			i += 1
			
	queue_free()
	
	pass
