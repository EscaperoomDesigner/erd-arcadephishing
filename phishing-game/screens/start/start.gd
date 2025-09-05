extends Control


@export var title_up_down_speed: float = 2.5
@export var title_up_down_distance: int = 10

@onready var button: TextureRect = %Button
@onready var title: TextureRect = %Title

var base_y: float
var time: float = 0.0

var transition_in_progress := false  # Prevent multiple triggers
var waiting_for_crt := false         # Flag to wait until fade completes

func _ready():
	base_y = title.position.y

func _process(delta):
	time += delta
	title.position.y = base_y + sin(time * title_up_down_speed) * title_up_down_distance

	if waiting_for_crt:
		if not CrtDisplay._transitioning:
			# Fade finished, allow input again
			transition_in_progress = false
			waiting_for_crt = false
		return

	# If a transition is in progress, ignore input
	if transition_in_progress:
		return

	# Check input
	if Input.is_action_just_pressed("phishing_yes"):
		_start_transition()
	elif Input.is_action_just_pressed("return"):
		get_tree().quit()

func _start_transition():
	transition_in_progress = true
	waiting_for_crt = true

	# Call CRT Global fade
	CrtDisplay.fade_to_packed(GameManager.TUTORIAL_PACKED_SCENE)
	
	GameManager.reset_game()
