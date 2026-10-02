extends Node
## Pad — full gamepad support (Xbox / PlayStation / Steam Deck layout), Fallout
## style. The left stick is bound to the move actions and the right stick is
## read by the player and car; every button is translated into the key or
## mouse event the game already understands, chosen by context:
##
##   ON FOOT        A interact · B phone (Pip-Boy) · X reload · Y jump
##                  RT fire · LT aim · LB EXPLOIT · RB heal · L3 sprint · R3 crouch
##                  D-pad: up light · down wait · left/right weapons
##                  START pause · BACK map
##   DRIVING        RT gas · LT brake/reverse · left stick steer · X handbrake
##                  LB horn · A get out · B phone
##   MENUS          stick / D-pad move · A select · B back · X take all
##                  LB / RB switch tabs · START close
##
## Synthetic events are ordinary key / mouse events (so every ui_* action and
## Button reacts to them), tagged with the "pad" meta so they never flip
## "using_pad" back off.

signal device_changed(pad: bool)

const DEAD := 0.18
const STICK_NAV := 0.55

var using_pad: bool = false
var device: int = 0
var fake: bool = false # tests: pretend a pad is plugged in

var _held: Dictionary = {} # joy button -> Array of synthetic events to release
var _dir: Dictionary = {"up": false, "down": false, "left": false, "right": false}
var _dir_t: Dictionary = {"up": 0.0, "down": 0.0, "left": 0.0, "right": 0.0}
var _rt: bool = false
var _lt: bool = false
var _focus_t: float = 0.0
## D-pad held state from the button events themselves (not polled), so menu
## navigation works whichever device id the pad turned up as.
var _dpad: Dictionary = {JOY_BUTTON_DPAD_UP: false, JOY_BUTTON_DPAD_DOWN: false, JOY_BUTTON_DPAD_LEFT: false, JOY_BUTTON_DPAD_RIGHT: false}
var _last_ctx: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Left stick walks and steers (analog: a light push walks, a full push runs).
	var binds := [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0], ["move_forward", JOY_AXIS_LEFT_Y, -1.0], ["move_back", JOY_AXIS_LEFT_Y, 1.0]]
	for b in binds:
		if not InputMap.has_action(str(b[0])):
			continue
		var ev := InputEventJoypadMotion.new()
		ev.device = -1
		ev.axis = int(b[1])
		ev.axis_value = float(b[2])
		InputMap.action_add_event(str(b[0]), ev)
		InputMap.action_set_deadzone(str(b[0]), 0.2)
	# The engine's own joypad UI bindings would fire alongside ours: drop them.
	for a in InputMap.get_actions():
		if not str(a).begins_with("ui_"):
			continue
		for ev2 in InputMap.action_get_events(a):
			if ev2 is InputEventJoypadButton or ev2 is InputEventJoypadMotion:
				InputMap.action_erase_event(a, ev2)
	device = _pick_device()
	Input.joy_connection_changed.connect(func(_d: int, _c: bool) -> void:
		if not Input.get_connected_joypads().has(device) or _is_junk(device):
			device = _pick_device())


## The controller to read sticks from. A PlayStation pad on Linux also shows up
## as a "Motion Sensors" joypad that never stops talking; never pick that one.
func _pick_device() -> int:
	var pads := Input.get_connected_joypads()
	for p in pads:
		if Input.is_joy_known(int(p)) and not _is_junk(int(p)):
			return int(p)
	for p in pads:
		if not _is_junk(int(p)):
			return int(p)
	return int(pads[0]) if not pads.is_empty() else 0


static func _is_junk(d: int) -> bool:
	var n := Input.get_joy_name(d).to_lower()
	return n.contains("motion") or n.contains("sensor") or n.contains("accelerometer") or n.contains("gyro") or n.contains("touchpad")


