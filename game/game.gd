extends Node3D
## Game — owns the world, the player, every system and every UI layer.
## Cells: "world" (the city) or an interior id. Interiors live far from the
## city and are built on first entry, so moving between them is instant.

const CONTAINER_H := 1.0

var player: Player
var hud: HUD
var dialog: DialogueUI
var phone: Phone
var loot_ui: LootUI
var barter_ui: BarterUI
var levelup_ui: LevelUpUI
var terminal_ui: TerminalUI
var minigames: MinigameHost
var pause_menu: PauseMenu
var intake_ui: IntakeUI
var ending_ui: EndingUI
var death_ui: DeathUI
var wait_ui: WaitUI
var travel_ui: TravelUI
var exploit_ui: ExploitUI
var env_ctl: WorldEnv
var fx: FX
var npcs: NPCManager
var crowd: Crowd
var traffic: Traffic
var city_root: Node3D
var city_extras: Node3D
var interiors_root: Node3D
var world_inter: Node3D
var ferris: Node3D
var busy_transition: bool = false
var cinematic: bool = false
var ui_depth: int = 0
var built_interiors: Dictionary = {} # id -> Node3D
var interior_index: Dictionary = {}
var current_subway: String = ""
var map_image: Image
var city_buildings: Array = []
var test_mode: bool = false
var test_picker: Callable
var _loading: Control
var _loading_lbl: Label
var _tick: float = 0.0
var _slow_tick: float = 0.0
var _detect_level: int = 0
var _detect_reports: Dictionary = {}
var _pending: Array = [] # deferred world effects after dialogue
var _cop_t: float = 0.0
var _whisper_t: float = 120.0
var _triggers_fired: Dictionary = {}
var _trig_conds: Dictionary = {}
var _last_district: String = ""
var _dead: bool = false
var _aim_target: Variant = null
var _blackout_cool: float = 0.0
## Generic-building doors (id -> entry) and every searchable city prop.
var gen_doors: Dictionary = {}
var loot_index: LootIndex
var jobs: Jobs
var encounters: Encounters
var _virt: Interactable
var _proc_defs: Dictionary = {}
const PROC_SLOT := 95 # interior origin slot shared by generated interiors
var _far_meshes: Array = [] # [MeshInstance3D, normal visibility range]
var robot_popup: RobotPopup
var vehicles_root: Node3D
var parked_cars: Array = [] # stealable Vehicles parked near the player
var player_car: Vehicle = null # the last car you drove (kept around)
var _high_mode: bool = false
var force_high: bool = false # intro flyover: draw the whole city


func _ready() -> void:
	DialogueManager.game = self
	if SaveManager.pending_load.get("state") is Dictionary:
		GameState.from_dict(SaveManager.pending_load["state"])
		SaveManager.pending_load.erase("state")
	WorldLayout.set_region(GameState.region)
	Mats.init()
	Mats.set_hidden_cars([]) # stolen parked cars come back on a fresh load
	_make_loading()
	await get_tree().process_frame
	await get_tree().process_frame
	await _build_world()
	_make_player()
	_make_ui()
	_make_world_interactables()
	GameState.died.connect(_on_died)
	GameState.heat_raised.connect(_on_heat_raised)
	GameState.leveled_up.connect(func(l: int) -> void: robot_popup.level_up(l))
	_loading.queue_free()
	if not SaveManager.pending_load.is_empty():
		var carry: Dictionary = SaveManager.pending_load.get("travel", {})
		var by_air := bool(SaveManager.pending_load.get("by_air", false))
		SaveManager.pending_load = {}
		await _restore_from_state()
		await _arrive_with(carry, by_air)
	else:
		await _start_new_game()


func _exit_tree() -> void:
	if DialogueManager.game == self:
		DialogueManager.game = null
	Engine.time_scale = 1.0


# ------------------------------------------------------------------- build
func _make_loading() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_loading = ColorRect.new()
	(_loading as ColorRect).color = Color(0, 0, 0, 1)
	_loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_loading)
	_loading_lbl = UI.label("", 22, UI.GREEN)
	_loading_lbl.set_anchors_preset(Control.PRESET_CENTER)
	_loading_lbl.position = Vector2(-300, -20)
	_loading_lbl.size = Vector2(600, 40)
	_loading_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading.add_child(_loading_lbl)
	var tip_text := _loading_tip()
	if SaveManager.pending_load.has("travel"):
		tip_text = _crossing_line(str(GameState.flags.get("region_from", "")), GameState.region)
	var tip := UI.label(tip_text, 16, UI.GREEN_DIM)
	tip.set_anchors_preset(Control.PRESET_CENTER)
	tip.position = Vector2(-420, 40)
	tip.size = Vector2(840, 80)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading.add_child(tip)
	_loading_lbl.text = "> booting city.sys ..."


## What the loading card says while you cross from one map into the next.
func _crossing_line(from: String, to: String) -> String:
	match to:
		"highway":
			var ahead := "New York is straight ahead."
			match from:
				"nyc":
					ahead = "Chicago is straight ahead. Exit 41 west for Washington Township, Exit 42 east for Port Ramsey."
				"township", "port":
					ahead = "North for Chicago, south for New York, across for the other town."
			return "Interstate 80. Three kilometres of Pennsylvania farmland, a diner, a motel, and billboards with opinions. " + ahead
		"chicago":
			return "Chicago. The Loop to the west of the lake, Meigs Field on the shore, and somewhere on the South Side a warehouse waiting for you."
		"nyc":
			return "New York. The Bronx under you, the towers on the horizon, and all of it exactly as loud as you left it."
		"township":
			return "Washington Township, New Jersey. A water tower, a Main Street, a memorial wall, and the stacks of the plant that was supposed to have closed in 1994."
		"port":
			return "Port Ramsey. Half fishing town, half E Corp freight terminal, and the freight half is winning. A lighthouse at the end of a jetty, and a ship the size of a street at berth 2."
		"gary":
			return "Gary, Indiana. Cold blast furnaces on the lakeshore, a depot of trucks with nobody in them, and a union hall on Broadway with its lights still on."
		"island":
			return "Price Island. Forty acres in the Atlantic, a house nobody lives in, a hill with a door in it, and a gardener who has kept one man's secrets for twenty-two years."
		"redmont":
			return "Redmont. Microslop's town: the glass campus on the hill, the company store on Main Street, and the East-1 data center on the shore, drinking the reservoir one chiller at a time."
	return _loading_tip()


func _loading_tip() -> String:
	var tips := [
		"Crouch [CTRL] to sneak. Sneak attacks on unaware targets are critical hits.",
		"Press [V] to enter EXPLOIT mode: time stops, you queue shots on body parts, FOCUS pays for them.",
		"Speech checks never lie: if the number is white, you'll pass it.",
		"Low STABILITY makes the world glitch. Meds help. Sleep helps. Mr. Robot doesn't.",
		"Wearing the fsociety mask keeps crimes off your name. Mostly.",
		"Subway stations are fast travel. So is the MAP in your phone once you've been somewhere.",
		"Every building has a door, and almost every door opens. Some after hours. Some to a lockpick.",
		"Every parked car in the city can be stolen. Walk up to one and press [E]. Taxis and vans too.",
		"There's an airfield on the Brooklyn waterfront. Planes don't have locks. Planes have guards.",
		"Crouch behind someone and press E to pickpocket them. Get caught and they scream for the cops.",
		"Phone > DATA > JOBS: paid contracts every day. Deliveries, bounties, data heists, hits.",
		"Street ATMs can be hacked. Stolen credit cards cash out at any of them.",
		"Parked cars have gloveboxes. Dumpsters have secrets. Shipping containers have both.",
		"Stores close at night. Break in and the till is yours, if nobody's watching.",
		"Eight unique weapons are hidden around the city, from the cemetery to the end of the pier.",
		"Bobby pins break. Buy more at the bodega.",
		"Disguises work on the rank and file. Supervisors are harder to fool.",
	]
	return tips[randi() % tips.size()]


func _build_world() -> void:
	_loading_lbl.text = "> generating 1.7 km of city ..."
	await get_tree().process_frame
	var cb := CityBuilder.new()
	cb.build_all()
	city_buildings = cb.buildings
	_index_city(cb)
	airfield_slots = cb.airfield_planes
	_loading_lbl.text = "> uploading geometry ..."
	await get_tree().process_frame
	city_root = Node3D.new()
	city_root.name = "City"
	add_child(city_root)
	cb.commit(city_root, Settings.view_far())
	for ch in city_root.get_children():
		for mi in ch.get_children():
			if mi is MeshInstance3D and str(mi.name) in ["Facade", "Ground", "Glow"]:
				_far_meshes.append([mi, (mi as MeshInstance3D).visibility_range_end])
	city_extras = Node3D.new()
	city_extras.name = "CityExtras"
	add_child(city_extras)
	city_extras.add_child(cb.take_water_holder())
	if cb.far_skyline != null:
		var fr := Node3D.new()
		fr.name = "FarSkyline"
		city_extras.add_child(fr)
		cb.far_skyline.commit(fr, 3000.0, 0.0, false)
	var lf := Node3D.new()
	lf.name = "Landmarks"
	city_extras.add_child(lf)
	# No distance cutoff: this one mesh holds the map's own set pieces and the
	# other cities' skylines, so its bounds' centre can be kilometres away
	# (out on the island it's seven), and a cutoff would hide the lot.
	cb.landmark_far.commit(lf, 0.0, 0.0, false)
	# Ferris wheel (rotating rim).
	if WorldLayout.region == "nyc":
		ferris = _make_ferris(cb.ferris_center)
		city_extras.add_child(ferris)
	# Infinite ground.
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	ground.collision_layer = Phys.WORLD
	# An explicit slab, not a WorldBoundaryShape3D: Jolt approximates "infinite"
	# planes with a finite 2 km quad, and the expanded city is ~2.7 km across.
	var gs := CollisionShape3D.new()
	var slab := BoxShape3D.new()
	slab.size = Vector3(9000.0, 4.0, 9000.0)
	gs.shape = slab
	gs.position = Vector3(450.0, -2.0, -400.0)
	ground.add_child(gs)
	add_child(ground)
	var base := MeshBatch.new()
	# Big enough to run under every map in the shared world (see Regions).
	# Below the water (which sits at -0.4 and swells 0.12 either way), or it
	# hides every sea and lake on every map.
	base.flat(Vector3(0, -0.9, 0), 24000.0, 24000.0, Color(0.06, 0.06, 0.065))
	base.commit(city_extras, Mats.lit, 0.0, "BaseGround")
	_loading_lbl.text = "> mapping ..."
	await get_tree().process_frame
	map_image = MapRender.render(city_buildings)
	env_ctl = WorldEnv.new()
	add_child(env_ctl)
	night_lights = NightLights.new()
	night_lights.name = "NightLights"
	night_lights.setup(cb.lamp_points())
	add_child(night_lights)
	fx = FX.new()
	add_child(fx)
	npcs = NPCManager.new()
	npcs.game = self
	add_child(npcs)
	crowd = Crowd.new()
	crowd.game = self
	add_child(crowd)
	traffic = Traffic.new()
	traffic.game = self
	add_child(traffic)
	vehicles_root = Node3D.new()
	vehicles_root.name = "Vehicles"
	add_child(vehicles_root)
	interiors_root = Node3D.new()
	interiors_root.name = "Interiors"
	add_child(interiors_root)
	world_inter = Node3D.new()
	world_inter.name = "WorldInteractables"
	add_child(world_inter)
	races = Races.new()
	races.name = "Races"
	races.game = self
	add_child(races)
	taxi = Taxi.new()
	taxi.name = "Taxi"
	taxi.game = self
	add_child(taxi)
	air_races = AirRaces.new()
	air_races.name = "AirRaces"
	air_races.game = self
	add_child(air_races)
	emergency = Emergency.new()
	emergency.name = "Emergency"
	emergency.game = self
	add_child(emergency)
	stunts = StuntJumps.new()
	stunts.name = "StuntJumps"
	stunts.game = self
	add_child(stunts)
	jobs = Jobs.new()
	jobs.name = "Jobs"
	jobs.game = self
	add_child(jobs)
	encounters = Encounters.new()
	encounters.name = "Encounters"
	encounters.game = self
	add_child(encounters)
	var ids := InteriorData.INTERIORS.keys()
	ids.sort()
	var i := 0
	for id in ids:
		interior_index[str(id)] = i
		i += 1


## Register generic doors and street props in the LootIndex.
func _index_city(cb: CityBuilder) -> void:
	loot_index = LootIndex.new()
	for e in cb.gen_doors:
		var gd: Dictionary = e
		gen_doors[str(gd["id"])] = gd
		var p: Vector3 = gd["pos"]
		var o: Vector3 = gd["out"]
		var he := Vector3(0.8, 1.3, 0.12) if absf(o.z) > 0.5 else Vector3(0.12, 1.3, 0.8)
		loot_index.add({"id": str(gd["id"]), "kind": "gdoor", "p": p + o * 0.12 + Vector3(0, 1.25, 0), "he": he, "r": 0.0})
	for e in cb.lootables:
		var ld: Dictionary = e
		var k := str(ld["k"])
		var p2: Vector3 = ld["p"]
		var id := "L:%s:%d:%d" % [k, int(round(p2.x * 2.0)), int(round(p2.z * 2.0))]
		if loot_index.by_id.has(id):
			continue
		var le := {"id": id, "kind": k, "p": p2, "he": ld["he"], "r": float(ld.get("r", 0.0))}
		if ld.has("car"):
			le["car"] = ld["car"]
			le["ci"] = ld["ci"]
			le["yaw"] = ld["yaw"]
		loot_index.add(le)


## Deterministic per-prop roll (locks) so a car is always locked or not.
static func _hash01(id: String, salt: int) -> float:
	return float(absi(hash(id + str(salt))) % 10000) / 10000.0


## The player's ray asks this when it didn't hit a real interactable node.
func loot_pick(from: Vector3, dir: Vector3, max_t: float) -> Interactable:
	if GameState.cell != "world" or loot_index == null:
		return null
	var e := loot_index.pick(from, dir, max_t)
	if e.is_empty():
		return null
	return _virtual_for(e)


func _virtual_for(e: Dictionary) -> Interactable:
	if _virt == null:
		_virt = Interactable.new()
		_virt.name = "VirtualInteract"
		add_child(_virt)
	var id := str(e["id"])
	if _virt.ident == id and _virt.data.has("_k"):
		return _virt
	var k := str(e["kind"])
	_virt.ident = id
	_virt.cond = null
	if k == "gdoor":
		var gd: Dictionary = gen_doors[id]
		_virt.kind = "door"
		_virt.title = str(gd["name"])
		_virt.verb = "Enter"
		var data := {"to": "bld:" + id, "door": id, "gen": true, "_k": k}
		for f in ["lock", "hours", "closed_lock"]:
			if gd.has(f):
				data[f] = gd[f]
		_virt.data = data
		return _virt
	var L: Dictionary = WorldObjects.LOOT_KINDS.get(k, {})
	if e.has("car"):
		# Every parked car on the street can be stolen and driven.
		_virt.kind = "parked_car"
		_virt.title = {"sedan": "Sedan", "hatch": "Hatchback", "suv": "SUV", "van": "Van", "taxi": "Taxi"}.get(str(e["car"]), "Car")
		var dc := _parked_lock(id)
		_virt.verb = ("Steal  [LOCKPICK %d]" % dc) if dc > 0 else "Steal  [keys inside]"
		_virt.data = {"_k": k}
		return _virt
	if k == "atm":
		_virt.kind = "atm"
		_virt.title = "ATM"
		_virt.verb = "Use"
		_virt.data = {"_k": k}
		return _virt
	_virt.kind = "container"
	_virt.title = str(L.get("title", "Container"))
	_virt.verb = str(L.get("verb", "Search"))
	var d2 := {"loot": str(L.get("loot", "trash")), "restock": int(L.get("restock", 0)), "_k": k}
	if L.has("owner"):
		d2["owner"] = L["owner"]
	if L.has("lock"):
		var lk: Array = L["lock"]
		if _hash01(id, 1) < float(lk[0]):
			d2["lock"] = int(lerpf(float(lk[1]), float(lk[2]), _hash01(id, 2)) / 5.0) * 5
	_virt.data = d2
	return _virt


## Door lookups that also understand generated doors.
func door_world_any(did: String) -> Dictionary:
	if gen_doors.has(did):
		var gd: Dictionary = gen_doors[did]
		var out: Vector3 = gd["out"]
		return {"pos": gd["pos"], "out": out, "yaw": atan2(-out.x, -out.z) + PI}
	return WorldLayout.door_world(did)


func door_exit_any(did: String) -> Dictionary:
	if gen_doors.has(did):
		var gd: Dictionary = gen_doors[did]
		var out: Vector3 = gd["out"]
		return {"pos": (gd["pos"] as Vector3) + out * 2.2, "yaw": atan2(-out.x, -out.z)}
	return WorldLayout.door_exit(did)


func _proc_def(gid: String) -> Dictionary:
	if not _proc_defs.has(gid):
		if not gen_doors.has(gid):
			return {}
		_proc_defs[gid] = ProcInterior.generate(gen_doors[gid])
	var d: Dictionary = _proc_defs[gid]
	# Offices are guarded after hours: security treats you as a trespasser.
	var gd: Dictionary = gen_doors[gid]
	d["restricted"] = "locals" if str(gd.get("kind", "")) == "office" and _hours_closed(gd) else ""
	var extra: Array = jobs.extra_containers(gid) if jobs != null else []
	if extra.is_empty():
		return d
	var d2 := d.duplicate()
	d2["containers"] = (d["containers"] as Array) + extra
	return d2


func _hours_closed(gd: Dictionary) -> bool:
	if not gd.has("hours"):
		return false
	var h: Array = gd["hours"]
	var a := int(h[0])
	var b := int(h[1])
	var hr := int(GameState.hour())
	return not ((hr >= a and hr < b) if a < b else (hr >= a or hr < b))


## Occupants of the current cell that aren't in NPCData (generated interiors,
## street encounters, job targets). NPCManager merges these each refresh.
func dynamic_spawns(cell: String) -> Array:
	var out: Array = []
	if cell.begins_with("bld:"):
		var d := interior_def(cell)
		for n in d.get("npcs", []):
			out.append({"id": str(n["id"]), "template": str(n["t"]), "cell": cell, "local": true, "pos": n["pos"], "yaw": float(n.get("yaw", 0.0)), "when": str(n.get("when", "")), "name": str(n.get("name", "")), "wander": float(n.get("wander", 0.0))})
	if cell == "world":
		out.append_array(encounters.spawns())
		out.append_array(jobs.spawns())
	return out


