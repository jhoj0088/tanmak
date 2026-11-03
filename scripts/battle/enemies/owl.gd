extends "res://scripts/battle/enemy_base.gd"
## 외계인 BJ KIM — 1챕터 보스. 집합과 명제의 방의 주인.
## 2025 이산수학 기출 9번의 '지구 방문 일지'를 쓴, 안드로메다 237번 행성에서 온 외계 생명체.
## 시각이 없다. 집합·함수·일대일 대응은 배웠지만 '대칭'이 무엇인지 아직 모른다.
##
## 공격 4종이 차례로 돈다:
##   1) p ⇒ q      화살표 열차
##   2) 참과 거짓   파란 벽(참)은 멈춰서, 주황 벽(거짓)은 움직이면서 통과
##   3) 귀류법      퍼져 나갔던 탄이 '모순'을 만나 되돌아온다
##   4) 귀납법      n=1 부터 도미노처럼 차례로 떨어지는 줄
## '명제로 답하기' 퀴즈 3문제(대우, 충분조건, 부정)를 맞히고,
## '대칭 설명하기'로 눈이 없는 BJ KIM 에게 대칭을 (보는 것 없이) 설명해 주면 살려 줄 수 있다.

const Art = preload("res://scripts/art/art.gd")

const QUIZ := [
	{
		"q": ["BJ KIM: 제1문. 명제 'x = 2 이면 x² = 4 이다'의 대우는?"],
		"opts": ["x² = 4 이면 x = 2 이다", "x ≠ 2 이면 x² ≠ 4 이다", "x² ≠ 4 이면 x ≠ 2 이다"],
		"answer": 2,
		"ok": "BJ KIM: 정답. 명제와 대우는 참·거짓이 늘 같다. 내 행성에서도 같다.",
	},
	{
		"q": ["BJ KIM: 제2문. 두 조건 p: x = 1,  q: x² = 1.", "BJ KIM: p 는 q 이기 위한 어떤 조건인가?"],
		"opts": ["필요조건이지만 충분조건은 아니다", "충분조건이지만 필요조건은 아니다", "필요충분조건이다"],
		"answer": 1,
		"ok": "BJ KIM: 정답. x = 1 이면 x² = 1 이지만, x² = 1 이어도 x = -1 일 수 있다.",
	},
	{
		"q": ["BJ KIM: 제3문. 명제 '모든 실수 x 에 대하여 x² - 2x + 1 > 0 이다'의 부정은?"],
		"opts": ["모든 실수 x 에 대하여 x² - 2x + 1 < 0 이다", "x² - 2x + 1 ≤ 0 인 실수 x 가 존재한다", "x² - 2x + 1 > 0 인 실수 x 가 존재한다"],
		"answer": 1,
		"ok": "BJ KIM: 정답. 그리고 원래 명제는 거짓이다. x = 1 하나면 충분하다. 반례는 하나로 족하다.",
	},
]

var solved := 0
var sym := false
var angry := false
var pattern := 0
var wave := 0
var hurt := false


func _init() -> void:
	id = "owl"
	name = "외계인 선생 BJ KIM"
	max_hp = 110
	hp = 110
	atk = 3
	def = 0
	exp_reward = 20
	boss = true
	music = "boss"
	can_flee = false
	bg = Color(0.1, 0.22, 0.24)
	acts = ["살펴보기", "명제로 답하기", "대칭 설명하기", "힌트 청하기"]


func intro() -> String:
	return "* 외계인 BJ KIM이 더듬이를 세웠다! 증명되지 않은 것은 지나갈 수 없다."


func flavor(_b) -> String:
	if spareable:
		return "* BJ KIM의 더듬이가 기분 좋게 깜빡인다. (자비를 베풀 수 있다)"
	if hp < max_hp / 3:
		return "* BJ KIM의 넥타이가 삐뚤어졌다. 보이지 않으니 좌우를 맞추기 어렵다."
	return ["* BJ KIM이 분필을 고쳐 잡았다.", "* 방 전체가 칠판처럼 고요하다.", "* BJ KIM의 더듬이에서 물결이 퍼진다. 당신의 위치를 '듣고' 있다.",
			"* 맞힌 명제: %d / 3" % solved][randi() % 4]


