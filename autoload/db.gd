extends Node
## DB — static game data: skills, items, perks, traits, factions, notes, quests.
## Quests and notes are parsed from plain-text files in res://data so they can
## be edited without touching code. Everything here is read-only at runtime.

const SKILLS := ["hacking", "speech", "sneak", "lockpick", "guns", "melee", "barter", "medicine"]
const SKILL_NAMES := {
	"hacking": "HACKING", "speech": "SPEECH", "sneak": "SNEAK", "lockpick": "LOCKPICK",
	"guns": "GUNS", "melee": "MELEE", "barter": "BARTER", "medicine": "MEDICINE",
}
const SKILL_DESC := {
	"hacking": "Terminals, keycards, cameras, phones. Opens [HACKING] dialogue and harder terminals.",
	"speech": "Persuasion and social engineering. Opens [SPEECH] dialogue checks.",
	"sneak": "How long it takes people to notice you, and how hard your sneak attacks land.",
	"lockpick": "Doors, desks, lockers. Higher skill = harder locks, fewer broken bobby pins.",
	"guns": "Accuracy and damage with firearms. Improves EXPLOIT hit chances.",
	"melee": "Damage with fists, pipes, bats and blades.",
	"barter": "Better prices. Opens [BARTER] dialogue checks.",
	"medicine": "How much healing you get from aid items. Opens [MEDICINE] checks.",
}

