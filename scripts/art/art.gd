extends RefCounted
## 모든 캐릭터 그림을 코드로 그린다 (이미지 파일 없이 바로 실행되도록).
## 나중에 진짜 그림(.png)이 생기면 여기 함수 대신 Sprite2D 를 쓰면 된다.
##
## 전투용 그림은  draw_이름(ci, 위치, 시간, 크기, 번쩍임, 투명도)  형태로 통일했다.


static func _c(c: Color, white: bool, alpha: float) -> Color:
	var r := Color.WHITE if white else c
	r.a = c.a * alpha
	return r


static func _oval(ci: CanvasItem, center: Vector2, rx: float, ry: float, col: Color, n := 20) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)


static func _shadow(ci: CanvasItem, rx: float) -> void:
	_oval(ci, Vector2.ZERO, rx, rx * 0.35, Color(0, 0, 0, 0.3), 12)


static func heart_points(size: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var k := size / 16.0
	for i in 32:
		var a := TAU * i / 32.0
		var x := 16.0 * pow(sin(a), 3)
		var y := -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))
		pts.append(Vector2(x, y - 2.5) * k)
	return pts


static func draw_heart(ci: CanvasItem, pos: Vector2, size: float, col: Color) -> void:
	var pts := heart_points(size)
	for i in pts.size():
		pts[i] += pos
	ci.draw_colored_polygon(pts, col)


# ================================================================ 필드용
## 방 데이터의 "look" 값에 따라 그린다. (0,0) = 발 위치.
static func draw_look(ci: CanvasItem, look: String, t: float, info: Dictionary) -> void:
	match look:
		"namoji":
			_shadow(ci, 8)
			draw_namoji(ci, Vector2(0, -26 + sin(t * 3.0) * 3.0), t, 1.0)
		"redpen", "gil":
			_shadow(ci, 12)
			draw_redpen(ci, Vector2(0, -24), t, 0.42)
		"empty_set":
			_shadow(ci, 12)
			draw_empty_set(ci, Vector2(0, -26 + sin(t * 2.0) * 2.0), t, 0.45)
		"venn":
			_shadow(ci, 16)
			draw_venn(ci, Vector2(0, -22 + sin(t * 2.0) * 2.0), t, 0.45)
		"swan":
			_shadow(ci, 14)
			draw_swan(ci, Vector2(0, -16), t, 0.5)
		"owl", "alien":
			_shadow(ci, 14)
			draw_alien(ci, Vector2(0, -30), t, 0.42)
		"flies":
			draw_flies(ci, Vector2(0, -22), t, 0.5)
		"butterfly":
			_shadow(ci, 12)
			draw_butterfly(ci, Vector2(0, -24), t, 0.45)
		"virus":
			_shadow(ci, 10)
			draw_virus(ci, Vector2(0, -20 + sin(t * 2.5) * 2.0), t, 0.45)
		"phage":
			_shadow(ci, 18)
			draw_phage(ci, Vector2(0, -44), t, 0.55)
		"bookworm":
			draw_bookworm(ci, t)
		"robot":
			draw_robot(ci, t)
		"photon":
			draw_photon(ci, Vector2(0, -22 + sin(t * 4.0) * 3.0), t, 0.5)
		"prism":
			_shadow(ci, 12)
			draw_prism(ci, Vector2(0, -24), t, 0.45)
		"lens":
			_shadow(ci, 18)
			draw_lens_teacher(ci, Vector2(0, -40), t, 0.5)
		"junkyu":
			draw_junkyu(ci, info.get("facing", 0), t, not Game.flag("junkyu_happy"))
		"kid":
			draw_kid(ci, info.get("facing", 0), 0, false, info.get("style", {}), t)
		"infinity":
			draw_infinity(ci, Vector2(0, -24), t, 0.35)
		"enzyme":
			_shadow(ci, 12)
			draw_enzyme(ci, Vector2(0, -22), t, 0.4)
		"curry":
			_shadow(ci, 16)
			draw_curry(ci, Vector2(0, -26), t, 0.4)
		"mirror":
			draw_mirror(ci, Vector2(0, -36), t, 0.4)
		"washer":
			_shadow(ci, 16)
			draw_washer(ci, Vector2(0, -26), t, 0.36)
		"trash":
			_shadow(ci, 14)
			draw_trash(ci, Vector2(0, -26), t, 0.4)
		"frog":
			_shadow(ci, 12)
			draw_frog(ci, Vector2(0, -16), t, 0.3)
		"ghost_senior":
			draw_kid(ci, 1, 0, false, {"coat": Color(0.5, 0.55, 0.75, 0.6), "hair": Color(0.2, 0.2, 0.3, 0.6), "skin": Color(0.9, 0.92, 1.0, 0.6)}, t)
		"astro":
			_shadow(ci, 14)
			draw_astro(ci, Vector2(0, -42), t, 0.42)
		"lamp":
			_shadow(ci, 10)
			draw_lamp(ci, Vector2(0, -18), t, 0.42, 0.0, 1.0, Game.flag("lamp_spared"))
		"jut":
			_shadow(ci, 14)
			draw_jut(ci, Vector2(0, -42), t, 0.42)
		"alarm":
			_shadow(ci, 10)
			draw_alarm(ci, Vector2(0, -18), t, 0.4)
		"exam":
			_shadow(ci, 12)
			draw_exam(ci, Vector2(0, -26 + sin(t * 2.0) * 2.0), t, 0.4)
		"core":
			draw_core(ci, Vector2(0, -40), t, 0.5)
		"principal":
			_shadow(ci, 14)
			draw_principal(ci, Vector2(0, -42), t, 0.42)
		"gate":
			draw_gate(ci, t, info.get("label", "?"))
		"lost":
			# 누군가 잃어버린 물건: 바닥에서 작게 반짝인다
			_oval(ci, Vector2(0, -2), 8, 3, Color(0, 0, 0, 0.25), 10)
			ci.draw_rect(Rect2(-6, -8, 12, 7), Color(0.55, 0.75, 0.95))
			ci.draw_rect(Rect2(-6, -8, 12, 2), Color(0.75, 0.9, 1.0))
			var a2 := maxf(0.0, sin(t * 3.0))
			ci.draw_line(Vector2(5, -14), Vector2(5, -8), Color(1, 1, 0.8, a2), 1)
			ci.draw_line(Vector2(2, -11), Vector2(8, -11), Color(1, 1, 0.8, a2), 1)
		"sparkle":
			var a := 0.5 + 0.5 * sin(t * 5.0)
			ci.draw_line(Vector2(-6, -12), Vector2(6, -12), Color(1, 1, 0.7, a), 2)
			ci.draw_line(Vector2(0, -18), Vector2(0, -6), Color(1, 1, 0.7, a), 2)
		_:
			pass


## 주인공 (교복 입은 학생)
static func draw_student(ci: CanvasItem, facing: int, frame: int, moving: bool) -> void:
	draw_kid(ci, facing, frame, moving, {})


