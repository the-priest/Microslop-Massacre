class_name Races
extends Node3D
## Street races: a loop of street corners, a loaner from the organiser, a
## rival driving the same pursuit AI the cruisers use (aimed at checkpoints
## instead of you), a countdown, laps, and money on the line.

const RACES := {
	"hunts": {
		"name": "Hunts Point Loop", "laps": 2, "bet": 200, "xp": 80,
		# Corners in order; the last one is the start/finish line.
		"points": [[1040, -1040], [1170, -1040], [1170, -1280], [1040, -1280], [1040, -1100]],
		"start": [1040, -1118], "yaw": 0.0,
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


func is_racing() -> bool:
	return active != ""


func start(id: String) -> void:
	if active != "" or not RACES.has(id) or game == null:
		return
	def = RACES[id]
	if GameState.cash < int(def["bet"]):
		game.hud.notify("You need $%d to race." % int(def["bet"]), "warn")
		return
	GameState.add_cash(-int(def["bet"]))
	active = id
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
	countdown = 3.5
	_last_count = -1
	_show_column()
	game.hud.subtitle("DEZ", "Two laps. Corners are marked. Hit every one or it doesn't count. Lights... in three.", 3.5)


func _physics_process(delta: float) -> void:
	if active == "":
		return
	if not is_instance_valid(car) or car.dead or game.player.driving != car or GameState.cell != "world":
		_finish(false, "You bailed. The bet stays with Dez.")
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
					_finish(false, "Dez's driver crosses the line first. The bet's gone.")
					return
			_aim_rival()
	# Too far off the course: forfeit.
	if Vector2(p.x - float(target[0]), p.z - float(target[1])).length() > 450.0:
		_finish(false, "Wrong way, too far. Dez keeps the money.")


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
		game.hud.subtitle("DEZ", "Okay. Okay! Somebody finally drove like they meant it. Money's yours. Keep the car tonight; bring it back never.", 5.0)
		AudioManager.play_levelup()
	else:
		game.hud.center("YOU LOSE", 2.5)
		if why != "":
			game.hud.subtitle("DEZ", why, 4.0)
	# The rival drives off into the night.
	if is_instance_valid(rival):
		var r := rival
		get_tree().create_timer(20.0).timeout.connect(func() -> void:
			if is_instance_valid(r) and not r.driving:
				r.queue_free())
	rival = null
