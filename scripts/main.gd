extends Node3D
## VOID INDUSTRIES first playable 3D vertical slice.
## Procedural environment: no runtime downloads, trackers or third-party assets.

const StateScript = preload("res://scripts/game_state.gd")
const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/threat.gd")
const HudScript = preload("res://scripts/hud.gd")
const GridScript = preload("res://scripts/power_grid.gd")
const SAVE_PATH := "user://void_save.json"
const SAVE_TEMP_PATH := "user://void_save.pending"
const SAVE_LIMIT := 32768

var state: IndustryState
var player: VoidOperator
var hud: VoidHUD
var pads: Array[Dictionary] = []
var enemies: Array[AnomalyThreat] = []
var animated_parts: Array[Node3D] = []
var alarm_lights: Array[OmniLight3D] = []
var power_cables: Array[Node3D] = []
var wave_cooldown: float = 220.0
var last_network_connections: int = 0
var confirm_prestige_seconds: float = 0.0
var selected_machine: String = "generator"
var ui_timer: float = 0.0
var attack_timer: float = 0.0
var world_time: float = 0.0
var mat_floor: StandardMaterial3D
var mat_steel: StandardMaterial3D
var mat_dark: StandardMaterial3D
var mat_neon: StandardMaterial3D
var mat_amber: StandardMaterial3D
var mat_red: StandardMaterial3D

func _ready() -> void:
	randomize()
	state = StateScript.new()
	state.name = "OfflineResourceSimulation"
	add_child(state)
	state.status.connect(_on_status)
	state.breach_requested.connect(_spawn_breach)
	_create_materials()
	_create_world()
	_recalculate_power_grid()
	player = PlayerScript.new()
	player.position = Vector3(0.0, 1.0, 11.0)
	add_child(player)
	player.shoot.connect(_on_shoot)
	player.respawned.connect(_on_respawn)
	hud = HudScript.new()
	add_child(hud)
	hud.announce("REAKTOR ONLINE. Folge den Auftraegen und baue deine Industrie aus.")
	_refresh_hud()

func _create_materials() -> void:
	mat_floor = _material(Color(0.105, 0.13, 0.15), 0.58, 0.77)
	mat_steel = _material(Color(0.19, 0.235, 0.26), 0.76, 0.43)
	mat_dark = _material(Color(0.045, 0.075, 0.09), 0.55, 0.78)
	mat_neon = _material(Color(0.10, 0.77, 0.92), 0.25, 0.22, 3.8)
	mat_amber = _material(Color(1.0, 0.43, 0.12), 0.23, 0.36, 2.8)
	mat_red = _material(Color(0.92, 0.06, 0.11), 0.23, 0.40, 3.2)

