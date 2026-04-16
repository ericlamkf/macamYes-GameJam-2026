extends CharacterBody2D

class_name EnemyBase

@export var max_health: int = 100
var current_health: int

# Faction system for phase 2 (pasted enemies can fight original enemies)
@export var is_ally: bool = false

func _ready():
	current_health = max_health
	
func take_damage(amount: int):
	current_health -= amount
	# Debug purpose
	print("Enemy took damage! Health: ", current_health)
	# Add a simple visual flash or knockback here later
	if current_health <= 0:
		die()
		
func die():
	queue_free()
