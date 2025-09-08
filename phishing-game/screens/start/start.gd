extends Control


@export var title_up_down_speed: float = 2.5
@export var title_up_down_distance: int = 10

@onready var title: TextureRect = %Title
@onready var one_player_button: TextureRect = %OnePlayerButton
@onready var two_player_button: TextureRect = %TwoPlayerButton
@onready var highscores_button: TextureRect = %HighscoresButton

var base_y: float
var time: float = 0.0

var button_default: Texture2D = preload("res://assets/images/menu/button_default.png")
var button_selected: Texture2D = preload("res://assets/images/menu/button_selected.png")

var one_player_button_default: Texture2D = preload("res://assets/images/menu/button_1p.png")
var one_player_button_selected: Texture2D = preload("res://assets/images/menu/button_1p_selected.png")
var two_player_button_default: Texture2D = preload("res://assets/images/menu/button_2p.png")
var two_player_button_selected: Texture2D = preload("res://assets/images/menu/button_2p_selected.png")


var transition_in_progress := false  # Prevent multiple triggers
var waiting_for_crt := false         # Flag to wait until fade completes

# Navigation state
enum MenuRow { PLAYER_SELECT, HIGH_SCORES }
var current_row: MenuRow = MenuRow.PLAYER_SELECT
var selected_player_mode: int = 1  # 1 or 2 players


func _ready():
	base_y = title.position.y
	_update_button_display()  # Set initial button state


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

	# Vertical navigation (UP/DOWN)
	if Input.is_action_just_pressed("phishing_up"):
		current_row = MenuRow.PLAYER_SELECT
		_update_button_display()
	elif Input.is_action_just_pressed("phishing_down"):
		current_row = MenuRow.HIGH_SCORES
		_update_button_display()

	# Horizontal navigation (LEFT/RIGHT) - only in player select row
	if current_row == MenuRow.PLAYER_SELECT:
		if Input.is_action_just_pressed("phishing_yes"):  # LEFT
			selected_player_mode = 1
			_update_button_display()
		elif Input.is_action_just_pressed("phishing_no"):  # RIGHT
			selected_player_mode = 2
			_update_button_display()

	# Selection (CONFIRM)
	if Input.is_action_just_pressed("phishing_confirm"):
		if current_row == MenuRow.HIGH_SCORES:
			_show_high_scores()
		else:
			_start_game()

func _update_button_display():
	# Reset all buttons to default state
	one_player_button.texture = one_player_button_default
	two_player_button.texture = two_player_button_default
	highscores_button.texture = button_default
	
	# Update based on current selection
	if current_row == MenuRow.HIGH_SCORES:
		# High scores row selected
		highscores_button.texture = button_selected
	else:
		# Player select row selected
		if selected_player_mode == 1:
			one_player_button.texture = one_player_button_selected
		else:
			two_player_button.texture = two_player_button_selected


func _show_high_scores():
	print("Showing high scores...")
	print(HighScoreManager.get_high_scores_text())
	
	# For now, we'll just print the scores
	# In a full implementation, you'd create a high scores scene

func _start_game():
	# Set the selected player mode in GameManager
	# You'll need to add this variable to GameManager if you want to use it
	print("Starting game with %d player(s)" % selected_player_mode)
	_start_transition()

func _start_transition():
	transition_in_progress = true
	waiting_for_crt = true

	# Call CRT Global fade
	CrtDisplay.fade_to_packed(GameManager.TUTORIAL_PACKED_SCENE)
	
	GameManager.reset_game()
