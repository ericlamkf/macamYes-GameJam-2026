extends CharacterBody2D

@export var speed = 150
@export var jump_force = -300
@export var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_range = 80

@onready var copy_ray = $RayCast2D
@onready var aim_line = $Line2D

var controls_inverted_signal = false
var controls_inverted = false
var view_direction

signal copy_successful(data: ClipboardData)

@export var health: int = 4

func _physics_process(delta):
	# 1. Handle Gravity
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, -3000, 3000)

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
		paste_object(GameState.clipboard)

func paste_object(clipboard: ClipboardData):
	if(clipboard == null):
		return
	var scene = load(clipboard.scene_ref)
	var type = clipboard.type
	var data = clipboard.data
	var instance = scene.instantiate()
	var target_pos
	
	# 1. SET POSITION FIRST (Before add_child)
	# This prevents the "flash" from (0,0) to the target
	if type == "projectile":
		instance.corrupted = data["corrupted"]
		target_pos = $Marker2D.global_position
	elif type == "enemy":
		if copy_ray.is_colliding():
			target_pos = copy_ray.get_collision_point()
		else:
			return
	elif type == "object":
		if copy_ray.is_colliding():
			target_pos = copy_ray.get_collision_point()
		else:
			target_pos = copy_ray.to_global(copy_ray.target_position)
	
	instance.position = target_pos

	# 2. ADD TO TREE
	get_tree().current_scene.add_child(instance)
	instance.global_position = target_pos
	# 3. FORCE INTERPOLATION RESET
	# This tells the physics engine: "Do not slide to this position, just BE here."
	if instance.has_method("reset_physics_interpolation"):
		instance.reset_physics_interpolation()

	# 4. INITIALIZE LOGIC
	if type == "projectile":
		instance.shoot(self, view_direction)
	elif type == "enemy":
		if view_direction.x > 0 and instance.has_method("set_facing_direction"):
			instance.set_facing_direction("right")
		
		instance.spawn_ally(clipboard.data["number_of_clone"] + 1)
	elif type == "object":
		instance.on_pasted(true)

func update_copy_ray():
	var mouse_pos = get_global_mouse_position()
	view_direction = (mouse_pos - global_position).normalized()
	copy_ray.target_position = view_direction * max_range  # max range

func update_aim_line():
	var start = Vector2.ZERO
	var end = copy_ray.target_position

	if copy_ray.is_colliding():
		end = to_local(copy_ray.get_collision_point())
		
	aim_line.points = [start, end]

func _input(event):
	if event.is_action_released("copy"):
		try_copy()

func try_copy():
	if copy_ray.is_colliding():
		var target = copy_ray.get_collider()
		if(target == null):
			return
		if not target.has_method("get_clipboard_data"):
			target = target.get_parent()
		if target and target.has_method("get_clipboard_data"):
			var data = target.get_clipboard_data()
			GameState.clipboard = data
			print("Copied:", target.name)
			copy_successful.emit(data)

func apply_damage(damage:int):
	health -= 1
	if(health == 0):
		print("YOU DIED")
