extends TextureRect

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

export var Left = false
var _base_pos 

func _ready():
	visible = true
	_base_pos = Vector2(rect_position.x, rect_position.y)
	Adapt()
	
func Adapt():
	return
	var offset_x = Global.BASE_RES.y/2
	if (Left):
		offset_x *= -1
		
	rect_position = Vector2(_base_pos.x + offset_x, _base_pos.y)