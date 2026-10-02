class_name WorldObjects
extends RefCounted
## Outdoor containers, pickups, scripted spots and story triggers in the city.

const CONTAINERS := [
	{"id": "wc_dump_les1", "title": "Dumpster", "pos": [-453.5, 325.3], "y": 0.7, "size": [2, 1.4, 1.2], "loot": "dumpster"},
	{"id": "wc_dump_les2", "title": "Dumpster", "pos": [-615, 330], "y": 0.7, "size": [2, 1.4, 1.2], "loot": "dumpster"},
	{"id": "wc_dump_mid1", "title": "Dumpster", "pos": [-330, -240], "y": 0.7, "size": [2, 1.4, 1.2], "loot": "dumpster"},
	{"id": "wc_dump_hells", "title": "Dumpster", "pos": [-490, 100], "y": 0.7, "size": [2, 1.4, 1.2], "loot": "dumpster"},
	{"id": "wc_dump_china", "title": "Dumpster", "pos": [470, 420], "y": 0.7, "size": [2, 1.4, 1.2], "loot": "dumpster"},
	{"id": "wc_dump_dock", "title": "Crate", "pos": [-728, -320], "y": 0.5, "size": [1, 1, 1], "loot": "crate"},
	{"id": "wc_dump_ind", "title": "Crate", "pos": [510, -555], "y": 0.5, "size": [1, 1, 1], "loot": "crate"},
	{"id": "wc_trash_park", "title": "Trash Can", "pos": [-90, 90], "y": 0.5, "size": [0.7, 0.9, 0.7], "loot": "trash"},
	{"id": "wc_coney_crate", "title": "Boardwalk Crate", "pos": [40, 700], "y": 0.5, "size": [1, 1, 1], "loot": "crate"},
]

## Rules for every searchable prop the city builder registers in the LootIndex.
## lock: [chance, dc_min, dc_max] rolled deterministically per prop.
## restock: in-game days until an emptied prop refills (0 = never).
## owner: faction that calls it stealing if they see you.
const LOOT_KINDS := {
	"trash": {"title": "Trash Can", "verb": "Search", "loot": "trash", "restock": 2},
	"bags": {"title": "Trash Bags", "verb": "Search", "loot": "trash", "restock": 2},
	"newsbox": {"title": "Newspaper Box", "verb": "Search", "loot": "newsbox", "restock": 3},
	"mailbox": {"title": "Mailbox", "verb": "Search", "loot": "mailbox", "restock": 4, "lock": [0.5, 15, 35]},
	"food_cart": {"title": "Food Cart", "verb": "Search", "loot": "food_cart", "restock": 1, "owner": "locals"},
	"phone": {"title": "Pay Phone", "verb": "Check coin return", "loot": "payphone", "restock": 2},
	"car": {"title": "Parked Car", "verb": "Search glovebox", "loot": "glovebox", "restock": 7, "lock": [0.55, 15, 50]},
	"taxi": {"title": "Taxi", "verb": "Search", "loot": "taxi", "restock": 5, "lock": [0.5, 20, 40]},
	"dumpster": {"title": "Dumpster", "verb": "Search", "loot": "dumpster", "restock": 3},
	"crate": {"title": "Crate", "verb": "Search", "loot": "crate", "restock": 5},
	"shipping": {"title": "Shipping Container", "verb": "Open", "loot": "shipping", "restock": 10, "lock": [0.7, 30, 65]},
	"truck": {"title": "Delivery Truck", "verb": "Search cab", "loot": "truck", "restock": 6, "lock": [0.5, 25, 45]},
	"stash": {"title": "Hidden Stash", "verb": "Search", "loot": "street_stash", "restock": 0},
	"atm": {"title": "ATM", "verb": "Use"},
}

