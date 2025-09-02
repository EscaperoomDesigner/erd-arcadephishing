extends Control

@onready var subviewport: SubViewport = $ShaderRect/SubViewport
@onready var fade: ColorRect = $Fade
@onready var unfiltered_display: Control = $UnfilteredDisplay

var _transitioning := false


func _ready():
	# Ensure singleton exists in root tree
	if get_parent() == null:
		get_tree().root.add_child(self)
		self.owner = null
	fade.visible = true
	fade.modulate.a = 0.0
	
	# Automatically move current scene root into SubViewport
	_move_current_scene_to_subviewport()


func _move_current_scene_to_subviewport():
	var current_scene = get_tree().current_scene
	if current_scene:
		# Defer the reparenting to avoid "Parent node is busy" error
		current_scene.get_parent().call_deferred("remove_child", current_scene)
		subviewport.call_deferred("add_child", current_scene)
		# Ensure it isn’t freed on scene change
		current_scene.owner = null


func fade_to_packed(
	packed: PackedScene,
	fade_time := 0.35
) -> void:
	if _transitioning:
		return
	_transitioning = true

	if packed == null:
		push_error("CRTDisplay: PackedScene is null!")
		_transitioning = false
		return

	fade.visible = true
	fade.modulate.a = 0.0

	var old_scene = null
	if subviewport.get_child_count() > 0:
		old_scene = subviewport.get_child(0)

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Fade out
	t.tween_property(fade, "modulate:a", 1.0, fade_time)

	# Swap CRT scene
	t.tween_callback(func():
		if old_scene:
			old_scene.queue_free()
		var instance = packed.instantiate()
		subviewport.add_child(instance)
	)

	# Fade back in
	t.tween_property(fade, "modulate:a", 0.0, fade_time)

	# Unlock
	t.tween_callback(func():
		_transitioning = false
	)


func _clear_subviewport():
	for c in subviewport.get_children():
		c.queue_free()


func set_unfiltered_content(packed: PackedScene) -> void:
	_clear_unfiltered()
	if packed:
		var instance = packed.instantiate()
		unfiltered_display.add_child(instance)


func show_unfiltered_after_delay(unfiltered: PackedScene, delay := 3.0, start_scale := 0.01, tween_time := 0.85) -> void:
	if unfiltered == null:
		push_error("CRTDisplay: Unfiltered PackedScene is null!")
		return

	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(func():
		_clear_unfiltered()
		var instance = unfiltered.instantiate()
		unfiltered_display.add_child(instance)

		# Start small
		instance.scale = Vector2(start_scale, start_scale)

		# Tween to full size
		var tween = create_tween()
		tween.tween_property(instance, "scale", Vector2(1,1), tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)

func _clear_unfiltered() -> void:
	for c in unfiltered_display.get_children():
		c.queue_free()
