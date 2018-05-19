extends TextureButton

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	set_process_input(true)
	pass
	
func _pressed():
	if (Global.Menu_State == Global.MENU_STATES.Tasklist):
		Global.CloseAllMenus()
	else:
		Global.CloseAllMenus()
		Global.Menu_State = Global.MENU_STATES.Tasklist
				
		var txtbox = load("res://Prefabs/TaskList.tscn")
		var txtbox_instance = txtbox.instance()
		txtbox_instance.set_name("TaskList")
		get_node("/root/Node2D/TileManager/Walls/PC/UI").call_deferred("add_child", txtbox_instance)
	
func _input(event):
	if ( Variables.Taskbar_Unlocked and event.is_action_pressed("Taskbar") ):
		_pressed()
		
func _process(delta):
	if (Global.Menus_Enabled[0] and disabled):
		disabled = false
	else:
		if (!Global.Menus_Enabled[0] and !disabled):
			disabled = true
		
	if (Variables.Taskbar_Unlocked and !visible):
		visible = true;
	else:
		if (!Variables.Taskbar_Unlocked and visible):
			visible = false

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
