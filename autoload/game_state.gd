extends Node
## GameState — every piece of persistent RPG state lives here.
## World scripts read it, dialogue effects write it, SaveManager serializes it.

signal changed
signal hp_changed(hp: float, max_hp: float)
signal stability_changed(value: int)
signal cash_changed(value: int)
signal xp_gained(amount: int)
signal leveled_up(level: int)
signal quest_updated(qid: String, stage: int, kind: String)
signal notify(text: String, kind: String)
signal inventory_changed
signal equipment_changed
signal achievement_unlocked(title: String, desc: String)
signal died

const TIME_SCALE := 20.0 # game seconds per real second
const START_MINUTES := 18.0 * 60.0 + 40.0 # day 0, 6:40 PM

const ACHIEVEMENTS := {
	"first_hack": ["FIRST BLOOD", "Crack your first terminal."],
	"first_kill": ["POINT OF NO RETURN", "Kill someone. It changes you."],
	"pacifist_59": ["CLEAN HANDS", "Reach the finale without killing anyone."],
	"all_keys": ["FOUR KEYS", "Secure all four keys to Five/Nine."],
	"dead_drops": ["WELL READ", "Find every fsociety dead drop."],
	"high_roller": ["HIGH ROLLER", "Hold $2,000 at once."],
	"level10": ["SUDO", "Reach level 10."],
	"level20": ["ROOT", "Reach level 20."],
	"explorer": ["CARTOGRAPHER", "Discover 30 locations."],
	"shayla_saved": ["NOT THIS TIME", "Get Shayla out alive."],
	"qwerty": ["FISH WHISPERER", "Keep Qwerty fed for three days."],
	"overlap": ["THE OVERLAP", "Find the hidden ending."],
	"arcade_champ": ["HIGH SCORE", "Top the Fun Society leaderboard."],
	"ghost": ["GHOST", "Get through Steel Mountain without being detected."],
	"microslop": ["MICROSLOP MASSACRE", "Find the switch on Floor 101."],
	"masks": ["FIFTY FACES", "Find all fifty hidden fsociety masks."],
	"road_trip": ["ROAD TRIP", "Visit every city and town on the map."],
	"airfields": ["SIX FIELDS", "Land a plane at every airfield."],
	"racer": ["LOCAL LEGEND", "Win a street race on every map."],
	"taxi": ["YOU TALKIN' TO ME?", "Drive ten taxi fares."],
	"aces": ["WHEELS DOWN", "Take gold in every air race."],
	"air_time": ["AIR TIME", "Land every stunt jump."],
}

# ------------------------------------------------------------------ state
var flags: Dictionary = {}
var hp: float = 100.0
var focus: float = 60.0
var stability: int = 80
var level: int = 1
var xp: int = 0
var skill_points: int = 0
var perk_points: int = 0
var pending_levels: int = 0
var base_skills: Dictionary = {}
var tags: Array = []
var traits: Array = []
var perks: Dictionary = {} # id -> rank
var cash: int = 60
var inventory: Dictionary = {} # item id -> count
var equipped: Dictionary = {"weapon": "fists", "body": "hoodie_black", "head": ""}
var mags: Dictionary = {} # weapon id -> rounds loaded
var hotkeys: Array = ["fists", "", "", "", "", "", "", ""]
var quests: Dictionary = {} # qid -> {stage, state, log:[stages]}
var tracked_quest: String = ""
var fame: Dictionary = {}
var infamy: Dictionary = {}
var trust: Dictionary = {}
var companions: Array = []
var dead: Dictionary = {}
var hostile: Dictionary = {} # npc id -> true (individually angered)
var containers: Dictionary = {} # container id -> {"items": {}, "cash": int}
var picked: Dictionary = {} # world pickup id -> true
## Vehicles you left somewhere (or own). Each: {uid, kind: car|plane, model, ci,
## pos: [x,y,z], yaw, hp, home: bool, owned: bool, slot}. They stay where you
## parked them, across saves.
var rides: Array = []
## Which map you're on: "nyc", "highway", "chicago" (see Regions).
var region: String = "nyc"
var unlocked: Dictionary = {} # lock id -> true
var discovered: Dictionary = {} # location id -> true
var game_minutes: float = START_MINUTES
var weather: String = "clear"
var weather_until: float = 0.0
var buffs: Array = [] # {id, skills:{}, until:float}
var stats: Dictionary = {}
var last_innocent: Dictionary = {} # {day, hour, cell} of the latest civilian killed by the player
var achievements: Array = []
var ending: String = ""
var wanted_until: float = -1.0
## Police heat, 0-5 stars. Each new crime while wanted raises it; breaking line
## of sight long enough (Game) clears it.
var heat: int = 0
## A crime was just committed or the heat went up: the police know where you are.
signal heat_raised
var zero_day_day: int = -1
var last_won: bool = false
var cell: String = "world" # world or interior id
var player_pos: Vector3 = Vector3.ZERO
var pos_local: bool = false # player_pos is relative to the cell's origin (saves since v2.1)
var player_yaw: float = 0.0
var dead_npc_pos: Dictionary = {}
var shop_stock: Dictionary = {} # shop id -> {items:{}, cash:int, day:int}
var npc_pos_override: Dictionary = {}
var jobs_state: Dictionary = {}
var playtime: float = 0.0
var debug_log: Array = []


