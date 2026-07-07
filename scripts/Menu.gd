extends Node2D

const AudioSystemScript := preload("res://scripts/AudioSystem.gd")
const PlayerSettingsScript := preload("res://scripts/PlayerSettings.gd")

var _audio: Node
var _hint_label: Label
var _start_button: TextureButton
var _settings_button: TextureButton
var _logo: Sprite2D
var _main_panel: PanelContainer
var _settings_panel: PanelContainer
var _name_edits: Dictionary = {}
var _value_edits: Dictionary = {}
var _float_time := 0.0


func _ready() -> void:
	_setup_background()
	_setup_audio()
	_setup_ui()


func _process(delta: float) -> void:
	_float_time += delta
	if _logo:
		_logo.position.y = 122.0 + sin(_float_time * 1.4) * 4.0
	if _start_button:
		_start_button.scale = Vector2.ONE * (0.92 + sin(_float_time * 2.2) * 0.015)


func _setup_background() -> void:
	var background := Sprite2D.new()
	background.texture = load("res://assets/images/menu/title_background.png")
	background.position = Vector2(640, 360)
	if background.texture:
		background.scale = Vector2(1280.0 / background.texture.get_width(), 720.0 / background.texture.get_height())
	background.z_index = -20
	add_child(background)

	var soft_overlay := ColorRect.new()
	soft_overlay.position = Vector2.ZERO
	soft_overlay.size = Vector2(1280, 720)
	soft_overlay.color = Color("#ffffff", 0.08)
	add_child(soft_overlay)


func _setup_audio() -> void:
	_audio = AudioSystemScript.new()
	_audio.name = "MenuAudio"
	add_child(_audio)


func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	_logo = Sprite2D.new()
	_logo.texture = load("res://assets/images/menu/title_logo.png")
	_logo.position = Vector2(640, 122)
	if _logo.texture:
		_logo.scale = Vector2.ONE * 0.92
	canvas.add_child(_logo)

	_main_panel = PanelContainer.new()
	_main_panel.position = Vector2(426, 386)
	_main_panel.custom_minimum_size = Vector2(428, 280)
	_main_panel.add_theme_stylebox_override("panel", _menu_panel_style())
	canvas.add_child(_main_panel)

	var panel_box := VBoxContainer.new()
	panel_box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel_box.add_theme_constant_override("separation", 8)
	_main_panel.add_child(panel_box)

	_start_button = _make_texture_button("res://assets/images/menu/start_button.png", Vector2(248, 132))
	_start_button.pressed.connect(_on_start_pressed)
	_start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel_box.add_child(_start_button)

	_settings_button = _make_texture_button("res://assets/images/menu/settings_button_clean.png", Vector2(238, 82))
	_settings_button.pressed.connect(_on_settings_pressed)
	_settings_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel_box.add_child(_settings_button)

	_hint_label = Label.new()
	_hint_label.text = "点击开始，守护汐汐公主的梦幻城堡。"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 16)
	_hint_label.add_theme_color_override("font_color", Color("#8b1f5f"))
	panel_box.add_child(_hint_label)

	_setup_settings_panel(canvas)


func _setup_settings_panel(canvas: CanvasLayer) -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.position = Vector2(280, 112)
	_settings_panel.custom_minimum_size = Vector2(720, 552)
	_settings_panel.visible = false
	_settings_panel.add_theme_stylebox_override("panel", _menu_panel_style())
	canvas.add_child(_settings_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_settings_panel.add_child(box)

	var title := Label.new()
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#8b1f5f"))
	box.add_child(title)

	var hint := Label.new()
	hint.text = "修改后点击保存，进入游戏后角色名字和初始数值会同步生效。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color("#9f1239"))
	box.add_child(hint)

	var name_title := Label.new()
	name_title.text = "底部角色名字"
	name_title.add_theme_font_size_override("font_size", 18)
	name_title.add_theme_color_override("font_color", Color("#8b1f5f"))
	box.add_child(name_title)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 7)
	box.add_child(grid)

	var names := PlayerSettingsScript.load_tower_names()
	for type in PlayerSettingsScript.TOWER_ORDER:
		var label := _make_settings_label("%s：" % str(PlayerSettingsScript.DEFAULT_TOWER_NAMES[type]), 72)
		grid.add_child(label)

		var edit := _make_line_edit(str(names.get(type, PlayerSettingsScript.DEFAULT_TOWER_NAMES[type])), 6, Vector2(178, 32))
		grid.add_child(edit)
		_name_edits[type] = edit

	var value_title := Label.new()
	value_title.text = "游戏初始数值"
	value_title.add_theme_font_size_override("font_size", 18)
	value_title.add_theme_color_override("font_color", Color("#8b1f5f"))
	box.add_child(value_title)

	var value_grid := GridContainer.new()
	value_grid.columns = 4
	value_grid.add_theme_constant_override("h_separation", 12)
	value_grid.add_theme_constant_override("v_separation", 7)
	box.add_child(value_grid)

	var values := PlayerSettingsScript.load_game_values()
	_add_value_edit(value_grid, "coins", "初始金币：", values)
	_add_value_edit(value_grid, "life", "初始生命：", values)
	_add_value_edit(value_grid, "star_power", "星雨能量：", values)
	_add_value_edit(value_grid, "start_wave", "起始关卡：", values)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)

	var save_button := _make_text_button("保存")
	save_button.pressed.connect(_save_settings)
	buttons.add_child(save_button)

	var reset_button := _make_text_button("恢复默认")
	reset_button.pressed.connect(_reset_settings)
	buttons.add_child(reset_button)

	var back_button := _make_text_button("返回")
	back_button.pressed.connect(_close_settings)
	buttons.add_child(back_button)


