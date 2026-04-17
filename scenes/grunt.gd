extends EnemyBase

@export var speed: float = 100.0
@export var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")
@export var shoot_cooldown: float = 1.0
@export var aim_ready_time: float = 1.0

@onready var ray_cast = $RayCast2D
@onready var patrol_timer = $Timer # The one you already have
@onready var detection_area = $DetectionArea
@onready var muzzle = $Marker2D # Positioned at the gun/chest

var direction: float = 1.0
var player: Node2D = null
var can_shoot: bool = true
var is_aiming: bool = false

func _ready():
	# 1. Setup Patrol Timer (from your code)
	patrol_timer.timeout.connect(_on_patrol_timeout)
	_on_patrol_timeout()
	
	# 2. Setup Detection Area
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	ray_cast.enabled = false # Save CPU until player is near

func _physics_process(delta):
	# Apply Gravity
	if not is_on_floor():
		velocity.y += 900 * delta

	if player:
		# --- TRACKING STATE ---
		velocity.x = 0 # Explicitly stop horizontal movement
		
		# Update visuals
		$Sprite2D.flip_h = (player.global_position.x < global_position.x)
	
		# Point RayCast at player
		ray_cast.target_position = ray_cast.to_local(player.global_position)
		
		if ray_cast.is_colliding():
			var collider = ray_cast.get_collider()
			if collider == player and can_shoot and not is_aiming:
				start_aiming_sequence()
	else:
		# --- PATROL STATE ---
		velocity.x = direction * speed
		
	move_and_slide()

func start_aiming_sequence():
	is_aiming = true
	
	# Optional: Play an "anticipation" animation or sound here
	# $AnimatedSprite2D.play("charge_up")
	
	# Wait for the wind-up time
	await get_tree().create_timer(aim_ready_time).timeout
	
	# Check if the player is STILL in sight after the timer ends
	# (Prevents shooting through walls if the player moved during the wait)
	if player and ray_cast.get_collider() == player:
		shoot(player.global_position)
	
	is_aiming = false # Reset so it can aim again next time can_shoot is true

func shoot(target_pos: Vector2):
	can_shoot = false # Start cooldown
	
	var bullet = projectile_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	# Use muzzle position so bullets don't come out of feet
	bullet.global_position = muzzle.global_position
	
	var dir_to_player = (target_pos - muzzle.global_position).normalized()
	
	if bullet.has_method("shoot"):
		bullet.shoot(self, dir_to_player)
	
	# Shooting cooldown timer (separate from patrol timer)
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true

# --- Patrol Logic ---
func _on_patrol_timeout():
	# Randomly choose movement
	direction = [ -1.0, 1.0, 0.0 ].pick_random()
	
	# Flip visual/ray logic only if we aren't tracking the player
	# If tracking the player, physics_process handles ray rotation
	if not player and direction != 0:
		ray_cast.target_position.x = abs(ray_cast.target_position.x) * direction
	
	patrol_timer.wait_time = randf_range(1.0, 3.0)
	patrol_timer.start()

# --- Area2D Signals ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body
		ray_cast.enabled = true
		# We stop the patrol timer so it doesn't change 'direction' while we are fighting
		patrol_timer.stop() 

func _on_body_exited(body):
	if body == player:
		player = null
		ray_cast.enabled = false
		# RESUME PATROL: Kickstart the timer again so the enemy starts walking
		_on_patrol_timeout()
