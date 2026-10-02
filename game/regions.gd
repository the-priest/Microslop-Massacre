class_name Regions
extends RefCounted
## The world beyond New York. Each region is its own map (a street grid the
## same CityBuilder fills in), loaded when you cross into it: drive the
## highway out of a city's travel gate, or fly a plane out of its airspace.
## "nyc" is WorldLayout's own defaults and is never overridden here.

const NAMES := {"nyc": "New York", "highway": "Interstate 80", "chicago": "Chicago"}

## Travel gates: drive into one and you're offered the road beyond it.
## to = [region, gate id on the other side]. "sign" is the green highway sign.
const GATES := {
	"nyc": {
		"nyc_west": {"pos": [-390.0, -1636.0], "r": 22.0, "to": ["highway", "hw_east"], "sign": "I-80 WEST  ·  CHICAGO 790", "yaw": 0.0},
	},
	"highway": {
		"hw_east": {"pos": [0.0, 1760.0], "r": 24.0, "to": ["nyc", "nyc_west"], "sign": "I-80 EAST  ·  NEW YORK CITY", "yaw": PI, "arrive_yaw": 0.0},
		"hw_west": {"pos": [0.0, -1760.0], "r": 24.0, "to": ["chicago", "chi_south"], "sign": "I-80 WEST  ·  CHICAGO", "yaw": 0.0, "arrive_yaw": PI},
	},
	"chicago": {
		"chi_south": {"pos": [20.0, 800.0], "r": 24.0, "to": ["highway", "hw_west"], "sign": "I-90 EAST  ·  NEW YORK 790", "yaw": PI, "arrive_yaw": 0.0},
	},
}

## Where you appear after driving through a gate (a little inside it, facing in).
const ARRIVE := {
	"nyc_west": {"pos": [-390.0, -1590.0], "yaw": PI},
	"hw_east": {"pos": [0.0, 1700.0], "yaw": 0.0},
	"hw_west": {"pos": [0.0, -1700.0], "yaw": PI},
	"chi_south": {"pos": [20.0, 745.0], "yaw": 0.0},
}

## Airspace per region (Rect2 x, z, w, d). Leaving it offers a flight elsewhere.
const SKY := {
	"nyc": Rect2(-1700.0, -2500.0, 4300.0, 3900.0),
	"highway": Rect2(-1200.0, -2600.0, 2700.0, 5200.0),
	"chicago": Rect2(-1500.0, -1500.0, 3200.0, 3000.0),
}

## Landing approach per region when you fly in: [x, altitude, z, heading].
const FLY_IN := {
	"nyc": [1570.0, 160.0, -500.0, 0.0],
	"chicago": [640.0, 150.0, 700.0, 0.0],
	"highway": [0.0, 160.0, 1200.0, 0.0],
}

## Grid and geography for each non-NYC region (overrides WorldLayout).
const DEFS := {
	"highway": {
		"SEED": 8080, "BJ0": 0, "AX0": -300.0, "AXS": 300.0, "NA": 3, "SZ0": -1800.0, "SZS": 300.0, "NS": 13,
		"NBI": 2, "NBJ": 12, "WORLD_X": 560.0, "WORLD_XE": 560.0, "WORLD_ZN": -1840.0, "BEACH_Z1": 1840.0,
		"START_POS": Vector3(0, 0, 1700), "START_YAW": 0.0,
		"DISTRICT_NAMES": {"farm": "Interstate 80", "reststop": "Big Rig Rest Stop", "town": "Lennox, Pennsylvania"},
	},
	"chicago": {
		"SEED": 6060, "BJ0": 0, "AX0": -700.0, "AXS": 120.0, "NA": 13, "SZ0": -700.0, "SZS": 95.0, "NS": 16,
		"NBI": 12, "NBJ": 15, "WORLD_X": 760.0, "WORLD_XE": 860.0, "WORLD_ZN": -760.0, "BEACH_Z1": 820.0,
		"START_POS": Vector3(20, 0, 745), "START_YAW": 0.0,
		"AIRFIELD": {"bi0": 10, "bi1": 11, "bj0": 2, "bj1": 8}, "RUNWAY_X": 640.0, "RUNWAY_HW": 18.0, "RUNWAY_Z0": -470.0, "RUNWAY_Z1": 110.0,
		"DISTRICT_NAMES": {"loop": "The Loop", "river": "River North", "west": "West Loop", "south": "South Side", "lake": "Lakeshore", "airfield": "Meigs Field"},
	},
}

## Off: the NYC-only set pieces (Central Park, Coney, Steel Mountain, Fort Tryon).
const OFF := {"bi0": 99, "bi1": -1, "bj0": 99, "bj1": -1}


static func district(region: String, bi: int, bj: int) -> String:
	match region:
		"highway":
			if bj == 6:
				return "reststop"
			if bj == 9:
				return "town"
			return "farm"
		"chicago":
			if bi >= 10 and bj >= 2 and bj <= 8:
				return "airfield"
			if bi >= 10:
				return "lake"
			if bj <= 2:
				return "river"
			if bj >= 11:
				return "south"
			if bi <= 2:
				return "west"
			return "loop"
	return "les"


static func gates(region: String) -> Dictionary:
	return GATES.get(region, {})


static func sky(region: String) -> Rect2:
	return SKY.get(region, SKY["nyc"])


static func region_name(region: String) -> String:
	return str(NAMES.get(region, region))
