extends CanvasLayer

@onready var label = $ColorRect/RichTextLabel

# The exact same hacker glyphs from your corrupted bullets!
var glyphs = "01ABCDE#!?@&$"
var timer = 0.0
var interval = 0.05 # Updates very fast for a chaotic flicker

func _ready():
	label.bbcode_enabled = true
	label.modulate.a = 0.0 # Start completely black
	
	# Create a tween for a cinematic fade-in
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 3.0)
	
func _process(delta):
	# Run the glitch timer every frame
	timer += delta
	if timer >= interval:
		timer = 0.0
		update_glitch_text()

func update_glitch_text():
	# Generate 12 random characters
	var random_text = ""
	for i in range(12):
		random_text += glyphs[randi() % glyphs.length()]
		
	# 1. The Clean Text
	var story_text = "[center]CRITICAL FAILURE: Entity override detected.\nA colossal hand has seized administrator control.\n\nThe tale continues... "	
	# 2. The Ominous Red Shaking Text
	var corrupted_part = "[shake rate=15.0 level=8][color=red]unraveling beyond your control.[/color][/shake]\n\n\n"
	
	# 3. The Flickering Hacker Garbage Data
	var system_error = "[shake rate=30.0 level=5][color=darkgray]ERR_SYS_CORE_" + random_text + "[/color][/shake]\n"
	
	# 4. The Final Outro
	var demo_end = "[END OF DEMO SEQUENCE][/center]"
	
	# Smash them all together and push it to the label
	label.text = story_text + corrupted_part + system_error + demo_end

func _input(event):
	# Only let them skip/quit AFTER the 3-second fade-in is fully finished
	if label.modulate.a >= 1.0:
		if event is InputEventKey and event.pressed:
			# Quit the game, or load your MainMenu.tscn!
			get_tree().quit()
