extends Node

var clipboard = null
var ctrl_attached = true
var offhand_mode = "C"  # or "V"
var spawn_position: Vector2 = Vector2.ZERO
var collected_keys: Array[String] = []
