extends CharacterBody2D

@export var speed = 150
@export var jump_force = -300
@export var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_range = 80
@export var health: int = 100
@export var death_screen_scene: PackedScene

@onready var copy_ray = $RayCast2D
@onready var aim_line = $Line2D
@onready var sprite = $Sprite2D
@onready var melee_hitbox = $MeleeHitbox

var gravity_field_count: int = 0
var base_gravity: int = 900

var controls_inverted_signal = false
var controls_inverted = false
var view_direction

var is_copy = false # Locks movement animations while shooting/copying
var is_dead = false   # Stops the player from moving when they die
var is_attacking = false
var game_state: GameState

signal copy_successful(data: ClipboardData)
signal take_damage(health: int)

var collected_keys: Array[String] = []

func _ready() -> void:
	game_state = GameState
	collected_keys = GameState.collected_keys.duplicate()
	if GameState.spawn_position != Vector2.ZERO:
		global_position = GameState.spawn_position
	health = GameState.player_health

func collect_key(key: String) -> void:
	if key not in collected_keys:
		collected_keys.append(key)
		GameState.collected_keys = collected_keys

func _physics_process(delta):
	# 1. Handle Gravity
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, -3000, 3000)
	
	if is_dead:
		# Stop horizontal movement instantly
		velocity.x = 0 
		# Make sure the body actually falls to the ground!
		move_and_slide() 
		# Cancel the rest of the script so they can't attack or jump
		return
			
	# 3. Get horizontal input direction
	var direction = 0
	
	direction = Input.get_axis("move_left", "move_right")
	
	# 4. "Regain" logic: Stop inversion only when the plaayer stops moving
	if direction == 0:
		if controls_inverted_signal:
			controls_inverted = true
		else:
			controls_inverted = false
	
	# 5. Apply the inversion if active
	if controls_inverted:
		direction = direction * -1
	
	# --- HOLD-TO-ATTACK & JUMP ATTACK LOGIC ---
	if Input.is_action_pressed("attack") and not is_copy:
		if not is_attacking:
			is_attacking = true
			sprite.play("attack")
			# Flip hitbox and sprite toward current movement or aim
			if direction != 0:
				sprite.flip_h = (direction < 0)
				melee_hitbox.position.x = -30 if direction < 0 else 30
			execute_melee_attack()
			
	# If we are attacking, force the character to stand still!
	if is_attacking and is_on_floor():
		direction = 0 
	
	# Animation logic
	if not is_dead and not is_copy and not is_attacking:
		if not is_on_floor():
			if velocity.y < 50: 
				sprite.play("jump")
			else:
				sprite.play("fall")
		elif direction != 0:
			sprite.play("run")
			sprite.flip_h = (direction < 0) 
			
			# --- FLIP THE HITBOX ---
			if direction < 0:
				melee_hitbox.position.x = -30 
			else:
				melee_hitbox.position.x = 30
		else:
			sprite.play("idle")
		
	velocity.x = direction * speed
	
	# 6. Handle Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()

func _process(delta):
	update_copy_ray()
	if "c" in collected_keys and Input.is_action_pressed("copy"):
		update_aim_line()
	else:
		aim_line.points = []

	if "v" in collected_keys and Input.is_action_just_pressed("paste"):
		paste_object(GameState.clipboard)

func paste_object(clipboard: ClipboardData):
	if(clipboard == null):
		return
	
	# Shoot animation
	is_copy = true
	sprite.play("shoot")
	sprite.flip_h = (view_direction.x < 0)
		
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
	if instance.has_method("reset_physics_interpolation"):
		instance.reset_physics_interpolation()

	# 4. INITIALIZE LOGIC
	if type == "projectile":
		instance.shoot(self, view_direction)
	elif type == "enemy":
		# 1. Handle Facing Direction (Checks both left and right)
		if view_direction.x < 0 and instance.has_method("set_facing_direction"):
			instance.set_facing_direction(-1)
		elif view_direction.x > 0 and instance.has_method("set_facing_direction"):
			instance.set_facing_direction("right")
		
		# 2. Ally Logic
		if instance.has_method("spawn_ally"):
			var clones = 0
			if clipboard.data.has("number_of_clone"):
				clones = clipboard.data["number_of_clone"]
			instance.spawn_ally(clones + 1)
		else:
			instance.is_ally = true
			instance.max_health = int(instance.max_health * 0.5)
			instance.current_health = instance.max_health
			get_tree().create_timer(15.0).timeout.connect(instance.queue_free)

	elif type == "object":
		if instance.has_method("on_pasted"):
			instance.on_pasted(true)

