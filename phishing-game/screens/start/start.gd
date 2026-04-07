extends Control


@export var title_up_down_speed: float = 2.5
@export var title_up_down_distance: int = 10

@onready var title: TextureRect = %Title
@onready var info_container: HBoxContainer = %InfoContainer

const HIGHSCORE_DISPLAY_INTERVAL: float = 30.0

@onready var highscore_packed_scene: PackedScene = load("uid://bvw3h2higqq3h")

var base_y: float
var time: float = 0.0
var idle_time: float = 0.0


var transition_in_progress: bool = false
var waiting_for_crt: bool = false
var scene_ready: bool = false

# Secret code sequence for opening options
const SECRET_CODE := ["phishing_up", "phishing_up", "phishing_left", "phishing_left", "phishing_down", "phishing_down", "phishing_right", "phishing_right"]
var input_sequence: Array = []


func _ready():
	base_y = title.position.y
	idle_time = 0.0
	MusicManager.play_main_menu_music()

	while CrtDisplay._transitioning:
		await get_tree().process_frame

	scene_ready = true



func _process(delta):
	time += delta
	title.position.y = base_y + sin(time * title_up_down_speed) * title_up_down_distance

	if waiting_for_crt:
		if not CrtDisplay._transitioning:
			transition_in_progress = false
			waiting_for_crt = false
		return

	if transition_in_progress or not scene_ready:
		return

	idle_time += delta
	if idle_time >= HIGHSCORE_DISPLAY_INTERVAL:
		_show_highscores()
		return

	# Secret code input detection
	var directions = ["phishing_up", "phishing_down", "phishing_left", "phishing_right"]
	for dir in directions:
		if Input.is_action_just_pressed(dir):
			input_sequence.append(dir)
			if input_sequence.size() > SECRET_CODE.size():
				input_sequence.pop_front()
			if input_sequence == SECRET_CODE:
				SfxManager.play_ui_select()
				_open_options()
				input_sequence.clear()

	if Input.is_action_just_pressed("phishing_confirm"):
		SfxManager.play_ui_select()
		_start_game()


func _open_options():
	if transition_in_progress:
		return
	transition_in_progress = true
	waiting_for_crt = true
	var options_scene = load("res://screens/options/options.tscn")
	CrtDisplay.fade_to_packed(options_scene)


func _start_game():
	if GameManager.start_game_blocked:
		return
	_start_transition()


func _show_highscores():
	if transition_in_progress:
		return
	transition_in_progress = true
	waiting_for_crt = true
	CrtDisplay.fade_to_packed(highscore_packed_scene)


func _start_transition():
	if transition_in_progress:
		return
	transition_in_progress = true
	waiting_for_crt = true
	GameManager.start_game_blocked = true
	CrtDisplay.fade_to_packed(GameManager.TUTORIAL_PACKED_SCENE)
