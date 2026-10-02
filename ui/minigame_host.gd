class_name MinigameHost
extends CanvasLayer
## Runs a minigame as a modal overlay with the world paused.
## Names: lockpick, exploit (shell puzzle), recon (network path), bruteforce,
## signal, cascade, invaders, loghunt.

const SCRIPTS := {
	"lockpick": "res://minigames/lockpick.gd",
	"exploit": "res://minigames/terminal_exploit.gd",
	"recon": "res://minigames/network_recon.gd",
	"bruteforce": "res://minigames/brute_force.gd",
	"signal": "res://minigames/signal_tap.gd",
	"cascade": "res://minigames/cascade_sequence.gd",
	"invaders": "res://minigames/invader_game.gd",
	"loghunt": "res://minigames/log_hunt.gd",
}

var game: Node = null
var _active: Control = null
var auto_result: int = -1 # tests: 1 win, 0 lose, -1 play for real


func _init() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_running() -> bool:
	return _active != null


## ESC (or B on a pad) walks away from any minigame: a loss, never a trap.
func _unhandled_input(event: InputEvent) -> void:
	if _active == null or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if (event as InputEventKey).physical_keycode == KEY_ESCAPE or (event as InputEventKey).keycode == KEY_ESCAPE:
		if _active.has_method("_finish"):
			_active.call("_finish", false)
			get_viewport().set_input_as_handled()


func run(name: String, params: Dictionary = {}) -> bool:
	if _active != null:
		return false
	if auto_result >= 0:
		return auto_result == 1
	var path := str(SCRIPTS.get(name, ""))
	if path == "":
		push_warning("unknown minigame " + name)
		return true
	var script: Script = load(path)
	var mg: Control = script.new()
	mg.theme = UI.theme()
	# Parameters.
	var arg := str(params.get("arg", ""))
	match name:
		"lockpick":
			mg.set("dc", int(params.get("dc", 25)))
		"exploit":
			if params.has("host"):
				mg.set("target_host", str(params["host"]))
			if params.has("code"):
				mg.set("hidden_code", str(params["code"]))
			elif arg != "":
				var hosts := {
					"ron": ["rons-coffee.net", "cold-brew-1979"],
					"vera": ["pier9-ledger.io", "calle-sin-salida"],
					"ecorp": ["corp.e-corp.com", "tyrell-cto-2015"],
					"steel": ["climate.steelmtn.local", "hvac-maint-7"],
					"fbi": ["cjis.fbi.gov", "femto-3190"],
					"lenny": ["mail.shannon-home.net", "flipper-good-girl"],
					"allsafe": ["cs30.allsafe.lan", "honeypot-dont-touch"],
					"deus": ["salina-events.priv", "gathering-of-six"],
					"gus": ["finance.e-corp.com", "lot-1027-b"],
				}
				var hc: Array = hosts.get(arg, ["target.lan", "open-sesame"])
				mg.set("target_host", str(hc[0]))
				mg.set("hidden_code", str(hc[1]))
			if int(params.get("dc", 0)) > 0:
				mg.set("time_limit", clampf(140.0 - float(int(params["dc"])), 45.0, 140.0) + float(GameState.skill("hacking")) * 0.6)
		"bruteforce":
			var words := {"ron": ["ronccino", "his favorite word. it's on the menu."], "lenny": ["flipper", "his dog's name. he posts her every morning."], "tyrell": ["joanna", "the only person he's afraid of."], "gideon": ["brooklyn", "where he grew up. it's in every bio he writes."], "vera": ["shayla", "the name of his leverage."], "angela": ["washington", "the town that took her mother."]}
			if words.has(arg):
				mg.set("target_word", str(words[arg][0]))
				mg.set("hint_text", str(words[arg][1]))
		"loghunt":
			if arg != "":
				mg.set("case_id", arg)
	_active = mg
	add_child(mg)
	if game != null:
		game.push_ui()
	var ok: bool = await mg.finished
	if is_instance_valid(mg):
		mg.queue_free()
	_active = null
	if game != null:
		game.pop_ui()
	return ok
