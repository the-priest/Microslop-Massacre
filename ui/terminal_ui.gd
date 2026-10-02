class_name TerminalUI
extends Modal
## Computer terminals. Locked ones need a HACKING check and the password
## game: pick words from a memory dump; likeness = letters in the right place.
## Bracket pairs like (), [], {}, <> remove a dud or restore attempts.

const WORDS := {
	4: ["ROOT", "HASH", "SALT", "PORT", "SUDO", "PING", "NODE", "BYTE", "CODE", "DATA", "LOCK", "PASS", "USER", "HOST", "EXEC", "KILL", "FORK", "PIPE", "SOCK", "BOOT", "WIPE", "LEAK", "MASK", "RATS", "DEBT", "BANK", "FISH", "COIN", "GRID", "VOID"],
	5: ["PROXY", "SHELL", "LOGIN", "ADMIN", "CACHE", "TOKEN", "DAEMON", "CRASH", "BLOCK", "QUERY", "PATCH", "FLOOD", "SPOOF", "CRACK", "STACK", "MACRO", "VIRUS", "WORMS", "LOGIC", "TRACE", "GHOST", "CLOAK", "SIGMA", "RESET", "OWNED", "CHAOS", "NERVE", "MONEY", "POWER", "TOWER"],
	6: ["KERNEL", "SOCKET", "BINARY", "CIPHER", "SCRIPT", "SERVER", "BACKUP", "EXPORT", "IMPORT", "SIGNAL", "HACKER", "MEMORY", "ACCESS", "ROUTER", "MALICE", "DEBTOR", "LEDGER", "SOCIETY", "EMPIRE", "MIRROR", "TUNNEL", "BREACH", "SYSTEM", "STATIC", "VECTOR", "SECRET", "FRIEND", "PUPPET", "RABBIT", "CANDLE"],
	7: ["FIREWALL", "PAYLOAD", "EXPLOIT", "ROOTKIT", "NETWORK", "CONSOLE", "COMPILE", "ENCRYPT", "DECRYPT", "MONITOR", "PROGRAM", "PACKETS", "BOTNETS", "TROJANS", "SANDBOX", "BITCOIN", "CAPITAL", "COMPANY", "CONTROL", "FREEDOM", "REVOLTS", "MACHINE", "PHANTOM", "SPECTRE", "HISTORY", "MORNING", "BROTHER", "SISTERS", "FATHERS", "PRIVACY"],
	8: ["PASSWORD", "OVERFLOW", "BACKDOOR", "KEYSTONE", "TERMINAL", "DATABASE", "SECURITY", "PROTOCOL", "MAINLINE", "NEURAL", "PHISHING", "SPYWARE", "RANSOMED", "INTERNET", "HARDWARE", "SOFTWARE", "FIRMWARE", "OPERATOR", "PERSONAL", "IDENTITY", "ANARCHY", "MANIFEST", "MIDNIGHT", "SUNSHINE", "DISTRUST", "CORPORATE", "VIGILANT", "ALDERSON", "REBOOTED", "WHISPERS"],
	9: ["ALGORITHM", "BLACKHATS", "DECRYPTED", "INJECTION", "KEYLOGGER", "MAINFRAME", "OVERWRITE", "PERMISSION", "SURVEYORS", "TELEMETRY", "BLACKLIST", "WHITELIST", "HANDSHAKE", "LOADSTONE", "REVOLTING", "CONSPIRED", "DELUSIONS", "SUBMARINE", "CROSSWIRE", "DISSOLVED"],
}

var _screen: RichTextLabel
var _side: RichTextLabel
var _title: Label
var _id: String = ""
var _data: Dictionary = {}
var _mode: String = "menu"
var _password: String = ""
var _attempts: int = 4
var _words: Array = []
var _duds_removed: Dictionary = {}
var _brackets_used: Dictionary = {}
var _log: Array = []
var _dump: Array = [] # segments
var _hacked_now: bool = false


func _build() -> void:
	var p := panel(1120, 640)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	p.add_child(vb)
	_title = UI.label("", 18, UI.GREEN)
	vb.add_child(_title)
	var hb := HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(hb)
	_screen = UI.rich(17)
	_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen.meta_underlined = false
	_screen.meta_clicked.connect(_on_meta)
	_screen.add_theme_color_override("default_color", UI.GREEN)
	hb.add_child(_screen)
	_side = UI.rich(16)
	_side.custom_minimum_size = Vector2(260, 0)
	_side.add_theme_color_override("default_color", UI.GREEN)
	hb.add_child(_side)
	_keys = UI.label("", 13, UI.GREEN_DIM)
	vb.add_child(_keys)