func bubble(b) -> String:
	pattern = (b.turn - 1) % 4
	if spareable:
		return "고맙다, 지구인.\n이제 나도\n대칭을 '본다'."
	var head := ""
	if angry:
		head = "틀렸다!\n"
	elif hurt:
		head = "삐빅!?\n폭력은 증명이 아니다!\n"
	hurt = false
	match pattern:
		0:
			return head + "제1증명.\n'p ⇒ q' !\n지구식으로 한다."
		1:
			return head + "참(파랑)은 멈춰서,\n거짓(주황)은 움직이며\n받아들여라!"
		2:
			return head + "귀류법!\n결론을 부정하면...\n모순이 되돌아오지!"
		_:
			return head + "수학적 귀납법!\nn=1 이 쓰러지면\n모두 쓰러진다!"


func on_hurt(_b, _dmg: int) -> void:
	hurt = true


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 외계인 선생 BJ KIM - 공격 3 방어 0", "* 안드로메다 237번 행성에서 왔다. 시각이 없다. 대신 소리와 숫자로 세상을 '본다'.", "* 집합, 함수, 일대일 대응은 배웠다. 아직 모르는 것은 하나. '대칭'.", "* 명제 세 문제를 맞히고, 대칭을 눈 없이도 알 수 있게 설명해 주자."])
		1:
			if solved >= QUIZ.size():
				await b.say(["* BJ KIM은 더 낼 명제가 없다며 더듬이를 흔든다. 남은 건 대칭이다."])
				return
			var q: Dictionary = QUIZ[solved]
			await b.say(q["q"])
			var k: int = await b.choose(q["opts"])
			if k == q["answer"]:
				solved += 1
				Game.logic += 1
				Snd.play("correct")
				if solved >= QUIZ.size():
					await b.say([q["ok"], "BJ KIM: ...세 문제 모두 정답. 지구인, 너는 셀 줄 안다.", "BJ KIM: 그럼 마지막으로 하나만 묻자. 내 일지의 빈칸이다. '대칭'이란 무엇인가?", "* ('대칭 설명하기'로 답해 주자)"])
				else:
					await b.say([q["ok"], "* 맞힌 문제: %d / 3  (논리 +1)" % solved])
			else:
				angry = true
				Snd.play("wrong")
				await b.say(["BJ KIM: 틀렸다! 다시 세어 봐라.", "* BJ KIM이 분필을 부러뜨렸다! (다음 공격이 거세진다)"])
		2:
			if sym:
				await b.say(["* BJ KIM은 '일대일 대응... 변하지 않는 것...'이라고 몇 번이고 되뇌고 있다."])
				return
			if solved < QUIZ.size():
				await b.say(["BJ KIM: 대칭? ...그건 내 일지의 마지막 빈칸이다. 먼저 명제 세 개로 너를 믿게 해 줘라. (명제로 답하기 먼저)"])
				return
			await b.say(["BJ KIM: 지구인들은 나비가, 눈송이가, 얼굴이 '대칭'이라고 한다.", "BJ KIM: 나에게는 눈이 없다. 집합과 함수와 일대일 대응만 안다.", "BJ KIM: 그것만으로 대칭을 설명할 수 있는가?"])
			var k2: int = await b.choose([
				"거울에 비춘 것처럼 양쪽이 똑같아 보이는 것",
				"어떤 일대일 대응으로 옮겨도 그대로인 것 (x → -x 로 보내도 {-2,-1,1,2}는 그대로)",
				"왼쪽 절반과 오른쪽 절반의 넓이가 같은 것",
			])
			if k2 == 1:
				sym = true
				spareable = true
				Game.logic += 1
				Snd.play("correct")
				await b.say([
					"BJ KIM: ...!",
					"BJ KIM: 집합 A 와, A 를 A 로 보내는 일대일 대응 f. f 로 옮겨도 A 가 그대로 A 라면, A 는 f 에 대해 대칭이다.",
					"BJ KIM: 보지 않아도 된다. 옮기기 전과 옮긴 뒤가 같은지만 확인하면 된다.",
					"BJ KIM: 그렇다면 나도 대칭을 '볼' 수 있다. 일지에 적겠다. (논리 +1)",
					"* BJ KIM의 더듬이가 부드럽게 내려앉았다!",
				])
			else:
				angry = true
				Snd.play("wrong")
				await b.say(["BJ KIM: '보인다'? 나는 볼 수 없다. 넓이도 만져 봐야 안다.", "BJ KIM: 내가 아는 말로 다시 말해 줘라. 집합, 함수, 일대일 대응... (다음 공격이 거세진다)"])
		3:
			await b.say(["BJ KIM: 'p 이면 q'의 대우는 'q 가 아니면 p 가 아니다'.", "BJ KIM: p ⇒ q 가 참이면 p 는 q 의 충분조건, q 는 p 의 필요조건.", "BJ KIM: '모든 ... 이다'의 부정은 '... 이 아닌 것이 존재한다'. 부등호도 같이 뒤집어라. > 의 반대는 ≤ 다.", "BJ KIM: 대칭은... 나는 모른다. 그래서 묻는 것이다. 다만 '보이는 것'으로는 나를 이해시킬 수 없다."])


