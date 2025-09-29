extends Node

# Settings file path
const SETTINGS_FILE_PATH = "user://settings.save"

# Default settings
var master_volume_level: int = 7
var music_volume_level: int = 7
var sfx_volume_level: int = 7

signal settings_changed
signal settings_loaded

func _ready():
	# Debug: Print available audio buses
	_debug_print_audio_buses()
	
	load_settings()
	# Emit signal after settings are loaded
	call_deferred("_emit_loaded_signal")

func _emit_loaded_signal():
	settings_loaded.emit()
	print("SettingsManager: Settings loaded and signal emitted")

func _debug_print_audio_buses():
	print("=== Available Audio Buses ===")
	var bus_count = AudioServer.get_bus_count()
	for i in range(bus_count):
		var bus_name = AudioServer.get_bus_name(i)
		print("Bus ", i, ": ", bus_name)
	print("==============================")

func save_settings():
	var save_file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if save_file == null:
		print("Failed to save settings")
		return false
	
	var save_data = {
		"master_volume": master_volume_level,
		"music_volume": music_volume_level,
		"sfx_volume": sfx_volume_level
	}
	
	save_file.store_string(JSON.stringify(save_data))
	save_file.close()
	print("Settings saved successfully")
	settings_changed.emit()
	return true

func load_settings():
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		print("No settings file found, using defaults")
		# Apply default volumes to audio buses
		_apply_master_volume()
		_apply_music_volume()
		_apply_sfx_volume()
		return false
	
	var save_file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if save_file == null:
		print("Failed to load settings")
		return false
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Failed to parse settings JSON")
		return false
	
	var save_data = json.data
	if save_data.has("master_volume"):
		master_volume_level = save_data["master_volume"]
	if save_data.has("music_volume"):
		music_volume_level = save_data["music_volume"]
	if save_data.has("sfx_volume"):
		sfx_volume_level = save_data["sfx_volume"]
	
	print("Settings loaded successfully - Master: ", master_volume_level, ", Music: ", music_volume_level, ", SFX: ", sfx_volume_level)
	
	# Apply the loaded volumes to audio buses
	_apply_master_volume()
	_apply_music_volume()
	_apply_sfx_volume()
	
	settings_changed.emit()
	return true

func set_master_volume(level: int):
	master_volume_level = clamp(level, 0, 10)
	_apply_master_volume()
	save_settings()

func set_music_volume(level: int):
	music_volume_level = clamp(level, 0, 10)
	_apply_music_volume()
	save_settings()

func set_sfx_volume(level: int):
	sfx_volume_level = clamp(level, 0, 10)
	_apply_sfx_volume()
	save_settings()

func _apply_master_volume():
	var volume_normalized = get_master_volume_normalized()
	var master_bus_index = AudioServer.get_bus_index("Master")
	if master_bus_index != -1:
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(volume_normalized))
		print("Master bus volume set to: ", volume_normalized, " (", master_volume_level, "/10)")
	else:
		print("Error: Master bus not found!")
	
	# Also apply master volume to SFX bus if it exists (SFX inherits from Master)
	_ensure_sfx_bus_exists()

func _apply_music_volume():
	var volume_normalized = get_music_volume_normalized()
	var music_bus_index = AudioServer.get_bus_index("Music")
	
	# If Music bus doesn't exist, try to create it
	if music_bus_index == -1:
		music_bus_index = _ensure_music_bus_exists()
	
	if music_bus_index != -1:
		AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(volume_normalized))
		print("Music bus volume set to: ", volume_normalized, " (", music_volume_level, "/10)")
	else:
		print("Warning: Music bus not available, music volume not applied")

func _apply_sfx_volume():
	var volume_normalized = get_sfx_volume_normalized()
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	# If SFX bus doesn't exist, try to create it
	if sfx_bus_index == -1:
		_ensure_sfx_bus_exists()
		sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	if sfx_bus_index != -1:
		AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(volume_normalized))
		print("SFX bus volume set to: ", volume_normalized, " (", sfx_volume_level, "/10)")
	else:
		print("Warning: SFX bus not available, SFX volume not applied")

func _ensure_music_bus_exists() -> int:
	# Try to create Music bus if it doesn't exist
	print("Music bus not found, attempting to create it...")
	
	AudioServer.add_bus()
	var new_bus_index = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(new_bus_index, "Music")
	
	# Make Music bus a child of Master bus
	var master_bus_index = AudioServer.get_bus_index("Master")
	if master_bus_index != -1:
		AudioServer.set_bus_send(new_bus_index, "Master")
	
	# Verify the bus was created correctly
	var created_bus_index = AudioServer.get_bus_index("Music")
	if created_bus_index != -1:
		print("Successfully created Music bus at index: ", created_bus_index)
		return created_bus_index
	else:
		print("Failed to create Music bus programmatically")
		return -1

func _ensure_sfx_bus_exists():
	# Check if SFX bus exists, create it if not
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	if sfx_bus_index == -1:
		print("SFX bus not found, attempting to create it...")
		
		AudioServer.add_bus()
		var new_bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(new_bus_index, "SFX")
		
		# Make SFX bus a child of Master bus
		var master_bus_index = AudioServer.get_bus_index("Master")
		if master_bus_index != -1:
			AudioServer.set_bus_send(new_bus_index, "Master")
		
		# Verify the bus was created correctly
		sfx_bus_index = AudioServer.get_bus_index("SFX")
		if sfx_bus_index != -1:
			print("Successfully created SFX bus at index: ", sfx_bus_index)
		else:
			print("Failed to create SFX bus programmatically")
	else:
		print("SFX bus found at index: ", sfx_bus_index)

func get_master_volume() -> int:
	return master_volume_level

func get_music_volume() -> int:
	return music_volume_level

func get_master_volume_normalized() -> float:
	return master_volume_level / 10.0

func get_music_volume_normalized() -> float:
	return music_volume_level / 10.0

func get_sfx_volume() -> int:
	return sfx_volume_level

func get_sfx_volume_normalized() -> float:
	return sfx_volume_level / 10.0