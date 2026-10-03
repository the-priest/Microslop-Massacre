extends "res://test/towns_walk.gd"
## Price Island, which no road reaches: The Ark started by Darlene's text, a
## Skyhawk flown from Ramsey Field across the airspace border over open water
## and landed on Price's strip, Graham's key, the bunker, the Ark wiped, the
## alarm, and the flight back out to Port Ramsey.


func _ready() -> void:
	GameState.region = "port"
	await _load_game()
	GameState.cash = 1500
	GameState.raise_skill("hacking", 70)
	GameState.raise_skill("speech", 65)
	_day()
	await _start()
	await _fly_out()
	await _the_key()
	await _the_ark()
	await _fly_home()
	var titles: Array = []
	for sl in EndingData.slides("quiet"):
		titles.append(str((sl as Dictionary)["title"]))
	_ok("the epilogue remembers the ark", titles.has("THE ARK"))
	print("ISLAND WALK DONE fails=%d" % fails)
	get_tree().quit()


func _start() -> void:
	print("PHASE darlene's text")
	GameState.set_flag("joined_fsociety")
	GameState.complete_quest("mq_steel")
	await _enter_world_at(Vector3(-700, 0, -300))
	await _wait_rules()
	_expect("sq_ark", 10)
	_ok("no road goes there", RegionContent.gate_toward("port", "island") == "")
	var t: Dictionary = game._marker_target("region:island")
	_ok("but the compass points out to sea", not t.is_empty() and (t["pos"] as Vector3).x > game.player.global_position.x)


func _fly_out() -> void:
	print("PHASE fly out")
	var a := await _board_plane(Vector3(-730, 0.5, -100))
	_ok("in a plane at ramsey field", game.player.driving == a)
	await _fly_border("island")
	await _wait_rules()
	_ok("over price island", WorldLayout.region == "island")
	_expect("sq_ark", 20)
	_ok("nobody on the streets, nothing on the roads", game.crowd.peds.size() == 0 and game.traffic.target_count == 0)
	var p: Aircraft = game.player.driving
	await _land(p)
	_ok("landed on price's strip", GameState.has_flag("landed_island"))
	game._update_airfield()
	var owned := 0
	for k in game.planes.keys():
		if str(k).begins_with("island_") and is_instance_valid(game.planes[k]) and (game.planes[k] as Aircraft).locked:
			owned += 1
	_ok("price's own aircraft are locked (%d)" % owned, owned >= 1)
	game.exit_vehicle(true)
	await _settle()


func _the_key() -> void:
	print("PHASE graham")
	GameState.tracked_quest = "sq_ark"
	await _follow("sq_ark") # -> Graham in the rose garden
	await _talk("graham", ["There's a bunker", "What do they cost you"])
	_ok("graham's key", GameState.has_item("ark_key"))
	await _wait_rules()
	_expect("sq_ark", 30)
	await _talk("collins", ["Graham sent me"])
	_ok("collins lets you by", GameState.has_flag("collins_ok"))


func _the_ark() -> void:
	print("PHASE the ark")
	await _follow("sq_ark") # -> the bunker
	_ok("the key lets you in", not game.cell_restricted("isl_ark", "ecorp"))
	await _term("ark_console", ["Ledger", "Restore plan"], ["Wipe the Ark"])
	_ok("the ark is gone", GameState.has_flag("ark_wiped"))
	_expect("sq_ark", 40)
	await _wait_rules()
	_ok("the alarm's going", GameState.has_flag("ark_alarm_heard") and game.cell_restricted("isl_ark", "ecorp"))
	await _exit_to("world:d_isl_bunker")


func _fly_home() -> void:
	print("PHASE fly home")
	var a := await _board_plane(Vector3(-150, 0.5, 200))
	a.airborne = true
	await _fly_border("port")
	await _wait_rules()
	_ok("the ark done", GameState.quest_state("sq_ark") == "done")
