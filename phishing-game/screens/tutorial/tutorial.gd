extends Control


@export var min_display_time := 1.0     # seconds
@export var max_display_time := 15.0    # seconds

@onready var timer_label: Label = %TimerLabel



var transition_in_progress: bool = false
var waiting_for_crt: bool = false
var phishing_timer_started: bool = false
var elapsed: float = 0.0
var can_transition: bool = false

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
	if can_transition && not GameManager.input_lock:
		if Input.is_action_just_pressed("phishing_confirm"):
			_start_transition()

func _start_transition():
	if transition_in_progress:
		return
	transition_in_progress = true
	waiting_for_crt = true
	GameManager.input_lock = true
	
	
	CrtDisplay.fade_to_packed(GameManager.MAIN_PACKED_SCENE)

	# Only start phishing display if it hasn't started
	if not phishing_timer_started:
		phishing_timer_started = true
		
		# Show phishing display after 3s delay
		CrtDisplay.show_unfiltered_after_delay(GameManager.PHISHING_DISPLAY_PACKED_SCENE, 3.0)

		# Unlock input after 3s + tween time (match show_unfiltered_after_delay)
		var total_delay = 3.0 + 0.85  # delay + tween_time
		var timer = get_tree().create_timer(total_delay)
		timer.timeout.connect(func():
			GameManager.input_lock = false  # <-- unlock input
		)
