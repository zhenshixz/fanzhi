extends Node2D

const EnemyScript := preload("res://scripts/Enemy.gd")
const TowerScript := preload("res://scripts/Tower.gd")
const AudioSystemScript := preload("res://scripts/AudioSystem.gd")
const ImpactFxScript := preload("res://scripts/ImpactFx.gd")
const PlayerSettingsScript := preload("res://scripts/PlayerSettings.gd")

var enemies: Array[Node] = []
var essence := 999
var heart := 12
var wave_index := 0
var corruption := 0.0

var towers_layer: Node2D
var enemies_layer: Node2D
var bullets_layer: Node2D
var fx_layer: Node2D

var _path_points: Array[Vector2] = [
	Vector2(-80, 376),
	Vector2(110, 312),
	Vector2(255, 245),
	Vector2(325, 330),
	Vector2(258, 488),
	Vector2(370, 592),
	Vector2(575, 588),
	Vector2(745, 600),
	Vector2(820, 505),
	Vector2(730, 390),
	Vector2(555, 345),
	Vector2(650, 242),
	Vector2(820, 258),
	Vector2(940, 335),
	Vector2(1082, 307),
	Vector2(1210, 385),
	Vector2(1360, 430)
]

var _build_spots: Array[Vector2] = [
	Vector2(211, 360),
	Vector2(361, 153),
	Vector2(524, 277),
	Vector2(408, 494),
	Vector2(567, 650),
	Vector2(672, 135),
	Vector2(792, 237),
	Vector2(673, 539),
	Vector2(982, 277),
	Vector2(990, 549)
]

var _occupied_spots: Dictionary = {}
var _tower_defs := {}
var _selected_type := "maw"
var _selected_spot := -1
var _hovered_spot := -1
var _spawn_left := 0
var _spawn_timer := 1.0
var _between_wave_timer := 2.0
var _game_speed := 1.0
var _quake_cooldown := 0.0

var _background: Sprite2D
var _audio: Node
var _hud_label: Label
var _life_value_label: Label
var _coin_value_label: Label
var _rain_value_label: Label
var _wave_label: Label
var _status_label: Label
var _details_label: Label
var _details_icon: TextureRect
var _details_title_label: Label
var _details_stats_label: Label
var _details_skill_label: Label
var _build_buttons: Dictionary = {}
var _upgrade_button: Button
var _quake_button: Button
var _speed_button: Button
var _music_button: Button
var _pause_button: Button
var _auto_button: Button
var _home_button: Button
var _skill_button: Button
var _build_cards: Dictionary = {}
var _build_name_labels: Dictionary = {}
var _custom_tower_names: Dictionary = {}


func _ready() -> void:
	Engine.time_scale = 1.0
	_custom_tower_names = PlayerSettingsScript.load_tower_names()
	_apply_game_values()
	_load_data()
	_setup_layers()
	_setup_ui()
	_setup_audio()
	_start_next_wave()


func _process(delta: float) -> void:
	_quake_cooldown = maxf(0.0, _quake_cooldown - delta)
	_hovered_spot = _find_nearest_spot(get_global_mouse_position(), 42.0)
	_handle_spawning(delta)
	_update_ui()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_map_click(get_global_mouse_position())
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			_cast_quake()
		elif event.keycode == KEY_1:
			_select_type("maw")
		elif event.keycode == KEY_2:
			_select_type("spore")
		elif event.keycode == KEY_3:
			_select_type("sigil")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Engine.time_scale = 1.0


func is_tower_selected(tower: Node) -> bool:
	return _get_selected_tower() == tower


func add_world_fx(fx: Node2D) -> void:
	fx_layer.add_child(fx)


func play_sfx(kind: String) -> void:
	if _audio:
		_audio.play_sfx(kind)


