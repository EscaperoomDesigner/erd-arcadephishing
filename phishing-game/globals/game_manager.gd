extends Node

# Signals
signal life_lost(current_lives: int)
signal game_over()

# Game state
var lives: int = 3
var score: int = 0

func lose_life():
	lives -= 1
	emit_signal("life_lost", lives)
	if lives <= 0:
		emit_signal("game_over")
