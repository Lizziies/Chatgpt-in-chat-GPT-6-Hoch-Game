extends CanvasLayer
## HUD is passive: it only reads in-memory state. It never saves or transmits data.
class_name VoidHUD

var title_label: Label
var resource_label: Label
var status_label: Label
var build_label: Label
var research_label: Label
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
	var top_panel := _panel(root, Vector2(22, 20), Vector2(405, 167))
	var top_box := _column(top_panel)
	title_label = _label(top_box, "VOID // INDUSTRIES", 23, Color(0.45, 0.93, 0.94))
	resource_label = _label(top_box, "INITIALISIERUNG", 17, Color(0.89, 0.96, 1.0))
	vitals_label = _label(top_box, "", 13, Color(0.78, 0.85, 0.92))
	var side_panel := _panel(root, Vector2(-385, 20), Vector2(360, 230), true)
	var side_box := _column(side_panel)
	_label(side_box, "FABRIK // KONSTRUKTION", 18, Color(0.45, 0.93, 0.94))
	build_label = _label(side_box, "", 15, Color(0.9, 0.93, 0.96))
	_label(side_box, "1 GENERATOR     2 EXTRAKTOR", 13, Color(0.72, 0.86, 0.91))
	_label(side_box, "3 LABOR          4 GESCHUETZ", 13, Color(0.72, 0.86, 0.91))
	_label(side_box, "E BAUEN          F FORSCHEN", 13, Color(0.72, 0.86, 0.91))
	_label(side_box, "R EXPERIMENT     T REPARIEREN", 13, Color(0.72, 0.86, 0.91))
	research_label = _label(side_box, "", 13, Color(0.97, 0.77, 0.49))
	var bottom_panel := _panel(root, Vector2(22, -113), Vector2(910, 88), false, true)
	var bottom_box := _column(bottom_panel)
	status_label = _label(bottom_box, "ERWACHEN // Stelle die Energieversorgung wieder her.", 14, Color(0.94, 0.97, 1.0))
	_label(bottom_box, "WASD BEWEGEN  |  MAUS KAMERA  |  TAB UEBERSICHT  |  KLICK FEUERN  |  P SPEICHERN / O LADEN  |  ESC MAUS FREI", 12, Color(0.58, 0.73, 0.79))
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 24)
	crosshair.add_theme_color_override("font_color", Color(0.5, 0.95, 1.0, 0.8))
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-7, -15)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair)
	toast_label = _label(bottom_box, "", 14, Color(1.0, 0.68, 0.41))

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

func refresh(state: IndustryState, player_health: float, selected: String, enemy_count: int) -> void:
	resource_label.text = "ENERGIE    %s     /s +%s\nLEGIERUNG %s     DATEN %s\nVOID %s        FEINDE %d" % [
		_num(state.energy), _num((3.5 + 5.0 * float(state.machines["generator"])) * (1.0 + state.tech_level * 0.32)),
		_num(state.alloy), _num(state.data), _num(state.void_matter), enemy_count]
	vitals_label.text = "KERN %d%%  |  ANZUG %d%%  |  INSTABILITAET %d%%" % [int(state.core_health), int(player_health), int(state.instability)]
	var cost: Dictionary = state.get_cost(selected)
	build_label.text = "GEWAEHLT: %s\nPREIS: %d E  |  %d L  |  %d D" % [selected.to_upper(), int(cost.get("energy", 0)), int(cost.get("alloy", 0)), int(cost.get("data", 0))]
	var price: Dictionary = state.research_cost()
	research_label.text = "FORSCHUNG ST. %d / 5  |  %d E + %d D" % [state.tech_level, int(price["energy"]), int(price["data"])]

func announce(message: String) -> void:
	status_label.text = "SYSTEM // " + message
	toast_label.text = "● " + message
	toast_timer = 5.0

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0 and is_instance_valid(toast_label):
			toast_label.text = ""

func _num(amount: float) -> String:
	if amount >= 1000000.0:
		return "%.2fM" % (amount / 1000000.0)
	if amount >= 10000.0:
		return "%.1fK" % (amount / 1000.0)
	return str(int(amount))
