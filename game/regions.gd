class_name Regions
extends RefCounted
## The world beyond New York. Each region is its own map (a street grid the
## same CityBuilder fills in), loaded when you cross into it: drive the
## highway out of a city's travel gate, or fly a plane across the edge of its
## airspace. "nyc" is WorldLayout's own defaults and is never overridden here.
##
## The maps sit side by side in one shared world (WORLD offsets): New York in
## the south, about three kilometres of Pennsylvania farmland on I-80, then
## Chicago in the north. Off the interstate, a county road runs west to
## Washington Township and another east to Port Ramsey on the coast; north of
## the township, on the lake, Gary, Indiana, with I-90 east into Chicago. Every
## airspace touches its neighbours edge to edge, so a plane flies straight
## from one into the next with the same speed, height and heading.

const NAMES := {"nyc": "New York", "highway": "Interstate 80", "chicago": "Chicago", "township": "Washington Township", "port": "Port Ramsey", "gary": "Gary, Indiana"}

## Travel gates: drive into one and you're offered the road beyond it.
## to = [region, gate id on the other side]. "sign" is the green highway sign.
const GATES := {
	"nyc": {
		"nyc_west": {"pos": [-390.0, -1636.0], "r": 22.0, "to": ["highway", "hw_east"], "sign": "I-80 WEST  ·  CHICAGO", "yaw": 0.0},
	},
	"highway": {
		"hw_east": {"pos": [0.0, 860.0], "r": 24.0, "to": ["nyc", "nyc_west"], "sign": "I-80 EAST  ·  NEW YORK CITY", "yaw": PI, "arrive_yaw": 0.0},
		"hw_west": {"pos": [0.0, -860.0], "r": 24.0, "to": ["chicago", "chi_south"], "sign": "I-80 WEST  ·  CHICAGO", "yaw": 0.0, "arrive_yaw": PI},
		"hw_tw": {"pos": [-520.0, 0.0], "r": 24.0, "to": ["township", "tw_east"], "sign": "EXIT 41  ·  WASHINGTON TOWNSHIP", "yaw": PI * 0.5},
		"hw_port": {"pos": [520.0, 0.0], "r": 24.0, "to": ["port", "pt_west"], "sign": "EXIT 42  ·  PORT RAMSEY", "yaw": -PI * 0.5},
	},
	"chicago": {
		"chi_south": {"pos": [20.0, 800.0], "r": 24.0, "to": ["highway", "hw_west"], "sign": "I-90 EAST  ·  NEW YORK", "yaw": PI, "arrive_yaw": 0.0},
		"chi_west": {"pos": [-760.0, -35.0], "r": 24.0, "to": ["gary", "gy_east"], "sign": "I-90  ·  GARY, INDIANA", "yaw": PI * 0.5},
	},
	"township": {
		"tw_east": {"pos": [680.0, 0.0], "r": 24.0, "to": ["highway", "hw_tw"], "sign": "TO I-80  ·  NEW YORK  ·  CHICAGO", "yaw": -PI * 0.5},
		"tw_north": {"pos": [0.0, -580.0], "r": 24.0, "to": ["gary", "gy_south"], "sign": "STATE ROAD 912 NORTH  ·  GARY", "yaw": 0.0},
	},
	"gary": {
		"gy_east": {"pos": [790.0, 0.0], "r": 24.0, "to": ["chicago", "chi_west"], "sign": "I-90 EAST  ·  CHICAGO", "yaw": -PI * 0.5},
		"gy_south": {"pos": [0.0, 680.0], "r": 24.0, "to": ["township", "tw_north"], "sign": "SR 912 SOUTH  ·  WASHINGTON TWP", "yaw": PI},
	},
	"port": {
		"pt_west": {"pos": [-880.0, 0.0], "r": 24.0, "to": ["highway", "hw_port"], "sign": "TO I-80  ·  NEW YORK  ·  CHICAGO", "yaw": PI * 0.5},
	},
}

