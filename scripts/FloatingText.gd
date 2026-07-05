extends Node2D
class_name FloatingText

var text := ""
var color := Color.WHITE
var life := 0.8

var _age := 0.0
var _font := ThemeDB.fallback_font


func setup(value: String, text_color: Color, duration: float = 0.8) -> void:
	text = value
	color = text_color
	life = duration


func _process(delta: float) -> void:
	_age += delta
	position.y -= 34.0 * delta
	queue_redraw()
	if _age >= life:
		queue_free()


func _draw() -> void:
	var t := clampf(_age / life, 0.0, 1.0)
	var draw_color := Color(color, 1.0 - t)
	draw_string(_font, Vector2(-18, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, draw_color)