func _ready() -> void:
	new_game()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	playtime += delta
	game_minutes += delta * TIME_SCALE / 60.0
	# Focus regenerates (FNV Action Points).
	if focus < max_focus():
		focus = minf(max_focus(), focus + delta * 6.0)
	_expire_buffs()


func new_game() -> void:
	flags = {}
	hp = 100.0
	focus = 60.0
	stability = 80
	level = 1
	xp = 0
	skill_points = 0
	perk_points = 0
	pending_levels = 0
	base_skills = {}
	for s in DB.SKILLS:
		base_skills[s] = 15
	tags = []
	traits = []
	perks = {}
	cash = 60
	inventory = {}
	equipped = {"weapon": "fists", "body": "hoodie_black", "head": ""}
	mags = {}
	hotkeys = ["fists", "", "", "", "", "", "", ""]
	quests = {}
	tracked_quest = ""
	fame = {}
	infamy = {}
	for f in DB.FACTIONS.keys():
		fame[f] = 0
		infamy[f] = 0
	trust = {"darlene": 0, "angela": 0, "robot": 0, "krista": 0, "shayla": 0, "leon": 0, "tyrell": 0}
	companions = []
	dead = {}
	hostile = {}
	containers = {}
	picked = {}
	rides = []
	region = "nyc"
	unlocked = {}
	discovered = {}
	game_minutes = START_MINUTES
	weather = "clear"
	weather_until = START_MINUTES + 240.0
	buffs = []
	stats = {"kills": 0, "innocents": 0, "hacks": 0, "locks": 0, "checks": 0, "quests": 0, "damage": 0, "exploits": 0, "caps_found": 0}
	last_innocent = {}
	achievements = []
	ending = ""
	wanted_until = -1.0
	heat = 0
	zero_day_day = -1
	last_won = false
	cell = "world"
	player_pos = Vector3.ZERO
	pos_local = false
	player_yaw = 0.0
	dead_npc_pos = {}
	shop_stock = {}
	npc_pos_override = {}
	jobs_state = {}
	playtime = 0.0
	give("hoodie_black", 1, true)
	give("key_apartment", 1, true)
	give("bobby_pin", 4, true)
	give("coffee", 2, true)
	give("meds", 2, true)
	give("burner_phone", 1, true)
	emit_signal("changed")


# ------------------------------------------------------------------- time
func day() -> int:
	return int(game_minutes / 1440.0)


func hour() -> float:
	return fmod(game_minutes, 1440.0) / 60.0


func is_night() -> bool:
	var h := hour()
	return h >= 20.0 or h < 6.0


func clock_text() -> String:
	var m := int(fmod(game_minutes, 1440.0))
	var h := m / 60
	var mm := m % 60
	var suffix := "AM" if h < 12 else "PM"
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, mm, suffix]


func date_text() -> String:
	var days := ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
	return "%s, DAY %d" % [days[day() % 7], day() + 1]


func advance_time(minutes: float) -> void:
	game_minutes += maxf(0.0, minutes)
	_expire_buffs()
	emit_signal("changed")


# ------------------------------------------------------------------ flags
func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value
	emit_signal("changed")


func get_flag(key: String, default: Variant = false) -> Variant:
	return flags.get(key, default)


func has_flag(key: String) -> bool:
	var v: Variant = flags.get(key, false)
	if v is bool:
		return v
	if v is int or v is float:
		return v != 0
	if v is String:
		return v != "" and v != "false" and v != "0"
	return v != null


