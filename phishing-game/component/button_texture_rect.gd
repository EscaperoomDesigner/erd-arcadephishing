extends TextureRect

const BUTTON_DEFAULT_DURATION: float = 1.0
const BUTTON_PRESSED_DURATION: float = 0.5

var button_pressed_texture: Texture2D = preload("uid://kxesqx6ma8l0")
var button_default_texture: Texture2D = preload("uid://cd72fbwyplkom")

var button_cycle_time: float = 0.0
var is_button_pressed_state: bool = false


func _process(delta):
	# Button texture cycling
	button_cycle_time += delta
	var current_interval = BUTTON_PRESSED_DURATION if is_button_pressed_state else BUTTON_DEFAULT_DURATION
	if button_cycle_time >= current_interval:
		button_cycle_time = 0.0
		is_button_pressed_state = !is_button_pressed_state
		texture = button_pressed_texture if is_button_pressed_state else button_default_texture
