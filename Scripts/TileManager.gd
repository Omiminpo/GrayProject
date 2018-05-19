extends Node2D

var Walls
var InitializeFunction
var Initialized
var ActiveItems
const INVALID_NAMES = ["Others", "PC", "Walls", "Floor", "Accessories_Floor", "Accessories_Ceiling"]


func _ready():
	set_process(true)
	Walls = get_node("Walls")
	InitializeFunction = Init()
	pass
	
func Init():
	Initialized = false
	yield()
	RefreshItems()
	Initialized = true
	pass

func _process(delta):
	if (Initialized == false):
		InitializeFunction.resume()
		
	pass
	
func IsFree(pos):
	if ( Walls.get_cell(pos.x, pos.y) >= 0 ):
		return false
	else:
		for tile in ActiveItems:
			if (tile != null):
				if ( tile.IS_WALL and Walls.world_to_map(tile.get_position() + Vector2(3,3)) == pos  ):
					return false
	return true

func GetTile( pos, type = "" ):
	for tile in ActiveItems:
		if (Walls.world_to_map(tile.get_position() + Vector2(3,3)) == pos):
			if (type == "" or type == tile.TYPE):
				return tile
	
	return null

func RefreshItems():
	ActiveItems = []
	for item in get_children() + get_node("Walls").get_children():
		var var_name = item.get_name()
		var is_name_found = false
		for inv_name in INVALID_NAMES:
			is_name_found = is_name_found or inv_name == var_name
			
		if (!is_name_found):
			ActiveItems.append(item)
	pass
	
func SpawnItem(item):
	ActiveItems.append(item)
	
func RemoveItem(item):
	var i = 0
	for tile in ActiveItems:
		if (tile == item):
			ActiveItems.remove(i)
			return
		i += 1