func add_flag(key: String, amount: int) -> void:
	flags[key] = int(flags.get(key, 0)) + amount
	emit_signal("changed")


# ----------------------------------------------------------------- skills
func skill(s: String) -> int:
	var v: int = int(base_skills.get(s, 15))
	# Apparel.
	for slot in ["body", "head"]:
		var id: String = str(equipped.get(slot, ""))
		if id != "":
			var b: Dictionary = DB.item(id).get("bonus", {})
			v += int(b.get(s, 0))
	# Perks.
	if has_perk("hello_friend") and (s == "speech" or s == "barter"):
		v += 5
	if has_perk("script_kiddie") and s == "hacking":
		v += 10
	if has_perk("night_owl") and is_night():
		if s == "sneak":
			v += 10
		elif s == "guns":
			v += 5
	if has_perk("polymath"):
		v += 5
	if has_perk("legend"):
		v += 10
	# Companions on the road, and what their last heart-to-heart taught you.
	for cid in companions:
		var cd: Dictionary = CompanionData.get_def(str(cid))
		v += int((cd.get("bonus", {}) as Dictionary).get(s, 0))
	for cid2 in CompanionData.C.keys():
		if flags.has("cperk_" + str(cid2)):
			v += int((CompanionData.C[cid2]["perk"] as Dictionary).get(s, 0))
	# Traits.
	if has_trait("insomniac"):
		if is_night() and (s == "hacking" or s == "sneak"):
			v += 10
		elif not is_night() and s == "speech":
			v -= 10
	if has_trait("paranoid"):
		if s == "sneak":
			v += 10
		elif s == "speech":
			v -= 10
	if has_trait("loner"):
		v += (-5 if companions.size() > 0 else 10)
	if has_trait("skilled"):
		v += 5
	# Buffs.
	for b in buffs:
		v += int((b["skills"] as Dictionary).get(s, 0))
	# Tools you carry.
	if s == "lockpick" and has_item("lockpick_set"):
		v += 5
	# A fraying mind costs you.
	if stability < 25:
		v -= 5
	return clampi(v, 0, 100)


func raise_skill(s: String, amount: int) -> void:
	base_skills[s] = clampi(int(base_skills.get(s, 15)) + amount, 0, 100)
	emit_signal("changed")


func set_tags(t: Array) -> void:
	# Remove previous tag bonus, apply new (used by the intake form).
	for old in tags:
		base_skills[old] = int(base_skills[old]) - 15
	tags = t.duplicate()
	for s in tags:
		base_skills[s] = int(base_skills[s]) + 15
	emit_signal("changed")


func has_trait(id: String) -> bool:
	return traits.has(id)


func has_perk(id: String) -> bool:
	return int(perks.get(id, 0)) > 0


func perk_rank(id: String) -> int:
	return int(perks.get(id, 0))


func perk_available(id: String) -> bool:
	var p := DB.perk(id)
	if p.is_empty():
		return false
	if level < int(p["level"]):
		return false
	if perk_rank(id) >= int(p["ranks"]):
		return false
	var req: Dictionary = p["req"]
	for s in req.keys():
		if int(base_skills.get(s, 0)) < int(req[s]):
			return false
	return true


func take_perk(id: String) -> bool:
	if perk_points <= 0 or not perk_available(id):
		return false
	perks[id] = perk_rank(id) + 1
	perk_points -= 1
	if id == "toughened" or id == "juggernaut":
		hp = minf(hp + (10.0 if id == "toughened" else 25.0), max_hp())
	emit_signal("changed")
	emit_signal("hp_changed", hp, max_hp())
	return true


# ------------------------------------------------------------ derived stats
func max_hp() -> float:
	return 100.0 + float(level - 1) * 5.0 + float(perk_rank("toughened")) * 10.0 + (25.0 if has_perk("juggernaut") else 0.0)


func max_focus() -> float:
	return 60.0 + (15.0 if has_perk("kill_chain") else 0.0) + float(level) * 1.0


func damage_threshold() -> float:
	var dt := 0.0
	for slot in ["body", "head"]:
		var id: String = str(equipped.get(slot, ""))
		if id != "":
			dt += float(DB.item(id).get("dt", 0))
	if has_perk("thick_skin"):
		dt += 3.0
	if has_perk("juggernaut"):
		dt += 2.0
	return dt


