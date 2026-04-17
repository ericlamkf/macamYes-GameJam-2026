# Hurtbox.gd
extends Area2D

func take_damage(amount: int):
	# "owner" refers to the root node of the scene (the Enemy)
	if owner.has_method("apply_damage"):
		owner.apply_damage(amount)
