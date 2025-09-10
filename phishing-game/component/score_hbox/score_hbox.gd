extends HBoxContainer

@onready var name_label = %NameLabel
@onready var score_label = %ScoreLabel
@onready var date_label = %DateLabel

func set_score_data(player_name: String, score: int, date: String):
	if not name_label or not score_label or not date_label:
		return
	
	name_label.text = player_name
	score_label.text = str(score)
	date_label.text = date
