extends CopyableObjectBase

@export var crush_damage: int = 150
var gravity: float = 1000.0 # High gravity for a "heavy" feel
var gravity_field_count: int = 0
var base_gravity: int = 900
var last_velocity = Vector2.ZERO

var is_locked: bool = false

func _physics_process(delta):

	velocity.y += gravity * delta
	
	#_on_landed()

	move_and_slide()
	# Check every collision that happened this frame
	if(last_velocity.y >= 100):
		for i in get_slide_collision_count():
			
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
				
			# Check if we hit the top of an enemy
			if collider.has_method("apply_damage"):
				# If the collision normal is pointing UP, it means we landed ON them
				if collision.get_normal().dot(Vector2.UP) > 0.5:
					collider.apply_damage(crush_damage)
	last_velocity = velocity

func _on_landed():
	pass#print("Logic Gate locked into Sector.")