## item fields: name, type (weapon|apparel|aid|ammo|misc|note|key), value, desc
## weapon: skill, dmg, rate, spread(deg), range, mag, reload, ammo, ap, pellets, auto, silent, stun, model
## apparel: slot (body|head), dt, bonus {skill: n}, disguise (faction)
## aid: fx {hp, stab, focus}, buff {skills:{}, minutes:n}
const ITEMS := {
	# ---------------------------------------------------------------- weapons
	"fists": {"name": "Bare Hands", "type": "weapon", "value": 0, "skill": "melee", "dmg": 6.0, "rate": 2.2, "range": 2.1, "ap": 10, "model": "fists", "desc": "Knuckles. Always equipped when nothing else is."},
	"switchblade": {"name": "Switchblade", "type": "weapon", "value": 40, "skill": "melee", "dmg": 11.0, "rate": 2.4, "range": 2.2, "ap": 12, "model": "knife", "desc": "Cheap, quiet, close."},
	"lead_pipe": {"name": "Lead Pipe", "type": "weapon", "value": 25, "skill": "melee", "dmg": 15.0, "rate": 1.4, "range": 2.5, "ap": 18, "model": "pipe", "desc": "Plumbing, repurposed."},
	"bat": {"name": "Baseball Bat", "type": "weapon", "value": 60, "skill": "melee", "dmg": 20.0, "rate": 1.15, "range": 2.6, "ap": 22, "model": "bat", "desc": "Louisville's finest. Swings like a bad decision."},
	"crowbar": {"name": "Crowbar", "type": "weapon", "value": 45, "skill": "melee", "dmg": 17.0, "rate": 1.3, "range": 2.5, "ap": 20, "model": "pipe", "desc": "Opens crates. And other things."},
	"taser": {"name": "Stun Gun", "type": "weapon", "value": 150, "skill": "guns", "dmg": 5.0, "rate": 0.8, "spread": 1.0, "range": 7.0, "mag": 1, "reload": 1.6, "ammo": "taser_cart", "ap": 20, "stun": 4.0, "model": "taser", "desc": "Non-lethal. Drops most people for a few seconds. Takes cartridges."},
	"pistol_22": {"name": "Suppressed .22", "type": "weapon", "value": 380, "skill": "guns", "dmg": 13.0, "rate": 3.2, "spread": 1.1, "range": 55.0, "mag": 16, "reload": 1.5, "ammo": "ammo_22", "ap": 15, "silent": true, "model": "pistol_sil", "desc": "Whisper-quiet. Doesn't wake the neighbors or the guards."},
	"pistol_9mm": {"name": "9mm Pistol", "type": "weapon", "value": 200, "skill": "guns", "dmg": 17.0, "rate": 3.0, "spread": 1.4, "range": 60.0, "mag": 12, "reload": 1.4, "ammo": "ammo_9mm", "ap": 17, "model": "pistol", "desc": "The city's most common argument."},
	"revolver": {"name": ".38 Revolver", "type": "weapon", "value": 280, "skill": "guns", "dmg": 28.0, "rate": 1.6, "spread": 0.9, "range": 70.0, "mag": 6, "reload": 2.3, "ammo": "ammo_38", "ap": 22, "model": "revolver", "desc": "Six chances to be right."},
	"smg": {"name": "Compact SMG", "type": "weapon", "value": 450, "skill": "guns", "dmg": 10.0, "rate": 10.0, "spread": 3.2, "range": 45.0, "mag": 30, "reload": 2.0, "ammo": "ammo_9mm", "ap": 28, "auto": true, "model": "smg", "desc": "Sprays 9mm like a firehose sprays water."},
	"shotgun": {"name": "Pump Shotgun", "type": "weapon", "value": 400, "skill": "guns", "dmg": 9.0, "pellets": 7, "rate": 1.1, "spread": 5.5, "range": 28.0, "mag": 6, "reload": 3.0, "ammo": "ammo_12ga", "ap": 30, "model": "shotgun", "desc": "Close range conflict resolution."},
	"rifle": {"name": "Hunting Rifle", "type": "weapon", "value": 560, "skill": "guns", "dmg": 48.0, "rate": 0.9, "spread": 0.2, "range": 140.0, "mag": 5, "reload": 2.8, "ammo": "ammo_308", "ap": 30, "zoom": 3.0, "model": "rifle", "desc": "Bolt action. Patient. Final."},
	"carbine": {"name": "Dark Army Carbine", "type": "weapon", "value": 900, "skill": "guns", "dmg": 19.0, "rate": 7.0, "spread": 1.6, "range": 90.0, "mag": 30, "reload": 2.2, "ammo": "ammo_556", "ap": 25, "auto": true, "model": "carbine", "desc": "No serial numbers. No questions."},
	"brass_knuckles": {"name": "Brass Knuckles", "type": "weapon", "value": 35, "skill": "melee", "dmg": 10.0, "rate": 2.6, "range": 2.1, "ap": 11, "model": "knuckles", "desc": "Your fists, with a lawyer's opinion attached."},
	"police_baton": {"name": "Police Baton", "type": "weapon", "value": 50, "skill": "melee", "dmg": 14.0, "rate": 1.8, "range": 2.4, "ap": 15, "stun": 0.7, "model": "baton", "desc": "Standard issue. Rattles people for a second."},
	"machete": {"name": "Machete", "type": "weapon", "value": 90, "skill": "melee", "dmg": 22.0, "rate": 1.5, "range": 2.5, "ap": 20, "model": "machete", "desc": "Cuts cane. Cuts everything else too."},
	"fire_axe": {"name": "Fire Axe", "type": "weapon", "value": 140, "skill": "melee", "dmg": 30.0, "rate": 0.95, "range": 2.7, "ap": 28, "model": "axe", "desc": "Pried off a hallway wall. In case of emergency."},
	"sledgehammer": {"name": "Sledgehammer", "type": "weapon", "value": 180, "skill": "melee", "dmg": 38.0, "rate": 0.7, "range": 2.7, "ap": 32, "model": "sledge", "desc": "Demolition. Of drywall or of arguments."},
	"katana": {"name": "Katana", "type": "weapon", "value": 420, "skill": "melee", "dmg": 28.0, "rate": 1.6, "range": 2.8, "ap": 24, "model": "katana", "desc": "Somebody's midlife crisis. Still very, very sharp."},
	"pistol_45": {"name": ".45 Pistol", "type": "weapon", "value": 320, "skill": "guns", "dmg": 24.0, "rate": 2.4, "spread": 1.2, "range": 60.0, "mag": 8, "reload": 1.5, "ammo": "ammo_45", "ap": 20, "model": "pistol45", "desc": "Heavy, loud, and very sure of itself."},
	"magnum": {"name": ".44 Magnum", "type": "weapon", "value": 520, "skill": "guns", "dmg": 44.0, "rate": 1.2, "spread": 0.8, "range": 80.0, "mag": 6, "reload": 2.6, "ammo": "ammo_44", "ap": 28, "model": "magnum", "desc": "The most powerful handgun in the argument."},
	"machine_pistol": {"name": "Machine Pistol", "type": "weapon", "value": 380, "skill": "guns", "dmg": 11.0, "rate": 12.0, "spread": 3.8, "range": 35.0, "mag": 20, "reload": 1.7, "ammo": "ammo_9mm", "ap": 26, "auto": true, "model": "pistol", "desc": "A pistol with anger issues."},
	"smg_sil": {"name": "Suppressed SMG", "type": "weapon", "value": 700, "skill": "guns", "dmg": 11.0, "rate": 9.0, "spread": 2.8, "range": 45.0, "mag": 30, "reload": 2.0, "ammo": "ammo_9mm", "ap": 26, "auto": true, "silent": true, "model": "smg_sil", "desc": "Thirty quiet opinions, delivered fast."},
	"sawed_off": {"name": "Sawed-Off Shotgun", "type": "weapon", "value": 260, "skill": "guns", "dmg": 11.0, "pellets": 8, "rate": 1.8, "spread": 8.0, "range": 16.0, "mag": 2, "reload": 2.2, "ammo": "ammo_12ga", "ap": 24, "model": "sawed", "desc": "Two barrels, no patience."},
	"combat_shotgun": {"name": "Combat Shotgun", "type": "weapon", "value": 780, "skill": "guns", "dmg": 9.0, "pellets": 7, "rate": 2.2, "spread": 5.0, "range": 30.0, "mag": 8, "reload": 3.2, "ammo": "ammo_12ga", "ap": 30, "model": "shotgun", "desc": "Semi-automatic. The pump was holding you back."},
	"assault_rifle": {"name": "Assault Rifle", "type": "weapon", "value": 1100, "skill": "guns", "dmg": 21.0, "rate": 8.0, "spread": 1.8, "range": 100.0, "mag": 30, "reload": 2.4, "ammo": "ammo_556", "ap": 28, "auto": true, "model": "ar", "desc": "Military pattern. Civilian paperwork, allegedly."},
	"sniper_rifle": {"name": "Sniper Rifle", "type": "weapon", "value": 1400, "skill": "guns", "dmg": 80.0, "rate": 0.6, "spread": 0.1, "range": 220.0, "mag": 5, "reload": 3.2, "ammo": "ammo_308", "ap": 40, "zoom": 5.0, "model": "sniper", "desc": "One shot. One problem solved, at a distance."},
	"compact_380": {"name": ".380 Pocket Pistol", "type": "weapon", "value": 120, "skill": "guns", "dmg": 14.0, "rate": 3.4, "spread": 1.5, "range": 45.0, "mag": 7, "reload": 1.2, "ammo": "ammo_9mm", "ap": 14, "model": "pistol", "desc": "Fits in a coat pocket. Fits in a sock, if you're that kind of person."},
	"pistol_10mm": {"name": "10mm Service Pistol", "type": "weapon", "value": 420, "skill": "guns", "dmg": 27.0, "rate": 2.6, "spread": 1.1, "range": 65.0, "mag": 10, "reload": 1.5, "ammo": "ammo_45", "ap": 20, "model": "pistol45", "desc": "What the Bureau carried before the Bureau got nervous about it."},
	"pdw": {"name": "Personal Defense Weapon", "type": "weapon", "value": 820, "skill": "guns", "dmg": 12.0, "rate": 11.0, "spread": 2.4, "range": 55.0, "mag": 40, "reload": 1.9, "ammo": "ammo_9mm", "ap": 26, "auto": true, "model": "smg", "desc": "Security contractors love it. Security contractors lose them."},
	"lever_rifle": {"name": "Lever-Action .38", "type": "weapon", "value": 480, "skill": "guns", "dmg": 32.0, "rate": 1.5, "spread": 0.5, "range": 100.0, "mag": 8, "reload": 2.6, "ammo": "ammo_38", "ap": 24, "zoom": 2.0, "model": "rifle", "desc": "A cowboy gun in a city of cowards. Shares ammo with your revolver."},
	"double_barrel": {"name": "Double-Barrel Shotgun", "type": "weapon", "value": 320, "skill": "guns", "dmg": 12.0, "pellets": 8, "rate": 1.5, "spread": 4.0, "range": 26.0, "mag": 2, "reload": 2.0, "ammo": "ammo_12ga", "ap": 24, "model": "sawed", "desc": "Grandpa's. Grandpa was not a nice man."},
	"marksman_rifle": {"name": "Marksman Rifle", "type": "weapon", "value": 1250, "skill": "guns", "dmg": 54.0, "rate": 1.4, "spread": 0.15, "range": 180.0, "mag": 10, "reload": 2.6, "ammo": "ammo_308", "ap": 32, "zoom": 3.5, "model": "sniper", "desc": "Semi-automatic, scoped, and very good at ending arguments across a street."},
	"battle_rifle": {"name": "Battle Rifle", "type": "weapon", "value": 1800, "skill": "guns", "dmg": 36.0, "rate": 4.5, "spread": 1.0, "range": 130.0, "mag": 20, "reload": 2.5, "ammo": "ammo_308", "ap": 32, "auto": true, "model": "ar", "desc": "Full-size, full-power, full-auto. It kicks like it means it."},
	"lmg": {"name": "Light Machine Gun", "type": "weapon", "value": 2200, "skill": "guns", "dmg": 20.0, "rate": 11.0, "spread": 2.8, "range": 100.0, "mag": 100, "reload": 5.0, "ammo": "ammo_556", "ap": 40, "auto": true, "model": "ar", "desc": "A hundred-round belt. Not subtle. Not meant to be."},
	"u_five_nine": {"name": "Five/Nine", "type": "weapon", "value": 2600, "unique": true, "skill": "guns", "dmg": 27.0, "rate": 9.0, "spread": 1.1, "range": 115.0, "mag": 40, "reload": 2.0, "ammo": "ammo_556", "ap": 24, "auto": true, "model": "ar", "desc": "UNIQUE. A rifle with a cartoon mask stenciled on the stock and 5/9 scratched under the serial number someone filed off."},
	"u_stage_two": {"name": "Stage Two", "type": "weapon", "value": 1900, "unique": true, "skill": "guns", "dmg": 12.0, "pellets": 9, "rate": 2.6, "spread": 4.6, "range": 32.0, "mag": 10, "reload": 2.8, "ammo": "ammo_12ga", "ap": 26, "model": "shotgun", "desc": "UNIQUE. A drum-fed shotgun with a white rose painted on the receiver. Whoever lost it is still looking."},
	"u_qwerty": {"name": "Qwerty", "type": "weapon", "value": 1000, "unique": true, "skill": "guns", "dmg": 22.0, "rate": 4.0, "spread": 0.6, "range": 70.0, "mag": 15, "reload": 1.1, "ammo": "ammo_22", "ap": 12, "silent": true, "model": "pistol_sil", "desc": "UNIQUE. A suppressed .22 with a little goldfish sticker on the grip. Never judges. Never misses much."},
	# ------------------------------------------------------ unique weapons
	"u_whitehat": {"name": "White Hat", "type": "weapon", "value": 900, "unique": true, "skill": "guns", "dmg": 19.0, "rate": 3.8, "spread": 0.7, "range": 75.0, "mag": 20, "reload": 1.3, "ammo": "ammo_22", "ap": 13, "silent": true, "model": "pistol_sil", "desc": "UNIQUE. A match-grade suppressed .22 with 'RESPONSIBLE DISCLOSURE' etched down the slide."},
	"u_zero_day": {"name": "Zero Day", "type": "weapon", "value": 1500, "unique": true, "skill": "guns", "dmg": 14.0, "rate": 12.0, "spread": 2.2, "range": 50.0, "mag": 40, "reload": 1.8, "ammo": "ammo_9mm", "ap": 22, "auto": true, "model": "smg", "desc": "UNIQUE. Nobody knew it existed until it was already too late."},
	"u_kernel_panic": {"name": "Kernel Panic", "type": "weapon", "value": 1300, "unique": true, "skill": "guns", "dmg": 60.0, "rate": 1.4, "spread": 0.6, "range": 85.0, "mag": 6, "reload": 2.3, "ammo": "ammo_44", "ap": 24, "model": "magnum", "desc": "UNIQUE. A chromed .44. Whatever it hits stops responding."},
	"u_patch_tuesday": {"name": "Patch Tuesday", "type": "weapon", "value": 950, "unique": true, "skill": "guns", "dmg": 14.0, "pellets": 9, "rate": 2.0, "spread": 7.0, "range": 18.0, "mag": 2, "reload": 1.8, "ammo": "ammo_12ga", "ap": 20, "model": "sawed", "desc": "UNIQUE. Fixes everything in front of it, once a week, very loudly."},
	"u_the_daemon": {"name": "The Daemon", "type": "weapon", "value": 2400, "unique": true, "skill": "guns", "dmg": 115.0, "rate": 0.7, "spread": 0.05, "range": 260.0, "mag": 5, "reload": 2.8, "ammo": "ammo_308", "ap": 34, "zoom": 6.0, "model": "sniper", "desc": "UNIQUE. Runs in the background. You never see it start."},
	"u_honeypot": {"name": "Honeypot", "type": "weapon", "value": 1100, "unique": true, "skill": "guns", "dmg": 31.0, "rate": 2.8, "spread": 0.9, "range": 70.0, "mag": 10, "reload": 1.3, "ammo": "ammo_45", "ap": 18, "model": "pistol45", "desc": "UNIQUE. Gold-plated .45. Looks like bait. Is not."},
	"u_root_kit": {"name": "Root Kit", "type": "weapon", "value": 700, "unique": true, "skill": "melee", "dmg": 34.0, "rate": 1.35, "range": 2.7, "ap": 20, "model": "bat", "desc": "UNIQUE. A nail bat with 'sudo' carved into the handle. Full privileges."},
	"u_dead_mans_switch": {"name": "Dead Man's Switch", "type": "weapon", "value": 650, "unique": true, "skill": "melee", "dmg": 25.0, "rate": 2.9, "range": 2.3, "ap": 10, "model": "knife", "desc": "UNIQUE. A black ceramic blade. Won't set off a metal detector. Won't miss."},
	# ------------------------------------------------------------------- ammo
	"ammo_22": {"name": ".22 LR Rounds", "type": "ammo", "value": 1, "desc": "Small, quiet rounds."},
	"ammo_9mm": {"name": "9mm Rounds", "type": "ammo", "value": 1, "desc": "Standard 9mm."},
	"ammo_38": {"name": ".38 Special Rounds", "type": "ammo", "value": 2, "desc": "Revolver rounds."},
	"ammo_12ga": {"name": "12 Gauge Shells", "type": "ammo", "value": 3, "desc": "Buckshot."},
	"ammo_308": {"name": ".308 Rounds", "type": "ammo", "value": 4, "desc": "Rifle rounds."},
	"ammo_556": {"name": "5.56mm Rounds", "type": "ammo", "value": 3, "desc": "Carbine rounds."},
	"taser_cart": {"name": "Taser Cartridge", "type": "ammo", "value": 10, "desc": "One shot of 50,000 volts."},
	"ammo_45": {"name": ".45 ACP Rounds", "type": "ammo", "value": 2, "desc": "Fat, slow, persuasive."},
	"ammo_44": {"name": ".44 Magnum Rounds", "type": "ammo", "value": 4, "desc": "For the magnum."},
	# ---------------------------------------------------------------- apparel
	"ortiz_sweater": {"name": "Mrs. Ortiz's Sweater", "type": "apparel", "slot": "body", "value": 5, "dt": 2, "bonus": {"speech": 5}, "look": "hoodie", "desc": "Hand-knitted, four colours that have never agreed on anything, one sleeve slightly longer. It is the warmest thing you have ever owned. People trust a man in a sweater like this."},
	"hoodie_black": {"name": "Black Hoodie", "type": "apparel", "slot": "body", "value": 20, "dt": 1, "bonus": {"sneak": 5}, "look": "hoodie", "desc": "Your uniform. The hood does half the work."},
	"work_clothes": {"name": "Allsafe Work Clothes", "type": "apparel", "slot": "body", "value": 40, "dt": 0, "bonus": {"hacking": 5, "speech": 3}, "look": "office", "desc": "Button-down, lanyard, soul optional."},
	"leather_jacket": {"name": "Leather Jacket", "type": "apparel", "slot": "body", "value": 120, "dt": 4, "bonus": {"melee": 5}, "look": "leather", "desc": "Scuffed. Earned."},
	"business_suit": {"name": "Business Suit", "type": "apparel", "slot": "body", "value": 260, "dt": 1, "bonus": {"speech": 10, "barter": 5}, "look": "suit", "desc": "Nobody questions a good suit."},
	"kevlar_vest": {"name": "Kevlar Vest", "type": "apparel", "slot": "body", "value": 520, "dt": 10, "bonus": {"sneak": -5}, "look": "vest", "desc": "Stops a 9mm. Doesn't stop the bruise."},
	"ecorp_uniform": {"name": "E Corp Security Uniform", "type": "apparel", "slot": "body", "value": 150, "dt": 5, "bonus": {}, "disguise": "ecorp", "look": "guard", "desc": "E Corp security won't look twice. Their supervisors might."},
	"darkarmy_jacket": {"name": "Dark Army Jacket", "type": "apparel", "slot": "body", "value": 180, "dt": 6, "bonus": {"guns": 3}, "disguise": "darkarmy", "look": "darkarmy", "desc": "Black, anonymous, expensive."},
	"steel_coveralls": {"name": "Maintenance Coveralls", "type": "apparel", "slot": "body", "value": 60, "dt": 2, "bonus": {"lockpick": 5}, "disguise": "steel", "look": "coveralls", "desc": "Steel Mountain facilities crew. Clipboard not included."},
	"mr_robot_jacket": {"name": "Mr. Robot's Jacket", "type": "apparel", "slot": "body", "value": 400, "dt": 5, "bonus": {"guns": 5, "speech": 5}, "look": "robot", "desc": "Olive drab, a patch that says what it means. It fits you. Of course it does."},
	"fsociety_mask": {"name": "fsociety Mask", "type": "apparel", "slot": "head", "value": 50, "dt": 0, "bonus": {"sneak": 5}, "mask": true, "desc": "Crimes committed in the mask don't stick to your name."},
	"sunglasses": {"name": "Aviator Sunglasses", "type": "apparel", "slot": "head", "value": 30, "dt": 0, "bonus": {"speech": 5}, "desc": "Confidence, tinted."},
	"beanie": {"name": "Black Beanie", "type": "apparel", "slot": "head", "value": 12, "dt": 0, "bonus": {"sneak": 3}, "desc": "Warm. Forgettable."},
	"ecorp_cap": {"name": "Security Cap", "type": "apparel", "slot": "head", "value": 25, "dt": 1, "bonus": {}, "desc": "Part of the E Corp security look."},
	"reading_glasses": {"name": "Reading Glasses", "type": "apparel", "slot": "head", "value": 20, "dt": 0, "bonus": {"hacking": 3}, "desc": "Somebody's prescription. Close enough."},
	# -------------------------------------------------------------------- aid
	"bandages": {"name": "Bandages", "type": "aid", "value": 8, "fx": {"hp": 15}, "desc": "+15 HP."},
	"painkillers": {"name": "Painkillers", "type": "aid", "value": 22, "fx": {"hp": 30}, "desc": "+30 HP. Don't take them with coffee. Or do."},
	"first_aid": {"name": "First Aid Kit", "type": "aid", "value": 65, "fx": {"hp": 60}, "desc": "+60 HP."},
	"epipen": {"name": "Epinephrine Pen", "type": "aid", "value": 90, "fx": {"hp": 40, "focus": 40}, "desc": "+40 HP, +40 FOCUS."},
	"meds": {"name": "Prescription Meds", "type": "aid", "value": 35, "fx": {"stab": 35}, "desc": "Krista's prescription. +35 STABILITY. The voice gets quieter."},
	"coffee": {"name": "Coffee", "type": "aid", "value": 3, "fx": {"focus": 20, "stab": 2}, "desc": "+20 FOCUS."},
	"energy_drink": {"name": "Red Voltage Energy", "type": "aid", "value": 6, "fx": {"focus": 35, "stab": -2}, "desc": "+35 FOCUS. Tastes like a battery."},
	"sandwich": {"name": "Bodega Sandwich", "type": "aid", "value": 6, "fx": {"hp": 22}, "desc": "+22 HP. Bacon egg and cheese, the city's true religion."},
	"hot_dog": {"name": "Street Hot Dog", "type": "aid", "value": 3, "fx": {"hp": 12}, "desc": "+12 HP."},
	"pizza": {"name": "Pizza Slice", "type": "aid", "value": 3, "fx": {"hp": 14, "stab": 1}, "desc": "+14 HP."},
	"dumplings": {"name": "Dumplings", "type": "aid", "value": 5, "fx": {"hp": 18}, "desc": "+18 HP. Chinatown's finest, $1.25 for four."},
	"whiskey": {"name": "Whiskey", "type": "aid", "value": 15, "fx": {"stab": 8}, "buff": {"skills": {"speech": 10, "guns": -10}, "minutes": 60}, "desc": "+8 STABILITY. SPEECH +10, GUNS -10 for an hour."},
	"nicotine_gum": {"name": "Nicotine Gum", "type": "aid", "value": 5, "fx": {"stab": 5}, "buff": {"skills": {"hacking": 5}, "minutes": 60}, "desc": "+5 STABILITY, HACKING +5 for an hour."},
	"adderall": {"name": "Study Pills", "type": "aid", "value": 40, "fx": {"stab": -6}, "buff": {"skills": {"hacking": 15, "lockpick": 10}, "minutes": 120}, "desc": "HACKING +15, LOCKPICK +10 for two hours. -6 STABILITY."},
	# ------------------------------------------------------------------- misc
	"bobby_pin": {"name": "Bobby Pin", "type": "misc", "value": 1, "desc": "Lockpicking consumes one of these when a pin breaks."},
	"usb_drive": {"name": "Blank USB Drive", "type": "misc", "value": 10, "desc": "Sell it or fill it."},
	"scrap_electronics": {"name": "Scrap Electronics", "type": "misc", "value": 12, "desc": "Boards and wires. Pawn shops pay for it."},
	"old_laptop": {"name": "Old Laptop", "type": "misc", "value": 60, "desc": "Wiped, mostly."},
	"smartphone": {"name": "Smartphone", "type": "misc", "value": 45, "desc": "Somebody's whole life, locked."},
	"watch": {"name": "Wristwatch", "type": "misc", "value": 55, "desc": "Keeps better time than you."},
	"gold_chain": {"name": "Gold Chain", "type": "misc", "value": 90, "desc": "Probably real."},
	"vinyl_record": {"name": "Vinyl Record", "type": "misc", "value": 20, "desc": "Somebody's favorite album. Now yours."},
	"cigarettes": {"name": "Pack of Cigarettes", "type": "misc", "value": 8, "desc": "A currency older than Bitcoin."},
	"hard_drive": {"name": "External Hard Drive", "type": "misc", "value": 35, "desc": "A terabyte of someone else's problems."},
	"burner_phone": {"name": "Burner Phone", "type": "misc", "value": 30, "desc": "Prepaid. Disposable. Like everyone's privacy."},
	"fish_food": {"name": "Fish Flakes", "type": "misc", "value": 4, "desc": "For Qwerty. He's watching."},
	"arcade_token": {"name": "Arcade Token", "type": "misc", "value": 1, "desc": "Fun Society Arcade. One play."},
	"credit_card": {"name": "Stolen Credit Card", "type": "misc", "value": 15, "desc": "Somebody's plastic. Any ATM will cash it out if you can talk to the machine."},
	"jewelry": {"name": "Jewelry", "type": "misc", "value": 120, "desc": "Rings, a bracelet, a pair of earrings. Pawn shops don't ask."},
	"tablet": {"name": "Tablet", "type": "misc", "value": 110, "desc": "Cracked screen, still boots."},
	"new_laptop": {"name": "New Laptop", "type": "misc", "value": 190, "desc": "Still has the protective film on the lid."},
	"camera": {"name": "Camera", "type": "misc", "value": 95, "desc": "Mirrorless, expensive lens. Someone's hobby."},
	"designer_bag": {"name": "Designer Handbag", "type": "misc", "value": 150, "desc": "The logo is worth more than the leather."},
	"silverware": {"name": "Silverware", "type": "misc", "value": 40, "desc": "A drawer's worth of forks, actually silver."},
	"hw_wallet": {"name": "Hardware Crypto Wallet", "type": "misc", "value": 420, "desc": "A USB stick with a seed phrase taped to the back. Rookie mistake. Your gain."},
	"gold_bar": {"name": "Gold Bar", "type": "misc", "value": 650, "desc": "One troy ounce, stamped and serialized. Heavier than it looks."},
	"cash_bundle": {"name": "Cash Bundle", "type": "misc", "value": 0, "cash": 100, "desc": "A rubber-banded stack of twenties. Use it to add $100 to your wallet."},
	"prescription": {"name": "Prescription Bottle", "type": "misc", "value": 30, "desc": "Somebody else's name on the label. Pharmacies and certain people buy these."},
	"toolkit": {"name": "Toolkit", "type": "misc", "value": 55, "desc": "Screwdrivers, pliers, a multimeter. Hardware stores buy them back."},
	"lockpick_set": {"name": "Lockpick Set", "type": "misc", "value": 80, "desc": "Proper picks. While you carry it, LOCKPICK +5."},
	"beer": {"name": "Beer", "type": "aid", "value": 4, "fx": {"stab": 3}, "buff": {"skills": {"speech": 3}, "minutes": 30}, "desc": "+3 STABILITY. SPEECH +3 for half an hour."},
	"soda": {"name": "Soda", "type": "aid", "value": 2, "fx": {"focus": 10}, "desc": "+10 FOCUS."},
	"chips": {"name": "Bag of Chips", "type": "aid", "value": 2, "fx": {"hp": 8}, "desc": "+8 HP."},
	"pretzel": {"name": "Street Pretzel", "type": "aid", "value": 3, "fx": {"hp": 10}, "desc": "+10 HP. Salt, carbs, and hope."},
	"noodles": {"name": "Takeout Noodles", "type": "aid", "value": 7, "fx": {"hp": 26, "stab": 2}, "desc": "+26 HP."},
	"stimpak_street": {"name": "Street Stim", "type": "aid", "value": 55, "fx": {"hp": 45, "focus": 15, "stab": -3}, "desc": "+45 HP, +15 FOCUS, -3 STABILITY. Don't ask what's in it."},
	# ------------------------------------------------------- job items
	"job_package": {"name": "Sealed Package", "type": "misc", "value": 0, "quest": true, "desc": "A contract delivery. Don't open it, don't lose it."},
	"air_cargo": {"name": "Air Freight Crate", "type": "misc", "value": 0, "quest": true, "desc": "A strapped crate with a waybill: an airfield in another town. Land on its runway and stop; the ground crew does the rest."},
	"haul_crate": {"name": "Long-Haul Crate", "type": "misc", "value": 0, "quest": true, "desc": "A heavy crate with an address in another town on the label. Drive it there. Bring a car with a trunk."},
	"job_data": {"name": "Encrypted Drive", "type": "misc", "value": 0, "quest": true, "desc": "The data a client paid you to lift. Hand it off to get paid."},
	"job_item": {"name": "Recovered Property", "type": "misc", "value": 0, "quest": true, "desc": "The thing a client wants back. Payment on delivery."},
	# ------------------------------------------------------------ quest items
	"raspberry_pi": {"name": "Rigged Raspberry Pi", "type": "misc", "value": 0, "quest": true, "desc": "Mobley's build. Plug it into a climate controller and it cooks the room."},
	"femtocell": {"name": "Femtocell", "type": "misc", "value": 0, "quest": true, "desc": "A fake cell tower in a box. Plug it into the right network port and it hears everything that network says."},
	"cd_mixtape": {"name": "Mixtape CD", "type": "misc", "value": 0, "quest": true, "desc": "'LIL DISASTER - STREET SERMONS'. A busker's mixtape, burned at home. Somewhere in track 9 is a signal that wants to be heard."},
	"ecorp_keycard": {"name": "E Corp Keycard", "type": "key", "value": 0, "quest": true, "desc": "Level-3 access to the E Corp tower."},
	"steel_badge": {"name": "Steel Mountain Visitor Badge", "type": "key", "value": 0, "quest": true, "desc": "Photo, barcode, and a name that isn't yours."},
	"fake_id": {"name": "Forged Credentials", "type": "misc", "value": 0, "quest": true, "desc": "A Steel Mountain auditor that doesn't exist, with a paper trail that says he does."},
	"tyrell_phone": {"name": "Tyrell's Burner", "type": "misc", "value": 0, "quest": true, "desc": "Tyrell Wellick's second phone. Everyone has one."},
	"lenny_phone": {"name": "Lenny's Phone Dump", "type": "misc", "value": 0, "quest": true, "desc": "Texts, photos, and a wife Krista doesn't know about."},
	"vera_ledger": {"name": "Vera's Ledger", "type": "misc", "value": 0, "quest": true, "desc": "Names, amounts, and who owes what. Worth a lot to the police. Worth more to Vera."},
	"colby_archive": {"name": "Colby Email Archive", "type": "misc", "value": 0, "quest": true, "desc": "Terry Colby's deleted mail from 1993. Washington Township, in his own words."},
	"stalker_db": {"name": "Ron's Customer Database", "type": "misc", "value": 0, "quest": true, "desc": "Every buyer of Ron's stalkerware. Names, cards, addresses."},
	"rose_package": {"name": "Sealed Package", "type": "misc", "value": 0, "quest": true, "desc": "Wrapped in red paper. Do not open."},
	"fbi_drive": {"name": "FBI Case Drive", "type": "misc", "value": 0, "quest": true, "desc": "Agent DiPierro's working file on fsociety."},
	"deus_invite": {"name": "Black Invitation", "type": "misc", "value": 0, "quest": true, "desc": "Heavy card stock. A crest. A date. No address."},
	"flipper_leash": {"name": "Flipper (on her leash)", "type": "misc", "value": 0, "quest": true, "desc": "Brown, damp, delighted to see anyone at all. She'd like to go home."},
	"candy_ledger": {"name": "Candyman's Ledger", "type": "misc", "value": 0, "quest": true, "desc": "Nine corners, the takings, and a column labelled CUT that rises every week. The dates line up with the funerals."},
	"candy_product": {"name": "'Candy'", "type": "misc", "value": 45, "desc": "Small bright bags stamped with a cartoon lollipop. Cut with something that kills. A fence will buy it. You could also just not."},
	"keller_drive": {"name": "Evidence Drive (Keller)", "type": "misc", "value": 0, "quest": true, "desc": "Directory listings, account records, payment logs. Enough to put Richard Keller away. You never opened the folders, and you never will."},
	"key_keller": {"name": "Spare Key (Ditmars Blvd)", "type": "key", "value": 0, "quest": true, "desc": "Under the mat. Men who think nobody's watching them keep their spare keys under the mat."},
	"malware_59": {"name": "Stage One Payload", "type": "misc", "value": 0, "quest": true, "desc": "fsociety's encryption payload. Five/Nine in a zip file."},
	# ------------------------------------------------------------------- keys
	"key_apartment": {"name": "Apartment Key", "type": "key", "value": 0, "quest": true, "desc": "Your apartment. 4D."},
	"key_arcade": {"name": "Arcade Back Room Key", "type": "key", "value": 0, "quest": true, "desc": "fsociety HQ, behind the pinball machines."},
	"key_ron_backroom": {"name": "Ron's Back Room Key", "type": "key", "value": 0, "quest": true, "desc": "Behind the espresso machine."},
	"ecoin_plan": {"name": "E Coin Rollout Deck", "type": "misc", "value": 0, "quest": true, "desc": "Phillip Price's internal plan for E Coin. Slide 9: 'The crisis is the onboarding.'"},
	"insulin_cooler": {"name": "Insulin Cooler", "type": "misc", "value": 0, "quest": true, "desc": "A white cooler, LENNOX COMMUNITY CLINIC on the lid in marker. Forty vials and two ice packs that are losing the argument with the sun."},
	"ms_invite": {"name": "Microslop Showcase Invitation", "type": "key", "value": 0, "quest": true, "desc": "Heavy card stock, embossed. 'kennyQA — COMMUNITY VOICE. Floor 101. Please arrive with enthusiasm.' The elevator reads the chip in the corner."},
	"angela_flowers": {"name": "Angela's Flowers", "type": "misc", "value": 0, "quest": true, "desc": "White lilies from the florist on Avenue B, wrapped in yesterday's Times. A card in Angela's handwriting: 'For Emily Moss. Third row. Mom, I'm sorry I don't come.'"},
	"pond_sample": {"name": "Pond Sample", "type": "misc", "value": 0, "quest": true, "desc": "A mason jar of Retention Pond 3, grey-green and faintly warm. Walt said bring a jar with a good lid. You understand why now."},
	"discharge_logs": {"name": "Plant Discharge Logs", "type": "misc", "value": 0, "quest": true, "desc": "Thirty years of 'remediation': nightly discharge volumes into Retention Pond 3, signed off by E Corp, never filed with anyone. The plant was never closed. It just stopped telling people."},
	"moss_box": {"name": "Angela's Box", "type": "misc", "value": 0, "quest": true, "desc": "A shoebox from the closet of the Moss house. 'ANGELA — KEEP OUT' in purple marker. Mixtapes, a friendship bracelet, a photo of two kids on a swing set. One of them is you."},
	"rx_crate": {"name": "Prescription Crate", "type": "misc", "value": 0, "quest": true, "desc": "A taped-up banana box of prescriptions, labelled in Walt's capitals: RAMSEY FIELD — FOR MARISOL — KEEP FLAT. Port Ramsey's pharmacy closed in March."},
	"bill_of_lading": {"name": "Everbright Manifest", "type": "misc", "value": 0, "quest": true, "desc": "MV Everbright, berth 2. Forty containers declared as 'turbine parts' for E Corp Washington Township Energy. The dock scale says they're mostly servers."},
	"lighthouse_log": {"name": "Keeper's Log", "type": "misc", "value": 0, "quest": true, "desc": "Fifty-one years of ships in Silas Pell's neat pencil. The last month has three entries with no name, no flag, and no lights: 'Dark ship. Berth 2. 1:05 AM.'"},
	"project_schematics": {"name": "Project Schematics", "type": "misc", "value": 0, "quest": true, "desc": "A drive full of drawings for a machine under Washington Township that nobody can explain, signed with a single character: a white rose."},
	"dc_badge": {"name": "E Corp Cloud Badge", "type": "key", "value": 0, "quest": true, "desc": "RAJ MEHTA — RETENTION OPERATIONS — LIC-1. Opens the staff door. The photo is from a happier decade."},
	"hidden_mask": {"name": "Hidden fsociety Mask", "type": "collectible", "value": 0, "quest": true, "desc": "A cheap plastic fsociety mask, zip-tied somewhere it shouldn't be, with a strip of paper inside: a number out of fifty and the words 'YOU FOUND ONE.' Somebody's playing a game across seven maps."},
	"ark_key": {"name": "Brass Key (green ribbon)", "type": "key", "value": 0, "quest": true, "desc": "A heavy brass key on a green silk ribbon, the kind of key that opens one door in the world. Stamped on the bow: ARK."},
	"patch_drive": {"name": "Ember Saga 1.01 (drive)", "type": "misc", "value": 0, "quest": true, "desc": "A warm external drive with a Sharpie label: EMBER SAGA 1.01 · PLEASE. Seven years of a studio's work, and the fix for the dragon."},
	"rm_keycard": {"name": "Microslop Facilities Keycard", "type": "key", "value": 0, "quest": true, "desc": "H. RUIZ — FACILITIES — ALL FLOORS (NIGHT). The photo is eleven years old. So is the lanyard."},
	"union_banner": {"name": "Local 1014 Banner", "type": "misc", "value": 0, "quest": true, "desc": "Red wool gone the color of brick, hand-stitched gold letters: LOCAL 1014 — 1919 — AN INJURY TO ONE. One corner scorched. It weighs more than it looks."},
	"rs_badge": {"name": "Rockstarved QA Badge", "type": "key", "value": 0, "quest": true, "desc": "CRUNCH TEAM C. Laminated, never deactivated. Opens the Floor 88 service elevator."},
	"whale_docs": {"name": "Project Whale Deck", "type": "misc", "value": 0, "quest": true, "desc": "Rockstarved's internal deck on 'whales'. The player is a funnel."},
	"jet_keys": {"name": "Citation Keys", "type": "key", "value": 0, "quest": true, "desc": "Keys, logbook and a one-dollar lease from Bowery Bay Flight School. The jet in hangar two is legally yours. Gus stamped it himself."},
	"dutch_phone": {"name": "Dutch's Phone", "type": "misc", "value": 0, "quest": true, "desc": "Unlocked. Vera's whole crew is in the group chat, and they all trust a message from Dutch."},
	"key_vera_stash": {"name": "Stash House Key", "type": "key", "value": 0, "quest": true, "desc": "Vera's crew uses this to get into their stash house."},
	"key_roof": {"name": "Rooftop Key", "type": "key", "value": 0, "quest": true, "desc": "Opens the roof hatch of the Heights relay building."},
	"key_steel_ops": {"name": "Ops Floor Key", "type": "key", "value": 0, "quest": true, "desc": "Steel Mountain climate control level."},
}

