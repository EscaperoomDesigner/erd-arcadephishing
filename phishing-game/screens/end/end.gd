extends Control


@export var min_display_time: float = 1.0     # seconds
@export var max_display_time: float = 5.0    # seconds
@export var alphabet := " ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"  # letters to cycle
@export var max_chars := 8  # number of character slots

@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var red_arrow_up: Texture2D = preload("res://assets/images/end/arrow_up.png")
@onready var red_arrow_down: Texture2D = preload("res://assets/images/end/arrow_down.png")
@onready var start_packed_scene: PackedScene = load("uid://c4ma6otpwlva4")
var transition_in_progress := false
var elapsed := 0.0
var can_transition := false
var name_selection_complete := false  # Prevent multiple saves

var rows: Array = []        # holds each VBoxContainer row (tex1, label, tex2)
var current_index := 0      # which character slot we're editing
var char_index := 0         # current letter in alphabet for this slot
var is_high_score := false


func _ready():
	elapsed = 0.0
	can_transition = false
	transition_in_progress = false
	name_selection_complete = false  # Reset the flag
	score_label.text = GameManager.get_score()
	
	# Continue playing game music for end screen
	MusicManager.play_game_music()
	
	# Check if this is a high score
	is_high_score = GameManager.check_high_score()
	
	# If not a high score, show top scores and allow quick exit
	if not is_high_score:
		_show_high_scores_info()
		# Allow faster transition for non-high scores
		min_display_time = 2.0
	else:
		print("New high score achieved! Enter your name.")

	# Grab all rows dynamically
	var hbox: HBoxContainer = %HBoxContainer
	for vbox in hbox.get_children():
		if vbox is VBoxContainer:
			var tex_up: TextureRect = vbox.get_child(0)
			var label: Label = vbox.get_child(1)
			var tex_down: TextureRect = vbox.get_child(2)
			label.text = ""
			rows.append({ "tex_up": tex_up, "label": label, "tex_down": tex_down })

	# Initialize first letter
	char_index = 0
	_update_current_label()


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
		# Force complete name selection before transitioning to ensure high score is saved
		if not name_selection_complete:
			_finish_name_selection()
		else:
			_start_transition()

	# Block input while transitioning or if name selection is complete
	if transition_in_progress or name_selection_complete:
		return

	# Allow quick exit only after name entry is complete
	# (removed the quick exit for non-high scores since all players can now enter names)

	# Name entry controls (for all players)
	if Input.is_action_just_pressed("phishing_up"):
		char_index = (char_index + 1) % alphabet.length()
		_update_current_label()
	elif Input.is_action_just_pressed("phishing_down"):
		char_index = (char_index - 1 + alphabet.length()) % alphabet.length()
		_update_current_label()

	if Input.is_action_just_pressed("phishing_confirm"):
		# Check bounds before accessing
		if current_index < rows.size():
			# Change the TextureRects to red arrows for this slot
			var row = rows[current_index]
			row["tex_up"].texture = red_arrow_up
			row["tex_down"].texture = red_arrow_down

		current_index += 1
		if current_index >= rows.size():
			_finish_name_selection()
		else:
			char_index = 0  # reset for next slot
			_update_current_label()



func _update_current_label():
	if current_index < rows.size() and char_index < alphabet.length():
		rows[current_index]["label"].text = alphabet[char_index]
	else:
		print("Warning: Index out of bounds in _update_current_label - current_index: %d, rows.size(): %d, char_index: %d, alphabet.length(): %d" % [current_index, rows.size(), char_index, alphabet.length()])


func _finish_name_selection():
	# Prevent multiple calls
	if name_selection_complete:
		return
		
	name_selection_complete = true
	print("Name selection done!")
	var chosen_name = ""
	
	# If we're in the middle of selecting a character (timer ran out), 
	# include the current character being displayed
	var slots_to_process = current_index
	if current_index < rows.size() and current_index < max_chars:
		# Include the current character if it's being displayed
		if rows[current_index]["label"].text != "":
			slots_to_process = current_index + 1
	
	# Build name from completed slots
	for i in range(min(slots_to_process, min(rows.size(), max_chars))):
		if i < rows.size():
			var char_text = rows[i]["label"].text
			if char_text != "":
				chosen_name += char_text
	
	GameManager.player_name = chosen_name.strip_edges()
	
	# Always save the score, regardless of whether it's a high score
	GameManager.save_high_score()

	# Wait for transition to be available, then start it
	if can_transition:
		_start_transition()
	else:
		while not can_transition and not transition_in_progress:
			await get_tree().process_frame
		if not transition_in_progress:  # Only start if not already transitioning
			_start_transition()


func _show_high_scores_info():
	print("Current high scores:")
	print(HighScoreManager.get_high_scores_text())
	
	# You could add UI elements here to display high scores on screen
	# For now, we'll just print them to console


func _start_transition():
	if transition_in_progress:
		return
	transition_in_progress = true
	
	GameManager.reset_game()
	CrtDisplay.fade_to_packed(start_packed_scene, 1.05)
