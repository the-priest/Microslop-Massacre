extends Node
## Settings — persisted player options. Everything that makes the game look
## good is ON by default (Ultra preset). On a Ryzen 4650U class iGPU, pick the
## High or Medium preset in Settings if the frame rate dips.

signal applied

const PATH := "user://settings.cfg"
## Bump when the graphics defaults change: older settings files get the new
## graphics defaults once (audio / controls are kept).
const GFX_REV := 2
const GFX_KEYS := ["gfx_preset", "render_scale", "view_distance", "crowd_density", "traffic_density", "shadow_q", "aa", "glow", "grade"]

## Graphics presets (index = gfx_preset; PRESETS.size() = Custom).
const PRESETS := [
	{"render_scale": 0.75, "view_distance": 0, "crowd_density": 0, "traffic_density": 0, "shadow_q": 0, "aa": 1, "glow": true, "grade": true},
	{"render_scale": 0.85, "view_distance": 1, "crowd_density": 1, "traffic_density": 1, "shadow_q": 0, "aa": 1, "glow": true, "grade": true},
	{"render_scale": 1.0, "view_distance": 1, "crowd_density": 1, "traffic_density": 1, "shadow_q": 1, "aa": 2, "glow": true, "grade": true},
	{"render_scale": 1.0, "view_distance": 2, "crowd_density": 2, "traffic_density": 2, "shadow_q": 2, "aa": 3, "glow": true, "grade": true},
]

var values := {
	"fullscreen": false,
	"vsync": true,
	"gfx_preset": 3, # 0 low, 1 medium, 2 high, 3 ultra, 4 custom
	"render_scale": 1.0,
	"view_distance": 2, # 0 near, 1 normal, 2 far
	"crowd_density": 2, # 0 low, 1 normal, 2 high
	"traffic_density": 2,
	"shadow_q": 2, # 0 off, 1 low, 2 high
	"aa": 3, # 0 off, 1 FXAA, 2 MSAA 2x, 3 MSAA 4x
	"glow": true,
	"grade": true, # filmic colour grade
	"gfx_rev": GFX_REV,
	"crt": true,
	"fov": 75.0,
	"mouse_sens": 1.0,
	"invert_y": false,
	"master_volume": 0.8,
	"music_volume": 0.6,
	"sfx_volume": 0.9,
	"voice_volume": 1.0,
	"show_markers": true,
	"subtitles_speed": 1.0,
	"max_fps": 0,
	"skip_intro": false,
	"pad_sens": 1.0,
	"pad_rumble": true,
}


func _ready() -> void:
	load_settings()
	apply()


func get_v(k: String) -> Variant:
	return values.get(k)


func set_v(k: String, v: Variant) -> void:
	values[k] = v


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	var old_gfx := int(cfg.get_value("s", "gfx_rev", 0)) < GFX_REV
	for k in values.keys():
		if old_gfx and k in GFX_KEYS:
			continue
		if cfg.has_section_key("s", k):
			var v: Variant = cfg.get_value("s", k)
			# Keep the type of the default.
			var def: Variant = values[k]
			if def is bool:
				values[k] = bool(v)
			elif def is int:
				values[k] = int(v)
			elif def is float:
				values[k] = float(v)
			else:
				values[k] = v
	values["gfx_rev"] = GFX_REV


## Apply a preset's values (call apply() after).
func set_preset(i: int) -> void:
	values["gfx_preset"] = i
	if i >= 0 and i < PRESETS.size():
		for k in PRESETS[i]:
			values[k] = PRESETS[i][k]


## A manual graphics change that leaves the preset switches the label to Custom.
func mark_custom() -> void:
	var i := int(values["gfx_preset"])
	if i < 0 or i >= PRESETS.size():
		return
	for k in PRESETS[i]:
		if values[k] != PRESETS[i][k]:
			values["gfx_preset"] = PRESETS.size()
			return


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in values.keys():
		cfg.set_value("s", k, values[k])
	cfg.save(PATH)


func apply() -> void:
	if DisplayServer.get_name() == "headless":
		emit_signal("applied")
		return
	var win := get_window()
	if bool(values["fullscreen"]):
		win.mode = Window.MODE_FULLSCREEN
	elif win.mode == Window.MODE_FULLSCREEN:
		win.mode = Window.MODE_WINDOWED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(values["vsync"]) else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = int(values["max_fps"])
	var vp := get_viewport()
	vp.scaling_3d_scale = clampf(float(values["render_scale"]), 0.5, 1.0)
	var aa := clampi(int(values["aa"]), 0, 3)
	vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][aa]
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if aa == 1 else Viewport.SCREEN_SPACE_AA_DISABLED
	var sq := int(values["shadow_q"])
	RenderingServer.directional_shadow_atlas_set_size(4096 if sq >= 2 else 2048, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW if sq >= 2 else RenderingServer.SHADOW_QUALITY_HARD)
	_apply_audio()
	emit_signal("applied")


func _apply_audio() -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(0.0001, float(values["master_volume"]))))


func view_far() -> float:
	return [380.0, 620.0, 900.0][clampi(int(values["view_distance"]), 0, 2)]


func crowd_count() -> int:
	return [14, 26, 40][clampi(int(values["crowd_density"]), 0, 2)]


func traffic_count() -> int:
	return [8, 16, 26][clampi(int(values["traffic_density"]), 0, 2)]
