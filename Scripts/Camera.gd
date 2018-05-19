extends Camera2D

const TRAUMA_DEPLETION = 1
const MAX_TRAUMA_OFFSET = 250

export var tile_size = 16
export var scroll_margin = Vector2(3, 3)
export var base_scroll_margin = [Vector2(0.33802816901, 0.22535211267), Vector2(0.2, 0.2)]
var actual_scroll_margin

var follow_h = true
var follow_v = true

var hor_trauma = 0
var ver_trauma = 0

var deplete = true

var shake_offset = Vector2(0,0)
var adapt_offset = Vector2(0,0)
var base_offset = Vector2(0,0)

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	Global.connect("resolution_changed", self, "Adapt")
	FixScrolling()
	Adapt()
	
func SetScroll(h, v):
	follow_h = h
	follow_v = v
	FixScrolling()
	
func FixScrolling():
	if (follow_v):
		drag_margin_bottom = ( ( scroll_margin.y - 1 ) * 2 ) / ( Global.BASE_RES.y / tile_size )
		drag_margin_top = ( scroll_margin.y * 2 ) / ( Global.BASE_RES.y / tile_size )
	else:
		drag_margin_bottom = 10
		drag_margin_top = 10
	
	if (follow_h):
		drag_margin_left = ( scroll_margin.x * 2 ) / ( Global.BASE_RES.x / tile_size )
		drag_margin_right = ( ( scroll_margin.x - 1 ) * 2 ) / ( Global.BASE_RES.x / tile_size )
	else:
		drag_margin_right = 10
		drag_margin_left = 10
	
func Adapt():
	return
	var res_x = Global.CURR_RES.x
	var res_y = Global.CURR_RES.y
	var base_res_x = Global.BASE_RES.x
	var base_res_y = Global.BASE_RES.y
	
	actual_scroll_margin = Vector2( ( ( base_res_x / res_x ) * base_scroll_margin  ), 
									( ( base_res_y / res_y ) * base_scroll_margin ) )
	FixScrolling()
	
	# var offset_x = ( res_x - base_res_x ) / 2
	# var offset_y = ( res_y - base_res_y ) / 2
	# adapt_offset = Vector2(offset_x, offset_y)
	
	# offset = adapt_offset + shake_offset + base_offset
	
	
	
func Shake(h, v, d):
	hor_trauma = h
	ver_trauma = v
	deplete = d

func AdditiveShake(h, v, d):
	hor_trauma += h
	ver_trauma += v
	deplete = d
	
func _process(delta):
	if ( Global.Menu_State != Global.MENU_STATES.None ):#
		return

	var h
	var v
	
	if (hor_trauma >= 1):
		hor_trauma = 1
	if (ver_trauma >= 1):
		ver_trauma = 1
	
	if (hor_trauma > 0 or ver_trauma > 0):
		if (hor_trauma > 0):
			h = MAX_TRAUMA_OFFSET * ( hor_trauma * hor_trauma * hor_trauma ) * rand_range(-1, 1)
			if (deplete):
				hor_trauma -= TRAUMA_DEPLETION * delta
		if (ver_trauma > 0):
			v = MAX_TRAUMA_OFFSET * ( ver_trauma * ver_trauma * ver_trauma ) * rand_range(-1, 1)
			if (deplete):
				ver_trauma -= TRAUMA_DEPLETION * delta
		
		shake_offset = Vector2(int(h), int(v))
		offset = adapt_offset + shake_offset + base_offset
	else:
		if (shake_offset != Vector2(0, 0)):
			shake_offset = Vector2(0, 0)
			offset = adapt_offset + shake_offset + base_offset

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