const PICKUPS := [
	# Unique weapons, hidden around the city. Each one is worth the walk.
	{"id": "wu_whitehat", "item": "u_whitehat", "count": 1, "pos": [-702, 0.35, -770]},
	{"id": "wu_zero_day", "item": "u_zero_day", "count": 1, "pos": [712, 0.35, -772]},
	{"id": "wu_kernel_panic", "item": "u_kernel_panic", "count": 1, "pos": [-28, 0.35, 876]},
	{"id": "wu_patch_tuesday", "item": "u_patch_tuesday", "count": 1, "pos": [-402, 0.35, 668]},
	{"id": "wu_the_daemon", "item": "u_the_daemon", "count": 1, "pos": [-112, 380.55, 341]},
	{"id": "wu_honeypot", "item": "u_honeypot", "count": 1, "pos": [-198, 0.35, -452]},
	{"id": "wu_root_kit", "item": "u_root_kit", "count": 1, "pos": [-812, 0.35, -156]},
	{"id": "wu_dead_mans_switch", "item": "u_dead_mans_switch", "count": 1, "pos": [-158, 0.35, 156]},
	{"id": "wp_brick", "item": "cash", "count": 45, "pos": [-433, 0.3, 336]},
	{"id": "wp_manhole", "item": "scrap_electronics", "count": 2, "pos": [-70, 0.2, -20]},
	{"id": "wp_pier", "item": "whiskey", "count": 1, "pos": [-30, 0.3, 840]},
	{"id": "wp_park_bench", "item": "smartphone", "count": 1, "pos": [30, 0.5, 12]},
	{"id": "wp_dock_ammo", "item": "ammo_12ga", "count": 8, "pos": [-730, 0.3, -280]},
	{"id": "wp_arcade_token", "item": "arcade_token", "count": 5, "pos": [-166, 0.3, 681]},
	# Flipper the dog (sq_cat), curled up under the end of the pier.
	{"id": "wp_flipper", "item": "flipper_leash", "count": 1, "pos": [-24, 0.3, 843]},
	# Richard Keller's spare key, under the mat on his stoop (sq_badco).
	{"id": "wp_keller_key", "item": "key_keller", "count": 1, "pos": [967.5, 0.12, -589.8]},
]

const SPOTS := [
	# Top of the North Tower.
	{"id": "ws_wtc_elev", "kind": "exit", "title": "Express Elevator", "verb": "Ride down", "pos": [-96, 381.3, 368.1], "size": [2.0, 2.4, 0.8], "to": "interior:wtc_lobby:1"},
	{"id": "ws_wtc_view", "kind": "text", "title": "The Edge", "verb": "Look out", "pos": [-96, 381.2, 376.9], "size": [8.0, 1.6, 1.0], "text": "Four hundred meters of air. The whole city laid out like a circuit board: the E Corp tower glowing blue, the Bronx going gold in the distance, Coney's wheel a coin on the edge of the sea. From up here, every problem is somebody else's. Down there, every one of them is yours."},

	{"id": "ws_bodega_atm", "kind": "text", "title": "ATM", "verb": "Read", "pos": [-6, 1.2, -4], "size": [0.6, 2, 0.6], "text": "OUT OF SERVICE. A sticker under it reads: 'ECOIN ACCEPTED HERE SOON.' Someone scratched 'NEVER' into it."},
	{"id": "ws_memorial", "kind": "convo", "title": "Washington Township Memorial", "verb": "Read", "pos": [-150, 1.4, 150.4], "size": [6, 2, 1], "convo": "memorial"},
	{"id": "ws_ecorp_fountain", "kind": "text", "title": "Plaza Fountain", "verb": "Look", "pos": [-65, 1.2, -256], "size": [4, 1, 4], "text": "Coins glint at the bottom. Wishes, denominated in the currency of the thing they're wishing against. You could take them. You don't."},
	{"id": "ws_wheel", "kind": "text", "title": "The Wonder Wheel", "verb": "Look up", "pos": [100, 1.6, 640], "size": [4, 2, 4], "text": "It still turns. Nobody's on it. It turns for the same reason the city does: momentum, and nobody brave enough to pull the lever."},
]

