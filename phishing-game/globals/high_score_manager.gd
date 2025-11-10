extends Node

signal new_high_score()

const SAVE_FILE_PATH = "user://high_scores.json"
const MAX_HIGH_SCORES_DISPLAY = 10  # How many scores to show in displays
# No limit on total scores saved - all scores will be kept

var high_scores: Array[Dictionary] = []

func _ready():
	load_high_scores()

# Load high scores from file
func load_high_scores():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No high score file found, starting fresh")
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		print("Failed to open high score file for reading")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		print("Failed to parse high scores JSON")
		return
	
	var data = json.data
	if data is Array:
		high_scores.clear()
		for item in data:
			if item is Dictionary:
				high_scores.append(item)
		print("Loaded %d high scores" % high_scores.size())
	else:
		print("Invalid high scores data format")

# Save high scores to file
func save_high_scores():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		print("Failed to open high score file for writing")
		return
	
	var json_text = JSON.stringify(high_scores)
	file.store_string(json_text)
	file.close()
	print("High scores saved successfully")

# Check if a score qualifies as a high score (for display purposes)
func is_high_score(score: int) -> bool:
	if high_scores.size() < MAX_HIGH_SCORES_DISPLAY:
		return true
	
	# Find the lowest score in the top scores
	var top_scores = high_scores.slice(0, MAX_HIGH_SCORES_DISPLAY)
	var lowest_score = top_scores[0].score
	for high_score in top_scores:
		if high_score.score < lowest_score:
			lowest_score = high_score.score
	
	return score > lowest_score

# Add a new score (now saves all scores, not just high scores)
func add_high_score(player_name: String, score: int) -> int:
	var new_entry = {
		"name": player_name.strip_edges(),
		"score": score,
		"date": Time.get_datetime_string_from_system()
	}
	
	high_scores.append(new_entry)
	
	# Sort by score (descending)
	high_scores.sort_custom(func(a, b): return a.score > b.score)
	
	# Find the position of the new score
	var position = -1
	for i in range(high_scores.size()):
		if high_scores[i] == new_entry:
			position = i + 1  # 1-indexed for display
			break
	
	# Keep only top scores for display purposes, but save all scores
	# You can increase MAX_HIGH_SCORES if you want to display more scores
	
	save_high_scores()
	
	emit_signal("new_high_score")
	
	return position

# Get all high scores
func get_high_scores() -> Array[Dictionary]:
	return high_scores

# Get the top score
func get_top_score() -> int:
	if high_scores.is_empty():
		return 0
	return high_scores[0].score

# Get a formatted string of high scores for display
func get_high_scores_text() -> String:
	if high_scores.is_empty():
		return "Nog geen high scores beschikbaar!"
	
	var text = ""
	var display_count = min(5, min(MAX_HIGH_SCORES_DISPLAY, high_scores.size()))
	for i in range(display_count):  # Show top 5 or fewer
		var entry = high_scores[i]
		text += "%d. %s - %d\n" % [i + 1, entry.name, entry.score]
	
	return text

# Clear all high scores (for testing/reset purposes)
func clear_high_scores():
	high_scores.clear()
	save_high_scores()
	print("High scores cleared")
