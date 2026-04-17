extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var spawn = get_tree().get_first_node_in_group("player_spawn")
		if spawn:
			body.global_position = spawn.global_position
			body.velocity = Vector2.ZERO
