extends Node

# SFX Manager - Global
# Audio players for different types of sounds
@onready var ui_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var game_player: AudioStreamPlayer = $AudioStreamPlayer2
@onready var countdown_player: AudioStreamPlayer = $AudioStreamPlayer3
@onready var timer_player: AudioStreamPlayer = $AudioStreamPlayer4

# Preloaded sound effects
var ui_hover_sound: AudioStream = preload("res://assets/sounds/sfx/UIhover.wav")
var ui_select_sound: AudioStream = preload("res://assets/sounds/sfx/UIselect.wav")
var countdown_sound: AudioStream = preload("res://assets/sounds/sfx/countdown.wav")
var countdown_ready_sound: AudioStream = preload("res://assets/sounds/sfx/countdownready.wav")

# Game sound effects from effectsold folder
var correct_sound: AudioStream = preload("res://assets/sounds/effectsold/correct.wav")
var wrong_sound: AudioStream = preload("res://assets/sounds/effectsold/wrong.wav")
var life_lost_sound: AudioStream = preload("res://assets/sounds/effectsold/dead.wav")
var time_sound: AudioStream = preload("res://assets/sounds/effectsold/time.wav")
var beep_up_sound: AudioStream = preload("res://assets/sounds/effectsold/beepup.wav")
var beep_down_sound: AudioStream = preload("res://assets/sounds/effectsold/beepdwn.wav")

# Volume settings (0.0 to 1.0)
var master_volume: float
var sfx_volume: float
var ui_volume: float

func _ready():
	
	# Connect to SettingsManager and load volume
	call_deferred("_initialize_with_settings")
	
	# Configure volumes
	_update_volumes()

func _initialize_with_settings():
	# This runs after all autoloads are ready
	var settings_manager = get_node("/root/SettingsManager")
	if settings_manager:
		# Connect to settings signals
		settings_manager.settings_changed.connect(_on_settings_changed)
		settings_manager.settings_loaded.connect(_on_settings_loaded)
		
		# Load current volumes
		_on_settings_loaded()

func _on_settings_loaded():
	# Called when settings are first loaded or reloaded
	var settings_manager = get_node("/root/SettingsManager")
	if settings_manager:
		# Update our internal volume variable for compatibility
		master_volume = settings_manager.get_master_volume_normalized()

func _on_settings_changed():
	# Reuse the same logic as settings_loaded
	_on_settings_loaded()

func _update_volumes():
	# Since we're using audio buses, we don't need to set individual player volumes
	# The SettingsManager handles the Master and SFX bus volumes
	# Keep player volumes at default (0 dB) - buses handle the actual volume control
	if ui_player:
		ui_player.volume_db = 0.0
	if game_player:
		game_player.volume_db = 0.0
	if countdown_player:
		countdown_player.volume_db = 0.0
	if timer_player:
		timer_player.volume_db = 0.0

# UI Sound Effects
func play_ui_hover():
	if ui_hover_sound and ui_player:
		ui_player.stream = ui_hover_sound
		ui_player.play()

func play_ui_select():
	if ui_select_sound and ui_player:
		ui_player.stream = ui_select_sound
		ui_player.play()

# Game Sound Effects
func play_countdown():
	if countdown_sound and countdown_player:
		countdown_player.stream = countdown_sound
		countdown_player.play()

func play_countdown_ready():
	if countdown_ready_sound and countdown_player:
		countdown_player.stream = countdown_ready_sound
		countdown_player.play()

func play_correct_answer():
	if correct_sound and game_player:
		game_player.stream = correct_sound
		game_player.play()

func play_wrong_answer():
	if wrong_sound and game_player:
		game_player.stream = wrong_sound
		game_player.play()

func play_life_lost():
	if life_lost_sound and game_player:
		game_player.stream = life_lost_sound
		game_player.play()

func play_time():
	if time_sound and timer_player:
		timer_player.stream = time_sound
		timer_player.play()

func play_beep_up():
	if beep_up_sound and ui_player:
		ui_player.stream = beep_up_sound
		ui_player.play()

func play_beep_down():
	if beep_down_sound and ui_player:
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
		"timer":
			player = timer_player
		_:
			player = game_player
	
	if player:
		player.stream = sound
		player.play()

# Volume control functions (deprecated - use SettingsManager instead)
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)

func set_ui_volume(volume: float):
	ui_volume = clamp(volume, 0.0, 1.0)

# Utility functions
func stop_all_sounds():
	if ui_player:
		ui_player.stop()
	if game_player:
		game_player.stop()
	if countdown_player:
		countdown_player.stop()
	if timer_player:
		timer_player.stop()

func is_playing(player_type: String = "game") -> bool:
	match player_type:
		"ui":
			return ui_player && ui_player.playing
		"countdown":
			return countdown_player && countdown_player.playing
		"timer":
			return timer_player && timer_player.playing
		_:
			return game_player && game_player.playing
