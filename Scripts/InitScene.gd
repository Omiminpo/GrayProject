extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	match (Global.FADE_TYPE.to_lower()):
		"fade":
			var transition = load("res://Prefabs/Transition_Fade.tscn")
			var instance = transition.instance()
			instance.set_name("Transition")
			get_node("/root/Node2D").call_deferred("add_child", instance)
			instance.Setup(Global.FADE_COLOUR, true, Global.FADE_SPEED)
		"cut":
			pass
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
