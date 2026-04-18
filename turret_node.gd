extends EnemyBase

# This lets you drag and drop your Projectile.tscn into the Inspector
@export var projectile_scene: PackedScene 

@onready var muzzle = $Muzzle
@onready var sprite = $Sprite2D

# Tells Dev A's system this enemy can be copy-pasted
@export var is_copyable: bool = true 

var facing_direction

func _ready():
	# Make sure we run EnemyBase's ready function so health is set!
	super._ready()
	melee_damage = 0
	set_facing_direction("left")

# We will connect the Timer to this function next
func _on_shoot_timer_timeout():
	if is_freeze:
		return
	shoot()

func shoot():
	# Safety check: Make sure we actually slotted a bullet into the Inspector
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		
		# Add the bullet to the main game world (NOT as a child of the turret, 
		# otherwise the bullet moves if the turret moves)
		get_tree().current_scene.add_child(proj)
		
		# Move the bullet to the Muzzle's exact location
		proj.global_position = muzzle.global_position

		proj.shoot(self, facing_direction)

func set_facing_direction(direction: String):
	if direction.to_lower() == "right":
		facing_direction = Vector2.RIGHT
		# Flip the visual. If your sprite faces Left by default, 
		# we flip scale.x to -1 to make it look Right.
		sprite.flip_h = false
		sprite.move_local_x(-9)
	else:
		facing_direction = Vector2.LEFT
		sprite.flip_h = true
		sprite.move_local_x(9)

func _physics_process(delta: float):
	print(velocity.y)
	velocity.y += gravity * delta
	
	velocity.y = clamp(velocity.y, -3000, 3000)
	
	move_and_slide()
