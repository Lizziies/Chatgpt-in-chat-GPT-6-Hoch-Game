# VOID INDUSTRIES

Ein düsteres, offline spielbares 3D-Incremental-/Automation-Spiel mit riskanten Experimenten, begehbarer Fabrik und gelegentlichen Kämpfen. **Open Source – MIT-Lizenz.**

## Status
**Version 0.2 – Spielbare Pre-Alpha.** Neue Aufträge, echte Freischaltungen, sechs Maschinen, reaktive Alarmbeleuchtung und weitere Produktionstiefe. Das Spiel ist noch lange nicht fertig oder kommerziell getestet.

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
| 5 / 6 | Kondensator / Stabilisator wählen (Forschung nötig) |
| E | Maschine auf der nächsten freien Bauplattform errichten |
| F | Forschung kaufen |
| R | Riskantes Experiment starten |
| G | Teureres, risikoärmeres Experiment |
| C | Netz-Puls (bei 100 Kondensator-Ladung: 25s dreifache Produktion) |
| Q | Erledigten Auftrag einlösen |
| Linksklick | Energieblaster |
| Esc | Maus freigeben; Linksklick im Spielfeld zum Einfangen |
| P / O | Spiel manuell speichern / laden |

## Grundschleife
Ressourcen erzeugen → Maschinen aufbauen → Forschungsstufen und neue Maschinen freischalten → Aufträge erfüllen und Belohnungen abholen → riskante oder stabilisierte Experimente durchführen → Anomalien abwehren → Produktionsboost nutzen. Die Produktion läuft beim Kämpfen weiter.

### Neue Systeme in Version 0.2
- **8 Direktiven:** konkrete Ziele, sichtbarer Fortschritt und optionale Belohnungen; `Q` holt fertige Aufträge ab.
- **Kondensator (Stufe 1):** erzeugt Netz-Ladung; mit `C` startet ein 25-Sekunden-Overdrive mit 3× Produktion.
- **Stabilisator (Stufe 2):** verbraucht Energie, kühlt den Reaktor und repariert ihn langsam.
- **7 Forschungsstufen:** schalten Turm, Kondensator und Stabilisator frei und steigern die Produktion.
- **Zwei Experimentprotokolle:** `R` spart Ressourcen, ist gefährlicher; `G` kostet mehr, reduziert das Risiko.
- **Industrie-Atmosphäre:** ergänzte Leitungen, Warnmarkierungen und bei Gefahr pulsierende Alarmbeleuchtung.
- **Speicherformat v2:** manuelles lokales Speichern (`P`) und Laden (`O`); Spielstände aus v1 werden weiterhin gelesen.

### Spielstandsicherheit
Beim Laden wird JSON auf Größe, Struktur, Zahlenbereiche und erlaubte Maschinen geprüft. Nur das feste Godot-`user://`-Spielstandsverzeichnis wird verwendet. Spielstände werden **nicht** automatisch hochgeladen; es gibt keinen Cloud-Sync. Kein automatisches Speichern. Bei Absturz unmittelbar beim Speichern ist eine Beschädigung möglich – Backups sind für eine spätere Version geplant.

## Roadmap
- [x] GitHub-Projekt & Lizenz
- [x] 3D-Welt, Spieler, frei drehbare Kamera
- [x] Maschinen, Ressourcensimulation, Forschung
- [x] Aufträge, Produktionsboost, Kondensatoren, Stabilisatoren, risikoärmere Experimente
- [x] Experimente, Bedrohungen, einfache Kämpfe
- [x] Freiwilliges lokales Save/Load
- [x] Windows-Build-Pipeline und grundlegende Tests
- [ ] Hochwertige 3D-Modelle, Charakteranimationen, Sounddesign, optimierte PBR-Materialien
- [ ] Physische Produktionsketten, verzweigter Forschungsbaum, Prestige
- [ ] Barrierefreiheit, Controller, Übersetzungen
- [ ] Spielbalance, Langzeittests, Steam-Release
