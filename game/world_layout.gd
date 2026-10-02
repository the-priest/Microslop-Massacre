class_name WorldLayout
extends RefCounted
## WorldLayout — the fixed geography of the city: street grid, districts,
## landmark buildings, doors, subway stations and points of interest.
## Everything else is filled procedurally by CityGen around these.
##
## Axes: +X east, +Z south. Avenues run N-S, streets run E-W.

const SEED := 51909
## The city grew: 10 rows north (Inwood, Harlem, the Bronx) and 7 avenues east
## (Astoria, Long Island City, Hunts Point). Legacy block rows are offset by
## BJ0 so every original landmark keeps its world position.
const BJ0 := 10
const AX0 := -780.0
const AXS := 130.0
const NA := 20 # avenues 0..19 (x=-780..1690)
const SZ0 := -1600.0
const SZS := 80.0
const NS := 28 # streets 0..27 (z=-1600..560)
const AVE_HW := 10.0 # corridor half width (asphalt 6.5 + sidewalk 3.5)
const AVE_ROAD := 6.5
const ST_HW := 8.0
const ST_ROAD := 4.5
const NBI := 19 # blocks along x
const NBJ := 27 # blocks along z

# Coney Island (south of the grid).
const CONEY_ROW_Z0 := 568.0
const CONEY_ROW_Z1 := 616.0
const SURF_Z := 624.0 # Surf Avenue center
const AMUSE_Z0 := 632.0
const AMUSE_Z1 := 688.0
const BOARD_Z0 := 688.0
const BOARD_Z1 := 712.0
const BEACH_Z1 := 790.0
const PIER_X0 := -40.0
const PIER_X1 := -20.0
const PIER_Z1 := 880.0

const WORLD_X := 866.0 # west edge (-X); the east edge is WORLD_XE
const WORLD_XE := 1776.0
const WORLD_ZN := -1666.0

# Parks and compounds remove internal roads.
const PARK := {"bi0": 4, "bi1": 6, "bj0": 19, "bj1": 22}
const STEEL := {"bi0": 9, "bi1": 10, "bj0": 11, "bj1": 12}
## Fort Tryon: a wooded park on the hills of upper Manhattan.
const TRYON := {"bi0": 0, "bi1": 1, "bj0": 1, "bj1": 3}
## Bowery Bay Airfield: a general-aviation field on the Queens waterfront.
const AIRFIELD := {"bi0": 16, "bi1": 18, "bj0": 0, "bj1": 7}
const RUNWAY_X := 1570.0 # runway centreline (it runs north-south)
const RUNWAY_HW := 20.0
const RUNWAY_Z0 := -1585.0
const RUNWAY_Z1 := -975.0

const DISTRICT_NAMES := {
	"heights": "Washington Heights", "industrial": "Industrial North", "docks": "West Side Docks",
	"midtown": "Midtown", "east_mid": "Turtle Bay", "hells": "Hell's Kitchen",
	"park": "Central Park", "uptown": "Upper East Side", "les": "Lower East Side",
	"civic": "Civic Center", "chinatown": "Chinatown", "coney": "Coney Island",
	"steel": "Steel Mountain",
	"harlem": "Harlem", "bronx": "The Bronx", "inwood": "Inwood", "tryon": "Fort Tryon Park",
	"astoria": "Astoria", "lic": "Long Island City", "hunts": "Hunts Point",
	"airfield": "Bowery Bay Airfield",
}


static func ax(i: int) -> float:
	return AX0 + AXS * float(i)


static func sz(j: int) -> float:
	return SZ0 + SZS * float(j)


static func block_rect(bi: int, bj: int) -> Rect2:
	# Buildable area (inside sidewalks). Rect2(x, z, w, d)
	var x0 := ax(bi) + AVE_HW
	var x1 := ax(bi + 1) - AVE_HW
	var z0 := sz(bj) + ST_HW
	var z1 := sz(bj + 1) - ST_HW
	return Rect2(x0, z0, x1 - x0, z1 - z0)


