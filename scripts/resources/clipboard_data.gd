extends Resource

class_name ClipboardData

# Defines if this is a "block", "projectile" or "enemy"
@export var type: String = "block"

# The actual scene that will be instantiated when Ctrl + V is pressed
@export var scene_ref: String

# Any extra stats speed, health, direction to retain when pasting
@export var data: Dictionary = {}
