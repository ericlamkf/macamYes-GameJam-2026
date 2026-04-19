extends CopyableObjectBase

@export var active: bool = true

# Bodies currently inside THIS field
var bodies_in_field := []


# ------------------------
# BODY ENTER / EXIT
# ------------------------

func _on_body_entered(body):
	if not has_gravity(body):
		return

	if body not in bodies_in_field:
		bodies_in_field.append(body)

	ensure_body_initialized(body)

	if active:
		body.gravity_field_count += 1
		
		update_gravity(body)


func _on_body_exited(body):
	if body not in bodies_in_field:
		return

	bodies_in_field.erase(body)

	if active and has_gravity(body):
		body.gravity_field_count -= 1
		body.gravity_field_count = max(body.gravity_field_count, 0)
		update_gravity(body)


# ------------------------
# CORE LOGIC (GLOBAL PER BODY)
# ------------------------

func ensure_body_initialized(body):
	if body.get("gravity_field_count") == null:
		body.gravity_field_count = 0

	if body.get("base_gravity") == null:
		body.base_gravity = body.gravity


func update_gravity(body):
	var count = body.gravity_field_count
	var base = body.base_gravity

	# Odd = inverted, Even = normal
	if count % 2 == 1:
		body.gravity = -abs(base)
	else:
		body.gravity = abs(base)


# ------------------------
# STATE TOGGLE (IMPORTANT)
# ------------------------

func set_active(value: bool):
	if active == value:
		return

	active = value

	for body in bodies_in_field:
		if not has_gravity(body):
			continue

		ensure_body_initialized(body)

		if active:
			body.gravity_field_count += 1
		else:
			body.gravity_field_count -= 1
			body.gravity_field_count = max(body.gravity_field_count, 0)

		update_gravity(body)


# ------------------------
# DAMAGE → TOGGLE ON/OFF
# ------------------------

func take_damage(amount: int):
	# Toggle instead of just turning off
	set_active(!active)

	# Optional visual feedback
	if has_node("Sprite2D"):
		if active:
			$Sprite2D.modulate = Color(1, 1, 1)
		else:
			$Sprite2D.modulate = Color(0.5, 0.5, 0.5)

	print("Gravity field active:", active)


# ------------------------
# HELPER
# ------------------------

func has_gravity(body) -> bool:
	return body.get("gravity") != null
