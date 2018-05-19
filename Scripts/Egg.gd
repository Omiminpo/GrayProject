extends Sprite

const IS_WALL = true
const TYPE = "TXT"
const ID = "Egg"
const LOAD_AT_START = false
const STOP_PLAYER = true

func Activate_Script():
	var txtbox = load("res://Prefabs/Textbox.tscn")
	var txtbox_instance = txtbox.instance()
	txtbox_instance.set_name("Textbox")
	txtbox_instance.Set_textbox(ID)
	get_node("/root/Node2D/TileManager/Walls/PC/UI").call_deferred("add_child", txtbox_instance)
	Global.Ui_Mode = STOP_PLAYER
	
	pass