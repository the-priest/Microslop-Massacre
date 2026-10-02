class_name IntroCinematic
extends Node
## New Game cold open, New Vegas style: a narrated flyover of the live city
## that tells the story of this world up to tonight, before Krista's office.
## ENTER / click = next line, SPACE / ESC = skip the whole intro.

# Each shot: camera "from"/"to" positions and "look_from"/"look_to" targets
# (world space), a location stamp, an optional hour of day, and narration.
# "black" shots have no camera, just text on black.
const SHOTS := [
	{"black": true, "lines": [
		"Hello, friend.",
		"Every story in this city begins the same way. With a number.",
	]},
	{"stamp": "NEW YORK", "hour": 17.5,
		"from": [-240.0, 150.0, 980.0], "to": [120.0, 260.0, 560.0],
		"look_from": [60.0, 60.0, -200.0], "look_to": [40.0, 110.0, -320.0],
		"lines": [
			"Eight million people live here. Every one of them is a number somewhere. A credit score. A balance. A risk.",
			"Most of them will never meet the people who keep those numbers. They just pay them. Every month. For the rest of their lives.",
		]},
	{"stamp": "E CORP  ·  WORLD HEADQUARTERS", "hour": 17.8,
		"from": [230.0, 120.0, -60.0], "to": [90.0, 250.0, -470.0],
		"look_from": [-65.0, 150.0, -284.0], "look_to": [-65.0, 200.0, -284.0],
		"lines": [
			"The people who keep the numbers have a name. E Corp. They make the phone in your pocket, the bank inside the phone, and the loan you took out to buy both.",
			"People call them Evil Corp. Quietly. Never on the phone.",
		]},
	{"stamp": "WASHINGTON TOWNSHIP, NEW JERSEY  ·  1993", "hour": 18.2,
		"from": [-980.0, 30.0, -120.0], "to": [-900.0, 70.0, -430.0],
		"look_from": [-720.0, 8.0, -287.0], "look_to": [-700.0, 14.0, -300.0],
		"lines": [
			"Twenty-two years ago, across the river, an E Corp plant leaked something into the ground. People got sick. Some of them died.",
			"There was a settlement. The files were sealed. The man who signed them got a corner office. Nobody went to prison. Nobody ever does.",
		]},
	{"stamp": "THE TOWNSHIP MEMORIAL", "hour": 18.4,
		"from": [-162.0, 3.2, 172.0], "to": [-150.0, 2.0, 157.0],
		"look_from": [-150.0, 2.0, 150.0], "look_to": [-150.0, 1.4, 150.0],
		"lines": [
			"One of the names on this stone is Edward Alderson. He fixed computers. He had a little shop out by the ocean, and a son who never left his side at the hospital.",
			"The boy was eight. He grew up remembering almost nothing about that year. That should have worried somebody.",
		]},
	{"stamp": "ALLSAFE CYBERSECURITY  ·  MIDTOWN", "hour": 18.6,
		"from": [-230.0, 20.0, -90.0], "to": [-270.0, 70.0, -120.0],
		"look_from": [-330.0, 30.0, -190.0], "look_to": [-330.0, 50.0, -190.0],
		"lines": [
			"His name is Elliot. Today he protects E Corp's servers for a living, from a glass office in Midtown, for a firm called Allsafe.",
			"He is very good at it. He can find out who anyone really is in about ten minutes. He has never once managed to do it to himself.",
		]},
	{"stamp": "LOWER EAST SIDE  ·  NIGHT", "hour": 23.2,
		"from": [-610.0, 2.2, 320.0], "to": [-520.0, 2.4, 320.0],
		"look_from": [-420.0, 3.0, 320.0], "look_to": [-400.0, 4.0, 322.0],
		"lines": [
			"At night, he reads people. Their email. Their messages. The things they delete. He doesn't steal. He doesn't sell. He just knows.",
			"Some nights, what he knows is enough to put a man in prison. He makes sure it does. Nobody ever finds out who sent the files.",
		]},
	{"stamp": "CONEY ISLAND", "hour": 19.0,
		"from": [-60.0, 40.0, 800.0], "to": [-170.0, 14.0, 712.0],
		"look_from": [-170.0, 4.0, 660.0], "look_to": [-170.0, 6.0, 660.0],
		"lines": [
			"Lately, someone has started talking back to E Corp. A cartoon mask. A voice run through a filter. A name sprayed across the walls of the subway.",
			"fsociety. Nobody knows who they are. Nobody knows what they want. That is what keeps the men in the tower awake at night.",
		]},
	{"stamp": "CHINATOWN", "hour": 22.4,
		"from": [530.0, 40.0, 500.0], "to": [470.0, 9.0, 445.0],
		"look_from": [450.0, 6.0, 410.0], "look_to": [450.0, 4.0, 408.0],
		"lines": [
			"And behind a tea house, in a room full of clocks that never agree, someone else has been waiting, very patiently, for all of this to begin.",
		]},
	{"stamp": "TONIGHT", "hour": 18.7,
		"from": [-372.0, 2.2, 320.0], "to": [-330.0, 150.0, 190.0],
		"look_from": [-339.0, 4.0, 312.0], "look_to": [-200.0, 120.0, -100.0],
		"lines": [
			"Tonight Elliot will sit in his therapist's office and tell her he's fine. He'll go home and find something on his computer that wasn't there this morning.",
			"And a man in an old field jacket, who knows his name and a great deal more, will finally decide that it's time they met.",
		]},
	{"black": true, "lines": [
		"There are a lot of ways this story can end. A few of them are kind. Most of them are not. Every one of them is his to choose.",
		"Well. His, and yours.",
		"Let's begin.",
	]},
]