func disguise() -> String:
	var id: String = str(equipped.get("body", ""))
	return str(DB.item(id).get("disguise", "")) if id != "" else ""


func wearing_mask() -> bool:
	var id: String = str(equipped.get("head", ""))
	return id != "" and bool(DB.item(id).get("mask", false))


# ---------------------------------------------------------------- xp/levels
func add_xp(amount: int) -> void:
	if amount <= 0 or level >= DB.XP_CAP_LEVEL:
		return
	if has_trait("skilled"):
		amount = int(round(float(amount) * 0.9))
	xp += amount
	emit_signal("xp_gained", amount)
	while level + pending_levels < DB.XP_CAP_LEVEL and xp >= DB.xp_for_level(level + pending_levels + 1):
		pending_levels += 1
		emit_signal("notify", "LEVEL UP — open your phone [TAB] to level up", "level")
	emit_signal("changed")


## Applies one pending level: skill points spent in the level-up screen.
func apply_level_up(spent: Dictionary, perk_id: String) -> void:
	if pending_levels <= 0:
		return
	pending_levels -= 1
	level += 1
	for s in spent.keys():
		raise_skill(str(s), int(spent[s]))
	if level % 2 == 0:
		perk_points += 1
	if perk_id != "":
		take_perk(perk_id)
	hp = max_hp()
	if level >= 10:
		unlock("level10")
	if level >= 20:
		unlock("level20")
	emit_signal("leveled_up", level)
	emit_signal("hp_changed", hp, max_hp())
	emit_signal("changed")


func skill_points_per_level() -> int:
	return 12


# --------------------------------------------------------------- health
func damage(amount: float) -> void:
	if amount <= 0.0 or hp <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	stats["damage"] = int(stats.get("damage", 0)) + int(amount)
	emit_signal("hp_changed", hp, max_hp())
	if hp <= 0.0:
		emit_signal("died")


func heal(amount: float) -> void:
	hp = clampf(hp + amount, 0.0, max_hp())
	emit_signal("hp_changed", hp, max_hp())


func adjust_stability(amount: int) -> void:
	if amount < 0:
		if has_perk("paranoia"):
			amount = int(floor(float(amount) / 2.0))
		if has_trait("robot_kid"):
			amount = int(floor(float(amount) * 1.25))
	var floor_v := 25 if has_perk("mastermind") else 0
	stability = clampi(stability + amount, floor_v, 100)
	emit_signal("stability_changed", stability)
	emit_signal("changed")


func spend_focus(amount: float) -> bool:
	if focus < amount:
		return false
	focus -= amount
	return true


# -------------------------------------------------------------- inventory
func count(id: String) -> int:
	return int(inventory.get(id, 0))


func has_item(id: String, n: int = 1) -> bool:
	return count(id) >= n


func give(id: String, n: int = 1, silent: bool = false) -> void:
	if n <= 0:
		return
	if not DB.has_item_def(id):
		push_warning("give: unknown item " + id)
		return
	var d := DB.item(id)
	# Cash-in-a-bag items go straight to the wallet.
	if int(d.get("cash", 0)) > 0:
		add_cash(int(d["cash"]) * n)
		return
	inventory[id] = count(id) + n
	if bool(d.get("unique", false)):
		emit_signal("notify", "UNIQUE WEAPON: %s" % DB.item_name(id), "level")
		stat_add("uniques")
	if str(d.get("type", "")) == "weapon":
		if not mags.has(id):
			mags[id] = int(d.get("mag", 0))
		_auto_hotkey(id)
	if not silent:
		emit_signal("notify", "%s%s added" % [DB.item_name(id), (" (%d)" % n) if n > 1 else ""], "item")
	emit_signal("inventory_changed")


func take(id: String, n: int = 1, silent: bool = false) -> int:
	var have := count(id)
	var removed := mini(have, n)
	if removed <= 0:
		return 0
	if have - removed <= 0:
		inventory.erase(id)
		# Unequip if we just lost it.
		for slot in equipped.keys():
			if str(equipped[slot]) == id:
				equipped[slot] = "fists" if slot == "weapon" else ""
				emit_signal("equipment_changed")
		for i in hotkeys.size():
			if str(hotkeys[i]) == id:
				hotkeys[i] = ""
	else:
		inventory[id] = have - removed
	if not silent:
		emit_signal("notify", "%s%s removed" % [DB.item_name(id), (" (%d)" % removed) if removed > 1 else ""], "item")
	emit_signal("inventory_changed")
	return removed


