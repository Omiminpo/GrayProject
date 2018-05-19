extends Label

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var _icon
var _arrow_left
var _arrow_right
var _column_two
var _description
var _no_tasks

var _start = 0
var _cursor = 0

func _ready():
	Global.connect("close_all_menus", self, "Close")
	set_process_input(true)
	
	_icon = get_parent().get_node("Black")
	_arrow_left = get_parent().get_node("ArrowLeft")
	_arrow_right = get_parent().get_node("ArrowRight")
	_column_two = get_parent().get_node("InventoryCol2")
	_description = get_parent().get_node("Description")
	_no_tasks = get_parent().get_node("Empty")
	
	ParseInventory()

	
func _input(event):
	if (event.is_action_pressed("Move_Up")):
		if (_cursor > 0):
			_cursor -= 1
			if (_cursor < _start):
				_start -= max_lines_visible
			ParseInventory()
	
	if (event.is_action_pressed("Move_Down")):
		if ( _cursor < Global.INVENTORY.size() - 1 ):
			_cursor += 1
			if (_cursor >= _start + (max_lines_visible*2) ):
				_start += max_lines_visible
			ParseInventory()
	
	if (event.is_action_pressed("Move_Right")):
		if ( _cursor < Global.INVENTORY.size() - 1 ):
			_cursor += max_lines_visible
			if (_cursor > Global.INVENTORY.size() - 1):
				_cursor = Global.INVENTORY.size() - 1
		
			if (_cursor >= _start + (max_lines_visible*2) ):
				_start += max_lines_visible
			
			ParseInventory()
		
	if (event.is_action_pressed("Move_Left")):
		if ( _cursor > 0 ):
			_cursor -= max_lines_visible
			if (_cursor < 0):
				_cursor = 0
				
			if (_cursor < _start):
				_start -= max_lines_visible
			ParseInventory()
		
	
func ParseInventory():
	text = ""
	_column_two.text = ""
	
	var inv = Global.INVENTORY
	
	if ( _start == 0 ):
		_arrow_left.visible = false
	else:
		_arrow_left.visible = true
	
	var i = 0
	
	if ( inv.empty() ):
		_no_tasks.visible = true
	else:
		_no_tasks.visible = false
	
	for item in inv:
		if (i >= _start):
			var c = "◽ "
			if ( i == _cursor):
				c = " ◾ "
				
			if (get_line_count() <= max_lines_visible):
				text += c + Global.Retreive_Item(item).Name + "\n"
			else:
				if (_column_two.get_line_count() <= max_lines_visible):
					_column_two.text += c + Global.Retreive_Item(item).Name + "\n"
				
				
		i += 1
		
		var item_data = Global.Retreive_Item(Global.INVENTORY[_cursor])
		_description.text = item_data.Description
		ShowPicture(item_data.Picture)
	
	
	if (inv.size() - _start <= max_lines_visible*2):
		_arrow_right.visible = false
	else:
		_arrow_right.visible = true


func Close():
	get_parent().queue_free()

func ShowPicture(address):
	_icon.texture = load("res://Art/Items/" + address + ".png")