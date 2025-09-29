extends Node

signal images_loaded()
signal loading_failed(error_message: String)

var images: Array = []
var bad_solutions: Dictionary = {}
var is_initialized: bool = false

func _ready():
	print("PhishingResourceManager initialized")

func load_all_resources():
	if is_initialized:
		print("Resources already loaded")
		return
	
	print("PhishingResourceManager: Loading all phishing resources...")
	images.clear()
	bad_solutions.clear()
	
	# Get the base path for external phishing folder
	var base_path = _get_external_phishing_path()
	print("Using phishing folder base path: ", base_path)
	
	_load_images(base_path + "/bad", true)
	_load_images(base_path + "/good", false)
	_load_solutions(base_path + "/bad_solution")
	
	print("Total images loaded: ", images.size())
	print("Total solutions loaded: ", bad_solutions.size())
	
	if images.is_empty():
		var error_msg = "No images were loaded! Please make sure there's a 'phishing' folder next to the game executable with phishing/bad/, phishing/good/, and phishing/bad_solution/ subfolders containing PNG images."
		print("ERROR: ", error_msg)
		emit_signal("loading_failed", error_msg)
		return
	
	images.shuffle()
	is_initialized = true
	emit_signal("images_loaded")
	print("PhishingResourceManager: All resources loaded successfully!")

func get_images() -> Array:
	return images.duplicate()

func get_solutions() -> Dictionary:
	return bad_solutions.duplicate()

func has_solution(id: String) -> bool:
	return bad_solutions.has(id)

func get_solution_info(id: String) -> Dictionary:
	return bad_solutions.get(id, {})

func load_texture(path: String, is_external: bool) -> Texture2D:
	if is_external:
		# Load external file
		var image = Image.new()
		var error = image.load(path)
		if error != OK:
			print("Error loading external image: ", path, " Error code: ", error)
			return null
		var image_texture = ImageTexture.new()
		image_texture.set_image(image)
		return image_texture
	else:
		# Load internal resource
		return ResourceLoader.load(path)

func _get_external_phishing_path() -> String:
	var executable_path = OS.get_executable_path()
	var executable_dir = executable_path.get_base_dir()
	var phishing_path = executable_dir + "/phishing"
	
	print("Executable path: ", executable_path)
	print("Executable directory: ", executable_dir)
	print("Looking for phishing folder at: ", phishing_path)
	
	# Check if external phishing folder exists
	if DirAccess.dir_exists_absolute(phishing_path):
		print("External phishing folder found!")
		return phishing_path
	else:
		print("External phishing folder not found, falling back to internal resources")
		# Fallback to internal resources if external folder doesn't exist
		return "res://assets/phishing"

func _load_images(folder, is_phish: bool):
	print("Loading images from folder: ", folder)
	
	# Check if directory exists first
	if not DirAccess.dir_exists_absolute(folder):
		print("Error: Directory does not exist: ", folder)
		return
	
	var dir = DirAccess.open(folder)
	if dir == null:
		print("Error: Could not open directory: ", folder)
		return
	
	var image_count = 0
	var is_external = not folder.begins_with("res://")
	
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".png"):
			var id = file.get_basename()
			var full_path = folder + "/" + file
			
			# Check if the file can actually be loaded
			var can_load = false
			if is_external:
				# For external files, check if file exists
				can_load = FileAccess.file_exists(full_path)
			else:
				# For internal resources, use ResourceLoader
				can_load = ResourceLoader.exists(full_path)
			
			if can_load:
				print("Found image: ", full_path)
				images.append({"path": full_path, "is_phish": is_phish, "id": id, "external": is_external})
				image_count += 1
			else:
				print("Warning: File exists but cannot be accessed: ", full_path)
		file = dir.get_next()
	dir.list_dir_end()
	print("Loaded ", image_count, " images from ", folder)

func _load_solutions(folder):
	print("Loading solutions from folder: ", folder)
	
	# Check if directory exists first
	if not DirAccess.dir_exists_absolute(folder):
		print("Warning: Solutions directory does not exist: ", folder)
		return
		
	var dir = DirAccess.open(folder)
	if dir == null:
		print("Error: Could not open solutions directory: ", folder)
		return
	
	var solution_count = 0
	var is_external = not folder.begins_with("res://")
	
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".png"):
			var id = file.get_basename().trim_suffix("m")  # "12m" → "12"
			var solution_path = folder + "/" + file
			
			# Check if file exists
			var file_exists = false
			if is_external:
				file_exists = FileAccess.file_exists(solution_path)
			else:
				file_exists = ResourceLoader.exists(solution_path)
			
			if file_exists:
				print("Found solution: ", id, " -> ", solution_path)
				bad_solutions[id] = {"path": solution_path, "external": is_external}
				solution_count += 1
			else:
				print("Warning: Solution file not accessible: ", solution_path)
		file = dir.get_next()
	dir.list_dir_end()
	print("Loaded ", solution_count, " solutions from ", folder)