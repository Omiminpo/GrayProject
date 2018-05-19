extends Node

var Ui_Mode = false
var Pg_Stopped = false

var Skip = false
var ZONE = "OFFICE_CORRIDOR"
var AudioPlayer

var NEXT_ZONE = ""
# Basic spawn zone to preserve camera is 22, 20
var SPAWN_POSITION = Vector2(29, 20)
var SPAWN_DIR = "U"
var FADE_TYPE = ""
var FADE_COLOUR
var FADE_SPEED

var BASE_RES
var CURR_RES
var LAST_ADAPTED_RES

signal resolution_changed
signal close_all_menus

var _toAdapt = false

var ZOOM_IN = false
var FULLSCREEN = true

var Menu_State = MENU_STATES.None
var Dialogue_Going = false

enum MENU_STATES 	{
					Disabled,
					None,
					Inventory,
					Map,
					Tasklist 
					}
					
#INVENTORY
var INVENTORY = []

#MAP
var MAP = 0
var MAP_POSITION = Vector2(0, 0)

var Menus_Enabled = [true, true, true]

var temp_save


onready var root = get_tree().root
onready var base_size = root.get_visible_rect().size
var ZOOM = 1
var V_ZOOM = 3

func ChangeScene():
	get_tree().change_scene("res://Scenes/" + Global.NEXT_ZONE + ".tscn")
	Global.ZONE = Global.NEXT_ZONE

func _ready():
	ProjectSettings.set_setting("rendering/environment/default_clear_color", "333233")
	var player_scene = load("res://Prefabs/AudioPlayer.tscn")
	AudioPlayer = player_scene.instance()
	AudioPlayer.set_name("AudioPlayer")
	call_deferred("add_child", AudioPlayer)
	
	BASE_RES = get_tree().get_root().size
	CURR_RES = BASE_RES
	LAST_ADAPTED_RES = BASE_RES
	
	set_process_input(true)
	set_process(true)
	
	if (FULLSCREEN):
		GoFullscreen()
	
	if (ZOOM_IN):
		get_tree().set_screen_stretch(2, 1, BASE_RES)
		
	get_tree().connect("screen_resized", self, "_on_screen_resized")
	
	root.set_attach_to_screen_rect(root.get_visible_rect())
	_on_screen_resized()
	
func _on_screen_resized():
	var new_window_size = OS.window_size
	
	var scale_w = max(int(new_window_size.x / base_size.x), 1)
	var scale_h = max(int(new_window_size.y / base_size.y), 1)
	var scale = V_ZOOM
	
	var diff = new_window_size - (base_size * scale)
	var diffhalf = (diff * 0.5).floor()
	
	root.set_attach_to_screen_rect(Rect2(diffhalf, base_size * scale))
	
	# Black bars to prevent flickering:
	var odd_offset = Vector2(int(new_window_size.x) % 2, int(new_window_size.y) % 2)
	
	VisualServer.black_bars_set_margins(
		max(diffhalf.x, 0), # prevent negative values, they make the black bars go in the wrong direction.
		max(diffhalf.y, 0),
		max(diffhalf.x, 0) + odd_offset.x,
		max(diffhalf.y, 0) + odd_offset.y
	)

func CloseAllMenus():
	emit_signal("close_all_menus")
	Menu_State = MENU_STATES.None
	
func GoFullscreen():
	OS.window_fullscreen = !OS.window_fullscreen
	_toAdapt = true
		
func _input(event):
	if (event.is_action_pressed("Fullscreen")):
		GoFullscreen()
		
	if (event.is_action_pressed("Temp_Save")):
		Save()
		
	if (event.is_action_pressed("Temp_Load")):
		Load()
	
	if (event.is_action_pressed("Temp_Zoom")):
		Zoom(V_ZOOM+1)
		
	if (event.is_action_pressed("Temp_Zoom_Down")):
		Zoom(V_ZOOM-1)
		
#		var keys = []
#
#		for i in temp_save:
#			keys.append(str(i))
#
#		print (keys)
		#get_tree().get_root().size = Vector2(1280, 720)
		#get_tree().get_root().set_size_override(true, Vector2(10, 10))
		#var t = get_tree().get_root().get_final_transform()
		#var sc = t.get_scale()
		
func Zoom(level):
	V_ZOOM = level
	
	if (!OS.window_fullscreen):
		OS.window_size = BASE_RES * ZOOM
		
	emit_signal("resolution_changed")
	_on_screen_resized()
	
	pass
		
func Save():
	var save = load("res://Prefabs/SaveGame.tscn")
	var save_instance = save.instance()
	save_instance.set_name("SaveGame")
	call_deferred("add_child", save_instance)
	save_instance.Save()

func Load():
	var save = load("res://Prefabs/SaveGame.tscn")
	var save_instance = save.instance()
	save_instance.set_name("SaveGame")
	call_deferred("add_child", save_instance)
	save_instance.Load()
		
func _process(delta):
	if (_toAdapt):
		CURR_RES = get_tree().get_root().size
		if (LAST_ADAPTED_RES !=  CURR_RES):
			LAST_ADAPTED_RES = CURR_RES
			emit_signal("resolution_changed") 
			_toAdapt = false
			
		if (!OS.window_fullscreen):
			OS.window_size = BASE_RES * V_ZOOM
			

func FindNode(string, parser):
	var found = false
	while (!found):
		parser.read()
		if (parser.get_node_data() == string):
			return true
		else:
			if (parser.get_node_name() == "END"):
				return false
				
