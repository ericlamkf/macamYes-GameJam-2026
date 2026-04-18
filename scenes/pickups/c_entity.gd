extends Node2D

func _ready() -> void:
	if "c" in GameState.collected_keys:
		queue_free()
		return
	$Area2D.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.collect_key("c")
		queue_free()
