extends Node
## Loads every script so parse/compile errors surface in one run (autoloads active).
func _ready() -> void:
	var bad := 0
	for f in _list("res://"):
		if f.ends_with(".gd") and not f.begins_with("res://.godot"):
			var s: Script = load(f)
			if s == null or not s.can_instantiate():
				print("COMPILE FAIL: ", f)
				bad += 1
	print("COMPILE DONE bad=", bad)
	get_tree().quit()
func _list(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if n.begins_with("."):
			n = d.get_next(); continue
		var p := dir.path_join(n)
		if d.current_is_dir():
			out.append_array(_list(p))
		else:
			out.append(p)
		n = d.get_next()
	return out