static func block_center(bi: int, bj: int) -> Vector2:
	return Vector2((ax(bi) + ax(bi + 1)) * 0.5, (sz(bj) + sz(bj + 1)) * 0.5)


static func in_park(bi: int, bj: int) -> bool:
	return bi >= PARK["bi0"] and bi <= PARK["bi1"] and bj >= PARK["bj0"] and bj <= PARK["bj1"]


static func in_steel(bi: int, bj: int) -> bool:
	return bi >= STEEL["bi0"] and bi <= STEEL["bi1"] and bj >= STEEL["bj0"] and bj <= STEEL["bj1"]


static func in_airfield(bi: int, bj: int) -> bool:
	return bi >= AIRFIELD["bi0"] and bi <= AIRFIELD["bi1"] and bj >= AIRFIELD["bj0"] and bj <= AIRFIELD["bj1"]


## Fenced compounds with no internal roads: Steel Mountain, the airfield.
static func in_compound(bi: int, bj: int) -> bool:
	return in_steel(bi, bj) or in_airfield(bi, bj)


## The airfield's fenced area (world x/z).
static func airfield_rect() -> Rect2:
	var x0 := ax(AIRFIELD["bi0"]) + AVE_HW
	var x1 := ax(AIRFIELD["bi1"] + 1) - AVE_HW
	var z0 := sz(AIRFIELD["bj0"]) + ST_HW
	var z1 := sz(AIRFIELD["bj1"] + 1) - ST_HW
	return Rect2(x0, z0, x1 - x0, z1 - z0)


static func in_tryon(bi: int, bj: int) -> bool:
	return bi >= TRYON["bi0"] and bi <= TRYON["bi1"] and bj >= TRYON["bj0"] and bj <= TRYON["bj1"]


## Parks (both) have no internal roads and no buildings.
static func is_green(bi: int, bj: int) -> bool:
	return in_park(bi, bj) or in_tryon(bi, bj)


static func district(bi: int, bj: int) -> String:
	if in_park(bi, bj):
		return "park"
	if in_steel(bi, bj):
		return "steel"
	if in_tryon(bi, bj):
		return "tryon"
	if in_airfield(bi, bj):
		return "airfield"
	var lj := bj - BJ0 # legacy row (the original city was rows 0..16)
	# The new east: Queens, across the old East River line.
	if bi >= 12:
		if lj < 0:
			return "hunts"
		return "astoria" if lj <= 7 else "lic"
	# The new north.
	if lj < 0:
		if lj <= -6:
			return "bronx"
		return "inwood" if bi <= 2 else "harlem"
	if bi <= 1 and lj >= 4 and lj <= 8:
		return "docks"
	if bi >= 7 and lj <= 4:
		return "industrial"
	if lj <= 3:
		return "heights"
	if lj <= 8:
		return "east_mid" if bi >= 10 else "midtown"
	if lj <= 12:
		return "hells" if bi <= 3 else "uptown"
	if bi <= 4:
		return "les"
	if bi <= 7:
		return "civic"
	return "chinatown"


## Inside the street grid (not the rivers or the edge of the world).
static func in_bounds(x: float, z: float) -> bool:
	return x > AX0 - AVE_HW + 1.0 and x < ax(NA - 1) + AVE_HW - 1.0 and z > SZ0 - ST_HW + 1.0 and z < sz(NS - 1) + ST_HW - 1.0


static func district_at(x: float, z: float) -> String:
	if z > CONEY_ROW_Z0 - 8.0:
		return "coney"
	var bi := clampi(int(floor((x - AX0) / AXS)), 0, NBI - 1)
	var bj := clampi(int(floor((z - SZ0) / SZS)), 0, NBJ - 1)
	return district(bi, bj)