## Narration: one clip per line, in order across all shots (audio/voice/intro_NN.ogg).
const VOICE := "res://audio/voice/intro_%02d.ogg"

const TYPE_CPS := 48.0
const LINE_GAP := 0.45

var _voice: AudioStreamPlayer
var _line_i := 0

var game: Node
var cam: Camera3D
var _layer: CanvasLayer
var _fade: ColorRect
var _text: Label
var _stamp: Label
var _hint: Label
var _skip := false
var _next := false
var _cur: Dictionary = {}
var _shot_t := 0.0
var _shot_dur := 1.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Estimated reading time of one line (seconds) when there is no voice clip.
static func line_time(s: String) -> float:
	return float(s.length()) / TYPE_CPS + 1.6 + float(s.length()) / 30.0


## Narrator clip for global line `i` (null if the file is missing).
static func clip(i: int) -> AudioStream:
	var p := VOICE % i
	if not ResourceLoader.exists(p):
		return null
	return load(p) as AudioStream


## How long line `i` stays up: the clip plus a breath, or the reading time.
static func line_dur(i: int, s: String) -> float:
	var c := clip(i)
	if c != null and c.get_length() > 0.1:
		return c.get_length() + LINE_GAP
	return line_time(s)


## Index of the first narration line of shot `n`.
static func first_line(n: int) -> int:
	var k := 0
	for j in mini(n, SHOTS.size()):
		k += (SHOTS[j]["lines"] as Array).size()
	return k


static func shot_duration(shot: Dictionary, first: int = -1) -> float:
	if first < 0:
		first = first_line(SHOTS.find(shot))
	var d := 0.6
	var i := first
	for l in shot["lines"]:
		d += line_dur(i, str(l))
		i += 1
	return d


func run(g: Node) -> void:
	game = g
	_build_ui()
	cam = Camera3D.new()
	cam.name = "IntroCam"
	cam.near = 0.1
	cam.far = 3400.0
	cam.fov = 60.0
	game.add_child(cam)
	_voice = AudioStreamPlayer.new()
	_voice.bus = "Voice" if AudioServer.get_bus_index("Voice") >= 0 else "Master"
	add_child(_voice)
	AudioManager.duck(true)
	_line_i = 0
	for shot in SHOTS:
		if _skip:
			break
		await _play(shot)
	_voice.stop()
	AudioManager.duck(false)
	# Stop steering the camera (and the player) before the game takes over.
	_cur = {}
	if _fade_tw != null and _fade_tw.is_valid():
		_fade_tw.kill()
	_fade.color.a = 1.0
	_text.text = ""
	_stamp.text = ""


## Called by the game once the first real scene is ready under the black.
func reveal() -> void:
	if cam != null:
		cam.queue_free()
	_text.text = ""
	_hint.visible = false
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 1.2)
	await tw.finished
	queue_free()


