# Security & Privacy

VOID INDUSTRIES is an offline, open-source game. Privacy is a design requirement.

## Intended behavior
- No online accounts, network traffic, ads, cloud sync or telemetry are implemented.
- No access to user profile details, browser data, Windows credentials or other games.
- Save/load requires a keypress and uses only Godot's `user://void_save.json` (app-specific data directory).
- Save input is size limited and schema validated; unknown save versions are refused. Versions 1 and 2 are explicitly migrated into version 3.
- The gameplay audit rejects network clients, process/OS inspection, and filesystem APIs outside the narrowly-scoped save/load module.
- Saves are manual and staged in `user://void_save.pending`, then renamed to the sole canonical `user://void_save.json` only on a successful write. No arbitrary filesystem path is accepted.
- Save backups and recovery are still planned for a later version. Filesystem errors, power loss, antivirus behavior or hardware issues can never be fully ruled out.
- Our source has no third-party game dependencies or plugins.
- GitHub Actions builds from the public code with pinned Godot 4.4.1 and read-only GitHub permissions.

## Trust boundaries
The operating system, GPU drivers, GitHub and potential future distribution platforms can
operate independently of the game. Godot creates its own engine behavior; audit its upstream
source and releases if you require a stricter assurance level.

## Limits
Security checks and code review reduce risk but do not prove a game is completely secure.
No security claims should be read as a formal audit or guarantee.

## Reports
Please use GitHub's private vulnerability reporting feature, when enabled, or contact the
project owner privately. Don't publish security-sensitive exploit instructions or personal
data in a public issue.

## Supported versions
Only the latest source at `main` and recent CI builds are supported during pre-alpha.