func begin_attack(b) -> void:
	b.attack_len = 5.0 if spareable else 8.0
	pt = 0.3
	wave = 0


func end_attack(_b) -> void:
	angry = false


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (1.25 if angry else 1.0) * (1.15 if hp < max_hp / 3 else 1.0)
	pt -= delta
	if pt > 0.0:
		return
	var box: Rect2 = b.box
	if spareable:
		pt = 0.6
		spin += 0.4
		for bl in b.ring(b.enemy_pos + Vector2(0, 40), 6, 60.0, 7, Color(0.7, 1.0, 0.8), spin, 2):
			bl.text = "∴"
		return
	match pattern:
		0:
			# p ⇒ q : 줄지어 지나가는 화살표
			pt = 0.5 / k
			wave += 1
			var lane := randi() % 6
			var y := box.position.y + 16 + lane * (box.size.y - 32) / 5.0
			var from_left := wave % 2 == 0
			for j in 4:
				var x: float = (box.position.x - 20 - j * 26) if from_left else (box.end.x + 20 + j * 26)
				var bl = b.add(Vector2(x, y), Vector2(135.0 * k * (1 if from_left else -1), 0), 8, Color(1.0, 0.9, 0.3), 2)
				bl.text = "⇒" if from_left else "⇐"
		1:
			# 참/거짓의 벽
			pt = 1.2 / k
			wave += 1
			var kind := 1 if randi() % 2 == 0 else 2
			# 한 번의 공격 안에서는 벽이 한 방향으로만 온다 (파랑과 주황이 겹치면 피할 수 없으므로)
			var from_left2: bool = (b.turn / 4) % 2 == 1
			var x2: float = box.position.x - 14 if from_left2 else box.end.x + 14
			var y2 := box.position.y - 4
			while y2 < box.end.y + 6:
				var bl2 = b.add(Vector2(x2, y2), Vector2(105.0 * k * (1 if from_left2 else -1), 0), 6, Color.WHITE)
				bl2.kind = kind
				y2 += 11.0
		2:
			# 귀류법: 나갔다가 되돌아오는 탄
			pt = 1.3 / k
			spin += 0.37
			var c: Vector2 = box.get_center() + Vector2(randf_range(-40, 40), randf_range(-30, 30))
			for bl3 in b.ring(c, 14, 95.0 * k, 5, Color(0.7, 0.5, 1.0), spin):
				bl3.delay = 0.5
				bl3.life = 4.2
				bl3.r = 5
				bl3.fn = func(q, _d):
					if not q.data.has("rev") and q.age > 1.75:
						q.data["rev"] = true
						q.vel = -q.vel * 1.15
						q.color = Color(1.0, 0.4, 0.6)
			Snd.play("warn")
		_:
			# 귀납법: 도미노
			pt = 2.3 / k
			wave += 1
			var n := 10
			var gap := randi() % n
			var ltr := wave % 2 == 1
			for j in n:
				if j == gap:
					continue
				var col := j if ltr else n - 1 - j
				var x3 := box.position.x + 14 + col * (box.size.x - 28) / float(n - 1)
				for row in 3:
					var bl4 = b.add(Vector2(x3, box.position.y - 16 - row * 13), Vector2(0, 250.0 * k), 6, Color(0.5, 0.9, 1.0) if j > 0 else Color(1.0, 1.0, 0.5))
					bl4.delay = 0.35 + j * 0.17 / k


func not_yet_text() -> Array:
	return ["* 살려 주려 했다.", "* 하지만 BJ KIM은 '일지가 아직 끝나지 않았다'고 했다. (명제 세 문제와 대칭 설명)"]


func kill_text() -> Array:
	return ["* BJ KIM은 'Q.E.D.'라고 속삭이며 초록빛 점들로 흩어졌다... 일지의 빈칸은 끝내 채워지지 않았다."]


func spare_text() -> Array:
	return ["* BJ KIM이 더듬이를 접고 고개를 숙였다. 지구식 인사다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_alien(ci, pos + Vector2(0, 0), t, 1.0, fl, alpha, 1 if spareable else 0)
