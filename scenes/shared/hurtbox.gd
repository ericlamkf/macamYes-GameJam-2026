# Hurtbox.gd
extends Area2D

func take_damage(amount):
	if owner.has_method("apply_damage"):
		owner.apply_damage(int(amount))
