class_name Ragdoll
extends Node3D
## When someone dies they don't play a canned fall: their body is cut into
## its six parts (torso, head, two arms, two legs; the person mesh tags every
## vertex with its limb in UV2) and each part becomes a rigid body, jointed at
## the hips, shoulders and neck, shoved by whatever killed them. A part can
## be blown clean off instead (Fallout rules: a big enough hit to a limb).
## The bodies settle, then freeze where they lie.

const LIMBS := [0, 1, 2, 3, 4, 5] # torso, L leg, R leg, L arm, R arm, head
const MASS := {0: 30.0, 1: 9.0, 2: 9.0, 3: 4.5, 4: 4.5, 5: 5.0}
const SWING := {1: 1.0, 2: 1.0, 3: 1.6, 4: 1.6, 5: 0.7}
const SETTLE := 7.0 # seconds before the bodies freeze in place
const MAX_ACTIVE := 10 # oldest ragdolls freeze early beyond this

static var _parts_cache: Dictionary = {}
static var _active: Array = []

var bodies: Dictionary = {} # limb -> RigidBody3D
var follower: Node3D = null # the dead NPC, kept on the torso so you can loot it
var _t := 0.0
var _frozen := false


## The parts of a person mesh: limb -> {mesh (recentred), center, size, pivot}.
static func parts_of(m: Mesh) -> Dictionary:
	var key := m.get_instance_id()
	if _parts_cache.has(key):
		return _parts_cache[key]
	var out := {}
	if m == null or m.get_surface_count() == 0:
		return out
	var a: Array = m.surface_get_arrays(0)
	var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var cols: PackedColorArray = a[Mesh.ARRAY_COLOR]
	var uv2: PackedVector2Array = a[Mesh.ARRAY_TEX_UV2]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var tris := {} # limb -> Array of indices (an Array: packed arrays copy)
	for i in range(0, idx.size(), 3):
		var limb := int(round(uv2[idx[i]].x))
		if not tris.has(limb):
			tris[limb] = []
		(tris[limb] as Array).append_array([idx[i], idx[i + 1], idx[i + 2]])
	for limb in tris.keys():
		var li: Array = tris[limb]
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		for j in li:
			lo = lo.min(verts[int(j)])
			hi = hi.max(verts[int(j)])
		var c := (lo + hi) * 0.5
		var nv := PackedVector3Array()
		var nn := PackedVector3Array()
		var nc := PackedColorArray()
		var nu := PackedVector2Array()
		var ni := PackedInt32Array()
		for j in li:
			ni.append(nv.size())
			nv.append(verts[int(j)] - c)
			nn.append(norms[int(j)])
			nc.append(cols[int(j)])
			nu.append(Vector2.ZERO) # no limb swing on a dead body's parts
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = nv
		arr[Mesh.ARRAY_NORMAL] = nn
		arr[Mesh.ARRAY_COLOR] = nc
		arr[Mesh.ARRAY_TEX_UV2] = nu
		arr[Mesh.ARRAY_INDEX] = ni
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var pv := 0.0
		pv = uv2[int(li[0])].y
		out[int(limb)] = {"mesh": am, "center": c, "size": (hi - lo).max(Vector3(0.06, 0.06, 0.06)), "pivot": pv}
	_parts_cache[key] = out
	return out


## Throw a body. xf: where the person stood. push: the blow's direction and
## strength (m/s), lifted a little. hit: which part took it. cut: parts that
## come away entirely.
static func spawn(parent: Node, mesh: Mesh, xf: Transform3D, push: Vector3, hit: int, cut: Array, follow: Node3D = null) -> Ragdoll:
	var parts := parts_of(mesh)
	if not parts.has(0):
		return null
	var rd := Ragdoll.new()
	rd.name = "Ragdoll"
	parent.add_child(rd)
	rd.follower = follow
	var torso: RigidBody3D = null
	for limb in LIMBS:
		if not parts.has(limb):
			continue
		var pd: Dictionary = parts[limb]
		var rb := RigidBody3D.new()
		rb.mass = float(MASS.get(limb, 5.0))
		rb.collision_layer = 0
		rb.collision_mask = Phys.WORLD | Phys.CAR
		rb.linear_damp = 0.15
		rb.angular_damp = 1.2
		rb.continuous_cd = true
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = (pd["size"] as Vector3) * Vector3(0.9, 0.96, 0.9)
		cs.shape = bs
		rb.add_child(cs)
		var mi := MeshInstance3D.new()
		mi.mesh = pd["mesh"]
		mi.material_override = Mats.npc
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mi.visibility_range_end = 160.0
		rb.add_child(mi)
		rd.add_child(rb)
		rb.global_transform = xf * Transform3D(Basis.IDENTITY, pd["center"])
		# Everyone gets the blow; the part that was hit gets most of it.
		var k := 1.0 if limb == hit else 0.55
		if limb == 0:
			k = 0.8 if hit != 0 else 1.0
		rb.linear_velocity = push * k + Vector3(randf_range(-0.4, 0.4), randf_range(0.0, 0.6), randf_range(-0.4, 0.4))
		rb.angular_velocity = Vector3(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0), randf_range(-2.0, 2.0)) * (2.5 if cut.has(limb) else 0.6)
		rd.bodies[limb] = rb
		if limb == 0:
			torso = rb
	if torso == null:
		return rd
	for a in rd.bodies.values():
		for b in rd.bodies.values():
			if a != b:
				(a as RigidBody3D).add_collision_exception_with(b as RigidBody3D)
	for limb in rd.bodies.keys():
		if int(limb) == 0:
			continue
		var rb2: RigidBody3D = rd.bodies[limb]
		if cut.has(limb):
			# Blown clean off: it flies on its own, and the stump bleeds.
			rb2.linear_velocity += (push.normalized() + Vector3(0, 0.9, 0)) * 4.0
			var st := MeshInstance3D.new()
			var sb := MeshBatch.new()
			sb.box(Vector3.ZERO, Vector3(0.13, 0.05, 0.13), Color(0.45, 0.02, 0.02))
			st.mesh = sb.to_mesh()
			st.material_override = Mats.lit
			torso.add_child(st)
			st.global_position = xf * _joint_point(int(limb), parts)
			continue
		var j := ConeTwistJoint3D.new()
		rd.add_child(j)
		# The twist axis (local X) points down the limb.
		j.global_transform = Transform3D(xf.basis * Basis(Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)), xf * _joint_point(int(limb), parts))
		j.node_a = j.get_path_to(torso)
		j.node_b = j.get_path_to(rb2)
		j.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, float(SWING.get(limb, 1.0)))
		j.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, 0.35)
	_active.append(rd)
	while _active.size() > MAX_ACTIVE:
		var old: Variant = _active.pop_front()
		if old != null and is_instance_valid(old):
			(old as Ragdoll).freeze_now()
	return rd