func _load_data() -> void:
	var data := _read_json("res://data/towers.json")
	_tower_defs = data.get("lairs", {})
	if _tower_defs.is_empty():
		_tower_defs = {
			"maw": { "name": "星光魔杖", "cost": 55, "damage": 18, "range": 150, "fire_rate": 0.62, "bullet_speed": 620, "upgrade_base": 46, "color": "#f97316" }
		}


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _apply_game_values() -> void:
	var values: Dictionary = PlayerSettingsScript.load_game_values()
	essence = int(values.get("coins", 999))
	heart = int(values.get("life", 12))
	corruption = float(values.get("star_power", 0))
	wave_index = int(values.get("start_wave", 1)) - 1


func _setup_layers() -> void:
	var background_path := "res://assets/images/xiaomox/backgrounds/magic_garden_map.png"
	if ResourceLoader.exists(background_path):
		var background_texture: Texture2D = load(background_path)
		if background_texture:
			_background = Sprite2D.new()
			_background.texture = background_texture
			_background.position = Vector2(640, 360)
			_background.scale = Vector2(1280.0 / background_texture.get_width(), 720.0 / background_texture.get_height())
			_background.z_index = -30
			add_child(_background)

	towers_layer = Node2D.new()
	towers_layer.name = "Lairs"
	add_child(towers_layer)

	enemies_layer = Node2D.new()
	enemies_layer.name = "Invaders"
	add_child(enemies_layer)

	bullets_layer = Node2D.new()
	bullets_layer.name = "Projectiles"
	add_child(bullets_layer)

	fx_layer = Node2D.new()
	fx_layer.name = "Effects"
	add_child(fx_layer)


