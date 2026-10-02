class_name WorldEnv
extends Node3D
## Day/night cycle, sky, fog, weather (clear/overcast/rain), interior lighting.

var env: Environment
var sun: DirectionalLight3D
var sky_mat: ShaderMaterial
var interior: bool = false
var interior_ambient: Color = Color(0.3, 0.28, 0.25)
var rain_amt: float = 0.0
var cloud_amt: float = 0.3
var _rain_layer: CanvasLayer
var _rain_rect: ColorRect
var _rain_mat: ShaderMaterial
var _particles: CPUParticles3D
var _wet: float = 0.0
var _last_weather_check: float = -1.0


func _ready() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky_mat = Mats.sky
	sky.sky_material = sky_mat
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_density = 0.002
	env.fog_sky_affect = 0.6
	env.glow_enabled = bool(Settings.get_v("glow"))
	env.glow_intensity = 0.5
	env.glow_strength = 0.95
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.85
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	# Tight halo on signs and windows plus a wide soft bloom at night.
	env.set_glow_level(1, 0.6)
	env.set_glow_level(2, 1.0)
	env.set_glow_level(4, 0.8)
	env.set_glow_level(5, 0.5)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.light_bake_mode = Light3D.BAKE_DISABLED
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_fade_start = 0.85
	add_child(sun)
	_apply_quality()
	# Rain overlay + particles.
	_rain_layer = CanvasLayer.new()
	_rain_layer.layer = 5
	add_child(_rain_layer)
	_rain_rect = ColorRect.new()
	_rain_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rain_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rain_mat = ShaderMaterial.new()
	_rain_mat.shader = load("res://shaders/rain_overlay.gdshader")
	_rain_rect.material = _rain_mat
	_rain_rect.visible = false
	_rain_layer.add_child(_rain_rect)
	_particles = CPUParticles3D.new()
	_particles.amount = 700
	_particles.lifetime = 0.9
	_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_particles.emission_box_extents = Vector3(18, 1, 18)
	_particles.direction = Vector3(0.05, -1, 0)
	_particles.spread = 2.0
	_particles.gravity = Vector3(0, -30, 0)
	_particles.initial_velocity_min = 16.0
	_particles.initial_velocity_max = 20.0
	var qm := BoxMesh.new()
	qm.size = Vector3(0.012, 0.5, 0.012)
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.albedo_color = Color(0.7, 0.75, 0.85, 0.35)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.material = pm
	_particles.mesh = qm
	_particles.emitting = false
	_particles.local_coords = false
	add_child(_particles)
	Settings.applied.connect(_apply_quality)


## Graphics settings that live on the environment and the sun.
func _apply_quality() -> void:
	env.glow_enabled = bool(Settings.get_v("glow"))
	var sq := int(Settings.get_v("shadow_q"))
	sun.shadow_enabled = sq > 0 and not interior
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if sq >= 2 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 150.0 if sq >= 2 else 70.0
	sun.shadow_blur = 1.4 if sq >= 2 else 1.0
	# Colour grade: a touch more contrast and colour, like the show's
	# cold-shadow / warm-light look.
	var g := bool(Settings.get_v("grade"))
	env.adjustment_enabled = g
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.07
	env.adjustment_saturation = 1.12


func set_interior(on: bool, ambient: Color = Color(0.3, 0.28, 0.25)) -> void:
	interior = on
	interior_ambient = ambient
	if on:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0, 0, 0)
		env.fog_enabled = false
		# Interiors are lit mostly by ambient: dark furniture must still read
		# (vertex colors are converted to linear, so 0.2 grey is ~0.03 light).
		env.ambient_light_color = ambient.lerp(Color(0.46, 0.44, 0.41), 0.35)
		env.ambient_light_energy = 2.7
		env.tonemap_exposure = 1.12
		sun.visible = false
		Mats.set_night(1.0)
		Mats.set_wet(0.0)
		_rain_rect.visible = false
		_particles.emitting = false
		AudioManager.stop_rain()
	else:
		env.background_mode = Environment.BG_SKY
		env.fog_enabled = true
		sun.visible = true
		env.tonemap_exposure = 1.0


