extends Node
## Planes: the airfield spawns them, you can take one, take off with the real
## controls, climb, turn, fly through a ring, land gently, and crash hard.

var game
var fails := 0


func _ready() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = func(c): return 0
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and GameState.cell == "krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	GameState.game_minutes = GameState.day() * 1440.0 + 12 * 60.0
	await game.enter_cell("world", Vector3(1300, 0.2, -1279), -PI * 0.5, false, true)
	await _frames(30)
	game._update_airfield()
	await _frames(5)
	_ok("airfield planes spawned (%d)" % game.planes.size(), game.planes.size() == 4)
	_ok("district is the airfield", WorldLayout.district_at(1450, -1250) == "airfield")
	_ok("no avenue through the field", not WorldLayout.avenue_segment_exists(17, 3))
	var a: Aircraft = game.planes.get("gus_1")
	if a == null:
		_done()
		return
	_ok("trainer locked before Gus says yes", a.locked)
	GameState.flags["gus_plane_ok"] = true
	game._update_airfield()
	_ok("Gus's yes unlocks it", not a.locked)
	var info: Dictionary = a.interact_info()
	_ok("prompt: %s" % str(info), str(info.get("verb", "")) == "Fly")
	# Wide shot of the field.
	var shot := Camera3D.new()
	game.add_child(shot)
	shot.global_position = Vector3(1290, 60, -1420)
	shot.look_at(Vector3(1500, 0, -1180), Vector3.UP)
	shot.make_current()
	await _frames(10)
	get_viewport().get_texture().get_image().save_png(_out("airfield.png"))
	shot.queue_free()
	# Line up on the runway, pointing north, and go.
	game.player.global_position = a.global_position + Vector3(0, 0, 6)
	await game.interact(a)
	await _frames(5)
	_ok("in the plane", game.player.driving == a)
	a.global_position = Vector3(WorldLayout.RUNWAY_X, 0.0, WorldLayout.RUNWAY_Z1 - 30.0)
	a.heading = 0.0
	a.rotation = Vector3.ZERO
	await _frames(5)
	Input.action_press("move_forward")
	var t := 0.0
	while t < 25.0 and not a.airborne:
		if a.speed > float(a.spec["rot"]) + 2.0:
			a._m_pitch = -0.9 # mouse pulled back = nose up
		await _frames(1)
		t += get_physics_process_delta_time()
	_ok("rolled down the runway and lifted off (%.1f m/s after %.1f s, z %.0f)" % [a.speed, t, a.global_position.z], a.airborne and a.global_position.z > WorldLayout.RUNWAY_Z0)
	for i in 240:
		a._m_pitch = -0.5
		await _frames(1)
	_ok("climbing (alt %.0f m, pitch %.2f)" % [a.global_position.y, a.pitch], a.global_position.y > 25.0 and not a.dead)
	var view := Camera3D.new()
	game.add_child(view)
	await _frames(3)
	get_viewport().get_texture().get_image().save_png(_out("flying.png"))
	# Bank right: the heading must swing right (rotation.y decreasing).
	var h0: float = a.heading
	Input.action_press("move_right")
	for i in 90:
		await _frames(1)
	Input.action_release("move_right")
	_ok("bank turns right (%.2f rad, bank %.2f)" % [wrapf(h0 - a.heading, -PI, PI), a.bank], wrapf(h0 - a.heading, -PI, PI) > 0.1)
	Input.action_release("move_forward")
	view.queue_free()
	# Ring: put the plane just short of ring 1 on the quest and fly through.
	GameState.set_quest_stage("sq_wings", 20)
	GameState.flags.erase("wings_ring")
	game._plane_rings_tick()
	_ok("rings shown", game.rings != null)
	var rc: Vector3 = game.RINGS[0]
	a.global_position = rc + Vector3(0, 0, 30)
	a.heading = 0.0
	a.pitch = 0.0
	a.bank = 0.0
	a.speed = 45.0
	for i in 60:
		await _frames(1)
		if game.ring_i > 0:
			break
	game._plane_rings_tick()
	_ok("flew through ring 1 (ring_i %d)" % game.ring_i, game.ring_i == 1)
	# Gentle landing: low over the runway, slow-ish, nose a hair up.
	a.global_position = Vector3(WorldLayout.RUNWAY_X, 6.0, -1400.0)
	a.heading = PI # pointing south
	a.pitch = -0.05 # a shallow approach
	a.bank = 0.0
	a.speed = 30.0
	a.throttle = 0.3
	a.sink = 0.0
	a.airborne = true
	for i in 600:
		await _frames(1)
		if not a.airborne:
			break
	Input.action_press("move_back") # throttle off, then the brakes
	for i in 900:
		await _frames(1)
		if a.speed < 1.0:
			break
	Input.action_release("move_back")
	_ok("landed and stopped (airborne %s, speed %.1f, hp %d)" % [a.airborne, a.speed, int(a.hp)], not a.airborne and not a.dead and a.speed < 2.0)
	game._check_wings_landing()
	GameState.set_quest_stage("sq_wings", 30)
	game._check_wings_landing()
	_ok("landing noticed for the quest", GameState.flags.has("wings_landed"))
	game.exit_vehicle()
	await _frames(5)
	_ok("got out on the ground", game.player.driving == null)
	# Crash: straight down from 80 m.
	await game.interact(a)
	await _frames(3)
	GameState.hp = 5000.0
	a.global_position = Vector3(1450, 80.0, -1400.0)
	a.airborne = true
	a.pitch = -1.0
	a.speed = 50.0
	for i in 300:
		await _frames(1)
		if a.dead:
			break
	_ok("nose-dive crashes the plane", a.dead)
	_ok("and throws you out", game.player.driving == null)
	# The jet: stealing it is a crime with consequences.
	var jet: Aircraft = game.planes.get("ecorp_jet")
	_ok("E Corp jet locked", jet != null and jet.locked)
	if jet != null:
		GameState.base_skills["lockpick"] = 100
		game.player.global_position = jet.global_position + Vector3(0, 0, 9)
		await game.interact(jet)
		await _frames(3)
		_ok("stole the jet: wanted + flag", GameState.flags.has("ecorp_jet_gone") and GameState.wanted_until > GameState.game_minutes)
	_done()


func _done() -> void:
	print("FLIGHT TEST DONE fails=%d" % fails)
	get_tree().quit()


func _ok(what: String, cond: bool) -> void:
	print(("  ok   " if cond else "  FAIL ") + what)
	if not cond:
		fails += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _until(c: Callable, limit: int) -> void:
	var t := 0
	while not c.call() and t < limit:
		await get_tree().process_frame
		t += 1


## Screenshots go to $OUT if set, else the user data folder.
func _out(f: String) -> String:
	var d := OS.get_environment("OUT")
	return (d.trim_suffix("/") + "/" + f) if d != "" else "user://" + f