func _make_ferris(c: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "WonderWheel"
	root.position = c
	var lit := MeshBatch.new()
	var glow := MeshBatch.new()
	var R := 22.0
	for k in 16:
		var a := TAU * float(k) / 16.0
		var p := Vector3(cos(a) * R, sin(a) * R, 0)
		lit.tube(Vector3.ZERO, p, 0.18, Color(0.9, 0.9, 0.92), 4)
		var a2 := TAU * float(k + 1) / 16.0
		lit.tube(p, Vector3(cos(a2) * R, sin(a2) * R, 0), 0.25, Color(0.85, 0.2, 0.25), 4)
		glow.sphere(p, 0.35, [Color(1, 0.3, 0.4), Color(1, 0.85, 0.3), Color(0.3, 0.8, 1)][k % 3], 5, 3)
		lit.box(p + Vector3(0, -1.4, 0), Vector3(1.6, 1.6, 1.4), Color(0.2, 0.45, 0.7))
	lit.cyl(Vector3.ZERO, 1.0, 1.0, 1.0, Color(0.6, 0.6, 0.6), 8)
	lit.commit(root, Mats.lit, 900.0, "Rim")
	glow.commit(root, Mats.glow, 1200.0, "Lights")
	return root


func _make_player() -> void:
	player = Player.new()
	player.game = self
	add_child(player)
	player.teleport(WorldLayout.START_POS)
	player.set_look(WorldLayout.START_YAW)


func _make_ui() -> void:
	hud = HUD.new()
	hud.game = self
	add_child(hud)
	robot_popup = RobotPopup.new()
	robot_popup.game = self
	add_child(robot_popup)
	dialog = DialogueUI.new()
	dialog.game = self
	dialog.auto_advance = test_mode
	add_child(dialog)
	phone = Phone.new()
	phone.game = self
	add_child(phone)
	loot_ui = LootUI.new()
	loot_ui.game = self
	add_child(loot_ui)
	barter_ui = BarterUI.new()
	barter_ui.game = self
	add_child(barter_ui)
	levelup_ui = LevelUpUI.new()
	levelup_ui.game = self
	add_child(levelup_ui)
	terminal_ui = TerminalUI.new()
	terminal_ui.game = self
	add_child(terminal_ui)
	minigames = MinigameHost.new()
	minigames.game = self
	add_child(minigames)
	pause_menu = PauseMenu.new()
	pause_menu.game = self
	add_child(pause_menu)
	intake_ui = IntakeUI.new()
	intake_ui.game = self
	add_child(intake_ui)
	ending_ui = EndingUI.new()
	ending_ui.game = self
	add_child(ending_ui)
	death_ui = DeathUI.new()
	death_ui.game = self
	add_child(death_ui)
	wait_ui = WaitUI.new()
	wait_ui.game = self
	add_child(wait_ui)
	travel_ui = TravelUI.new()
	travel_ui.game = self
	add_child(travel_ui)
	exploit_ui = ExploitUI.new()
	exploit_ui.game = self
	add_child(exploit_ui)


func _make_world_interactables() -> void:
	var doors := WorldLayout.all_doors()
	for did in doors.keys():
		var d: Dictionary = doors[did]
		var dw := WorldLayout.door_world(str(did))
		var p: Vector3 = dw["pos"]
		var out: Vector3 = dw["out"]
		var data := {"to": str(d["interior"]), "door": str(did)}
		if d.has("lock"):
			data["lock"] = int(d["lock"])
		if d.has("key"):
			data["key"] = str(d["key"])
		if d.has("when"):
			data["when"] = d["when"]
		if d.has("unlock_when"):
			data["unlock_when"] = d["unlock_when"]
		var it := Interactable.new().setup("door", str(did), str(d["name"]), "Enter", p + out * 0.3 + Vector3(0, 1.2, 0), Vector3(1.6, 2.4, 0.8) if absf(out.z) > 0.5 else Vector3(0.8, 2.4, 1.6), data)
		world_inter.add_child(it)
	var cmesh := MeshBatch.new()
	var cbody := StaticBody3D.new()
	cbody.collision_layer = Phys.WORLD
	world_inter.add_child(cbody)
	for c in WorldObjects.CONTAINERS:
		var cd: Dictionary = c
		if str(cd.get("region", "nyc")) != WorldLayout.region:
			continue
		var pa: Array = cd["pos"]
		var sz: Array = cd.get("size", [1.4, 1.2, 1.2])
		var it2 := Interactable.new().setup("container", str(cd["id"]), str(cd.get("title", "Container")), "Search", Vector3(float(pa[0]), float(cd.get("y", 0.7)), float(pa[1])), Vector3(float(sz[0]) + 0.1, float(sz[1]) + 0.1, float(sz[2]) + 0.1), cd)
		world_inter.add_child(it2)
		# Give these hand-placed containers a body you can actually see.
		var proto := {"dumpster": "dumpster", "crate": "crate", "trash": "trash"}.get(str(cd.get("loot", "")), "crate") as String
		cmesh.merge(Props.proto(proto)["lit"], Transform3D(Basis.IDENTITY, Vector3(float(pa[0]), 0.0, float(pa[1]))))
		var cs := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(float(sz[0]), float(sz[1]), float(sz[2]))
		cs.shape = bx
		cs.position = Vector3(float(pa[0]), float(sz[1]) * 0.5, float(pa[1]))
		cbody.add_child(cs)
	cmesh.commit(world_inter, Mats.lit, 200.0, "WorldContainers")
	for pk in WorldObjects.PICKUPS:
		if str((pk as Dictionary).get("region", "nyc")) != WorldLayout.region:
			continue
		_spawn_pickup(world_inter, pk, Vector3.ZERO)
	_spawn_hidden_masks()
	var smesh := MeshBatch.new()
	for sp in WorldObjects.SPOTS:
		var sd: Dictionary = sp
		if str(sd.get("region", "nyc")) != WorldLayout.region:
			continue
		var pa3: Array = sd["pos"]
		var sz3: Array = sd.get("size", [1.2, 1.8, 1.2])
		var it3 := Interactable.new().setup(str(sd.get("kind", "convo")), str(sd["id"]), str(sd.get("title", "")), str(sd.get("verb", "Examine")), Vector3(float(pa3[0]), float(pa3[1]), float(pa3[2])), Vector3(float(sz3[0]), float(sz3[1]), float(sz3[2])), sd)
		world_inter.add_child(it3)
		if str(sd.get("prop", "")) == "jbox":
			# A utility box on a pole: grey steel, a door, a warning sticker.
			var bx3 := Vector3(float(pa3[0]), 0.0, float(pa3[2]))
			smesh.box(bx3 + Vector3(0, 1.6, 0.25), Vector3(0.14, 3.2, 0.14), Color(0.36, 0.37, 0.38))
			smesh.box(bx3 + Vector3(0, 1.25, 0), Vector3(0.8, 1.0, 0.4), Color(0.52, 0.54, 0.55))
			smesh.box(bx3 + Vector3(0, 1.25, -0.21), Vector3(0.66, 0.86, 0.03), Color(0.46, 0.48, 0.5))
			smesh.box(bx3 + Vector3(0.12, 1.5, -0.235), Vector3(0.22, 0.14, 0.01), Color(0.9, 0.75, 0.1))
	smesh.commit(world_inter, Mats.lit, 160.0, "WorldSpotProps")
	air_races.spawn_board(world_inter)
	stunts.build(world_inter)
	emergency.call_deferred("spawn_parked")


func _spawn_pickup(parent: Node3D, pk: Dictionary, origin: Vector3) -> void:
	var id := str(pk["id"])
	if GameState.picked.has(id):
		return
	var pa: Array = pk["pos"]
	var pos := origin + Vector3(float(pa[0]), float(pa[1]), float(pa[2]))
	var it := Interactable.new().setup("pickup", id, DB.item_name(str(pk["item"])), "Take", pos, Vector3(0.6, 0.5, 0.6), pk)
	var mb := MeshBatch.new()
	var iid_pk := str(pk["item"])
	var idef := DB.item(iid_pk)
	var itype := "cash" if iid_pk == "cash" else str(idef.get("type", "misc"))
	var unique := bool(idef.get("unique", false))
	var col := {"weapon": Color(0.15, 0.15, 0.16), "ammo": Color(0.6, 0.5, 0.2), "aid": Color(0.8, 0.2, 0.2), "note": Color(0.9, 0.9, 0.85), "apparel": Color(0.2, 0.2, 0.25), "key": Color(0.8, 0.7, 0.2), "cash": Color(0.3, 0.8, 0.4)}.get(itype, Color(0.3, 0.5, 0.6)) as Color
	var E := Vector2(0, 0.35)
	var y0 := -0.24 # items rest a little below the pickup's origin
	match itype:
		"weapon":
			var long := idef.has("mag") and float(idef.get("range", 0.0)) > 40.0 and str(idef.get("model", "")) in ["rifle", "sniper", "ar", "carbine", "shotgun", "smg", "smg_sil"]
			var L := 0.9 if long else (0.32 if idef.has("mag") else 0.7)
			var gcol := Color(0.62, 0.5, 0.22) if unique else col
			mb.box(Vector3(0, y0 + 0.05, 0), Vector3(L, 0.08, 0.1), gcol, 0.3, E)
			if idef.has("mag"):
				# Grip, magazine, and on long guns a stock and a barrel shroud.
				mb.box(Vector3(-L * 0.3, y0 + 0.05, 0.1), Vector3(0.08, 0.07, 0.14), col.lightened(0.1), 0.3, E)
				mb.box(Vector3(-L * 0.05, y0 + 0.05, 0.09), Vector3(0.06, 0.06, 0.16), col.darkened(0.2), 0.3, E)
				if long:
					mb.box(Vector3(-L * 0.55, y0 + 0.06, 0.0), Vector3(0.24, 0.1, 0.12), Color(0.32, 0.2, 0.12) if str(idef.get("model", "")) in ["rifle", "sniper"] else col.lightened(0.05), 0.3, E)
					mb.box(Vector3(L * 0.55, y0 + 0.05, 0.0), Vector3(0.22, 0.04, 0.04), col.darkened(0.3), 0.3, E)
		"ammo":
			for k in 3:
				mb.box(Vector3(float(k) * 0.14 - 0.14, y0 + 0.06, 0), Vector3(0.12, 0.12, 0.09), col, 0.2, E)
		"cash":
			mb.box(Vector3(0, y0 + 0.03, 0), Vector3(0.18, 0.06, 0.09), col, 0.4, E)
			mb.box(Vector3(0.05, y0 + 0.08, 0.02), Vector3(0.18, 0.04, 0.09), col.darkened(0.15), 0.9, E)
		"note":
			mb.box(Vector3(0, y0 + 0.01, 0), Vector3(0.25, 0.01, 0.32), col, 0.3, E)
		"collectible":
			# An fsociety mask on a stake: white face, black hat, the grin.
			mb.box(Vector3(0, y0 + 0.5, 0), Vector3(0.04, 1.0, 0.04), Color(0.3, 0.25, 0.2), 0.0, E)
			mb.box(Vector3(0, y0 + 1.1, 0), Vector3(0.3, 0.36, 0.06), Color(0.92, 0.9, 0.86), 0.0, E)
			mb.box(Vector3(0, y0 + 1.36, 0), Vector3(0.36, 0.06, 0.08), Color(0.08, 0.08, 0.08), 0.0, E)
			mb.box(Vector3(0, y0 + 1.46, 0), Vector3(0.22, 0.16, 0.08), Color(0.08, 0.08, 0.08), 0.0, E)
			for ex in [-0.07, 0.07]:
				mb.box(Vector3(ex, y0 + 1.16, 0.035), Vector3(0.05, 0.03, 0.01), Color(0.05, 0.05, 0.05), 0.0, E)
			mb.box(Vector3(0, y0 + 1.0, 0.035), Vector3(0.16, 0.025, 0.01), Color(0.1, 0.1, 0.1), 0.0, E)
		_:
			mb.box(Vector3(0, y0 + 0.07, 0), Vector3(0.28, 0.14, 0.2), col, 0.3, E)
	# A soft glint above it so loot reads from a few meters away.
	var gb := MeshBatch.new()
	var gc := Color(1.0, 0.8, 0.3) if unique else Color(0.4, 1.0, 0.6)
	gb.box(Vector3(0, y0 + 0.45, 0), Vector3(0.03, 0.22, 0.03), gc)
	gb.box(Vector3(0, y0 + 0.45, 0), Vector3(0.14, 0.03, 0.03), gc)
	var far := 45.0 if not unique else 90.0
	if itype == "collectible":
		# Hidden masks glow red and green so a sharp eye catches them from a car.
		gb.box(Vector3(0, y0 + 2.4, 0), Vector3(0.02, 2.0, 0.02), Color(0.9, 0.15, 0.15))
		for k in 6:
			var am := float(k) / 6.0 * TAU
			gb.box(Vector3(cos(am) * 0.4, y0 + 0.01, sin(am) * 0.4), Vector3(0.2, 0.01, 0.03), Color(0.3, 1.0, 0.45), -am + PI * 0.5)
		far = 90.0
	if itype == "weapon":
		# Weapons get a faint light column and a ground ring so they can be
		# spotted from down the block.
		var wc := Color(1.0, 0.75, 0.25) if unique else Color(1.0, 0.45, 0.25)
		gb.box(Vector3(0, y0 + 1.4, 0), Vector3(0.02, 2.6, 0.02), wc.darkened(0.3))
		for k in 8:
			var a := float(k) / 8.0 * TAU
			gb.box(Vector3(cos(a) * 0.45, y0 + 0.01, sin(a) * 0.45), Vector3(0.22, 0.01, 0.03), wc, -a + PI * 0.5)
		far = 120.0
	mb.commit(it, Mats.lit, 70.0, "PickupMesh")
	gb.commit(it, Mats.glow, far, "PickupGlow")
	parent.add_child(it)


# ----------------------------------------------------------------- start
func _start_new_game() -> void:
	GameState.new_game()
	var intro: IntroCinematic = null
	if not test_mode and not bool(Settings.get_v("skip_intro")):
		intro = await _play_intro()
	# The game opens in Krista's office: the intake session is character creation.
	await enter_cell("krista_office", Vector3(4.0, 0, 4.5), PI, false)
	if intro != null:
		GameState.game_minutes = GameState.START_MINUTES
		player.cam.make_current()
		hud.set_visible_all(true)
		cinematic = false
		player.frozen = ui_depth > 0
		await intro.reveal()
	_fade_in_quick()
	await get_tree().create_timer(0.4).timeout
	hud.location("KRISTA GORDON, LCSW  —  6:40 PM")
	if DialogueManager.has_convo("intro_session"):
		await dialog.run("intro_session", npcs.get_npc("krista"))
	if test_mode:
		GameState.set_tags(["hacking", "sneak", "speech"])
	else:
		await intake_ui.open()
	if DialogueManager.has_convo("intro_after"):
		await dialog.run("intro_after", npcs.get_npc("krista"))
	GameState.set_quest_stage("mq_hello", 10)
	SaveManager.autosave("Start", true)


## New Vegas-style cold open over the live city. Returns the intro node with
## the screen still black so the caller can reveal the first scene.
func _play_intro() -> IntroCinematic:
	await enter_cell("world", Vector3(-96, 0.1, 420), PI, false, true)
	cinematic = true
	player.frozen = true
	hud.set_visible_all(false)
	force_high = true
	_update_high_mode()
	var intro := IntroCinematic.new()
	intro.name = "Intro"
	add_child(intro)
	await intro.run(self)
	force_high = false
	_update_high_mode()
	return intro


func _fade_in_quick() -> void:
	pass


func _restore_from_state() -> void:
	var cell := GameState.cell
	var pos := GameState.player_pos
	var yaw := GameState.player_yaw
	var gen_ok := cell.begins_with("bld:") and gen_doors.has(cell.substr(4))
	if cell != "world" and not InteriorData.INTERIORS.has(cell) and not cell.begins_with("subway:") and not gen_ok:
		cell = "world"
		pos = WorldLayout.START_POS
	if cell.begins_with("subway:"):
		current_subway = cell.substr(7)
	if GameState.pos_local and cell != "world":
		pos = cell_to_global(cell, pos)
	elif cell != "world" and not GameState.pos_local:
		# An older save stored a world-space position that may no longer be
		# inside this interior: use its entrance instead.
		var sp := InteriorBuilder.exit_spawn(interior_def(cell), 0)
		pos = cell_to_global(cell, sp["pos"])
		yaw = float(sp.get("yaw", yaw))
	await enter_cell(cell, pos, yaw, false, true)
	hud.notify("Loaded.", "")


# -------------------------------------------------------------------- cells
func interior_def(cell: String) -> Dictionary:
	if cell.begins_with("subway:"):
		return InteriorData.INTERIORS.get("subway", {})
	if cell.begins_with("bld:"):
		return _proc_def(cell.substr(4))
	return InteriorData.INTERIORS.get(cell, {})


func _phys_cell(cell: String) -> String:
	return "subway" if cell.begins_with("subway:") else cell


func cell_origin(cell: String) -> Vector3:
	if cell == "world":
		return Vector3.ZERO
	if cell.begins_with("bld:"):
		return InteriorBuilder.origin_for(PROC_SLOT)
	var pc := _phys_cell(cell)
	return InteriorBuilder.origin_for(int(interior_index.get(pc, 0)))


func cell_to_global(cell: String, local: Vector3) -> Vector3:
	return cell_origin(cell) + local


func cell_restricted(cell: String, faction: String) -> bool:
	var d := interior_def(cell)
	return str(d.get("restricted", "")) != "" and str(d.get("restricted", "")) == faction and not DialogueManager.check(str(d.get("allowed_when", "false")))


func _ensure_interior(cell: String) -> Node3D:
	var pc := _phys_cell(cell)
	if built_interiors.has(pc):
		return built_interiors[pc]
	# Generated interiors share one slot: drop the previous one first.
	if pc.begins_with("bld:"):
		for k in built_interiors.keys():
			if str(k).begins_with("bld:"):
				(built_interiors[k] as Node).queue_free()
				built_interiors.erase(k)
	var d := interior_def(cell)
	var origin := cell_origin(cell)
	var node := InteriorBuilder.build(pc, d, origin)
	interiors_root.add_child(node)
	# Exits.
	var ei := 0
	for e in d.get("exits", []):
		var ed: Dictionary = e
		var p: Array = ed["pos"]
		var out := WorldLayout.face_normal(str(ed.get("face", "s")))
		var data := {"to": str(ed.get("to", "world")), "exit": ei}
		if ed.has("lock"):
			data["lock"] = int(ed["lock"])
		if ed.has("key"):
			data["key"] = ed["key"]
		if ed.has("when"):
			data["when"] = ed["when"]
		var lab := str(ed.get("label", "Exit"))
		var it := Interactable.new().setup("exit", "%s:exit%d" % [pc, ei], lab, "Go", Vector3(float(p[0]), 1.2, float(p[1])) - out * 0.35, Vector3(1.4, 2.4, 0.7) if absf(out.z) > 0.5 else Vector3(0.7, 2.4, 1.4), data)
		node.add_child(it)
		ei += 1
	for c in d.get("containers", []):
		var cd: Dictionary = c
		var pa: Array = cd["pos"]
		var sz: Array = cd.get("size", [1.0, 1.0, 1.0])
		var it2 := Interactable.new().setup("container", str(cd["id"]), str(cd.get("title", "Container")), str(cd.get("verb", "Search")), Vector3(float(pa[0]), float(cd.get("y", 0.6)), float(pa[1])), Vector3(float(sz[0]), float(sz[1]), float(sz[2])), cd)
		node.add_child(it2)
	for pk in d.get("pickups", []):
		_spawn_pickup(node, pk, Vector3.ZERO)
	for s in d.get("spots", []):
		var sd: Dictionary = s
		var pa3: Array = sd["pos"]
		var sz3: Array = sd.get("size", [1.2, 1.8, 1.2])
		var it3 := Interactable.new().setup(str(sd.get("kind", "convo")), str(sd["id"]), str(sd.get("title", "")), str(sd.get("verb", "Examine")), Vector3(float(pa3[0]), float(pa3[1]), float(pa3[2])), Vector3(float(sz3[0]), float(sz3[1]), float(sz3[2])), sd)
		node.add_child(it3)
	built_interiors[pc] = node
	return node


## Move the player to a cell. spawn is local to the cell (world = global).
func enter_cell(cell: String, spawn: Vector3, yaw: float, fade: bool = true, spawn_is_global: bool = false) -> void:
	if busy_transition:
		return
	if player != null and player.driving != null:
		exit_vehicle(true)
	busy_transition = true
	push_ui()
	if fade:
		AudioManager.play_door()
		await SceneRouter.fade(true, 0.25)
	var was_world := GameState.cell == "world"
	GameState.cell = cell
	if cell == "world":
		city_root.visible = true
		city_extras.visible = true
		world_inter.visible = true
		crowd.set_active(true)
		traffic.set_active(true)
		env_ctl.set_interior(false)
		AudioManager.set_ambient("street")
		for k in built_interiors.keys():
			(built_interiors[k] as Node3D).visible = false
	else:
		var node := _ensure_interior(cell)
		for k in built_interiors.keys():
			(built_interiors[k] as Node3D).visible = built_interiors[k] == node
		city_root.visible = false
		city_extras.visible = false
		world_inter.visible = false
		crowd.set_active(false)
		traffic.set_active(false)
		var d := interior_def(cell)
		env_ctl.set_interior(true, d.get("ambient", Color(0.3, 0.28, 0.25)))
		AudioManager.set_ambient(str(d.get("amb", "interior")))
	var gpos := spawn if spawn_is_global else cell_to_global(cell, spawn)
	player.teleport(gpos + Vector3(0, 0.05, 0))
	player.velocity = Vector3.ZERO
	player.set_look(yaw, 0.0)
	npcs.refresh(true)
	# Companions arrive with you.
	for cid in GameState.companions:
		var n := npcs.get_npc(str(cid))
		if n != null:
			n.cell = cell
			n.global_position = gpos + Vector3(1.2, 0.1, 1.2).rotated(Vector3.UP, yaw)
			n.velocity = Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	if fade:
		await SceneRouter.fade(false, 0.35)
	busy_transition = false
	pop_ui()
	jobs.on_enter(cell)
	if cell != "world":
		var d2 := interior_def(cell)
		var nm := str(d2.get("name", ""))
		if cell.begins_with("subway:"):
			nm = str(WorldLayout.SUBWAYS.get(current_subway, {}).get("name", "Subway"))
		hud.location(nm.to_upper())
		if not cell.begins_with("subway:") and not cell.begins_with("bld:"):
			GameState.discover(cell)
	else:
		_last_district = ""
	if not test_mode:
		SaveManager.autosave(_location_name())


func _location_name() -> String:
	if GameState.cell != "world":
		var d := interior_def(GameState.cell)
		return str(d.get("name", GameState.cell))
	var dname := WorldLayout.district_at(player.global_position.x, player.global_position.z)
	return str(WorldLayout.DISTRICT_NAMES.get(dname, dname))


func sync_state_for_save() -> void:
	if player == null:
		return
	if GameState.cell.begins_with("subway:"):
		GameState.cell = "subway:" + current_subway
	# Interiors are saved relative to their own origin, so adding an interior in
	# an update (which shifts the origin slots) can't drop you into the void.
	GameState.player_pos = player.global_position - cell_origin(GameState.cell)
	GameState.pos_local = true
	GameState.player_yaw = player.yaw


# ---------------------------------------------------------------- ui stack
func push_ui() -> void:
	ui_depth += 1
	player.frozen = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func pop_ui() -> void:
	ui_depth = maxi(0, ui_depth - 1)
	player.frozen = ui_depth > 0 or cinematic
	if ui_depth == 0:
		get_tree().paused = false


func ui_open() -> bool:
	return ui_depth > 0


# -------------------------------------------------------------------- input
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if _dead or busy_transition or exploit_ui.executing:
		return
	var k := (event as InputEventKey).physical_keycode
	if k == KEY_ESCAPE:
		if not ui_open() and not get_tree().paused:
			pause_menu.open()
			get_viewport().set_input_as_handled()
		return
	if ui_open() or get_tree().paused:
		return
	match k:
		KEY_E:
			if player.driving != null:
				exit_vehicle()
			elif player.interact_target != null and is_instance_valid(player.interact_target):
				interact(player.interact_target)
		KEY_TAB, KEY_J, KEY_I:
			if GameState.pending_levels > 0 and k == KEY_TAB:
				levelup_ui.open()
			else:
				phone.open("stats" if k == KEY_TAB else ("items" if k == KEY_I else "data"))
		KEY_M:
			phone.open("map")
		KEY_V, KEY_Q:
			if player.driving == null:
				exploit_ui.try_open()
		KEY_H:
			var best := GameState.best_healing_item()
			if best != "" and GameState.hp < GameState.max_hp():
				GameState.use_aid(best)
				AudioManager.play_heal()
			else:
				hud.notify("Nothing to heal with." if best == "" else "Already at full health.", "")
		KEY_T:
			if _in_combat():
				hud.notify("You can't wait with enemies nearby.", "warn")
			else:
				wait_ui.open()
		KEY_F5:
			var why := save_blocked()
			if why != "":
				hud.notify(why, "warn")
			else:
				sync_state_for_save()
				if SaveManager.save("quick", _location_name()):
					hud.notify("Quicksaved.", "")
		KEY_F9:
			if SaveManager.has_slot("quick"):
				SaveManager.load_slot("quick")
				SceneRouter.goto_game()
	get_viewport().set_input_as_handled()


## Why you can't save right now ("" = you can).
func save_blocked() -> String:
	if _in_combat():
		return "You can't save with enemies nearby."
	if player != null and player.driving is Aircraft and ((player.driving as Aircraft).airborne or absf(player.driving.speed) > 2.0):
		return "You can't save while flying. Land first."
	return ""


func _in_combat() -> bool:
	for n in get_tree().get_nodes_in_group("npc"):
		var o := n as NPC
		if o != null and not o.dead and o.mode == "combat" and o.is_hostile_to_player() and o.global_position.distance_to(player.global_position) < 60.0:
			return true
	return false


# -------------------------------------------------------------- interaction
func interact(obj: Object) -> void:
	if obj is Vehicle:
		await _use_vehicle(obj as Vehicle)
		return
	if obj is Traffic.Car:
		_carjack(obj as Traffic.Car)
		return
	if obj is NPC:
		var n := obj as NPC
		if n.dead:
			await _loot_npc(n)
			return
		if n.generic and player.crouching and n.can_pickpocket():
			_pickpocket(n, n.global_position, n.display_name)
			return
		var convo := str(n.def.get("convo", ""))
		if convo != "" and DialogueManager.has_convo(convo):
			await dialog.run(convo, n)
		else:
			var b: Array = n.def.get("barks", [])
			bark(n, str(b[randi() % b.size()]) if b.size() > 0 else "...")
		return
	if obj is Pedestrian:
		var pd := obj as Pedestrian
		if not pd.dead and player.crouching and not pd.picked:
			_pickpocket(pd, pd.global_position, pd.display_name)
			return
		if pd.dead:
			var items := pd.loot
			var cash := {"items": items, "cash": pd.loot_cash}
			await loot_ui.open_container(pd.display_name, cash, false)
			pd.loot = cash["items"]
			pd.loot_cash = int(cash["cash"])
		else:
			bark(pd, crowd.random_bark())
		return
	if not (obj is Interactable):
		return
	var it := obj as Interactable
	match it.kind:
		"parked_car":
			_steal_parked(it.ident)
		"door":
			if not await _try_unlock(it):
				return
			var to := str(it.data["to"])
			var door_id := str(it.data["door"])
			if to.begins_with("subway:"):
				current_subway = to.substr(7)
				GameState.discover(current_subway, str(WorldLayout.SUBWAYS[current_subway]["name"]))
			var d := interior_def(to)
			var ei := _exit_index_for_door(d, door_id)
			var sp := InteriorBuilder.exit_spawn(d, ei)
			await enter_cell(to, sp["pos"], float(sp["yaw"]))
		"exit":
			if not await _try_unlock(it):
				return
			await _take_exit(str(it.data["to"]))
		"container":
			if not await _try_unlock(it):
				return
			await open_container(it.ident, it.title, it.data)
		"pickup":
			var item := str(it.data.get("item", ""))
			var n2 := int(it.data.get("count", 1))
			var owner := str(it.data.get("owner", ""))
			if owner != "" and _is_watched_by(owner):
				hud.notify("Someone's watching. That's stealing.", "warn")
				return
			if item == "cash":
				GameState.add_cash(n2)
				AudioManager.play_coin()
			else:
				GameState.give(item, n2)
			GameState.picked[it.ident] = true
			AudioManager.play_pickup()
			if it.data.has("fx"):
				await DialogueManager.run_effects(DialogueManager.parse_effects(str(it.data["fx"]), it.ident))
			it.queue_free()
		"bed":
			if _in_combat():
				hud.notify("You can't sleep with enemies nearby.", "warn")
			else:
				await wait_ui.open(true)
		"terminal":
			await terminal_ui.open(it.ident, it.data)
		"convo":
			var cv := str(it.data.get("convo", ""))
			if cv != "" and DialogueManager.has_convo(cv):
				await dialog.run(cv, null)
		"subway_map":
			await travel_ui.open_subway()
		"radio":
			phone.open("radio")
		"minigame":
			var won := await minigames.run(str(it.data.get("game", "invaders")), it.data)
			GameState.last_won = won
			if it.data.has("fx_win") and won:
				await DialogueManager.run_effects(DialogueManager.parse_effects(str(it.data["fx_win"]), it.ident))
		"shop":
			var clerk := str(it.data.get("clerk", ""))
			if clerk != "":
				var cn := npcs.get_npc(clerk)
				if cn == null or cn.dead:
					hud.notify("Nobody's minding the counter.", "warn")
					return
			await barter_ui.open(str(it.data.get("shop", "")), it.title, str(it.data.get("stock_key", "")))
		"atm":
			await _use_atm(it)
		"text":
			hud.center(str(it.data.get("text", "")), 4.0)
			if it.data.has("fx"):
				await DialogueManager.run_effects(DialogueManager.parse_effects(str(it.data["fx"]), it.ident))
		"effects":
			await DialogueManager.run_effects(DialogueManager.parse_effects(str(it.data.get("fx", "")), it.ident))


func _exit_index_for_door(d: Dictionary, door_id: String) -> int:
	var i := 0
	for e in d.get("exits", []):
		var to := str((e as Dictionary).get("to", ""))
		if to == "world:" + door_id or (door_id.begins_with("sub_") and to.begins_with("world:subway")):
			return i
		i += 1
	return 0


func _take_exit(to: String) -> void:
	if to.begins_with("world:"):
		var door := to.substr(6)
		if door == "subway":
			door = current_subway
		var ex := door_exit_any(door)
		await enter_cell("world", ex["pos"], float(ex["yaw"]))
	elif to == "roof:wtc":
		await enter_cell("world", WorldLayout.WTC_ROOF, PI, true, true)
		_update_high_mode()
		if GameState.discover("wtc_roof", "Top of the World"):
			GameState.add_xp(20)
		hud.center("TOP OF THE WORLD  —  107 FLOORS UP", 3.5)
	elif to.begins_with("interior:"):
		var parts := to.split(":")
		var cell := str(parts[1])
		var ei := int(parts[2]) if parts.size() > 2 else 0
		var sp := InteriorBuilder.exit_spawn(interior_def(cell), ei)
		await enter_cell(cell, sp["pos"], float(sp["yaw"]))


func _try_unlock(it: Interactable) -> bool:
	if not it.is_locked():
		return true
	var key := str(it.data.get("key", ""))
	if key != "" and GameState.has_item(key):
		GameState.unlocked[it.ident] = true
		hud.notify("Unlocked with %s" % DB.item_name(key), "")
		return true
	var dc := it.lock_dc()
	if dc > 100:
		hud.notify("Locked. You'll need a key%s." % ((" (" + DB.item_name(key) + ")") if key != "" else ""), "warn")
		AudioManager.play_fail()
		return false
	if GameState.skill("lockpick") < dc:
		hud.notify("Lock too complex. LOCKPICK %d required (you: %d)." % [dc, GameState.skill("lockpick")], "warn")
		AudioManager.play_fail()
		return false
	if GameState.count("bobby_pin") <= 0:
		hud.notify("You need a bobby pin.", "warn")
		return false
	var won := await minigames.run("lockpick", {"dc": dc})
	if won:
		GameState.unlocked[it.ident] = true
		GameState.stat_add("locks")
		GameState.add_xp(10 + dc / 5)
		if str(it.data.get("owner", "")) != "" and _is_watched_by(str(it.data["owner"])):
			crime_witnessed(player.global_position)
		return true
	return false


func _is_watched_by(owner_faction: String) -> bool:
	for n in get_tree().get_nodes_in_group("npc"):
		var o := n as NPC
		if o == null or o.dead or o.faction != owner_faction:
			continue
		if o.global_position.distance_to(player.global_position) < 12.0 and o._los(o.head_pos(), player.eye_pos()):
			return true
	return false


func open_container(ident: String, title: String, data: Dictionary) -> void:
	var rs := int(data.get("restock", 0))
	if not GameState.containers.has(ident):
		GameState.containers[ident] = _roll_container(data)
	elif rs > 0 and GameState.day() - int((GameState.containers[ident] as Dictionary).get("day", 0)) >= rs:
		GameState.containers[ident] = _roll_container(data)
	var c: Dictionary = GameState.containers[ident]
	var owner := str(data.get("owner", ""))
	var stealing := owner != "" and not DialogueManager.check(str(data.get("owner_ok", "false")))
	await loot_ui.open_container(title, c, stealing)
	if stealing and loot_ui.took_anything and _is_watched_by(owner):
		hud.notify("You were seen stealing.", "warn")
		GameState.add_infamy(owner if DB.FACTIONS.has(owner) else "locals", 3)
		crime_witnessed(player.global_position)
		_witnesses_react(owner)
	if data.has("fx_open") and not GameState.flags.has("opened:" + ident):
		GameState.flags["opened:" + ident] = true
		await DialogueManager.run_effects(DialogueManager.parse_effects(str(data["fx_open"]), ident))


func _roll_container(data: Dictionary) -> Dictionary:
	var items := {}
	var cash := 0
	if data.has("items"):
		for k in (data["items"] as Dictionary).keys():
			items[str(k)] = int(data["items"][k])
	if data.has("cash"):
		cash = int(data["cash"])
	var lt := str(data.get("loot", ""))
	if lt != "" and NPCData.LOOT.has(lt):
		var L: Dictionary = NPCData.LOOT[lt]
		var cr: Array = L.get("cash", [0, 0])
		cash += randi_range(int(cr[0]), int(cr[1]))
		for k in (L.get("items", {}) as Dictionary).keys():
			var spec: Array = L["items"][k]
			if randf() <= float(spec[2]):
				var n := randi_range(int(spec[0]), int(spec[1]))
				if n > 0:
					items[str(k)] = int(items.get(str(k), 0)) + n
	if GameState.has_perk("walking_wallet"):
		cash = int(float(cash) * 1.3)
	return {"items": items, "cash": cash, "day": GameState.day()}


## Sneak up (crouched) on a civilian and lift their wallet.
func _pickpocket(target: Node3D, pos: Vector3, nm: String) -> void:
	var sneak := float(GameState.skill("sneak"))
	var fwd := -target.global_transform.basis.z
	var to_p := player.global_position - pos
	to_p.y = 0.0
	var behind := to_p.length() < 0.01 or fwd.dot(to_p.normalized()) < 0.0
	var chance := 28.0 + sneak * 0.62 + (22.0 if behind else -12.0)
	if player.detection >= 2:
		chance -= 30.0
	if GameState.has_perk("ghost_protocol"):
		chance += 10.0
	chance = clampf(chance, 5.0, 95.0)
	target.set("picked", true)
	if randf() * 100.0 < chance:
		var cash := randi_range(3, 25) + int(sneak * 0.35)
		var got: Array = []
		if target is Pedestrian:
			var pd := target as Pedestrian
			cash += pd.loot_cash
			pd.loot_cash = 0
			for k in pd.loot.keys():
				GameState.give(str(k), int(pd.loot[k]), true)
				got.append(DB.item_name(str(k)))
			pd.loot.clear()
		elif randf() < 0.35:
			var it: String = ["cigarettes", "smartphone", "watch", "burner_phone", "bobby_pin", "usb_drive", "jewelry"][randi() % 7]
			GameState.give(it, 1, true)
			got.append(DB.item_name(it))
		if randf() < 0.3:
			GameState.give("credit_card", 1, true)
			got.append("a credit card")
		GameState.add_cash(cash, true)
		GameState.add_xp(6)
		GameState.stat_add("pickpockets")
		AudioManager.play_coin()
		hud.notify("Lifted $%d%s from %s." % [cash, (" + " + ", ".join(got)) if not got.is_empty() else "", nm], "cash")
	else:
		AudioManager.play_fail()
		hud.notify("%s caught your hand in their pocket." % nm, "warn")
		bark(target, "Hey! Thief! THIEF!")
		GameState.add_infamy("locals", 1)
		crime_witnessed(pos)
		if target is Pedestrian:
			(target as Pedestrian).flee_from(player.global_position)
		elif target is NPC:
			(target as NPC).alarm(player)


## Stolen from in front of the owner's people: the armed ones don't just watch.
func _witnesses_react(owner_faction: String) -> void:
	for n in get_tree().get_nodes_in_group("npc"):
		var o := n as NPC
		if o == null or o.dead or o.faction != owner_faction:
			continue
		if o.global_position.distance_to(player.global_position) > 16.0:
			continue
		bark(o, ["Hey! Put that back!", "Thief! Somebody call the cops!", "Are you kidding me?!"][randi() % 3])
		o.alarm(player)


## Street ATMs: cash out stolen cards, or crack the cash cassette.
func _use_atm(it: Interactable) -> void:
	var id := it.ident
	var key := "atm:" + id
	var hot := GameState.day() - int(GameState.flags.get(key, -99)) < 2
	var hk := GameState.skill("hacking")
	var dc := int((20.0 + _hash01(id, 3) * 40.0) / 5.0) * 5
	var pay := int(lerpf(70.0, 220.0, _hash01(id + str(GameState.day()), 4))) + hk
	var card_pay := randi_range(20, 55) + hk / 3
	var cop := _is_watched_by("nypd")
	var t := "=== _atm\n-- start\n"
	t += "> The ATM glows: INSERT CARD. Behind the plastic sits a cassette full of twenties.%s\n" % (" A cop is watching from down the block." if cop else "")
	if GameState.count("credit_card") > 0:
		t += "* [if item.credit_card>=1] Cash out a stolen card ($%d each). -> card\n" % card_pay
	if not hot:
		t += "* Jack in and skim the cassette (hacking, difficulty %d). -> hack\n" % dc
	else:
		t += "* The machine is still locked down from last time. Give it a couple of days. -> END\n"
	t += "* Walk away. -> END\n"
	t += "-- card\n! take credit_card 1 ; cash %d ; xp 4 ; add cards_cashed\n" % card_pay
	t += "> The machine thinks about it. Then it counts out $%d. Somebody's calling their bank in the morning.\n-> start\n" % card_pay
	t += "-- hack\n! set %s=%d ; minigame bruteforce %d\n? won -> paid\n" % [key, GameState.day(), dc]
	t += "> LOCKOUT. The screen flashes red and the little camera above it blinks awake.\n! wanted 15\n-> END\n"
	t += "-- paid\n! cash %d ; xp %d ; add atms_hacked\n" % [pay, 12 + dc / 4]
	t += "> The cassette clicks and exhales $%d in warm, anonymous twenties.\n-> END\n" % pay
	DialogueManager.convos.erase("_atm") # rebuilt every time: never stack two
	DialogueManager.parse_text(t, "runtime:atm")
	await dialog.run("_atm", null)
	if cop and GameState.flags.has(key) and int(GameState.flags[key]) == GameState.day() and GameState.last_won:
		crime_witnessed(player.global_position)


func _loot_npc(n: NPC) -> void:
	if n.generic:
		var c := {"items": n.loot, "cash": n.loot_cash}
		await loot_ui.open_container(n.display_name, c, false)
		n.loot = c["items"]
		n.loot_cash = int(c["cash"])
	else:
		var key := "npc:" + n.id
		if not GameState.containers.has(key):
			GameState.containers[key] = {"items": {}, "cash": 0}
		await loot_ui.open_container(n.display_name, GameState.containers[key], false)


# ------------------------------------------------------------ world effects
func dlg_world_effect(cmd: String, args: Array) -> void:
	var a0 := str(args[0]) if args.size() > 0 else ""
	var a1 := str(args[1]) if args.size() > 1 else ""
	var who := a0 if a0 != "" else DialogueManager.current_npc
	match cmd:
		"hostile":
			GameState.hostile[who] = true
			var n := npcs.get_npc(who)
			if n != null:
				n.alarm(player)
			if dialog.is_open():
				dialog.abort()
		"calm":
			GameState.hostile.erase(who)
			var n2 := npcs.get_npc(who)
			if n2 != null and n2.mode == "combat":
				n2.mode = "idle"
		"race":
			_pending.append(func() -> void: races.start(a0))
		"airrace":
			_pending.append(func() -> void: await air_races.start(a0))
		"barter":
			var shop := a0
			if shop == "":
				var n3 := npcs.get_npc(DialogueManager.current_npc)
				shop = str(n3.def.get("shop", "")) if n3 != null else ""
			var nm := str(NPCData.SHOPS.get(shop, {}).get("name", "Shop"))
			await barter_ui.open(shop, nm)
		"minigame":
			var won := await minigames.run(a0, {"dc": int(a1) if a1.is_valid_int() else 0, "arg": a1})
			GameState.last_won = won
		"recruit":
			if not GameState.companions.has(who):
				if GameState.companions.size() >= 2:
					hud.notify("You can only have two companions.", "warn")
				else:
					GameState.companions.append(who)
					hud.notify("%s joined you." % str(NPCData.NPCS.get(who, {}).get("name", who)), "")
					var cd: Dictionary = CompanionData.get_def(who)
					if cd.has("bonus_desc"):
						hud.notify(str(cd["bonus_desc"]), "")
					# Things that happened before they joined aren't news to them.
					for f in (cd.get("react", {}) as Dictionary).keys():
						if GameState.flags.has(str(f)):
							GameState.flags["react_%s_%s" % [who, f]] = true
					var n4 := npcs.get_npc(who)
					if n4 != null:
						n4.aggro = "companion"
						n4.mode = "follow"
						GameState.hostile.erase(who)
		"dismiss":
			if GameState.companions.has(who):
				_release_companion(who)
				hud.notify("%s went home." % str(NPCData.NPCS.get(who, {}).get("name", who)), "")
		"travel":
			_pending.append(func() -> void: await travel_to(a0))
		"ending":
			_pending.append(func() -> void: await ending_ui.play(a0))
		"glitch":
			hud.glitch(float(a0) if a0 != "" else 0.8, 0.8)
			AudioManager.play_glitch()
		"sfx":
			AudioManager.sfx(a0)
		"kill":
			var n5 := npcs.get_npc(a0)
			if n5 != null:
				n5.die(null)
			else:
				GameState.mark_dead(a0)
		"move":
			# move npc_id: re-evaluate spawns (conditions changed).
			# move npc_id x z: also put that NPC at cell-local (x, z) right now.
			if args.size() >= 3:
				var mn := npcs.get_npc(a0)
				if mn != null and not mn.dead:
					mn.global_position = cell_to_global(GameState.cell, Vector3(float(args[1]), 0.1, float(args[2])))
					mn.home_pos = mn.global_position
					mn.velocity = Vector3.ZERO
			_pending.append(func() -> void: npcs.refresh(false))
		"sleep":
			_pending.append(func() -> void: await wait_ui.open(true))
		"save":
			sync_state_for_save()
			SaveManager.autosave(_location_name(), true)
		"blackout":
			_pending.append(func() -> void: await blackout(a0))
		"spawn":
			_pending.append(func() -> void: npcs.refresh(false))
		"fade":
			await SceneRouter.fade(true, 0.4)
			await get_tree().create_timer(0.4).timeout
			await SceneRouter.fade(false, 0.5)
		"levelup":
			if GameState.pending_levels > 0:
				_pending.append(func() -> void: await levelup_ui.open())


func after_dialogue() -> void:
	npcs.refresh(false)
	_run_pending()


func _run_pending() -> void:
	while not _pending.is_empty():
		var f: Callable = _pending.pop_front()
		await f.call()


## Fast travel / scripted travel to a location id (door, subway, poi, npc, pos).
func travel_to(loc: String) -> void:
	var t := resolve_location(loc)
	if t.is_empty():
		push_warning("travel_to: unknown " + loc)
		return
	var cell := str(t["cell"])
	await enter_cell(cell, t["pos"], float(t.get("yaw", 0.0)), true, cell == "world")


func resolve_location(loc: String) -> Dictionary:
	if loc.begins_with("interior:"):
		var parts := loc.split(":")
		var d := interior_def(str(parts[1]))
		var sp := InteriorBuilder.exit_spawn(d, int(parts[2]) if parts.size() > 2 else 0)
		return {"cell": str(parts[1]), "pos": sp["pos"], "yaw": sp["yaw"]}
	if WorldLayout.all_doors().has(loc) or gen_doors.has(loc):
		var ex := door_exit_any(loc)
		return {"cell": "world", "pos": ex["pos"], "yaw": ex["yaw"]}
	if WorldLayout.POIS.has(loc):
		var p: Array = WorldLayout.POIS[loc]["pos"]
		return {"cell": "world", "pos": Vector3(float(p[0]), 0, float(p[1])), "yaw": 0.0}
	if loc.begins_with("pos:"):
		var xy := loc.substr(4).split(",")
		return {"cell": "world", "pos": Vector3(float(xy[0]), 0, float(xy[1])), "yaw": 0.0}
	if InteriorData.INTERIORS.has(loc):
		var d2 := interior_def(loc)
		var sp2 := InteriorBuilder.exit_spawn(d2, 0)
		return {"cell": loc, "pos": sp2["pos"], "yaw": sp2["yaw"]}
	return {}


# ------------------------------------------------------------------- hooks
func hud_msg(t: String) -> void:
	hud.notify(t, "")


func noise(pos: Vector3, radius: float, loud: bool) -> void:
	for n in get_tree().get_nodes_in_group("npc"):
		var o := n as NPC
		if o != null and o.global_position.distance_to(pos) < radius:
			o.noise_heard(pos, loud)
	if loud and GameState.cell == "world":
		crowd.scatter(pos, radius * 0.7)


func impact(p: Vector3, n: Vector3) -> void:
	fx.impact(p, n)


func blood(p: Vector3) -> void:
	fx.blood(p)


func tracer(a: Vector3, b: Vector3) -> void:
	fx.tracer(a, b)


func hit_marker(crit: bool) -> void:
	hud.hit_marker(crit)


func on_player_hurt(dmg: float, _from: Vector3) -> void:
	hud.hurt(dmg)


func bark(n: Node, text: String) -> void:
	var nm := str(n.get("display_name")) if n.get("display_name") != null else "?"
	hud.subtitle(nm, text, 3.5)


func report_detection(n: NPC, level: float, combat: bool) -> void:
	_detect_reports[n.get_instance_id()] = 2 if combat or n.mode == "combat" else (1 if level > 0.15 else 0)


func crime_witnessed(pos: Vector3) -> void:
	if GameState.cell != "world":
		return
	var cop_near := false
	for n in get_tree().get_nodes_in_group("npc"):
		var o := n as NPC
		if o != null and not o.dead and o.faction == "nypd" and o.global_position.distance_to(pos) < 45.0:
			cop_near = true
	if cop_near or randf() < 0.45:
		GameState.set_wanted(60.0 if not GameState.wearing_mask() else 25.0)
		GameState.add_infamy("nypd", 2)
		_cop_t = 8.0
		_pursuit_t = 4.0


func on_npc_died_signal(n: NPC) -> void:
	pass


func on_npc_died(n: NPC, by_player: bool) -> void:
	var od := str(n.def.get("on_death", ""))
	if od != "":
		DialogueManager.run_effects(DialogueManager.parse_effects(od, "on_death " + n.id))
	# Generated occupants, encounters and job targets stay dead.
	if n.id.begins_with("bld:") or n.id.begins_with("enc:") or n.id.begins_with("job:"):
		GameState.dead[n.id] = true
		if n.id.begins_with("bld:") and by_player:
			_check_cleared(n)
	# Street crews with a "clear_flag" stay gone once every one of them is down.
	var grp := str(n.def.get("group", ""))
	if by_player and grp != "" and NPCData.GROUPS.has(grp):
		var G: Dictionary = NPCData.GROUPS[grp]
		var cf := str(G.get("clear_flag", ""))
		if cf != "" and not GameState.flags.has(cf):
			var k := "gkills:" + grp
			GameState.flags[k] = int(GameState.flags.get(k, 0)) + 1
			if int(GameState.flags[k]) >= (G.get("positions", []) as Array).size():
				GameState.flags[cf] = true
				GameState.add_xp(40)
				GameState.add_fame("locals", 2)
				hud.center("%s  —  CLEARED" % str(G.get("clear_name", "The crew")).to_upper(), 3.5)
				AudioManager.play_success()
	jobs.on_npc_died(n)
	encounters.on_npc_died(n, by_player)
	if by_player and exploit_ui.executing and GameState.has_perk("adrenaline_loop"):
		GameState.focus = GameState.max_focus()
	if by_player and n.faction in ["nypd", "fbi"] and (n.id.begins_with("cop_resp_") or n.id.begins_with("fbi_resp_") or GameState.is_wanted()):
		# Killing police: two stars on top of whatever you had.
		GameState.set_wanted(120.0)
		GameState.add_heat(1)
	elif by_player and n.faction == "nypd":
		GameState.set_wanted(120.0)


## Every hostile in a generated building is down: hideout cleared.
func _check_cleared(n: NPC) -> void:
	var cell := n.cell
	if not cell.begins_with("bld:") or GameState.flags.has("cleared:" + cell):
		return
	var d := interior_def(cell)
	var total := 0
	var left := 0
	for o in d.get("npcs", []):
		var tmpl: Dictionary = NPCData.TEMPLATES.get(str((o as Dictionary)["t"]), {})
		if str(tmpl.get("aggro", "")) != "hostile":
			continue
		total += 1
		if not GameState.is_dead(str((o as Dictionary)["id"])):
			left += 1
	if total > 0 and left == 0:
		GameState.flags["cleared:" + cell] = true
		GameState.add_xp(30 + 15 * total)
		GameState.add_fame("locals", 1 + total / 2)
		GameState.stat_add("hideouts")
		hud.center("%s  —  CLEARED" % str(d.get("name", "")).to_upper(), 3.5)
		AudioManager.play_success()


func discover_location(loc: String) -> void:
	var nm := loc
	if WorldLayout.POIS.has(loc):
		nm = str(WorldLayout.POIS[loc]["name"])
	elif WorldLayout.all_doors().has(loc):
		nm = str(WorldLayout.all_doors()[loc]["name"])
	GameState.discover(loc, nm)


func aim_target() -> Variant:
	return _aim_target


# ------------------------------------------------------------------ markers
func compass_markers() -> Array:
	var out: Array = []
	if player == null:
		return out
	var pp := player.global_position
	var tq := GameState.tracked_quest
	if tq != "" and GameState.quest_state(tq) == "active" and bool(Settings.get_v("show_markers")):
		for o in DB.quest_objectives(tq, GameState.quest_stage(tq)):
			var m := str((o as Dictionary).get("marker", ""))
			if m == "":
				continue
			var wp: Variant = marker_pos(m)
			if wp == null:
				continue
			var dv: Vector3 = (wp as Vector3) - pp
			out.append({"dir": dv, "kind": "quest", "dist": Vector2(dv.x, dv.z).length()})
	if bool(Settings.get_v("show_markers")):
		for tp in taxi.marker_positions() + air_races.marker_positions() + emergency.marker_positions():
			var dvt: Vector3 = (tp as Vector3) - pp
			out.append({"dir": dvt, "kind": "job", "dist": Vector2(dvt.x, dvt.z).length()})
		for jp in jobs.marker_positions():
			var jv: Variant = marker_pos_world(jp)
			if jv != null:
				var dvj: Vector3 = (jv as Vector3) - pp
				out.append({"dir": dvj, "kind": "job", "dist": Vector2(dvj.x, dvj.z).length()})
	if GameState.cell == "world":
		for did in WorldLayout.DOORS.keys():
			var dw := WorldLayout.door_world(str(did))
			var dv2: Vector3 = (dw["pos"] as Vector3) - pp
			if dv2.length() < 90.0:
				out.append({"dir": dv2, "kind": "door"})
		for pid in WorldLayout.POIS.keys():
			var pa: Array = WorldLayout.POIS[pid]["pos"]
			var dv3 := Vector3(float(pa[0]), 0, float(pa[1])) - pp
			if dv3.length() < 200.0:
				out.append({"dir": dv3, "kind": "poi"})
	for n in get_tree().get_nodes_in_group("npc"):
		var o2 := n as NPC
		if o2 == null or o2.dead:
			continue
		var dv4 := o2.global_position - pp
		if dv4.length() > 70.0:
			continue
		if o2.mode == "combat" and o2.is_hostile_to_player():
			out.append({"dir": dv4, "kind": "hostile"})
		elif GameState.companions.has(o2.id):
			out.append({"dir": dv4, "kind": "friend"})
	return out


## A world-space target seen from wherever the player is (routes through the
## current interior's exit when inside).
func marker_pos_world(p: Vector3) -> Variant:
	if GameState.cell == "world":
		return p
	var d := interior_def(GameState.cell)
	var exits: Array = d.get("exits", [])
	if exits.is_empty():
		return null
	var ep: Array = (exits[0] as Dictionary)["pos"]
	return cell_to_global(GameState.cell, Vector3(float(ep[0]), 0, float(ep[1])))


## Drop a pickup into the world at runtime (encounters: a dropped wallet).
func spawn_dynamic_pickup(id: String, item: String, count: int, pos: Vector3) -> void:
	if GameState.picked.has(id):
		return
	_spawn_pickup(world_inter, {"id": id, "item": item, "count": count, "pos": [pos.x, pos.y, pos.z]}, Vector3.ZERO)


## World position of a quest marker, routed through doors when the target is
## in another cell. Returns null if unknown.
func marker_pos(m: String) -> Variant:
	var tgt := _marker_target(m)
	if tgt.is_empty():
		return null
	var tcell := str(tgt["cell"])
	var here := GameState.cell
	if tcell == here or (tcell.begins_with("subway") and here.begins_with("subway")):
		return tgt["pos"]
	# Different cell.
	if here != "world":
		# Head for the exit of this interior.
		var d := interior_def(here)
		var exits: Array = d.get("exits", [])
		if exits.is_empty():
			return null
		var p: Array = (exits[0] as Dictionary)["pos"]
		return cell_to_global(here, Vector3(float(p[0]), 0, float(p[1])))
	# We're outside; target is inside some interior: point at its door.
	var door := _door_for_interior(tcell)
	if door == "":
		return null
	var dw := door_world_any(door)
	if dw.is_empty():
		return null
	return dw["pos"]


## Where a gate sits in world space (or its exit interior if we're inside).
func _gate_marker(gid: String) -> Dictionary:
	var g: Dictionary = Regions.gates(WorldLayout.region).get(gid, {})
	if g.is_empty():
		return {}
	var gp: Array = g["pos"]
	# Indoors, marker_pos routes this through the interior's exit.
	return {"cell": "world", "pos": Vector3(float(gp[0]), 0, float(gp[1]))}


## Which region a marker's destination is on ("" if it's region-agnostic).
## Somewhere no road goes (the island): point at it across the sky, a few
## hundred metres out, so the compass shows which way to fly.
func _toward_by_air(dest: String) -> Dictionary:
	if not Regions.SKY.has(dest) or player == null:
		return {}
	var w := Regions.to_world(dest, (Regions.SKY[dest] as Rect2).get_center())
	var lp := Regions.to_local(WorldLayout.region, w)
	var pp := Vector2(player.global_position.x, player.global_position.z)
	var dir := (lp - pp).normalized()
	var p := pp + dir * 400.0
	return {"cell": "world", "pos": Vector3(p.x, 0, p.y)}


func _marker_region(m: String) -> String:
	var cell := ""
	if m.begins_with("cell:"):
		cell = str(m.split(":")[1])
	elif InteriorData.INTERIORS.has(m) or RegionContent.region_of_interior(m) != "nyc":
		cell = m
	elif WorldLayout.all_doors().has(m) or m.begins_with("d_"):
		var reg := _door_region(m)
		return reg
	elif m.begins_with("poi_"):
		for r2 in RegionContent.POIS.keys():
			if (RegionContent.POIS[r2] as Dictionary).has(m):
				return str(r2)
		return "nyc"
	else:
		return ""
	if cell == "" or cell == "world":
		return ""
	return RegionContent.region_of_interior(cell)


func _door_region(did: String) -> String:
	for reg in RegionContent.DOORS.keys():
		if RegionContent.DOORS[reg].has(did):
			return str(reg)
	return "nyc"


func _door_for_interior(cell: String) -> String:
	if cell.begins_with("subway:"):
		return cell.substr(7)
	if cell == "subway":
		# Someone waiting "on a platform": any station works, so point at the nearest.
		var best := ""
		var bd := INF
		var pp := player.global_position if player != null else Vector3.ZERO
		for sid in WorldLayout.SUBWAYS.keys():
			var a: Array = WorldLayout.SUBWAYS[sid]["door"]
			var dd := Vector2(float(a[0]) - pp.x, float(a[1]) - pp.z).length()
			if dd < bd:
				bd = dd
				best = str(sid)
		return best
	var d := interior_def(cell)
	for e in d.get("exits", []):
		var to := str((e as Dictionary).get("to", ""))
		if to.begins_with("world:"):
			return to.substr(6)
		if to.begins_with("interior:"):
			# Nested interior: route through its parent.
			var parent := to.split(":")[1]
			return _door_for_interior(parent)
	return ""


func _marker_target(m: String) -> Dictionary:
	# A travel gate (highway on-ramp / city exit), by its id.
	if m.begins_with("gate:"):
		return _gate_marker(m.substr(5))
	# A destination city: the on-ramp toward it from whatever map you're on
	# (nothing once you're there; the arrival rule moves the quest on).
	if m.begins_with("region:"):
		var dest := m.substr(7)
		if dest == WorldLayout.region:
			return {}
		var gr := RegionContent.gate_toward(WorldLayout.region, dest)
		return _gate_marker(gr) if gr != "" else _toward_by_air(dest)
	# If the marker points into another region, steer the player to the gate
	# that heads there instead of a door that isn't on this map.
	var mr := _marker_region(m)
	if mr != "" and mr != WorldLayout.region:
		var g := RegionContent.gate_toward(WorldLayout.region, mr)
		if g != "":
			return _gate_marker(g)
		return _toward_by_air(mr)
	if m.begins_with("npc:"):
		var id := m.substr(4)
		var n := npcs.get_npc(id)
		if n != null and not n.dead:
			return {"cell": n.cell, "pos": n.global_position}
		var d: Dictionary = NPCData.NPCS.get(id, {})
		if d.is_empty():
			return {}
		# Someone in another town: head for the road (or sky) that goes there.
		var nr := npcs.placement_region(d)
		if nr != "" and nr != WorldLayout.region:
			var g2 := RegionContent.gate_toward(WorldLayout.region, nr)
			return _gate_marker(g2) if g2 != "" else _toward_by_air(nr)
		var pl := npcs.placement(id, d)
		if pl.is_empty():
			return {}
		return {"cell": str(pl["cell"]), "pos": cell_to_global(str(pl["cell"]), pl["pos"])}
	if m.begins_with("cell:"):
		var parts := m.split(":")
		var c := str(parts[1])
		var xy := str(parts[2]).split(",") if parts.size() > 2 else PackedStringArray(["0", "0"])
		return {"cell": c, "pos": cell_to_global(c, Vector3(float(xy[0]), 0, float(xy[1])))}
	if WorldLayout.all_doors().has(m):
		return {"cell": "world", "pos": WorldLayout.door_world(m)["pos"]}
	if gen_doors.has(m):
		return {"cell": "world", "pos": (gen_doors[m] as Dictionary)["pos"]}
	if m.begins_with("bld:") and gen_doors.has(m.substr(4)):
		var sp2 := InteriorBuilder.exit_spawn(interior_def(m), 0)
		return {"cell": m, "pos": cell_to_global(m, sp2["pos"])}
	if WorldLayout.POIS.has(m):
		var p: Array = WorldLayout.POIS[m]["pos"]
		return {"cell": "world", "pos": Vector3(float(p[0]), 0, float(p[1]))}
	if m == "ring":
		var cid := _active_course()
		if cid == "":
			return {}
		var pts: Array = (COURSES[cid] as Dictionary)["rings"]
		return {"cell": "world", "pos": pts[clampi(ring_i, 0, pts.size() - 1)]}
	if m.begins_with("pos:"):
		var xy2 := m.substr(4).split(",")
		return {"cell": "world", "pos": Vector3(float(xy2[0]), 0, float(xy2[1]))}
	if InteriorData.INTERIORS.has(m):
		var sp := InteriorBuilder.exit_spawn(interior_def(m), 0)
		return {"cell": m, "pos": cell_to_global(m, sp["pos"])}
	return {}


# -------------------------------------------------------------------- tick
func _process(delta: float) -> void:
	if player == null or _dead or get_tree().paused:
		return
	if ferris != null and ferris.visible:
		ferris.rotation.z += delta * 0.05
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.25
		_update_detection()
		_update_aim_target()
		_check_triggers()
		_plane_rings_tick()
		_check_wings_landing()
	_slow_tick -= delta
	if _slow_tick <= 0.0:
		_slow_tick = 1.0
		_slow_update()
		_update_high_mode()


func _update_detection() -> void:
	var lvl := 0
	for k in _detect_reports.keys():
		var obj := instance_from_id(k)
		if obj == null or not is_instance_valid(obj) or (obj as NPC).dead:
			_detect_reports.erase(k)
			continue
		lvl = maxi(lvl, int(_detect_reports[k]))
	_detect_reports.clear()
	player.detection = lvl


func _update_aim_target() -> void:
	_aim_target = null
	if player.frozen:
		return
	var from := player.cam.global_position
	var to := from - player.cam.global_transform.basis.z * 80.0
	var q := PhysicsRayQueryParameters3D.create(from, to, Phys.WORLD | Phys.NPC)
	q.exclude = [player.get_rid()]
	var res := get_world_3d().direct_space_state.intersect_ray(q)
	if res.is_empty():
		return
	var c: Object = res["collider"]
	if c is NPC:
		var n := c as NPC
		if not n.dead and (n.is_hostile_to_player() or n.hp < n.max_hp):
			_aim_target = n


func _check_triggers() -> void:
	if busy_transition or ui_open() or cinematic:
		return
	var pp := player.global_position
	var cell := GameState.cell
	for t in WorldObjects.TRIGGERS:
		var td: Dictionary = t
		var tid := str(td["id"])
		if bool(td.get("once", true)) and GameState.flags.has("trig:" + tid):
			continue
		var tc := str(td.get("cell", "world"))
		if tc != "*" and tc != cell and not (tc == "subway" and cell.begins_with("subway")):
			continue
		if tc == "world" and str(td.get("region", "nyc")) != WorldLayout.region:
			continue
		# Story-director rules have no position: they fire anywhere in the cell.
		if td.has("pos"):
			var pa: Array = td["pos"]
			var tp := cell_to_global(cell, Vector3(float(pa[0]), 0, float(pa[1])))
			if Vector2(pp.x - tp.x, pp.z - tp.z).length() > float(td.get("r", 4.0)):
				continue
		var cw := str(td.get("when", ""))
		if cw != "":
			if not _trig_conds.has(cw):
				_trig_conds[cw] = DialogueManager.parse_cond(cw, "trigger " + tid)
			if not DialogueManager.eval_cond(_trig_conds[cw]):
				continue
		GameState.flags["trig:" + tid] = true
		_fire_trigger(td)
		return


func _fire_trigger(td: Dictionary) -> void:
	if td.has("fx"):
		await DialogueManager.run_effects(DialogueManager.parse_effects(str(td["fx"]), "trigger"))
		# A rule can change who should be standing where (e.g. Whiterose appears).
		npcs.refresh(false)
	if td.has("convo") and DialogueManager.has_convo(str(td["convo"])):
		var npc: NPC = npcs.get_npc(str(td.get("npc", ""))) if td.has("npc") else null
		await dialog.run(str(td["convo"]), npc)
	elif td.has("bark"):
		hud.subtitle(str(td.get("speaker", "ELLIOT (V.O.)")), str(td["bark"]), 5.0)


func _slow_update() -> void:
	var pp := player.global_position
	_update_parked()
	_update_airfield()
	_update_rides()
	_update_gates()
	_update_quest_rides()
	_spray_tick()
	_radio_tick()
	_companion_tick()
	# The Kingpin path: the corners pay every morning.
	if GameState.has_flag("kingpin"):
		var today := GameState.day()
		if not GameState.flags.has("kingpin_paid_day"):
			GameState.flags["kingpin_paid_day"] = today
		elif int(GameState.flags["kingpin_paid_day"]) < today:
			GameState.flags["kingpin_paid_day"] = today
			var amt := 450 if GameState.has_flag("kingpin_dirty") else 180
			GameState.add_cash(amt, true)
			hud.notify("An envelope from the corners: $%d" % amt, "")
	# Discovery (not while a cutscene drags the player around the city).
	if GameState.cell == "world" and not cinematic:
		for pid in WorldLayout.POIS.keys():
			if GameState.discovered.has(pid):
				continue
			var P: Dictionary = WorldLayout.POIS[pid]
			var pa: Array = P["pos"]
			if Vector2(pp.x - float(pa[0]), pp.z - float(pa[1])).length() < float(P.get("r", 30.0)):
				GameState.discover(str(pid), str(P["name"]))
		for did in WorldLayout.DOORS.keys():
			if GameState.discovered.has(did):
				continue
			var dw := WorldLayout.door_world(str(did))
			if (dw["pos"] as Vector3).distance_to(pp) < 14.0:
				GameState.discover(str(did), str(WorldLayout.DOORS[did]["name"]))
		for sid in WorldLayout.SUBWAYS.keys():
			if GameState.discovered.has(sid):
				continue
			if WorldLayout.subway_world(str(sid)).distance_to(pp) < 14.0:
				GameState.discover(str(sid), str(WorldLayout.SUBWAYS[sid]["name"]))
		var dist := WorldLayout.district_at(pp.x, pp.z)
		if dist != _last_district:
			_last_district = dist
			hud.location(str(WorldLayout.DISTRICT_NAMES.get(dist, dist)).to_upper())
	# Wanted: police response, by heat.
	_heat_tick()
	_chop_tick()
	# Mr. Robot whispers when you're fraying.
	_whisper_t -= 1.0
	if _whisper_t <= 0.0 and not ui_open():
		_whisper_t = randf_range(90.0, 180.0)
		if GameState.stability < 45 or (GameState.has_trait("robot_kid") and randf() < 0.4):
			hud.subtitle("MR. ROBOT", Whispers.pick(), 4.5)
			hud.glitch(0.35, 0.6)
			AudioManager.play_glitch()
	# Stability slowly drains without meds after dark; blackout at the bottom.
	_blackout_cool = maxf(0.0, _blackout_cool - 1.0)
	if GameState.stability <= 5 and _blackout_cool <= 0.0 and not ui_open() and not _in_combat():
		_blackout_cool = 600.0
		blackout("")
	# Wanted expiry is time-based; nothing to do.


## On a rooftop hundreds of meters up, draw the whole city (temporarily).
func _update_high_mode() -> void:
	var high := force_high or (GameState.cell == "world" and player.global_position.y > 120.0)
	if high == _high_mode:
		return
	_high_mode = high
	for e in _far_meshes:
		var mi: MeshInstance3D = e[0]
		if is_instance_valid(mi):
			mi.visibility_range_end = 3200.0 if high else float(e[1])
	if player != null and player.cam != null:
		player.cam.far = 3400.0 if high else Settings.view_far()
		player.cam.near = 0.25 if high else 0.05


var _cop_count: int = 0

# ---------------------------------------------------------------- the heat
## Seconds since any officer last had eyes on you. Stay out of sight long
## enough (longer the hotter it is) and they give up.
var unseen_t: float = 0.0
var last_seen := Vector3.ZERO
var _seen_ride: int = 0
var _search_mark: Node3D = null
var pursuit: Array = [] # police cars chasing you
var _roadblock_t: float = 0.0
var _pursuit_t: float = 0.0
const HEAT_FOOT := [0, 2, 3, 4, 5, 6] # officers on foot near you, per star
const HEAT_CARS := [0, 0, 1, 2, 2, 3] # cruisers chasing, per star
const SEARCH_AFTER := 5.0 # seconds unseen before it's a search, not a response
const HEAT_EVERY := [40.0, 40.0, 25.0, 18.0, 14.0, 12.0] # seconds between waves


# ------------------------------------------------------------ chop shop
## Rafi's Auto Body, Hunts Point: roll a stolen car into the bay and stop.
const CHOP_POS := Vector3(1105.0, 0.0, -1200.0)
const CHOP_PRICE := {"sedan": 450, "hatch": 350, "suv": 700, "van": 550, "taxi": 500, "police": 1500, "truck": 800}
const CHOP_PER_DAY := 3
var _chop_asked := false


## Today's wanted model: double money.
static func chop_wanted_model() -> String:
	var models := ["suv", "taxi", "van", "sedan", "truck", "hatch", "police"]
	return models[GameState.day() % models.size()]


func chop_price(v: Vehicle) -> int:
	var base := int(CHOP_PRICE.get(v.kind, 400))
	var p := float(base) * (0.35 + 0.65 * clampf(v.hp / 100.0, 0.0, 1.0))
	if v.kind == chop_wanted_model():
		p *= 2.0
	return int(round(p / 10.0)) * 10


func _chop_tick() -> void:
	GameState.flags["chop_want"] = chop_wanted_model() # Rafi's list, for his dialogue
	if WorldLayout.region != "nyc" or GameState.cell != "world" or ui_open() or busy_transition:
		return
	var v: Vehicle = player.driving
	var near := v != null and not (v is Aircraft) and Vector2(v.global_position.x - CHOP_POS.x, v.global_position.z - CHOP_POS.z).length() < 9.0
	if not near:
		_chop_asked = false
		return
	if _chop_asked or absf(v.speed) > 1.5 or GameState.is_wanted():
		return # with the heat on you, Rafi resprays first (_spray_tick)
	_chop_asked = true
	_chop_offer(v)


func _chop_offer(v: Vehicle) -> void:
	var day_key := "chop_day_%d" % GameState.day()
	var sold := int(GameState.flags.get(day_key, 0))
	var t := "=== _chop\n-- start\n"
	if v.has_meta("owned"):
		t += "RAFI: That's yours, papi. Registered, insured, loved. I don't buy cars with feelings.\n-> END\n"
	elif sold >= CHOP_PER_DAY:
		t += "RAFI: Three's my limit. Four cars in one day and the insurance guys start drawing circles on maps. Come back tomorrow.\n-> END\n"
	else:
		var price := chop_price(v)
		var wanted := v.kind == chop_wanted_model()
		t += "> A roll-up door rattles open. A man in coveralls walks around the car once, slowly, like a doctor.\n"
		t += "RAFI: %s. %s %s\n" % [v.display_name(), "Oh, that's on my list today. Double." if wanted else "Okay.", "Little banged up." if v.hp < 60.0 else "Clean."]
		t += "* \"Sell it. $%d.\" -> sell\n" % price
		t += "* \"Not today.\" -> END\n"
		t += "-- sell\n! set chop_pick\nRAFI: Pleasure. Walk out the side, don't look back, and you never saw this car. Neither did I. Nobody ever has.\n-> END\n"
	DialogueManager.convos.erase("_chop")
	DialogueManager.parse_text(t, "runtime:chop")
	GameState.flags.erase("chop_pick")
	await dialog.run("_chop", null)
	if not GameState.flags.has("chop_pick") or player.driving != v:
		return
	GameState.flags.erase("chop_pick")
	var price2 := chop_price(v)
	exit_vehicle(true)
	var uid := int(v.get_meta("ride_uid", -1))
	if uid >= 0:
		GameState.rides.erase(_ride_rec(uid))
	if player_car == v:
		player_car = null
	v.queue_free()
	GameState.add_cash(price2)
	GameState.flags[day_key] = sold + 1
	GameState.stat_add("cars_chopped")
	GameState.add_infamy("nypd", 1)
	hud.notify("Sold to Rafi: +$%d" % price2, "")
	AudioManager.play_success()


## A fresh crime: they know exactly where you are, and they're coming.
func _on_heat_raised() -> void:
	unseen_t = 0.0
	if player != null:
		last_seen = player.global_position
	_cop_t = minf(_cop_t, 3.0)
	_pursuit_t = minf(_pursuit_t, 4.0)


func heat_lose_time() -> float:
	return 12.0 + 7.0 * float(GameState.heat)


func _heat_tick() -> void:
	var wanted := GameState.is_wanted()
	if not wanted and GameState.heat > 0 and GameState.wanted_until <= GameState.game_minutes:
		GameState.clear_wanted() # the clock ran out
	AudioManager.siren(wanted and GameState.cell == "world")
	if not wanted:
		unseen_t = 0.0
		if not pursuit.is_empty():
			_end_pursuit()
		return
	# Are they looking at you right now?
	if _police_sees_player():
		unseen_t = 0.0
		last_seen = player.global_position
		_seen_ride = player.driving.get_instance_id() if player.driving != null else 0
		GameState.wanted_until = maxf(GameState.wanted_until, GameState.game_minutes + 20.0)
	else:
		# Indoors, nobody follows you in; in a different car, they're
		# looking for the wrong one. Either way it cools twice as fast.
		var swapped := player.driving != null and player.driving.get_instance_id() != _seen_ride
		unseen_t += 2.0 if GameState.cell != "world" or swapped else 1.0
		if unseen_t >= heat_lose_time():
			GameState.clear_wanted()
			unseen_t = 0.0
			_end_pursuit()
			hud.notify("You lost them.", "")
			AudioManager.play_success()
			return
	if GameState.cell != "world":
		return
	# Reinforcements only come while they can see you; once they've lost
	# you, the units already out search where you were last seen.
	var searching := unseen_t > SEARCH_AFTER
	_cop_t -= 1.0
	if _cop_t <= 0.0 and not searching:
		_cop_t = HEAT_EVERY[GameState.heat]
		_spawn_cops()
	_pursuit_t -= 1.0
	if _pursuit_t <= 0.0:
		_pursuit_t = 8.0
		_update_pursuit()
	if GameState.heat >= 4 and player.driving != null and not (player.driving is Aircraft):
		_roadblock_t -= 1.0
		if _roadblock_t <= 0.0:
			_roadblock_t = 28.0
			_spawn_roadblock()


func _police_sees_player() -> bool:
	if GameState.cell != "world":
		return false
	var eye := player.global_position + Vector3(0, 1.5, 0)
	for n in get_tree().get_nodes_in_group("npc"):
		var o := n as NPC
		if o == null or o.dead or not (o.faction in ["nypd", "fbi"]):
			continue
		var d := o.global_position.distance_to(player.global_position)
		if d < 6.0 or (d < 70.0 and o._los(o.head_pos(), eye)):
			return true
	var space := get_world_3d().direct_space_state
	for v in pursuit:
		var pv := v as Vehicle
		if not is_instance_valid(pv) or pv.dead:
			continue
		var d2 := pv.global_position.distance_to(player.global_position)
		if d2 < 55.0:
			var q := PhysicsRayQueryParameters3D.create(pv.global_position + Vector3(0, 1.4, 0), eye, Phys.WORLD)
			q.exclude = [pv.get_rid()]
			if player.driving != null:
				q.exclude.append(player.driving.get_rid())
			if space.intersect_ray(q).is_empty():
				return true
	return false


## Keep the right number of cruisers on your tail, aimed at you or your car
## (or, while they've lost you, at the spot you were last seen).
func _update_pursuit() -> void:
	var tgt: Node3D = player.driving if player.driving != null else player
	if unseen_t > SEARCH_AFTER:
		if _search_mark == null:
			_search_mark = Node3D.new()
			add_child(_search_mark)
		_search_mark.global_position = last_seen
		tgt = _search_mark
	var alive: Array = []
	for v in pursuit:
		var pv := v as Vehicle
		if not is_instance_valid(pv):
			continue
		if pv.dead or pv.driving or pv.global_position.distance_to(player.global_position) > 320.0:
			if not pv.driving and pv.global_position.distance_to(player.global_position) > 320.0:
				pv.queue_free()
			continue
		pv.ai_target = tgt
		alive.append(pv)
	pursuit = alive
	var want: int = HEAT_CARS[GameState.heat]
	if player.driving is Aircraft or unseen_t > SEARCH_AFTER:
		want = 0 # cruisers don't fly, and nobody new joins a search
	var tries := 0
	while pursuit.size() < want and tries < 6:
		tries += 1
		var ang := randf() * TAU
		var p := player.global_position + Vector3(cos(ang), 0, sin(ang)) * randf_range(70.0, 110.0)
		# On the nearest road's centre line, clear of the parked cars.
		var ic := clampi(roundi((p.x - WorldLayout.AX0) / WorldLayout.AXS), 0, WorldLayout.NA - 1)
		var jc := clampi(roundi((p.z - WorldLayout.SZ0) / WorldLayout.SZS), 0, WorldLayout.NS - 1)
		var on_ave := absf(p.x - WorldLayout.ax(ic)) < absf(p.z - WorldLayout.sz(jc))
		if on_ave:
			p.x = WorldLayout.ax(ic)
		else:
			p.z = WorldLayout.sz(jc)
		if not _street_spot(p):
			continue
		var car := Vehicle.new().setup("police", 0, Vector3(p.x, 0.3, p.z), 0.0, self)
		car.locked = true
		car.lock_dc = 60
		car.set_meta("pursuit", true)
		car.ai_speed_mul = 0.92 if GameState.heat < 4 else 1.0
		car.ai_on_arrive = _cruiser_unload
		vehicles_root.add_child(car)
		# Facing along the road, whichever way is toward you.
		var to := player.global_position - car.global_position
		if on_ave:
			car.rotation.y = 0.0 if to.z < 0.0 else PI
		else:
			car.rotation.y = PI * 0.5 if to.x < 0.0 else -PI * 0.5
		car.ai_target = tgt
		pursuit.append(car)


## A cruiser pulled up beside you: two officers out, guns up.
func _cruiser_unload(car: Vehicle) -> void:
	if car.has_meta("unloaded"):
		return
	car.set_meta("unloaded", true)
	var side := car.global_transform.basis.x
	for s in [-1.0, 1.0]:
		_spawn_officer(car.global_position + side * (1.9 * float(s)) + Vector3(0, 0.05, 0))


func _end_pursuit() -> void:
	for v in pursuit:
		var pv := v as Vehicle
		if is_instance_valid(pv) and not pv.driving:
			pv.ai_target = null
			pv.speed = 0.0
	pursuit = []


## Open street at ground level (no roof over it, in the map).
func _street_spot(p: Vector3) -> bool:
	if not WorldLayout.in_bounds(p.x, p.z):
		return false
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, 60.0, p.z), Vector3(p.x, -1.0, p.z), Phys.WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return not hit.is_empty() and (hit["position"] as Vector3).y < 0.5


