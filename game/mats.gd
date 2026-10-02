class_name Mats
extends RefCounted
## Shared materials. One instance of each so the renderer batches state.

static var facade: ShaderMaterial
static var lit: ShaderMaterial
static var glow: ShaderMaterial
static var city_lit: ShaderMaterial # city chunk props: same shader, can hide stolen cars
static var city_glow: ShaderMaterial
static var pool: ShaderMaterial
static var npc: ShaderMaterial
static var water: ShaderMaterial
static var sky: ShaderMaterial
static var ghost: StandardMaterial3D
static var _ready: bool = false


static func init() -> void:
	if _ready:
		return
	_ready = true
	facade = _sm("res://shaders/facade.gdshader")
	lit = _sm("res://shaders/vc_lit.gdshader")
	glow = _sm("res://shaders/vc_glow.gdshader")
	city_lit = _sm("res://shaders/vc_lit.gdshader")
	city_glow = _sm("res://shaders/vc_glow.gdshader")
	pool = _sm("res://shaders/light_pool.gdshader")
	npc = _sm("res://shaders/npc.gdshader")
	water = _sm("res://shaders/water.gdshader")
	sky = _sm("res://shaders/sky.gdshader")
	ghost = StandardMaterial3D.new()
	ghost.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost.albedo_color = Color(1, 1, 1, 0.0)


static func _sm(path: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(path)
	return m


## Boxes (Vector4: cx, cz, half x, half z) of parked cars to hide in the city.
static func set_hidden_cars(boxes: Array) -> void:
	var arr := PackedVector4Array()
	for b in boxes:
		arr.append(b)
	while arr.size() < 32:
		arr.append(Vector4(0, 0, 0, 0))
	for m in [city_lit, city_glow]:
		m.set_shader_parameter("hide_box", arr)
		m.set_shader_parameter("hide_n", mini(boxes.size(), 32))


## Last value handed to the shaders (reading a global shader parameter back
## is editor-only).
static var night: float = 0.0


static func set_night(n: float) -> void:
	night = n
	RenderingServer.global_shader_parameter_set("night_amt", n)


static func set_wet(w: float) -> void:
	RenderingServer.global_shader_parameter_set("wet_amt", w)


static func set_sky_col(c: Color) -> void:
	RenderingServer.global_shader_parameter_set("sky_col", c)
