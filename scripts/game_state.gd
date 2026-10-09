extends Node
## Stand-alone economy: no OS access, network, clock reads, or tracking.
class_name IndustryState

signal status(message: String)
signal breach_requested(amount: int)

const MAX_RESOURCES: float = 1.0e12
const MAX_LEVEL: int = 7
const MACHINES: Array[String] = ["generator", "extractor", "laboratory", "turret", "capacitor", "stabilizer"]
const COSTS := {
	"generator": {"energy": 45.0, "alloy": 12.0, "data": 0.0},
	"extractor": {"energy": 65.0, "alloy": 15.0, "data": 0.0},
	"laboratory": {"energy": 90.0, "alloy": 32.0, "data": 0.0},
	"turret": {"energy": 135.0, "alloy": 40.0, "data": 10.0},
	"capacitor": {"energy": 220.0, "alloy": 62.0, "data": 14.0},
	"stabilizer": {"energy": 420.0, "alloy": 110.0, "data": 42.0}
}
const UNLOCKS := {
	"generator": 0, "extractor": 0, "laboratory": 0,
	"turret": 1, "capacitor": 1, "stabilizer": 2
}
const TECH_NAMES := [
	"Grundversorgung", "Sicherheitsprotokolle", "Anomalie-Kontrolle",
	"Quantenlogistik", "Nullpunkt-Forschung", "Reaktorsynthese",
	"Automatisierte Forschung", "Singularitaets-Architektur"
]
const DIRECTIVES := [
	{"title": "Erstes Licht", "hint": "Errichte 1 Generator", "type": "machine", "kind": "generator", "target": 1, "energy": 85.0, "alloy": 15.0, "data": 0.0, "void": 0.0},
	{"title": "Stahl und Staub", "hint": "Errichte 1 Extraktor", "type": "machine", "kind": "extractor", "target": 1, "energy": 120.0, "alloy": 25.0, "data": 0.0, "void": 0.0},
	{"title": "Forschung erwacht", "hint": "Errichte 1 Labor", "type": "machine", "kind": "laboratory", "target": 1, "energy": 165.0, "alloy": 30.0, "data": 0.0, "void": 0.0},
	{"title": "Neue Protokolle", "hint": "Erreiche Forschungsstufe 1", "type": "tech", "target": 1, "energy": 150.0, "alloy": 55.0, "data": 20.0, "void": 0.0},
	{"title": "Jenseits der Grenze", "hint": "Sammle 1 VOID-Materie", "type": "void", "target": 1, "energy": 300.0, "alloy": 80.0, "data": 25.0, "void": 0.0},
	{"title": "Dauerbetrieb", "hint": "Errichte insgesamt 5 Maschinen", "type": "total", "target": 5, "energy": 430.0, "alloy": 110.0, "data": 32.0, "void": 0.0},
	{"title": "Anomalie-Abwehr", "hint": "Besiege 5 Kreaturen", "type": "kills", "target": 5, "energy": 360.0, "alloy": 100.0, "data": 40.0, "void": 2.0},
	{"title": "Singularitaetswerk", "hint": "Erreiche Forschungsstufe 4", "type": "tech", "target": 4, "energy": 1800.0, "alloy": 700.0, "data": 250.0, "void": 3.0}
]

var energy: float = 90.0
var alloy: float = 40.0
var data: float = 0.0
var void_matter: float = 0.0
var instability: float = 0.0
var core_health: float = 100.0
var tech_level: int = 0
var waves_survived: int = 0
var lifetime_seconds: float = 0.0
var charge: float = 0.0
var overdrive_seconds: float = 0.0
var directive_index: int = 0
var prestige_cores: int = 0
var power_grid_enabled: bool = false
var powered_machines: Dictionary = {}
var synergies: Dictionary = {"lab_extractor": 0, "generator_capacitor": 0, "turret_stabilizer": 0}
var branches: Dictionary = {"energy": 0, "industry": 0, "containment": 0}
const BRANCHES := ["energy", "industry", "containment"]
const BRANCH_MAX_LEVEL: int = 3
var machines: Dictionary = {
	"generator": 0, "extractor": 0, "laboratory": 0,
	"turret": 0, "capacitor": 0, "stabilizer": 0
}

func machine_count(kind: String) -> int:
	if not MACHINES.has(kind):
		return 0
	if power_grid_enabled:
		return int(powered_machines.get(kind, 0))
	return int(machines.get(kind, 0))

func configure_power_grid(counts: Dictionary, adjacency: Dictionary = {}) -> void:
	power_grid_enabled = true
	for synergy in synergies:
		synergies[synergy] = mini(32, maxi(0, int(adjacency.get(synergy, 0))))
	powered_machines.clear()
	for kind in MACHINES:
		powered_machines[kind] = mini(int(machines[kind]), maxi(0, int(counts.get(kind, 0))))

