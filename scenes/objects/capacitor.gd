extends CopyableObjectBase

@export var blast_radius: float = 130.0
@export var freeze_duration: float = 3.0

# This triggers when the player (or an enemy) shoots the capacitor
func take_damage(amount: int):
	trigger_emp()

func trigger_emp():
	print("CAPACITOR OVERLOAD!")
	
	# Find all enemies in the current level (assuming they are in an "enemies" group)
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		# Check if they are close enough to the blast
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= blast_radius:
			# If the enemy has a freeze function, call it
			if enemy.has_method("apply_freeze"):
				enemy.apply_freeze(freeze_duration)
				
	# The capacitor destroys itself after overloading
	queue_free()
