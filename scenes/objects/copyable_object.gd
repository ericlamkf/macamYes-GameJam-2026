extends CharacterBody2D
class_name CopyableObjectBase

@export var object_id: String = "generic_object"
@export var timeout: int = 5
@export var will_expired: bool = false

func _ready():
	# Put all copyable objects on a specific collision layer (e.g., Layer 5)
	set_collision_layer_value(5, true) 
	if(will_expired):
		$Timer.start(timeout)

# The Player's Ctrl+V script should call this right after add_child()
func on_pasted(will_expired: bool):
	if(will_expired):
		$Timer.start(timeout)
	print("Pasted into reality: ", object_id)

func get_clipboard_data() -> ClipboardData:
	var data = ClipboardData.new()
	data.type = "object"
	data.sprite_frames = $AnimatedSprite2D.sprite_frames
	data.data = {
		
	}
	data.scene_ref = self.scene_file_path
	return data

func _on_timer_timeout():
	queue_free()
