extends TextureRect

@onready var content: TextureRect = $MarginContainer/PhishingContent

@export var answer_cooldown: float = 1.5
@export var scale_duration: float = 0.3
@export var solution_time: float = 3.0

var images: Array = []
var bad_solutions: Dictionary = {}
var current_image
var score: int = 0
var elapsed: float = 0.0
var last_answer_time: float = -999.0
var is_busy: bool = false


func _ready():
	randomize()
	_load_images("res://assets/phishing/bad", true)
	_load_images("res://assets/phishing/good", false)
	_load_solutions("res://assets/phishing/bad_solution")
	images.shuffle()
	_show_next_image()


func _load_images(folder, is_phish):
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
	elapsed += delta
	if elapsed - last_answer_time < answer_cooldown: return
	if is_busy: return  # ignore input while showing solution

	if Input.is_action_just_pressed("phishing_yes"): _check_answer(true)
	elif Input.is_action_just_pressed("phishing_no"): _check_answer(false)


func _show_next_image():
	if images.is_empty(): return

	current_image = images.pop_front()
	content.texture = load(current_image.path)
	
	# Block input while animating in
	is_busy = true
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
		score += 1
		_animate_out(_show_next_image)
		print("goed")
	else:
		# Only decrement lives for wrong answers
		GameManager.lose_life()
		print("fout")
		if current_image.is_phish and bad_solutions.has(current_image.id):
			_show_solution(current_image.id)
		else:
			_animate_out(_show_next_image)




func _show_solution(id: String):
	if bad_solutions.has(id):
		is_busy = true
		content.texture = load(bad_solutions[id])
		await get_tree().create_timer(solution_time).timeout
		is_busy = false
	_animate_out(_show_next_image)



func _animate_out(next_cb):
	is_busy = true
	pivot_offset = Vector2(size.x, 0)
	var t = create_tween()
	t.tween_property(self, "scale", Vector2.ZERO, scale_duration)
	t.tween_callback(func():
		is_busy = false
		next_cb.call()
	)
