extends Node2D

const EnemyScript := preload("res://scripts/Enemy.gd")
const TowerScript := preload("res://scripts/Tower.gd")
const AudioSystemScript := preload("res://scripts/AudioSystem.gd")
const ImpactFxScript := preload("res://scripts/ImpactFx.gd")

var enemies: Array[Enemy] = []
var essence := 140
var heart := 12
var wave_index := 0
var corruption := 0.0

var towers_layer: Node2D
var enemies_layer: Node2D
var bullets_layer: Node2D
var fx_layer: Node2D

var _path_points: Array[Vector2] = [
	Vector2(-70, 372),
	Vector2(160, 374),
	Vector2(280, 260),
	Vector2(430, 320),
	Vector2(520, 500),
	Vector2(690, 562),
	Vector2(805, 420),
	Vector2(960, 310),
	Vector2(1080, 388),
	Vector2(1340, 410)
]

var _build_spots: Array[Vector2] = [
	Vector2(220, 250),
	Vector2(365, 405),
	Vector2(502, 205),
	Vector2(620, 600),
	Vector2(745, 340),
	Vector2(895, 500),
	Vector2(1032, 232),
	Vector2(1142, 515)
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
var _audio: AudioSystem
var _hud_label: Label
var _wave_label: Label
var _status_label: Label
var _details_label: Label
var _build_buttons: Dictionary = {}
var _upgrade_button: Button
var _quake_button: Button
var _speed_button: Button
var _music_button: Button


func _ready() -> void:
	Engine.time_scale = 1.0
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


func is_tower_selected(tower: Tower) -> bool:
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
			"maw": { "name": "Maw Lair", "cost": 55, "damage": 18, "range": 150, "fire_rate": 0.62, "bullet_speed": 620, "upgrade_base": 46, "color": "#f97316" }
		}


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _setup_layers() -> void:
	if ResourceLoader.exists("res://assets/images/dungeon_battlefield_v2.png"):
		_background = Sprite2D.new()
		_background.texture = load("res://assets/images/dungeon_battlefield_v2.png")
		_background.position = Vector2(640, 360)
		_background.scale = Vector2(1280.0 / _background.texture.get_width(), 720.0 / _background.texture.get_height())
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

	var top := PanelContainer.new()
	top.position = Vector2(18, 14)
	top.custom_minimum_size = Vector2(480, 94)
	top.add_theme_stylebox_override("panel", _panel_style(Color("#09090b", 0.72), Color("#f59e0b", 0.18)))
	canvas.add_child(top)

	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 5)
	top.add_child(top_box)

	_hud_label = Label.new()
	_hud_label.add_theme_font_size_override("font_size", 24)
	top_box.add_child(_hud_label)

	_wave_label = Label.new()
	_wave_label.add_theme_font_size_override("font_size", 15)
	top_box.add_child(_wave_label)

	_status_label = Label.new()
	_status_label.text = "Choose a lair, claim a socket, break the heroes before they reach the heart."
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_box.add_child(_status_label)

	var right := PanelContainer.new()
	right.position = Vector2(980, 18)
	right.custom_minimum_size = Vector2(280, 178)
	right.add_theme_stylebox_override("panel", _panel_style(Color("#09090b", 0.68), Color("#a855f7", 0.22)))
	canvas.add_child(right)

	var right_box := VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 8)
	right.add_child(right_box)

	_details_label = Label.new()
	_details_label.add_theme_font_size_override("font_size", 15)
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_box.add_child(_details_label)

	_upgrade_button = Button.new()
	_upgrade_button.text = "Upgrade"
	_upgrade_button.pressed.connect(_upgrade_selected)
	right_box.add_child(_upgrade_button)

	_quake_button = Button.new()
	_quake_button.text = "Cave-In"
	_quake_button.pressed.connect(_cast_quake)
	right_box.add_child(_quake_button)

	var bottom := PanelContainer.new()
	bottom.position = Vector2(230, 622)
	bottom.custom_minimum_size = Vector2(820, 82)
	bottom.add_theme_stylebox_override("panel", _panel_style(Color("#09090b", 0.76), Color("#fef3c7", 0.14)))
	canvas.add_child(bottom)

	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 10)
	bottom.add_child(bottom_row)

	for type in ["maw", "spore", "sigil"]:
		var button := Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(160, 56)
		button.pressed.connect(_select_type.bind(type))
		_build_buttons[type] = button
		bottom_row.add_child(button)

	_speed_button = Button.new()
	_speed_button.custom_minimum_size = Vector2(92, 56)
	_speed_button.pressed.connect(_toggle_speed)
	bottom_row.add_child(_speed_button)

	_music_button = Button.new()
	_music_button.custom_minimum_size = Vector2(92, 56)
	_music_button.pressed.connect(_toggle_music)
	bottom_row.add_child(_music_button)


func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
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
	_status_label.text = "A new party enters the mine. Wave %d." % wave_index


