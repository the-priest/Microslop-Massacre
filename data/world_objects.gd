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
	{"id": "wu_five_nine", "item": "u_five_nine", "count": 1, "pos": [-47, 0.35, -246]},
	{"id": "wu_stage_two", "item": "u_stage_two", "count": 1, "pos": [-733, 0.35, -275]},
	{"id": "wu_qwerty", "item": "u_qwerty", "count": 1, "pos": [-87, 0.35, 93]},
	# Gun stashes: behind dumpsters, under piers, in the gaps. Each comes with ammo.
	{"id": "wg_les_380", "item": "compact_380", "count": 1, "pos": [-453.5, 0.35, 327.6]},
	{"id": "wg_les_380a", "item": "ammo_9mm", "count": 21, "pos": [-452.6, 0.3, 327.8]},
	{"id": "wg_hells_db", "item": "double_barrel", "count": 1, "pos": [-490, 0.35, 102.6]},
	{"id": "wg_hells_dba", "item": "ammo_12ga", "count": 10, "pos": [-489, 0.3, 102.8]},
	{"id": "wg_mid_10mm", "item": "pistol_10mm", "count": 1, "pos": [-331.8, 0.35, -237.8]},
	{"id": "wg_mid_10mma", "item": "ammo_45", "count": 20, "pos": [-332.2, 0.3, -238.6]},
	{"id": "wg_china_pdw", "item": "pdw", "count": 1, "pos": [470, 0.35, 422.6]},
	{"id": "wg_china_pdwa", "item": "ammo_9mm", "count": 40, "pos": [471, 0.3, 422.8]},
	{"id": "wg_dock_lever", "item": "lever_rifle", "count": 1, "pos": [-729.8, 0.35, -317.0]},
	{"id": "wg_dock_levera", "item": "ammo_38", "count": 16, "pos": [-730.2, 0.3, -316.2]},
	{"id": "wg_ind_br", "item": "battle_rifle", "count": 1, "pos": [510, 0.35, -552.4]},
	{"id": "wg_ind_bra", "item": "ammo_308", "count": 20, "pos": [511, 0.3, -552.2]},
	{"id": "wg_coney_mk", "item": "marksman_rifle", "count": 1, "pos": [40, 0.35, 702.6]},
	{"id": "wg_coney_mka", "item": "ammo_308", "count": 10, "pos": [41, 0.3, 702.8]},
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
	# Washington Township and Port Ramsey.
	{"id": "ws_tw_wall", "kind": "convo", "region": "township", "title": "Township Memorial", "verb": "Read", "pos": [-75.0, 1.4, 281.0], "size": [22.0, 2.8, 1.4], "convo": "tw_wall"},
	{"id": "ws_tw_sign", "kind": "text", "region": "township", "title": "Welcome Sign", "verb": "Read", "pos": [640.4, 2.6, 14.0], "size": [1.0, 2.4, 8.6], "text": "WELCOME TO WASHINGTON TOWNSHIP. A NICE PLACE TO RAISE A FAMILY. EST. 1798. And underneath, in red spray paint that the township has painted over twice and somebody has redone twice: E CORP KILLED US."},
	{"id": "ws_tw_pond", "kind": "text", "region": "township", "title": "Retention Pond 3", "verb": "Look", "pos": [-375.0, 1.2, -132.5], "size": [100.0, 2.6, 1.0], "text": "Chain-link, razor wire, and a pond the color of a bruise on the far side of it. It steams a little, even in the afternoon. No birds on it. There are birds everywhere else in the county.", "when": "!q.sq_tw2>=20"},
	{"id": "ws_pt_market", "kind": "text", "region": "port", "title": "Fish Market", "verb": "Read", "pos": [670.0, 3.0, 200.0], "size": [1.0, 6.0, 8.6], "text": "RAMSEY FISH MARKET. OPEN 4AM. CASH ONLY. A newer sign zip-tied underneath: 'TEMPORARILY CLOSED (NO FISH).' Somebody has crossed out TEMPORARILY and written ASK TEDDY GRIECO."},
	{"id": "ws_rig", "kind": "convo", "region": "highway", "title": "Dolores's Rig", "verb": "Inspect", "pos": [-17.0, 1.6, -296.0], "size": [3.0, 3.2, 4.0], "convo": "rig", "when": "q.sq_rig>=20"},
	{"id": "ws_wtc_view", "kind": "text", "title": "The Edge", "verb": "Look out", "pos": [-96, 381.2, 376.9], "size": [8.0, 1.6, 1.0], "text": "Four hundred meters of air. The whole city laid out like a circuit board: the E Corp tower glowing blue, the Bronx going gold in the distance, Coney's wheel a coin on the edge of the sea. From up here, every problem is somebody else's. Down there, every one of them is yours."},

	{"id": "ws_bodega_atm", "kind": "text", "title": "ATM", "verb": "Read", "pos": [-6, 1.2, -4], "size": [0.6, 2, 0.6], "text": "OUT OF SERVICE. A sticker under it reads: 'ECOIN ACCEPTED HERE SOON.' Someone scratched 'NEVER' into it."},
	{"id": "ws_memorial", "kind": "convo", "title": "Washington Township Memorial", "verb": "Read", "pos": [-150, 1.4, 150.4], "size": [6, 2, 1], "convo": "memorial"},
	{"id": "ws_ecorp_fountain", "kind": "text", "title": "Plaza Fountain", "verb": "Look", "pos": [-65, 1.2, -256], "size": [4, 1, 4], "text": "Coins glint at the bottom. Wishes, denominated in the currency of the thing they're wishing against. You could take them. You don't."},
	{"id": "ws_vera_door", "kind": "convo", "title": "Stash House", "verb": "Case the place", "pos": [-137.0, 1.2, 520.5], "size": [1.2, 2.0, 2.0], "convo": "vera_door", "when": "q.sq_shayla>=30 & !flag.shayla_out"},
	{"id": "ws_wheel", "kind": "text", "title": "The Wonder Wheel", "verb": "Look up", "pos": [100, 1.6, 640], "size": [4, 2, 4], "text": "It still turns. Nobody's on it. It turns for the same reason the city does: momentum, and nobody brave enough to pull the lever."},
]