func _auto_hotkey(id: String) -> void:
	if hotkeys.has(id):
		return
	for i in range(1, hotkeys.size()):
		if str(hotkeys[i]) == "":
			hotkeys[i] = id
			return


func set_cash(v: int) -> void:
	cash = maxi(0, v)
	emit_signal("cash_changed", cash)
	emit_signal("changed")
	if cash >= 2000:
		unlock("high_roller")


func add_cash(delta: int, silent: bool = false) -> void:
	set_cash(cash + delta)
	if not silent and delta != 0:
		emit_signal("notify", ("+$%d" % delta) if delta > 0 else ("-$%d" % -delta), "cash")


func equip(id: String) -> void:
	if id == "fists":
		equipped["weapon"] = "fists"
		emit_signal("equipment_changed")
		return
	if not has_item(id):
		return
	var d := DB.item(id)
	var t := str(d.get("type", ""))
	if t == "weapon":
		equipped["weapon"] = id
		if not mags.has(id):
			mags[id] = 0
	elif t == "apparel":
		var slot := str(d.get("slot", "body"))
		equipped[slot] = "" if str(equipped.get(slot, "")) == id else id
	emit_signal("equipment_changed")
	emit_signal("changed")


func is_equipped(id: String) -> bool:
	for slot in equipped.keys():
		if str(equipped[slot]) == id:
			return true
	return false


## Use an aid item. Returns true if consumed.
func use_aid(id: String) -> bool:
	if not has_item(id):
		return false
	var d := DB.item(id)
	if str(d.get("type", "")) != "aid":
		return false
	var fx: Dictionary = d.get("fx", {})
	var med_mult := 1.0 + float(skill("medicine")) / 100.0
	if has_perk("field_medic"):
		med_mult += 0.3
	if fx.has("hp"):
		heal(float(fx["hp"]) * med_mult)
	if fx.has("focus"):
		focus = minf(max_focus(), focus + float(fx["focus"]))
	if fx.has("stab"):
		adjust_stability(int(fx["stab"]))
	if d.has("buff"):
		var b: Dictionary = d["buff"]
		buffs = buffs.filter(func(x: Dictionary) -> bool: return str(x["id"]) != id)
		buffs.append({"id": id, "skills": b.get("skills", {}), "until": game_minutes + float(b.get("minutes", 60))})
	if id == "meds":
		set_flag("meds_taken_day", day())
		add_flag("meds_taken", 1)
	take(id, 1, true)
	emit_signal("notify", "Used %s" % DB.item_name(id), "item")
	emit_signal("changed")
	return true


func _expire_buffs() -> void:
	if buffs.is_empty():
		return
	var before := buffs.size()
	buffs = buffs.filter(func(b: Dictionary) -> bool: return float(b["until"]) > game_minutes)
	if buffs.size() != before:
		emit_signal("changed")


func best_healing_item() -> String:
	var best := ""
	var best_hp := 0.0
	var missing := max_hp() - hp
	for id in inventory.keys():
		var d := DB.item(str(id))
		if str(d.get("type", "")) != "aid":
			continue
		var h := float((d.get("fx", {}) as Dictionary).get("hp", 0))
		if h <= 0.0:
			continue
		# Prefer the smallest item that covers the gap, else the biggest.
		if best == "" or (h >= missing and (best_hp < missing or h < best_hp)) or (best_hp < missing and h > best_hp):
			best = str(id)
			best_hp = h
	return best


# ------------------------------------------------------------------ quests
func quest_stage(qid: String) -> int:
	if not quests.has(qid):
		return 0
	return int(quests[qid]["stage"])


func quest_state(qid: String) -> String:
	if not quests.has(qid):
		return ""
	return str(quests[qid]["state"])


