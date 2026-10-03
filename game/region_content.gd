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
		"chi_clinic": {"rect": [160, 165, 240, 225], "h": 34.0, "style": 3, "color": Color(0.64, 0.62, 0.58), "sign": "LAKESIDE GENERAL · EMERGENCY", "sign_col": Color(1.0, 0.3, 0.3), "door": "d_chi_clinic"},
	},
	"township": {
		"tw_diner": {"rect": [20, -40, 52, -8], "h": 7.0, "style": 2, "color": Color(0.76, 0.72, 0.62), "sign": "TOWNSHIP DINER", "sign_col": Color(1.0, 0.4, 0.3), "door": "d_tw_diner", "awning": Color(0.65, 0.1, 0.08)},
		"tw_law": {"rect": [62, -34, 88, -8], "h": 8.0, "style": 1, "color": Color(0.4, 0.26, 0.2), "sign": "M. HALE · ATTORNEY AT LAW", "sign_col": Color(1.0, 0.85, 0.5), "door": "d_tw_law"},
		"tw_bar": {"rect": [232, -44, 272, -8], "h": 7.0, "style": 1, "color": Color(0.32, 0.22, 0.18), "sign": "THE SPILLWAY", "sign_col": Color(0.4, 0.8, 1.0), "door": "d_tw_bar", "flicker": true},
		"tw_sheriff": {"rect": [-130, 8, -86, 40], "h": 8.0, "style": 8, "color": Color(0.55, 0.52, 0.46), "sign": "TOWNSHIP SHERIFF", "sign_col": Color(0.9, 0.9, 1.0), "door": "d_tw_sheriff"},
		"tw_chapel": {"rect": [180, 10, 208, 48], "h": 10.0, "style": 8, "color": Color(0.58, 0.56, 0.52), "sign": "ST. BRIGID'S", "sign_col": Color(1.0, 0.9, 0.6), "door": "d_tw_chapel", "steeple": true},
		"tw_plant": {"rect": [-120, -232, -40, -190], "h": 12.0, "style": 8, "color": Color(0.5, 0.52, 0.55), "sign": "E CORP · WASHINGTON TOWNSHIP ENERGY", "sign_col": Color(0.35, 0.55, 1.0), "door": "d_tw_plant"},
		"tw_hangar": {"rect": [-492, 120, -462, 160], "h": 9.0, "style": 5, "color": Color(0.55, 0.57, 0.6), "sign": "KEARNEY STRIP · EST. 1961", "sign_col": Color(1.0, 0.8, 0.3), "door": "d_tw_hangar"},
		"tw_moss": {"rect": [326, -40, 340, -16], "h": 6.0, "style": 2, "color": Color(0.7, 0.67, 0.6), "door": "d_tw_moss", "boarded": true, "gable": true},
		"tw_clinic": {"rect": [40, 8, 90, 40], "h": 9.0, "style": 2, "color": Color(0.84, 0.84, 0.8), "sign": "TOWNSHIP MEDICAL CLINIC", "sign_col": Color(1.0, 0.3, 0.3), "awning": Color(0.7, 0.15, 0.12), "door": "d_tw_clinic"},
	},
	"port": {
		"pt_bar": {"rect": [40, -40, 80, -8], "h": 8.0, "style": 1, "color": Color(0.33, 0.29, 0.27), "sign": "THE BARNACLE", "sign_col": Color(0.3, 0.8, 1.0), "door": "d_pt_bar", "awning": Color(0.1, 0.2, 0.35)},
		"pt_inn": {"rect": [-140, 10, -96, 40], "h": 9.0, "style": 2, "color": Color(0.82, 0.8, 0.74), "sign": "HARBOR LIGHT INN", "sign_col": Color(1.0, 0.75, 0.4), "door": "d_pt_inn"},
		"pt_terminal": {"rect": [340, -204, 400, -160], "h": 14.0, "style": 8, "color": Color(0.45, 0.47, 0.5), "sign": "E CORP LOGISTICS · TERMINAL OFFICE", "sign_col": Color(0.35, 0.55, 1.0), "door": "d_pt_terminal"},
		"pt_harbor": {"rect": [592, 96, 626, 132], "h": 8.0, "style": 2, "color": Color(0.82, 0.82, 0.8), "sign": "HARBORMASTER", "sign_col": Color(0.9, 0.95, 1.0), "door": "d_pt_harbor"},
		"pt_lighthouse": {"rect": [744, -574, 760, -558], "h": 28.0, "style": 2, "color": Color(0.92, 0.92, 0.9), "door": "d_pt_lighthouse", "lighthouse": true},
		"pt_cannery": {"rect": [-300, 320, -200, 400], "h": 12.0, "style": 5, "color": Color(0.45, 0.4, 0.35), "sign": "OCEAN BRIGHT CANNERY", "sign_col": Color(0.9, 0.5, 0.3), "door": "d_pt_cannery", "flicker": true},
		"pt_hangar": {"rect": [-680, -150, -652, -110], "h": 8.0, "style": 5, "color": Color(0.55, 0.57, 0.6), "sign": "RAMSEY FIELD", "sign_col": Color(0.9, 0.9, 0.95), "door": "d_pt_hangar"},
		"pt_clinic": {"rect": [40, 8, 90, 40], "h": 9.0, "style": 2, "color": Color(0.86, 0.86, 0.84), "sign": "PORT RAMSEY URGENT CARE", "sign_col": Color(1.0, 0.3, 0.3), "awning": Color(0.2, 0.35, 0.6), "door": "d_pt_clinic"},
	},
	"gary": {
		"gy_union": {"rect": [-120, 10, -80, 44], "h": 10.0, "style": 1, "color": Color(0.42, 0.24, 0.18), "sign": "USW LOCAL 1014", "sign_col": Color(1.0, 0.4, 0.3), "door": "d_gy_union"},
		"gy_diner": {"rect": [30, 10, 62, 40], "h": 7.0, "style": 2, "color": Color(0.6, 0.36, 0.26), "sign": "STEEL CITY GRILL", "sign_col": Color(1.0, 0.6, 0.2), "door": "d_gy_diner", "awning": Color(0.6, 0.12, 0.08)},
		"gy_tower": {"rect": [40, -330, 80, -290], "h": 22.0, "style": 7, "color": Color(0.2, 0.3, 0.42), "sign": "FREIGHTOS · FLEET OPERATIONS", "sign_col": Color(0.3, 0.75, 1.0), "door": "d_gy_tower", "roof": "antenna"},
		"gy_millofc": {"rect": [-390, -60, -330, -20], "h": 12.0, "style": 1, "color": Color(0.36, 0.22, 0.16), "sign": "GARY WORKS · MAIN OFFICE", "sign_col": Color(0.9, 0.75, 0.4), "door": "d_gy_millofc", "boarded": true, "flicker": true},
		"gy_cluster": {"rect": [-540, -220, -450, -150], "h": 14.0, "style": 7, "color": Color(0.14, 0.28, 0.2), "sign": "SLOPFORGE", "sign_col": Color(0.35, 1.0, 0.45), "door": "d_gy_cluster"},
		"gy_hangar": {"rect": [650, -120, 686, -84], "h": 8.0, "style": 5, "color": Color(0.55, 0.57, 0.6), "sign": "GARY/CHICAGO AIRPORT", "sign_col": Color(1.0, 0.7, 0.2), "door": "d_gy_hangar"},
		"gy_clinic": {"rect": [170, 8, 230, 44], "h": 16.0, "style": 3, "color": Color(0.6, 0.56, 0.5), "sign": "ST. MARGARET'S HOSPITAL", "sign_col": Color(1.0, 0.3, 0.3), "door": "d_gy_clinic"},
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
		"d_chi_clinic": {"pos": [200, 165], "face": "n", "interior": "clinic_er", "name": "Lakeside General — Emergency"},
		"d_chi_hangar": {"pos": [585, 176], "face": "s", "interior": "chi_hangar", "name": "Meigs Field Hangar"},
	},
	"township": {
		"d_tw_diner": {"pos": [36, -8], "face": "s", "interior": "tw_diner", "name": "Township Diner"},
		"d_tw_law": {"pos": [75, -8], "face": "s", "interior": "tw_law", "name": "Law Office of Margaret Hale"},
		"d_tw_bar": {"pos": [252, -8], "face": "s", "interior": "tw_bar", "name": "The Spillway"},
		"d_tw_sheriff": {"pos": [-108, 8], "face": "n", "interior": "tw_sheriff", "name": "Township Sheriff"},
		"d_tw_clinic": {"pos": [65, 8], "face": "n", "interior": "clinic_er", "name": "Township Medical Clinic"},
		"d_tw_chapel": {"pos": [194, 10], "face": "n", "interior": "tw_chapel", "name": "St. Brigid's Church"},
		"d_tw_plant": {"pos": [-80, -190], "face": "s", "interior": "tw_plant", "name": "E Corp Washington Township Energy"},
		"d_tw_hangar": {"pos": [-462, 140], "face": "e", "interior": "tw_hangar", "name": "Kearney Strip Hangar"},
		"d_tw_moss": {"pos": [333, -16], "face": "s", "interior": "tw_moss", "name": "The Moss House", "lock": 25},
	},
	"port": {
		"d_pt_bar": {"pos": [60, -8], "face": "s", "interior": "pt_bar", "name": "The Barnacle"},
		"d_pt_inn": {"pos": [-118, 10], "face": "n", "interior": "pt_inn", "name": "Harbor Light Inn"},
		"d_pt_terminal": {"pos": [370, -160], "face": "s", "interior": "pt_terminal", "name": "E Corp Logistics Terminal Office"},
		"d_pt_harbor": {"pos": [626, 114], "face": "e", "interior": "pt_harbor", "name": "Harbormaster's Office"},
		"d_pt_lighthouse": {"pos": [744, -566], "face": "w", "interior": "pt_lighthouse", "name": "Ramsey Point Light"},
		"d_pt_cannery": {"pos": [-250, 400], "face": "s", "interior": "pt_cannery", "name": "Ocean Bright Cannery", "lock": 45, "unlock_when": "q.mq_pr1>=30"},
		"d_pt_hangar": {"pos": [-652, -130], "face": "e", "interior": "pt_hangar", "name": "Ramsey Field Office"},
		"d_pt_clinic": {"pos": [65, 8], "face": "n", "interior": "clinic_er", "name": "Port Ramsey Urgent Care"},
	},
	"gary": {
		"d_gy_union": {"pos": [-100, 10], "face": "n", "interior": "gy_union", "name": "USW Local 1014 Union Hall"},
		"d_gy_diner": {"pos": [46, 10], "face": "n", "interior": "gy_diner", "name": "Steel City Grill"},
		"d_gy_tower": {"pos": [60, -290], "face": "s", "interior": "gy_ops", "name": "FreightOS Control Tower"},
		"d_gy_millofc": {"pos": [-360, -20], "face": "s", "interior": "gy_millofc", "name": "Gary Works Main Office", "lock": 30},
		"d_gy_cluster": {"pos": [-495, -150], "face": "s", "interior": "gy_cluster", "name": "SlopForge Training Cluster", "lock": 50, "unlock_when": "q.sq_gy3>=10"},
		"d_gy_hangar": {"pos": [686, -102], "face": "e", "interior": "gy_hangar", "name": "Gary/Chicago Airport Office"},
		"d_gy_clinic": {"pos": [200, 8], "face": "n", "interior": "clinic_er", "name": "St. Margaret's Hospital"},
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
	"township": {
		"poi_tw_main": {"pos": [100, 0], "name": "Main Street", "r": 120.0},
		"poi_tw_plant": {"pos": [-250, -330], "name": "The Plant", "r": 120.0},
		"poi_tw_pond": {"pos": [-375, -187], "name": "Retention Pond 3", "r": 45.0},
		"poi_tw_memorial": {"pos": [-75, 286], "name": "Township Memorial", "r": 30.0},
		"poi_tw_strip": {"pos": [-525, 0], "name": "Kearney Strip", "r": 120.0},
		"poi_tw_tower": {"pos": [180, -300], "name": "Water Tower", "r": 30.0},
		"poi_tw_dock": {"pos": [-225, -250], "name": "Plant Loading Dock (Mill St)", "r": 30.0},
	},
	"port": {
		"poi_pt_docks": {"pos": [480, -150], "name": "Ramsey Container Terminal", "r": 150.0},
		"poi_pt_ship": {"pos": [690, -175], "name": "MV Everbright (berth 2)", "r": 50.0},
		"poi_pt_light": {"pos": [730, -566], "name": "Ramsey Point Light", "r": 30.0},
		"poi_pt_old": {"pos": [0, -80], "name": "Old Port", "r": 120.0},
		"poi_pt_field": {"pos": [-720, -300], "name": "Ramsey Field", "r": 120.0},
		"poi_pt_cannery": {"pos": [-250, 420], "name": "Ocean Bright Cannery", "r": 50.0},
	},
	"gary": {
		"poi_gy_mill": {"pos": [-420, -300], "name": "Gary Works", "r": 160.0},
		"poi_gy_depot": {"pos": [140, -360], "name": "FreightOS Depot", "r": 150.0},
		"poi_gy_broadway": {"pos": [-140, 200], "name": "Broadway", "r": 120.0},
		"poi_gy_airport": {"pos": [560, -300], "name": "Gary/Chicago Airport", "r": 140.0},
		"poi_gy_lake": {"pos": [-200, -660], "name": "Lake Michigan shore", "r": 80.0},
	},
}


