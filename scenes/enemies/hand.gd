extends EnemyBase

@onready var sprite = $Sprite2D # Or $AnimatedSprite2D depending on your node

# 1. THE IMMUNITY SETTINGS
# Override the EnemyBase variables so the player cannot copy it
@export var is_copyable: bool = false

var is_attacking: bool = false

# --- FLOATING VARIABLES ---
@export var float_speed: float = 3.0       # How fast it bobs up and down
@export var float_amplitude: float = 150.0 # How high/low it bobs
@export var chase_speed: float = 60.0      # How fast it chases the player horizontally

var time_passed: float = 0.0
var player_ref: Node2D = null

func _ready() -> void:
	# Run the EnemyBase setup
	super._ready()
	
	# Force this to NEVER be an ally, just in case
	is_ally = false 
	
	# Give the boss a lot of health!
	max_health = 1000
	current_health = max_health
	
	sprite.play("idle")
	
	player_ref = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if is_freeze or is_attacking:
		return
		
	# 1. THE HOVER (Vertical Bobbing)
	time_passed += delta
	# Using cosine for velocity automatically creates a smooth sine wave hover!
	velocity.y = cos(time_passed * float_speed) * float_amplitude
	
	# 2. THE CHASE (Horizontal Tracking)
	if is_instance_valid(player_ref):
		# Calculate if the player is to the left (-1) or right (1)
		var direction = sign(player_ref.global_position.x - global_position.x)
		
		velocity.x = direction * chase_speed
		
		# Flip the hand sprite so it always faces the player
		# (If your hand is backwards, change this to direction > 0)
		sprite.flip_h = (direction < 0) 
	else:
		velocity.x = 0 # Stop if the player is missing/dead
		
	move_and_slide()

# 2. THE ATTACK LOGIC
# You can call this function from a Timer, or when the player enters an Area2D
func start_attack():
	if not is_attacking:
		is_attacking = true
		sprite.play("attack")
		
		# (Optional) If you want the hand to drop down and smash the player, 
		# you would add your movement code here!

# 3. RETURNING TO IDLE
# Don't forget to connect the sprite's `animation_finished` signal to this function!
func _on_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		is_attacking = false
		sprite.play("idle")

# 4. OVERRIDE COPY/PASTE SAFETY
# Just to be 100% bulletproof against your player's paste function
func get_clipboard_data():
	print("Boss Hand cannot be copied!")
	return null 
	
func spawn_ally(number_of_clone: int):
	print("Boss Hand refuses to switch teams!")
	pass # Doing nothing here prevents the base script from turning it green

func _on_fatal_hitbox_body_entered(body: Node2D) -> void:
	# Check if the thing the hand just touched is the Player
	if body.name == "Player" or body.is_in_group("player"):
		
		start_attack()
		# 1. Force the player to die instantly by dealing massive damage
		if body.has_method("apply_damage"):
			body.apply_damage(9999)
			
		# Optional: Stop the boss hand from doing any other animations so it poses over the body
		is_attacking = true 
		
		# 2. Wait 2 seconds. This lets the player actually see their character 
		# fall to the ground and realize they lost the fight.
		await get_tree().create_timer(2.0).timeout
		
		# 3. Cut to your black glitch screen!
		get_tree().change_scene_to_file("res://scenes/ending.tscn")
