extends EnemyBase 

@export var speed: float = 50.0
var direction: int = 1

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var wall_check = $WallCheck
@onready var ledge_check = $LedgeCheck
@onready var sprite = $Sprite2D

func _ready():
	# Runs the code from EnemyBase's _ready (setting health)
	super._ready() 

func _physics_process(delta):
	# Apply Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Check if we should flip (Ground logic)
	if is_on_floor():
		if wall_check.is_colliding() or not ledge_check.is_colliding():
			flip_direction()
			
	# 3. Apply movement (Runs EVERY frame, rain or shine)
	velocity.x = direction * speed
	move_and_slide()

func flip_direction():
	direction *= -1
	
	# Flip the visuals
	sprite.flip_h = (direction < 0)
	
	# Flip the sensor positions so they look the right way
	wall_check.target_position.x *= -1
	ledge_check.position.x *= -1
