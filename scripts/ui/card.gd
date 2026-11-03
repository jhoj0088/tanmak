extends Node2D
## 챕터 카드 (검은 화면에 큰 글씨). main.show_card() 가 사용한다.
const P = preload("res://scripts/art/palette.gd")

signal done
var big := ""
var small := ""
var t := 0.0
var dur := 0.0
var active := false
var finished := true
var backdrop_only := false     # 기억 장면: 검은 바탕 + 위쪽 작은 제목만


func start(b: String, s: String, sec: float) -> void:
	big = b
	small = s
	t = 0.0
	dur = sec
	active = true
	finished = false


func stop() -> void:
	active = false
	queue_redraw()


func _process(delta: float) -> void:
	if not active:
		return
	queue_redraw()
	if finished:
		return
	t += delta
	if t >= dur or (t > 0.8 and Input.is_action_just_pressed("confirm")):
		finished = true
		done.emit()


func _draw() -> void:
	if not active:
		return
	draw_rect(Rect2(0, 0, 640, 480), P.UI_BG)
	var f: Font = Game.font
	if backdrop_only:
		for i in 30:
			var a := 0.15 + 0.15 * sin(t * 0.8 + i)
			draw_rect(Rect2(float((i * 211) % 640), float((i * 97) % 300), 1, 1), Color(P.UI_INK, a))
		draw_string(f, Vector2(0, 90), small, HORIZONTAL_ALIGNMENT_CENTER, 640, Game.FS, P.UI_MUTED)
		return
	draw_string(f, Vector2(0, 200), small, HORIZONTAL_ALIGNMENT_CENTER, 640, Game.FL, P.SKY_100)
	draw_string(f, Vector2(0, 256), big, HORIZONTAL_ALIGNMENT_CENTER, 640, 36, P.UI_INK)
	draw_line(Vector2(200, 280), Vector2(200 + 240 * clampf(t / 1.2, 0, 1), 280), P.UI_INK, 2)
