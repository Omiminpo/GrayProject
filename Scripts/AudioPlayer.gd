extends Node

var _players
var _effects = []

func _ready():
	_players = get_children()
	
	for player in _players:
		_effects.append("")

func PlayMusic(effect):
	var stream = load("res://Audio/Music/" + effect )
	
	stream.loop_mode = AudioStreamSample.LOOP_FORWARD
	
	_players[0].stream = stream
	_players[0].play()
	_effects[0] = effect
	
func PlayEffect(effect, loop = false):
	var skip = true
	var found = false
	var i = 0
	
	for player in _players:
		if (skip):
			skip = false
		else:
			if (!player.playing):
				var stream = load("res://Audio/Effects/" + effect )
				if (loop):
					stream.loop_mode = AudioStreamSample.LOOP_FORWARD
				player.stream = stream
				player.play()
				
				_effects[i] = effect
				found = true
		i += 1
	
	if (!found):
		var stream = load("res://Audio/Effects/" + effect )
		if (loop):
			stream.loop_mode = AudioStreamSample.LOOP_FORWARD
		_players[1].stream = stream
		_players[1].play()
		_effects[1] = effect

func StopAllSounds(StopMusicToo = true):
	var skip = true
	
	for player in _players:
		if (skip and !StopMusicToo):
			skip = false
		else:
			player.stop()
	
	for n in _effects:
		if (skip and !StopMusicToo):
			skip = false
		else:
			n = ""

func StopMusic():
	_players[0].stop()
	_effects[0] = ""
	
func StopEffect(effect):
	var i = 0
	
	for n in _effects:
		if (n == effect):
			n = ""
			_players[i].stop()
		i += 1
		
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