func tick(delta: float) -> void:
	if delta <= 0.0 or delta > 1.0:
		return
	lifetime_seconds += delta
	var multiplier: float = get_multiplier()
	energy = clampf(energy + ((3.5 + 5.0 * float(machine_count("generator"))) * multiplier - 0.9 * float(machine_count("laboratory"))) * delta, 0.0, MAX_RESOURCES)
	alloy = clampf(alloy + (0.65 + 1.75 * float(machine_count("extractor"))) * multiplier * (1.0 + float(branches["industry"]) * 0.18) * delta, 0.0, MAX_RESOURCES)
	data = clampf(data + 0.9 * float(machine_count("laboratory")) * multiplier * (1.0 + float(branches["industry"]) * 0.18) * (1.0 + float(synergies["lab_extractor"]) * 0.22) * delta, 0.0, MAX_RESOURCES)
	charge = clampf(charge + 1.9 * float(machine_count("capacitor")) * (1.0 + float(synergies["generator_capacitor"]) * 0.25) * delta, 0.0, 100.0)
	var stabilizers: int = machine_count("stabilizer")
	var base_cooling: float = 0.18
	if stabilizers > 0 and energy > 2.0:
		energy = maxf(0.0, energy - float(stabilizers) * 1.5 * delta)
		base_cooling += 0.72 * float(stabilizers)
		core_health = minf(100.0, core_health + float(stabilizers) * 0.48 * delta)
	instability = maxf(0.0, instability - delta * (base_cooling + float(branches["containment"]) * 0.35))
	overdrive_seconds = maxf(0.0, overdrive_seconds - delta)

func get_multiplier() -> float:
	var multiplier: float = (1.0 + float(tech_level) * 0.32) * (1.0 + float(prestige_cores) * 0.15) * (1.0 + float(branches["energy"]) * 0.25)
	if overdrive_seconds > 0.0:
		multiplier *= 3.0
	return multiplier

func get_production() -> Dictionary:
	var mult: float = get_multiplier()
	return {
		"energy": (3.5 + 5.0 * float(machine_count("generator"))) * mult - 0.9 * float(machine_count("laboratory")) - 1.5 * float(machine_count("stabilizer")),
		"alloy": (0.65 + 1.75 * float(machine_count("extractor"))) * mult * (1.0 + float(branches["industry"]) * 0.18),
		"data": 0.9 * float(machine_count("laboratory")) * mult * (1.0 + float(branches["industry"]) * 0.18) * (1.0 + float(synergies["lab_extractor"]) * 0.22)
	}

func is_unlocked(kind: String) -> bool:
	return MACHINES.has(kind) and tech_level >= int(UNLOCKS[kind])

func get_cost(kind: String) -> Dictionary:
	if not COSTS.has(kind):
		return {}
	var base: Dictionary = COSTS[kind]
	var owned: int = int(machines.get(kind, 0))
	var scale: float = pow(1.19, float(owned))
	return {
		"energy": ceil(float(base["energy"]) * scale),
		"alloy": ceil(float(base["alloy"]) * scale),
		"data": ceil(float(base["data"]) * scale)
	}

func can_build(kind: String) -> bool:
	if not is_unlocked(kind):
		return false
	var price: Dictionary = get_cost(kind)
	return energy >= float(price["energy"]) and alloy >= float(price["alloy"]) and data >= float(price["data"])

func buy_machine(kind: String) -> bool:
	if not is_unlocked(kind):
		status.emit("TECHNOLOGIE GESPERRT: Erst Forschung durchfuehren.")
		return false
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
	return {
		"energy": 140.0 * pow(1.85, float(tech_level)),
		"data": 12.0 + float(tech_level * tech_level) * 13.0
	}

func next_technology() -> String:
	return TECH_NAMES[mini(tech_level + 1, MAX_LEVEL)]

func research() -> bool:
	if tech_level >= MAX_LEVEL:
		status.emit("Maximale Forschungsstufe erreicht.")
		return false
	var price: Dictionary = research_cost()
	if energy < float(price["energy"]) or data < float(price["data"]):
		status.emit("Forschung benoetigt mehr Energie und Forschungsdaten.")
		return false
	energy -= float(price["energy"])
	data -= float(price["data"])
	tech_level += 1
	status.emit("TECHNOLOGIE ENTDECKT: " + TECH_NAMES[tech_level] + " // +32% Produktion!")
	return true

func branch_cost(kind: String) -> Dictionary:
	if not BRANCHES.has(kind):
		return {}
	var level: int = int(branches[kind])
	return {"energy": 400.0 * pow(2.1, float(level)), "data": 55.0 * pow(2.0, float(level)), "alloy": 80.0 * pow(1.8, float(level)), "void": float(level)}

