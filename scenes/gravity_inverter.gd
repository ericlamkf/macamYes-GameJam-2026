extends CopyableObjectBase

@export var gravity_multiplier: float = -1.0 # -1.0 reverses it

var overlapping_body = []

func _ready():
	# Connect signals to detect when things enter the "Gravity Well"
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# Check if the body has gravity (CharacterBody2D/RigidBody2D)
	if "gravity" in body:
		overlapping_body.append(body)
		body.gravity *= gravity_multiplier
	elif body is CharacterBody2D:
		# If you use custom gravity logic in your player/enemy
		if body.has_method("set_gravity_direction"):
			body.set_gravity_direction(Vector2.UP)

func _on_body_exited(body):
	# Restore normal gravity when they leave
	if "gravity" in body:
		overlapping_body.erase(body)
		body.gravity /= gravity_multiplier

func take_damage(amount: int):
	gravity_multiplier *= -1
	for body in overlapping_body:
		if "gravity" in body:
			body.gravity *= gravity_multiplier
	
