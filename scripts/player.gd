extends CharacterBody3D
## Third-person controller with orbit camera and an elevated construction view.
class_name VoidOperator

signal shoot(origin: Vector3, direction: Vector3)
signal respawned

const WALK_SPEED: float = 6.5
const SPRINT_SPEED: float = 10.0
const JUMP_VELOCITY: float = 6.0
const MOUSE_SENSITIVITY: float = 0.0025

var health: float = 100.0
var tactical: bool = false
var orbit: Node3D
var view: Camera3D
var model: Node3D
var pitch: float = -0.13
var yaw: float = 0.0
var shot_cooldown: float = 0.0

func _ready() -> void:
	name = "Operator"
	collision_layer = 2
	collision_mask = 1
	var collider := CollisionShape3D.new()
	var body := CapsuleShape3D.new()
	body.radius = 0.38
	body.height = 1.85
	collider.shape = body
	collider.position.y = 0.98
	add_child(collider)
	model = Node3D.new()
	model.name = "OperatorModel"
	add_child(model)
	_make_part("Armor", Vector3(0, 1.18, 0), Vector3(0.72, 0.85, 0.38), Color(0.13, 0.18, 0.22))
	_make_part("Helmet", Vector3(0, 1.78, 0), Vector3(0.43, 0.40, 0.43), Color(0.19, 0.25, 0.28))
	_make_part("Visor", Vector3(0, 1.79, -0.235), Vector3(0.36, 0.13, 0.05), Color(0.06, 0.9, 0.95), true)
	_make_part("LeftLeg", Vector3(-0.2, 0.47, 0), Vector3(0.24, 0.82, 0.25), Color(0.11, 0.14, 0.19))
	_make_part("RightLeg", Vector3(0.2, 0.47, 0), Vector3(0.24, 0.82, 0.25), Color(0.11, 0.14, 0.19))
	_make_part("LeftArm", Vector3(-0.49, 1.14, -0.03), Vector3(0.22, 0.68, 0.26), Color(0.13, 0.18, 0.22))
	_make_part("RightArm", Vector3(0.49, 1.14, -0.03), Vector3(0.22, 0.68, 0.26), Color(0.13, 0.18, 0.22))
	orbit = Node3D.new()
	orbit.name = "CameraRig"
	orbit.position = Vector3(0, 1.45, 0)
	add_child(orbit)
	view = Camera3D.new()
	view.name = "FollowCamera"
	view.position = Vector3(0, 2.3, 7.2)
	view.rotation.x = deg_to_rad(-17)
	view.fov = 72.0
	view.current = true
	orbit.add_child(view)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _make_part(part_name: String, pos: Vector3, size: Vector3, color: Color, glow: bool = false) -> void:
	var node := MeshInstance3D.new()
	node.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.62
	mat.roughness = 0.3
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 4.0
	node.material_override = mat
	model.add_child(node)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		yaw -= motion.relative.x * MOUSE_SENSITIVITY
		pitch = clampf(pitch - motion.relative.y * MOUSE_SENSITIVITY, -0.7, 0.45)
		orbit.rotation.y = yaw
		if not tactical:
			view.rotation.x = pitch - 0.15
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			elif shot_cooldown <= 0.0:
				shot_cooldown = 0.16
				shoot.emit(view.global_position, -view.global_transform.basis.z)
	elif event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif key.keycode == KEY_TAB:
			tactical = not tactical
			if tactical:
				view.position = Vector3(0, 22.0, 14.0)
				view.rotation.x = deg_to_rad(-58.0)
			else:
				view.position = Vector3(0, 2.3, 7.2)
				view.rotation.x = pitch - 0.15

func _physics_process(delta: float) -> void:
	shot_cooldown = maxf(0.0, shot_cooldown - delta)
	if not is_on_floor():
		velocity.y -= 17.0 * delta
	elif Input.is_key_pressed(KEY_SPACE) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		velocity.y = JUMP_VELOCITY
	var x_axis := int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
	var z_axis := int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
	var input_dir := Vector3(float(x_axis), 0.0, float(z_axis)).normalized()
	var forward := -orbit.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := orbit.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var direction := (right * input_dir.x - forward * input_dir.z).normalized()
	var speed: float = SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
	velocity.x = move_toward(velocity.x, direction.x * speed, 22.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 22.0 * delta)
	if direction.length_squared() > 0.02:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-direction.x, -direction.z), delta * 11.0)
	move_and_slide()

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		global_position = Vector3(0, 1.0, 11)
		velocity = Vector3.ZERO
		health = 100.0
		respawned.emit()
