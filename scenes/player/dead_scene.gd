extends CanvasLayer

var _restarting := false

func _input(event: InputEvent) -> void:
	if _restarting:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_restarting = true
		restart_from_checkpoint()

func restart_from_checkpoint() -> void:
	get_tree().paused = false
	GameState.reset_clipboard()
	GameState.player_health = 100
	get_tree().reload_current_scene()
