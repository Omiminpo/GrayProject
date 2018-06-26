extends Sprite

# DEV SETTINGS
const MAXCHOICES = 3
const TYPE_TIME = 0.02
# DEV SETTINGS

# MODES
const NULL = 0
const BREAK = 1
const CHOICE = 2
const NEXTNODE = 3
const WAITING = 4
const END = 5
# MODES

var _textbox
var _dialogues = {}
var _rootNode
var _tags
var _body

var _mode = NULL
var _startup
var _freemovement

var _line = 0
var _choices = []
var _choices_gotos = []
var _choices_question = ""
var _choices_current_select = 0
var _choices_start_viewer = 0
var _visible = true
var _nextNode = ""
var _wait_time = 0
signal stop_waiting

var _type_timer = TYPE_TIME
var _current_timer = TYPE_TIME
var _timed_string = ""
var _timing_multiplier = 1
var _full_line = ""
var _char_used = 0

var _overrides = [false, false]
var _auto = -1
var _auto_timer = 0

var label_begin_y_base
var label_end_y_base 

var label_base_x
var _picture
var _frame_box
var _picture_box

var _self_item
var _disabler
var _alone
var _fnScript

var non_interactable

var frameskip = 2

func _ready():
	set_process_input(true)
	set_process(true)
	
	var lab = get_node("Label")
	label_begin_y_base = lab.get_begin().y
	label_end_y_base = lab.get_end().y
	label_base_x = lab.margin_left
	_picture = get_node("Black")
	_frame_box = get_node("Window")
	_picture_box = _frame_box.get_node("Black2")
	
	Adapt()
	
func Adapt():
	# offset.y = get_parent().HALF_OFFSET
	var lab = get_children()[0]
	# lab.set_begin(Vector2(lab.get_begin().x, label_begin_y_base + get_parent().HALF_OFFSET))
	# lab.set_end(Vector2(lab.get_end().x, label_end_y_base + get_parent().HALF_OFFSET))

func _input(event):
	if ( Global.Menu_State != Global.MENU_STATES.None ):#
		return
		
	if (non_interactable):
		return
		
	if (event.is_action_pressed("Look")):
		Global.Skip = true
		if (_full_line == _textbox.text):
			match (_mode):
				BREAK:
					if (!_overrides[0]):
						NextLine()
						ProcessScript()
				CHOICE:
					_line = _choices_gotos[_choices_current_select] - 1
					_mode = NULL
					_choices = []
					_choices_gotos = []
					_choices_start_viewer = 0
					_choices_current_select = 0
					Global.AudioPlayer.PlayEffect("126_Blip_1.wav")
					ProcessScript()
		else:
			if (!_overrides[1]):
				_textbox.set_text(_full_line)
		
	if (event.is_action_pressed("Move_Up")):
		match (_mode):
			CHOICE:
				if (_choices_current_select <= 0):
					Global.AudioPlayer.PlayEffect("119_Blip_2.wav")
					pass
				else:
					Global.AudioPlayer.PlayEffect("Blip_4.wav")
					_choices_current_select -= 1
					if (_choices_current_select < _choices_start_viewer):
						_choices_start_viewer -= 1
				SetText(ParseChoice(_choices_question, _choices, _choices_start_viewer, _choices_current_select))
				_textbox.set_text(_full_line)
				
	if (event.is_action_pressed("Move_Down")):
		match (_mode):
			CHOICE:
				if (_choices_current_select >= _choices.size() - 1):
					Global.AudioPlayer.PlayEffect("119_Blip_2.wav")
					pass
				else:
					Global.AudioPlayer.PlayEffect("Blip_4.wav")
					_choices_current_select += 1
					if (_choices_current_select > _choices_start_viewer + MAXCHOICES - 1):
						_choices_start_viewer += 1
				SetText(ParseChoice(_choices_question, _choices, _choices_start_viewer, _choices_current_select))
				_textbox.set_text(_full_line)
	
