class_name Races
extends Node3D
## Street races: a loop of street corners, a loaner from the organiser, a
## rival driving the same pursuit AI the cruisers use (aimed at checkpoints
## instead of you), a countdown, laps, and money on the line.

## One loop per map, each run by somebody local. Corners in order; the last
## one is the start/finish line. yaw points the cars at the first corner.
const RACES := {
	"hunts": {
		"name": "Hunts Point Loop", "region": "nyc", "host": "DEZ", "laps": 2, "bet": 200, "xp": 80,
		"points": [[1040, -1040], [1170, -1040], [1170, -1280], [1040, -1280], [1040, -1100]],
		"start": [1040, -1118], "yaw": 0.0,
		"go": "Two laps. Corners are marked. Hit every one or it doesn't count. Lights... in three.",
		"win": "Okay. Okay! Somebody finally drove like they meant it. Money's yours. Keep the car tonight; bring it back never.",
		"lose": "Dez's driver crosses the line first. The bet's gone.",
	},
	"lakeshore": {
		"name": "Lakeshore Loop", "region": "chicago", "host": "TASHA", "laps": 2, "bet": 250, "xp": 90,
		"points": [[260, -130], [500, -130], [500, 250], [260, 250], [260, 190]],
		"start": [260, 205], "yaw": 0.0,
		"go": "Up to Grand, right to the lake, down past the field, back on Jackson. Twice. Don't hit a tourist.",
		"win": "Man. MAN. You drive like a Chicago winter: no mercy. Take the money before I change my mind.",
		"lose": "Tasha's cousin takes the flag on the lakefront and doesn't even look back.",
	},
	"interstate": {
		"name": "Interstate Loop", "region": "highway", "host": "BOBBY RAY", "laps": 1, "bet": 150, "xp": 90,
		"points": [[0, -300], [300, -300], [300, 600], [0, 600], [0, 560]],
		"start": [0, 575], "yaw": 0.0,
		"go": "North up the big road, cut across the farm road, come back down the county road. One lap. That's three kilometres, city kid. Don't fall asleep.",
		"win": "Well I'll be. Ain't nobody beat my nephew on that loop since the corn was knee high. Here.",
		"lose": "Bobby Ray's nephew blows past the diner with his horn going. Bet's his.",
	},
	"mainstreet": {
		"name": "Main Street Loop", "region": "township", "host": "THE PELL TWINS", "laps": 3, "bet": 100, "xp": 70,
		"points": [[-150, -125], [150, -125], [150, 125], [-150, 125], [-150, 50]],
		"start": [-150, 65], "yaw": 0.0,
		"go": "Three laps round the square. Up First, across Elm, down Third, back on Walnut. Sheriff's asleep. Probably.",
		"win": "You beat Danny! Nobody beats Danny! ...Danny's going to cry. Here's your money.",
		"lose": "The other Pell twin takes the last corner on two wheels and screams all the way to the line.",
	},
	"quay": {
		"name": "Quay Run", "region": "port", "host": "BOBBY MAC", "laps": 2, "bet": 200, "xp": 85,
		"points": [[160, -300], [640, -300], [640, 150], [160, 150], [160, 90]],
		"start": [160, 105], "yaw": 0.0,
		"go": "Up Whaler, out to the quay, down past the ship, back on Harbor. Twice. Mind the cranes, they don't stop for nobody.",
		"win": "Ha! Forty years on the water and I never seen anybody take the quay corner like that. Drinks are on you. Kidding. Money's yours.",
		"lose": "Bobby Mac's grandson takes the quay corner flat out and wins by a boat length.",
	},
	"broadway": {
		"name": "Broadway Drag", "region": "gary", "host": "JAMAL", "laps": 2, "bet": 200, "xp": 85,
		"points": [[-140, 0], [280, 0], [280, 360], [-140, 360], [-140, 290]],
		"start": [-140, 305], "yaw": 0.0,
		"go": "Up Broadway, right on Fifteenth, down Grant, back on Twenty-Fifth. Twice. I drive trucks from a chair all day. Tonight I drive.",
		"win": "First time all week anybody beat me at anything. Feels kind of good, honestly. Here.",
		"lose": "Jamal crosses the line with both hands off the wheel, laughing. Sixteen hours of remote driving, and he can still really drive.",
	},
	"campus": {
		"name": "Campus Loop", "region": "redmont", "host": "KAI", "laps": 2, "bet": 150, "xp": 80,
		"points": [[0, -360], [280, -360], [280, 120], [0, 120], [0, 90]],
		"start": [0, 105], "yaw": 0.0,
		"go": "Up Route 9 past HQ, right on Synergy, down Synergy Ave past the studio, back on Second. Twice. The drones are for 'safety.' Wave.",
		"win": "You beat the intern car with the self turned off! I'm putting this in my review. 'Lost to an external benchmark, learned a lot.' Here.",
		"lose": "Kai takes the last corner with the self turned off and the screen flashing PLEASE RETURN TO CAMPUS, screaming the whole way.",
	},
}
const CP_RADIUS := 14.0

