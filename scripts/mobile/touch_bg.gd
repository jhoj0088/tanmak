extends Node2D
## 터치 모드에서 게임 화면 바깥(남는 자리)의 배경
const P = preload("res://scripts/art/palette.gd")

var touch: Node


func _ready() -> void:
	get_tree().root.size_changed.connect(queue_redraw)


func _draw() -> void:
	var vr := get_viewport().get_visible_rect().size
	draw_rect(Rect2(Vector2.ZERO, vr), P.NIGHT_950)
	# 은은한 모눈
	var g := 32.0
	var x := 0.0
	while x < vr.x:
		draw_line(Vector2(x, 0), Vector2(x, vr.y), Color(P.UI_INK, 0.025), 1)
		x += g
	var y := 0.0
	while y < vr.y:
		draw_line(Vector2(0, y), Vector2(vr.x, y), Color(P.UI_INK, 0.025), 1)
		y += g
	if touch:
		var r: Rect2 = touch.game_rect
		draw_rect(r.grow(2), Color(P.UI_LINE, 0.6), false, 2.0)
