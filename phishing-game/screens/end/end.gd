extends Control


@export var min_display_time := 1.0     # seconds
@export var max_display_time := 15.0    # seconds

@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
var start_packed_scene: PackedScene = load("uid://c4ma6otpwlva4")

var transition_in_progress := false
var elapsed := 0.0
var can_transition := false

func _ready():
	elapsed = 0.0
	can_transition = false
	transition_in_progress = false
	score_label.text = GameManager.get_score()


func _process(delta):
	elapsed += delta

	var remaining = max(max_display_time - elapsed, 0)
	if timer_label:
		var seconds = int(remaining) % 60
		timer_label.text = "%d" % [seconds]

	if elapsed >= min_display_time:
		can_transition = true

	# Automatically transition after max_display_time
	if elapsed >= max_display_time and not transition_in_progress:
		_start_transition()

	# Block input while transitioning
	if transition_in_progress:
		return

	# Detect input 
	if can_transition:
		if Input.is_action_just_pressed("phishing_yes"):
			_start_transition()

func _start_transition():
	if transition_in_progress:
		return
	transition_in_progress = true
	CrtDisplay.fade_to_packed(start_packed_scene, 1.05)
