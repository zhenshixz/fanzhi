extends Node2D
class_name Enemy

const FloatingTextScript := preload("res://scripts/FloatingText.gd")
const FloatRigScript := preload("res://scripts/FloatRig.gd")

signal reached_goal(enemy: Enemy)
signal died(enemy: Enemy, reward: int)

var path_points: Array[Vector2] = []
var title := "Delver"
var max_hp := 50.0
var hp := 50.0
var speed := 90.0
var reward := 8
var armor := 0.0
var progress_distance := 0.0
var slow_timer := 0.0
var slow_multiplier := 1.0
var bleed_timer := 0.0
var bleed_damage := 0.0
var shatter_timer := 0.0
var armor_break := 0.0
var _dead := false

var _path_index := 0
var _rig: FloatRig
var _texture: Texture2D
var _wobble := 0.0


func setup(points: Array[Vector2], enemy_hp: float, enemy_speed: float, enemy_reward: int, enemy_title: String = "Delver", enemy_armor: float = 0.0) -> void:
	path_points = points
	title = enemy_title
	max_hp = enemy_hp
	hp = enemy_hp
	speed = enemy_speed
	reward = enemy_reward
	armor = enemy_armor
	_path_index = 1
	if not path_points.is_empty():
		global_position = path_points[0]


func _ready() -> void:
	z_index = 20
	if ResourceLoader.exists("res://assets/images/hero_invader_cutout.png"):
		_texture = load("res://assets/images/hero_invader_cutout.png")
	if _texture:
		_rig = FloatRigScript.new()
		_rig.setup(_texture, Vector2(0.044, 0.044), Color.WHITE if armor < 4.0 else Color("#fef3c7"), randf() * TAU)
		_rig.bob_amount = 3.0
		_rig.bob_speed = 4.0
		_rig.shadow_offset = Vector2(0, 18)
		add_child(_rig)
	queue_redraw()


func _process(delta: float) -> void:
	_tick_status(delta)
	if path_points.size() < 2 or _path_index >= path_points.size():
		return

	var target := path_points[_path_index]
	var to_target := target - global_position
	var step := speed * slow_multiplier * delta

	if to_target.length() <= step:
		progress_distance += to_target.length()
		global_position = target
		_path_index += 1
		if _path_index >= path_points.size():
			reached_goal.emit(self)
	else:
		progress_distance += step
		var direction := to_target.normalized()
		global_position += direction * step
		if _rig and _rig.sprite:
			_rig.sprite.flip_h = direction.x < -0.05


func take_damage(amount: float) -> void:
	if _dead:
		return
	var effective_armor := maxf(0.0, armor - armor_break)
	var final_damage := maxf(1.0, amount - effective_armor)
	hp -= final_damage
	_wobble = 1.0
	if _rig:
		_rig.punch()
	_spawn_damage_text(final_damage)
	queue_redraw()
	if hp <= 0.0:
		_dead = true
		died.emit(self, reward)


func apply_status(status: String, power: float, duration: float, status_color: Color) -> void:
	match status:
		"slow":
			slow_timer = maxf(slow_timer, duration)
			slow_multiplier = minf(slow_multiplier, clampf(1.0 - power, 0.28, 0.95))
		"bleed":
			bleed_timer = maxf(bleed_timer, duration)
			bleed_damage = maxf(bleed_damage, power)
		"shatter":
			shatter_timer = maxf(shatter_timer, duration)
			armor_break = maxf(armor_break, power)
	if _rig and _rig.sprite:
		_rig.sprite.modulate = _rig.sprite.modulate.lerp(status_color, 0.35)
	queue_redraw()


func _tick_status(delta: float) -> void:
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_multiplier = 1.0
	if shatter_timer > 0.0:
		shatter_timer -= delta
		if shatter_timer <= 0.0:
			armor_break = 0.0
	if bleed_timer > 0.0:
		bleed_timer -= delta
		hp -= bleed_damage * delta
		if hp <= 0.0:
			if _dead:
				return
			_dead = true
			died.emit(self, reward)


func _draw() -> void:
	if _wobble > 0.0:
		draw_circle(Vector2.ZERO, 24.0 + _wobble * 12.0, Color("#ef4444", 0.12 * _wobble))
		_wobble = maxf(0.0, _wobble - 0.08)
	if slow_timer > 0.0:
		draw_arc(Vector2.ZERO, 25, 0.0, TAU, 32, Color("#22c55e", 0.55), 1.5)
	if shatter_timer > 0.0:
		draw_arc(Vector2.ZERO, 29, 0.0, TAU, 32, Color("#a855f7", 0.55), 1.5)
	if bleed_timer > 0.0:
		draw_arc(Vector2.ZERO, 33, 0.0, TAU, 32, Color("#f97316", 0.55), 1.5)
	if _rig:
		_draw_health_bar(Vector2(-22, -32))
		return

	draw_circle(Vector2.ZERO, 19, Color("#8bd35c"))
	draw_circle(Vector2(7, -5), 6, Color("#f1ffd0"))
	draw_circle(Vector2(-6, -3), 4, Color("#f1ffd0"))
	_draw_health_bar(Vector2(-22, -32))


func _draw_health_bar(offset: Vector2) -> void:
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(offset, Vector2(44, 4)), Color("#111827", 0.75))
	draw_rect(Rect2(offset, Vector2(44 * ratio, 4)), Color("#f43f5e"))


func _spawn_damage_text(value: float) -> void:
	if not is_inside_tree():
		return
	var label := FloatingTextScript.new()
	label.global_position = global_position + Vector2(randf_range(-8.0, 8.0), -28.0)
	label.setup(str(int(round(value))), Color("#fde68a"), 0.55)
	get_tree().current_scene.add_child(label)
