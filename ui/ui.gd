class_name UI
extends RefCounted
## Shared UI look: phosphor-green terminal on black, red for Mr. Robot.

const GREEN := Color(0.25, 1.0, 0.55)
const GREEN_DIM := Color(0.15, 0.55, 0.32)
const GREEN_DARK := Color(0.02, 0.08, 0.04)
const RED := Color(1.0, 0.28, 0.3)
const AMBER := Color(1.0, 0.75, 0.3)
const WHITE := Color(0.9, 0.95, 0.92)
const GREY := Color(0.55, 0.6, 0.58)
const BLUE := Color(0.45, 0.7, 1.0)
const BG := Color(0.0, 0.02, 0.01, 0.94)

static var _mono: Font
static var _sign: Font
static var _theme: Theme


static func mono() -> Font:
	if _mono == null:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["JetBrains Mono", "DejaVu Sans Mono", "Liberation Mono", "Consolas", "Courier New", "monospace"])
		_mono = sf
	return _mono


## Spray-paint lettering for graffiti: the heaviest condensed face around.
static var _graffiti: Font = null


static func font_graffiti() -> Font:
	if _graffiti == null:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["Impact", "Haettenschweiler", "DejaVu Sans Condensed", "Liberation Sans Narrow", "Arial Black", "sans-serif"])
		sf.font_weight = 900
		sf.font_italic = true
		_graffiti = sf
	return _graffiti


static func font_sign() -> Font:
	if _sign == null:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["DejaVu Sans", "Liberation Sans", "Arial", "Helvetica", "sans-serif"])
		sf.font_weight = 700
		_sign = sf
	return _sign


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = mono()
	t.default_font_size = 18
	for cls in ["Label", "Button", "LineEdit", "RichTextLabel", "CheckBox", "OptionButton", "ItemList"]:
		t.set_color("font_color", cls, GREEN)
	t.set_color("default_color", "RichTextLabel", WHITE)
	t.set_color("font_hover_color", "Button", Color(0, 0, 0))
	t.set_color("font_focus_color", "Button", Color(0, 0, 0))
	t.set_color("font_pressed_color", "Button", Color(0, 0, 0))
	t.set_color("font_disabled_color", "Button", GREEN_DIM * Color(1, 1, 1, 0.6))
	var normal := box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0)
	var hover := box(GREEN, GREEN, 0)
	var dis := box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", hover)
	t.set_stylebox("focus", "Button", box(GREEN, GREEN, 0))
	t.set_stylebox("disabled", "Button", dis)
	t.set_stylebox("panel", "PanelContainer", box(BG, GREEN_DIM, 2))
	t.set_stylebox("panel", "Panel", box(BG, GREEN_DIM, 2))
	var le := box(Color(0, 0.06, 0.03), GREEN_DIM, 1)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le)
	t.set_color("caret_color", "LineEdit", GREEN)
	t.set_stylebox("background", "ProgressBar", box(Color(0, 0.08, 0.04), GREEN_DIM, 1))
	t.set_stylebox("fill", "ProgressBar", box(GREEN, GREEN, 0))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0.1, 0.05)
	t.set_stylebox("scroll", "VScrollBar", sb)
	var grab := StyleBoxFlat.new()
	grab.bg_color = GREEN_DIM
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	t.set_stylebox("slider", "HSlider", box(Color(0, 0.1, 0.05), GREEN_DIM, 1))
	t.set_stylebox("grabber_area", "HSlider", box(GREEN_DIM, GREEN_DIM, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(GREEN, GREEN, 0))
	_theme = t
	return t


static func box(bg: Color, border: Color, bw: int, pad: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	return s


static func label(text: String, size: int = 18, color: Color = GREEN) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", mono())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, size: int = 18) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	return b


static func rich(size: int = 17) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.add_theme_font_override("normal_font", mono())
	r.add_theme_font_override("bold_font", mono())
	r.add_theme_font_override("italics_font", mono())
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_color_override("default_color", WHITE)
	return r


static func speaker_color(speaker: String) -> Color:
	var s := speaker.get_slice(" (", 0).strip_edges().to_upper()
	match s:
		"ELLIOT": return GREEN
		"MR. ROBOT", "MR ROBOT": return RED
		"DARLENE": return Color(0.9, 0.55, 1.0)
		"ANGELA": return Color(0.45, 0.95, 0.9)
		"TYRELL": return Color(0.55, 0.7, 1.0)
		"WHITEROSE": return Color(1.0, 0.45, 0.6)
		"KRISTA": return Color(0.95, 0.85, 0.6)
		"SHAYLA": return Color(1.0, 0.6, 0.8)
		"DIPIERRO", "AGENT DIPIERRO": return Color(0.7, 0.8, 1.0)
		"VERA": return Color(1.0, 0.5, 0.3)
		"GIDEON": return Color(0.6, 0.75, 0.95)
		"LEON": return Color(0.95, 0.8, 0.4)
	return Color(0.85, 0.9, 0.88)


static func dim_rect(alpha: float = 0.6) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, alpha)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r
