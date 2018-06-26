extends TileMap

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export var time = 1
var actual_time

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	actual_time = time
	pass

func _process(delta):
	if (actual_time <= 0):
		visible = !visible
		actual_time = time
	else:
		actual_time -= delta
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
