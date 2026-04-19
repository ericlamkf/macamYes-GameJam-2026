extends Control

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/levels/level_00.tscn")

func _on_quit_button_pressed() -> void:
	# This closes the game window instantly
	get_tree().quit()
