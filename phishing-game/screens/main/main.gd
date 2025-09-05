extends Control

@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var heart_1: TextureRect = %Heart1
@onready var heart_2: TextureRect = %Heart2
@onready var heart_3: TextureRect = %Heart3
@onready var yes: TextureRect = %Yes
@onready var no: TextureRect = %No

var full_heart_texture: Texture2D = preload("../../assets/images/game/heart.png")
var empty_heart_texture: Texture2D = preload("../../assets/images/game/heart_empty.png")
var yes_normal: Texture2D = preload("res://assets/images/game/button_ja.png")
var yes_selected: Texture2D = preload("res://assets/images/game/button_hover_ja.png")
var no_normal: Texture2D = preload("res://assets/images/game/button_nee.png")
var no_selected: Texture2D = preload("res://assets/images/game/button_hover_nee.png")

var game_time := 123.0  # total game time in seconds
var elapsed := 0.0


func _ready():
	# Start game loop
	elapsed = 0
	score_label.text = "0"
	GameManager.game_running = true
	GameManager.life_lost.connect(_on_life_lost)
	GameManager.game_over.connect(_on_game_over)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.candidate_changed.connect(_on_candidate_changed)



func _process(delta):
	if not GameManager.game_running:
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
	GameManager.game_running = false
	print("game over unlucky!")


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