func FindNode_json(string, dictionary, starting_node = 0, ending_node = 0):
	if (ending_node == 0 or ending_node > dictionary.size()):
		ending_node = dictionary.size()
	
	for i in range(starting_node, ending_node):
		if (dictionary[i].title == string):
			return i
	
	print ("ERROR: ", string, " node not found. Search range: ", starting_node, " - ", ending_node)
	return -1

func FindNode_json_tags(index, dictionary):
	return dictionary[index].tags.split(" ")
	
func FindNode_json_body(index, dictionary):
	return dictionary[index].body.split("\n")
	
func Parse_Dialogue_Condition (cmd, loop_start = 0):
	var result = false
	var cmd_array = cmd.split(" ")
	
	var comp
	if (cmd_array[loop_start] != "inventory" and cmd_array[loop_start] != "task"):
		comp = Variables.get( cmd_array[loop_start] )
	
	match cmd_array[loop_start + 1]:
		"b==":
			result = comp == StringToBool(cmd_array[loop_start + 2])
		"i==":
			result = comp == int(cmd_array[loop_start + 2])
		">":
			result = comp > int(cmd_array[loop_start + 2])
		"<":
			result = comp < int(cmd_array[loop_start + 2])
		"<=":
			result = comp <= int(cmd_array[loop_start + 2])
		">=":
			result = comp >= int(cmd_array[loop_start + 2])
		"vb==":
			result = comp == Variables.get( cmd_array[loop_start + 2] ) 
		"vi==":
			result = comp == Variables.get( cmd_array[loop_start + 2] )  
		"v>":
			result = comp > Variables.get( cmd_array[loop_start + 2] ) 
		"v<":
			result = comp < Variables.get( cmd_array[loop_start + 2] ) 
		"v<=":
			result = comp <=  Variables.get( cmd_array[loop_start + 2] ) 
		"v>=":
			result = comp >=  Variables.get( cmd_array[loop_start + 2] ) 
		"contains", "Contains":
			result = Global.Is_Item_In_Inventory(cmd_array[loop_start + 2])
		"lacks", "Lacks":
			result = !Global.Is_Item_In_Inventory(cmd_array[loop_start + 2])
		"position", "Position", "X>", "x>", "X<", "x<", "y<", "Y<", "y>", "Y>":
			var pos = get_node("/root/Node2D/TileManager/Walls/PC").GetCoor()
			var cmd_result = cmd_array[loop_start + 2].split(":")
			var trgt = Vector2(int(cmd_result[loop_start]), int(cmd_result[loop_start + 1]) )
			
			match(cmd_array[loop_start + 1]):
				"position", "Position":
					result = pos == trgt 
				"X>", "x>":
					result = trgt.x > pos.x
				"X<", "x<":
					result = trgt.x < pos.x
				"y<", "Y<":
					result = trgt.y < pos.y
				"y>", "Y>":
					result = trgt.y > pos.y
		"completed", "Completed":
			result = Tasklist_Manager.IsTaskCompleted(cmd_array[loop_start + 2])
		"not_completed", "Not_Completed", "nc", "n_c", "open", "Open":
			result = !Tasklist_Manager.IsTaskCompleted(cmd_array[loop_start + 2])
		"all_completed", "All_Completed", "allcompleted", "AllCompleted":
			match (cmd_array[loop_start + 2]):
				"all", "a", "All":
					result = Tasklist_Manager.AreAllCompleted(true)
				"main", "m", "Main":
					result = Tasklist_Manager.AreAllCompleted(false)
				"optional", "o", "Optional", "opt", "Opt":
					result = Tasklist_Manager.AreAllOptionalCompleted()
	
	match (cmd_array[loop_start + 3]):
		"and", "AND", "&", "&&", "And":
			var rest = Parse_Dialogue_Condition(cmd, loop_start + 4)
			result = rest and result
		"or", "OR", "|", "||", "Or":
			var rest = Parse_Dialogue_Condition(cmd, loop_start + 4)
			result = rest or result
	
	return result

func Parse_Dialogue_Setter(cmd):
	var cmd_array = cmd.split(" ")
	var base = Variables.get( cmd_array[0] )
					
	match (cmd_array[1]):
		"b=":
			Variables.set( cmd_array[0], StringToBool(cmd_array[2]) )
		"i=": 
			Variables.set( cmd_array[0], int(cmd_array[2]) )
		"+=":
			Variables.set( cmd_array[0], int (base) + int(cmd_array[2]) )
		"-=":
			Variables.set( cmd_array[0], int (base) - int(cmd_array[2]) )
		"*=":
			Variables.set( cmd_array[0], int (base) * int(cmd_array[2]) )
		"vb=":
			Variables.set( cmd_array[0],  Variables.get( cmd_array[2]) ) 
		"vi=":
			Variables.set( cmd_array[0], Variables.get( cmd_array[2]) ) 
		"v+=":
			Variables.set( cmd_array[0], int(base) + Variables.get( cmd_array[2]) )
		"v-=":
			Variables.set( cmd_array[0], int(base) - Variables.get( cmd_array[2])  )
		"v*=":
			Variables.set( cmd_array[0], int(base) * Variables.get( cmd_array[2])  )

func Get_Item(id):
	INVENTORY.append(id)

func Is_Item_In_Inventory(id):
	return INVENTORY.has(id)

func Remove_Item(id):
	INVENTORY.erase(id)
	
func Retreive_Item(id):
	var file = File.new()
	var Items
	
	file.open("res://Data/Items.json", File.READ)
	Items = parse_json(file.get_as_text())
	file.close()
	
	return Items[id]
	
func StringToBool(flag_string):
	match (flag_string):
		"True", "true", "TRUE", "T", "t":
			return true
		"False", "false", "FALSE", "F", "f":
			return false
			