## Where you appear after driving through a gate (a little inside it, facing in).
const ARRIVE := {
	"nyc_west": {"pos": [-390.0, -1590.0], "yaw": PI},
	"hw_east": {"pos": [0.0, 800.0], "yaw": 0.0},
	"hw_west": {"pos": [0.0, -800.0], "yaw": PI},
	"chi_south": {"pos": [20.0, 745.0], "yaw": 0.0},
	"hw_tw": {"pos": [-468.0, 0.0], "yaw": -PI * 0.5},
	"hw_port": {"pos": [468.0, 0.0], "yaw": PI * 0.5},
	"tw_east": {"pos": [628.0, 0.0], "yaw": PI * 0.5},
	"pt_west": {"pos": [-828.0, 0.0], "yaw": -PI * 0.5},
	"chi_west": {"pos": [-710.0, -35.0], "yaw": -PI * 0.5},
	"tw_north": {"pos": [0.0, -528.0], "yaw": PI},
	"gy_east": {"pos": [738.0, 0.0], "yaw": PI * 0.5},
	"gy_south": {"pos": [0.0, 628.0], "yaw": 0.0},
}

## Airspace per region (Rect2 x, z, w, d, local coordinates). In world
## coordinates (+ WORLD) they touch: fly across the line and you're over the
## next map. Leave one where nothing borders it and the plane turns you back.
const SKY := {
	"nyc": Rect2(-1700.0, -2500.0, 4300.0, 3900.0),
	"highway": Rect2(-2400.0, -900.0, 4800.0, 1800.0),
	"chicago": Rect2(-2300.0, -1500.0, 4600.0, 3000.0),
	"township": Rect2(-1700.0, -900.0, 3400.0, 1800.0),
	"port": Rect2(-1700.0, -900.0, 3400.0, 1800.0),
	"gary": Rect2(-1700.0, -1465.0, 3480.0, 3000.0),
}

## Where each map's origin sits in the shared world (x, z). The township and
## the port sit either side of I-80, level with Lennox.
const WORLD := {
	"nyc": Vector2(0.0, 0.0),
	"highway": Vector2(-390.0, -3400.0),
	"chicago": Vector2(-410.0, -5800.0),
	"township": Vector2(-4490.0, -3400.0),
	"port": Vector2(3710.0, -3400.0),
	"gary": Vector2(-4490.0, -5835.0),
}

## Silhouettes you see of a city from the other maps: its centre (local),
## how far its towers spread, how many, and how tall the tallest.
const SKYLINE := {
	"nyc": {"c": Vector2(250.0, -350.0), "spread": 1100.0, "n": 70, "h": 220.0},
	"chicago": {"c": Vector2(-60.0, -80.0), "spread": 650.0, "n": 50, "h": 200.0},
	"township": {"c": Vector2(-330.0, -300.0), "spread": 160.0, "n": 8, "h": 48.0, "stacks": true},
	"port": {"c": Vector2(450.0, -100.0), "spread": 260.0, "n": 12, "h": 40.0, "cranes": true},
	"gary": {"c": Vector2(-200.0, -250.0), "spread": 320.0, "n": 12, "h": 46.0, "furnaces": true},
}

## Landing approach per region when you fly in: [x, altitude, z, heading].
const FLY_IN := {
	"nyc": [1570.0, 160.0, -500.0, 0.0],
	"chicago": [640.0, 150.0, 700.0, 0.0],
	"highway": [0.0, 160.0, 600.0, 0.0],
	"township": [-545.0, 140.0, 800.0, 0.0],
	"port": [-720.0, 140.0, 500.0, 0.0],
	"gary": [560.0, 140.0, 450.0, 0.0],
}

