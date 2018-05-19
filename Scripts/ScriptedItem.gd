extends Sprite

export var STAND_ALONE_LOADER = false
export var Interactable = false
export var Movable = false
export var Loop = false
export var IS_WALL = true
export var TYPE = ""
export var ID = ""
export var LOAD_AT_START = false
export var STOP_PLAYER = true
export var DISABLE_COMMANDS = true
export var STOP_PLAYER_INIT = false
export var DISABLE_COMMANDS_INIT = false
export var TYPE_OF_FOOTPRINT = 0
export var DISABLER = true
export var DISABLER_INIT = false

var Activated = 0

func Activate_Script():
	if (Interactable):
		var txtbox = load("res://Prefabs/Textbox.tscn")
		var txtbox_instance = txtbox.instance()
		txtbox_instance.set_name("Textbox")
		txtbox_instance.Set_textbox(ID, STAND_ALONE_LOADER, ID, self, DISABLER)
		get_node("/root/Node2D/TileManager/Walls/PC/UI").call_deferred("add_child", txtbox_instance)
		Global.Pg_Stopped = STOP_PLAYER
		Global.Ui_Mode = DISABLE_COMMANDS
	
		Activated += 1
	pass
	
func Activate_InitScript():
	var txtbox = load("res://Prefabs/Textbox.tscn")
	var txtbox_instance = txtbox.instance()
	txtbox_instance.set_name("Textbox")
	txtbox_instance.Set_textbox(ID + "_INIT", STAND_ALONE_LOADER, ID, self, DISABLER_INIT)
	get_node("/root/Node2D/TileManager/Walls/PC/UI").call_deferred("add_child", txtbox_instance)
	Global.Pg_Stopped = STOP_PLAYER_INIT
	Global.Ui_Mode = DISABLE_COMMANDS_INIT
	
#MOVING
export var SPEED = 1
export var RUN_SPEED = 2

const DOWN = 0
const LEFT = 1
const RIGHT = 2
const UP = 3

var Grid
var GridManager
var FloorGrid
var MovTween
var animation
var ReadyToMove
var dir
var pc

var MoveQueue = []
var DirQueue = []
var Loop_MoveQueue = []
var Loop_DirQueue = []

var TWEEN_POS = Vector2(0, 0)

var cur_speed

func _ready():
	if (get_parent().name == "Walls"):
		GridManager = get_parent().get_parent()
	else:
		GridManager = get_parent()
	
	Grid = GridManager.get_node("Walls")
	FloorGrid = GridManager.get_node("Floor")
	
	pc = get_node("/root/Node2D/TileManager/Walls/PC")
		
	if (LOAD_AT_START):
		Activate_InitScript()
		
	if (Movable):
		animation = get_node("AnimationPlayer")
	
		MovTween = Tween.new()
		add_child(MovTween)
		MovTween.connect("tween_completed", self, "EndTween")
		ReadyToMove = true;
	
		cur_speed = SPEED
	
		set_process(true)

func _process(delta):
	# if (Movable and !ReadyToMove):
	#	position = Vector2(int (TWEEN_POS.x), int (TWEEN_POS.y))
		
	if ( Global.Menu_State != Global.MENU_STATES.None ):
		if (Movable):
			if ( MovTween.playback_speed >= 1):
				MovTween.playback_speed = 0
		return
	else:
		if (Movable):
			if ( MovTween.playback_speed <= 0):
				MovTween.playback_speed = 1
		
	if (_processQueque()):
		return
		
func EndTween(one, two):
	ReadyToMove = true;
	
func PlayAnimation(anim_name):
	if (animation.get_current_animation() != anim_name): 
		animation.play(anim_name)

func Move(pos):
	var speed = float(1)/float(cur_speed)
	
	TWEEN_POS = position	
	
	MovTween.interpolate_property(self, "position", get_position(), pos, speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT) 
	MovTween.start()
	ReadyToMove = false;
	
	# Effect Spawning #
	var landing_floor = FloorGrid.GetEffect(FloorGrid.get_cell(GetCoor().x, GetCoor().y), TYPE_OF_FOOTPRINT)
	if (landing_floor != null):
		var effect_instance = landing_floor.instance()
		effect_instance.Turn(dir)
		FloorGrid.call_deferred("add_child", effect_instance)
		effect_instance.position = position
	# End Effect Spawning #

func _processQueque():
	if (MoveQueue.size() > 0):
		if (ReadyToMove):
			
			var target = MoveQueue[0][0]
			if (MoveQueue[0][3] == "relative"):
				target += GetCoor()
			
			if (GridManager.IsFree(target) and target != pc.GetCoor()):
				TurnAround(DirQueue[0])
				DirQueue.pop_front()
				
				Move(Grid.map_to_world(target)) 
				PlayAnimation(MoveQueue[0][2])
				MoveQueue.pop_front()
				
		return true
	else:
		if (Loop):
			MoveQueue = Loop_MoveQueue.duplicate()
			DirQueue = Loop_DirQueue.duplicate()
			return true
		else:
			return false

func MoveOrder(pos, dir, anim, info = ""):
	DirQueue.append(pos)
	MoveQueue.append([pos, dir, anim, info])
	if (Loop):
		Loop_DirQueue.append(pos)
		Loop_MoveQueue.append([pos, dir, anim, info])

func GetCoor():
	return WorldToMap(get_position())
	
func SetSpeed(val):
	cur_speed = val
	
func SetRun():
	cur_speed = RUN_SPEED

func SetWalk():
	cur_speed = SPEED
	
func WorldToMap(num):
	return Grid.world_to_map(num + Grid.cell_size/16)
	
func TurnAround(vect):
	match vect:
		Vector2(0, -1):
			dir = UP
		Vector2(0, 1):
			dir = DOWN
		Vector2(-1, 0):
			dir = LEFT
		Vector2(1, 0):
			dir = RIGHT
		_:
			pass

func SetCoorPos(x, y):
	set_position(Grid.map_to_world(Vector2(x, y)))