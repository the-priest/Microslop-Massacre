extends "res://test/towns_walk.gd"
## Cold Chain: Anita at the Lennox Pharmacy on I-80, the MV Everbright's
## gangway at Port Ramsey after dark (and not by day), the reefers and the
## manifest in the hold, and back to Lennox.


func _ready() -> void:
	GameState.region = "highway"
	await _load_game()
	GameState.raise_skill("hacking", 60)
	GameState.raise_skill("medicine", 50)
	_day()
	print("PHASE lennox")
	await _enter_world_at(Vector3(10, 0, 654))
	await _enter_door("d_hw_pharmacy")
	await _wait_rules()
	_expect("sq_cold", 10)
	GameState.tracked_quest = "sq_cold"
	await _talk("anita", ["What happened to the insulin", "How long do your patients have"])
	_expect("sq_cold", 20)
	print("PHASE berth 2")
	await _travel("port", "pt_west")
	await _enter_world_at(Vector3(690, 0, -153))
	_ok("no gangway by day", _find_it("d_pt_ship") == null or not DialogueManager.eval_cond(_find_it("d_pt_ship").cond))
	_night()
	await _follow("sq_cold") # -> up the gangway
	_expect("sq_cold", 30)
	await _spot("pt_reefers", [])
	await _term("reefer_manifest", ["Manifest", "Margin"], ["Reroute the reefers"])
	_ok("insulin rerouted", GameState.has_flag("insulin_rerouted"))
	_expect("sq_cold", 40)
	await _exit_to("world:d_pt_ship")
	print("PHASE back to lennox")
	_day()
	await _travel("highway", "hw_port")
	await _follow("sq_cold") # -> Anita
	await _talk("anita", [])
	_ok("cold chain done", GameState.quest_state("sq_cold") == "done")
	var titles: Array = []
	for sl in EndingData.slides("quiet"):
		titles.append(str((sl as Dictionary)["title"]))
	_ok("the epilogue remembers the cold chain", titles.has("COLD CHAIN"))
	print("COLD WALK DONE fails=%d" % fails)
	get_tree().quit()
