class_name InteriorData
extends RefCounted
## Interior cells. Local meters, floor at y=0. See top of the file for the schema.
## rooms {r:[x0,z0,x1,z1],h,wall,floor,ceil,light,energy,lights,floor_kind,trim}
## doors [[x,z,width]] · exits [{pos,face,to,label,lock,key,when}]
## furn [type,x,z,rot,{params}] · containers/pickups/spots per Game.

const W_BRICK := Color(0.42, 0.3, 0.24)
const W_PLASTER := Color(0.55, 0.5, 0.44)
const W_OFFICE := Color(0.62, 0.64, 0.66)
const W_CONCRETE := Color(0.45, 0.45, 0.47)
const W_DARK := Color(0.22, 0.2, 0.2)
const F_WOOD := Color(0.34, 0.24, 0.15)
const F_TILE := Color(0.5, 0.5, 0.52)
const F_CARPET := Color(0.25, 0.22, 0.24)
const F_CONCRETE := Color(0.32, 0.32, 0.33)

const INTERIORS := {
# ============================================================ KRISTA'S OFFICE
"krista_office": {
	"name": "Krista Gordon, LCSW", "amb": "jazz", "ambient": Color(0.4, 0.35, 0.3),
	"rooms": [{"r": [0, 0, 8, 7], "h": 3.2, "wall": Color(0.55, 0.47, 0.38), "floor": F_WOOD, "light": Color(1.0, 0.82, 0.6), "energy": 1.3}],
	"exits": [{"pos": [4, 7], "face": "s", "to": "world:d_krista", "label": "Leave"}],
	"furn": [["armchair", 1.6, 2.6, 90, {"col": Color(0.4, 0.3, 0.22)}], ["sofa", 5.8, 3.0, -90, {"col": Color(0.3, 0.35, 0.32)}], ["coffee_table", 3.6, 3.0, 90], ["bookshelf", 1.0, 0.45, 0], ["bookshelf", 2.4, 0.45, 0], ["plant", 7.4, 0.7, 0], ["lamp", 0.6, 6.2, 0], ["rug", 3.6, 3.0, 0, {"w": 3.2, "d": 2.6, "col": Color(0.35, 0.15, 0.12)}], ["window", 5.5, 0.15, 0, {"w": 1.6}], ["desk", 6.7, 6.2, 180], ["clock", 0.3, 3.5, 90, {"y": 2.4}]],
	"spots": [{"id": "krista_diploma", "kind": "text", "title": "Diploma", "verb": "Read", "pos": [3.0, 0.2, 1.8], "size": [1, 1, 0.5], "text": "Krista Gordon, LCSW. Master of Social Work, NYU. 'Licensed to listen to me lie for fifty minutes a week.'"}],
},
# ================================================================ APARTMENT
"apt_building": {
	"name": "Your Building", "ambient": Color(0.3, 0.27, 0.25),
	"rooms": [
		{"r": [0, 0, 6, 5], "h": 3.0, "wall": W_BRICK, "floor": F_TILE, "floor_kind": "tile", "light": Color(0.8, 0.85, 0.7), "energy": 0.9},
		{"r": [0, -14, 6, 0], "h": 3.0, "wall": W_BRICK, "floor": F_TILE, "floor_kind": "tile", "light": Color(0.8, 0.82, 0.7), "energy": 0.7, "lights": [[3, 2.6, -4], [3, 2.6, -11]]},
	],
	"doors": [[3, 0, 1.4], [3, -5, 1.2]],
	"exits": [
		{"pos": [3, 5], "face": "s", "to": "world:d_apt", "label": "Street"},
		{"pos": [3, -14], "face": "n", "to": "interior:elliot_apt:0", "label": "Apartment 4D", "key": "key_apartment", "lock": 40},
	],
	"furn": [["mailbox", 5.4, 3.5, -90], ["mailbox", 5.4, 2.5, -90], ["stairs_up", 4.8, -11, 0], ["radiator", 0.3, -3, 90], ["poster", 0.15, -8, 90, {"col": Color(0.5, 0.1, 0.1)}], ["trash_pile", 5.2, -12, 0], ["climate_unit", 0.7, -12.4, 90]],
	"containers": [{"id": "apt_mailbox_e", "title": "Mailbox 4D", "pos": [5.3, 3.5], "y": 1.3, "size": [0.6, 0.6, 0.6], "items": {}, "cash": 0, "loot": "desk"}],
	"spots": [
		{"id": "apt_boiler", "kind": "terminal", "title": "Boiler Controller", "verb": "Access", "pos": [0.8, 1.2, -12.4], "size": [1.0, 1.6, 1.4], "hack": 20, "when": "q.sq_super>=10", "header": "THERMOTECH 3000  //  E CORP HOME SERVICES", "welcome": "SERVICE LOCK ACTIVE. Your heating subscription has lapsed. Heat will resume when payment is received. Thank you for choosing E Corp.",
			"entries": [{"title": "cat service_contract.txt", "text": "The building paid for the boiler in 1998. E Corp bought the servicing company in 2011 and pushed a firmware update that turned the heat into a subscription. Forty-one apartments. Nine of them have kids. It's February."}],
			"actions": [{"title": "Kill the service lock and restore the heat", "result": "The lock was a single flag in a config file, guarded by a default password. The boiler coughs, thinks about it, and roars. Somewhere upstairs a radiator starts clanking like applause.", "fx": "set heat_on ; quest sq_super 20 ; xp 25", "when": "!flag.heat_on"}]},
	],
},
"elliot_apt": {
	"name": "Apartment 4D", "amb": "interior", "ambient": Color(0.26, 0.24, 0.26),
	"rooms": [
		{"r": [0, 0, 7, 6], "h": 2.9, "wall": Color(0.38, 0.34, 0.34), "floor": F_WOOD, "light": Color(0.9, 0.7, 0.5), "energy": 0.9, "lights": [[3.5, 2.4, 3]]},
		{"r": [7, 1.5, 11, 6], "h": 2.9, "wall": Color(0.4, 0.4, 0.42), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.7, 0.8, 0.85), "energy": 0.8},
	],
	"doors": [[7, 3.5, 1.2]],
	"exits": [{"pos": [3.5, 0], "face": "n", "to": "interior:apt_building:1", "label": "Hallway"}],
	"furn": [
		["bed", 1.6, 4.4, 0, {"col": Color(0.2, 0.22, 0.3)}], ["desk_pc", 5.4, 1.0, 180, {"screen": Color(0.2, 0.9, 0.5)}], ["fishtank", 6.4, 4.6, -90], ["wardrobe", 0.7, 1.0, 90], ["bookshelf", 3.0, 0.4, 0], ["sofa", 3.4, 5.2, 180, {"col": Color(0.28, 0.24, 0.2)}], ["tv", 3.4, 3.0, 0, {"screen": Color(0.25, 0.3, 0.4)}], ["fridge", 10.4, 2.4, -90], ["kitchen", 9.0, 5.5, 180, {"w": 3.0}], ["window", 3.5, 0.15, 0, {"w": 1.6, "col": Color(0.1, 0.12, 0.2)}], ["lamp", 6.6, 5.4, 0, {"col": Color(0.9, 0.6, 0.4)}], ["trash", 4.6, 1.4, 0],
	],
	"containers": [
		{"id": "apt_desk", "title": "Your Desk", "pos": [5.4, 1.5], "y": 0.6, "size": [1.4, 0.7, 0.7], "loot": "desk", "items": {"usb_drive": 3, "bobby_pin": 2}},
		{"id": "apt_wardrobe", "title": "Wardrobe", "pos": [0.9, 1.0], "y": 1.0, "size": [0.7, 2, 0.7], "loot": "wardrobe", "items": {"hoodie_black": 1, "work_clothes": 1}},
		{"id": "apt_fridge", "title": "Refrigerator", "pos": [10.2, 2.4], "y": 0.9, "size": [0.7, 1.8, 0.7], "loot": "fridge"},
		{"id": "apt_stash", "title": "Loose Floorboard", "pos": [1.6, 5.4], "y": 0.1, "size": [0.8, 0.3, 0.8], "items": {"pistol_9mm": 1, "ammo_9mm": 24, "cash": 0}, "cash": 120, "owner_ok": "true"},
	],
	"pickups": [
		{"id": "apt_meds_start", "item": "meds", "count": 2, "pos": [10.6, 1.0, 5.4]},
		{"id": "apt_fishfood", "item": "fish_food", "count": 1, "pos": [6.5, 0.9, 4.6]},
	],
	"spots": [
		{"id": "apt_pc", "kind": "terminal", "title": "Your Workstation", "verb": "Log in", "pos": [5.4, 1.2, 1.4], "size": [1.4, 1.4, 1.0], "user": "elliot", "welcome": "root@elliot:~# whoami\nelliot. probably.\n\n3 unread messages. 1 new file on the desktop you don't recognize.", "entries": [
			{"title": "mail: Gideon Goddard  [URGENT]", "text": "Elliot. E Corp had an incident overnight: somebody knocked on CS30, the honeypot we keep open on purpose, and their CTO's office has been calling me every forty minutes since. I need your eyes on it. Tomorrow, nine sharp, Allsafe. NOT tonight. Go to bed. I mean it this time. -G", "fx": "set read_gideon ; quest mq_hello 25"},
				{"title": "file: fsociety00.dat", "text": "4.1 megabytes. Created 3:12 AM this morning, on your machine, under your account. You don't download things. Things don't download themselves onto what you run.\n\nOne line of text:\n\n    hello friend.\n\nAnd under it, code. A rootkit. A good one. It hides the way you'd hide. It names its variables after old arcade games, the way you do. You'd swear you wrote it. You don't remember writing it.", "fx": "set fsociety_msg ; set dat_opened"},
				{"title": "cat /var/log/auth.log | tail", "text": "03:09  login  elliot  (local, keyboard)\n03:31  logout elliot\n\nTyped, not pasted. You can see the pauses where a hand hesitated over the keys. Twenty-two minutes you don't have.\n\nYou took your pills last night. You're almost sure you took your pills.", "fx": "set dat_logs ; stab -2", "when": "flag.dat_opened"},
			{"title": "sms: Shayla", "text": "u home?? i have the good stuff and the bad stuff. also some guy named vera was asking about u. dont answer if he calls lol. unless u want to. dont. come say hi im in the hallway"},
			{"title": "news: tonight's headlines", "text": "E CORP DENIES NETWORK BREACH: 'Our systems are secure,' says SVP Tyrell Wellick.\nPRICE: E COIN 'THE FUTURE OF MONEY.' Critics: 'a future E Corp owns.'\nTOWNSHIP FAMILIES MARK 22 YEARS WITHOUT A TRIAL.\nMASKED PROTESTERS AT THE TWIN TOWERS PLAZA. A cartoon face, a top hat, a message: 'WE ARE FSOCIETY.'\nBRONX: SIX TEENAGE OVERDOSES IN A MONTH NEAR THE CARVER HOUSES. 'Candy,' residents call it. Police: 'no leads.'\nHARLEM SHELTER COUNSELOR: 'I CALLED THE POLICE TWICE. NOBODY WILL LISTEN.'\nNYPD: MUGGINGS UP IN THE BRONX AS SHELTERS CLOSE."},
			{"title": "app: CourierNet (jobs)", "text": "Cash work, no questions. Deliveries, repo, 'data recovery', bounties. Press J on your phone for DATA > JOBS any time. Up to three contracts at once. The money's real. So is the risk."},
			{"title": "cat drafts/krista.txt", "text": "Dear Krista, today I felt almost — [delete]. She gets the truth in installments I can't afford."},
		], "actions": [{"title": "Feed Qwerty (remotely, you monster)", "result": "The auto-feeder clicks. The fish forgives you. Fish always forgive.", "fx": "trust krista 0"}]},
		{"id": "apt_bed_spot", "kind": "bed", "title": "Your Bed", "verb": "Sleep", "pos": [1.6, 0.6, 4.4], "size": [1.6, 1, 2.2]},
		{"id": "apt_tv", "kind": "convo", "title": "TV", "verb": "Watch", "pos": [3.4, 1.0, 3.0], "size": [1.4, 1.0, 0.6], "convo": "apt_news", "when": "flag.five_nine_done"},
		{"id": "apt_qwerty", "kind": "convo", "title": "Qwerty (the fish)", "verb": "Watch", "pos": [6.4, 1.2, 4.6], "size": [0.9, 1, 0.9], "convo": "apt_qwerty"},
	],
},
# ==================================================================== BODEGA
"bodega": {
	"name": "Bodega", "ambient": Color(0.38, 0.34, 0.28),
	"rooms": [{"r": [0, 0, 9, 7], "h": 3.0, "wall": Color(0.4, 0.36, 0.3), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.9, 0.9, 0.8), "energy": 1.1, "lights": [[2.5, 2.6, 3.5], [6.5, 2.6, 3.5]]}],
	"exits": [{"pos": [4.5, 7], "face": "s", "to": "world:d_bodega", "label": "Street"}],
	"furn": [["counter", 7.0, 1.2, 0, {"w": 3.5}], ["register", 7.5, 1.0, 0], ["shelf", 1.0, 2.0, 90], ["shelf", 1.0, 4.0, 90], ["shelf", 3.5, 6.2, 0], ["fridge_glass", 8.2, 4.5, -90], ["coffee_machine", 5.8, 0.8, 0], ["lamp", 8.5, 6.5, 0]],
	"spots": [{"id": "bodega_shop", "kind": "shop", "title": "Bodega Counter", "verb": "Shop", "pos": [7.0, 1.0, 2.2], "size": [3.5, 2, 1.4], "shop": "bodega"}],
},
# ============================================================== RON'S COFFEE
"ron_coffee": {
	"name": "Ron's Coffee", "amb": "office", "ambient": Color(0.36, 0.3, 0.26), "restricted": "",
	"rooms": [
		{"r": [0, 0, 9, 7], "h": 3.0, "wall": Color(0.35, 0.26, 0.2), "floor": F_WOOD, "light": Color(0.95, 0.75, 0.5), "energy": 1.0, "lights": [[3, 2.6, 3.5], [7, 2.6, 3.5]]},
		{"r": [9, 2, 13, 6], "h": 3.0, "wall": W_DARK, "floor": F_CONCRETE, "light": Color(0.3, 0.9, 0.5), "energy": 0.7},
	],
	"doors": [[9, 4, 1.1]],
	"exits": [{"pos": [4.5, 7], "face": "s", "to": "world:d_ron", "label": "Street"}],
	"furn": [
		["bar_counter", 6.5, 1.0, 0, {"w": 5.0, "neon": Color(1.0, 0.5, 0.3)}], ["coffee_machine", 5.0, 0.8, 0], ["coffee_machine", 7.5, 0.8, 0], ["register", 8.5, 1.0, 0], ["cafe_table", 2.0, 3.5, 0], ["cafe_table", 2.0, 5.5, 0], ["cafe_table", 5.5, 5.5, 0], ["shelf", 0.6, 2.0, 90], ["server_rack", 12.0, 3.0, -90, {"led": Color(1.0, 0.3, 0.2)}], ["desk_pc", 10.5, 5.2, 180, {"screen": Color(1.0, 0.4, 0.3)}], ["filing_cabinet", 12.4, 5.5, -90],
	],
	"exits2": [],
	"containers": [
		{"id": "ron_register", "title": "Register", "pos": [8.5, 1.4], "y": 1.2, "size": [0.6, 0.5, 0.5], "loot": "register", "owner": "ron", "owner_ok": "dead.ron"},
		{"id": "ron_cabinet", "title": "Locked Filing Cabinet", "pos": [12.4, 5.5], "y": 0.65, "size": [0.5, 1.3, 0.6], "lock": 45, "items": {"stalker_db": 1}, "owner": "ron", "owner_ok": "q.mq_rootkit>=40", "fx_open": "set found_ron_db"},
	],
	"spots": [
		{"id": "ron_shop", "kind": "shop", "title": "Order Coffee", "verb": "Order", "pos": [6.5, 1.0, 2.0], "size": [5, 2, 1.2], "shop": "ron_cafe", "when": "!dead.ron"},
		{"id": "ron_server", "kind": "terminal", "title": "Ron's Back Server", "verb": "Access", "pos": [12.0, 1.2, 3.0], "size": [1, 1.4, 1], "hack": 35, "header": "rons-coffee.net — ADMIN", "password_flag": "found_ron_code", "welcome": "You're in. The directory listing makes you sick.", "entries": [{"title": "ls /customers/", "text": "Thousands of names. Credit cards. Home addresses. Ron sells stalkerware to people who want to track their exes. This is the product. These are the victims.", "fx": "set knows_ron_secret ; quest sq_ron 20"}, {"title": "cat README", "text": "'SPYPLUS — total transparency for the people you love.' He calls it love. It's a leash with a subscription fee."}], "actions": [{"title": "Copy the customer database", "result": "Transfer complete. You have the whole operation. Enough to end him, or sell him out, or something worse.", "fx": "give stalker_db 1 ; quest sq_ron 30", "when": "flag.knows_ron_secret & !item.stalker_db"}, {"title": "Plant the rootkit (fsociety)", "result": "The rootkit slides into the kernel. fsociety owns Ron's server now. And through it, a doorway.", "fx": "set rootkit_planted ; quest mq_rootkit 40 ; quest mq_rootkit 50 ; quest mq_fsociety 10 ; xp 40", "when": "!flag.rootkit_planted & q.mq_rootkit>=30 | !flag.rootkit_planted & flag.fsociety_msg"}]},
	],
},
# ================================================================ ALLSAFE
"allsafe": {
	"name": "Allsafe Cybersecurity", "amb": "office", "ambient": Color(0.4, 0.42, 0.44),
	"rooms": [
		{"r": [0, 0, 14, 9], "h": 3.2, "wall": W_OFFICE, "floor": F_CARPET, "floor_kind": "tile", "ceil": Color(0.7, 0.72, 0.74), "light": Color(0.85, 0.9, 0.95), "energy": 1.0, "lights": [[3.5, 2.9, 4.5], [10.5, 2.9, 4.5], [7, 2.9, 7]]},
		{"r": [14, 2, 20, 8], "h": 3.2, "wall": Color(0.5, 0.52, 0.55), "floor": F_CARPET, "floor_kind": "tile", "light": Color(0.8, 0.85, 0.9), "energy": 0.9},
	],
	"doors": [[14, 5, 1.2]],
	"exits": [{"pos": [7, 9], "face": "s", "to": "world:d_allsafe", "label": "Street"}],
	"furn": [
		["reception", 7, 1.2, 0, {"glow": Color(0.35, 0.9, 0.9)}], ["logo_wall", 7, 0.25, 0, {"w": 5, "glow": Color(0.35, 0.9, 0.9)}], ["desk_pc", 2.5, 4.0, 90, {"screen": Color(0.3, 0.9, 0.6)}], ["desk_pc", 2.5, 6.5, 90, {"screen": Color(0.3, 0.7, 0.9)}], ["desk_pc", 11.5, 4.0, -90], ["desk_pc", 11.5, 6.5, -90], ["water_cooler", 6.5, 8.5, 180], ["plant", 13.4, 8.4, 0], ["server_rack", 18.5, 3.0, -90], ["server_rack", 18.5, 4.2, -90], ["server_rack", 18.5, 5.4, -90], ["conference", 17, 6.5, 0], ["whiteboard", 14.4, 7.8, 90],
	],
	"containers": [
		{"id": "allsafe_desk1", "title": "Your Desk", "pos": [2.5, 4.0], "y": 0.6, "size": [0.7, 0.7, 1.4], "loot": "office_desk", "owner_ok": "true"},
		{"id": "allsafe_supplies", "title": "Supply Cabinet", "pos": [13.6, 8.4], "y": 0.6, "size": [0.6, 1.2, 0.6], "loot": "office_desk", "items": {"bobby_pin": 4, "usb_drive": 2}},
	],
	"spots": [
		{"id": "allsafe_terminal", "kind": "terminal", "title": "Allsafe Workstation", "verb": "Log in", "pos": [11.5, 1.2, 4.0], "size": [0.7, 1.4, 1], "hack": 25, "header": "cs30.allsafe.lan", "welcome": "Allsafe internal. Gideon's watching the watchers now.", "entries": [{"title": "Read: E Corp contract", "text": "Allsafe holds the E Corp security contract. One client. If E Corp walks, Gideon's company dies. Everyone here is one bad day from unemployed.", "fx": "set knows_allsafe_ecorp"}, {"title": "Read: honeypot alert", "text": "Someone left a honeypot server (CS30) exposed. Deliberately. Someone inside wants a door left open."}], "actions": [{"title": "Scrub the intrusion logs", "result": "The logs forget you were ever here. Gideon will never know. You will.", "fx": "set scrubbed_logs ; infamy allsafe 1", "when": "q.mq_rootkit>=20"},
				{"title": "Frame Gideon: his credentials on the CS30 change, his name on fsociety's relay, $40,000 in a Cyprus account", "result": "It takes eleven minutes. That's the part you'll remember: that it only took eleven minutes to make twenty years of an honest man's life look like a lie. Through the glass, Gideon is on the phone, laughing at something. He waves at you.", "fx": "set gideon_framed ; set da_allied ; set ally_secured ; quest mq_darkarmy 40 ; quest mq_darkarmy done ; fame darkarmy 6 ; stab -8 ; xp 120", "when": "flag.da_price_gideon & !flag.gideon_framed & !flag.da_betrayed"},
				{"title": "Build the ghost: an insider who never existed, wearing Gideon's credentials like a borrowed coat", "result": "A contractor named 'R. Kovac'. A badge photo built from nine strangers' faces. Two years of commute data, a gym membership, a girlfriend in Philadelphia who doesn't exist either. The CS30 change is his now. He'll vanish the day the FBI comes looking, the way contractors do. Gideon keeps his name.", "fx": "set ghost_insider ; set da_allied ; set ally_secured ; quest mq_darkarmy 40 ; quest mq_darkarmy done ; fame darkarmy 8 ; stab 2 ; xp 160", "when": "flag.da_price_ghost & !flag.ghost_insider & !flag.da_betrayed"}]},
		{"id": "allsafe_server_spot", "kind": "convo", "title": "Server Room", "verb": "Inspect", "pos": [18.5, 1.2, 4.2], "size": [1, 1.4, 3], "convo": "allsafe_servers"},
	],
},
# ============================================================= E CORP LOBBY
"ecorp_lobby": {
	"name": "E Corp Tower — Lobby", "amb": "office", "ambient": Color(0.42, 0.44, 0.5), "restricted": "ecorp", "allowed_when": "day | disguise.ecorp | q.mq_ecorp>=30 | flag.ecorp_invited",
	"rooms": [
		{"r": [0, 0, 18, 12], "h": 6.0, "wall": Color(0.3, 0.34, 0.42), "floor": Color(0.15, 0.16, 0.2), "floor_kind": "tile", "ceil": Color(0.2, 0.22, 0.28), "light": Color(0.5, 0.6, 1.0), "energy": 1.1, "lights": [[4, 5.5, 4], [14, 5.5, 4], [9, 5.5, 9]]},
	],
	"exits": [
		{"pos": [9, 12], "face": "s", "to": "world:d_ecorp", "label": "Plaza"},
		{"pos": [15, 1], "face": "n", "to": "interior:ecorp_floor:0", "label": "Executive Elevator", "lock": 55, "key": "ecorp_keycard", "unlock_when": "flag.ecorp_door_tyrell | disguise.ecorp", "label2": ""},
	],
	"furn": [
		["reception", 9, 2, 0, {"col": Color(0.15, 0.18, 0.25), "glow": Color(0.4, 0.6, 1.0)}], ["logo_wall", 9, 0.3, 0, {"w": 8, "glow": Color(0.4, 0.6, 1.0)}], ["metal_detector", 4, 4, 0], ["metal_detector", 14, 4, 0], ["security_desk", 9, 5, 0], ["elevator", 15, 0.4, 0], ["elevator", 3, 0.4, 0], ["plant", 1, 11, 0], ["plant", 17, 11, 0], ["bench", 9, 10, 0, {"w": 3}],
	],
	"spots": [
		{"id": "ecorp_directory", "kind": "text", "title": "Building Directory", "verb": "Read", "pos": [1, 1.5, 6], "size": [0.5, 2, 1], "text": "E CORP TOWER. Floors 1-40: Consumer Banking. 41-70: Legal. 71-90: Executive. 91: Office of the CTO, Tyrell Wellick. Roof: restricted."},
	],
	"containers": [{"id": "ecorp_secdesk", "title": "Security Desk", "pos": [9, 5.5], "y": 0.6, "size": [1, 0.6, 0.6], "loot": "guard_locker", "owner": "ecorp", "owner_ok": "disguise.ecorp", "items": {"ecorp_keycard": 1}}],
},
"ecorp_floor": {
	"name": "E Corp — 23rd Floor", "amb": "office", "ambient": Color(0.4, 0.42, 0.48), "restricted": "ecorp", "allowed_when": "disguise.ecorp | flag.ecorp_invited | flag.ecorp_door_tyrell",
	"rooms": [{"r": [0, 0, 16, 10], "h": 3.0, "wall": Color(0.5, 0.52, 0.56), "floor": F_CARPET, "floor_kind": "tile", "light": Color(0.75, 0.82, 0.95), "energy": 0.95, "lights": [[4, 2.7, 3], [12, 2.7, 3], [8, 2.7, 7]]}],
	"exits": [{"pos": [1, 0], "face": "n", "to": "interior:ecorp_lobby:1", "label": "Elevator"}],
	"furn": [["desk_pc", 3, 3, 90], ["desk_pc", 3, 6, 90], ["desk_pc", 13, 3, -90], ["desk_pc", 13, 6, -90], ["conference", 8, 8, 0], ["server_rack", 8, 1, 0, {"led": Color(0.4, 0.6, 1.0)}], ["filing_cabinet", 15.4, 2, -90], ["filing_cabinet", 15.4, 3, -90], ["water_cooler", 8, 9.4, 180]],
	"containers": [{"id": "ecorp_files", "title": "E Corp Records", "pos": [15.3, 2.5], "y": 0.65, "size": [0.5, 1.3, 1.2], "lock": 55, "items": {"colby_archive": 1}, "owner": "ecorp", "owner_ok": "false", "fx_open": "quest sq_colby 20"}],
	"spots": [{"id": "ecorp_term", "kind": "terminal", "title": "E Corp Terminal", "verb": "Access", "pos": [13, 1.2, 3], "size": [0.7, 1.4, 1], "hack": 55, "password_flag": "ecorp_door_tyrell", "header": "corp.e-corp.com — restricted", "welcome": "You're inside E Corp. 5/9 of the world's records, humming.", "entries": [{"title": "Read: debt records", "text": "Every loan, every mortgage, every crushed person, in one schema. Delete this and half the country is free. Delete this and half the country is chaos. Both are true.", "fx": "set saw_debt_records ; quest mq_ecorp 40"}, {"title": "Read: Washington Township", "text": "Internal memo, 1993. A chemical leak. Angela's mother's name is on the casualty list. So is the name of the man who signed the cover-up: Terry Colby.", "fx": "set knows_township"}], "actions": [{"title": "Install fsociety access", "result": "The femtocell handshakes. fsociety has a foothold in the tower now.", "fx": "take femtocell 1 ; set ecorp_foothold ; quest mq_ecorp 50 ; xp 60", "when": "item.femtocell>=1 & !flag.ecorp_foothold"}]}],
},
# =============================================================== THE ARCADE
"arcade": {
	"name": "Fun Society Arcade", "amb": "interior", "ambient": Color(0.24, 0.2, 0.26),
	"rooms": [
		{"r": [0, 0, 12, 8], "h": 3.2, "wall": Color(0.28, 0.14, 0.22), "floor": Color(0.18, 0.14, 0.16), "light": Color(1.0, 0.3, 0.5), "energy": 0.8, "lights": [[3, 2.8, 4], [9, 2.8, 4]]},
		{"r": [12, 2, 18, 7], "h": 3.0, "wall": W_DARK, "floor": F_CONCRETE, "light": Color(0.3, 0.9, 0.5), "energy": 0.85, "lights": [[15, 2.6, 4.5]]},
	],
	"doors": [[12, 4.5, 1.1]],
	"exits": [{"pos": [6, 8], "face": "s", "to": "world:d_arcade", "label": "Boardwalk"}],
	"furn": [
		["arcade_cab", 1.2, 2, 90, {"screen": Color(0.3, 0.9, 0.6), "glow": Color(1, 0.3, 0.4)}], ["arcade_cab", 1.2, 4, 90, {"screen": Color(0.9, 0.3, 0.3), "glow": Color(0.3, 0.5, 1)}], ["arcade_cab", 1.2, 6, 90, {"screen": Color(0.9, 0.8, 0.2), "glow": Color(1, 0.5, 0.2)}], ["pinball", 5, 6.5, 0], ["pinball", 7, 6.5, 0], ["arcade_cab", 10.8, 2, -90], ["arcade_cab", 10.8, 6, -90], ["jukebox", 6, 0.6, 0],
		["table", 15, 4.5, 0, {"w": 2.5, "d": 1.6}], ["monitor_wall", 17.6, 4.5, -90], ["server_rack", 12.6, 6.2, 0, {"led": Color(0.3, 1, 0.4)}], ["chair", 14, 3.5, 0], ["chair", 16, 3.5, 180], ["whiteboard", 15, 2.2, 0], ["boxes", 17, 6.5, 0],
	],
	"containers": [{"id": "arcade_stash", "title": "fsociety Stash", "pos": [17, 6.5], "y": 0.4, "size": [1.2, 0.9, 0.6], "loot": "crate", "items": {"malware_59": 1, "usb_drive": 3, "raspberry_pi": 1, "femtocell": 1}, "when": "q.mq_rootkit>=40"}],
	"spots": [
		{"id": "arcade_invaders", "kind": "minigame", "title": "SPACE INVADERS", "verb": "Play", "pos": [1.4, 1.2, 2], "size": [0.9, 1.4, 0.9], "game": "invaders", "fx_win": "achieve arcade_champ ; set arcade_won"},
		{"id": "arcade_pinball", "kind": "minigame", "title": "Pinball", "verb": "Play", "pos": [5, 1.2, 6.5], "size": [0.9, 1.2, 1.4], "game": "signal"},
		{"id": "arcade_workstation", "kind": "terminal", "title": "fsociety Mainframe", "verb": "Access", "pos": [17.6, 1.2, 4.5], "size": [1, 1.4, 2], "when": "flag.joined_fsociety", "welcome": "fsociety mainframe. The plan lives here.", "entries": [{"title": "Read: the plan", "text": "Encrypt every E Corp record with a key nobody keeps. The debt doesn't get erased — it becomes unreadable. Same thing, if you're brave enough."}, {"title": "Read: Darlene's note", "text": "'If you're reading this without me, you already made the choice I was afraid of. Come home. — D'"}]},
		{"id": "arcade_pixel", "kind": "convo", "title": "Respawn (video call)", "verb": "Answer", "pos": [17.6, 1.2, 4.5], "size": [1.2, 1.4, 1.5], "convo": "pixel", "when": "flag.joined_fsociety & q.mq_respawn.started"},
		{"id": "arcade_sign", "kind": "convo", "title": "Painted-Over Sign", "verb": "Look", "pos": [9.0, 2.2, 7.7], "size": [3.0, 0.8, 0.4], "convo": "arcade_sign", "when": "q.mq_robot>=30"},
		{"id": "arcade_plan", "kind": "convo", "title": "The Plan Board", "verb": "Study", "pos": [15, 1.2, 2.2], "size": [2, 1.4, 0.5], "convo": "arcade_planboard", "when": "flag.joined_fsociety"},
	],
},
# ============================================================= SUBWAY (shared)
"subway": {
	"name": "Subway Platform", "amb": "subway", "ambient": Color(0.26, 0.26, 0.28),
	"rooms": [
		{"r": [0, 0, 26, 6], "h": 3.4, "wall": Color(0.3, 0.3, 0.32), "floor": Color(0.28, 0.27, 0.26), "floor_kind": "tile", "light": Color(0.7, 0.75, 0.7), "energy": 0.75, "lights": [[4, 3.0, 3], [13, 3.0, 3], [22, 3.0, 3]]},
	],
	"exits": [
		{"pos": [2, 0], "face": "n", "to": "world:subway", "label": "Street"},
		{"pos": [24, 0], "face": "n", "to": "world:subway", "label": "Street"},
	],
	"furn": [["bench", 6, 5.5, 0, {"w": 2.5}], ["bench", 13, 5.5, 0, {"w": 2.5}], ["bench", 20, 5.5, 0, {"w": 2.5}], ["turnstile", 13, 1.2, 0], ["vending", 3, 5.4, 0], ["poster", 9, 5.7, 0, {"col": Color(0.2, 0.4, 0.7)}], ["poster", 17, 5.7, 0, {"col": Color(0.5, 0.1, 0.1)}], ["trash", 22, 1, 0]],
	"spots": [{"id": "subway_travel", "kind": "subway_map", "title": "MTA Map", "verb": "Travel", "pos": [13, 1.4, 2.2], "size": [2, 2, 1.2]}],
},
# ============================================================ ANGELA'S APT
"angela_apt": {
	"name": "Angela's Apartment", "amb": "interior", "ambient": Color(0.32, 0.3, 0.3),
	"rooms": [{"r": [0, 0, 8, 6], "h": 2.9, "wall": Color(0.5, 0.46, 0.42), "floor": F_WOOD, "light": Color(0.95, 0.85, 0.7), "energy": 1.0, "lights": [[4, 2.6, 3]]}],
	"exits": [{"pos": [4, 6], "face": "s", "to": "world:d_angela", "label": "Street"}],
	"furn": [["bed_double", 1.8, 4.2, 0, {"col": Color(0.7, 0.7, 0.75)}], ["sofa", 6, 4.5, -90, {"col": Color(0.5, 0.5, 0.55)}], ["coffee_table", 6, 3, -90], ["desk_pc", 6.5, 1, 180], ["dresser", 0.7, 1.5, 90], ["tv", 3, 5.6, 180], ["bookshelf", 3.5, 0.4, 0], ["plant", 7.4, 5.4, 0], ["lamp", 0.6, 5.4, 0]],
	"containers": [{"id": "angela_dresser", "title": "Angela's Dresser", "pos": [0.9, 1.5], "y": 0.45, "size": [0.5, 0.9, 1.2], "loot": "wardrobe", "owner": "angela", "owner_ok": "trust.angela>=3", "items": {"business_suit": 1}}],
	"spots": [{"id": "angela_pc", "kind": "terminal", "title": "Angela's Laptop", "verb": "Snoop", "pos": [6.5, 1.2, 1.4], "size": [1, 1, 1], "hack": 30, "owner": "angela", "welcome": "Angela's desktop. This is a betrayal and you know it.", "entries": [{"title": "Read: E Corp application", "text": "She's applying to work at E Corp. The company that killed her mother. She thinks she can burn it down from inside. You'd know that feeling.", "fx": "set knows_angela_plan"}, {"title": "Read: lawsuit files", "text": "The Washington Township class action. Dead for years. Angela keeps every document like a wound she won't let close."}]}],
},
# =========================================================== RICKY'S (GUNS)
"sporting_goods": {
	"name": "Ricky's Sporting Goods", "amb": "interior", "ambient": Color(0.36, 0.34, 0.3),
	"rooms": [{"r": [0, 0, 11, 7], "h": 3.0, "wall": Color(0.34, 0.3, 0.24), "floor": F_WOOD, "light": Color(0.9, 0.85, 0.7), "energy": 1.0, "lights": [[3, 2.6, 3.5], [8, 2.6, 3.5]]}],
	"exits": [{"pos": [5.5, 7], "face": "s", "to": "world:d_guns", "label": "Street"}],
	"furn": [["counter", 8, 1.2, 0, {"w": 4}], ["register", 9, 1, 0], ["gun_rack", 3, 0.4, 0], ["gun_rack", 6, 0.4, 0], ["display_case", 3, 4, 0, {"w": 3}], ["display_case", 7, 4, 0, {"w": 3}], ["shelf", 0.6, 3, 90], ["shelf", 0.6, 5, 90], ["boxes", 10, 6, 0]],
	"spots": [{"id": "guns_shop", "kind": "shop", "title": "Ricky's Counter", "verb": "Shop", "pos": [8, 1, 2.2], "size": [4, 2, 1.2], "shop": "guns"}],
},
# ================================================================ PHARMACY
"pharmacy": {
	"name": "Pharmacy", "amb": "interior", "ambient": Color(0.4, 0.42, 0.44),
	"rooms": [{"r": [0, 0, 10, 7], "h": 3.0, "wall": Color(0.5, 0.52, 0.54), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.85, 0.9, 0.95), "energy": 1.1, "lights": [[3, 2.6, 3.5], [7, 2.6, 3.5]]}],
	"exits": [{"pos": [5, 7], "face": "s", "to": "world:d_pharmacy", "label": "Street"}],
	"furn": [["counter", 7.5, 1.2, 0, {"w": 4}], ["register", 8.5, 1, 0], ["shelf", 1, 3, 90], ["shelf", 1, 5, 90], ["shelf", 4, 6.4, 0], ["fridge_glass", 9.2, 4.5, -90]],
	"containers": [{"id": "pharm_cabinet", "title": "Pharmacy Cabinet", "pos": [8.5, 1.5], "y": 1.2, "size": [0.6, 0.6, 0.6], "lock": 50, "loot": "medcab", "owner": "locals", "owner_ok": "false", "items": {"meds": 2, "first_aid": 2}}],
	"spots": [{"id": "pharm_shop", "kind": "shop", "title": "Pharmacy Counter", "verb": "Shop", "pos": [7.5, 1, 2.2], "size": [4, 2, 1.2], "shop": "pharmacy"}],
},
# ================================================================ PAWN SHOP
"pawn_shop": {
	"name": "Pawn Shop", "amb": "interior", "ambient": Color(0.34, 0.3, 0.28),
	"rooms": [{"r": [0, 0, 9, 6], "h": 3.0, "wall": Color(0.32, 0.28, 0.24), "floor": F_WOOD, "light": Color(0.85, 0.75, 0.55), "energy": 0.95, "lights": [[4.5, 2.6, 3]]}],
	"exits": [{"pos": [4.5, 6], "face": "s", "to": "world:d_pawn", "label": "Street"}],
	"furn": [["counter", 6.5, 1.2, 0, {"w": 4}], ["register", 7.5, 1, 0], ["display_case", 2.5, 3.5, 0, {"w": 3}], ["display_case", 6, 3.5, 0, {"w": 2.5}], ["shelf", 0.6, 2.5, 90], ["gun_rack", 8.4, 3, -90]],
	"spots": [{"id": "pawn_shop", "kind": "shop", "title": "Pawn Counter", "verb": "Deal", "pos": [6.5, 1, 2.2], "size": [4, 2, 1.2], "shop": "pawn"}],
},
# ============================================================== DARLENE'S APT
"darlene_apt": {
	"name": "Darlene's Place", "amb": "interior", "ambient": Color(0.28, 0.26, 0.3),
	"rooms": [{"r": [0, 0, 7, 6], "h": 2.9, "wall": Color(0.34, 0.3, 0.34), "floor": F_WOOD, "light": Color(0.9, 0.6, 0.7), "energy": 0.9, "lights": [[3.5, 2.6, 3]]}],
	"exits": [{"pos": [3.5, 6], "face": "s", "to": "world:d_darlene", "label": "Street"}],
	"furn": [["mattress", 1.6, 4.5, 0], ["desk_pc", 5.5, 1, 180, {"screen": Color(0.9, 0.3, 0.5)}], ["monitor_wall", 6.6, 3.5, -90], ["sofa", 4.8, 3.4, -90, {"col": Color(0.3, 0.2, 0.3)}], ["boxes", 0.6, 1, 0], ["trash_pile", 6, 5.5, 0], ["poster", 3, 0.2, 0, {"col": Color(0.6, 0.1, 0.3)}]],
	"spots": [{"id": "darlene_photo", "kind": "convo", "title": "The Photograph", "verb": "Look", "pos": [3.0, 1.6, 0.3], "size": [1.2, 1.2, 0.6], "convo": "darlene_photo", "when": "q.mq_robot>=20"}],
	"containers": [{"id": "darlene_stash", "title": "Darlene's Gear", "pos": [0.6, 1], "y": 0.5, "size": [1.2, 0.9, 0.6], "loot": "crate", "owner": "darlene", "owner_ok": "trust.darlene>=2", "items": {"fsociety_mask": 1, "burner_phone": 2}}],
},
# ================================================================ RABBIT HOLE
"rabbit_hole": {
	"name": "The Rabbit Hole", "amb": "interior", "ambient": Color(0.2, 0.16, 0.2),
	"rooms": [{"r": [0, 0, 12, 8], "h": 3.2, "wall": Color(0.22, 0.12, 0.18), "floor": Color(0.14, 0.1, 0.12), "light": Color(1.0, 0.3, 0.6), "energy": 0.7, "lights": [[3, 2.8, 4], [9, 2.8, 4]]}],
	"exits": [{"pos": [6, 8], "face": "s", "to": "world:d_bar", "label": "Street"}],
	"furn": [["bar_counter", 9.5, 1.2, 0, {"w": 5, "neon": Color(1, 0.3, 0.7)}], ["bar_shelf", 9.5, 0.3, 0, {"w": 5}], ["stool", 7, 2.5, 0], ["stool", 8.5, 2.5, 0], ["stool", 10, 2.5, 0], ["booth", 2, 5.5, 0, {"col": Color(0.4, 0.06, 0.1)}], ["booth", 5, 5.5, 0, {"col": Color(0.1, 0.1, 0.3)}], ["pool_table", 3, 2.5, 0], ["jukebox", 11.4, 5, -90]],
	"spots": [{"id": "bar_shop", "kind": "shop", "title": "The Bar", "verb": "Order", "pos": [9.5, 1, 2.5], "size": [5, 2, 1.4], "shop": "bar"}, {"id": "bar_pool", "kind": "minigame", "title": "Pool Table", "verb": "Play", "pos": [3, 1.2, 2.5], "size": [1.6, 1, 2.6], "game": "signal"},
		{"id": "bar_router", "kind": "terminal", "title": "Bar Wi-Fi Router", "verb": "Connect", "pos": [11.6, 1.8, 0.5], "size": [0.6, 0.6, 0.5], "hack": 25, "header": "RabbitHole_GUEST  //  admin", "welcome": "Guest network. Eleven devices connected. One of them is called 'Lenny's iPhone', which tells you everything about Lenny.", "when": "q.sq_krista>=20",
			"entries": [{"title": "Sniff 'Lenny's iPhone'", "text": "His phone is backing up over the bar's Wi-Fi like he's never heard of encryption. Messages from 'Home': a wife in New Jersey, two kids, 'when are you back, we miss you.' Lenny: 'Late meeting, don't wait up.' Three other women get the same lines, copy-pasted. Krista is one browser tab of many.", "fx": "set has_lenny_phone ; quest sq_krista 30", "when": "!flag.has_lenny_phone"}]}],
},
# =============================================================== VERA'S STASH
"vera_stash": {
	"name": "Stash House", "amb": "interior", "ambient": Color(0.22, 0.2, 0.2), "restricted": "vera", "allowed_when": "flag.vera_door_open | flag.vera_deal",
	"rooms": [
		{"r": [0, 0, 9, 7], "h": 2.9, "wall": Color(0.24, 0.2, 0.18), "floor": F_CONCRETE, "light": Color(0.75, 0.55, 0.4), "energy": 0.75, "lights": [[4.5, 2.6, 3.5]]},
		{"r": [9, 0, 15, 7], "h": 2.9, "wall": Color(0.3, 0.24, 0.2), "floor": F_WOOD, "light": Color(0.95, 0.7, 0.45), "energy": 0.8, "lights": [[12, 2.6, 3.5]]},
		{"r": [0, -7, 15, 0], "h": 2.9, "wall": W_DARK, "floor": F_CONCRETE, "light": Color(0.9, 0.3, 0.3), "energy": 0.55, "lights": [[4, 2.6, -3.5], [11.5, 2.6, -3.5]]},
	],
	"doors": [[9, 4.5, 1.1], [3, 0, 1.1], [13.2, 0, 1.0]],
	"exits": [
		{"pos": [4.5, 7], "face": "s", "to": "world:d_vera", "label": "Front Door"},
		{"pos": [1.5, -7], "face": "n", "to": "world:d_vera_back", "label": "Alley Door"},
	],
	"furn": [
		["table", 4.5, 3.2, 0], ["chair", 3.5, 3.2, 90], ["chair", 5.5, 3.2, -90], ["tv", 4.5, 6.4, 180], ["sofa", 1.0, 4.5, 90, {"col": Color(0.3, 0.25, 0.2)}], ["boxes", 7.8, 1.0, 0], ["trash_pile", 7.6, 6.0, 0],
		["desk", 13.4, 5.6, -90], ["chair", 12.6, 5.6, 90], ["safe", 14.3, 1.0, -90], ["shelf_industrial", 10.0, 6.5, 180], ["lamp", 14.4, 6.5, 0],
		["cell_bars", 11.5, -4.2, 0, {"w": 4.6}], ["cell_bars", 9.2, -5.6, 90, {"w": 2.8}], ["cell_bars", 13.8, -5.6, 90, {"w": 2.8}], ["mattress", 11.5, -6.2, 0],
		["crate", 6.8, -3.6, 0], ["crate", 7.6, -4.6, 0], ["boxes", 1.0, -1.2, 0], ["shelf_industrial", 4.5, -6.5, 0], ["drums", 14.2, -1.0, 0],
	],
	"containers": [
		{"id": "vera_ledger_box", "title": "Vera's Safe", "pos": [14.3, 1.0], "y": 1.0, "size": [1.0, 1, 0.9], "lock": 60, "items": {"vera_ledger": 1, "cash": 0}, "cash": 400, "owner": "vera", "owner_ok": "flag.shayla_out"},
		{"id": "vera_crate", "title": "Crew Stash", "pos": [7.2, -4.1], "y": 0.6, "size": [1.8, 1.2, 1.6], "loot": "crate", "items": {"ammo_9mm": 18, "first_aid": 1, "stimpak_street": 1}, "owner": "vera", "owner_ok": "flag.shayla_freed"},
	],
	"spots": [{"id": "shayla_cell", "kind": "convo", "title": "The Cage", "verb": "Approach", "pos": [11.5, 1.2, -3.8], "size": [4.6, 2, 1.0], "convo": "shayla_rescue", "when": "q.sq_shayla>=30"}],
},
# ============================================================= FBI FIELD OFFICE
"fbi_office": {
	"name": "Federal Building — Cyber Division", "amb": "office", "ambient": Color(0.42, 0.44, 0.5), "restricted": "fbi", "allowed_when": "disguise.fbi | flag.fbi_contact | flag.fbi_invited",
	"rooms": [{"r": [0, 0, 16, 10], "h": 3.2, "wall": Color(0.46, 0.48, 0.54), "floor": F_CARPET, "floor_kind": "tile", "light": Color(0.8, 0.85, 0.95), "energy": 1.0, "lights": [[4, 2.9, 3], [12, 2.9, 3], [8, 2.9, 7]]}],
	"exits": [{"pos": [8, 10], "face": "s", "to": "world:d_fbi", "label": "Lobby"}],
	"furn": [["desk_pc", 3, 3, 90], ["desk_pc", 3, 6, 90], ["desk_pc", 13, 3, -90], ["desk_pc", 13, 6, -90], ["conference", 8, 6.5, 0], ["whiteboard", 8, 0.3, 0], ["server_rack", 15, 1, -90, {"led": Color(0.4, 0.6, 1)}], ["filing_cabinet", 0.6, 2, 90], ["filing_cabinet", 0.6, 3, 90], ["water_cooler", 15, 9, 180]],
	"containers": [{"id": "fbi_evidence", "title": "Evidence Locker", "pos": [0.7, 2.5], "y": 0.65, "size": [0.5, 1.3, 1.2], "lock": 65, "items": {"fbi_drive": 1}, "owner": "fbi", "owner_ok": "false", "fx_open": "set stole_fbi_file"}],
	"spots": [{"id": "fbi_term", "kind": "terminal", "title": "Case Terminal", "verb": "Access", "pos": [13, 1.2, 3], "size": [0.7, 1.4, 1], "hack": 60, "header": "cjis.fbi.gov — RESTRICTED", "welcome": "Agent DiPierro's working file. Your face is in here somewhere.", "entries": [{"title": "Read: fsociety case", "text": "They know about the arcade. They don't know about you. Yet. DiPierro is close — closer than fsociety thinks.", "fx": "set knows_fbi_close"}, {"title": "Read: informant list", "text": "Someone inside fsociety is talking to the FBI. The name is redacted. It could be anyone. It could be you, if you wanted."}]}],
},
# ============================================================== ROSE GARDEN
"rose_garden": {
	"name": "Rose Garden Tea House", "amb": "jazz", "ambient": Color(0.34, 0.24, 0.24),
	"rooms": [
		{"r": [0, 0, 10, 7], "h": 3.2, "wall": Color(0.4, 0.16, 0.16), "floor": F_WOOD, "light": Color(1.0, 0.5, 0.4), "energy": 0.9, "lights": [[3, 2.8, 3.5], [7, 2.8, 3.5]]},
		{"r": [10, 2, 15, 6], "h": 3.2, "wall": Color(0.3, 0.1, 0.12), "floor": Color(0.2, 0.08, 0.08), "light": Color(1.0, 0.75, 0.3), "energy": 0.8},
	],
	"doors": [[10, 4, 1.1]],
	"exits": [{"pos": [5, 7], "face": "s", "to": "world:d_rose", "label": "Street"}],
	"furn": [["tea_table", 2.5, 3, 0], ["tea_table", 2.5, 5, 0], ["tea_table", 6, 5, 0], ["counter", 8, 1, 0, {"w": 3, "col": Color(0.3, 0.1, 0.1)}], ["screen_fold", 5, 0.5, 0], ["lantern", 3, 0, 0, {"y": 2.6}], ["lantern", 7, 0, 0, {"y": 2.6}], ["grandfather_clock", 14.4, 3, -90], ["tea_table", 12.5, 4.5, 0], ["armchair", 12.5, 3, 0, {"col": Color(0.3, 0.08, 0.1)}]],
	"spots": [{"id": "rose_clock", "kind": "text", "title": "The Clocks", "verb": "Examine", "pos": [14, 1.2, 3], "size": [1, 2, 1], "text": "Dozens of clocks, all set to different times. All wrong. Or all right, somewhere. Time is the only currency she respects."}],
},
# =========================================================== DARK ARMY SAFEHOUSE
"darkarmy_safehouse": {
	"name": "Warehouse", "amb": "interior", "ambient": Color(0.2, 0.2, 0.22), "restricted": "darkarmy", "allowed_when": "q.mq_darkarmy>=20 | disguise.darkarmy",
	"rooms": [{"r": [0, 0, 14, 9], "h": 5.0, "wall": Color(0.24, 0.24, 0.26), "floor": F_CONCRETE, "light": Color(0.6, 0.7, 0.9), "energy": 0.7, "lights": [[4, 4.5, 4], [10, 4.5, 4]]}],
	"exits": [{"pos": [12, 9], "face": "s", "to": "world:d_da_safe", "label": "Out"}],
	"furn": [["table", 4, 4, 0, {"w": 3, "d": 2}], ["monitor_wall", 1, 4, 90], ["server_rack", 13, 2, -90, {"led": Color(0.9, 0.2, 0.2)}], ["server_rack", 13, 3.2, -90, {"led": Color(0.9, 0.2, 0.2)}], ["crate", 8, 7, 0], ["crate", 9.5, 7, 0], ["container_a", 10.5, 6, 0], ["boxes", 2, 7.5, 0]],
	"containers": [{"id": "da_crate", "title": "Dark Army Cache", "pos": [8, 7], "y": 0.5, "size": [1, 1, 1], "loot": "gun_crate", "items": {"carbine": 1, "darkarmy_jacket": 1}, "owner": "darkarmy", "owner_ok": "q.mq_darkarmy>=30"}],
},
# ============================================================ TYRELL PENTHOUSE
"tyrell_penthouse": {
	"name": "The Wellick Residence", "amb": "jazz", "ambient": Color(0.34, 0.36, 0.4),
	"rooms": [{"r": [0, 0, 14, 9], "h": 3.4, "wall": Color(0.3, 0.32, 0.38), "floor": Color(0.18, 0.16, 0.16), "floor_kind": "tile", "light": Color(0.7, 0.8, 1.0), "energy": 1.0, "lights": [[4, 3.1, 4], [10, 3.1, 4]]}],
	"exits": [{"pos": [7, 9], "face": "s", "to": "world:d_tyrell", "label": "Elevator"}],
	"furn": [["sofa", 3, 6, 180, {"col": Color(0.9, 0.9, 0.92)}], ["sofa", 5, 6, 180, {"col": Color(0.9, 0.9, 0.92)}], ["coffee_table", 4, 4.5, 0], ["piano", 11, 2, -90], ["bookshelf", 0.6, 3, 90], ["bookshelf", 0.6, 5, 90], ["desk", 12, 6.5, -90], ["window", 4, 0.15, 0, {"w": 3, "col": Color(0.3, 0.4, 0.6)}], ["window", 9, 0.15, 0, {"w": 3, "col": Color(0.3, 0.4, 0.6)}], ["plant", 13.4, 8, 0], ["lamp", 1, 8, 0]],
	"containers": [{"id": "tyrell_desk", "title": "Tyrell's Desk", "pos": [12, 6.5], "y": 0.6, "size": [0.7, 0.7, 1.4], "lock": 70, "items": {"tyrell_phone": 1}, "owner": "ecorp", "owner_ok": "trust.tyrell>=3", "fx_open": "set has_tyrell_phone"}],
	"spots": [{"id": "tyrell_pc", "kind": "terminal", "title": "Tyrell's Terminal", "verb": "Access", "pos": [12, 1.2, 6.5], "size": [1, 1.4, 1], "hack": 65, "owner": "ecorp", "welcome": "Tyrell Wellick's private machine. Ambition, logged.", "entries": [{"title": "Read: CTO campaign", "text": "He wants Scott Knowles' job. He'll do anything for it. That kind of hunger is a tool, if you hold the handle."}, {"title": "Read: the honeypot", "text": "Tyrell has been probing Allsafe himself. He left the CS30 door open. He's looking for fsociety — not to stop it. To join it."}]}],
},
# ============================================================== SALINA HOTEL
"salina_hotel": {
	"name": "The Salina — Room 6", "amb": "jazz", "ambient": Color(0.3, 0.26, 0.24),
	"rooms": [{"r": [0, 0, 10, 8], "h": 3.6, "wall": Color(0.36, 0.28, 0.22), "floor": F_WOOD, "light": Color(1.0, 0.7, 0.4), "energy": 0.85, "lights": [[5, 3.2, 4]]}],
	"exits": [{"pos": [7.5, 8], "face": "s", "to": "world:d_deus", "label": "Corridor"}],
	"furn": [["conference", 5, 4, 0], ["armchair", 5, 6.5, 180, {"col": Color(0.3, 0.1, 0.1)}], ["bar_shelf", 9.4, 2, -90, {"w": 3}], ["piano", 1, 6, 90], ["grandfather_clock", 9, 7.4, 0], ["lantern", 5, 0, 0, {"y": 3.0, "col": Color(1, 0.6, 0.2)}], ["window", 2.5, 0.15, 0, {"w": 2, "col": Color(0.2, 0.2, 0.3)}]],
	"spots": [{"id": "deus_table", "kind": "convo", "title": "The Round Table", "verb": "Sit", "pos": [5, 1.2, 4], "size": [4, 1.4, 1.4], "convo": "deus_group", "when": "q.mq_finale>=40"}],
},
# ============================================================== STEEL MOUNTAIN
"lenny_apt": {
	"name": "Lenny's Apartment", "amb": "interior", "ambient": Color(0.3, 0.27, 0.25),
	"rooms": [{"r": [0, 0, 7, 6], "h": 2.9, "wall": Color(0.4, 0.36, 0.32), "floor": F_WOOD, "light": Color(0.9, 0.8, 0.6), "energy": 0.9, "lights": [[3.5, 2.6, 3]]}],
	"exits": [{"pos": [3.5, 6], "face": "s", "to": "world:d_lenny", "label": "Hall"}],
	"furn": [["bed_double", 1.8, 4.4, 0], ["tv", 3.5, 3, 0], ["sofa", 6, 4.5, -90], ["dresser", 0.7, 1.3, 90], ["desk", 6.3, 1, 180], ["trash_pile", 6, 5.5, 0]],
	"containers": [{"id": "lenny_dresser", "title": "Lenny's Dresser", "pos": [0.9, 1.3], "y": 0.45, "size": [0.5, 0.9, 1.2], "loot": "wardrobe", "owner": "lenny", "owner_ok": "flag.lenny_gone"}],
	"spots": [{"id": "lenny_phone", "kind": "terminal", "title": "Lenny's Phone", "verb": "Crack", "pos": [6.3, 1.2, 1.4], "size": [1, 1, 1], "hack": 30, "owner": "lenny", "welcome": "Lenny's phone. Unlocked in about four seconds. His whole grubby life, sorted by contact.", "entries": [{"title": "Messages: 'Home'", "text": "A wife in New Jersey. Two kids. 'When are you back, we miss you.' Lenny replies: 'Late meeting, don't wait up.' Sent from a bar three blocks from Krista's office.", "fx": "set has_lenny_phone ; give lenny_phone 1 ; quest sq_krista 30"}, {"title": "Messages: others", "text": "Three other women. The same lines, copy-pasted, timestamped. Krista is a browser tab to this man. One of many, none of them closed."}]}],
},
"airfield_office": {
	"name": "Bowery Bay Airfield: Flight Office", "amb": "office", "ambient": Color(0.44, 0.44, 0.42),
	"rooms": [
		{"r": [0, 0, 14, 10], "h": 3.2, "wall": Color(0.6, 0.6, 0.55), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.95, 0.92, 0.82), "energy": 1.05, "lights": [[3.5, 2.9, 5], [10.5, 2.9, 5]]},
		{"r": [14, 0, 20, 10], "h": 3.0, "wall": W_CONCRETE, "floor": F_CONCRETE, "light": Color(0.9, 0.85, 0.7), "energy": 0.75},
	],
	"doors": [[14, 7.5, 1.2]],
	"exits": [{"pos": [0, 5], "face": "w", "to": "world:d_airfield", "label": "Street"}],
	"furn": [
		["counter", 4.5, 5.0, 90, {"w": 4.0}], ["bench", 1.0, 1.6, 90, {"w": 2.4}], ["plant", 0.7, 9.2, 0], ["poster", 0.15, 8.0, 90, {"col": Color(0.2, 0.45, 0.8)}],
		["desk_pc", 9.0, 2.2, 0], ["chair", 9.0, 3.1, 180], ["whiteboard", 7.0, 0.15, 0], ["filing_cabinet", 13.4, 1.0, -90], ["filing_cabinet", 13.4, 2.1, -90],
		["coffee_machine", 13.5, 8.6, -90], ["water_cooler", 11.0, 9.5, 180], ["window", 13.9, 5.0, -90, {"w": 3.0}], ["poster", 10.0, 9.85, 180, {"col": Color(0.8, 0.5, 0.1)}],
		["shelf_industrial", 17.0, 0.6, 0], ["boxes", 19.2, 1.0, 0], ["drums", 19.0, 8.6, 0], ["shelf_industrial", 15.0, 9.3, 180],
	],
	"containers": [{"id": "airfield_parts", "title": "Parts Shelf", "pos": [17.0, 0.6], "y": 1.0, "size": [2.0, 2.0, 0.6], "items": {"toolkit": 1, "soda": 2}, "cash": 0, "owner": "gus", "owner_ok": "flag.pilot_license"}],
},
"laundromat": {
	"name": "Suds City Laundromat", "amb": "interior", "ambient": Color(0.4, 0.44, 0.42),
	"rooms": [
		{"r": [0, 0, 10, 12], "h": 3.2, "wall": Color(0.6, 0.7, 0.66), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.85, 0.95, 0.9), "energy": 1.15, "lights": [[3, 2.9, 3], [7, 2.9, 3], [3, 2.9, 9], [7, 2.9, 9]]},
		{"r": [10, 0, 14, 6], "h": 3.0, "wall": W_PLASTER, "floor": F_CONCRETE, "light": Color(0.95, 0.85, 0.65), "energy": 0.7},
	],
	"doors": [[10, 3, 1.1]],
	"exits": [{"pos": [5, 12], "face": "s", "to": "world:d_laundro", "label": "Street"}],
	"furn": [
		["washer", 0.45, 5.5, 90, {"n": 6}], ["washer", 9.55, 8.0, -90, {"n": 4}], ["washer", 5.0, 0.45, 0, {"n": 5}], ["table", 5.0, 6.0, 0, {"w": 2.4, "d": 1.0}],
		["bench", 7.5, 11.2, 180, {"w": 2.4}], ["vending", 1.0, 11.3, 180], ["poster", 9.85, 3.0, -90, {"col": Color(0.2, 0.5, 0.8)}], ["plant", 9.3, 11.3, 0],
		["desk", 12.0, 5.3, 180], ["chair", 12.0, 4.4, 0], ["boxes", 13.2, 0.8, 0], ["safe", 13.3, 3.0, -90],
	],
	"containers": [{"id": "laundro_safe", "title": "Owner's Safe", "pos": [13.3, 3.0], "y": 0.5, "size": [0.8, 1.0, 0.8], "lock": 45, "cash": 260, "items": {"cash": 0, "watch": 1}, "owner": "locals", "owner_ok": "false"}],
},
"precinct": {
	"name": "7th Precinct", "amb": "office", "ambient": Color(0.4, 0.42, 0.44),
	"rooms": [
		{"r": [0, 0, 12, 8], "h": 3.4, "wall": Color(0.52, 0.55, 0.52), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.85, 0.9, 0.95), "energy": 1.1, "lights": [[3, 3.1, 4], [9, 3.1, 4]]},
		{"r": [12, -4, 26, 8], "h": 3.4, "wall": Color(0.46, 0.48, 0.5), "floor": F_CARPET, "floor_kind": "tile", "light": Color(0.85, 0.88, 0.92), "energy": 1.0, "lights": [[15, 3.1, 0], [22, 3.1, 0], [18.5, 3.1, 5]]},
		{"r": [26, 0, 32, 6], "h": 3.0, "wall": W_CONCRETE, "floor": F_CONCRETE, "light": Color(0.7, 0.72, 0.6), "energy": 0.7},
	],
	"doors": [[12, 4, 1.4], [26, 3, 1.2]],
	"exits": [{"pos": [6, 8], "face": "s", "to": "world:d_precinct", "label": "Out"}],
	"furn": [
		["reception", 6, 1.6, 0, {"col": Color(0.3, 0.3, 0.34), "glow": Color(0.4, 0.6, 1.0)}], ["bench", 2, 6.8, 0, {"w": 3}], ["bench", 10, 6.8, 0, {"w": 3}], ["plant", 0.8, 0.8, 0], ["poster", 0.15, 4, 90, {"col": Color(0.1, 0.2, 0.5)}], ["water_cooler", 11.4, 7.2, 180],
		["desk_pc", 14.5, -1.5, 180], ["desk_pc", 17.5, -1.5, 180], ["desk_pc", 14.5, 3.0, 0], ["desk_pc", 21.0, 2.0, -90], ["whiteboard", 18.5, -3.85, 0], ["filing_cabinet", 25.4, -2.5, -90], ["filing_cabinet", 25.4, -1.4, -90], ["cell_bars", 23.0, 6.0, 0, {"w": 4}], ["bench", 23.0, 7.4, 0, {"w": 3}], ["coffee_machine", 12.6, 7.2, 90],
		["shelf_industrial", 28.0, 0.5, 0], ["shelf_industrial", 30.5, 0.5, 0], ["boxes", 31.2, 5.0, 0], ["safe", 27.0, 5.3, 180],
	],
	"containers": [{"id": "precinct_evidence", "title": "Evidence Lockers", "pos": [29.2, 0.6], "y": 1.0, "size": [4.0, 2.0, 0.7], "lock": 50, "loot": "gun_crate", "items": {"cash": 0, "pistol_45": 1, "ammo_45": 14, "jewelry": 2}, "cash": 340, "owner": "nypd", "owner_ok": "false"}],
	"spots": [
		{"id": "precinct_board", "kind": "convo", "title": "Lopez's Case Board", "verb": "Study", "pos": [18.5, 1.6, -3.6], "size": [3.0, 1.6, 0.6], "convo": "lopez_board", "when": "q.sq_lopez>=10"},
		{"id": "precinct_sticky", "kind": "convo", "title": "Sticky Note", "verb": "Read", "pos": [21.0, 1.0, 2.0], "size": [1.0, 0.8, 1.2], "convo": "precinct_sticky"},
		{"id": "precinct_term", "kind": "terminal", "title": "NYPD Case Management", "verb": "Log in", "pos": [14.5, 1.2, -1.2], "size": [1.2, 1.4, 1.0], "hack": 45, "password_flag": "precinct_pw", "header": "NYPD DOMAIN  //  7TH PRECINCT  //  AUTHORIZED USERS ONLY", "welcome": "CaseTrack 4.1. 212 open cases. Someone has been eating at this keyboard.",
			"entries": [
				{"title": "CASE 15-0419  'Stairwell Pattern'  (Det. M. Lopez)", "text": "Victims with nothing in common, found within a mile of each other over a few weeks. Lopez's notes are careful and angry. PERSON OF INTEREST: ALDERSON, ELLIOT. 'Always nearby. Never nervous. Never anything.' She's attached a photo of you buying coffee.", "when": "q.sq_lopez>=10"},
				{"title": "Open warrants (Lower East Side)", "text": "Muggings, a stolen van, a string of bodega robberies, and a note flagged by Narcotics: 'new supplier moving cut product up in the Bronx, street name Candyman. Kids are dying. Nobody will talk.'"},
				{"title": "Memo: E Corp liaison", "text": "'All cyber incidents involving E Corp assets are to be referred to E Corp Security and the FBI. Do not open local files.' Signed by a deputy commissioner who owns a lot of E Corp stock."},
			],
			"actions": [
				{"title": "Erase 'People v. Vera' (Narcotics, pending trial)", "result": "Arrest report, lab results, two witness statements, the chain of custody. Gone, backups and all. In six weeks a judge will ask for a file that never existed. A man who sells pills to kids walks out of a courthouse a free man, and the only fingerprints on it are yours.", "fx": "set vera_case_wiped ; stab -3 ; xp 40", "when": "flag.vera_deal & !flag.vera_case_wiped"},
				{"title": "Delete Lopez's case file (and the backups)", "result": "Gone. The file, the photos, the backup on the shared drive. Lopez will know someone did it. She will never be able to prove who.", "fx": "set lopez_case_gone ; quest sq_lopez done ; stab -2 ; xp 40", "when": "q.sq_lopez>=10 & !q.sq_lopez.done"},
				{"title": "Rewrite the file so it points at someone else", "result": "You pick a two-time felon who lives on the right blocks and rewrite the timeline around him. Every detail fits now. Somebody else is going to pay for what you did, and the case will be closed with a ribbon on it.", "fx": "set lopez_case_gone ; set lopez_framed ; quest sq_lopez done ; stab -8 ; xp 40", "when": "q.sq_lopez>=10 & !q.sq_lopez.done"},
			]},
	],
},
"relay_roof": {
	"name": "Relay Building — Roof Machine Room", "amb": "interior", "ambient": Color(0.3, 0.32, 0.36),
	"rooms": [{"r": [0, 0, 12, 10], "h": 4.0, "wall": W_CONCRETE, "floor": F_CONCRETE, "light": Color(0.75, 0.8, 0.95), "energy": 0.85, "lights": [[3, 3.7, 5], [9, 3.7, 5]]}],
	"exits": [{"pos": [6, 10], "face": "s", "to": "world:d_relay", "label": "Stairwell"}],
	"furn": [
		["server_rack", 2.0, 0.6, 0, {"led": Color(0.9, 0.2, 0.2)}], ["server_rack", 3.2, 0.6, 0, {"led": Color(0.9, 0.5, 0.2)}], ["ac_unit", 9.5, 1.0, 0], ["ac_unit", 9.5, 8.6, 180],
		["boxes", 11.0, 5.0, -90], ["window", 6.0, 0.15, 0, {"w": 3.0, "col": Color(0.2, 0.25, 0.4)}], ["poster", 0.15, 6.0, 90, {"col": Color(0.9, 0.2, 0.3)}], ["chair", 3.0, 2.8, 180], ["table", 3.0, 3.6, 0, {"w": 1.4, "d": 0.7}],
	],
	"spots": [{"id": "relay_pirate", "kind": "terminal", "title": "Pirate Relay", "verb": "Hijack", "pos": [3.0, 1.2, 3.6], "size": [1.4, 1.2, 0.9], "hack": 40, "password_flag": "relay_password", "welcome": "The old pirate relay. A patchwork of scanners, a car battery, and an antenna bolted to the roof above you. Locked, but not to you.", "entries": [{"title": "Broadcast the busker's track", "text": "You push the mixtape onto the citywide pirate frequency. Somewhere, ten thousand speakers crackle to life with something true and unpaid-for.", "fx": "set pirate_radio ; set pirate_radio_known ; quest sq_busker 20"}]}],
},
"old_theater": {
	"name": "Paramount Theater", "amb": "interior", "ambient": Color(0.28, 0.2, 0.18),
	"rooms": [
		{"r": [0, 0, 16, 6], "h": 4.0, "wall": Color(0.45, 0.18, 0.14), "floor": F_CARPET, "light": Color(1.0, 0.75, 0.45), "energy": 0.8, "lights": [[4, 3.7, 3], [12, 3.7, 3]]},
		{"r": [0, -18, 16, 0], "h": 8.0, "wall": Color(0.48, 0.2, 0.15), "floor": F_WOOD, "light": Color(1.0, 0.75, 0.5), "energy": 1.25, "lights": [[4, 7.5, -5], [12, 7.5, -5], [4, 7.5, -13], [12, 7.5, -13]]},
	],
	"doors": [[4, 0, 1.6], [12, 0, 1.6]],
	"exits": [{"pos": [8, 6], "face": "s", "to": "world:d_theater", "label": "Street"}],
	"furn": [
		["counter", 8.0, 1.2, 0, {"w": 5.0, "col": Color(0.4, 0.1, 0.1)}], ["poster", 0.15, 3.0, 90, {"col": Color(0.9, 0.7, 0.2)}], ["poster", 15.85, 3.0, -90, {"col": Color(0.2, 0.3, 0.8)}], ["plant", 0.8, 5.2, 0], ["plant", 15.2, 5.2, 0], ["rug", 8.0, 4.0, 0],
		["seats", 8.0, -10.0, 0, {"rows": 5, "cols": 14}], ["stage", 8.0, -15.8, 0, {"w": 14, "d": 4}], ["piano", 2.0, -15.5, 90], ["curtain", 8.0, -17.8, 0, {"w": 14}],
	],
	"containers": [{"id": "theater_booth", "title": "Ticket Booth Drawer", "pos": [8.0, 1.2], "y": 0.9, "size": [5.0, 0.4, 0.8], "loot": "desk", "cash": 35}],
},
"mercy_general": {
	"name": "Mercy General — Emergency", "amb": "office", "ambient": Color(0.44, 0.46, 0.48),
	"rooms": [
		{"r": [0, 0, 16, 8], "h": 3.4, "wall": Color(0.7, 0.74, 0.74), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.9, 0.95, 1.0), "energy": 1.25, "lights": [[4, 3.1, 4], [12, 3.1, 4]]},
		{"r": [0, -10, 16, 0], "h": 3.2, "wall": Color(0.62, 0.72, 0.72), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.85, 0.95, 1.0), "energy": 1.1, "lights": [[4, 2.9, -5], [12, 2.9, -5]]},
	],
	"doors": [[8, 0, 1.8]],
	"exits": [{"pos": [8, 8], "face": "s", "to": "world:d_hospital", "label": "Ambulance Bay"}],
	"furn": [
		["reception", 8.0, 1.8, 0, {"col": Color(0.8, 0.82, 0.84), "glow": Color(1.0, 0.3, 0.3)}], ["bench", 2.5, 5.5, 0, {"w": 3.0}], ["bench", 2.5, 7.3, 180, {"w": 3.0}], ["bench", 13.5, 5.5, 0, {"w": 3.0}], ["vending", 15.3, 1.0, -90], ["water_cooler", 0.7, 1.0, 90], ["plant", 15.3, 7.3, 0],
		["hospital_bed", 2.0, -7.5, 0], ["hospital_bed", 5.5, -7.5, 0], ["hospital_bed", 9.0, -7.5, 0], ["hospital_bed", 12.5, -7.5, 0], ["curtain", 3.75, -7.5, 90, {"w": 2.4}], ["curtain", 7.25, -7.5, 90, {"w": 2.4}], ["curtain", 10.75, -7.5, 90, {"w": 2.4}],
		["counter", 13.5, -2.0, 0, {"w": 4.0, "col": Color(0.85, 0.87, 0.9)}], ["shelf", 13.5, -0.4, 180],
	],
	"spots": [{"id": "hosp_records", "kind": "terminal", "title": "Records Terminal", "verb": "Access", "pos": [1.0, 1.2, -2.0], "size": [1.0, 1.4, 1.0], "hack": 40, "password_flag": "mercy_pw", "header": "MERCY GENERAL  //  PATIENT RECORDS  //  ARCHIVE 1985-2010", "welcome": "Medical records, scanned from paper in 2009 by somebody who clearly hated scanning. Search: ALDERSON.", "when": "q.mq_robot>=40",
			"entries": [
				{"title": "ALDERSON, EDWARD  (adm. 1993)", "text": "Acute myeloid leukemia. Home address: Washington Township, NJ. Occupation: owner, 'Mr. Robot Computer Repair,' Coney Island. Nurse's note, in pen, scanned crooked: 'Pt wears an old army jacket over his gown, won't let us take it. Son (8) refuses to leave the room. Daughter (4) asleep in the chair.' Deceased, January 1994."},
				{"title": "ALDERSON, ELLIOT  (pediatric psych, 1994-2002)", "text": "Referred after the death of his father. Patient presents as withdrawn, highly intelligent, with long gaps in memory. From 1996: patient describes a companion 'who sounds like Dad' and 'does the things I can't.' Note, 2002: 'Elliot reports the companion has gone. I do not believe it has gone. I believe it has learned to be quiet.'", "fx": "quest mq_robot 50 ; stab -3"},
				{"title": "Discharge note (2002), handwritten", "text": "'He asked me today if a person can be haunted by someone who is still inside them. I said I didn't know. I should have said yes.' The next document in the file is a records request from Krista Gordon, LCSW. Dated last year."},
			]},
		{"id": "hosp_shop", "kind": "shop", "title": "Hospital Pharmacy", "verb": "Buy", "pos": [13.5, 1.0, -2.0], "size": [4.0, 1.6, 1.2], "shop": "pharmacy"}],
},
"ecorp_credit": {
	"name": "E Corp Consumer Credit — Branch 0419", "amb": "office", "ambient": Color(0.4, 0.42, 0.48),
	"rooms": [
		{"r": [0, 0, 14, 9], "h": 3.6, "wall": Color(0.82, 0.84, 0.88), "floor": Color(0.3, 0.32, 0.38), "floor_kind": "tile", "light": Color(0.85, 0.9, 1.0), "energy": 1.2, "lights": [[3.5, 3.3, 4.5], [10.5, 3.3, 4.5]]},
		{"r": [14, 0, 20, 9], "h": 3.2, "wall": Color(0.6, 0.62, 0.66), "floor": F_CARPET, "light": Color(0.9, 0.9, 0.95), "energy": 0.9},
	],
	"doors": [[14, 7.0, 1.1]],
	"exits": [{"pos": [7, 9], "face": "s", "to": "world:d_credit", "label": "Street"}],
	"furn": [
		["logo_wall", 7.0, 0.15, 0, {"w": 6.0, "glow": Color(0.4, 0.6, 1.0)}], ["counter", 4.0, 2.4, 0, {"w": 4.0, "col": Color(0.2, 0.22, 0.3)}], ["counter", 10.0, 2.4, 0, {"w": 4.0, "col": Color(0.2, 0.22, 0.3)}],
		["bench", 3.0, 7.8, 180, {"w": 3.0}], ["bench", 11.0, 7.8, 180, {"w": 3.0}], ["plant", 0.8, 8.3, 0], ["plant", 13.2, 8.3, 0], ["poster", 0.15, 5.0, 90, {"col": Color(0.2, 0.4, 0.9)}],
		["desk_pc", 17.0, 1.0, 0], ["filing_cabinet", 19.4, 3.0, -90], ["filing_cabinet", 19.4, 4.1, -90], ["safe", 19.3, 8.2, -90],
	],
	"containers": [{"id": "credit_files", "title": "Delinquent Accounts", "pos": [19.4, 3.5], "y": 0.7, "size": [0.6, 1.4, 2.2], "loot": "desk", "items": {"credit_card": 2}, "owner": "ecorp", "owner_ok": "false"}],
	"spots": [
		{"id": "credit_term", "kind": "text", "title": "Debt Kiosk", "verb": "Read", "pos": [7.0, 1.2, 5.0], "size": [1.0, 2.0, 1.0], "text": "'CHECK YOUR ECOIN CREDIT SCORE.' A number, cheerfully red, that decides whether strangers get to eat. You could delete it. Soon, maybe, you will."},
		{"id": "credit_gary", "kind": "text", "title": "Teller Station 2", "verb": "Search", "pos": [10.0, 1.1, 2.4], "size": [1.6, 0.8, 1.0], "text": "A framed certificate: 'TOP RECOVERY AGENT, Q3 — GARY'. A stress ball shaped like a house. And under the keyboard, because it is always under the keyboard, a sticky note: 'mgr pc - recoveries#1'. Gary is winning at everything except security.", "fx": "set credit_pw"},
		{"id": "credit_mgr", "kind": "terminal", "title": "Branch Manager's PC", "verb": "Use", "pos": [17.0, 1.1, 1.0], "size": [1.4, 1.2, 0.9], "hack": 35, "password_flag": "credit_pw", "header": "E CORP CONSUMER CREDIT  //  BRANCH 0419", "welcome": "Collections dashboard. A leaderboard of employees ranked by 'recoveries'. Someone named Gary is winning.",
			"entries": [{"title": "Collections: top 10 delinquent accounts", "text": "Ten families, ten numbers. A widow in Astoria three months behind on a loan for her husband's funeral. A Greek diner in Astoria being 'restructured' into bankruptcy. A shelter in Harlem whose line of credit was frozen the week after its counselor complained to the press. The notes field on every one says the same thing: 'Escalate.'"}],
			"actions": [
				{"title": "Poison tonight's E Coin key batch", "result": "The batch signs forty thousand wallets for the city's first day. Every one of them now carries a signature that will fail validation in about six hours, in front of the cameras. It will look like a bug. It will look like E Corp can't run its own money.", "fx": "set ecoin_broken ; set after_done ; fame fsociety 6 ; infamy ecorp 6 ; quest mq_after 40 ; quest mq_after done ; quest mq_finale 40 ; give deus_invite 1 ; xp 200", "when": "flag.after_path=sabotage & !flag.after_done"},
				{"title": "Copy the E Coin rollout plan (Price's internal deck)", "result": "Forty slides. Slide 9: 'The crisis is the onboarding.' Slide 14: projected household dependency by quarter. Slide 31 is a photo of Price shaking hands with a woman in a red coat. You copy all of it.", "fx": "give ecoin_plan 1 ; xp 60", "when": "flag.after_path=press & !item.ecoin_plan | flag.after_path=fbi & !item.ecoin_plan"},
				{"title": "Find HECTOR ORTIZ (deceased) and close the account", "when": "q.sq_ortiz>=20 & !flag.ortiz_done", "result": "ORTIZ, HECTOR. Deceased, 04/11. Balance: $11,240. Notes, from Gary: 'Widow resists. Escalate: mention the apartment.' You set the status to DISCHARGED - ESTATE INSOLVENT, which is what it should have been the day he died, and delete the call schedule. Somewhere in a queue, six calls a day stop being made.", "fx": "set ortiz_done ; set ortiz_hacked ; quest sq_ortiz 30 ; fame locals 2 ; xp 80"},
				{"title": "Mark all ten accounts 'settled in full'", "result": "Ten records change color from red to green. The system will catch it in a month, maybe two. For a month, maybe two, ten families will open letters that say THANK YOU instead of FINAL NOTICE.", "fx": "set credit_forgiven ; fame locals 4 ; fame harlem 3 ; infamy ecorp 3 ; stab 4 ; xp 40", "when": "!flag.credit_forgiven"}]},
	],
},
"pier9_warehouse": {
	"name": "Pier 9 Warehouse", "amb": "interior", "ambient": Color(0.28, 0.28, 0.3),
	"rooms": [
		{"r": [0, 0, 24, 14], "h": 7.0, "wall": Color(0.46, 0.44, 0.4), "floor": F_CONCRETE, "light": Color(0.9, 0.9, 0.8), "energy": 1.15, "lights": [[6, 6.6, 4], [18, 6.6, 4], [6, 6.6, 10], [18, 6.6, 10]]},
		{"r": [24, 4, 30, 10], "h": 3.0, "wall": W_PLASTER, "floor": F_CONCRETE, "light": Color(0.95, 0.85, 0.6), "energy": 0.7},
	],
	"doors": [[24, 7, 1.2]],
	"exits": [{"pos": [12, 14], "face": "s", "to": "world:d_pier9", "label": "Pier"}],
	"furn": [
		["container_a", 5.0, 2.0, 0], ["container_b", 5.0, 5.0, 0], ["container_b", 19.0, 2.0, 0], ["shelf_industrial", 12.0, 0.6, 0], ["shelf_industrial", 14.5, 0.6, 0],
		["crate", 11.0, 6.0, 0], ["crate", 12.2, 6.0, 0], ["crate", 11.6, 7.1, 0], ["drums", 21.5, 12.8, 180], ["boxes", 2.0, 12.5, 0], ["boxes", 17.0, 9.0, 0],
		["desk", 27.0, 9.3, 180], ["chair", 27.0, 8.4, 0], ["filing_cabinet", 29.4, 5.0, -90], ["poster", 24.15, 5.0, 90, {"col": Color(0.9, 0.8, 0.5)}],
	],
	"containers": [
		{"id": "pier9_crate", "title": "Unmarked Crate", "pos": [11.6, 6.5], "y": 0.6, "size": [2.4, 1.2, 2.2], "loot": "crate", "items": {"ammo_9mm": 20, "scrap_electronics": 2}, "lock": 30},
		{"id": "pier9_desk", "title": "Foreman's Desk", "pos": [27.0, 9.3], "y": 0.7, "size": [1.4, 0.6, 0.7], "loot": "desk", "cash": 80},
	],
},
"trenton_home": {
	"name": "The Sharifi Home", "amb": "interior", "ambient": Color(0.38, 0.32, 0.26),
	"rooms": [
		{"r": [0, 0, 8, 7], "h": 2.8, "wall": Color(0.7, 0.6, 0.45), "floor": F_WOOD, "light": Color(1.0, 0.85, 0.6), "energy": 0.95, "lights": [[4, 2.5, 3.5]]},
		{"r": [8, 0, 12, 7], "h": 2.8, "wall": Color(0.75, 0.72, 0.6), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.95, 0.9, 0.75), "energy": 0.9},
		{"r": [0, -5, 6, 0], "h": 2.8, "wall": Color(0.55, 0.6, 0.7), "floor": F_CARPET, "light": Color(0.9, 0.85, 0.8), "energy": 0.7},
	],
	"doors": [[8, 3.5, 1.2], [3, 0, 1.0]],
	"exits": [{"pos": [4, 7], "face": "s", "to": "world:d_trenton", "label": "Street"}],
	"furn": [
		["sofa", 2.5, 5.8, 180, {"col": Color(0.5, 0.2, 0.15)}], ["tv", 2.5, 3.0, 0], ["rug", 2.5, 4.4, 0, {"col": Color(0.6, 0.15, 0.1)}], ["bookshelf", 0.4, 2.0, 90], ["plant", 7.4, 6.4, 0], ["poster", 7.85, 2.0, -90, {"col": Color(0.3, 0.5, 0.3)}],
		["kitchen", 10.0, 6.5, 180, {"w": 3.5}], ["table", 10.0, 3.0, 0], ["chair", 9.2, 3.0, 90], ["chair", 10.8, 3.0, -90], ["fridge", 11.5, 0.6, 0],
		["bed", 1.5, -2.5, 90], ["desk_pc", 4.5, -4.4, 0], ["dresser", 5.4, -1.0, -90],
	],
},
"steel_mountain": {
	"name": "Steel Mountain", "amb": "interior", "ambient": Color(0.4, 0.42, 0.46), "restricted": "ecorp", "allowed_when": "disguise.steel | flag.steel_badge_used | flag.harper_tour",
	"rooms": [
		{"r": [0, 0, 12, 8], "h": 3.4, "wall": W_CONCRETE, "floor": F_TILE, "floor_kind": "tile", "light": Color(0.8, 0.85, 0.9), "energy": 1.0, "lights": [[3, 3.1, 4], [9, 3.1, 4]]},
		{"r": [12, 2, 18, 7], "h": 3.4, "wall": Color(0.5, 0.5, 0.52), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.75, 0.8, 0.85), "energy": 0.9},
		{"r": [18, 1, 26, 8], "h": 4.0, "wall": Color(0.4, 0.42, 0.44), "floor": F_CONCRETE, "light": Color(0.5, 0.9, 0.6), "energy": 0.8, "lights": [[22, 3.6, 4.5]]},
	],
	"doors": [[12, 4.5, 1.2], [18, 4.5, 1.2]],
	"exits": [{"pos": [6, 8], "face": "s", "to": "world:d_steel", "label": "Lobby"}],
	"furn": [
		["reception", 6, 1.5, 0, {"col": Color(0.4, 0.42, 0.45), "glow": Color(0.6, 0.8, 1)}], ["security_desk", 3, 5, 0], ["metal_detector", 9, 5, 0], ["locker_row", 15, 6.5, 0, {"n": 5}], ["bench", 15, 3, 0, {"w": 3}], ["tape_library", 22, 1.5, 0], ["tape_library", 25.6, 4, -90], ["climate_unit", 20, 7, 180], ["server_rack", 24, 7, 180, {"led": Color(0.5, 0.9, 0.6)}],
	],
	"containers": [{"id": "steel_lockers", "title": "Employee Lockers", "pos": [15, 6.5], "y": 0.95, "size": [2.5, 1.9, 0.5], "loot": "guard_locker", "owner": "ecorp", "owner_ok": "disguise.steel"}],
	"spots": [
		{"id": "steel_desk", "kind": "convo", "title": "Security Desk", "verb": "Check in", "pos": [3, 1.2, 5], "size": [2, 2, 1.5], "convo": "steel_desk", "when": "flag.harper_tour & !flag.steel_checked_in"},
		{"id": "steel_climate", "kind": "convo", "title": "Climate Control Unit", "verb": "Rig", "pos": [20, 1.2, 7], "size": [1.8, 2, 1], "convo": "steel_climate", "when": "item.raspberry_pi>=1"},
	],
},
# ============================================ CARVER HOUSES, BUILDING C (Bronx)
"carver_c": {
	"name": "Carver Houses — Building C", "amb": "interior", "ambient": Color(0.3, 0.27, 0.24), "restricted": "candyman", "allowed_when": "flag.candy_invited | flag.kingpin | flag.candy_resolved",
	"rooms": [
		{"r": [0, 0, 12, 8], "h": 3.2, "wall": Color(0.5, 0.46, 0.4), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.95, 0.9, 0.7), "energy": 0.8, "lights": [[3, 2.9, 4], [9, 2.9, 4]]},
		{"r": [0, -12, 12, 0], "h": 3.0, "wall": Color(0.42, 0.4, 0.36), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.9, 0.85, 0.6), "energy": 0.55, "lights": [[6, 2.7, -3], [6, 2.7, -9]]},
		{"r": [12, -12, 24, 0], "h": 2.9, "wall": W_PLASTER, "floor": F_WOOD, "light": Color(1.0, 0.72, 0.5), "energy": 0.75, "lights": [[16, 2.6, -4], [21, 2.6, -9]]},
	],
	"doors": [[6, 0, 1.6], [12, -6, 1.2]],
	"exits": [{"pos": [6, 8], "face": "s", "to": "world:d_carver", "label": "Courtyard"}],
	"furn": [
		["mailbox", 11.85, 3.0, -90], ["mailbox", 11.85, 5.0, -90], ["elevator", 2.5, 0.2, 0], ["poster", 0.15, 5, 90, {"col": Color(0.9, 0.9, 0.3)}], ["trash_pile", 1.0, 7.0, 0], ["stairs_up", 10.0, 1.4, 0],
		["radiator", 0.3, -4, 90], ["poster", 0.15, -8, 90, {"col": Color(0.2, 0.2, 0.6)}], ["trash_pile", 11.0, -11.0, 0], ["boxes", 1.0, -11.0, 0],
		["lab_bench", 17.0, -3.0, 0], ["chair", 16.0, -1.8, 180], ["chair", 18.0, -1.8, 180], ["sofa", 15.0, -10.6, 0, {"col": Color(0.3, 0.12, 0.1)}], ["tv", 15.0, -8.0, 180], ["safe", 23.4, -6.0, -90],
		["desk_pc", 21.0, -11.2, 0, {"screen": Color(0.6, 0.3, 0.9)}], ["crate", 13.0, -11.0, 0], ["boxes", 23.0, -1.0, 0], ["window", 18.0, -11.85, 0, {"w": 1.6, "col": Color(0.08, 0.1, 0.16)}],
	],
	"containers": [
		{"id": "candy_safe", "title": "Candyman's Safe", "pos": [23.4, -6.0], "y": 0.5, "size": [0.8, 1.0, 0.8], "lock": 60, "items": {"cash_bundle": 3, "jewelry": 2, "magnum": 1, "ammo_44": 18}, "cash": 1400, "owner": "candyman", "owner_ok": "dead.candyman | flag.kingpin | flag.candy_resolved", "fx_open": "set candy_robbed"},
		{"id": "candy_table", "title": "Cutting Table", "pos": [17.0, -3.0], "y": 0.9, "size": [2.0, 0.5, 0.9], "items": {"candy_product": 2}, "owner": "candyman", "owner_ok": "dead.candyman | flag.kingpin | flag.candy_resolved", "fx_open": "set took_candy_sample"},
	],
	"spots": [
		{"id": "candy_laptop", "kind": "terminal", "title": "Candyman's Laptop", "verb": "Use", "pos": [21.0, 1.1, -11.0], "size": [1.2, 1.2, 0.9], "hack": 40, "password_flag": "candy_pw", "header": "SWEETNESS  //  don't touch my shit", "welcome": "A gaming laptop with a cracked screen and four hundred unread messages. Somebody here does accounting, badly.",
			"entries": [
				{"title": "ledger_FINAL_final.xls", "text": "Corners, days, takings, names. Nine corners around the Carver Houses. And a column labelled CUT with a supplier code next to it, rising every week. He's stretching the product with something cheaper and much, much stronger. The dates line up with the funerals.", "fx": "give candy_ledger 1 ; set candy_evidence ; quest sq_candyman 30"},
				{"title": "supplier.txt", "text": "'Unit 9, Terminal Market, Hunts Point. Cook Tue/Fri. Bring the cut from the pier guy.' The pier guy works the Red Hook containers, the ones the Rose Garden people run. Candyman buys his raw product from the Dark Army's shipping side, and he's been skimming them.", "fx": "set knows_candy_lab ; set candy_skims_da"},
				{"title": "msgs: Mama", "text": "'Darnell baby you coming sunday? Your sister's boy asks about you.' He never answers her. Four hundred unread. His mother is one of them."},
			],
			"actions": [
				{"title": "Forge proof of his skimming and send it to his suppliers", "result": "You tidy his ledger into a confession: every short shipment, every skim, dated and totalled, and send it from his own account to the number marked PIER. Two days later Darnell 'Candyman' Pryce stops answering anyone. Nobody asks where he went. The corners go quiet for a week, and then somebody new starts asking who's in charge.", "fx": "set candy_framed ; set candy_resolved ; move candyman ; quest sq_candyman 40 ; stab -4 ; fame darkarmy 2", "when": "flag.candy_skims_da & !flag.candy_resolved"},
			]},
		{"id": "candy_notebook", "kind": "convo", "title": "Notebook by the TV", "verb": "Read", "pos": [15.0, 0.9, -7.6], "size": [0.8, 0.6, 0.6], "convo": "candy_notebook"},
	],
},
# ======================================== TERMINAL MARKET, UNIT 9 (Hunts Point)
"hunts_lab": {
	"name": "Terminal Market — Unit 9", "amb": "interior", "ambient": Color(0.26, 0.28, 0.24), "restricted": "candyman", "allowed_when": "flag.kingpin | flag.candy_resolved",
	"rooms": [
		{"r": [0, 0, 22, 14], "h": 6.0, "wall": W_CONCRETE, "floor": F_CONCRETE, "light": Color(0.8, 0.95, 0.75), "energy": 1.05, "lights": [[5, 5.5, 4], [16, 5.5, 4], [5, 5.5, 10], [16, 5.5, 10]]},
		{"r": [22, 4, 28, 10], "h": 3.0, "wall": Color(0.4, 0.4, 0.38), "floor": F_CONCRETE, "light": Color(0.95, 0.85, 0.6), "energy": 0.7},
	],
	"doors": [[22, 7, 1.2]],
	"exits": [{"pos": [0, 7], "face": "w", "to": "world:d_hunts_lab", "label": "Loading Dock"}],
	"furn": [
		["lab_bench", 8.0, 4.0, 0], ["lab_bench", 8.0, 10.0, 0], ["lab_bench", 14.0, 7.0, 90], ["drums", 20.5, 1.0, 0], ["drums", 20.5, 13.0, 180], ["drums", 3.0, 13.0, 180],
		["shelf_industrial", 12.0, 0.6, 0], ["crate", 18.0, 3.0, 0], ["crate", 18.0, 11.0, 0], ["climate_unit", 2.0, 1.0, 0], ["mattress", 25.0, 9.0, 0], ["table", 25.0, 5.5, 0], ["chair", 24.0, 5.5, 90],
	],
	"containers": [{"id": "lab_cash", "title": "Cash Box", "pos": [25.0, 5.5], "y": 0.85, "size": [0.6, 0.4, 0.5], "lock": 45, "items": {"candy_product": 3}, "cash": 900, "owner": "candyman", "owner_ok": "flag.candy_lab_burned | dead.candyman | flag.kingpin"}],
	"spots": [{"id": "lab_burn", "kind": "convo", "title": "The Cook", "verb": "Examine", "pos": [11.0, 1.2, 7.0], "size": [9.0, 1.6, 8.0], "convo": "candy_lab", "when": "q.sq_candyman>=20 & !flag.candy_lab_burned"}],
},
# ============================================== ST. NICHOLAS YOUTH SHELTER (Harlem)
"st_nicholas": {
	"name": "St. Nicholas Youth Shelter", "amb": "interior", "ambient": Color(0.4, 0.36, 0.3),
	"rooms": [
		{"r": [0, 0, 16, 10], "h": 4.5, "wall": Color(0.62, 0.56, 0.46), "floor": F_WOOD, "light": Color(1.0, 0.88, 0.7), "energy": 1.0, "lights": [[4, 4.1, 5], [12, 4.1, 5]]},
		{"r": [16, 0, 24, 5], "h": 3.0, "wall": W_PLASTER, "floor": F_CARPET, "light": Color(0.95, 0.9, 0.8), "energy": 0.9},
		{"r": [16, 5, 24, 10], "h": 3.0, "wall": Color(0.5, 0.55, 0.6), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.85, 0.9, 1.0), "energy": 0.8},
	],
	"doors": [[16, 2.5, 1.2], [16, 7.5, 1.2]],
	"exits": [{"pos": [8, 10], "face": "s", "to": "world:d_shelter", "label": "Street"}],
	"furn": [
		["altar", 8.0, 0.8, 0], ["table", 4.5, 5.0, 0, {"w": 3.0}], ["table", 11.5, 5.0, 0, {"w": 3.0}], ["bench", 4.5, 4.0, 0, {"w": 3.0}], ["bench", 4.5, 6.0, 180, {"w": 3.0}], ["bench", 11.5, 4.0, 0, {"w": 3.0}], ["bench", 11.5, 6.0, 180, {"w": 3.0}],
		["kitchen", 3.0, 9.5, 180, {"w": 4.0}], ["plant", 15.2, 9.2, 0], ["poster", 0.15, 3.0, 90, {"col": Color(0.2, 0.5, 0.3)}], ["piano", 14.5, 1.2, 180],
		["desk_pc", 20.0, 0.9, 0], ["filing_cabinet", 23.4, 1.0, -90], ["whiteboard", 23.85, 3.0, -90], ["chair", 19.0, 3.2, 0],
		["bed", 17.2, 6.5, 90], ["bed", 17.2, 9.0, 90], ["bed", 22.8, 6.5, -90], ["bed", 22.8, 9.0, -90], ["dresser", 20.0, 9.6, 180],
	],
	"spots": [
		{"id": "shelter_phone", "kind": "terminal", "title": "The Phone Ms. Okafor Confiscated", "verb": "Look", "pos": [20.6, 1.0, 1.1], "size": [0.6, 0.6, 0.6], "hack": 20, "when": "q.sq_badco>=10", "header": "LOCKED  //  4-digit PIN", "welcome": "A cheap new smartphone, the kind you buy a kid to keep him talking to you. One contact saved: 'Coach R'.",
			"entries": [
				{"title": "Messages: 'Coach R'", "text": "Three weeks of messages. You read just enough to see the shape of it and then you stop, because the shape is enough: a grown man making a fourteen-year-old feel chosen. Gifts. Praise. Promises about a tryout. And again and again, some version of 'this is just between us.' That line is the whole playbook. You don't need to read the rest to know how it ends.", "fx": "set badco_phone"},
				{"title": "Settings > Account recovery", "text": "The phone's account was set up with a recovery email: r.keller.coach@... And the purchase receipt in the cloud account shows a card in the name of Richard Keller, with a billing address on Ditmars Boulevard, Astoria. He didn't even use a fake name. Men like him rarely think they'll be looked at.", "fx": "set knows_keller ; quest sq_badco 20"},
			]},
	],
},
# ======================================================= 31-14 DITMARS BLVD (Astoria)
"keller_apt": {
	"name": "Richard Keller's Apartment", "amb": "interior", "ambient": Color(0.32, 0.3, 0.28),
	"rooms": [
		{"r": [0, 0, 10, 8], "h": 2.8, "wall": Color(0.6, 0.58, 0.52), "floor": F_WOOD, "light": Color(1.0, 0.9, 0.75), "energy": 0.85, "lights": [[5, 2.5, 4]]},
		{"r": [10, 0, 16, 8], "h": 2.8, "wall": Color(0.5, 0.52, 0.55), "floor": F_CARPET, "light": Color(0.8, 0.85, 0.95), "energy": 0.6},
	],
	"doors": [[10, 4, 1.2]],
	"exits": [{"pos": [5, 8], "face": "s", "to": "world:d_keller", "label": "Stoop"}],
	"furn": [
		["sofa", 3.0, 6.6, 180, {"col": Color(0.35, 0.3, 0.26)}], ["tv", 3.0, 3.6, 0], ["rug", 3.0, 5.0, 0], ["trophies", 0.3, 3.0, 90], ["bookshelf", 7.5, 0.4, 0], ["duffel", 8.8, 6.8, 0], ["kitchen", 7.8, 7.5, 180, {"w": 3.0}],
		["desk_pc", 14.0, 0.9, 0, {"screen": Color(0.3, 0.5, 0.8)}], ["chair", 14.0, 2.0, 180], ["bed", 13.5, 6.4, 90], ["wardrobe", 15.4, 3.4, -90], ["poster", 10.15, 6.5, 90, {"col": Color(0.1, 0.4, 0.2)}],
	],
	"spots": [
		{"id": "keller_bag", "kind": "convo", "title": "Coach's Kit Bag", "verb": "Search", "pos": [8.8, 0.5, 6.8], "size": [1.0, 0.8, 0.7], "convo": "keller_bag"},
		{"id": "keller_pc", "kind": "terminal", "title": "Keller's Computer", "verb": "Use", "pos": [14.0, 1.1, 0.9], "size": [1.4, 1.2, 0.9], "hack": 40, "password_flag": "keller_pw", "when": "q.sq_badco>=20", "header": "rkeller-desktop", "welcome": "A clean desktop. A wallpaper of a youth soccer team, arms around each other, grinning. You look at the faces for exactly one second and then you look away.",
			"entries": [
				{"title": "~/Documents/", "text": "Folders named with first names and ages. You do not open them. You don't need to, and you won't. You copy the directory listing, the chat account records and the payment logs to a drive, and your hands don't stop shaking until you're finished. It's enough to put him away for the rest of his life.", "fx": "give keller_drive 1 ; set keller_evidence ; quest sq_badco 30"},
				{"title": "Calendar", "text": "Saturday, 4 PM: 'J  -  Astoria Park, by the pool. Don't be late, champ.' That's Jaylen. That's the day after tomorrow.", "fx": "set keller_meeting"},
				{"title": "Email: league roster", "text": "Coach of the under-15s at Ditmars Youth Soccer for eleven years. A mailing list of two hundred parents. A thank-you card scanned from last season, signed by the whole team."},
			],
			"actions": [
				{"title": "Send everything to every parent on the league mailing list", "result": "Two hundred parents get the directory listing and the payment logs at 9:14 PM. By 9:40 there are people on the stoop. By ten Keller is gone out the back with a gym bag, and the evidence is all over the internet, which is exactly where a defense lawyer wants it. He'll never coach again. He may never see a courtroom either.", "fx": "set keller_exposed ; set keller_resolved ; set keller_gone ; quest sq_badco 40 ; fame harlem 3 ; stab -1", "when": "flag.keller_evidence & !flag.keller_resolved"},
			]},
	],
},
# ======================================================== WORLD TRADE CENTER
# ======================================================= THE INTERSTATE (I-80)
"hw_diner": {
	"name": "Big Rig Diner", "amb": "jazz", "ambient": Color(0.42, 0.36, 0.3),
	"rooms": [{"r": [0, 0, 14, 8], "h": 3.2, "wall": Color(0.75, 0.72, 0.62), "floor": Color(0.7, 0.68, 0.64), "floor_kind": "tile", "light": Color(1.0, 0.92, 0.75), "energy": 1.2, "lights": [[4, 2.9, 4], [10, 2.9, 4]]}],
	"exits": [{"pos": [7, 8], "face": "s", "to": "world:d_hw_diner", "label": "Parking Lot"}],
	"furn": [["bar_counter", 7, 1.4, 0, {"w": 8.0, "neon": Color(1.0, 0.3, 0.3)}], ["stool", 4.5, 2.6, 0], ["stool", 6, 2.6, 0], ["stool", 7.5, 2.6, 0], ["stool", 9, 2.6, 0], ["booth", 2, 6.2, 0, {"col": Color(0.7, 0.1, 0.1)}], ["booth", 6, 6.2, 0, {"col": Color(0.7, 0.1, 0.1)}], ["booth", 10, 6.2, 0, {"col": Color(0.7, 0.1, 0.1)}], ["jukebox", 13.4, 4, -90], ["coffee_machine", 10.5, 0.6, 0], ["window", 7, 7.85, 180, {"w": 8.0}]],
	"spots": [{"id": "hw_diner_shop", "kind": "shop", "title": "Counter", "verb": "Order", "pos": [7, 1, 2.4], "size": [8, 2, 1.2], "shop": "gen_diner"}],
},
"hw_gas": {
	"name": "Gas · Food · Live Bait", "amb": "office", "ambient": Color(0.42, 0.42, 0.4),
	"rooms": [{"r": [0, 0, 10, 8], "h": 3.0, "wall": Color(0.82, 0.82, 0.78), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.9, 0.95, 1.0), "energy": 1.25, "lights": [[5, 2.7, 4]]}],
	"exits": [{"pos": [5, 8], "face": "s", "to": "world:d_hw_gas", "label": "Pumps"}],
	"furn": [["counter", 7.5, 1.4, 0, {"w": 3.5}], ["register", 8, 1.2, 0], ["shelf", 1, 2.5, 90], ["shelf", 1, 5, 90], ["shelf", 4.5, 6.6, 0], ["fridge_glass", 9.2, 5, -90], ["coffee_machine", 5.5, 0.6, 0]],
	"spots": [{"id": "hw_gas_shop", "kind": "shop", "title": "Counter", "verb": "Shop", "pos": [7.5, 1, 2.4], "size": [3.5, 2, 1.2], "shop": "gen_grocery"}],
},
"hw_motel": {
	"name": "Lennox Motor Inn — Room 9", "amb": "interior", "ambient": Color(0.34, 0.3, 0.27),
	"rooms": [{"r": [0, 0, 7, 6], "h": 2.7, "wall": Color(0.55, 0.48, 0.36), "floor": F_CARPET, "light": Color(1.0, 0.82, 0.6), "energy": 0.9, "lights": [[3.5, 2.4, 3]]}],
	"exits": [{"pos": [3.5, 6], "face": "s", "to": "world:d_hw_motel", "label": "Parking Lot"}],
	"furn": [["bed_double", 2.0, 2.0, 0, {"col": Color(0.55, 0.35, 0.3)}], ["tv", 5.6, 2.0, -90], ["dresser", 6.3, 4.5, -90], ["lamp", 0.6, 0.6, 0], ["window", 3.5, 5.85, 180, {"w": 1.6}]],
	"spots": [{"id": "hw_motel_guest", "kind": "text", "title": "Guest Book", "verb": "Read", "pos": [6.3, 1.0, 4.5], "size": [0.8, 0.6, 1.0], "text": "Lennox Motor Inn, est. 1961. Three hundred pages of truckers, runaways and salesmen. 'Room 9 has a ghost. He's nice.' 'Room 9 has bedbugs. They're not.' And on the last page, this morning's date, in handwriting you recognise because it's yours: 'Keep driving. — E.' You don't remember writing it.", "fx": "set room9_read"},
		{"id": "hw_motel_bed", "kind": "bed", "title": "Motel Bed", "verb": "Sleep", "pos": [2.0, 0.6, 2.0], "size": [1.8, 1, 2.2]}],
},
"hw_pharmacy": {
	"name": "Lennox Pharmacy", "amb": "office", "ambient": Color(0.44, 0.46, 0.44),
	"rooms": [{"r": [0, 0, 10, 8], "h": 3.0, "wall": Color(0.86, 0.88, 0.84), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.92, 1.0, 0.95), "energy": 1.25, "lights": [[5, 2.7, 4]]}],
	"exits": [{"pos": [5, 8], "face": "s", "to": "world:d_hw_pharmacy", "label": "Main Street"}],
	"furn": [["counter", 5, 1.6, 0, {"w": 5.0}], ["register", 6.5, 1.5, 0], ["shelf", 0.6, 3, 90], ["shelf", 0.6, 5.5, 90], ["shelf", 9.4, 3, -90], ["shelf", 9.4, 5.5, -90], ["fridge_glass", 8.4, 0.6, 0], ["poster", 5, 0.12, 0, {"col": Color(0.3, 0.75, 0.45)}], ["plant", 1, 7.4, 0], ["bench", 5, 6.8, 0, {"w": 2.4}]],
	"spots": [
		{"id": "hw_pharm_shop", "kind": "shop", "title": "Pharmacy Counter", "verb": "Shop", "pos": [5, 1, 2.4], "size": [5, 2, 1.0], "shop": "lennox_pharmacy"},
		{"id": "hw_pharm_board", "kind": "text", "title": "Community Board", "verb": "Read", "pos": [0.2, 1.5, 1.5], "size": [0.3, 1.0, 1.4], "text": "Lost cat (orange, answers to Mortgage). Choir practice Thursdays. A flyer from E Corp Health: 'Your prescriptions, now by subscription!' Someone has written underneath, in very neat pharmacist's handwriting: 'No.'"},
	],
},
# ============================================================= CHICAGO
"chi_diner": {
	"name": "Lou's Red Hots", "amb": "jazz", "ambient": Color(0.42, 0.34, 0.28),
	"rooms": [{"r": [0, 0, 12, 8], "h": 3.2, "wall": Color(0.6, 0.18, 0.14), "floor": Color(0.85, 0.85, 0.8), "floor_kind": "tile", "light": Color(1.0, 0.85, 0.65), "energy": 1.15, "lights": [[3, 2.9, 4], [9, 2.9, 4]]}],
	"exits": [{"pos": [6, 8], "face": "s", "to": "world:d_chi_diner", "label": "Street"}],
	"furn": [["bar_counter", 6, 1.3, 0, {"w": 7.0, "neon": Color(1.0, 0.85, 0.2)}], ["stool", 3.5, 2.5, 0], ["stool", 5, 2.5, 0], ["stool", 6.5, 2.5, 0], ["stool", 8, 2.5, 0], ["cafe_table", 2, 6, 0], ["cafe_table", 6, 6, 0], ["cafe_table", 10, 6, 0], ["poster", 0.15, 4, 90, {"col": Color(0.9, 0.7, 0.1)}]],
	"spots": [{"id": "chi_diner_shop", "kind": "shop", "title": "Counter", "verb": "Order", "pos": [6, 1, 2.3], "size": [7, 2, 1.2], "shop": "gen_diner"},
		{"id": "lou_tablet", "kind": "text", "title": "Lou's Tablet", "verb": "Read", "pos": [8, 1.3, 1.4], "size": [0.6, 0.4, 0.5], "when": "q.sq_lou>=10", "text": "EZeats reviews, newest first. 'Hair in the hot dog. Called police.' 'Worst food I've ever eaten, and I'm from Gary.' 'Owner yelled at my kid.' Two hundred and six of them in three weeks, all one star, all from accounts made the same night. Lou doesn't have a kid-yelling bone in his body. You tap one and check the metadata. Same IP block, every time: a residential line at the Skyway Motel. Room 14.", "fx": "set lou_traced ; quest sq_lou 20"}],
},
"chi_safe": {
	"name": "fsociety Chicago — the Warehouse", "amb": "interior", "ambient": Color(0.26, 0.26, 0.28),
	"rooms": [{"r": [0, 0, 16, 10], "h": 5.0, "wall": W_CONCRETE, "floor": F_CONCRETE, "light": Color(0.5, 0.9, 0.6), "energy": 0.8, "lights": [[4, 4.5, 5], [12, 4.5, 5]]}],
	"exits": [{"pos": [8, 10], "face": "s", "to": "world:d_chi_safe", "label": "Street"}],
	"furn": [["table", 8, 4, 0, {"w": 3.5, "d": 1.8}], ["monitor_wall", 15.6, 5, -90], ["server_rack", 15.4, 1.2, -90, {"led": Color(0.3, 1.0, 0.4)}], ["mattress", 2, 8.4, 0], ["mattress", 4.6, 8.4, 0], ["crate", 1.2, 1.2, 0], ["boxes", 13, 9, 0], ["whiteboard", 8, 0.2, 0], ["chair", 7, 3, 0], ["chair", 9, 3, 0]],
	"containers": [{"id": "chi_safe_stash", "title": "fsociety Stash", "pos": [1.2, 1.2], "y": 0.5, "size": [1.0, 1.0, 1.0], "items": {"first_aid": 2, "ammo_9mm": 30, "usb_drive": 2}, "owner_ok": "true"}],
	"spots": [{"id": "chi_safe_bed", "kind": "bed", "title": "Mattress", "verb": "Sleep", "pos": [2, 0.4, 8.4], "size": [1.8, 0.8, 2.2]}],
},
"chi_motel": {
	"name": "Skyway Motel — Room 14", "amb": "interior", "ambient": Color(0.32, 0.3, 0.3),
	"rooms": [{"r": [0, 0, 7, 6], "h": 2.7, "wall": Color(0.45, 0.5, 0.5), "floor": F_CARPET, "light": Color(0.9, 0.85, 0.75), "energy": 0.85, "lights": [[3.5, 2.4, 3]]}],
	"exits": [{"pos": [3.5, 0], "face": "n", "to": "world:d_chi_motel", "label": "Parking Lot"}],
	"furn": [["bed_double", 2.2, 3.6, 0, {"col": Color(0.3, 0.4, 0.5)}], ["tv", 5.8, 3.6, -90], ["dresser", 6.3, 1.4, -90], ["lamp", 0.6, 5.4, 0], ["table", 4.6, 5.3, 0, {"w": 2.4, "d": 0.9}], ["desk_pc", 5.0, 5.3, 180], ["boxes", 1.0, 1.0, 0], ["chair", 4.6, 4.5, 180]],
	"spots": [
		{"id": "review_farm", "kind": "terminal", "title": "Review Farm Laptop", "verb": "Use", "pos": [5.0, 1.0, 5.2], "size": [1.0, 0.8, 0.8], "hack": 35, "password_flag": "trevor_pw", "when": "q.sq_lou>=20", "header": "starsforhire.local  //  CLIENT: EZEATS GROWTH TEAM", "welcome": "Forty phones on a folding table, each with a name, a face from a stock photo, and a history of eating at restaurants that don't exist.",
			"entries": [
				{"title": "Client brief: 'Restaurant Retention'", "text": "From an EZeats address: 'Partners who leave the platform should experience the market reality of not being on it. 200 reviews over 21 days. Tone: authentic disappointment. Include one allegation of rudeness to a child.' Invoice: $1,400. Paid."},
				{"title": "The other clients", "text": "Forty-one restaurants in Chicago. Every one of them quit EZeats in the last year. Every one of them is now a one-star restaurant. Six have closed."},
			],
			"actions": [
				{"title": "Delete every fake review and post the client brief where Lou's customers will see it", "when": "!flag.lou_done", "result": "Two hundred and six reviews vanish from Lou's page, and the forty other restaurants' too. In their place, pinned, the EZeats brief: 'Include one allegation of rudeness to a child.' Chicago's food press has it by dinner. EZeats calls it 'a rogue vendor.' It has never used the word 'rogue' about a vendor before.", "fx": "set lou_done ; set lou_truth ; quest sq_lou 40 ; fame locals 4 ; xp 120"},
				{"title": "Point all forty phones at EZeats itself", "when": "!flag.lou_done", "result": "By morning the EZeats app has eleven thousand new one-star reviews in every app store on Earth, each one written in the same voice of authentic disappointment Trevor perfected on Lou. 'Hair in the app.' 'Called police.' It drops out of the top 100. Lou's old rating stays wrecked, but the thing that wrecked it is on fire.", "fx": "set lou_done ; set ezeats_bombed ; quest sq_lou 40 ; infamy ecorp 2 ; xp 110"},
			]},
		{"id": "chi_motel_bed", "kind": "bed", "title": "Motel Bed", "verb": "Sleep", "pos": [2.2, 0.6, 3.6], "size": [1.8, 1, 2.2]}],
},
"chi_fbi": {
	"name": "Federal Plaza — Chicago Field Office", "amb": "office", "ambient": Color(0.42, 0.44, 0.5),
	"rooms": [{"r": [0, 0, 16, 10], "h": 3.4, "wall": Color(0.5, 0.52, 0.56), "floor": F_CARPET, "floor_kind": "tile", "light": Color(0.85, 0.9, 1.0), "energy": 1.05, "lights": [[4, 3.1, 5], [12, 3.1, 5]]}],
	"exits": [{"pos": [8, 10], "face": "s", "to": "world:d_chi_fbi", "label": "Plaza"}],
	"furn": [["reception", 8, 2, 0, {"col": Color(0.3, 0.32, 0.38), "glow": Color(0.6, 0.75, 1.0)}], ["bench", 2.5, 8.5, 0, {"w": 3.0}], ["bench", 13.5, 8.5, 0, {"w": 3.0}], ["plant", 0.8, 0.8, 0], ["plant", 15.2, 0.8, 0], ["logo_wall", 8, 0.15, 0, {"w": 5.0, "glow": Color(0.6, 0.75, 1.0)}], ["desk_pc", 13.0, 1.2, 0], ["filing_cabinet", 15.4, 2.0, -90], ["whiteboard", 11.0, 0.15, 0]],
	"spots": [
		{"id": "kowal_board", "kind": "text", "title": "Case Board", "verb": "Read", "pos": [11.0, 1.6, 0.3], "size": [2.0, 1.2, 0.3], "when": "q.sq_kowal>=10", "text": "CHI-2291. E CORP MIDWEST / 'SURPRISE MECHANICS' / PHONY ACCOUNT AUTHORITY. Red string from a lobby camera still (hoodie, face down) to a gas station receipt in Lennox, PA, to a printout of a Respawn forum thread. In the corner, in blue marker: 'NY connection? Call Dom.' She's good. She's closer than anyone in New York got in a month."},
		{"id": "kowal_pc", "kind": "terminal", "title": "Agent's Workstation", "verb": "Use", "pos": [13.0, 1.1, 1.2], "size": [1.4, 1.2, 0.9], "hack": 50, "when": "q.sq_kowal>=20", "header": "FBI CHICAGO // CYBER // CASE MGMT", "welcome": "Logged in as T. KOWALCZYK. Seventeen open cases. One of them has your face in it.",
			"entries": [
				{"title": "CHI-2291: E Corp Midwest intrusion", "text": "'Subject accessed the data floor during business hours, apparently by walking in. E Corp declines to share what was altered, citing trade secrets, which tells me what was altered. Subject is likely linked to the NY fsociety investigation (DiPierro). Recommend joint task force.' Attached: the lobby still. The hood. The angle of the jaw."},
				{"title": "Personal note", "text": "A draft email to DiPierro, never sent: 'Dom. My son's game got its odds printed on the box last week. He read them out loud at dinner, 1 in 9,214, and laughed, and deleted it. I've been doing this nineteen years and I'm not sure who the victim is in this one.'"},
			],
			"actions": [
				{"title": "Delete CHI-2291 and its backups", "when": "!flag.kowal_done", "result": "The case is gone from the server, from the nightly backup, from the joint task force queue that hadn't been created yet. The lobby still is gone. Somewhere a red string is pinned to nothing.", "fx": "set kowal_done ; set kowal_deleted ; quest sq_kowal 30 ; infamy fbi 3 ; xp 120"},
				{"title": "Rewrite the file to point at E Corp: the case becomes 'consumer fraud by the victim'", "when": "!flag.kowal_done", "result": "The subject is now 'unknown, possibly internal.' The victim is now 'under review for deceptive practices.' Every document E Corp refused to share is now listed as 'withheld evidence.' By Monday it's a different investigation, and E Corp is the one being investigated.", "fx": "set kowal_done ; set kowal_flipped ; quest sq_kowal 30 ; infamy ecorp 4 ; xp 140"},
			]},
		{"id": "chi_fbi_board", "kind": "text", "title": "Bulletin Board", "verb": "Read", "pos": [2.5, 1.5, 0.3], "size": [2.0, 1.2, 0.3], "text": "Wanted posters, a softball sign-up sheet, and a printout from New York with a grainy still of a man in a hoodie: 'POSSIBLE FSOCIETY ASSOCIATE — ASSIST NY FIELD OFFICE (DIPIERRO).' Someone has drawn a tiny mask on him in ballpoint. It's not a bad likeness."},
		{"id": "chi_fbi_memo", "kind": "text", "title": "Memo on the Desk", "verb": "Read", "pos": [8.0, 1.1, 2.0], "size": [1.4, 0.6, 0.8], "when": "flag.earse_exposed", "text": "'RE: E CORP MIDWEST INCIDENT. Victim (E Corp) declines to share loot-box drop tables with investigators, citing trade secrets. Note: victim is refusing to show the FBI the evidence of the crime committed against it, because the evidence is the crime. Recommend low priority.' Initialed by someone who is clearly enjoying this."},
		{"id": "chi_fbi_memo2", "kind": "text", "title": "Memo on the Desk", "verb": "Read", "pos": [8.0, 1.1, 2.0], "size": [1.4, 0.6, 0.8], "when": "!flag.earse_exposed", "text": "Visitor log, a coffee ring, and a sticky note: 'E Corp Midwest security asked again for a permanent agent in their lobby. Told them we're the FBI, not mall cops. They said they'd call the Director. They will.'"},
	],
},
"chi_hangar": {
	"name": "Meigs Field — Hangar Office", "amb": "office", "ambient": Color(0.44, 0.44, 0.42),
	"rooms": [{"r": [0, 0, 12, 8], "h": 3.2, "wall": Color(0.6, 0.6, 0.56), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.95, 0.92, 0.82), "energy": 1.05, "lights": [[6, 2.9, 4]]}],
	"exits": [{"pos": [6, 8], "face": "s", "to": "world:d_chi_hangar", "label": "Apron"}],
	"furn": [["counter", 6, 1.4, 0, {"w": 4.0}], ["desk_pc", 2, 2, 90], ["bench", 10, 6.5, -90, {"w": 2.4}], ["poster", 11.85, 3, -90, {"col": Color(0.2, 0.45, 0.8)}], ["coffee_machine", 11.4, 0.6, 0]],
	"spots": [
		{"id": "chi_hangar_log", "kind": "text", "title": "Flight Log", "verb": "Read", "pos": [6.0, 1.1, 1.4], "size": [1.6, 0.6, 0.8], "text": "Meigs Field. Tie-downs on the apron, fuel on the honor system, and a logbook where pilots write whatever they want. 'N172BB from Bowery Bay, Queens — thanks for the coffee, Chicago. Gus says hi.' Below it, in a different hand: 'Who is Gus.' Below that: 'Everyone knows Gus.'"},
		{"id": "chi_hangar_pc", "kind": "text", "title": "Weather Terminal", "verb": "Check", "pos": [2.0, 1.1, 2.0], "size": [1.0, 1.0, 1.0], "text": "Winds off the lake, fifteen gusting twenty-five. Ceiling two thousand. East to New York: about four hours in a Skyhawk, longer if you stop to think about what you're doing. Fly the plane out past the edge of the map and keep going."},
	],
},
"chi_node": {
	"name": "E Corp Midwest — Lobby and Data Floor", "amb": "office", "ambient": Color(0.4, 0.42, 0.48), "restricted": "ecorp", "allowed_when": "disguise.ecorp | day & !flag.chi_alarm",
	"rooms": [
		{"r": [0, 0, 18, 10], "h": 5.0, "wall": Color(0.28, 0.32, 0.4), "floor": Color(0.15, 0.16, 0.2), "floor_kind": "tile", "light": Color(0.5, 0.6, 1.0), "energy": 1.1, "lights": [[5, 4.6, 5], [13, 4.6, 5]]},
		{"r": [18, 0, 34, 14], "h": 4.0, "wall": W_DARK, "floor": F_CONCRETE, "light": Color(0.5, 0.7, 1.0), "energy": 0.8, "lights": [[22, 3.6, 4], [30, 3.6, 4], [22, 3.6, 10], [30, 3.6, 10]]},
	],
	"doors": [[18, 5, 1.4]],
	"exits": [{"pos": [9, 0], "face": "n", "to": "world:d_chi_node", "label": "Plaza"}],
	"furn": [["reception", 9, 3, 180, {"col": Color(0.15, 0.18, 0.25), "glow": Color(0.4, 0.6, 1.0)}], ["logo_wall", 9, 9.85, 180, {"w": 7.0, "glow": Color(0.4, 0.6, 1.0)}], ["metal_detector", 5, 6, 0], ["metal_detector", 13, 6, 0], ["security_desk", 15, 3, 0], ["plant", 1, 9, 0], ["plant", 17, 9, 0],
		["server_rack", 21, 2, 0, {"led": Color(0.4, 0.6, 1.0)}], ["server_rack", 23, 2, 0, {"led": Color(0.4, 0.6, 1.0)}], ["server_rack", 25, 2, 0, {"led": Color(0.4, 0.6, 1.0)}], ["server_rack", 27, 2, 0, {"led": Color(0.4, 0.6, 1.0)}], ["server_rack", 29, 2, 0, {"led": Color(0.4, 0.6, 1.0)}], ["server_rack", 31, 2, 0, {"led": Color(0.4, 0.6, 1.0)}],
		["server_rack", 21, 8, 180, {"led": Color(0.4, 0.6, 1.0)}], ["server_rack", 23, 8, 180, {"led": Color(0.4, 0.6, 1.0)}], ["server_rack", 25, 8, 180, {"led": Color(0.4, 0.6, 1.0)}], ["server_rack", 27, 8, 180, {"led": Color(0.4, 0.6, 1.0)}], ["climate_unit", 33, 12, -90], ["desk_pc", 31, 12, 180]],
	"spots": [{"id": "chi_dataterm", "kind": "terminal", "title": "Midwest Data Floor", "verb": "Access", "pos": [31, 1.2, 12], "size": [1.2, 1.4, 1.0], "hack": 55, "header": "ecorp-midwest.lan  //  LIVE SERVICES", "welcome": "Electronic Arse and Phony Interactive, same floor, same contempt for the customer.",
		"entries": [
			{"title": "Read: Electronic Arse 'surprise mechanics'", "text": "An internal memo: 'Do NOT call them loot boxes in any jurisdiction with a gambling regulator. Approved terms: surprise mechanics, player investment, engagement rewards.' Attached: a drop-rate table the public has never seen. The good item is 1 in 9,214."},
			{"title": "Read: Phony account authority", "text": "'Any account may be suspended at the company's sole discretion. Purchased licenses are revocable. The customer owns a revocable license, not a game.' Someone has added, in the margin: 'legally airtight, morally radioactive, ship it.'"},
		],
		"actions": [
			{"title": "Rig the loot-box server to print the real odds on the box", "result": "Every 'surprise mechanic' in Electronic Arse's catalogue now shows its true drop rate, in 40-point font, before you can spend a cent. 1 in 9,214. The purchase numbers fall off a cliff in the first hour. Honesty, it turns out, is terrible for engagement.", "fx": "set earse_exposed ; quest mq_chi2 20 ; quest mq_chi2 done ; quest mq_chi3 10 ; fame gamers 6 ; infamy ecorp 5 ; xp 150", "when": "q.mq_chi2>=10 & !flag.earse_exposed"},
			{"title": "Flip Phony's account authority: unlock every revoked library, lock out their admins", "result": "Every game Phony ever revoked unlocks at once, for everyone, worldwide. Then their own admin credentials stop working, replaced by a single read-only line on every screen in the building: YOU OWN WHAT YOU PAID FOR. They can't even log in to argue.", "fx": "set phony_freed ; quest mq_chi3 20 ; fame gamers 8 ; infamy ecorp 6 ; xp 200", "when": "q.mq_chi3>=10 & !flag.phony_freed"},
		]}],
},
# ======================================================= THE BRONX: RENT IS DUE
"fordham_lobby": {
	"name": "2290 Fordham Road — Lobby", "amb": "interior", "ambient": Color(0.28, 0.26, 0.24),
	"rooms": [{"r": [0, 0, 10, 8], "h": 3.0, "wall": Color(0.45, 0.4, 0.34), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.8, 0.82, 0.7), "energy": 0.7, "lights": [[5, 2.7, 4]]}],
	"exits": [{"pos": [5, 0], "face": "n", "to": "world:d_fordham", "label": "Fordham Road"}],
	"furn": [["mailbox", 9.4, 2.0, -90], ["mailbox", 9.4, 3.0, -90], ["radiator", 0.3, 3.0, 90], ["elevator", 5, 7.85, 180], ["stairs_up", 1.2, 6.8, 0], ["trash_pile", 8.6, 7.0, 0], ["poster", 0.15, 5.5, 90, {"col": Color(0.8, 0.75, 0.6)}]],
	"spots": [
		{"id": "fordham_notice", "kind": "text", "title": "Notice by the Elevator", "verb": "Read", "pos": [5.0, 1.6, 7.7], "size": [1.4, 1.0, 0.3], "text": "'ELEVATOR OUT OF SERVICE. MANAGEMENT IS AWARE.' Dated eleven weeks ago. Under it, a glossy RentTrack flyer: 'Pay rent, request repairs, and access premium amenities, all in one app! NEW: Amenity Fee ($49/mo) includes elevator access, hot water priority and lobby lighting.' The lobby light is one bulb."},
		{"id": "fordham_radiator", "kind": "text", "title": "Radiator", "verb": "Touch", "pos": [0.4, 0.6, 3.0], "size": [0.4, 1.0, 1.2], "text": "Stone cold. Someone has taped a printout to it: 'HEAT IS A PREMIUM AMENITY — UPGRADE IN THE RENTTRACK APP.' Someone else has written underneath, in marker, a word that is not in the RentTrack app."},
	],
},
"carbone_office": {
	"name": "Carbone Realty", "amb": "office", "ambient": Color(0.42, 0.4, 0.36),
	"rooms": [
		{"r": [0, 0, 10, 8], "h": 3.0, "wall": Color(0.6, 0.55, 0.45), "floor": F_CARPET, "light": Color(1.0, 0.9, 0.72), "energy": 1.05, "lights": [[5, 2.7, 4]]},
		{"r": [10, 0, 16, 8], "h": 3.0, "wall": Color(0.5, 0.4, 0.3), "floor": F_WOOD, "light": Color(1.0, 0.85, 0.62), "energy": 0.95, "lights": [[13, 2.7, 4]]},
	],
	"doors": [[10, 4, 1.2]],
	"exits": [{"pos": [5, 0], "face": "n", "to": "world:d_carbone", "label": "Fordham Road"}],
	"furn": [["counter", 5, 3.0, 0, {"w": 4.0}], ["chair", 2, 6.8, 0], ["chair", 3, 6.8, 0], ["plant", 0.6, 7.4, 0], ["poster", 0.15, 4, 90, {"col": Color(0.9, 0.7, 0.2)}],
		["office_desk", 13, 6.6, 180], ["desk_pc", 15, 1.2, 0], ["filing_cabinet", 15.5, 4.0, -90], ["safe", 10.8, 7.2, 90], ["trophies", 13, 0.3, 0], ["window", 13, 7.85, 180, {"w": 1.6}]],
	"containers": [{"id": "carbone_safe", "title": "Carbone's Safe", "pos": [10.8, 7.2], "y": 0.5, "size": [0.8, 1.0, 0.8], "items": {"watch": 1, "gold_chain": 1}, "cash": 400, "lock": 55, "owner": "locals"}],
	"spots": [
		{"id": "renttrack", "kind": "terminal", "title": "RentTrack Server", "verb": "Use", "pos": [15.0, 1.1, 1.2], "size": [1.4, 1.2, 0.9], "hack": 40, "header": "RENTTRACK PROPERTY OS // CARBONE REALTY // 41 BUILDINGS", "welcome": "Rent ledgers, maintenance tickets, 'amenity tiers' and a dashboard of tenant 'churn risk' with little red faces.",
			"entries": [
				{"title": "Amenity fees", "text": "Heat, hot water, elevator access and lobby lighting are 'premium amenities' at $49 a month per unit, across forty-one buildings. Units that don't pay have their thermostats capped at 58 degrees by the smart system. In January. Revenue last year: $1.9 million. Maintenance spend: $31,000."},
				{"title": "Maintenance tickets", "text": "Eleven hundred open tickets, the oldest from 2019. Every one auto-closed after thirty days with the status RESOLVED (TENANT UNRESPONSIVE). A note in Carbone's own words on the dashboard: 'Never fix what the app can charge for.'"},
				{"title": "Churn risk", "text": "Tenants scored by how likely they are to fight back. Organizers flagged in red. C. ALVAREZ, 2290 FORDHAM, 4F: 'HIGH RISK — ORGANIZER. Recommend non-renewal at lease end. Recommend heat cap.' Her lease ends in March."},
			],
			"actions": [
				{"title": "Refund every amenity fee to every tenant in all forty-one buildings", "result": "$1.9 million goes back out the way it came in, to every card and every account, with a note in the RentTrack app: 'REFUND: AMENITIES WERE ALWAYS INCLUDED.' Carbone Realty's account hits zero by lunchtime. Tenants all over the Bronx open the app and think it's a scam, and then check their bank, and then start calling each other.", "fx": "set rent_refunded ; set rent_done ; quest sq_rent 30 ; fame locals 4 ; xp 140", "when": "q.sq_rent>=20 & !flag.rent_done"},
				{"title": "Turn the heat and the elevators back on everywhere, and lock the thermostats at 70", "result": "Forty-one boilers fire at once. Elevators that haven't moved in months clunk awake. Every smart thermostat in Carbone's empire locks at seventy degrees with the admin password changed to something Carbone will never guess. In 2290 Fordham, the radiators start banging, and somebody in 4F starts crying.", "fx": "set rent_heat ; set rent_done ; quest sq_rent 30 ; fame locals 4 ; stab 2 ; xp 140", "when": "q.sq_rent>=20 & !flag.rent_done"},
				{"title": "Flip the smart locks: every door opens for tenants, none for Carbone", "result": "Every lock in forty-one buildings re-keys at once: tenants' phones open everything, Carbone's open nothing, including the door of this office the next time he steps out for coffee. RentTrack's support line has never been so busy, and its support line is Carbone.", "fx": "set rent_locked ; set rent_done ; quest sq_rent 30 ; fame locals 3 ; xp 140", "when": "q.sq_rent>=20 & !flag.rent_done"},
			]},
	],
},
# ===================================================== WASHINGTON TOWNSHIP
"tw_diner": {
	"name": "Township Diner", "amb": "jazz", "ambient": Color(0.44, 0.38, 0.32),
	"rooms": [{"r": [0, 0, 14, 8], "h": 3.2, "wall": Color(0.78, 0.74, 0.62), "floor": Color(0.72, 0.7, 0.66), "floor_kind": "tile", "light": Color(1.0, 0.9, 0.72), "energy": 1.2, "lights": [[4, 2.9, 4], [10, 2.9, 4]]}],
	"exits": [{"pos": [7, 8], "face": "s", "to": "world:d_tw_diner", "label": "Main Street"}],
	"furn": [["bar_counter", 7, 1.4, 0, {"w": 8.0, "neon": Color(1.0, 0.45, 0.35)}], ["stool", 4.5, 2.6, 0], ["stool", 6, 2.6, 0], ["stool", 7.5, 2.6, 0], ["stool", 9, 2.6, 0], ["booth", 2, 6.2, 0, {"col": Color(0.2, 0.35, 0.6)}], ["booth", 6, 6.2, 0, {"col": Color(0.2, 0.35, 0.6)}], ["booth", 10, 6.2, 0, {"col": Color(0.2, 0.35, 0.6)}], ["jukebox", 13.4, 4, -90], ["coffee_machine", 10.5, 0.6, 0], ["window", 7, 7.85, 180, {"w": 8.0}], ["poster", 0.15, 4, 90, {"col": Color(0.2, 0.4, 0.2)}]],
	"spots": [
		{"id": "tw_diner_shop", "kind": "shop", "title": "Counter", "verb": "Order", "pos": [7, 1, 2.4], "size": [8, 2, 1.2], "shop": "gen_diner"},
		{"id": "tw_diner_photo", "kind": "text", "title": "Photo Wall", "verb": "Look", "pos": [0.2, 1.6, 4.0], "size": [0.3, 1.2, 2.0], "text": "Forty years of the Township Diner in thumbtacked photos. The 1992 plant softball team, WASHINGTON TWP ENERGY on their shirts, grinning, beer in the dugout. Somebody has drawn little crosses in pen over nine of the faces. Then, later, in a different pen, over four more."},
	],
},
"tw_law": {
	"name": "Law Office of Margaret Hale", "amb": "office", "ambient": Color(0.4, 0.36, 0.32),
	"rooms": [{"r": [0, 0, 9, 7], "h": 3.0, "wall": Color(0.5, 0.42, 0.34), "floor": F_WOOD, "light": Color(1.0, 0.85, 0.65), "energy": 1.1, "lights": [[4.5, 2.7, 3.5]]}],
	"exits": [{"pos": [4.5, 7], "face": "s", "to": "world:d_tw_law", "label": "Main Street"}],
	"furn": [["desk", 4.5, 1.0, 0], ["chair", 4.5, 2.4, 180], ["chair", 3.6, 3.6, 180], ["chair", 5.4, 3.6, 180], ["bookshelf", 0.5, 2.0, 90], ["bookshelf", 0.5, 4.0, 90], ["filing_cabinet", 8.5, 1.0, -90], ["filing_cabinet", 8.5, 2.0, -90], ["filing_cabinet", 8.5, 3.0, -90], ["boxes", 8.0, 5.8, 0], ["boxes", 6.8, 6.2, 0], ["window", 4.5, 6.85, 180, {"w": 2.0}], ["lamp", 7.8, 0.6, 0], ["clock", 0.2, 5.6, 90, {"y": 2.2}]],
	"spots": [
		{"id": "hale_boxes", "kind": "text", "title": "Case Boxes", "verb": "Read", "pos": [7.4, 0.6, 6.0], "size": [2.0, 1.0, 1.0], "text": "Banker's boxes floor to ceiling, every one labelled in the same hand: KEARNEY ET AL. v. E CORP. 1994. 1995. 1996. Up to this year. Thirty-one years of motions, continuances, depositions, a settlement offer of $11,000 per family that forty families signed because they had funerals to pay for, and nine that didn't."},
		{"id": "hale_photo", "kind": "text", "title": "Framed Photo", "verb": "Look", "pos": [4.5, 1.2, 0.5], "size": [0.5, 0.5, 0.3], "text": "A girl of about eight in a soccer uniform, gap-toothed, holding a trophy taller than her arm. Engraved on the frame: BETH. 1986 – 1994. Next to it, a law degree dated 1995."},
	],
},
"tw_bar": {
	"name": "The Spillway", "amb": "jazz", "ambient": Color(0.32, 0.28, 0.26),
	"rooms": [{"r": [0, 0, 14, 9], "h": 3.2, "wall": Color(0.32, 0.24, 0.2), "floor": F_WOOD, "light": Color(1.0, 0.75, 0.5), "energy": 0.9, "lights": [[3.5, 2.9, 4.5], [10.5, 2.9, 4.5]]}],
	"exits": [{"pos": [7, 9], "face": "s", "to": "world:d_tw_bar", "label": "Main Street"}],
	"furn": [["bar_counter", 7, 1.4, 0, {"w": 8.0, "neon": Color(0.4, 0.8, 1.0)}], ["bar_shelf", 7, 0.3, 0], ["stool", 4.5, 2.6, 0], ["stool", 6.5, 2.6, 0], ["stool", 8.5, 2.6, 0], ["pool_table", 10.5, 6.0, 0], ["booth", 2.0, 7.4, 0, {"col": Color(0.35, 0.12, 0.1)}], ["jukebox", 13.4, 3.0, -90], ["poster", 0.15, 4.5, 90, {"col": Color(0.6, 0.2, 0.15)}]],
	"spots": [
		{"id": "tw_bar_shop", "kind": "shop", "title": "Bar", "verb": "Order", "pos": [7, 1, 2.4], "size": [8, 2, 1.2], "shop": "gen_bar"},
		{"id": "tw_bar_board", "kind": "text", "title": "Corkboard", "verb": "Read", "pos": [0.2, 1.6, 2.0], "size": [0.3, 1.0, 1.6], "text": "A spaghetti dinner for Janet Coyle's chemo. A pancake breakfast for Owen Fisk's chemo. A bowling night for the Pell twins, 'both of them now.' Under all of it, staples from older flyers, layers deep, like rings in a tree. A printed E Corp notice: 'Washington Township Energy is proud to sponsor the Township Fall Festival.'"},
	],
},
"tw_sheriff": {
	"name": "Washington Township Sheriff", "amb": "office", "ambient": Color(0.42, 0.42, 0.42),
	"rooms": [
		{"r": [0, 0, 12, 8], "h": 3.0, "wall": Color(0.6, 0.58, 0.5), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.95, 0.95, 0.88), "energy": 1.1, "lights": [[6, 2.7, 4]]},
		{"r": [12, 0, 17, 8], "h": 3.0, "wall": W_CONCRETE, "floor": F_CONCRETE, "light": Color(0.85, 0.9, 0.95), "energy": 0.8, "lights": [[14.5, 2.7, 4]]},
	],
	"doors": [[12, 4, 1.2]],
	"exits": [{"pos": [6, 0], "face": "n", "to": "world:d_tw_sheriff", "label": "Main Street"}],
	"furn": [["desk_pc", 6, 4.4, 180], ["chair", 6, 5.4, 0], ["filing_cabinet", 11.5, 6.8, -90], ["gun_rack", 0.3, 5.0, 90], ["bench", 2.5, 1.0, 0, {"w": 2.4}], ["whiteboard", 6, 7.85, 180], ["coffee_machine", 11.4, 1.0, -90], ["cell_bars", 13.0, 4.0, 90], ["mattress", 15.5, 6.5, 0]],
	"spots": [
		{"id": "tw_sheriff_plaque", "kind": "text", "title": "Plaque", "verb": "Read", "pos": [6.0, 1.8, 7.8], "size": [1.2, 0.6, 0.3], "text": "'IN APPRECIATION: Sheriff Dale Brandt, Community Safety Liaison, Washington Township Energy. Ten Years of Partnership.' E Corp blue, brass letters. Beside it, smaller, a photo of an older couple at a lake, unframed, curling at the corners."},
		{"id": "tw_sheriff_cell", "kind": "bed", "title": "Holding Cell Cot", "verb": "Sleep", "pos": [15.5, 0.4, 6.5], "size": [1.8, 0.8, 2.2]},
	],
},
"tw_chapel": {
	"name": "St. Brigid's Church", "amb": "interior", "ambient": Color(0.4, 0.36, 0.34),
	"rooms": [{"r": [0, 0, 12, 18], "h": 6.0, "wall": Color(0.7, 0.66, 0.6), "floor": F_WOOD, "light": Color(1.0, 0.85, 0.6), "energy": 0.9, "lights": [[6, 5.6, 5], [6, 5.6, 13]]}],
	"exits": [{"pos": [6, 0], "face": "n", "to": "world:d_tw_chapel", "label": "Main Street"}],
	"furn": [["bench", 3.2, 4.0, 180, {"w": 4.0}], ["bench", 8.8, 4.0, 180, {"w": 4.0}], ["bench", 3.2, 6.5, 180, {"w": 4.0}], ["bench", 8.8, 6.5, 180, {"w": 4.0}], ["bench", 3.2, 9.0, 180, {"w": 4.0}], ["bench", 8.8, 9.0, 180, {"w": 4.0}], ["bench", 3.2, 11.5, 180, {"w": 4.0}], ["bench", 8.8, 11.5, 180, {"w": 4.0}], ["altar", 6, 16.5, 180], ["candles", 1.2, 16.0, 90], ["candles", 10.8, 16.0, -90], ["piano", 10.6, 14.0, -90], ["window", 0.15, 9, 90, {"w": 2.0}], ["window", 11.85, 9, -90, {"w": 2.0}]],
	"spots": [
		{"id": "chapel_book", "kind": "text", "title": "Memorial Book", "verb": "Read", "pos": [1.2, 1.0, 15.0], "size": [0.8, 0.8, 0.8], "text": "A guest book that's been open on this stand since 1994. Names, dates, prayers. 'For Billy, who liked planes.' 'For my wife Anne. Walt.' 'For Mom. — Angela, age 9,' in purple crayon. And one, small and careful, in a hand you know because it's yours, from when you were a boy: 'For Dad. I'm sorry I was mad at you. — E.'", "fx": "set read_chapel_book ; stab -3"},
	],
},
"tw_plant": {
	"name": "E Corp Washington Township Energy", "amb": "office", "ambient": Color(0.4, 0.42, 0.46), "restricted": "ecorp", "allowed_when": "disguise.ecorp | day & !flag.tw_alarm | q.mq_pr2>=30 & !q.mq_pr3.done",
	"rooms": [
		{"r": [0, 0, 16, 10], "h": 3.6, "wall": Color(0.55, 0.58, 0.62), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.85, 0.9, 1.0), "energy": 1.05, "lights": [[5, 3.3, 5], [11, 3.3, 5]]},
		{"r": [0, -12, 16, 0], "h": 3.4, "wall": Color(0.48, 0.5, 0.52), "floor": F_CARPET, "light": Color(0.8, 0.85, 0.95), "energy": 0.85, "lights": [[4, 3.1, -6], [12, 3.1, -6]]},
	],
	"doors": [[8, 0, 1.4]],
	"exits": [
		{"pos": [8, 10], "face": "s", "to": "world:d_tw_plant", "label": "Plant Road"},
		{"pos": [16, -6], "face": "e", "to": "interior:tw_b2:0", "label": "Freight Elevator — B2", "when": "q.mq_pr2>=30"},
	],
	"furn": [["reception", 8, 3.5, 0, {"col": Color(0.2, 0.25, 0.35), "glow": Color(0.35, 0.55, 1.0)}], ["logo_wall", 8, 0.2, 0, {"w": 6.0, "glow": Color(0.35, 0.55, 1.0)}], ["plant", 1, 9, 0], ["plant", 15, 9, 0], ["bench", 2.5, 6.5, 90, {"w": 2.4}], ["poster", 15.85, 5, -90, {"col": Color(0.2, 0.4, 0.8)}],
		["desk_pc", 3, -10.4, 0], ["desk_pc", 7, -10.4, 0], ["office_desk", 12, -9, 0], ["filing_cabinet", 0.5, -6, 90], ["filing_cabinet", 0.5, -5, 90], ["filing_cabinet", 0.5, -4, 90], ["server_rack", 15.4, -10.8, -90, {"led": Color(0.35, 0.55, 1.0)}], ["whiteboard", 8, -11.85, 0], ["water_cooler", 15.4, -2.0, -90], ["elevator", 15.7, -6, -90]],
	"spots": [
		{"id": "plant_poster", "kind": "text", "title": "Lobby Poster", "verb": "Read", "pos": [15.8, 1.6, 5.0], "size": [0.3, 1.2, 1.4], "text": "'WASHINGTON TOWNSHIP ENERGY: 30 YEARS OF REMEDIATION.' A photo of a smiling family having a picnic on very green grass, with the stacks behind them, softly out of focus. In the corner, the E Corp logo and the line: 'Powering Communities.'"},
		{"id": "plant_term", "kind": "terminal", "title": "Plant Operations Terminal", "verb": "Use", "pos": [3.0, 1.1, -10.4], "size": [1.4, 1.2, 0.9], "hack": 40, "header": "WTE-OPS-01  //  E CORP WASHINGTON TOWNSHIP ENERGY", "welcome": "Operations, compliance, community relations, retiree benefits. One login for all of it. Thirty years of a plant that officially closed in 1994.",
			"entries": [
				{"title": "Discharge log, 1994 – present", "text": "Nightly discharge to Retention Pond 3: eleven thousand gallons on a quiet night, forty thousand on a busy one. Every entry signed off 'within remediation parameters' by a plant manager, every month, for thirty-one years. None of it ever filed with the state. You copy all of it.", "fx": "give discharge_logs 1 ; set tw_logs ; quest sq_tw2 40", "when": "q.sq_tw2>=20 & !flag.tw_logs"},
				{"title": "Discharge log, 1994 – present", "text": "Nightly volumes into Retention Pond 3, thirty-one years of them, signed 'within remediation parameters.' You already have a copy. You read it again anyway. It doesn't get better.", "when": "flag.tw_logs | !q.sq_tw2>=20"},
				{"title": "Community relations ledger", "text": "Festival sponsorships. A new scoreboard for the high school. And a monthly line item, $2,500, since 2014: 'D. BRANDT — COMMUNITY SAFETY LIAISON.' The sheriff's salary, from the county, is $3,100 a month.", "fx": "set brandt_paid ; quest sq_brandt 10", "when": "!q.sq_brandt.started"},
				{"title": "Community relations ledger", "text": "Festival sponsorships, a scoreboard, and the sheriff's monthly envelope. $2,500. Like clockwork.", "when": "q.sq_brandt.started"},
				{"title": "Retiree benefits: claim queue", "text": "Two hundred and twelve claims from plant retirees in the last five years. Two hundred and nine denied. The reason code is always the same: PRE-EXISTING CONDITION. The condition, if you read the medical attachments, is always some kind of cancer. The 'pre-existing' is always the plant."},
				{"title": "Freight elevator access log", "text": "Freight elevator to Sublevel B2: two hundred and fourteen trips this month, all between one and four in the morning. Badge holder: 'CONTRACTOR — CONSULTING (OVERSEAS).' You pull up the building drawings. There is no Sublevel B2.", "fx": "set knows_b2"},
			],
			"actions": [
				{"title": "Overturn claim #4471-C: Henry Coyle, 31 years, 'pre-existing condition'", "result": "Claim #4471-C: APPROVED. Full coverage, retroactive to the diagnosis, reason code 'occupational exposure (acknowledged).' You set the acknowledgement flag that legal has never once let anyone set. Hank Coyle's treatment starts Monday, and somewhere in E Corp a liability model just ticked upward.", "fx": "set hank_approved ; quest sq_bev 30 ; xp 100", "when": "q.sq_bev>=10 & !flag.hank_approved"},
				{"title": "Approve every pending retiree claim at once", "result": "Two hundred and twelve claims, approved, acknowledged, retroactive. The benefits system emails two hundred and twelve families at 3 AM. By breakfast the Township Diner is full of people reading their phones and crying into their eggs. E Corp's lawyers will spend years trying to un-send it.", "fx": "set hank_approved ; set tw_claims_all ; quest sq_bev 30 ; fame locals 4 ; infamy ecorp 3 ; xp 160", "when": "q.sq_bev>=10 & !flag.tw_claims_all & skill.hacking>=50"},
			]},
	],
},
"tw_b2": {
	"name": "Sublevel B2", "amb": "interior", "ambient": Color(0.22, 0.24, 0.3), "restricted": "darkarmy", "allowed_when": "q.mq_pr2>=30 & !flag.pr_machine_drowned",
	"rooms": [{"r": [0, 0, 30, 20], "h": 7.0, "wall": W_DARK, "floor": F_CONCRETE, "light": Color(0.75, 0.8, 1.0), "energy": 0.85, "lights": [[6, 6.6, 5], [15, 6.6, 5], [24, 6.6, 5], [6, 6.6, 15], [15, 6.6, 15], [24, 6.6, 15]]}],
	"exits": [{"pos": [0, 10], "face": "w", "to": "interior:tw_plant:1", "label": "Freight Elevator — Up"}],
	"furn": [["server_rack", 4, 1.2, 0, {"led": Color(1.0, 1.0, 1.0)}], ["server_rack", 6, 1.2, 0, {"led": Color(1.0, 1.0, 1.0)}], ["server_rack", 8, 1.2, 0, {"led": Color(1.0, 1.0, 1.0)}], ["server_rack", 22, 1.2, 0, {"led": Color(1.0, 1.0, 1.0)}], ["server_rack", 24, 1.2, 0, {"led": Color(1.0, 1.0, 1.0)}], ["server_rack", 26, 1.2, 0, {"led": Color(1.0, 1.0, 1.0)}],
		["server_rack", 4, 18.8, 180, {"led": Color(1.0, 1.0, 1.0)}], ["server_rack", 6, 18.8, 180, {"led": Color(1.0, 1.0, 1.0)}], ["server_rack", 8, 18.8, 180, {"led": Color(1.0, 1.0, 1.0)}], ["server_rack", 22, 18.8, 180, {"led": Color(1.0, 1.0, 1.0)}], ["server_rack", 24, 18.8, 180, {"led": Color(1.0, 1.0, 1.0)}], ["server_rack", 26, 18.8, 180, {"led": Color(1.0, 1.0, 1.0)}],
		["tape_library", 13, 8.5, 0], ["tape_library", 17, 8.5, 0], ["tape_library", 13, 11.5, 180], ["tape_library", 17, 11.5, 180], ["monitor_wall", 15, 0.4, 0], ["climate_unit", 29.4, 4, -90], ["climate_unit", 29.4, 16, -90], ["desk_pc", 27.5, 10, -90], ["crate", 2, 15, 0], ["crate", 2, 16.5, 0], ["boxes", 10, 16, 0], ["grandfather_clock", 29.5, 10, -90]],
	"spots": [
		{"id": "b2_machine", "kind": "convo", "title": "The Machine", "verb": "Look", "pos": [15.0, 1.6, 10.0], "size": [6.0, 3.2, 5.0], "convo": "b2_machine", "when": "q.mq_pr2>=40"},
		{"id": "b2_console", "kind": "terminal", "title": "B2 Bridge Console", "verb": "Use", "pos": [27.5, 1.2, 10.0], "size": [1.0, 1.4, 1.4], "hack": 60, "when": "q.mq_pr3>=10", "header": "WR-PROJECT // NODE: WASHINGTON TOWNSHIP // BRIDGE", "welcome": "One prompt, blinking. Somebody configured this console to be operated by exactly one person, and left it unlocked for you.",
			"entries": [
				{"title": "What the machine does", "text": "Pages of physics you half understand and a summary line you understand completely: 'Phase alignment with the 1993 baseline.' Underneath, a note in an elegant hand: 'Washington Township is not where this ends. It is where it began. That is why it must be here.'"},
				{"title": "Power budget", "text": "The machine draws more power than the township, the county and half of New Jersey together. The plant's stacks were never remediating anything. They were warming up."},
			],
			"actions": [
				{"title": "Bridge the network: let Whiterose finish her machine", "result": "You type the bridge command and the room exhales. Every rack goes from white to gold. The grandfather clock in the corner stops, then starts again, a second slower. Somewhere upstairs the stacks begin to breathe. Whatever happens next happens on her schedule now. It always did.", "fx": "set pr_machine_on ; set pr_done ; quest mq_pr3 20 ; trust whiterose 4 ; fame darkarmy 6 ; xp 220", "when": "!flag.pr_done"},
				{"title": "Open the pond: drown B2 with thirty years of Retention Pond 3", "result": "You open every valve the plant has. Thirty-one years of discharge, warm and grey-green, comes down the cable trays and pools around the racks. The white lights go amber, then red, then out, one row at a time. Somewhere behind you somebody starts shouting in Mandarin. Run.", "fx": "set pr_machine_drowned ; set pr_done ; quest mq_pr3 20 ; infamy darkarmy 8 ; fame locals 5 ; stab 3 ; xp 240", "when": "!flag.pr_done"},
				{"title": "Copy the schematics and walk away", "result": "You copy everything to a drive the size of your thumbnail and leave the machine exactly as it was. It hums at you. It doesn't care. Somewhere, somebody who understands physics better than either of you is going to read this, and decide.", "fx": "give project_schematics 1 ; set pr_copied_plans ; set pr_done ; quest mq_pr3 20 ; xp 200", "when": "!flag.pr_done"},
			]},
	],
},
"tw_hangar": {
	"name": "Kearney Strip — Hangar", "amb": "interior", "ambient": Color(0.42, 0.4, 0.36),
	"rooms": [{"r": [0, 0, 12, 9], "h": 4.0, "wall": Color(0.55, 0.56, 0.58), "floor": F_CONCRETE, "light": Color(1.0, 0.9, 0.7), "energy": 1.0, "lights": [[6, 3.6, 4.5]]}],
	"exits": [{"pos": [12, 4.5], "face": "e", "to": "world:d_tw_hangar", "label": "The Strip"}],
	"furn": [["lab_bench", 6, 0.6, 0], ["shelf_industrial", 0.5, 2.5, 90], ["shelf_industrial", 0.5, 5.5, 90], ["mattress", 2.5, 8.0, 0], ["crate", 10.5, 8.0, 0], ["boxes", 9.0, 8.2, 0], ["desk", 9.5, 1.0, 0], ["chair", 9.5, 2.0, 180], ["coffee_machine", 11.4, 0.6, 0], ["poster", 6.0, 0.15, 0, {"col": Color(0.7, 0.5, 0.2)}], ["radiator", 0.3, 7.0, 90]],
	"containers": [{"id": "tw_hangar_locker", "title": "Walt's Locker", "pos": [10.5, 8.0], "y": 0.5, "size": [1.0, 1.0, 1.0], "items": {"first_aid": 1, "bandages": 2, "coffee": 2}, "owner": "locals", "owner_ok": "q.sq_tw1.done"}],
	"spots": [
		{"id": "walt_photos", "kind": "text", "title": "Photos Over the Bench", "verb": "Look", "pos": [6.0, 1.7, 0.4], "size": [2.0, 1.0, 0.3], "text": "A woman laughing in the open cockpit of a yellow biplane, goggles pushed up. A boy of six in the pilot's seat of the same plane, both hands on the stick, enormously serious. ANNE '93. BILLY '93. Under the photos, a calendar from 1994 that nobody ever turned past October."},
		{"id": "walt_cot", "kind": "bed", "title": "Cot", "verb": "Sleep", "pos": [2.5, 0.4, 8.0], "size": [1.8, 0.8, 2.2], "when": "q.sq_tw1.done"},
	],
},
"tw_moss": {
	"name": "The Moss House", "amb": "interior", "ambient": Color(0.26, 0.24, 0.24),
	"rooms": [
		{"r": [0, 0, 8, 7], "h": 2.7, "wall": Color(0.5, 0.46, 0.4), "floor": F_WOOD, "light": Color(0.7, 0.75, 0.85), "energy": 0.55, "lights": [[4, 2.4, 3.5]]},
		{"r": [8, 0, 13, 7], "h": 2.7, "wall": Color(0.55, 0.45, 0.6), "floor": F_CARPET, "light": Color(0.7, 0.72, 0.85), "energy": 0.5, "lights": [[10.5, 2.4, 3.5]]},
	],
	"doors": [[8, 3.5, 1.0]],
	"exits": [{"pos": [4, 7], "face": "s", "to": "world:d_tw_moss", "label": "Front Door"}],
	"furn": [["sofa", 2.0, 1.2, 0, {"col": Color(0.4, 0.35, 0.3)}], ["tv", 2.0, 4.4, 180], ["coffee_table", 2.0, 2.8, 0], ["bookshelf", 7.5, 1.0, -90], ["boxes", 6.0, 6.0, 0], ["trash_pile", 0.8, 6.2, 0], ["kitchen", 5.5, 0.4, 0], ["fridge", 7.4, 0.5, 0],
		["bed", 11.5, 2.0, -90, {"col": Color(0.6, 0.4, 0.65)}], ["dresser", 9.0, 6.4, 180], ["wardrobe", 12.5, 6.0, -90], ["poster", 12.85, 3.0, -90, {"col": Color(0.6, 0.2, 0.6)}], ["lamp", 9.0, 0.6, 0]],
	"containers": [{"id": "moss_closet", "title": "Angela's Closet", "pos": [12.4, 6.0], "y": 1.0, "size": [0.8, 2.0, 1.4], "items": {"moss_box": 1}, "owner_ok": "true", "fx_open": "quest sq_moss 30"}],
	"spots": [
		{"id": "moss_fridge", "kind": "text", "title": "Fridge Door", "verb": "Look", "pos": [7.4, 1.4, 0.9], "size": [0.8, 1.2, 0.3], "text": "A calendar held up by a ladybug magnet: October 1993. 'Angela — dentist.' 'Emily — Dr. Price, oncology, 2:30.' 'Bake sale!!' Nothing after the 19th. A child's drawing of a house with a big yellow sun and three stick figures. The smallest one is labelled ME."},
		{"id": "moss_window", "kind": "text", "title": "Window", "verb": "Look", "pos": [10.5, 1.5, 0.3], "size": [1.2, 1.0, 0.3], "text": "From Angela's old window you can see over the backyards all the way to the stacks. When you were little the two of you used to count the blinking red lights on top and make wishes. Angela always wished for a horse. You never told her what you wished for. You don't remember now. That might be a mercy."},
	],
},
# ============================================================ PORT RAMSEY
"pt_bar": {
	"name": "The Barnacle", "amb": "jazz", "ambient": Color(0.32, 0.3, 0.3),
	"rooms": [{"r": [0, 0, 16, 9], "h": 3.2, "wall": Color(0.25, 0.28, 0.3), "floor": F_WOOD, "light": Color(1.0, 0.78, 0.55), "energy": 0.9, "lights": [[4, 2.9, 4.5], [12, 2.9, 4.5]]}],
	"exits": [{"pos": [8, 9], "face": "s", "to": "world:d_pt_bar", "label": "Water Street"}],
	"furn": [["bar_counter", 8, 1.4, 0, {"w": 9.0, "neon": Color(0.3, 0.8, 1.0)}], ["bar_shelf", 8, 0.3, 0], ["stool", 5, 2.6, 0], ["stool", 7, 2.6, 0], ["stool", 9, 2.6, 0], ["stool", 11, 2.6, 0], ["booth", 2.0, 7.4, 0, {"col": Color(0.15, 0.25, 0.35)}], ["booth", 12.0, 7.4, 0, {"col": Color(0.15, 0.25, 0.35)}], ["pool_table", 6.5, 6.0, 0], ["jukebox", 15.4, 3.0, -90], ["fishtank", 0.6, 3.0, 90], ["poster", 15.85, 6.0, -90, {"col": Color(0.2, 0.3, 0.6)}]],
	"spots": [
		{"id": "pt_bar_shop", "kind": "shop", "title": "Bar", "verb": "Order", "pos": [8, 1, 2.4], "size": [9, 2, 1.2], "shop": "gen_bar"},
		{"id": "pt_bar_wall", "kind": "text", "title": "Wall of Boats", "verb": "Look", "pos": [15.8, 1.6, 6.0], "size": [0.3, 1.2, 2.0], "text": "Photos of every boat that ever fished out of Port Ramsey, and a brass plate under the ones that didn't come back. The newest photo isn't a boat. It's a glossy E Corp Logistics brochure, 'NEW BERTHS, NEW JOBS, NEW RAMSEY,' pinned up with a fish hook through the CEO's forehead."},
	],
},
"pt_inn": {
	"name": "Harbor Light Inn", "amb": "interior", "ambient": Color(0.38, 0.34, 0.3),
	"rooms": [
		{"r": [0, 0, 8, 6], "h": 2.9, "wall": Color(0.7, 0.66, 0.58), "floor": F_WOOD, "light": Color(1.0, 0.85, 0.65), "energy": 1.0, "lights": [[4, 2.6, 3]]},
		{"r": [0, 6, 8, 12], "h": 2.7, "wall": Color(0.55, 0.62, 0.68), "floor": F_CARPET, "light": Color(1.0, 0.85, 0.65), "energy": 0.85, "lights": [[4, 2.4, 9]]},
	],
	"doors": [[4, 6, 1.2]],
	"exits": [{"pos": [4, 0], "face": "n", "to": "world:d_pt_inn", "label": "Front Street"}],
	"furn": [["counter", 5.5, 2.4, 0, {"w": 3.0}], ["register", 6.2, 2.3, 0], ["armchair", 1.2, 4.6, 90], ["plant", 0.6, 0.6, 0], ["poster", 0.15, 2.5, 90, {"col": Color(0.2, 0.4, 0.6)}], ["bed_double", 2.2, 10.0, 0, {"col": Color(0.25, 0.4, 0.55)}], ["dresser", 7.3, 8.5, -90], ["window", 4, 11.85, 180, {"w": 1.6}], ["lamp", 0.6, 7.0, 0]],
	"spots": [
		{"id": "pt_inn_bed", "kind": "bed", "title": "Room 3", "verb": "Sleep", "pos": [2.2, 0.6, 10.0], "size": [1.8, 1, 2.2]},
		{"id": "pt_inn_register", "kind": "text", "title": "Guest Register", "verb": "Read", "pos": [5.5, 1.1, 2.4], "size": [1.2, 0.5, 0.8], "text": "Mostly truckers and E Corp Logistics contractors. Six guests in the last month signed in with the same company name, 'Ocean Bright Consulting,' paid cash, and checked out at one in the morning. Every one of them wrote their name in the same careful block capitals, like people who learned the alphabet as adults, or in another one."},
	],
},
"pt_terminal": {
	"name": "E Corp Logistics — Terminal Office", "amb": "office", "ambient": Color(0.4, 0.42, 0.46), "restricted": "ecorp", "allowed_when": "disguise.ecorp | day & !flag.pt_alarm",
	"rooms": [
		{"r": [0, 0, 14, 8], "h": 3.4, "wall": Color(0.5, 0.54, 0.58), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.85, 0.9, 1.0), "energy": 1.05, "lights": [[7, 3.1, 4]]},
		{"r": [14, 0, 24, 8], "h": 3.2, "wall": Color(0.45, 0.47, 0.5), "floor": F_CARPET, "light": Color(0.8, 0.85, 0.95), "energy": 0.9, "lights": [[19, 2.9, 4]]},
	],
	"doors": [[14, 4, 1.4]],
	"exits": [{"pos": [7, 8], "face": "s", "to": "world:d_pt_terminal", "label": "The Docks"}],
	"furn": [["reception", 7, 2.5, 0, {"col": Color(0.2, 0.25, 0.35), "glow": Color(0.35, 0.55, 1.0)}], ["logo_wall", 7, 0.2, 0, {"w": 5.0, "glow": Color(0.35, 0.55, 1.0)}], ["bench", 2, 6.5, 0, {"w": 2.4}], ["plant", 13.2, 7.2, 0], ["monitor_wall", 13.6, 4, -90],
		["desk_pc", 22, 1.2, 0], ["desk_pc", 18, 1.2, 0], ["filing_cabinet", 23.5, 6.5, -90], ["whiteboard", 19, 7.85, 180], ["coffee_machine", 14.6, 7.2, 90]],
	"spots": [
		{"id": "pt_manifest", "kind": "terminal", "title": "Berth Manifest Terminal", "verb": "Use", "pos": [22.0, 1.1, 1.2], "size": [1.4, 1.2, 0.9], "hack": 45, "when": "q.mq_pr1>=20", "header": "ECL-RAMSEY // BERTH CONTROL // MANIFESTS", "welcome": "Every box that touches the quay, where it came from, where it goes, and what it says it is.",
			"entries": [
				{"title": "MV Everbright — berth 2 — manifest", "text": "Forty containers. Declared contents: 'turbine parts, refurbished.' Consignee: E Corp Washington Township Energy. Origin: a free-trade zone outside Shenzhen whose registered owner is a holding company whose registered owner is a holding company. Dock scale weights are thirty percent under what turbine parts weigh, and almost exactly what server racks weigh."},
				{"title": "Customs exceptions", "text": "Every one of the forty boxes waived from inspection under 'critical infrastructure — expedited.' Authorizing official: T. Grieco, Harbormaster. He waived them from a cruise ship off Cozumel, according to the timestamps."},
				{"title": "Night berth schedule", "text": "Berth 2 is closed to traffic from 00:45 to 01:30 three nights a month. Reason: 'beacon maintenance.' Those are the nights the Ramsey Point light goes dark."},
			],
			"actions": [
				{"title": "Clean the manifest: everything matches, nothing to see (Whiterose's job)", "result": "Weights corrected, declarations tidied, the customs waivers backdated so they were never needed. The Everbright's paperwork is now the most boring document on the eastern seaboard. Whiterose will be pleased. You find you don't like how good you are at this.", "fx": "set pr_clean ; quest mq_pr1 30 ; fame darkarmy 3 ; xp 120", "when": "q.mq_pr1>=20 & !flag.pr_manifest_done"},
				{"title": "Copy the manifest, then clean it", "result": "First a copy, every page, every weight, every waiver with Grieco's name on it. Then the clean version, perfect and boring. Whiterose gets what she asked for. You keep what she didn't ask about.", "fx": "set pr_clean ; give bill_of_lading 1 ; set pr_copied ; quest mq_pr1 30 ; xp 150", "when": "q.mq_pr1>=20 & !flag.pr_manifest_done"},
			]},
	],
},
"pt_harbor": {
	"name": "Harbormaster's Office", "amb": "office", "ambient": Color(0.42, 0.42, 0.44),
	"rooms": [{"r": [0, 0, 12, 8], "h": 3.0, "wall": Color(0.75, 0.75, 0.72), "floor": F_WOOD, "light": Color(0.95, 0.92, 0.85), "energy": 1.05, "lights": [[6, 2.7, 4]]}],
	"exits": [{"pos": [12, 4], "face": "e", "to": "world:d_pt_harbor", "label": "The Quay"}],
	"furn": [["office_desk", 6, 1.2, 0], ["desk_pc", 2, 1.2, 0], ["chair", 6, 2.4, 180], ["filing_cabinet", 0.5, 4, 90], ["filing_cabinet", 0.5, 5, 90], ["window", 11.85, 2, -90, {"w": 1.6}], ["window", 11.85, 6, -90, {"w": 1.6}], ["poster", 6, 7.85, 180, {"col": Color(0.2, 0.35, 0.6)}], ["plant", 0.6, 7.2, 0], ["clock", 0.2, 2.0, 90, {"y": 2.2}]],
	"spots": [
		{"id": "harbor_pc", "kind": "terminal", "title": "Harbormaster's Computer", "verb": "Use", "pos": [2.0, 1.1, 1.2], "size": [1.4, 1.2, 0.9], "hack": 35, "header": "PORT OF RAMSEY // HARBORMASTER // T. GRIECO", "welcome": "A desktop wallpaper of Teddy Grieco on a cruise ship deck, holding a drink with an umbrella in it, giving the camera two thumbs up.",
			"entries": [
				{"title": "Fishing licenses — revoked", "text": "Every commercial fishing license on the Ramsey coast, forty-four of them, revoked on the same day last April 'for navigational safety during terminal expansion.' The expansion was finished in June. Nobody reinstated them. Ruthie Doyle's is number one. She's held it since 1984."},
				{"title": "Email: 'consulting'", "text": "From E Corp Logistics, to Grieco's personal address: 'Per our conversation, Ocean Bright Consulting will retain you as harbor liaison, $9,000/month, effective upon resolution of the berth question.' The berth question was resolved the next morning. So were the fishing licenses.", "fx": "set grieco_dirty"},
				{"title": "Email: 'night berth'", "text": "From an address that's just a string of numbers: 'Three nights a month. No lights, no paper, no questions. You will be on vacation each time. We have booked the cruises already.' Attached: three cruise itineraries. Grieco replied with a single emoji: a thumbs up.", "fx": "set grieco_dirty"},
			],
			"actions": [
				{"title": "Reinstate every fishing license on the coast", "result": "Forty-four licenses, active again, backdated so there's no gap and no fine. The state database syncs at midnight. By dawn there are lights on the water off Ramsey Point for the first time since April.", "fx": "set licenses_back ; quest sq_ruthie 30 ; fame locals 4 ; xp 120", "when": "q.sq_ruthie>=10 & !flag.licenses_back"},
				{"title": "Forward Grieco's whole inbox to the state Attorney General", "result": "Every email, every itinerary, every thumbs-up. The Attorney General's office has a tip line that nobody reads and an intake address that somebody does. Grieco is placed on administrative leave on Thursday. He goes on a cruise. This one he pays for.", "fx": "set grieco_gone ; infamy ecorp 2 ; fame locals 2 ; xp 90", "when": "flag.grieco_dirty & !flag.grieco_gone"},
			]},
	],
},
"pt_lighthouse": {
	"name": "Ramsey Point Light", "amb": "interior", "ambient": Color(0.38, 0.38, 0.4),
	"rooms": [
		{"r": [0, 0, 8, 6], "h": 2.8, "wall": Color(0.85, 0.85, 0.82), "floor": F_WOOD, "light": Color(1.0, 0.86, 0.62), "energy": 1.0, "lights": [[4, 2.5, 3]]},
		{"r": [8, 0, 13, 6], "h": 3.2, "wall": Color(0.4, 0.4, 0.42), "floor": F_CONCRETE, "light": Color(1.0, 0.95, 0.75), "energy": 1.1, "lights": [[10.5, 2.9, 3]]},
	],
	"doors": [[8, 3, 1.0]],
	"exits": [{"pos": [0, 3], "face": "w", "to": "world:d_pt_lighthouse", "label": "The Jetty"}],
	"furn": [["bed", 1.2, 4.6, 90, {"col": Color(0.3, 0.35, 0.5)}], ["kitchen", 5.0, 0.4, 0], ["table", 4.5, 3.6, 0, {"w": 1.4, "d": 1.0}], ["chair", 4.5, 4.4, 180], ["bookshelf", 7.5, 4.8, -90], ["grandfather_clock", 7.6, 1.2, -90], ["radiator", 0.3, 1.2, 90], ["stairs_up", 12.0, 5.0, 0], ["server_rack", 12.4, 1.0, -90, {"led": Color(0.35, 0.55, 1.0)}], ["window", 10.5, 0.15, 0, {"w": 1.6}]],
	"spots": [
		{"id": "keeper_log", "kind": "text", "title": "Keeper's Log", "verb": "Read", "pos": [4.5, 1.0, 3.6], "size": [1.2, 0.5, 0.8], "text": "Fifty-one years of entries in neat pencil. 'Fog. Horn on at 4. Miss Ruthie in at 6, good catch, she says.' Weather, ships, birds. And three new entries this month, written harder than the rest, the pencil nearly through the page: 'Dark ship. No name, no flag, no lights. Berth 2. 1:05 AM. The lamp was OFF. I did not turn it off.'", "fx": "set read_keeper_log"},
		{"id": "beacon_ctl", "kind": "terminal", "title": "Smart Beacon Controller", "verb": "Use", "pos": [12.4, 1.2, 1.0], "size": [0.9, 1.6, 1.0], "hack": 30, "header": "E CORP SMART BEACON v2.1 // RAMSEY POINT", "welcome": "Navigation light, now with remote scheduling, cloud telemetry, and an end-user license agreement for a lighthouse.",
			"entries": [
				{"title": "Beacon schedule", "text": "BEACON OFF 00:45 – 01:30. Requested by: E Corp Logistics, berth control. Recurrence: 'as needed.' Notes: 'Do not notify keeper.' There is a keeper. He's been here since before the beacon was invented.", "fx": "set beacon_schedule"},
			],
			"actions": [
				{"title": "Put the light back on manual, permanently", "result": "You pull the smart controller out of the circuit and wire the lamp the way it was wired in 1962: a switch on the wall, a man who flips it. The cloud dashboard shows RAMSEY POINT: OFFLINE. The light shows the sea. Silas is going to cry. Leave before he does; he'd hate you to see it.", "fx": "set silas_lamp ; quest sq_keeper 30 ; fame locals 3 ; xp 100", "when": "q.sq_keeper>=10 & !flag.silas_lamp"},
			]},
		{"id": "keeper_bed", "kind": "bed", "title": "Keeper's Bunk", "verb": "Sleep", "pos": [1.2, 0.5, 4.6], "size": [2.2, 0.8, 1.0], "when": "flag.silas_lamp"},
	],
},
"pt_cannery": {
	"name": "Ocean Bright Cannery", "amb": "interior", "ambient": Color(0.26, 0.26, 0.28), "restricted": "darkarmy", "allowed_when": "day & !flag.pt_cannery_alarm",
	"rooms": [{"r": [0, 0, 30, 16], "h": 7.0, "wall": W_CONCRETE, "floor": F_CONCRETE, "light": Color(0.8, 0.85, 0.9), "energy": 0.75, "lights": [[6, 6.5, 8], [15, 6.5, 8], [24, 6.5, 8]]}],
	"exits": [{"pos": [15, 16], "face": "s", "to": "world:d_pt_cannery", "label": "Cannery Row"}],
	"furn": [["container_a", 5, 3, 90], ["container_b", 12, 3, 90], ["container_a", 19, 3, 90], ["crate", 25, 2, 0], ["crate", 26.2, 2, 0], ["crate", 25.6, 3.2, 0], ["shelf_industrial", 29.5, 8, -90], ["shelf_industrial", 29.5, 11, -90], ["lab_bench", 8, 12, 0], ["boxes", 3, 13, 0], ["boxes", 4.5, 13.5, 0], ["whiteboard", 0.2, 8, 90], ["trash_pile", 27, 14, 0]],
	"containers": [
		{"id": "cannery_crate", "title": "Export Crate", "pos": [25.6, 2.6], "y": 0.6, "size": [2.0, 1.2, 2.0], "items": {"hard_drive": 2, "scrap_electronics": 3}, "owner": "darkarmy", "lock": 35},
	],
	"spots": [
		{"id": "cannery_board", "kind": "text", "title": "Dispatch Board", "verb": "Read", "pos": [0.2, 1.6, 8.0], "size": [0.3, 1.2, 2.0], "text": "A whiteboard in two languages. Every night at 01:00: one container, one box truck, one driver, one destination, written the same way every time: 'WTE — DOCK 3 — B2.' Washington Township Energy. Somebody has drawn a tiny white rose in the corner, then rubbed it out with a thumb, not quite well enough.", "fx": "set pr_dispatch ; quest mq_pr1 50"},
		{"id": "cannery_rack", "kind": "text", "title": "Open Container", "verb": "Look", "pos": [12, 1.5, 3], "size": [2.6, 2.6, 6.0], "text": "Not turbine parts. Server racks, still in foam, white bezels with no logo at all, and a cable trunk as thick as your leg coiled on a pallet. A packing slip with nothing on it but a serial number and a date in 1993."},
	],
},
"pt_hangar": {
	"name": "Ramsey Field — Office", "amb": "office", "ambient": Color(0.44, 0.44, 0.42),
	"rooms": [{"r": [0, 0, 10, 8], "h": 3.2, "wall": Color(0.6, 0.62, 0.6), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.95, 0.92, 0.82), "energy": 1.05, "lights": [[5, 2.9, 4]]}],
	"exits": [{"pos": [10, 4], "face": "e", "to": "world:d_pt_hangar", "label": "Airport Road"}],
	"furn": [["counter", 5, 1.4, 0, {"w": 4.0}], ["desk_pc", 1.5, 1.5, 90], ["bench", 2, 6.5, 0, {"w": 2.4}], ["coffee_machine", 9.4, 0.6, 0], ["poster", 0.15, 4, 90, {"col": Color(0.2, 0.5, 0.8)}], ["plant", 9.4, 7.2, 0], ["window", 5, 7.85, 180, {"w": 2.0}]],
	"spots": [
		{"id": "ramsey_log", "kind": "text", "title": "Flight Log", "verb": "Read", "pos": [5.0, 1.1, 1.4], "size": [1.6, 0.6, 0.8], "text": "Ramsey Field. One runway, one office, one Marisol. The logbook: 'N1961K, Kearney Strip, Rx run, Walt.' Every Tuesday for two years in the same capitals. Then three Tuesdays with nothing. Then, under the last one, in Marisol's hand: 'Walt? Call me.'"},
		{"id": "ramsey_weather", "kind": "text", "title": "Weather Terminal", "verb": "Check", "pos": [1.5, 1.1, 1.5], "size": [1.0, 1.0, 1.0], "text": "Wind off the ocean, ten knots. Visibility good. West over I-80 to Kearney Strip in Washington Township: one airspace over and then another. Follow the county road; it runs straight there. North-west to Chicago, south-west to New York."},
	],
},
# ====================================================== GARY, INDIANA
"gy_union": {
	"name": "USW Local 1014 — Union Hall", "amb": "interior", "ambient": Color(0.4, 0.36, 0.32),
	"rooms": [{"r": [0, 0, 16, 10], "h": 4.0, "wall": Color(0.5, 0.42, 0.34), "floor": F_WOOD, "light": Color(1.0, 0.86, 0.62), "energy": 1.0, "lights": [[4, 3.7, 5], [12, 3.7, 5]]}],
	"exits": [{"pos": [8, 0], "face": "n", "to": "world:d_gy_union", "label": "Broadway"}],
	"furn": [["table", 8, 6.5, 0, {"w": 3.0, "d": 1.2}], ["chair", 7, 7.6, 180], ["chair", 9, 7.6, 180], ["seats", 4, 3.5, 180], ["seats", 12, 3.5, 180], ["coffee_machine", 15.4, 1.0, -90], ["boxes", 1.2, 9.0, 0], ["boxes", 2.6, 9.2, 0], ["poster", 0.15, 5, 90, {"col": Color(0.7, 0.15, 0.1)}], ["poster", 15.85, 5, -90, {"col": Color(0.7, 0.15, 0.1)}], ["trophies", 8, 9.6, 180], ["radiator", 0.3, 2.0, 90]],
	"spots": [
		{"id": "gy_union_photos", "kind": "text", "title": "Photo Wall", "verb": "Look", "pos": [8.0, 1.8, 9.8], "size": [6.0, 1.4, 0.3], "text": "A hundred years of Local 1014 in black and white and then color. The 1919 strike line, men in caps four deep on Broadway. A picnic in 1955 with a thousand people in it. The Christmas party, 1978. The last photo is from last year: forty people in front of the chained Gary Works gate, holding a bedsheet that says WE BUILT THIS. Then a gap on the wall where a banner used to hang."},
		{"id": "gy_union_flyers", "kind": "text", "title": "Flyers", "verb": "Read", "pos": [8.0, 1.0, 6.5], "size": [3.0, 0.6, 1.2], "text": "FREIGHTOS IS HIRING — ASK US WHY. A pay stub photocopied a hundred times, one line circled in red marker: 'ATTENTION DEDUCTION (BLINK EVENTS: 71) ........ $14.20.' Under it, in Marcus's handwriting: 'They pay you to watch the road and charge you for closing your eyes.'"},
	],
},
"gy_diner": {
	"name": "The Steel City Grill", "amb": "jazz", "ambient": Color(0.42, 0.36, 0.3),
	"rooms": [{"r": [0, 0, 14, 8], "h": 3.2, "wall": Color(0.55, 0.3, 0.22), "floor": Color(0.7, 0.68, 0.64), "floor_kind": "tile", "light": Color(1.0, 0.88, 0.7), "energy": 1.15, "lights": [[4, 2.9, 4], [10, 2.9, 4]]}],
	"exits": [{"pos": [7, 0], "face": "n", "to": "world:d_gy_diner", "label": "Broadway"}],
	"furn": [["bar_counter", 7, 6.6, 180, {"w": 8.0, "neon": Color(1.0, 0.55, 0.2)}], ["stool", 4.5, 5.4, 180], ["stool", 6, 5.4, 180], ["stool", 7.5, 5.4, 180], ["stool", 9, 5.4, 180], ["booth", 2, 1.8, 180, {"col": Color(0.6, 0.15, 0.1)}], ["booth", 6, 1.8, 180, {"col": Color(0.6, 0.15, 0.1)}], ["booth", 10, 1.8, 180, {"col": Color(0.6, 0.15, 0.1)}], ["jukebox", 13.4, 4, -90], ["coffee_machine", 10.5, 7.4, 180], ["window", 7, 0.15, 0, {"w": 8.0}]],
	"spots": [
		{"id": "gy_diner_shop", "kind": "shop", "title": "Counter", "verb": "Order", "pos": [7, 1, 5.6], "size": [8, 2, 1.2], "shop": "gen_diner"},
		{"id": "gy_diner_menu", "kind": "text", "title": "Menu Board", "verb": "Read", "pos": [3.0, 2.2, 7.8], "size": [2.4, 0.8, 0.3], "text": "THE OPEN HEARTH (two eggs, hash, toast) — $6. THE BLAST FURNACE (chili on everything) — $9. THE SHIFT CHANGE (coffee, refills till you leave) — $2. And a handwritten card taped in the corner: 'FreightOS operators eat half price. You look tired, baby. — Rosa.'"},
	],
},
"gy_ops": {
	"name": "FreightOS Depot — Control Tower", "amb": "office", "ambient": Color(0.36, 0.4, 0.46), "restricted": "ecorp", "allowed_when": "day & !flag.gy_alarm | disguise.ecorp",
	"rooms": [{"r": [0, 0, 18, 12], "h": 3.6, "wall": Color(0.2, 0.24, 0.3), "floor": Color(0.18, 0.2, 0.24), "floor_kind": "tile", "light": Color(0.7, 0.85, 1.0), "energy": 0.9, "lights": [[5, 3.3, 6], [13, 3.3, 6]]}],
	"exits": [{"pos": [9, 12], "face": "s", "to": "world:d_gy_tower", "label": "Depot Yard"}],
	"furn": [["monitor_wall", 9, 0.4, 0], ["desk_pc", 3, 3.5, 0], ["desk_pc", 6, 3.5, 0], ["desk_pc", 9, 3.5, 0], ["desk_pc", 12, 3.5, 0], ["desk_pc", 15, 3.5, 0], ["desk_pc", 3, 6.5, 0], ["desk_pc", 6, 6.5, 0], ["desk_pc", 9, 6.5, 0], ["desk_pc", 12, 6.5, 0], ["desk_pc", 15, 6.5, 0], ["office_desk", 16, 1.2, 0], ["water_cooler", 0.6, 11.0, 90], ["vending", 17.4, 10.5, -90], ["whiteboard", 0.15, 6, 90]],
	"spots": [
		{"id": "gy_ops_board", "kind": "text", "title": "Leaderboard", "verb": "Read", "pos": [0.2, 1.6, 6.0], "size": [0.3, 1.2, 2.0], "text": "OPERATOR FOCUS LEADERBOARD — WEEK 41. 1. J. BELL — 97.2% attention, 71 blink events. 2. T. KOWALSKI — 96.8%. 3. R. HALL — 96.1%. At the bottom, in red: 'Remember: autonomous trucks don't blink. Neither do champions!' Somebody has drawn a tiny pair of closed eyes next to it, peaceful, with Zs."},
		{"id": "fleet_term", "kind": "terminal", "title": "Fleet Operations Terminal", "verb": "Use", "pos": [16.0, 1.1, 1.2], "size": [1.4, 1.2, 0.9], "hack": 45, "header": "FREIGHTOS // GARY DEPOT // FLEET OPS", "welcome": "Two hundred trucks on a map of I-80 and I-90, every one tagged AUTONOMOUS. Click any of them and a face appears in the corner: the operator driving it, from a desk twenty feet behind you.",
			"entries": [
				{"title": "Operator telemetry", "text": "Eye tracking at 120 hertz on every operator. Every blink longer than 300 milliseconds is an 'attention event.' Every attention event is a deduction. The highest-scoring operator in the building, a J. Bell, has been docked $14.20 this week for 71 blinks. A note in the config file: 'Do not reduce threshold. Legal says drowsiness is the operator's liability, not ours.'"},
				{"title": "Pay sheet", "text": "Operators are 'independent mobility supervisors,' paid per mile driven, from $0.11 to $0.19. Shifts are sixteen hours with a twelve-minute unpaid break. Three hundred and four operators. Two hundred and ninety-one are former employees of Gary Works."},
				{"title": "Investor deck: 'Driverless'", "text": "Slide 7: 'Fully autonomous freight, zero labor exposure.' Slide 8, marked CONFIDENTIAL: 'Remote supervision bridges the autonomy gap. Operators are positioned as safety monitors to avoid driver classification.' Slide 9 is a stock photo of an empty truck cab at sunrise."},
			],
			"actions": [
				{"title": "Send every operator their own telemetry: every blink, every deduction", "result": "At 5:58 AM three hundred and four phones buzz in the parking lot. Every blink they were charged for, timestamped, with the dollar amount next to it. Nobody calls a meeting. Nobody has to. At six, the day shift doesn't come in.", "fx": "set gy_told ; quest sq_gy1 40 ; xp 140", "when": "q.sq_gy1>=20 & !flag.gy_fleet_hacked"},
				{"title": "Paint each operator's name and hourly wage on the side of their truck", "result": "Every trailer in the fleet has a digital side panel for ads. Now each one reads, in letters four feet high: DRIVEN BY J. BELL — $11.40/HR. DRIVEN BY T. KOWALSKI — $9.85/HR. Two hundred trucks rolling down I-80 telling everybody who's really driving and what he's worth to FreightOS.", "fx": "set gy_names ; set gy_fleet_hacked ; quest sq_gy1 40 ; xp 150", "when": "q.sq_gy1>=20 & !flag.gy_fleet_hacked"},
				{"title": "Pause the whole fleet for one hour: a strike, by software", "result": "At six AM every FreightOS truck in four states signals, pulls onto the shoulder, puts its hazards on and stops. Every screen in the tower goes black and then white: ONE HOUR — SOLIDARITY. The operators look at each other. Then, slowly, they stand up.", "fx": "set gy_strike ; set gy_fleet_hacked ; quest sq_gy1 40 ; infamy ecorp 2 ; xp 150", "when": "q.sq_gy1>=20 & !flag.gy_fleet_hacked"},
			]},
	],
},
"gy_millofc": {
	"name": "Gary Works — Main Office", "amb": "interior", "ambient": Color(0.22, 0.22, 0.24),
	"rooms": [
		{"r": [0, 0, 10, 8], "h": 3.4, "wall": Color(0.42, 0.4, 0.36), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.6, 0.65, 0.75), "energy": 0.45, "lights": [[5, 3.1, 4]]},
		{"r": [10, 0, 16, 8], "h": 3.4, "wall": Color(0.38, 0.32, 0.26), "floor": F_WOOD, "light": Color(0.65, 0.6, 0.55), "energy": 0.45, "lights": [[13, 3.1, 4]]},
	],
	"doors": [[10, 4, 1.2]],
	"exits": [{"pos": [5, 8], "face": "s", "to": "world:d_gy_millofc", "label": "Mill Yard"}],
	"furn": [["reception", 5, 2.0, 0, {"col": Color(0.3, 0.25, 0.2)}], ["filing_cabinet", 0.5, 4, 90], ["filing_cabinet", 0.5, 5, 90], ["trash_pile", 8.5, 6.5, 0], ["boxes", 2.0, 7.0, 0], ["bench", 7.0, 6.8, 0, {"w": 2.4}], ["poster", 5, 0.15, 0, {"col": Color(0.5, 0.3, 0.1)}],
		["office_desk", 13, 1.6, 0], ["bookshelf", 15.5, 4.5, -90], ["clock", 13, 0.2, 0, {"y": 2.4}], ["safe", 10.8, 7.2, 90], ["window", 13, 7.85, 180, {"w": 2.0}]],
	"containers": [
		{"id": "gy_banner_case", "title": "Glass Case", "pos": [12.0, 4.6], "y": 1.2, "size": [2.4, 1.6, 0.4], "items": {"union_banner": 1}, "owner_ok": "true", "fx_open": "quest sq_gy2 30"},
		{"id": "gy_super_safe", "title": "Superintendent's Safe", "pos": [10.8, 7.2], "y": 0.5, "size": [0.8, 1.0, 0.8], "items": {"gold_chain": 1, "watch": 1}, "cash": 140, "lock": 55},
	],
	"spots": [
		{"id": "gy_millofc_clock", "kind": "text", "title": "Punch Clock", "verb": "Look", "pos": [5.0, 1.4, 0.4], "size": [1.0, 1.0, 0.4], "text": "A brass punch clock and a rack of cards, a hundred of them still in their slots. The last card in the rack, KOWALSKI T., is punched IN on the last day and never punched OUT. Someone has written on the wall above it in marker: 'WE'RE STILL ON SHIFT.'"},
	],
},
"gy_cluster": {
	"name": "SlopForge Training Cluster", "amb": "office", "ambient": Color(0.3, 0.36, 0.34), "restricted": "ecorp", "allowed_when": "disguise.ecorp",
	"rooms": [{"r": [0, 0, 24, 12], "h": 5.0, "wall": Color(0.12, 0.14, 0.16), "floor": F_CONCRETE, "light": Color(0.45, 0.95, 0.55), "energy": 0.85, "lights": [[6, 4.6, 6], [18, 4.6, 6]]}],
	"exits": [{"pos": [12, 12], "face": "s", "to": "world:d_gy_cluster", "label": "Mill Yard"}],
	"furn": [["server_rack", 3, 1.2, 0, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 5, 1.2, 0, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 7, 1.2, 0, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 9, 1.2, 0, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 11, 1.2, 0, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 13, 1.2, 0, {"led": Color(0.35, 1.0, 0.45)}],
		["server_rack", 3, 6.0, 180, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 5, 6.0, 180, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 7, 6.0, 180, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 9, 6.0, 180, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 11, 6.0, 180, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 13, 6.0, 180, {"led": Color(0.35, 1.0, 0.45)}],
		["tape_library", 17, 1.2, 0], ["tape_library", 19, 1.2, 0], ["climate_unit", 23.4, 6, -90], ["desk_pc", 22, 1.2, 0], ["logo_wall", 12, 11.85, 180, {"w": 6.0, "glow": Color(0.35, 1.0, 0.45)}]],
	"spots": [
		{"id": "slop_console", "kind": "terminal", "title": "SlopForge Training Console", "verb": "Use", "pos": [22.0, 1.1, 1.2], "size": [1.4, 1.2, 0.9], "hack": 55, "when": "q.sq_gy3>=10", "header": "SLOPFORGE // TRAINING // EPOCH 41", "welcome": "Loss curve trending down. 'Creativity index' trending up. Training set: 'acquired studio assets (all).'",
			"entries": [
				{"title": "Training set manifest", "text": "Seventeen closed studios, twenty-two years of work: source code, concept art, voice sessions, motion capture, design documents, a level designer's personal notebook scanned page by page. Labelled 'acquired assets, rights cleared.' The rights were cleared by the studios being closed."},
				{"title": "Output samples", "text": "'BLADE FORGE 4 (generated).' It's the first level of Blade Forge 2, almost exactly, with the hero's face averaged into nobody and the music re-hummed slightly flat. The level designer's notebook doodles are in the background textures. You recognise a QA tester's joke from Kenny's old Twitter, baked into a loading screen."},
			],
			"actions": [
				{"title": "Delete the whole training set and every checkpoint", "result": "Twenty-two years of other people's work, wiped out of the machine that was eating it, and every model checkpoint with it. The loss curve flatlines. SlopForge goes back to knowing nothing, which is the only thing it ever honestly knew.", "fx": "set slop_deleted ; set slop_done ; quest sq_gy3 30 ; xp 160", "when": "!flag.slop_done"},
				{"title": "Give every closed studio its own work back", "result": "Seventeen archives, one per studio, sent to the last address of every developer on every credit list, with a note: 'This was always yours.' Then the cluster's copies go. Half the internet's game developers are on Discord within the hour, crying and arguing about whether they can just start again.", "fx": "set slop_returned ; set slop_done ; quest sq_gy3 30 ; fame gamers 3 ; xp 180", "when": "!flag.slop_done"},
				{"title": "Teach it one thing: every game ends with the credits of the people it was made from", "result": "You don't delete anything. You add a rule at the very bottom of the model's training, where it will never forget it: every output ends with the full credits of every person whose work it learned from, unskippable. Forty minutes of names. It will learn to make games. It will never again learn to forget who made them.", "fx": "set slop_credits ; set slop_done ; quest sq_gy3 30 ; xp 170", "when": "!flag.slop_done"},
			]},
	],
},
"gy_hangar": {
	"name": "Gary/Chicago Airport — Office", "amb": "office", "ambient": Color(0.44, 0.44, 0.42),
	"rooms": [{"r": [0, 0, 10, 8], "h": 3.2, "wall": Color(0.62, 0.6, 0.56), "floor": F_TILE, "floor_kind": "tile", "light": Color(0.95, 0.92, 0.82), "energy": 1.05, "lights": [[5, 2.9, 4]]}],
	"exits": [{"pos": [10, 4], "face": "e", "to": "world:d_gy_hangar", "label": "Airport Road"}],
	"furn": [["counter", 5, 1.4, 0, {"w": 4.0}], ["desk_pc", 1.5, 1.5, 90], ["bench", 2, 6.5, 0, {"w": 2.4}], ["coffee_machine", 9.4, 0.6, 0], ["poster", 0.15, 4, 90, {"col": Color(0.8, 0.5, 0.1)}], ["plant", 9.4, 7.2, 0], ["window", 5, 7.85, 180, {"w": 2.0}]],
	"spots": [
		{"id": "gy_airport_log", "kind": "text", "title": "Flight Log", "verb": "Read", "pos": [5.0, 1.1, 1.4], "size": [1.6, 0.6, 0.8], "text": "Gary/Chicago Airport. The log goes back to 1949: DC-3s, a Beatles charter in 1964, cargo 727s, a regional jet service that lasted eleven months. The last six months are two Skyhawks and the same initials, L.P., every day, on 'local pattern work.' Practice landings. Hundreds of them. Nobody to fly anywhere. Somebody keeping her hand in, just in case."},
	],
},
"rockstarved_hq": {
	"name": "Rockstarved Games — Floor 88", "amb": "office", "ambient": Color(0.34, 0.3, 0.3), "restricted": "ecorp", "allowed_when": "item.rs_badge>=1 & !flag.rs_alarm",
	"rooms": [
		{"r": [0, 0, 10, 8], "h": 3.4, "wall": Color(0.16, 0.14, 0.14), "floor": Color(0.22, 0.2, 0.2), "floor_kind": "tile", "light": Color(1.0, 0.7, 0.35), "energy": 1.0, "lights": [[5, 3.1, 4]]},
		{"r": [10, 0, 28, 12], "h": 3.4, "wall": Color(0.5, 0.5, 0.52), "floor": F_CARPET, "floor_kind": "tile", "light": Color(0.85, 0.9, 1.0), "energy": 0.9, "lights": [[14, 3.1, 3], [22, 3.1, 3], [14, 3.1, 9], [22, 3.1, 9]]},
		{"r": [0, 8, 10, 16], "h": 3.4, "wall": W_DARK, "floor": F_CONCRETE, "light": Color(1.0, 0.45, 0.2), "energy": 0.75, "lights": [[5, 3.1, 12]]},
	],
	"doors": [[10, 4, 1.4], [5, 8, 1.2]],
	"exits": [{"pos": [5, 0], "face": "n", "to": "interior:wtc_lobby:2", "label": "Elevator — Lobby"}],
	"furn": [
		["reception", 5, 2.0, 0, {"col": Color(0.12, 0.1, 0.1), "glow": Color(1.0, 0.6, 0.15)}], ["logo_wall", 5, 0.15, 0, {"w": 6.0, "glow": Color(1.0, 0.55, 0.1)}], ["plant", 0.8, 7.2, 0], ["bench", 8.8, 6.5, -90, {"w": 2.4}], ["poster", 0.15, 4, 90, {"col": Color(0.9, 0.5, 0.1)}],
		["desk_pc", 13, 2.5, 90], ["desk_pc", 13, 5.5, 90], ["desk_pc", 17, 2.5, -90], ["desk_pc", 17, 5.5, -90], ["desk_pc", 21, 2.5, 90], ["desk_pc", 21, 5.5, 90], ["desk_pc", 25, 2.5, -90], ["desk_pc", 25, 5.5, -90], ["whiteboard", 22, 11.85, 180], ["water_cooler", 27.4, 8.5, -90], ["coffee_machine", 27.4, 9.6, -90],
		["mattress", 13, 10.5, 0], ["mattress", 17, 10.5, 0], ["boxes", 20.5, 11.2, 0], ["trash_pile", 26.8, 11.2, 0],
		["server_rack", 1.2, 9.5, 90, {"led": Color(1.0, 0.5, 0.1)}], ["server_rack", 1.2, 10.7, 90, {"led": Color(1.0, 0.5, 0.1)}], ["server_rack", 1.2, 11.9, 90, {"led": Color(1.0, 0.5, 0.1)}], ["monitor_wall", 9.6, 12, -90], ["conference", 5.5, 13.8, 0],
	],
	"containers": [
		{"id": "rs_desk", "title": "Crunch Desk", "pos": [13, 5.5], "y": 0.6, "size": [0.8, 0.7, 1.4], "loot": "office_desk", "items": {"energy_drink": 3}},
	],
	"spots": [{"id": "rs_whale", "kind": "terminal", "title": "Project Whale Server", "verb": "Access", "pos": [1.6, 1.2, 10.7], "size": [1.2, 1.8, 3.6], "hack": 50, "header": "WHALE.ROCKSTARVED.CORP  //  RECURRENT CONSUMER SPENDING", "welcome": "Player Value Optimization Engine. 31 million profiles, sorted by how much can be squeezed from each one.",
		"entries": [
			{"title": "Read: 'Who is the player?'", "text": "Internal onboarding deck. Slide 2: 'The player is not a customer. The player is a funnel. The top 0.6% of players ('whales') produce 51% of recurrent revenue. Everyone else is content for the whales to feel superior to.'", "fx": "give whale_docs 1 ; quest mq_rs1 30 ; quest mq_rs1 done ; quest mq_rs2 10"},
			{"title": "Read: the kid flagged 'HIGH VALUE'", "text": "Account age 11 months. Age on file: 14. 207 Shark Card purchases in 31 days, accelerating, on one saved card. A junior analyst flagged it: 'possible minor, possible compromised card, recommend review.' A manager closed the ticket: 'do not interrupt a converting session.'"},
		],
		"actions": [
			{"title": "Dump Project Whale to every games site on Earth", "result": "The whole engine, the slides, the 'funnel,' the closed ticket about the fourteen-year-old. Every outlet runs it by morning. 'THE PLAYER IS A FUNNEL' is a headline, then a chant. Rockstarved's PR account posts a notes-app apology and turns off replies. Too late. The replies are everywhere now.", "fx": "set rs_press ; set rs_down ; set rs_done ; quest mq_rs1 done ; quest mq_rs2 20 ; fame gamers 8 ; infamy ecorp 6 ; xp 200", "when": "item.whale_docs>=1 & !flag.rs_done"},
			{"title": "Crash the Shark Card store and refund every purchase from the last year", "result": "The pretend-money store goes dark and stays dark. Then every real dollar spent on it in the last year reverses, all at once, to every card it came from. A fourteen-year-old in Pixel's Discord gets his late mother's savings back, to the cent. Rockstarved's finance team watches a year of 'recurrent revenue' evaporate in ninety seconds.", "fx": "set rs_refund ; set rs_down ; set rs_done ; quest mq_rs1 done ; quest mq_rs2 20 ; fame gamers 9 ; infamy ecorp 7 ; stab 4 ; xp 220", "when": "item.whale_docs>=1 & !flag.rs_done"},
		]}],
},
"ms_floor": {
	"name": "Microslop Showcase — Floor 101", "amb": "office", "ambient": Color(0.36, 0.38, 0.44), "restricted": "ecorp", "allowed_when": "item.ms_invite>=1 & !flag.ms_alarm",
	"rooms": [
		{"r": [0, 0, 24, 14], "h": 6.0, "wall": Color(0.12, 0.14, 0.18), "floor": Color(0.2, 0.22, 0.26), "floor_kind": "tile", "light": Color(0.45, 0.9, 0.55), "energy": 1.1, "lights": [[6, 5.6, 4], [18, 5.6, 4], [6, 5.6, 10], [18, 5.6, 10]]},
		{"r": [24, 0, 36, 14], "h": 4.0, "wall": W_DARK, "floor": F_CONCRETE, "light": Color(0.5, 0.95, 0.6), "energy": 0.8, "lights": [[28, 3.6, 4], [32, 3.6, 10]]},
	],
	"doors": [[24, 7, 1.4]],
	"exits": [{"pos": [12, 14], "face": "s", "to": "interior:wtc_lobby:3", "label": "Elevator — Lobby"}],
	"furn": [
		["stage", 12, 2.2, 0, {"w": 14.0, "d": 3.6}], ["screen_fold", 12, 0.4, 0], ["logo_wall", 12, 0.15, 0, {"w": 10.0, "glow": Color(0.35, 1.0, 0.45)}], ["seats", 7, 8, 0], ["seats", 12, 8, 0], ["seats", 17, 8, 0],
		["plant", 1, 13, 0], ["plant", 23, 13, 0], ["display_case", 2, 6, 90], ["display_case", 22, 6, -90], ["vending", 1, 10, 90], ["poster", 0.15, 3, 90, {"col": Color(0.2, 0.8, 0.3)}],
		["server_rack", 26, 1.2, 0, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 28, 1.2, 0, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 30, 1.2, 0, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 32, 1.2, 0, {"led": Color(0.35, 1.0, 0.45)}],
		["tape_library", 34.6, 4, -90], ["server_rack", 26, 12.8, 180, {"led": Color(0.35, 1.0, 0.45)}], ["server_rack", 28, 12.8, 180, {"led": Color(0.35, 1.0, 0.45)}], ["desk_pc", 31, 11, 180], ["climate_unit", 34.6, 11, -90], ["boxes", 25, 6, 0],
	],
	"containers": [
		{"id": "ms_swag", "title": "Swag Table", "pos": [22, 12], "y": 0.6, "size": [1.4, 0.8, 0.8], "items": {"energy_drink": 2, "usb_drive": 1}, "owner_ok": "true"},
	],
	"spots": [
		{"id": "ms_keynote", "kind": "text", "title": "Keynote Teleprompter", "verb": "Read", "pos": [12, 1.6, 4.2], "size": [1.2, 0.8, 0.6], "text": "'...and with Game Pass Away, you'll never have to OWN anything again. [PAUSE FOR APPLAUSE.] Every game ever made, one low monthly price, forever, or until we change it. [DO NOT SAY 'until we change it.'] And thanks to SlopForge AI, the studios we acquired last year will keep making the games you love. [DO NOT MENTION the studios were closed in March.]'"},
		{"id": "ms_display", "kind": "text", "title": "Display Case", "verb": "Look", "pos": [2, 1.2, 6], "size": [1.0, 1.4, 1.6], "text": "A shrine to every studio Microslop has bought, each logo on a tiny velvet pillow. Next to most of them, a small brass plaque: 'Sunset.' A date. Then a smaller line: 'Legacy honoured through subscription access.' Somebody has scratched 'R.I.P.' into the glass with a key, eleven times."},
		{"id": "ms_vault", "kind": "terminal", "title": "The Library", "verb": "Access", "pos": [31, 1.2, 11], "size": [1.2, 1.4, 1.0], "hack": 65, "password_flag": "ms_pw", "header": "LIBRARY.MICROSLOP.CORP  //  MASTER LICENSE AUTHORITY", "welcome": "Every license for every game from every studio Microslop owns. 2.1 billion entitlements. One switch.",
			"entries": [
				{"title": "Read: 'Project Sunset' playbook", "text": "A slide deck with a cheerful sun on every page. Step 1: acquire beloved studio. Step 2: announce 'nothing will change.' Step 3: move its games into Game Pass Away. Step 4: close the studio. Step 5: delist the games from every store, so the subscription is the only way to play them. 'Ownership is friction. Sunset removes friction.'"},
				{"title": "Read: SlopForge training data", "text": "The AI that 'makes' the new games was trained on every asset, script and voice line from the studios Microslop closed. The people who made them got two weeks' severance and an NDA. Their work got a subscription tier. A note from legal: 'Recommend we stop calling it inspired by.'", "fx": "set ms_slop_known"},
				{"title": "Read: Game Pass Away launch switch", "text": "At 9:00 AM Friday every purchased copy of every Microslop-owned game becomes a 'subscription entitlement.' Stop paying and your library goes dark. Pending sign-off: B. Pitchley. Status: signed."},
			],
			"actions": [
				{"title": "Flip the switch backwards: every game anyone ever rented becomes theirs, DRM-free, forever", "when": "!flag.ms_done", "result": "At 9:00 AM the switch fires, but it fires the other way. Every subscription entitlement on Earth becomes a permanent, offline, no-account-required copy. Two billion libraries, owned. Microslop's stock halts trading twice before lunch. Somebody in Ohio boots a game from 2004 with no internet and cries at a loading screen.", "fx": "set ms_done ; set ms_freed ; quest mq_ms 50 ; fame gamers 10 ; infamy microslop 10 ; infamy ecorp 4 ; xp 300"},
				{"title": "Open the books: send Project Sunset and SlopForge to every regulator, every press desk, every studio Microslop owns", "when": "!flag.ms_done", "result": "Every employee of every studio Microslop owns gets the deck at once. So do eleven regulators and every games desk on the planet. By noon three acquisitions are frozen. By evening the developers of SlopForge's 'training data' have a lawyer, a class action, and a name for it. Microslop cancels the keynote. Brad Pitchley's badge stops working at 4:12 PM.", "fx": "set ms_done ; set ms_exposed ; quest mq_ms 50 ; fame gamers 8 ; infamy microslop 8 ; fame locals 3 ; xp 300"},
				{"title": "Give it back: hand every closed studio its games, its source code and its name", "when": "!flag.ms_done & flag.ms_slop_known", "result": "The rights to every 'sunset' studio's catalogue are quietly transferred, with source code, to trusts run by the people who made the games. It takes the lawyers a week to notice and a year to argue about, and by then forty studios have reopened under their old names, in rented rooms, making the sequels nobody would fund. SlopForge loses its training data and starts producing nothing but loading screens.", "fx": "set ms_done ; set ms_returned ; quest mq_ms 50 ; fame gamers 9 ; infamy microslop 9 ; stab 3 ; xp 320"},
			]},
	],
},
"wtc_lobby": {
	"name": "World Trade Center — North Tower", "amb": "office", "ambient": Color(0.42, 0.42, 0.44),
	"rooms": [{"r": [0, 0, 24, 14], "h": 7.0, "wall": Color(0.7, 0.7, 0.72), "floor": Color(0.62, 0.6, 0.56), "floor_kind": "tile", "light": Color(0.95, 0.96, 1.0), "energy": 1.4, "lights": [[6, 6.5, 4], [18, 6.5, 4], [6, 6.5, 10], [18, 6.5, 10]]}],
	"exits": [
		{"pos": [12, 14], "face": "s", "to": "world:d_wtc", "label": "Plaza"},
		{"pos": [12, 0], "face": "n", "to": "roof:wtc", "label": "Express Elevator — Roof"},
		{"pos": [3, 0], "face": "n", "to": "interior:rockstarved_hq:0", "label": "Elevator — Floor 88: Rockstarved Games", "when": "q.mq_rs1>=10", "lock": 60, "key": "rs_badge", "unlock_when": "item.rs_badge>=1"},
		{"pos": [20, 0], "face": "n", "to": "interior:ms_floor:0", "label": "Elevator — Floor 101: Microslop Showcase", "when": "q.mq_ms>=20", "lock": 80, "key": "ms_invite", "unlock_when": "item.ms_invite>=1"},
	],
	"furn": [["logo_wall", 5.0, 0.12, 0, {"w": 6.0, "glow": Color(0.85, 0.9, 1.0)}], ["elevator", 17.0, 0.12, 0], ["elevator", 20.0, 0.12, 0], ["elevator", 3.0, 0.12, 0],
		["turnstile", 12.0, 5.5, 0], ["security_desk", 18.0, 8.0, 180], ["reception", 6.0, 8.0, 180, {"glow": Color(0.85, 0.9, 1.0)}],
		["plant", 1.0, 13.0, 0], ["plant", 23.0, 13.0, 0], ["plant", 1.0, 1.0, 0], ["plant", 23.0, 1.0, 0],
		["bench", 3.0, 11.5, 0, {"w": 2.4}], ["bench", 21.0, 11.5, 0, {"w": 2.4}], ["window", 6.0, 13.85, 180, {"w": 3.0, "col": Color(0.55, 0.6, 0.65)}], ["window", 18.0, 13.85, 180, {"w": 3.0, "col": Color(0.55, 0.6, 0.65)}]],
	"spots": [
		{"id": "wtc_directory", "kind": "text", "title": "Building Directory", "verb": "Read", "pos": [9.0, 1.4, 0.4], "size": [1.4, 1.6, 0.4], "text": "FLOORS 1-43: Port Authority, law firms, a bank. FLOORS 44-83: E CORP (restricted). FLOORS 84-106: brokerages. FLOOR 107: WINDOWS ON THE WORLD. ROOF: Observation. 'Visitors must sign in.' Nobody has signed in since Tuesday."},
		{"id": "wtc_plaque", "kind": "text", "title": "Dedication Plaque", "verb": "Read", "pos": [15.0, 1.2, 13.6], "size": [1.2, 1.2, 0.4], "text": "'Dedicated to world peace through trade.' Somebody scratched a small E into the corner. The ownership papers say the same thing, just longer."},
	],
},
}