## Is there an avenue segment between street j and j+1 at avenue i?
static func avenue_segment_exists(i: int, j: int) -> bool:
	# Avenue i separates blocks bi=i-1 and bi=i. Removed when both sides are park/steel.
	if i <= 0 or i >= NA - 1:
		return true
	var l := i - 1
	var r := i
	if is_green(l, j) and is_green(r, j):
		return false
	if in_compound(l, j) and in_compound(r, j):
		return false
	return true


static func street_segment_exists(j: int, i: int) -> bool:
	# Street j between avenues i and i+1 separates blocks bj=j-1 and bj=j.
	if j <= 0 or j >= NS - 1:
		return true
	var u := j - 1
	var d := j
	if is_green(i, u) and is_green(i, d):
		return false
	if in_compound(i, u) and in_compound(i, d):
		return false
	return true


static func intersection_exists(i: int, j: int) -> bool:
	# Any road touching this intersection.
	var any := false
	if j > 0 and avenue_segment_exists(i, j - 1):
		any = true
	if j < NS - 1 and avenue_segment_exists(i, j):
		any = true
	if i > 0 and street_segment_exists(j, i - 1):
		any = true
	if i < NA - 1 and street_segment_exists(j, i):
		any = true
	return any


# ------------------------------------------------------------------ landmarks
## rect = [x0, z0, x1, z1]; door = [x, z, facing] facing in n/s/e/w (outward normal)
## style: facade style id (see facade.gdshader). sign: text on the facade.
const LANDMARKS := {
	# Lower East Side ----------------------------------------------------------
	"elliot_apt": {"rect": [-482, 328, -450, 358], "h": 19.0, "style": 1, "color": Color(0.36, 0.2, 0.16), "roof": "tank", "fire_escape": "n", "door": "d_apt"},
	"bodega": {"rect": [-416, 328, -402, 346], "h": 13.0, "style": 1, "color": Color(0.3, 0.26, 0.2), "sign": "BODEGA 24H", "sign_col": Color(1.0, 0.75, 0.3), "door": "d_bodega", "awning": Color(0.1, 0.4, 0.2)},
	"krista_office": {"rect": [-352, 288, -326, 312], "h": 14.0, "style": 2, "color": Color(0.33, 0.24, 0.2), "door": "d_krista", "stoop": true},
	"ron_coffee": {"rect": [-604, 408, -580, 430], "h": 11.0, "style": 1, "color": Color(0.26, 0.18, 0.14), "sign": "RON'S COFFEE", "sign_col": Color(1.0, 0.55, 0.3), "door": "d_ron", "awning": Color(0.4, 0.12, 0.08)},
	"pawn_shop": {"rect": [-752, 248, -732, 270], "h": 12.0, "style": 1, "color": Color(0.24, 0.22, 0.2), "sign": "PAWN", "sign_col": Color(1.0, 0.85, 0.3), "door": "d_pawn"},
	"laundromat": {"rect": [-596, 328, -580, 346], "h": 12.0, "style": 1, "color": Color(0.3, 0.3, 0.32), "sign": "LAUNDROMAT", "sign_col": Color(0.4, 0.8, 1.0), "door": "d_laundro"},
	"pharmacy": {"rect": [-340, 408, -316, 428], "h": 14.0, "style": 1, "color": Color(0.35, 0.33, 0.3), "sign": "Rx PHARMACY", "sign_col": Color(1.0, 0.25, 0.3), "door": "d_pharmacy", "awning": Color(0.5, 0.05, 0.08)},
	"precinct": {"rect": [-250, 248, -214, 276], "h": 16.0, "style": 8, "color": Color(0.4, 0.38, 0.34), "sign": "7TH PRECINCT", "sign_col": Color(0.6, 0.8, 1.0), "door": "d_precinct"},
	"darlene_apt": {"rect": [-226, 408, -204, 432], "h": 17.0, "style": 1, "color": Color(0.28, 0.2, 0.22), "fire_escape": "n", "door": "d_darlene"},
	"vera_stash": {"rect": [-164, 500, -140, 530], "h": 12.0, "style": 1, "color": Color(0.2, 0.17, 0.16), "door": "d_vera", "boarded": true},
	# Midtown -----------------------------------------------------------------
	"allsafe": {"rect": [-362, -214, -298, -168], "h": 64.0, "style": 3, "color": Color(0.5, 0.52, 0.55), "sign": "ALLSAFE CYBERSECURITY", "sign_col": Color(0.35, 0.9, 1.0), "door": "d_allsafe", "roof": "mech"},
	"ecorp_tower": {"rect": [-90, -306, -40, -262], "h": 236.0, "style": 7, "color": Color(0.14, 0.16, 0.2), "sign": "E CORP", "sign_col": Color(0.35, 0.55, 1.0), "door": "d_ecorp", "roof": "spire", "plaza": [-120, -312, -10, -248]},
	"salina_hotel": {"rect": [332, -376, 378, -328], "h": 96.0, "style": 8, "color": Color(0.45, 0.4, 0.34), "sign": "THE SALINA", "sign_col": Color(1.0, 0.8, 0.45), "door": "d_deus", "roof": "deco"},
	# Heights -----------------------------------------------------------------
	"relay_building": {"rect": [-80, -684, -40, -648], "h": 44.0, "style": 8, "color": Color(0.36, 0.3, 0.26), "door": "d_relay", "roof": "antenna"},
	"sporting_goods": {"rect": [-600, -632, -570, -608], "h": 12.0, "style": 1, "color": Color(0.3, 0.24, 0.2), "sign": "RICKY'S SPORTING GOODS", "sign_col": Color(0.9, 0.9, 0.4), "door": "d_guns"},
	# Hell's Kitchen --------------------------------------------------------------
	"angela_apt": {"rect": [-604, 8, -574, 36], "h": 28.0, "style": 2, "color": Color(0.42, 0.36, 0.3), "door": "d_angela", "stoop": true},
	"rabbit_hole": {"rect": [-484, 88, -460, 110], "h": 12.0, "style": 1, "color": Color(0.2, 0.16, 0.18), "sign": "THE RABBIT HOLE", "sign_col": Color(1.0, 0.3, 0.7), "door": "d_bar"},
	"old_theater": {"rect": [-352, 168, -300, 198], "h": 22.0, "style": 8, "color": Color(0.34, 0.26, 0.2), "sign": "PARAMOUNT", "sign_col": Color(1.0, 0.6, 0.2), "door": "d_theater", "marquee": true},
	# Upper East ------------------------------------------------------------------
	"tyrell_tower": {"rect": [432, 8, 478, 40], "h": 118.0, "style": 4, "color": Color(0.3, 0.34, 0.38), "door": "d_tyrell", "roof": "mech"},
	"mercy_general": {"rect": [290, 88, 360, 152], "h": 48.0, "style": 3, "color": Color(0.62, 0.6, 0.56), "sign": "MERCY GENERAL", "sign_col": Color(1.0, 0.3, 0.3), "door": "d_hospital"},
	"lenny_apt": {"rect": [562, 88, 592, 116], "h": 34.0, "style": 2, "color": Color(0.4, 0.34, 0.3), "door": "d_lenny", "stoop": true},
	# Civic --------------------------------------------------------------------
	"fbi_office": {"rect": [30, 328, 100, 372], "h": 92.0, "style": 3, "color": Color(0.46, 0.46, 0.48), "sign": "FEDERAL BUILDING", "sign_col": Color(0.8, 0.85, 1.0), "door": "d_fbi", "roof": "mech"},
	# This is not our world: here the towers still stand.
	"wtc_north": {"rect": [-116, 338, -76, 378], "h": 380.0, "style": 3, "color": Color(0.64, 0.66, 0.7), "twin": "north", "sign": "WORLD TRADE CENTER", "sign_col": Color(0.85, 0.9, 1.0), "door": "d_wtc", "plaza": [-122, 330, -8, 392]},
	"wtc_south": {"rect": [-56, 338, -16, 378], "h": 372.0, "style": 3, "color": Color(0.64, 0.66, 0.7), "twin": "south"},
	"ecorp_credit": {"rect": [170, 408, 200, 430], "h": 18.0, "style": 3, "color": Color(0.4, 0.42, 0.46), "sign": "E CORP CONSUMER CREDIT", "sign_col": Color(0.35, 0.55, 1.0), "door": "d_credit"},
	# Chinatown ----------------------------------------------------------------
	"rose_garden": {"rect": [430, 408, 470, 432], "h": 10.0, "style": 6, "color": Color(0.45, 0.12, 0.1), "sign": "ROSE GARDEN TEA HOUSE", "sign_col": Color(1.0, 0.35, 0.4), "door": "d_rose", "awning": Color(0.55, 0.08, 0.06), "pagoda": true},
	"darkarmy_safehouse": {"rect": [604, 344, 640, 376], "h": 14.0, "style": 5, "color": Color(0.22, 0.2, 0.2), "door": "d_da_safe"},
	# Docks ------------------------------------------------------------------
	"pier9_warehouse": {"rect": [-760, -312, -680, -262], "h": 14.0, "style": 5, "color": Color(0.3, 0.26, 0.22), "sign": "PIER 9", "sign_col": Color(0.9, 0.8, 0.5), "door": "d_pier9"},
	# Coney ------------------------------------------------------------------
	"arcade": {"rect": [-192, 640, -148, 676], "h": 11.0, "style": 9, "color": Color(0.3, 0.12, 0.2), "sign": "FUN SOCIETY ARCADE", "sign_col": Color(1.0, 0.2, 0.35), "door": "d_arcade", "flicker": true},
	"trenton_home": {"rect": [364, 572, 386, 596], "h": 9.0, "style": 9, "color": Color(0.5, 0.44, 0.36), "door": "d_trenton"},
	# The Bronx ----------------------------------------------------------------
	"carver_houses": {"rect": [-100, -1425, -50, -1385], "h": 48.0, "style": 1, "color": Color(0.46, 0.24, 0.18), "sign": "CARVER HOUSES  BLDG C", "sign_col": Color(0.9, 0.85, 0.7), "door": "d_carver", "roof": "tank", "memorial": [-62, -1384.4]},
	# Hunts Point ----------------------------------------------------------------
	"airfield_office": {"rect": [1312, -1345, 1352, -1310], "h": 8.0, "style": 2, "color": Color(0.62, 0.6, 0.56), "sign": "BOWERY BAY AIRFIELD", "sign_col": Color(0.4, 0.75, 1.0), "door": "d_airfield"},
	"hunts_lab": {"rect": [1200, -1180, 1260, -1140], "h": 12.0, "style": 5, "color": Color(0.3, 0.28, 0.26), "sign": "TERMINAL MARKET  UNIT 9", "sign_col": Color(0.9, 0.8, 0.5), "door": "d_hunts_lab"},
	# Harlem -----------------------------------------------------------------------
	"st_nicholas": {"rect": [-100, -1020, -50, -985], "h": 22.0, "style": 8, "color": Color(0.55, 0.48, 0.4), "sign": "ST. NICHOLAS YOUTH SHELTER", "sign_col": Color(1.0, 0.85, 0.55), "door": "d_shelter"},
	# Astoria ----------------------------------------------------------------------
	"keller_bldg": {"rect": [945, -622, 985, -592], "h": 18.0, "style": 2, "color": Color(0.5, 0.4, 0.32), "door": "d_keller", "stoop": true},
}

