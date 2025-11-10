extends Control

@onready var master_volume_minus: TextureRect = %MasterVolumeMinus
@onready var master_volume_plus: TextureRect = %MasterVolumePlus
@onready var music_volume_minus: TextureRect = %MusicVolumeMinus
@onready var music_volume_plus: TextureRect = %MusicVolumePlus
@onready var terug_button: TextureRect = %TerugButton
@onready var highscore_reset_button: TextureRect = %HighscoreResetButton
@onready var master_volume_progress: ProgressBar = %MasterProgressBar
@onready var music_volume_progress: ProgressBar = %MusicProgressBar
@onready var sfx_progress_bar: ProgressBar = %SfxProgressBar
@onready var sfx_volume_minus: TextureRect = %SfxVolumeMinus
@onready var sfx_volume_plus: TextureRect = %SfxVolumePlus
@onready var master_volume_label: Label = %MasterVolumeLabel
@onready var music_volume_label: Label = %MusicVolumeLabel
@onready var sfx_volume_label: Label = %SfxVolumeLabel
@onready var fullscreen_button: TextureRect = %FullscreenButton

# Confirmation popup elements (assuming these exist in the scene)
@onready var confirmation_popup: Control = %ConfirmPanel
@onready var confirmation_ja_button: TextureRect = %YesButton
@onready var confirmation_nee_button: TextureRect = %NoButton

@onready var start_packed_scene: PackedScene = load("uid://c4ma6otpwlva4")

var button_default: Texture2D = preload("res://assets/images/options/optionsbutton.png")
var button_selected: Texture2D = preload("res://assets/images/options/optionsbutton_selected.png")

var terug_button_default: Texture2D = preload("res://assets/images/menu/button_default.png")
var terug_button_selected: Texture2D = preload("res://assets/images/menu/button_selected.png")

var transition_in_progress := false  # Prevent multiple triggers
var waiting_for_crt := false         # Flag to wait until fade completes
var scene_ready := false             # Prevent immediate input on scene load

# Navigation state
enum OptionRow { MASTER_VOLUME, MUSIC_VOLUME, SFX_VOLUME, FULLSCREEN, HIGHSCORE_RESET, BACK }
var current_row: OptionRow = OptionRow.MASTER_VOLUME

# Confirmation popup state
var showing_confirmation := false
var confirmation_selection := 0  # 0 = Nee, 1 = Ja

# Volume levels (0-10) - loaded from SettingsManager
var master_volume_level: int = 10
var music_volume_level: int = 10
var sfx_volume_level: int = 10

# Volume control data structure for cleaner code
var volume_controls = {
	OptionRow.MASTER_VOLUME: {
		"level": 0,
		"progress_bar": null,
		"minus_button": null,
		"plus_button": null,
		"apply_func": "_apply_master_volume"
	},
	OptionRow.MUSIC_VOLUME: {
		"level": 0,
		"progress_bar": null,
		"minus_button": null,
		"plus_button": null,
		"apply_func": "_apply_music_volume"
	},
	OptionRow.SFX_VOLUME: {
		"level": 0,
		"progress_bar": null,
		"minus_button": null,
		"plus_button": null,
		"apply_func": "_apply_sfx_volume"
	}
}


func _ready():
	# Load settings from SettingsManager
	_load_settings_from_manager()
	
	# Initialize volume controls structure
	_setup_volume_controls()
	
	# Initialize progress bars
	_initialize_progress_bars()
	
	_update_button_display()
	
	# Hide confirmation popup initially
	if confirmation_popup:
		confirmation_popup.visible = false
	
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

	# Handle input differently if confirmation popup is showing
	if showing_confirmation:
		_handle_confirmation_input()
		return
	
	# Vertical navigation (UP/DOWN)
	if Input.is_action_just_pressed("phishing_up"):
		_navigate_vertical(-1)
	elif Input.is_action_just_pressed("phishing_down"):
		_navigate_vertical(1)

	# Horizontal navigation (LEFT/RIGHT) - for volume controls
	if Input.is_action_just_pressed("phishing_yes"):  # LEFT (decrease volume)
		_adjust_volume(-1)
	elif Input.is_action_just_pressed("phishing_no"):  # RIGHT (increase volume)
		_adjust_volume(1)

	# Selection (CONFIRM)
	if Input.is_action_just_pressed("phishing_confirm"):
		SfxManager.play_ui_select()
		match current_row:
			OptionRow.FULLSCREEN:
				_toggle_fullscreen()
			OptionRow.HIGHSCORE_RESET:
				_show_highscore_reset_confirmation()
			OptionRow.BACK:
				_go_back_to_start()