func set_quest_stage(qid: String, stage: int) -> void:
	if not DB.QUESTS.has(qid):
		push_warning("unknown quest " + qid)
		return
	var q: Dictionary = DB.QUESTS[qid]
	if not quests.has(qid):
		quests[qid] = {"stage": 0, "state": "active", "log": []}
		emit_signal("quest_updated", qid, stage, "started")
		# The next mission in the line you're following takes over the tracker;
		# a new line never steals it from a mission you're in the middle of.
		var tq := tracked_quest
		if tq == "" or quest_state(tq) != "active" or DB.quest_line(tq) == DB.quest_line(qid):
			tracked_quest = qid
	var cur: Dictionary = quests[qid]
	if str(cur["state"]) != "active":
		return
	if stage <= int(cur["stage"]):
		return
	cur["stage"] = stage
	(cur["log"] as Array).append(stage)
	var objs := DB.quest_objectives(qid, stage)
	var is_done := stage >= 100 or (objs.size() == 1 and str(objs[0]["text"]) == "done")
	if is_done:
		complete_quest(qid)
		return
	emit_signal("quest_updated", qid, stage, "stage")
	emit_signal("changed")


func complete_quest(qid: String) -> void:
	if not quests.has(qid):
		quests[qid] = {"stage": 100, "state": "active", "log": [100]}
	var cur: Dictionary = quests[qid]
	if str(cur["state"]) == "done":
		return
	cur["state"] = "done"
	cur["stage"] = maxi(int(cur["stage"]), 100)
	stats["quests"] = int(stats.get("quests", 0)) + 1
	var q: Dictionary = DB.QUESTS.get(qid, {})
	emit_signal("quest_updated", qid, 100, "done")
	add_xp(int(q.get("xp", 100)))
	if tracked_quest == qid:
		tracked_quest = _next_tracked(qid)
	emit_signal("changed")


func fail_quest(qid: String) -> void:
	if not quests.has(qid):
		quests[qid] = {"stage": 0, "state": "active", "log": []}
	var cur: Dictionary = quests[qid]
	if str(cur["state"]) != "active":
		return
	cur["state"] = "failed"
	emit_signal("quest_updated", qid, int(cur["stage"]), "failed")
	if tracked_quest == qid:
		tracked_quest = _next_tracked(qid)
	emit_signal("changed")


## After a quest ends: the next active mission in the same line, else the
## main story, else anything still open.
func _next_tracked(after: String = "") -> String:
	var line := DB.quest_line(after) if after != "" else ""
	var best := ""
	var best_score := -1
	for qid in quests.keys():
		if str(quests[qid]["state"]) != "active":
			continue
		var score := 0
		if line != "" and DB.quest_line(str(qid)) == line:
			score = 3
		elif str(DB.QUESTS.get(qid, {}).get("kind", "")) == "main":
			score = 2
		else:
			score = 1
		if score > best_score:
			best_score = score
			best = str(qid)
	return best


func active_quests() -> Array:
	var out: Array = []
	for qid in quests.keys():
		if str(quests[qid]["state"]) == "active":
			out.append(str(qid))
	return out


# -------------------------------------------------------------- reputation
func add_fame(f: String, n: int) -> void:
	fame[f] = int(fame.get(f, 0)) + n
	if n > 0:
		emit_signal("notify", "%s reputation up" % DB.FACTIONS.get(f, {}).get("name", f), "rep")
	emit_signal("changed")


func add_infamy(f: String, n: int) -> void:
	# The mask keeps your name out of it (except with people who already know).
	if wearing_mask() and f in ["ecorp", "nypd", "fbi"]:
		n = int(ceil(float(n) * 0.25))
	infamy[f] = int(infamy.get(f, 0)) + n
	if n > 0:
		emit_signal("notify", "%s reputation down" % DB.FACTIONS.get(f, {}).get("name", f), "rep")
	emit_signal("changed")


func rep_tier(v: int) -> int:
	if v >= 50:
		return 3
	if v >= 25:
		return 2
	if v >= 8:
		return 1
	return 0


func rep_title(f: String) -> String:
	var ft := rep_tier(int(fame.get(f, 0)))
	var it := rep_tier(int(infamy.get(f, 0)))
	var grid := [
		["Unknown", "Suspect", "Enemy", "Public Enemy"],
		["Noticed", "Wildcard", "Troublemaker", "Hunted"],
		["Trusted", "Double Agent", "Loose Cannon", "Dangerous"],
		["Legend", "Folk Hero", "Necessary Evil", "Myth"],
	]
	return str(grid[ft][it])


func faction_hostile(f: String) -> bool:
	if has_flag("hostile_" + f):
		return true
	if f == "nypd" and wanted_until > game_minutes:
		return true
	var fa := int(fame.get(f, 0))
	var inf := int(infamy.get(f, 0))
	return inf >= 25 and inf > fa + 10


