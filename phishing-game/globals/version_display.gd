extends CanvasLayer

const VERSION = "V0.9.0"
const SHOW_ON = ["Start", "End", "Options"]

var _label: Label
var _last_scene_name: String = ""


func _ready():
	layer = 128

	var control := Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_label.add_theme_font_size_override("font_size", 12)
	_label.text = VERSION
	_label.visible = false
	control.add_child(_label)


func _process(_delta: float) -> void:
	var scene_name := _get_active_scene_name()
	if scene_name != _last_scene_name:
		_last_scene_name = scene_name
		_label.visible = scene_name in SHOW_ON


func _get_active_scene_name() -> String:
	if not is_instance_valid(CrtDisplay):
		return ""
	var vp: SubViewport = CrtDisplay.subviewport
	if vp == null or vp.get_child_count() == 0:
		return ""
	var child := vp.get_child(0)
	return child.name if is_instance_valid(child) else ""
