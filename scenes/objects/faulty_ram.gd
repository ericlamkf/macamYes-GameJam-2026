extends CopyableObjectBase

@export_group("Overload Settings")
@export var overload_limit: float = 100.0
@export var explosion_damage: int = 50
@export var explosion_radius: float = 150.0

var current_load: float = 0.0
var is_bursting: bool = false

@onready var status_label = $RichTextLabel
@onready var explosion_area = $ExplosionArea

func _ready():
	# Initial UI state
	update_display()

func take_damage(amount: int):
	if is_bursting: return
	
	current_load += amount
	
	# Visual "Glitch" effect: increase shake as load grows
	var intensity = int((current_load / overload_limit) * 20.0)
	status_label.text = "[center][shake rate=30 level=%d]0x%X[/shake][/center]" % [intensity, int(current_load)]
	
	# Color shift toward "Heat/Error" red
	var lerp_val = current_load / overload_limit
	modulate = Color(1.0, 1.0 - lerp_val, 1.0 - lerp_val)
	
	if current_load >= overload_limit:
		burst()

func update_display():
	status_label.text = "[center]MEM_STABLE[/center]"

func burst():
	is_bursting = true
	status_label.text = "[center]SEG_FAULT![/center]"
	
	# Wait a tiny bit for dramatic effect (The "Hang" before the crash)
	await get_tree().create_timer(1).timeout
	
	# Damage Calculation
	var bodies = explosion_area.get_overlapping_bodies()
	print("body:" + str(bodies))
	for body in bodies:
		print(body)
		# Check if it's the player, an enemy, or another copyable object
		if body == self: continue
		
		if body.has_method("apply_damage"):
			body.apply_damage(explosion_damage)
		elif body.has_method("take_damage"):
			body.take_damage(explosion_damage)
	
	# You could trigger a screen shake here or a particle effect
	print("RAM_BURST: Memory dumped to local area.")
	queue_free()

# Override for your Clipboard System
func get_clipboard_data() -> ClipboardData:
	var data = super.get_clipboard_data()
	data.type = "object"
	data.sprite_frames = $'AnimatedSprite2D'.sprite_frames
	# We can even save the current load state in the clipboard!
	data.data["saved_load"] = current_load 
	return data
