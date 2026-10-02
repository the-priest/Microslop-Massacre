extends Node
## Perf probe: visit spots across the map, report draw calls / objects / memory.
var game
func _ready() -> void:
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate(); game.test_mode = true; game.test_picker = func(chs): return 0
	add_child(game)
	await _until(func(): return game.player != null and not game.busy_transition and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	var out := OS.get_environment("OUT")
	var spots := [["les", -466, 318, 180], ["midtown", -200, -300, 0], ["bronx", 0, -1380, 0], ["harlem", 150, -980, 90], ["lic", 1240, 200, 270], ["astoria", 1200, -480, 0], ["hunts", 1235, -1180, 180], ["tryon", -650, -1250, 0]]
	for sp in spots:
		GameState.game_minutes = GameState.day() * 1440.0 + 14 * 60.0
		await game.enter_cell("world", Vector3(float(sp[1]), 0, float(sp[2])), deg_to_rad(float(sp[3])), false, true)
		for i in 30:
			await get_tree().process_frame
		var dc := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var ob := Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		var pr := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		var mem := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
		var vm := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
		var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		print("PERF %-8s draws=%d objects=%d prims=%dk mem=%dMB vram=%dMB nodes=%d district=%s" % [sp[0], dc, ob, int(pr / 1000), int(mem), int(vm), nodes, WorldLayout.district_at(float(sp[1]), float(sp[2]))])
		if out != "":
			get_viewport().get_texture().get_image().save_png(out + "/" + str(sp[0]) + ".png")
	get_tree().quit()
func _until(c, l): var t = 0; while not c.call() and t < l: await get_tree().process_frame; t += 1
