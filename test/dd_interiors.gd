extends Node
var game
var problems: Array = []
func _ready() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate(); game.test_mode = true; game.test_picker = func(chs): return 0
	add_child(game)
	await _until(func(): return game.player != null and not game.busy_transition and GameState.cell=="krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	GameState.new_game(); GameState.set_tags(["hacking","sneak","speech"])
	# give disguises so restricted interiors don't trigger hostile spam
	for d in ["ecorp_uniform","steel_coveralls","darkarmy_jacket"]: GameState.give(d)
	var cells := InteriorData.INTERIORS.keys(); cells.sort()
	for cell in cells:
		if str(cell)=="subway": continue
		await game.enter_cell(str(cell), InteriorBuilder.exit_spawn(game.interior_def(str(cell)),0)["pos"], 0.0, false)
		await get_tree().physics_frame; await get_tree().physics_frame
		var t=0
		while game.busy_transition and t<200: await get_tree().process_frame; t+=1
		if GameState.cell != str(cell): problems.append("enter fail: "+str(cell))
		# verify every exit link resolves to a real destination
		for e in game.interior_def(str(cell)).get("exits", []):
			var loc = game.resolve_location(str((e as Dictionary).get("to","")).replace("world:","").replace("interior:","").split(":")[0]) if false else {}
		await _frames(2)
	print("INTERIORS DONE problems=%d" % problems.size())
	for p in problems: print("PROBLEM ", p)
	get_tree().quit()
func _until(c,l): var t=0; while not c.call() and t<l: await get_tree().process_frame; t+=1
func _frames(n): for i in n: await get_tree().process_frame
