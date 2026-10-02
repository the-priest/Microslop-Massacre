class_name FX
extends Node3D
## Pooled short-lived effects: bullet impacts, holes, blood puffs, tracers.

var _sparks: Array = []
var _holes: Array = []
var _tracers: Array = []
var _blood: Array = []
var _i_spark: int = 0
var _i_hole: int = 0
var _i_tr: int = 0
var _i_blood: int = 0
var _spark_mesh: ArrayMesh
var _hole_mesh: ArrayMesh
var _tr_mesh: ArrayMesh
var _blood_mesh: ArrayMesh


func _ready() -> void:
	var b := MeshBatch.new()
	b.sphere(Vector3.ZERO, 0.05, Color(1.0, 0.8, 0.4), 5, 3)
	_spark_mesh = b.to_mesh()
	var h := MeshBatch.new()
	h.panel(Vector3.ZERO, 0.08, 0.08, Color(0.02, 0.02, 0.02))
	_hole_mesh = h.to_mesh()
	var t := MeshBatch.new()
	t.box(Vector3(0, 0, -0.5), Vector3(0.02, 0.02, 1.0), Color(1.0, 0.85, 0.5))
	_tr_mesh = t.to_mesh()
	var bl := MeshBatch.new()
	bl.sphere(Vector3.ZERO, 0.12, Color(0.45, 0.02, 0.02), 5, 3)
	_blood_mesh = bl.to_mesh()
	for i in 10:
		_sparks.append(_make(_spark_mesh, Mats.glow))
		_tracers.append(_make(_tr_mesh, Mats.glow))
		_blood.append(_make(_blood_mesh, Mats.lit))
	for i in 40:
		_holes.append(_make(_hole_mesh, Mats.lit))


func _make(m: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	return mi


func impact(p: Vector3, n: Vector3) -> void:
	var s: MeshInstance3D = _sparks[_i_spark]
	_i_spark = (_i_spark + 1) % _sparks.size()
	s.global_position = p + n * 0.03
	s.scale = Vector3.ONE
	s.visible = true
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector3.ONE * 0.1, 0.12)
	tw.tween_callback(func() -> void: s.visible = false)
	var hmi: MeshInstance3D = _holes[_i_hole]
	_i_hole = (_i_hole + 1) % _holes.size()
	hmi.visible = true
	hmi.global_position = p + n * 0.012
	if absf(n.dot(Vector3.UP)) > 0.95:
		hmi.global_rotation = Vector3(-PI * 0.5 * signf(n.y), 0, 0)
	else:
		hmi.look_at(p + n, Vector3.UP)
		hmi.rotate_object_local(Vector3.UP, PI)
	if randf() < 0.25:
		AudioManager.play_3d("ricochet", p, -10.0, randf_range(0.8, 1.2))


func blood(p: Vector3) -> void:
	var b: MeshInstance3D = _blood[_i_blood]
	_i_blood = (_i_blood + 1) % _blood.size()
	b.global_position = p
	b.scale = Vector3.ONE * 0.4
	b.visible = true
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector3.ONE * 1.4, 0.15)
	tw.tween_property(b, "scale", Vector3.ONE * 0.01, 0.25)
	tw.tween_callback(func() -> void: b.visible = false)


func tracer(a: Vector3, b: Vector3) -> void:
	var t: MeshInstance3D = _tracers[_i_tr]
	_i_tr = (_i_tr + 1) % _tracers.size()
	var d := b - a
	var L := d.length()
	if L < 0.5:
		return
	t.global_position = a
	t.look_at(b, Vector3.UP if absf(d.normalized().y) < 0.99 else Vector3.RIGHT)
	t.scale = Vector3(1, 1, L)
	t.visible = true
	var tw := t.create_tween()
	tw.tween_interval(0.05)
	tw.tween_callback(func() -> void: t.visible = false)