func _material(color: Color, metallic: float, roughness: float, emission: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	return mat

func _create_world() -> void:
	var world_env := WorldEnvironment.new()
	world_env.name = "IndustrialAtmosphere"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.009, 0.014, 0.023)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.19, 0.28, 0.33)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_density = 0.012
	env.fog_light_color = Color(0.08, 0.14, 0.18)
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 34, 0)
	sun.light_color = Color(0.45, 0.67, 0.77)
	sun.light_energy = 0.34
	add_child(sun)
	_box(Vector3(82, 0.9, 82), Vector3(0, -0.48, 0), mat_floor, true)
	# Reinforced surrounding laboratory walls.
	for side in [-1.0, 1.0]:
		_box(Vector3(82, 12, 1.1), Vector3(0, 5.9, 40.3 * side), mat_dark, true)
		_box(Vector3(1.1, 12, 82), Vector3(40.3 * side, 5.9, 0), mat_dark, true)
	for grid_pos in range(-36, 37, 6):
		_box(Vector3(0.09, 0.02, 78), Vector3(float(grid_pos), 0.015, 0), mat_steel)
		_box(Vector3(78, 0.02, 0.09), Vector3(0, 0.018, float(grid_pos)), mat_steel)
	# Wall struts and suspended gantries.
	for z in range(-36, 37, 12):
		for side in [-1.0, 1.0]:
			_box(Vector3(0.85, 10.5, 1.25), Vector3(side * 39.0, 5.0, float(z)), mat_steel)
	for x in range(-30, 31, 15):
		_box(Vector3(0.6, 0.9, 79), Vector3(float(x), 10.5, 0), mat_steel)
	# Ventilation, conduits and small illuminated warning panels.
	for side in [-1.0, 1.0]:
		for height in [3.5, 8.1]:
			_pipe(Vector3(side * 38.4, height, -37), Vector3(side * 38.4, height, 37), 0.19, mat_steel)
			_pipe(Vector3(-37, height, side * 38.4), Vector3(37, height, side * 38.4), 0.14, mat_steel)
	for i in range(16):
		var z: float = -34.0 + 4.55 * float(i)
		_box(Vector3(0.12, 0.12, 1.6), Vector3(39.45, 3.9, z), mat_amber)
		_box(Vector3(0.12, 0.12, 1.6), Vector3(-39.45, 3.9, z), mat_amber)
	for i in range(4):
		var angle: float = TAU * float(i) / 4.0
		var pos := Vector3(cos(angle) * 34.0, 6.8, sin(angle) * 34.0)
		var beacon := OmniLight3D.new()
		beacon.name = "AlertBeacon_%d" % i
		beacon.position = pos
		beacon.light_color = Color(1.0, 0.08, 0.055)
		beacon.light_energy = 0.0
		beacon.omni_range = 15.0
		beacon.shadow_enabled = false
		add_child(beacon)
		alarm_lights.append(beacon)
		_box(Vector3(0.65, 0.4, 0.65), pos, mat_red)
	# Reactor shell, column, protected glass and spinning stabilizers.
	_cylinder(Vector3(0, 0.7, 0), 3.15, 1.4, mat_dark, true)
	_cylinder(Vector3(0, 1.7, 0), 1.25, 3.8, mat_neon)
	_cylinder(Vector3(0, 3.75, 0), 2.25, 0.6, mat_steel)
	_cylinder(Vector3(0, 4.1, 0), 1.75, 0.25, mat_amber)
	for i in range(8):
		var a: float = TAU * float(i) / 8.0
		var ring_point := Vector3(cos(a) * 2.35, 0.0, sin(a) * 2.35)
		_pipe(ring_point + Vector3(0, 1.2, 0), ring_point + Vector3(0, 3.5, 0), 0.12, mat_steel)
		_pipe(ring_point + Vector3(0, 1.5, 0), ring_point + Vector3(0, 3.3, 0), 0.045, mat_neon)
	_light(Vector3(0, 4.9, 0), Color(0.13, 0.83, 1.0), 8.0, 20.0)
	for i in range(18):
		var angle: float = TAU * float(i) / 18.0
		var distance: float = 11.8 + 6.8 * float(i % 2)
		var spot := Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		_create_pad(spot)
	for i in range(18):
		var angle: float = TAU * float(i) / 18.0
		var distance: float = 26.0 + float(i % 3) * 2.0
		var point := Vector3(cos(angle) * distance, 0, sin(angle) * distance)
		_box(Vector3(2.8, 0.4, 2.8), point + Vector3(0, 0.2, 0), mat_dark)
		_box(Vector3(0.25, 4.8, 0.25), point + Vector3(0, 2.5, 0), mat_steel)
		_box(Vector3(0.9, 0.26, 0.9), point + Vector3(0, 4.8, 0), mat_amber)
		if i % 2 == 0:
			_light(point + Vector3(0, 4.45, 0), Color(0.13, 0.72, 0.91), 1.25, 13.0)
	for i in range(4):
		var a: float = TAU * float(i) / 4.0 + PI / 4.0
		var x: float = cos(a) * 23.0
		var z: float = sin(a) * 23.0
		_box(Vector3(6.2, 1.5, 3.2), Vector3(x, 0.75, z), mat_steel)
		_box(Vector3(4.5, 2.5, 2.2), Vector3(x, 2.35, z), mat_dark)
		_pipe(Vector3(x-2, 3, z), Vector3(x+2, 3, z), 0.18, mat_amber)

func _create_pad(location: Vector3) -> void:
	_cylinder(location + Vector3(0, 0.085, 0), 2.05, 0.18, mat_steel)
	_cylinder(location + Vector3(0, 0.19, 0), 1.85, 0.055, mat_neon)
	_cylinder(location + Vector3(0, 0.23, 0), 1.65, 0.075, mat_dark)
	for n in range(4):
		var angle: float = TAU * float(n) / 4.0
		_box(Vector3(0.38, 0.3, 0.38), location + Vector3(cos(angle) * 1.7, 0.38, sin(angle) * 1.7), mat_amber)
	pads.append({"position": location, "kind": "", "machine_node": null})

