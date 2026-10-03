extends "res://test/towns_walk.gd"
## Wildlife: pigeons and a stray in the city that scatter at a gunshot,
## gulls over the water, deer and cows out on the township's farms; animals
## can be shot.


func _ready() -> void:
	GameState.region = "nyc"
	await _load_game()
	_day()
	await _enter_world_at(Vector3(-470, 0, 330))
	await _fill()
	_ok("pigeons on the sidewalks (%d)" % game.animals.count("pigeon"), game.animals.count("pigeon") >= 4)
	_ok("a stray dog (%d)" % game.animals.count("dog"), game.animals.count("dog") >= 1)
	# A gunshot: the pigeons go up.
	var pg: Variant = null
	for a in game.animals.animals:
		if (a as Animals.Animal).kind == "pigeon":
			pg = a
	if pg != null:
		var y0: float = (pg as Node3D).global_position.y
		game.noise((pg as Node3D).global_position, 40.0, true)
		for i in 90:
			await get_tree().physics_frame
		_ok("a gunshot sends the pigeons up", not is_instance_valid(pg) or (pg as Node3D).global_position.y > y0 + 2.0)
	await _enter_world_at(Vector3(-20, 0, 850))
	await _fill()
	_ok("gulls over the water (%d)" % game.animals.count("gull"), game.animals.count("gull") >= 1)
	await _travel("township", "")
	await _enter_world_at(Vector3(-300, 0, 300))
	await _fill()
	_ok("cows on the farms (%d)" % game.animals.count("cow"), game.animals.count("cow") >= 1)
	_ok("deer in the fields (%d)" % game.animals.count("deer"), game.animals.count("deer") >= 1)
	var cw: Variant = null
	for a in game.animals.animals:
		if (a as Animals.Animal).kind == "cow":
			cw = a
	if cw != null:
		(cw as Animals.Animal).take_hit(500.0, game.player, false, false, 0.0)
		_ok("animals can be shot", (cw as Animals.Animal).dead)
	print("ANIMAL TEST DONE fails=%d" % fails)
	get_tree().quit()


func _fill() -> void:
	for i in 8:
		game.animals._tick = 0.0
		await get_tree().process_frame
		await get_tree().physics_frame