func upgrade_branch(kind: String) -> bool:
	if not BRANCHES.has(kind) or tech_level < 2:
		status.emit("SPEZIALISIERUNG: Erst Forschungsstufe 2 erreichen.")
		return false
	if int(branches[kind]) >= BRANCH_MAX_LEVEL:
		status.emit("Dieser Forschungszweig ist bereits vollstaendig.")
		return false
	var cost: Dictionary = branch_cost(kind)
	if energy < float(cost["energy"]) or data < float(cost["data"]) or alloy < float(cost["alloy"]) or void_matter < float(cost["void"]):
		status.emit("ZU WENIG RESSOURCEN: Spezialisierung " + kind.to_upper())
		return false
	energy -= float(cost["energy"])
	data -= float(cost["data"])
	alloy -= float(cost["alloy"])
	void_matter -= float(cost["void"])
	branches[kind] = int(branches[kind]) + 1
	status.emit("SPEZIALISIERUNG ERFORSCHT: " + kind.to_upper() + " STUFE " + str(branches[kind]))
	return true

func authorize_containment_trial() -> bool:
	if tech_level < 4 or energy < 850.0 or data < 190.0:
		status.emit("ELITE-TEST: Stufe 4, 850 Energie und 190 Daten erforderlich.")
		return false
	energy -= 850.0
	data -= 190.0
	instability = minf(100.0, instability + 18.0)
	status.emit("EINSPERRUNGS-PROTOKOLL: Elite-Anomalie freigesetzt!")
	return true

func prestige_eligible() -> bool:
	return tech_level >= 5 and void_matter >= 8.0 and data >= 800.0 and energy >= 3500.0

func initiate_prestige() -> bool:
	if not prestige_eligible():
		status.emit("SINGULARITAET: 5 Forschung, 8 VOID, 800 Daten, 3500 Energie erforderlich.")
		return false
	prestige_cores = mini(prestige_cores + 1 + (tech_level - 5), 100)
	var persistent: int = prestige_cores
	energy = 90.0 + float(persistent * 12)
	alloy = 40.0 + float(persistent * 4)
	data = 0.0
	void_matter = 0.0
	instability = 0.0
	core_health = 100.0
	tech_level = 0
	waves_survived = 0
	charge = 0.0
	overdrive_seconds = 0.0
	directive_index = 0
	for kind in MACHINES:
		machines[kind] = 0
		powered_machines[kind] = 0
	for kind in BRANCHES:
		branches[kind] = 0
	status.emit("SINGULARITAET ABGESCHLOSSEN: %d bleibende Kerne, +%d%% Produktion." % [persistent, persistent * 15])
	return true

func pulse() -> bool:
	if charge < 100.0:
		status.emit("NETZ-PULS: Kondensatoren muessen erst 100 Ladung sammeln.")
		return false
	charge = 0.0
	overdrive_seconds = 25.0
	status.emit("NETZ-PULS AKTIV: 25 Sekunden dreifache Produktion!")
	return true

func experiment(safe_protocol: bool = false) -> bool:
	var energy_cost: float = 220.0 if safe_protocol else 100.0
	var data_cost: float = 25.0 if safe_protocol else 12.0
	if energy < energy_cost or data < data_cost:
		status.emit("Experiment: %d Energie und %d Daten erforderlich." % [int(energy_cost), int(data_cost)])
		return false
	energy -= energy_cost
	data -= data_cost
	instability = minf(100.0, instability + (8.0 if safe_protocol else 21.0) + float(tech_level * 3))
	var roll: int = randi_range(0, 99)
	if roll < (58 if safe_protocol else 42):
		void_matter = minf(MAX_RESOURCES, void_matter + 1.0 + float(tech_level))
		status.emit("ANOMALIE STABILISIERT: VOID-Materie gewonnen!")
	elif roll < (91 if safe_protocol else 68):
		energy = minf(MAX_RESOURCES, energy + 250.0 * (1.0 + float(tech_level)))
		status.emit("REAKTOR-RESONANZ: Gewaltiger Energieschub!")
	else:
		status.emit("ALARM! DIMENSIONSBRUCH: Feinde im Komplex!")
		breach_requested.emit(2 + tech_level)
	if instability >= 85.0:
		instability = 35.0
		damage_core(12.0)
		status.emit("KRITISCHE UEBERLASTUNG! Reaktor beschaedigt!")
		breach_requested.emit(3 + tech_level)
	return true

func damage_core(amount: float) -> void:
	core_health = maxf(0.0, core_health - maxf(0.0, amount))
	if core_health <= 0.0:
		core_health = 35.0
		energy = maxf(0.0, energy * 0.70)
		instability = 0.0
		status.emit("NOTABSCHALTUNG: 30% Energie verloren. Reaktor repariert sich minimal.")

