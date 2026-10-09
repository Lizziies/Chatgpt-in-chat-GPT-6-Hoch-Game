# Release Candidate Readiness — VOID INDUSTRIES

Current position: **PRE-ALPHA / NOT YET READY FOR PUBLIC STEAM LAUNCH**.

A successful CI export does not prove enjoyable gameplay, real-world Windows compatibility, performance, security or distribution readiness.

## Must-pass automated checks
- [x] Godot project import and GDScript parse in clean CI
- [x] Economy, unlock and prestige regression tests
- [x] Menu and local-save integration tests
- [x] Headless 3D scene startup and Windows export
- [x] Privacy code guardrails
- [ ] Full malformed-save input fuzz tests
- [ ] Longer economy balance tests covering whole campaign
- [ ] Dependency checksum verification and pinned workflow action commits
- [ ] Windows Defender and security/provenance review

## Real Windows 11 testing still required
- [ ] Clean PC first-run without Godot editor
- [ ] Keyboard/mouse, pause, camera and control responsiveness
- [ ] Saves from old game versions on real Windows machines
- [ ] Save corruption and simulated power interruption
- [ ] Packet capture to verify no game network traffic
- [ ] Audit for access to personal files or other games
- [ ] Long duration GPU/CPU/memory profiling and reliable FPS
- [ ] Controller, key remapping, text scaling and accessibility

## Content and commercial readiness
- [ ] Polished 3D assets, animations, lighting, sound and soundtrack
- [ ] Endgame fully playtested and combat balance verified
- [ ] Tutorial, feedback, accessibility and localization
- [ ] External playtesting, legal and license review
- [ ] Code signing, checksums and support process
- [ ] Steam store, policies and review

## Gate
Do not label the game v1.0, publish to Steam, or claim certified security until these items are completed and reviewed. CI success alone is not release approval.