## Story triggers: fire when the player enters a radius with the condition met.
const TRIGGERS := [
	{"id": "tr_first_street", "cell": "world", "pos": [-339, 318], "r": 8, "once": true, "bark": "Hello, friend. I'm back on the street. The city doesn't care. It never did. But you're still here. So let's keep going.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_ecorp_view", "cell": "world", "pos": [-65, -248], "r": 30, "once": true, "when": "!flag.saw_township", "bark": "E Corp. Seventy percent of the world's consumer debt, in one building. It has a heartbeat. I want to stop it.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_arcade_first", "cell": "world", "pos": [-170, 680], "r": 12, "once": true, "when": "!flag.joined_fsociety & q.mq_rootkit>=40", "bark": "The arcade. Coney Island. This is where it started, or where it ends. Same door.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_night_first", "cell": "world", "pos": [-466, 318], "r": 40, "once": true, "when": "night", "bark": "The city sounds different at night. Like it's finally telling the truth.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_shayla_docks", "cell": "world", "pos": [-700, -322], "r": 30, "once": true, "when": "q.sq_shayla>=20 & q.sq_shayla<30", "fx": "quest sq_shayla 30", "bark": "Vera's crew, but no Shayla. One of them keeps saying 'the stash house by the boardwalk.' Coney. Of course it's Coney.", "speaker": "ELLIOT (V.O.)"},

	{"id": "tr_airfield_first", "cell": "world", "pos": [1420, -1250], "r": 130, "once": true, "when": "!q.sq_wings>=20", "fx": "quest sq_wings 10", "bark": "An airfield. In Queens. Little white planes on tie-downs and a sign that says AUTHORIZED ONLY, which is what every sign says right before I ignore it.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_airfield_jet", "cell": "world", "pos": [1395, -1150], "r": 25, "once": true, "when": "!flag.ecorp_jet_gone", "bark": "E Corp's corporate jet. Leather seats, a bar, and a tail number registered to a shell company in Delaware. Someone should take it for a spin.", "speaker": "ELLIOT (V.O.)"},

	# --- Story director: position-less rules that fire anywhere in the cell
	# ("*" = any cell). They keep every quest moving no matter what order the
	# player does things in.
	{"id": "sd_wings_rings", "cell": "*", "when": "q.sq_wings>=20 & q.sq_wings<30 & flag.wings_rings_done", "fx": "quest sq_wings 30", "bark": "Five for five. Now the part that kills people. Put her down on the Bowery Bay runway, gently, and stop.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_wings_landed", "cell": "*", "when": "q.sq_wings>=30 & q.sq_wings<40 & flag.wings_landed", "fx": "quest sq_wings 40", "bark": "Wheels down. Nothing bent. Gus saw the whole thing from the office window.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_wings_hint", "cell": "*", "when": "q.mq_fsociety.done & !q.sq_wings>=10", "fx": "quest sq_wings 10", "bark": "yo. random. old guy in queens runs bowery bay airfield, E Corp's foreclosing on him. they park the exec jet there too. thought you'd want to know. delete this.", "speaker": "MOBLEY (TEXT)"},
	{"id": "sd_hello_home", "cell": "elliot_apt", "when": "q.mq_hello>=10 & q.mq_hello<20", "fx": "quest mq_hello 20", "bark": "Home. Qwerty, the hum of the tower under the desk, and a light on the monitor that wasn't blinking this morning.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_hello_skip", "cell": "*", "when": "q.mq_rootkit>=10 & q.mq_hello.active", "fx": "quest mq_hello done"},
	{"id": "sd_rootkit_cafe", "cell": "ron_coffee", "when": "q.mq_rootkit>=10 & q.mq_rootkit<20", "fx": "quest mq_rootkit 20", "bark": "Ron's. Burnt beans and a hard drive working too hard. The server's in the back, past the counter. Past Ron.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_rootkit_known", "cell": "*", "when": "flag.knows_ron_secret & q.mq_rootkit>=10 & q.mq_rootkit<30", "fx": "quest mq_rootkit 30"},
	{"id": "sd_sq_ron_start", "cell": "ron_coffee", "when": "q.mq_rootkit>=10 & !q.sq_ron.started", "fx": "quest sq_ron 10"},
	{"id": "sd_rootkit_msg", "cell": "*", "when": "flag.rootkit_planted & q.mq_fsociety>=10 & q.mq_fsociety<20 & !in.ron_coffee", "bark": "Nice work. Delancey Street station. Alone. Any platform will do; I'll find you.  - a friend", "speaker": "UNKNOWN NUMBER"},
	{"id": "sd_robot_platform", "cell": "subway", "when": "q.mq_fsociety>=10 & q.mq_fsociety<20", "bark": "He's here. End of the platform. Like he's been waiting since before the trains.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_fsoc_arcade", "cell": "arcade", "when": "q.mq_fsociety>=20 & q.mq_fsociety<30", "fx": "quest mq_fsociety 30", "bark": "Fun Society. Dead machines, live wires, and people who've been waiting for me.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_finale_start", "cell": "*", "when": "flag.joined_fsociety & !q.mq_finale.started", "fx": "quest mq_finale 10"},
	{"id": "sd_steel_ready", "cell": "*", "when": "q.mq_steel>=10 & q.mq_steel<20 & item.raspberry_pi>=1 & item.steel_coveralls>=1 | q.mq_steel>=10 & q.mq_steel<20 & item.raspberry_pi>=1 & item.steel_badge>=1", "fx": "quest mq_steel 20", "bark": "The device and a way in. Steel Mountain's at the far north-east edge of the city. Put the coveralls on before the gate.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_steel_inside", "cell": "steel_mountain", "when": "q.mq_steel>=10 & q.mq_steel<30", "fx": "quest mq_steel 30"},
	{"id": "sd_finale_ready", "cell": "*", "when": "q.mq_finale>=10 & q.mq_finale<20 & flag.rootkit_planted & q.mq_steel.done & flag.ally_secured & flag.ecorp_door_tyrell | q.mq_finale>=10 & q.mq_finale<20 & flag.rootkit_planted & q.mq_steel.done & flag.ally_secured & flag.ecorp_foothold", "fx": "quest mq_finale 20", "bark": "That's everything. The mountain, the army, the door. Back to the arcade. Tell him to press it.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_darkarmy_ready", "cell": "*", "when": "q.mq_darkarmy>=20 & q.mq_darkarmy<30 & q.mq_steel.done", "fx": "quest mq_darkarmy 30", "bark": "Steel Mountain is burning slow. That was Cisco's price. Whiterose will see me now.", "speaker": "ELLIOT (V.O.)"},
	# --- The Monster path: the city notices the bodies.
	{"id": "sd_killings_news", "cell": "*", "when": "innocents>=3", "bark": "...and police are investigating a third unexplained death in as many days. The victims appear to be unconnected. Anyone with information is asked to call...", "speaker": "RADIO"},
	{"id": "sd_lopez_card", "cell": "*", "when": "innocents>=6 & !q.sq_lopez.started", "fx": "quest sq_lopez 10", "bark": "A card under my door. 'Det. Maria Lopez, Homicide. Let's talk.' She's good. She's the first one who's been good.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_lopez_closing", "cell": "*", "when": "innocents>=12 & q.sq_lopez>=10 & q.sq_lopez<30 & !flag.lopez_doubt", "fx": "quest sq_lopez 30", "bark": "Missed call. Voicemail, eleven seconds: 'It's Lopez. I'm at your building. I'll wait.'", "speaker": "PHONE"},
	# --- The Bronx and Harlem.
	{"id": "tr_candles", "cell": "world", "pos": [-62, -1377], "r": 16, "once": true, "when": "!q.sq_candyman.started", "bark": "Candles on the pavement. A photo taped to the brick: a boy in a graduation cap. The woman kneeling there hasn't slept in a week.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_shelter", "cell": "world", "pos": [-75, -978], "r": 14, "once": true, "when": "!q.sq_badco.started", "bark": "St. Nicholas. Hot meals, bunk beds, a counselor who's been fighting the city for nineteen years. The building looks as tired as she must be.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_candy_lab_known", "cell": "hunts_lab", "when": "q.sq_candyman>=20 & !flag.knows_candy_lab", "fx": "set knows_candy_lab", "bark": "Unit 9. So this is the kitchen.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_colby_found", "cell": "*", "when": "item.colby_archive>=1 & !q.sq_colby>=20 & !flag.township_resolved", "fx": "quest sq_colby 20", "bark": "Colby's emails. 'Proceed with the cleanup. Do not disclose.' Signed. Dated. Angela needs to see this.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_shayla_taken", "cell": "*", "when": "q.sq_shayla>=10 & q.sq_shayla<20 & night & !in.apt_building", "fx": "quest sq_shayla 20", "bark": "vera's guys grabbed me outside the bodega. pier 9. they keep saying its about u. please hurry", "speaker": "TEXT FROM SHAYLA"},
	{"id": "sd_cat_found", "cell": "*", "when": "item.flipper_leash>=1 & q.sq_cat>=10 & q.sq_cat<20", "fx": "quest sq_cat 20", "bark": "Flipper. Brown, damp, thrilled to see literally anyone. Come on. Let's get you home.", "speaker": "ELLIOT (V.O.)"},
]
