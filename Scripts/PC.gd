extends Sprite

# class member variables go here, for example:
# var b = "textvar"

var TIPE = "PC"

const TRASHOLD_FOR_MOVING = 0.2
const SPEED = 1
const RUN_SPEED = 2

const DOWN = 0
const LEFT = 1
const RIGHT = 2
const UP = 3

const IDLE = 0
const MOVING = 1

var Grid
var GridManager
var FloorGrid
var MovTween
var animation

var direction
var effective_direction
var state
var effective_state

var current_speed = SPEED

var move_trashold
var move_held
var ReadyToMove

var target

var MoveQueue = []
var DirQueue = []

var TWEEN_POS = Vector2(0, 0)

var override = false

var time = 0

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here 
	animation = get_node("PC_Anikm")
	direction = DOWN
	effective_direction = direction
	state = IDLE
	effective_state = state
	move_trashold = TRASHOLD_FOR_MOVING
	move_held = false
	
	MovTween = Tween.new()
	add_child(MovTween)
	MovTween.connect("tween_completed", self, "EndTween")
	ReadyToMove = true

	set_process_input(true)
	set_process(true)
	
	Grid = get_parent()
	GridManager = Grid.get_parent()
	FloorGrid = GridManager.get_node("Floor")
	
	set_position(Grid.map_to_world(Global.SPAWN_POSITION))
	Turn(Global.SPAWN_DIR)
	
	pass

func _process(delta):
	# if (!ReadyToMove):
	# 	position = Vector2(int (TWEEN_POS.x), int (TWEEN_POS.y))
	
	if (Global.Menu_State != Global.MENU_STATES.None):
		if ( MovTween.playback_speed >= 1):
			MovTween.playback_speed = 0
			
		state = IDLE
		move_held = false
		return
	else:
		if ( MovTween.playback_speed <= 0):
			MovTween.playback_speed = 1
	
	if (_processQueque()):
		return
		
	if (Global.Pg_Stopped or Global.Ui_Mode):
		state = IDLE
		move_held = false
		return
	
	if (Global.Pg_Stopped):
		return
	
	if (move_held):
		move_trashold -= delta
	else:
		move_trashold = TRASHOLD_FOR_MOVING

	if ( move_trashold <= 0 and move_held ):
		state = MOVING
	else:
		state = IDLE
		
	ProcessAnimation()
	ProcessMoveStart()

func _input(event):
	if (Global.Menu_State != Global.MENU_STATES.None):
		if ( MovTween.playback_speed >= 1):
			MovTween.playback_speed = 0
			
		state = IDLE
		move_held = false
		return
	else:
		if ( MovTween.playback_speed <= 0):
			MovTween.playback_speed = 1
		
	if (Global.Pg_Stopped or Global.Ui_Mode):
		state = IDLE
		move_held = false
		return
	
	if (Global.Dialogue_Going):
		Global.Skip = true
		return
		
	if (Global.Skip):
		Global.Skip = false
		return
	
	#check old presses on release
	if (( event.is_action_released("Move_Down") and direction == DOWN ) or 
	( event.is_action_released("Move_Left") and direction == LEFT ) or 
	( event.is_action_released("Move_Right") and direction == RIGHT ) or 
	( event.is_action_released("Move_Up") and direction == UP )):
		if (Input.is_action_pressed("Move_Down")):
			direction = DOWN
		if (Input.is_action_pressed("Move_Left")):
			direction = LEFT
		if (Input.is_action_pressed("Move_Right")):
			direction = RIGHT
		if (Input.is_action_pressed("Move_Up")):
			direction = UP
			
	#check new presses
	if (event.is_action_pressed("Move_Down")):
		direction = DOWN
	if (event.is_action_pressed("Move_Left")):
		direction = LEFT
	if (event.is_action_pressed("Move_Right")):
		direction = RIGHT
	if (event.is_action_pressed("Move_Up")):
		direction = UP
	
	#check if idle or moving
	if ( ( direction == DOWN and Input.is_action_pressed("Move_Down") ) or
	( direction == RIGHT and Input.is_action_pressed("Move_Right") ) or
	( direction == LEFT and Input.is_action_pressed("Move_Left") ) or
	( direction == UP and Input.is_action_pressed("Move_Up") ) ):
		move_held = true;
	else:
		move_held = false;
		
	#Check Look at things
	if (ReadyToMove and event.is_action_pressed("Look")):
		var tile = GridManager.GetTile(target, "TXT")
		if (tile != null):
			# Stops Player
			if (Global.Pg_Stopped):
				_process(0)
				match effective_direction:
					DOWN:
						animation.play("IdleD")
					LEFT:
						animation.play("IdleL")
					RIGHT:
						animation.play("IdleR")
					UP:
						animation.play("IdleU")
			# End Stop
			tile.Activate_Script()
	
	pass
	
