extends Node
## SaveManager — JSON save slots in user://saves. Full state, versioned.
## Slots: "quick", "auto", "auto2", "slot1".."slot8".

const DIR := "user://saves"
const SLOTS := ["slot1", "slot2", "slot3", "slot4", "slot5", "slot6", "slot7", "slot8"]
var _last_auto: float = -9999.0
var _auto_flip: bool = false
var pending_load: Dictionary = {} # consumed by Game on start


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


func path_for(slot: String) -> String:
	return "%s/%s.json" % [DIR, slot]


func has_slot(slot: String) -> bool:
	return FileAccess.file_exists(path_for(slot))


func any_save() -> bool:
	return latest_slot() != ""


func save(slot: String, note: String = "") -> bool:
	# Let the running game write the player's position into GameState first.
	var g := DialogueManager.game
	if g != null and g.has_method("sync_state_for_save"):
		g.sync_state_for_save()
	var data := {
		"meta": {
			"slot": slot,
			"note": note,
			"time": Time.get_unix_time_from_system(),
			"level": GameState.level,
			"clock": GameState.clock_text(),
			"date": GameState.date_text(),
			"location": note,
			"playtime": GameState.playtime,
		},
		"state": GameState.to_dict(),
	}
	var f := FileAccess.open(path_for(slot), FileAccess.WRITE)
	if f == null:
		push_error("save failed: " + path_for(slot))
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true


func autosave(note: String = "", force: bool = false) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if not force and now - _last_auto < 45.0:
		return
	_last_auto = now
	_auto_flip = not _auto_flip
	save("auto" if _auto_flip else "auto2", note)


func read_meta(slot: String) -> Dictionary:
	var d := _read(slot)
	return d.get("meta", {}) if not d.is_empty() else {}


func _read(slot: String) -> Dictionary:
	if not has_slot(slot):
		return {}
	var f := FileAccess.open(path_for(slot), FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


## Loads the state into GameState and queues a Game restart.
func load_slot(slot: String) -> bool:
	var d := _read(slot)
	if d.is_empty() or not (d.get("state") is Dictionary):
		return false
	# The state is applied by the new Game scene, never under the world that's
	# still running (its NPCs and triggers would act on the loaded state).
	pending_load = {"slot": slot, "state": d["state"]}
	return true


func latest_slot() -> String:
	var best := ""
	var best_t := -1.0
	for s in ["quick", "auto", "auto2"] + SLOTS:
		var m := read_meta(s)
		if m.is_empty():
			continue
		var t := float(m.get("time", 0))
		if t > best_t:
			best_t = t
			best = s
	return best


func delete_slot(slot: String) -> void:
	if has_slot(slot):
		DirAccess.remove_absolute(path_for(slot))
