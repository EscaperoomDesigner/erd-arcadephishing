extends Control

@onready var subviewport: SubViewport = $ShaderRect/SubViewport
@onready var fade: ColorRect = $Fade
@onready var unfiltered_display: Control = $UnfilteredDisplay
@onready var transition_material: ShaderMaterial = $Fade.material

var _transitioning := false


func _ready():
	# Ensure singleton exists in root tree
	if get_parent() == null:
		get_tree().root.add_child(self)
		self.owner = null

	fade.visible = true
	# Defer so GameManager has already applied the mode's viewport size
	call_deferred("_apply_display_size")
	_move_current_scene_to_subviewport()


func _apply_display_size() -> void:
	var display_size := get_viewport_rect().size
	subviewport.size = Vector2i(display_size)
	transition_material.set_shader_parameter("screen_size", display_size)


func _move_current_scene_to_subviewport():
	var current_scene = get_tree().current_scene
	if current_scene:
		# Defer the reparenting to avoid "Parent node is busy" error
		current_scene.get_parent().call_deferred("remove_child", current_scene)
		subviewport.call_deferred("add_child", current_scene)
		current_scene.owner = null


func fade_to_packed(
	packed: PackedScene,
	fade_time := 3.0
) -> void:
	if _transitioning:
		return
	_transitioning = true

	if packed == null:
		push_error("CRTDisplay: PackedScene is null!")
		_transitioning = false
		return

	fade.visible = true
	transition_material.set_shader_parameter("progress", 0.0)

	var old_scene = null
	if subviewport.get_child_count() > 0:
		old_scene = subviewport.get_child(0)

	var t := create_tween()
	t.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# Converge: pixels come from outside to center (progress 0.0 -> 0.5)
	t.tween_property(transition_material, "shader_parameter/progress", 0.5, fade_time * 0.5)

	# Swap CRT scene at the middle point (when fully black)
	t.tween_callback(func():
		if old_scene:
			old_scene.queue_free()
		var instance = packed.instantiate()
		subviewport.add_child(instance)
	)

	# Disperse: pixels spread from center outwards (progress 0.5 -> 1.0)
	t.tween_property(transition_material, "shader_parameter/progress", 1.0, fade_time * 0.5)

	# Reset and unlock
	t.tween_callback(func():
		transition_material.set_shader_parameter("progress", 0.0)
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