func _setup_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	_life_value_label = _create_resource_pill(canvas, Vector2(12, 10), "res://assets/images/xiaomox/ui_icons_decor_clean/01_life_icon.png", "20")
	_coin_value_label = _create_resource_pill(canvas, Vector2(184, 10), "res://assets/images/xiaomox/ui_icons_decor_clean/02_coin_icon.png", "999")
	_rain_value_label = _create_resource_pill(canvas, Vector2(356, 10), "res://assets/images/xiaomox/ui_icons_decor_clean/03_star_icon.png", "0%")

	var wave_panel := Control.new()
	wave_panel.position = Vector2(12, 62)
	wave_panel.custom_minimum_size = Vector2(150, 78)
	canvas.add_child(wave_panel)
	_add_texture_rect(wave_panel, "res://assets/images/xiaomox/ui_generated/wave_panel.png", Vector2.ZERO, Vector2(150, 78))

	_wave_label = Label.new()
	_wave_label.position = Vector2(10, 10)
	_wave_label.size = Vector2(130, 24)
	_wave_label.add_theme_font_size_override("font_size", 16)
	_wave_label.add_theme_color_override("font_color", Color("#9f1239"))
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_panel.add_child(_wave_label)

	var status_panel := Control.new()
	status_panel.position = Vector2(166, 62)
	status_panel.custom_minimum_size = Vector2(430, 56)
	canvas.add_child(status_panel)
	_add_texture_rect(status_panel, "res://assets/images/xiaomox/ui_generated/status_panel.png", Vector2.ZERO, Vector2(430, 56))

	_status_label = Label.new()
	_status_label.position = Vector2(18, 12)
	_status_label.size = Vector2(394, 34)
	_status_label.text = "守护花园！"
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color("#9f1239"))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_panel.add_child(_status_label)

	_pause_button = _create_round_button(canvas, Vector2(1200, 18), 68, "Ⅱ", _toggle_pause)
	_speed_button = _create_round_button(canvas, Vector2(1200, 92), 68, "x1", _toggle_speed)
	_auto_button = _create_round_button(canvas, Vector2(1200, 166), 68, "自动", _toggle_auto_hint)
	_music_button = _create_round_button(canvas, Vector2(1118, 18), 68, "音乐", _toggle_music)
	_home_button = _create_round_button(canvas, Vector2(1118, 92), 68, "返回", _return_to_menu)

	var right := Control.new()
	right.position = Vector2(1008, 256)
	right.custom_minimum_size = Vector2(252, 406)
	canvas.add_child(right)
	_add_texture_rect(right, "res://assets/images/xiaomox/ui_generated/right_panel.png", Vector2.ZERO, Vector2(252, 406))

	_details_icon = TextureRect.new()
	_details_icon.position = Vector2(20, 22)
	_details_icon.size = Vector2(64, 64)
	_details_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_details_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right.add_child(_details_icon)

	_details_title_label = Label.new()
	_details_title_label.position = Vector2(94, 24)
	_details_title_label.size = Vector2(136, 44)
	_details_title_label.add_theme_font_size_override("font_size", 18)
	_details_title_label.add_theme_color_override("font_color", Color("#8b1f5f"))
	_details_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_details_title_label)

	_details_stats_label = Label.new()
	_details_stats_label.position = Vector2(24, 98)
	_details_stats_label.size = Vector2(204, 100)
	_details_stats_label.add_theme_font_size_override("font_size", 15)
	_details_stats_label.add_theme_color_override("font_color", Color("#7c2d12"))
	_details_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_details_stats_label)

	_add_texture_rect(right, "res://assets/images/xiaomox/ui_generated/skill_box.png", Vector2(20, 202), Vector2(212, 90))
	_details_skill_label = Label.new()
	_details_skill_label.position = Vector2(36, 216)
	_details_skill_label.size = Vector2(180, 64)
	_details_skill_label.add_theme_font_size_override("font_size", 13)
	_details_skill_label.add_theme_color_override("font_color", Color("#8b1f5f"))
	_details_skill_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_details_skill_label)

	_upgrade_button = Button.new()
	_upgrade_button.position = Vector2(17, 312)
	_upgrade_button.size = Vector2(218, 46)
	_upgrade_button.text = "升级"
	_style_action_button(_upgrade_button)
	_upgrade_button.pressed.connect(_upgrade_selected)
	right.add_child(_upgrade_button)

	_quake_button = Button.new()
	_quake_button.position = Vector2(17, 360)
	_quake_button.size = Vector2(218, 46)
	_quake_button.text = "星雨"
	_style_action_button(_quake_button)
	_quake_button.pressed.connect(_cast_quake)
	right.add_child(_quake_button)

	var bottom := Control.new()
	bottom.position = Vector2(54, 590)
	bottom.custom_minimum_size = Vector2(880, 120)
	canvas.add_child(bottom)
	_add_texture_rect(bottom, "res://assets/images/xiaomox/ui_generated/bottom_bar.png", Vector2.ZERO, Vector2(880, 120))

	var x := 18.0
	for type in ["maw", "spore", "sigil", "rainbow", "mascot", "moon", "love"]:
		_create_tower_card(bottom, Vector2(x, 10), type)
		x += 98.0

	_skill_button = _create_skill_button(canvas, Vector2(928, 616))


