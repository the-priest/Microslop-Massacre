extends Node
## Screenshots of the airfield and flying (for eyeballing, not pass/fail).

var game


func _ready() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = func(c): return 0
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and GameState.cell == "krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	game.hud.visible = false
	GameState.game_minutes = GameState.day() * 1440.0 + 15 * 60.0
	GameState.weather = "clear"
	await game.enter_cell("world", Vector3(1360, 0.2, -1250), -PI * 0.5, false, true)
	await _frames(40)
	game._update_airfield()
	await _frames(10)
	var cam := Camera3D.new()
	game.add_child(cam)
	cam.far = 3000.0
	cam.global_position = Vector3(1370, 4.0, -1215)
	cam.look_at(Vector3(1445, 1.5, -1260), Vector3.UP)
	cam.make_current()
	await _frames(10)
	_shot("air_apron")
	cam.global_position = Vector3(1500, 30.0, -1000)
	cam.look_at(Vector3(1500, 0, -1300), Vector3.UP)
	await _frames(10)
	_shot("air_field")
	# In the air with the ring course up.
	GameState.set_quest_stage("sq_wings", 20)
	game._plane_rings_tick()
	var a: Aircraft = game.planes.get("gus_1")
	a.locked = false
	game.interact(a)
	await _frames(5)
	a.airborne = true
	a.global_position = Vector3(1570, 70, -1650)
	a.heading = 0.0
	a.speed = 40.0
	a.throttle = 0.7
	for i in 90:
		await get_tree().physics_frame
	_shot("air_ring")
	a.global_position = Vector3(300, 160, -700)
	a.heading = PI * 0.75
	for i in 120:
		await get_tree().physics_frame
	_shot("air_city")
	print("AIR SHOTS DONE")
	get_tree().quit()


func _shot(n: String) -> void:
	var d := OS.get_environment("OUT")
	var p := (d.trim_suffix("/") + "/" + n + ".png") if d != "" else "user://" + n + ".png"
	get_viewport().get_texture().get_image().save_png(p)


func _frames(k: int) -> void:
	for i in k:
		await get_tree().process_frame


func _until(c: Callable, limit: int) -> void:
	var t := 0
	while not c.call() and t < limit:
		await get_tree().process_frame
		t += 1