func _process(delta):
	
	if (frameskip <= 0):
		if (_visible):
			show()
	else:
		frameskip -= 1
	
	# Process Typing
	if ( Global.Menu_State != Global.MENU_STATES.None ):#
		return
		
	if (_full_line != _textbox.text):
		_type_timer -= delta
		if (_type_timer <= 0):
			_char_used += 1
			_textbox.set_text(_full_line.left(_char_used))
			
			if (_timed_string == ""):
				_current_timer = TYPE_TIME
			else:
				if (_char_used < _timed_string.length()):
					var c = _timed_string[_char_used]
					match (c):
						"d", "D":
							_current_timer = TYPE_TIME
						"1", "2", "3", "4", "5", "6", "7", "8", "9", "0":
							_current_timer = float(c)
						"`", "!", "£", "$", "%", "^", "&", "*", "(", ")", "-":
							_current_timer = ProcessAltNumbers(c) * _timing_multiplier
						"Q", "q", "W", "w", "E", "e", "R", "r", "T", "t", "Y", "y", "U", "u", "I", "i", "O", "o", "P", "p":
							_current_timer = ProcessAltNumbers(c) * _timing_multiplier * 10
			
			_type_timer = _current_timer
			
	# Process Typing
	match (_mode):
		BREAK:
			# Auto Advance
			if (_full_line == _textbox.text):
				if ( _auto >= 0 ):
					_auto_timer -= delta
					if (_auto_timer <= 0):
						_auto_timer = _auto
						NextLine(false)
			# Auto Advance
		WAITING:
			# Process Wait
			if ( _wait_time > 0 ):
				_wait_time -= delta
			else:
				_wait_time = 0
				_mode = NULL
				emit_signal("stop_waiting")
			# Process Wait
		END:
			Global.Ui_Mode = false
			Global.Pg_Stopped = false
			Global.Skip = true
			queue_free()
			
		NEXTNODE: 
			Set_textbox(_nextNode, _alone, _fnScript, _self_item, _disabler)
			_line = 0
			_mode = NULL
			ProcessScript()
		
func ProcessScript():
	while (_mode == NULL):
		Parse_line()
		if (_mode == WAITING):
			yield( self, "stop_waiting")
			_mode = NULL
		
func SetText(txt):
	_char_used = 0
	_type_timer = TYPE_TIME
	
	if (_textbox == null):
		_textbox = get_node("Label")
	
	_full_line = txt
	
func Set_textbox(ObjectID, stand_alone = false, filename_script = "", objectself = null, disabler = false, dis_com = false, ni = false):
	# Load Dialogue File
	var file = File.new()
	var address_name
	_self_item = objectself
	
	non_interactable = ni
	_alone = stand_alone
	_fnScript = filename_script
	_disabler = disabler
	if (_disabler):
		Global.Menus_Enabled = [false, false, false]
	
	if (dis_com):
		Global.Dialogue_Going = true
	
	if (stand_alone):
		address_name = "Characters/" + filename_script
	else:
		address_name = Global.ZONE
	
	file.open("res://Dialogues/" + address_name + ".json", File.READ)
	_dialogues = parse_json(file.get_as_text())
	file.close()
	# End Load
	
	_textbox = get_node("Label")
	
	_rootNode = Global.FindNode_json(ObjectID, _dialogues)
	_tags = Global.FindNode_json_tags(_rootNode, _dialogues)
	_body = Global.FindNode_json_body(_rootNode, _dialogues)
	
	
	ProcessScript()
	
