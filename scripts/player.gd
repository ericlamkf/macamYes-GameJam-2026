extends CharacterBody2D

@export var speed = 200
@export var jump_force = -400
@export var gravity = 900

@onready var copy_ray = $RayCast2D
@onready var aim_line = $Line2D

var controls_inverted_signal = false
var controls_inverted = false
var view_direction

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

func _process(delta):
	update_copy_ray()
	if(Input.is_action_pressed("copy")):
		update_aim_line()
	else:
		aim_line.points = []
		
	if(Input.is_action_just_pressed("paste")):
		paste()

func paste():
	var scene = GameState.clipboard.scene_ref

	var instance = scene.instantiate()
	get_tree().current_scene.add_child(instance)
	
	instance.global_position = global_position
	instance.shoot(self, view_direction)


func update_copy_ray():
	var mouse_pos = get_global_mouse_position()
	view_direction = (mouse_pos - global_position).normalized()
	copy_ray.target_position = view_direction * 300  # max range

func update_aim_line():
	var start = Vector2.ZERO
	var end = copy_ray.target_position

	if copy_ray.is_colliding():
		end = to_local(copy_ray.get_collision_point())
		
	aim_line.points = [start, end]

func _input(event):
	if event.is_action_pressed("copy"):
		try_copy()

func try_copy():
	if copy_ray.is_colliding():
		var target = copy_ray.get_collider().get_parent()
		if target.has_method("get_clipboard_data"):
			GameState.clipboard = target.get_clipboard_data()
			print("Copied:", target.name)
