class_name IntakeUI
extends Modal
## Character creation, disguised as Krista's intake form: three tag skills
## (+15 each) and up to two traits.

var _tags: Array = []
var _traits: Array = []
var _skill_box: VBoxContainer
var _trait_box: VBoxContainer
var _info: RichTextLabel
var _confirm: Button


func _build() -> void:
	var p := panel(1100, 660)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	vb.add_child(UI.label("PATIENT INTAKE FORM  ·  KRISTA GORDON, LCSW", 22, UI.WHITE))
	vb.add_child(UI.label("Name: Elliot Alderson.  Occupation: cybersecurity engineer, Allsafe.  Referred by: himself, reluctantly.", 15, UI.GREEN_DIM))
	var hb := HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.add_theme_constant_override("separation", 24)
	vb.add_child(hb)
	var l := VBoxContainer.new()
	l.custom_minimum_size = Vector2(420, 0)
	hb.add_child(l)
	l.add_child(UI.label("\"What are you good at?\"  (tag 3 skills, +15)", 16, UI.AMBER))
	_skill_box = VBoxContainer.new()
	l.add_child(_skill_box)
	var r := VBoxContainer.new()
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(r)
	r.add_child(UI.label("\"Anything else I should know?\"  (up to 2 traits, optional)", 16, UI.AMBER))
	var sc := ScrollContainer.new()
	sc.follow_focus = true
	sc.custom_minimum_size = Vector2(0, 260)
	r.add_child(sc)
	_trait_box = VBoxContainer.new()
	_trait_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_trait_box)
	_info = UI.rich(15)
	_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r.add_child(_info)
	_confirm = UI.button("[ SIGN THE FORM ]", 20)
	_confirm.pressed.connect(_on_confirm)
	vb.add_child(_confirm)


func open() -> void:
	_tags = ["hacking", "sneak", "speech"]
	_traits = []
	open_modal()
	_refresh()
	await closed


func _refresh() -> void:
	clear(_skill_box)
	for s in DB.SKILLS:
		var ss := str(s)
		var on := _tags.has(ss)
		var b := UI.button("%s %-10s %d" % ["★" if on else "·", DB.SKILL_NAMES[ss], 30 if on else 15], 18)
		b.add_theme_color_override("font_color", UI.WHITE if on else UI.GREEN)
		b.pressed.connect(func() -> void:
			if _tags.has(ss):
				_tags.erase(ss)
			elif _tags.size() < 3:
				_tags.append(ss)
			AudioManager.play_key()
			_refresh())
		b.mouse_entered.connect(func() -> void: _info.text = "[b]%s[/b]\n%s" % [DB.SKILL_NAMES[ss], DB.SKILL_DESC[ss]])
		b.focus_entered.connect(func() -> void: _info.text = "[b]%s[/b]\n%s" % [DB.SKILL_NAMES[ss], DB.SKILL_DESC[ss]])
		_skill_box.add_child(b)
	clear(_trait_box)
	for t in DB.TRAITS:
		var td: Dictionary = t
		var id := str(td["id"])
		var on2 := _traits.has(id)
		var b2 := UI.button("%s %s" % ["■" if on2 else "□", str(td["name"])], 17)
		b2.add_theme_color_override("font_color", UI.WHITE if on2 else UI.GREEN)
		b2.pressed.connect(func() -> void:
			if _traits.has(id):
				_traits.erase(id)
			elif _traits.size() < 2:
				_traits.append(id)
			AudioManager.play_key()
			_refresh())
		b2.mouse_entered.connect(func() -> void: _info.text = "[b]%s[/b]\n%s" % [str(td["name"]), str(td["desc"])])
		b2.focus_entered.connect(func() -> void: _info.text = "[b]%s[/b]\n%s" % [str(td["name"]), str(td["desc"])])
		_trait_box.add_child(b2)
	_confirm.disabled = _tags.size() != 3
	_confirm.text = "[ SIGN THE FORM ]" if _tags.size() == 3 else "[ tag %d more ]" % (3 - _tags.size())


func _on_confirm() -> void:
	if _tags.size() != 3:
		return
	GameState.set_tags(_tags)
	GameState.traits = _traits.duplicate()
	if GameState.has_trait("robot_kid"):
		GameState.adjust_stability(-10)
	AudioManager.play_success()
	close_modal()
