extends "res://scripts/battle/enemy_base.gd"
## 무한대 ∞ — 1챕터 '수열의 다리'에서 발을 헛디디면 나온다. 끝이 없어서 외롭다.
## '같이 세어 주기' 두 번, 또는 '끝을 정해 주기'로 살려 줄 수 있다.

const Art = preload("res://scripts/art/art.gd")

var counted := 0
var ended := false


func _init() -> void:
	id = "infinity"
	name = "무한대"
	max_hp = 30
	hp = 30
	atk = 3
	exp_reward = 6
	bg = Color(0.3, 0.2, 0.45)
	acts = ["살펴보기", "같이 세어 주기", "끝을 정해 주기"]


func intro() -> String:
	return "* 무한대가 빙글빙글 돌며 나타났다! 어디서 시작했는지 본인도 모른다."


func flavor(_b) -> String:
	if spareable:
		return "* 무한대가 처음으로 멈춰 섰다. (자비를 베풀 수 있다)"
	return ["* 무한대가 1, 2, 3... 을 세다가 처음부터 다시 센다.", "* 무한대의 고리 안에서 숫자들이 영원히 돈다.", "* '끝이 없다는 건 멋지지만, 쉴 곳도 없다는 뜻이야.' 무한대가 중얼거렸다."][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "끝이 있어도...\n괜찮구나."
	return ["하나, 둘, 셋...\n...몇까지 셌더라?", "나는 끝나지 않아.\n그래서 아무도\n끝까지 안 있어 줘.", "∞ + 1 = ∞\n뭘 더해도 그대로야."][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 무한대 - 공격 3 방어 0", "* 끝없이 이어지는 수. 아무리 세도 끝나지 않아서, 누가 같이 세 주길 바란다."])
		1:
			counted += 1
			if counted >= 2:
				spareable = true
				Snd.play("correct")
				await b.say(["* 당신은 무한대와 함께 끝까지... 아니, 충분할 때까지 세었다.", "* 무한대는 처음으로 '같이' 세어 본 것 같다."])
			else:
				await b.say(["* 당신은 '하나, 둘, 셋...' 무한대와 같이 숫자를 세기 시작했다.", "* 무한대의 회전이 조금 느려졌다."])
		2:
			var k: int = await b.choose(["∞ + 1 = ∞", "∞ + 1 = ∞ + 1", "∞ + 1 = 0"])
			if k == 0:
				spareable = true
				Game.logic += 1
				Snd.play("correct")
				await b.say(["* '무한대에 1을 더해도 무한대야. 넌 이미 충분히 커.'", "* 무한대가 멈췄다. 처음으로 '충분하다'는 말을 들었다. (논리 +1)"])
			else:
				Snd.play("wrong")
				await b.say(["* 무한대가 고개를 갸웃했다. 고리가 더 빨리 돈다!"])


func begin_attack(b) -> void:
	b.attack_len = 6.0
	pt = 0.3


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (0.6 if spareable else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	if pt > 0.0:
		return
	if b.turn % 2 == 1:
		# 8자 궤도를 도는 탄
		pt = 0.35 / k
		var c: Vector2 = box.get_center()
		var bl = b.add(c, Vector2.ZERO, 5, Color(0.8, 0.65, 1.0))
		bl.life = 5.0
		bl.data["ph"] = randf() * TAU
		bl.data["sp"] = (1.4 + randf() * 0.6) * k
		bl.data["c"] = c
		bl.fn = func(q, _d):
			var a: float = q.data["ph"] + q.age * q.data["sp"]
			var dd := 1.0 + pow(sin(a), 2)
			q.pos = q.data["c"] + Vector2(cos(a) / dd * 120.0, sin(a) * cos(a) / dd * 120.0)
	else:
		# 끝없이 반복되는 줄: 같은 간격으로 계속
		pt = 0.55 / k
		var y := box.position.y + 14 + fposmod(b.attack_t * 47.0, box.size.y - 28)
		b.add(Vector2(box.position.x - 12, y), Vector2(120.0 * k, 0), 5, Color(0.8, 0.65, 1.0), 2).text = "∞"


func kill_text() -> Array:
	return ["* 무한대가... 끝났다. 끝이 있을 수 있다는 걸 마지막에야 알았다."]


func spare_text() -> Array:
	return ["* 무한대는 느긋하게 한 바퀴 돌고 방 저편으로 굴러갔다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_infinity(ci, pos, t, 1.1, fl, alpha, spareable)