func add_trust(who: String, n: int) -> void:
	trust[who] = clampi(int(trust.get(who, 0)) + n, -10, 10)
	emit_signal("changed")


func get_trust(who: String) -> int:
	return int(trust.get(who, 0))


func set_wanted(minutes: float) -> void:
	if minutes <= 0.0:
		return
	var was := is_wanted()
	wanted_until = maxf(wanted_until, game_minutes + minutes)
	# Bigger crimes start hotter; a crime while they're already after you
	# turns it up a star.
	var base := 2 if minutes >= 120.0 else 1
	add_heat(1 if was else base, false)
	if not was:
		emit_signal("notify", "The police are looking for you", "warn")


func is_wanted() -> bool:
	return wanted_until > game_minutes and heat > 0


## Raise the police heat by `n` stars (max 5), and keep them looking.
func add_heat(n: int, extend: bool = true) -> void:
	var before := heat
	heat = clampi(heat + n, 1, 5)
	emit_signal("heat_raised")
	if extend:
		wanted_until = maxf(wanted_until, game_minutes + 30.0 + 20.0 * float(heat))
	if heat > before and before > 0:
		emit_signal("notify", "Heat: " + "★".repeat(heat) + "☆".repeat(5 - heat), "warn")


func clear_wanted() -> void:
	wanted_until = -1.0
	heat = 0


# ------------------------------------------------------------ world state
func mark_dead(npc_id: String) -> void:
	dead[npc_id] = true
	companions.erase(npc_id)
	emit_signal("changed")


func is_dead(npc_id: String) -> bool:
	return dead.has(npc_id)


func discover(loc_id: String, loc_name: String = "") -> bool:
	if discovered.has(loc_id):
		return false
	discovered[loc_id] = true
	if loc_name != "":
		emit_signal("notify", "Discovered: %s" % loc_name, "discover")
		add_xp(10)
	if discovered.size() >= 30:
		unlock("explorer")
	emit_signal("changed")
	return true


func unlock(ach: String) -> void:
	if achievements.has(ach) or not ACHIEVEMENTS.has(ach):
		return
	achievements.append(ach)
	var a: Array = ACHIEVEMENTS[ach]
	emit_signal("achievement_unlocked", str(a[0]), str(a[1]))


