extends "res://scripts/battle/enemy_base.gd"
## 표본 나비 — 핀에 꽂힌 채 살아난 표본. 핀(예고 후 빠르게 떨어짐)과 인분 가루(휘어지는 느린 탄).

const Art = preload("res://scripts/art/art.gd")

var pins := 2
var dust_t := 0.0


func _init() -> void:
	id = "butterfly"
	name = "표본 나비"
	max_hp = 34
	hp = 34
	atk = 3
	exp_reward = 8
	bg = Color(0.15, 0.25, 0.5)
	acts = ["살펴보기", "핀 뽑아 주기", "라벨 읽기"]


func intro() -> String:
	return "* 표본 나비가 상자째 날아올랐다! 핀이 꽂힌 채로 파닥거린다."


func flavor(_b) -> String:
	if spareable:
		return "* 나비가 자유롭게 날갯짓한다. (자비를 베풀 수 있다)"
	if pins == 1:
		return "* 핀이 하나 남았다. 나비가 당신을 기대에 찬 눈으로 본다."
	return ["* 나비의 날개에서 푸른 가루가 떨어진다.", "* 표본 상자의 유리가 덜컹거린다.", "* 나비가 핀을 원망스럽게 내려다본다."][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "...고마워.\n1987년 이후로\n처음 날아 봐."
	if pins == 1:
		return "하나 더...\n하나만 더..."
	return ["움직이면... 아파.", "나는 '보기 좋게'\n고정됐어.", "완벽한 표본은\n움직이지 않는대."][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 표본 나비 - 공격 3 방어 0", "* 가장 아름다운 순간에 고정된 나비. 핀만 없으면 싸울 이유가 없다."])
		1:
			pins -= 1
			if pins == 1:
				await b.say(["* 당신은 노란 핀을 조심스럽게 뽑았다.", "* 나비의 한쪽 날개가 풀려났다! (핀 공격이 사라진다)"])
			else:
				pins = 0
				spareable = true
				Snd.play("correct")
				await b.say(["* 당신은 마지막 빨간 핀을 뽑았다.", "* 나비가 상자 밖으로 날아올랐다!"])
		2:
			await b.say(["* 라벨: 'Morpho. 채집 1987. 상태: 완벽.'", "* 누군가 '완벽'에 줄을 긋고 '답답함'이라고 고쳐 써 놓았다."])


func begin_attack(b) -> void:
	b.attack_len = 6.5
	pt = 0.5
	dust_t = 0.2


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (0.6 if spareable else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	dust_t -= delta
	if pt <= 0.0 and pins >= 2:
		# 핀: 하트의 머리 위에서 깜빡이다가 수직으로 떨어진다
		pt = 0.62 / k
		var x := clampf(b.soul.x + randf_range(-24, 24), box.position.x + 6, box.end.x - 6)
		var bl = b.add(Vector2(x, box.position.y - 12), Vector2(0, 330.0 * k), 5, Color(0.9, 0.9, 1.0), 1)
		bl.delay = 0.55
	if dust_t <= 0.0:
		# 인분 가루: 양 날개에서 흩날리며 휘어진다
		dust_t = (0.16 if pins >= 2 else 0.11) / k
		var side := -1.0 if randf() < 0.5 else 1.0
		var src: Vector2 = b.enemy_pos + Vector2(70 * side, randf_range(-30, 20))
		var bl2 = b.add(src, Vector2(randf_range(-30, 30), randf_range(60, 95) * k), 4, Color(0.4, 0.75, 1.0).lerp(Color(0.8, 0.6, 1.0), randf()))
		bl2.curve = randf_range(-0.9, 0.9)
		bl2.life = 6.0


func kill_text() -> Array:
	return ["* 나비는 푸른 가루가 되어 흩어졌다. 핀 두 개만 남았다."]


func spare_text() -> Array:
	return ["* 나비는 창밖 밤하늘로 날아갔다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_butterfly(ci, pos + Vector2(0, 4), t, 1.05, fl, alpha, pins)