## 학생 공통 그림. st 로 겉모습을 바꾼다:
##   hair(색), skin, coat(겉옷 색), hoodie(true면 후드티), glasses, messy(삐친 머리), open_bag(가방 열림),
##   sock(한쪽 양말 내려감), sweat(땀방울), tie(넥타이 색), long_hair
static func draw_kid(ci: CanvasItem, facing: int, frame: int, moving: bool, st: Dictionary, t := 0.0) -> void:
	_shadow(ci, 11)
	var bob := -1.0 if moving and frame % 2 == 1 else 0.0
	var step := 0.0
	if moving:
		step = 2.0 if frame < 2 else -2.0
	var hair: Color = st.get("hair", Color(0.1, 0.08, 0.08))
	var hair_hi: Color = hair.lightened(0.25)
	var skin: Color = st.get("skin", Color(1.0, 0.86, 0.72))
	var coat: Color = st.get("coat", Color(0.14, 0.2, 0.42))
	var coat_dk: Color = coat.darkened(0.3)
	var pants: Color = st.get("pants", Color(0.17, 0.19, 0.3))
	var shoe := Color(0.08, 0.08, 0.08)
	var hoodie: bool = st.get("hoodie", false)
	# 다리 + 양말 + 신발
	var l_up := minf(step, 0.0)
	var r_up := minf(-step, 0.0)
	ci.draw_rect(Rect2(-7, -12 + l_up, 6, 10), pants)
	ci.draw_rect(Rect2(1, -12 + r_up, 6, 10), pants)
	ci.draw_rect(Rect2(-7, -4 + l_up, 6, 2), Color(0.95, 0.95, 0.95))
	if not st.get("sock", false):
		ci.draw_rect(Rect2(1, -4 + r_up, 6, 2), Color(0.95, 0.95, 0.95))
	ci.draw_rect(Rect2(-8, -3 + l_up, 7, 3), shoe)
	ci.draw_rect(Rect2(1, -3 + r_up, 7, 3), shoe)
	ci.draw_rect(Rect2(-7, -3 + l_up, 3, 1), Color(0.35, 0.35, 0.38))
	ci.draw_rect(Rect2(2, -3 + r_up, 3, 1), Color(0.35, 0.35, 0.38))
	# 가방 (뒤에서 보면 크게)
	var bag := Color(0.2, 0.32, 0.28)
	if facing == 1:
		ci.draw_rect(Rect2(-9, -29 + bob, 18, 15), bag)
		ci.draw_rect(Rect2(-9, -29 + bob, 18, 3), bag.lightened(0.2))
		ci.draw_rect(Rect2(-5, -20 + bob, 10, 5), bag.darkened(0.2))
		if st.get("open_bag", false):
			ci.draw_rect(Rect2(-6, -33 + bob, 5, 5), Color(0.96, 0.96, 0.92))
			ci.draw_rect(Rect2(1, -32 + bob, 6, 4), Color(0.95, 0.85, 0.3))
	# 몸통
	ci.draw_rect(Rect2(-10, -27 + bob, 20, 16), coat)
	ci.draw_rect(Rect2(4, -27 + bob, 6, 16), coat_dk)
	var arm_swing := step * 0.8
	ci.draw_rect(Rect2(-13, -26 + bob - arm_swing, 3, 12), coat)
	ci.draw_rect(Rect2(10, -26 + bob + arm_swing, 3, 12), coat_dk)
	ci.draw_rect(Rect2(-13, -15 + bob - arm_swing, 3, 3), skin)
	ci.draw_rect(Rect2(10, -15 + bob + arm_swing, 3, 3), skin)
	if facing == 0:
		if hoodie:
			ci.draw_rect(Rect2(-5, -27 + bob, 10, 4), coat.lightened(0.15))
			ci.draw_line(Vector2(-2, -23 + bob), Vector2(-2, -18 + bob), Color(0.9, 0.9, 0.9), 1)
			ci.draw_line(Vector2(2, -23 + bob), Vector2(2, -18 + bob), Color(0.9, 0.9, 0.9), 1)
			ci.draw_rect(Rect2(-6, -17 + bob, 12, 4), coat_dk)
		else:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-5, -27 + bob), Vector2(5, -27 + bob), Vector2(0, -19 + bob)]), Color.WHITE)
			ci.draw_line(Vector2(-5, -27 + bob), Vector2(-1, -19 + bob), coat_dk, 1)
			ci.draw_line(Vector2(5, -27 + bob), Vector2(1, -19 + bob), coat_dk, 1)
			ci.draw_rect(Rect2(-1, -24 + bob, 2, 8), st.get("tie", Color(0.75, 0.1, 0.15)))
			ci.draw_rect(Rect2(-7, -24 + bob, 3, 3), Color(0.9, 0.75, 0.25))
			ci.draw_rect(Rect2(3, -23 + bob, 5, 3), Color(0.97, 0.97, 0.97))
			ci.draw_rect(Rect2(-2, -14 + bob, 1, 1), Color(0.85, 0.85, 0.8))
		# 가방끈
		ci.draw_line(Vector2(-8, -27 + bob), Vector2(-8, -16 + bob), bag, 2)
		ci.draw_line(Vector2(8, -27 + bob), Vector2(8, -16 + bob), bag, 2)
	elif facing == 2 or facing == 3:
		var sx := -1.0 if facing == 2 else 1.0
		ci.draw_rect(Rect2(-10 * sx - (4 if sx > 0 else 0), -27 + bob, 4, 13), bag)
	# 머리
	var head := Vector2(0, -36 + bob)
	ci.draw_circle(head, 10.5, hair)
	if st.get("long_hair", false):
		ci.draw_rect(Rect2(head.x - 10, head.y, 20, 9), hair)
	match facing:
		0:
			ci.draw_circle(head + Vector2(0, 2.5), 8.5, skin)
			ci.draw_rect(Rect2(head.x - 9, head.y - 8, 18, 5), hair)
			ci.draw_rect(Rect2(head.x - 5, head.y - 9, 4, 1), hair_hi)
			ci.draw_rect(Rect2(head.x - 10, head.y, 2, 3), skin.darkened(0.08))
			ci.draw_rect(Rect2(head.x + 8, head.y, 2, 3), skin.darkened(0.08))
			ci.draw_rect(Rect2(head.x - 4.5, head.y + 1, 2, 3), Color.BLACK)
			ci.draw_rect(Rect2(head.x + 2.5, head.y + 1, 2, 3), Color.BLACK)
			ci.draw_rect(Rect2(head.x - 4.5, head.y + 1, 1, 1), Color.WHITE)
			ci.draw_rect(Rect2(head.x + 2.5, head.y + 1, 1, 1), Color.WHITE)
			ci.draw_rect(Rect2(head.x - 6.5, head.y + 4, 2, 1), Color(1.0, 0.6, 0.6, 0.6))
			ci.draw_rect(Rect2(head.x + 4.5, head.y + 4, 2, 1), Color(1.0, 0.6, 0.6, 0.6))
			if st.get("glasses", false):
				ci.draw_arc(head + Vector2(-3.5, 2.5), 3.2, 0, TAU, 10, Color(0.15, 0.15, 0.2), 1)
				ci.draw_arc(head + Vector2(3.5, 2.5), 3.2, 0, TAU, 10, Color(0.15, 0.15, 0.2), 1)
		1:
			ci.draw_rect(Rect2(head.x - 6, head.y - 6, 5, 2), hair_hi)
			ci.draw_rect(Rect2(head.x - 1, head.y + 6, 2, 3), hair.darkened(0.2))
		2:
			ci.draw_circle(head + Vector2(-3, 2.5), 7.5, skin)
			ci.draw_rect(Rect2(head.x - 8, head.y - 8, 14, 5), hair)
			ci.draw_rect(Rect2(head.x - 7, head.y + 1, 2, 3), Color.BLACK)
			ci.draw_rect(Rect2(head.x + 1, head.y, 3, 4), skin.darkened(0.08))
			if st.get("glasses", false):
				ci.draw_arc(head + Vector2(-6, 2.5), 3.2, 0, TAU, 10, Color(0.15, 0.15, 0.2), 1)
		3:
			ci.draw_circle(head + Vector2(3, 2.5), 7.5, skin)
			ci.draw_rect(Rect2(head.x - 6, head.y - 8, 14, 5), hair)
			ci.draw_rect(Rect2(head.x + 5, head.y + 1, 2, 3), Color.BLACK)
			ci.draw_rect(Rect2(head.x - 4, head.y, 3, 4), skin.darkened(0.08))
			if st.get("glasses", false):
				ci.draw_arc(head + Vector2(6, 2.5), 3.2, 0, TAU, 10, Color(0.15, 0.15, 0.2), 1)
	if st.get("messy", false):
		ci.draw_line(head + Vector2(2, -10), head + Vector2(5, -15), hair, 2)
		ci.draw_line(head + Vector2(5, -15), head + Vector2(8, -13), hair, 2)
		ci.draw_line(head + Vector2(-6, -9), head + Vector2(-9, -12), hair, 2)
	if st.get("sweat", false) and fmod(t, 2.0) < 1.2:
		var dy := fmod(t, 2.0) * 4.0
		ci.draw_circle(head + Vector2(11, -4 + dy), 2, Color(0.6, 0.85, 1.0))
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(10, -5 + dy), head + Vector2(12, -5 + dy), head + Vector2(11, -9 + dy)]), Color(0.6, 0.85, 1.0))


## 절규: 맨날 물건을 잃어버리는 친구. 후드티, 삐친 머리, 동그란 안경, 열린 가방, 내려간 양말.
const JUNKYU_STYLE := {"hair": Color(0.32, 0.22, 0.14), "coat": Color(0.55, 0.57, 0.62), "hoodie": true, "glasses": true,
	"messy": true, "open_bag": true, "sock": true}


static func draw_junkyu(ci: CanvasItem, facing: int, t: float, worried := true) -> void:
	var st: Dictionary = JUNKYU_STYLE.duplicate()
	st["sweat"] = worried
	draw_kid(ci, facing, 0, false, st, t)


## 숲의 돌문. label = 문에 새겨진 기호
static func draw_gate(ci: CanvasItem, t: float, label: String) -> void:
	ci.draw_rect(Rect2(-16, -44, 32, 46), Color(0.42, 0.44, 0.48))
	ci.draw_rect(Rect2(-16, -44, 32, 46), Color(0.25, 0.27, 0.3), false, 2)
	ci.draw_rect(Rect2(-12, -40, 24, 6), Color(0.55, 0.57, 0.6))
	var a := 0.6 + 0.4 * sin(t * 3.0)
	ci.draw_string(Game.font, Vector2(-16, -10), label, HORIZONTAL_ALIGNMENT_CENTER, 32, Game.FL, Color(0.5, 1.0, 0.85, a))


# ================================================================ 등장인물
## 나머지: 코어가 버린 '나누어떨어지지 않는 조각'. 안내 역할.
static func draw_namoji(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0) -> void:
	var wf := flash > 0.0
	var body := _c(Color(0.45, 1.0, 0.82), wf, alpha)
	var dark := _c(Color(0.1, 0.35, 0.3), wf, alpha)
	# 잔상 조각
	for i in 3:
		var off := Vector2(-10.0 - i * 7.0 + sin(t * 4.0 + i) * 2.0, 6.0 + i * 4.0) * s
		var c := body
		c.a *= 0.5 - i * 0.14
		ci.draw_rect(Rect2(pos + off - Vector2(3, 3) * s, Vector2(6 - i, 6 - i) * s), c)
	var glitch := Vector2(3, 0) if fmod(t, 2.3) < 0.08 else Vector2.ZERO
	ci.draw_set_transform(pos + glitch, 0.0, Vector2(s, s))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -13), Vector2(12, 0), Vector2(0, 13), Vector2(-12, 0)]), body)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -13), Vector2(12, 0), Vector2(0, 0), Vector2(-12, 0)]), _c(Color(0.7, 1.0, 0.92), wf, alpha))
	var blink := fmod(t, 3.1) < 0.12
	if blink:
		ci.draw_rect(Rect2(-6, -1, 4, 1), dark)
		ci.draw_rect(Rect2(2, -1, 4, 1), dark)
	else:
		ci.draw_rect(Rect2(-6, -3, 3, 5), dark)
		ci.draw_rect(Rect2(3, -3, 3, 5), dark)
	ci.draw_rect(Rect2(-2, 4, 4, 2), dark)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## GIL (수학 교원연구실의 숨은 보스): 네모난 얼굴에 크고 동그란 빨간 안경, 손에는 빨간펜
static func draw_redpen(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0) -> void:
	var wf := flash > 0.0
	var skin := _c(Color(0.96, 0.82, 0.68), wf, alpha)
	var skin_d := _c(Color(0.85, 0.68, 0.55), wf, alpha)
	var hair := _c(Color(0.12, 0.11, 0.12), wf, alpha)
	var red := _c(Color(0.88, 0.1, 0.14), wf, alpha)
	var lens := _c(Color(0.85, 0.95, 1.0, 0.35), wf, alpha)
	var shirt := _c(Color(0.92, 0.93, 0.96), wf, alpha)
	var vest := _c(Color(0.32, 0.36, 0.46), wf, alpha)
	var tie := _c(Color(0.2, 0.25, 0.55), wf, alpha)
	var black := _c(Color(0.05, 0.05, 0.05), wf, alpha)
	var white := _c(Color.WHITE, wf, alpha)
	ci.draw_set_transform(pos, sin(t * 1.3) * 0.03, Vector2(s, s))
	# 몸 (셔츠 + 조끼)
	ci.draw_rect(Rect2(-26, 6, 52, 50), shirt)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-26, 6), Vector2(-6, 6), Vector2(-2, 56), Vector2(-26, 56)]), vest)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(26, 6), Vector2(6, 6), Vector2(2, 56), Vector2(26, 56)]), vest)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-3, 8), Vector2(3, 8), Vector2(5, 36), Vector2(0, 42), Vector2(-5, 36)]), tie)
	# 팔과 빨간펜 (채점하듯 흔든다)
	var wave := sin(t * 4.0) * 5.0
	ci.draw_line(Vector2(26, 14), Vector2(40, -2 + wave), shirt, 9)
	ci.draw_circle(Vector2(41, -4 + wave), 5, skin)
	ci.draw_line(Vector2(38, -6 + wave), Vector2(50, -24 + wave), red, 4)
	ci.draw_line(Vector2(49, -22 + wave), Vector2(52, -27 + wave), black, 2)
	ci.draw_line(Vector2(-26, 14), Vector2(-34, 40), shirt, 9)
	ci.draw_circle(Vector2(-34, 42), 5, skin)
	# 네모난 얼굴
	ci.draw_rect(Rect2(-24, -46, 48, 50), skin)
	ci.draw_rect(Rect2(-24, -2, 48, 6), skin_d)
	ci.draw_rect(Rect2(-27, -28, 4, 12), skin)
	ci.draw_rect(Rect2(23, -28, 4, 12), skin)
	# 짧은 머리
	ci.draw_rect(Rect2(-26, -54, 52, 12), hair)
	ci.draw_rect(Rect2(-26, -46, 6, 10), hair)
	ci.draw_rect(Rect2(20, -46, 6, 10), hair)
	# 크고 동그란 빨간 안경
	for sx in [-11.0, 11.0]:
		ci.draw_circle(Vector2(sx, -24), 11, lens)
		ci.draw_arc(Vector2(sx, -24), 11, 0, TAU, 24, red, 3.5)
		ci.draw_circle(Vector2(sx + 1, -23), 2.5, black)
		ci.draw_circle(Vector2(sx - 3, -28), 2, white)
	ci.draw_line(Vector2(-1, -25), Vector2(1, -25), red, 3)
	ci.draw_line(Vector2(-22, -26), Vector2(-26, -24), red, 2.5)
	ci.draw_line(Vector2(22, -26), Vector2(26, -24), red, 2.5)
	# 입 (반쯤 웃는)
	ci.draw_arc(Vector2(0, -8), 7, 0.3, PI - 0.3, 10, black, 2)
	# 떨어지는 빨간 잉크 방울
	for i in 3:
		var dy := fmod(t * 40.0 + i * 22.0, 50.0)
		ci.draw_circle(Vector2(52, -24 + dy + wave), 2.2, _c(Color(0.84, 0.12, 0.16), wf, alpha * (1.0 - dy / 50.0)))
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 공집합: 속이 텅 빈 동그라미에 빗금
static func draw_empty_set(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0) -> void:
	var wf := flash > 0.0
	var line := _c(Color(0.8, 0.95, 1.0), wf, alpha)
	var faint := _c(Color(0.8, 0.95, 1.0, 0.08), wf, alpha)
	var dark := _c(Color(0.8, 0.95, 1.0, 0.75), wf, alpha)
	ci.draw_set_transform(pos, sin(t * 0.9) * 0.05, Vector2(s, s))
	ci.draw_circle(Vector2.ZERO, 44, faint)
	ci.draw_arc(Vector2.ZERO, 44, 0, TAU, 40, line, 8)
	ci.draw_line(Vector2(-38, 52), Vector2(38, -52), line, 8)
	# 수줍은 눈
	var look := sin(t * 0.7) * 3.0
	if fmod(t, 3.7) < 0.15:
		ci.draw_line(Vector2(-20, -8), Vector2(-10, -8), dark, 2)
		ci.draw_line(Vector2(12, 6), Vector2(22, 6), dark, 2)
	else:
		ci.draw_circle(Vector2(-15 + look, -8), 4, dark)
		ci.draw_circle(Vector2(17 + look, 6), 4, dark)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 벤 쌍둥이: 겹쳐진 두 원 A, B.  mood: 0 다투는 중, 1 사이좋음
