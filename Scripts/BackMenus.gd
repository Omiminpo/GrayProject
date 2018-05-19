extends TextureButton

func _ready():
	set_process_input(true)
	pass
	
func _pressed():
	Global.CloseAllMenus()
	
func _input(event):
	if ( Variables.Taskbar_Unlocked and event.is_action_pressed("Back") ):
		_pressed()