## Four stars and you're in a car: two cruisers across the road ahead.
func _spawn_roadblock() -> void:
	var v: Vehicle = player.driving
	var fwd := -v.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var dist := clampf(absf(v.speed) * 3.0, 60.0, 110.0)
	var c := v.global_position + fwd * dist
	if not _street_spot(c):
		return
	var side := Vector3(-fwd.z, 0, fwd.x)
	var yaw := atan2(-side.x, -side.z)
	var placed := 0
	for s in [-1.0, 1.0]:
		var p: Vector3 = c + side * (2.8 * float(s))
		if not _street_spot(p):
			continue
		var car := Vehicle.new().setup("police", 0, Vector3(p.x, 0.3, p.z), yaw + (0.25 * float(s)), self)
		car.locked = true
		car.lock_dc = 60
		car.set_meta("roadblock", true)
		vehicles_root.add_child(car)
		_spawn_officer(p - fwd * 3.0)
		placed += 1
	if placed > 0:
		hud.notify("Roadblock ahead.", "warn")


func _spawn_officer(p: Vector3) -> void:
	# Five stars: the Bureau shows up instead of the precinct.
	var fbi := GameState.heat >= 5 and randf() < 0.6
	var tmpl: Dictionary = NPCData.TEMPLATES["fbi_agent" if fbi else "cop"].duplicate(true)
	if fbi:
		tmpl["weapon"] = "smg"
		tmpl["name"] = "FBI Tactical"
		tmpl["hp"] = 110.0
	elif GameState.heat >= 3 and randf() < 0.4:
		tmpl["weapon"] = "shotgun"
	var n2 := NPC.new()
	_cop_count += 1
	var cid := ("fbi_resp_%d" if fbi else "cop_resp_%d") % _cop_count
	n2.setup(cid, tmpl, p, 0.0, "world", self)
	npcs.add_child(n2)
	n2.global_position = p
	npcs.live[cid] = n2 # despawned with the rest when you leave
	n2.call_deferred("alarm", player)