func Parse_line(override_instruction = false, override_instruction_line = ""):
	var instruction
	
	if (override_instruction):
		instruction = override_instruction_line
	else:
		instruction = _body[_line]
		
	var char_pos = 0
	var i = 0
	print (instruction, " ", _line)
	match (instruction.left(2) ):
		"<<":
			char_pos = 2
				
			#Get Command
			i = Find_Cmd(instruction, char_pos, '>')
			var cmd = instruction.substr(char_pos, i - char_pos - 1)
			char_pos = i + 3
			
			match (cmd.to_upper()):
				"TEXTBOX":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					match (cmd_txt):
						"up", "UP", "U", "u", "Up":
							position = Vector2(142, 30)
						"down", "DOWN", "D", "d", "Down":
							position = Vector2(142, 130)
				"IF":
					#Get Code
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = instruction.right(char_pos).split(":")
					
					if ( Global.Parse_Dialogue_Condition(cmd_txt) ):
						_line = int(cmd_result[0]) - 1
					else:
						_line = int(cmd_result[1]) - 1
					
				
				"SET":
					#Get Code
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					Global.Parse_Dialogue_Setter(cmd_txt)
					
					_line += 1
				
				"GET":
					#Get Code
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					Global.Get_Item(cmd_txt)
					_line += 1
					
				"REMOVE":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					Global.Remove_Item(cmd_txt)
					_line += 1
					
					
				"CHOICE":
					#GetCode
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var choices_to_check = cmd_txt.split("-")
					_choices_question = choices_to_check[0]
					choices_to_check.remove(0)
					
					for cho in choices_to_check:
						var split_cho = cho.split(":")
						var add = false
						
						if (split_cho.size() <= 2):
							add = true
						else:
							if ( Global.Parse_Dialogue_Condition(split_cho[2])):
								add = true
								
						if (add):
							_choices.append(split_cho[0])
							_choices_gotos.append(int(split_cho[1]))
					
					SetText(ParseChoice(_choices_question, _choices, _choices_start_viewer, _choices_current_select))
					_mode = CHOICE
					
				"BOX.INVISIBLE":
					_visible = false;
					hide()
					_line += 1
					
				"BOX.VISIBLE":
					_visible = true;
					show()
					_line += 1
					
				"BOX.TOGGLE":
					_visible = !_visible
					if (_visible):
						show()
					else:
						hide()
					
					_line += 1
					
				"SOUND":
					#Get Code
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					
					match cmd_result[0].to_lower():
							"playfx":
								if (cmd_result.size() <= 2):
									Global.AudioPlayer.PlayEffect(cmd_result[1])
								else:
									Global.AudioPlayer.PlayEffect(cmd_result[1], cmd_result[2])
							"playmusic":
								Global.AudioPlayer.PlayMusic(cmd_result[1])
							"stop":
								Global.AudioPlayer.StopEffect(cmd_result[1])
							"stopmusic":
								Global.AudioPlayer.StopMusic()
							"stopall":
								Global.AudioPlayer.StopAllSounds()
							"stopfx":
								Global.AudioPlayer.StopAllSounds(false)
					_line += 1
					
				"WAIT":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					_mode = WAITING
					_wait_time = float(cmd_txt)
					_line += 1
					
				"TIMING":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					if (cmd_txt.to_lower() == "clear" or cmd_txt.to_lower() == "c"):
						_timed_string = ""
						_type_timer = TYPE_TIME
						_timing_multiplier = 1
					else:
						_timing_multiplier = float(cmd_txt.split(":")[1])
						cmd_txt = cmd_txt.split(":")[0]
						_timed_string = cmd_txt
						_type_timer = float(cmd_txt[0])
						_current_timer = _type_timer
						
					_line += 1
				
				"AUTO":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					_auto = float(cmd_txt)
					_auto_timer = _auto
					
					_line += 1
					
				"OVERRIDE":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					match(cmd_txt.to_lower()):
						"next", "advance":
							_overrides = [true, false]
						"type", "typing":
							_overrides = [false, true]
						"nexttype", "next_type", "next type", "both":
							_overrides = [true, true]
						"clear":
							_overrides = [false, false]
							
					_line += 1
				
				"TRANSITION":
					#Get Code
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					var fade = cmd_result[0].split(" to ")
					var spd = cmd_result[2].split(" to ")
					var c = Color(0, 0, 0)
					var c_txt = (cmd_result[1].split(" "))
					
					c.r8 = int(c_txt[0])
					c.g8 = int(c_txt[1])
					c.b8 = int(c_txt[2])
					
					Global.FADE_COLOUR = c
					Global.FADE_TYPE = fade[1]
					Global.FADE_SPEED = float(spd[1])
					
					match (fade[0].to_lower()):
						"fade":
							var transition = load("res://Prefabs/Transition_Fade.tscn")
							var instance = transition.instance()
							instance.set_name("Transition")
							get_node("/root/Node2D").call_deferred("add_child", instance)
							instance.Setup(c, false, float(spd[0]))
							
						"cut":
							pass
					
					_line += 1
				
				"MOVE":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					
					Global.NEXT_ZONE = cmd_result[0]
					Global.SPAWN_POSITION = Vector2(int(cmd_result[1]), int(cmd_result[2]))
					Global.SPAWN_DIR = cmd_result[3]
					
					#get_tree().change_scene("res://Scenes/" + Global.NEXT_ZONE + ".tscn")
					Global.ChangeScene()
					
					_line += 1
				
				"WARP.PG":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					var pc = get_node("/root/Node2D/TileManager/Walls/PC")
					
					pc.SetCoorPos(int(cmd_result[0]), int(cmd_result[0]))
					
					_line += 1
					
				"WALK.PG":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					var pc = get_node("/root/Node2D/TileManager/Walls/PC")
					
					var pos
					var info
					
					if (cmd_result[0] == "REL" or cmd_result[0] == "REl" or cmd_result[0] == "Rel" or cmd_result[0] == "rel"):
						info = "relative"
						
						var dir_to_move_to
						if (cmd_result[1].to_upper() == "RAN" or cmd_result[1].to_upper() == "RANDOM"):
							var directions_array = ["U", "D", "L", "R"]
							dir_to_move_to = directions_array[randi()%4]
						else:
							dir_to_move_to = cmd_result[1].to_upper()
						
						match (dir_to_move_to):
							"U":
								pos = Vector2(0, -1)
							"D":
								pos = Vector2(0, 1)
							"L":
								pos = Vector2(-1, 0)
							"R":
								pos = Vector2(1, 0)
							"N","", "M", "I":
								pos = Vector2(0, 0)
					else:
						pos = Vector2(int(cmd_result[0]), int(cmd_result[1]))
						info = "targeted"
						
					pc.MoveOrder(pos, cmd_result[2], cmd_result[3], info)
					
					_line += 1
				
				"SPEED.PG":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var pc = get_node("/root/Node2D/TileManager/Walls/PC")
					
					match (cmd_txt):
						"walk":
							pc.SetWalk()
						"run":
							pc.SetRun()
						_:
							pc.SetSpeed(float(cmd_txt))
							
					_line += 1
					
				"WARP.TRG":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					
					var pc
						
					if (has_node("/root/Node2D/TileManager/" + cmd_result[0])):
						pc = get_node("/root/Node2D/TileManager/" + cmd_result[0])
					else:
						pc = get_node("/root/Node2D/TileManager/Walls/" + cmd_result[0])
					
					pc.SetCoorPos(int(cmd_result[1]), int(cmd_result[2]))
					
					_line += 1
					
				"WALK.TRG":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					
					var pc
						
					if (has_node("/root/Node2D/TileManager/" + cmd_result[0])):
						pc = get_node("/root/Node2D/TileManager/" + cmd_result[0])
					else:
						pc = get_node("/root/Node2D/TileManager/Walls/" + cmd_result[0])
					
					var pos
					var info
					
					if (cmd_result[1] == "REL" or cmd_result[1] == "REl" or cmd_result[1] == "Rel" or cmd_result[1] == "rel"):
						info = "relative"
						
						var dir_to_move_to
						if (cmd_result[2].to_upper() == "RAN" or cmd_result[2].to_upper() == "RANDOM"):
							var directions_array = ["U", "D", "L", "R"]
							dir_to_move_to = directions_array[randi()%4]
						else:
							dir_to_move_to = cmd_result[2].to_upper()
						
						match (dir_to_move_to):
							"U":
								pos = Vector2(0, -1)
							"D":
								pos = Vector2(0, 1)
							"L":
								pos = Vector2(-1, 0)
							"R":
								pos = Vector2(1, 0)
							"N","", "M", "I":
								pos = Vector2(0, 0)
					else:
						pos = Vector2(int(cmd_result[1]), int(cmd_result[2]))
						info = "targeted"
						
					pc.MoveOrder(pos, cmd_result[3], cmd_result[4], info)
					
					_line += 1
					
				"SPEED.TRG":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					
					var pc
						
					if (has_node("/root/Node2D/TileManager/" + cmd_result[0])):
						pc = get_node("/root/Node2D/TileManager/" + cmd_result[0])
					else:
						pc = get_node("/root/Node2D/TileManager/Walls/" + cmd_result[0])
					
					match (cmd_result[1]):
						"walk":
							pc.SetWalk()
						"run":
							pc.SetRun()
						_:
							pc.SetSpeed(float(cmd_result[1]))
							
					_line += 1
					
				"ANIM.TRG":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					
					var pc
						
					if (has_node("/root/Node2D/TileManager/" + cmd_result[0])):
						pc = get_node("/root/Node2D/TileManager/" + cmd_result[0])
					else:
						pc = get_node("/root/Node2D/TileManager/Walls/" + cmd_result[0])
					
					pc.PlayAnimation(cmd_result[1])
					
					_line += 1
				
				"PROP.TRG":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
						
					var pc
						
					if (has_node("/root/Node2D/TileManager/" + cmd_result[0])):
						pc = get_node("/root/Node2D/TileManager/" + cmd_result[0])
					else:
						pc = get_node("/root/Node2D/TileManager/Walls/" + cmd_result[0])
					
					match (cmd_result[2]):
						"int":
							pc.set(cmd_result[1], int(cmd_result[3]))
						"float":
							pc.set(cmd_result[1], float(cmd_result[3]))
						"bool":
							pc.set(cmd_result[1], Global.StringToBool(cmd_result[3]))
						"string":
							pc.set(cmd_result[1], cmd_result[3])
						"toggle":
							pc.set(cmd_result[1], !pc.get(cmd_result[1]))
					
					_line += 1
					
				"SPAWN":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					
					var ob = load("res://Prefabs/" + cmd_result[0])
					var instance = ob.instance()
					instance.set_name(cmd_result[1])
					get_node("/root/Node2D/TileManager/Walls/").call_deferred("add_child", instance)
					get_node("/root/Node2D/TileManager").SpawnItem(instance)
					
					_line += 1
					
				"SHAKE":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					
					var pc = get_node("/root/Node2D/TileManager/Walls/PC/Camera2D")
					
					pc.Shake(float(cmd_result[0]), float(cmd_result[1]), Global.StringToBool(cmd_result[2]))
					
					_line += 1
					
				"SCROLL.CAMERA":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					var pc = get_node("/root/Node2D/TileManager/Walls/PC/Camera2D")
					
					pc.SetScroll(Global.StringToBool(cmd_result[0]), Global.StringToBool(cmd_result[1]))
					
					_line += 1
					
				"SKIN.PG":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var pc = get_node("/root/Node2D/TileManager/Walls/PC")
					
					pc.texture = load(cmd_txt)
					
					Global.NEW_SKIN = cmd_txt
							
					_line += 1
					
				"PICTURE.SHOW":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					get_node("Label").margin_left = -28
					_picture.texture = load("res://Art/" + cmd_txt)
					
					_line += 1
				
				"PICTURE.HIDE":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					get_node("Label").margin_left = label_base_x
					_picture.texture = null
					
					_line += 1
					
				"PICTURE.BOX.SHOW":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					_picture_box.texture = load("res://Art/" + cmd_txt)
					_frame_box.visible = true
					
					_line += 1
				
				"PICTURE.BOX.HIDE":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					_frame_box.visible = false
					_picture_box.texture = null
					
					_line += 1
					
				"TASK.CHECK":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					
					if (cmd_result.size() >= 2):
						Tasklist_Manager.CheckTask(cmd_result[0], int(cmd_result[1]))
					else:
						Tasklist_Manager.CheckTask(cmd_result[0])
					
					_line += 1
				
				"TASK.CLEAR":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					Tasklist_Manager.RemoveTask(cmd_txt)
					
					_line += 1
					
				"TASK.CLEAR.IF_COMPLETED":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					if (Tasklist_Manager.IsTaskCompleted(cmd_txt)):
						Tasklist_Manager.RemoveTask(cmd_txt)
					
					_line += 1
				
				"TASK.CLEAR.ALL":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					Tasklist_Manager.ClearAll()
					
					_line += 1
				
				"TASK.CLEAR.ALL.IF_COMPLETED":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					match (cmd_txt):
						"all", "All", "a", "A":
							Tasklist_Manager.ClearCompleted(true)
							
						"Main", "main", "m", "M":
							Tasklist_Manager.ClearCompleted(false)
							
						"Optional", "optional", "o", "O", "Opt", "opt":
							Tasklist_Manager.ClearOptionals()
												
					_line += 1
					
				"TASK.ADD":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					
					Tasklist_Manager.AddTask(cmd_result[0], cmd_result[1], int(cmd_result[2]), Global.StringToBool(cmd_result[3]))
												
					_line += 1
					
					
				"MAP.SELECT":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					Global.MAP = int (cmd_txt)
					
					_line += 1
					
				"MAP.PLACE":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					
					Global.MAP_POSITION = Vector2(int(cmd_result[0] ), int( cmd_result[1] ))
					
					_line += 1
					
				"MENUS", "MENU":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
					
					Global.Menus_Enabled = [Global.StringToBool(cmd_result[0]), Global.StringToBool(cmd_result[1]), Global.StringToBool(cmd_result[2])]
					_line += 1
					
				"DESTROY":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					get_parent().get_parent().get_parent().get_parent().RemoveItem(_self_item)
					_self_item.queue_free()
					
					_line += 1
					
				"DESTROY.TRG":
					i = Find_Cmd(instruction, char_pos, '>')
					var cmd_txt = instruction.substr(char_pos, i - char_pos - 1)
					char_pos = i + 1
					
					var cmd_result = cmd_txt.split(":")
						
					var pc
					
					print (get_node("/root/Node2D/TileManager/" + cmd_result[0]))
					if (has_node("/root/Node2D/TileManager/" + cmd_result[0])):
						pc = get_node("/root/Node2D/TileManager/" + cmd_result[0])
					else:
						pc = get_node("/root/Node2D/TileManager/Walls/" + cmd_result[0])
					
					if (pc != null):
						get_parent().get_parent().get_parent().get_parent().RemoveItem(pc)
						pc.queue_free()
					
					_line += 1
					
				"BREAK":
					_mode = BREAK
					
				"END":
					_mode = END
					Global.Pg_Stopped = false
					Global.Ui_Mode = false
					
					if (_disabler):
						Global.Menus_Enabled = [true, true, true]
						Global.Dialogue_Going = false
				_:
					print ("COMMAND ERROR")
					_line += 1
		"[[":
			char_pos = 2
			
			#Get Command
			i = Find_Cmd(instruction, char_pos, ']')
			var cmd = instruction.substr(char_pos, i - char_pos - 1)
			char_pos = i + 3
			
			_nextNode = cmd
			_mode = NEXTNODE
		
		"((":
			char_pos = 2
			
			i = Find_Cmd(instruction, char_pos, ')')
			var cmd = instruction.substr(char_pos, i - char_pos - 1).split(":")
			var char2erase = instruction.substr(char_pos, i - char_pos - 1).length()
			
			if (Variables.Days >= int(cmd[0]) and Variables.Days <= int(cmd[1]) ):
				instruction.erase(0, 4+char2erase)
				Parse_line(true, instruction)
			else:
				_line += 1
			#
		"##":
			_line += 1
		_:
			SetText(instruction)
			_line += 1
		