static func draw_venn(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, mood := 0) -> void:
	var wf := flash > 0.0
	var ca := _c(Color(1.0, 0.4, 0.55, 0.55), wf, alpha)
	var cb := _c(Color(0.35, 0.9, 0.6, 0.55), wf, alpha)
	var la := _c(Color(1.0, 0.6, 0.7), wf, alpha)
	var lb := _c(Color(0.55, 1.0, 0.75), wf, alpha)
	var black := _c(Color(0.05, 0.05, 0.1), wf, alpha)
	var tug := sin(t * 3.0) * (4.0 if mood == 0 else 1.0)
	var a := Vector2(-22 - tug, sin(t * 2.0) * 3.0)
	var b := Vector2(22 + tug, cos(t * 2.0) * 3.0)
	ci.draw_set_transform(pos, 0.0, Vector2(s, s))
	ci.draw_circle(a, 40, ca)
	ci.draw_circle(b, 40, cb)
	ci.draw_arc(a, 40, 0, TAU, 36, la, 3)
	ci.draw_arc(b, 40, 0, TAU, 36, lb, 3)
	# 얼굴 (바깥쪽에)
	for side in 2:
		var c: Vector2 = a + Vector2(-14, -4) if side == 0 else b + Vector2(14, -4)
		ci.draw_circle(c + Vector2(-6, 0), 3, black)
		ci.draw_circle(c + Vector2(6, 0), 3, black)
		if mood == 0:
			var d := -1.0 if side == 0 else 1.0
			ci.draw_line(c + Vector2(-10, -8 + 3 * d), c + Vector2(-2, -8 - 3 * d), black, 2)
			ci.draw_line(c + Vector2(2, -8 - 3 * d * -1), c + Vector2(10, -8 + 3 * d * -1), black, 2)
			ci.draw_line(c + Vector2(-4, 12), c + Vector2(4, 12), black, 2)
		else:
			ci.draw_arc(c + Vector2(0, 8), 5, 0.2, PI - 0.2, 8, black, 2)
	var f: Font = Game.font
	ci.draw_string(f, a + Vector2(-34, -20), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, la)
	ci.draw_string(f, b + Vector2(20, -20), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, lb)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if mood == 1:
		draw_heart(ci, pos + Vector2(0, sin(t * 2.0) * 3.0 * s), 9.0 * s, _c(Color(1, 0.95, 0.6), wf, alpha))


## 반례: '모든 백조는 희다'를 거짓으로 만드는 검은 백조
static func draw_swan(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0) -> void:
	var wf := flash > 0.0
	var black := _c(Color(0.09, 0.09, 0.13), wf, alpha)
	var wing := _c(Color(0.2, 0.2, 0.28), wf, alpha)
	var red := _c(Color(0.95, 0.2, 0.2), wf, alpha)
	var white := _c(Color.WHITE, wf, alpha)
	var rim := _c(Color(0.75, 0.8, 1.0), wf, alpha)
	var bob := sin(t * 2.0) * 3.0
	ci.draw_set_transform(pos + Vector2(0, bob * s), 0.0, Vector2(s, s))
	# 몸
	_oval(ci, Vector2(8, 10), 46, 26, rim)
	_oval(ci, Vector2(8, 10), 44, 24, black)
	_oval(ci, Vector2(18, 4 + sin(t * 4.0) * 2.0), 26, 14, wing)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(46, 2), Vector2(66, -10), Vector2(50, 16)]), black)
	# 목 (S자)
	var pts := PackedVector2Array()
	for i in 13:
		var k := float(i) / 12.0
		pts.append(Vector2(-26 - sin(k * PI) * 16.0 + k * 6.0, 4 - k * 62.0))
	ci.draw_polyline(pts, rim, 13)
	ci.draw_polyline(pts, black, 10)
	var head := pts[12]
	ci.draw_circle(head, 10, rim)
	ci.draw_circle(head, 9, black)
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-7, -3), head + Vector2(-24, 3), head + Vector2(-7, 5)]), red)
	ci.draw_circle(head + Vector2(-2, -2), 2.5, white)
	ci.draw_line(head + Vector2(-6, -8), head + Vector2(3, -5), white, 1.5)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# 물결
	for i in 2:
		var x := fmod(t * 20.0 + i * 40.0, 80.0) - 40.0
		ci.draw_line(pos + Vector2(x - 8, 36 + i * 5) * s, pos + Vector2(x + 8, 36 + i * 5) * s, _c(Color(0.6, 0.8, 1.0, 0.5), wf, alpha), 1.5)


## 외계인 선생 BJ KIM (1챕터 보스): 안드로메다 237번 행성. 시각이 없어 눈이 없다. 커다란 머리, ∀·∃ 더듬이, 정장에 분필
static func draw_alien(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, mood := 0) -> void:
	var wf := flash > 0.0
	var skin := _c(Color(0.62, 0.86, 0.7), wf, alpha)
	var skin_d := _c(Color(0.45, 0.7, 0.55), wf, alpha)
	var eye := _c(Color(0.06, 0.08, 0.14), wf, alpha)
	var suit := _c(Color(0.2, 0.22, 0.32), wf, alpha)
	var shirt := _c(Color(0.92, 0.94, 0.98), wf, alpha)
	var tie := _c(Color(0.95, 0.75, 0.2), wf, alpha)
	var glow := _c(Color(0.6, 1.0, 0.9), wf, alpha)
	var chalk := _c(Color(1, 1, 1), wf, alpha)
	var bob := sin(t * 1.8) * 3.0
	ci.draw_set_transform(pos + Vector2(0, bob * s), 0.0, Vector2(s, s))
	# 떠 있는 고리 (발 대신)
	_oval(ci, Vector2(0, 66), 40, 9, _c(Color(0.6, 1.0, 0.9, 0.25 + 0.15 * sin(t * 5.0)), wf, alpha), 20)
	_oval(ci, Vector2(0, 66), 26, 5, _c(Color(0.6, 1.0, 0.9, 0.45), wf, alpha), 16)
	# 몸통 (정장)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-30, 60), Vector2(-24, 4), Vector2(24, 4), Vector2(30, 60)]), suit)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-10, 4), Vector2(10, 4), Vector2(0, 30)]), shirt)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-3, 8), Vector2(3, 8), Vector2(5, 30), Vector2(0, 36), Vector2(-5, 30)]), tie)
	# 팔: 한 손엔 분필, 한 손은 설명하듯
	var w := sin(t * 3.0) * 6.0
	ci.draw_line(Vector2(-22, 12), Vector2(-44, 30 + w), suit, 8)
	ci.draw_circle(Vector2(-45, 31 + w), 5, skin)
	ci.draw_line(Vector2(-47, 28 + w), Vector2(-54, 20 + w), chalk, 3)
	ci.draw_line(Vector2(22, 12), Vector2(42, -2 - w), suit, 8)
	ci.draw_circle(Vector2(43, -3 - w), 5, skin)
	# 목
	ci.draw_rect(Rect2(-6, -6, 12, 12), skin_d)
	# 커다란 머리
	_oval(ci, Vector2(0, -38), 36, 34, skin, 28)
	_oval(ci, Vector2(0, -20), 24, 14, skin, 20)
	# 더듬이 (∀ 와 ∃)
	ci.draw_line(Vector2(-14, -68), Vector2(-24, -94), skin_d, 3)
	ci.draw_line(Vector2(14, -68), Vector2(24, -94), skin_d, 3)
	var gl := 0.6 + 0.4 * sin(t * 4.0)
	ci.draw_circle(Vector2(-24, -98), 8, _c(Color(0.6, 1.0, 0.9, 0.35 * gl), wf, alpha))
	ci.draw_circle(Vector2(24, -98), 8, _c(Color(0.6, 1.0, 0.9, 0.35 * gl), wf, alpha))
	ci.draw_string(Game.font, Vector2(-31, -92), "∀", HORIZONTAL_ALIGNMENT_CENTER, 14, Game.FS, glow)
	ci.draw_string(Game.font, Vector2(17, -92), "∃", HORIZONTAL_ALIGNMENT_CENTER, 14, Game.FS, glow)
	# 눈이 없다 (BJ KIM 은 시각이 없다). 대신 더듬이에서 소리처럼 퍼지는 감지 물결과, 얼굴 가운데의 옅은 대칭축
	for k in 3:
		var ph := fmod(t * 0.9 + k / 3.0, 1.0)
		ci.draw_arc(Vector2(0, -98), 14 + ph * 46, PI * 1.15, PI * 1.85, 16, _c(Color(0.6, 1.0, 0.9, 0.4 * (1.0 - ph)), wf, alpha), 1.5)
	for k in 6:
		ci.draw_line(Vector2(0, -70 + k * 9), Vector2(0, -66 + k * 9), _c(Color(0.35, 0.6, 0.5, 0.7), wf, alpha), 1.5)
	# 눈 자리는 매끈하고, 마음이 풀리면 볼이 붉어진다
	ci.draw_arc(Vector2(-15, -40), 8, 0.3, PI - 0.3, 10, skin_d, 1.5)
	ci.draw_arc(Vector2(15, -40), 8, 0.3, PI - 0.3, 10, skin_d, 1.5)
	if mood == 1:
		ci.draw_circle(Vector2(-20, -26), 5, _c(Color(1.0, 0.6, 0.6, 0.5), wf, alpha))
		ci.draw_circle(Vector2(20, -26), 5, _c(Color(1.0, 0.6, 0.6, 0.5), wf, alpha))
	# 이름표
	ci.draw_rect(Rect2(10, 14, 16, 8), shirt)
	ci.draw_string(Game.font, Vector2(10, 21), "BJ", HORIZONTAL_ALIGNMENT_CENTER, 16, 8, eye)
	# 작은 입
	ci.draw_arc(Vector2(0, -16), 5, 0.4, PI - 0.4, 8, skin_d, 2)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## (예전 1챕터 보스) 학사모를 쓴 부엉이
