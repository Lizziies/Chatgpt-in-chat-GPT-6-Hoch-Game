# VOID INDUSTRIES

Ein düsteres, offline spielbares 3D-Incremental-/Automation-Spiel mit riskanten Experimenten, begehbarer Fabrik und gelegentlichen Kämpfen. **Open Source – MIT-Lizenz.**

## Status
**Frühe spielbare Alpha / Vertical Slice.** Keine vollständige kommerzielle Veröffentlichung. Der Fokus liegt auf dem spielbaren Kernsystem.

## Datenschutz als Architekturprinzip
- Kein Account, keine Werbung, keine Online-Schnittstellen, kein HTTP, keine Telemetrie.
- Kein Lesen von Windows-Konten, Browsern, anderen Spielen oder beliebigen Benutzerdateien.
- Keine Drittanbieter-Plugins, Tracking-SDKs oder heruntergeladenen Laufzeit-Assets.
- Kein automatisches Speichern oder Laden. Spielstände sind **freiwillig** und liegen ausschließlich im Godot-eigenen App-Datenverzeichnis (`user://void_save.json`).
- Der Godot-Dateilogger wird für das Spielprojekt deaktiviert. Betriebssystem, Steam oder Grafiktreiber können unabhängig vom Spiel eigene Diagnosedaten erzeugen.
- Laufzeitberechtigungen sind auf die Standardfunktionen eines normalen Spiels beschränkt.
- Niemand kann absolute Fehlerfreiheit oder Sicherheit garantieren. Sicherheitsmeldungen bitte als private Nachricht an die Projektverantwortlichen statt öffentlich mit Exploit-Details.

## Technik
- **Godot 4.4.1**, GDScript, ohne Netzwerkcode
- Codegenerierte 3D-Umgebung und Materialien: keine externen Asset-Lizenzen oder Binärdateien nötig
- Windows 11 (x86-64) über reproduzierbaren GitHub-Actions-Export
- Quelloffen: eigene Spielinhalte unter MIT (siehe LICENSE), Godot-Engine unter separater MIT-Lizenz

## Spielen
1. GitHub Actions → `Godot CI & Windows Build` → erfolgreiches Workflow-Ergebnis öffnen.
2. Artifact `VOID-INDUSTRIES-Windows` herunterladen und entpacken.
3. `VOID_INDUSTRIES.exe` unter Windows starten. Windows SmartScreen kann bei nicht signierten Alpha-Builds warnen: nur Builds aus dem offiziellen Repository verwenden.
4. Alternativ das Repository mit Godot 4.4.1 öffnen und `F6`/Projekt starten.

### Steuerung
| Taste | Aktion |
| --- | --- |
| WASD | Laufen |
| Maus | Third-Person-Kamera |
| Umschalt | Sprinten |
| Leertaste | Springen |
| Tab | Taktische Kamera ein/aus |
| 1 / 2 / 3 / 4 | Generator / Extraktor / Labor / Turm auswählen |
| E | Maschine auf der nächsten freien Bauplattform errichten |
| F | Forschung kaufen |
| R | Riskantes Experiment starten |
| Linksklick | Energieblaster |
| Esc | Maus freigeben; Linksklick im Spielfeld zum Einfangen |
| P / O | Spiel manuell speichern / laden |

## Grundschleife
Ressourcen erzeugen → Maschinen aufbauen → Forschung betreiben → experimentelle Technologie riskieren → Anomalien und Angriffe überstehen → weitere Technologie freischalten. Die Produktion läuft weiter, wenn du kämpfst.

## Roadmap
- [x] GitHub-Projekt & Lizenz
- [x] 3D-Welt, Spieler, frei drehbare Kamera
- [x] Maschinen, Ressourcensimulation, Forschung
- [x] Experimente, Bedrohungen, einfache Kämpfe
- [x] Freiwilliges lokales Save/Load
- [x] Windows-Build-Pipeline und grundlegende Tests
- [ ] 3D-Modelle, Animationspakete, Sounddesign
- [ ] Produktionsketten, riesiger Forschungsbaum, Prestige
- [ ] Barrierefreiheit, Controller, Übersetzungen
- [ ] Spielbalance, Langzeittests, Steam-Release
