extends TextureRect

@onready var content: TextureRect = $MarginContainer/PhishingContent

@export var answer_cooldown: float = 1.5
@export var scale_duration: float = 0.3
@export var solution_time: float = 3.0

var images: Array = []
var bad_solutions: Dictionary = {}
var current_image
var elapsed: float = 0.0
var last_answer_time: float = -999.0
var is_busy: bool = false
var showing_solution: bool = false
var handling_last_life: bool = false  # Track if we're handling last life scenario

var candidate_stick: String = ""   # "left" or "right"
var confirmed_stick: String = ""
var candidate_answer: int = 2  # 0 = yes, 1 = no, 2 = null




func _ready():
	print("PhishingDisplay _ready() called")
	randomize()
	
	# Get the base path for external phishing folder
	var base_path = _get_external_phishing_path()
	print("Using phishing folder base path: ", base_path)
	
	_load_images(base_path + "/bad", true)
	_load_images(base_path + "/good", false)
	_load_solutions(base_path + "/bad_solution")
	
	print("Total images loaded: ", images.size())
	if images.is_empty():
		print("ERROR: No images were loaded!")
		print("Please make sure there's a 'phishing' folder next to the game executable with:")
		print("- phishing/bad/ (containing phishing PNG images)")
		print("- phishing/good/ (containing legitimate PNG images)")
		print("- phishing/bad_solution/ (containing solution PNG images)")
		# Don't try to show images if none are loaded
		return
	
	images.shuffle()
	
	# Continue playing game music (should already be playing from tutorial)
	MusicManager.play_game_music()
	_show_next_image()
	
	# Connect to timer expired signal
	GameManager.timer_expired.connect(_on_timer_expired)


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


func _load_texture(path: String, is_external: bool) -> Texture2D:
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


func _process(delta):
	if not GameManager.game_running:
		return

	elapsed += delta
	if elapsed - last_answer_time < answer_cooldown:
		return
	if is_busy or GameManager.input_lock:
		return  # ignore input while showing solution

	# --- Select candidate (but don't confirm yet) ---
	if Input.is_action_just_pressed("phishing_yes"):
		candidate_answer = 0
		GameManager.emit_signal("candidate_changed", candidate_answer)
		print("Candidate answer: YES")

	elif Input.is_action_just_pressed("phishing_no"):
		candidate_answer = 1
		GameManager.emit_signal("candidate_changed", candidate_answer)
		print("Candidate answer: NO")
		

	# --- Confirm selection ---
	if candidate_answer != 2 and Input.is_action_just_pressed("phishing_confirm"):
		# Guard against null current_image before checking answer
		if current_image != null:
			_check_answer(candidate_answer == 0)  # true if YES
		candidate_answer = 2  # reset after confirming
		GameManager.emit_signal("candidate_changed", candidate_answer)


func _show_next_image():
	if not GameManager.game_running:
		current_image = null
		return
	if images.is_empty(): 
		current_image = null
		return

	# Block input while animating in
	is_busy = true
	current_image = images.pop_front()
	
	# Load texture with error handling
	var texture_resource = _load_texture(current_image.path, current_image.get("external", false))
	if texture_resource == null:
		print("Error: Could not load texture from path: ", current_image.path)
		# Set current_image to null and unblock to prevent infinite loops
		current_image = null
		is_busy = false
		return
	
	content.texture = texture_resource

	scale = Vector2.ZERO
	pivot_offset = size
	var t = create_tween()
	t.tween_property(self, "scale", Vector2.ONE, scale_duration)
	t.tween_callback(func():
		is_busy = false  # unblock after animation finishes
	)


func _check_answer(ans: bool):
	last_answer_time = elapsed
	
	# Guard against null current_image
	if current_image == null:
		print("Warning: _check_answer called with null current_image")
		return

	if ans == current_image.is_phish:
		GameManager.add_score(1)
		SfxManager.play_correct_answer()
		_animate_out(_show_next_image)
		print("goed")
	else:
		# Wrong answer: decrement lives
		# Check if we are on the last life and will show solution
		var will_show_solution = (GameManager.lives == 1 and current_image.is_phish and bad_solutions.has(current_image.id))
		
		
		GameManager.lose_life(will_show_solution)
		print("fout")
		if GameManager.lives >= 1:
			SfxManager.play_wrong_answer()

		# Check if we are on the last life
		if GameManager.lives <= 0:
			SfxManager.play_life_lost()
			handling_last_life = true  # Mark that we're handling last life
			if current_image.is_phish and bad_solutions.has(current_image.id):
				# Show solution first, then fade to end
				_show_solution(current_image.id, true)
			else:
				# No solution, just fade to end
				_fade_to_end()
			return  # Stop further logic

		# Not last life
		if current_image.is_phish and bad_solutions.has(current_image.id):
			_show_solution(current_image.id)
		else:
			_animate_out(_show_next_image)


func _show_solution(id: String, fade_to_end := false):
	if not bad_solutions.has(id):
		return

	is_busy = true
	showing_solution = true
	if fade_to_end:
		GameManager.input_lock = true  # Lock input when showing solution on last life
	
	var solution_info = bad_solutions[id]
	content.texture = _load_texture(solution_info.path, solution_info.get("external", false))

	# Wait while showing solution
	await get_tree().create_timer(solution_time).timeout

	is_busy = false
	showing_solution = false

	if fade_to_end:
		GameManager.input_lock = false  # Unlock input before game over
		# If we were pending a game over, trigger it now
		if GameManager.pending_game_over:
			GameManager.pending_game_over = false
			GameManager.emit_signal("game_over")
		_fade_to_end()
	else:
		_animate_out(_show_next_image)



func _fade_to_end():
	is_busy = true
	pivot_offset = Vector2(size.x, 0)
	var t = create_tween()
	t.tween_property(self, "scale", Vector2.ZERO, scale_duration)
	t.tween_callback(func():
		is_busy = false
		showing_solution = false
		handling_last_life = false  # Reset the flag
		GameManager.game_running = false
		GameManager.input_lock = false  # Ensure input is unlocked
		CrtDisplay.fade_to_packed(GameManager.END_PACKED_SCENE)
	)



func _animate_out(next_cb):
	is_busy = true
	pivot_offset = Vector2(size.x, 0)
	var t = create_tween()
	t.tween_property(self, "scale", Vector2.ZERO, scale_duration)
	t.tween_callback(func():
		is_busy = false
		next_cb.call()
	)


func _on_timer_expired():
	# If we're already handling last life scenario, don't interfere
	if handling_last_life:
		return
	
	# When timer expires, check if solution is showing
	if showing_solution:
		# Wait for solution to finish, then fade to end
		while showing_solution:
			await get_tree().process_frame
		_fade_to_end()
	else:
		# No solution showing, immediately fade to end
		_fade_to_end()


func is_showing_solution() -> bool:
	return showing_solution and handling_last_life
