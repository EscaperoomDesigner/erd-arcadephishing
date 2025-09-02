extends Control

@export var title_up_down_speed: float = 2.5
@export var title_up_down_distance: int = 10

@onready var button: TextureRect = %Button
@onready var title: TextureRect = %Title

var base_y: float
var time: float = 0.0
var tutorial_packed_scene: PackedScene = preload("uid://b0ckh3uehbwwd")
var transitioning := false

func _ready():
	base_y = title.position.y
	button.gui_input.connect(_on_button_gui_input)

func _process(delta):
	time += delta
	title.position.y = base_y + sin(time * title_up_down_speed) * title_up_down_distance

func _unhandled_input(event):
	if event.is_action_pressed("phishing_yes"):
		print("pressed d")
		go_to_tutorial()
	elif event.is_action_pressed("return"):
		get_tree().quit()

func _on_button_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		go_to_tutorial()

func go_to_tutorial():
	if transitioning:
		return
	transitioning = true
	print("transitioning")
	CrtDisplay.fade_to_packed(tutorial_packed_scene)
