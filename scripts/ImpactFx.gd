extends Node2D
class_name ImpactFx

var color := Color("#a855f7")
var life := 0.35
var radius := 8.0

var _age := 0.0


func setup(effect_color: Color, start_radius: float = 8.0, duration: float = 0.35) -> void:
	color = effect_color
	radius = start_radius
	life = duration


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= life:
		queue_free()


func _draw() -> void:
	var t := clampf(_age / life, 0.0, 1.0)
	var alpha := 1.0 - t
	draw_circle(Vector2.ZERO, radius + t * 30.0, Color(color, 0.14 * alpha))
	draw_arc(Vector2.ZERO, radius + t * 24.0, 0.0, TAU, 40, Color(color, 0.75 * alpha), 2.0)
	draw_circle(Vector2.ZERO, maxf(2.0, 5.0 * alpha), Color("#fff7ed", 0.7 * alpha))