func repair_core() -> bool:
	if energy < 65.0 or alloy < 18.0 or core_health >= 100.0:
		status.emit("Reparatur: 65 Energie + 18 Legierung erforderlich.")
		return false
	energy -= 65.0
	alloy -= 18.0
	core_health = minf(100.0, core_health + 35.0)
	status.emit("REAKTOR REPARIERT: +35 Integritaet.")
	return true

func current_directive() -> Dictionary:
	if directive_index >= DIRECTIVES.size():
		return {}
	return DIRECTIVES[directive_index]

func directive_progress() -> int:
	var goal: Dictionary = current_directive()
	if goal.is_empty():
		return 0
	match str(goal["type"]):
		"machine": return int(machines.get(str(goal["kind"]), 0))
		"tech": return tech_level
		"void": return int(void_matter)
		"total":
			var result: int = 0
			for kind in MACHINES:
				result += int(machines[kind])
			return result
		"kills": return waves_survived
	return 0

func claim_directive() -> bool:
	var goal: Dictionary = current_directive()
	if goal.is_empty():
		status.emit("Alle aktuellen Auftraege abgeschlossen.")
		return false
	if directive_progress() < int(goal["target"]):
		status.emit("Auftrag ist noch nicht abgeschlossen.")
		return false
	energy = minf(MAX_RESOURCES, energy + float(goal["energy"]))
	alloy = minf(MAX_RESOURCES, alloy + float(goal["alloy"]))
	data = minf(MAX_RESOURCES, data + float(goal["data"]))
	void_matter = minf(MAX_RESOURCES, void_matter + float(goal["void"]))
	directive_index += 1
	status.emit("AUFTRAG ABGESCHLOSSEN: " + str(goal["title"]) + " // BONUS ERHALTEN!")
	return true

func to_save() -> Dictionary:
	return {
		"version": 3, "energy": energy, "alloy": alloy, "data": data,
		"void_matter": void_matter, "instability": instability, "core_health": core_health,
		"tech_level": tech_level, "waves_survived": waves_survived,
		"lifetime_seconds": lifetime_seconds, "charge": charge,
		"overdrive_seconds": overdrive_seconds, "directive_index": directive_index,
		"prestige_cores": prestige_cores, "branches": branches.duplicate(true)
	}

func restore(saved: Dictionary) -> bool:
	var version: int = int(saved.get("version", -1))
	if version != 1 and version != 2 and version != 3:
		return false
	var keys: Array[String] = ["energy", "alloy", "data", "void_matter",
		"instability", "core_health", "tech_level", "waves_survived", "lifetime_seconds"]
	if version >= 2:
		keys.append_array(["charge", "overdrive_seconds", "directive_index"])
	for key in keys:
		if not saved.has(key) or (typeof(saved[key]) != TYPE_FLOAT and typeof(saved[key]) != TYPE_INT):
			return false
		var value: float = float(saved[key])
		if is_nan(value) or is_inf(value) or value < 0.0 or value > MAX_RESOURCES:
			return false
	if int(saved["tech_level"]) > MAX_LEVEL or int(saved["waves_survived"]) > 1000000:
		return false
	if version >= 2 and (int(saved["directive_index"]) > DIRECTIVES.size()
			or float(saved["charge"]) > 100.0 or float(saved["overdrive_seconds"]) > 25.0):
		return false
	if version >= 3:
		if not saved.has("prestige_cores") or (typeof(saved["prestige_cores"]) != TYPE_INT and typeof(saved["prestige_cores"]) != TYPE_FLOAT):
			return false
		var core_count: float = float(saved["prestige_cores"])
		if is_nan(core_count) or is_inf(core_count) or core_count != floor(core_count) or core_count < 0.0 or core_count > 100.0:
			return false
		var saved_branches: Variant = saved.get("branches", {})
		if typeof(saved_branches) != TYPE_DICTIONARY:
			return false
		for kind in BRANCHES:
			if not saved_branches.has(kind) or (typeof(saved_branches[kind]) != TYPE_INT and typeof(saved_branches[kind]) != TYPE_FLOAT):
				return false
			var branch_level: float = float(saved_branches[kind])
			if is_nan(branch_level) or is_inf(branch_level) or branch_level != floor(branch_level) or branch_level < 0.0 or branch_level > float(BRANCH_MAX_LEVEL):
				return false
			if int(saved_branches[kind]) > 0 and int(saved["tech_level"]) < 2:
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
	charge = float(saved.get("charge", 0.0))
	overdrive_seconds = float(saved.get("overdrive_seconds", 0.0))
	directive_index = int(saved.get("directive_index", 0))
	prestige_cores = int(saved.get("prestige_cores", 0))
	var restored_branches: Dictionary = saved.get("branches", {})
	for kind in BRANCHES:
		branches[kind] = int(restored_branches.get(kind, 0))
	return true
