class_name EndingUI
extends Modal
## New Vegas-style ending slides, narrated by Elliot. Built from what you did.

var _title: Label
var _text: RichTextLabel
var _hint: Label
var _bg: ColorRect
var _advance: bool = false


func _build() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 1)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_bg)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.position = Vector2(-520, -240)
	vb.custom_minimum_size = Vector2(1040, 480)
	vb.add_theme_constant_override("separation", 20)
	root.add_child(vb)
	_title = UI.label("", 30, UI.GREEN)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)
	_text = UI.rich(20)
	_text.custom_minimum_size = Vector2(1040, 360)
	_text.add_theme_color_override("default_color", UI.WHITE)
	vb.add_child(_text)
	_hint = UI.label("[A] continue" if Pad.using_pad else "[SPACE / CLICK] continue", 14, UI.GREEN_DIM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_hint)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if (event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_E, KEY_ESCAPE]) or (event is InputEventMouseButton and event.pressed):
		_advance = true
		get_viewport().set_input_as_handled()


func _wait_advance() -> void:
	_advance = false
	var t := 0.0
	while not _advance:
		await get_tree().process_frame
		t += get_process_delta_time()
		if game != null and game.test_mode and t > 0.05:
			break


func play(ending_id: String) -> void:
	GameState.ending = ending_id
	GameState.set_flag("ending_" + ending_id, true)
	if ending_id == "overlap":
		GameState.unlock("overlap")
	if int(GameState.stats.get("kills", 0)) == 0:
		GameState.unlock("pacifist_59")
	open_modal()
	AudioManager.radio_stop()
	AudioManager.set_ambient("jazz")
	var slides := EndingData.slides(ending_id)
	for s in slides:
		var sd: Dictionary = s
		_title.text = str(sd.get("title", ""))
		_text.text = str(sd.get("text", ""))
		_text.visible_ratio = 0.0
		var tw := create_tween()
		tw.tween_property(_text, "visible_ratio", 1.0, 2.5)
		AudioManager.play_whoosh()
		await _wait_advance()
		tw.kill()
		_text.visible_ratio = 1.0
	_title.text = "HELLO, FRIEND"
	_text.text = "[center]\n\nThanks for playing.\n\nAn original fan story in the world of Mr. Robot.\nEvery street, sound and line in this city was made for this game.\n\nKills: %d    Days: %d    Level: %d\nEnding: %s[/center]" % [int(GameState.stats.get("kills", 0)), GameState.day() + 1, GameState.level, EndingData.NAMES.get(ending_id, ending_id)]
	await _wait_advance()
	# Remember endings across saves for the main menu.
	var cfg := ConfigFile.new()
	cfg.load("user://endings.cfg")
	cfg.set_value("endings", ending_id, true)
	cfg.save("user://endings.cfg")
	close_modal()
	SceneRouter.goto_menu()
