extends Sprite

export var IS_WALL = true
export var TYPE = "TXT"
export var ID = "Girl"
export var LOAD_AT_START = false
export var STOP_PLAYER = false

func Activate_Script():
	var txtbox = load("res://Prefabs/Textbox.tscn")
	var txtbox_instance = txtbox.instance()
	txtbox_instance.set_name("Textbox")
	txtbox_instance.Set_textbox(ID)
	get_node("/root/Node2D/TileManager/Walls/PC/UI").call_deferred("add_child", txtbox_instance)
	Global.Ui_Mode = STOP_PLAYER
	
	pass