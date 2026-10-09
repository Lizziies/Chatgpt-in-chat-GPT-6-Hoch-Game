# VOID INDUSTRIES

Ein düsteres, offline spielbares 3D-Incremental-/Automation-Spiel mit riskanten Experimenten, begehbarer Fabrik und gelegentlichen Kämpfen. **Open Source – MIT-Lizenz.**

## Status
**Version 0.5 – Spielbare Pre-Alpha.** Begehbare 3D-Fabrik, echtes stromgebundenes Produktionsnetz, Maschinen-Synergien, Forschungszweige, Prestige, gefährliche Experimente und freiwilliger Elite-Kampf. Noch **kein fertiges Spiel** und noch nicht grafisch unter Windows 11 getestet.

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
4. Alternativ das Repository mit Godot 4.4.1 öffnen und `F5`/Projekt starten.

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
| 7 / 8 | Fabrikator / Void-Harvester (ab Forschungsstufe 3 / 4) |
| J | Nächste Maschine abbauen und 40 % des Materialwerts zurückbekommen |
| K / L | Förderband am Bau-Raster bauen / entfernen (Forschungsstufe 2) |
| M | Lokalen Sound ein-/ausschalten |
| E | Gewählte Maschine frei auf dem angezeigten Bau-Raster platzieren |
| F | Forschung kaufen |
| R | Riskantes Experiment starten |
| G | Teureres, risikoärmeres Experiment |
| C | Netz-Puls (bei 100 Kondensator-Ladung: 25s dreifache Produktion) |
| Q | Erledigten Auftrag einlösen |
| Z / X / V | Energie-, Industrie- oder Sicherheitsforschung (ab Stufe 2) |
| B (zweimal) | Prestige/Singularität nach Freischaltung bestätigen |
| Y | Freiwilligen Elite-Kampf starten (ab Forschung 4, Ressourcen nötig) |
| H | Bedienungs-Handbuch im Spiel anzeigen |
| Linksklick | Energieblaster |
| Esc | Maus freigeben; Linksklick im Spielfeld zum Einfangen |
| P / O | Spiel manuell speichern / laden |

## Kampagnenende
Das Spiel hat nun eine endliche erste Hauptkampagne: Erreiche Forschung 7, verdiene durch Prestige mindestens 2 dauerhafte Kerne, sammle 25 VOID-Materie, 250 Bauteile und 2500 Forschungsdaten und halte den Reaktor über 75 % Integrität. Mit **N** versiegelst du die Singularität und erreichst den Kampagnenabschluss; die Industrie bleibt als Sandbox spielbar. Dieses Ende ersetzt noch keine ausgearbeitete Handlung oder professionelle Präsentation.

## Grundschleife
Ressourcen erzeugen → Maschinen aufbauen → Forschungsstufen und neue Maschinen freischalten → Aufträge erfüllen und Belohnungen abholen → riskante oder stabilisierte Experimente durchführen → Anomalien abwehren → Produktionsboost nutzen. Die Produktion läuft beim Kämpfen weiter.

### Neue Systeme in Version 0.5
- **Freie Maschinenplatzierung:** Auf einem Raster innerhalb der Fabrik frei bauen, statt an 18 festen Plattformen. Bauabstände, Reaktorsicherheitszone und Weltgrenzen werden überprüft. Ein leuchtendes Vorschaufeld zeigt den Platz.
- **Physische Förderbänder:** Mit K einzelne Bandsegmente setzen, mit L entfernen. Verbindet eine zusammenhängende Bandstrecke einen stromversorgten Fabrikator mit einem Harvester, läuft eine Bauteil-Transportanimation und die Void-Ausbeute steigt um 15 % pro Route (bis zu 75 %).
- **Lokal synthetisierte Sounds:** Maschinenaktionen, Forschung, Alarm und ein leises Reaktor-Dröhnen. Kein Download und keine Audiodateien im Benutzerprofil. Mit M stumm schaltbar.
- **Verbesserter Operator:** Zusätzliche Rüstungsteile und prozedurale Laufanimation.
- **Größere Baufläche:** 114 × 114 statt bisher 82 × 82 Welteinheiten. Weiterhin eine geschlossene Fabrikhalle, noch keine komplett offene Welt.
- **Saveformat v5:** Speichert echte Maschinenkoordinaten, Förderbandsegmente und das bisherige Wirtschafts-/Prestige-System. Alte Saveformate v1–v4 werden geladen und die festen Plattformen dabei wiederhergestellt.
- **Sicherheitsgrenzen:** Maximal 110 Maschinen und 160 Förderbandsegmente. Vor dem Laden werden Koordinaten, Raster und Layout geprüft. Alle Funktionen sind offline.

### Neue Systeme in Version 0.4
- **Bauteile als Ressource:** Fabrikatoren konsumieren Energie und Legierungen, um Bauteile herzustellen.
- **Void-Harvester:** Nutzen Bauteile, Forschungsdaten und Energie, um Void-Materie automatisch zu gewinnen. Die Produktion erhöht geringfügig die Instabilität.
- **Neue Platzierungs-Synergien:** Extraktor neben Fabrikator verbessert Bauteil-Produktion; Stabilisator neben Harvester verbessert Void-Ausbeute.
- **Demontage:** `J` baut eine nahe Maschine ab und gibt 40 % des vorherigen Baupreises in Ressourcen zurück. Die Stromversorgung der verbliebenen Anlage wird sofort aktualisiert.
- **Speicherformat 4:** Beinhaltet Bauteilvorrat und produzierte Gesamtmenge. Liest ältere Spielstände der Versionen 1–3. Alles bleibt lokal und manuell.
- **Mehr Aufträge:** Die Kampagne erhält zusätzliche Zwischenziele für Bauteilproduktion und Void-Harvesting.
- **Weiterhin Pre-Alpha:** Prozedurale Platzhaltermodelle und fehlende große Welten, Sound/Animationen und Windows-Grafiktests bleiben offene Aufgaben.