## Doors: id -> {pos [x, z], face (outward: n s e w), interior, name, lock (skill dc or key id)}
const DOORS := {
	"d_apt": {"pos": [-466, 328], "face": "n", "interior": "apt_building", "name": "Your Building"},
	"d_bodega": {"pos": [-409, 328], "face": "n", "interior": "bodega", "name": "Bodega"},
	"d_krista": {"pos": [-339, 312], "face": "s", "interior": "krista_office", "name": "Krista Gordon, LCSW"},
	"d_ron": {"pos": [-592, 408], "face": "n", "interior": "ron_coffee", "name": "Ron's Coffee"},
	"d_pawn": {"pos": [-742, 248], "face": "n", "interior": "pawn_shop", "name": "Pawn Shop"},
	"d_laundro": {"pos": [-588, 328], "face": "n", "interior": "laundromat", "name": "Suds City Laundromat"},
	"d_pharmacy": {"pos": [-328, 408], "face": "n", "interior": "pharmacy", "name": "Pharmacy"},
	"d_precinct": {"pos": [-232, 248], "face": "n", "interior": "precinct", "name": "7th Precinct"},
	"d_darlene": {"pos": [-215, 408], "face": "n", "interior": "darlene_apt", "name": "Darlene's Building", "lock": 35},
	"d_vera": {"pos": [-140, 515], "face": "e", "interior": "vera_stash", "name": "Stash House", "lock": 60, "key": "key_vera_stash"},
	"d_allsafe": {"pos": [-330, -168], "face": "s", "interior": "allsafe", "name": "Allsafe Cybersecurity"},
	"d_ecorp": {"pos": [-65, -262], "face": "s", "interior": "ecorp_lobby", "name": "E Corp Tower"},
	"d_deus": {"pos": [355, -328], "face": "s", "interior": "salina_hotel", "name": "The Salina Hotel", "lock": 100, "key": "deus_invite"},
	"d_relay": {"pos": [-60, -648], "face": "s", "interior": "relay_roof", "name": "Relay Building", "lock": 40, "key": "key_roof"},
	"d_guns": {"pos": [-585, -632], "face": "n", "interior": "sporting_goods", "name": "Ricky's Sporting Goods"},
	"d_angela": {"pos": [-589, 8], "face": "n", "interior": "angela_apt", "name": "Angela's Building"},
	"d_bar": {"pos": [-472, 88], "face": "n", "interior": "rabbit_hole", "name": "The Rabbit Hole"},
	"d_theater": {"pos": [-326, 168], "face": "n", "interior": "old_theater", "name": "Paramount Theater", "lock": 25},
	"d_tyrell": {"pos": [455, 8], "face": "n", "interior": "tyrell_penthouse", "name": "The Wellick Residence"},
	"d_hospital": {"pos": [325, 152], "face": "s", "interior": "mercy_general", "name": "Mercy General Hospital"},
	"d_lenny": {"pos": [577, 88], "face": "n", "interior": "lenny_apt", "name": "Lenny's Building", "lock": 45},
	"d_fbi": {"pos": [65, 328], "face": "n", "interior": "fbi_office", "name": "Federal Building"},
	"d_wtc": {"pos": [-96, 378], "face": "s", "interior": "wtc_lobby", "name": "World Trade Center"},
	"d_credit": {"pos": [185, 408], "face": "n", "interior": "ecorp_credit", "name": "E Corp Consumer Credit"},
	"d_rose": {"pos": [450, 408], "face": "n", "interior": "rose_garden", "name": "Rose Garden Tea House"},
	"d_da_safe": {"pos": [640, 360], "face": "e", "interior": "darkarmy_safehouse", "name": "Warehouse", "lock": 75},
	"d_pier9": {"pos": [-720, -312], "face": "n", "interior": "pier9_warehouse", "name": "Pier 9 Warehouse"},
	"d_arcade": {"pos": [-170, 676], "face": "s", "interior": "arcade", "name": "Fun Society Arcade"},
	"d_trenton": {"pos": [375, 572], "face": "n", "interior": "trenton_home", "name": "The Sharifi Home"},
	"d_steel": {"pos": [540, -568], "face": "s", "interior": "steel_mountain", "name": "Steel Mountain"},
	"d_carver": {"pos": [-75, -1385], "face": "s", "interior": "carver_c", "name": "Carver Houses, Building C"},
	"d_airfield": {"pos": [1312, -1327], "face": "w", "interior": "airfield_office", "name": "Bowery Bay Airfield, Flight Office"},
	"d_hunts_lab": {"pos": [1200, -1160], "face": "w", "interior": "hunts_lab", "name": "Terminal Market, Unit 9", "lock": 55},
	"d_shelter": {"pos": [-75, -985], "face": "s", "interior": "st_nicholas", "name": "St. Nicholas Youth Shelter"},
	"d_keller": {"pos": [965, -592], "face": "s", "interior": "keller_apt", "name": "31-14 Ditmars Blvd", "lock": 40, "key": "key_keller"},
}

