extends Control

@onready var vbox_container = $BackgroundRect/MarginContainer/VBoxContainer
@onready var start_packed_scene: PackedScene = load("uid://c4ma6otpwlva4")

const SCORE_HBOX_SCENE = preload("res://component/score_hbox/score_hbox.tscn")

var transition_in_progress := false
var waiting_for_crt := false
var scene_ready := false

func _ready():
	# Connect to high score manager signal to auto-refresh
	if HighScoreManager.new_high_score.connect(_on_new_high_score) != OK:
		print("Failed to connect to new_high_score signal")
	
	display_high_scores()

	# Wait for CRT transition to complete before allowing input
	while CrtDisplay._transitioning:
		await get_tree().process_frame
	
	# Small delay to prevent immediate input after scene transition
	await get_tree().create_timer(0.5).timeout
	scene_ready = true


func _process(_delta):
	if waiting_for_crt:
		if not CrtDisplay._transitioning:
			# Fade finished, allow input again
			transition_in_progress = false
			waiting_for_crt = false
		return

	# If a transition is in progress or scene not ready, ignore input
	if transition_in_progress or not scene_ready:
		return

	# Handle confirm input to go back to start screen
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
	
	# Display up to 10 high scores
	var max_display = min(10, high_scores.size())
	
	if max_display == 0:
		# Show "No scores yet" message
		var no_scores_label = Label.new()
		no_scores_label.text = "No high scores yet!"
		no_scores_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_scores_label.add_theme_font_size_override("font_size", 16)
		no_scores_label.add_theme_color_override("font_color", Color.WHITE)
		vbox_container.add_child(no_scores_label)
		return
	
	# Create score entries (header already exists in scene)
	for i in range(max_display):
		var score_entry = high_scores[i]
		var score_hbox = SCORE_HBOX_SCENE.instantiate()
		
		# Format the date to be shorter (just date, no time)
		var date_parts = score_entry.date.split("T")
		var formatted_date = date_parts[0] if date_parts.size() > 0 else score_entry.date
		
		vbox_container.add_child(score_hbox)
		
		# Use call_deferred to ensure the node is ready
		score_hbox.call_deferred("set_score_data", score_entry.name, score_entry.score, formatted_date)

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
