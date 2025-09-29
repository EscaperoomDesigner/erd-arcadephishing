extends Node

# SFX Manager - Global singleton for handling sound effects across all screens
# Add this to AutoLoad in Project Settings as "SfxManager"

# Audio players for different types of sounds
@onready var ui_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var game_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var countdown_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Preloaded sound effects
var ui_hover_sound: AudioStream = preload("res://assets/sounds/sfx/UIhover.wav")
var ui_select_sound: AudioStream = preload("res://assets/sounds/sfx/UIselect.wav")
var countdown_sound: AudioStream = preload("res://assets/sounds/sfx/countdown.wav")
var countdown_ready_sound: AudioStream = preload("res://assets/sounds/sfx/countdownready.wav")

# Game sound effects from effectsold folder
var correct_sound: AudioStream = preload("res://assets/sounds/effectsold/correct.wav")
var wrong_sound: AudioStream = preload("res://assets/sounds/effectsold/wrong.wav")
var life_lost_sound: AudioStream = preload("res://assets/sounds/effectsold/dead.wav")
var time_warning_sound: AudioStream = preload("res://assets/sounds/effectsold/time.wav")
var beep_up_sound: AudioStream = preload("res://assets/sounds/effectsold/beepup.wav")
var beep_down_sound: AudioStream = preload("res://assets/sounds/effectsold/beepdwn.wav")

# Volume settings (0.0 to 1.0)
var master_volume: float = 1.0
var sfx_volume: float = 0.7
var ui_volume: float = 0.5

func _ready():
	# Add audio players to the scene tree
	add_child(ui_player)
	add_child(game_player)
	add_child(countdown_player)
	
	# Set up audio players
	ui_player.name = "UIPlayer"
	game_player.name = "GamePlayer"
	countdown_player.name = "CountdownPlayer"
	
	# Configure volumes
	_update_volumes()

func _update_volumes():
	ui_player.volume_db = linear_to_db(master_volume * ui_volume)
	game_player.volume_db = linear_to_db(master_volume * sfx_volume)
	countdown_player.volume_db = linear_to_db(master_volume * sfx_volume)

# UI Sound Effects
func play_ui_hover():
	if ui_hover_sound:
		ui_player.stream = ui_hover_sound
		ui_player.play()

func play_ui_select():
	if ui_select_sound:
		ui_player.stream = ui_select_sound
		ui_player.play()

# Game Sound Effects
func play_countdown():
	if countdown_sound:
		countdown_player.stream = countdown_sound
		countdown_player.play()

func play_countdown_ready():
	if countdown_ready_sound:
		countdown_player.stream = countdown_ready_sound
		countdown_player.play()

func play_correct_answer():
	if correct_sound:
		game_player.stream = correct_sound
		game_player.play()

func play_wrong_answer():
	if wrong_sound:
		game_player.stream = wrong_sound
		game_player.play()

func play_life_lost():
	if life_lost_sound:
		game_player.stream = life_lost_sound
		game_player.play()

func play_time_warning():
	if time_warning_sound:
		game_player.stream = time_warning_sound
		game_player.play()

func play_beep_up():
	if beep_up_sound:
		ui_player.stream = beep_up_sound
		ui_player.play()

func play_beep_down():
	if beep_down_sound:
		ui_player.stream = beep_down_sound
		ui_player.play()

# Generic function to play any sound
func play_sound(sound: AudioStream, player_type: String = "game"):
	if not sound:
		return
		
	var player: AudioStreamPlayer
	match player_type:
		"ui":
			player = ui_player
		"countdown":
			player = countdown_player
		_:
			player = game_player
	
	player.stream = sound
	player.play()

# Volume control functions
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()

func set_ui_volume(volume: float):
	ui_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()

# Utility functions
func stop_all_sounds():
	ui_player.stop()
	game_player.stop()
	countdown_player.stop()

func is_playing(player_type: String = "game") -> bool:
	match player_type:
		"ui":
			return ui_player.playing
		"countdown":
			return countdown_player.playing
		_:
			return game_player.playing
