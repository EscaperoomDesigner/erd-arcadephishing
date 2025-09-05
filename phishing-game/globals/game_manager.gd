extends Node

signal life_lost(current_lives: int)
signal game_over()
signal score_changed(new_score: int)
signal candidate_changed(candidate: int)


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


func reset_game():
	lives = 3
	score = 0
	game_running = false
	pending_game_over = false
	input_lock = false