## Grid and geography for each non-NYC region (overrides WorldLayout).
const DEFS := {
	"highway": {
		"SEED": 8080, "BJ0": 0, "AX0": -300.0, "AXS": 300.0, "NA": 3, "SZ0": -900.0, "SZS": 300.0, "NS": 7,
		"NBI": 2, "NBJ": 6, "WORLD_X": 560.0, "WORLD_XE": 560.0, "WORLD_ZN": -940.0, "BEACH_Z1": 940.0,
		"START_POS": Vector3(0, 0, 800), "START_YAW": 0.0,
		"DISTRICT_NAMES": {"farm": "Interstate 80", "reststop": "Big Rig Rest Stop", "town": "Lennox, Pennsylvania"},
	},
	"chicago": {
		"SEED": 6060, "BJ0": 0, "AX0": -700.0, "AXS": 120.0, "NA": 13, "SZ0": -700.0, "SZS": 95.0, "NS": 16,
		"NBI": 12, "NBJ": 15, "WORLD_X": 800.0, "WORLD_XE": 860.0, "WORLD_ZN": -760.0, "BEACH_Z1": 820.0,
		"START_POS": Vector3(20, 0, 745), "START_YAW": 0.0,
		"AIRFIELD": {"bi0": 10, "bi1": 11, "bj0": 2, "bj1": 8}, "RUNWAY_X": 640.0, "RUNWAY_HW": 18.0, "RUNWAY_Z0": -470.0, "RUNWAY_Z1": 110.0,
		"DISTRICT_NAMES": {"loop": "The Loop", "river": "River North", "west": "West Loop", "south": "South Side", "lake": "Lakeshore", "airfield": "Meigs Field"},
	},
	# Where Elliot's father worked and Angela's mother lived: a crop-duster
	# strip on the west edge, the E Corp plant in the north-west corner, Main
	# Street in the middle, houses to the east and the memorial to the south.
	"township": {
		"SEED": 1979, "BJ0": 0, "AX0": -600.0, "AXS": 150.0, "NA": 9, "SZ0": -500.0, "SZS": 125.0, "NS": 9,
		"NBI": 8, "NBJ": 8, "WORLD_X": 640.0, "WORLD_XE": 720.0, "WORLD_ZN": -620.0, "BEACH_Z1": 540.0,
		"START_POS": Vector3(628, 0, 0), "START_YAW": PI * 0.5,
		"AIRFIELD": {"bi0": 0, "bi1": 0, "bj0": 0, "bj1": 7}, "RUNWAY_X": -548.0, "RUNWAY_HW": 14.0, "RUNWAY_Z0": -470.0, "RUNWAY_Z1": 470.0,
		"DISTRICT_NAMES": {"tw_plant": "Washington Township Plant", "tw_main": "Main Street", "tw_homes": "Maple Ridge", "tw_field": "Township Farms", "tw_memorial": "Township Memorial", "airfield": "Kearney Strip"},
	},
	# A fishing town that E Corp turned into a freight port: a runway on the
	# west edge, the old town and the canneries in the middle, container docks
	# and a lighthouse on the Atlantic.
	"port": {
		"SEED": 4242, "BJ0": 0, "AX0": -800.0, "AXS": 160.0, "NA": 10, "SZ0": -600.0, "SZS": 150.0, "NS": 9,
		"NBI": 9, "NBJ": 8, "WORLD_X": 920.0, "WORLD_XE": 820.0, "WORLD_ZN": -640.0, "BEACH_Z1": 640.0,
		"START_POS": Vector3(-828, 0, 0), "START_YAW": -PI * 0.5,
		"AIRFIELD": {"bi0": 0, "bi1": 0, "bj0": 0, "bj1": 3}, "RUNWAY_X": -730.0, "RUNWAY_HW": 15.0, "RUNWAY_Z0": -575.0, "RUNWAY_Z1": -25.0,
		"DISTRICT_NAMES": {"pt_town": "Old Port", "pt_homes": "Cape Row", "pt_ind": "Cannery Row", "pt_docks": "Ramsey Container Terminal", "airfield": "Ramsey Field"},
	},
	# Steel town on Lake Michigan: the dead mill and its blast furnaces on
	# the shore, FreightOS's truck depot on the old rail yard, Broadway and its
	# brick bungalows, and the airport on the east side.
	"gary": {
		"SEED": 1906, "BJ0": 0, "AX0": -700.0, "AXS": 140.0, "NA": 11, "SZ0": -600.0, "SZS": 120.0, "NS": 11,
		"NBI": 10, "NBJ": 10, "WORLD_X": 740.0, "WORLD_XE": 830.0, "WORLD_ZN": -640.0, "BEACH_Z1": 720.0,
		"START_POS": Vector3(738, 0, 0), "START_YAW": PI * 0.5,
		"AIRFIELD": {"bi0": 8, "bi1": 9, "bj0": 0, "bj1": 4}, "RUNWAY_X": 560.0, "RUNWAY_HW": 16.0, "RUNWAY_Z0": -570.0, "RUNWAY_Z1": -30.0,
		"DISTRICT_NAMES": {"gy_mill": "Gary Works", "gy_depot": "FreightOS Depot", "gy_town": "Broadway", "gy_homes": "Emerson", "airfield": "Gary/Chicago Airport"},
	},
}

