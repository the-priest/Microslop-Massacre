class_name RegionContent
extends RefCounted
## Landmark buildings, doors and points of interest for the regions outside
## New York (same formats as WorldLayout.LANDMARKS / DOORS / POIS).

const LANDMARKS := {
	"highway": {
		"hw_diner": {"rect": [24, 20, 60, 50], "h": 6.0, "style": 2, "color": Color(0.7, 0.2, 0.18), "sign": "BIG RIG DINER", "sign_col": Color(1.0, 0.3, 0.3), "door": "d_hw_diner", "awning": Color(0.8, 0.8, 0.82)},
		"hw_gas": {"rect": [24, 70, 50, 92], "h": 5.0, "style": 2, "color": Color(0.85, 0.85, 0.8), "sign": "GAS · FOOD · LIVE BAIT", "sign_col": Color(1.0, 0.85, 0.2), "door": "d_hw_gas"},
		"hw_pharmacy": {"rect": [24, 640, 50, 668], "h": 5.5, "style": 2, "color": Color(0.82, 0.8, 0.74), "sign": "LENNOX PHARMACY", "sign_col": Color(0.3, 1.0, 0.5), "door": "d_hw_pharmacy"},
		"hw_motel": {"rect": [24, 600, 70, 630], "h": 7.0, "style": 1, "color": Color(0.55, 0.45, 0.35), "sign": "LENNOX MOTOR INN", "sign_col": Color(1.0, 0.5, 0.7), "door": "d_hw_motel"},
	},
	"chicago": {
		"chi_node": {"rect": [-130, -150, -20, -60], "h": 120.0, "style": 7, "color": Color(0.18, 0.2, 0.26), "sign": "E CORP MIDWEST", "sign_col": Color(0.35, 0.55, 1.0), "door": "d_chi_node"},
		"chi_diner": {"rect": [-450, 520, -410, 548], "h": 9.0, "style": 1, "color": Color(0.42, 0.24, 0.18), "sign": "LOU'S RED HOTS", "sign_col": Color(1.0, 0.35, 0.25), "door": "d_chi_diner", "awning": Color(0.7, 0.12, 0.1)},
		"chi_safe": {"rect": [-560, -620, -520, -590], "h": 14.0, "style": 5, "color": Color(0.3, 0.27, 0.24), "door": "d_chi_safe", "boarded": true},
		"chi_motel": {"rect": [60, 620, 108, 650], "h": 8.0, "style": 1, "color": Color(0.5, 0.42, 0.32), "sign": "SKYWAY MOTEL", "sign_col": Color(0.4, 0.9, 1.0), "door": "d_chi_motel"},
		"chi_fbi": {"rect": [130, -340, 220, -260], "h": 60.0, "style": 8, "color": Color(0.45, 0.43, 0.4), "sign": "FEDERAL PLAZA", "sign_col": Color(0.7, 0.8, 1.0), "door": "d_chi_fbi"},
		"chi_hangar": {"rect": [560, 140, 610, 176], "h": 10.0, "style": 5, "color": Color(0.5, 0.52, 0.55), "sign": "MEIGS FIELD", "sign_col": Color(0.9, 0.9, 0.95), "door": "d_chi_hangar"},
	},
}

const DOORS := {
	"highway": {
		"d_hw_diner": {"pos": [24, 35], "face": "w", "interior": "hw_diner", "name": "Big Rig Diner"},
		"d_hw_gas": {"pos": [24, 81], "face": "w", "interior": "hw_gas", "name": "Gas Station"},
		"d_hw_pharmacy": {"pos": [24, 654], "face": "w", "interior": "hw_pharmacy", "name": "Lennox Pharmacy"},
		"d_hw_motel": {"pos": [24, 615], "face": "w", "interior": "hw_motel", "name": "Lennox Motor Inn"},
	},
	"chicago": {
		"d_chi_node": {"pos": [-75, -60], "face": "s", "interior": "chi_node", "name": "E Corp Midwest"},
		"d_chi_diner": {"pos": [-430, 548], "face": "s", "interior": "chi_diner", "name": "Lou's Red Hots"},
		"d_chi_safe": {"pos": [-540, -590], "face": "s", "interior": "chi_safe", "name": "Warehouse (fsociety safehouse)", "lock": 30, "unlock_when": "q.mq_chi1>=20"},
		"d_chi_motel": {"pos": [84, 620], "face": "n", "interior": "chi_motel", "name": "Skyway Motel"},
		"d_chi_fbi": {"pos": [175, -260], "face": "s", "interior": "chi_fbi", "name": "Federal Plaza"},
		"d_chi_hangar": {"pos": [585, 176], "face": "s", "interior": "chi_hangar", "name": "Meigs Field Hangar"},
	},
}

const POIS := {
	"highway": {
		"poi_hw_rest": {"pos": [40, 55], "name": "Big Rig Rest Stop", "r": 60.0},
		"poi_hw_rig": {"pos": [-17, -300], "name": "Stalled Rig (I-80 shoulder)", "r": 30.0},
		"poi_hw_town": {"pos": [60, 680], "name": "Lennox, Pennsylvania", "r": 80.0},
	},
	"chicago": {
		"poi_chi_loop": {"pos": [-75, -100], "name": "The Loop", "r": 80.0},
		"poi_chi_meigs": {"pos": [640, -180], "name": "Meigs Field", "r": 120.0},
		"poi_chi_lake": {"pos": [760, 300], "name": "Lake Michigan", "r": 80.0},
		"poi_chi_south": {"pos": [-200, 600], "name": "South Side", "r": 80.0},
	},
}


static func landmarks(region: String) -> Dictionary:
	return LANDMARKS.get(region, {})


static func doors(region: String) -> Dictionary:
	return DOORS.get(region, {})


static func pois(region: String) -> Dictionary:
	return POIS.get(region, {})


## Which region an interior cell belongs to (nyc unless a region's door leads
## to it). Used to route quest markers across cities.
static func region_of_interior(cell: String) -> String:
	for reg in DOORS.keys():
		for did in DOORS[reg].keys():
			if str(DOORS[reg][did]["interior"]) == cell:
				return str(reg)
	return "nyc"


## The gate id in `from` that leads toward region `to` (empty if none direct).
## One hop only; the quest text tells the player the chain.
static func gate_toward(from: String, to: String) -> String:
	for gid in Regions.GATES.get(from, {}).keys():
		if str(Regions.GATES[from][gid]["to"][0]) == to:
			return str(gid)
	# Two hops via the highway (NYC <-> Chicago).
	for gid in Regions.GATES.get(from, {}).keys():
		var mid := str(Regions.GATES[from][gid]["to"][0])
		for gid2 in Regions.GATES.get(mid, {}).keys():
			if str(Regions.GATES[mid][gid2]["to"][0]) == to:
				return str(gid)
	return ""
