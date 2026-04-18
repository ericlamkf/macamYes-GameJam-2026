extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ClipboardFrame/AnimatedSprite2D.visible = false
	$ClipboardFrame/RichTextLabel.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
var glyphs = "01ABCDE#!?@&$"
var timer = 0.0
var interval = 0.5 # Change every 0.5 seconds
var corrupted

func _process(delta: float):
	timer += delta
		
	if timer >= interval:
		update_glitch_text()
		timer = 0.0 # Reset the timer

func update_glitch_text():
	var random_text = ""
	if(corrupted):
		for i in range(4):
			random_text += glyphs[randi() % glyphs.length()]
	else:
		for i in range(4):
			random_text += str(randi_range(0, 1))
	
	# Using BBCode to keep it shaking even between text changes
	$ClipboardFrame/RichTextLabel.bbcode_enabled = true
	if(corrupted):
		$ClipboardFrame/RichTextLabel.text = "[center][shake rate=10.0 level=5][color=red]" + random_text + "[/color][/shake][/center]"
	else:
		$ClipboardFrame/RichTextLabel.text = "[center]" + random_text + "[/center]"
		
func _on_player_copy_successful(data):
	$ClipboardFrame/AnimatedSprite2D.visible = false
	$ClipboardFrame/RichTextLabel.visible = false
	
	if(data.type == "projectile"):
		corrupted = data.data["corrupted"]
		if(!corrupted):
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
