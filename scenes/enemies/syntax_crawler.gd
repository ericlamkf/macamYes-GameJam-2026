extends EnemyBase 

@export var speed: float = 50.0
var direction: int = 1

@onready var wall_check = $WallCheck
@onready var ledge_check = $LedgeCheck
@onready var sprite = $Sprite2D
var is_attacking: bool = false
var is_dead: bool = false # To prevent movement after death

func _ready():
	# Runs the code from EnemyBase's _ready (setting health)
	super._ready() 
	melee_damage = 20

func _physics_process(delta):
	# Apply Gravity
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, -3000, 3000)
	
	if is_dead or is_freeze:
		velocity.x = 0
		move_and_slide()
		return
	
	# 1. Attack Lock
	if is_attacking:
		velocity.x = 0 # Stand still to attack
		move_and_slide()
		return
		
	# 2. Check if we should flip (Ground logic)
	if is_on_floor():
		if wall_check.is_colliding() or not ledge_check.is_colliding():
			flip_direction()
			
	# 3. Apply movement (Runs EVERY frame, rain or shine)
	velocity.x = direction * speed
	sprite.play("default")
	move_and_slide()


func flip_direction():
	direction *= -1
	
	# Flip the visuals
	sprite.flip_h = (direction < 0)
	
	# Flip the sensor positions so they look the right way
	wall_check.target_position.x *= -1
	ledge_check.position.x *= -1

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
	
	$WallCheck.set_collision_mask_value(1, true)
	$WallCheck.set_collision_mask_value(2, false)
	$WallCheck.set_collision_mask_value(6, true)
	
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
	die()

# --- ANIMATION TRIGGER LOGIC ---

# Trigger this via a signal (e.g., DetectionRange Area2D) 
# or inside your EnemyBase logic when near the player
func start_attack():
	if not is_attacking and not is_dead:
		is_attacking = true
		sprite.play("attack")

# EnemyBase handles apply_damage and calls this automatically!
func die():
	if is_dead: return # Shotgun bug prevention
	is_dead = true
	sprite.play("death")
	
	# ONLY disable the layer so the player can walk through the corpse.
	# Do NOT touch collision_mask, so the body still hits the floor!
	collision_layer = 0 
	
	# Safely turn off the damage zones using set_deferred
	if has_node("Hitbox"): 
		$Hitbox.set_deferred("monitoring", false)
		$Hitbox.set_deferred("monitorable", false)
	if has_node("Hurtbox"): 
		$Hurtbox.set_deferred("monitoring", false)
		$Hurtbox.set_deferred("monitorable", false)
	
# --- SIGNAL CONNECTION ---
# Connect the AnimatedSprite2D's animation_finished() signal to this function
func _on_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		is_attacking = false
		
	if sprite.animation == "death":
		queue_free()
		
func _on_hitbox_area_entered(area):
	if area.name == "Hurtbox" or area.get_parent().name == "Player":
		start_attack()