## Subway stations: fast travel between discovered stations.
const SUBWAYS := {
	"sub_les": {"rect": [-510, 328, -498, 338], "door": [-504, 328], "face": "n", "name": "Delancey St Station"},
	"sub_midtown": {"rect": [-250, -178, -238, -168], "door": [-244, -168], "face": "s", "name": "5th Ave - 53rd St"},
	"sub_heights": {"rect": [-380, -632, -368, -622], "door": [-374, -632], "face": "n", "name": "181st St Station"},
	"sub_industrial": {"rect": [140, -552, 152, -542], "door": [146, -552], "face": "n", "name": "Harlem River Yards"},
	"sub_civic": {"rect": [140, 328, 152, 338], "door": [146, 328], "face": "n", "name": "Chambers St Station"},
	"sub_chinatown": {"rect": [400, 328, 412, 338], "door": [406, 328], "face": "n", "name": "Canal St Station"},
	"sub_hells": {"rect": [-770, 8, -758, 18], "door": [-764, 8], "face": "n", "name": "50th St Station"},
	"sub_coney": {"rect": [20, 568, 32, 578], "door": [26, 568], "face": "n", "name": "Stillwell Ave - Coney Island"},
	"sub_uptown": {"rect": [530, 168, 542, 178], "door": [536, 168], "face": "n", "name": "77th St Station"},
	"sub_inwood": {"rect": [-600, -1112, -588, -1102], "door": [-594, -1112], "face": "n", "name": "Dyckman St Station"},
	"sub_harlem": {"rect": [50, -1032, 62, -1022], "door": [56, -1032], "face": "n", "name": "125th St - Harlem"},
	"sub_bronx": {"rect": [-210, -1432, -198, -1422], "door": [-204, -1432], "face": "n", "name": "Fordham Rd Station"},
	"sub_hunts": {"rect": [1230, -1352, 1242, -1342], "door": [1236, -1352], "face": "n", "name": "Hunts Point Ave"},
	"sub_astoria": {"rect": [1100, -552, 1112, -542], "door": [1106, -552], "face": "n", "name": "Astoria Blvd"},
	"sub_lic": {"rect": [1350, 88, 1362, 98], "door": [1356, 88], "face": "n", "name": "Court Square - LIC"},
}

