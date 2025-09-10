extends Node

signal life_lost(current_lives: int)
signal game_over()
signal score_changed(new_score: int)
signal candidate_changed(candidate: int)
signal high_score_achieved(position: int)
signal timer_expired()


const START_PACKED_SCENE: PackedScene = preload("uid://c4ma6otpwlva4")
const TUTORIAL_PACKED_SCENE: PackedScene = preload("uid://b0ckh3uehbwwd")
const MAIN_PACKED_SCENE: PackedScene = preload("uid://75uq0a777qf6")
const PHISHING_DISPLAY_PACKED_SCENE: PackedScene = preload("uid://dtggel806lv3q")
const END_PACKED_SCENE: PackedScene = preload("uid://bomsy4dsoap7a")

var lives: int = 3
var score: int = 0
var game_running: bool = false
var pending_game_over: bool = false 
var input_lock: bool = false
var player_name: String = ""
var is_new_high_score: bool = false
var high_score_position: int = -1
var timer_ran_out: bool = false
var start_game_blocked: bool = false  # Prevent double start game calls

func lose_life(showing_solution: bool = false):
	lives -= 1
	emit_signal("life_lost", lives)

	if lives <= 0:
		if showing_solution:
			pending_game_over = true
		else:
			emit_signal("game_over")


func add_score(points: int = 1):
	score += points
	emit_signal("score_changed", score)


func get_score():
	return str(score)


func check_high_score() -> bool:
	return HighScoreManager.is_high_score(score)


func save_high_score():
	if player_name.strip_edges().is_empty():
		player_name = "ANONYMOUS"
	
	high_score_position = HighScoreManager.add_high_score(player_name, score)
	is_new_high_score = true
	emit_signal("high_score_achieved", high_score_position)


func reset_game():
	lives = 3
	score = 0
	game_running = false
	pending_game_over = false
	input_lock = false
	is_new_high_score = false
	high_score_position = -1
	player_name = ""
	timer_ran_out = false
	start_game_blocked = false  # Reset the start game block


# Debug function to set score for testing
func set_score_for_testing(new_score: int):
	score = new_score
	emit_signal("score_changed", score)
