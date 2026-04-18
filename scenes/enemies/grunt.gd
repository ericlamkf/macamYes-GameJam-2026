extends EnemyBase

@export var speed: float = 20.0
@export var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
@export var shoot_cooldown: float = 0.5
@export var aim_ready_time: float = 0.5

@onready var ray_cast = $RayCast2D
@onready var patrol_timer = $Timer # The one you already have
@onready var detection_area = $DetectionArea
@onready var muzzle = $Marker2D # Positioned at the gun/chest

var direction: float = 1.0
var target: Node2D = null
var can_shoot: bool = true
var is_aiming: bool = false
var target_location: Vector2
var targets_in_sight = []

func _ready():
	super._ready()
	melee_damage = 10
	
	# 1. Setup Patrol Timer (from your code)
	patrol_timer.timeout.connect(_on_patrol_timeout)
	_on_patrol_timeout()
	
	# 2. Setup Detection Area
	#detection_area.body_entered.connect(_on_body_entered)
	#detection_area.body_exited.connect(_on_body_exited)
	ray_cast.enabled = false # Save CPU until player is near

func _physics_process(delta):
	# Apply Gravity
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, -900, 900)

	if is_freeze:
		return

	# --- NEW: Check if target was destroyed ---
	if target and not is_instance_valid(target):
		update_target() # Switch to next target if current one died

	if target:
		# --- TRACKING STATE ---
		velocity.x = 0 # Explicitly stop horizontal movement
		
		# Update visuals
		set_facing_direction_int(target.global_position.x - global_position.x)
		
		target_location = Vector2(target.global_position.x, target.global_position.y - 8)
		
		# Point RayCast at player
		ray_cast.target_position = ray_cast.to_local(target_location)
		
		if ray_cast.is_colliding():
			var collider = ray_cast.get_collider()
			if collider == target and can_shoot and not is_aiming:
				start_aiming_sequence()
	else:
		# --- PATROL STATE ---
		velocity.x = direction * speed
		
	move_and_slide()

# --- NEW: Target Selection Logic ---
func update_target():
	# 1. Clean the array: Remove any targets that were queue_free()'d
	targets_in_sight = targets_in_sight.filter(func(t): return is_instance_valid(t))
	
	if targets_in_sight.size() > 0:
		# 2. Find the closest valid target in the array
		var closest_dist = INF
		var closest_target = null
		
		for t in targets_in_sight:
			var dist = global_position.distance_squared_to(t.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_target = t
				
		target = closest_target
		ray_cast.enabled = true
		patrol_timer.stop()
	else:
		# 3. No targets left! Go back to patrol mode.
		target = null
		ray_cast.enabled = false
		_on_patrol_timeout() # Kickstart patrol

func start_aiming_sequence():
	is_aiming = true
	
	# Wait for the wind-up time
	await get_tree().create_timer(aim_ready_time).timeout
	
	# NEW SAFETY CHECK: Make sure target didn't die while we were aiming!
	if is_instance_valid(target) and ray_cast.get_collider() == target:
		shoot(target_location)
	
	is_aiming = false 

func shoot(target_pos: Vector2):
	can_shoot = false 
	
	var bullet = projectile_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	
	var dir_to_player = (target_pos - muzzle.global_position).normalized()
	
	if bullet.has_method("shoot"):
		bullet.shoot(self, dir_to_player)
	
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

func set_facing_direction_int(direction: int):
	if direction > 0:
		# Flip the visual. If your sprite faces Left by default, 
		# we flip scale.x to -1 to make it look Right.
		$Sprite2D.flip_h = false
		$Sprite2D.offset = Vector2(0, 0)
	else:
		$Sprite2D.flip_h = true
		$Sprite2D.offset = Vector2(8, 0)

# --- Patrol Logic ---
func _on_patrol_timeout():
	direction = [ -1.0, 1.0, 0.0 ].pick_random()
	set_facing_direction_int(direction)
	if not target and direction != 0:
		ray_cast.target_position.x = abs(ray_cast.target_position.x) * direction
	
	patrol_timer.wait_time = randf_range(1.0, 3.0)
	patrol_timer.start()

# --- Area2D Signals ---
func _on_body_entered(body):
	if not is_ally:
		if body.is_in_group("player") or body.is_in_group("ally"):
			if not targets_in_sight.has(body):
				targets_in_sight.append(body)
			
			# If we don't have a valid target right now, evaluate!
			if not is_instance_valid(target):
				update_target()
	else:
		if body.is_in_group("enemies"):
			if not targets_in_sight.has(body):
				targets_in_sight.append(body)
			
			if not is_instance_valid(target):
				update_target()

func _on_body_exited(body):
	if targets_in_sight.has(body):
		targets_in_sight.erase(body)
	
	# If the target that just walked away was our MAIN target,
	# or if our main target died, pick a new one!
	if target == body or not is_instance_valid(target):
		update_target()

# --- Your Paste Logic remains exactly the same below! ---
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
	
	$RayCast2D.set_collision_mask_value(1, false)
	$RayCast2D.set_collision_mask_value(6, false)
	$RayCast2D.set_collision_mask_value(2, true)
	
	$DetectionArea.set_collision_mask_value(1, false)
	$DetectionArea.set_collision_mask_value(6, false)
	$DetectionArea.set_collision_mask_value(2, true)
	
	await get_tree().create_timer(ally_timeout).timeout
	queue_free()