## Map points of interest (discovered when you walk near them).
const POIS := {
	"poi_park": {"pos": [-65, 80], "name": "Central Park", "r": 60.0},
	"poi_memorial": {"pos": [-150, 150], "name": "Washington Township Memorial", "r": 20.0},
	"poi_chess": {"pos": [30, 10], "name": "Chess Tables", "r": 18.0},
	"poi_boardwalk": {"pos": [0, 700], "name": "Coney Boardwalk", "r": 40.0},
	"poi_pier": {"pos": [-30, 840], "name": "Steeplechase Pier", "r": 25.0},
	"poi_wheel": {"pos": [100, 660], "name": "Wonder Wheel", "r": 35.0},
	"poi_parachute": {"pos": [-400, 660], "name": "The Parachute Jump", "r": 30.0},
	"poi_ecorp_plaza": {"pos": [-65, -240], "name": "E Corp Plaza", "r": 40.0},
	"poi_docks": {"pos": [-800, -150], "name": "West Side Piers", "r": 50.0},
	"poi_steel": {"pos": [520, -560], "name": "Steel Mountain", "r": 60.0},
	"poi_times": {"pos": [-200, -440], "name": "Neon Square", "r": 45.0},
	"poi_bridge_view": {"pos": [840, 200], "name": "East River Overlook", "r": 30.0},
	"poi_trainyard": {"pos": [700, -760], "name": "Rail Yard", "r": 50.0},
	"poi_graveyard": {"pos": [-700, -760], "name": "Trinity Cemetery", "r": 40.0},
	"poi_tryon": {"pos": [-650, -1340], "name": "Fort Tryon Park", "r": 70.0},
	"poi_wtc": {"pos": [-46, 388], "name": "World Trade Center Plaza", "r": 30.0},
	"poi_concourse": {"pos": [220, -1310], "name": "Grand Concourse", "r": 50.0},
	"poi_airfield": {"pos": [1450, -1240], "name": "Bowery Bay Airfield", "r": 140.0},
	"poi_hunts_market": {"pos": [1235, -1260], "name": "Hunts Point Market", "r": 60.0},
	"poi_astoria_water": {"pos": [1735, -600], "name": "Astoria Waterfront", "r": 40.0},
	"poi_gantry": {"pos": [1735, 160], "name": "Gantry Plaza", "r": 40.0},
	"poi_harlem_river": {"pos": [-835, -1150], "name": "Harlem River Promenade", "r": 40.0},
	"poi_carver": {"pos": [-75, -1375], "name": "Carver Houses", "r": 30.0},
	"poi_shelter": {"pos": [-75, -975], "name": "St. Nicholas Shelter", "r": 25.0},
}

