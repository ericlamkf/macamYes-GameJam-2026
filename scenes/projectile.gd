extends Node2D

class_name Projectile

@export var speed: float = 20.0
var source: Node # Tracks who fired it
var direction: Vector2

var shot = false

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
	data.scene_ref = preload("res://scenes/projectile.tscn")
	return data

func shoot(source, direction):
	self.source = source
	self.direction = direction
	look_at(global_position + direction)
	self.direction = direction * speed
	print(direction)
	shot = true

func _physics_process(delta):
	if(shot):
		position += direction