func _update_button_display():
	# Reset all buttons to default state
	_reset_all_buttons()
	
	# Update confirmation buttons if popup is showing
	if showing_confirmation:
		_update_confirmation_display()
		return
	
	# Update based on current selection
	match current_row:
		OptionRow.MASTER_VOLUME, OptionRow.MUSIC_VOLUME, OptionRow.SFX_VOLUME:
			_highlight_volume_controls(current_row)
		OptionRow.FULLSCREEN:
			if fullscreen_button:
				fullscreen_button.texture = terug_button_selected
		OptionRow.HIGHSCORE_RESET:
			if highscore_reset_button:
				highscore_reset_button.texture = terug_button_selected
		OptionRow.BACK:
			terug_button.texture = terug_button_selected


func _get_settings_manager() -> Node:
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if not settings_manager:
		print("Warning: SettingsManager not found!")
	return settings_manager


func _apply_master_volume():
	master_volume_progress.value = master_volume_level
	_update_volume_labels()
	var settings_manager = _get_settings_manager()
	if settings_manager:
		settings_manager.set_master_volume(master_volume_level)
	print("Master volume set to: ", master_volume_level)


func _apply_music_volume():
	music_volume_progress.value = music_volume_level
	_update_volume_labels()
	var settings_manager = _get_settings_manager()
	if settings_manager:
		settings_manager.set_music_volume(music_volume_level)
	print("Music volume set to: ", music_volume_level)


func _apply_sfx_volume():
	sfx_progress_bar.value = sfx_volume_level
	_update_volume_labels()
	var settings_manager = _get_settings_manager()
	if settings_manager:
		settings_manager.set_sfx_volume(sfx_volume_level)
	print("SFX volume set to: ", sfx_volume_level)


func _load_settings_from_manager():
	var settings_manager = _get_settings_manager()
	if settings_manager:
		master_volume_level = settings_manager.get_master_volume()
		music_volume_level = settings_manager.get_music_volume()
		sfx_volume_level = settings_manager.get_sfx_volume()
		_update_fullscreen_button_label()
		print("Settings loaded from SettingsManager")
	else:
		print("Using default settings")


func _handle_confirmation_input():
	# Horizontal navigation in confirmation popup (LEFT/RIGHT)
	if Input.is_action_just_pressed("phishing_yes"):  # LEFT - select "Ja"
		confirmation_selection = 1
		_update_confirmation_display()
		SfxManager.play_ui_hover()
	elif Input.is_action_just_pressed("phishing_no"):  # RIGHT - select "Nee"
		confirmation_selection = 0
		_update_confirmation_display()
		SfxManager.play_ui_hover()
	
	# Confirm selection
	elif Input.is_action_just_pressed("phishing_confirm"):
		SfxManager.play_ui_select()
		if confirmation_selection == 1:  # Ja selected
			_reset_highscores()
		_hide_confirmation_popup()


func _show_highscore_reset_confirmation():
	showing_confirmation = true
	confirmation_selection = 0  # Default to "Nee"
	if confirmation_popup:
		confirmation_popup.visible = true
	_update_confirmation_display()


func _hide_confirmation_popup():
	showing_confirmation = false
	if confirmation_popup:
		confirmation_popup.visible = false
	_update_button_display()


func _update_confirmation_display():
	if not showing_confirmation:
		return
	
	# Reset confirmation buttons to default
	if confirmation_nee_button:
		confirmation_nee_button.texture = terug_button_default
	if confirmation_ja_button:
		confirmation_ja_button.texture = terug_button_default
	
	# Highlight selected option
	if confirmation_selection == 0:  # Nee selected
		if confirmation_nee_button:
			confirmation_nee_button.texture = terug_button_selected
	else:  # Ja selected
		if confirmation_ja_button:
			confirmation_ja_button.texture = terug_button_selected


func _reset_highscores():
	# Reset the highscores using HighScoreManager
	if HighScoreManager:
		HighScoreManager.clear_high_scores()
		print("Highscores have been reset!")
	else:
		print("HighScoreManager not found!")


func _go_back_to_start():
	if transition_in_progress:
		return
		
	transition_in_progress = true
	waiting_for_crt = true
	
	# Load the start scene
	CrtDisplay.fade_to_packed(start_packed_scene)



