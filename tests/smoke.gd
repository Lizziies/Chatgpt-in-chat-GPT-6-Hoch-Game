extends SceneTree
## Headless regression suite. No filesystem writes or network.
const IndustryScript = preload("res://scripts/game_state.gd")

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
