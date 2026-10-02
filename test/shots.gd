extends Node
## Screenshot harness. SHOTS env: "name:x,z,yaw_deg,pitch_deg,hour;..." (world cell)
## or "name:@cell,x,z,yaw,pitch,hour" for an interior. Writes PNGs to OUT dir.
var game

func _ready() -> void:
	if OS.get_environment("REGION") != "":
		GameState.region = OS.get_environment("REGION")
	var scene: PackedScene = load("res://game/Game.tscn")
	game = scene.instantiate(); game.test_mode = true; game.test_picker = func(chs): return 0
	add_child(game)
	await _until(func(): return game.player != null and not game.busy_transition and not game.dialog.is_open() and GameState.quests.has("mq_hello"), 6000)
	var out := OS.get_environment("OUT")
	if out == "":
		out = "/tmp/shots"
	DirAccess.make_dir_recursive_absolute(out)
	var spec := OS.get_environment("SHOTS")
	for s in spec.split(";", false):
		var ci := s.find(":")
		var nm := s.substr(0, ci)
		var p := s.substr(ci + 1).split(",")
		var cell := "world"
		var off := 0
		if p[0].begins_with("@"):
			cell = p[0].substr(1)
			off = 1
			if cell.begins_with("kind="):
				var want := cell.substr(5)
				for gid in game.gen_doors.keys():
					if str(game.gen_doors[gid]["kind"]) == want:
						cell = "bld:" + str(gid)
						break
		var x := float(p[off]); var z := float(p[off + 1]); var yaw := deg_to_rad(float(p[off + 2])); var pitch := deg_to_rad(float(p[off + 3])); var hr := float(p[off + 4])
		GameState.game_minutes = GameState.day() * 1440.0 + hr * 60.0
		GameState.weather = "clear"
		if cell == "roof" or cell == "roof_edge":
			await game._take_exit("roof:wtc")
			await _until(func(): return not game.busy_transition, 300)
			if cell == "roof_edge":
				game.player.global_position = Vector3(-96, 380.3, 339.6) if yaw > -1.0 and yaw < 1.0 else Vector3(-96, 380.3, 376.6)
		elif cell == "intro":
			await game.enter_cell("world", Vector3(-96, 0.1, 420), PI, false, true)
			game.force_high = true
			game._update_high_mode()
			game.hud.set_visible_all(false)
			var ic := IntroCinematic.new()
			game.add_child(ic)
			ic.game = game
			ic._build_ui()
			ic.cam = Camera3D.new(); ic.cam.far = 3400.0; ic.cam.fov = 60.0
			game.add_child(ic.cam)
			ic.cam.make_current()
			var shot: Dictionary = IntroCinematic.SHOTS[int(x)]
			ic._fade.color.a = 0.0
			ic._stamp.text = str(shot.get("stamp", ""))
			ic._text.text = str(shot["lines"][0])
			ic.pose(shot, z)
			for i in 40:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(out + "/" + nm + ".png")
			print("SHOT ", nm)
			ic.cam.queue_free(); ic.queue_free()
			game.force_high = false
			game.player.cam.make_current()
			continue
		elif cell == "world":
			await game.enter_cell("world", Vector3(x, 0, z), yaw, false, true)
		else:
			await game.enter_cell(cell, Vector3(x, 0, z), yaw, false, false)
		game.player.set_look(yaw, pitch)
		for i in 40:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png(out + "/" + nm + ".png")
		print("SHOT ", nm)
	get_tree().quit()

func _until(c, l): var t = 0; while not c.call() and t < l: await get_tree().process_frame; t += 1
