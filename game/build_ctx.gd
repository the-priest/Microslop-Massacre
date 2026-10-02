class_name BuildCtx
extends RefCounted
## One chunk (or interior) worth of geometry, split by material, plus
## collision boxes. commit() turns it into a handful of nodes.

var facade := MeshBatch.new()
var ground := MeshBatch.new()
var props := MeshBatch.new()
var glow := MeshBatch.new()
var pool := MeshBatch.new()
var solids: Array = [] # [center: Vector3, size: Vector3, rot_y: float]
var labels: Array = [] # {pos, text, size, color, rot, range, outline}
var props_mat: Material = null # city chunks use Mats.city_lit / city_glow
var glow_mat: Material = null


## tag "bounds": the invisible walls at the edge of the city (planes fly over).
func solid(center: Vector3, size: Vector3, rot_y: float = 0.0, tag: String = "") -> void:
	solids.append([center, size, rot_y, tag])


func label(pos: Vector3, text: String, font_size: int, color: Color, rot_y: float, vis_range: float = 160.0, pixel: float = 0.02) -> void:
	labels.append({"pos": pos, "text": text, "size": font_size, "color": color, "rot": rot_y, "range": vis_range, "pixel": pixel})


func commit(parent: Node3D, far: float, props_range: float = 260.0, collision: bool = true) -> void:
	facade.commit(parent, Mats.facade, far, "Facade")
	ground.commit(parent, Mats.lit, minf(far, 520.0), "Ground")
	props.commit(parent, props_mat if props_mat != null else Mats.lit, props_range, "Props")
	glow.commit(parent, glow_mat if glow_mat != null else Mats.glow, far, "Glow")
	pool.commit(parent, Mats.pool, 170.0, "Pools")
	if collision and not solids.is_empty():
		var body := StaticBody3D.new()
		body.name = "Solids"
		body.collision_layer = 1
		body.collision_mask = 0
		parent.add_child(body)
		for s in solids:
			var cs := CollisionShape3D.new()
			var sh := BoxShape3D.new()
			sh.size = s[1]
			cs.shape = sh
			cs.position = s[0]
			if float(s[2]) != 0.0:
				cs.rotation.y = float(s[2])
			if (s as Array).size() > 3 and str(s[3]) != "":
				cs.set_meta("tag", str(s[3]))
			body.add_child(cs)
	for l in labels:
		var lb := Label3D.new()
		lb.text = str(l["text"])
		lb.font_size = int(l["size"])
		lb.pixel_size = float(l["pixel"])
		lb.modulate = l["color"]
		lb.outline_size = 0
		lb.position = l["pos"]
		lb.rotation.y = float(l["rot"])
		lb.double_sided = false
		lb.shaded = false
		lb.visibility_range_end = float(l["range"])
		lb.font = UI.font_sign()
		lb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(lb)