func _spawn_cops() -> void:
	var alive := 0
	for n in get_tree().get_nodes_in_group("npc"):
		var o := n as NPC
		if o != null and not o.dead and (o.faction in ["nypd", "fbi"]) and o.global_position.distance_to(player.global_position) < 120.0:
			alive += 1
	var room: int = HEAT_FOOT[GameState.heat] - alive
	var wave := mini(room, 1 + (GameState.heat + 1) / 2)
	var placed := 0
	for attempt in 14:
		if placed >= wave:
			break
		var ang := randf() * TAU
		var p := player.global_position + Vector3(cos(ang), 0, sin(ang)) * randf_range(35.0, 50.0)
		# Street level only: nothing above the spot (not inside a building or under a roof).
		if not _street_spot(p):
			continue
		p.y = 0.05
		_spawn_officer(p)
		placed += 1


## Mr. Robot takes over: lose time, wake somewhere else.
func blackout(where: String) -> void:
	push_ui()
	hud.glitch(1.0, 1.5)
	AudioManager.play_glitch()
	await SceneRouter.fade(true, 0.6)
	var hours := randf_range(2.0, 5.0)
	GameState.advance_time(hours * 60.0)
	GameState.adjust_stability(25)
	var dest := where
	if dest == "":
		var opts: Array = []
		for d in GameState.discovered.keys():
			if WorldLayout.POIS.has(d) or WorldLayout.DOORS.has(d):
				opts.append(str(d))
		dest = str(opts[randi() % opts.size()]) if not opts.is_empty() else "d_apt"
	pop_ui()
	var t := resolve_location(dest)
	if not t.is_empty():
		GameState.cell = "__blackout"
		busy_transition = false
		await enter_cell(str(t["cell"]), t["pos"], float(t.get("yaw", 0.0)), false, str(t["cell"]) == "world")
	await SceneRouter.fade(false, 1.0)
	hud.center("You lost %d hours. What did he do with them?" % int(hours), 5.0)
	GameState.add_flag("blackouts", 1)
	if randf() < 0.5:
		GameState.add_cash(randi_range(-40, 80))