## Top of the North Tower (reached by the express elevator in the lobby).
const WTC_ROOF := Vector3(-96.0, 380.2, 369.8)
const WTC_H := 380.0

## Where the player starts a new game (after the intake session).
const START_POS := Vector3(-339, 0, 316)
const START_YAW := PI


static func door_world(door_id: String) -> Dictionary:
	# Returns {pos: Vector3 (on the facade), out: Vector3 (outward normal), yaw}
	var d: Dictionary = all_doors().get(door_id, {})
	if d.is_empty():
		return {}
	var p: Array = d["pos"]
	var out := face_normal(str(d["face"]))
	return {"pos": Vector3(float(p[0]), 0.0, float(p[1])), "out": out, "yaw": atan2(-out.x, -out.z) + PI}


static func face_normal(f: String) -> Vector3:
	match f:
		"n": return Vector3(0, 0, -1)
		"s": return Vector3(0, 0, 1)
		"e": return Vector3(1, 0, 0)
		"w": return Vector3(-1, 0, 0)
	return Vector3(0, 0, 1)


## Spot just outside a door where the player appears when exiting.
static func door_exit(door_id: String) -> Dictionary:
	var dw := door_world(door_id)
	if dw.is_empty():
		return {"pos": START_POS, "yaw": START_YAW}
	var out: Vector3 = dw["out"]
	# Facing away from the door: look along `out`.
	return {"pos": (dw["pos"] as Vector3) + out * 2.2, "yaw": atan2(-out.x, -out.z)}


static func subway_world(id: String) -> Vector3:
	var s: Dictionary = SUBWAYS.get(id, {})
	if s.is_empty():
		return START_POS
	var p: Array = s["door"]
	return Vector3(float(p[0]), 0.0, float(p[1]))


## All enterable doors, including subway stations.
static var _all_doors: Dictionary = {}


## Landmark doors plus subway stairs. Built once (callers must not modify it).
static func all_doors() -> Dictionary:
	if not _all_doors.is_empty():
		return _all_doors
	var out := DOORS.duplicate()
	for sid in SUBWAYS.keys():
		var s: Dictionary = SUBWAYS[sid]
		out[sid] = {"pos": s["door"], "face": s["face"], "interior": "subway:" + str(sid), "name": s["name"]}
	_all_doors = out
	return out
