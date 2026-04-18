extends Node

var slot_order = ["COMBAT", "OBJECT", "ENTITY"]
var current_slot_index = 0

var clipboard = registers[slot_order[current_slot_index]]

var ctrl_attached = true
var offhand_mode = "C"  # or "V"
var spawn_position: Vector2 = Vector2.ZERO
