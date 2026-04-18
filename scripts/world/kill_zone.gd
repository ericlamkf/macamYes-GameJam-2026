extends Area2D

# This creates a slot in the Inspector to drop your dead_scene.tscn into
@export var death_screen_scene: PackedScene

var _triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if body.is_in_group("player"):
		_triggered = true
		GameState.reset_clipboard()
		GameState.player_health = 100

		# 1. Freeze the game immediately so the player stops falling
		get_tree().paused = true

		# 2. Spawn the Death Screen
		if death_screen_scene:
			var death_ui = death_screen_scene.instantiate()
			get_tree().current_scene.add_child(death_ui)
		else:
			print("DEV C WARNING: You forgot to assign the death_screen_scene in the Inspector!")