func _process(delta: float) -> void:
	_update_weather()
	if interior:
		return
	var h := GameState.hour()
	# Sun elevation: rises 6:00, peaks 13:00, sets 20:00.
	var elev := -0.35
	if h >= 5.5 and h <= 20.5:
		elev = sin((h - 5.5) / 15.0 * PI)
	var dayf := smoothstep(-0.05, 0.3, elev)
	var golden := clampf(1.0 - absf(elev - 0.08) / 0.22, 0.0, 1.0) * float(h > 4.0 and h < 22.0)
	var over := cloud_amt
	var target_rain := 1.0 if GameState.weather == "rain" else 0.0
	rain_amt = move_toward(rain_amt, target_rain, delta * 0.08)
	_wet = move_toward(_wet, target_rain, delta * (0.05 if target_rain > _wet else 0.01))
	var gloom := clampf(over * 0.6 + rain_amt * 0.5, 0.0, 1.0)
	# Sky colors.
	var top_n := Vector3(0.01, 0.015, 0.035)
	var top_d := Vector3(0.22, 0.38, 0.66).lerp(Vector3(0.35, 0.38, 0.42), gloom)
	var hor_n := Vector3(0.07, 0.055, 0.08)
	var hor_d := Vector3(0.66, 0.72, 0.78).lerp(Vector3(0.5, 0.52, 0.55), gloom)
	var top := top_n.lerp(top_d, dayf)
	var hor := hor_n.lerp(hor_d, dayf).lerp(Vector3(0.95, 0.5, 0.28), golden * 0.7 * (1.0 - gloom))
	var glow_c := Vector3(0.38, 0.2, 0.1).lerp(Vector3(0.1, 0.08, 0.05), dayf)
	sky_mat.set_shader_parameter("top_col", top)
	sky_mat.set_shader_parameter("hor_col", hor)
	sky_mat.set_shader_parameter("glow_col", glow_c)
	sky_mat.set_shader_parameter("night", 1.0 - dayf)
	sky_mat.set_shader_parameter("cloud", clampf(0.25 + over * 0.6 + rain_amt * 0.4, 0.0, 0.95))
	# Sun / moon.
	var ang := (h - 5.5) / 15.0 * PI
	var sun_dir := Vector3(cos(ang), sin(ang) * 0.9 + 0.05, -0.35).normalized()
	if dayf < 0.05:
		var ma := (fmod(h + 12.0, 24.0) - 5.5) / 15.0 * PI
		sun_dir = Vector3(cos(ma) * 0.6, maxf(0.35, sin(ma)), 0.4).normalized()
	sky_mat.set_shader_parameter("sun_dir", sun_dir)
	var sun_col := Color(0.55, 0.65, 1.0).lerp(Color(1.0, 0.94, 0.84), dayf).lerp(Color(1.0, 0.55, 0.3), golden * 0.6)
	sky_mat.set_shader_parameter("sun_col", Vector3(sun_col.r, sun_col.g, sun_col.b) * (1.0 - gloom * 0.8))
	sun.light_color = sun_col
	sun.light_energy = lerpf(0.18, 1.35, dayf) * (1.0 - gloom * 0.6)
	sun.look_at_from_position(Vector3.ZERO, -sun_dir, Vector3.UP if absf(sun_dir.y) < 0.99 else Vector3.FORWARD)
	# Ambient + fog.
	var amb_n := Color(0.2, 0.22, 0.33)
	var amb_d := Color(0.58, 0.62, 0.7)
	env.ambient_light_color = amb_n.lerp(amb_d, dayf).lerp(Color(0.4, 0.42, 0.45), gloom * 0.5)
	env.ambient_light_energy = lerpf(0.95, 1.0, dayf)
	var fog_n := Color(0.05, 0.05, 0.075)
	var fog_d := Color(0.6, 0.65, 0.72)
	env.fog_light_color = fog_n.lerp(fog_d, dayf).lerp(Color(0.35, 0.37, 0.4) * lerpf(0.3, 1.0, dayf), gloom)
	var far := Settings.view_far()
	var base_density := 1.1 / far
	env.fog_density = base_density * (1.0 + rain_amt * 1.6 + over * 0.3) * lerpf(1.6, 1.0, dayf)
	# Up high (the Twin Towers' roof) the haze thins so you can see the city.
	var cam0 := get_viewport().get_camera_3d()
	if cam0 != null and cam0.global_position.y > 30.0:
		env.fog_density *= lerpf(1.0, 0.18, clampf((cam0.global_position.y - 30.0) / 250.0, 0.0, 1.0))
	Mats.set_night(1.0 - dayf)
	Mats.set_wet(_wet)
	Mats.set_sky_col(Color(hor.x, hor.y, hor.z).lerp(Color(top.x, top.y, top.z), 0.4))
	# Rain visuals.
	_rain_rect.visible = rain_amt > 0.02
	_rain_mat.set_shader_parameter("amount", rain_amt)
	_particles.emitting = rain_amt > 0.3
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		_particles.global_position = cam.global_position + Vector3(0, 12, 0) - cam.global_transform.basis.z * 6.0
	if rain_amt > 0.3:
		AudioManager.start_rain()
	elif rain_amt < 0.1:
		AudioManager.stop_rain()


func _update_weather() -> void:
	# Weather changes every few game hours.
	if GameState.game_minutes < GameState.weather_until:
		cloud_amt = move_toward(cloud_amt, 0.9 if GameState.weather != "clear" else 0.25, 0.001)
		return
	var r := randf()
	if r < 0.55:
		GameState.weather = "clear"
	elif r < 0.8:
		GameState.weather = "overcast"
	else:
		GameState.weather = "rain"
	GameState.weather_until = GameState.game_minutes + randf_range(120.0, 360.0)
