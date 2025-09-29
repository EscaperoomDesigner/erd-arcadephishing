extends Control

@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var heart_1: TextureRect = %Heart1
@onready var heart_2: TextureRect = %Heart2
@onready var heart_3: TextureRect = %Heart3
@onready var yes: TextureRect = %Yes
@onready var no: TextureRect = %No
@onready var countdown_label: Label = %CountdownLabel

var full_heart_texture: Texture2D = preload("../../assets/images/game/heart.png")
var empty_heart_texture: Texture2D = preload("../../assets/images/game/heart_empty.png")
var yes_normal: Texture2D = preload("res://assets/images/game/button_ja.png")
var yes_selected: Texture2D = preload("res://assets/images/game/button_hover_ja.png")
var no_normal: Texture2D = preload("res://assets/images/game/button_nee.png")
var no_selected: Texture2D = preload("res://assets/images/game/button_hover_nee.png")

var game_time: float = GameManager.game_time  # total game time in seconds
var elapsed: float = 0.0
var countdown_active: bool = false
var countdown_time: float = 3.0
var countdown_elapsed: float = 0.0
var time_warning_played: bool = false  # Track if time warning sound has been played
var countdown_sounds_played: Dictionary = {"3": false, "2": false, "1": false, "GO": false}  # Track which sounds have been played
var last_second_played: int = -1  # Track the last second for timer tick sound


func _ready():
	# Initialize UI
	elapsed = 0
	score_label.text = "0"
	countdown_label.visible = true
	countdown_label.text = ""
	last_second_played = -1  # Reset timer tick tracking
	
	# Connect signals
	GameManager.life_lost.connect(_on_life_lost)
	GameManager.game_over.connect(_on_game_over)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.candidate_changed.connect(_on_candidate_changed)
	
	# Start countdown sequence
	_start_countdown()



func _process(delta):
	if countdown_active:
		_handle_countdown(delta)
		return
		
	if not GameManager.game_running:
		return

	# Don't count down timer if showing solution on last life
	if GameManager.lives <= 0 and GameManager.input_lock:
		return

	elapsed += delta
	var remaining = max(game_time - elapsed, 0)
	
	# Play timer tick sound every second
	var current_second = int(remaining)
	if current_second != last_second_played and remaining > 0:
		last_second_played = current_second
		SfxManager.play_time()
	
	
	# Update timer label in MM:SS format
	var minutes = int(remaining) / 60.0
	var seconds = int(remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]


	if remaining <= 0:
		GameManager.timer_ran_out = true
		end_game()


func _start_countdown():
	countdown_active = true
	countdown_elapsed = 0.0
	countdown_label.visible = true
	
	# Reset countdown sounds tracking
	countdown_sounds_played = {"3": false, "2": false, "1": false, "GO": false}
	
	# Don't start the game yet
	GameManager.game_running = false


func _handle_countdown(delta):
	countdown_elapsed += delta
	
	if countdown_elapsed <= 1.0:
		countdown_label.text = "3"
		# Play sound immediately when "3" first appears
		if not countdown_sounds_played["3"]:
			countdown_sounds_played["3"] = true
			SfxManager.play_countdown()
	elif countdown_elapsed <= 2.0:
		countdown_label.text = "2"
		# Play sound immediately when "2" first appears
		if not countdown_sounds_played["2"]:
			countdown_sounds_played["2"] = true
			SfxManager.play_countdown()
	elif countdown_elapsed <= 3.0:
		countdown_label.text = "1"
		# Play sound immediately when "1" first appears
		if not countdown_sounds_played["1"]:
			countdown_sounds_played["1"] = true
			SfxManager.play_countdown()
	elif countdown_elapsed <= 4.0:
		countdown_label.text = "GO!"
		# Play sound immediately when "GO!" first appears
		if not countdown_sounds_played["GO"]:
			countdown_sounds_played["GO"] = true
			SfxManager.play_countdown_ready()
	else:
		# Countdown finished - start the actual game
		_start_actual_game()


func _start_actual_game():
	countdown_active = false
	countdown_label.visible = false
	
	# Show phishing display and start the game
	CrtDisplay.show_unfiltered_after_delay(GameManager.PHISHING_DISPLAY_PACKED_SCENE, 0.0)
	
	# Start the game timer
	GameManager.game_running = true
	elapsed = 0
	time_warning_played = false  # Reset time warning flag


func _is_showing_solution() -> bool:
	# This function may not be needed with the new countdown structure
	# The phishing display is now handled as an overlay
	return false


func end_game():
	GameManager.game_running = false
	GameManager.emit_signal("timer_expired")


func _on_life_lost(current_lives: int):
	heart_1.texture = full_heart_texture if current_lives >= 1 else empty_heart_texture
	heart_2.texture = full_heart_texture if current_lives >= 2 else empty_heart_texture
	heart_3.texture = full_heart_texture if current_lives >= 3 else empty_heart_texture


func _on_game_over():
	end_game()


func _on_score_changed(new_score: int):
	score_label.text = str(new_score)


func _on_candidate_changed(candidate: int):
	match candidate:
		0:  # YES
			yes.texture = yes_selected
			no.texture = no_normal
		1:  # NO
			yes.texture = yes_normal
			no.texture = no_selected
		2:  # None
			yes.texture = yes_normal
			no.texture = no_normal
