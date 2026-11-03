extends "res://scripts/battle/enemy_base.gd"
## 반례 (검은 백조) — 틀린 답을 고르면 나타난다. '틀렸음을 인정하기'로 살려 줄 수 있다.

const Art = preload("res://scripts/art/art.gd")

var angry := false


func _init() -> void:
	id = "swan"
	name = "반례"
	max_hp = 26
	hp = 26
	atk = 3
	exp_reward = 5
	bg = Color(0.2, 0.2, 0.4)
	acts = ["살펴보기", "틀렸음을 인정하기", "우기기"]


func intro() -> String:
	return "* 반례가 나타났다! '모든 백조는 희다'를 비웃는 검은 백조다."


func flavor(_b) -> String:
	if spareable:
		return "* 반례는 할 일을 다 했다는 표정이다."
	return ["* 반례가 고개를 꼿꼿이 들고 있다.", "* 반례가 깃털을 고르며 당신의 실수를 곱씹는다.", "* '하나면 충분하지.' 반례가 중얼거렸다."][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "인정했으면 됐어."
	if angry:
		return "우긴다고\n참이 되진 않아!"
	return ["반례는 하나면\n충분해.", "네 명제,\n거짓이야.", "'모든'이라는 말을\n쉽게 쓰지 마."][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 반례 - 공격 3 방어 0", "* 단 하나만 있어도 명제를 거짓으로 만든다. 그래서 콧대가 높다."])
		1:
			spareable = true
			Snd.play("correct")
			await b.say(["* 당신은 '내가 틀렸어'라고 인정했다.", "* 반례는 고개를 끄덕였다. 틀린 걸 아는 것이 증명의 시작이다."])
		2:
			angry = true
			await b.say(["* 당신은 '그래도 백조는 전부 희다'고 우겼다.", "* 반례가 깃털을 곤두세웠다! (다음 공격이 거세진다)"])


func begin_attack(b) -> void:
	b.attack_len = 6.0
	pt = 0.4


func end_attack(_b) -> void:
	angry = false


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (0.65 if spareable else 1.0)
	pt -= delta
	if pt > 0.0:
		return
	var src: Vector2 = b.enemy_pos + Vector2(-40, -20)
	if b.turn % 2 == 1:
		# 깃털 부채: 하트를 조준
		pt = 0.95 / k
		var base: float = b.aim(src)
		var n := 2 if angry else 1
		for j in range(-n, n + 1):
			b.add(src, Vector2.RIGHT.rotated(base + j * 0.22) * 150.0 * k, 5, Color(0.6, 0.65, 1.0), 1)
	else:
		# "반례!": 상자 가장자리에서 깜빡이다가 하트를 향해 빠르게 날아온다
		pt = (0.6 if angry else 1.0) / k
		var edge := randi() % 3
		var p := Vector2(randf_range(b.box.position.x, b.box.end.x), b.box.position.y - 14)
		if edge == 1:
			p = Vector2(b.box.position.x - 14, randf_range(b.box.position.y, b.box.end.y))
		elif edge == 2:
			p = Vector2(b.box.end.x + 14, randf_range(b.box.position.y, b.box.end.y))
		var bl = b.add(p, (b.soul - p).normalized() * 240.0 * k, 6, Color(1.0, 0.3, 0.3), 1)
		bl.delay = 0.7
		Snd.play("warn")


func kill_text() -> Array:
	return ["* 반례는 깃털 하나를 남기고 사라졌다. 명제는 여전히 거짓이다."]


func spare_text() -> Array:
	return ["* 반례는 우아하게 헤엄쳐 떠났다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_swan(ci, pos + Vector2(0, 10), t, 1.2, fl, alpha)
