extends Area2D

class_name Projectile

@export var speed: float = 200.0
var source: Node # Tracks who fired it
var direction: Vector2
var shot = false
var projectile_damage

@onready var label = $Label
@onready var collision_shape = $CollisionShape2D

# Connect the screen_exited signal from VisibleOnScreenNotifier2D
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _ready():
	var rand = randi_range(4, 6)
	var string = ""
	var length = 0
	for i in rand:
		var integer = randi_range(0, 1)
		string += str(integer)
		if integer == 1:
			length += 3
		else:
			length += 5
	projectile_damage = string.bin_to_int()

	label.text = string

	change_collision_width(length)
	visible = false

func change_collision_width(new_width: float):
	var shape = collision_shape.shape
	var old_width = shape.size.x
	
	# Update the sizev
	shape.size.x = new_width
	
	# Calculate how much we grew
	var growth = (new_width - old_width) / 2
	
	# Shift the node so it looks "anchored" to the left
	collision_shape.position.x += growth

# CTRL+C
func get_clipboard_data() -> ClipboardData:
	var data = ClipboardData.new()
	data.type = "projectile"
	data.data = {
		"speed": speed,
		"original_direction": direction
	}
	data.scene_ref = self.scene_file_path
	return data

func shoot(source, direction):
	if direction.x < 0:
		label.scale.y = -1
		label.position.y = 3
	else:
		label.scale.y = 1
		label.position.y = -4
	
	self.source = source
	self.direction = direction
	look_at(global_position + direction)
	self.direction = direction * speed
	
	set_collision_mask_value(source.collision_layer, false)
	shot = true

func _physics_process(delta):
	if(shot):
		visible = true
		position += direction * delta
		

func _on_area_entered(area: Area2D):
	print(area)
	# The 'area' is the Hurtbox of the enemy
	if area.has_method("take_damage"):
		area.take_damage(projectile_damage)             # Send it to the target
		
	queue_free() # Destroy the bullet
