extends Sprite

var _mode = 0
var _speed
var f

func _ready():
	set_process(true)
	pass
	
func _process(delta):
	match (_mode):
		1:
			self_modulate .a -= delta * _speed
			if (self_modulate .a <= 0):
				queue_free()
		2:
			self_modulate .a += delta * _speed
			# if (f.color.a >= 1):
			# 	queue_free()
	
func Setup(colour, fadeout, speed):
	var _colour = colour
	_speed = speed
	
	if (fadeout):
		_mode = 1
		_colour.a = 1
	else:
		_mode = 2
		_colour.a = 0
		
	self_modulate  = _colour



#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
