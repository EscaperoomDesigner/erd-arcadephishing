extends Control


const END_PACKED_SCENE: PackedScene = preload("uid://bomsy4dsoap7a")


@onready var timer_label: Label = %TimerLabel
@onready var heart_1: TextureRect = %Heart1
@onready var heart_2: TextureRect = %Heart2
@onready var heart_3: TextureRect = %Heart3

var full_heart_texture: Texture2D = preload("../../assets/images/game/heart.png")
var empty_heart_texture: Texture2D = preload("../../assets/images/game/heart_empty.png")


var game_time := 123.0  # total game time in seconds
var elapsed := 0.0


func _ready():
	# Start game loop
	elapsed = 0
	GameManager.game_running = true
	GameManager.life_lost.connect(_on_life_lost)
	GameManager.game_over.connect(_on_game_over)

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
	print("game over unlucky!")
	GameManager.game_running = false
	CrtDisplay.fade_to_packed(END_PACKED_SCENE, 1.05)


func _on_life_lost(current_lives: int):
	heart_1.texture = full_heart_texture if current_lives >= 1 else empty_heart_texture
	heart_2.texture = full_heart_texture if current_lives >= 2 else empty_heart_texture
	heart_3.texture = full_heart_texture if current_lives >= 3 else empty_heart_texture


func _on_game_over():
	end_game()