func _input(event: InputEvent) -> void:
	if event.has_meta("pad"):
		return
	if event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if _is_junk(jb.device):
			get_viewport().set_input_as_handled()
			return
		device = jb.device # whatever pad you just pressed a button on is the pad
		_set_pad(true)
		if jb.button_index in _dpad:
			_dpad[jb.button_index] = jb.pressed
		_button(jb.button_index, jb.pressed)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadMotion:
		var jm := event as InputEventJoypadMotion
		if _is_junk(jm.device) or (jm.device != device and not Input.is_joy_known(jm.device)):
			get_viewport().set_input_as_handled()
			return # sensor noise / a second unknown device
		var trig := jm.axis == JOY_AXIS_TRIGGER_LEFT or jm.axis == JOY_AXIS_TRIGGER_RIGHT
		if (trig and jm.axis_value > 0.45) or (not trig and absf(jm.axis_value) > 0.45):
			device = jm.device
			_set_pad(true)
		return
	if event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > 3.0):
		_set_pad(false)


func _set_pad(on: bool) -> void:
	if on == using_pad:
		return
	using_pad = on
	emit_signal("device_changed", on)


# ------------------------------------------------------------------ context
func _game() -> Node:
	var g = DialogueManager.game
	# Only the real game world (tests plug in stubs without a player or UI).
	if g == null or not is_instance_valid(g) or not g.has_method("ui_open") or not ("player" in g):
		return null
	return g


## "menu" (main menu, pause, any open screen), "drive", or "play".
func context() -> String:
	var g := _game()
	if g == null or get_tree().paused:
		return "menu"
	if g.player == null or g.ui_open() or (g.dialog != null and g.dialog.is_open()):
		return "menu"
	if g.minigames != null and g.minigames.has_method("is_running") and g.minigames.is_running():
		return "menu"
	if g.player.get("driving") != null:
		return "drive"
	return "play"


## Which screen is on top, for per-screen button meanings.
func _screen() -> String:
	var g := _game()
	if g == null:
		return ""
	if g.exploit_ui != null and g.exploit_ui.is_open():
		return "exploit"
	if g.minigames != null and g.minigames.is_running():
		return "minigame"
	# Screens a conversation can open on top of itself (a fence's barter) come first.
	for pair in [["phone", g.phone], ["loot", g.loot_ui], ["barter", g.barter_ui], ["terminal", g.terminal_ui], ["levelup", g.levelup_ui], ["wait", g.wait_ui]]:
		var m = pair[1]
		if m != null and m.is_open():
			return str(pair[0])
	if g.dialog != null and g.dialog.is_open():
		return "dialogue"
	return ""