var _keys: Label


func open(id: String, data: Dictionary) -> void:
	_keys.text = "[STICK] choose    [A] select    [B] log off" if Pad.using_pad else "[↑/↓] or click to choose    [ENTER] select    [ESC] log off"
	_id = id
	_data = data
	_title.text = "%s  ·  %s" % [str(data.get("title", "TERMINAL")).to_upper(), "ROBCO-FREE LINUX 5.9"]
	open_modal()
	AudioManager.sfx("typing")
	var dc := int(data.get("hack", 0))
	if dc > 0 and not GameState.unlocked.has(id):
		_mode = "locked"
		_show_locked()
	else:
		_mode = "menu"
		_show_menu()
	await closed


# Keyboard / gamepad cursor over the screen's links: the highlighted link is
# redrawn inverted; arrows move it, Enter or Space follows it.
var _decorated: String = ""
var _raw: String = ""
var _links: Array = []
var _cur: int = 0


func _process(_delta: float) -> void:
	if not _is_open or _screen == null:
		return
	if _screen.text != _decorated:
		_raw = _screen.text
		_links = []
		var re := RegEx.new()
		re.compile("\\[url=([^\\]]+)\\]")
		for m in re.search_all(_raw):
			_links.append(m.get_string(1))
		_cur = clampi(_cur, 0, maxi(0, _links.size() - 1))
		# Land on something useful: in a menu, the first entry rather than LOG OFF.
		_decorate()


func _decorate() -> void:
	var t := _raw
	if _links.size() > 0:
		var tag := "[url=%s]" % str(_links[_cur])
		var i := t.find(tag)
		if i >= 0:
			var j := t.find("[/url]", i)
			if j > 0:
				var inner := t.substr(i + tag.length(), j - i - tag.length())
				t = t.substr(0, i) + tag + "[bgcolor=#2bd46e][color=#021006]" + inner + "[/color][/bgcolor]" + t.substr(j)
	_decorated = t
	_screen.text = t


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var kc := (event as InputEventKey).physical_keycode
	if kc in [KEY_UP, KEY_LEFT, KEY_W] and _links.size() > 0:
		_cur = (_cur - 1 + _links.size()) % _links.size()
		_decorate()
		AudioManager.sfx("key")
		get_viewport().set_input_as_handled()
		return
	if kc in [KEY_DOWN, KEY_RIGHT, KEY_S] and _links.size() > 0:
		_cur = (_cur + 1) % _links.size()
		_decorate()
		AudioManager.sfx("key")
		get_viewport().set_input_as_handled()
		return
	if kc in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and _links.size() > 0:
		var link := str(_links[_cur])
		_cur = 0
		_on_meta(link)
		get_viewport().set_input_as_handled()
		return
	if (event as InputEventKey).physical_keycode in [KEY_ESCAPE, KEY_TAB]:
		if _mode == "entry":
			_mode = "menu"
			_show_menu()
		else:
			close_modal()
	get_viewport().set_input_as_handled()


func _show_locked() -> void:
	var dc := int(_data.get("hack", 0))
	var lock_until := float(GameState.get_flag("term_lock:" + _id, -1.0))
	var t := "[color=#8fd]%s[/color]\n\n" % str(_data.get("header", "PASSWORD REQUIRED"))
	if lock_until > GameState.game_minutes:
		t += "TERMINAL LOCKED. Please contact an administrator.\n(Try again in %d minutes.)\n" % int(lock_until - GameState.game_minutes)
		t += "\n[url=exit]> LOG OFF[/url]"
		_screen.text = t
		_side.text = ""
		return
	var sk := GameState.skill("hacking")
	t += "Security rating: %d    Your HACKING: %d\n\n" % [dc, sk]
	if GameState.has_perk("zero_day") and GameState.zero_day_day != GameState.day():
		t += "[url=zeroday]> DEPLOY ZERO-DAY (once per day)[/url]\n"
	if sk >= dc:
		t += "[url=hack]> ATTEMPT BYPASS[/url]\n"
	else:
		t += "[color=#f55]Encryption too strong. You need HACKING %d.[/color]\n" % dc
	var pw_item := str(_data.get("password_item", ""))
	if pw_item != "" and GameState.has_item(pw_item):
		t += "[url=password]> USE PASSWORD (%s)[/url]\n" % DB.item_name(pw_item)
	if _data.has("password_flag") and GameState.has_flag(str(_data["password_flag"])):
		t += "[url=password]> ENTER THE PASSWORD YOU FOUND[/url]\n"
	t += "\n[url=exit]> LOG OFF[/url]"
	_screen.text = t
	_side.text = ""