static func draw_owl(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, mood := 0) -> void:
	var wf := flash > 0.0
	var brown := _c(Color(0.45, 0.32, 0.2), wf, alpha)
	var dark := _c(Color(0.3, 0.2, 0.12), wf, alpha)
	var belly := _c(Color(0.85, 0.75, 0.55), wf, alpha)
	var white := _c(Color.WHITE, wf, alpha)
	var black := _c(Color(0.05, 0.05, 0.08), wf, alpha)
	var gold := _c(Color(1.0, 0.8, 0.2), wf, alpha)
	var flap := sin(t * 3.0) * 0.25
	ci.draw_set_transform(pos + Vector2(0, sin(t * 2.0) * 4.0 * s), 0.0, Vector2(s, s))
	# 날개
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array()
		var base := Vector2(34 * side, -8)
		var ang: float = (0.5 + flap) * side
		for q in [Vector2(0, -14), Vector2(48, -30), Vector2(62, 0), Vector2(50, 22), Vector2(36, 12), Vector2(26, 34), Vector2(10, 22), Vector2(0, 30)]:
			wing.append(base + Vector2(q.x * side, q.y).rotated(ang * 0.6))
		ci.draw_colored_polygon(wing, dark)
	# 몸통
	_oval(ci, Vector2(0, 10), 42, 54, brown, 24)
	_oval(ci, Vector2(0, 22), 28, 38, belly, 20)
	for row in 3:
		for i in 3:
			var q := Vector2(-14 + i * 14, 6 + row * 14)
			ci.draw_polyline(PackedVector2Array([q + Vector2(-5, 0), q + Vector2(0, 5), q + Vector2(5, 0)]), dark, 2)
	# 발
	for side in [-1.0, 1.0]:
		for i in 3:
			ci.draw_line(Vector2(14 * side, 60), Vector2(14 * side + (i - 1) * 6, 70), gold, 3)
	# 머리
	ci.draw_circle(Vector2(0, -42), 36, brown)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-34, -56), Vector2(-40, -88), Vector2(-14, -70)]), brown)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(34, -56), Vector2(40, -88), Vector2(14, -70)]), brown)
	ci.draw_circle(Vector2(-15, -42), 15, white)
	ci.draw_circle(Vector2(15, -42), 15, white)
	var look := Vector2(sin(t * 0.8) * 4.0, 2.0)
	if mood == 1:
		ci.draw_arc(Vector2(-15, -40), 8, PI + 0.3, TAU - 0.3, 8, black, 3)
		ci.draw_arc(Vector2(15, -40), 8, PI + 0.3, TAU - 0.3, 8, black, 3)
	elif fmod(t, 4.3) < 0.14:
		ci.draw_line(Vector2(-24, -42), Vector2(-6, -42), black, 3)
		ci.draw_line(Vector2(6, -42), Vector2(24, -42), black, 3)
	else:
		ci.draw_circle(Vector2(-15, -42) + look, 7, black)
		ci.draw_circle(Vector2(15, -42) + look, 7, black)
		ci.draw_circle(Vector2(-17, -45) + look, 2, white)
		ci.draw_circle(Vector2(13, -45) + look, 2, white)
	ci.draw_arc(Vector2(-15, -42), 16, 0, TAU, 20, gold, 2)
	ci.draw_arc(Vector2(15, -42), 16, 0, TAU, 20, gold, 2)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-6, -32), Vector2(6, -32), Vector2(0, -20)]), gold)
	if mood == 0:
		ci.draw_line(Vector2(-30, -62), Vector2(-6, -56), dark, 4)
		ci.draw_line(Vector2(30, -62), Vector2(6, -56), dark, 4)
	# 학사모
	ci.draw_rect(Rect2(-18, -84, 36, 10), black)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-40, -86), Vector2(0, -98), Vector2(40, -86), Vector2(0, -76)]), black)
	ci.draw_line(Vector2(0, -87), Vector2(30 + sin(t * 3.0) * 3.0, -70), gold, 2)
	ci.draw_circle(Vector2(30 + sin(t * 3.0) * 3.0, -68), 3, gold)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


# ================================================================ 2챕터: 생명 실험실
## 초파리 떼
static func draw_flies(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, calm := false) -> void:
	var wf := flash > 0.0
	var body := _c(Color(0.25, 0.18, 0.1), wf, alpha)
	var eye := _c(Color(1.0, 0.15, 0.1), wf, alpha)
	var wing := _c(Color(0.9, 0.95, 1.0, 0.55), wf, alpha)
	var speed := 0.6 if calm else 1.0
	for i in 11:
		var a := t * speed * (1.6 + (i % 4) * 0.5) + i * 1.7
		var c := pos + Vector2(cos(a) * (30.0 + (i % 3) * 16.0), sin(a * 1.3 + i) * (22.0 + (i % 2) * 14.0)) * s
		var flap := 4.0 * s * absf(sin(t * 40.0 + i))
		ci.draw_line(c, c + Vector2(-5 * s, -3 * s - flap), wing, 2.5 * s)
		ci.draw_line(c, c + Vector2(5 * s, -3 * s - flap), wing, 2.5 * s)
		ci.draw_circle(c, 4.0 * s, body)
		ci.draw_circle(c + Vector2(2.5 * s, -1 * s), 1.8 * s, eye)


## 표본 나비: 핀에 꽂혀 있다. pins = 남은 핀 개수
static func draw_butterfly(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, pins := 2) -> void:
	var wf := flash > 0.0
	var blue := _c(Color(0.2, 0.55, 1.0), wf, alpha)
	var deep := _c(Color(0.08, 0.15, 0.45), wf, alpha)
	var body := _c(Color(0.12, 0.1, 0.1), wf, alpha)
	var silver := _c(Color(0.85, 0.85, 0.9), wf, alpha)
	var paper := _c(Color(0.95, 0.94, 0.88), wf, alpha)
	var flap := 0.75 + 0.25 * sin(t * (2.0 if pins > 0 else 6.0))
	ci.draw_set_transform(pos, 0.0, Vector2(s, s))
	ci.draw_rect(Rect2(-70, -62, 140, 128), _c(Color(0.95, 0.94, 0.88, 0.12), wf, alpha))
	for side in [-1.0, 1.0]:
		var up := PackedVector2Array([Vector2(0, -6), Vector2(62 * flap * side, -56), Vector2(74 * flap * side, -10), Vector2(40 * flap * side, 8)])
		var low := PackedVector2Array([Vector2(0, 2), Vector2(44 * flap * side, 12), Vector2(50 * flap * side, 44), Vector2(18 * flap * side, 52)])
		ci.draw_colored_polygon(up, deep)
		ci.draw_colored_polygon(low, deep)
		var up2 := PackedVector2Array([Vector2(4 * side, -8), Vector2(52 * flap * side, -46), Vector2(62 * flap * side, -14), Vector2(36 * flap * side, 2)])
		ci.draw_colored_polygon(up2, blue)
		ci.draw_circle(Vector2(46 * flap * side, -26), 5, _c(Color(1, 1, 1, 0.8), wf, alpha))
		ci.draw_circle(Vector2(32 * flap * side, 30), 6, blue)
	ci.draw_line(Vector2(0, -22), Vector2(0, 30), body, 7)
	ci.draw_line(Vector2(0, -22), Vector2(-10, -42), body, 1.5)
	ci.draw_line(Vector2(0, -22), Vector2(10, -42), body, 1.5)
	ci.draw_circle(Vector2(-3, -20), 1.5, _c(Color.WHITE, wf, alpha))
	ci.draw_circle(Vector2(3, -20), 1.5, _c(Color.WHITE, wf, alpha))
	if pins >= 1:
		ci.draw_line(Vector2(0, -2), Vector2(8, -30), silver, 2)
		ci.draw_circle(Vector2(8, -30), 4, _c(Color(1, 0.3, 0.3), wf, alpha))
	if pins >= 2:
		ci.draw_line(Vector2(-30, -20), Vector2(-24, -44), silver, 2)
		ci.draw_circle(Vector2(-24, -44), 4, _c(Color(1, 0.9, 0.3), wf, alpha))
	ci.draw_rect(Rect2(-34, 56, 68, 14), paper)
	ci.draw_line(Vector2(-28, 61), Vector2(28, 61), body, 1)
	ci.draw_line(Vector2(-28, 66), Vector2(10, 66), body, 1)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 바이러스: 돌기가 돋은 공
static func draw_virus(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, calm := false) -> void:
	var wf := flash > 0.0
	var body := _c(Color(0.55, 0.3, 0.75), wf, alpha)
	var lite := _c(Color(0.75, 0.5, 0.95), wf, alpha)
	var spike := _c(Color(0.4, 0.95, 0.6), wf, alpha)
	var black := _c(Color(0.05, 0.02, 0.08), wf, alpha)
	ci.draw_set_transform(pos, t * 0.3, Vector2(s, s))
	for i in 12:
		var a := TAU * i / 12.0
		var ln := 44.0 + sin(t * 4.0 + i * 1.3) * 4.0
		ci.draw_line(Vector2.RIGHT.rotated(a) * 28.0, Vector2.RIGHT.rotated(a) * ln, spike, 4)
		ci.draw_circle(Vector2.RIGHT.rotated(a) * ln, 5, spike)
	ci.draw_set_transform(pos, 0.0, Vector2(s, s))
	ci.draw_circle(Vector2.ZERO, 32, body)
	ci.draw_circle(Vector2(-8, -10), 14, lite)
	if calm:
		ci.draw_arc(Vector2(-11, -2), 5, PI + 0.3, TAU - 0.3, 8, black, 3)
		ci.draw_arc(Vector2(11, -2), 5, PI + 0.3, TAU - 0.3, 8, black, 3)
	else:
		ci.draw_circle(Vector2(-11, -2), 5, black)
		ci.draw_circle(Vector2(11, -2), 5, black)
		ci.draw_line(Vector2(-18, -12), Vector2(-5, -7), black, 3)
		ci.draw_line(Vector2(18, -12), Vector2(5, -7), black, 3)
	ci.draw_arc(Vector2(0, 10), 7, 0.3, PI - 0.3, 8, black, 2.5)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 박테리오파지 T4 (2챕터 보스): 달 착륙선처럼 생긴 바이러스
