extends Node2D

@export var follow_speed := 1.0
@export var max_distance := 150
@export var stop_distance := 30

var player: CharacterBody2D
var attached := true

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if GameState.ctrl_position != Vector2.ZERO:
		global_position = GameState.ctrl_position
	GameState.ctrl_position_locked = false

func _exit_tree() -> void:
	if not GameState.ctrl_position_locked:
		GameState.ctrl_position = global_position

func _process(delta):
	if not player:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		return

	check_detach()

	if attached:
		follow_player(delta)


func follow_player(delta):
	if global_position.distance_to(player.global_position) <= 30:
		return
		
	global_position = global_position.lerp(
		player.global_position,
		follow_speed * delta
	)

func check_detach():
	if global_position.distance_to(player.global_position) > max_distance:
		detach()
	else:
		reattach()

func detach():
	attached = false
	GameState.ctrl_attached = false

	# trigger chaos effect
	player.controls_inverted_signal = true

func reattach():
	attached = true
	GameState.ctrl_attached = true

	# trigger chaos effect
	player.controls_inverted_signal = false