func _box(size: Vector3, at: Vector3, mat: Material, solid: bool = false, parent: Node3D = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = mat
	visual.position = at
	var host: Node3D = parent if parent != null else self
	host.add_child(visual)
	if solid:
		var static_body := StaticBody3D.new()
		static_body.position = at
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		static_body.add_child(shape)
		host.add_child(static_body)
	return visual

func _cylinder(at: Vector3, radius: float, height: float, mat: Material, solid: bool = false, parent: Node3D = null) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 18
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	var host: Node3D = parent if parent != null else self
	host.add_child(node)
	if solid:
		var static_body := StaticBody3D.new()
		static_body.position = at
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = radius
		cylinder.height = height
		shape.shape = cylinder
		static_body.add_child(shape)
		host.add_child(static_body)
	return node

func _pipe(a: Vector3, b: Vector3, radius: float, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var vec := b - a
	if vec.length_squared() < 0.0001:
		return null
	var pipe := _cylinder((a + b) * 0.5, radius, vec.length(), mat, false, parent)
	pipe.quaternion = Quaternion(Vector3.UP, vec.normalized())
	return pipe

func _light(pos: Vector3, color: Color, energy: float, radius: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = pos
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = radius
	lamp.shadow_enabled = false
	add_child(lamp)

func _build_machine(index: int, kind: String) -> void:
	if index < 0 or index >= pads.size() or not IndustryState.MACHINES.has(kind):
		return
	var pad: Dictionary = pads[index]
	if is_instance_valid(pad.get("machine_node")):
		return
	var machine := Node3D.new()
	machine.name = kind.capitalize() + "_" + str(index)
	machine.position = pad["position"]
	add_child(machine)
	_box(Vector3(2.7, 0.6, 2.7), Vector3(0, 0.6, 0), mat_steel, false, machine)
	match kind:
		"generator":
			_cylinder(Vector3(0, 1.6, 0), 0.85, 1.6, mat_dark, false, machine)
			_cylinder(Vector3(0, 2.55, 0), 0.92, 0.26, mat_neon, false, machine)
			for i in range(4):
				var a: float = TAU * float(i) / 4.0
				_pipe(Vector3(cos(a), 0.9, sin(a)), Vector3(cos(a), 2.4, sin(a)), 0.1, mat_neon, machine)
			animated_parts.append(_cylinder(Vector3(0, 3.0, 0), 0.43, 0.15, mat_amber, false, machine))
		"extractor":
			_box(Vector3(1.5, 2.6, 1.65), Vector3(0, 1.8, 0), mat_dark, false, machine)
			_pipe(Vector3(-1.0, 2.8, 0), Vector3(1.0, 1.2, 0), 0.27, mat_steel, machine)
			_cylinder(Vector3(0, 3.25, 0), 0.85, 0.21, mat_amber, false, machine)
		"laboratory":
			_box(Vector3(2.35, 1.8, 2.1), Vector3(0, 1.6, 0), mat_dark, false, machine)
			_box(Vector3(2.0, 0.16, 0.13), Vector3(0, 1.85, -1.12), mat_neon, false, machine)
			_cylinder(Vector3(0, 3.0, 0), 0.38, 0.8, mat_neon, false, machine)
			for i in range(3):
				_box(Vector3(0.35, 0.35, 0.35), Vector3(-0.7 + 0.7 * i, 2.45, -1.10), mat_amber, false, machine)
		"turret":
			_cylinder(Vector3(0, 1.25, 0), 0.75, 1.0, mat_dark, false, machine)
			_cylinder(Vector3(0, 2.15, 0), 0.85, 0.7, mat_steel, false, machine)
			_pipe(Vector3(0, 2.2, -0.2), Vector3(0, 2.2, -1.7), 0.2, mat_neon, machine)
			_box(Vector3(0.9, 0.1, 0.25), Vector3(0, 2.65, -0.2), mat_amber, false, machine)
		"capacitor":
			_cylinder(Vector3(0, 1.1, 0), 0.95, 0.45, mat_dark, false, machine)
			_cylinder(Vector3(0, 1.85, 0), 0.57, 1.5, mat_neon, false, machine)
			for i in range(4):
				var a: float = TAU * float(i) / 4.0
				_pipe(Vector3(cos(a) * 0.85, 0.95, sin(a) * 0.85), Vector3(cos(a) * 0.85, 2.55, sin(a) * 0.85), 0.11, mat_steel, machine)
			animated_parts.append(_cylinder(Vector3(0, 2.85, 0), 0.9, 0.18, mat_amber, false, machine))
		"fabricator":
			_box(Vector3(2.25, 1.45, 2.25), Vector3(0, 1.5, 0), mat_dark, false, machine)
			_box(Vector3(1.7, 0.24, 1.7), Vector3(0, 2.35, 0), mat_amber, false, machine)
			animated_parts.append(_cylinder(Vector3(0, 2.75, 0), 0.55, 0.2, mat_neon, false, machine))
		"harvester":
			_cylinder(Vector3(0, 1.45, 0), 1.0, 1.8, mat_dark, false, machine)
			_cylinder(Vector3(0, 2.7, 0), 0.68, 0.8, mat_red, false, machine)
			animated_parts.append(_cylinder(Vector3(0, 3.5, 0), 1.02, 0.18, mat_amber, false, machine))
		"stabilizer":
			_box(Vector3(2.2, 1.4, 2.2), Vector3(0, 1.3, 0), mat_dark, false, machine)
			for i in range(4):
				var a: float = TAU * float(i) / 4.0
				var off := Vector3(cos(a) * 0.85, 0, sin(a) * 0.85)
				_cylinder(off + Vector3(0, 2.35, 0), 0.23, 1.1, mat_steel, false, machine)
				_cylinder(off + Vector3(0, 3.0, 0), 0.29, 0.13, mat_amber, false, machine)
			_cylinder(Vector3(0, 2.75, 0), 0.68, 0.6, mat_neon, false, machine)
			animated_parts.append(_cylinder(Vector3(0, 3.25, 0), 0.85, 0.15, mat_neon, false, machine))
	pad["kind"] = kind
	pad["machine_node"] = machine
	pads[index] = pad

func _process(delta: float) -> void:
	var dt: float = minf(delta, 0.2)
	world_time += dt
	state.tick(dt)
	wave_cooldown -= dt
	confirm_prestige_seconds = maxf(0.0, confirm_prestige_seconds - dt)
	if wave_cooldown <= 0.0:
		wave_cooldown = 175.0 + randf_range(0.0, 70.0)
		if state.tech_level >= 2 and state.instability > 12.0:
			hud.announce("ALARM: Instabilitaet zieht Anomalien an!")
			_spawn_breach(2 + state.tech_level / 2)
	var under_alarm: bool = not enemies.is_empty() or state.instability > 55.0
	var flash: float = 1.1 + 1.4 * absf(sin(world_time * 5.0)) if under_alarm else 0.0
	for beacon in alarm_lights:
		beacon.light_energy = flash
	for part in animated_parts:
		if is_instance_valid(part):
			part.rotate_y(dt * 0.8)
	ui_timer -= dt
	attack_timer -= dt
	if attack_timer <= 0.0:
		attack_timer = 0.9
		_turret_attack()
	if ui_timer <= 0.0:
		ui_timer = 0.2
		_refresh_hud()

func _refresh_hud() -> void:
	if is_instance_valid(hud) and is_instance_valid(player):
		hud.refresh(state, player.health, selected_machine, enemies.size(), last_network_connections)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1: selected_machine = "generator"
		KEY_2: selected_machine = "extractor"
		KEY_3: selected_machine = "laboratory"
		KEY_4: selected_machine = "turret"
		KEY_5: selected_machine = "capacitor"
		KEY_6: selected_machine = "stabilizer"
		KEY_7: selected_machine = "fabricator"
		KEY_8: selected_machine = "harvester"
		KEY_J: _try_salvage()
		KEY_E: _try_build()
		KEY_F: state.research()
		KEY_R: state.experiment()
		KEY_G: state.experiment(true)
		KEY_C: state.pulse()
		KEY_Q: state.claim_directive()
		KEY_Z: state.upgrade_branch("energy")
		KEY_X: state.upgrade_branch("industry")
		KEY_V: state.upgrade_branch("containment")
		KEY_B: _try_prestige()
		KEY_Y: _try_elite_trial()
		KEY_H: hud.toggle_help()
		KEY_T: state.repair_core()
		KEY_P: _save_game()
		KEY_O: _load_game()
	_refresh_hud()

func _try_build() -> void:
	var nearest: int = -1
	var distance: float = 5.1
	for i in range(pads.size()):
		if pads[i]["kind"] != "":
			continue
		var p: Vector3 = pads[i]["position"]
		var flat_player := Vector3(player.position.x, 0.0, player.position.z)
		var d: float = p.distance_to(flat_player)
		if d < distance:
			distance = d
			nearest = i
	if nearest < 0:
		hud.announce("Gehe zu einer freien, blau beleuchteten Bauplattform.")
		return
	if state.buy_machine(selected_machine):
		_build_machine(nearest, selected_machine)
		_recalculate_power_grid()
		if state.machine_count(selected_machine) < int(state.machines[selected_machine]):
			hud.announce("ACHTUNG: Maschine ohne Energieanschluss! Baue Richtung Reaktorkern.")

func _try_salvage() -> void:
	var nearest: int = -1
	var closest: float = 5.1
	for i in range(pads.size()):
		if str(pads[i]["kind"]) == "":
			continue
		var at: Vector3 = pads[i]["position"]
		var distance: float = at.distance_to(Vector3(player.position.x, 0, player.position.z))
		if distance < closest:
			closest = distance
			nearest = i
	if nearest < 0:
		hud.announce("Keine gebaute Maschine in Reichweite.")
		return
	var kind: String = str(pads[nearest]["kind"])
	if state.salvage_machine(kind):
		var node: Variant = pads[nearest]["machine_node"]
		if is_instance_valid(node):
			node.queue_free()
		pads[nearest]["machine_node"] = null
		pads[nearest]["kind"] = ""
		animated_parts = animated_parts.filter(func(part: Node3D) -> bool: return is_instance_valid(part) and not part.is_queued_for_deletion() and part.get_parent() != node)
		_recalculate_power_grid()

func _try_elite_trial() -> void:
	for threat in enemies:
		if is_instance_valid(threat) and threat.live and threat.elite:
			hud.announce("ELITE-TEST: Eine Elite-Anomalie ist bereits aktiv.")
			return
	if enemies.size() >= 23:
		hud.announce("ELITE-TEST: Zu viele aktive Feinde.")
		return
	if state.authorize_containment_trial():
		_spawn_breach(1, true)

func _try_prestige() -> void:
	if not state.prestige_eligible():
		state.initiate_prestige()
		return
	if confirm_prestige_seconds <= 0.0:
		confirm_prestige_seconds = 9.0
		hud.announce("SINGULARITAET: B erneut innerhalb von 9s = Fabrik-RESET. Kerne bleiben!")
		return
	confirm_prestige_seconds = 0.0
	if state.initiate_prestige():
		_clear_factory()
		_recalculate_power_grid()
		for e in enemies:
			if is_instance_valid(e):
				e.queue_free()
		enemies.clear()
		player.health = 100.0

func _clear_factory() -> void:
	animated_parts.clear()
	for i in range(pads.size()):
		var old: Variant = pads[i]["machine_node"]
		if is_instance_valid(old):
			old.queue_free()
		pads[i]["machine_node"] = null
		pads[i]["kind"] = ""

func _recalculate_power_grid() -> void:
	for wire in power_cables:
		if is_instance_valid(wire):
			wire.queue_free()
	power_cables.clear()
	var snapshot: Dictionary = GridScript.solve(pads)
	state.configure_power_grid(snapshot["counts"], snapshot["synergies"])
	last_network_connections = int(snapshot["connected"])
	for link in snapshot["links"]:
		var connection: Vector2i = link
		var finish: Vector3 = pads[connection.y]["position"] + Vector3(0, 0.34, 0)
		var start: Vector3 = Vector3(0, 0.5, 0) if connection.x < 0 else pads[connection.x]["position"] + Vector3(0, 0.34, 0)
		var wire: MeshInstance3D = _pipe(start, finish, 0.055, mat_neon)
		if wire != null:
			power_cables.append(wire)
	# Unpowered machines receive dim red warning beacons.
	for i in range(pads.size()):
		var pad: Dictionary = pads[i]
		var machine_node: Variant = pad["machine_node"]
		if not is_instance_valid(machine_node):
			continue
		var existing: Node = machine_node.get_node_or_null("PowerWarning")
		if existing != null:
			existing.queue_free()
		if not snapshot["powered"][i]:
			var warning := Node3D.new()
			warning.name = "PowerWarning"
			machine_node.add_child(warning)
			_box(Vector3(0.52, 0.12, 0.52), Vector3(0, 3.6, 0), mat_red, false, warning)

func _on_status(message: String) -> void:
	if is_instance_valid(hud):
		hud.announce(message)

func _spawn_breach(amount: int, spawn_elite: bool = false) -> void:
	for i in range(mini(amount, 12)):
		if enemies.size() >= 24:
			break
		var e: AnomalyThreat = EnemyScript.new()
		var angle: float = randf_range(0.0, TAU)
		var radius: float = randf_range(24.0, 33.0)
		e.position = Vector3(cos(angle) * radius, 1.0, sin(angle) * radius)
		e.initialize(player, state.tech_level, spawn_elite)
		e.core_struck.connect(_on_core_hit)
		e.player_struck.connect(_on_player_hit)
		e.destroyed.connect(_on_enemy_destroyed.bind(spawn_elite))
		add_child(e)
		enemies.append(e)

func _on_core_hit(amount: float) -> void:
	state.damage_core(amount)

func _on_player_hit(amount: float) -> void:
	player.take_damage(amount)

func _on_respawn() -> void:
	state.energy *= 0.85
	hud.announce("OPERATOR GERETTET. Notfall-Rueckkehr: 15% Energie verloren.")

func _on_enemy_destroyed(_at: Vector3, was_elite: bool = false) -> void:
	state.waves_survived += 1
	state.alloy = minf(IndustryState.MAX_RESOURCES, state.alloy + 6.0)
	if was_elite:
		state.void_matter = minf(IndustryState.MAX_RESOURCES, state.void_matter + 4.0)
		state.data = minf(IndustryState.MAX_RESOURCES, state.data + 170.0)
		state.alloy = minf(IndustryState.MAX_RESOURCES, state.alloy + 110.0)
		hud.announce("ELITE BESIEGT! +4 VOID, +170 DATEN, +110 LEGIERUNG!")
	# defer so removed nodes are not used on the current physics tick
	call_deferred("_prune_enemies")

func _prune_enemies() -> void:
	var living: Array[AnomalyThreat] = []
	for e in enemies:
		if is_instance_valid(e) and e.live:
			living.append(e)
	enemies = living

func _turret_attack() -> void:
	for pad in pads:
		if pad["kind"] != "turret":
			continue
		var nearest: AnomalyThreat = null
		var nearest_distance: float = 17.0
		var origin: Vector3 = pad["position"] + Vector3(0, 2.2, 0)
		for enemy in enemies:
			if not is_instance_valid(enemy) or not enemy.live:
				continue
			var d: float = origin.distance_to(enemy.global_position)
			if d < nearest_distance:
				nearest_distance = d
				nearest = enemy
		if nearest != null:
			_spawn_beam(origin, nearest.global_position + Vector3(0, 1.1, 0), mat_amber)
			nearest.take_hit(22.0 + state.tech_level * 4.0 + float(state.synergies["turret_stabilizer"]) * 8.0)

func _on_shoot(origin: Vector3, direction: Vector3) -> void:
	var ray := PhysicsRayQueryParameters3D.create(origin, origin + direction * 70.0)
	ray.exclude = [player.get_rid()]
	ray.collision_mask = 1 | 4
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
	var destination: Vector3 = origin + direction * 70.0
	if not hit.is_empty():
		destination = hit["position"]
		if hit["collider"] is AnomalyThreat:
			var threat: AnomalyThreat = hit["collider"]
			threat.take_hit(35.0 + float(state.tech_level) * 3.0)
	_spawn_beam(origin + direction * 0.8, destination, mat_neon)

func _spawn_beam(a: Vector3, b: Vector3, mat: Material) -> void:
	if a.distance_to(b) < 0.1:
		return
	var effect: MeshInstance3D = _pipe(a, b, 0.035, mat)
	var timeout := get_tree().create_timer(0.10)
	timeout.timeout.connect(func() -> void:
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _save_game() -> void:
	var serialized_pads: Array[String] = []
	for pad in pads:
		serialized_pads.append(str(pad["kind"]))
	var snapshot := {"version": 4, "state": state.to_save(), "pads": serialized_pads}
	var data_string: String = JSON.stringify(snapshot)
	if data_string.length() > SAVE_LIMIT:
		hud.announce("Spielstand zu gross. Speichern abgebrochen.")
		return
	# First write to the fixed application-local staging file; only replace the
	# previous save after a complete successful write.
	var file := FileAccess.open(SAVE_TEMP_PATH, FileAccess.WRITE)
	if file == null:
		hud.announce("Speichern fehlgeschlagen (keine Dateiberechtigung).")
		return
	file.store_string(data_string)
	file.flush()
	if file.get_error() != OK:
		file.close()
		hud.announce("Speichern fehlgeschlagen: Schreibfehler.")
		return
	file.close()
	var source: String = ProjectSettings.globalize_path(SAVE_TEMP_PATH)
	var destination: String = ProjectSettings.globalize_path(SAVE_PATH)
	if DirAccess.rename_absolute(source, destination) != OK:
		hud.announce("Speichern fehlgeschlagen: Alte Datei bleibt bestehen.")
		return
	hud.announce("LOKAL UND SICHER GESPEICHERT - Nur im Godot-Appverzeichnis.")

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		hud.announce("Kein lokaler Spielstand vorhanden.")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		hud.announce("Spielstand konnte nicht gelesen werden.")
		return
	if file.get_length() > SAVE_LIMIT:
		file.close()
		hud.announce("Spielstand zu gross - Laden verweigert.")
		return
	var raw: String = file.get_as_text()
	file.close()
	var document: Variant = JSON.parse_string(raw)
	if typeof(document) != TYPE_DICTIONARY:
		hud.announce("Ungueltiger Spielstand.")
		return
	var parsed: Dictionary = document
	var raw_version: Variant = parsed.get("version", -1)
	if typeof(raw_version) != TYPE_INT and typeof(raw_version) != TYPE_FLOAT:
		hud.announce("Unbekannte Spielstand-Version.")
		return
	var save_version: float = float(raw_version)
	if is_nan(save_version) or is_inf(save_version) or save_version != floor(save_version) or save_version < 1.0 or save_version > 4.0:
		hud.announce("Unbekannte Spielstand-Version.")
		return
	var restored_pads: Variant = parsed.get("pads", [])
	if typeof(restored_pads) != TYPE_ARRAY or restored_pads.size() != pads.size():
		hud.announce("Spielstand hat ungueltige Bauplattformen.")
		return
	for kind in restored_pads:
		if typeof(kind) != TYPE_STRING or (kind != "" and not IndustryState.MACHINES.has(kind)):
			hud.announce("Spielstand enthaelt ungueltige Maschinen.")
			return
	var snapshot: Variant = parsed.get("state", {})
	if typeof(snapshot) != TYPE_DICTIONARY:
		hud.announce("Spielstand enthaelt ungueltige Ressourcen.")
		return
	# Check save technology and machine compatibility BEFORE mutating the economy.
	var save_level: Variant = snapshot.get("tech_level", -1)
	if typeof(save_level) != TYPE_INT and typeof(save_level) != TYPE_FLOAT:
		hud.announce("Ungueltige Forschungsdaten.")
		return
	var level_number: int = int(save_level)
	var count_by_kind: Dictionary = {}
	for kind in IndustryState.MACHINES:
		count_by_kind[kind] = 0
	for kind in restored_pads:
		if kind == "":
			continue
		count_by_kind[kind] = int(count_by_kind[kind]) + 1
		if not IndustryState.UNLOCKS.has(kind) or level_number < int(IndustryState.UNLOCKS[kind]):
			# Old alpha save files allowed the turret before research unlock.
			if not (parsed.get("version") == 1 and kind == "turret"):
				hud.announce("Spielstand enthaelt gesperrte Maschinen.")
				return
	if not state.restore(snapshot):
		hud.announce("Spielstand enthaelt ungueltige Ressourcen.")
		return
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	_clear_factory()
	for kind in IndustryState.MACHINES:
		state.machines[kind] = 0
	for i in range(pads.size()):
		var kind: String = restored_pads[i]
		if kind != "":
			_build_machine(i, kind)
			state.machines[kind] = int(state.machines[kind]) + 1
	_recalculate_power_grid()
	hud.announce("LOKALER SPIELSTAND GELADEN.")
	_refresh_hud()
