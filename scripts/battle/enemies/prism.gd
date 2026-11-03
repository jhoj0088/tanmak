extends "res://scripts/battle/enemy_base.gd"
## 프리즘 — 박자에 맞춰 흰 레이저를 무지개 부채로 가른다.

const Art = preload("res://scripts/art/art.gd")
const RAINBOW := [Color(1, 0.25, 0.3), Color(1, 0.9, 0.3), Color(0.5, 1, 0.4), Color(0.4, 1, 0.85), Color(0.5, 0.45, 1), Color(0.85, 0.45, 1)]

var lit := 0
var polished := false


func _init() -> void:
	id = "prism"
	name = "프리즘"
	max_hp = 36
	hp = 36
	atk = 3
	def = 1
	exp_reward = 9
	bpm = 120.0
	music = "optics"
	bg = Color(0.3, 0.2, 0.45)
	acts = ["살펴보기", "빛 비춰 주기", "닦아 주기"]


func intro() -> String:
	return "* 프리즘이 나타났다! 어두운 암실에서는 그냥 유리 덩어리다."


func flavor(_b) -> String:
	if spareable:
		return "* 프리즘이 무지개를 벽에 비추며 뽐내고 있다. (자비를 베풀 수 있다)"
	return ["* 프리즘이 빛을 찾아 두리번거린다.", "* 프리즘의 모서리가 날카롭게 반짝인다.", "* '흰색은 색이 아니야. 전부야.' 프리즘이 중얼거렸다."][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "봤어? 봤지?\n나 이런 것도 해."
	if polished:
		return "어... 고마워.\n지문 싫어했는데."
	return ["암실에선 아무도\n날 안 봐.", "빛만 있으면\n나도 빛나는데.", "흰색을 가르면\n일곱 빛깔이야!"][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 프리즘 - 공격 3 방어 1", "* 빛을 색깔별로 꺾는다. 파장이 짧을수록 더 많이 꺾인다. 빛을 받으면 기뻐한다."])
		1:
			lit += 1
			if lit == 1:
				await b.say(["* 당신은 휴대폰 손전등을 프리즘에 비추었다.", "* 벽에 작은 무지개가 생겼다. 프리즘이 깜짝 놀랐다. 한 번 더...?"])
			else:
				spareable = true
				Snd.play("correct")
				await b.say(["* 당신은 각도를 바꿔 가며 빛을 비추었다.", "* 암실 가득 무지개가 퍼졌다! 프리즘이 행복해한다."])
		2:
			polished = true
			await b.say(["* 당신은 소매로 프리즘의 지문을 닦아 주었다.", "* 이번 턴은 프리즘의 공격이 느슨해진다."])


func begin_attack(b) -> void:
	b.attack_len = 7.0


func end_attack(_b) -> void:
	polished = false


func update_attack(b, _delta: float) -> void:
	if not b.beat_hit:
		return
	var k: float = (0.7 if polished else 1.0) * (0.6 if spareable else 1.0)
	var src: Vector2 = b.enemy_pos + Vector2(20, 50)
	if b.beat_i % 2 == 0:
		# 무지개 부채: 박자마다 방향이 조금씩 돈다
		var base: float = PI / 2.0 + sin(b.beat_i * 0.8) * 0.45
		var n := 3 if spareable else 5
		for j in n:
			var ang: float = base + (j - (n - 1) / 2.0) * 0.2
			b.add(src, Vector2.RIGHT.rotated(ang) * 110.0 * k, 5, RAINBOW[j % RAINBOW.size()], 1)
	if b.beat_i % 4 == 3 and not spareable:
		# 흰 빛: 하트 높이를 가로지르는 레이저
		b.laser(Vector2(b.box.position.x - 30, b.soul.y), 0.0, b.beat_len(), 0.2, 9, Color(1, 1, 1))
		Snd.play("warn")


func kill_text() -> Array:
	return ["* 프리즘은 금이 가더니 조각조각 흩어졌다. 조각마다 작은 무지개가 맺혔다."]


func spare_text() -> Array:
	return ["* 프리즘은 무지개를 끌고 암실 구석으로 굴러갔다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_prism(ci, pos + Vector2(0, 10), t, 1.0, fl, alpha, spareable)
