extends Control

@onready var scroll_container = %ScrollContainer
@onready var vbox_container = %ScoresVBox
@onready var start_packed_scene: PackedScene = load("uid://c4ma6otpwlva4")

const SCORE_HBOX_SCENE = preload("res://component/score_hbox/score_hbox.tscn")

const AUTO_RETURN_TIME: float = 30.0

# Auto-scrolling billboard configuration
const SCROLL_SPEED: float = 30.0        # Pixels per second for auto-scroll
const MANUAL_SCROLL_SPEED: float = 200.0 # Pixels per second for manual scroll
const BOTTOM_PAUSE_DURATION: float = 3.0 # Pause at bottom before going to start
const MANUAL_RESUME_DELAY: float = 3.0   # Seconds of inactivity before auto-scroll resumes

# Auto-scrolling state
enum ScrollState {
	SCROLLING_DOWN,
	BOTTOM_PAUSE,
	MANUAL_SCROLL
}

var scroll_state: ScrollState = ScrollState.SCROLLING_DOWN
var scroll_timer: float = 0.0
var manual_idle_timer: float = 0.0
var auto_scroll_enabled: bool = false
var scroll_position: float = 0.0  # Float accumulator for sub-pixel smooth scrolling

var transition_in_progress := false
var waiting_for_crt := false
var scene_ready := false
var idle_time: float = 0.0

func _ready():
	# Connect to high score manager signal to auto-refresh
	if HighScoreManager.new_high_score.connect(_on_new_high_score) != OK:
		print("Failed to connect to new_high_score signal")
	
	display_high_scores()
	
	# Play main menu music for highscore screen
	MusicManager.play_main_menu_music()

	# Wait for CRT transition to complete before allowing input
	while CrtDisplay._transitioning:
		await get_tree().process_frame
	
	# Small delay to prevent immediate input after scene transition
	await get_tree().create_timer(0.5).timeout
	scene_ready = true
	
	# Check if auto-scrolling should be enabled
	await get_tree().process_frame  # Wait for layout to calculate
	var high_scores = HighScoreManager.get_high_scores()
	_check_auto_scroll_enabled(high_scores.size())


func _process(delta):
	if waiting_for_crt:
		if not CrtDisplay._transitioning:
			# Fade finished, allow input again
			transition_in_progress = false
			waiting_for_crt = false
		return

	# If a transition is in progress or scene not ready, ignore input
	if transition_in_progress or not scene_ready:
		return

	# Always handle scroll input (manual up/down), and auto-scroll when enabled
	if scroll_container:
		_handle_scroll(delta)

	# No auto-scroll: fall back to idle timer for return
	if not auto_scroll_enabled:
		idle_time += delta
		if idle_time >= AUTO_RETURN_TIME:
			_go_back_to_start()

	# Always allow manual skip
	if Input.is_action_just_pressed("phishing_confirm"):
		_go_back_to_start()

func _go_back_to_start():
	if transition_in_progress:
		return
		
	transition_in_progress = true
	waiting_for_crt = true
	
	# Load the start scene
	CrtDisplay.fade_to_packed(start_packed_scene)

func _on_new_high_score():
	# Automatically refresh when new scores are added
	refresh_high_scores()

