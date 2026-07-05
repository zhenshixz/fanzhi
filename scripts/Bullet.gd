extends Node2D
class_name Bullet

const ImpactFxScript := preload("res://scripts/ImpactFx.gd")

var target: Enemy
var damage := 10.0
var speed := 500.0
var color := Color("#a855f7")
var effect := ""
var effect_power := 0.0
var effect_duration := 0.0

var _sprite: Sprite2D
var _texture: Texture2D
var _trail: Array[Vector2] = []


func setup(new_target: Enemy, bullet_damage: float, bullet_speed: float, bullet_color: Color = Color("#a855f7"), bullet_effect: String = "", power: float = 0.0, duration: float = 0.0) -> void:
	target = new_target
	damage = bullet_damage
	speed = bullet_speed
	color = bullet_color
	effect = bullet_effect
	effect_power = power
	effect_duration = duration


func _ready() -> void:
	z_index = 25
	if ResourceLoader.exists("res://assets/images/curse_orb_cutout.png"):
		_texture = load("res://assets/images/curse_orb_cutout.png")
	if _texture:
		_sprite = Sprite2D.new()
		_sprite.texture = _texture
		_sprite.scale = Vector2(0.028, 0.028)
		_sprite.modulate = Color(color, 0.9)
		add_child(_sprite)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var to_target := target.global_position - global_position
	var step := speed * delta
	if to_target.length() <= step:
		_spawn_impact(target.global_position)
		if get_tree().current_scene and get_tree().current_scene.has_method("play_sfx"):
			get_tree().current_scene.play_sfx("hit")
		target.take_damage(damage)
		if effect != "":
			target.apply_status(effect, effect_power, effect_duration, color)
		queue_free()
	else:
		_trail.append(global_position)
		if _trail.size() > 8:
			_trail.pop_front()
		global_position += to_target.normalized() * step
		rotation = to_target.angle()
	queue_redraw()


func _spawn_impact(effect_position: Vector2) -> void:
	var fx := ImpactFxScript.new()
	fx.global_position = effect_position
	fx.setup(color, 8.0, 0.34)
	get_tree().current_scene.add_child(fx)


func _draw() -> void:
	for i in range(_trail.size()):
		var local := to_local(_trail[i])
		var alpha := float(i + 1) / float(_trail.size() + 1)
		draw_circle(local, 4.0 * alpha, Color(color, 0.16 * alpha))
	if _sprite:
		draw_circle(Vector2.ZERO, 12, Color(color, 0.2))
		return
	draw_circle(Vector2.ZERO, 7, Color(color, 0.75))
	draw_circle(Vector2.ZERO, 2, Color("#fff8c2"))