# ------------------------------------------------------------------- death
func _on_died() -> void:
	if _dead:
		return
	if player.driving != null:
		exit_vehicle(true)
	_dead = true
	push_ui()  # freeze the player through the death beat
	await get_tree().create_timer(0.8).timeout
	pop_ui()   # release that freeze-push; death_ui.open() pushes its own (net +1)
	death_ui.open()


func test_pick_choice(chs: Array) -> int:
	if test_picker.is_valid():
		return int(test_picker.call(chs))
	return 0


# ------------------------------------------------------------------ vehicles
func _use_vehicle(v: Vehicle) -> void:
	if v.dead or player.driving != null:
		return
	if v.locked:
		if GameState.skill("lockpick") >= v.lock_dc:
			AudioManager.sfx("lockpick")
			hud.notify("You slim-jim the lock and pull the ignition cover.", "")
			GameState.stat_add("locks")
			if randf() < (0.12 if GameState.is_night() else 0.3):
				crime_witnessed(v.global_position)
		else:
			AudioManager.play_3d("lockbreak", v.global_position, 4.0)
			AudioManager.play_3d("hit", v.global_position, 2.0, 1.6)
			hud.notify("You crowbar the cabin door. It screams like it's being murdered." if v is Aircraft else "Elbow through the window. Subtle.", "warn")
			crime_witnessed(v.global_position)
			for p in crowd.peds:
				var ped = p
				if is_instance_valid(ped) and not ped.dead and ped.global_position.distance_to(v.global_position) < 20.0:
					ped.flee_from(v.global_position)
		v.locked = false
		v.stolen = true
		if v is Aircraft:
			_plane_taken(v as Aircraft)
		else:
			GameState.stat_add("cars_stolen")
		GameState.adjust_stability(-1)
	enter_vehicle(v)