## Off: the NYC-only set pieces (Central Park, Coney, Steel Mountain, Fort Tryon).
const OFF := {"bi0": 99, "bi1": -1, "bj0": 99, "bj1": -1}


static func district(region: String, bi: int, bj: int) -> String:
	match region:
		"highway":
			if bj == 3:
				return "reststop"
			if bj == 5:
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
		"township":
			if bj <= 2 and bi <= 3:
				return "tw_plant"
			if bj >= 6:
				return "tw_memorial" if bi == 3 and bj == 6 else "tw_field"
			if bi >= 6:
				return "tw_homes"
			if bi >= 3 and bi <= 5 and bj >= 3 and bj <= 4:
				return "tw_main"
			return "tw_homes" if bj >= 3 else "tw_field"
		"gary":
			if bj <= 4 and bi <= 3:
				return "gy_mill"
			if bj <= 3 and bi <= 7:
				return "gy_depot"
			if bi >= 7 or bj >= 8:
				return "gy_homes"
			return "gy_town"
		"port":
			if bi >= 7:
				return "pt_docks"
			if bi <= 1 and bj >= 4:
				return "pt_homes"
			if bj >= 5 and bi >= 2 and bi <= 4:
				return "pt_ind"
			return "pt_town"
	return "les"


static func gates(region: String) -> Dictionary:
	return GATES.get(region, {})


static func sky(region: String) -> Rect2:
	return SKY.get(region, SKY["nyc"])


## Each map's built-up area (local Rect2): the countryside stops here.
const CITY := {
	"nyc": Rect2(-906.0, -1706.0, 2722.0, 2536.0),
	"highway": Rect2(-310.0, -910.0, 620.0, 1820.0),
	"chicago": Rect2(-800.0, -800.0, 1700.0, 1660.0),
	"township": Rect2(-610.0, -510.0, 1220.0, 1020.0),
	"port": Rect2(-810.0, -610.0, 1510.0, 1220.0),
	"gary": Rect2(-710.0, -610.0, 1420.0, 1220.0),
}

## Open water inside an airspace (local): Lake Michigan off Chicago and the
## Atlantic off Port Ramsey. No farmland is laid over it, from any map.
const SEA := {
	"chicago": Rect2(860.0, -1500.0, 1440.0, 3000.0),
	"port": Rect2(700.0, -900.0, 1000.0, 1800.0),
	"gary": Rect2(-1700.0, -1465.0, 3480.0, 825.0),
}


## Is this point (local to `region`) dry land outside the city? New York has
## rivers east and west and the Atlantic south, so its country is north of it;
## Chicago has Lake Michigan to the east.
static func is_country(region: String, p: Vector2) -> bool:
	if (CITY.get(region, Rect2()) as Rect2).has_point(p):
		return false
	match region:
		"nyc":
			return p.y < -1706.0 and p.x > -1100.0 and p.x < 2000.0
		"chicago":
			return p.x < 920.0
		"port":
			return p.x < 700.0
		"gary":
			return p.y > -640.0
	return true


## Local map position -> shared world position, and back.
static func to_world(region: String, p: Vector2) -> Vector2:
	return p + (WORLD.get(region, Vector2.ZERO) as Vector2)


static func to_local(region: String, w: Vector2) -> Vector2:
	return w - (WORLD.get(region, Vector2.ZERO) as Vector2)


## The map whose airspace holds world point `w` (not `except`), or "".
static func region_at(w: Vector2, except: String = "") -> String:
	for r in SKY.keys():
		if str(r) == except:
			continue
		if (SKY[r] as Rect2).has_point(to_local(str(r), w)):
			return str(r)
	return ""


static func region_name(region: String) -> String:
	return str(NAMES.get(region, region))
