extends CharacterBody3D
## Simple local-only hostile unit; no pathfinding plugins or network.
class_name AnomalyThreat

signal core_struck(amount: float)
signal player_struck(amount: float)
signal destroyed(position_world: Vector3)

var health: float = 70.0
var speed: float = 3.2
var damage: float = 7.0
var target: Node3D
var attack_timer: float = 0.0
var live: bool = true
var body_mesh: MeshInstance3D

func initialize(player_target: Node3D, tier: int = 0) -> void:
	target = player_target
	health = 70.0 + float(tier) * 26.0
	speed = 3.2 + float(tier) * 0.22
	damage = 7.0 + float(tier) * 2.0

func _ready() -> void:
	name = "Hostile_Anomaly"
	collision_layer = 4
	collision_mask = 1
	var shape := CapsuleShape3D.new()
	shape.radius = 0.49
	shape.height = 1.9
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 1.0
	add_child(col)
	body_mesh = MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.48
	mesh.height = 1.9
	body_mesh.mesh = mesh
	body_mesh.position.y = 1.0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.31, 0.27)
	material.emission_enabled = true
	material.emission = Color(0.02, 0.45, 0.26)
	material.emission_energy_multiplier = 1.7
	material.roughness = 0.63
	body_mesh.material_override = material
	add_child(body_mesh)
	var eye := MeshInstance3D.new()
	var eye_mesh := BoxMesh.new()
	eye_mesh.size = Vector3(0.58, 0.12, 0.11)
	eye.mesh = eye_mesh
	eye.position = Vector3(0, 1.4, -0.45)
	var eye_material := StandardMaterial3D.new()
	eye_material.albedo_color = Color(1, 0.22, 0.08)
	eye_material.emission_enabled = true
	eye_material.emission = Color(1, 0.12, 0.04)
	eye_material.emission_energy_multiplier = 4.5
	eye.material_override = eye_material
	add_child(eye)

func _physics_process(delta: float) -> void:
	if not live:
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	if not is_on_floor():
		velocity.y -= 17.0 * delta
	var objective: Vector3 = Vector3.ZERO
	var player_in_range: bool = is_instance_valid(target) and global_position.distance_to(target.global_position) < 8.0
	if player_in_range:
		objective = target.global_position
	var flat_difference := objective - global_position
	flat_difference.y = 0.0
	if flat_difference.length() > 1.8:
		var heading := flat_difference.normalized()
		velocity.x = heading.x * speed
		velocity.z = heading.z * speed
		rotation.y = lerp_angle(rotation.y, atan2(-heading.x, -heading.z), delta * 6.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
		if attack_timer <= 0.0:
			attack_timer = 1.25
			if player_in_range:
				player_struck.emit(damage)
			else:
				core_struck.emit(damage)
	move_and_slide()

func take_hit(amount: float) -> void:
	if not live or amount <= 0.0:
		return
	health -= amount
	if health <= 0.0:
		live = false
		destroyed.emit(global_position)
		queue_free()
