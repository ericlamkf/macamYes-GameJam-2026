extends CharacterBody2D

@export var speed = 200
@export var jump_force = -400
@export var gravity = 900

var controls_inverted_signal = false
var controls_inverted = false

func _physics_process(delta):
	# 1. Handle Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 3. Get horizontal input direction
	var direction = Input.get_axis("move_left", "move_right")
	
	# 4. "Regain" logic: Stop inversion only when the player stops moving
	if direction == 0:
		if controls_inverted_signal:
			controls_inverted = true
		else:
			controls_inverted = false

	# 5. Apply the inversion if active
	if controls_inverted:
		direction = direction * -1
		
	velocity.x = direction * speed
	
	# 6. Handle Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()
