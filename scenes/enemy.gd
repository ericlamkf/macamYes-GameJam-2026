extends CharacterBody2D

class_name EnemyBase

@export var max_health: int = 50
@export var melee_damage: int = 1
@export var attack_interval: float = 1.0 # Time between hits (in seconds)
@export var is_ally: bool = false
@export var ally_timeout: int = 15
@export var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

var number_of_clone = 0;
var current_health: int
var is_freeze: bool = false
var can_attack: bool = true # Track if the cooldown is ready

# List to keep track of everyone currently inside the hitbox
var overlapping_targets = []

func _ready():
	current_health = max_health
	is_freeze = false
	
func apply_damage(amount: int):
	current_health -= amount
	# Debug purpose
	print("Enemy took damage! Health: ", current_health)
	# Add a simple visual flash or knockback here later
	if current_health <= 0:
		die()
		
func die():
	queue_free()
	

func get_clipboard_data() -> ClipboardData:
	print(number_of_clone)
	var data = ClipboardData.new()
	data.type = "enemy"
	data.sprite_frames = $Sprite2D.sprite_frames
	data.data = {
		"current_health": current_health,
		"number_of_clone": number_of_clone
	}
	data.scene_ref = self.scene_file_path
	return data

func _process(_delta):
	# If we can attack and someone is in the hitbox, hit them!
	if can_attack and not is_freeze and overlapping_targets.size() > 0:
		attack_targets()

func apply_freeze(duration: int):
	is_freeze = true
	await get_tree().create_timer(duration).timeout
	is_freeze = false

func attack_targets():
	can_attack = false
	
	# Loop through everyone inside and damage them
	for target in overlapping_targets:
		if target.has_method("take_damage"):
			target.take_damage(melee_damage)
			print("Enemy dealing continuous damage to: ", target.name)

	# Wait for the cooldown
	await get_tree().create_timer(attack_interval).timeout
	can_attack = true

func spawn_ally(number_of_clone:int):
	self.number_of_clone = number_of_clone
	is_ally = true
	var divisor = (2 ** number_of_clone)
	max_health = max_health / divisor
	ally_timeout = ally_timeout / divisor
	
	if(max_health < 1):
		max_health = 1
	
	if(ally_timeout < 2):
		ally_timeout = 2
	
	current_health = max_health
	
	$Hitbox.set_collision_mask_value(1, false)
	$Hitbox.set_collision_mask_value(2, true)
	$Hitbox.set_collision_mask_value(6, false)
	
	$Hurtbox.set_collision_layer_value(2, false)
	$Hurtbox.set_collision_layer_value(6, true)
	
	set_collision_layer_value(2, false)
	set_collision_layer_value(6, true)
	
	add_to_group("ally")
	remove_from_group("enemies")
	
	$Hurtbox.add_to_group("ally")
	$Hurtbox.remove_from_group("enemies")
	
	await get_tree().create_timer(ally_timeout).timeout
	queue_free()

# --- HITBOX LOGIC ---

func _on_hitbox_area_entered(area: Area2D):
	# Filter who we should add to the "to-be-damaged" list
	if is_ally:
		# Allies attack enemies
		if area.is_in_group("enemies") and area != self:
			overlapping_targets.append(area)
	else:
		# Normal enemies attack player
		print(area.get_groups())
		if area.is_in_group("player") or area.is_in_group("ally"):
			overlapping_targets.append(area)

func _on_hitbox_area_exited(area: Area2D):
	# Remove them from the list when they leave the hitbox
	if overlapping_targets.has(area):
		overlapping_targets.erase(area)