# ------------------------------------------------------------------ buttons
func _button(btn: int, pressed: bool) -> void:
	if not pressed:
		_release(btn)
		return
	var ctx := context()
	if ctx != "menu" and btn in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT] and ctx == "drive":
		return
	if ctx == "menu":
		if btn in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
			return # handled with the stick in _process (with key repeat)
		var scr := _screen()
		var title := _game() == null # title screen / menus outside the game
		# Confirm: press whatever button has focus, directly. (Screens that read
		# keys themselves — dialogue, EXPLOIT, terminals, minigames — get keys.)
		var confirm := btn == JOY_BUTTON_A or (title and btn in [JOY_BUTTON_X, JOY_BUTTON_Y])
		var map_open: bool = scr == "phone" and _game().phone.get("_map_view") != null and _game().phone._map_view.visible
		if confirm and not map_open and not (scr in ["dialogue", "exploit", "terminal", "minigame"]) and _activate_focus():
			return
		var k := -1
		match btn:
			JOY_BUTTON_A:
				k = KEY_SPACE if scr == "exploit" else KEY_ENTER
			JOY_BUTTON_B, JOY_BUTTON_START, JOY_BUTTON_BACK:
				k = KEY_ESCAPE
				if scr == "dialogue":
					k = -1 # conversations can't be backed out of mid-line
			JOY_BUTTON_X:
				k = KEY_E if scr == "exploit" else KEY_R
			JOY_BUTTON_Y:
				k = KEY_BACKSPACE if scr == "exploit" else KEY_SPACE
			JOY_BUTTON_LEFT_SHOULDER:
				k = KEY_A if scr == "exploit" else KEY_Q
			JOY_BUTTON_RIGHT_SHOULDER:
				k = KEY_D if scr == "exploit" else (KEY_E if scr == "phone" else KEY_PAGEDOWN)
		if k >= 0:
			_press_key(btn, k)
		return
	if ctx == "drive":
		var g := _game()
		if g != null and g.player.driving is Aircraft and btn in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
			return # rudder, read directly by the plane
		match btn:
			JOY_BUTTON_A: _press_key(btn, KEY_E)
			JOY_BUTTON_B: _press_key(btn, KEY_TAB)
			JOY_BUTTON_LEFT_SHOULDER: _press_key(btn, KEY_G)
			JOY_BUTTON_RIGHT_SHOULDER: _press_key(btn, KEY_H)
			JOY_BUTTON_START: _press_key(btn, KEY_ESCAPE)
			JOY_BUTTON_BACK: _press_key(btn, KEY_M)
		return
	# On foot.
	match btn:
		JOY_BUTTON_A: _press_key(btn, KEY_E)
		JOY_BUTTON_B: _press_key(btn, KEY_TAB)
		JOY_BUTTON_X: _press_key(btn, KEY_R)
		JOY_BUTTON_Y: _press_key(btn, KEY_SPACE)
		JOY_BUTTON_LEFT_SHOULDER: _press_key(btn, KEY_V)
		JOY_BUTTON_RIGHT_SHOULDER: _press_key(btn, KEY_H)
		JOY_BUTTON_RIGHT_STICK: _press_key(btn, KEY_C)
		JOY_BUTTON_START: _press_key(btn, KEY_ESCAPE)
		JOY_BUTTON_BACK: _press_key(btn, KEY_M)
		JOY_BUTTON_DPAD_UP: _press_key(btn, KEY_F)
		JOY_BUTTON_DPAD_DOWN: _press_key(btn, KEY_T)
		JOY_BUTTON_DPAD_LEFT: _wheel(MOUSE_BUTTON_WHEEL_UP)
		JOY_BUTTON_DPAD_RIGHT: _wheel(MOUSE_BUTTON_WHEEL_DOWN)


## Press the focused button (Button, CheckBox/CheckButton, OptionButton) the
## same way a mouse click would. Returns false if nothing pressable has focus.
func _cycle_option(ob: OptionButton, d: int) -> void:
	var n := ob.item_count
	if n <= 0 or ob.disabled:
		return
	var i := (ob.selected + d + n) % n
	ob.select(i)
	ob.item_selected.emit(i)
	AudioManager.play_key()


func _activate_focus() -> bool:
	var f := get_viewport().gui_get_focus_owner()
	if f == null or not (f is BaseButton) or not f.is_visible_in_tree():
		_ensure_focus()
		f = get_viewport().gui_get_focus_owner()
		if f == null or not (f is BaseButton) or not f.is_visible_in_tree():
			return false
	var b := f as BaseButton
	if b.disabled:
		return true # swallow it: a disabled button does nothing, like a click
	if b is OptionButton:
		_cycle_option(b as OptionButton, 1)
		return true
	if b.toggle_mode:
		b.button_pressed = not b.button_pressed
	b.pressed.emit()
	return true


func _press_key(btn: int, code: int) -> void:
	var e := _key_event(code, true)
	Input.parse_input_event(e)
	var rel := _key_event(code, false)
	if not _held.has(btn):
		_held[btn] = []
	(_held[btn] as Array).append(rel)


func _release(btn: int) -> void:
	if not _held.has(btn):
		return
	for e in _held[btn]:
		Input.parse_input_event(e)
	_held.erase(btn)


