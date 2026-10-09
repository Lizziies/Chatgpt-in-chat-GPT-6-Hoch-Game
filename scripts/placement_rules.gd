extends RefCounted
## Pure construction validation. Geometry is constrained to the game's own 3D map.
class_name PlacementRules

const CELL: float = 3.5
const WORLD_HALF: float = 54.0
const CORE_CLEARANCE: float = 6.25
const MAX_MACHINES: int = 110
const MAX_BELTS: int = 160

static func snap(at: Vector3) -> Vector3:
	return Vector3(roundf(at.x / CELL) * CELL, 0.0, roundf(at.z / CELL) * CELL)

static func grid_cell(at: Vector3) -> Vector2i:
	return Vector2i(roundi(at.x / CELL), roundi(at.z / CELL))

static func position_for(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * CELL, 0.0, float(cell.y) * CELL)

static func in_bounds(at: Vector3) -> bool:
	return is_finite(at.x) and is_finite(at.z) and absf(at.x) <= WORLD_HALF and absf(at.z) <= WORLD_HALF

static func machine_allowed(at: Vector3, machines: Array, belts: Array) -> bool:
	if not in_bounds(at) or Vector2(at.x, at.z).length() < CORE_CLEARANCE:
		return false
	if machines.size() >= MAX_MACHINES:
		return false
	for machine in machines:
		if str(machine.get("kind", "")) != "":
			var other: Vector3 = machine.get("position", Vector3.ZERO)
			if Vector2(at.x-other.x, at.z-other.z).length() < 3.35:
				return false
	for belt in belts:
		var p: Vector3 = position_for(belt)
		if Vector2(at.x-p.x, at.z-p.z).length() < 3.3:
			return false
	return true

static func belt_allowed(cell: Vector2i, machines: Array, belts: Array) -> bool:
	if belts.size() >= MAX_BELTS:
		return false
	var at: Vector3 = position_for(cell)
	if not in_bounds(at) or Vector2(at.x, at.z).length() < CORE_CLEARANCE:
		return false
	if belts.has(cell):
		return false
	for machine in machines:
		if str(machine.get("kind", "")) != "":
			var other: Vector3 = machine.get("position", Vector3.ZERO)
			if Vector2(at.x-other.x, at.z-other.z).length() < 3.3:
				return false
	return true

static func validate_layout(entries: Array, belt_cells: Array) -> bool:
	if entries.size() > MAX_MACHINES or belt_cells.size() > MAX_BELTS:
		return false
	var checked: Array = []
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			return false
		var kind: String = str(entry.get("kind", ""))
		var at: Vector3 = entry.get("position", Vector3.ZERO)
		if not IndustryState.MACHINES.has(kind) or snap(at).distance_to(at) > 0.01:
			return false
		if not machine_allowed(at, checked, []):
			return false
		checked.append({"position": at, "kind": kind})
	var valid_belts: Array = []
	for cell in belt_cells:
		if typeof(cell) != TYPE_VECTOR2I or not belt_allowed(cell, checked, valid_belts):
			return false
		valid_belts.append(cell)
	return true
