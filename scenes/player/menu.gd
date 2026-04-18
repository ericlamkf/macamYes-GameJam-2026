extends Control

@onready var buttons = [$PanelContainer/VBoxContainer/Resume, $PanelContainer/VBoxContainer/Restart, $PanelContainer/VBoxContainer/Quit]
var selected_index := 0

func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_process_mode_recursive(self, Node.PROCESS_MODE_ALWAYS)
	$PanelContainer/VBoxContainer/Resume.pressed.connect(_on_resume)
	$PanelContainer/VBoxContainer/Restart.pressed.connect(_on_restart)
	$PanelContainer/VBoxContainer/Quit.pressed.connect(_on_quit)
	_highlight(selected_index)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if visible:
			_close()
		else:
			_open()
		accept_event()
		return

	if not visible:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_S:
			selected_index = (selected_index + 1) % buttons.size()
			_highlight(selected_index)
			accept_event()
		elif event.keycode == KEY_W:
			selected_index = (selected_index - 1 + buttons.size()) % buttons.size()
			_highlight(selected_index)
			accept_event()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			buttons[selected_index].pressed.emit()
			accept_event()
		elif event.keycode == KEY_C:
			_on_resume()
			accept_event()
		elif event.keycode == KEY_R:
			_on_restart()
			accept_event()

func _open() -> void:
	visible = true
	selected_index = 0
	_highlight(selected_index)
	get_tree().paused = true

func _close() -> void:
	visible = false
	get_tree().paused = false

func _highlight(index: int) -> void:
	for i in buttons.size():
		if i == index:
			buttons[i].grab_focus()
		else:
			buttons[i].release_focus()

func _on_resume() -> void:
	_close()

func _on_restart() -> void:
	get_tree().paused = false
	GameState.reset_clipboard()
	get_tree().reload_current_scene()

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().quit()

func _set_process_mode_recursive(node: Node, mode: int) -> void:
	node.process_mode = mode
	for child in node.get_children():
		_set_process_mode_recursive(child, mode)
