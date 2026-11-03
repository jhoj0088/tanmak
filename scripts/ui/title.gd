extends Node2D
## 타이틀 화면
const P = preload("res://scripts/art/palette.gd")

var main: Node
var sel := 0
var t := 0.0
var chosen := false
var options: Array = []


func _ready() -> void:
	options = ["새 게임", "난이도", "개발자 모드"]
	if Game.has_save():
		options = ["이어하기", "새 게임", "난이도", "개발자 모드"]


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if chosen or t < 0.5:
		return
	if Input.is_action_just_pressed("move_up"):
		sel = (sel - 1 + options.size()) % options.size()
		Snd.play("move")
	elif Input.is_action_just_pressed("move_down"):
		sel = (sel + 1) % options.size()
		Snd.play("move")
	elif Input.is_action_just_pressed("confirm"):
		Snd.play("select")
		if options[sel] == "난이도":
			Game.set_easy(not Game.easy)
			return
		if options[sel] == "개발자 모드":
			Game.set_dev(not Game.dev)
			return
		chosen = true
		if options[sel] == "이어하기":
			main.continue_game()
		else:
			main.start_new_game()


func _draw() -> void:
	var f: Font = Game.font
	# 밤하늘 (위로 갈수록 짙게)
	for i in 18:
		draw_rect(Rect2(0, i * 24, 640, 24), P.NIGHT_950.lerp(P.NIGHT_900, i / 18.0))
	for i in 70:
		var x := float((i * 197) % 640)
		var y := float((i * 89) % 230)
		var tw := 0.5 + 0.5 * sin(t * (1.0 + (i % 5) * 0.4) + i)
		draw_rect(Rect2(x, y, 2 if i % 9 == 0 else 1, 2 if i % 9 == 0 else 1), Color(P.UI_INK, 0.25 + 0.6 * tw))
	draw_circle(Vector2(560, 60), 18, P.PAPER)
	draw_circle(Vector2(553, 55), 16, P.NIGHT_950)
	# 운동장 (천연 잔디) + 골대
	draw_rect(Rect2(0, 410, 640, 70), P.BENCH_700.darkened(0.5))
	for i in 8:
		draw_rect(Rect2(i * 80, 410, 40, 70), P.BENCH_700.darkened(0.4))
	draw_line(Vector2(40, 440), Vector2(40, 418), P.WALL_500, 2)
	draw_line(Vector2(40, 418), Vector2(80, 418), P.WALL_500, 2)
	draw_line(Vector2(80, 418), Vector2(80, 440), P.WALL_500, 2)
	var base := P.UI_BG
	var edge := P.NIGHT_900
	# 기숙사 (뒤쪽 오른편)
	draw_rect(Rect2(500, 280, 120, 130), P.UI_BG)
	for fl in 5:
		for i in 6:
			var lit := (i * 5 + fl * 7) % 9 == 0
			draw_rect(Rect2(508 + i * 18, 288 + fl * 24, 8, 10), Color(P.UI_ACCENT, 0.8) if lit else P.NIGHT_900)
	# S동 (왼쪽) + 천문대 돔
	draw_rect(Rect2(60, 240, 230, 170), base)
	draw_rect(Rect2(60, 240, 230, 3), edge)
	draw_rect(Rect2(110, 214, 60, 26), base)
	draw_circle(Vector2(140, 214), 26, base)
	draw_arc(Vector2(140, 214), 26, PI, TAU, 20, edge, 2)
	var slit := 0.3 + 0.2 * sin(t * 0.5)
	draw_line(Vector2(140, 189), Vector2(140 + cos(slit) * 6, 205), Color(P.UI_ACCENT_2, 0.6), 2)
	# A동 (오른쪽) + 연결 다리
	draw_rect(Rect2(330, 250, 170, 160), base)
	draw_rect(Rect2(330, 250, 170, 3), edge)
	draw_rect(Rect2(290, 330, 40, 22), P.NIGHT_900)
	draw_rect(Rect2(290, 333, 40, 6), Color(P.BLUE_500, 0.4))
	for fl in 5:
		for i in 9:
			var lit2 := (i * 7 + fl * 13) % 11 == 0 or (fl == 0 and i == 1)
			var flick := lit2 and sin(t * 3.0 + i) > -0.6
			draw_rect(Rect2(72 + i * 24, 256 + fl * 30, 14, 16), Color(P.UI_ACCENT, 0.9) if flick else P.NIGHT_900)
		for i in 6:
			var lit3 := (i * 3 + fl * 5) % 7 == 0
			draw_rect(Rect2(342 + i * 26, 264 + fl * 28, 14, 14), Color(P.SKY_100, 0.85) if lit3 else P.NIGHT_900)
	# 연못과 분수
	draw_colored_polygon(PackedVector2Array([Vector2(200, 430), Vector2(300, 424), Vector2(330, 440), Vector2(260, 456), Vector2(190, 448)]), P.NIGHT_900)
	draw_line(Vector2(255, 438), Vector2(255, 428), Color(P.SKY_100, 0.5), 1)
	draw_string(f, Vector2(0, 120), "탄막 RPG", HORIZONTAL_ALIGNMENT_CENTER, 640, 72, P.UI_INK)
	draw_string(f, Vector2(0, 162), "- 융합 프로토콜 -", HORIZONTAL_ALIGNMENT_CENTER, 640, Game.FL, P.SKY_100)
	for i in options.size():
		var col := P.UI_ACCENT if i == sel else P.UI_INK
		var y := 330 + i * 32
		draw_rect(Rect2(160, y - 26, 320, 34), Color(P.UI_BG, 0.75))
		var label: String = options[i]
		if label == "난이도":
			label = "난이도: 쉬움" if Game.easy else "난이도: 보통"
		elif label == "개발자 모드":
			label = "개발자 모드: 켜짐 (F1)" if Game.dev else "개발자 모드: 꺼짐"
		draw_string(f, Vector2(0, y), label, HORIZONTAL_ALIGNMENT_CENTER, 640, Game.FL, col)
		if i == sel:
			draw_string(f, Vector2(168, y), "♥", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, P.UI_SIGNAL)
	var cl: Dictionary = Game.clears()
	if cl.has("true") or cl.has("normal") or cl.has("bad"):
		var marks := ""
		for pair in [["true", "TRUE"], ["normal", "NORMAL"], ["bad", "BAD"]]:
			marks += ("★ " if cl.has(pair[0]) else "☆ ") + pair[1] + "   "
		draw_string(f, Vector2(0, 196), "본 결말:  " + marks.strip_edges(), HORIZONTAL_ALIGNMENT_CENTER, 640, Game.FS, P.UI_ACCENT)
	draw_string(f, Vector2(0, 466), "패드: 이동   Z: 확인   X: 취소·폭탄   C: 메뉴   S: 정밀 이동" if Touch.enabled else "방향키: 이동   Z: 확인   X: 취소   C: 메뉴   Shift: 정밀 이동", HORIZONTAL_ALIGNMENT_CENTER, 640, Game.FS, P.UI_MUTED)