func _start_hack() -> void:
	_mode = "hack"
	var dc := int(_data.get("hack", 25))
	var length := clampi(4 + dc / 20, 4, 9)
	var pool: Array = (WORDS.get(length, WORDS[6]) as Array).duplicate()
	pool = pool.filter(func(w: String) -> bool: return w.length() == length)
	if pool.size() < 8:
		pool = (WORDS[6] as Array).filter(func(w: String) -> bool: return w.length() == 6)
		length = 6
	pool.shuffle()
	var count := clampi(8 + dc / 15, 8, 14)
	_words = pool.slice(0, mini(count, pool.size()))
	_password = str(_words[randi() % _words.size()])
	_attempts = 4 + (1 if GameState.has_perk("root_access") else 0)
	_duds_removed = {}
	_brackets_used = {}
	_log = []
	_build_dump()
	if GameState.has_perk("root_access"):
		_remove_dud()
	_render_hack()


func _build_dump() -> void:
	# Segments: {"t": "junk"/"word"/"br", "s": text, "id": n}
	_dump = []
	var junk := "!@#$%^&*-_=+;:,.?/|\\'\""
	var opens := "([{<"
	var closes := ")]}>"
	var words := _words.duplicate()
	words.shuffle()
	var br_id := 0
	var total := 0
	for w in words:
		var n := randi_range(4, 14)
		var s := ""
		for i in n:
			if randf() < 0.07 and br_id < 6:
				var k := randi() % 4
				var inner := ""
				for j in randi_range(0, 3):
					inner += junk[randi() % junk.length()]
				_flush_junk(s)
				s = ""
				_dump.append({"t": "br", "s": opens[k] + inner + closes[k], "id": br_id})
				br_id += 1
			else:
				s += junk[randi() % junk.length()]
		_flush_junk(s)
		_dump.append({"t": "word", "s": str(w)})
		total += n + str(w).length()
	var tail := ""
	for i in 10:
		tail += junk[randi() % junk.length()]
	_flush_junk(tail)


func _flush_junk(s: String) -> void:
	if s != "":
		_dump.append({"t": "junk", "s": s})


func _render_hack() -> void:
	var t := "[color=#8fd]ROBCO-FREE LINUX · MEMORY DUMP · ENTER PASSWORD NOW[/color]\n\n"
	t += "ATTEMPTS: %s\n\n" % "■ ".repeat(_attempts)
	var line_len := 0
	var addr := 0xF4A0 + randi() % 64
	var out := "0x%04X  " % addr
	for seg in _dump:
		var sd: Dictionary = seg
		var s := str(sd["s"])
		var disp := s
		match str(sd["t"]):
			"word":
				if _duds_removed.has(s):
					disp = "[color=#355]%s[/color]" % ".".repeat(s.length())
				else:
					disp = "[url=w:%s][color=#bfffcf]%s[/color][/url]" % [s, s]
			"br":
				var bid := int(sd["id"])
				if _brackets_used.has(bid):
					disp = "[color=#355]%s[/color]" % s.replace("[", "(").replace("]", ")")
				else:
					disp = "[url=b:%d]%s[/url]" % [bid, s.replace("[", "[lb]")]
			_:
				disp = s.replace("[", "[lb]")
		out += disp + " "
		line_len += s.length() + 1
		if line_len > 60:
			line_len = 0
			addr += 12
			out += "\n0x%04X  " % addr
	t += out
	_screen.text = t
	var side := "[color=#8fd]>LOG[/color]\n"
	for l in _log.slice(maxi(0, _log.size() - 14)):
		side += str(l) + "\n"
	_side.text = side


func _on_meta(meta: Variant) -> void:
	var m := str(meta)
	AudioManager.sfx("typing")
	if m == "exit":
		close_modal()
	elif m == "hack":
		_start_hack()
	elif m == "zeroday":
		GameState.zero_day_day = GameState.day()
		_access_granted()
	elif m == "password":
		_access_granted()
	elif m.begins_with("w:"):
		_guess(m.substr(2))
	elif m.begins_with("b:"):
		_bracket(int(m.substr(2)))
	elif m.begins_with("e:"):
		_show_entry(int(m.substr(2)))
	elif m.begins_with("a:"):
		_do_action(int(m.substr(2)))
	elif m == "back":
		_mode = "menu"
		_show_menu()


