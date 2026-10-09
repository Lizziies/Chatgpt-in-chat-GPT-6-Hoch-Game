extends SceneTree
## Headless regression suite. No filesystem writes or network.
const IndustryScript = preload("res://scripts/game_state.gd")
const GridScript = preload("res://scripts/power_grid.gd")

var failures: int = 0
var assertions: int = 0

func _initialize() -> void:
	call_deferred("_execute")

func _execute() -> void:
	var economy: IndustryState = IndustryScript.new()
	root.add_child(economy)
	var start_energy: float = economy.energy
	economy.tick(1.0)
	_check(economy.energy > start_energy, "passive generation")
	_check(economy.get_cost("invalid").is_empty(), "reject unknown machine")
	_check(not economy.can_build("turret"), "turrets technology-locked")
	_check(not economy.buy_machine("stabilizer"), "locked stabilizer refused")
	_check(economy.buy_machine("generator"), "starter generator affordable")
	_check(int(economy.machines["generator"]) == 1, "machine count")
	_check(economy.directive_progress() == 1, "first directive progression")
	var before_claim: float = economy.energy
	_check(economy.claim_directive(), "directive reward")
	_check(economy.energy > before_claim, "directive awards resources")
	_check(economy.directive_index == 1, "advance to second directive")
	_check(not economy.claim_directive(), "cannot double claim objective")
	var before_tick: float = economy.energy
	economy.tick(1.0)
	_check(economy.energy > before_tick + 5.0, "generator multiplies production")

	# Research and unlock gates.
	economy.energy = 5000.0
	economy.alloy = 1000.0
	economy.data = 1000.0
	_check(economy.buy_machine("laboratory"), "laboratory affordable")
	var before_data: float = economy.data
	economy.tick(1.0)
	_check(economy.data > before_data, "laboratory generates data")
	_check(economy.research(), "first research")
	_check(economy.tech_level == 1, "research level increment")
	_check(economy.is_unlocked("turret"), "turret unlocked")
	_check(economy.is_unlocked("capacitor"), "capacitor unlocked")
	_check(not economy.is_unlocked("stabilizer"), "stabilizer still locked")
	_check(economy.buy_machine("capacitor"), "capacitor purchase")
	economy.tick(1.0)
	_check(economy.charge > 0.0, "capacitor charges")
	_check(not economy.pulse(), "premature pulse rejected")
	economy.charge = 100.0
	_check(economy.pulse(), "overdrive activated")
	_check(economy.overdrive_seconds == 25.0, "overdrive duration")
	_check(economy.charge == 0.0, "overdrive drains charge")
	_check(economy.get_multiplier() > 3.0, "overdrive multiplies production")
	_check(economy.research(), "second research")
	_check(economy.is_unlocked("stabilizer"), "stabilizer unlocked")
	_check(economy.buy_machine("stabilizer"), "stabilizer purchase")
	economy.instability = 40.0
	economy.core_health = 60.0
	economy.tick(1.0)
	_check(economy.instability < 40.0, "stabilizer cools reactor")
	_check(economy.core_health > 60.0, "stabilizer repairs reactor")

	# Experiment modes consume resources and produce bounded results.
	economy.energy = 5000.0
	economy.data = 1000.0
	_check(economy.experiment(true), "safer experiment executes")
	_check(economy.experiment(false), "risky experiment executes")
	_check(economy.instability <= 100.0, "instability clamped")

	# Save migration and malicious save rejection.
	var saved_v2: Dictionary = economy.to_save()
	_check(economy.restore(saved_v2), "v2 save loads")
	var saved_v1: Dictionary = saved_v2.duplicate(true)
	saved_v1["version"] = 1
	saved_v1.erase("charge")
	saved_v1.erase("overdrive_seconds")
	saved_v1.erase("directive_index")
	_check(economy.restore(saved_v1), "v1 legacy save loads")
	_check(economy.charge == 0.0, "legacy load resets capacitor charge")
	var invalid: Dictionary = saved_v2.duplicate(true)
	invalid["energy"] = "unsafe"
	_check(not economy.restore(invalid), "string amount rejected")
	invalid = saved_v2.duplicate(true)
	invalid["charge"] = 101.0
	_check(not economy.restore(invalid), "overcharge save rejected")
	invalid = saved_v2.duplicate(true)
	invalid["directive_index"] = 100
	_check(not economy.restore(invalid), "bogus mission index rejected")
	invalid = saved_v2.duplicate(true)
	invalid["energy"] = INF
	_check(not economy.restore(invalid), "non-finite resource rejected")

	# Power grid graph: no remote production without a path to the reactor.
	var sample: Array[Dictionary] = [
		{"kind": "generator", "position": Vector3(4, 0, 0)},
		{"kind": "laboratory", "position": Vector3(17, 0, 0)},
		{"kind": "extractor", "position": Vector3(12, 0, 0)},
		{"kind": "turret", "position": Vector3(30, 0, 0)}
	]
	var solved: Dictionary = GridScript.solve(sample)
	_check(int(solved["connected"]) == 3, "grid BFS connects relay machines")
	_check(int(solved["counts"]["turret"]) == 0, "distant turret unpowered")
	_check(int(solved["counts"]["laboratory"]) == 1, "relay powers remote laboratory")
	_check(solved["links"].size() == 3, "grid displays three cables")
	var no_relay: Array[Dictionary] = [
		{"kind": "generator", "position": Vector3(4, 0, 0)},
		{"kind": "laboratory", "position": Vector3(17, 0, 0)}
	]
	var isolated: Dictionary = GridScript.solve(no_relay)
	_check(int(isolated["connected"]) == 1, "isolated machine not connected")
	var linked: IndustryState = IndustryScript.new()
	root.add_child(linked)
	linked.machines["generator"] = 2
	linked.machines["laboratory"] = 1
	linked.configure_power_grid({"generator": 1, "laboratory": 0})
	_check(linked.machine_count("generator") == 1, "only powered generators produce")
	_check(linked.machine_count("laboratory") == 0, "disconnected laboratory yields no data")
	linked.tick(1.0)
	_check(linked.data == 0.0, "disconnected machine no output")
	linked.configure_power_grid({"generator": 2, "laboratory": 1})
	linked.tick(1.0)
	_check(linked.data > 0.0, "reconnected machine resumes output")

	# Adjacency combos strengthen production, stored energy and defense.
	var combos: Array[Dictionary] = [
		{"kind": "generator", "position": Vector3(3, 0, 0)},
		{"kind": "capacitor", "position": Vector3(5, 0, 0)},
		{"kind": "extractor", "position": Vector3(0, 0, 4)},
		{"kind": "laboratory", "position": Vector3(0, 0, 7)},
		{"kind": "turret", "position": Vector3(-5, 0, 0)},
		{"kind": "stabilizer", "position": Vector3(-7, 0, 0)}
	]
	var built_combos: Dictionary = GridScript.solve(combos)
	_check(int(built_combos["synergies"]["generator_capacitor"]) > 0, "generator and capacitor combo")
	_check(int(built_combos["synergies"]["lab_extractor"]) > 0, "extractor and laboratory combo")
	_check(int(built_combos["synergies"]["turret_stabilizer"]) > 0, "defensive tower and stabilizer combo")
	linked.machines["capacitor"] = 1
	linked.configure_power_grid(built_combos["counts"], built_combos["synergies"])
	_check(int(linked.synergies["lab_extractor"]) > 0, "grid synergy copied into economy")
	var old_charge: float = linked.charge
	linked.tick(1.0)
	_check(linked.charge > old_charge + 1.9, "capacitor adjacency accelerates charge")

	# Research specializations and long-term prestige after completing the tech tree.
	var specialists: IndustryState = IndustryScript.new()
	root.add_child(specialists)
	_check(not specialists.upgrade_branch("energy"), "research gated before level two")
	specialists.tech_level = 2
	specialists.energy = 10000.0
	specialists.data = 10000.0
	specialists.alloy = 10000.0
	specialists.void_matter = 50.0
	_check(specialists.upgrade_branch("energy"), "energy research branch")
	_check(specialists.upgrade_branch("industry"), "industrial research branch")
	_check(specialists.upgrade_branch("containment"), "containment research branch")
	_check(specialists.get_multiplier() > 1.8, "energy branch improves output")
	_check(int(specialists.branches["energy"]) == 1, "branch levels persist in memory")
	var valid_v3: Dictionary = specialists.to_save()
	_check(specialists.restore(valid_v3), "v3 save round-trip")
	var tampered: Dictionary = valid_v3.duplicate(true)
	tampered["branches"]["energy"] = 999
	_check(not specialists.restore(tampered), "out of-range research save rejected")
	tampered = valid_v3.duplicate(true)
	tampered["prestige_cores"] = 999
	_check(not specialists.restore(tampered), "out of-range permanent core count rejected")
	specialists.tech_level = 5
	specialists.energy = 6000.0
	specialists.data = 1800.0
	specialists.void_matter = 10.0
	specialists.machines["generator"] = 5
	_check(specialists.prestige_eligible(), "tech threshold allows prestige")
	var old_data: float = specialists.data
	_check(specialists.authorize_containment_trial(), "voluntary elite test authorized")
	_check(specialists.data < old_data, "trial consumes science resources")
	_check(specialists.initiate_prestige(), "singularity resets temporary systems")
	_check(specialists.tech_level == 0, "prestige resets tech")
	_check(int(specialists.machines["generator"]) == 0, "prestige resets machines")
	_check(specialists.prestige_cores == 1, "prestige grants permanent core")
	_check(specialists.get_multiplier() >= 1.15, "permanent core grants 15 percent production")
	_check(int(specialists.branches["energy"]) == 0, "prestige resets branch investment")
	_check(not specialists.prestige_eligible(), "cannot instantly repeat prestige")
	_check(not specialists.initiate_prestige(), "prestige gate rejects premature reset")
	var migrated_v2: Dictionary = specialists.to_save()
	migrated_v2["version"] = 2
	migrated_v2.erase("prestige_cores")
	migrated_v2.erase("branches")
	_check(specialists.restore(migrated_v2), "v2 save migrates into v3")
	_check(specialists.prestige_cores == 0, "legacy saves do not claim permanent cores")

	if failures == 0:
		print("SMOKE_TEST_PASS: %d assertions" % assertions)
	else:
		push_error("SMOKE_TEST_FAIL: %d / %d assertions failed" % [failures, assertions])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("SMOKE_TEST_FAIL: " + label)