func _tap(code: int) -> void:
	Input.parse_input_event(_key_event(code, true))
	Input.parse_input_event(_key_event(code, false))


func _key_event(code: int, pressed: bool) -> InputEventKey:
	var e := InputEventKey.new()
	e.set_meta("pad", true)
	e.keycode = code
	e.physical_keycode = code
	e.pressed = pressed
	return e


func _mouse(button: int, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.set_meta("pad", true)
	e.button_index = button
	e.pressed = pressed
	e.position = get_viewport().get_visible_rect().size * 0.5
	e.global_position = e.position
	Input.parse_input_event(e)


func _wheel(button: int) -> void:
	_mouse(button, true)
	_mouse(button, false)


# ------------------------------------------------------------------ polling
func _process(delta: float) -> void:
	var ctx := context()
	if ctx != _last_ctx:
		# Context flipped mid-press: let go of everything we were holding.
		for b in _held.keys():
			_release(int(b))
		for d in _dir.keys():
			if _dir[d]:
				Input.parse_input_event(_key_event(_dir_key(str(d)), false))
				_dir[d] = false
		if _rt:
			_rt = false
			_mouse(MOUSE_BUTTON_LEFT, false)
		if _lt:
			_lt = false
			_mouse(MOUSE_BUTTON_RIGHT, false)
		_last_ctx = ctx
	if _no_pad():
		return
	if ctx == "play":
		# Triggers: fire and aim, as mouse buttons (so full-auto just works).
		var rt := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > 0.45
		if rt != _rt:
			_rt = rt
			_mouse(MOUSE_BUTTON_LEFT, rt)
		var lt := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT) > 0.45
		if lt != _lt:
			_lt = lt
			_mouse(MOUSE_BUTTON_RIGHT, lt)
	elif ctx == "menu":
		_menu_nav(delta)
		# Triggers flip sub-sections on screens that have them (phone: A / D).
		var rt2 := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > 0.5
		var lt2 := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT) > 0.5
		if rt2 != _rt or lt2 != _lt:
			var scr := _screen()
			if rt2 and not _rt and scr == "phone":
				_tap(KEY_D)
			if lt2 and not _lt and scr == "phone":
				_tap(KEY_A)
			_rt = rt2
			_lt = lt2


