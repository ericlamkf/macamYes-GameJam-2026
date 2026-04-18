extends Area2D

@export var next_level_path: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and next_level_path != "":
		GameState.spawn_position = Vector2.ZERO
		GameState.ctrl_position = Vector2.ZERO
		GameState.ctrl_position_locked = true
		get_tree().change_scene_to_file(next_level_path)
