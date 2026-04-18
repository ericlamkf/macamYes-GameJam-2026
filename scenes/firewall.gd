extends CopyableObjectBase

@export var max_integrity: int = 200
var current_integrity: int

func _ready():
	current_integrity = max_integrity

func take_damage(amount: int):
	current_integrity -= amount
	
	# Visual feedback without an AnimatedSprite
	# We can use 'modulate' to make it more transparent as it breaks
	modulate.a = float(current_integrity) / float(max_integrity)
	
	if current_integrity <= 0:
		queue_free()
