extends Node
## AudioManager — every sound effect is synthesized at runtime; the only audio
## files are the narrator's voice lines (audio/voice).
## Sounds are generated once and cached; players are pooled so shots, steps
## and UI can overlap. 3D sounds use a positional pool. Radio stations stream
## procedurally composed loops.

const RATE := 22050
const LOFI := 11025

var _cache: Dictionary = {}
var _ui_pool: Array = []
var _sfx_pool: Array = []
var _p3d_pool: Array = []
var _ui_i: int = 0
var _sfx_i: int = 0
var _p3d_i: int = 0
var _ambient: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _rumble: AudioStreamPlayer
var _muzak: AudioStreamPlayer
var _radio: AudioStreamPlayer
var _siren: AudioStreamPlayer
var _step_flip: bool = false
var radio_station: String = ""
var _radio_streams: Dictionary = {}
var _radio_thread_busy: bool = false
var _ambient_kind: String = ""

const STATIONS := {
	"jazz": {"name": "NIGHT JAZZ 88.3", "desc": "Slow chords for people who can't sleep."},
	"synth": {"name": "WAVE 101.9", "desc": "Neon, analog, and nostalgia for a future that got foreclosed."},
	"beats": {"name": "LOFI 92.1", "desc": "Beats to hack to."},
	"pirate": {"name": "fsociety PIRATE SIGNAL", "desc": "Broadcast from a rooftop in the Heights. Static and conviction."},
	"news": {"name": "E NEWS 24 · NEWS, TALK & TRAFFIC", "desc": "E Corp's own station. It reports what you did anyway, in between the ads."},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_bus("SFX")
	_make_bus("Music")
	_make_bus("Voice")
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_ui_pool.append(p)
	for i in 10:
		var p2 := AudioStreamPlayer.new()
		p2.bus = "SFX"
		add_child(p2)
		_sfx_pool.append(p2)
	for i in 12:
		var p3 := AudioStreamPlayer3D.new()
		p3.bus = "SFX"
		p3.unit_size = 8.0
		p3.max_distance = 120.0
		p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(p3)
		_p3d_pool.append(p3)
	_ambient = _loop_player("Music")
	_rain = _loop_player("SFX")
	_rumble = _loop_player("SFX")
	_muzak = _loop_player("Music")
	_radio = _loop_player("Music")
	_siren = _loop_player("SFX")
	Settings.applied.connect(apply_volumes)
	apply_volumes()


func _make_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _loop_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


var _ducked := false


## Pull music and effects down under narration.
func duck(on: bool) -> void:
	_ducked = on
	apply_volumes()


func apply_volumes() -> void:
	var s := AudioServer.get_bus_index("SFX")
	var m := AudioServer.get_bus_index("Music")
	var v := AudioServer.get_bus_index("Voice")
	var dk := -14.0 if _ducked else 0.0
	if s >= 0:
		AudioServer.set_bus_volume_db(s, linear_to_db(maxf(0.0001, float(Settings.get_v("sfx_volume")))) + dk)
	if m >= 0:
		AudioServer.set_bus_volume_db(m, linear_to_db(maxf(0.0001, float(Settings.get_v("music_volume")))) + dk)
	if v >= 0:
		AudioServer.set_bus_volume_db(v, linear_to_db(maxf(0.0001, float(Settings.get_v("voice_volume")))))


# ------------------------------------------------------------------ synthesis
func _wav(samples: PackedFloat32Array, rate: int, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = rate
	st.stereo = false
	st.data = data
	if loop:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = samples.size()
	return st


func _pluck(freqs: Array, dur: float, vol: float, stagger: float = 0.0, decay: float = 9.0) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for k in freqs.size():
			var f: float = freqs[k]
			var lt := t - float(k) * stagger
			if lt < 0.0:
				continue
			var env := exp(-lt * decay) * minf(lt / 0.008, 1.0)
			v += (sin(TAU * f * lt) * 0.7 + sin(TAU * f * 2.0 * lt) * 0.2 + sin(TAU * f * 0.5 * lt) * 0.15) * env
		s[i] = v / float(maxi(freqs.size(), 1)) * vol
	return _wav(s, RATE)


func _noise_burst(dur: float, vol: float, cutoff: float, decay: float, thump_f: float = 0.0, thump_v: float = 0.0, crackle: float = 0.0) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var prev := 0.0
	var prev2 := 0.0
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var white := randf() * 2.0 - 1.0
		prev = prev * (1.0 - cutoff) + white * cutoff
		prev2 = prev2 * 0.5 + prev * 0.5
		var env := exp(-t * decay) * minf(t / 0.002, 1.0)
		var v := prev2 * 2.5 * env
		if thump_v > 0.0:
			var f := thump_f * (1.0 - t * 0.6)
			ph += TAU * maxf(20.0, f) / RATE
			v += sin(ph) * thump_v * exp(-t * 18.0)
		if crackle > 0.0 and randf() < crackle * env:
			v += (randf() * 2.0 - 1.0) * 0.6 * env
		s[i] = v * vol
	return _wav(s, RATE)


func _sweep(f0: float, f1: float, dur: float, vol: float, wave: String = "sine", decay: float = 0.0) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := lerpf(f0, f1, t / dur)
		ph += TAU * f / RATE
		var v := sin(ph)
		if wave == "square":
			v = 0.5 if sin(ph) > 0.0 else -0.5
		elif wave == "saw":
			v = fmod(ph / TAU, 1.0) * 2.0 - 1.0
		var env := minf(t / 0.01, 1.0) * minf((dur - t) / 0.03, 1.0)
		if decay > 0.0:
			env *= exp(-t * decay)
		s[i] = v * vol * env
	return _wav(s, RATE)


func _snd(name: String) -> AudioStreamWAV:
	if _cache.has(name):
		return _cache[name]
	var st: AudioStreamWAV = null
	match name:
		"blip": st = _pluck([660.0], 0.06, 0.22)
		"key": st = _noise_burst(0.04, 0.2, 0.18, 90.0)
		"select": st = _pluck([392.0, 523.25], 0.12, 0.28, 0.04)
		"success": st = _pluck([523.25, 659.25, 783.99], 0.35, 0.3, 0.06, 6.0)
		"fail": st = _pluck([196.0, 185.0], 0.3, 0.3, 0.05, 6.0)
		"glitch": st = _noise_burst(0.2, 0.25, 0.9, 12.0, 0.0, 0.0, 0.3)
		"whoosh": st = _noise_burst(0.35, 0.18, 0.12, 6.0)
		"levelup": st = _pluck([392.0, 493.88, 587.33, 783.99], 0.9, 0.3, 0.09, 3.0)
		"quest": st = _pluck([523.25, 392.0, 659.25], 0.6, 0.26, 0.1, 4.0)
		"discover": st = _pluck([440.0, 554.37, 659.25], 0.5, 0.22, 0.07, 5.0)
		"xp": st = _pluck([880.0], 0.08, 0.12)
		"step_a": st = _noise_burst(0.05, 0.16, 0.12, 60.0, 80.0, 0.15)
		"step_b": st = _noise_burst(0.05, 0.16, 0.08, 60.0, 70.0, 0.15)
		"gun_pistol": st = _noise_burst(0.35, 0.7, 0.55, 16.0, 110.0, 0.8, 0.05)
		"gun_revolver": st = _noise_burst(0.5, 0.8, 0.45, 11.0, 80.0, 0.9, 0.05)
		"gun_smg": st = _noise_burst(0.18, 0.55, 0.6, 26.0, 120.0, 0.6, 0.02)
		"gun_shotgun": st = _noise_burst(0.6, 0.9, 0.35, 8.0, 60.0, 1.0, 0.1)
		"gun_rifle": st = _noise_burst(0.7, 0.85, 0.5, 7.0, 70.0, 0.9, 0.04)
		"gun_carbine": st = _noise_burst(0.25, 0.65, 0.55, 18.0, 100.0, 0.7, 0.03)
		"gun_silent": st = _noise_burst(0.12, 0.3, 0.25, 40.0, 180.0, 0.3)
		"gun_taser": st = _noise_burst(0.35, 0.3, 0.95, 8.0, 0.0, 0.0, 0.6)
		"dry": st = _noise_burst(0.03, 0.3, 0.9, 150.0)
		"reload": st = _reload_sound()
		"swing": st = _noise_burst(0.2, 0.2, 0.08, 12.0)
		"punch": st = _noise_burst(0.12, 0.5, 0.1, 30.0, 70.0, 0.9)
		"thud": st = _noise_burst(0.1, 0.35, 0.06, 35.0, 55.0, 0.6)
		"hit": st = _noise_burst(0.08, 0.4, 0.2, 40.0, 140.0, 0.4)
		"ricochet": st = _sweep(2400.0, 900.0, 0.18, 0.12, "sine", 14.0)
		"hurt": st = _sweep(180.0, 90.0, 0.22, 0.4, "saw", 8.0)
		"death": st = _noise_burst(0.5, 0.5, 0.05, 6.0, 50.0, 0.8)
		"alert": st = _pluck([311.13, 466.16], 0.25, 0.25, 0.03, 8.0)
		"door": st = _door_sound()
		"lockpick": st = _noise_burst(0.03, 0.25, 0.7, 120.0)
		"lockbreak": st = _pluck([1760.0, 880.0], 0.15, 0.25, 0.02, 20.0)
		"pickup": st = _pluck([740.0, 988.0], 0.12, 0.2, 0.03)
		"horn": st = _sweep(392.0, 392.0, 0.4, 0.18, "square")
		"phone": st = _sweep(180.0, 180.0, 0.3, 0.2, "square", 0.0)
		"typing": st = _noise_burst(0.025, 0.18, 0.5, 160.0)
		"spray": st = _noise_burst(1.1, 0.2, 0.85, 1.6)
		"rattle": st = _noise_burst(0.05, 0.28, 0.65, 70.0, 900.0, 0.25)
		"heal": st = _pluck([523.25, 783.99], 0.3, 0.2, 0.05, 7.0)
		"coin": st = _pluck([1318.5, 1760.0], 0.18, 0.18, 0.04, 12.0)
		"siren": st = _siren_sound()
		"train": st = _train_sound()
	if st == null:
		st = _pluck([440.0], 0.05, 0.1)
	_cache[name] = st
	return st


func _reload_sound() -> AudioStreamWAV:
	var n := int(RATE * 0.5)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for c in [0.02, 0.22, 0.4]:
			var lt := t - float(c)
			if lt >= 0.0 and lt < 0.04:
				v += (randf() * 2.0 - 1.0) * exp(-lt * 120.0) * 0.6
		s[i] = v
	return _wav(s, RATE)


func _door_sound() -> AudioStreamWAV:
	var n := int(RATE * 0.6)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	var prev := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 220.0 + sin(t * 30.0) * 60.0 + t * 200.0
		ph += TAU * f / RATE
		prev = prev * 0.9 + (randf() * 2.0 - 1.0) * 0.1
		var env := minf(t / 0.05, 1.0) * exp(-t * 3.0)
		var v := (sin(ph) * 0.12 + prev * 0.8) * env
		if t > 0.5:
			v += (randf() * 2.0 - 1.0) * exp(-(t - 0.5) * 60.0) * 0.5
		s[i] = v * 0.5
	return _wav(s, RATE)


func _siren_sound() -> AudioStreamWAV:
	var dur := 3.0
	var n := int(LOFI * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / LOFI
		var f := 700.0 + 350.0 * sin(TAU * t / dur)
		ph += TAU * f / LOFI
		s[i] = (sin(ph) * 0.6 + sin(ph * 2.0) * 0.15) * 0.25
	return _wav(s, LOFI, true)


func _train_sound() -> AudioStreamWAV:
	var dur := 4.0
	var n := int(LOFI * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var prev := 0.0
	for i in n:
		var t := float(i) / LOFI
		prev = prev * 0.95 + (randf() * 2.0 - 1.0) * 0.05
		var clack := 0.0
		if fmod(t, 0.55) < 0.05:
			clack = (randf() * 2.0 - 1.0) * 0.5
		var env := minf(t / 1.0, 1.0) * minf((dur - t) / 1.0, 1.0)
		s[i] = (prev * 2.0 + clack + sin(TAU * 45.0 * t) * 0.1) * env * 0.5
	return _wav(s, LOFI)


# ------------------------------------------------------------------- playback
func _play(name: String, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	var p: AudioStreamPlayer = _sfx_pool[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx_pool.size()
	p.stream = _snd(name)
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.play()


func _play_ui(name: String, vol_db: float = 0.0) -> void:
	var p: AudioStreamPlayer = _ui_pool[_ui_i]
	_ui_i = (_ui_i + 1) % _ui_pool.size()
	p.stream = _snd(name)
	p.volume_db = vol_db
	p.play()


func play_3d(name: String, pos: Vector3, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	var p: AudioStreamPlayer3D = _p3d_pool[_p3d_i]
	_p3d_i = (_p3d_i + 1) % _p3d_pool.size()
	p.stream = _snd(name)
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.global_position = pos
	p.play()


func sfx(name: String, vol_db: float = 0.0) -> void:
	_play(name, vol_db)


func play_blip() -> void: _play_ui("blip")
func play_key() -> void: _play_ui("key", -4.0)
func play_select() -> void: _play_ui("select")
func play_success() -> void: _play_ui("success")
func play_fail() -> void: _play_ui("fail")
func play_glitch() -> void: _play("glitch")
func play_whoosh() -> void: _play("whoosh")
func play_levelup() -> void: _play_ui("levelup")
func play_quest() -> void: _play_ui("quest")
func play_discover() -> void: _play_ui("discover")
func play_dry() -> void: _play("dry")
func play_reload() -> void: _play("reload")
func play_swing() -> void: _play("swing", -3.0, randf_range(0.9, 1.1))
func play_punch() -> void: _play("punch", 0.0, randf_range(0.9, 1.1))
func play_thud() -> void: _play("thud", -4.0)
func play_hurt() -> void: _play("hurt", -2.0, randf_range(0.9, 1.1))
func play_pickup() -> void: _play_ui("pickup", -3.0)
func play_door() -> void: _play("door")
func play_heal() -> void: _play_ui("heal")
func play_coin() -> void: _play_ui("coin", -4.0)


func play_step() -> void:
	_step_flip = not _step_flip
	_play("step_a" if _step_flip else "step_b", -6.0, randf_range(0.9, 1.1))


func play_gunshot(model: String, silent: bool) -> void:
	_play(gun_sound(model, silent), -2.0, randf_range(0.95, 1.05))


func gun_sound(model: String, silent: bool) -> String:
	if silent:
		return "gun_silent"
	match model:
		"revolver", "magnum": return "gun_revolver"
		"smg", "smg_sil": return "gun_smg"
		"shotgun", "sawed": return "gun_shotgun"
		"rifle", "sniper": return "gun_rifle"
		"carbine", "ar": return "gun_carbine"
		"taser": return "gun_taser"
		"pistol_sil": return "gun_silent"
	return "gun_pistol"


# ---------------------------------------------------------------------- loops
func set_ambient(kind: String) -> void:
	# kind: street | interior | jazz | office | subway | none
	if kind == _ambient_kind:
		return
	_ambient_kind = kind
	_ambient.stop()
	_muzak.stop()
	_rumble.stop()
	match kind:
		"street":
			_ambient.stream = _city_loop()
			_ambient.volume_db = -16.0
			_ambient.play()
		"jazz":
			_ambient.stream = _jazz_loop()
			_ambient.volume_db = -20.0
			_ambient.play()
		"office":
			_muzak.stream = _muzak_loop()
			_muzak.volume_db = -22.0
			_muzak.play()
		"subway":
			_rumble.stream = _rumble_loop()
			_rumble.volume_db = -18.0
			_rumble.play()
		"interior":
			_ambient.stream = _room_tone()
			_ambient.volume_db = -24.0
			_ambient.play()


func start_rain() -> void:
	if _rain.playing:
		return
	if not _cache.has("rain"):
		var dur := 4.0
		var n := int(LOFI * dur)
		var s := PackedFloat32Array()
		s.resize(n)
		var prev := 0.0
		for i in n + LOFI:
			var white := randf() * 2.0 - 1.0
			prev = prev * 0.86 + white * 0.14
			if i < LOFI:
				continue
			var j := i - LOFI
			var tj := float(j) / LOFI
			var swell := 0.7 + 0.3 * sin(TAU * 0.25 * tj) * sin(TAU * 0.5 * tj + 1.3)
			s[j] = (prev * 2.2 + white * 0.12) * 0.5 * swell
		_cache["rain"] = _wav(s, LOFI, true)
	_rain.stream = _cache["rain"]
	_rain.volume_db = -16.0
	_rain.play()


func stop_rain() -> void:
	_rain.stop()


func siren(on: bool) -> void:
	if on and not _siren.playing:
		_siren.stream = _snd("siren")
		_siren.volume_db = -22.0
		_siren.play()
	elif not on and _siren.playing:
		_siren.stop()


func _city_loop() -> AudioStreamWAV:
	if _cache.has("city"):
		return _cache["city"]
	var dur := 8.0
	var n := int(LOFI * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var prev := 0.0
	var prev2 := 0.0
	for i in n:
		var t := float(i) / LOFI
		var white := randf() * 2.0 - 1.0
		prev = prev * 0.97 + white * 0.03
		prev2 = prev2 * 0.8 + white * 0.2
		var swell := 0.75 + 0.25 * sin(TAU * t / dur) * sin(TAU * 2.0 * t / dur + 0.7)
		var hum := sin(TAU * 55.0 * t) * 0.02
		var honk := 0.0
		var ht := fmod(t, 8.0)
		if ht > 5.2 and ht < 5.45:
			honk = (0.5 if sin(TAU * 350.0 * t) > 0.0 else -0.5) * 0.05
		s[i] = (prev * 3.0 * swell + prev2 * 0.05 + hum + honk) * 0.5
	var edge := int(LOFI * 0.5)
	for i in edge:
		var a := float(i) / float(edge)
		s[i] *= a
		s[n - 1 - i] *= a
	var st := _wav(s, LOFI, true)
	_cache["city"] = st
	return st


func _room_tone() -> AudioStreamWAV:
	if _cache.has("room"):
		return _cache["room"]
	var dur := 4.0
	var n := int(LOFI * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var prev := 0.0
	for i in n:
		var t := float(i) / LOFI
		prev = prev * 0.99 + (randf() * 2.0 - 1.0) * 0.01
		s[i] = prev * 2.0 + sin(TAU * 60.0 * t) * 0.012 + sin(TAU * 120.0 * t) * 0.006
	var st := _wav(s, LOFI, true)
	_cache["room"] = st
	return st


func _jazz_loop() -> AudioStreamWAV:
	if _cache.has("jazz"):
		return _cache["jazz"]
	var st := _compose("jazz", 8.0)
	_cache["jazz"] = st
	return st


func _muzak_loop() -> AudioStreamWAV:
	if _cache.has("muzak"):
		return _cache["muzak"]
	var notes := [261.63, 329.63, 392.0, 493.88, 392.0, 329.63, 293.66, 349.23, 440.0, 392.0, 349.23, 293.66]
	var dur := 9.6
	var n := int(LOFI * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var per: float = dur / float(notes.size())
	for i in n:
		var t := float(i) / LOFI
		var idx := int(t / per) % notes.size()
		var lt := fmod(t, per) / per
		var att := minf(lt / 0.25, 1.0) * minf((1.0 - lt) / 0.2, 1.0)
		var f: float = notes[idx]
		s[i] = (sin(TAU * f * t) * 0.45 + sin(TAU * f * 2.0 * t) * 0.1) * att * 0.3
	var st := _wav(s, LOFI, true)
	_cache["muzak"] = st
	return st


func _rumble_loop() -> AudioStreamWAV:
	if _cache.has("rumble"):
		return _cache["rumble"]
	var dur := 5.0
	var n := int(LOFI * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var prev := 0.0
	for i in n:
		var t := float(i) / LOFI
		var hum := sin(TAU * 38.0 * t) * 0.12 + sin(TAU * 76.5 * t) * 0.05
		prev = prev * 0.94 + (randf() * 2.0 - 1.0) * 0.06
		var clack := 0.0
		if fmod(t, 1.1) < 0.09:
			clack = (randf() * 2.0 - 1.0) * 0.6
		s[i] = (hum * 0.5 + prev * 1.2 + clack * 0.7) * 0.32
	var edge := int(LOFI * 0.4)
	for i in edge:
		var a := float(i) / float(edge)
		s[i] *= a
		s[n - 1 - i] *= a
	var st := _wav(s, LOFI, true)
	_cache["rumble"] = st
	return st


# ---------------------------------------------------------------------- radio
## Procedural composer: chord progressions + bass + drums, per station style.
func _compose(style: String, bar_len: float) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(style)
	var progs := {
		"jazz": [[146.83, 174.61, 220.0, 261.63], [196.0, 246.94, 293.66, 349.23], [130.81, 164.81, 196.0, 246.94], [110.0, 130.81, 164.81, 196.0]],
		"synth": [[110.0, 130.81, 164.81], [87.31, 110.0, 130.81], [130.81, 164.81, 196.0], [98.0, 123.47, 146.83]],
		"beats": [[174.61, 220.0, 261.63, 329.63], [164.81, 207.65, 246.94, 293.66], [146.83, 174.61, 220.0, 261.63], [130.81, 164.81, 196.0, 246.94]],
		"pirate": [[110.0, 130.81, 164.81], [103.83, 130.81, 155.56], [98.0, 116.54, 146.83], [92.5, 110.0, 138.59]],
	}
	var prog: Array = progs.get(style, progs["jazz"])
	var bars := prog.size() * 2
	var dur := bar_len * float(bars) / 2.0
	var rate := LOFI
	var n := int(rate * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var per := dur / float(bars)
	var bpm_beat := per / 4.0
	var hat_prev := 0.0
	for i in n:
		var t := float(i) / rate
		var bar := int(t / per)
		var chord: Array = prog[bar % prog.size()]
		var lt := fmod(t, per)
		var v := 0.0
		# Pad / chords.
		var swell := 0.6 + 0.4 * sin(PI * clampf(lt / per, 0.0, 1.0))
		for f in chord:
			var ff := float(f)
			if style == "synth":
				v += (fmod(ff * t, 1.0) * 2.0 - 1.0) * 0.05 * swell
			else:
				v += (sin(TAU * ff * t) * 0.16 + sin(TAU * ff * 2.0 * t) * 0.04) * swell
		# Bass on beats 1 and 3.
		var beat_t := fmod(lt, bpm_beat * 2.0)
		var root := float(chord[0]) * 0.5
		v += sin(TAU * root * t) * exp(-beat_t * 4.0) * 0.3
		# Arpeggio for synth.
		if style == "synth":
			var step_i := int(lt / (bpm_beat * 0.5)) % chord.size()
			var at := fmod(lt, bpm_beat * 0.5)
			v += sin(TAU * float(chord[step_i]) * 2.0 * t) * exp(-at * 10.0) * 0.18
		# Drums.
		if style == "beats" or style == "synth" or style == "pirate":
			var bt := fmod(lt, bpm_beat)
			var beat_n := int(lt / bpm_beat) % 4
			if beat_n == 0 or beat_n == 2:
				v += sin(TAU * (60.0 - bt * 80.0) * bt) * exp(-bt * 14.0) * 0.5
			else:
				v += (rng.randf() * 2.0 - 1.0) * exp(-bt * 22.0) * 0.18
			var ht := fmod(lt, bpm_beat * 0.5)
			hat_prev = hat_prev * 0.3 + (rng.randf() * 2.0 - 1.0) * 0.7
			v += hat_prev * exp(-ht * 60.0) * 0.05
		if style == "beats":
			v += (rng.randf() * 2.0 - 1.0) * 0.01 # vinyl crackle floor
		if style == "pirate":
			v = v * 0.8 + (rng.randf() * 2.0 - 1.0) * 0.04 * (0.5 + 0.5 * sin(t * 0.7))
		s[i] = v * 0.45
	var edge := int(rate * 0.3)
	for i in edge:
		var a := float(i) / float(edge)
		s[i] *= a
		s[n - 1 - i] *= a
	return _wav(s, rate, true)


func radio_play(station: String) -> void:
	if station == "" or not STATIONS.has(station):
		radio_stop()
		return
	radio_station = station
	if not _radio_streams.has(station):
		var bar := {"jazz": 4.0, "synth": 2.4, "beats": 3.2, "pirate": 3.6}.get(station, 3.0) as float
		_radio_streams[station] = _compose(station, bar)
	_radio.stream = _radio_streams[station]
	_radio.volume_db = -10.0
	_radio.play()


func radio_stop() -> void:
	radio_station = ""
	_radio.stop()


func radio_on() -> bool:
	return _radio.playing
