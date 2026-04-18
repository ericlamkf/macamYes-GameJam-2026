extends EnemyBase

@export var patrol_speed: float = 40.0
@export var charge_speed: float = 120.0 # 3x faster when charging!
@export var projectile_scene: PackedScene 

var direction: int = -1
var current_speed: float = patrol_speed
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# The Sensors
@onready var wall_check = $WallCheck
@onready var ledge_check = $LedgeCheck
@onready var player_vision = $PlayerVision
@onready var muzzle = $Muzzle
@onready var sprite = $Sprite2D

@export var is_copyable: bool = true 

func _ready():
	super._ready()
	
	if is_ally:
		# 1. Tint him green so the player knows he's friendly!
		sprite.modulate = Color(0.5, 1.5, 0.5) 
		
		# 2. Switch his radar to look for Enemies (Layer 2) instead of the Player (Layer 1)
		player_vision.set_collision_mask_value(1, false)
		player_vision.set_collision_mask_value(2, true)

func _physics_process(delta):
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Check for Walls/Ledges
	if is_on_floor():
		if wall_check.is_colliding() or not ledge_check.is_colliding():
			flip_direction()

	# 3. The "Aggro" Logic
	if player_vision.is_colliding():		
		var target = player_vision.get_collider()
		
		# If I am an ally, charge if I see an enemy!
		var hunting_enemy = is_ally and target and not "Player" in target.name
		
		# If I am normal, charge if I see the player!
		var hunting_player = not is_ally and target and "Player" in target.name
		
		if hunting_enemy or hunting_player:
			current_speed = charge_speed
		else:
			current_speed = patrol_speed
	else:
		current_speed = patrol_speed

	# 4. Move!
	velocity.x = direction * current_speed
	move_and_slide()

func flip_direction():
	direction *= -1
	sprite.flip_h = (direction > 0)
	
	# Flip all sensors so they look the correct way
	wall_check.target_position.x *= -1
	ledge_check.position.x *= -1
	player_vision.target_position.x *= -1
	muzzle.position.x *= -1 # Make sure he shoots in the direction he's facing!

func _on_shoot_timer_timeout():
	shoot()

func shoot():
	print("PEW! Brute attempting to fire...") # Debug line
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		get_tree().current_scene.add_child(proj)
		
		proj.global_position = muzzle.global_position
		
		# 1. Use YOUR custom shoot function to pull the trigger!
		proj.shoot(self, Vector2(direction, 0))
		
		# 2. OVERRIDE the random damage to make it armor-piercing!
		proj.projectile_damage = 100
		
		# 3. (Optional) Make the label display 100 in binary so it looks cool!
		if proj.label:
			proj.label.text = "1100100"
			
		# 4. If I am an Ally, my bullets need to switch teams too!
		if is_ally:
			# Turn OFF hitting the Player (Layer 1)
			proj.set_collision_mask_value(1, false)
			# Turn ON hitting Enemies (Layer 2)
			proj.set_collision_mask_value(2, true)
			# Tint the bullet green so the player knows it is safe!
			proj.modulate = Color(0.5, 1.5, 0.5)
	else:
		print("BRUTE ERROR: No projectile_scene loaded in Inspector!")
		
# This overrides the default damage logic in EnemyBase
func apply_damage(amount: int):
	if amount >= 100:
		super.apply_damage(amount)
		print("Armor PIERCED! Health is now: ", current_health)
	else:
		print("CLANG! Normal attacks did 0 damage to the Brute armor.")
		
