extends Node

signal life_lost(current_lives: int)
signal game_over()
signal solution_shown_finished()

var lives: int = 3
var score: int = 0
var game_running: bool = false
var pending_game_over: bool = false 

func lose_life(showing_solution: bool = false):
	lives -= 1
	emit_signal("life_lost", lives)

	if lives <= 0:
		if showing_solution:
			pending_game_over = true
		else:
			emit_signal("game_over")

func solution_finished():
	emit_signal("solution_shown_finished")

	if pending_game_over and lives <= 0:
		pending_game_over = false
		emit_signal("game_over")
