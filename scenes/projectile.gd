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
