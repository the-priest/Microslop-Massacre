extends Node
## SceneRouter — menu <-> game transitions with a fade.

const GAME := "res://game/Game.tscn"
const MENU := "res://ui/MainMenu.tscn"
var _busy: bool = false
var _overlay: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 1)
	_overlay.modulate.a = 0.0
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_overlay)


func goto_game() -> void:
	change_scene(GAME)


func goto_menu() -> void:
	change_scene(MENU)


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	Engine.time_scale = 1.0
	# Freeze the old scene while we fade: nothing in it may act any more.
	get_tree().paused = true
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.3)
	await tw.finished
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("change_scene failed: %s" % path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_property(_overlay, "modulate:a", 0.0, 0.4)
	await tw2.finished
	_busy = false


func fade(to_black: bool, dur: float = 0.3) -> void:
	var tw := create_tween()
	tw.tween_property(_overlay, "modulate:a", 1.0 if to_black else 0.0, dur)
	await tw.finished


func glitch_pulse(strength: float = 0.6, duration: float = 0.4) -> void:
	var r := ColorRect.new()
	r.color = Color(0.1, 1.0, 0.4, 0.12 * strength + 0.05)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.get_parent().add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "modulate:a", 0.0, duration)
	tw.tween_callback(r.queue_free)
