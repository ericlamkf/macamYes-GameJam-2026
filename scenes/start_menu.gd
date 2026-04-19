extends Control

func _ready() -> void:
	$VBoxContainer/StartButton.pressed.connect(_on_start)      
	$VBoxContainer/QuitButton.pressed.connect(_on_quit)        

func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/world/levels/level_00.tscn")

func _on_quit() -> void:
	get_tree().quit()
