extends Control

@onready var high_scores_label: Label = %HighScoresLabel
@onready var back_button: Button = %BackButton
@onready var start_packed_scene: PackedScene = load("uid://c4ma6otpwlva4")

func _ready():
	_load_high_scores()
	
	# Connect back button if it exists
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _load_high_scores():
	if not high_scores_label:
		return
	
	var scores = HighScoreManager.get_high_scores()
	if scores.is_empty():
		high_scores_label.text = "Nog geen high scores beschikbaar!"
		return
	
	var text = "HIGH SCORES\n\n"
	
	for i in range(min(10, scores.size())):
		var entry = scores[i]
		var name = entry.name if entry.name.length() > 0 else "ANONYMOUS"
		text += "%d. %s - %d\n" % [i + 1, name, entry.score]
	
	high_scores_label.text = text

func _on_back_pressed():
	CrtDisplay.fade_to_packed(start_packed_scene, 1.05)

func _input(event):
	# Allow going back with any key press or controller input
	if event.is_pressed() and not event.is_echo():
		_on_back_pressed()
