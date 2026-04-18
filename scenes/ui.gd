extends CanvasLayer

@onready var bar_sprite = $BarContainer/TextureRect
@onready var container_width = $BarContainer.size.x

var start_glitch_text = false
var frames

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	frames = [$CombatFrame, $ObjectFrame, $EntityFrame]
	$CombatFrame/AnimatedSprite2D.visible = false
	$ObjectFrame/AnimatedSprite2D.visible = false
	$EntityFrame/AnimatedSprite2D.visible = false
	deselect_frame($CombatFrame)
	deselect_frame($ObjectFrame)
	deselect_frame($EntityFrame)

	_restore_slots_from_state()
	update_health_bar(100, 100)

func _restore_slots_from_state() -> void:
	var slot_map = {"projectile": 0, "object": 1, "enemy": 2}
	for i in GameState.registers.size():
		var data = GameState.registers[i]
		if data == null:
			continue
		if data.type == "projectile":
			$CombatFrame/RichTextLabel.visible = true
		elif data.type == "object":
			if data.sprite_frames:
				$ObjectFrame/AnimatedSprite2D.sprite_frames = data.sprite_frames
				$ObjectFrame/AnimatedSprite2D.play("default")
				$ObjectFrame/AnimatedSprite2D.visible = true
				$ObjectFrame/RichTextLabel.visible = false
		elif data.type == "enemy":
			if data.sprite_frames:
				$EntityFrame/AnimatedSprite2D.sprite_frames = data.sprite_frames
				$EntityFrame/AnimatedSprite2D.play("default")
				$EntityFrame/AnimatedSprite2D.visible = true
				$EntityFrame/RichTextLabel.visible = false
	switch_frame(GameState.current_slot_index)

# Called every frame. 'delta' is the elapsed time since the previous frame.
var glyphs = "01ABCDE#!?@&$"
var timer = 0.0
var interval = 0.5 # Change every 0.5 seconds
var corrupted

func _process(delta: float):
	switch_frame(GameState.current_slot_index)
	if not start_glitch_text:
		return
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
	$CombatFrame/RichTextLabel.bbcode_enabled = true
	if(corrupted):
		$CombatFrame/RichTextLabel.text = "[center][shake rate=10.0 level=5][color=red]" + random_text + "[/color][/shake][/center]"
	else:
		$CombatFrame/RichTextLabel.text = "[center]" + random_text + "[/center]"
		
func _on_player_copy_successful(data):
	if(data.type == "projectile"):
		start_glitch_text = true
		corrupted = data.data["corrupted"]
		if(!corrupted):
			$CombatFrame/RichTextLabel.text = "[center]0101[/center]"
		else:
			$CombatFrame/RichTextLabel.text = "[center][shake rate=10.0 level=5][color=red]" + "@0!1" + "[/color][/shake][/center]"
		$CombatFrame/RichTextLabel.visible = true
		switch_frame(0)
	elif(data.type == "object"):
	# 1. Update the UI's sprite with the enemy's animations
		$ObjectFrame/AnimatedSprite2D.sprite_frames = data.sprite_frames
		$ObjectFrame/AnimatedSprite2D.play("default")
		$ObjectFrame/RichTextLabel.visible = false
		$ObjectFrame/AnimatedSprite2D.visible = true
		switch_frame(1)
	elif(data.type == "enemy"):
		$EntityFrame/AnimatedSprite2D.sprite_frames = data.sprite_frames
		$EntityFrame/AnimatedSprite2D.play("default") 
		$EntityFrame/RichTextLabel.visible = false
		$EntityFrame/AnimatedSprite2D.visible = true
		switch_frame(2)

func update_health_bar(current_health, max_health):
	var health_ratio = float(current_health) / max_health
	
	# Calculate the target X position
	# If health is 0, target_x is -container_width (hidden to the left)
	# If health is 1.0, target_x is 0 (fully visible)
	var target_x = (health_ratio - 1.0) * container_width
	
	# Use a Tween for a smooth sliding effect
	var tween = create_tween()
	tween.tween_property(bar_sprite, "position:x", target_x, 0.3).set_trans(Tween.TRANS_LINEAR)

func update_pressure_bar(current_health, max_health):
	var health_ratio = float(current_health) / max_health
	
	# Calculate the target X position
	# If health is 0, target_x is -container_width (hidden to the left)
	# If health is 1.0, target_x is 0 (fully visible)
	var target_x = (health_ratio - 1.0) * container_width
	
	# Use a Tween for a smooth sliding effect
	var tween = create_tween()
	tween.tween_property(bar_sprite, "position:x", target_x, 0.3).set_trans(Tween.TRANS_LINEAR)

func _on_player_take_damage(health: int) -> void:
	update_health_bar(health, 100)

func switch_frame(frame:int):
	for i in len(frames):
		if i == frame:
			select_frame(frames[i])
		else:
			deselect_frame(frames[i])

func select_frame(texture: TextureRect):
	texture.modulate = Color(1, 1, 1, 1) # Intense Green Glow
	
func deselect_frame(texture: TextureRect):
	texture.modulate = Color(0.6, 0.6, 0.6, 1.0)
