extends EnemyBase

# This lets you drag and drop your Projectile.tscn into the Inspector
@export var projectile_scene: PackedScene 

@onready var muzzle = $Muzzle

# Tells Dev A's system this enemy can be copy-pasted
@export var is_copyable: bool = true 

func _ready():
	# Make sure we run EnemyBase's ready function so health is set!
	super._ready()

# We will connect the Timer to this function next
func _on_shoot_timer_timeout():
	print("1. Timer hit zero!")
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
		
		# Tell the bullet who fired it and which way to go
		proj.source = self 
		proj.direction = Vector2.LEFT # Change to RIGHT if your turret faces right
