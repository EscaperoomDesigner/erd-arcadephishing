extends Control

@onready var timer_label: Label = %TimerLabel

var game_time := 123.0  # total game time in seconds
var elapsed := 0.0
var game_running := false

func _ready():
	# Start game loop
	elapsed = 0
	game_running = true

func _process(delta):
	if not game_running:
		return

	elapsed += delta
	var remaining = max(game_time - elapsed, 0)
	
	# Update timer label in MM:SS format
	var minutes = int(remaining) / 60.0
	var seconds = int(remaining) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]

	if remaining <= 0:
		end_game()

func end_game():
	game_running = false
	print("Game over!")
