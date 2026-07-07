extends Node2D
class_name Tower

const BulletScript := preload("res://scripts/Bullet.gd")
const FloatRigScript := preload("res://scripts/FloatRig.gd")

var game: Node
var archetype := "maw"
var display_name := "魔法塔"
var tint := Color("#f97316")
var damage := 18.0
var attack_range := 170.0
var fire_rate := 0.85
var bullet_speed := 520.0
var level := 1
var upgrade_base := 45
var effect := ""
var effect_power := 0.0
var effect_duration := 0.0

var _cooldown := 0.0
var _rig: Node2D
var _texture: Texture2D
var _charge := 0.0


func setup(owner_game: Node, stats: Dictionary, tower_type: String = "maw") -> void:
	game = owner_game
	archetype = tower_type
	display_name = str(stats.get("name", display_name))
	tint = Color(str(stats.get("color", "#f97316")))
	damage = float(stats.get("damage", damage))
	attack_range = float(stats.get("range", attack_range))
	fire_rate = float(stats.get("fire_rate", fire_rate))
	bullet_speed = float(stats.get("bullet_speed", bullet_speed))
	upgrade_base = int(stats.get("upgrade_base", upgrade_base))
	effect = str(stats.get("effect", ""))
	effect_power = float(stats.get("effect_power", 0.0))
	effect_duration = float(stats.get("effect_duration", 0.0))


func _ready() -> void:
	z_index = 15
	var texture_path := _texture_path_for_type()
	if ResourceLoader.exists(texture_path):
		_texture = load(texture_path)
	if _texture:
		_rig = FloatRigScript.new()
		_rig.setup(_texture, _texture_scale_for_type(), Color(tint, 0.95), randf() * TAU)
		_rig.bob_amount = 4.0
		_rig.bob_speed = 1.65
		add_child(_rig)
	queue_redraw()


func _texture_path_for_type() -> String:
	match archetype:
		"maw":
			return "res://assets/images/xiaomox/towers_characters_clean/03_gold_star_tower.png"
		"spore":
			return "res://assets/images/xiaomox/towers_characters_clean/02_blue_ice_tower.png"
		"sigil":
			return "res://assets/images/xiaomox/towers_characters_clean/06_heart_lantern.png"
		"rainbow":
			return "res://assets/images/xiaomox/towers_characters_clean/05_flower_spirit_tower.png"
		"mascot":
			return "res://assets/images/xiaomox/towers_characters_clean/01_pink_magic_tower.png"
		"moon":
			return "res://assets/images/xiaomox/towers_characters_clean/04_purple_moon_tower.png"
		"love":
			return "res://assets/images/xiaomox/towers_characters_clean/07_star_crystal_tower.png"
	return "res://assets/images/xiaomox/towers_characters_clean/03_gold_star_tower.png"


func _texture_scale_for_type() -> Vector2:
	match archetype:
		"maw":
			return Vector2(0.92, 0.92)
		"spore":
			return Vector2(1.02, 1.02)
		"sigil":
			return Vector2(0.88, 0.88)
		"rainbow":
			return Vector2(0.82, 0.82)
		"mascot":
			return Vector2(1.02, 1.02)
		"moon":
			return Vector2(0.98, 0.98)
		"love":
			return Vector2(0.82, 0.82)
	return Vector2(0.95, 0.95)


func _process(delta: float) -> void:
	_charge = maxf(0.0, _charge - delta * 3.0)
	_cooldown -= delta
	if _cooldown > 0.0:
		return

	var target := _find_target()
	if target:
		_fire(target)
		_cooldown = fire_rate


func _find_target() -> Node:
	var best: Node
	var best_progress := -INF
	for enemy in game.enemies:
		if not is_instance_valid(enemy):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= attack_range and enemy.progress_distance > best_progress:
			best = enemy
			best_progress = enemy.progress_distance
	return best


func _fire(target: Node) -> void:
	var bullet := BulletScript.new()
	bullet.global_position = global_position
	bullet.setup(target, damage, bullet_speed, tint, effect, effect_power + level * 0.6, effect_duration)
	game.bullets_layer.add_child(bullet)
	if game.has_method("play_sfx"):
		game.play_sfx("shot")
	_charge = 1.0
	if _rig:
		_rig.punch()


func get_upgrade_cost() -> int:
	return int(round(upgrade_base * pow(1.65, level - 1)))


func upgrade() -> void:
	level += 1
	damage *= 1.34
	attack_range += 12.0
	fire_rate = maxf(0.35, fire_rate * 0.92)
	if _rig:
		_rig.base_scale = _texture_scale_for_type() * (1.0 + minf(0.18, level * 0.035))
		_rig.punch()
	queue_redraw()


func _draw() -> void:
	var selected: bool = game != null and game.is_tower_selected(self)
	if selected:
		draw_circle(Vector2.ZERO, attack_range, Color(tint, 0.08))
		draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 96, Color(tint, 0.38), 2)
	if _charge > 0.0:
		draw_circle(Vector2.ZERO, 34.0 + _charge * 18.0, Color(tint, 0.12 * _charge))
	if _rig:
		draw_string(ThemeDB.fallback_font, Vector2(-15, 43), "Lv%d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#fef3c7"))
		return
	draw_circle(Vector2.ZERO, 25, Color("#6b4f2a"))
	draw_circle(Vector2(0, -9), 21, Color("#47b881"))
	draw_circle(Vector2(0, -9), 10, Color("#b8f2c2"))