func Find_Cmd(text, pos, bracket):
	var i = 0
	var string_found = false
	for c in text:
		if (!string_found):
			if (i >= pos):
				if (c == bracket and text.substr(i, 1) == bracket):
					string_found = true
			i += 1
	
	return i
	
func ParseChoice(question, text, start, current):
	var final_text = question + "\n"
	var i = 0
		
	var counter = 0
	
	for cho in text:
		if (i >= start and i < start + MAXCHOICES):
			counter += 1 
			
			if (counter == 1):
				if (text.size() > MAXCHOICES and start > 0):
					final_text += "▲   "
				else:
					final_text += "     "
			else:
				if (counter == MAXCHOICES):
					if (text.size() > MAXCHOICES and start + MAXCHOICES  < text.size() ):
						final_text += "▼   "
					else:
						final_text += "     "
				else:
						final_text += "     "
			
			if (i == current):
				final_text += " ◾ "
			else:
				final_text += "□ "
					
					
			final_text += cho + "\n"
		i += 1
	
	return final_text
		
func NextLine(sound = true):
	_line += 1
	_mode = NULL
	if (sound):
		Global.AudioPlayer.PlayEffect("Blip_3.wav")
	ProcessScript()
	
func ProcessAltNumbers(c):
	match (c):
		"!", "Q", "q": return 1
		"`", "-", "W", "w": return 2
		"£", "E", "e": return 3
		"$", "R", "r": return 4
		"%", "T", "t": return 5
		"^", "Y", "y": return 6
		"&", "U", "u": return 7
		"*", "I", "i": return 8
		"(", "O", "o": return 9
		")", "P", "p": return 0
		_: return 1
	