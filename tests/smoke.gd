extends SceneTree
## Headless smoke tests for the economy and local-save validation.
const IndustryScript = preload("res://scripts/game_state.gd")

func _initialize() -> void:
	call_deferred("_execute")

func _execute() -> void:
	var economy: IndustryState = IndustryScript.new()
	root.add_child(economy)
	var previous_energy: float = economy.energy
	economy.tick(1.0)
	_check(economy.energy > previous_energy, "passive energy generation")
	_check(economy.get_cost("unknown").is_empty(), "unknown machine rejected")
	_check(not economy.can_build("turret"), "locked turret is not free")
	_check(economy.buy_machine("generator"), "starter generator affordable")
	_check(int(economy.machines["generator"]) == 1, "generator counter")
	var after_build: float = economy.energy
	economy.tick(1.0)
	_check(economy.energy > after_build + 5.0, "generator increases production")
	var stored: Dictionary = economy.to_save()
	_check(economy.restore(stored), "valid save accepted")
	var malformed: Dictionary = stored.duplicate()
	malformed["energy"] = "UNSAFE_STRING"
	_check(not economy.restore(malformed), "invalid save rejected")
	economy.energy = 1000.0
	economy.alloy = 500.0
	_check(economy.buy_machine("laboratory"), "laboratory purchase")
	economy.tick(1.0)
	_check(economy.data > 0.0, "laboratory generates research data")
	economy.data = 100.0
	_check(economy.research(), "research unlock")
	economy.data = 100.0
	_check(economy.experiment(), "experiment executes")
	print("SMOKE_TEST_PASS")
	quit(0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		push_error("SMOKE_TEST_FAIL: " + label)
		quit(1)
		# quit happens on the next loop iteration; abort other assertions
		assert(false, label)
