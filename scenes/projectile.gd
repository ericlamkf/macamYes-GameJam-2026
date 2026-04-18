extends Area2D

class_name Projectile

@export var speed: float = 200.0
var source: Node # Tracks who fired it
var direction: Vector2
var shot = false
var projectile_damage

@export var corrupted_damage = 25.0
#@export var normal_damage = 5.0
@export var corrupted: bool = true

@onready var label = $RichTextLabel
@onready var collision_shape = $CollisionShape2D

# Connect the screen_exited signal from VisibleOnScreenNotifier2D
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()


var glyphs = "01ABCDE#!?@&$"
var timer = 0.0
var interval = 0.5 # Change every 0.5 seconds

func _process(delta):
	if(corrupted):
		timer += delta
		
		if timer >= interval:
			update_glitch_text()
			timer = 0.0 # Reset the timer
		

func update_glitch_text():
	var random_text = ""
	for i in range(4):
		random_text += glyphs[randi() % glyphs.length()]
	
	# Using BBCode to keep it shaking even between text changes
	label.bbcode_enabled = true
	label.text = "[shake rate=10.0 level=5][color=red]" + random_text + "[/color][/shake]"


func _ready():
	if(corrupted):
		update_glitch_text()
		projectile_damage = corrupted_damage
	else:
		var random_text = ""
		for i in range(5):
			random_text += str(randi_range(0, 1))
		label.text = random_text
		var normal_damage = random_text.bin_to_int()
		projectile_damage = normal_damage

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
		"original_direction": direction,
		"corrupted": corrupted
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
	if source.get_collision_layer_value(1)  or source.get_collision_layer_value(6):
		set_collision_mask_value(1, false)
		set_collision_mask_value(6, false)
	else:
		set_collision_mask_value(2, false)
	shot = true

func _physics_process(delta):
	if(shot):
		visible = true
		position += direction * delta
		

func _on_area_entered(area: Area2D):
	print(area) # debug purpose
	# 1. Don't collide if it hasn't been fired yet
	if (!shot):
		return
		
	# 2. FOOLPROOF FRIENDLY FIRE
	if area.owner == source:
		return

	# The 'area' is the Hurtbox of the enemy
	if area.has_method("take_damage"):
		area.take_damage(projectile_damage)             # Send it to the target
		
	queue_free() # Destroy the bullet


func _on_body_entered(body: Node2D) -> void:
	if(!shot):
		return
	if body.has_method("take_damage"):
		body.take_damage(projectile_damage) 
	queue_free()
