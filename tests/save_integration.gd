extends SceneTree
## E2E save/load test; refuses to overwrite any preexisting game save.
const MainScene = preload("res://scenes/main.tscn")
const SAVE_PATH := "user://void_save.json"
const TEMP_PATH := "user://void_save.pending"
var failures: int = 0

func _initialize() -> void:
	call_deferred("_execute")

func _execute() -> void:
	if FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(TEMP_PATH):
		push_error("SAVE_INTEGRATION_FAIL: existing user save detected; refusing to overwrite")
		quit(1)
		return
	var game: Variant = MainScene.instantiate()
	root.add_child(game)
	game.state.energy = 734.0
	game.state.data = 612.0
	game.state.tech_level = 2
	game.state.branches["energy"] = 1
	game.state.prestige_cores = 3
	game.pads.append({"position": Vector3(7, 0, 7), "kind": "", "machine_node": null})
	game._build_machine(game.pads.size() - 1, "generator")
	game.state.machines["generator"] = 1
	game.belt_cells.append(Vector2i(4, 2))
	game._save_game()
	_check(FileAccess.file_exists(SAVE_PATH), "version 5 save file created")
	_check(not FileAccess.file_exists(TEMP_PATH), "save staging file renamed")
	game.state.energy = 4.0
	game.state.data = 0.0
	game.state.tech_level = 0
	game.state.branches["energy"] = 0
	game.state.prestige_cores = 0
	game._clear_factory()
	game.belt_cells.clear()
	game._load_game()
	if int(game.state.tech_level) != 2:
		print("SAVE_DIAGNOSTIC: " + game.hud.status_label.text)
	_check(is_equal_approx(float(game.state.energy), 734.0), "resources restored")
	_check(is_equal_approx(float(game.state.data), 612.0), "data restored")
	_check(int(game.state.tech_level) == 2, "research restored")
	_check(int(game.state.branches["energy"]) == 1, "branch restored")
	_check(int(game.state.prestige_cores) == 3, "permanent cores restored")
	_check(game.pads.size() == 1, "free placed machine restored")
	_check(game.belt_cells.size() == 1, "conveyor tile restored")
	# Tests execute on isolated cloud runner, but cleanup stays application-local.
	var cleanup: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	_check(cleanup == OK, "temporary test save cleaned")
	game.queue_free()
	if failures == 0:
		print("SAVE_INTEGRATION_PASS")
		quit(0)
	else:
		push_error("SAVE_INTEGRATION_FAIL: %d checks failed" % failures)
		quit(1)

func _check(valid: bool, message: String) -> void:
	if not valid:
		failures += 1
		push_error("SAVE_INTEGRATION_FAIL: " + message)