func _create_tower_card(parent: Control, pos: Vector2, type: String) -> void:
	var card_root := Control.new()
	card_root.position = pos
	card_root.custom_minimum_size = Vector2(92, 100)
	parent.add_child(card_root)

	var card_bg := _add_texture_rect(card_root, "res://assets/images/xiaomox/ui_generated/tower_card.png", Vector2.ZERO, Vector2(92, 100))
	_build_cards[type] = card_bg

	var icon := TextureRect.new()
	icon.position = Vector2(16, 8)
	icon.size = Vector2(60, 50)
	icon.texture = _tower_icon_for_type(type)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_root.add_child(icon)

	var name_label := Label.new()
	name_label.position = Vector2(8, 56)
	name_label.size = Vector2(76, 20)
	name_label.text = _short_tower_name(type)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color("#7c2d12"))
	card_root.add_child(name_label)
	_build_name_labels[type] = name_label

	_add_texture_rect(card_root, "res://assets/images/xiaomox/ui_generated/cost_badge.png", Vector2(11, 74), Vector2(70, 22))
	var coin_icon := TextureRect.new()
	coin_icon.position = Vector2(17, 77)
	coin_icon.size = Vector2(16, 16)
	coin_icon.texture = _ui_texture("res://assets/images/xiaomox/ui_icons_decor_clean/02_coin_icon.png")
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_root.add_child(coin_icon)

	var cost_label := Label.new()
	var def: Dictionary = _tower_defs.get(type, {})
	cost_label.position = Vector2(30, 76)
	cost_label.size = Vector2(46, 18)
	cost_label.text = "%d" % int(def.get("cost", 0))
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 13)
	cost_label.add_theme_color_override("font_color", Color("#ffffff"))
	card_root.add_child(cost_label)

	var button := Button.new()
	button.toggle_mode = true
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	_style_transparent_button(button)
	button.pressed.connect(_select_type.bind(type))
	card_root.add_child(button)
	_build_buttons[type] = button


func _create_resource_pill(canvas: CanvasLayer, pos: Vector2, icon_path: String, fallback_text: String) -> Label:
	var root := Control.new()
	root.position = pos
	root.custom_minimum_size = Vector2(168, 50)
	canvas.add_child(root)
	_add_texture_rect(root, "res://assets/images/xiaomox/ui_generated/resource_pill.png", Vector2.ZERO, Vector2(168, 50))

	var icon := TextureRect.new()
	icon.position = Vector2(12, 9)
	icon.size = Vector2(32, 32)
	icon.texture = _ui_texture(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(icon)

	var label := Label.new()
	label.position = Vector2(50, 8)
	label.size = Vector2(102, 34)
	label.text = fallback_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("#7c2d12"))
	root.add_child(label)
	return label