func _processQueque():
	if (MoveQueue.size() > 0):
		if (ReadyToMove):
			target = MoveQueue[0][0]
			if (MoveQueue[0][3] == "relative"):
				target += GetCoor()
			
			if (GridManager.IsFree(target)):
				TurnAround(DirQueue[0])
				DirQueue.pop_front()
				
				Move(Grid.map_to_world(target)) 
				match (MoveQueue[0][2].to_lower() ):
					"idle":
						match (MoveQueue[0][1].to_upper()):
							"U":
								if ( animation.get_current_animation() != "IdleU"): 
									animation.play("IdleU")
								direction = UP
								effective_direction = direction
								state = IDLE
								effective_state = state
							"D":
								if ( animation.get_current_animation() != "IdleD"): 
									animation.play("IdleD")
								direction = DOWN
								effective_direction = direction
								state = IDLE
								effective_state = state
							"L":
								if ( animation.get_current_animation() != "IdleL"): 
									animation.play("IdleL")
								direction = LEFT
								effective_direction = direction
								state = IDLE
								effective_state = state
							"R":
								if ( animation.get_current_animation() != "IdleR"): 
									animation.play("IdleR")
								direction = RIGHT
								effective_direction = direction
								state = IDLE
								effective_state = state
							
					"walk":
						match (MoveQueue[0][1].to_upper()):
							"U":
								if ( animation.get_current_animation() != "WalkingU"): 
									animation.play("WalkingU")
								direction = UP
								effective_direction = direction
								state = MOVING
								effective_state = state
							"D":
								if ( animation.get_current_animation() != "WalkingD"): 
									animation.play("WalkingD")
								direction = DOWN
								effective_direction = direction
								state = MOVING
								effective_state = state
							"L":
								if ( animation.get_current_animation() != "WalkingL"): 
									animation.play("WalkingL")
								direction = LEFT
								effective_direction = direction
								state = MOVING
								effective_state = state
							"R":
								if ( animation.get_current_animation() != "WalkingR"): 
									animation.play("WalkingR")
								direction = RIGHT
								effective_direction = direction
								state = MOVING
								effective_state = state
							
				MoveQueue.pop_front()
		return true
	else:
		return false 
						
func ProcessAnimation():
	match ReadyToMove:
		true:
			if ( !( ( Input.is_action_pressed("Move_Down") ) or 
			( Input.is_action_pressed("Move_Right") ) or
			( Input.is_action_pressed("Move_Left") ) or
			( Input.is_action_pressed("Move_Up") ) ) ):
				match effective_direction:
					DOWN:
						if ( animation.get_current_animation() != "IdleD"): 
							animation.play("IdleD")
					LEFT:
						if ( animation.get_current_animation() != "IdleL"): 
							animation.play("IdleL")
					RIGHT:
						if ( animation.get_current_animation() != "IdleR"): 
							animation.play("IdleR")
					UP:
						if ( animation.get_current_animation() != "IdleU"): 
							animation.play("IdleU")
		false:
			match effective_direction:
				DOWN:
					if ( animation.get_current_animation() != "WalkingD"): 
						animation.play("WalkingD")
				LEFT:
					if ( animation.get_current_animation() != "WalkingL"):
						animation.play("WalkingL")
				RIGHT:
					if ( animation.get_current_animation() != "WalkingR"):
						animation.play("WalkingR")
				UP:
					if ( animation.get_current_animation() != "WalkingU"):
						animation.play("WalkingU")

func ProcessMoveStart():
	if (ReadyToMove and !Global.Ui_Mode):
		var dir
		match direction:
			DOWN:
				dir = Vector2(0, 1)
			LEFT:
				dir = Vector2(-1, 0)
			RIGHT:
				dir = Vector2(1, 0)
			UP:
				dir = Vector2(0, -1)
		
		target = GetCoor() + dir
		effective_direction = direction
		if (state == MOVING and GridManager.IsFree(target)):
			effective_state = state
			Move(Grid.map_to_world(target))
			ProcessAnimation()

func Move(pos):
	var tile = GridManager.GetTile(target, "ENT")
	if (tile != null):
		tile.Activate_Script()
		
	var speed = float(1)/float(current_speed)
	
	TWEEN_POS = position
	
	MovTween.interpolate_property(self, "position", get_position(), pos, speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT) 
	MovTween.start()
	ReadyToMove = false;
	
		# Effect Spawning #
	var landing_floor = FloorGrid.GetEffect(FloorGrid.get_cell(GetCoor().x, GetCoor().y), 1)
	if (landing_floor != null):
		var effect_instance = landing_floor.instance()
		effect_instance.Turn(effective_direction)
		FloorGrid.call_deferred("add_child", effect_instance)
		effect_instance.global_position = global_position
	
func MoveOrder(pos, dir, anim, info = ""):
	MoveQueue.append([pos, dir, anim, info])
	DirQueue.append(dir)
	
func EndTween(one, two):
	ReadyToMove = true;
	
	var tile = GridManager.GetTile(GetCoor(), "STP")
	if (tile != null):
		tile.Activate_Script()
	
func GetCoor():
	return WorldToMap(get_position())
	
func WorldToMap(num):
	return Grid.world_to_map(num + Grid.cell_size/16)
	
func SetCoorPos(x, y):
	set_position(Grid.map_to_world(Vector2(x, y)))
	
func SetSpeed(val):
	current_speed = val
	
func SetRun():
	current_speed = RUN_SPEED

func SetWalk():
	current_speed = SPEED
	
func TurnAround(vect):
	match vect:
		Vector2(0, -1):
			effective_direction = UP
		Vector2(0, 1):
			effective_direction = DOWN
		Vector2(-1, 0):
			effective_direction = LEFT
		Vector2(1, 0):
			effective_direction = RIGHT
		_:
			pass
func Turn(dir):
	match dir:
		"U":
			direction = UP
		"D":
			direction = DOWN
		"L":
			direction = LEFT
		"R":
			direction = RIGHT
	
	effective_direction = direction
