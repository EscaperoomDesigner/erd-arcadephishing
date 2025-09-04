extends Control

const MAIN_PACKED_SCENE: PackedScene = preload("uid://75uq0a777qf6")
const PHISHING_DISPLAY_PACKED_SCENE: PackedScene = preload("uid://dtggel806lv3q")

@export var min_display_time := 3.0     # seconds
@export var max_display_time := 15.0    # seconds

@onready var timer_label: Label = %TimerLabel


var transition_in_progress := false
var waiting_for_crt := false
var phishing_timer_started := false

var elapsed := 0.0
var can_transition := false

func _ready():
	elapsed = 0.0
	can_transition = false
	transition_in_progress = false
	waiting_for_crt = false
	phishing_timer_started = false

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

	if waiting_for_crt:
		if not CrtDisplay._transitioning:
			transition_in_progress = false
			waiting_for_crt = false
		return

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
	waiting_for_crt = true

	CrtDisplay.fade_to_packed(MAIN_PACKED_SCENE)

	if not phishing_timer_started:
		phishing_timer_started = true
		CrtDisplay.show_unfiltered_after_delay(PHISHING_DISPLAY_PACKED_SCENE, 3.0)
