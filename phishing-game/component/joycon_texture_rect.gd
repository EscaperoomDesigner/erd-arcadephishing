extends TextureRect

const JOYCON_DEFAULT_DURATION: float = 0.5
const JOYCON_LEFT_DURATION: float = 0.5
const JOYCON_RIGHT_DURATION: float = 0.5

var joycon_default_texture: Texture2D = preload("uid://dly75ncy1m3ug")
var joycon_left_texture: Texture2D = preload("uid://m1ltgpfryjfs")
var joycon_right_texture: Texture2D = preload("uid://c38cebax5c2is")

var joycon_cycle_time: float = 0.0
var current_state: int = 0  # 0 = default, 1 = left, 2 = default, 3 = right


func _process(delta):
	# Joycon texture cycling
	joycon_cycle_time += delta
	
	var current_interval: float
	match current_state:
		0: current_interval = JOYCON_DEFAULT_DURATION
		1: current_interval = JOYCON_LEFT_DURATION
		2: current_interval = JOYCON_DEFAULT_DURATION
		3: current_interval = JOYCON_RIGHT_DURATION
		_: current_interval = JOYCON_DEFAULT_DURATION
	
	if joycon_cycle_time >= current_interval:
		joycon_cycle_time = 0.0
		current_state = (current_state + 1) % 4
		
		match current_state:
			0: texture = joycon_default_texture
			1: texture = joycon_left_texture
			2: texture = joycon_default_texture
			3: texture = joycon_right_texture
