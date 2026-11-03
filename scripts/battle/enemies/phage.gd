extends "res://scripts/battle/enemy_base.gd"
## 박테리오파지 T4 — 2챕터 보스. "불완전한 유전자를 교정"하려 든다.
##
## 공격 4종:
##   1) 착륙      다리(레이저)가 예고 후 내리꽂힌다
##   2) DNA 주입  이중 나선 사이를 따라 내려간다
##   3) 용균      커다란 세포가 떠다니다 터져서 제멋대로 갈라진다
##   4) 증식      탄 하나가 2 → 4 → 8개로 갈라진다
## 살려 주는 방법 두 가지: '변이를 옹호하기' 3문제를 맞히거나, 탄을 70번 스쳐 '항체'를 만든다.

const Art = preload("res://scripts/art/art.gd")
const Flask = preload("res://scripts/battle/enemies/flask.gd")

const QUIZ := [
	{
		"q": ["파지 T4: 돌연변이는 오류입니다. 오류는 삭제해야 합니다. 반론이 있습니까?"],
		"opts": ["없다. 돌연변이는 전부 해롭다", "있다. 어떤 변이는 환경에 유리하다", "있다. 돌연변이는 일어나지 않는다"],
		"answer": 1,
	},
	{
		"q": ["파지 T4: 모두가 같은 유전자를 가지면 완벽합니다. 무엇이 문제입니까?"],
		"opts": ["환경이 바뀌면 한꺼번에 사라진다", "문제없다. 똑같을수록 강하다", "유전자는 원래 다 똑같다"],
		"answer": 0,
	},
	{
		"q": ["파지 T4: 마지막 질문. 진화의 재료는 무엇입니까?"],
		"opts": ["완벽하게 복제된 유전자", "가장 힘센 개체 하나", "서로 다름, 곧 변이"],
		"answer": 2,
	},
]

var solved := 0
var angry := false
var hurt := false
var pattern := 0
var grazes := 0
var immune_msg := false
var wave := 0
var helix_x := 0.0
var sub := 0.0


func _init() -> void:
	id = "phage"
	name = "파지 T4"
	max_hp = 130
	hp = 130
	atk = 4
	exp_reward = 28
	boss = true
	music = "boss"
	can_flee = false
	bg = Color(0.1, 0.35, 0.35)
	acts = ["살펴보기", "변이를 옹호하기", "힌트 청하기"]


func intro() -> String:
	return "* 박테리오파지 T4가 착륙했다! 교정 대상을 스캔하고 있다."


func flavor(_b) -> String:
	if immune_msg:
		immune_msg = false
		return "* 탄을 스치는 동안 몸에 항체가 생겼다! 파지가 달라붙지 못한다. (자비를 베풀 수 있다)"
	if spareable:
		return "* 파지 T4의 눈이 초록색으로 깜빡인다. (자비를 베풀 수 있다)"
	if hp < max_hp / 3:
		return "* 파지 T4의 다리 하나가 덜덜 떨린다."
	return ["* 파지 T4가 당신의 유전자를 읽고 있다. '오차 0.1% 발견.'", "* 꼬리 끝에서 무언가 똑똑 떨어진다.",
			"* 옹호한 횟수: %d / 3   항체(스친 횟수): %d / 70" % [solved, grazes], "* 파지 T4의 머리가 육각형으로 반짝인다."][randi() % 4]


func bubble(b) -> String:
	pattern = (b.turn - 1) % 4
	if spareable:
		return "다양성...\n오류가 아니라\n재료였군요."
	var head := ""
	if angry:
		head = "반론 기각.\n"
	elif hurt:
		head = "손상 감지.\n교정 강도를 높입니다.\n"
	hurt = false
	match pattern:
		0:
			return head + "착륙 시퀀스.\n다리를 조심하십시오."
		1:
			return head + "DNA 주입.\n이중 나선을 따라\n내려오십시오."
		2:
			return head + "용균 단계.\n세포가 터집니다.\n불규칙하게."
		_:
			return head + "증식.\n1, 2, 4, 8..."


func on_hurt(_b, _dmg: int) -> void:
	hurt = true


func on_graze(_b) -> void:
	grazes += 1
	if grazes == 70 and not spareable:
		spareable = true
		immune_msg = true
		Snd.play("correct")


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 파지 T4 - 공격 4 방어 0", "* 세균에 착륙해 유전자를 주입하는 바이러스. 코어에게 '교정' 임무를 받았다.",
				"* 말로 설득하거나(3문제), 탄을 많이 스쳐 항체를 만들면(70번) 물러난다."])
		1:
			if solved >= QUIZ.size():
				await b.say(["* 파지 T4는 더 반박하지 않는다."])
				return
			var q: Dictionary = QUIZ[solved]
			await b.say(q["q"])
			var k: int = await b.choose(q["opts"])
			if k == q["answer"]:
				solved += 1
				Game.logic += 1
				Snd.play("correct")
				if solved >= QUIZ.size():
					spareable = true
					await b.say(["파지 T4: ...재계산 중. '변이 = 오류'라는 전제가 틀렸습니다.", "* 파지 T4의 눈이 초록색으로 바뀌었다! (논리 +1)"])
				else:
					await b.say(["파지 T4: ...반론을 기록합니다.", "* 옹호한 횟수: %d / 3  (논리 +1)" % solved])
			else:
				angry = true
				Snd.play("wrong")
				await b.say(["파지 T4: 반론 기각. 그것은 사실이 아닙니다.", "* 파지 T4의 눈이 더 붉어졌다! (다음 공격이 거세진다)"])
		2:
			await b.say(["* 나머지가 명찰 뒤에서 속삭였다.", "나머지: 다 똑같으면 병 하나에 전부 쓰러져. 서로 달라야 누군가는 살아남아!", "나머지: 그리고 저 탄, 스칠수록 몸이 익숙해지는 것 같아."])