static func draw_phage(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, mood := 0) -> void:
	var wf := flash > 0.0
	var head := _c(Color(0.3, 0.75, 0.7), wf, alpha)
	var head2 := _c(Color(0.5, 0.95, 0.85), wf, alpha)
	var dark := _c(Color(0.12, 0.3, 0.32), wf, alpha)
	var metal := _c(Color(0.7, 0.75, 0.8), wf, alpha)
	var led := _c(Color(1.0, 0.25, 0.3) if mood == 0 else Color(0.5, 1.0, 0.6), wf, alpha)
	var bob := sin(t * 2.0) * 4.0
	ci.draw_set_transform(pos + Vector2(0, bob * s), sin(t * 1.1) * 0.03, Vector2(s, s))
	# 다리 6개
	for i in 6:
		var side := -1.0 if i < 3 else 1.0
		var k := i % 3
		var knee := Vector2((34 + k * 18) * side, 44 - k * 10 + sin(t * 3.0 + i) * 3.0)
		var foot := Vector2((48 + k * 26) * side, 96)
		ci.draw_line(Vector2(8 * side, 62), knee, dark, 4)
		ci.draw_line(knee, foot, dark, 4)
		ci.draw_circle(foot, 3, metal)
	# 꼬리
	ci.draw_rect(Rect2(-9, -4, 18, 66), metal)
	for i in 7:
		ci.draw_line(Vector2(-9, 2 + i * 9), Vector2(9, 2 + i * 9), dark, 2)
	ci.draw_rect(Rect2(-20, 60, 40, 8), dark)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-5, 68), Vector2(5, 68), Vector2(0, 82)]), metal)
	ci.draw_rect(Rect2(-14, -10, 28, 8), dark)
	# 머리 (정이십면체)
	var hex := PackedVector2Array()
	for i in 6:
		var a := TAU * i / 6.0 + PI / 6.0
		hex.append(Vector2(cos(a) * 36.0, sin(a) * 44.0 - 50.0))
	ci.draw_colored_polygon(hex, head)
	ci.draw_colored_polygon(PackedVector2Array([hex[3], hex[4], hex[5], Vector2(0, -50)]), head2)
	for i in 6:
		ci.draw_line(hex[i], Vector2(0, -50), dark, 1.5)
		ci.draw_line(hex[i], hex[(i + 1) % 6], dark, 2)
	# 눈 (LED)
	var blink := fmod(t, 3.7) < 0.12
	if not blink:
		ci.draw_circle(Vector2(0, -50), 9, _c(Color(0.05, 0.05, 0.08), wf, alpha))
		ci.draw_circle(Vector2(sin(t * 0.9) * 3.0, -50), 5, led)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


# ================================================================ 3층: 도서관
## 사서 책벌레: 펼친 책에서 고개를 내민 벌레
static func draw_bookworm(ci: CanvasItem, t: float) -> void:
	_shadow(ci, 13)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-16, -6), Vector2(0, -2), Vector2(0, -16), Vector2(-16, -20)]), Color(0.95, 0.93, 0.85))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(16, -6), Vector2(0, -2), Vector2(0, -16), Vector2(16, -20)]), Color(0.88, 0.86, 0.78))
	ci.draw_rect(Rect2(-17, -6, 34, 4), Color(0.5, 0.15, 0.15))
	for i in 3:
		ci.draw_line(Vector2(-13, -16 + i * 4), Vector2(-3, -13 + i * 4), Color(0.4, 0.4, 0.45), 1)
		ci.draw_line(Vector2(13, -16 + i * 4), Vector2(3, -13 + i * 4), Color(0.4, 0.4, 0.45), 1)
	var sway := sin(t * 2.0) * 2.0
	for i in 4:
		ci.draw_circle(Vector2(sway * i * 0.3, -14 - i * 6), 6 - i * 0.4, Color(0.55, 0.8, 0.4) if i % 2 == 0 else Color(0.45, 0.72, 0.35))
	var head := Vector2(sway, -36)
	ci.draw_circle(head, 7, Color(0.6, 0.85, 0.45))
	ci.draw_arc(head + Vector2(-3, -1), 3, 0, TAU, 8, Color(0.1, 0.1, 0.1), 1)
	ci.draw_arc(head + Vector2(3, -1), 3, 0, TAU, 8, Color(0.1, 0.1, 0.1), 1)
	ci.draw_rect(Rect2(head.x - 4, head.y - 2, 2, 2), Color(0.1, 0.1, 0.1))
	ci.draw_rect(Rect2(head.x + 2, head.y - 2, 2, 2), Color(0.1, 0.1, 0.1))


## 수업용 로봇
static func draw_robot(ci: CanvasItem, t: float) -> void:
	_shadow(ci, 12)
	ci.draw_rect(Rect2(-12, -6, 9, 6), Color(0.15, 0.15, 0.18))
	ci.draw_rect(Rect2(3, -6, 9, 6), Color(0.15, 0.15, 0.18))
	ci.draw_rect(Rect2(-11, -22, 22, 16), Color(0.85, 0.85, 0.88))
	ci.draw_rect(Rect2(-11, -22, 22, 4), Color(0.9, 0.3, 0.25))
	ci.draw_rect(Rect2(-8, -34, 16, 12), Color(0.7, 0.72, 0.78))
	var blink := fmod(t, 2.5) < 0.1
	ci.draw_rect(Rect2(-6, -31, 4, 1 if blink else 4), Color(0.2, 0.9, 1.0))
	ci.draw_rect(Rect2(2, -31, 4, 1 if blink else 4), Color(0.2, 0.9, 1.0))
	ci.draw_line(Vector2(0, -34), Vector2(0, -40), Color(0.4, 0.4, 0.45), 1.5)
	ci.draw_circle(Vector2(0, -41), 2, Color(1.0, 0.3, 0.3) if sin(t * 6.0) > 0 else Color(0.4, 0.1, 0.1))
	ci.draw_rect(Rect2(-5, -16, 10, 6), Color(0.2, 0.25, 0.3))


# ================================================================ 3챕터: 단일광자 실험실
## 광자: 입자이면서 파동.  form: 0 둘 다, 1 입자, 2 파동
static func draw_photon(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, form := 0) -> void:
	var wf := flash > 0.0
	var glow := _c(Color(1.0, 0.95, 0.6, 0.25), wf, alpha)
	var core := _c(Color(1.0, 1.0, 0.8), wf, alpha)
	var wave := _c(Color(0.6, 1.0, 0.9), wf, alpha)
	var black := _c(Color(0.1, 0.1, 0.15), wf, alpha)
	if form != 1:
		var pts := PackedVector2Array()
		for i in 25:
			var x := -120.0 + i * 10.0
			var amp := 26.0 * exp(-pow(x / 70.0, 2.0))
			pts.append(pos + Vector2(x, sin(x * 0.12 - t * 8.0) * amp) * s)
		ci.draw_polyline(pts, wave, 3.0 * s + 1.0)
	if form != 2:
		var wob := Vector2(sin(t * 9.0), cos(t * 7.0)) * 3.0 * s
		ci.draw_circle(pos + wob, 42 * s, glow)
		ci.draw_circle(pos + wob, 26 * s, _c(Color(1.0, 0.95, 0.6, 0.5), wf, alpha))
		ci.draw_circle(pos + wob, 17 * s, core)
		ci.draw_circle(pos + wob + Vector2(-6, -2) * s, 3 * s, black)
		ci.draw_circle(pos + wob + Vector2(6, -2) * s, 3 * s, black)
		ci.draw_arc(pos + wob + Vector2(0, 4) * s, 4 * s, 0.2, PI - 0.2, 6, black, 1.5)
	else:
		ci.draw_circle(pos + Vector2(-6, -2) * s, 3 * s, core)
		ci.draw_circle(pos + Vector2(6, -2) * s, 3 * s, core)


## 프리즘: 흰 빛을 무지개로 가른다
static func draw_prism(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, happy := false) -> void:
	var wf := flash > 0.0
	var glass := _c(Color(0.75, 0.9, 1.0, 0.45), wf, alpha)
	var edge := _c(Color(0.9, 0.97, 1.0), wf, alpha)
	var black := _c(Color(0.08, 0.08, 0.15), wf, alpha)
	var bob := sin(t * 2.0) * 4.0
	ci.draw_set_transform(pos + Vector2(0, bob * s), sin(t * 0.8) * 0.06, Vector2(s, s))
	ci.draw_line(Vector2(-150, 10), Vector2(-28, 2), _c(Color(1, 1, 1, 0.8), wf, alpha), 4)
	var cols := [Color(1, 0.25, 0.3), Color(1, 0.9, 0.3), Color(0.4, 1, 0.4), Color(0.4, 1, 0.9), Color(0.45, 0.4, 1), Color(0.8, 0.4, 1)]
	for i in cols.size():
		var a := -0.28 + i * 0.11 + (sin(t * 3.0 + i) * 0.02 if happy else 0.0)
		ci.draw_line(Vector2(26, 6), Vector2(26, 6) + Vector2.RIGHT.rotated(a) * 130.0, _c(cols[i], wf, alpha * (1.0 if happy else 0.55)), 4)
	var tri := PackedVector2Array([Vector2(0, -52), Vector2(52, 38), Vector2(-52, 38)])
	ci.draw_colored_polygon(tri, glass)
	ci.draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), edge, 3)
	ci.draw_line(Vector2(0, -52), Vector2(-14, 38), _c(Color(1, 1, 1, 0.35), wf, alpha), 2)
	ci.draw_circle(Vector2(-12, 8), 4, black)
	ci.draw_circle(Vector2(12, 8), 4, black)
	if happy:
		ci.draw_arc(Vector2(0, 18), 7, 0.2, PI - 0.2, 8, black, 2.5)
	else:
		ci.draw_line(Vector2(-6, 22), Vector2(6, 22), black, 2.5)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 렌즈 선생 (3챕터 리틀 보스): 커다란 안경을 쓴 광학 선생님. 실존 인물과 무관한 가상의 캐릭터.
static func draw_lens_teacher(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, mood := 0, beat := 0.0) -> void:
	var wf := flash > 0.0
	var coat := _c(Color(0.92, 0.94, 0.98), wf, alpha)
	var coat2 := _c(Color(0.72, 0.76, 0.85), wf, alpha)
	var skin := _c(Color(1.0, 0.87, 0.74), wf, alpha)
	var hair := _c(Color(0.25, 0.22, 0.25), wf, alpha)
	var black := _c(Color(0.06, 0.06, 0.1), wf, alpha)
	var glass := _c(Color(0.55, 0.85, 1.0, 0.55), wf, alpha)
	var shine := _c(Color(1, 1, 1, 0.9), wf, alpha)
	var tie := _c(Color(0.3, 0.5, 0.95), wf, alpha)
	var nod := sin(beat * TAU) * 3.0
	ci.draw_set_transform(pos + Vector2(0, sin(t * 1.6) * 3.0 * s), 0.0, Vector2(s, s))
	# 가운
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-44, 100), Vector2(-36, 6), Vector2(36, 6), Vector2(44, 100)]), coat)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-10, 6), Vector2(10, 6), Vector2(0, 40)]), _c(Color(0.35, 0.4, 0.5), wf, alpha))
	ci.draw_line(Vector2(0, 40), Vector2(0, 100), coat2, 2)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-5, 10), Vector2(5, 10), Vector2(3, 34), Vector2(0, 38), Vector2(-3, 34)]), tie)
	# 팔 + 레이저 포인터
	var arm := Vector2(64, -6 + sin(t * 2.0) * 8.0)
	ci.draw_line(Vector2(34, 22), arm, coat, 12)
	ci.draw_circle(arm, 7, skin)
	ci.draw_line(arm, arm + Vector2(22, -20), black, 4)
	ci.draw_circle(arm + Vector2(22, -20), 3, _c(Color(1, 0.2, 0.2), wf, alpha))
	ci.draw_line(Vector2(-34, 22), Vector2(-52, 60), coat, 12)
	ci.draw_circle(Vector2(-52, 60), 7, skin)
	# 머리
	var head := Vector2(0, -34 + nod)
	ci.draw_circle(head, 34, skin)
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-36, -6), head + Vector2(-30, -36), head + Vector2(0, -44), head + Vector2(30, -36), head + Vector2(36, -6), head + Vector2(20, -22), head + Vector2(-20, -22)]), hair)
	# 안경 (과장되게 큰 렌즈)
	for side in [-1.0, 1.0]:
		var c: Vector2 = head + Vector2(17 * side, 2)
		ci.draw_circle(c, 15, glass)
		ci.draw_arc(c, 15, 0, TAU, 20, black, 3)
		if mood == 1:
			ci.draw_arc(c + Vector2(0, 2), 6, PI + 0.3, TAU - 0.3, 8, black, 2.5)
		else:
			ci.draw_circle(c + Vector2(sin(t * 0.7) * 3.0, 1), 4, black)
		ci.draw_line(c + Vector2(-9, -8), c + Vector2(-3, -11), shine, 2)
	ci.draw_line(head + Vector2(-2, 2), head + Vector2(2, 2), black, 3)
	if mood == 1:
		ci.draw_arc(head + Vector2(0, 18), 7, 0.2, PI - 0.2, 8, black, 2.5)
	else:
		ci.draw_line(head + Vector2(-7, 22), head + Vector2(7, 21), black, 2.5)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


