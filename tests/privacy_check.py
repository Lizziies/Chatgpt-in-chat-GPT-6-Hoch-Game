"""Fail CI if new game code introduces dangerous operating-system or networking APIs.

This intentionally simple guardrail complements code review; it does not prove safety.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BANNED = (
    "HTTPRequest", "HTTPClient", "WebSocketPeer", "WebSocketMultiplayerPeer",
    "ENetMultiplayerPeer", "PacketPeerUDP", "TCPServer", "StreamPeerTCP",
    "OS.", "Engine.get_singleton(", "DisplayServer.clipboard_get(",
    "FileAccess.get_file_as_bytes(", "FileAccess.get_file_as_string(",
    "FileAccess.open_encrypted_with_pass(",
    "JavaScriptBridge", "DirAccess.open(", "DirAccess.copy(",
    "FileAccess.open_encrypted", "FileAccess.open_compressed",
    "ProjectSettings.load_resource_pack(", "ResourceLoader.load_threaded_request(",
)

def main() -> None:
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    if "file_logging/enable_file_logging=false" not in project:
        raise SystemExit("Privacy audit failed: game file logging must stay off.")
    for source in (ROOT / "scripts").rglob("*.gd"):
        code = source.read_text(encoding="utf-8")
        # No arbitrary filesystem, process execution, or network in gameplay scripts.
        for forbidden in BANNED:
            if forbidden in code:
                raise SystemExit(f"Privacy audit failed: {source.name} contains {forbidden!r}")
    main_script = (ROOT / "scripts/main.gd").read_text(encoding="utf-8")
    for source in (ROOT / "scripts").rglob("*.gd"):
        if source.name != "main.gd" and ("FileAccess." in source.read_text(encoding="utf-8") or "DirAccess." in source.read_text(encoding="utf-8")):
            raise SystemExit(f"Privacy audit failed: filesystem API in {source.name}")
    if "get_as_text()" not in main_script or "FileAccess.open(SAVE_PATH, FileAccess.WRITE)" not in main_script:
        raise SystemExit("Privacy audit failed: save/load implementation changed; manual review required.")
    if 'const SAVE_PATH := "user://void_save.json"' not in main_script:
        raise SystemExit("Privacy audit failed: fixed local save path changed.")
    print("PRIVACY_GUARDRAILS_PASS")

if __name__ == "__main__":
    main()
