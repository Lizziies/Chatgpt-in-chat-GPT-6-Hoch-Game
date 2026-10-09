extends RefCounted
## Pure, deterministic connectivity solver: no IO, no scene tree, no wall-clock.
class_name PowerGrid

const HUB_RADIUS: float = 13.6
const CABLE_RANGE: float = 9.6

static func solve(pads: Array) -> Dictionary:
	var total: int = pads.size()
	var visited: Array[bool] = []
	visited.resize(total)
	visited.fill(false)
	var next: Array[int] = []
	var links: Array[Vector2i] = []
	var counts: Dictionary = {}
	for kind in IndustryState.MACHINES:
		counts[kind] = 0
	for i in range(total):
		if str(pads[i].get("kind", "")) == "":
			continue
		var origin: Vector3 = pads[i].get("position", Vector3.ZERO)
		var flat: Vector2 = Vector2(origin.x, origin.z)
		if flat.length() <= HUB_RADIUS:
			visited[i] = true
			next.append(i)
			links.append(Vector2i(-1, i))
	var front: int = 0
	while front < next.size():
		var source: int = next[front]
		front += 1
		var from_pos: Vector3 = pads[source].get("position", Vector3.ZERO)
		for target in range(total):
			if visited[target] or str(pads[target].get("kind", "")) == "":
				continue
			var to_pos: Vector3 = pads[target].get("position", Vector3.ZERO)
			var horizontal_distance: float = Vector2(
				from_pos.x - to_pos.x, from_pos.z - to_pos.z).length()
			if horizontal_distance <= CABLE_RANGE:
				visited[target] = true
				next.append(target)
				links.append(Vector2i(source, target))
	for i in range(total):
		if not visited[i]:
			continue
		var kind: String = str(pads[i].get("kind", ""))
		if counts.has(kind):
			counts[kind] = int(counts[kind]) + 1
	var synergies: Dictionary = {"lab_extractor": 0, "generator_capacitor": 0, "turret_stabilizer": 0}
	for i in range(total):
		if not visited[i]:
			continue
		var kind_a: String = str(pads[i].get("kind", ""))
		var point_a: Vector3 = pads[i].get("position", Vector3.ZERO)
		for j in range(i + 1, total):
			if not visited[j]:
				continue
			var kind_b: String = str(pads[j].get("kind", ""))
			var point_b: Vector3 = pads[j].get("position", Vector3.ZERO)
			var gap: float = Vector2(point_a.x - point_b.x, point_a.z - point_b.z).length()
			if gap > CABLE_RANGE:
				continue
			if (kind_a == "laboratory" and kind_b == "extractor") or (kind_a == "extractor" and kind_b == "laboratory"):
				synergies["lab_extractor"] = int(synergies["lab_extractor"]) + 1
			elif (kind_a == "generator" and kind_b == "capacitor") or (kind_a == "capacitor" and kind_b == "generator"):
				synergies["generator_capacitor"] = int(synergies["generator_capacitor"]) + 1
			elif (kind_a == "turret" and kind_b == "stabilizer") or (kind_a == "stabilizer" and kind_b == "turret"):
				synergies["turret_stabilizer"] = int(synergies["turret_stabilizer"]) + 1
	return {"powered": visited, "counts": counts, "links": links, "connected": next.size(), "synergies": synergies}
