class_name Interactable
extends Area3D
## Anything you can press E on that isn't a person: doors, containers,
## pickups, beds, terminals, and scripted spots. The Game dispatches on `kind`.
## One shape-less instance is also reused as a "virtual" interactable for the
## thousands of props in the LootIndex (dumpsters, parked cars, generic doors).

var kind: String = "spot"
var ident: String = ""
var title: String = ""
var verb: String = "Use"
var data: Dictionary = {}
var cond: Variant = null # parsed dialogue condition; hidden when false
var _shape: CollisionShape3D


func setup(k: String, id: String, t: String, v: String, pos: Vector3, size: Vector3, d: Dictionary = {}) -> Interactable:
	kind = k
	ident = id
	title = t
	verb = v
	data = d
	position = pos
	if d.has("when"):
		cond = DialogueManager.parse_cond(str(d["when"]), "interactable " + id)
	collision_layer = Phys.INTERACT
	collision_mask = 0
	monitoring = false
	monitorable = true
	_shape = CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	_shape.shape = bs
	add_child(_shape)
	return self


func interact_info() -> Dictionary:
	if cond != null and not DialogueManager.eval_cond(cond):
		return {}
	match kind:
		"pickup":
			if GameState.picked.has(ident):
				return {}
			var n := int(data.get("count", 1))
			var iid := str(data.get("item", ""))
			if iid == "cash":
				return {"verb": "Take", "name": "$%d" % n}
			return {"verb": "Take", "name": DB.item_name(iid) + (" (%d)" % n if n > 1 else "")}
		"container":
			var locked := is_locked()
			var nm := title
			if _is_empty() and not locked:
				nm += " (empty)"
			elif is_owned():
				nm += "  [owned]"
			if locked:
				return {"verb": "Pick Lock [%d]" % lock_dc() if lock_dc() <= 100 else "Locked", "name": nm, "locked": true}
			return {"verb": verb if verb != "" else "Search", "name": nm}
		"door":
			var nm2 := title
			if is_closed_now() and not GameState.unlocked.has(ident):
				nm2 += "  (Closed · opens %d:00)" % int((data["hours"] as Array)[0])
			if is_locked():
				var dc := lock_dc()
				var key := str(data.get("key", ""))
				if key != "" and GameState.has_item(key):
					return {"verb": "Open", "name": nm2}
				return {"verb": ("Pick Lock [%d]" % dc) if dc <= 100 else "Locked", "name": nm2, "locked": true}
			return {"verb": verb, "name": nm2}
		"atm":
			var hot := int(GameState.flags.get("atm:" + ident, -99))
			return {"verb": "Use", "name": "ATM" + ("  (locked down)" if GameState.day() - hot < 2 else "")}
	return {"verb": verb, "name": title}


func is_owned() -> bool:
	return str(data.get("owner", "")) != "" and not DialogueManager.check(str(data.get("owner_ok", "false")))


## Businesses with opening hours lock their door when closed.
func is_closed_now() -> bool:
	if not data.has("hours"):
		return false
	var h: Array = data["hours"]
	var a := int(h[0])
	var b := int(h[1])
	var hr := int(GameState.hour())
	var open := (hr >= a and hr < b) if a < b else (hr >= a or hr < b)
	return not open


func lock_dc() -> int:
	if is_closed_now():
		return int(data.get("closed_lock", 40))
	return int(data.get("lock", 0))


func is_locked() -> bool:
	if lock_dc() <= 0:
		return false
	if GameState.unlocked.has(ident):
		return false
	if data.has("unlock_when") and DialogueManager.check(str(data["unlock_when"])):
		return false
	return true


func _is_empty() -> bool:
	if kind != "container":
		return false
	if not GameState.containers.has(ident):
		return false
	var c: Dictionary = GameState.containers[ident]
	var rs := int(data.get("restock", 0))
	if rs > 0 and GameState.day() - int(c.get("day", 0)) >= rs:
		return false
	return (c.get("items", {}) as Dictionary).is_empty() and int(c.get("cash", 0)) <= 0