## Body shops: a painted bay on the street. Roll in with the heat on you and
## stop, and they'll respray the car so the cops lose you; roll in banged up
## and they'll fix it. Rafi's in Hunts Point also buys stolen cars.
const BODY_SHOPS := {
	"nyc": [{"pos": [1105, -1200], "name": "RAFI'S AUTO BODY", "rafi": true}, {"pos": [-455, 480], "name": "LES COLLISION"}],
	"chicago": [{"pos": [-400, -415], "name": "WEST LOOP COLLISION"}],
	"highway": [{"pos": [150, 300], "name": "ROADSIDE BODY & TOW"}],
	"township": [{"pos": [375, 0], "name": "COYLE'S BODY SHOP"}],
	"port": [{"pos": [400, 150], "name": "HARBOR AUTO & MARINE"}],
	"gary": [{"pos": [70, 480], "name": "STEEL CITY COLLISION"}],
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
	# Two hops via the highway (NYC <-> Chicago, or any town off I-80).
	for gid in Regions.GATES.get(from, {}).keys():
		var mid := str(Regions.GATES[from][gid]["to"][0])
		for gid2 in Regions.GATES.get(mid, {}).keys():
			if str(Regions.GATES[mid][gid2]["to"][0]) == to:
				return str(gid)
	return ""
