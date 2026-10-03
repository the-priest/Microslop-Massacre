class_name MapRender
extends RefCounted
## Renders the city map once into an Image (green phosphor style).

const SIZE := 1536
## The square of ground the map covers, per map (x0, z0, span).
const FRAMES := {
	"nyc": [-950.0, -1750.0, 2800.0],
	"highway": [-1000.0, -1000.0, 2000.0],
	"chicago": [-900.0, -900.0, 1900.0],
	"township": [-760.0, -720.0, 1480.0],
	"port": [-960.0, -760.0, 1760.0],
	"gary": [-860.0, -760.0, 1720.0],
}
static var X0 := -950.0
static var Z0 := -1750.0
static var SPAN := 2800.0


static func use_region(region: String) -> void:
	var f: Array = FRAMES.get(region, FRAMES["nyc"])
	X0 = float(f[0])
	Z0 = float(f[1])
	SPAN = float(f[2])


static func to_px(x: float, z: float) -> Vector2:
	return Vector2((x - X0) / SPAN * SIZE, (z - Z0) / SPAN * SIZE)


static func to_world(px: Vector2) -> Vector2:
	return Vector2(px.x / SIZE * SPAN + X0, px.y / SIZE * SPAN + Z0)


static func _rect(img: Image, x0: float, z0: float, x1: float, z1: float, c: Color) -> void:
	var a := to_px(x0, z0)
	var b := to_px(x1, z1)
	var r := Rect2i(int(minf(a.x, b.x)), int(minf(a.y, b.y)), maxi(1, int(absf(b.x - a.x))), maxi(1, int(absf(b.y - a.y))))
	r = r.intersection(Rect2i(0, 0, SIZE, SIZE))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, c)


static func render(buildings: Array) -> Image:
	use_region(WorldLayout.region)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.05, 0.03))
	# Water.
	var ex := WorldLayout.WORLD_XE
	var zn := WorldLayout.WORLD_ZN
	_rect(img, X0, Z0, -866, Z0 + SPAN, Color(0.0, 0.1, 0.12))
	_rect(img, ex, Z0, X0 + SPAN, Z0 + SPAN, Color(0.0, 0.1, 0.12))
	_rect(img, X0, WorldLayout.BEACH_Z1, X0 + SPAN, Z0 + SPAN, Color(0.0, 0.1, 0.12))
	# Land base.
	_rect(img, -866, zn, ex, WorldLayout.BEACH_Z1, Color(0.02, 0.09, 0.05))
	# Park + beach.
	var px0 := WorldLayout.ax(WorldLayout.PARK["bi0"]) + WorldLayout.AVE_HW
	var px1 := WorldLayout.ax(WorldLayout.PARK["bi1"] + 1) - WorldLayout.AVE_HW
	var pz0 := WorldLayout.sz(WorldLayout.PARK["bj0"]) + WorldLayout.ST_HW
	var pz1 := WorldLayout.sz(WorldLayout.PARK["bj1"] + 1) - WorldLayout.ST_HW
	_rect(img, px0, pz0, px1, pz1, Color(0.05, 0.22, 0.08))
	var T := WorldLayout.TRYON
	_rect(img, WorldLayout.ax(int(T["bi0"])) + WorldLayout.AVE_HW, WorldLayout.sz(int(T["bj0"])) + WorldLayout.ST_HW, WorldLayout.ax(int(T["bi1"]) + 1) - WorldLayout.AVE_HW, WorldLayout.sz(int(T["bj1"]) + 1) - WorldLayout.ST_HW, Color(0.04, 0.18, 0.06))
	_rect(img, -170, 40, -60, 120, Color(0.0, 0.14, 0.16))
	# Bowery Bay Airfield: grass, apron and the runway.
	var af := WorldLayout.airfield_rect()
	_rect(img, af.position.x, af.position.y, af.end.x, af.end.y, Color(0.04, 0.15, 0.07))
	_rect(img, 1330, -1300, 1470, -1120, Color(0.1, 0.26, 0.15))
	_rect(img, WorldLayout.RUNWAY_X - WorldLayout.RUNWAY_HW, WorldLayout.RUNWAY_Z0, WorldLayout.RUNWAY_X + WorldLayout.RUNWAY_HW, WorldLayout.RUNWAY_Z1, Color(0.16, 0.4, 0.22))
	_rect(img, WorldLayout.RUNWAY_X - 1.5, WorldLayout.RUNWAY_Z0 + 20, WorldLayout.RUNWAY_X + 1.5, WorldLayout.RUNWAY_Z1 - 20, Color(0.4, 0.8, 0.5))
	_rect(img, -866, WorldLayout.BOARD_Z1, ex, WorldLayout.BEACH_Z1, Color(0.2, 0.2, 0.1))
	_rect(img, -866, WorldLayout.BOARD_Z0, ex, WorldLayout.BOARD_Z1, Color(0.18, 0.14, 0.06))
	_rect(img, WorldLayout.PIER_X0, WorldLayout.BOARD_Z1, WorldLayout.PIER_X1, WorldLayout.PIER_Z1, Color(0.18, 0.14, 0.06))
	# Roads.
	var road := Color(0.1, 0.32, 0.16)
	for i in WorldLayout.NA:
		for j in WorldLayout.NS - 1:
			if WorldLayout.avenue_segment_exists(i, j):
				var x := WorldLayout.ax(i)
				_rect(img, x - WorldLayout.AVE_HW, WorldLayout.sz(j), x + WorldLayout.AVE_HW, WorldLayout.sz(j + 1), road)
		_rect(img, WorldLayout.ax(i) - WorldLayout.AVE_HW, WorldLayout.sz(WorldLayout.NS - 1), WorldLayout.ax(i) + WorldLayout.AVE_HW, WorldLayout.SURF_Z, road)
	for j in WorldLayout.NS:
		for i in WorldLayout.NA - 1:
			if WorldLayout.street_segment_exists(j, i):
				var z := WorldLayout.sz(j)
				_rect(img, WorldLayout.ax(i), z - WorldLayout.ST_HW, WorldLayout.ax(i + 1), z + WorldLayout.ST_HW, road)
	_rect(img, WorldLayout.ax(0), WorldLayout.SURF_Z - WorldLayout.ST_HW, WorldLayout.ax(WorldLayout.NA - 1), WorldLayout.SURF_Z + WorldLayout.ST_HW, road)
	# Buildings, brighter = taller.
	for b in buildings:
		var ba: Array = b
		var h := float(ba[4])
		var t := clampf(h / 120.0, 0.0, 1.0)
		var c := Color(0.06, 0.2, 0.1).lerp(Color(0.2, 0.55, 0.3), t)
		_rect(img, float(ba[0]), float(ba[1]), float(ba[2]), float(ba[3]), c)
	return img


static func texture(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)