func stat_add(key: String, n: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + n


# -------------------------------------------------------------- save/load
func to_dict() -> Dictionary:
	return {
		"version": 2,
		"flags": flags, "hp": hp, "focus": focus, "stability": stability,
		"level": level, "xp": xp, "skill_points": skill_points, "perk_points": perk_points,
		"pending_levels": pending_levels, "base_skills": base_skills, "tags": tags, "traits": traits,
		"perks": perks, "cash": cash, "inventory": inventory, "equipped": equipped, "mags": mags,
		"hotkeys": hotkeys, "quests": quests, "tracked_quest": tracked_quest, "fame": fame,
		"infamy": infamy, "trust": trust, "companions": companions, "dead": dead, "hostile": hostile,
		"containers": containers, "picked": picked, "unlocked": unlocked, "discovered": discovered,
		"game_minutes": game_minutes, "weather": weather, "weather_until": weather_until,
		"buffs": buffs, "stats": stats, "last_innocent": last_innocent, "achievements": achievements, "ending": ending,
		"wanted_until": wanted_until, "heat": heat, "zero_day_day": zero_day_day, "cell": cell,
		"player_pos": [player_pos.x, player_pos.y, player_pos.z], "player_yaw": player_yaw,
		"shop_stock": shop_stock, "npc_pos_override": npc_pos_override, "playtime": playtime,
		"jobs_state": jobs_state, "dead_npc_pos": dead_npc_pos, "pos_local": pos_local, "rides": rides, "region": region,
	}


func from_dict(d: Dictionary) -> void:
	new_game()
	flags = _dict(d, "flags")
	hp = maxf(1.0, float(d.get("hp", 100.0)))
	focus = float(d.get("focus", 60.0))
	stability = int(d.get("stability", 80))
	level = clampi(int(d.get("level", 1)), 1, DB.XP_CAP_LEVEL)
	xp = int(d.get("xp", 0))
	skill_points = int(d.get("skill_points", 0))
	perk_points = int(d.get("perk_points", 0))
	pending_levels = int(d.get("pending_levels", 0))
	var bs := _dict(d, "base_skills")
	for s in DB.SKILLS:
		base_skills[s] = int(bs.get(s, 15))
	tags = _arr(d, "tags")
	traits = _arr(d, "traits")
	perks = {}
	var pk := _dict(d, "perks")
	for k in pk.keys():
		perks[str(k)] = int(pk[k])
	cash = int(d.get("cash", 0))
	inventory = {}
	var inv := _dict(d, "inventory")
	for k in inv.keys():
		if DB.has_item_def(str(k)) and int(inv[k]) > 0:
			inventory[str(k)] = int(inv[k])
	var eq := _dict(d, "equipped")
	equipped = {"weapon": str(eq.get("weapon", "fists")), "body": str(eq.get("body", "")), "head": str(eq.get("head", ""))}
	if str(equipped["weapon"]) != "fists" and not has_item(str(equipped["weapon"])):
		equipped["weapon"] = "fists"
	mags = {}
	var mg := _dict(d, "mags")
	for k in mg.keys():
		mags[str(k)] = int(mg[k])
	hotkeys = _arr(d, "hotkeys")
	while hotkeys.size() < 8:
		hotkeys.append("")
	quests = {}
	var qs := _dict(d, "quests")
	for k in qs.keys():
		var q: Dictionary = qs[k]
		var lg: Array = []
		for s in q.get("log", []):
			lg.append(int(s))
		quests[str(k)] = {"stage": int(q.get("stage", 0)), "state": str(q.get("state", "active")), "log": lg}
	tracked_quest = str(d.get("tracked_quest", ""))
	fame = _intdict(_dict(d, "fame"))
	infamy = _intdict(_dict(d, "infamy"))
	for f in DB.FACTIONS.keys():
		fame[f] = int(fame.get(f, 0))
		infamy[f] = int(infamy.get(f, 0))
	trust = _intdict(_dict(d, "trust"))
	companions = _arr(d, "companions")
	dead = _dict(d, "dead")
	hostile = _dict(d, "hostile")
	dead_npc_pos = _dict(d, "dead_npc_pos")
	pos_local = bool(d.get("pos_local", false))
	containers = _dict(d, "containers")
	picked = _dict(d, "picked")
	region = str(d.get("region", "nyc"))
	rides = []
	for r in _arr(d, "rides"):
		if r is Dictionary and (r as Dictionary).has("pos"):
			rides.append(r)
	unlocked = _dict(d, "unlocked")
	discovered = _dict(d, "discovered")
	game_minutes = float(d.get("game_minutes", START_MINUTES))
	weather = str(d.get("weather", "clear"))
	weather_until = float(d.get("weather_until", game_minutes + 120.0))
	buffs = _arr(d, "buffs")
	stats = _dict(d, "stats")
	last_innocent = _dict(d, "last_innocent")
	achievements = _arr(d, "achievements")
	ending = str(d.get("ending", ""))
	wanted_until = float(d.get("wanted_until", -1.0))
	heat = int(d.get("heat", 1 if wanted_until > game_minutes else 0))
	zero_day_day = int(d.get("zero_day_day", -1))
	cell = str(d.get("cell", "world"))
	var pp: Array = d.get("player_pos", [0, 0, 0])
	if pp.size() >= 3:
		player_pos = Vector3(float(pp[0]), float(pp[1]), float(pp[2]))
	player_yaw = float(d.get("player_yaw", 0.0))
	shop_stock = _dict(d, "shop_stock")
	npc_pos_override = _dict(d, "npc_pos_override")
	jobs_state = _dict(d, "jobs_state")
	playtime = float(d.get("playtime", 0.0))
	emit_signal("changed")
	emit_signal("hp_changed", hp, max_hp())
	emit_signal("stability_changed", stability)
	emit_signal("cash_changed", cash)
	emit_signal("inventory_changed")
	emit_signal("equipment_changed")


func _dict(d: Dictionary, k: String) -> Dictionary:
	var v: Variant = d.get(k, {})
	return (v as Dictionary).duplicate(true) if v is Dictionary else {}


func _arr(d: Dictionary, k: String) -> Array:
	var v: Variant = d.get(k, [])
	return (v as Array).duplicate(true) if v is Array else []


func _intdict(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d.keys():
		out[str(k)] = int(d[k])
	return out


func log_msg(msg: String) -> void:
	debug_log.append(msg)
	if debug_log.size() > 300:
		debug_log.pop_front()
