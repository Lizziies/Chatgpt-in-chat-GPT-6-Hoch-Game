extends CanvasLayer
## HUD is passive: it only reads in-memory state. It never saves or transmits data.
class_name VoidHUD

var title_label: Label
var resource_label: Label
var status_label: Label
var build_label: Label
var research_label: Label
var mission_label: Label
var pulse_label: Label
var power_label: Label
var specialty_label: Label
var prestige_label: Label
var help_panel: PanelContainer
var logistics_label: Label
var vitals_label: Label
var toast_label: Label
var toast_timer: float = 0.0

func _ready() -> void:
	layer = 3
	var root := Control.new()
	root.name = "HUD"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var top_panel := _panel(root, Vector2(22, 20), Vector2(440, 196))
	var top_box := _column(top_panel)
	title_label = _label(top_box, "VOID // INDUSTRIES", 23, Color(0.45, 0.93, 0.94))
	resource_label = _label(top_box, "INITIALISIERUNG", 17, Color(0.89, 0.96, 1.0))
	vitals_label = _label(top_box, "", 13, Color(0.78, 0.85, 0.92))
	var side_panel := _panel(root, Vector2(-385, 20), Vector2(378, 346), true)
	var side_box := _column(side_panel)
	_label(side_box, "FABRIK // KONSTRUKTION", 18, Color(0.45, 0.93, 0.94))
	build_label = _label(side_box, "", 15, Color(0.9, 0.93, 0.96))
	_label(side_box, "1 GENERATOR     2 EXTRAKTOR", 13, Color(0.72, 0.86, 0.91))
	_label(side_box, "3 LABOR          4 GESCHUETZ", 13, Color(0.72, 0.86, 0.91))
	_label(side_box, "5 KONDENSATOR   6 STABILISATOR", 13, Color(0.72, 0.86, 0.91))
	_label(side_box, "7 FABRIKATOR      8 VOID-HARVESTER", 13, Color(0.72, 0.86, 0.91))
	_label(side_box, "J DEMONTIEREN (40% RUECKGABE)", 13, Color(0.72, 0.86, 0.91))
	_label(side_box, "E BAUEN     F FORSCHEN     Q BELOHNUNG", 13, Color(0.72, 0.86, 0.91))
	_label(side_box, "R EXPERIMENT   G SICHER   T REPARATUR", 13, Color(0.72, 0.86, 0.91))
	_label(side_box, "C NETZ-PULS (bei voller Ladung)", 13, Color(0.72, 0.86, 0.91))
	research_label = _label(side_box, "", 13, Color(0.97, 0.77, 0.49))
	pulse_label = _label(side_box, "", 13, Color(0.50, 0.94, 0.90))
	var task_panel := _panel(root, Vector2(22, 231), Vector2(440, 104))
	var task_box := _column(task_panel)
	_label(task_box, "DIREKTIVE // PRODUKTIONSZIELE", 14, Color(0.45, 0.93, 0.94))
	mission_label = _label(task_box, "", 13, Color(0.90, 0.92, 0.97))
	var power_panel := _panel(root, Vector2(22, 349), Vector2(440, 122))
	var power_box := _column(power_panel)
	_label(power_box, "REAKTOR // ENERGIE-NETZWERK", 14, Color(0.45, 0.93, 0.94))
	power_label = _label(power_box, "", 13, Color(0.90, 0.92, 0.97))
	logistics_label = _label(power_box, "", 12, Color(0.86, 0.65, 0.45))
	var upgrade_panel := _panel(root, Vector2(-398, 380), Vector2(378, 240), true)
	var upgrade_box := _column(upgrade_panel)
	_label(upgrade_box, "FORSCHUNGSZWEIGE // AB STUFE 2", 14, Color(0.45, 0.93, 0.94))
	specialty_label = _label(upgrade_box, "", 13, Color(0.90, 0.92, 0.97))
	prestige_label = _label(upgrade_box, "", 13, Color(0.97, 0.77, 0.49))
	_label(upgrade_box, "Y ELITE-TEST (FORSCHUNG 4+) // SELTENE BEUTE", 12, Color(0.95, 0.40, 0.38))
	var bottom_panel := _panel(root, Vector2(22, -113), Vector2(910, 88), false, true)
	var bottom_box := _column(bottom_panel)
	status_label = _label(bottom_box, "ERWACHEN // Stelle die Energieversorgung wieder her.", 14, Color(0.94, 0.97, 1.0))
	_label(bottom_box, "WASD / SHIFT LAUFEN   |   TAB BAUKAMERA   |   KLICK BLASTER   |   P SPEICHERN / O LADEN   |   ESC MAUS FREI", 12, Color(0.58, 0.73, 0.79))
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 24)
	crosshair.add_theme_color_override("font_color", Color(0.5, 0.95, 1.0, 0.8))
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-7, -15)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair)
	toast_label = _label(bottom_box, "", 14, Color(1.0, 0.68, 0.41))
	help_panel = _panel(root, Vector2(480, 140), Vector2(650, 510))
	help_panel.visible = false
	var help_box := _column(help_panel)
	_label(help_box, "VOID INDUSTRIES // OPERATOREN-HANDBUCH", 23, Color(0.45, 0.93, 0.94))
	_label(help_box, "DER KOMPLEX  •  DEIN ZIEL", 17, Color(0.97, 0.77, 0.49))
	_label(help_box, "Erzeuge Energie, baue ein zusammenhaengendes Maschinen-Netz und erforsche immer riskantere Technologien. Steht eine Maschine nicht in Reichweite des Reaktors oder anderer aktiver Maschinen, produziert sie nichts.", 15, Color(0.89, 0.94, 0.99))
	_label(help_box, "WASD laufen  |  SHIFT sprinten  |  LEERTASTE springen\nMAUS drehen  |  RAD zoomen  |  TAB Baukamera\n1–8 Maschine | E frei bauen | J abbauen | K Band | L Band weg\nF Forschung  |  Z/X/V Forschungszweige\nR Riskantes Experiment  |  G Sichereres Experiment\nC Netz-Puls  |  Q Auftrag einloesen  |  T reparieren\nLINKSKLICK schiessen  |  Y Elite-Kampf (Stufe 4+)\nB Prestige (zweimal bestaetigen)\nM Ton umschalten | K Foerderband | L Band abbauen\nP Lokal speichern  |  O Lokal laden\nESC Maus freigeben  |  H Handbuch anzeigen/schliessen", 14, Color(0.87, 0.93, 0.96))
	_label(help_box, "DATENSCHUTZ", 16, Color(0.45, 0.93, 0.94))
	_label(help_box, "Kein Login. Keine Telemetrie. Offline spielbar. Speicherungen ausschliesslich nach Tastendruck auf P in den lokalen App-Daten.", 14, Color(0.87, 0.93, 0.96))

