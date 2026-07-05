extends Node2D
class_name FloatRig

var bob_amount := 5.0
var bob_speed := 2.3
var tilt_amount := 0.035
var shadow_scale := Vector2(1.0, 0.32)
var shadow_offset := Vector2(0, 22)
var base_scale := Vector2.ONE
var flash_color := Color.WHITE

var sprite: Sprite2D
var shadow: Polygon2D

var _phase := 0.0
var _flash := 0.0


func setup(texture: Texture2D, scale: Vector2, tint: Color = Color.WHITE, phase_offset: float = 0.0) -> void:
	_phase = phase_offset
	base_scale = scale
	shadow = Polygon2D.new()
	shadow.polygon = PackedVector2Array([
		Vector2(-44, -12), Vector2(44, -12), Vector2(56, 0),
		Vector2(44, 12), Vector2(-44, 12), Vector2(-56, 0)
	])
	shadow.position = shadow_offset
	shadow.scale = shadow_scale
	shadow.color = Color("#020617", 0.38)
	add_child(shadow)

	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = scale
	sprite.modulate = tint
	add_child(sprite)


func punch() -> void:
	_flash = 1.0


func _process(delta: float) -> void:
	_phase += delta * bob_speed
	_flash = maxf(0.0, _flash - delta * 5.5)
	if sprite == null or shadow == null:
		return

	var bob := sin(_phase) * bob_amount
	sprite.position.y = -8.0 + bob
	sprite.rotation = sin(_phase * 0.72) * tilt_amount
	sprite.scale = base_scale * (1.0 + _flash * 0.06)
	sprite.modulate = sprite.modulate.lerp(flash_color, _flash * 0.45)

	var squash := 1.0 - bob / maxf(20.0, bob_amount * 5.0)
	shadow.scale = Vector2(shadow_scale.x * squash, shadow_scale.y * (1.0 / squash))
	shadow.color = Color("#020617", 0.28 + _flash * 0.16)
