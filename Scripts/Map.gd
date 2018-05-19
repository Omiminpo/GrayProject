extends TextureRect

var _picture
var _label
var _cur_map
var _cursor

#MAPS#
var MAPS = [

# MAP 0 : DEFAULT
["res://Art/MAPS/DEFAULT.png", [ 
[ "YELLOW", 	[70, 264], 		[368, 516] ],
[ "RED", 		[77, 279], 		[53, 249] ],
[ "GREEN", 		[431, 647], 	[72, 221] ], 
[ "HOUSE", 		[494, 662],		[345, 531] ] 
] ]

]

func Close():
	queue_free()

func _ready():
	Global.connect("close_all_menus", self, "Close")
	_picture = get_node("MapPicture")
	_label = get_node("Label")
	_cursor = _picture.get_node("Pointer")
	_cursor.rect_position = Global.MAP_POSITION - Vector2(16, 16)
	_cur_map = MAPS[Global.MAP]
	_picture.texture = load(_cur_map[0])
	
	set_process(true)
	set_process_input(true)
	pass
	
func _process(delta):
	_label.text = ""
	var pos = _picture.get_local_mouse_position ( )
	
	for zone in _cur_map[1]:
		if ( pos.x > zone[1][0] and pos.x < zone[1][1] and pos.y > zone[2][0] and pos.y < zone[2][1] ):
			_label.text = zone[0]
			return
	pass

func _input(event):
	if (event.is_action_pressed("Look")):
		print( _picture.get_local_mouse_position ( ) )
	
func Adapt():
	pass