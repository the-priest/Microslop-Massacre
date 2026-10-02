class_name Compass
extends Control
## FNV-style compass strip. Game fills `markers` each frame:
## [{dir: Vector3 (world), kind: "quest"|"poi"|"hostile"|"friend"|"door", dist: float}]

var heading: float = 0.0 # player yaw
var markers: Array = []
var fov_deg: float = 160.0


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0, 0.04, 0.02, 0.55))
	draw_rect(Rect2(0, 0, w, h), UI.GREEN_DIM, false, 1.0)
	var font := UI.mono()
	var dirs := {"N": 0.0, "NE": 45.0, "E": 90.0, "SE": 135.0, "S": 180.0, "SW": 225.0, "W": 270.0, "NW": 315.0}
	# Heading 0 = facing north (-Z). Player yaw: forward = (-sin y, 0, -cos y).
	var facing := fposmod(-rad_to_deg(heading), 360.0)
	for k in dirs.keys():
		var a: float = dirs[k]
		var d := wrapf(a - facing, -180.0, 180.0)
		if absf(d) > fov_deg * 0.5:
			continue
		var x := w * 0.5 + d / (fov_deg * 0.5) * (w * 0.5 - 10.0)
		var major := str(k).length() == 1
		draw_line(Vector2(x, 0), Vector2(x, 6 if major else 4), UI.GREEN, 1.0)
		draw_string(font, Vector2(x - (5.0 if major else 9.0), h - 5.0), str(k), HORIZONTAL_ALIGNMENT_LEFT, -1, 14 if major else 11, UI.GREEN if major else UI.GREEN_DIM)
	for tick in range(0, 360, 15):
		var d2 := wrapf(float(tick) - facing, -180.0, 180.0)
		if absf(d2) > fov_deg * 0.5:
			continue
		var x2 := w * 0.5 + d2 / (fov_deg * 0.5) * (w * 0.5 - 10.0)
		draw_line(Vector2(x2, 0), Vector2(x2, 3), UI.GREEN_DIM, 1.0)
	for m in markers:
		var md: Dictionary = m
		var v: Vector3 = md["dir"]
		var a2 := fposmod(rad_to_deg(atan2(v.x, -v.z)), 360.0)
		var dd := wrapf(a2 - facing, -180.0, 180.0)
		var clamped := false
		if absf(dd) > fov_deg * 0.5:
			if str(md["kind"]) != "quest" and str(md["kind"]) != "job":
				continue
			dd = clampf(dd, -fov_deg * 0.5, fov_deg * 0.5)
			clamped = true
		var mx := w * 0.5 + dd / (fov_deg * 0.5) * (w * 0.5 - 10.0)
		match str(md["kind"]):
			"quest":
				var c := UI.AMBER if not clamped else UI.AMBER * Color(1, 1, 1, 0.6)
				draw_colored_polygon(PackedVector2Array([Vector2(mx - 6, 2), Vector2(mx + 6, 2), Vector2(mx, 12)]), c)
				if float(md.get("dist", 0.0)) > 0.0:
					draw_string(font, Vector2(mx + 8, 12), "%dm" % int(md["dist"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, c)
			"job":
				var jc := Color(0.4, 0.85, 1.0) if not clamped else Color(0.4, 0.85, 1.0, 0.55)
				draw_colored_polygon(PackedVector2Array([Vector2(mx, 2), Vector2(mx + 5, 7), Vector2(mx, 12), Vector2(mx - 5, 7)]), jc)
				if float(md.get("dist", 0.0)) > 0.0:
					draw_string(font, Vector2(mx + 7, 12), "$%dm" % int(md["dist"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, jc)
			"poi":
				draw_rect(Rect2(mx - 3, h * 0.5 - 3, 6, 6), UI.GREEN_DIM, false, 1.0)
			"door":
				draw_rect(Rect2(mx - 3, h * 0.5 - 3, 6, 6), UI.GREEN, true)
			"hostile":
				draw_line(Vector2(mx, 2), Vector2(mx, h - 2), UI.RED, 2.0)
			"friend":
				draw_line(Vector2(mx, 4), Vector2(mx, h - 4), UI.GREEN, 2.0)
	draw_line(Vector2(w * 0.5, 0), Vector2(w * 0.5, h), Color(1, 1, 1, 0.25), 1.0)
