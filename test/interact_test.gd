extends "res://test/towns_walk.gd"
## Pressing E: doors, subway stairs and people are picked up when you're
## roughly facing them, from any side, not only with the crosshair dead on;
## never through a wall.


func _ready() -> void:
	GameState.region = "nyc"
	await _load_game()
	_day()
	for did in ["d_apt", "d_ron", "d_arcade"]:
		await _door_from_angles(did)
	await _subway_stairs()
	print("INTERACT TEST DONE fails=%d" % fails)
	get_tree().quit()


func _target_after(p: Vector3, yaw: float, pitch: float) -> Object:
	game.player.teleport(p)
	game.player.set_look(yaw, pitch)
	for i in 4:
		await get_tree().physics_frame
	return game.player.interact_target


func _is_door(t: Object, did: String) -> bool:
	return t is Interactable and (t as Interactable).kind == "door" and str((t as Interactable).data.get("door", (t as Interactable).ident)) == did


func _door_from_angles(did: String) -> void:
	print("PHASE door " + did)
	var dw := WorldLayout.door_world(did)
	var dp: Vector3 = dw["pos"]
	await _enter_world_at(dp)
	# Where the street is: step back from the door the way its facing says.
	var out: Vector3 = dw["out"]
	var stand := dp + out * 2.0 + Vector3(0, 0.1, 0)
	var face := atan2(-(dp - stand).x, -(dp - stand).z)
	var hit := 0
	for off in [0.0, 0.5, -0.5, 0.75, -0.75]:
		for pitch in [0.0, -0.35, 0.3]:
			var t: Object = await _target_after(stand, face + float(off), float(pitch))
			if _is_door(t, did):
				hit += 1
	_ok("%s picked up from %d of 15 angles" % [did, hit], hit >= 13)
	# Right next to it, turned half away: still the door.
	var t2: Object = await _target_after(dp + out * 1.0 + Vector3(0, 0.1, 0), face + 1.3, 0.0)
	_ok("%s from right beside it, half turned" % did, _is_door(t2, did))
	# Facing away: nothing.
	var t3: Object = await _target_after(stand, face + PI, 0.0)
	_ok("%s not picked with your back to it" % did, not _is_door(t3, did))


func _subway_stairs() -> void:
	print("PHASE subway")
	var best := ""
	var bd := INF
	for did in WorldLayout.all_doors().keys():
		if str(did).begins_with("sub_"):
			var p: Vector3 = WorldLayout.door_world(str(did))["pos"]
			var d := p.distance_to(Vector3(-470, 0, 300))
			if d < bd:
				bd = d
				best = str(did)
	_ok("found a subway entrance", best != "")
	if best == "":
		return
	await _door_from_angles(best)