## Hip, shoulder or neck (local to the standing person) for a limb.
static func _joint_point(limb: int, parts: Dictionary) -> Vector3:
	var pd: Dictionary = parts[limb]
	var c: Vector3 = pd["center"]
	var pv := float(pd["pivot"])
	if pv <= 0.0:
		pv = c.y + (pd["size"] as Vector3).y * 0.5
	return Vector3(c.x, pv, c.z)


func _physics_process(delta: float) -> void:
	if _frozen:
		return
	_t += delta
	var torso: RigidBody3D = bodies.get(0)
	if torso != null and is_instance_valid(torso):
		if torso.global_position.y < -20.0:
			queue_free()
			return
		if follower != null and is_instance_valid(follower):
			# The corpse you loot stays with the body.
			follower.global_position = Vector3(torso.global_position.x, maxf(0.0, torso.global_position.y - 0.25), torso.global_position.z)
	if _t > SETTLE:
		freeze_now()


func freeze_now() -> void:
	if _frozen:
		return
	_frozen = true
	for b in bodies.values():
		if is_instance_valid(b):
			(b as RigidBody3D).freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
			(b as RigidBody3D).freeze = true
	_active.erase(self)


## Which part of a standing person (mesh-local point) a hit landed on.
static func limb_near(mesh: Mesh, local: Vector3) -> int:
	var parts := parts_of(mesh)
	var best := 0
	var bd := INF
	for limb in parts.keys():
		var pd: Dictionary = parts[limb]
		var c: Vector3 = pd["center"]
		var h: Vector3 = (pd["size"] as Vector3) * 0.5 + Vector3(0.05, 0.05, 0.05)
		var d := local - c
		if absf(d.x) <= h.x and absf(d.y) <= h.y and absf(d.z) <= h.z:
			# Inside: prefer the small parts (a hand over the torso behind it).
			var vol := h.x * h.y * h.z
			if vol < bd:
				bd = vol
				best = int(limb)
	if bd < INF:
		return best
	for limb in parts.keys():
		var d2 := local.distance_to((parts[limb] as Dictionary)["center"])
		if d2 < bd:
			bd = d2
			best = int(limb)
	return best


## What comes off, Fallout style: a big hit to a limb can take it clean off
## (more likely with a shotgun up close, a heavy rifle, or a blade), and a
## heavy enough shot to the head takes that. The torso never does.
static func cuts_for(limb: int, dmg: float, model: String, dist: float) -> Array:
	if limb == 0:
		return []
	var chance := 0.0
	var blade := model in ["machete", "katana", "axe", "knife"]
	var scatter := model in ["shotgun", "sawed"]
	if limb == 5:
		if dmg >= 55.0 or scatter and dist < 7.0:
			chance = 0.35
	else:
		if dmg >= 26.0:
			chance = 0.4
		if scatter and dist < 7.0:
			chance = 0.55
		if blade and dmg >= 18.0:
			chance = 0.3
	if GameState.has_perk("bloody_mess"):
		chance = minf(1.0, chance * 1.6 + 0.1)
	return [limb] if randf() < chance else []


## The shove a killing blow gives a body (m/s), mostly along the shot.
static func push_for(dir: Vector3, dmg: float, model: String) -> Vector3:
	var f := clampf(dmg * 0.09, 1.5, 7.5)
	if model in ["shotgun", "sawed", "magnum", "sniper"]:
		f *= 1.5
	var d := Vector3(dir.x, 0.0, dir.z).normalized() if Vector2(dir.x, dir.z).length() > 0.01 else Vector3(0, 0, 1)
	return d * f + Vector3(0, f * 0.25, 0)