func _setup_volume_controls():
	volume_controls[OptionRow.MASTER_VOLUME].level = master_volume_level
	volume_controls[OptionRow.MASTER_VOLUME].progress_bar = master_volume_progress
	volume_controls[OptionRow.MASTER_VOLUME].minus_button = master_volume_minus
	volume_controls[OptionRow.MASTER_VOLUME].plus_button = master_volume_plus
	
	volume_controls[OptionRow.MUSIC_VOLUME].level = music_volume_level
	volume_controls[OptionRow.MUSIC_VOLUME].progress_bar = music_volume_progress
	volume_controls[OptionRow.MUSIC_VOLUME].minus_button = music_volume_minus
	volume_controls[OptionRow.MUSIC_VOLUME].plus_button = music_volume_plus
	
	volume_controls[OptionRow.SFX_VOLUME].level = sfx_volume_level
	volume_controls[OptionRow.SFX_VOLUME].progress_bar = sfx_progress_bar
	volume_controls[OptionRow.SFX_VOLUME].minus_button = sfx_volume_minus
	volume_controls[OptionRow.SFX_VOLUME].plus_button = sfx_volume_plus


func _initialize_progress_bars():
	for row in volume_controls:
		var control = volume_controls[row]
		if control.progress_bar:
			control.progress_bar.max_value = 10
			control.progress_bar.value = control.level

	_update_volume_labels()


func _navigate_vertical(direction: int):
	var options = [OptionRow.MASTER_VOLUME, OptionRow.MUSIC_VOLUME, OptionRow.SFX_VOLUME, OptionRow.FULLSCREEN, OptionRow.HIGHSCORE_RESET, OptionRow.BACK]
	var current_index = options.find(current_row)
	
	if direction > 0:  # Down
		current_index = (current_index + 1) % options.size()
	else:  # Up
		current_index = (current_index - 1) % options.size()
		if current_index < 0:
			current_index = options.size() - 1
	
	current_row = options[current_index]
	_update_button_display()
	SfxManager.play_ui_hover()


func _adjust_volume(direction: int):
	if current_row in volume_controls:
		match current_row:
			OptionRow.MASTER_VOLUME:
				master_volume_level = clamp(master_volume_level + direction, 0, 10)
				_apply_master_volume()
			OptionRow.MUSIC_VOLUME:
				music_volume_level = clamp(music_volume_level + direction, 0, 10)
				_apply_music_volume()
			OptionRow.SFX_VOLUME:
				sfx_volume_level = clamp(sfx_volume_level + direction, 0, 10)
				_apply_sfx_volume()
		
		_update_button_display()
		SfxManager.play_ui_hover()


func _reset_all_buttons():
	master_volume_minus.texture = button_default
	master_volume_plus.texture = button_default
	music_volume_minus.texture = button_default
	music_volume_plus.texture = button_default
	sfx_volume_minus.texture = button_default
	sfx_volume_plus.texture = button_default
	if fullscreen_button:
		fullscreen_button.texture = terug_button_default
	if highscore_reset_button:
		highscore_reset_button.texture = terug_button_default
	terug_button.texture = terug_button_default


func _highlight_volume_controls(row: OptionRow):
	match row:
		OptionRow.MASTER_VOLUME:
			master_volume_minus.texture = button_selected
			master_volume_plus.texture = button_selected
		OptionRow.MUSIC_VOLUME:
			music_volume_minus.texture = button_selected
			music_volume_plus.texture = button_selected
		OptionRow.SFX_VOLUME:
			sfx_volume_minus.texture = button_selected
			sfx_volume_plus.texture = button_selected


func _update_volume_labels():
	if master_volume_label:
		master_volume_label.text = str(master_volume_level)
	if music_volume_label:
		music_volume_label.text = str(music_volume_level)
	if sfx_volume_label:
		sfx_volume_label.text = str(sfx_volume_level)


func _toggle_fullscreen():
	var settings_manager = _get_settings_manager()
	if settings_manager:
		settings_manager.toggle_fullscreen()
		_update_fullscreen_button_label()
		print("Fullscreen toggled")


func _update_fullscreen_button_label():
	var settings_manager = _get_settings_manager()
	if not settings_manager or not fullscreen_button:
		return
	
	var label = fullscreen_button.get_node_or_null("Label")
	if label:
		if settings_manager.get_fullscreen():
			label.text = "ON"
		else:
			label.text = "OFF"
