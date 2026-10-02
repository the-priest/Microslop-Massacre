extends SceneTree
func _init() -> void:
	var m0 := OS.get_static_memory_usage()
	var cb = load("res://game/city_builder.gd").new()
	var t := Time.get_ticks_msec()
	cb.build_all()
	print("build ms=", Time.get_ticks_msec() - t, " buildings=", cb.stats["buildings"], " doors=", cb.stats["doors"], " lootables=", cb.stats["lootables"], " chunks=", cb.chunks.size())
	var v := 0
	var lab := 0
	for k in cb.chunks.keys():
		var c = cb.chunks[k]
		v += c.facade.vcount() + c.props.vcount() + c.glow.vcount() + c.ground.vcount()
		lab += c.labels.size()
	print("verts=", v, " labels=", lab, " mem MB=", (OS.get_static_memory_usage() - m0) / 1048576)
	quit()
