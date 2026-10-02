class_name Modal
extends CanvasLayer
## Base for full-screen menus: pauses the world while open.

signal closed

var game: Node = null
var root: Control
var _is_open: bool = false


func _init() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UI.theme()
	root.visible = false
	add_child(root)
	_build()


func _build() -> void:
	pass


func is_open() -> bool:
	return _is_open


func open_modal() -> void:
	if _is_open:
		return
	_is_open = true
	root.visible = true
	if game != null:
		game.push_ui()
	if Pad.using_pad or not Pad._no_pad():
		_pad_focus.call_deferred()


## On a pad something must be selected the moment a screen opens.
func _pad_focus() -> void:
	if not _is_open:
		return
	var cur := root.get_viewport().gui_get_focus_owner()
	if cur != null and root.is_ancestor_of(cur) and cur.is_visible_in_tree():
		return
	var b := _first_button(root)
	if b != null:
		b.grab_focus()


func close_modal() -> void:
	if not _is_open:
		return
	_is_open = false
	root.visible = false
	if game != null:
		game.pop_ui()
	emit_signal("closed")


func panel(w: float, h: float) -> PanelContainer:
	var dim := UI.dim_rect(0.72)
	root.add_child(dim)
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(w, h)
	p.position = Vector2(-w * 0.5, -h * 0.5)
	p.size = Vector2(w, h)
	p.add_theme_stylebox_override("panel", UI.box(Color(0.0, 0.035, 0.018, 0.98), UI.GREEN_DIM, 2, 16))
	root.add_child(p)
	return p


func clear(c: Node) -> void:
	# A rebuilt list frees the button the pad / keyboard was on: put focus back on
	# whatever lands in the same slot, so A-A-A down a loot list just works.
	var fo := c.get_viewport().gui_get_focus_owner() if c.is_inside_tree() else null
	if fo != null and c.is_ancestor_of(fo):
		var slot: Node = fo
		while slot.get_parent() != c:
			slot = slot.get_parent()
		_refocus_in = c
		_refocus_idx = slot.get_index()
		_restore_focus.call_deferred()
	for ch in c.get_children():
		c.remove_child(ch)
		ch.queue_free()


var _refocus_in: Node = null
var _refocus_idx: int = 0


func _restore_focus() -> void:
	var c := _refocus_in
	_refocus_in = null
	if c == null or not is_instance_valid(c) or not c.is_inside_tree() or not _is_open:
		return
	var cur := c.get_viewport().gui_get_focus_owner()
	if cur != null and cur.is_visible_in_tree():
		return
	var kids := c.get_children()
	if kids.is_empty():
		return
	# Same slot first, then outward.
	for off in kids.size():
		for idx in [_refocus_idx + off, _refocus_idx - off]:
			if idx < 0 or idx >= kids.size():
				continue
			var b := _first_button(kids[idx])
			if b != null:
				b.grab_focus()
				return


## First focusable control, depth-first in screen order (buttons, checkboxes,
## dropdowns and sliders).
static func _first_button(n: Node) -> Control:
	if (n is BaseButton or n is Range) and not (n is BaseButton and (n as BaseButton).disabled) and (n as Control).focus_mode != Control.FOCUS_NONE and (n as Control).is_visible_in_tree() and not (n is ScrollBar):
		return n as Control
	for ch in n.get_children():
		var b := _first_button(ch)
		if b != null:
			return b
	return null
