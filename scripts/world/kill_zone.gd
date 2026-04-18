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

		# Play random death sound
		var dead_sounds = ["res://assets/audio/music/dead.mp3", "res://assets/audio/music/dead_2.mp3"]
		var sfx = AudioStreamPlayer.new()
		sfx.stream = load(dead_sounds[randi() % dead_sounds.size()])
		sfx.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().current_scene.add_child(sfx)
		sfx.play()

		get_tree().paused = true
		var scene = death_screen_scene if death_screen_scene else load("res://scenes/player/dead_scene.tscn")
		if scene:
			var death_ui = scene.instantiate()
			get_tree().current_scene.add_child(death_ui)
