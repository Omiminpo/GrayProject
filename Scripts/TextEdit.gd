extends TextEdit

var _line = 0
# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass
	
func _input(event):
	if (event.is_action_pressed("Cheat")):
		if (visible):
			visible = false
		else:
			visible = true

	if (event.is_action_pressed("Look")):
		Parse_line(text)
		
	if (event.is_action_pressed("Cheat_Select")):
		Parse_line("<<MOVE>><<"+text+":D>>")

func Parse_line(instruction):
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
					
				_:
					print ("COMMAND ERROR")
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
