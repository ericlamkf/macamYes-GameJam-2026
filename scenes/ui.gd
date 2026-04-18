extends CanvasLayer


@onready var bar_sprite = $BarContainer/TextureRect
@onready var container_width = $BarContainer.size.x


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ClipboardFrame/AnimatedSprite2D.visible = false
	$ClipboardFrame/RichTextLabel.visible = false
	update_health_bar(100, 100)
# Called every frame. 'delta' is the elapsed time since the previous frame.
var glyphs = "01ABCDE#!?@&$"
var timer = 0.0
var interval = 0.5 # Change every 0.5 seconds

func _process(delta: float) -> void:
	timer += delta
		
	if timer >= interval:
		update_glitch_text()
		timer = 0.0 # Reset the timer

func update_glitch_text():
	var random_text = ""
	for i in range(4):
		random_text += glyphs[randi() % glyphs.length()]
	
	# Using BBCode to keep it shaking even between text changes
	$ClipboardFrame/RichTextLabel.bbcode_enabled = true
	$ClipboardFrame/RichTextLabel.text = "[center][shake rate=10.0 level=5][color=red]" + random_text + "[/color][/shake][/center]"

func _on_player_copy_successful(data):
	$ClipboardFrame/AnimatedSprite2D.visible = false
	$ClipboardFrame/RichTextLabel.visible = false
	
	if(data.type == "projectile"):
		if(!data.data["corrupted"]):
			$ClipboardFrame/RichTextLabel.text = "[center]0101[/center]"
		else:
			$ClipboardFrame/RichTextLabel.text = "[center][shake rate=10.0 level=5][color=red]" + "@0!1" + "[/color][/shake][/center]"
		$ClipboardFrame/RichTextLabel.visible = true
	else:
	# 1. Update the UI's sprite with the enemy's animations
		$ClipboardFrame/AnimatedSprite2D.sprite_frames = data.sprite_frames
		
		# 2. Play the 'idle' or 'default' animation as a preview
		$ClipboardFrame/AnimatedSprite2D.play("default") 
		$ClipboardFrame/AnimatedSprite2D.visible = true

func update_health_bar(current_health, max_health):
	var health_ratio = float(current_health) / max_health
	
	# Calculate the target X position
	# If health is 0, target_x is -container_width (hidden to the left)
	# If health is 1.0, target_x is 0 (fully visible)
	var target_x = (health_ratio - 1.0) * container_width
	
	# Use a Tween for a smooth sliding effect
	var tween = create_tween()
	tween.tween_property(bar_sprite, "position:x", target_x, 0.3).set_trans(Tween.TRANS_LINEAR)
