extends Node2D
## 터치 패드와 버튼 그리기 (scripts/mobile/touch.gd 가 만든다)
const P = preload("res://scripts/art/palette.gd")

var touch: Node


func _draw() -> void:
	if touch == null:
		return
	var f: Font = Game.font
	var a := 0.45 if touch.overlay else 1.0
	# 방향 패드
	var c: Vector2 = touch.pad_c
	var r: float = touch.pad_r
	draw_circle(c, r, Color(P.UI_INK, 0.07 * a + 0.03))
	draw_arc(c, r, 0, TAU, 48, Color(P.UI_INK, 0.35 * a), 2.0)
	var d: Vector2 = touch.pad_dir
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var on: bool = (dir.x != 0 and dir.x == d.x) or (dir.y != 0 and dir.y == d.y)
		var tip: Vector2 = c + dir * r * 0.78
		var side := Vector2(-dir.y, dir.x) * r * 0.16
		var base: Vector2 = c + dir * r * 0.5
		draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]),
			Color(P.UI_ACCENT, a) if on else Color(P.UI_INK, 0.5 * a))
	var knob: Vector2 = touch.pad_knob if touch.touches.values().has("pad") else c
	draw_circle(knob, r * 0.3, Color(P.UI_INK, 0.18 * a + 0.05))
	# 버튼
	for n in touch.buttons:
		var b: Dictionary = touch.buttons[n]
		var p: Vector2 = b["pos"]
		var br: float = b["r"]
		var on: bool = touch.pressed.has(n) or (n == "focus" and touch.focus_on)
		var col := P.UI_ACCENT if n == "confirm" else (P.SKY_100 if n == "cancel" else P.UI_MUTED)
		draw_circle(p, br, Color(col.r, col.g, col.b, (0.55 if on else 0.14) * a))
		draw_arc(p, br, 0, TAU, 40, Color(col.r, col.g, col.b, 0.8 * a), 2.0)
		var ks := Game.FL if br >= 34 else Game.FS
		draw_string(f, p + Vector2(-br, ks * 0.35), b["key"], HORIZONTAL_ALIGNMENT_CENTER, br * 2, ks, Color(P.UI_INK, 0.95 * a))
		draw_string(f, p + Vector2(-60, br + Game.FS + 3), b["label"], HORIZONTAL_ALIGNMENT_CENTER, 120, Game.FS, Color(P.UI_MUTED, 0.85 * a))
