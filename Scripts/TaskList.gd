extends Label

var _textbox
var _no_tasks
var _cur_start = 0
var _base_text = ""
var _flag_up = false
var _flag_down = false
var _base_textbox_text = ""


func Close():
	get_parent().queue_free()

func _ready():
	Global.connect("close_all_menus", self, "Close")
	_textbox = get_parent().get_node("Text")
	_no_tasks = get_parent().get_node("NoTasks")
	_base_text = text
	_base_textbox_text = _textbox.text
	
	SpitOutText()
	
	set_process_input(true)
	pass

func _input(event):	
	if (_flag_up and event.is_action_pressed("Move_Up")):
		_cur_start -= 1
		text = _base_text
		_textbox.text = _base_textbox_text 
		SpitOutText()
		
	if (_flag_down and event.is_action_pressed("Move_Down")):
		_cur_start += 1
		text = _base_text
		_textbox.text = _base_textbox_text 
		SpitOutText()

func SpitOutText():	
	if (Tasklist_Manager.Tasks.empty() or Tasklist_Manager.Tasks[0].empty()):
		_no_tasks.visible = true
	else:
		_no_tasks.visible = false
		
		if (_cur_start > 0):
			text += "\n"
			_textbox.text += "          ▲\n"
			_flag_up = true
		else:
			text += " ---------\n"
			_textbox.text += "----------------\n"
			_flag_up = false
			
		
		var i = 0
		for task in Tasklist_Manager.Tasks:
			
			if (i > _cur_start):
				if (get_line_count() >= max_lines_visible - 1):
					text += "\n\n\n\n"
					_textbox.text += "          ▼       \n\n\n\n"
					_flag_down = true
				else:
					text += " ---------\n"
					_textbox.text += "----------------\n"
					_flag_down = false
			i += 1
			
			if (i > _cur_start):
				if (get_line_count() >= max_lines_visible - 1):
					text += "\n\n\n\n"
					_textbox.text += "          ▼       \n\n\n\n"
					_flag_down = true
				else:
					var checks = task[3]
					var checks_needed = task[2] - task[3]
					if (checks_needed < 0):
						checks_needed = 0
			
					for i in range(0, checks):
						text += "◼"
			
					for i in range(0, checks_needed):
						text += "◻"
			
					_textbox.text += task[1]
		
					if (_textbox.get_line_count() > get_line_count()):
						for i in range(_textbox.get_line_count() - get_line_count()):
							text += "\n"
		
					text += "\n"
					_textbox.text += "\n"
			i += 1
		
		text += " ---------\n"
		_textbox.text += "----------------\n"