var game: Node = null
var active: String = ""
var def: Dictionary = {}
var cp: int = 0
var lap: int = 0
var rival: Vehicle = null
var rival_cp: int = 0
var rival_lap: int = 0
var car: Vehicle = null
var countdown: float = 0.0
var _rival_mark: Node3D
var _column: MeshInstance3D
var _last_count: int = -1
var _armed := false # false until you're actually sitting in the loaner


func is_racing() -> bool:
	return active != ""


func start(id: String) -> void:
	if active != "" or not RACES.has(id) or game == null:
		return
	if str((RACES[id] as Dictionary).get("region", "nyc")) != WorldLayout.region:
		return
	def = RACES[id]
	if GameState.cash < int(def["bet"]):
		game.hud.notify("You need $%d to race." % int(def["bet"]), "warn")
		return
	GameState.add_cash(-int(def["bet"]))
	active = id
	_armed = false
	cp = 0
	lap = 0
	rival_cp = 0
	rival_lap = 0
	var s: Array = def["start"]
	var yaw := float(def["yaw"])
	var side := Vector3(cos(yaw), 0, -sin(yaw))
	var base := Vector3(float(s[0]), 0.3, float(s[1]))
	if game.player.driving != null:
		game.exit_vehicle(true)
	car = Vehicle.new().setup("sedan", 4, base - side * 2.6, yaw, game)
	car.locked = false
	car.lock_dc = 0
	car.set_meta("race_loaner", true)
	game.vehicles_root.add_child(car)
	rival = Vehicle.new().setup("hatch", 6, base + side * 2.6, yaw, game)
	rival.locked = true
	rival.lock_dc = 90
	rival.ai_race = true
	rival.ai_speed_mul = 0.9
	game.vehicles_root.add_child(rival)
	_rival_mark = Node3D.new()
	add_child(_rival_mark)
	await get_tree().process_frame
	game.enter_vehicle(car)
	_armed = true
	countdown = 3.5
	_last_count = -1
	_show_column()
	game.hud.subtitle(str(def["host"]), str(def["go"]), 3.5)


