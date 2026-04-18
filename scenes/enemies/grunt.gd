extends EnemyBase

@export var speed: float = 20.0
@export var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
@export var shoot_cooldown: float = 0.5
@export var aim_ready_time: float = 0.5

@onready var ray_cast = $RayCast2D
@onready var patrol_timer = $Timer
@onready var detection_area = $DetectionArea
@onready var muzzle = $Marker2D

var direction: float = 1.0
var target: Node2D = null
var can_shoot: bool = true
var is_aiming: bool = false
var target_location: Vector2
var targets_in_sight: Array = []

func _ready():
	super._ready()
	melee_damage = 10
	
	# Programmatically enforce RayCast collision masks so you don't have to set them in the Inspector.
	# Layer 1 (World), Layer 2 (Player), Layer 6 (Ally)
	ray_cast.set_collision_mask_value(1, true)
	ray_cast.set_collision_mask_value(2, true)
	ray_cast.set_collision_mask_value(6, true)
	
	patrol_timer.timeout.connect(_on_patrol_timeout)
	_on_patrol_timeout()
	
	ray_cast.enabled = false

func _physics_process(delta):
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, -900, 900)

	if is_freeze:
		return

	# Check if current target was destroyed/freed
	if target and not is_instance_valid(target):
		update_target()

	if target:
		# --- TRACKING STATE ---
		velocity.x = 0
		
		set_facing_direction_int(target.global_position.x - global_position.x)
		target_location = Vector2(target.global_position.x, target.global_position.y - 8)
		
		# Point RayCast at target
		ray_cast.target_position = ray_cast.to_local(target_location)
		
		# If we see a valid hostile and aren't already aiming/on cooldown, start aiming
		if can_shoot and not is_aiming and can_see_hostile():
			start_aiming_sequence()
	else:
		# --- PATROL STATE ---
		velocity.x = direction * speed
		
	move_and_slide()

# --- Helper: Line of Sight ---
func can_see_hostile() -> bool:
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if is_instance_valid(collider):
			# We shoot if the RayCast hits the Player OR an Ally
			return collider.is_in_group("player") or collider.is_in_group("ally") or collider.is_in_group("enemies")
	return false

# --- Target Management ---
func update_target():
	# Clean array of dead targets
	targets_in_sight = targets_in_sight.filter(func(t): return is_instance_valid(t))
	
	if targets_in_sight.size() > 0:
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
		target = null
		ray_cast.enabled = false
		_on_patrol_timeout()

# --- Combat Sequence ---
func start_aiming_sequence():
	is_aiming = true
	
	await get_tree().create_timer(aim_ready_time).timeout
	
	# Final check: target must be alive AND we must still have line of sight
	if is_instance_valid(target) and can_see_hostile():
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

# --- Visuals ---
func set_facing_direction_int(dir: int):
	if dir > 0:
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

# --- Detection Area Signals ---
func _on_body_entered(body):
	if not is_ally:
		if body.is_in_group("player") or body.is_in_group("ally"):
			if not targets_in_sight.has(body):
				targets_in_sight.append(body)
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
	
	if target == body or not is_instance_valid(target):
		update_target()

# --- Spawn Ally (Paste Logic) ---
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
