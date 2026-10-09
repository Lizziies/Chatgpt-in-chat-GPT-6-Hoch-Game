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
	return {"powered": visited, "counts": counts, "links": links, "connected": next.size()}
