# VOID INDUSTRIES — Game Architecture

## Current development level
Pre-alpha 0.3 (Godot 4.4.1, GDScript, GL Compatibility). Runtime-generated procedural 3D; no binary mods, injectors, online APIs or telemetry.

## Modules
- `scripts/game_state.gd` — pure game economy, crafting costs, upgrades, risk, quests, prestige, validation of saves.
- `scripts/power_grid.gd` — graph-based power routing and machine synergy calculation. Does not access the operating system.
- `scripts/main.gd` — 3D environment, construction pads, power visuals, game orchestration, fights, manual saves.
- `scripts/player.gd` — local player controller, orbit and tactical camera, firing.
- `scripts/threat.gd` — enemies and elite encounter behavior.
- `scripts/hud.gd` — resource views, goals, technology summaries, operator handbook.
- `tests/smoke.gd` — headless gameplay regression checks.
- `tests/privacy_check.py` — CI source guardrails; not a substitute for security assessment.
- `.github/workflows/windows-build.yml` — read-only CI permission, import, tests, headless startup and Windows export.

## Save boundary
Saves use the *single* app-specific Godot path `user://void_save.json`, after explicit P/O input. There are no runtime connections to external services. No access to other game saves, accounts, profiles, browsers or arbitrary filesystem trees is required by our game code.

## Game loop
Player builds machine -> payment verified -> construct procedural mesh -> recompute energy connectivity and combos -> yield from connected machines only -> research, risk and missions -> periodic or manual combat -> optional double-confirmed Prestige resetting the facility while granting a lasting bonus.

## Release criteria (not yet achieved)
- Visual Windows 11 playtest, validated input, frame pacing and accessibility.
- Proper realistic models/textures, legally auditable original/compatible assets and audio.
- Interactive UI with mouse/controller access and localization.
- End-game depth, multiple map sectors and narrative beats.
- Dependency and source reviews, privacy and security verification, signed releases.
- Packaging/licensing and Steam compliance.

**No claims of production-readiness or total security are made for the alpha.**