func _create_round_button(canvas: CanvasLayer, pos: Vector2, size: int, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.position = pos
	button.size = Vector2(size, size)
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_art_button(button, "res://assets/images/xiaomox/ui_generated/round_button.png", "res://assets/images/xiaomox/ui_generated/disabled_button.png")
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(callback)
	canvas.add_child(button)
	return button


func _create_skill_button(canvas: CanvasLayer, pos: Vector2) -> Button:
	var button := Button.new()
	button.position = pos
	button.size = Vector2(84, 84)
	button.text = "技能"
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_art_button(button, "res://assets/images/xiaomox/ui_generated/skill_round.png", "res://assets/images/xiaomox/ui_generated/round_button.png")
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(_cast_quake)
	canvas.add_child(button)
	return button


func _add_texture_rect(parent: Control, path: String, pos: Vector2, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.position = pos
	rect.size = size
	rect.texture = _ui_texture(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	parent.add_child(rect)
	return rect


func _ui_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _style_art_button(button: Button, normal_path: String, disabled_path: String = "") -> void:
	button.add_theme_stylebox_override("normal", _texture_style(normal_path))
	button.add_theme_stylebox_override("hover", _texture_style(normal_path))
	button.add_theme_stylebox_override("pressed", _texture_style(normal_path))
	button.add_theme_stylebox_override("disabled", _texture_style(disabled_path if disabled_path != "" else normal_path))
	button.add_theme_color_override("font_color", Color("#8b1f5f"))
	button.add_theme_color_override("font_hover_color", Color("#be123c"))
	button.add_theme_color_override("font_pressed_color", Color("#ffffff"))
	button.add_theme_color_override("font_disabled_color", Color("#9ca3af"))
	button.add_theme_font_size_override("font_size", 15)


func _style_action_button(button: Button) -> void:
	var path := "res://assets/images/xiaomox/ui_generated/gold_button.png"
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _texture_style(path))
	button.add_theme_stylebox_override("hover", _texture_style(path, Color("#fff7fd")))
	button.add_theme_stylebox_override("pressed", _texture_style(path, Color("#ffd6ea")))
	button.add_theme_stylebox_override("disabled", _texture_style(path, Color(1.0, 0.86, 0.93, 0.78)))
	button.add_theme_color_override("font_color", Color("#8b1f5f"))
	button.add_theme_color_override("font_hover_color", Color("#be123c"))
	button.add_theme_color_override("font_pressed_color", Color("#ffffff"))
	button.add_theme_color_override("font_disabled_color", Color("#b85a8b"))
	button.add_theme_font_size_override("font_size", 15)


func _texture_style(path: String, modulate: Color = Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = _ui_texture(path)
	style.draw_center = true
	style.modulate_color = modulate
	style.set_content_margin_all(4)
	return style


func _style_button(button: Button, fill: Color, border: Color) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _panel_style(fill, border, 16, 12, 8, 2))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#ffffff", 0.96), border, 16, 12, 8, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(border, Color("#ffffff", 0.88), 16, 12, 8, 2))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("#f3f4f6", 0.72), Color("#d1d5db", 0.75), 16, 12, 8, 1))
	button.add_theme_color_override("font_color", Color("#7c2d12"))
	button.add_theme_color_override("font_hover_color", Color("#9f1239"))
	button.add_theme_color_override("font_pressed_color", Color("#ffffff"))
	button.add_theme_color_override("font_disabled_color", Color("#9ca3af"))
	button.add_theme_font_size_override("font_size", 15)


func _style_transparent_button(button: Button) -> void:
	var clear := StyleBoxFlat.new()
	clear.bg_color = Color(1, 1, 1, 0)
	clear.border_color = Color(1, 1, 1, 0)
	clear.set_border_width_all(0)
	button.add_theme_stylebox_override("normal", clear)
	button.add_theme_stylebox_override("hover", clear)
	button.add_theme_stylebox_override("pressed", clear)
	button.add_theme_stylebox_override("disabled", clear)


func _tower_card_style(type: String, selected: bool, disabled: bool) -> StyleBoxFlat:
	var def: Dictionary = _tower_defs.get(type, {})
	var border := Color(str(def.get("color", "#f472b6")))
	border.a = 1.0 if selected else 0.58
	var fill := Color("#fff7ed", 0.96)
	if selected:
		fill = Color("#ffe4f7", 0.98)
	elif disabled:
		fill = Color("#f8fafc", 0.7)
		border = Color("#d1d5db", 0.78)
	return _panel_style(fill, border, 16, 8, 7, 2 if selected else 1)


func _tower_icon_for_type(type: String) -> Texture2D:
	var path := ""
	match type:
		"maw":
			path = "res://assets/images/xiaomox/towers_characters_clean/03_gold_star_tower.png"
		"spore":
			path = "res://assets/images/xiaomox/towers_characters_clean/02_blue_ice_tower.png"
		"sigil":
			path = "res://assets/images/xiaomox/towers_characters_clean/06_heart_lantern.png"
		"rainbow":
			path = "res://assets/images/xiaomox/towers_characters_clean/05_flower_spirit_tower.png"
		"mascot":
			path = "res://assets/images/xiaomox/towers_characters_clean/01_pink_magic_tower.png"
		"moon":
			path = "res://assets/images/xiaomox/towers_characters_clean/04_purple_moon_tower.png"
		"love":
			path = "res://assets/images/xiaomox/towers_characters_clean/07_star_crystal_tower.png"
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null


func _add_hot_button(canvas: CanvasLayer, rect: Rect2, callback: Callable) -> void:
	var button := Button.new()
	button.position = rect.position
	button.custom_minimum_size = rect.size
	button.size = rect.size
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.modulate = Color(1, 1, 1, 0.01)
	button.pressed.connect(callback)
	canvas.add_child(button)


func _panel_style(fill: Color, border: Color, radius: int = 8, margin_x: int = 12, margin_y: int = 10, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin_x
	style.content_margin_right = margin_x
	style.content_margin_top = margin_y
	style.content_margin_bottom = margin_y
	return style


func _setup_audio() -> void:
	_audio = AudioSystemScript.new()
	_audio.name = "AudioSystem"
	add_child(_audio)


func _handle_spawning(delta: float) -> void:
	if _spawn_left > 0:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_enemy()
			_spawn_left -= 1
			_spawn_timer = maxf(0.34, 0.88 - wave_index * 0.035)
		return

	if enemies.is_empty():
		_between_wave_timer -= delta
		if _between_wave_timer <= 0.0:
			_start_next_wave()


func _start_next_wave() -> void:
	wave_index += 1
	_spawn_left = 6 + wave_index * 3
	_spawn_timer = 0.25
	_between_wave_timer = 2.8
	_status_label.text = "新的捣蛋鬼来啦！第 %d 关。" % wave_index


func _spawn_enemy() -> void:
	var party_roll := (_spawn_left + wave_index) % 5
	var hp := 48.0 + wave_index * 13.0
	var speed := 88.0 + minf(38.0, wave_index * 3.5)
	var armor := 0.0
	var title := "Spark Blob"
	var reward := 8 + wave_index
	if party_roll == 0:
		title = "Shield Puff"
		hp *= 1.65
		speed *= 0.82
		armor = 5.0 + wave_index * 0.6
		reward += 5
	elif party_roll == 1:
		title = "Quick Star"
		hp *= 0.72
		speed *= 1.32
		reward += 2

	var enemy := EnemyScript.new()
	enemy.setup(_path_points, hp, speed, reward, title, armor)
	enemy.reached_goal.connect(_on_enemy_reached_goal)
	enemy.died.connect(_on_enemy_died)
	enemies_layer.add_child(enemy)
	enemies.append(enemy)


func _handle_map_click(mouse_position: Vector2) -> void:
	var spot := _find_nearest_spot(mouse_position, 46.0)
	if spot == -1:
		_selected_spot = -1
		return
	if _occupied_spots.has(spot):
		_selected_spot = spot
		_status_label.text = "已选择这座魔法塔。"
	else:
		_build_at(spot)


func _find_nearest_spot(mouse_position: Vector2, threshold: float) -> int:
	var best := -1
	var best_distance := 99999.0
	for i in range(_build_spots.size()):
		var distance := mouse_position.distance_to(_build_spots[i])
		if distance < best_distance:
			best = i
			best_distance = distance
	return best if best_distance <= threshold else -1


func _build_at(spot: int) -> void:
	var def: Dictionary = _tower_defs.get(_selected_type, {}).duplicate(true)
	def["name"] = _display_name_for_type(_selected_type)
	var cost := int(def.get("cost", 50))
	if essence < cost:
		_status_label.text = "星光能量不够。"
		return
	essence -= cost
	var tower := TowerScript.new()
	tower.global_position = _build_spots[spot]
	tower.setup(self, def, _selected_type)
	towers_layer.add_child(tower)
	_occupied_spots[spot] = tower
	_selected_spot = spot
	_spawn_fx(tower.global_position, Color(str(def.get("color", "#f97316"))), 18.0)
	play_sfx("build")
	_status_label.text = "%s 点亮啦。" % str(def.get("name", "魔法塔"))


func _select_type(type: String) -> void:
	_selected_type = type
	play_sfx("ui")
	_status_label.text = "选择了 %s。" % _display_name_for_type(type)


func _upgrade_selected() -> void:
	var tower := _get_selected_tower()
	if tower == null:
		_status_label.text = "先选择一个已经点亮的魔法塔。"
		return
	var cost: int = int(tower.get_upgrade_cost())
	if essence < cost:
		_status_label.text = "升级还需要 %d 星光能量。" % cost
		return
	essence -= cost
	tower.upgrade()
	_spawn_fx(tower.global_position, tower.tint, 22.0)
	play_sfx("upgrade")
	_status_label.text = "%s 升到 Lv.%d。" % [tower.display_name, tower.level]


func _cast_quake() -> void:
	if _quake_cooldown > 0.0:
		return
	if corruption < 45.0:
		_status_label.text = "星雨魔法需要 45 点星光。"
		return
	corruption -= 45.0
	_quake_cooldown = 8.0
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.take_damage(34.0 + wave_index * 4.0)
			_spawn_fx(enemy.global_position, Color("#f97316"), 14.0)
	play_sfx("quake")
	_status_label.text = "星雨魔法闪闪登场！"


func _toggle_speed() -> void:
	_game_speed = 2.0 if is_equal_approx(_game_speed, 1.0) else 1.0
	Engine.time_scale = _game_speed


func _toggle_pause() -> void:
	if is_equal_approx(Engine.time_scale, 0.0):
		Engine.time_scale = _game_speed
		_status_label.text = "继续守护花园。"
	else:
		Engine.time_scale = 0.0
		_status_label.text = "暂停中。"


func _toggle_auto_hint() -> void:
	play_sfx("ui")
	_status_label.text = "自动模式即将开放，目前请手动点亮塔位。"


func _toggle_music() -> void:
	if _audio:
		_audio.set_music_enabled(not _audio.music_enabled)
		play_sfx("ui")


func _return_to_menu() -> void:
	Engine.time_scale = 1.0
	play_sfx("ui")
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_enemy_reached_goal(enemy: Node) -> void:
	_remove_enemy(enemy)
	heart -= 1
	play_sfx("leak")
	_status_label.text = "有捣蛋鬼碰到水晶心了。"
	if heart <= 0:
		_reset_run()


func _on_enemy_died(enemy: Node, reward: int) -> void:
	essence += reward
	corruption = minf(100.0, corruption + 7.5)
	play_sfx("death")
	_remove_enemy(enemy)


func _remove_enemy(enemy: Node) -> void:
	enemies.erase(enemy)
	if is_instance_valid(enemy):
		enemy.queue_free()


func _reset_run() -> void:
	for enemy in enemies.duplicate():
		_remove_enemy(enemy)
	for child in towers_layer.get_children():
		child.queue_free()
	_occupied_spots.clear()
	_selected_spot = -1
	_apply_game_values()
	_spawn_left = 0
	_between_wave_timer = 1.0
	_status_label.text = "水晶心需要休息一下，花园重新开始。"


func _get_selected_tower() -> Node:
	if _selected_spot == -1 or not _occupied_spots.has(_selected_spot):
		return null
	var tower = _occupied_spots[_selected_spot]
	return tower if is_instance_valid(tower) else null


func _spawn_fx(where: Vector2, color: Color, radius: float) -> void:
	var fx := ImpactFxScript.new()
	fx.global_position = where
	fx.setup(color, radius, 0.5)
	fx_layer.add_child(fx)


func _update_ui() -> void:
	if _life_value_label:
		_life_value_label.text = "%d" % heart
	if _coin_value_label:
		_coin_value_label.text = "%d" % essence
	if _rain_value_label:
		_rain_value_label.text = "%d%%" % int(corruption)
	_wave_label.text = "第 %d 关" % wave_index

	for type in _build_buttons.keys():
		var def: Dictionary = _tower_defs.get(type, {})
		var cost := int(def.get("cost", 0))
		_build_buttons[type].disabled = essence < cost
		_build_buttons[type].button_pressed = type == _selected_type
		if _build_name_labels.has(type):
			_build_name_labels[type].text = _short_tower_name(type)
		if _build_cards.has(type):
			var card_path := "res://assets/images/xiaomox/ui_generated/tower_card.png"
			if essence < cost:
				card_path = "res://assets/images/xiaomox/ui_generated/tower_card_disabled.png"
			elif type == _selected_type:
				card_path = "res://assets/images/xiaomox/ui_generated/tower_card_selected.png"
			_build_cards[type].texture = _ui_texture(card_path)

	var tower := _get_selected_tower()
	if tower:
		var cost: int = int(tower.get_upgrade_cost())
		_details_icon.texture = _tower_icon_for_type(tower.archetype)
		_details_title_label.text = "%s\n等级 %d" % [_display_name_for_type(tower.archetype), tower.level]
		_details_stats_label.text = "攻击   %.0f\n范围   %.0f\n间隔   %.2fs" % [tower.damage, tower.attack_range, tower.fire_rate]
		_details_skill_label.text = "技能\n%s\n星雨可清理全场捣蛋鬼。" % _effect_text(tower.effect)
		_upgrade_button.disabled = essence < cost
		_upgrade_button.text = "升级 %d" % cost
	else:
		var def: Dictionary = _tower_defs.get(_selected_type, {})
		_details_icon.texture = _tower_icon_for_type(_selected_type)
		_details_title_label.text = "%s\n待建造" % _display_name_for_type(_selected_type)
		_details_stats_label.text = "攻击   %.0f\n范围   %.0f\n费用   %d" % [float(def.get("damage", 0)), float(def.get("range", 0)), int(def.get("cost", 0))]
		_details_skill_label.text = "提示\n点击空的星星塔位建造。\n空格或技能键释放星雨。"
		_upgrade_button.disabled = true
		_upgrade_button.text = "升级"

	_quake_button.disabled = corruption < 45.0 or _quake_cooldown > 0.0
	_quake_button.text = "星雨 %.0fs" % _quake_cooldown if _quake_cooldown > 0.0 else "星雨"
	_skill_button.disabled = _quake_button.disabled
	_skill_button.text = "冷却" if _quake_cooldown > 0.0 else "技能"
	_pause_button.text = "▶" if is_equal_approx(Engine.time_scale, 0.0) else "Ⅱ"
	_speed_button.text = "x%d" % int(_game_speed)
	_music_button.text = "音乐" if _audio and _audio.music_enabled else "静音"


func _short_tower_name(type: String) -> String:
	if _custom_tower_names.has(type):
		return str(_custom_tower_names[type])
	if PlayerSettingsScript.DEFAULT_TOWER_NAMES.has(type):
		return str(PlayerSettingsScript.DEFAULT_TOWER_NAMES[type])
	return str(type)


func _display_name_for_type(type: String) -> String:
	return _short_tower_name(type)


func _effect_text(effect: String) -> String:
	match effect:
		"slow":
			return "减速捣蛋鬼。"
		"bleed":
			return "造成持续星光伤害。"
		"shatter":
			return "削弱护甲。"
	return "普通魔法攻击。"


func _draw() -> void:
	if _background == null:
		_draw_fallback_board()
		_draw_fallback_path()
	_draw_sockets()
	_draw_vignette()


func _draw_fallback_board() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("#111018"))


func _draw_fallback_path() -> void:
	for index in range(_path_points.size() - 1):
		draw_line(_path_points[index], _path_points[index + 1], Color("#7c4a2d", 0.58), 28)


func _draw_sockets() -> void:
	for i in range(_build_spots.size()):
		var spot := _build_spots[i]
		var occupied := _occupied_spots.has(i)
		var selected := i == _selected_spot
		var hovered := i == _hovered_spot
		if occupied:
			if selected:
				draw_arc(spot, 43, 0.0, TAU, 64, Color("#fbbf24", 0.8), 2.5)
			continue

		var pulse := 0.5 + sin(Time.get_ticks_msec() / 240.0 + i) * 0.12
		var color := Color("#a855f7", 0.22 + pulse * 0.18)
		if hovered:
			color = Color("#f59e0b", 0.42)
		draw_circle(spot, 18, color)
		draw_arc(spot, 25, 0.0, TAU, 48, Color("#f5d0fe", 0.42), 1.2)


func _draw_vignette() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("#fff1f8", 0.04), false, 5.0)
