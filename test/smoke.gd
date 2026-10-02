extends Node
## Runtime smoke test: boots the Game in test mode and exercises systems.
var game: Node
var shots := 0
func _ready() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	add_child(game)
	await _wait_ready()
	print("SMOKE: game ready, cell=", GameState.cell, " quests=", GameState.quests.keys())
	await _shot("krista")
	await game._take_exit("world:d_krista")
	await _frames(20)
	print("SMOKE: in world at ", game.player.global_position, " cell=", GameState.cell)
	await _shot("street_start")
	# Walk forward for a bit.
	Input.action_press("move_forward")
	await _frames(90)
	Input.action_release("move_forward")
	print("SMOKE: after walk ", game.player.global_position)
	# Spawn a hostile thug and let them fight.
	var n := NPC.new()
	n.setup("test_thug", NPCData.TEMPLATES["thug_gun"], game.player.global_position + Vector3(0, 0, -12), 0.0, "world", game)
	game.npcs.add_child(n)
	n.global_position = game.player.global_position + Vector3(0, 0, -12)
	await _frames(60)
	print("SMOKE: thug mode=", n.mode, " player hp=", GameState.hp)
	GameState.give("pistol_9mm"); GameState.give("ammo_9mm", 40); GameState.equip("pistol_9mm")
	await _frames(5)
	game.player.look_toward(n.chest_pos())
	for i in 8:
		game.player.attack()
		await _frames(12)
	print("SMOKE: thug hp=", n.hp, " dead=", n.dead)
	await _shot("combat")
	game.phone.open("stats")
	await _frames(5)
	await _shot("phone_stats")
	game.phone.close_modal()
	game.phone.open("map")
	await _frames(5)
	await _shot("phone_map")
	game.phone.close_modal()
	# Enter apartment door region: teleport + enter bodega interior etc.
	await game.travel_to("d_ecorp")
	await _frames(30)
	await _shot("ecorp_plaza")
	GameState.game_minutes += 14 * 60
	await _frames(30)
	await _shot("day_street")
	print("SMOKE: crowd=", game.crowd.peds.size(), " traffic=", game.traffic.cars.size())
	print("SMOKE DONE")
	get_tree().quit()
func _wait_ready() -> void:
	var t := 0
	while (game.player == null or game.busy_transition or GameState.cell == "world") and t < 1200:
		await get_tree().process_frame
		t += 1
	await _frames(30)
func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
func _shot(name: String) -> void:
	await _frames(3)
	var dc := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	print("SHOT %s drawcalls=%d fps=%d" % [name, dc, Engine.get_frames_per_second()])
	get_viewport().get_texture().get_image().save_png(_out("g_%s.png" % name))


## Screenshots go to $OUT if set, else the user data folder.
func _out(f: String) -> String:
	var d := OS.get_environment("OUT")
	return (d.trim_suffix("/") + "/" + f) if d != "" else "user://" + f