func update_copy_ray():
	var mouse_pos = get_global_mouse_position()
	view_direction = (mouse_pos - global_position).normalized()
	copy_ray.target_position = view_direction * max_range

func update_aim_line():
	var start = Vector2.ZERO
	var end = copy_ray.target_position

	if copy_ray.is_colliding():
		end = to_local(copy_ray.get_collision_point())
		
	aim_line.points = [start, end]

func _input(event):
	if "c" in collected_keys and event.is_action_released("copy"):
		try_copy()

	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		GameState.reset_clipboard()
		GameState.player_health = 100
		get_tree().reload_current_scene()

	# Q to move Left, E to move Right (Inventory Slots)
	if event.is_action_pressed("prev_slot"): # Map 'Q'
		cycle_slots(-1)
	elif event.is_action_pressed("next_slot"): # Map 'E'
		cycle_slots(1)

func cycle_slots(direction: int):
	# Using the 'wrap' function is the cleanest way to do this in Godot
	game_state.current_slot_index = posmod(game_state.current_slot_index + direction, game_state.slot_order.size())
	game_state.clipboard = game_state.registers[game_state.current_slot_index]


func try_copy():
	if copy_ray.is_colliding():
		var target = copy_ray.get_collider()
		if(target == null):
			return
		if not target.has_method("get_clipboard_data"):
			target = target.get_parent()
		if target and target.has_method("get_clipboard_data"):
			var data = target.get_clipboard_data()
			if(data.type == "projectile"):
				game_state.current_slot_index = 0
			elif(data.type == "object"):
				game_state.current_slot_index = 1
			elif(data.type == "enemy"):
				game_state.current_slot_index = 2
			game_state.registers[game_state.current_slot_index] = data
			game_state.clipboard = data
			print("Copied:", target.name)
			
			# --- TRIGGER COPY ANIMATION ---
			is_copy = true
			sprite.play("copy")
			sprite.flip_h = (view_direction.x < 0)
			
			copy_successful.emit(data)

func apply_damage(damage:int):
	if is_dead: return
	
	health -= damage
	take_damage.emit(health)
	
	if(health <= 0):
		is_dead = true
		sprite.play("death")

		# --- DEATH SOUND ---
		var dead_sounds = ["res://assets/audio/music/dead.mp3", "res://assets/audio/music/dead_2.mp3"]
		var sfx = AudioStreamPlayer.new()
		sfx.stream = load(dead_sounds[randi() % dead_sounds.size()])
		sfx.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(sfx)
		sfx.play()

		# --- GHOST MODE ---
		set_collision_layer_value(1, false)
		$Hurtbox.set_deferred("monitorable", false)
		$Hurtbox.set_deferred("monitoring", false)

		# --- DEATH SCREEN ---
		get_tree().paused = true
		var scene = death_screen_scene if death_screen_scene else load("res://scenes/player/dead_scene.tscn")
		if scene:
			var death_ui = scene.instantiate()
			get_tree().current_scene.add_child(death_ui)

func _on_sprite_2d_animation_finished() -> void:
	# Unlock copy/shoot
	if sprite.animation == "copy" or sprite.animation == "shoot":
		is_copy = false
		
	# Unlock the melee attack!
	if sprite.animation == "attack":
		is_attacking = false
		
func execute_melee_attack():
	var targets = melee_hitbox.get_overlapping_bodies()
	print("Hitbox overlapping count: ", targets.size())
	
	for target in targets:
		print("Hitbox touched: ", target.name)
		if target.has_method("apply_damage") and target != self:
			print("Player smacked: ", target.name)
			target.apply_damage(50)
