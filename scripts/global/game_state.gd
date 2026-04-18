extends Node

const DEFAULT_ITEM_SCENE = "res://scenes/gravity_inverter.tscn"

var clipboard = null
var ctrl_attached = true
var offhand_mode = "C"  # or "V"
var spawn_position: Vector2 = Vector2.ZERO
var ctrl_position: Vector2 = Vector2.ZERO
var ctrl_position_locked: bool = false
var collected_keys: Array[String] = []

func _ready() -> void:
	_init_default_clipboard()

func _init_default_clipboard() -> void:
	if clipboard != null:
		return
	_build_default_clipboard()

func reset_clipboard() -> void:
	_build_default_clipboard()

func _build_default_clipboard() -> void:
	var cap = load(DEFAULT_ITEM_SCENE).instantiate()
	var data = ClipboardData.new()
	data.type = "object"
	data.scene_ref = DEFAULT_ITEM_SCENE
	data.data = {}
	var sprite2d = cap.get_node_or_null("AnimatedSprite2D")
	if sprite2d and sprite2d.sprite_frames:
		data.sprite_frames = sprite2d.sprite_frames.duplicate(true)
	clipboard = data
	cap.free()