# ================================================================ 4~6챕터
## 사람 모양 공통: 몸통과 머리.  (0,0) = 가슴 근처
static func _person(ci: CanvasItem, body: Color, body2: Color, skin: Color, hair: Color, black: Color, mood: int, t: float) -> Vector2:
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-42, 100), Vector2(-36, 6), Vector2(36, 6), Vector2(42, 100)]), body)
	ci.draw_line(Vector2(-34, 22), Vector2(-54, 62), body, 12)
	ci.draw_line(Vector2(34, 22), Vector2(54, 62), body, 12)
	ci.draw_circle(Vector2(-54, 62), 7, skin)
	ci.draw_circle(Vector2(54, 62), 7, skin)
	ci.draw_line(Vector2(0, 8), Vector2(0, 100), body2, 2)
	var head := Vector2(0, -34 + sin(t * 1.5) * 1.5)
	ci.draw_circle(head, 33, skin)
	ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-35, -4), head + Vector2(-30, -34), head + Vector2(0, -42), head + Vector2(30, -34), head + Vector2(35, -4), head + Vector2(22, -20), head + Vector2(-22, -20)]), hair)
	if mood == 1:
		ci.draw_arc(head + Vector2(-13, 2), 5, PI + 0.3, TAU - 0.3, 8, black, 2.5)
		ci.draw_arc(head + Vector2(13, 2), 5, PI + 0.3, TAU - 0.3, 8, black, 2.5)
		ci.draw_arc(head + Vector2(0, 14), 7, 0.2, PI - 0.2, 8, black, 2.5)
	else:
		ci.draw_circle(head + Vector2(-13, 2), 4, black)
		ci.draw_circle(head + Vector2(13, 2), 4, black)
		ci.draw_line(head + Vector2(-20, -8), head + Vector2(-6, -4), black, 3)
		ci.draw_line(head + Vector2(20, -8), head + Vector2(6, -4), black, 3)
		ci.draw_line(head + Vector2(-7, 18), head + Vector2(7, 18), black, 2.5)
	return head


## 주T: 기숙사 사감. 키가 크고 마른 체형, 안경, 체육복, 호루라기, 손전등, 벌점 수첩.
static func draw_jut(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, mood := 0) -> void:
	var wf := flash > 0.0
	var suit := _c(Color(0.12, 0.2, 0.45), wf, alpha)
	var stripe := _c(Color(0.95, 0.95, 1.0), wf, alpha)
	var skin := _c(Color(0.98, 0.82, 0.68), wf, alpha)
	var hair := _c(Color(0.12, 0.1, 0.1), wf, alpha)
	var black := _c(Color(0.06, 0.06, 0.1), wf, alpha)
	# 키 크고 마른 체형: 가로는 좁게, 세로는 길게 (발 위치는 그대로)
	ci.draw_set_transform(pos + Vector2(0, sin(t * 1.4) * 2.0 * s - 14.0 * s), 0.0, Vector2(s * 0.78, s * 1.14))
	# 손전등 불빛
	var sw := sin(t * 1.2) * 0.35
	ci.draw_colored_polygon(PackedVector2Array([Vector2(54, 62), Vector2(54, 62) + Vector2(150, 40).rotated(sw), Vector2(54, 62) + Vector2(120, 110).rotated(sw)]), _c(Color(1, 1, 0.7, 0.22), wf, alpha))
	var head := _person(ci, suit, stripe, skin, hair, black, mood, t)
	# 안경
	ci.draw_arc(head + Vector2(-13, 2), 9, 0, TAU, 16, black, 2.5)
	ci.draw_arc(head + Vector2(13, 2), 9, 0, TAU, 16, black, 2.5)
	ci.draw_line(head + Vector2(-4, 1), head + Vector2(4, 1), black, 2.5)
	ci.draw_line(head + Vector2(-22, 0), head + Vector2(-32, -4), black, 2)
	ci.draw_line(head + Vector2(22, 0), head + Vector2(32, -4), black, 2)
	ci.draw_line(head + Vector2(-17, -2), head + Vector2(-10, -1), _c(Color(1, 1, 1, 0.6), wf, alpha), 1.5)
	ci.draw_line(Vector2(-39, 10), Vector2(-45, 100), stripe, 3)
	ci.draw_line(Vector2(39, 10), Vector2(45, 100), stripe, 3)
	# 호루라기
	ci.draw_line(Vector2(-10, 6), Vector2(0, 30), _c(Color(0.9, 0.2, 0.2), wf, alpha), 2)
	ci.draw_line(Vector2(10, 6), Vector2(0, 30), _c(Color(0.9, 0.2, 0.2), wf, alpha), 2)
	ci.draw_circle(Vector2(0, 33), 5, _c(Color(0.85, 0.85, 0.9), wf, alpha))
	# 벌점 수첩
	ci.draw_rect(Rect2(-66, 52, 22, 28), _c(Color(0.9, 0.85, 0.3), wf, alpha))
	ci.draw_line(Vector2(-62, 60), Vector2(-48, 60), black, 1.5)
	ci.draw_line(Vector2(-62, 66), Vector2(-48, 66), black, 1.5)
	# 손전등
	ci.draw_rect(Rect2(48, 54, 22, 10), black)
	# 모자
	ci.draw_rect(Rect2(head.x - 30, head.y - 40, 60, 14), suit)
	ci.draw_rect(Rect2(head.x - 6, head.y - 30, 46, 6), suit)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 알람 시계 (기숙사 잡몹)
static func draw_alarm(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, ringing := true) -> void:
	var wf := flash > 0.0
	var red := _c(Color(0.9, 0.25, 0.25), wf, alpha)
	var face := _c(Color(0.98, 0.97, 0.9), wf, alpha)
	var gold := _c(Color(1.0, 0.8, 0.25), wf, alpha)
	var black := _c(Color(0.06, 0.06, 0.1), wf, alpha)
	var jit := Vector2(sin(t * 50.0) * 3.0, 0) if ringing else Vector2.ZERO
	ci.draw_set_transform(pos + jit * s, 0.0, Vector2(s, s))
	ci.draw_line(Vector2(-26, 40), Vector2(-36, 58), black, 6)
	ci.draw_line(Vector2(26, 40), Vector2(36, 58), black, 6)
	ci.draw_circle(Vector2(-32, -44), 18, gold)
	ci.draw_circle(Vector2(32, -44), 18, gold)
	ci.draw_line(Vector2(0, -52), Vector2(0, -66), black, 4)
	ci.draw_circle(Vector2(0, -68), 5, black)
	ci.draw_circle(Vector2.ZERO, 50, red)
	ci.draw_circle(Vector2.ZERO, 40, face)
	for i in 12:
		var a := TAU * i / 12.0
		ci.draw_line(Vector2.RIGHT.rotated(a) * 33.0, Vector2.RIGHT.rotated(a) * 38.0, black, 2)
	ci.draw_line(Vector2.ZERO, Vector2.UP.rotated(t * 0.5) * 22.0, black, 4)
	ci.draw_line(Vector2.ZERO, Vector2.UP.rotated(t * 6.0) * 32.0, red, 2)
	ci.draw_circle(Vector2(-14, 6), 4, black)
	ci.draw_circle(Vector2(14, 6), 4, black)
	if ringing:
		ci.draw_line(Vector2(-22, -6), Vector2(-8, -1), black, 3)
		ci.draw_line(Vector2(22, -6), Vector2(8, -1), black, 3)
		_oval(ci, Vector2(0, 22), 8, 6, black, 10)
	else:
		ci.draw_arc(Vector2(0, 16), 7, 0.2, PI - 0.2, 8, black, 2.5)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 시험지 (5챕터). label = 과목 이름
static func draw_exam(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, label := "", mood := 0) -> void:
	var wf := flash > 0.0
	var paper := _c(Color(0.97, 0.96, 0.9), wf, alpha)
	var line := _c(Color(0.5, 0.52, 0.6), wf, alpha)
	var red := _c(Color(0.9, 0.15, 0.2), wf, alpha)
	var black := _c(Color(0.06, 0.06, 0.1), wf, alpha)
	ci.draw_set_transform(pos + Vector2(0, sin(t * 2.2) * 4.0 * s), sin(t * 1.1) * 0.07, Vector2(s, s))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-50, -70), Vector2(36, -70), Vector2(52, -54), Vector2(50, 72), Vector2(-52, 70)]), paper)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(36, -70), Vector2(52, -54), Vector2(36, -54)]), line)
	for i in 5:
		ci.draw_line(Vector2(-40, 14 + i * 11), Vector2(8, 14 + i * 11), line, 2)
		for k in 5:
			var filled := (i * 3 + k + int(t * 2.0)) % 5 == 0
			if filled:
				ci.draw_circle(Vector2(16 + k * 7, 14 + i * 11), 2.6, black)
			else:
				ci.draw_arc(Vector2(16 + k * 7, 14 + i * 11), 2.6, 0, TAU, 8, line, 1)
	ci.draw_circle(Vector2(-18, -22), 7, black)
	ci.draw_circle(Vector2(18, -22), 7, black)
	if mood == 1:
		ci.draw_arc(Vector2(0, -6), 9, 0.2, PI - 0.2, 8, black, 3)
		ci.draw_arc(Vector2(26, -44), 14, 0, TAU, 20, red, 3)
	else:
		ci.draw_line(Vector2(-30, -36), Vector2(-8, -28), black, 4)
		ci.draw_line(Vector2(30, -36), Vector2(8, -28), black, 4)
		ci.draw_line(Vector2(-10, -4), Vector2(10, -4), black, 3)
		ci.draw_line(Vector2(14, -58), Vector2(40, -34), red, 4)
	ci.draw_string(Game.font, Vector2(-46, -46), label, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, red)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 코어: 메인 서버의 자아. crack = 0(완벽) ~ 1(무너짐)
