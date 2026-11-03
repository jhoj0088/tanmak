extends "res://scripts/battle/enemy_base.gd"
## 렌즈 선생 — 3챕터 리틀 보스. 모든 공격이 음악(120 BPM) 박자에 맞는다.
##
## 공격 4종:
##   1) 볼록 렌즈   평행하게 내려오던 빛이 렌즈를 지나 초점으로 모였다가 퍼진다
##   2) 레이저 격자 박자마다 가로·세로 레이저 (한 박자 예고)
##   3) 이중 슬릿   간섭무늬: 밝은 줄에만 탄이 쏟아지고, 8박마다 줄이 반 칸 옮겨 간다
##   4) 단일 광자   박자마다 빠른 광자 한 발, 4박마다 원형 탄
## 살려 주는 방법: 한 번 이하로 맞고 공격을 넘긴 다음 '초점 맞춰 주기'. 세 번 성공하면 된다.

const Art = preload("res://scripts/art/art.gd")

var focus_count := 0
var last_hits := -1
var wiped := false
var hurt := false
var pattern := 0
var focus := Vector2.ZERO
var phase := 0
var beat_now := 0.0


func _init() -> void:
	id = "lens"
	name = "렌즈 선생"
	max_hp = 150
	hp = 150
	atk = 4
	def = 1
	exp_reward = 32
	boss = true
	bpm = 120.0
	music = "optics"
	can_flee = false
	bg = Color(0.15, 0.3, 0.5)
	acts = ["살펴보기", "초점 맞춰 주기", "안경 닦아 주기"]


func intro() -> String:
	return "* 렌즈 선생이 레이저 포인터를 켰다! 암실 전체가 박자에 맞춰 깜빡인다."


func flavor(_b) -> String:
	if spareable:
		return "* 렌즈 선생의 안경에 당신이 또렷하게 비친다. (자비를 베풀 수 있다)"
	if hp < max_hp / 3:
		return "* 렌즈 선생의 안경에 금이 갔다."
	return ["* 렌즈 선생이 박자에 맞춰 고개를 끄덕인다.", "* 암실에 레이저 냄새가 난다. 레이저에 냄새가 있었나?",
			"* 초점이 맞은 횟수: %d / 3  (1번 이하로 맞고 넘기면 맞출 수 있다)" % focus_count, "* 렌즈 선생이 안경을 고쳐 썼다. 렌즈가 번쩍 빛났다."][randi() % 4]


func bubble(b) -> String:
	pattern = (b.turn - 1) % 4
	if spareable:
		return "...선명하군.\n흔들림 없는 눈이야.\n오랜만에 보네."
	var head := ""
	if hurt:
		head = "실험 기구를\n함부로 다루지 말게!\n"
	elif wiped:
		head = "흠, 잘 보이는군.\n"
	hurt = false
	match pattern:
		0:
			return head + "볼록 렌즈는\n빛을 한 점에 모으지.\n초점을 피하게!"
		1:
			return head + "쿵, 쿵, 쿵, 쿵.\n예고선이 보이면\n한 박자 뒤에 쏜다네."
		2:
			return head + "이중 슬릿!\n밝은 무늬에만\n빛이 쌓이지."
		_:
			return head + "광자를 하나씩.\n박자마다, 정확히."


func on_hurt(_b, _dmg: int) -> void:
	hurt = true


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 렌즈 선생 - 공격 4 방어 1", "* 광학 담당. 흐릿한 것을 참지 못한다. 모든 공격이 음악의 박자에 맞는다.",
				"* 공격을 거의 맞지 않고(1번 이하) 넘긴 뒤 '초점 맞춰 주기'를 세 번 성공하면 물러난다."])
		1:
			if last_hits < 0:
				await b.say(["* 아직 관측이 시작되지 않았다.", "* (먼저 공격을 한 번 피해 보자.)"])
			elif last_hits > 1:
				await b.say(["* 당신은 초점을 맞추려 했지만, 방금 맞은 충격으로 눈이 흔들린다.", "렌즈 선생: 흐릿해! 흔들리지 말게. (두 번 이상 맞으면 안 된다)"])
			else:
				focus_count += 1
				last_hits = -1
				Snd.play("correct")
				if focus_count >= 3:
					spareable = true
					await b.say(["* 당신은 흔들림 없이 렌즈 선생을 바라보았다.", "* 세 번째 초점이 맞았다. 상이 또렷하게 맺혔다!"])
				else:
					await b.say(["* 당신은 흔들림 없이 렌즈 선생을 바라보았다.", "* 초점이 맞았다! (%d / 3)" % focus_count])
		2:
			wiped = true
			await b.say(["* 당신은 렌즈 선생의 안경을 닦아 주었다.", "* 이번 턴은 공격이 조금 느려진다."])


func begin_attack(b) -> void:
	b.attack_len = 5.0 if spareable else 8.0
	phase = 0
	focus = b.attack_box.get_center()
	pt = 0.0


func end_attack(b) -> void:
	last_hits = b.hits_this_attack
	wiped = false


