extends CanvasLayer

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var HALF_OFFSET = Vector2(0, 0)

func _ready():
	Adapt()
	Global.connect("resolution_changed", self, "Adapt")
	# Called every time the node is added to the scene.
	# Initialization here
	pass
	
func Adapt():
	return
	scale = Vector2(Global.ZOOM, Global.ZOOM)
	
	var res_x = Global.CURR_RES.x
	var res_y = Global.CURR_RES.y
	var base_res_x = Global.BASE_RES.x
	var base_res_y = Global.BASE_RES.y
	
	var z
	if (OS.window_fullscreen):
		z = Global.ZOOM
	else:
		z = 1
	
	var offset_x = ( res_x  - base_res_x * z) / 2 
	var offset_y = ( res_y - base_res_y * z) / 2 
	offset = Vector2(offset_x, offset_y)
	HALF_OFFSET = ( res_y - base_res_y * z) / 2 
	
	for element in get_children():
		element.Adapt()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
