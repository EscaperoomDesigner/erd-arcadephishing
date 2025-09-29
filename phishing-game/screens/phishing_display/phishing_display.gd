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
	randomize()
	_load_images("res://assets/phishing/bad", true)
	_load_images("res://assets/phishing/good", false)
	_load_solutions("res://assets/phishing/bad_solution")
	images.shuffle()
	
	# Continue playing game music (should already be playing from tutorial)
	MusicManager.play_game_music()
	_show_next_image()
	
	# Connect to timer expired signal
	GameManager.timer_expired.connect(_on_timer_expired)


func _load_images(folder, is_phish: bool):
	var dir = DirAccess.open(folder)
	if dir == null: return
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".png"):
			var id = file.get_basename()
			images.append({"path": folder + "/" + file, "is_phish": is_phish, "id": id})
		file = dir.get_next()
	dir.list_dir_end()


func _load_solutions(folder):
	var dir = DirAccess.open(folder)
	if dir == null: return
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".png"):
			var id = file.get_basename().trim_suffix("m")  # "12m" → "12"
			bad_solutions[id] = folder + "/" + file
		file = dir.get_next()
	dir.list_dir_end()


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
		_check_answer(candidate_answer == 0)  # true if YES
		candidate_answer = 2  # reset after confirming
		GameManager.emit_signal("candidate_changed", candidate_answer)


func _show_next_image():
	if not GameManager.game_running:
		return
	if images.is_empty(): 
		return

	# Block input while animating in
	is_busy = true
	current_image = images.pop_front()
	content.texture = load(current_image.path)

	scale = Vector2.ZERO
	pivot_offset = size
	var t = create_tween()
	t.tween_property(self, "scale", Vector2.ONE, scale_duration)
	t.tween_callback(func():
		is_busy = false  # unblock after animation finishes
	)


func _check_answer(ans: bool):
	last_answer_time = elapsed

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
	content.texture = load(bad_solutions[id])

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
