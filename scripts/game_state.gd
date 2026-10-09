extends Node
## Deterministic, offline resource simulation. Does not access network or OS data.
class_name IndustryState

signal status(message: String)
signal breach_requested(amount: int)

const MAX_RESOURCES := 1.0e12
const MACHINES := ["generator", "extractor", "laboratory", "turret"]
const COSTS := {
	"generator": {"energy": 45.0, "alloy": 12.0, "data": 0.0},
	"extractor": {"energy": 65.0, "alloy": 15.0, "data": 0.0},
	"laboratory": {"energy": 90.0, "alloy": 32.0, "data": 0.0},
	"turret": {"energy": 135.0, "alloy": 40.0, "data": 10.0}
}

var energy: float = 90.0
var alloy: float = 40.0
var data: float = 0.0
var void_matter: float = 0.0
var instability: float = 0.0
var core_health: float = 100.0
var tech_level: int = 0
var waves_survived: int = 0
var lifetime_seconds: float = 0.0
var machines: Dictionary = {"generator": 0, "extractor": 0, "laboratory": 0, "turret": 0}

func tick(delta: float) -> void:
	if delta <= 0.0 or delta > 1.0:
		return
	lifetime_seconds += delta
	var multiplier: float = 1.0 + float(tech_level) * 0.32
	energy = clampf(energy + ((3.5 + 5.0 * float(machines["generator"])) * multiplier - 0.9 * float(machines["laboratory"])) * delta, 0.0, MAX_RESOURCES)
	alloy = clampf(alloy + (0.65 + 1.75 * float(machines["extractor"])) * multiplier * delta, 0.0, MAX_RESOURCES)
	data = clampf(data + (0.9 * float(machines["laboratory"])) * multiplier * delta, 0.0, MAX_RESOURCES)
	instability = maxf(0.0, instability - delta * 0.18)

func get_cost(kind: String) -> Dictionary:
	if not COSTS.has(kind):
		return {}
	var base: Dictionary = COSTS[kind]
	var owned: int = int(machines.get(kind, 0))
	var scale: float = pow(1.19, float(owned))
	return {"energy": ceil(float(base["energy"]) * scale), "alloy": ceil(float(base["alloy"]) * scale), "data": ceil(float(base["data"]) * scale)}

func can_build(kind: String) -> bool:
	if not COSTS.has(kind):
		return false
	var price: Dictionary = get_cost(kind)
	return energy >= float(price["energy"]) and alloy >= float(price["alloy"]) and data >= float(price["data"])

func buy_machine(kind: String) -> bool:
	if not can_build(kind):
		status.emit("Nicht genug Ressourcen fuer " + kind.to_upper() + ".")
		return false
	var price: Dictionary = get_cost(kind)
	energy -= float(price["energy"])
	alloy -= float(price["alloy"])
	data -= float(price["data"])
	machines[kind] = int(machines[kind]) + 1
	status.emit("MASCHINE ONLINE: " + kind.to_upper())
	return true

func research_cost() -> Dictionary:
	return {"energy": 140.0 * pow(2.0, float(tech_level)), "data": 12.0 + float(tech_level * tech_level) * 16.0}

func research() -> bool:
	if tech_level >= 5:
		status.emit("Forschungsstufe 5 erreicht - weitere Forschung folgt.")
		return false
	var price: Dictionary = research_cost()
	if energy < float(price["energy"]) or data < float(price["data"]):
		status.emit("Forschung benoetigt mehr Energie und Daten.")
		return false
	energy -= float(price["energy"])
	data -= float(price["data"])
	tech_level += 1
	status.emit("FORSCHUNG ERFOLGREICH: SEKTOR " + str(tech_level) + " // Effizienz +32%")
	return true

func experiment() -> bool:
	if energy < 100.0 or data < 12.0:
		status.emit("Experiment: 100 Energie und 12 Forschungsdaten erforderlich.")
		return false
	energy -= 100.0
	data -= 12.0
	instability = minf(100.0, instability + 20.0 + float(tech_level * 4))
	var roll: int = randi_range(0, 99)
	if roll < 42:
		void_matter = minf(MAX_RESOURCES, void_matter + 1.0 + float(tech_level))
		status.emit("ANOMALIE STABILISIERT: Seltene VOID-Materie gewonnen.")
	elif roll < 68:
		energy = minf(MAX_RESOURCES, energy + 220.0 * (1.0 + float(tech_level)))
		status.emit("REAKTOR-RESONANZ: Gewaltiger Energieschub!")
	else:
		status.emit("WARNUNG: DIMENSIONSBRUCH! FEINDE IM KOMPLEX!")
		breach_requested.emit(2 + tech_level)
	if instability >= 85.0:
		instability = 35.0
		core_health = maxf(1.0, core_health - 12.0)
		status.emit("KRITISCHE UEBERLASTUNG! Reaktor beschaedigt.")
		breach_requested.emit(3 + tech_level)
	return true

func damage_core(amount: float) -> void:
	core_health = maxf(0.0, core_health - maxf(0.0, amount))
	if core_health <= 0.0:
		core_health = 35.0
		energy = maxf(0.0, energy * 0.70)
		instability = 0.0
		status.emit("NOTABSCHALTUNG! Reaktor neu gestartet. 30% Energie verloren.")

func repair_core() -> bool:
	if energy < 65.0 or alloy < 18.0 or core_health >= 100.0:
		status.emit("Reparatur: 65 Energie + 18 Legierung erforderlich.")
		return false
	energy -= 65.0
	alloy -= 18.0
	core_health = minf(100.0, core_health + 35.0)
	status.emit("REAKTOR REPARIERT: +35 Integritaet.")
	return true

func to_save() -> Dictionary:
	return {
		"version": 1, "energy": energy, "alloy": alloy, "data": data, "void_matter": void_matter,
		"instability": instability, "core_health": core_health, "tech_level": tech_level,
		"waves_survived": waves_survived, "lifetime_seconds": lifetime_seconds
	}

func restore(saved: Dictionary) -> bool:
	if saved.get("version", -1) != 1:
		return false
	for key in ["energy", "alloy", "data", "void_matter", "instability", "core_health", "tech_level", "waves_survived", "lifetime_seconds"]:
		if not saved.has(key) or (typeof(saved[key]) != TYPE_FLOAT and typeof(saved[key]) != TYPE_INT):
			return false
		var number: float = float(saved[key])
		if is_nan(number) or is_inf(number) or number < 0.0 or number > MAX_RESOURCES:
			return false
	if int(saved["tech_level"]) > 5 or int(saved["waves_survived"]) > 1000000:
		return false
	energy = float(saved["energy"])
	alloy = float(saved["alloy"])
	data = float(saved["data"])
	void_matter = float(saved["void_matter"])
	instability = clampf(float(saved["instability"]), 0.0, 100.0)
	core_health = clampf(float(saved["core_health"]), 1.0, 100.0)
	tech_level = int(saved["tech_level"])
	waves_survived = int(saved["waves_survived"])
	lifetime_seconds = float(saved["lifetime_seconds"])
	return true