## Lock difficulty of a city parked car (0 = keys in it). Stable per car.
func _parked_lock(id: String) -> int:
	if _hash01(id, 7) < 0.08:
		return 0
	return [15, 20, 25, 30, 35, 40, 45, 50, 60][int(_hash01(id, 8) * 9.0) % 9]


var _hidden_cars: Array = [] # [{id, box: Vector4, shape: CollisionShape3D}]


## Turn one of the city's merged parked cars into a real Vehicle and take it.
func _steal_parked(id: String) -> void:
	var e := loot_index.get_entry(id)
	if e.is_empty() or e.has("gone") or player.driving != null:
		return
	var p: Vector3 = e["p"]
	var yaw := float(e["yaw"])
	var v := Vehicle.new().setup(str(e["car"]), int(e["ci"]), Vector3(p.x, 0.1, p.z), yaw, self)
	v.lock_dc = _parked_lock(id)
	v.locked = v.lock_dc > 0
	_hide_parked(id, e)
	vehicles_root.add_child(v)
	# Whatever was in the glovebox comes with it.
	if not GameState.containers.has(id):
		var lt := "taxi" if str(e["kind"]) == "taxi" else "glovebox"
		var got := _roll_container({"loot": lt})
		if int(got["cash"]) > 0:
			GameState.add_cash(int(got["cash"]))
		for k in (got["items"] as Dictionary).keys():
			GameState.give(str(k), int(got["items"][k]))
		GameState.containers[id] = {"items": {}, "cash": 0, "day": GameState.day()}
	_use_vehicle(v)


func _hide_parked(id: String, e: Dictionary) -> void:
	var p: Vector3 = e["p"]
	var he: Vector3 = e["he"]
	var along_z := he.z > he.x
	var box := Vector4(p.x, p.z, 1.25 if along_z else 2.95, 2.95 if along_z else 1.25)
	# Its static collider goes too.
	var shape: CollisionShape3D = null
	var q := PhysicsPointQueryParameters3D.new()
	q.position = Vector3(p.x, 0.8, p.z)
	q.collision_mask = Phys.WORLD
	for hit in get_world_3d().direct_space_state.intersect_point(q, 4):
		var body := (hit as Dictionary).get("collider") as StaticBody3D
		if body == null:
			continue
		var owner_id := body.shape_find_owner(int(hit["shape"]))
		var cs := body.shape_owner_get_owner(owner_id) as CollisionShape3D
		if cs != null and (cs.shape is BoxShape3D) and (cs.shape as BoxShape3D).size.y < 1.7:
			shape = cs
			cs.set_deferred("disabled", true)
			break
	e["gone"] = true
	_hidden_cars.append({"id": id, "box": box, "shape": shape})
	while _hidden_cars.size() > 32:
		var old: Dictionary = _hidden_cars.pop_front()
		var oe := loot_index.get_entry(str(old["id"]))
		oe.erase("gone") # a new car parks in the old spot
		if old["shape"] != null and is_instance_valid(old["shape"]):
			(old["shape"] as CollisionShape3D).set_deferred("disabled", false)
	var boxes: Array = []
	for h in _hidden_cars:
		boxes.append(h["box"])
	Mats.set_hidden_cars(boxes)


# ---------------------------------------------------------------- aircraft
var planes: Dictionary = {} # airfield slot -> Aircraft
var night_lights: NightLights
var races: Races
var taxi: Taxi
var air_races: AirRaces
var emergency: Emergency
var stunts: StuntJumps
var airfield_slots: Array = [] # from CityBuilder.airfield_planes
var _af_filled: Dictionary = {} # slot -> true once spawned this session
var rings: Node3D = null
var ring_i: int = 0
var _course := ""
## The flight test: five rings over the city (sq_wings 20).
const RINGS := [Vector3(1570, 70, -1790), Vector3(950, 110, -1900), Vector3(300, 130, -1250), Vector3(10, 190, -284), Vector3(-60, 90, 80)]
## Ring courses: fly them in order while the quest sits at `stage` on that
## map. Progress is saved as flags <flag>_ring and <flag>_rings_done.
const COURSES := {
	"wings": {"quest": "sq_wings", "stage": 20, "region": "nyc", "flag": "wings", "rings": RINGS},
	# Paper Rain: out of Kearney Strip, over the plant's stacks, down Main
	# Street over the festival, and over the memorial wall.
	"paper": {"quest": "sq_tw3", "stage": 20, "region": "township", "flag": "paper", "rings": [Vector3(-470, 60, -200), Vector3(-240, 112, -345), Vector3(-60, 70, 0), Vector3(150, 55, 0), Vector3(-75, 55, 300)]},
	# Who's Driving?: the banner over the FreightOS depot, low over the mill,
	# then down Broadway.
	"banner": {"quest": "sq_gy4", "stage": 20, "region": "gary", "flag": "banner", "rings": [Vector3(420, 70, -380), Vector3(150, 60, -340), Vector3(-280, 85, -300), Vector3(-140, 55, 120), Vector3(-140, 50, 420)]},
}
## Landings that count: stop a plane on that map's airfield while the quest
## sits at `stage` and the flag is set (the story director does the rest).
const LANDINGS := [
	{"quest": "sq_wings", "stage": 30, "region": "nyc", "flag": "wings_landed"},
	{"quest": "sq_tw3", "stage": 30, "region": "township", "flag": "paper_landed"},
	{"quest": "sq_airmail", "stage": 20, "region": "port", "flag": "airmail_landed"},
	{"quest": "sq_gy4", "stage": 30, "region": "gary", "flag": "banner_landed"},
	{"quest": "sq_rm4", "stage": 30, "region": "nyc", "flag": "patch_landed"},
]


## Keep the airfield's planes on their tie-downs (and clear wrecks away).
func _update_airfield() -> void:
	if GameState.cell != "world" or vehicles_root == null:
		return
	var pp := player.global_position
	var may_fly := GameState.flags.has("pilot_license") or GameState.flags.has("gus_plane_ok")
	var walt_ok := GameState.flags.has("walt_plane_ok")
	for sl in airfield_slots:
		var sid := str(sl["slot"])
		var a: Aircraft = planes.get(sid)
		if a != null and not is_instance_valid(a):
			planes.erase(sid)
			a = null
		if a != null:
			if a.owner_tag == "gus" and a.locked and may_fly and not a.driving:
				a.locked = false # Gus said yes
			if a.owner_tag == "walt" and a.locked and walt_ok and not a.driving:
				a.locked = false # Walt said yes
			if a.owner_tag == "lena" and a.locked and GameState.flags.has("gy_plane_ok") and not a.driving:
				a.locked = false # Lena said yes
			if a.owner_tag == "ines" and a.locked and GameState.flags.has("rm_plane_ok") and not a.driving:
				a.locked = false # Ines said yes
			var dist := a.global_position.distance_to(pp)
			if not a.driving and (dist > 1800.0 or (a.dead and dist > 300.0)):
				a.queue_free()
				planes.erase(sid)
			continue
		var spot: Vector3 = sl["pos"]
		var d2 := spot.distance_to(pp)
		if d2 > 900.0 or (_af_filled.has(sid) and d2 < 250.0):
			continue # don't pop a plane in while you're watching the spot
		if sid == "ecorp_jet" and GameState.flags.has("ecorp_jet_gone") and not GameState.flags.has("jet_owned"):
			continue
		if _ride_in_slot(sid):
			continue # that plane is parked somewhere else now, wherever you left it
		_spawn_plane(sid, str(sl["model"]), spot, float(sl["yaw"]))


func _spawn_plane(sid: String, m: String, pos: Vector3, yaw: float) -> Aircraft:
	var a := Aircraft.new().setup_plane(m, pos, yaw, self)
	a.slot = sid
	if m == "citation" and GameState.flags.has("jet_owned"):
		a.owner_tag = "player"
		a.lock_dc = 0
		a.locked = false
		a.set_meta("owned", true)
	elif m == "citation":
		a.owner_tag = "ecorp"
		a.lock_dc = 60
		a.locked = true
	elif sid.begins_with("township_"):
		# Kearney Strip: Walt's planes. His word is the only license he cares about.
		a.owner_tag = "walt"
		a.lock_dc = 35
		a.locked = not GameState.flags.has("walt_plane_ok")
	elif sid.begins_with("gary_"):
		# Gary/Chicago Airport: Lena's two Skyhawks.
		a.owner_tag = "lena"
		a.lock_dc = 35
		a.locked = not GameState.flags.has("gy_plane_ok")
	elif sid.begins_with("island_"):
		# Price's own aircraft. Taking one is exactly as illegal as it sounds.
		a.owner_tag = "ecorp"
		a.lock_dc = 60
		a.locked = true
	elif sid.begins_with("redmont_"):
		# Microslop Field: Ines logs every flight as 'proficiency.'
		a.owner_tag = "ines"
		a.lock_dc = 40
		a.locked = not GameState.flags.has("rm_plane_ok")
	elif sid.begins_with("port_"):
		# Ramsey Field: Marisol's one plane, and the answer is no.
		a.owner_tag = "marisol"
		a.lock_dc = 45
		a.locked = true
	else:
		a.owner_tag = "gus"
		a.lock_dc = 35
		a.locked = not (GameState.flags.has("pilot_license") or GameState.flags.has("gus_plane_ok"))
	vehicles_root.add_child(a)
	planes[sid] = a
	_af_filled[sid] = true
	return a


## Taking a plane you weren't given.
func _plane_taken(a: Aircraft) -> void:
	GameState.stat_add("planes_stolen")
	if a.owner_tag == "ecorp":
		GameState.flags["ecorp_jet_gone"] = true
		GameState.set_wanted(150.0)
		GameState.add_infamy("ecorp", 8)
		GameState.add_fame("fsociety", 4)
		hud.notify("E Corp's jet. They'll notice. Everyone will notice.", "warn")
	else:
		crime_witnessed(a.global_position)


func _active_course() -> String:
	if GameState.cell != "world":
		return ""
	for cid in COURSES.keys():
		var c: Dictionary = COURSES[cid]
		if str(c["region"]) == WorldLayout.region and GameState.quest_state(str(c["quest"])) == "active" and GameState.quest_stage(str(c["quest"])) == int(c["stage"]):
			return str(cid)
	return ""


func _course_rings() -> Array:
	return (COURSES[_course] as Dictionary)["rings"] if COURSES.has(_course) else RINGS


func _plane_rings_tick() -> void:
	var cid := _active_course()
	if cid != _course and rings != null:
		rings.queue_free()
		rings = null
	_course = cid
	if cid == "":
		return
	var C: Dictionary = COURSES[cid]
	var pts: Array = C["rings"]
	var fl := str(C["flag"])
	if GameState.flags.has(fl + "_rings_done"):
		if rings != null:
			rings.queue_free()
			rings = null
		return
	if rings == null:
		ring_i = clampi(int(GameState.flags.get(fl + "_ring", 0)), 0, pts.size() - 1)
		_build_rings()
	var v: Vehicle = player.driving
	if v == null or not (v is Aircraft) or not (v as Aircraft).airborne:
		return
	if v.global_position.distance_to(pts[ring_i]) < 16.0:
		ring_i += 1
		GameState.flags[fl + "_ring"] = ring_i
		AudioManager.play_success()
		Pad.rumble(0.3, 0.2, 0.15)
		if ring_i >= pts.size():
			GameState.flags[fl + "_rings_done"] = true # the story director moves the quest on
			if rings != null:
				rings.queue_free()
				rings = null
		else:
			hud.notify("Ring %d / %d" % [ring_i, pts.size()], "")
			_build_rings()


func _build_rings() -> void:
	if rings != null:
		rings.queue_free()
	rings = Node3D.new()
	rings.name = "FlightRings"
	add_child(rings)
	var pts := _course_rings()
	for k in [ring_i, ring_i + 1]:
		if k >= pts.size():
			continue
		var c: Vector3 = pts[k]
		var prev: Vector3 = pts[k - 1] if k > 0 else Vector3(WorldLayout.RUNWAY_X, 0, WorldLayout.RUNWAY_Z0)
		var dir := (c - prev)
		dir.y = 0.0
		dir = dir.normalized()
		var bas := Basis.looking_at(dir, Vector3.UP)
		var mb := MeshBatch.new()
		var col := Color(1.0, 0.7, 0.15) if k == ring_i else Color(0.35, 0.25, 0.08)
		for i in 28:
			var a := TAU * float(i) / 28.0
			var local := Vector3(cos(a) * 15.0, sin(a) * 15.0, 0)
			var xf := Transform3D(bas * Basis(Vector3.BACK, a), c + bas * local)
			mb.box_xf(xf, Vector3(0.9, 3.6, 0.9), col)
		var mi := mb.commit(rings, Mats.glow, 0.0, "Ring%d" % k)
		mi.visibility_range_end = 4000.0


## A plane stopped on this map's airfield counts for whichever landing the
## story is waiting on.
func _check_wings_landing() -> void:
	var v: Vehicle = player.driving
	if v == null or not (v is Aircraft) or (v as Aircraft).airborne or absf(v.speed) > 2.0 or v.dead:
		return
	if not WorldLayout.airfield_rect().has_point(Vector2(v.global_position.x, v.global_position.z)):
		return
	if not GameState.flags.has("landed_" + WorldLayout.region):
		GameState.flags["landed_" + WorldLayout.region] = true
	for L in LANDINGS:
		var ld: Dictionary = L
		if str(ld["region"]) == WorldLayout.region and GameState.quest_state(str(ld["quest"])) == "active" and GameState.quest_stage(str(ld["quest"])) == int(ld["stage"]):
			GameState.flags[str(ld["flag"])] = true
	jobs.on_landed(WorldLayout.region)


