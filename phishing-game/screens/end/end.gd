extends Control


@export var min_display_time: float = 1.0     # seconds
@export var max_display_time: float = 30.0    # seconds
@export var alphabet := " ABCDEFGHIJKLMNOPQRSTUVWXYZ"  # letters to cycle
@export var max_chars := 8  # number of character slots

@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel
@onready var red_arrow_up: Texture2D = preload("res://assets/images/end/arrow_up.png")
@onready var red_arrow_down: Texture2D = preload("res://assets/images/end/arrow_down.png")
@onready var start_packed_scene: PackedScene = load("uid://c4ma6otpwlva4")
var transition_in_progress := false
var elapsed := 0.0
var can_transition := false

var rows: Array = []        # holds each VBoxContainer row (tex1, label, tex2)
var current_index := 0      # which character slot we're editing
var char_index := 0         # current letter in alphabet for this slot


func _ready():
	elapsed = 0.0
	can_transition = false
	transition_in_progress = false
	score_label.text = GameManager.get_score()

	# Grab all rows dynamically
	var hbox: HBoxContainer = %HBoxContainer
	for vbox in hbox.get_children():
		if vbox is VBoxContainer:
			var tex_up: TextureRect = vbox.get_child(0)
			var label: Label = vbox.get_child(1)
			var tex_down: TextureRect = vbox.get_child(2)
			label.text = ""  # start empty
			rows.append({ "tex_up": tex_up, "label": label, "tex_down": tex_down })

	# Initialize first letter
	char_index = 0
	_update_current_label()


func _process(delta):
	elapsed += delta

	var remaining = max(max_display_time - elapsed, 0)
	if timer_label:
		var seconds = int(remaining) % 60
		timer_label.text = "%d" % [seconds]

	if elapsed >= min_display_time:
		can_transition = true

	# Automatically transition after max_display_time
	if elapsed >= max_display_time and not transition_in_progress:
		_start_transition()

	# Block input while transitioning
	if transition_in_progress:
		return

	# Cycle letters
	if Input.is_action_just_pressed("phishing_up"):
		char_index = (char_index + 1) % alphabet.length()
		_update_current_label()
	elif Input.is_action_just_pressed("phishing_down"):
		char_index = (char_index - 1 + alphabet.length()) % alphabet.length()
		_update_current_label()

	if Input.is_action_just_pressed("phishing_confirm"):
		# Change the TextureRects to red arrows for this slot
		var row = rows[current_index]
		row["tex_up"].texture = red_arrow_up
		row["tex_down"].texture = red_arrow_down

		current_index += 1
		if current_index >= rows.size():
			_finish_name_selection()
		else:
			char_index = 0  # reset for next slot
			_update_current_label()



func _update_current_label():
	rows[current_index]["label"].text = alphabet[char_index]


func _finish_name_selection():
	print("Name selection done!")
	var name = ""
	for row in rows:
		name += row["label"].text
	print("Selected name: %s" % name)
	GameManager.player_name = name

	if can_transition:
		_start_transition()


func _start_transition():
	if transition_in_progress:
		return
	transition_in_progress = true
	CrtDisplay.fade_to_packed(start_packed_scene, 1.05)