func display_high_scores():
	# Clear any existing score entries
	clear_score_entries()
	
	# Get high scores from the manager
	var high_scores = HighScoreManager.get_high_scores()
	
	# Display ALL high scores (unlimited)
	var score_count = high_scores.size()
	
	if score_count == 0:
		# Show "No scores yet" message
		var no_scores_label = Label.new()
		no_scores_label.text = "Nog geen high scores beschikbaar!"
		no_scores_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_scores_label.add_theme_font_size_override("font_size", 16)
		no_scores_label.add_theme_color_override("font_color", Color.WHITE)
		vbox_container.add_child(no_scores_label)
		return
	
	# Create score entries for ALL scores (header already exists in scene)
	var last = HighScoreManager.last_added_entry
	for i in range(score_count):
		var score_entry = high_scores[i]
		var score_hbox = SCORE_HBOX_SCENE.instantiate()

		# Format the date to be shorter (just date, no time)
		var date_parts = score_entry.date.split("T")
		var date_ymd = date_parts[0] if date_parts.size() > 0 else score_entry.date
		var ymd = date_ymd.split("-")
		var formatted_date = "%s/%s/%s" % [ymd[2], ymd[1], ymd[0]] if ymd.size() == 3 else date_ymd

		vbox_container.add_child(score_hbox)

		# Use call_deferred to ensure the node is ready, and pass rank (i + 1)
		score_hbox.call_deferred("set_score_data", score_entry.name, score_entry.score, formatted_date, i + 1)

		# Highlight the entry that was just achieved (matched by datetime, which is unique per entry)
		if not last.is_empty() and score_entry.get("date", "") == last.get("date", ""):
			score_hbox.call_deferred("highlight")
	
	# Wait for layout to calculate, then check if auto-scroll should be enabled
	await get_tree().process_frame
	_check_auto_scroll_enabled(score_count)

func clear_score_entries():
	# Remove all children except the title label and header (first 2 children)
	var children_to_remove = []
	var keep_count = 2 # Title + Header
	
	for i in range(keep_count, vbox_container.get_child_count()):
		children_to_remove.append(vbox_container.get_child(i))
	
	for child in children_to_remove:
		child.queue_free()

func refresh_high_scores():
	# Call this method to refresh the display when scores change
	display_high_scores()

func _check_auto_scroll_enabled(score_count: int):
	# Enable auto-scroll when there are 15 or more high scores
	if not scroll_container or not vbox_container:
		auto_scroll_enabled = false
		return
	
	auto_scroll_enabled = score_count >= 15
	
	if auto_scroll_enabled:
		scroll_state = ScrollState.SCROLLING_DOWN
		scroll_timer = 0.0
		scroll_position = 0.0
		manual_idle_timer = 0.0
		print("Auto-scroll enabled: %d scores (>=15)" % score_count)
	else:
		print("Auto-scroll disabled: only %d scores (<15)" % score_count)

func _handle_scroll(delta: float):
	var scroll_bar = scroll_container.get_v_scroll_bar()
	var max_scroll: float = scroll_bar.max_value - scroll_bar.page

	# Manual input always takes priority
	var pressing_up   = Input.is_action_pressed("phishing_up")
	var pressing_down = Input.is_action_pressed("phishing_down")

	if pressing_up or pressing_down:
		manual_idle_timer = 0.0
		scroll_state = ScrollState.MANUAL_SCROLL
		var dir = -1.0 if pressing_up else 1.0
		scroll_position = clamp(scroll_position + dir * MANUAL_SCROLL_SPEED * delta, 0.0, max_scroll)
		scroll_container.scroll_vertical = int(scroll_position)
		return

	# No manual input — run state machine
	match scroll_state:
		ScrollState.MANUAL_SCROLL:
			# Wait for inactivity before resuming auto-scroll
			manual_idle_timer += delta
			if manual_idle_timer >= MANUAL_RESUME_DELAY:
				manual_idle_timer = 0.0
				scroll_state = ScrollState.SCROLLING_DOWN

		ScrollState.SCROLLING_DOWN:
			if not auto_scroll_enabled or max_scroll <= 0:
				return

			scroll_position += SCROLL_SPEED * delta
			if scroll_position >= max_scroll:
				scroll_position = max_scroll
				scroll_container.scroll_vertical = int(scroll_position)
				scroll_timer = 0.0
				scroll_state = ScrollState.BOTTOM_PAUSE
			else:
				scroll_container.scroll_vertical = int(scroll_position)

		ScrollState.BOTTOM_PAUSE:
			# Pause at the bottom, then return to start screen
			scroll_timer += delta
			if scroll_timer >= BOTTOM_PAUSE_DURATION:
				_go_back_to_start()
