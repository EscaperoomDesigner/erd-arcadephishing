extends Control

@onready var master_volume_minus: TextureRect = %MasterVolumeMinus
@onready var master_volume_plus: TextureRect = %MasterVolumePlus
@onready var music_volume_minus: TextureRect = %MusicVolumeMinus
@onready var music_volume_plus: TextureRect = %MusicVolumePlus
@onready var terug_button: TextureRect = %TerugButton
@onready var master_volume_progress: ProgressBar = %MasterProgressBar
@onready var music_volume_progress: ProgressBar = %MusicProgressBar

@onready var start_packed_scene: PackedScene = load("uid://c4ma6otpwlva4")

var button_default: Texture2D = preload("res://assets/images/options/optionsbutton.png")
var button_selected: Texture2D = preload("res://assets/images/options/optionsbutton_selected.png")

var terug_button_default: Texture2D = preload("res://assets/images/menu/button_default.png")
var terug_button_selected: Texture2D = preload("res://assets/images/menu/button_selected.png")

var transition_in_progress := false  # Prevent multiple triggers
var waiting_for_crt := false         # Flag to wait until fade completes
var scene_ready := false             # Prevent immediate input on scene load

# Navigation state
enum OptionRow { MASTER_VOLUME, MUSIC_VOLUME, BACK }
var current_row: OptionRow = OptionRow.MASTER_VOLUME

# Volume levels (0-10) - loaded from SettingsManager
var master_volume_level: int = 10
var music_volume_level: int = 10

func _ready():
	# Load settings from SettingsManager
	_load_settings_from_manager()
	
	# Initialize progress bars
	master_volume_progress.max_value = 10
	master_volume_progress.value = master_volume_level
	music_volume_progress.max_value = 10
	music_volume_progress.value = music_volume_level
	
	_update_button_display()
	
	# Play main menu music for options screen
	MusicManager.play_main_menu_music()
	
	# Wait for CRT transition to complete before allowing input
	while CrtDisplay._transitioning:
		await get_tree().process_frame
	
	# Small delay to prevent immediate input after scene transition
	await get_tree().create_timer(0.5).timeout
	scene_ready = true

func _process(_delta):
	if waiting_for_crt:
		if not CrtDisplay._transitioning:
			# Fade finished, allow input again
			transition_in_progress = false
			waiting_for_crt = false
		return

	# If a transition is in progress or scene not ready, ignore input
	if transition_in_progress or not scene_ready:
		return

	# Vertical navigation (UP/DOWN)
	if Input.is_action_just_pressed("phishing_up"):
		match current_row:
			OptionRow.MUSIC_VOLUME:
				current_row = OptionRow.MASTER_VOLUME
			OptionRow.BACK:
				current_row = OptionRow.MUSIC_VOLUME
			OptionRow.MASTER_VOLUME:
				current_row = OptionRow.BACK  # Wrap to bottom
		_update_button_display()
		SfxManager.play_ui_hover()
	elif Input.is_action_just_pressed("phishing_down"):
		match current_row:
			OptionRow.MASTER_VOLUME:
				current_row = OptionRow.MUSIC_VOLUME
			OptionRow.MUSIC_VOLUME:
				current_row = OptionRow.BACK
			OptionRow.BACK:
				current_row = OptionRow.MASTER_VOLUME  # Wrap to top
		_update_button_display()
		SfxManager.play_ui_hover()

	# Horizontal navigation (LEFT/RIGHT) - for volume controls
	if Input.is_action_just_pressed("phishing_yes"):  # LEFT (decrease volume)
		match current_row:
			OptionRow.MASTER_VOLUME:
				master_volume_level = max(0, master_volume_level - 1)
				_apply_master_volume()
				_update_button_display()
				SfxManager.play_ui_hover()
			OptionRow.MUSIC_VOLUME:
				music_volume_level = max(0, music_volume_level - 1)
				_apply_music_volume()
				_update_button_display()
				SfxManager.play_ui_hover()
	elif Input.is_action_just_pressed("phishing_no"):  # RIGHT (increase volume)
		match current_row:
			OptionRow.MASTER_VOLUME:
				master_volume_level = min(10, master_volume_level + 1)
				_apply_master_volume()
				_update_button_display()
				SfxManager.play_ui_hover()
			OptionRow.MUSIC_VOLUME:
				music_volume_level = min(10, music_volume_level + 1)
				_apply_music_volume()
				_update_button_display()
				SfxManager.play_ui_hover()

	# Selection (CONFIRM)
	if Input.is_action_just_pressed("phishing_confirm"):
		SfxManager.play_ui_select()
		match current_row:
			OptionRow.BACK:
				_go_back_to_start()

func _update_button_display():
	# Reset all buttons to default state
	master_volume_minus.texture = button_default
	master_volume_plus.texture = button_default
	music_volume_minus.texture = button_default
	music_volume_plus.texture = button_default
	terug_button.texture = terug_button_default
	
	# Update based on current selection
	match current_row:
		OptionRow.MASTER_VOLUME:
			# Highlight master volume controls
			master_volume_minus.texture = button_selected
			master_volume_plus.texture = button_selected
		OptionRow.MUSIC_VOLUME:
			# Highlight music volume controls
			music_volume_minus.texture = button_selected
			music_volume_plus.texture = button_selected
		OptionRow.BACK:
			# Highlight back button
			terug_button.texture = terug_button_selected

func _apply_master_volume():
	master_volume_progress.value = master_volume_level
	# Apply master volume to SfxManager or AudioServer
	# You might want to implement this in SfxManager
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager:
		settings_manager.set_master_volume(master_volume_level)
	print("Master volume set to: ", master_volume_level)

func _apply_music_volume():
	music_volume_progress.value = music_volume_level
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager:
		settings_manager.set_music_volume(music_volume_level)
	print("Music volume set to: ", music_volume_level)

func _load_settings_from_manager():
	# Load settings from the global SettingsManager
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager:
		master_volume_level = settings_manager.get_master_volume()
		music_volume_level = settings_manager.get_music_volume()
		print("Settings loaded from SettingsManager")
	else:
		print("SettingsManager not found, using defaults")

func _go_back_to_start():
	if transition_in_progress:
		return
		
	transition_in_progress = true
	waiting_for_crt = true
	
	# Load the start scene
	CrtDisplay.fade_to_packed(start_packed_scene)
