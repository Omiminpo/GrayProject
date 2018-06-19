extends Node

var VARIABLES
var TASKS
var ZONE
var NEXT_ZONE
var SPAWN_POSITION_X
var SPAWN_POSITION_Y
var INVENTORY
var NEW_SKIN

func Save():
	VARIABLES = inst2dict(Variables)
	TASKS = Tasklist_Manager.Tasks.duplicate()
	ZONE = Global.ZONE
	NEXT_ZONE = Global.NEXT_ZONE
	SPAWN_POSITION_X = Global.SPAWN_POSITION.x
	SPAWN_POSITION_Y = Global.SPAWN_POSITION.y
	INVENTORY = Global.INVENTORY.duplicate()
	NEW_SKIN = Global.NEW_SKIN
	
	var newsave = File.new()
	newsave.open("user://savegame.save", File.WRITE)
	newsave.store_line(to_json(inst2dict(self)))
	newsave.close()
	
	queue_free()

func Load():
	var loadsav = File.new()
	if (loadsav.file_exists("user://savegame.save")):
		loadsav.open("user://savegame.save", File.READ)
		
		var current_data = parse_json(loadsav.get_line())
		
		Global.ZONE = current_data.ZONE
		Global.NEXT_ZONE = current_data.ZONE
		Global.SPAWN_POSITION = Vector2( int(current_data.SPAWN_POSITION_X), int(current_data.SPAWN_POSITION_Y) )
		Global.INVENTORY = current_data.INVENTORY.duplicate()
		Global.NEW_SKIN = current_data.NEW_SKIN
		Tasklist_Manager.Tasks = current_data.TASKS.duplicate()
		
		var var_keys = current_data.VARIABLES.keys()
			
		for key in var_keys:
			if (!key.begins_with('@')):
				Variables.set(key, current_data.VARIABLES[key])
					
		loadsav.close()
		
		Global.ChangeScene()
		
	loadsav.close()
	
	queue_free()