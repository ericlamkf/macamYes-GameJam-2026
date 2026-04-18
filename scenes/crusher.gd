extends CopyableObjectBase

@export var crush_damage: int = 150
var gravity: float = 1000.0 # High gravity for a "heavy" feel
var is_locked: bool = false

func _physics_process(delta):

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# It hit the floor!
		velocity = Vector2.ZERO
		_on_landed()

	move_and_slide()
	
	# Check every collision that happened this frame
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if we hit the top of an enemy
		if collider.has_method("apply_damage"):
			# If the collision normal is pointing UP, it means we landed ON them
			if collision.get_normal().dot(Vector2.UP) > 0.5:
				collider.apply_damage(crush_damage)

func _on_landed():
	pass#print("Logic Gate locked into Sector.")