func _physics_process(delta: float) -> void:
	if active == "" or not _armed:
		return
	if not is_instance_valid(car) or car.dead or game.player.driving != car or GameState.cell != "world":
		_finish(false, "You bailed. The bet stays with %s." % str(def["host"]).capitalize())
		return
	var pts: Array = def["points"]
	if countdown > 0.0:
		countdown -= delta
		car.speed = 0.0
		rival.speed = 0.0
		rival.ai_target = null
		var n := int(ceil(countdown - 0.5))
		if n != _last_count:
			_last_count = n
			game.hud.center("GO!" if n <= 0 else str(n), 0.9)
			AudioManager.play_key()
		if countdown <= 0.0:
			_aim_rival()
		return
	# You.
	var p := car.global_position
	var target: Array = pts[cp]
	if Vector2(p.x - float(target[0]), p.z - float(target[1])).length() < CP_RADIUS:
		cp += 1
		AudioManager.play_success()
		if cp >= pts.size():
			cp = 0
			lap += 1
			if lap >= int(def["laps"]):
				_finish(true, "")
				return
			game.hud.center("LAP %d / %d" % [lap + 1, int(def["laps"])], 1.5)
		else:
			game.hud.center("%d / %d" % [cp, pts.size()], 0.8)
		_show_column()
	# The rival.
	if is_instance_valid(rival) and not rival.dead:
		var rt: Array = pts[rival_cp]
		if Vector2(rival.global_position.x - float(rt[0]), rival.global_position.z - float(rt[1])).length() < CP_RADIUS:
			rival_cp += 1
			if rival_cp >= pts.size():
				rival_cp = 0
				rival_lap += 1
				if rival_lap >= int(def["laps"]):
					_finish(false, str(def["lose"]))
					return
			_aim_rival()
	# Too far off the course: forfeit. "Too far" is the length of this leg
	# (from the last corner, or the start line) plus a few blocks of slack.
	var prev: Array = pts[cp - 1] if cp > 0 else (def["start"] if lap == 0 else pts[pts.size() - 1])
	var leg := Vector2(float(prev[0]) - float(target[0]), float(prev[1]) - float(target[1])).length()
	if Vector2(p.x - float(target[0]), p.z - float(target[1])).length() > leg + 300.0:
		_finish(false, "Wrong way, too far. %s keeps the money." % str(def["host"]).capitalize())


func _aim_rival() -> void:
	var pts: Array = def["points"]
	var t: Array = pts[rival_cp]
	_rival_mark.global_position = Vector3(float(t[0]), 0, float(t[1]))
	rival.ai_target = _rival_mark


## A tall amber column on the next corner you have to hit.
func _show_column() -> void:
	if _column != null:
		_column.queue_free()
	var pts: Array = def["points"]
	var t: Array = pts[cp]
	var mb := MeshBatch.new()
	mb.box(Vector3(float(t[0]), 15.0, float(t[1])), Vector3(1.6, 30.0, 1.6), Color(1.0, 0.7, 0.15))
	mb.flat(Vector3(float(t[0]), 0.06, float(t[1])), CP_RADIUS * 1.6, CP_RADIUS * 1.6, Color(1.0, 0.6, 0.1))
	_column = mb.commit(self, Mats.glow, 0.0, "RaceMark")


func _finish(won: bool, why: String) -> void:
	var id := active
	active = ""
	_armed = false
	if _column != null:
		_column.queue_free()
		_column = null
	if is_instance_valid(rival):
		rival.ai_target = null
		rival.speed = 0.0
	if won:
		var pot := int(def["bet"]) * 2
		GameState.add_cash(pot)
		GameState.add_xp(int(def["xp"]))
		GameState.add_fame("locals", 2)
		GameState.set_flag("race_won_" + id)
		GameState.add_flag("races_won", 1)
		game.hud.center("YOU WIN  +$%d" % pot, 3.0)
		game.hud.subtitle(str(def["host"]), str(def["win"]), 5.0)
		AudioManager.play_levelup()
	else:
		game.hud.center("YOU LOSE", 2.5)
		if why != "":
			game.hud.subtitle(str(def["host"]), why, 4.0)
	# The rival drives off into the night.
	if is_instance_valid(rival):
		# The timer lives on the rival, so a map change that frees it frees this too.
		var r := rival
		var t := Timer.new()
		t.wait_time = 20.0
		t.one_shot = true
		t.autostart = true
		r.add_child(t)
		t.timeout.connect(func() -> void:
			if not r.driving:
				r.queue_free())
	rival = null