func _spawn_enemy() -> void:
	var party_roll := (_spawn_left + wave_index) % 5
	var hp := 48.0 + wave_index * 13.0
	var speed := 88.0 + minf(38.0, wave_index * 3.5)
	var armor := 0.0
	var title := "Delver"
	var reward := 8 + wave_index
	if party_roll == 0:
		title = "Knight"
		hp *= 1.65
		speed *= 0.82
		armor = 5.0 + wave_index * 0.6
		reward += 5
	elif party_roll == 1:
		title = "Scout"
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
		_status_label.text = "Socket selected."
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
	var def: Dictionary = _tower_defs.get(_selected_type, {})
	var cost := int(def.get("cost", 50))
	if essence < cost:
		_status_label.text = "Not enough essence."
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
	_status_label.text = "%s awakened." % str(def.get("name", "Lair"))


func _select_type(type: String) -> void:
	_selected_type = type
	play_sfx("ui")
	_status_label.text = "%s selected." % str(_tower_defs.get(type, {}).get("name", "Lair"))


func _upgrade_selected() -> void:
	var tower := _get_selected_tower()
	if tower == null:
		_status_label.text = "Select a socket with a lair first."
		return
	var cost := tower.get_upgrade_cost()
	if essence < cost:
		_status_label.text = "Need %d essence for that upgrade." % cost
		return
	essence -= cost
	tower.upgrade()
	_spawn_fx(tower.global_position, tower.tint, 22.0)
	play_sfx("upgrade")
	_status_label.text = "%s reaches level %d." % [tower.display_name, tower.level]


func _cast_quake() -> void:
	if _quake_cooldown > 0.0:
		return
	if corruption < 45.0:
		_status_label.text = "Cave-In needs 45 corruption."
		return
	corruption -= 45.0
	_quake_cooldown = 8.0
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.take_damage(34.0 + wave_index * 4.0)
			_spawn_fx(enemy.global_position, Color("#f97316"), 14.0)
	play_sfx("quake")
	_status_label.text = "The ceiling answers."


func _toggle_speed() -> void:
	_game_speed = 2.0 if is_equal_approx(_game_speed, 1.0) else 1.0
	Engine.time_scale = _game_speed


func _toggle_music() -> void:
	if _audio:
		_audio.set_music_enabled(not _audio.music_enabled)
		play_sfx("ui")


func _on_enemy_reached_goal(enemy: Enemy) -> void:
	_remove_enemy(enemy)
	heart -= 1
	play_sfx("leak")
	_status_label.text = "A hero found the demon heart."
	if heart <= 0:
		_reset_run()


func _on_enemy_died(enemy: Enemy, reward: int) -> void:
	essence += reward
	corruption = minf(100.0, corruption + 7.5)
	play_sfx("death")
	_remove_enemy(enemy)


func _remove_enemy(enemy: Enemy) -> void:
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
	essence = 140
	heart = 12
	wave_index = 0
	corruption = 0.0
	_spawn_left = 0
	_between_wave_timer = 1.0
	_status_label.text = "The heart was breached. The dungeon reforms."


func _get_selected_tower() -> Tower:
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
	_hud_label.text = "Essence %d   Heart %d   Corruption %d%%" % [essence, heart, int(corruption)]
	_wave_label.text = "Wave %d   Heroes alive %d   Next group %d" % [wave_index, enemies.size(), _spawn_left]

	for type in _build_buttons.keys():
		var def: Dictionary = _tower_defs.get(type, {})
		var cost := int(def.get("cost", 0))
		var label := "%s\n%d essence" % [str(def.get("name", type)), cost]
		_build_buttons[type].text = label
		_build_buttons[type].disabled = essence < cost
		_build_buttons[type].button_pressed = type == _selected_type

	var tower := _get_selected_tower()
	if tower:
		var cost := tower.get_upgrade_cost()
		_details_label.text = "%s Lv%d\nDamage %.0f  Range %.0f\nRate %.2fs  Upgrade %d" % [tower.display_name, tower.level, tower.damage, tower.attack_range, tower.fire_rate, cost]
		_upgrade_button.disabled = essence < cost
		_upgrade_button.text = "Upgrade %d" % cost
	else:
		var def: Dictionary = _tower_defs.get(_selected_type, {})
		_details_label.text = "Build: %s\nClick an empty glowing socket.\nSpace: Cave-In at 45 corruption." % str(def.get("name", "Lair"))
		_upgrade_button.disabled = true
		_upgrade_button.text = "Upgrade"

	_quake_button.disabled = corruption < 45.0 or _quake_cooldown > 0.0
	_quake_button.text = "Cave-In %.0fs" % _quake_cooldown if _quake_cooldown > 0.0 else "Cave-In"
	_speed_button.text = "x%d" % int(_game_speed)
	_music_button.text = "Music On" if _audio and _audio.music_enabled else "Music Off"


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
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color("#020617", 0.08), false, 8.0)
