extends Node

# Music tracks
var main_music: AudioStream = preload("res://assets/sounds/music/main.wav")
var game_music: AudioStream = preload("res://assets/sounds/music/game.wav")

# Audio player
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

# Current music state
var current_track: AudioStream
var is_playing: bool = false

# Volume settings
var music_volume: float
var fade_duration: float = 1.0

enum MusicTrack {
	NONE,
	MAIN_MENU,
	GAME
}

func _ready():
	# Connect to SettingsManager and load volume
	call_deferred("_initialize_with_settings")
	
	# Start with main menu music
	play_main_menu_music()

func _initialize_with_settings():
	# This runs after all autoloads are ready
	var settings_manager = get_node("/root/SettingsManager")
	if settings_manager:
		# Connect to both signals
		settings_manager.settings_changed.connect(_on_settings_changed)
		settings_manager.settings_loaded.connect(_on_settings_loaded)
		
		# Load current volume
		_on_settings_loaded()

func _on_settings_loaded():
	# Called when settings are first loaded or reloaded
	var settings_manager = get_node("/root/SettingsManager")
	if settings_manager:
		_apply_volume_settings(settings_manager)

func _apply_volume_settings(settings_manager):
	# SettingsManager now handles audio bus volumes directly
	# We just need to track the current volume for internal use
	music_volume = settings_manager.get_music_volume_normalized()

	# Ensure audio player volume is at default (bus handles actual volume)
	if audio_player:
		audio_player.volume_db = 0.0

func _on_settings_changed():
	# Reuse the same logic as settings_loaded
	_on_settings_loaded()

func play_main_menu_music():
	_play_track(main_music, true)

func play_game_music():
	_play_track(game_music, true)

func stop_music():
	if audio_player and audio_player.playing:
		audio_player.stop()
	is_playing = false
	current_track = null

func fade_out_and_stop():
	if not audio_player or not audio_player.playing:
		return
		
	var tween = create_tween()
	if tween:
		tween.tween_method(_set_volume_db, audio_player.volume_db, -80.0, fade_duration)
		tween.tween_callback(stop_music)
	else:
		# Fallback if tween creation fails
		stop_music()

func _play_track(track: AudioStream, loop: bool = true):
	if not track or not audio_player:
		return
		
	# Don't restart the same track if it's already playing
	if current_track == track and audio_player.playing:
		return
		
	# Fade out current music if playing
	if audio_player.playing and current_track != track:
		var tween = create_tween()
		if tween:
			tween.tween_method(_set_volume_db, audio_player.volume_db, -80.0, fade_duration * 0.5)
			tween.tween_callback(_start_new_track.bind(track, loop))
		else:
			# Fallback if tween creation fails
			_start_new_track(track, loop)
	else:
		_start_new_track(track, loop)

func _start_new_track(track: AudioStream, _loop: bool):
	if not audio_player or not track:
		return
		
	audio_player.stream = track
	current_track = track
	
	# Set volume to 0 for fade in
	audio_player.volume_db = -80.0
	audio_player.play()
	
	# Fade in
	var tween = create_tween()
	if tween:
		tween.tween_method(_set_volume_db, -80.0, 0.0, fade_duration * 0.5)
	else:
		# Fallback if tween creation fails - set volume directly
		audio_player.volume_db = 0.0
	
	is_playing = true

func _set_volume_db(volume_db: float):
	if audio_player:
		audio_player.volume_db = volume_db
