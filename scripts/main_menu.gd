extends CanvasLayer
## Keyboard/mouse accessible offline start, pause, options and credits menu.
## All settings are session-only. This script performs NO filesystem or network IO.
class_name VoidMainMenu

signal new_game_requested
signal continue_requested
signal resume_requested
signal save_requested
signal title_requested
signal mouse_speed_changed(value: float)
signal audio_volume_changed(value: float)

var mode: String = "title"
var root_layer: Control
var menu_stack: VBoxContainer
var notice: Label
var can_continue: bool = false
var mouse_sensitivity: float = 0.0025
var volume: float = 0.65

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	root_layer = Control.new()
	root_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_layer)
	var background := ColorRect.new()
	background.color = Color(0.006, 0.015, 0.023, 0.94)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	root_layer.add_child(background)
	var centered := CenterContainer.new()
	centered.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centered.mouse_filter = Control.MOUSE_FILTER_PASS
	root_layer.add_child(centered)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(610, 0)
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color(0.031, 0.062, 0.083, 0.96)
	skin.border_color = Color(0.14, 0.61, 0.68)
	skin.set_border_width_all(1)
	skin.set_corner_radius_all(12)
	skin.set_content_margin_all(28)
	frame.add_theme_stylebox_override("panel", skin)
	centered.add_child(frame)
	menu_stack = VBoxContainer.new()
	menu_stack.add_theme_constant_override("separation", 12)
	frame.add_child(menu_stack)
	_render()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if mode == "playing":
			show_pause()
		elif mode == "victory":
			resume_requested.emit()
		elif mode == "pause":
			resume_requested.emit()
		elif mode == "settings":
			if can_continue:
				show_pause()
			else:
				show_title(false)
		get_viewport().set_input_as_handled()

func show_title(available: bool) -> void:
	can_continue = available
	mode = "title"
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_render()

func show_pause() -> void:
	can_continue = true
	mode = "pause"
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_render()

func resume() -> void:
	mode = "playing"
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func show_victory() -> void:
	mode = "victory"
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_render()

func show_notice(message: String) -> void:
	if is_instance_valid(notice):
		notice.text = message

func _clear() -> void:
	for child in menu_stack.get_children():
		menu_stack.remove_child(child)
		child.queue_free()

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	menu_stack.add_child(label)
	return label

func _button(value: String, callback: Callable, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", 18)
	button.disabled = disabled
	button.pressed.connect(callback)
	menu_stack.add_child(button)
	return button

func _render() -> void:
	if not is_instance_valid(menu_stack):
		return
	_clear()
	_label("V O I D  / /  I N D U S T R I E S", 29, Color(0.45, 0.95, 0.96))
	_label("EXPERIMENTAL INDUSTRIAL COMPLEX  •  OFFLINE EDITION", 12, Color(0.56, 0.70, 0.78))
	var divider := HSeparator.new()
	menu_stack.add_child(divider)
	match mode:
		"title":
			_label("Erwecke die Anlage. Automatisiere eine verbotene Industrie. Ueberlebe die Folgen.", 19, Color(0.86, 0.93, 0.98))
			_button("NEUES SPIEL", func() -> void: new_game_requested.emit())
			_button("SPIELSTAND FORTSETZEN", func() -> void: continue_requested.emit(), not can_continue)
			_button("EINSTELLUNGEN", func() -> void:
				can_continue = false
				mode = "settings"
				_render())
			_button("STEUERUNG & DATENSCHUTZ", func() -> void:
				mode = "about"
				_render())
			_button("BEENDEN", func() -> void: get_tree().quit())
		"pause":
			_label("PAUSE // DER KOMPLEX WARTET", 18, Color(0.89, 0.96, 0.98))
			_button("SPIEL FORTSETZEN", func() -> void: resume_requested.emit())
			_button("MANUELL SPEICHERN", func() -> void: save_requested.emit())
			_button("EINSTELLUNGEN", func() -> void:
				mode = "settings"
				_render())
			_button("ZUM TITELBILDSCHIRM", func() -> void: title_requested.emit())
			_button("BEENDEN (OHNE AUTO-SAVE)", func() -> void: get_tree().quit())
		"victory":
			_label("KAMPAGNE ABGESCHLOSSEN", 25, Color(0.95, 0.77, 0.42))
			_label("SINGULARITAET VERSIEGELT", 20, Color(0.45, 0.95, 0.96))
			_label("Du hast die Anlage zurueckerobert, die Industrie stabilisiert und die letzte Anomalie versiegelt.", 17, Color(0.89, 0.94, 0.99))
			_label("Deine Maschinen und permanenten Prestige-Kerne bleiben erhalten. Du kannst die freie Fabrik weiter ausbauen.", 15, Color(0.80, 0.89, 0.96))
			_button("SANDBOX WEITERSPIELEN", func() -> void: resume_requested.emit())
			_button("MANUELL SPEICHERN", func() -> void: save_requested.emit())
			_button("ZUM TITELBILDSCHIRM", func() -> void: title_requested.emit())
		"settings":
			_label("EINSTELLUNGEN – nur fuer diese Sitzung", 20, Color(0.89, 0.96, 0.98))
			_label("Mausempfindlichkeit", 15, Color(0.80, 0.87, 0.93))
			var sensitivity := HSlider.new()
			sensitivity.min_value = 0.001
			sensitivity.max_value = 0.008
			sensitivity.step = 0.00025
			sensitivity.value = mouse_sensitivity
			sensitivity.custom_minimum_size.y = 25
			sensitivity.value_changed.connect(func(next: float) -> void:
				mouse_sensitivity = next
				mouse_speed_changed.emit(next))
			menu_stack.add_child(sensitivity)
			_label("Lautstaerke", 15, Color(0.80, 0.87, 0.93))
			var audio_slider := HSlider.new()
			audio_slider.min_value = 0
			audio_slider.max_value = 1.0
			audio_slider.step = 0.05
			audio_slider.value = volume
			audio_slider.custom_minimum_size.y = 25
			audio_slider.value_changed.connect(func(next: float) -> void:
				volume = next
				audio_volume_changed.emit(next))
			menu_stack.add_child(audio_slider)
			_button("ZURUECK", func() -> void:
				if can_continue:
					show_pause()
				else:
					show_title(false))
		"about":
			_label("WASD bewegen  •  Maus drehen  •  TAB Baukamera  •  ESC Pause", 15, Color(0.88, 0.94, 0.99))
			_label("1–8 Maschinentyp  •  E bauen  •  K/L Foerderband", 15, Color(0.88, 0.94, 0.99))
			_label("F Forschung  •  Q Aufgaben  •  R/G Experimente", 15, Color(0.88, 0.94, 0.99))
			_label("P speichern  •  O laden  •  H Handbuch", 15, Color(0.88, 0.94, 0.99))
			_label("DATENSCHUTZ: Kein Login, kein Tracking, keine Netzwerkzugriffe des Spiels. Spielstaende sind freiwillig und ausschliesslich lokal.", 16, Color(0.55, 0.90, 0.87))
			_button("ZURUECK", func() -> void: show_title(can_continue))
	notice = _label("", 14, Color(1.0, 0.72, 0.43))
	_label("Pre-release • Vollstaendig offline • Open Source / MIT", 12, Color(0.54, 0.67, 0.75))