## Notes live in data/notes.txt and are auto-registered as items (type note).
var NOTES: Dictionary = {}

## Perk effects are implemented by id in GameState / Player / minigames.
const PERKS := [
	{"id": "toughened", "name": "Toughened", "level": 2, "ranks": 3, "req": {}, "desc": "+10 max HP per rank."},
	{"id": "hello_friend", "name": "Hello, Friend", "level": 2, "ranks": 1, "req": {"speech": 25}, "desc": "+5 SPEECH and +5 BARTER."},
	{"id": "script_kiddie", "name": "Script Kiddie", "level": 2, "ranks": 1, "req": {"hacking": 20}, "desc": "+10 HACKING."},
	{"id": "night_owl", "name": "Night Owl", "level": 4, "ranks": 1, "req": {}, "desc": "+10 SNEAK and +5 GUNS between 8 PM and 6 AM."},
	{"id": "deep_pockets", "name": "Deep Pockets", "level": 4, "ranks": 1, "req": {"barter": 30}, "desc": "Merchants pay 15% more for what you sell."},
	{"id": "kill_chain", "name": "Kill Chain", "level": 6, "ranks": 1, "req": {"guns": 40}, "desc": "+15 max FOCUS. EXPLOIT shots cost 10% less."},
	{"id": "root_access", "name": "Root Access", "level": 6, "ranks": 1, "req": {"hacking": 45}, "desc": "Terminal hacking: +1 attempt and one dud removed on start."},
	{"id": "social_engineer", "name": "Social Engineer", "level": 6, "ranks": 1, "req": {"speech": 45}, "desc": "Unlocks special [SOCIAL ENG] dialogue options."},
	{"id": "silent_running", "name": "Silent Running", "level": 6, "ranks": 1, "req": {"sneak": 45}, "desc": "Sprinting no longer makes you easier to detect."},
	{"id": "bruiser", "name": "Bruiser", "level": 6, "ranks": 1, "req": {"melee": 40}, "desc": "+25% melee damage."},
	{"id": "lock_whisperer", "name": "Lock Whisperer", "level": 8, "ranks": 1, "req": {"lockpick": 50}, "desc": "Wider sweet spots. Bobby pins break half as often."},
	{"id": "field_medic", "name": "Field Medic", "level": 8, "ranks": 1, "req": {"medicine": 40}, "desc": "Healing items restore 30% more."},
	{"id": "thick_skin", "name": "Thick Skin", "level": 8, "ranks": 1, "req": {}, "desc": "+3 Damage Threshold."},
	{"id": "cascade_tuned", "name": "Cascade Tuned", "level": 10, "ranks": 1, "req": {"hacking": 60}, "desc": "+1 mistake allowed in cascade sequences."},
	{"id": "better_criticals", "name": "Better Criticals", "level": 10, "ranks": 1, "req": {"guns": 50}, "desc": "Critical hits deal +50% damage."},
	{"id": "bloody_mess", "name": "Bloody Mess", "level": 4, "ranks": 1, "req": {}, "desc": "People you kill come apart more often, and more spectacularly. You're not proud of it. You're not ashamed of it either."},
	{"id": "ghost_protocol", "name": "Ghost Protocol", "level": 10, "ranks": 1, "req": {"sneak": 60}, "desc": "People take 25% longer to detect you."},
	{"id": "paranoia", "name": "Paranoia Is Healthy", "level": 10, "ranks": 1, "req": {}, "desc": "Stability losses are halved."},
	{"id": "signal_hound", "name": "Signal Hound", "level": 10, "ranks": 1, "req": {"hacking": 50}, "desc": "Signal tap windows are wider."},
	{"id": "adrenaline_loop", "name": "Adrenaline Loop", "level": 12, "ranks": 1, "req": {}, "desc": "A kill in EXPLOIT mode refills your FOCUS."},
	{"id": "finesse", "name": "Finesse", "level": 12, "ranks": 1, "req": {}, "desc": "+10% critical hit chance."},
	{"id": "polymath", "name": "Polymath", "level": 14, "ranks": 1, "req": {}, "desc": "+5 to every skill."},
	{"id": "walking_wallet", "name": "Walking Wallet", "level": 14, "ranks": 1, "req": {}, "desc": "Find 30% more cash in containers and on bodies."},
	{"id": "juggernaut", "name": "Juggernaut", "level": 16, "ranks": 1, "req": {}, "desc": "+25 max HP and +2 Damage Threshold."},
	{"id": "zero_day", "name": "Zero Day", "level": 16, "ranks": 1, "req": {"hacking": 75}, "desc": "Once per day, instantly crack any terminal."},
	{"id": "legend", "name": "Legend of the Grid", "level": 20, "ranks": 1, "req": {}, "desc": "+10 to every skill. Capstone."},
	{"id": "mastermind", "name": "The Mastermind", "level": 22, "ranks": 1, "req": {}, "desc": "Stability can no longer drop below 25."},
]

