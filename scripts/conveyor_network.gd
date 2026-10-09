extends RefCounted
## Shortest-path, physically-connected conveyor routing. No filesystem or networking.
class_name ConveyorNetwork

const CELL: float = 3.5
const OFFSETS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

static func _near_machine(cell: Vector2i, point: Vector3) -> bool:
	return PlacementRules.position_for(cell).distance_to(Vector3(point.x, 0.0, point.z)) <= CELL * 1.46

static func solve(machines: Array, belts: Array, powered: Array) -> Dictionary:
	var cells: Dictionary = {}
	for cell in belts:
		cells[cell] = true
	var paths: Array = []
	var active_cells: Dictionary = {}
	var used_targets: Dictionary = {}
	for source_index in range(machines.size()):
		if str(machines[source_index].get("kind", "")) != "fabricator":
			continue
		if source_index >= powered.size() or not bool(powered[source_index]):
			continue
		var start_pos: Vector3 = machines[source_index]["position"]
		var queue: Array[Vector2i] = []
		var parent: Dictionary = {}
		for cell in belts:
			if _near_machine(cell, start_pos):
				queue.append(cell)
				parent[cell] = cell
		var front: int = 0
		var found: Vector2i = Vector2i.ZERO
		var found_target: int = -1
		while front < queue.size() and found_target == -1:
			var current: Vector2i = queue[front]
			front += 1
			for target_index in range(machines.size()):
				if target_index >= powered.size() or not bool(powered[target_index]) or used_targets.has(target_index):
					continue
				if str(machines[target_index].get("kind", "")) == "harvester":
					if _near_machine(current, machines[target_index]["position"]):
						found = current
						found_target = target_index
						break
			if found_target != -1:
				break
			for offset in OFFSETS:
				var next: Vector2i = current + offset
				if cells.has(next) and not parent.has(next):
					parent[next] = current
					queue.append(next)
		if found_target == -1:
			continue
		used_targets[found_target] = true
		var path: Array[Vector2i] = []
		var current_cell: Vector2i = found
		path.push_front(current_cell)
		while parent[current_cell] != current_cell:
			current_cell = parent[current_cell]
			path.push_front(current_cell)
		for active in path:
			active_cells[active] = true
		paths.append(path)
	return {"routes": paths.size(), "paths": paths, "active_tiles": active_cells.size()}
