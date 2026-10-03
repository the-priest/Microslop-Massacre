extends Node
## Screenshots of the connected world from the air (for eyeballing): REGION
## env picks the map; a free camera looks along the route between cities.

var game


func _ready() -> void:
	var reg := OS.get_environment("REGION")
	if reg != "":
		GameState.region = reg
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = func(c): return 0
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	game.hud.visible = false
	if OS.get_environment("NOSHADOW") != "":
		Settings.set_v("shadow_q", 0)
		Settings.applied.emit()
	GameState.weather = "clear"
	var out := OS.get_environment("OUT")
	if out == "":
		out = "/tmp/world_shots"
	DirAccess.make_dir_recursive_absolute(out)
	# name:x,y,z,look_x,look_y,look_z,hour;...
	for s in OS.get_environment("SHOTS").split(";", false):
		var ci := s.find(":")
		var nm := s.substr(0, ci)
		var p := s.substr(ci + 1).split(",")
		GameState.game_minutes = GameState.day() * 1440.0 + float(p[6]) * 60.0
		await game.enter_cell("world", Vector3(float(p[0]), 0.2, float(p[2])), 0.0, false, true)
		game.force_high = true
		game._update_high_mode()
		var cam := Camera3D.new()
		game.add_child(cam)
		cam.far = 7000.0
		cam.near = 1.5
		cam.fov = 70.0
		cam.global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
		cam.look_at(Vector3(float(p[3]), float(p[4]), float(p[5])), Vector3.UP)
		cam.make_current()
		for hn in OS.get_environment("HIDE").split(",", false):
			for n in game.find_children(hn, "", true, false):
				if n is Node3D:
					(n as Node3D).visible = false
		for i in 40:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(out + "/" + nm + ".png")
		print("SHOT ", nm)
		cam.queue_free()
	if OS.get_environment("MAPSHOT") != "":
		await game.enter_cell("world", WorldLayout.START_POS + Vector3(0, 0.2, 0), 0.0, false, true)
		game.hud.visible = true
		game.phone.open("map")
		for i in 30:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(out + "/map.png")
		print("SHOT map")
	get_tree().quit()


func _until(c: Callable, l: int) -> void:
	var t := 0
	while not c.call() and t < l:
		await get_tree().process_frame
		t += 1
