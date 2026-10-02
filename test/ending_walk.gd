extends Node
## Reaches one ending per run through the dialogue that actually offers it.
## ENDING env picks the scenario. The state leading up to the choice is set
## directly (the story_walk test covers getting there); the choice itself,
## its visibility conditions and the ending effect are exercised for real.

var game: Node
var prefs: Array = []
var picked: Array = []

const SCENARIOS := {
	"quiet": {"fx": "quest mq_fsociety 20 ; quest mq_fsociety 40 ; set joined_fsociety", "convo": "krista", "npc": "krista", "prefs": ["I want to stop", "Help me stop"]},
	"confession": {"fx": "quest mq_fsociety 20 ; set fbi_contact", "convo": "dipierro", "npc": "dipierro", "prefs": ["Stop fishing", "Say it again"]},
	"confession_lopez": {"fx": "quest sq_lopez 10", "stats": {"innocents": 7}, "convo": "lopez", "npc": "lopez", "prefs": ["It was me", "hands on the desk"], "want": "confession"},
	"informant": {"fx": "quest mq_fsociety 20 ; set joined_fsociety ; quest mq_fsociety 40 ; set fbi_contact ; quest mq_fbi 10 ; quest mq_fbi 20 ; set fbi_informant ; set ally_secured ; quest mq_fbi 30", "convo": "dipierro", "npc": "dipierro", "prefs": ["Take them", "Do it"]},
	"company": {"fx": "set joined_fsociety ; set met_tyrell_invite ; set ecorp_door_tyrell", "convo": "tyrell", "npc": "tyrell_n", "prefs": ["Change of plans", "Everything"]},
	"kingpin": {"fx": "quest sq_candyman 10 ; set candy_resolved ; set kingpin ; set kingpin_clean", "convo": "tee", "npc": "lil_tee", "prefs": ["Forget fsociety", "Tell the boys"]},
	"kingpin_finale": {"finale": true, "fx": "set kingpin ; set kingpin_dirty", "prefs": ["cash is king"], "want": "kingpin"},
	"fsociety": {"finale": true, "prefs": ["fsociety keeps it"]},
	"reboot": {"finale": true, "prefs": ["None of them"]},
	"darkarmy": {"finale": true, "fx": "quest mq_darkarmy 10 ; quest mq_darkarmy 40", "prefs": ["Dark Army finishes"]},
	"fbi": {"finale": true, "fx": "set fbi_informant", "prefs": ["FBI everything"]},
	"ecorp": {"finale": true, "fx": "set ecorp_door_tyrell", "prefs": ["E Corp's offer"]},
	"press": {"finale": true, "fx": "set township_public", "prefs": ["to the press"]},
	"robot": {"finale": true, "fx": "stab -80", "prefs": ["Let him have it"]},
	"monster": {"finale": true, "stats": {"innocents": 12}, "prefs": ["Let it burn"]},
	"overlap": {"finale": true, "fx": "set ending_path=overlap ; set darlene_bond ; set knows_darlene_sister ; set krista_truth", "prefs": ["together"]},
}


func _ready() -> void:
	var which := OS.get_environment("ENDING")
	var sc: Dictionary = SCENARIOS.get(which, {})
	if sc.is_empty():
		print("ENDING WALK: unknown scenario '%s'" % which)
		get_tree().quit()
		return
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate()
	game.test_mode = true
	game.test_picker = _pick
	add_child(game)
	await _until(func() -> bool: return game.player != null and not game.busy_transition and GameState.cell == "krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	game.minigames.auto_result = 1
	GameState.cash = 3000
	GameState.stability = 60
	for k in (sc.get("stats", {}) as Dictionary).keys():
		GameState.stats[k] = int(sc["stats"][k])
	if sc.has("fx"):
		await DialogueManager.run_effects(DialogueManager.parse_effects(str(sc["fx"]), "test"))
	prefs = sc["prefs"]
	if bool(sc.get("finale", false)):
		GameState.set_flag("five_nine_done", true)
		game.dialog.run("finale_choose", null)
	else:
		# Stand in the right room so the NPC is really there.
		var nid := str(sc["npc"])
		var pl: Dictionary = game.npcs.placement(nid, NPCData.NPCS[nid])
		if pl.is_empty():
			print("  FAIL %s has no placement in this state" % nid)
		else:
			var cell := str(pl["cell"])
			if cell != GameState.cell:
				await game.enter_cell(cell, InteriorBuilder.exit_spawn(game.interior_def(cell), 0)["pos"], 0.0, false)
				await _until(func() -> bool: return not game.busy_transition, 600)
			game.npcs.refresh(true)
			await get_tree().process_frame
			var n = game.npcs.get_npc(nid)
			if n == null:
				print("  FAIL %s not spawned in %s" % [nid, cell])
			else:
				game.interact(n)
	var t := 0
	while GameState.ending == "" and t < 3000:
		await get_tree().process_frame
		t += 1
	var want := str(sc.get("want", which))
	print("  picks: ", picked)
	print("ENDING WALK %s: got '%s' -> %s" % [which, GameState.ending, "OK" if GameState.ending == want else "FAIL"])
	get_tree().quit()


func _pick(chs: Array) -> int:
	for p in prefs:
		for i in chs.size():
			if str((chs[i] as Dictionary)["text"]).to_lower().contains(str(p).to_lower()):
				picked.append(str((chs[i] as Dictionary)["text"]).left(40))
				return i
	var texts: Array = []
	for c in chs:
		texts.append(str((c as Dictionary)["text"]).left(40))
	picked.append("DEFAULT of " + str(texts))
	return 0


func _until(cond: Callable, limit: int) -> void:
	var tt := 0
	while not cond.call() and tt < limit:
		await get_tree().process_frame
		tt += 1
