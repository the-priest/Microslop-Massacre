extends Node
## Helicopters: Bowery Bay's chopper, taken with Gus's yes, lifted off with the
## collective, held in a hover, flown forward and turned, set down gently on a
## rooftop and then back on the pad; the corporate one at Microslop Field.

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
	await game.enter_cell("world", Vector3(1340, 0.2, -1268), -PI * 0.5, false, true)
	await _frames(30)
	game._update_airfield()
	await _frames(5)
	var h: Aircraft = game.planes.get("gus_heli")
	_ok("the chopper is on the apron", h != null and h.model == "heli")
	if h == null:
		_done()
		return
	_ok("locked until Gus says yes", h.locked)
	GameState.flags["gus_plane_ok"] = true
	game._update_airfield()
	_ok("unlocked", not h.locked)
	game.player.global_position = h.global_position + Vector3(4, 0, 0)
	await game.interact(h)
	await _frames(5)
	_ok("in the chopper", game.player.driving == h)
	var y0: float = h.global_position.y
	# Collective up: straight up, no runway.
	Input.action_press("move_forward")
	for i in 150:
		await get_tree().physics_frame
	Input.action_release("move_forward")
	_ok("lifted straight off (y %.1f, moved %.1f m sideways)" % [h.global_position.y, Vector2(h.global_position.x - 1380.0, h.global_position.z + 1268.0).length()], h.airborne and h.global_position.y > y0 + 10.0)
	for i in 90:
		await get_tree().physics_frame
	var yh: float = h.global_position.y
	for i in 120:
		await get_tree().physics_frame
	_ok("hands off, it holds its height (%.1f -> %.1f)" % [yh, h.global_position.y], absf(h.global_position.y - yh) < 2.0)
	# Nose down: forward. A/D: turn on the spot.
	var p0: Vector3 = h.global_position
	for i in 180:
		h._m_pitch = 0.9
		await get_tree().physics_frame
	_ok("nose down flies it forward (%.1f m/s, %.0f m)" % [h.speed, h.global_position.distance_to(p0)], h.speed > 10.0 and h.global_position.distance_to(p0) > 30.0)
	var hd: float = h.heading
	Input.action_press("move_right")
	for i in 60:
		await get_tree().physics_frame
	Input.action_release("move_right")
	_ok("turns right (%.2f rad)" % wrapf(hd - h.heading, -PI, PI), wrapf(hd - h.heading, -PI, PI) > 0.5)
	# Settle onto a rooftop: hover over the tower by the field, let it down.
	var roof := Vector3(1345.0, 0, -995.0) # Bowery Bay's control tower
	h.speed = 0.0
	h.global_position = Vector3(roof.x, 45.0, roof.z)
	h.airborne = true
	h.sink = 0.0
	await get_tree().physics_frame
	Input.action_press("move_back")
	for i in 600:
		await get_tree().physics_frame
		if not h.airborne:
			break
	Input.action_release("move_back")
	_ok("set down on the control tower roof (y %.1f, hp %.0f)" % [h.global_position.y, h.hp], not h.airborne and not h.dead and h.global_position.y > 25.0)
	# Up, over to the apron, down again.
	Input.action_press("move_forward")
	for i in 60:
		await get_tree().physics_frame
	Input.action_release("move_forward")
	_ok("off the roof again", h.airborne)
	h.global_position = Vector3(1380.0, 20.0, -1268.0)
	h.airborne = true
	h.speed = 0.0
	Input.action_press("move_back")
	for i in 600:
		await get_tree().physics_frame
		if not h.airborne:
			break
	Input.action_release("move_back")
	_ok("back on the pad in one piece (y %.2f)" % h.global_position.y, not h.airborne and not h.dead and h.global_position.y < 1.0)
	# A hard arrival is still a crash.
	h.global_position = Vector3(1380.0, 30.0, -1268.0)
	h.airborne = true
	h.sink = -30.0
	h.speed = 40.0
	for i in 120:
		await get_tree().physics_frame
		if h.dead:
			break
	_ok("dropping out of the sky is a crash", h.dead)
	_done()


func _done() -> void:
	print("HELI TEST DONE fails=%d" % fails)
	get_tree().quit()


func _ok(what: String, cond: bool) -> void:
	print(("  ok   " if cond else "  FAIL ") + what)
	if not cond:
		fails += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _until(cond: Callable, limit: int) -> void:
	for i in limit:
		if cond.call():
			return
		await get_tree().process_frame