### Neue Systeme in Version 0.3
- **Physisches Energie-Netzwerk:** Nur Maschinen, die über sichtbare Leitungen mit dem Reaktor verbunden sind, arbeiten. Neue Maschinen können andere Maschinen als Verbindungsbrücke versorgen. Nicht verbundene Module werden markiert.
- **Drei Produktionskombinationen:** Extraktor neben Labor erhöht Forschungsdaten, Generator neben Kondensator erhöht Laderate und Stabilisator neben Geschützturm erhöht dessen Angriffskraft. Alle Kombinationen erfordern aktive Verbindungen.
- **Drei Forschungszweige:** Energie, Industrie und Containment mit jeweils 3 Stufen, Materialkosten und echten Effekten.
- **Prestige / Singularität:** Nach Forschung 5 und genügend Ressourcen mit `B` zweimal bestätigen. Die Fabrik setzt sich zurück, aber bleibende Kerne gewähren einen permanenten Produktionsbonus.
- **Gelegentliche Bedrohungen:** Experimentbedingte Anomalien, dazu ein seltener Gefahrendirektor bei hoher Instabilität; Kämpfe unterbrechen die Produktion nicht.
- **Elite-Anomalie:** Freiwillige Bossprüfung ab Forschung 4 mit deutlich stärkerem Gegner und besonderen Ressourcenbelohnungen.
- **Ingame-Handbuch:** `H` zeigt Steuerung, Strategie und Datenschutz ohne Internetverbindung.
- **Spielstandformat v3 (historisch):** liest ältere v1/v2-Spielstände, speichert neue Forschungszweige und Prestige-Fortschritt. Keine automatische Dateisynchronisation.

### Neue Systeme in Version 0.2
- **8 Direktiven:** konkrete Ziele, sichtbarer Fortschritt und optionale Belohnungen; `Q` holt fertige Aufträge ab.
- **Kondensator (Stufe 1):** erzeugt Netz-Ladung; mit `C` startet ein 25-Sekunden-Overdrive mit 3× Produktion.
- **Stabilisator (Stufe 2):** verbraucht Energie, kühlt den Reaktor und repariert ihn langsam.
- **7 Forschungsstufen:** schalten Turm, Kondensator und Stabilisator frei und steigern die Produktion.
- **Zwei Experimentprotokolle:** `R` spart Ressourcen, ist gefährlicher; `G` kostet mehr, reduziert das Risiko.
- **Industrie-Atmosphäre:** ergänzte Leitungen, Warnmarkierungen und bei Gefahr pulsierende Alarmbeleuchtung.
- **Speicherformat v2 (historisch):** frühere Verbesserungen am lokalen Spielstand; die aktuelle Version verwendet v3.

### Spielstandsicherheit
Beim Laden wird JSON auf Größe, Struktur, Zahlenbereiche und erlaubte Maschinen geprüft. Nur das feste Godot-`user://`-Spielstandsverzeichnis wird verwendet. Spielstände werden **nicht** automatisch hochgeladen; es gibt keinen Cloud-Sync. Kein automatisches Speichern. Spielstände werden erst nach erfolgreichem Schreiben einer kleinen temporären Datei ersetzt; so soll ein Absturz während des Schreibvorgangs den bisherigen Stand nicht überschreiben. Zusätzliche Wiederherstellungs-Backups sind für eine spätere Version geplant.

## Roadmap
- [x] GitHub-Projekt & Lizenz
- [x] 3D-Welt, Spieler, frei drehbare Kamera
- [x] Maschinen, Ressourcensimulation, Forschung
- [x] Aufträge, Produktionsboost, Kondensatoren, Stabilisatoren, risikoärmere Experimente
- [x] Experimente, Bedrohungen, einfache Kämpfe
- [x] Freiwilliges lokales Save/Load
- [x] Windows-Build-Pipeline und grundlegende Tests
- [x] Einfache prozedurale Figurenanimationen und offline-synthetisierte Audioeffekte
- [ ] Hochwertige realistische 3D-Modelle, professionelle Charakteranimationen, Musik/Sounddesign, optimierte PBR-Materialien
- [x] Stromnetz-Abhängigkeiten, drei Forschungszweige und erstes Prestige-System
- [x] Bauteile und automatische Void-Verarbeitung als erste mehrstufige Produktionsketten
- [x] Freie Rasterplatzierung, visuelle Förderbänder, Produktionsbonus durch physische Logistik
- [ ] Verschiedene Industriezonen, umfangreichere Förderbandlogistik mit Item-Puffern, weitere Ressourcen und Prestige-Erweiterungen
- [ ] Barrierefreiheit, Controller, Übersetzungen
- [ ] Balancing, Windows-11-Grafiktests, Sicherheitsreview durch Dritte, Steam-Release