## Story triggers: fire when the player enters a radius with the condition met.
const TRIGGERS := [
	{"id": "tr_first_street", "cell": "world", "pos": [-339, 318], "r": 8, "once": true, "bark": "Hello, friend. I'm back on the street. The city doesn't care. It never did. But you're still here. So let's keep going.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_ecorp_view", "cell": "world", "pos": [-65, -248], "r": 30, "once": true, "when": "!flag.saw_township", "bark": "E Corp. Seventy percent of the world's consumer debt, in one building. It has a heartbeat. I want to stop it.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_arcade_first", "cell": "world", "pos": [-170, 680], "r": 12, "once": true, "when": "!flag.joined_fsociety & q.mq_rootkit>=40", "bark": "The arcade. Coney Island. This is where it started, or where it ends. Same door.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_night_first", "cell": "world", "pos": [-466, 318], "r": 40, "once": true, "when": "night", "bark": "The city sounds different at night. Like it's finally telling the truth.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_shayla_docks", "cell": "world", "pos": [-700, -322], "r": 30, "once": true, "when": "q.sq_shayla>=20 & q.sq_shayla<30", "bark": "Vera's crew, but no Shayla. The big one in the good coat must be Dutch. He's the one who knows where she is.", "speaker": "ELLIOT (V.O.)"},

	{"id": "tr_airfield_first", "cell": "world", "pos": [1420, -1250], "r": 130, "once": true, "when": "!q.sq_wings>=20", "fx": "quest sq_wings 10", "bark": "An airfield. In Queens. Little white planes on tie-downs and a sign that says AUTHORIZED ONLY, which is what every sign says right before I ignore it.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_airfield_jet", "cell": "world", "pos": [1395, -1150], "r": 25, "once": true, "when": "!flag.ecorp_jet_gone", "bark": "E Corp's corporate jet. Leather seats, a bar, and a tail number registered to a shell company in Delaware. Someone should take it for a spin.", "speaker": "ELLIOT (V.O.)"},

	# --- Story director: position-less rules that fire anywhere in the cell
	# ("*" = any cell). They keep every quest moving no matter what order the
	# player does things in.
	{"id": "sd_wings_rings", "cell": "*", "when": "q.sq_wings>=20 & q.sq_wings<30 & flag.wings_rings_done", "fx": "quest sq_wings 30", "bark": "Five for five. Now the part that kills people. Put her down on the Bowery Bay runway, gently, and stop.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_wings_landed", "cell": "*", "when": "q.sq_wings>=30 & q.sq_wings<40 & flag.wings_landed", "fx": "quest sq_wings 40", "bark": "Wheels down. Nothing bent. Gus saw the whole thing from the office window.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_wings_hint", "cell": "*", "when": "q.mq_fsociety.done & !q.sq_wings>=10", "fx": "quest sq_wings 10", "bark": "yo. random. old guy in queens runs bowery bay airfield, E Corp's foreclosing on him. they park the exec jet there too. thought you'd want to know. delete this.", "speaker": "MOBLEY (TEXT)"},
	{"id": "sd_hello_home", "cell": "elliot_apt", "when": "q.mq_hello>=10 & q.mq_hello<20", "fx": "quest mq_hello 20", "bark": "Home. Qwerty, the hum of the tower under the desk, and a light on the monitor that wasn't blinking this morning.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_hello_block", "cell": "*", "when": "q.mq_hello>=25 & q.mq_hello<30 & flag.heat_on & q.sq_shayla>=10 | q.mq_hello>=25 & q.mq_hello<30 & flag.heat_on & flag.bodega_saved | q.mq_hello>=25 & q.mq_hello<30 & q.sq_shayla>=10 & flag.bodega_saved | q.mq_hello>=25 & q.mq_hello<30 & daynum>=4", "fx": "quest mq_hello 30", "bark": "Okay, Krista. I talked to the neighbors. Some of them even talked back. Tomorrow: Allsafe, Gideon, the honeypot. And the file I'm pretending isn't on my desktop.", "speaker": "ELLIOT (V.O.)"},
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
	{"id": "sd_fbi_start", "cell": "*", "when": "q.mq_steel.done & !q.mq_fbi.started", "fx": "quest mq_fbi 10 ; set fbi_contact", "bark": "Mr. Alderson. This is Special Agent Dominique DiPierro, FBI. I'd like to talk to you about Steel Mountain. Federal Building, at your convenience. Which is to say: soon.", "speaker": "VOICEMAIL"},
	{"id": "sd_robot_start", "cell": "*", "when": "flag.joined_fsociety & !q.mq_robot.started & q.mq_steel.done & q.mq_darkarmy.done | flag.joined_fsociety & !q.mq_robot.started & q.mq_steel.done & q.mq_ecorp.done | flag.joined_fsociety & !q.mq_robot.started & q.mq_darkarmy.done & q.mq_ecorp.done", "fx": "quest mq_robot 10", "bark": "come to my place. not the arcade. mine. there's something you need to see and i can't keep doing this where he can hear. please. - D", "speaker": "TEXT FROM DARLENE"},
	{"id": "sd_robot_pier", "cell": "*", "when": "q.mq_robot>=50 & !q.mq_robot.done & !flag.pier_hint", "fx": "set pier_hint", "bark": "The Coney Island pier. At night. He'll be at the end of it, the way he is in the dream I keep having and keep forgetting.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_after_start", "cell": "*", "when": "flag.five_nine_done & !q.mq_after.started", "fx": "quest mq_after 10"},
	{"id": "sd_after_invite", "cell": "*", "when": "flag.after_done & !flag.salina_texted", "fx": "set salina_texted", "bark": "Unknown number. No words, just a photo: a hotel room door, number 6, and an old brass key on the carpet in front of it. The Salina. They've noticed me. Good. I've noticed them.", "speaker": "PHONE"},
	{"id": "sd_rs_up", "cell": "wtc_lobby", "when": "q.mq_rs1>=20 & q.mq_rs1<30 & item.rs_badge>=1 & !flag.rs_floor_open", "fx": "set rs_floor_open"},
	{"id": "sd_chi_arrive", "cell": "world", "region": "chicago", "when": "q.mq_chi1>=10 & q.mq_chi1<20 & !flag.chi_arrived", "fx": "set chi_arrived ; quest mq_chi1 20", "bark": "Chicago. Colder, flatter, meaner about it. The lake on one side and the Loop on the other, and somewhere in the South Side a warehouse with my name on the lease under a name that isn't mine.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_respawn_start", "cell": "*", "when": "flag.joined_fsociety & q.mq_steel.done & !q.mq_respawn.started & !in.steel_mountain", "fx": "quest mq_respawn 10", "bark": "found something. a forum called Respawn. 10k gamers E Corp screwed over, and they're done writing angry reviews. their admin wants to talk to fsociety. i patched him into the arcade's back terminal. be nice, he types in all caps when he's excited  - D", "speaker": "DARLENE (TEXT)"},
	{"id": "sd_rs_floor", "cell": "rockstarved_hq", "when": "q.mq_rs1>=20 & q.mq_rs1<30", "fx": "quest mq_rs1 30", "bark": "Floor 88. Bean bags, a ball pit nobody uses, and a wall that says WE MAKE MAGIC. Under the magic, mattresses. The crunch team sleeps here. The server's in the back.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_rs_texted", "cell": "*", "when": "flag.rs_done & q.mq_rs2>=20 & !q.mq_rs2.done & !flag.rs_pixel_text & !in.rockstarved_hq", "fx": "set rs_pixel_text", "bark": "OH MY GOD. OH MY GOD. RESPAWN IS LOSING ITS MIND. COME TO THE ARCADE TERMINAL. sorry. caps. i'm excited.", "speaker": "PIXEL (TEXT)"},
	{"id": "sd_chi_inside", "cell": "chi_node", "when": "q.mq_chi2>=10 & q.mq_chi2<20 & !flag.chi_inside", "fx": "set chi_inside", "bark": "E Corp Midwest. Same logo, same marble, same hum. Every one of these lobbies is a copy of the one in New York, like somebody just keeps hitting paste. The data floor's through the back.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_chi_done", "cell": "chi_node", "when": "flag.phony_freed & q.mq_chi3>=20 & !flag.chi_done_bark", "fx": "set chi_done_bark", "bark": "Both of them. In one night. Every game anyone ever paid for, back where it belongs. Ansel's going to scream. Then I need to go home. It's 790 miles and I don't know which of us is driving.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_chi_home", "cell": "world", "region": "nyc", "when": "q.mq_chi3>=20 & !q.mq_chi3.done", "fx": "set chi_home ; quest mq_chi3 done ; fame gamers 3 ; stab 2", "bark": "Back in New York. Two cities down. Darlene says the whole industry's watching their own stock tickers like heart monitors now. Good. Let them feel it.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_chi_crew", "cell": "*", "when": "flag.chi_home & !flag.chi_crew_text & flag.joined_fsociety", "fx": "set chi_crew_text ; quest mq_ms 10", "bark": "welcome home. mobley made a cake shaped like a loot box. it has a 1 in 9214 chance of being edible. trenton says that's a joke. it's not a joke. come by the arcade  - D", "speaker": "DARLENE (TEXT)"},
	{"id": "sd_ms_up", "cell": "wtc_lobby", "when": "q.mq_ms>=30 & q.mq_ms<40 & !flag.ms_hint", "fx": "set ms_hint", "bark": "Far-right elevator. The chip in Kenny's invitation turns the light green. Floor 101. Please arrive with enthusiasm.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_ms_floor", "cell": "ms_floor", "when": "q.mq_ms>=30 & q.mq_ms<40", "fx": "quest mq_ms 40", "bark": "Green light everywhere, like the inside of a progress bar. A stage, a screen, three hundred people clapping on cue. The Library is through the door behind the stage. So is everything they're going to take.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_ms_done", "cell": "ms_floor", "when": "flag.ms_done & !flag.ms_done_bark", "fx": "set ms_done_bark", "bark": "The keynote screen glitches, then goes black. Three hundred phones buzz at once. Somebody near the front starts laughing and doesn't stop. Time to leave, before the people who own this floor figure out who was on it.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_lou_farm", "cell": "chi_motel", "when": "q.sq_lou>=20 & q.sq_lou<30", "fx": "quest sq_lou 30", "bark": "Room 14 hums. Forty phones, forty fake people, and one real one in a hoodie, eating cereal out of the box at two in the afternoon.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_lou_door", "cell": "chi_diner", "once": true, "when": "!q.sq_lou.started", "bark": "Lou's Red Hots. Thirty-one years on this corner, says the sign. Empty at lunch. The man behind the counter keeps looking at a tablet like it owes him money.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_rig_cold", "cell": "*", "when": "item.insulin_cooler>=1 & q.sq_rig>=30 & q.sq_rig<40 & !flag.rig_cold_hint", "fx": "set rig_cold_hint", "bark": "The cooler's sweating already. Lennox is south down I-80: past the motel sign, the green PHARMACY one. A pharmacist named Ruth is waiting.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_rig_diner", "cell": "hw_diner", "once": true, "when": "!q.sq_rig.started", "bark": "Big Rig Diner. Truckers, pie, a TV with the sound off showing E Corp's stock. A woman in a trucker's jacket at the back booth is on hold with someone and losing.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_kowal_call", "cell": "world", "region": "chicago", "when": "flag.earse_exposed & !q.sq_kowal.started", "fx": "quest sq_kowal 10", "bark": "This message is for the gentleman in the hoodie who visited E Corp Midwest on a weekday afternoon. Special Agent Kowalczyk, FBI. Federal Plaza. I'd rather we talked before I talk to anybody else. You know where to find me.", "speaker": "VOICEMAIL"},
	{"id": "sd_room9_start", "cell": "*", "when": "flag.room9_read & !q.sq_room9.started", "fx": "quest sq_room9 10", "bark": "Keep driving. In my handwriting. My E. I've never been to Pennsylvania. ...Have I? Come back after dark. Whoever wrote it will want it to be dark.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_room9_dark", "cell": "hw_motel", "when": "q.sq_room9>=10 & !q.sq_room9.done & night & !flag.room9_lamp", "fx": "set room9_lamp", "bark": "The lamp's on. I didn't turn it on.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_killings_news", "cell": "*", "when": "innocents>=3", "bark": "...and police are investigating a third unexplained death in as many days. The victims appear to be unconnected. Anyone with information is asked to call...", "speaker": "RADIO"},
	{"id": "sd_lopez_card", "cell": "*", "when": "innocents>=6 & !q.sq_lopez.started", "fx": "quest sq_lopez 10", "bark": "A card under my door. 'Det. Maria Lopez, Homicide. Let's talk.' She's good. She's the first one who's been good.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_lopez_closing", "cell": "*", "when": "innocents>=12 & q.sq_lopez>=10 & q.sq_lopez<30 & !flag.lopez_doubt", "fx": "quest sq_lopez 30", "bark": "Missed call. Voicemail, eleven seconds: 'It's Lopez. I'm at your building. I'll wait.'", "speaker": "PHONE"},
	# --- The Bronx and Harlem.
	{"id": "tr_candles", "cell": "world", "pos": [-62, -1377], "r": 16, "once": true, "when": "!q.sq_candyman.started", "bark": "Candles on the pavement. A photo taped to the brick: a boy in a graduation cap. The woman kneeling there hasn't slept in a week.", "speaker": "ELLIOT (V.O.)"},
	{"id": "tr_shelter", "cell": "world", "pos": [-75, -978], "r": 14, "once": true, "when": "!q.sq_badco.started", "bark": "St. Nicholas. Hot meals, bunk beds, a counselor who's been fighting the city for nineteen years. The building looks as tired as she must be.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_candy_lab_known", "cell": "hunts_lab", "when": "q.sq_candyman>=20 & !flag.knows_candy_lab", "fx": "set knows_candy_lab", "bark": "Unit 9. So this is the kitchen.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_colby_found", "cell": "*", "when": "item.colby_archive>=1 & !q.sq_colby>=20 & !flag.township_resolved", "fx": "quest sq_colby 20", "bark": "Colby's emails. 'Proceed with the cleanup. Do not disclose.' Signed. Dated. Angela needs to see this.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_shayla_taken", "cell": "*", "when": "q.sq_shayla>=10 & q.sq_shayla<20 & night & !in.apt_building & q.mq_hello.done", "fx": "quest sq_shayla 20", "bark": "vera's guys grabbed me outside the bodega. pier 9. they keep saying its about u. please hurry", "speaker": "TEXT FROM SHAYLA"},
	{"id": "sd_shayla_dutch", "cell": "*", "when": "q.sq_shayla>=20 & q.sq_shayla<30 & item.dutch_phone>=1 | q.sq_shayla>=20 & q.sq_shayla<30 & dead.dutch", "fx": "quest sq_shayla 30 ; set vera_backdoor", "bark": "Dutch's phone, still unlocked. The group chat: 'girl's at the blue door on the boardwalk. back alley code 0419.' People should really stop texting.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_shayla_home", "cell": "apt_building", "when": "flag.shayla_freed & !flag.shayla_out", "fx": "set shayla_out ; quest sq_shayla done ; achieve shayla_saved ; fame locals 3 ; xp 60", "bark": "Home. Our hallway. Our terrible carpet. I'm kissing it. I'm not kissing it. I'm thinking about it.", "speaker": "SHAYLA"},
	{"id": "sd_vera_wiped", "cell": "*", "when": "flag.vera_case_wiped & q.sq_shayla>=35 & q.sq_shayla<38 & !flag.shayla_freed", "fx": "quest sq_shayla 38", "bark": "People v. Vera. Gone. Somewhere in the DA's office a paralegal is about to have the worst morning of her life. Back to the blue door.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_bodega_rico", "cell": "*", "when": "q.sq_bodega>=10 & q.sq_bodega<20 & dead.rico", "fx": "set bodega_saved ; set corner_gone ; quest sq_bodega 20", "bark": "Rico's done. His crew will scatter by morning. Omar should know he can stay open.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_cat_found", "cell": "*", "when": "item.flipper_leash>=1 & q.sq_cat>=10 & q.sq_cat<20", "fx": "quest sq_cat 20", "bark": "Flipper. Brown, damp, thrilled to see literally anyone. Come on. Let's get you home.", "speaker": "ELLIOT (V.O.)"},
	# ---- Washington Township.
	{"id": "sd_tw_angela", "cell": "*", "when": "flag.township_resolved & !q.sq_tw1.started & daynum>=1", "fx": "quest sq_tw1 10 ; give angela_flowers 1", "bark": "I can't go back there. I've tried. But somebody should put flowers on the wall for my mom. Emily Moss, third row. It's off I-80, Exit 41. I left lilies on your doormat, sorry, I know you hate doormat surprises. Thank you. — A", "speaker": "ANGELA (TEXT)"},
	{"id": "sd_tw_arrive", "cell": "world", "region": "township", "when": "!q.sq_tw1.started", "fx": "quest sq_tw1 20", "bark": "Washington Township. The water tower still says it like it's proud. Main Street, the church, the stacks behind everything like a parent standing in a doorway. I haven't been back since I was a kid. The memorial's on the south side. I should go.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_tw_arrive2", "cell": "world", "region": "township", "when": "q.sq_tw1==10", "fx": "quest sq_tw1 20", "bark": "Washington Township. Angela's lilies on the passenger seat. The memorial's on the south side, past Main Street. Third row.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_tw_pond", "cell": "world", "region": "township", "pos": [-375, -187], "r": 70.0, "when": "q.sq_tw2==10 & night", "fx": "quest sq_tw2 20 ; give pond_sample 1 ; xp 40", "bark": "A box truck with no markings backs up to the fence and a man in a respirator opens a valve. The pond takes it without a sound. When he's gone I fill Walt's jar through the chain-link. It's warm. In October. It's not supposed to be warm.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_tw_plant_in", "cell": "tw_plant", "when": "q.sq_tw2==20", "fx": "quest sq_tw2 30", "bark": "E Corp blue, a picnic poster, a receptionist's chair with nobody in it. The back office is past the desk. One terminal runs all of it, Bev said. One password since 2008.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_tw_paper", "cell": "world", "region": "township", "when": "flag.paper_rings_done & q.sq_tw3==20", "fx": "quest sq_tw3 30 ; set paper_dropped", "bark": "I pull the hopper lever over Main Street and six thousand pages of discharge logs come out behind the plane like snow. On the E Corp tent. On the bouncy castle. On the free hot dogs. Three hundred people look up at once. Now bring Anne's plane home.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_tw_paper_land", "cell": "world", "region": "township", "when": "flag.paper_landed & q.sq_tw3==30", "fx": "quest sq_tw3 40 ; xp 60", "bark": "Wheels down, engine ticking, the strip quiet. Through the hangar door I can see Walt standing very still, the way people stand when they don't trust their legs.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_tw_moss_in", "cell": "tw_moss", "when": "q.sq_moss==10", "fx": "quest sq_moss 20", "bark": "Dust and the smell of a house nobody's opened a window in for thirty years. Her mom's coat is still on the hook by the door. Angela's room is through there. Purple. I knew it would be purple.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_airmail_air", "cell": "world", "region": "port", "when": "q.sq_airmail==10 & item.rx_crate", "fx": "quest sq_airmail 20", "bark": "Port Ramsey on the nose: the cranes, the ship, the lighthouse on its jetty. Ramsey Field's on the west edge of town. One runway, north-south. Don't land in the ocean, Walt said. Good note.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_airmail_land", "cell": "world", "region": "port", "when": "flag.airmail_landed & q.sq_airmail==20", "fx": "quest sq_airmail 30 ; xp 60", "bark": "Down. Rolling. Stopped. A woman in a windbreaker is already walking out of the little office toward the plane, shading her eyes, and I can tell from here she was expecting somebody else.", "speaker": "ELLIOT (V.O.)"},
	# ---- The Project.
	{"id": "sd_pr_call", "cell": "*", "when": "q.mq_darkarmy.done & !q.mq_pr1.started & daynum>=2", "fx": "quest mq_pr1 10", "bark": "Yo. It's Leon. Whiterose's people got a job out of town. Port Ramsey, the coast off I-80, Exit 42, little fish town with a big E Corp port stuck on it. There's a bar called the Barnacle. I'll be the guy watching Knight Rider on his phone. Don't bring a coat, it's nice out there.", "speaker": "LEON (PHONE)"},
	{"id": "sd_pr_port", "cell": "world", "region": "port", "when": "q.mq_pr1==10 & !flag.pr_port_seen", "fx": "set pr_port_seen", "bark": "Port Ramsey. Half a fishing town, half a freight terminal, and the freight half is winning. A ship the size of a street at berth 2, MV EVERBRIGHT in white down the side. Leon said the Barnacle, on Water Street.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_pr_cannery", "cell": "pt_cannery", "when": "q.mq_pr1==30 & !flag.pr_cannery_in", "fx": "set pr_cannery_in", "bark": "Forty containers' worth of crates and foam, and a whiteboard by the wall in two languages. Somebody runs this place like a train station.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_pr_truck_wait", "cell": "world", "region": "port", "pos": [-250, 425], "r": 40.0, "when": "q.mq_pr2==10 & day & !flag.pr_truck_day", "fx": "set pr_truck_day", "bark": "The yard's empty by day. The truck comes at night, Leon said. One in the morning. I could sleep at the Harbor Light Inn and come back.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_pr_dock", "cell": "world", "region": "township", "pos": [-225, -250], "r": 28.0, "when": "q.mq_pr2==20 & driving.truck", "fx": "quest mq_pr2 30 ; xp 80", "bark": "The dock door rolls up before I even stop. Two men in overalls take the container off on a forklift without looking at me, and one of them points at the plant's back door like a waiter pointing at a table. Freight elevator. B2.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_pr_b2", "cell": "tw_b2", "when": "q.mq_pr2==30", "fx": "quest mq_pr2 40", "bark": "The elevator goes down a lot longer than one floor should take. When the doors open the air is cold and humming and every light in the room is white.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_pr_out_on", "cell": "world", "region": "township", "when": "q.mq_pr3==20 & flag.pr_machine_on", "fx": "quest mq_pr3 done ; xp 100", "bark": "Outside, the stacks are breathing white into the dark, and every streetlight on Plant Road flickers once, all together, like the town just blinked. I don't know what I did. She does. That's going to have to be enough.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_pr_out_drowned", "cell": "world", "region": "township", "when": "q.mq_pr3==20 & flag.pr_machine_drowned", "fx": "quest mq_pr3 done ; xp 120", "bark": "I come out of the loading dock running and don't stop until the fence. Behind me the stacks cough, and then, for the first time in thirty-one years, go cold. Somewhere under my feet, Whiterose's machine is sitting in the water that killed my father. It seems right. It also seems like the kind of thing people don't forgive.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_pr_out_copied", "cell": "world", "region": "township", "when": "q.mq_pr3==20 & flag.pr_copied_plans", "fx": "quest mq_pr3 done ; xp 100", "bark": "The night air, the stacks, the hum under everything. In my pocket, a drive with a machine on it that nobody alive can explain. I didn't choose. I just made sure I'd get to choose later. Krista would have something to say about that.", "speaker": "ELLIOT (V.O.)"},
	# ---- Port Ramsey.
	{"id": "sd_pt_arrive", "cell": "world", "region": "port", "when": "!flag.pt_arrive_bark & !q.mq_pr1==10", "fx": "set pt_arrive_bark", "bark": "Port Ramsey. Cranes, containers, a lighthouse at the end of a jetty and a town that used to smell of fish and now smells of diesel. The Barnacle on Water Street looks like where people go to complain. That's usually where the stories are.", "speaker": "ELLIOT (V.O.)"},

	# ---- Gary, Indiana.
	{"id": "sd_gy_arrive", "cell": "world", "region": "gary", "when": "!q.sq_gy1.started", "fx": "quest sq_gy1 10", "bark": "Gary. The furnaces on the lakeshore, cold. A truck depot where the rail yard was, full of white trucks with nobody in them. And on Broadway, a union hall with its lights on and a banner out front: FREIGHTOS IS HIRING. ASK US WHY.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_gy_tower_in", "cell": "gy_ops", "when": "q.sq_gy1==20", "fx": "quest sq_gy1 30", "bark": "Three hundred people in rows, three screens each, nobody talking, nobody looking up. On every screen, a highway. On every face, a little camera watching their eyes. The supervisor's desk is at the back.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_gy_millofc_in", "cell": "gy_millofc", "when": "q.sq_gy2==10", "fx": "quest sq_gy2 20", "bark": "Dust, punch cards, a smell of cold iron. The scrappers have been through the front, but not the back. The superintendent's office is through there.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_gy_banner_tow", "cell": "world", "region": "gary", "when": "flag.banner_rings_done & q.sq_gy4==20", "fx": "quest sq_gy4 30 ; set banner_towed", "bark": "FREIGHTOS — WHO'S DRIVING? fifty feet long, sliding past the control tower's glass at sixty knots. Every operator in the building stands up at once. Down Broadway, people come out of the diner to point. Now bring Lena's plane home.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_gy_banner_land", "cell": "world", "region": "gary", "when": "flag.banner_landed & q.sq_gy4==30", "fx": "quest sq_gy4 40 ; xp 60", "bark": "Down, rolling, stopped. Lena's already out on the apron with her phone up, filming, laughing.", "speaker": "ELLIOT (V.O.)"},
	{"id": "sd_gy3_call", "cell": "*", "when": "q.mq_ms.done & q.sq_gy1.started & !q.sq_gy3.started", "fx": "quest sq_gy3 10", "bark": "Dude. DUDE. Microslop didn't kill SlopForge, they MOVED it. A training cluster in a glass box in the yard of a dead steel mill in Gary, Indiana. Every game from every studio they closed is in there getting chewed into sequels. Including mine. Please. — Kenny", "speaker": "KENNY (TEXT)"},
	{"id": "sd_gy_cluster_in", "cell": "gy_cluster", "when": "q.sq_gy3==10", "fx": "quest sq_gy3 20", "bark": "Green light, cold air, the hum of a thousand GPUs learning to make games out of other people's games. The training console's at the far end.", "speaker": "ELLIOT (V.O.)"},

]