func _panel(parent: Control, offset: Vector2, dims: Vector2, align_right: bool = false, align_bottom: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	if align_right:
		panel.anchor_left = 1.0
		panel.anchor_right = 1.0
	if align_bottom:
		panel.anchor_top = 1.0
		panel.anchor_bottom = 1.0
	panel.offset_left = offset.x
	panel.offset_top = offset.y
	panel.offset_right = offset.x + dims.x
	panel.offset_bottom = offset.y + dims.y
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.036, 0.051, 0.91)
	style.border_color = Color(0.14, 0.34, 0.4, 0.92)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _column(parent: PanelContainer) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(v)
	return v

func _label(parent: Node, text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func toggle_help() -> void:
	help_panel.visible = not help_panel.visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if help_panel.visible else Input.MOUSE_MODE_CAPTURED

func refresh(state: IndustryState, player_health: float, selected: String, enemy_count: int, connected_count: int) -> void:
	var production: Dictionary = state.get_production()
	resource_label.text = "ENERGIE  %s (+%s/s)\nLEGIERUNG %s (+%s/s) | DATEN %s (+%s/s)\nBAUTEILE %s (+%s/s) | VOID %s | FEINDE %d" % [
		_num(state.energy), _num(float(production["energy"])),
		_num(state.alloy), _num(float(production["alloy"])), _num(state.data),
		_num(float(production["data"])), _num(state.components), _num(float(production["components"])), _num(state.void_matter), enemy_count]
	vitals_label.text = "KERN %d%%   ANZUG %d%%   INSTABILITAET %d%%" % [
		int(state.core_health), int(player_health), int(state.instability)]
	var cost: Dictionary = state.get_cost(selected)
	var lock_text: String = ""
	if not state.is_unlocked(selected):
		lock_text = "  [FORSCHUNG ST. %d]" % int(IndustryState.UNLOCKS[selected])
	build_label.text = "GEWAEHLT: %s%s\nPREIS: %d E | %d L | %d D | %d B" % [
		selected.to_upper(), lock_text,
		int(cost.get("energy", 0)), int(cost.get("alloy", 0)), int(cost.get("data", 0)), int(cost.get("components", 0))]
	var price: Dictionary = state.research_cost()
	if state.tech_level >= IndustryState.MAX_LEVEL:
		research_label.text = "FORSCHUNG: ALLE PROTOKOLLE ENTDECKT"
	else:
		research_label.text = "FORSCHUNG %d / %d: %s\nPREIS %d E + %d D" % [
			state.tech_level, IndustryState.MAX_LEVEL, state.next_technology(),
			int(price["energy"]), int(price["data"])]
	pulse_label.text = "KONDENSATOR-LADUNG: %d%%  |  OVERDRIVE: %ds" % [
		int(state.charge), int(ceil(state.overdrive_seconds))]
	power_label.text = "VERSORGT: %d / %d MASCHINEN\nKOMBOS: LAB+EX %d | GEN+CAP %d | TOWER+STAB %d" % [
		connected_count, _machine_total(state),
		int(state.synergies["lab_extractor"]), int(state.synergies["generator_capacitor"]),
		int(state.synergies["turret_stabilizer"])]
	specialty_label.text = "Z ENERGIE        St. %d/3   (+25%% je Stufe)\nX INDUSTRIE      St. %d/3   (+18%% Legierung/Daten)\nV SICHERHEIT     St. %d/3   (+Kuehlung)\nKosten wachsen mit jeder Forschungsstufe." % [
		int(state.branches["energy"]), int(state.branches["industry"]), int(state.branches["containment"])]
	var prep: String = "B = SINGULARITAET STARTEN!" if state.prestige_eligible() else "B = PRESTIGE (F5, 8V, 800D, 3500E)"
	prestige_label.text = "KERNE: %d  |  DAUERBONUS +%d%%\n%s\n%s" % [
		state.prestige_cores, state.prestige_cores * 15, prep,
		"FINALE ERREICHT // INDUSTRIE GERETTET" if state.campaign_complete else "N FINALE: F7 + 2 KERNE + 25 VOID + 250 BAUTEILE + 2500 DATEN"]
	var goal: Dictionary = state.current_directive()
	if goal.is_empty():
		mission_label.text = "ALLE DIREKTIVEN ABGESCHLOSSEN\nWeitere Sektoren sind in Entwicklung."
	else:
		var progress: int = mini(state.directive_progress(), int(goal["target"]))
		var ready: String = "  [Q: BONUS ABHOLEN]" if progress >= int(goal["target"]) else ""
		mission_label.text = "%s\n%s   [%d/%d]%s" % [
			str(goal["title"]).to_upper(), str(goal["hint"]),
			progress, int(goal["target"]), ready]

func announce(message: String) -> void:
	status_label.text = "SYSTEM // " + message
	toast_label.text = "● " + message
	toast_timer = 5.0

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0 and is_instance_valid(toast_label):
			toast_label.text = ""

func _machine_total(state: IndustryState) -> int:
	var count: int = 0
	for kind in IndustryState.MACHINES:
		count += int(state.machines[kind])
	return count

func _num(amount: float) -> String:
	if amount >= 1000000.0:
		return "%.2fM" % (amount / 1000000.0)
	if amount >= 10000.0:
		return "%.1fK" % (amount / 1000.0)
	return str(int(amount))

func update_logistics(routes: int, tiles: int) -> void:
	if is_instance_valid(logistics_label):
		logistics_label.text = "FOERDERBAENDER %d | AKTIVE ROUTEN %d | +15%% VOID JE ROUTE" % [tiles, routes]