static func draw_core(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, crack := 0.0, mood := 0) -> void:
	var wf := flash > 0.0
	var cyan := _c(Color(0.3, 0.95, 1.0), wf, alpha)
	var dim := _c(Color(0.3, 0.95, 1.0, 0.25), wf, alpha)
	var white := _c(Color.WHITE, wf, alpha)
	var black := _c(Color(0.02, 0.04, 0.08), wf, alpha)
	var warm := _c(Color(1.0, 0.75, 0.5), wf, alpha)
	for ring in 3:
		var n := 6 - ring
		var rad := (78.0 - ring * 20.0) * s
		var rot := t * (0.5 + ring * 0.35) * (1.0 if ring % 2 == 0 else -1.0)
		var pts := PackedVector2Array()
		for i in n + 1:
			var wob := sin(t * 7.0 + i * 3.0 + ring) * crack * 9.0 * s
			pts.append(pos + Vector2.RIGHT.rotated(rot + TAU * i / n) * (rad + wob))
		ci.draw_polyline(pts, cyan if crack < 0.7 or ring != 0 else warm, 3)
		if ring == 0:
			ci.draw_colored_polygon(pts.slice(0, n), dim)
	ci.draw_circle(pos, 26 * s, black)
	ci.draw_arc(pos, 26 * s, 0, TAU, 24, cyan, 3)
	if mood == 1:
		ci.draw_arc(pos + Vector2(0, 2) * s, 12 * s, PI + 0.3, TAU - 0.3, 10, warm, 3)
	else:
		var look := Vector2(sin(t * 0.9), cos(t * 0.6)) * 6.0 * s
		ci.draw_circle(pos + look, 11 * s, white)
		ci.draw_circle(pos + look, 5 * s, black)
	if crack > 0.3:
		ci.draw_polyline(PackedVector2Array([pos + Vector2(-20, -60) * s, pos + Vector2(-6, -34) * s, pos + Vector2(-16, -20) * s]), white, 2)
	if crack > 0.6:
		ci.draw_polyline(PackedVector2Array([pos + Vector2(40, 50) * s, pos + Vector2(22, 30) * s, pos + Vector2(30, 14) * s]), white, 2)


## 교장: 최종 보스. link = 코어에 이어진 정도 (1 = 조종당하는 중). 실존 인물과 무관한 가상의 캐릭터.
static func draw_principal(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, mood := 0, link := 0.0) -> void:
	var wf := flash > 0.0
	var suit := _c(Color(0.16, 0.17, 0.24), wf, alpha)
	var suit2 := _c(Color(0.3, 0.32, 0.42), wf, alpha)
	var skin := _c(Color(0.98, 0.84, 0.72), wf, alpha)
	var hair := _c(Color(0.75, 0.76, 0.8), wf, alpha)
	var black := _c(Color(0.06, 0.06, 0.1), wf, alpha)
	var gold := _c(Color(1.0, 0.8, 0.25), wf, alpha)
	var cyan := _c(Color(0.3, 0.95, 1.0, 0.8 * link), wf, alpha)
	ci.draw_set_transform(pos + Vector2(0, sin(t * 1.2) * 2.0 * s), 0.0, Vector2(s, s))
	if link > 0.0:
		for i in 4:
			var x := -60.0 + i * 40.0
			ci.draw_line(Vector2(x, -150), Vector2(x * 0.3, -70 + sin(t * 3.0 + i) * 4.0), cyan, 2)
	var head := _person(ci, suit, suit2, skin, hair, black, mood, t)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-12, 6), Vector2(12, 6), Vector2(0, 44)]), _c(Color(0.95, 0.95, 0.98), wf, alpha))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-5, 10), Vector2(5, 10), Vector2(3, 36), Vector2(0, 42), Vector2(-3, 36)]), _c(Color(0.7, 0.1, 0.15), wf, alpha))
	ci.draw_circle(Vector2(-22, 26), 5, gold)
	# 안경
	ci.draw_rect(Rect2(head.x - 24, head.y - 6, 20, 14), black, false, 2)
	ci.draw_rect(Rect2(head.x + 4, head.y - 6, 20, 14), black, false, 2)
	ci.draw_line(head + Vector2(-4, 0), head + Vector2(4, 0), black, 2)
	if link > 0.5 and mood == 0:
		ci.draw_circle(head + Vector2(-13, 2), 3, cyan)
		ci.draw_circle(head + Vector2(13, 2), 3, cyan)
	# 상장
	ci.draw_rect(Rect2(46, 30, 30, 40), _c(Color(0.98, 0.95, 0.8), wf, alpha))
	ci.draw_rect(Rect2(46, 30, 30, 40), gold, false, 2)
	ci.draw_circle(Vector2(61, 58), 5, _c(Color(0.9, 0.15, 0.2), wf, alpha))
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


# ================================================================ 확장: 새 잡몹들
## 무한대 ∞ (1챕터): 8자 고리 두 개에 눈
static func draw_infinity(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, calm := false) -> void:
	var wf := flash > 0.0
	var col := _c(Color(0.75, 0.6, 1.0), wf, alpha)
	var glow := _c(Color(0.75, 0.6, 1.0, 0.18), wf, alpha)
	var black := _c(Color(0.06, 0.04, 0.1), wf, alpha)
	var pts := PackedVector2Array()
	for i in 49:
		var a := TAU * i / 48.0 + t * (0.3 if calm else 1.2)
		var d := 1.0 + pow(sin(a), 2)
		pts.append(pos + Vector2(cos(a) / d * 70.0, sin(a) * cos(a) / d * 70.0) * s)
	ci.draw_polyline(pts, glow, 16 * s)
	ci.draw_polyline(pts, col, 6 * s)
	for side in [-1.0, 1.0]:
		var e: Vector2 = pos + Vector2(36 * side, 0) * s
		ci.draw_circle(e, 9 * s, _c(Color.WHITE, wf, alpha))
		if calm:
			ci.draw_arc(e + Vector2(0, 2) * s, 5 * s, PI + 0.3, TAU - 0.3, 8, black, 2)
		else:
			ci.draw_circle(e + Vector2(sin(t * 3.0) * 3.0, 0) * s, 4 * s, black)


## 효소 가위 (2챕터): 입을 벌렸다 닫는 단백질
static func draw_enzyme(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, calm := false) -> void:
	var wf := flash > 0.0
	var body := _c(Color(0.95, 0.55, 0.3), wf, alpha)
	var dark := _c(Color(0.7, 0.35, 0.15), wf, alpha)
	var black := _c(Color(0.08, 0.05, 0.05), wf, alpha)
	var open := (0.15 if calm else 0.25 + 0.25 * absf(sin(t * 3.0)))
	ci.draw_set_transform(pos, 0.0, Vector2(s, s))
	for side in [-1.0, 1.0]:
		var pts := PackedVector2Array([Vector2.ZERO])
		for i in 13:
			var ang: float = (open + float(i) / 12.0 * (PI - open)) * side
			pts.append(Vector2.RIGHT.rotated(ang) * 52.0)
		ci.draw_colored_polygon(pts, body if side > 0 else dark)
	ci.draw_circle(Vector2(-6, -24), 6, _c(Color.WHITE, wf, alpha))
	ci.draw_circle(Vector2(-6, -24), 3, black)
	for i in 4:
		ci.draw_circle(Vector2(-40 + i * 8, 18 + sin(t * 4.0 + i) * 2.0), 3, _c(Color(1, 0.8, 0.5), wf, alpha))
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 카레 냄비 (2층 급식실 숨은 보스): 월화수 카레의 화신
static func draw_curry(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, happy := false) -> void:
	var wf := flash > 0.0
	var pot := _c(Color(0.72, 0.74, 0.78), wf, alpha)
	var pot_dk := _c(Color(0.5, 0.52, 0.56), wf, alpha)
	var curry := _c(Color(0.92, 0.62, 0.1), wf, alpha)
	var black := _c(Color(0.08, 0.06, 0.04), wf, alpha)
	ci.draw_set_transform(pos, sin(t * 2.0) * 0.04, Vector2(s, s))
	# 김
	for i in 3:
		var y := -60.0 - fmod(t * 30.0 + i * 20.0, 60.0)
		ci.draw_circle(Vector2(-20 + i * 20 + sin(t * 2.0 + i) * 6.0, y), 8, _c(Color(1, 1, 1, 0.25 * (1.0 + y / 120.0)), wf, alpha))
	ci.draw_rect(Rect2(-62, -10, 14, 8), pot_dk)
	ci.draw_rect(Rect2(48, -10, 14, 8), pot_dk)
	_oval(ci, Vector2(0, -24), 56, 14, curry)
	for i in 4:
		var bx := -30.0 + i * 20.0
		ci.draw_circle(Vector2(bx, -26 + sin(t * 5.0 + i) * 2.0), 4, _c(Color(1.0, 0.75, 0.25), wf, alpha))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-56, -24), Vector2(56, -24), Vector2(48, 50), Vector2(-48, 50)]), pot)
	ci.draw_line(Vector2(-56, -24), Vector2(56, -24), pot_dk, 4)
	ci.draw_circle(Vector2(-18, 8), 6, _c(Color.WHITE, wf, alpha))
	ci.draw_circle(Vector2(18, 8), 6, _c(Color.WHITE, wf, alpha))
	ci.draw_circle(Vector2(-18, 9), 3, black)
	ci.draw_circle(Vector2(18, 9), 3, black)
	if happy:
		ci.draw_arc(Vector2(0, 24), 9, 0.2, PI - 0.2, 8, black, 3)
	else:
		ci.draw_line(Vector2(-10, 26), Vector2(10, 22), black, 3)
	# 국자
	ci.draw_line(Vector2(30, -40), Vector2(70, -90 + sin(t * 3.0) * 8.0), pot_dk, 4)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 거울 속의 나 (3챕터): 거울 틀 안에 주인공이 거꾸로 비친다
static func draw_mirror(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, kind := false) -> void:
	var wf := flash > 0.0
	var frame := _c(Color(0.75, 0.62, 0.35), wf, alpha)
	var glass := _c(Color(0.55, 0.7, 0.85, 0.5), wf, alpha)
	ci.draw_set_transform(pos, 0.0, Vector2(s, s))
	ci.draw_rect(Rect2(-46, -70, 92, 140), frame)
	ci.draw_rect(Rect2(-38, -62, 76, 124), glass)
	for i in 3:
		ci.draw_line(Vector2(-30 + i * 22, -58), Vector2(-40 + i * 22, -40), _c(Color(1, 1, 1, 0.35), wf, alpha), 2)
	ci.draw_set_transform(pos + Vector2(0, 50) * s, 0.0, Vector2(-1.6 * s, 1.6 * s))
	var st := {"coat": Color(0.25, 0.25, 0.4) if not kind else Color(0.14, 0.2, 0.42), "hair": Color(0.1, 0.08, 0.08)}
	draw_kid(ci, 0, 0, false, st, t)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if not kind:
		# 거울 속 얼굴은 웃지 않는다
		ci.draw_line(pos + Vector2(-8, -6) * s, pos + Vector2(8, -6) * s, _c(Color(0.9, 0.2, 0.25), wf, alpha), 2)