func update_attack(b, delta: float) -> void:
	beat_now = b.beat_frac
	var k: float = (0.78 if wiped else 1.0) * (1.1 if hp < max_hp / 3 else 1.0)
	var box: Rect2 = b.box
	if spareable:
		if b.beat_hit and b.beat_i % 2 == 0:
			b.add(Vector2(randf_range(box.position.x, box.end.x), box.position.y - 10), Vector2(0, 70), 5, Color(0.8, 0.95, 1.0))
		return
	match pattern:
		0:
			# 볼록 렌즈
			if b.beat_hit and b.beat_i % 2 == 0:
				focus = Vector2(randf_range(box.position.x + 40, box.end.x - 40), box.position.y + 115)
				var lens_y := box.position.y + 26
				var f := focus
				for j in 10:
					var x := box.position.x - 26 + j * (box.size.x + 52) / 9.0
					var bl = b.add(Vector2(x, box.position.y - 24), Vector2(0, 135.0 * k), 4.5, Color(1.0, 0.95, 0.55))
					bl.fn = func(q, _d):
						if not q.data.has("bent") and q.pos.y >= lens_y:
							q.data["bent"] = true
							q.vel = (f - q.pos).normalized() * 135.0 * k
		1:
			# 레이저 격자
			if b.beat_hit:
				var bl_len: float = b.beat_len()
				if b.beat_i % 2 == 0:
					b.laser(Vector2(box.position.x - 30, b.soul.y), 0.0, bl_len, 0.22, 10, Color(1.0, 0.3, 0.35))
					b.laser(Vector2(randf_range(box.position.x + 10, box.end.x - 10), box.position.y - 30), PI / 2.0, bl_len, 0.22, 10, Color(1.0, 0.3, 0.35))
				else:
					b.laser(Vector2(b.soul.x, box.position.y - 30), PI / 2.0, bl_len, 0.22, 10, Color(1.0, 0.3, 0.35))
					b.laser(Vector2(box.position.x - 30, randf_range(box.position.y + 10, box.end.y - 10)), 0.0, bl_len, 0.22, 10, Color(1.0, 0.3, 0.35))
				if b.beat_i % 4 == 3 and hp < max_hp * 2 / 3:
					b.laser(Vector2(box.position.x - 20, box.position.y - 20), 0.55, bl_len, 0.22, 10, Color(1.0, 0.6, 0.9))
				Snd.play("warn")
		2:
			# 이중 슬릿: 8박마다 무늬가 반 칸 이동. 옮기기 직전 2박은 쉰다.
			if b.beat_hit and b.beat_i % 8 == 0:
				phase = 1 - phase
			var resting: bool = b.beat_i % 8 >= 6
			pt -= delta
			if pt <= 0.0 and not resting:
				pt = 0.17 / k
				for x in _bands(box, phase):
					b.add(Vector2(x + randf_range(-8, 8), box.position.y - 10), Vector2(0, 150.0 * k), 4, Color(1.0, 0.35, 0.4))
		_:
			# 단일 광자
			if b.beat_hit:
				var p := Vector2(randf_range(box.position.x, box.end.x), box.position.y - 14)
				var edge := randi() % 3
				if edge == 1:
					p = Vector2(box.position.x - 14, randf_range(box.position.y, box.end.y))
				elif edge == 2:
					p = Vector2(box.end.x + 14, randf_range(box.position.y, box.end.y))
				var bl2 = b.add(p, (b.soul - p).normalized() * 240.0 * k, 5, Color(1.0, 1.0, 0.7), 1)
				bl2.delay = b.beat_len() * 0.5
				if b.beat_i % 4 == 0:
					spin += 0.26
					b.ring(b.enemy_pos + Vector2(0, 50), 12, 88.0 * k, 5, Color(0.6, 0.85, 1.0).lerp(Color(1, 1, 1), 0.4), spin)


## 밝은 무늬(탄이 쏟아지는 줄)의 x 좌표들
func _bands(box: Rect2, ph: int) -> Array:
	var out: Array = []
	var x := box.position.x + 14.0 + ph * 28.0
	while x < box.end.x:
		out.append(x)
		x += 56.0
	return out


func draw_attack(b) -> void:
	if spareable:
		return
	var box: Rect2 = b.box
	if pattern == 0:
		# 렌즈와 초점
		var lens_y := box.position.y + 26
		var pts := PackedVector2Array()
		for i in 21:
			var a := TAU * i / 20.0
			pts.append(Vector2(box.get_center().x + cos(a) * (box.size.x * 0.5 - 6), lens_y + sin(a) * 7.0))
		b.draw_polyline(pts, Color(0.6, 0.9, 1.0, 0.7), 2)
		b.draw_arc(focus, 8 + sin(b.t * 10.0) * 2.0, 0, TAU, 12, Color(1.0, 0.4, 0.4, 0.8), 2)
		b.draw_line(focus + Vector2(-5, 0), focus + Vector2(5, 0), Color(1.0, 0.4, 0.4, 0.8), 1.5)
		b.draw_line(focus + Vector2(0, -5), focus + Vector2(0, 5), Color(1.0, 0.4, 0.4, 0.8), 1.5)
	elif pattern == 2:
		var resting: bool = b.beat_i % 8 >= 6
		var show_phase := (1 - phase) if resting else phase
		var a2 := 0.3 * absf(sin(b.t * 12.0)) if resting else 0.13
		for x in _bands(box, show_phase):
			b.draw_rect(Rect2(x - 12, box.position.y + 3, 24, box.size.y - 6), Color(1.0, 0.3, 0.35, a2))


func not_yet_text() -> Array:
	return ["* 살려 주려 했다.", "* 렌즈 선생: '아직 상이 흐릿하네.' (거의 맞지 않고 공격을 넘긴 뒤 초점을 맞춰 주자)"]


func kill_text() -> Array:
	return ["* 렌즈 선생의 안경이 깨졌다. 암실이 다시 캄캄해졌다..."]


func spare_text() -> Array:
	return ["* 렌즈 선생이 레이저 포인터를 껐다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_lens_teacher(ci, pos + Vector2(0, 0), t, 0.82, fl, alpha, 1 if spareable else 0, beat_now)
