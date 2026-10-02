extends Node
var game
func _ready():
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate(); game.test_mode = true; game.test_picker = func(c): return 0
	add_child(game)
	var t := 0
	while not (game.player != null and not game.busy_transition and GameState.cell == "krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello")) and t < 6000:
		await get_tree().process_frame; t += 1
	await game.enter_cell("world", Vector3(-30, 0.2, 836), 0.0, false, true)
	await DialogueManager.run_effects(DialogueManager.parse_effects("quest sq_cat 10 ; give flipper_leash 1", "t"))
	for i in 20:
		await get_tree().create_timer(0.3).timeout
		var fired := []
		for tr in WorldObjects.TRIGGERS:
			if GameState.flags.has("trig:" + str(tr["id"])): fired.append(str(tr["id"]))
		print(i, " cat=", GameState.quest_stage("sq_cat"), " ui=", game.ui_depth, " busy=", game.busy_transition, " fired=", fired)
		if GameState.quest_stage("sq_cat") >= 20: break
	get_tree().quit()