func _dir_key(d: String) -> int:
	return {"up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT}[d]


## Stick and D-pad move through menus as arrow keys, with a key-repeat.
func _menu_nav(delta: float) -> void:
	var lx := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	var ly := Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
	var want := {
		"up": ly < -STICK_NAV or bool(_dpad[JOY_BUTTON_DPAD_UP]),
		"down": ly > STICK_NAV or bool(_dpad[JOY_BUTTON_DPAD_DOWN]),
		"left": lx < -STICK_NAV or bool(_dpad[JOY_BUTTON_DPAD_LEFT]),
		"right": lx > STICK_NAV or bool(_dpad[JOY_BUTTON_DPAD_RIGHT]),
	}
	for d in want.keys():
		var on: bool = want[d]
		if on and not _dir[d]:
			_dir[d] = true
			_dir_t[d] = 0.42
			_nav_key(str(d))
		elif on:
			_dir_t[d] = float(_dir_t[d]) - delta
			if float(_dir_t[d]) <= 0.0:
				_dir_t[d] = 0.13
				Input.parse_input_event(_key_event(_dir_key(str(d)), false))
				_nav_key(str(d))
		elif _dir[d]:
			_dir[d] = false
			Input.parse_input_event(_key_event(_dir_key(str(d)), false))
	# Screens built from buttons need something focused to navigate from.
	_focus_t -= delta
	if using_pad and _focus_t <= 0.0:
		_focus_t = 0.25
		_ensure_focus()


func _nav_key(d: String) -> void:
	# Dropdowns: left/right flip through the options in place. (Their popup
	# list is a separate window that a pad can't reach, so it's never opened.)
	var fo := get_viewport().gui_get_focus_owner()
	if fo is OptionButton and (d == "left" or d == "right"):
		_cycle_option(fo as OptionButton, 1 if d == "right" else -1)
		return
	Input.parse_input_event(_key_event(_dir_key(d), true))
	# The dialogue and EXPLOIT screens read W/S too; arrows are enough for the rest.


func _ensure_focus() -> void:
	var vp := get_viewport()
	var cur := vp.gui_get_focus_owner()
	var scr := _screen()
	if scr in ["dialogue", "exploit", "terminal"]:
		return # these screens run their own selection
	var root: Node = get_tree().root
	var g := _game()
	if scr == "minigame" and g != null:
		root = g.minigames # never reach through a minigame into the screen under it
	var best: Control = null
	var best_layer := -99999
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CanvasItem and not (n as CanvasItem).visible:
			continue
		if n is CanvasLayer and not (n as CanvasLayer).visible:
			continue
		if n is BaseButton:
			var b := n as BaseButton
			if b.is_visible_in_tree() and not b.disabled and b.focus_mode != Control.FOCUS_NONE:
				var layer := _layer_of(b)
				if layer > best_layer:
					best_layer = layer
					best = b
		var kids := n.get_children()
		for i in range(kids.size() - 1, -1, -1):
			# The 3D world holds no buttons: only step into a 3D node's UI layers.
			if n is Node3D and kids[i] is Node3D:
				continue
			stack.append(kids[i])
	var cur_ok := cur != null and cur.is_visible_in_tree() and not (cur is LineEdit or cur is TextEdit)
	if cur_ok and scr == "minigame" and g != null and not g.minigames.is_ancestor_of(cur):
		cur_ok = false
	if cur_ok and (best == null or _layer_of(cur) >= best_layer):
		return # focus is already on the top screen
	if best != null:
		best.grab_focus()
	elif cur != null and not cur_ok:
		cur.release_focus()


func _layer_of(n: Node) -> int:
	var p := n
	while p != null:
		if p is CanvasLayer:
			return (p as CanvasLayer).layer
		p = p.get_parent()
	return 0


# ------------------------------------------------------------------ helpers
func _no_pad() -> bool:
	return not fake and Input.get_connected_joypads().is_empty()


## Right stick, with a deadzone and a gentle response curve. (-1..1)
func look_vector() -> Vector2:
	if _no_pad():
		return Vector2.ZERO
	var v := Vector2(Input.get_joy_axis(device, JOY_AXIS_RIGHT_X), Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y))
	var l := v.length()
	if l < DEAD:
		return Vector2.ZERO
	var k := (l - DEAD) / (1.0 - DEAD)
	return v / l * clampf(k * k * 0.6 + k * 0.4, 0.0, 1.0)


func trigger(right: bool) -> float:
	if _no_pad():
		return 0.0
	var a := Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT if right else JOY_AXIS_TRIGGER_LEFT)
	return clampf((a - 0.08) / 0.92, 0.0, 1.0)


func button(b: int) -> bool:
	return not _no_pad() and Input.is_joy_button_pressed(device, b)


func rumble(weak: float, strong: float, secs: float) -> void:
	if using_pad and bool(Settings.get_v("pad_rumble")):
		Input.start_joy_vibration(device, clampf(weak, 0.0, 1.0), clampf(strong, 0.0, 1.0), secs)


## What to print for a keyboard key in on-screen hints, depending on the device.
func glyph(key: String) -> String:
	if not using_pad:
		return key
	var map := {"E": "A", "TAB": "B", "R": "X", "SPACE": "Y", "V": "LB", "H": "RB", "C": "R3", "SHIFT": "L3", "F": "D-PAD UP", "T": "D-PAD DOWN", "M": "BACK", "ESC": "START", "G": "LB", "W": "RT", "S": "LT"}
	return str(map.get(key, key))