# -------------------------------------------------------------- companions
var _comp_bark_t: float = 90.0
var _comp_combat_t: float = 0.0
var _comp_hp_t: float = 0.0
var _comp_event_t: float = 0.0
var _comp_last_cell: String = ""
var _comp_innocents: int = -1


## Once a second: affinity, leaving, reactions, place lines, barks.
func _companion_tick() -> void:
	_comp_event_t = maxf(0.0, _comp_event_t - 1.0)
	var inn := int(GameState.stats.get("innocents", 0))
	if _comp_innocents >= 0 and inn > _comp_innocents:
		companion_event("kill_innocent")
	_comp_innocents = inn
	if GameState.companions.is_empty() or _dead or ui_open() or busy_transition:
		_comp_last_cell = GameState.cell
		return
	_comp_bark_t -= 1.0
	_comp_combat_t -= 1.0
	_comp_hp_t -= 1.0
	var new_cell := GameState.cell != _comp_last_cell
	_comp_last_cell = GameState.cell
	for cid in GameState.companions.duplicate():
		var id := str(cid)
		var cd: Dictionary = CompanionData.get_def(id)
		if cd.is_empty():
			continue
		GameState.flags["aff_" + id] = int(GameState.flags.get("aff_" + id, 0)) + 1
		var n := npcs.get_npc(id)
		if DialogueManager.check(str(cd.get("leave_when", "false"))):
			_companion_leaves(id, cd)
			return
		for f in (cd.get("react", {}) as Dictionary).keys():
			var key := "react_%s_%s" % [id, f]
			if GameState.flags.has(str(f)) and not GameState.flags.has(key):
				GameState.flags[key] = true
				_cbark(id, str(cd["react"][f]))
				return
		# The first time you reach another city or town together.
		var rkey := "cregion_%s_%s" % [id, WorldLayout.region]
		if GameState.cell == "world" and (cd.get("regions", {}) as Dictionary).has(WorldLayout.region) and not GameState.flags.has(rkey):
			GameState.flags[rkey] = true
			_cbark(id, str(cd["regions"][WorldLayout.region]))
			return
		if new_cell:
			for ck in (cd.get("cells", {}) as Dictionary).keys():
				var c := str(ck)
				var hit := c == GameState.cell or (c.ends_with("*") and GameState.cell.begins_with(c.trim_suffix("*")))
				var seen := "cseen_%s_%s" % [id, c]
				if hit and not GameState.flags.has(seen):
					GameState.flags[seen] = true
					_cbark(id, str(cd["cells"][ck]))
					return
		if n != null and n.mode == "combat" and _comp_combat_t <= 0.0:
			_comp_combat_t = 35.0
			_cbark_kind(id, "combat")
			return
	# You, hurt.
	if GameState.hp < GameState.max_hp() * 0.3 and _comp_hp_t <= 0.0:
		_comp_hp_t = 50.0
		var id2 := str(GameState.companions[randi() % GameState.companions.size()])
		_cbark_kind(id2, "low_hp")
		if GameState.companions.has("leon") and _in_combat():
			GameState.heal(25.0)
			hud.notify("Leon hands you a sandwich. You eat it with one hand. +25 HP", "")
		return
	# Shayla's bag: once a day.
	if GameState.companions.has("shayla_n") and int(GameState.flags.get("shayla_gift_day", -1)) != GameState.day():
		GameState.flags["shayla_gift_day"] = GameState.day()
		var gift: String = ["painkillers", "bandages"][randi() % 2]
		GameState.give(gift)
		_cbark("shayla_n", "Here. Put this in your pocket and don't ask where I got it. Okay, I got it from my pocket.")
		return
	# Night falls.
	if GameState.is_night() and int(GameState.flags.get("cnight_day", -1)) != GameState.day():
		GameState.flags["cnight_day"] = GameState.day()
		_cbark_kind(str(GameState.companions[0]), "night")
		return
	if _comp_bark_t <= 0.0 and not _in_combat():
		_comp_bark_t = randf_range(120.0, 240.0)
		_cbark_kind(str(GameState.companions[randi() % GameState.companions.size()]), "idle")


## Something happened that a companion would comment on.
func companion_event(kind: String) -> void:
	if GameState.companions.is_empty() or _comp_event_t > 0.0:
		return
	_comp_event_t = 8.0
	_cbark_kind(str(GameState.companions[randi() % GameState.companions.size()]), kind)


func _cbark_kind(id: String, kind: String) -> void:
	var cd: Dictionary = CompanionData.get_def(id)
	var lines: Array = (cd.get("barks", {}) as Dictionary).get(kind, [])
	if lines.is_empty():
		return
	_cbark(id, str(lines[randi() % lines.size()]))


func _cbark(id: String, text: String) -> void:
	var nm := str(CompanionData.get_def(id).get("name", id)).to_upper()
	hud.subtitle(nm, text, 4.5)


func _companion_leaves(id: String, cd: Dictionary) -> void:
	GameState.flags["left_" + id] = true
	hud.subtitle(str(cd.get("name", id)).to_upper(), str(cd.get("leave_line", "I'm done.")), 6.0)
	_release_companion(id)
	hud.notify("%s has left you." % str(cd.get("name", id)), "warn")


## Back to their own life: their own temper, their own home.
func _release_companion(id: String) -> void:
	GameState.companions.erase(id)
	var n := npcs.get_npc(id)
	if n != null:
		n.aggro = str(n.def.get("aggro", "neutral"))
		n.target = null
		n.mode = "idle"
		n.visible = true
		n.collision_layer = Phys.NPC
		n.collision_mask = Phys.WORLD | Phys.NPC | Phys.PLAYER
		# Walk home if home is right here; otherwise walk off, despawn out of
		# sight, and turn up at home later.
		var pl := npcs.placement(id, NPCData.NPCS.get(id, {}))
		if not pl.is_empty() and str(pl["cell"]) == GameState.cell:
			var hp: Vector3 = cell_to_global(GameState.cell, pl["pos"])
			n.walk_to(hp)
			n.set_home(hp, float(pl["yaw"]))
		else:
			var away := n.global_position - player.global_position
			away.y = 0.0
			if away.length() < 0.5:
				away = Vector3(1, 0, 0)
			n.walk_to(n.global_position + away.normalized() * 30.0)
	npcs.call_deferred("refresh", false)


func enter_vehicle(v: Vehicle) -> void:
	player.driving = v
	player.collision_layer = 0
	player.collision_mask = 0
	player.velocity = Vector3.ZERO
	parked_cars.erase(v)
	if player_car != null and player_car != v and is_instance_valid(player_car) and not (player_car is Aircraft) and not player_car.has_meta("ride_uid"):
		parked_cars.append(player_car) # the last ride gets cleaned up like any parked car
	player_car = v
	v.begin_drive()
	AudioManager.sfx("door")
	if v is Aircraft:
		companion_event("fly")
	elif v.stolen:
		companion_event("steal_car")
	if v is Aircraft:
		if not GameState.flags.has("hint_flying"):
			GameState.flags["hint_flying"] = true
			if Pad.using_pad:
				hud.center("RT/LT throttle · left stick: bank and nose (pull back to climb) · LB/RB rudder · X brakes · A get out (stopped)", 8.0)
			else:
				hud.center("W/S throttle · A/D bank · mouse back (or ↓) climbs · SPACE brakes · E get out (stopped)\nFull throttle down the runway, pull back once you're fast enough.", 9.0)
		return
	if not GameState.flags.has("hint_driving"):
		GameState.flags["hint_driving"] = true
		if Pad.using_pad:
			hud.center("RT gas · LT brake · stick steer · X handbrake · LB horn · A get out", 6.0)
		else:
			hud.center("W/S  drive · A/D  steer · SPACE  handbrake · G  horn · E  get out", 6.0)


func exit_vehicle(forced: bool = false) -> void:
	var v: Vehicle = player.driving
	if v == null:
		return
	if not forced and v is Aircraft and ((v as Aircraft).airborne or absf(v.speed) > 2.0):
		hud.notify("Not while you're moving. Land it first." if (v as Aircraft).airborne else "Stop the plane first.", "warn")
		return
	if not forced and absf(v.speed) > 6.0:
		hud.notify("Slow down first.", "warn")
		return
	# Step out on the driver's side if there's room, else the other side, else behind.
	var basis := v.global_transform.basis
	var spots := [v.global_position - basis.x * 2.0, v.global_position + basis.x * 2.0, v.global_position + basis.z * 3.4, v.global_position - basis.z * 3.4]
	var out: Vector3 = spots[0]
	var found := false
	var space := get_world_3d().direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.7
	for sp in spots:
		var q := PhysicsRayQueryParameters3D.create(v.global_position + Vector3(0, 1.0, 0), (sp as Vector3) + Vector3(0, 1.0, 0), Phys.WORLD | Phys.CAR)
		q.exclude = [v.get_rid()]
		if not space.intersect_ray(q).is_empty():
			continue
		# Room to stand, not just a clear line to the spot.
		var sq := PhysicsShapeQueryParameters3D.new()
		sq.shape = cap
		sq.transform = Transform3D(Basis.IDENTITY, Vector3((sp as Vector3).x, v.global_position.y + 1.0, (sp as Vector3).z))
		sq.collision_mask = Phys.WORLD | Phys.CAR
		sq.exclude = [v.get_rid()]
		if space.intersect_shape(sq, 1).is_empty():
			out = sp
			found = true
			break
	if not found:
		if not forced:
			hud.notify("No room to get out here.", "warn")
			return
		out = v.global_position + Vector3(0, 2.2, 0) # climb out onto the roof
	player.driving = null
	v.end_drive()
	player.collision_layer = Phys.PLAYER
	player.collision_mask = Phys.WORLD | Phys.NPC | Phys.CAR
	player.teleport(Vector3(out.x, (v.global_position.y + 0.1) if found else out.y, out.z))
	player.velocity = Vector3.ZERO
	player.set_look(v.rotation.y, 0.0)
	player.cam.make_current()
	AudioManager.sfx("door")
	_remember_ride(v)


## Pull a driver out of a stopped car in traffic.
func _carjack(car: Traffic.Car) -> void:
	if player.driving != null or not is_instance_valid(car) or car.speed > 3.0:
		return
	var v := Vehicle.new().setup(car.kind if car.kind != "truck" else "van", car.color_idx, car.global_position, car.rotation.y, self)
	v.locked = false
	v.stolen = true
	v.lock_dc = 0
	vehicles_root.add_child(v)
	traffic.remove_car(car)
	hud.notify("You drag the driver out. They run, screaming.", "warn")
	AudioManager.play_3d("hurt", v.global_position, 0.0, 1.3)
	GameState.stat_add("cars_stolen")
	GameState.stat_add("carjackings")
	GameState.adjust_stability(-2)
	if v.kind == "police":
		GameState.set_wanted(180.0)
		GameState.add_infamy("nypd", 6)
	else:
		crime_witnessed(v.global_position)
		if randf() < 0.5:
			GameState.set_wanted(60.0)
	for p in crowd.peds:
		var ped = p
		if is_instance_valid(ped) and not ped.dead and ped.global_position.distance_to(v.global_position) < 25.0:
			ped.flee_from(v.global_position)
	enter_vehicle(v)


# ----------------------------------------------------------------- regions
## Driving through a travel gate (the highway sign at a city's edge) takes the
## whole car down the road to the next map; planes fly out of the airspace.
var _gate_hold := 0.0
var region_requested := ""


func _update_gates() -> void:
	if GameState.cell != "world" or busy_transition or ui_depth > 0:
		return
	var pp := player.global_position
	var near := ""
	for gid in Regions.gates(WorldLayout.region).keys():
		var g: Dictionary = Regions.gates(WorldLayout.region)[gid]
		var gp: Array = g["pos"]
		if Vector2(pp.x, pp.z).distance_to(Vector2(float(gp[0]), float(gp[1]))) < float(g["r"]):
			near = str(gid)
	if near == "":
		_gate_hold = 0.0
		return
	var g2: Dictionary = Regions.gates(WorldLayout.region)[near]
	var dest: Array = g2["to"]
	if player.driving == null:
		hud.notify("%s. It's a long way on foot. Bring a car, or fly." % str(g2["sign"]), "warn")
		return
	if player.driving is Aircraft:
		return
	_gate_hold += 1.0
	if _gate_hold < 2.0:
		hud.center("%s\nKeep driving to leave %s" % [str(g2["sign"]), Regions.region_name(WorldLayout.region)], 1.6)
		return
	_gate_hold = 0.0
	go_region(str(dest[0]), str(dest[1]), false)


## Called by a plane that has flown out of this map's airspace. If another
## map borders it there, carry on into it mid-flight (true). Otherwise warn
## and let the plane turn itself back (false).
var _air_warn_t := 0.0


func airspace_exit(a: Aircraft) -> bool:
	if busy_transition or ui_depth > 0 or player.driving != a:
		return busy_transition
	var w := Regions.to_world(WorldLayout.region, Vector2(a.global_position.x, a.global_position.z))
	var nb := Regions.region_at(w, WorldLayout.region)
	if nb == "":
		var now := Time.get_ticks_msec() / 1000.0
		if now - _air_warn_t > 6.0:
			_air_warn_t = now
			hud.notify(_airspace_hint(), "warn")
		return false
	# Come in just over the line, same height, heading and speed.
	var lp := Regions.to_local(nb, w)
	var fwd := Vector2(-sin(a.heading), -cos(a.heading))
	lp += fwd * 40.0
	go_region_air(nb, Vector3(lp.x, a.global_position.y, lp.y), a)
	return true


## Where the neighbours are, for a pilot about to fly off the edge of nothing.
func _airspace_hint() -> String:
	match WorldLayout.region:
		"nyc":
			return "Nothing out that way but haze and open water. Head north over the Bronx for I-80, and the towns and Chicago beyond it."
		"highway":
			return "Haze and empty farmland. I-80 runs north to Chicago and south to New York; Washington Township is west, Port Ramsey east."
		"chicago":
			return "Nothing out there but lake and prairie. New York and the towns are south, down I-80."
		"township":
			return "Nothing out that way but fields to the horizon. I-80 is east; follow the county road."
		"port":
			return "Open Atlantic, except for one island, due east. Turn back west for I-80, or north up Route 9 for Redmont."
		"gary":
			return "Lake Michigan and nothing else. Chicago is east, Washington Township south."
		"island":
			return "Open Atlantic in every direction. Port Ramsey is back west."
		"redmont":
			return "Woods and hills, all the way to the horizon, all of it Microslop's. Port Ramsey is south, down Route 9; Chicago is west, across the water."
	return "Nothing out that way. Turn back."


## Fly into a neighbouring map at a precise spot (see airspace_exit).
var _air_arrive := Vector3.INF
var _air_heading := 0.0
var _air_throttle := 0.7


func go_region_air(region: String, local_pos: Vector3, a: Aircraft) -> void:
	_air_arrive = local_pos
	_air_heading = a.heading
	_air_throttle = a.throttle
	go_region(region, "", true)


## Leave this map for another. By road: arrive at the matching gate with the
## same car. By air: arrive on approach to the destination's airfield.
func go_region(region: String, gate: String, by_air: bool) -> void:
	if busy_transition:
		return
	busy_transition = true
	var v: Vehicle = player.driving
	var carry := {}
	if v != null and is_instance_valid(v):
		carry = {"kind": "plane" if v is Aircraft else "car", "model": (v as Aircraft).model if v is Aircraft else v.kind, "ci": v.color_idx, "hp": v.hp, "owned": v.has_meta("owned") or bool(GameState.flags.get("jet_owned", false)) and v is Aircraft and (v as Aircraft).model == "citation", "speed": v.speed}
		# It comes with you, so it's no longer parked here.
		var uid := int(v.get_meta("ride_uid", -1))
		if uid >= 0:
			GameState.rides.erase(_ride_rec(uid))
	var from := WorldLayout.region
	GameState.region = region
	GameState.cell = "world"
	GameState.pos_local = false
	if by_air and _air_arrive != Vector3.INF:
		GameState.player_pos = _air_arrive
		GameState.player_yaw = _air_heading
		carry["heading"] = _air_heading
		carry["throttle"] = _air_throttle
		_air_arrive = Vector3.INF
	elif by_air and Regions.FLY_IN.has(region):
		var f: Array = Regions.FLY_IN[region]
		GameState.player_pos = Vector3(float(f[0]), float(f[1]), float(f[2]))
		GameState.player_yaw = float(f[3])
	else:
		var a: Dictionary = Regions.ARRIVE.get(gate, {"pos": [0, 0], "yaw": 0.0})
		var ap: Array = a["pos"]
		GameState.player_pos = Vector3(float(ap[0]), 0.2, float(ap[1]))
		GameState.player_yaw = float(a["yaw"])
	GameState.flags["region_from"] = from
	if not GameState.flags.has("visited_" + region):
		GameState.flags["visited_" + region] = true
		GameState.add_xp(100)
	SaveManager.pending_load = {"state": GameState.to_dict(), "travel": carry, "by_air": by_air}
	if test_mode:
		region_requested = region # the test harness swaps the scene itself
		return
	SceneRouter.goto_game()


## After a region load: put the car or plane you came in under you again.
func _arrive_with(carry: Dictionary, by_air: bool) -> void:
	if carry.is_empty():
		return
	var pos := player.global_position
	var yaw := GameState.player_yaw
	var nv: Vehicle
	if str(carry.get("kind", "car")) == "plane":
		var a := Aircraft.new().setup_plane(str(carry.get("model", "skyhawk")), pos, yaw, self)
		a.owner_tag = "player"
		nv = a
	else:
		nv = Vehicle.new().setup(str(carry.get("model", "sedan")), int(carry.get("ci", 0)), pos, yaw, self)
	nv.locked = false
	nv.lock_dc = 0
	nv.stolen = false
	nv.hp = maxf(20.0, float(carry.get("hp", 100.0)))
	if bool(carry.get("owned", false)):
		nv.set_meta("owned", true)
	vehicles_root.add_child(nv)
	await get_tree().process_frame
	enter_vehicle(nv)
	if nv is Aircraft and by_air:
		var ac := nv as Aircraft
		ac.airborne = true
		ac.heading = float(carry.get("heading", yaw))
		var vmax := float(ac.spec.get("vmax", 66.0))
		ac.speed = clampf(float(carry.get("speed", vmax * 0.7)), float(ac.spec.get("stall", 22.0)) * 1.3, vmax)
		ac.throttle = float(carry.get("throttle", 0.7))
	hud.center(Regions.region_name(WorldLayout.region).to_upper(), 3.0)
	if nv is Aircraft and by_air:
		_atc_hello(str(GameState.flags.get("region_from", "")))


