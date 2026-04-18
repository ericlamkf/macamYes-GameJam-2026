extends Area2D

var activated := false
var player_inside := false

const COLOR_INACTIVE = Color(0.4, 0.4, 0.4, 1.0)  # grey
const COLOR_ACTIVE   = Color(1.0, 0.85, 0.0, 1.0)  # gold

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Restore gold color if this checkpoint was the last saved one
	if GameState.spawn_position != Vector2.ZERO and global_position.is_equal_approx(GameState.spawn_position):
		activated = true
	_update_color()

func _update_color() -> void:
	var visual = get_node_or_null("Visual")
	if visual:
		visual.modulate = COLOR_ACTIVE if activated else COLOR_INACTIVE

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _input(event: InputEvent) -> void:
	if player_inside and not activated:
		if event is InputEventKey and event.pressed and event.keycode == KEY_S:
			activated = true
			GameState.spawn_position = global_position
			_update_color()