## 세탁기 (4챕터 기숙사 세탁실)
static func draw_washer(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, calm := false) -> void:
	var wf := flash > 0.0
	var body := _c(Color(0.92, 0.93, 0.95), wf, alpha)
	var edge := _c(Color(0.6, 0.62, 0.68), wf, alpha)
	var drum := _c(Color(0.2, 0.25, 0.35), wf, alpha)
	var black := _c(Color(0.05, 0.05, 0.08), wf, alpha)
	var shake := Vector2(sin(t * 40.0) * (0.0 if calm else 3.0), 0)
	ci.draw_set_transform(pos + shake * s, 0.0, Vector2(s, s))
	ci.draw_rect(Rect2(-55, -60, 110, 125), body)
	ci.draw_rect(Rect2(-55, -60, 110, 125), edge, false, 3)
	ci.draw_rect(Rect2(-55, -60, 110, 22), edge)
	ci.draw_circle(Vector2(30, -49), 6, _c(Color(0.3, 0.9, 0.5), wf, alpha))
	ci.draw_circle(Vector2(0, 12), 40, edge)
	ci.draw_circle(Vector2(0, 12), 34, drum)
	var spin := t * (1.0 if calm else 6.0)
	for i in 5:
		var c := Vector2.RIGHT.rotated(spin + TAU * i / 5.0) * 20.0 + Vector2(0, 12)
		ci.draw_circle(c, 7, _c(Color.from_hsv(i * 0.2, 0.5, 0.95), wf, alpha))
	ci.draw_circle(Vector2(-12, 4), 5, _c(Color.WHITE, wf, alpha))
	ci.draw_circle(Vector2(12, 4), 5, _c(Color.WHITE, wf, alpha))
	ci.draw_circle(Vector2(-12, 5), 2.5, black)
	ci.draw_circle(Vector2(12, 5), 2.5, black)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 휴지통 (6챕터 백업 저장소): 지워진 것들을 모아 둔 통
static func draw_trash(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, calm := false) -> void:
	var wf := flash > 0.0
	var bin := _c(Color(0.35, 0.55, 0.75), wf, alpha)
	var bin_dk := _c(Color(0.22, 0.38, 0.55), wf, alpha)
	var paper := _c(Color(0.95, 0.95, 0.92), wf, alpha)
	var black := _c(Color(0.05, 0.05, 0.08), wf, alpha)
	ci.draw_set_transform(pos, 0.0, Vector2(s, s))
	for i in 5:
		var a := t * 0.8 + TAU * i / 5.0
		var p := Vector2(cos(a) * 70.0, -60 + sin(a * 1.3) * 14.0)
		ci.draw_rect(Rect2(p - Vector2(8, 10), Vector2(16, 20)), paper)
		ci.draw_line(p + Vector2(-5, -4), p + Vector2(5, -4), _c(Color(0.5, 0.5, 0.6), wf, alpha), 1)
		ci.draw_line(p + Vector2(-5, 1), p + Vector2(3, 1), _c(Color(0.5, 0.5, 0.6), wf, alpha), 1)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-44, -30), Vector2(44, -30), Vector2(34, 60), Vector2(-34, 60)]), bin)
	ci.draw_rect(Rect2(-50, -40, 100, 12), bin_dk)
	for i in 4:
		ci.draw_line(Vector2(-24 + i * 16, -20), Vector2(-20 + i * 13, 52), bin_dk, 3)
	ci.draw_circle(Vector2(-14, 4), 6, paper)
	ci.draw_circle(Vector2(14, 4), 6, paper)
	if calm:
		ci.draw_arc(Vector2(-14, 6), 4, PI + 0.3, TAU - 0.3, 8, black, 2)
		ci.draw_arc(Vector2(14, 6), 4, PI + 0.3, TAU - 0.3, 8, black, 2)
	else:
		ci.draw_circle(Vector2(-14, 5), 3, black)
		ci.draw_circle(Vector2(14, 5), 3, black)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 탈출한 해부 실습 개구리 (1층 정원)
static func draw_frog(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, calm := false) -> void:
	var wf := flash > 0.0
	var green := _c(Color(0.35, 0.75, 0.35), wf, alpha)
	var belly := _c(Color(0.8, 0.95, 0.6), wf, alpha)
	var black := _c(Color(0.05, 0.08, 0.05), wf, alpha)
	var hop := absf(sin(t * 3.0)) * (2.0 if calm else 10.0)
	ci.draw_set_transform(pos + Vector2(0, -hop) * s, 0.0, Vector2(s, s))
	_oval(ci, Vector2(0, 20), 50, 32, green)
	_oval(ci, Vector2(0, 28), 32, 20, belly)
	ci.draw_circle(Vector2(-24, -10), 16, green)
	ci.draw_circle(Vector2(24, -10), 16, green)
	ci.draw_circle(Vector2(-24, -12), 9, _c(Color.WHITE, wf, alpha))
	ci.draw_circle(Vector2(24, -12), 9, _c(Color.WHITE, wf, alpha))
	ci.draw_circle(Vector2(-24, -11), 5, black)
	ci.draw_circle(Vector2(24, -11), 5, black)
	ci.draw_arc(Vector2(0, 14), 18, 0.3, PI - 0.3, 12, black, 2)
	# 실험실 이름표
	ci.draw_rect(Rect2(10, 30, 22, 10), _c(Color(0.95, 0.95, 0.9), wf, alpha))
	ci.draw_string(Game.font, Vector2(10, 39), "#7", HORIZONTAL_ALIGNMENT_CENTER, 22, Game.FS, black)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 천문 선생 (5장 보스): 안경, 별 무늬 바람막이, 완주 메달, 스포츠 시계. 마른 근육질 체형.
static func draw_astro(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, mood := 0) -> void:
	var wf := flash > 0.0
	var jacket := _c(Color(0.12, 0.16, 0.36), wf, alpha)
	var zip := _c(Color(0.85, 0.88, 0.95), wf, alpha)
	var skin := _c(Color(0.92, 0.74, 0.58), wf, alpha)
	var hair := _c(Color(0.1, 0.09, 0.1), wf, alpha)
	var black := _c(Color(0.05, 0.05, 0.08), wf, alpha)
	var gold := _c(Color(1.0, 0.8, 0.25), wf, alpha)
	var star_c := _c(Color(1.0, 0.95, 0.6), wf, alpha)
	var bob := sin(t * 5.0) * 2.0 if mood == 0 else sin(t * 1.5) * 1.0
	ci.draw_set_transform(pos + Vector2(0, bob * s - 10.0 * s), 0.0, Vector2(s * 0.86, s * 1.1))
	var head := _person(ci, jacket, zip, skin, hair, black, mood, t)
	# 바람막이의 별 무늬
	for i in 6:
		var q := Vector2(-26 + (i % 3) * 22, 30 + (i / 3) * 34)
		ci.draw_circle(q, 2.0, star_c)
	# 완주 메달
	ci.draw_line(Vector2(-12, 6), Vector2(0, 34), _c(Color(0.85, 0.2, 0.25), wf, alpha), 3)
	ci.draw_line(Vector2(12, 6), Vector2(0, 34), _c(Color(0.2, 0.35, 0.85), wf, alpha), 3)
	ci.draw_circle(Vector2(0, 40), 8, gold)
	ci.draw_circle(Vector2(0, 40), 4, _c(Color(0.85, 0.65, 0.15), wf, alpha))
	# 스포츠 시계
	ci.draw_rect(Rect2(48, 56, 12, 9), black)
	ci.draw_rect(Rect2(50, 58, 8, 5), _c(Color(0.3, 1.0, 0.6, 0.6 + 0.4 * sin(t * 4.0)), wf, alpha))
	# 안경 (각진 테)
	ci.draw_rect(Rect2(head + Vector2(-23, -6), Vector2(18, 14)), black, false, 2.5)
	ci.draw_rect(Rect2(head + Vector2(5, -6), Vector2(18, 14)), black, false, 2.5)
	ci.draw_line(head + Vector2(-5, 0), head + Vector2(5, 0), black, 2.5)
	ci.draw_line(head + Vector2(-20, -3), head + Vector2(-14, -3), _c(Color(1, 1, 1, 0.6), wf, alpha), 1.5)
	# 짧게 자른 머리 위 별 모양 머리핀
	star_shape(ci, head + Vector2(18, -34), 6.0, star_c)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


static func star_shape(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2.RIGHT.rotated(a) * (r if i % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, col)


## 유성우 (5장 잡몹): 꼬리를 끄는 빛나는 돌, 웃는 얼굴
static func draw_meteor(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0) -> void:
	var wf := flash > 0.0
	ci.draw_set_transform(pos, 0.0, Vector2(s, s))
	for i in 8:
		var k := float(i) / 8.0
		ci.draw_circle(Vector2(30 + i * 9, -24 - i * 7) + Vector2(sin(t * 8.0 + i) * 2.0, 0), 16 - i * 1.6, _c(Color(0.6, 0.75, 1.0, 0.35 * (1.0 - k)), wf, alpha))
	ci.draw_circle(Vector2.ZERO, 22, _c(Color(1.0, 0.92, 0.6), wf, alpha))
	ci.draw_circle(Vector2(-4, -4), 16, _c(Color(1.0, 0.98, 0.85), wf, alpha))
	ci.draw_circle(Vector2(-8, -2), 3, _c(Color(0.2, 0.15, 0.1), wf, alpha))
	ci.draw_circle(Vector2(6, -2), 3, _c(Color(0.2, 0.15, 0.1), wf, alpha))
	ci.draw_arc(Vector2(-1, 5), 6, 0.3, PI - 0.3, 8, _c(Color(0.2, 0.15, 0.1), wf, alpha), 2)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 광해 가로등 (5장 잡몹): 눈부신 가로등, 갓을 쓰면 아래만 비춘다
static func draw_lamp(ci: CanvasItem, pos: Vector2, t: float, s: float, flash := 0.0, alpha := 1.0, calm := false) -> void:
	var wf := flash > 0.0
	var pole := _c(Color(0.35, 0.37, 0.42), wf, alpha)
	var light := _c(Color(1.0, 0.95, 0.65), wf, alpha)
	var black := _c(Color(0.08, 0.08, 0.1), wf, alpha)
	ci.draw_set_transform(pos, 0.0, Vector2(s, s))
	if not calm:
		for i in 3:
			ci.draw_circle(Vector2(0, -78), 40 + i * 18 + sin(t * 3.0) * 4.0, _c(Color(1.0, 0.95, 0.6, 0.12 - i * 0.03), wf, alpha))
	else:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-16, -70), Vector2(16, -70), Vector2(40, 40), Vector2(-40, 40)]), _c(Color(1.0, 0.95, 0.6, 0.12), wf, alpha))
	ci.draw_rect(Rect2(-5, -70, 10, 110), pole)
	ci.draw_rect(Rect2(-16, 36, 32, 8), pole)
	ci.draw_circle(Vector2(0, -80), 16, light)
	if calm:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-26, -86), Vector2(26, -86), Vector2(14, -100), Vector2(-14, -100)]), _c(Color(0.25, 0.3, 0.35), wf, alpha))
	ci.draw_circle(Vector2(-6, -80), 2.5, black)
	ci.draw_circle(Vector2(6, -80), 2.5, black)
	if calm:
		ci.draw_arc(Vector2(0, -74), 5, 0.3, PI - 0.3, 8, black, 2)
	else:
		ci.draw_line(Vector2(-6, -72), Vector2(6, -72), black, 2)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