const TRAITS := [
	{"id": "insomniac", "name": "Insomniac", "desc": "+10 HACKING and SNEAK between 8 PM and 6 AM. -10 SPEECH during the day."},
	{"id": "paranoid", "name": "Paranoid", "desc": "+10 SNEAK, and people take longer to spot you. -10 SPEECH."},
	{"id": "loner", "name": "Loner", "desc": "+10 to all skills with no companion following. -5 to all skills with one."},
	{"id": "heavy_handed", "name": "Heavy Handed", "desc": "+25% melee damage. Guns are 30% less accurate."},
	{"id": "trigger_discipline", "name": "Trigger Discipline", "desc": "Guns are 25% more accurate but fire 20% slower."},
	{"id": "spray_and_pray", "name": "Spray and Pray", "desc": "Guns fire 20% faster but are 25% less accurate."},
	{"id": "skilled", "name": "Skilled", "desc": "+5 to all skills. Earn 10% less XP."},
	{"id": "robot_kid", "name": "Mr. Robot's Kid", "desc": "Unlocks strange encounters and extra Mr. Robot dialogue. Stability drains 25% faster."},
]

const FACTIONS := {
	"fsociety": {"name": "fsociety", "desc": "A hacker collective in a dead arcade on Coney Island. They want to erase all debt."},
	"ecorp": {"name": "E Corp", "desc": "The biggest conglomerate on Earth. Owns 70% of consumer debt and most of the city."},
	"darkarmy": {"name": "Dark Army", "desc": "An untraceable hacker army. Answers to one person. Nobody leaves."},
	"fbi": {"name": "FBI", "desc": "The New York field office's cyber division. Agent DiPierro doesn't sleep."},
	"nypd": {"name": "NYPD", "desc": "The cops. They mostly want the city quiet."},
	"locals": {"name": "Lower East Side", "desc": "Your neighbors. Bodega owners, supers, and people who notice things."},
	"allsafe": {"name": "Allsafe", "desc": "Gideon's small cybersecurity firm. One big client, fifty jobs, and your day job."},
	"vera": {"name": "Vera's Crew", "desc": "A dealer's operation running out of the docks. Vera thinks everyone belongs to him."},
	"coney": {"name": "Coney Island", "desc": "Boardwalk folks, carnies, and night people."},
	"candyman": {"name": "Candyman's Crew", "desc": "A Bronx drug operation selling cut 'candy' on the Carver Houses corners. Kids are dying of it."},
	"gamers": {"name": "Respawn", "desc": "Gamers who are done being farmed: streamers, modders, laid-off QA testers, kids with refunds they'll never get. Led by Pixel."},
	"rockstarved": {"name": "Rockstarved Games", "desc": "One great game a decade and a paid-currency store in between. A parody studio. Owned by E Corp."},
	"earse": {"name": "Electronic Arse", "desc": "The same sports game every year, 'surprise mechanics,' and servers that switch off the games you paid for. A parody publisher. Owned by E Corp."},
	"phony": {"name": "Phony Interactive", "desc": "Your account, your library, your purchases: theirs to revoke. A parody platform. Owned by E Corp."},
	"blizzhard": {"name": "Activi$ion Blizzhard", "desc": "Record profits, then record layoffs, and a battle pass for everything. A parody publisher. Owned by Microslop."},
	"ubisloth": {"name": "Ubisloth", "desc": "The same open world with the towers moved around, always online, side quests written by a machine. A parody publisher. Owned by E Corp."},
	"microslop": {"name": "Microslop", "desc": "Buys the studios you love and shuts them down. Wants an account for your toaster and a subscription for your subscription. A parody megacorp. E Corp's favorite child."},
	"harlem": {"name": "Harlem", "desc": "The block associations, the shelter, the churches: the people holding Harlem together with tape and stubbornness."},
}