func _add_value_edit(parent: GridContainer, key: String, label_text: String, values: Dictionary) -> void:
	parent.add_child(_make_settings_label(label_text, 92))
	var edit := _make_line_edit(str(values.get(key, PlayerSettingsScript.DEFAULT_GAME_VALUES[key])), 5, Vector2(110, 32))
	edit.placeholder_text = str(PlayerSettingsScript.DEFAULT_GAME_VALUES[key])
	parent.add_child(edit)
	_value_edits[key] = edit


func _make_settings_label(text: String, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 30)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#7c2d12"))
	return label


func _make_line_edit(text: String, max_length: int, size: Vector2) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = text
	edit.max_length = max_length
	edit.custom_minimum_size = size
	edit.add_theme_font_size_override("font_size", 16)
	edit.add_theme_color_override("font_color", Color("#7c2d12"))
	edit.add_theme_color_override("font_placeholder_color", Color("#be123c", 0.55))
	edit.add_theme_stylebox_override("normal", _line_edit_style(false))
	edit.add_theme_stylebox_override("focus", _line_edit_style(true))
	edit.add_theme_stylebox_override("read_only", _line_edit_style(false))
	return edit


func _make_texture_button(path: String, size: Vector2) -> TextureButton:
	var button := TextureButton.new()
	var texture: Texture2D = load(path)
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = size
	button.size = size
	button.pivot_offset = size * 0.5
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


func _make_text_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(128, 42)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _button_style(Color("#fff7ed", 0.96), Color("#ff70a6", 0.95)))
	button.add_theme_stylebox_override("hover", _button_style(Color("#ffffff", 0.98), Color("#ff70a6", 1.0)))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#ff70a6", 0.96), Color("#ffffff", 0.9)))
	button.add_theme_color_override("font_color", Color("#8b1f5f"))
	button.add_theme_color_override("font_hover_color", Color("#be123c"))
	button.add_theme_color_override("font_pressed_color", Color("#ffffff"))
	button.add_theme_font_size_override("font_size", 16)
	return button


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _line_edit_style(focused: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff7ed", 0.96)
	style.border_color = Color("#38bdf8", 0.95) if focused else Color("#ff70a6", 0.78)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _menu_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff7ed", 0.72)
	style.border_color = Color("#ff70a6", 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(30)
	style.shadow_color = Color("#7c2d12", 0.18)
	style.shadow_size = 10
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _on_start_pressed() -> void:
	if _audio:
		_audio.play_sfx("ui")
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_settings_pressed() -> void:
	if _audio:
		_audio.play_sfx("ui")
	_main_panel.visible = false
	_settings_panel.visible = true
	_hint_label.text = "设置角色名字和初始数值。"


func _save_settings() -> void:
	var names := {}
	for type in PlayerSettingsScript.TOWER_ORDER:
		names[type] = str(_name_edits[type].text).strip_edges()
	PlayerSettingsScript.save_tower_names(names)
	var values := {}
	for key in PlayerSettingsScript.GAME_VALUE_ORDER:
		values[key] = _value_from_edit(key)
	PlayerSettingsScript.save_game_values(values)
	if _audio:
		_audio.play_sfx("ui")
	_close_settings()
	_hint_label.text = "设置已保存，开始游戏后会同步生效。"


func _reset_settings() -> void:
	PlayerSettingsScript.reset_all_settings()
	var names := PlayerSettingsScript.load_tower_names()
	for type in PlayerSettingsScript.TOWER_ORDER:
		_name_edits[type].text = str(names[type])
	var values := PlayerSettingsScript.load_game_values()
	for key in PlayerSettingsScript.GAME_VALUE_ORDER:
		_value_edits[key].text = str(values[key])
	if _audio:
		_audio.play_sfx("ui")


func _close_settings() -> void:
	_settings_panel.visible = false
	_main_panel.visible = true


func _value_from_edit(key: String) -> int:
	var text := str(_value_edits[key].text).strip_edges()
	if not text.is_valid_int():
		return int(PlayerSettingsScript.DEFAULT_GAME_VALUES[key])
	var limits: Vector2i = PlayerSettingsScript.GAME_VALUE_LIMITS[key]
	return clampi(int(text), limits.x, limits.y)
