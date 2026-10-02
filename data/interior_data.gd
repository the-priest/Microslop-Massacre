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
		{"id": "apt_pc", "kind": "terminal", "title": "Your Workstation", "verb": "Log in", "pos": [5.4, 1.2, 1.4], "size": [1.4, 1.4, 1.0], "user": "elliot", "welcome": "root@elliot:~# whoami\nelliot. probably.\n\n3 unread messages. 1 has no sender.", "entries": [
			{"title": "mail: Gideon Goddard  [URGENT]", "text": "Elliot, E Corp got hit tonight. Their edge servers lit up like Christmas and now their CTO's office is lighting ME up. Somebody knocked on the CS30 honeypot, the one we left open on purpose. I need you at Allsafe. Now. I know it's late. I'm sorry. I'm not sorry. Midtown, the glass building, you know the one. -G", "fx": "set read_gideon ; quest mq_hello 30"},
			{"title": "mail: (no sender)  hello_friend.txt", "text": "Hello, Elliot.\n\nWe've been watching the same people you have. You hack them to understand them. We hack them to end them.\n\nYou know the name Washington Township. Your father's name is on that memorial. E Corp paid a fine smaller than their coffee budget and called it justice. Every loan they hold is a leash, and every leash is backed up somewhere. We know where.\n\nThe honeypot tonight wasn't an accident. Someone left the door open. A coffee shop on the Lower East Side, Ron's, runs a server that talks to it. When you get there, you'll find a rootkit on your own desktop that you don't remember writing. Put it on that server. Then come find us.\n\nWe are fsociety. We are finally awake.", "fx": "set fsociety_msg"},
			{"title": "sms: Shayla", "text": "u home?? i have the good stuff and the bad stuff. also some guy named vera was asking about u. dont answer if he calls lol. unless u want to. dont. come say hi im in the hallway"},
			{"title": "news: tonight's headlines", "text": "E CORP DENIES NETWORK BREACH: 'Our systems are secure,' says SVP Tyrell Wellick.\nPRICE: E COIN 'THE FUTURE OF MONEY.' Critics: 'a future E Corp owns.'\nTOWNSHIP FAMILIES MARK 22 YEARS WITHOUT A TRIAL.\nMASKED PROTESTERS AT THE TWIN TOWERS PLAZA. A cartoon face, a top hat, a message: 'WE ARE FSOCIETY.'\nBRONX: SIX TEENAGE OVERDOSES IN A MONTH NEAR THE CARVER HOUSES. 'Candy,' residents call it. Police: 'no leads.'\nHARLEM SHELTER COUNSELOR: 'I CALLED THE POLICE TWICE. NOBODY WILL LISTEN.'\nNYPD: MUGGINGS UP IN THE BRONX AS SHELTERS CLOSE."},
			{"title": "app: CourierNet (jobs)", "text": "Cash work, no questions. Deliveries, repo, 'data recovery', bounties. Press J on your phone for DATA > JOBS any time. Up to three contracts at once. The money's real. So is the risk."},
			{"title": "cat drafts/krista.txt", "text": "Dear Krista, today I felt almost — [delete]. She gets the truth in installments I can't afford."},
		], "actions": [{"title": "Feed Qwerty (remotely, you monster)", "result": "The auto-feeder clicks. The fish forgives you. Fish always forgive.", "fx": "trust krista 0"}]},
		{"id": "apt_bed_spot", "kind": "bed", "title": "Your Bed", "verb": "Sleep", "pos": [1.6, 0.6, 4.4], "size": [1.6, 1, 2.2]},
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
		{"id": "allsafe_terminal", "kind": "terminal", "title": "Allsafe Workstation", "verb": "Log in", "pos": [11.5, 1.2, 4.0], "size": [0.7, 1.4, 1], "hack": 25, "header": "cs30.allsafe.lan", "welcome": "Allsafe internal. Gideon's watching the watchers now.", "entries": [{"title": "Read: E Corp contract", "text": "Allsafe holds the E Corp security contract. One client. If E Corp walks, Gideon's company dies. Everyone here is one bad day from unemployed.", "fx": "set knows_allsafe_ecorp"}, {"title": "Read: honeypot alert", "text": "Someone left a honeypot server (CS30) exposed. Deliberately. Someone inside wants a door left open."}], "actions": [{"title": "Scrub the intrusion logs", "result": "The logs forget you were ever here. Gideon will never know. You will.", "fx": "set scrubbed_logs ; infamy allsafe 1", "when": "q.mq_rootkit>=20"}]},
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
	"name": "Stash House", "amb": "interior", "ambient": Color(0.22, 0.2, 0.2), "restricted": "vera", "allowed_when": "false",
	"rooms": [
		{"r": [0, 0, 9, 7], "h": 2.9, "wall": Color(0.24, 0.2, 0.18), "floor": F_CONCRETE, "light": Color(0.7, 0.5, 0.4), "energy": 0.7, "lights": [[4.5, 2.6, 3.5]]},
		{"r": [9, 2, 14, 6], "h": 2.9, "wall": W_DARK, "floor": F_CONCRETE, "light": Color(0.9, 0.3, 0.3), "energy": 0.6},
	],
	"doors": [[9, 4, 1.1]],
	"exits": [{"pos": [4.5, 7], "face": "s", "to": "world:d_vera", "label": "Out"}],
	"furn": [["mattress", 1.6, 5, 0], ["table", 4.5, 3, 0], ["chair", 3.5, 3, 90], ["chair", 5.5, 3, -90], ["boxes", 0.6, 1, 0], ["shelf_industrial", 8, 6, 0], ["cell_bars", 11.5, 2.2, 0, {"w": 4}], ["mattress", 11.5, 5, 0], ["trash_pile", 6, 6, 0]],
	"containers": [
		{"id": "vera_ledger_box", "title": "Vera's Safe", "pos": [8, 6], "y": 1.0, "size": [1.4, 1, 0.9], "lock": 60, "items": {"vera_ledger": 1, "cash": 0}, "cash": 400, "owner": "vera", "owner_ok": "dead.vera", "fx_open": "quest sq_shayla 40"},
	],
	"spots": [{"id": "shayla_cell", "kind": "convo", "title": "The Cell", "verb": "Approach", "pos": [11.5, 1.2, 3.5], "size": [4, 2, 1.5], "convo": "shayla_rescue", "when": "q.sq_shayla>=30"}],
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
	"spots": [{"id": "hosp_shop", "kind": "shop", "title": "Hospital Pharmacy", "verb": "Buy", "pos": [13.5, 1.0, -2.0], "size": [4.0, 1.6, 1.2], "shop": "pharmacy"}],
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
		{"id": "credit_mgr", "kind": "terminal", "title": "Branch Manager's PC", "verb": "Use", "pos": [17.0, 1.1, 1.0], "size": [1.4, 1.2, 0.9], "hack": 35, "header": "E CORP CONSUMER CREDIT  //  BRANCH 0419", "welcome": "Collections dashboard. A leaderboard of employees ranked by 'recoveries'. Someone named Gary is winning.",
			"entries": [{"title": "Collections: top 10 delinquent accounts", "text": "Ten families, ten numbers. A widow in Astoria three months behind on a loan for her husband's funeral. A Greek diner in Astoria being 'restructured' into bankruptcy. A shelter in Harlem whose line of credit was frozen the week after its counselor complained to the press. The notes field on every one says the same thing: 'Escalate.'"}],
			"actions": [{"title": "Mark all ten accounts 'settled in full'", "result": "Ten records change color from red to green. The system will catch it in a month, maybe two. For a month, maybe two, ten families will open letters that say THANK YOU instead of FINAL NOTICE.", "fx": "set credit_forgiven ; fame locals 4 ; fame harlem 3 ; infamy ecorp 3 ; stab 4 ; xp 40", "when": "!flag.credit_forgiven"}]},
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
	"name": "Steel Mountain", "amb": "interior", "ambient": Color(0.4, 0.42, 0.46), "restricted": "ecorp", "allowed_when": "disguise.steel | flag.steel_badge_used",
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
	"spots": [{"id": "steel_climate", "kind": "convo", "title": "Climate Control Unit", "verb": "Rig", "pos": [20, 1.2, 7], "size": [1.8, 2, 1], "convo": "steel_climate", "when": "item.raspberry_pi>=1"}],
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
"wtc_lobby": {
	"name": "World Trade Center — North Tower", "amb": "office", "ambient": Color(0.42, 0.42, 0.44),
	"rooms": [{"r": [0, 0, 24, 14], "h": 7.0, "wall": Color(0.7, 0.7, 0.72), "floor": Color(0.62, 0.6, 0.56), "floor_kind": "tile", "light": Color(0.95, 0.96, 1.0), "energy": 1.4, "lights": [[6, 6.5, 4], [18, 6.5, 4], [6, 6.5, 10], [18, 6.5, 10]]}],
	"exits": [
		{"pos": [12, 14], "face": "s", "to": "world:d_wtc", "label": "Plaza"},
		{"pos": [12, 0], "face": "n", "to": "roof:wtc", "label": "Express Elevator — Roof"},
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