func _likeness(a: String, b: String) -> int:
	var n := 0
	for i in mini(a.length(), b.length()):
		if a[i] == b[i]:
			n += 1
	return n


func _guess(w: String) -> void:
	if _mode != "hack" or _duds_removed.has(w):
		return
	_log.append(">" + w)
	if w == _password:
		_log.append(">Exact match!")
		_access_granted()
		return
	_attempts -= 1
	_log.append(">Entry denied.")
	_log.append(">Likeness=%d" % _likeness(w, _password))
	_duds_removed[w] = true
	AudioManager.play_fail()
	if _attempts <= 0:
		GameState.set_flag("term_lock:" + _id, GameState.game_minutes + 30.0)
		_mode = "locked"
		_show_locked()
		return
	_render_hack()


func _bracket(bid: int) -> void:
	if _mode != "hack" or _brackets_used.has(bid):
		return
	_brackets_used[bid] = true
	if randf() < 0.3 and _attempts < 4:
		_attempts = 4 + (1 if GameState.has_perk("root_access") else 0)
		_log.append(">Allowance replenished.")
	else:
		if _remove_dud():
			_log.append(">Dud removed.")
		else:
			_log.append(">Nothing happened.")
	AudioManager.play_blip()
	_render_hack()


func _remove_dud() -> bool:
	var duds: Array = []
	for w in _words:
		if str(w) != _password and not _duds_removed.has(str(w)):
			duds.append(str(w))
	if duds.is_empty():
		return false
	_duds_removed[duds[randi() % duds.size()]] = true
	return true


func _access_granted() -> void:
	GameState.unlocked[_id] = true
	GameState.stat_add("hacks")
	GameState.unlock("first_hack")
	GameState.add_xp(15 + int(_data.get("hack", 0)) / 3)
	AudioManager.play_success()
	_mode = "menu"
	if _data.has("fx_hack"):
		await DialogueManager.run_effects(DialogueManager.parse_effects(str(_data["fx_hack"]), _id))
	_show_menu()


func _show_menu() -> void:
	var t := "[color=#8fd]%s[/color]\n\n" % str(_data.get("welcome", "Welcome, %s." % str(_data.get("user", "USER"))))
	var i := 0
	for e in _data.get("entries", []):
		var ed: Dictionary = e
		if ed.has("when") and not DialogueManager.check(str(ed["when"])):
			i += 1
			continue
		t += "[url=e:%d]> %s[/url]\n" % [i, str(ed.get("title", "Entry"))]
		i += 1
	var j := 0
	for a in _data.get("actions", []):
		var ad: Dictionary = a
		var done := GameState.flags.has("tact:%s:%d" % [_id, j])
		var ok := not ad.has("when") or DialogueManager.check(str(ad["when"]))
		if ok and not (done and bool(ad.get("once", true))):
			t += "[url=a:%d]> %s[/url]\n" % [j, str(ad.get("title", "Run"))]
		j += 1
	t += "\n[url=exit]> LOG OFF[/url]"
	_screen.text = t
	_side.text = ""


func _show_entry(i: int) -> void:
	var entries: Array = _data.get("entries", [])
	if i < 0 or i >= entries.size():
		return
	var ed: Dictionary = entries[i]
	_mode = "entry"
	var body := str(ed.get("text", ""))
	if ed.has("note"):
		var nid := str(ed["note"])
		body = str(DB.item(nid).get("text", body))
		if not GameState.has_item(nid):
			GameState.give(nid, 1)
	_screen.text = "[color=#8fd]%s[/color]\n\n%s\n\n[url=back]> BACK[/url]" % [str(ed.get("title", "")), body.replace("[", "[lb]")]
	if ed.has("fx") and not GameState.flags.has("tent:%s:%d" % [_id, i]):
		GameState.flags["tent:%s:%d" % [_id, i]] = true
		DialogueManager.run_effects(DialogueManager.parse_effects(str(ed["fx"]), _id))


func _do_action(j: int) -> void:
	var acts: Array = _data.get("actions", [])
	if j < 0 or j >= acts.size():
		return
	var ad: Dictionary = acts[j]
	GameState.flags["tact:%s:%d" % [_id, j]] = true
	_screen.text = "[color=#8fd]%s[/color]\n\n%s\n\n[url=back]> BACK[/url]" % [str(ad.get("title", "")), str(ad.get("result", "Done.")).replace("[", "[lb]")]
	_mode = "entry"
	await DialogueManager.run_effects(DialogueManager.parse_effects(str(ad.get("fx", "")), _id))
