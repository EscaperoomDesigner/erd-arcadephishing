extends HBoxContainer

@onready var rank_label = %RankLabel
@onready var name_label = %NameLabel
@onready var score_label = %ScoreLabel
@onready var date_label = %DateLabel

func set_score_data(player_name: String, score: int, date: String, rank: int = 0):
	if not name_label or not score_label or not date_label:
		return

	if rank_label and rank > 0:
		rank_label.text = str(rank)

	name_label.text = player_name
	score_label.text = str(score)
	date_label.text = date

func highlight():
	var labels = [rank_label, name_label, score_label, date_label]
	var tween = create_tween().set_loops()
	tween.tween_method(_set_label_colors.bind(labels), 0.0, 1.0, 0.7)
	tween.tween_method(_set_label_colors.bind(labels), 1.0, 0.0, 0.7)

func _set_label_colors(t: float, labels: Array):
	# t=0: gold, t=1: white
	var color = Color(1.0, 0.85 + 0.15 * t, t)
	for label in labels:
		if label:
			label.add_theme_color_override("font_color", color)