const XP_CAP_LEVEL := 30

## quests: id -> {title, kind, xp, desc, stages: {n: [{text, marker}]}}
var QUESTS: Dictionary = {}
## Quest lines: id -> {title, quests: [qid in story order]}. Every quest belongs
## to exactly one line; finishing one tracks the next one in the same line.
var LINES: Dictionary = {}
var _loaded: bool = false


func _ready() -> void:
	load_all()


func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	_load_notes("res://data/notes.txt")
	_load_quests("res://data/quests.qst")


func item(id: String) -> Dictionary:
	if ITEMS.has(id):
		return ITEMS[id]
	if NOTES.has(id):
		return NOTES[id]
	return {}


func has_item_def(id: String) -> bool:
	return ITEMS.has(id) or NOTES.has(id)


func item_name(id: String) -> String:
	var d := item(id)
	return str(d.get("name", id))


func perk(id: String) -> Dictionary:
	for p in PERKS:
		if str(p["id"]) == id:
			return p
	return {}


func trait_def(id: String) -> Dictionary:
	for t in TRAITS:
		if str(t["id"]) == id:
			return t
	return {}


# --------------------------------------------------------------------- notes
func _load_notes(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var cur := ""
	var body: PackedStringArray = []
	for raw in f.get_as_text().split("\n"):
		var line := raw.strip_edges(false, true)
		if line.begins_with("=== "):
			_commit_note(cur, body)
			body = []
			var parts := line.substr(4).split("|")
			cur = parts[0].strip_edges()
			NOTES[cur] = {"name": parts[1].strip_edges() if parts.size() > 1 else cur, "type": "note", "value": 0, "text": ""}
		elif cur != "":
			body.append(line)
	_commit_note(cur, body)


func _commit_note(id: String, body: PackedStringArray) -> void:
	if id == "" or not NOTES.has(id):
		return
	var txt := "\n".join(body).strip_edges()
	NOTES[id]["text"] = txt
	NOTES[id]["desc"] = txt.substr(0, 80) + ("..." if txt.length() > 80 else "")


# -------------------------------------------------------------------- quests
## Format:
##   === quest_id | Title | main/side | xp
##   free text description lines
##   10 Objective text @marker_location
##   10 Another parallel objective @other
##   100 done
func _load_quests(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("quests file missing: " + path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var cur := ""
	for raw in f.get_as_text().split("\n"):
		var line := raw.strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		if line.begins_with("+++ "):
			var lp := line.substr(4).split("|")
			var lid := lp[0].strip_edges()
			LINES[lid] = {"title": lp[1].strip_edges() if lp.size() > 1 else lid, "quests": []}
			continue
		if line.begins_with("=== "):
			var parts := line.substr(4).split("|")
			cur = parts[0].strip_edges()
			var ln := parts[4].strip_edges() if parts.size() > 4 else cur
			QUESTS[cur] = {
				"title": parts[1].strip_edges() if parts.size() > 1 else cur,
				"kind": parts[2].strip_edges() if parts.size() > 2 else "side",
				"xp": int(parts[3].strip_edges()) if parts.size() > 3 else 100,
				"line": ln,
				"desc": "",
				"stages": {},
			}
			if not LINES.has(ln):
				LINES[ln] = {"title": QUESTS[cur]["title"], "quests": []}
			(LINES[ln]["quests"] as Array).append(cur)
			continue
		if cur == "":
			continue
		var sp := line.find(" ")
		var head := line.substr(0, sp) if sp > 0 else line
		if head.is_valid_int():
			var n := int(head)
			var rest := line.substr(sp + 1).strip_edges() if sp > 0 else ""
			var marker := ""
			var at := rest.rfind(" @")
			if at >= 0:
				marker = rest.substr(at + 2).strip_edges()
				rest = rest.substr(0, at).strip_edges()
			elif rest.begins_with("@"):
				marker = rest.substr(1).strip_edges()
				rest = ""
			# "[if cond] text": a line (and its marker) shown only while cond
			# holds, so a stage can walk you through its steps one at a time.
			var when := ""
			if rest.begins_with("[if "):
				var cb := rest.find("]")
				when = rest.substr(4, cb - 4).strip_edges()
				rest = rest.substr(cb + 1).strip_edges()
			var st: Dictionary = QUESTS[cur]["stages"]
			if not st.has(n):
				st[n] = []
			var ob := {"text": rest, "marker": marker}
			if when != "":
				ob["when"] = when
			(st[n] as Array).append(ob)
		else:
			var q: Dictionary = QUESTS[cur]
			q["desc"] = (str(q["desc"]) + " " + line).strip_edges()


func quest_line(qid: String) -> String:
	return str(QUESTS.get(qid, {}).get("line", qid))


func line_title(lid: String) -> String:
	return str(LINES.get(lid, {}).get("title", lid))


## [index (1-based), total] of a quest inside its line.
func line_pos(qid: String) -> Array:
	var qs: Array = LINES.get(quest_line(qid), {}).get("quests", [])
	return [qs.find(qid) + 1, qs.size()]


var _obj_conds: Dictionary = {} # parsed "[if ...]" objective conditions


func quest_objectives(qid: String, stage: int) -> Array:
	if not QUESTS.has(qid):
		return []
	var st: Dictionary = QUESTS[qid]["stages"]
	var all: Array = st.get(stage, [])
	var out: Array = []
	for o in all:
		var w := str((o as Dictionary).get("when", ""))
		if w != "" and not _obj_conds.has(w):
			_obj_conds[w] = DialogueManager.parse_cond(w, "quest %s %d" % [qid, stage])
		if w == "" or DialogueManager.eval_cond(_obj_conds[w]):
			out.append(o)
	return out if not out.is_empty() else all


## XP needed to reach level L (New Vegas curve).
func xp_for_level(l: int) -> int:
	if l <= 1:
		return 0
	return 25 * (3 * l + 2) * (l - 1)
