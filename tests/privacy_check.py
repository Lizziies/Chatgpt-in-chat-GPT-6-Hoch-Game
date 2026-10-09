"""Fail CI if new game code introduces dangerous operating-system or networking APIs.

This intentionally simple guardrail complements code review; it does not prove safety.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BANNED = (
    "HTTPRequest", "HTTPClient", "WebSocketPeer", "WebSocketMultiplayerPeer",
    "ENetMultiplayerPeer", "PacketPeerUDP", "TCPServer", "StreamPeerTCP",
    "OS.execute(", "OS.create_process(", "OS.shell_open(",
    "JavaScriptBridge", "DirAccess.open(", "DirAccess.copy(",
    "FileAccess.open_encrypted", "FileAccess.open_compressed",
    "ProjectSettings.load_resource_pack(", "ResourceLoader.load_threaded_request(",
)

def main() -> None:
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    if "file_logging/enable_file_logging=false" not in project:
        raise SystemExit("Privacy audit failed: game file logging must stay off.")
    for source in (ROOT / "scripts").glob("*.gd"):
        code = source.read_text(encoding="utf-8")
        # No arbitrary filesystem, process execution, or network in gameplay scripts.
        for forbidden in BANNED:
            if forbidden in code:
                raise SystemExit(f"Privacy audit failed: {source.name} contains {forbidden!r}")
    main_script = (ROOT / "scripts/main.gd").read_text(encoding="utf-8")
    if 'const SAVE_PATH := "user://void_save.json"' not in main_script:
        raise SystemExit("Privacy audit failed: fixed local save path changed.")
    print("PRIVACY_GUARDRAILS_PASS")

if __name__ == "__main__":
    main()
