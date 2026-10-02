class_name DeathUI
extends Modal
## Game over. Load the latest save or quit to the menu.

var _msg: Label


func _build() -> void:
	var p := panel(600, 300)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(vb)
	var t := UI.label("PROCESS TERMINATED", 34, UI.RED)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	_msg = UI.label("", 17, UI.GREEN_DIM)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_msg)
	var load := UI.button("[ LOAD LAST SAVE ]", 20)
	load.alignment = HORIZONTAL_ALIGNMENT_CENTER
	load.pressed.connect(func() -> void:
		var s := SaveManager.latest_slot()
		if s != "" and SaveManager.load_slot(s):
			SceneRouter.goto_game()
		else:
			SceneRouter.goto_menu())
	vb.add_child(load)
	var menu := UI.button("[ MAIN MENU ]", 20)
	menu.alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.pressed.connect(func() -> void: SceneRouter.goto_menu())
	vb.add_child(menu)


func open() -> void:
	var lines := ["The city keeps running without you. It always did.", "Mr. Robot: \"Get up. We're not done.\" You don't.", "exit code 0x0000. No one files a report.", "Somewhere, a fish goes unfed."]
	_msg.text = lines[randi() % lines.size()]
	open_modal()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
