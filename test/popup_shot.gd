extends Node
var game
func _ready():
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate(); game.test_mode = true; game.test_picker = func(c): return 0
	add_child(game)
	var t := 0
	while not (game.player != null and not game.busy_transition and GameState.cell == "krista_office" and not game.dialog.is_open() and GameState.quests.has("mq_hello")) and t < 6000:
		await get_tree().process_frame; t += 1
	GameState.game_minutes = GameState.day() * 1440.0 + 20 * 60.0
	await game.enter_cell("world", Vector3(-466, 0.2, 318), PI * 0.5, false, true)
	await get_tree().create_timer(4.0).timeout
	var out := OS.get_environment("OUT")
	game.robot_popup.level_up(5)
	await get_tree().create_timer(2.2).timeout
	get_viewport().get_texture().get_image().save_png(out + "/pop_level.png")
	await get_tree().create_timer(6.0).timeout
	game.robot_popup.quest_done("The Rootkit", 250)
	await get_tree().create_timer(2.0).timeout
	get_viewport().get_texture().get_image().save_png(out + "/pop_quest.png")
	await get_tree().create_timer(5.5).timeout
	game.robot_popup.objective("Hello, Friend", "Gideon wants you at Allsafe Cybersecurity (Midtown) for the E Corp breach. Talk to him")
	await get_tree().create_timer(1.8).timeout
	get_viewport().get_texture().get_image().save_png(out + "/pop_obj.png")
	print("POPUP SHOTS DONE")
	get_tree().quit()