## The radio, when a plane crosses into the next map's airspace.
func _atc_hello(from: String) -> void:
	var lines := {
		"chicago": ["CHICAGO APPROACH", "Aircraft inbound from the east, Chicago Approach. Meigs Field is on the lakeshore, runway runs north-south. Winds off the lake, fifteen gusting twenty-five. Welcome to Chicago."],
		"highway": ["LENNOX TRAFFIC", "Lennox traffic, unidentified aircraft over the interstate... ah, nobody's listening on this frequency anyway. Follow I-80. " + ("Chicago's dead ahead." if from == "nyc" else "New York's dead ahead.")],
		"nyc": ["NEW YORK APPROACH", "Aircraft over the Bronx, New York Approach. Bowery Bay is on the Queens waterfront, east of you. Mind the towers. Welcome home."],
		"township": ["KEARNEY UNICOM", "Kearney traffic, this is Kearney Strip, which is me, Walt. Strip's on the west edge of town, runway north-south, nine hundred metres of it. Water tower's your landmark. Don't land on Main Street, we're having a festival."],
		"gary": ["GARY TOWER", "Aircraft over the lakeshore, Gary Tower, which is a very grand name for one woman with a radio. Runway's on the east side of town, north-south, past the truck depot. The furnaces are taller than they look. Welcome to Gary."],
		"island": ["PRICE ISLAND", "Unidentified aircraft, this is private airspace, owned by E Corp, and you are not on the list. Strip is on the west side, north-south. Please state your business. ...Hello? Is anyone up there?"],
		"redmont": ["MICROSLOP FIELD", "Aircraft over the reservoir, Microslop Field Unicom. Runway's on the east side of town, north-south, past the campus. Corporate traffic has priority. You are not corporate traffic. Welcome to Redmont, where your future is saved."],
		"port": ["RAMSEY UNICOM", "Aircraft over the county road, Ramsey Field. Runway's on the west side of town, north-south, wind off the water at ten. The cranes are tall and the lighthouse is taller. Welcome to Port Ramsey."],
	}
	var l: Array = lines.get(WorldLayout.region, [])
	if l.is_empty():
		return
	await get_tree().create_timer(2.5).timeout
	if is_inside_tree():
		hud.subtitle(str(l[0]), str(l[1]), 6.0)


# ------------------------------------------------------------ hidden masks
## Fifty fsociety masks, zip-tied to street corners across all six maps. Where
## they go is fixed per map (a seeded walk over the intersections), so the
## same mask is always on the same corner and saves remember which you took.
const MASKS_PER := {"nyc": 10, "highway": 5, "chicago": 8, "township": 7, "port": 7, "gary": 8, "redmont": 5, "island": 0}
const MASKS_TOTAL := 50


func hidden_mask_spots(region: String) -> Array:
	var out: Array = []
	var n := int(MASKS_PER.get(region, 0))
	var r := RandomNumberGenerator.new()
	r.seed = hash("fsociety_masks_" + region)
	var used := {}
	var tries := 0
	while out.size() < n and tries < 600:
		tries += 1
		var i := r.randi_range(0, WorldLayout.NA - 1)
		var j := r.randi_range(0, WorldLayout.NS - 1)
		var sx := 1.0 if r.randf() < 0.5 else -1.0
		var sz := 1.0 if r.randf() < 0.5 else -1.0
		if used.has(Vector2i(i, j)) or not WorldLayout.intersection_exists(i, j):
			continue
		var x := WorldLayout.ax(i) + sx * (WorldLayout.AVE_HW - 1.3)
		var z := WorldLayout.sz(j) + sz * (WorldLayout.ST_HW - 1.3)
		if not WorldLayout.in_bounds(x, z) or WorldLayout.district_at(x, z) in ["airfield", "park", "steel"]:
			continue
		used[Vector2i(i, j)] = true
		out.append({"id": "mask_%s_%d" % [region, out.size()], "pos": Vector3(x, 0.3, z)})
	return out


func _spawn_hidden_masks() -> void:
	for m in hidden_mask_spots(WorldLayout.region):
		var md: Dictionary = m
		spawn_dynamic_pickup(str(md["id"]), "hidden_mask", 1, md["pos"])


# ------------------------------------------------------------- talk radio
## E NEWS 24: with the phone's radio on the news station, an item every
## half minute or so: something you did if there's anything new, otherwise
## local traffic and weather, otherwise an ad (see RadioData).
var _radio_t := 6.0


func _radio_tick() -> void:
	if not AudioManager.radio_on() or AudioManager.radio_station != "news" or ui_open():
		_radio_t = minf(_radio_t, 6.0)
		return
	_radio_t -= 1.0
	if _radio_t > 0.0:
		return
	_radio_t = 32.0
	var fresh: Array = []
	var local: Array = []
	var filler: Array = []
	for i in RadioData.HEADLINES.size():
		var h: Dictionary = RadioData.HEADLINES[i]
		if h.has("region") and str(h["region"]) != WorldLayout.region:
			continue
		if h.has("when"):
			if not DialogueManager.check(str(h["when"])):
				continue
			if not GameState.flags.has("news:%d" % i):
				fresh.append(i)
		elif h.has("region"):
			local.append(i)
		else:
			filler.append(i)
	var pick := -1
	if not fresh.is_empty():
		pick = int(fresh[0])
		GameState.flags["news:%d" % pick] = true
	else:
		var pool: Array = local + local + filler
		if pool.is_empty():
			return
		pick = int(pool[randi() % pool.size()])
	hud.subtitle("E NEWS 24", str((RadioData.HEADLINES[pick] as Dictionary)["text"]), 7.0)


# -------------------------------------------------------------- body shops
## A body shop's painted bay: roll in with the heat on you and stop, and they
## respray the car so the cops lose you; roll in banged up and they fix it.
var _spray_asked := false


func _spray_tick() -> void:
	if GameState.cell != "world" or ui_open() or busy_transition:
		return
	var v: Vehicle = player.driving
	if v == null or v is Aircraft or not is_instance_valid(v):
		_spray_asked = false
		return
	var shop: Dictionary = {}
	for b in RegionContent.BODY_SHOPS.get(WorldLayout.region, []):
		var bp: Array = (b as Dictionary)["pos"]
		if Vector2(v.global_position.x - float(bp[0]), v.global_position.z - float(bp[1])).length() < 9.0:
			shop = b
	if shop.is_empty():
		_spray_asked = false
		return
	if _spray_asked or absf(v.speed) > 1.5:
		return
	var rafi := bool(shop.get("rafi", false))
	if not GameState.is_wanted() and (rafi or v.hp >= 90.0):
		return # Rafi's own offer handles the rest at his bay
	_spray_asked = true
	_spray_offer(v, shop)


func _spray_offer(v: Vehicle, shop: Dictionary) -> void:
	var wanted := GameState.is_wanted()
	var cost := 100 + 50 * GameState.heat if wanted else 60
	var who := "RAFI" if bool(shop.get("rafi", false)) else "MECHANIC"
	var t := "=== _spray\n-- start\n> %s. A roll-up door rattles open and a man in paint-spattered coveralls looks at the car, then at you.\n" % str(shop["name"]).capitalize()
	if wanted and _police_sees_player():
		t += "%s: With the cops RIGHT THERE? Are you crazy? Lose them first, then come back.\n-> END\n" % who
	elif wanted:
		t += "%s: Hot, huh. I can hear the sirens from here. New color, new plates, five minutes. They'll be looking for a car that doesn't exist.\n" % who
		t += "* [if cash>=%d] \"Do it. $%d.\" -> do\n" % [cost, cost]
		t += "* \"Not today.\" -> END\n"
		t += "-- do\n! set spray_pick\n%s: Pull in. Close your eyes. Don't breathe the fumes. ...There. Never seen this car in my life.\n-> END\n" % who
	else:
		t += "%s: You drove that here? Brave. Dents out, glass in, engine sorted. $%d.\n" % [who, cost]
		t += "* [if cash>=%d] \"Fix it.\" -> do\n" % cost
		t += "* \"It's fine.\" -> END\n"
		t += "-- do\n! set spray_pick\n%s: Good as new. Better, honestly. Don't tell anyone.\n-> END\n" % who
	DialogueManager.convos.erase("_spray")
	DialogueManager.parse_text(t, "runtime:spray")
	GameState.flags.erase("spray_pick")
	await dialog.run("_spray", null)
	if not GameState.flags.has("spray_pick") or player.driving != v:
		return
	GameState.flags.erase("spray_pick")
	GameState.add_cash(-cost)
	v.hp = 100.0
	if wanted:
		GameState.clear_wanted()
		v.stolen = false
		v.color_idx = (v.color_idx + 3) % Props.CAR_COLORS.size()
		var mm: Array = Props.car_meshes("car_%s_%d" % [v.kind, v.color_idx])
		var body: Variant = v.get("_mesh")
		if body is MeshInstance3D:
			(body as MeshInstance3D).mesh = mm[0]
		hud.center("RESPRAYED  ·  THE HEAT IS OFF", 3.0)
		GameState.stat_add("resprays")
	else:
		hud.center("REPAIRED", 2.0)
	AudioManager.play_success()


# ------------------------------------------------------------- quest rides
## The night freight (Night Freight): a box truck in the cannery yard after
## dark, waiting for a driver. Get in and the job is yours.
var _night_truck: Vehicle = null


func _update_quest_rides() -> void:
	if GameState.cell != "world" or vehicles_root == null:
		return
	var want := WorldLayout.region == "port" and GameState.quest_state("mq_pr2") == "active" and GameState.quest_stage("mq_pr2") == 10 and GameState.is_night()
	if want and (_night_truck == null or not is_instance_valid(_night_truck)):
		_night_truck = Vehicle.new().setup("truck", 0, Vector3(-232.0, 0.4, 424.0), PI * 0.5, self)
		_night_truck.locked = false
		_night_truck.lock_dc = 0
		_night_truck.set_meta("night_freight", true)
		vehicles_root.add_child(_night_truck)
	if _night_truck != null and is_instance_valid(_night_truck) and player.driving == _night_truck and GameState.quest_stage("mq_pr2") == 10:
		GameState.set_quest_stage("mq_pr2", 20)
		hud.subtitle("ELLIOT (V.O.)", "Keys in the visor. A clipboard on the seat: WTE — DOCK 3. Nobody in the yard to stop me, because I'm exactly who they're expecting. West to I-80, north to Exit 41, into the township.", 6.0)


# ------------------------------------------------------------------- rides
## Every car or plane you drive stays where you leave it. The four most recent
## stay put anywhere in the city; anything parked at home (outside your
## building, or at Bowery Bay for planes) or that you own stays forever.
const RIDES_LOOSE := 4
const HOMES := [
	{"name": "outside your building", "pos": Vector2(-466, 320), "r": 26.0, "plane": false, "region": "nyc"},
	{"name": "at the Bowery Bay hangars", "pos": Vector2(1420, -1250), "r": 150.0, "plane": true, "region": "nyc"},
	{"name": "on the apron at Kearney Strip", "pos": Vector2(-504, 0), "r": 90.0, "plane": true, "region": "township", "when": "flag.walt_plane_ok"},
]
var ride_nodes: Dictionary = {} # uid -> Vehicle


func _ride_in_slot(sid: String) -> bool:
	for r in GameState.rides:
		if str((r as Dictionary).get("slot", "")) == sid:
			return true
	return false


func _ride_rec(uid: int) -> Dictionary:
	for r in GameState.rides:
		if int((r as Dictionary).get("uid", -1)) == uid:
			return r
	return {}


func _remember_ride(v: Vehicle) -> void:
	if v == null or not is_instance_valid(v) or v.dead or GameState.cell != "world":
		return
	var uid := int(v.get_meta("ride_uid", -1))
	if uid < 0:
		uid = int(GameState.flags.get("ride_uid_next", 1))
		GameState.flags["ride_uid_next"] = uid + 1
		v.set_meta("ride_uid", uid)
	var plane := v is Aircraft
	var rec := _ride_rec(uid)
	var fresh := rec.is_empty()
	if fresh:
		rec = {"uid": uid}
		GameState.rides.append(rec)
	var p := v.global_position
	rec["region"] = WorldLayout.region
	rec["kind"] = "plane" if plane else "car"
	rec["model"] = (v as Aircraft).model if plane else v.kind
	rec["ci"] = v.color_idx
	rec["pos"] = [p.x, p.y, p.z]
	rec["yaw"] = v.rotation.y
	rec["hp"] = v.hp
	rec["owned"] = bool(rec.get("owned", false)) or v.has_meta("owned")
	if plane:
		var a := v as Aircraft
		if a.slot != "":
			rec["slot"] = a.slot
			planes.erase(a.slot)
			a.slot = ""
	var was_home := bool(rec.get("home", false))
	rec["home"] = false
	for h in HOMES:
		if str(h.get("region", "nyc")) != WorldLayout.region or (h.has("when") and not DialogueManager.check(str(h["when"]))):
			continue
		if bool(h["plane"]) == plane and Vector2(p.x, p.z).distance_to(h["pos"]) < float(h["r"]):
			rec["home"] = true
			if not was_home:
				hud.notify("Parked %s. It'll be right here whenever you want it." % str(h["name"]), "")
	ride_nodes[uid] = v
	v.locked = false
	parked_cars.erase(v)
	# Only the most recent loose rides are kept; older ones get towed.
	GameState.rides.erase(rec)
	GameState.rides.append(rec)
	var loose := 0
	for i in range(GameState.rides.size() - 1, -1, -1):
		var r: Dictionary = GameState.rides[i]
		if bool(r.get("home", false)) or bool(r.get("owned", false)):
			continue
		loose += 1
		if loose > RIDES_LOOSE:
			var old_uid := int(r.get("uid", -1))
			GameState.rides.remove_at(i)
			var on: Vehicle = ride_nodes.get(old_uid)
			ride_nodes.erase(old_uid)
			if on != null and is_instance_valid(on) and on != player.driving:
				on.remove_meta("ride_uid")
				if not (on is Aircraft):
					parked_cars.append(on) # back to being just a car on the street


## Spawn parked rides near you, park them away when you're far, forget wrecks.
func _update_rides() -> void:
	if GameState.cell != "world" or vehicles_root == null:
		return
	var pp := player.global_position
	for r in GameState.rides.duplicate():
		var rec: Dictionary = r
		if str(rec.get("region", "nyc")) != WorldLayout.region:
			continue
		var uid := int(rec.get("uid", -1))
		var v: Vehicle = ride_nodes.get(uid)
		if v != null and not is_instance_valid(v):
			ride_nodes.erase(uid)
			v = null
		if v != null:
			if v.dead:
				GameState.rides.erase(rec)
				ride_nodes.erase(uid)
				continue
			if v == player.driving:
				continue
			if v.global_position.distance_to(pp) > 1300.0:
				var vp := v.global_position
				rec["pos"] = [vp.x, vp.y, vp.z]
				rec["yaw"] = v.rotation.y
				rec["hp"] = v.hp
				v.queue_free()
				ride_nodes.erase(uid)
			continue
		var pa: Array = rec.get("pos", [0, 0, 0])
		var pos := Vector3(float(pa[0]), float(pa[1]), float(pa[2]))
		if pos.distance_to(pp) > 950.0:
			continue
		var nv: Vehicle
		if str(rec.get("kind", "car")) == "plane":
			var a := Aircraft.new().setup_plane(str(rec.get("model", "skyhawk")), pos, float(rec.get("yaw", 0.0)), self)
			a.owner_tag = "player"
			nv = a
		else:
			nv = Vehicle.new().setup(str(rec.get("model", "sedan")), int(rec.get("ci", 0)), pos + Vector3(0, 0.15, 0), float(rec.get("yaw", 0.0)), self)
		nv.locked = false
		nv.lock_dc = 0
		nv.stolen = false
		nv.hp = maxf(20.0, float(rec.get("hp", 100.0)))
		nv.set_meta("ride_uid", uid)
		if bool(rec.get("owned", false)):
			nv.set_meta("owned", true)
		vehicles_root.add_child(nv)
		ride_nodes[uid] = nv


const PARKED_MAX := 5 # plus every parked car the city itself draws (_steal_parked)
const PARK_KINDS := ["sedan", "sedan", "sedan", "hatch", "hatch", "suv", "van", "taxi"]


## Keep a handful of stealable cars parked on the curbs around the player, in
## parking-lane gaps between the city's static parked cars.
func _update_parked() -> void:
	if GameState.cell != "world" or player.driving != null and absf(player.driving.speed) > 20.0:
		return
	var pp := player.global_position
	for c in parked_cars.duplicate():
		var v: Vehicle = c
		if not is_instance_valid(v):
			parked_cars.erase(c)
			continue
		if v.has_meta("ride_uid"):
			parked_cars.erase(v) # yours now: the ride keeper looks after it
			continue
		if v != player_car and v.global_position.distance_to(pp) > 260.0:
			parked_cars.erase(v)
			v.queue_free()
	if player_car != null and is_instance_valid(player_car) and player.driving == null and player_car.global_position.distance_to(pp) > 600.0:
		if not player_car.has_meta("ride_uid"):
			player_car.queue_free()
		player_car = null
	var tries := 6
	while parked_cars.size() < PARKED_MAX and tries > 0:
		tries -= 1
		var spot := _parking_spot(pp)
		if spot.is_empty():
			continue
		var kind: String = PARK_KINDS[randi() % PARK_KINDS.size()]
		var v2 := Vehicle.new().setup(kind, randi() % Props.CAR_COLORS.size(), spot["pos"], float(spot["yaw"]), self)
		v2.lock_dc = [15, 20, 25, 30, 35, 40, 50, 60][randi() % 8]
		v2.locked = randf() > 0.07 # now and then somebody leaves the keys in it
		vehicles_root.add_child(v2)
		parked_cars.append(v2)


func _parking_spot(pp: Vector3) -> Dictionary:
	var pos := Vector3.ZERO
	var yaw := 0.0
	if randf() < 0.55:
		var i := clampi(int(round((pp.x - WorldLayout.AX0) / WorldLayout.AXS)) + randi_range(-1, 1), 0, WorldLayout.NA - 1)
		var j := clampi(int(floor((pp.z - WorldLayout.SZ0) / WorldLayout.SZS)) + randi_range(-2, 2), 0, WorldLayout.NS - 2)
		if not WorldLayout.avenue_segment_exists(i, j):
			return {}
		var side := 1.0 if randf() < 0.5 else -1.0
		pos = Vector3(WorldLayout.ax(i) + side * 5.2, 0.1, randf_range(WorldLayout.sz(j) + 14.0, WorldLayout.sz(j + 1) - 14.0))
		yaw = 0.0 if side > 0.0 else PI
	else:
		var j2 := clampi(int(round((pp.z - WorldLayout.SZ0) / WorldLayout.SZS)) + randi_range(-2, 2), 0, WorldLayout.NS - 1)
		var i2 := clampi(int(floor((pp.x - WorldLayout.AX0) / WorldLayout.AXS)) + randi_range(-1, 1), 0, WorldLayout.NA - 2)
		if not WorldLayout.street_segment_exists(j2, i2):
			return {}
		var side2 := 1.0 if randf() < 0.5 else -1.0
		pos = Vector3(randf_range(WorldLayout.ax(i2) + 14.0, WorldLayout.ax(i2 + 1) - 14.0), 0.1, WorldLayout.sz(j2) + side2 * 3.3)
		yaw = PI * 0.5 if side2 > 0.0 else -PI * 0.5
	var d := pos.distance_to(pp)
	if d < 35.0 or d > 200.0 or not WorldLayout.in_bounds(pos.x, pos.z):
		return {}
	# Not on top of the city's own parked cars or street furniture.
	if loot_index != null:
		for e in loot_index.near(pos, 4.2):
			var ep: Vector3 = (e as Dictionary)["p"]
			if Vector2(ep.x - pos.x, ep.z - pos.z).length() < 4.2:
				return {}
	for c in parked_cars:
		if is_instance_valid(c) and (c as Vehicle).global_position.distance_to(pos) < 7.0:
			return {}
	if player_car != null and is_instance_valid(player_car) and player_car.global_position.distance_to(pos) < 7.0:
		return {}
	# And not inside anything solid.
	var q := PhysicsShapeQueryParameters3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.2, 1.2, 4.8)
	q.shape = bs
	q.transform = Transform3D(Basis(Vector3.UP, yaw), pos + Vector3(0, 0.9, 0))
	q.collision_mask = Phys.WORLD | Phys.CAR
	if not get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty():
		return {}
	return {"pos": pos, "yaw": yaw}
