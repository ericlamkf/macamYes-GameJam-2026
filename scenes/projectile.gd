extends Area2D
class_name Projectile

@export var speed: float = 200.0
var direction: Vector2 = Vector2.LEFT # Default shooting left
var source: Node # Tracks who fired it

func _physics_process(delta):
	position += direction * speed * delta

# Connect the screen_exited signal from VisibleOnScreenNotifier2D
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

# CTRL+C
func get_clipboard_data() -> ClipboardData:
	var data = ClipboardData.new()
	data.type = "projectile"
	data.data = {
		"speed": speed,
		"original_direction": direction
	}
	return data

extends Node2D

@export var speed = 10.0

func get_clipboard_data():
	return {
		"scene": preload("res://scenes/Projectile.tscn"),
		"type": "projectile"
	}
	
var started = false
var vector

func shoot(direction, position):
	global_position = position
	vector = direction
	look_at(global_position + vector)
	vector = direction * speed
	started = true
	
func _physics_process(delta):
	if(started):
		position += vector
