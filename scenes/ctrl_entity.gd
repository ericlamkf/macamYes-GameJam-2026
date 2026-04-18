extends Node2D

@export var follow_speed := 1.0
@export var max_distance := 150
@export var stop_distance := 30

var player: CharacterBody2D
var attached := true

func _process(delta):
	if not player:
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
