extends Node
## Plays the New Game intro for a few seconds, skips it, and checks we land in
## Krista's office with the HUD back and the player camera current.
var game

func _ready() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	add_child(game)
	var t := 0
	while game.get_node_or_null("Intro") == null and t < 6000:
		await get_tree().process_frame; t += 1
	var intro = game.get_node_or_null("Intro")
	print("INTRO started=", intro != null, " cell=", GameState.cell)
	for i in 240:
		await get_tree().process_frame
	print("INTRO cam current=", get_viewport().get_camera_3d().name, " text=", intro._text.text.left(40))
	var ev := InputEventKey.new(); ev.keycode = KEY_SPACE; ev.pressed = true
	Input.parse_input_event(ev)
	t = 0
	while GameState.cell != "krista_office" and t < 3000:
		await get_tree().process_frame; t += 1
	for i in 120:
		await get_tree().process_frame
	var ok: bool = GameState.cell == "krista_office" and game.dialog.is_open() and not is_instance_valid(intro) and not game.cinematic and not game.force_high
	print("INTRO DONE ok=", ok, " cell=", GameState.cell, " cam=", get_viewport().get_camera_3d().name, " hud_hidden=", game.hud.hidden_all, " high=", game._high_mode, " far=", game.player.cam.far)
	get_tree().quit()
