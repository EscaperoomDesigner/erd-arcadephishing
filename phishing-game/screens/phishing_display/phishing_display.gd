extends TextureRect

@onready var content: TextureRect = $MarginContainer/PhishingContent

var images := []
var current_image = null
var score := 0
var game_time := 120.0  # 2 minutes
var elapsed := 0.0

func _ready():
	randomize()
	load_images_from_folder("res://assets/phishing/bad", true)
	load_images_from_folder("res://assets/phishing/good", false)
	images.shuffle()
	show_next_image()
	set_process(true)

# Load all images in a folder and mark them phishing or not
func load_images_from_folder(folder_path: String, is_phish: bool):
	var dir = DirAccess.open(folder_path)
	if dir == null:
		push_error("Failed to open folder: " + folder_path)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			images.append({
				"path": folder_path + "/" + file_name,
				"is_phish": is_phish
			})
		file_name = dir.get_next()
	dir.list_dir_end()


func _process(_delta):
	# Handle Yes/No input
	if Input.is_action_just_pressed("phishing_yes"):
		_check_answer(true)
	elif Input.is_action_just_pressed("phishing_no"):
		_check_answer(false)


func show_next_image():
	if images.size() == 0:
		return
	current_image = images.pop_front()
	content.texture = load(current_image["path"])

func _check_answer(answer: bool):
	if answer == current_image["is_phish"]:
		score += 1
		print("✅ Correct")
	else:
		print("❌ Wrong")
	show_next_image()