func begin_attack(b) -> void:
	b.attack_len = 5.0 if spareable else 8.0
	pt = 0.4
	sub = 0.0
	wave = 0
	helix_x = b.attack_box.get_center().x


func end_attack(_b) -> void:
	angry = false


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (1.2 if angry else 1.0) * (1.12 if hp < max_hp / 3 else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	sub -= delta
	if spareable:
		if pt <= 0.0:
			pt = 0.7
			var bl0 = b.add(Vector2(randf_range(box.position.x, box.end.x), box.position.y - 10), Vector2(0, 60), 8, Color(0.5, 1.0, 0.7), 5)
			bl0.life = 6.0
		return
	match pattern:
		0:
			# 착륙: 다리 세 개가 예고선 뒤에 내리꽂힌다. 하나는 하트를 노린다.
			if pt <= 0.0:
				pt = 1.15 / k
				wave += 1
				var xs := [b.soul.x, randf_range(box.position.x + 10, box.end.x - 10), randf_range(box.position.x + 10, box.end.x - 10)]
				for x in xs:
					var lean := randf_range(-0.18, 0.18)
					b.laser(Vector2(x - lean * 200.0, box.position.y - 40), PI / 2.0 + lean, 0.7, 0.22, 12, Color(0.4, 1.0, 0.85))
				Snd.play("warn")
			if sub <= 0.0 and hp < max_hp / 2:
				sub = 2.4
				Flask.toss(b, Color(0.4, 1.0, 0.85), 6)
		1:
			# DNA 주입: 두 가닥이 꼬이며 내려온다. 가닥 사이(또는 바깥)에서 따라 움직인다.
			helix_x += sin(b.attack_t * 0.9) * 28.0 * delta
			if pt <= 0.0:
				pt = 0.075 / k
				wave += 1
				var ph: float = b.attack_t * 3.2
				for s in [0.0, PI]:
					var x2 := helix_x + sin(ph + s) * 46.0
					var col := Color(1.0, 0.45, 0.6) if s == 0.0 else Color(1.0, 0.9, 0.35)
					b.add(Vector2(x2, box.position.y - 12), Vector2(0, 125.0 * k), 4.5, col)
				if wave % 6 == 0:
					# 염기쌍 사다리
					for j in range(-1, 2):
						b.add(Vector2(helix_x + j * 14.0 * cos(ph), box.position.y - 12), Vector2(0, 125.0 * k), 3, Color(0.6, 1.0, 0.8))
		2:
			# 용균: 세포가 둥둥 떠다니다 터진다
			if pt <= 0.0:
				pt = 1.0 / k
				var c := Vector2(randf_range(box.position.x + 20, box.end.x - 20), box.position.y - 20)
				var cell = b.add(c, Vector2(randf_range(-25, 25), randf_range(45, 70)), 15, Color(0.5, 0.95, 0.8), 5)
				cell.data["pop"] = randf_range(1.3, 2.1)
				cell.fn = func(q, _d):
					if q.age > q.data["pop"]:
						b.burst(q, 10, 105.0 * k, 4.5, Color(0.5, 0.95, 0.8), 0.6)
						Snd.play("warn")
			if sub <= 0.0:
				sub = 1.9 / k
				Flask.toss(b, Color(0.9, 1.0, 0.4), 7)
		_:
			# 증식: 하나가 둘로, 둘이 넷으로
			if pt <= 0.0:
				pt = 1.5 / k
				var src: Vector2 = b.enemy_pos + Vector2(randf_range(-60, 60), 60)
				var seed = b.add(src, Vector2.RIGHT.rotated(b.aim(src)) * 78.0 * k, 9, Color(0.4, 1.0, 0.85), 5)
				seed.data["gen"] = 0
				seed.fn = _divide.bind(b)


func _divide(q, _d, b) -> void:
	if q.age < 0.85 or q.data["gen"] >= 3:
		return
	q.life = 0.0
	var ang: float = q.vel.angle()
	var sp: float = q.vel.length() * 1.08
	for s in [-0.42, 0.42]:
		var c = b.add(q.pos, Vector2.RIGHT.rotated(ang + s) * sp, maxf(4.0, q.r - 1.8), q.color, 5 if q.data["gen"] < 1 else 0)
		c.data["gen"] = q.data["gen"] + 1
		c.fn = _divide.bind(b)


func not_yet_text() -> Array:
	return ["* 살려 주려 했다.", "* 파지 T4: '교정이 끝나지 않았습니다.' (변이를 옹호하거나, 탄을 스쳐 항체를 만들자)"]


func kill_text() -> Array:
	return ["* 파지 T4는 육각형 조각들로 무너져 내렸다. 마지막까지 '오차'를 세고 있었다."]


func spare_text() -> Array:
	return ["* 파지 T4가 다리를 접고 조용히 내려앉았다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_phage(ci, pos + Vector2(0, -8), t, 0.92, fl, alpha, 1 if spareable else 0)
