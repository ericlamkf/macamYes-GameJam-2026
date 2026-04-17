extends Area2D

var activated := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not activated:
		activated = true
		GameState.spawn_position = global_position