func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 90
	add_child(_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(root)
	# Letterbox.
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0, 0, 0, 1)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.anchor_left = 0.0
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 0.87
		bar.anchor_bottom = 0.1 if top else 1.0
		root.add_child(bar)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade)
	_stamp = UI.label("", 16, UI.GREEN)
	_stamp.anchor_left = 0.0
	_stamp.anchor_top = 0.1
	_stamp.offset_left = 40
	_stamp.offset_top = 18
	_stamp.size = Vector2(800, 30)
	root.add_child(_stamp)
	_text = UI.label("", 24, Color(0.92, 0.94, 0.9))
	_text.anchor_left = 0.12
	_text.anchor_right = 0.88
	_text.anchor_top = 0.66
	_text.anchor_bottom = 0.86
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_text.add_theme_constant_override("shadow_offset_x", 2)
	_text.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(_text)
	_hint = UI.label("[A] next    [START] skip intro" if Pad.using_pad or not Input.get_connected_joypads().is_empty() else "[ENTER] next    [SPACE] skip intro", 13, UI.GREEN_DIM)
	_hint.anchor_left = 1.0
	_hint.anchor_right = 1.0
	_hint.anchor_top = 0.87
	_hint.offset_left = -300
	_hint.offset_top = 22
	_hint.size = Vector2(280, 20)
	root.add_child(_hint)


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		if event.is_pressed() and not event.is_echo():
			var k := event as InputEventKey
			var jb := event as InputEventJoypadButton
			if jb != null and jb.button_index in [JOY_BUTTON_START, JOY_BUTTON_B, JOY_BUTTON_Y]:
				_skip = true
			elif k != null and k.keycode in [KEY_SPACE, KEY_ESCAPE]:
				_skip = true
			elif k == null or k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E]:
				_next = true
		get_viewport().set_input_as_handled()


## Place the camera for shot `shot` at normalized time t (0..1). Used by the
## screenshot harness too.
func pose(shot: Dictionary, t: float) -> void:
	if shot.get("black", false) or cam == null:
		return
	var e := t * t * (3.0 - 2.0 * t)
	var a := _v(shot["from"]).lerp(_v(shot["to"]), e)
	var la := _v(shot["look_from"]).lerp(_v(shot["look_to"]), e)
	cam.global_position = a
	if a.distance_to(la) > 0.01:
		cam.look_at(la, Vector3.UP)
	if game != null and game.player != null:
		# Stream the city (crowds, traffic, NPCs) around the camera.
		game.player.global_position = Vector3(a.x, 0.1, a.z) if WorldLayout.in_bounds(a.x, a.z) else game.player.global_position


static func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func _play(shot: Dictionary) -> void:
	var black: bool = shot.get("black", false)
	_cur = shot
	_shot_t = 0.0
	_shot_dur = shot_duration(shot, _line_i)
	_stamp.text = ""
	_text.text = ""
	if shot.has("hour"):
		GameState.game_minutes = GameState.day() * 1440.0 + float(shot["hour"]) * 60.0
	if not black:
		cam.make_current()
		pose(shot, 0.0)
		await _wait(0.05)
		_fade_to(0.0, 0.9)
	else:
		_fade_to(1.0, 0.6)
	_stamp.text = str(shot.get("stamp", ""))
	_stamp.visible_ratio = 0.0
	var tw := create_tween()
	tw.tween_property(_stamp, "visible_ratio", 1.0, 0.8)
	await _wait(0.6)
	for l in shot["lines"]:
		if _skip:
			return
		var s := str(l)
		_text.text = s
		_text.visible_characters = 0
		var tt := 0.0
		var c := clip(_line_i)
		_line_i += 1
		var tot := line_time(s)
		# Type the line out in step with the narrator, finishing a little
		# before he does, then hold for a breath.
		var cps := TYPE_CPS
		if c != null and c.get_length() > 0.1:
			tot = c.get_length() + LINE_GAP
			cps = maxf(12.0, float(s.length()) / maxf(0.5, c.get_length() * 0.82))
			_voice.stream = c
			_voice.play()
		_next = false
		while tt < tot and not _skip and not _next:
			var d := get_process_delta_time()
			tt += d
			_text.visible_characters = mini(s.length(), int(tt * cps))
			await get_tree().process_frame
		_voice.stop()
		_text.visible_characters = -1
	if not black and not _skip:
		_fade_to(1.0, 0.7)
		await _wait(0.7)


func _process(delta: float) -> void:
	if _cur.is_empty() or _cur.get("black", false):
		return
	_shot_t += delta
	pose(_cur, clampf(_shot_t / (_shot_dur + 0.7), 0.0, 1.0))


var _fade_tw: Tween = null


func _fade_to(a: float, dur: float) -> void:
	if _fade_tw != null and _fade_tw.is_valid():
		_fade_tw.kill()
	_fade_tw = create_tween()
	_fade_tw.tween_property(_fade, "color:a", a, dur)


func _wait(s: float) -> void:
	var t := 0.0
	while t < s and not _skip:
		t += get_process_delta_time()
		await get_tree().process_frame
