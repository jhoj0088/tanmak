extends "res://scripts/battle/enemy_base.gd"
## 세탁기 — 4챕터 기숙사 세탁실. 누군가 빨래를 넣고 잊어버려서 몇 주째 혼자 돌고 있다.
## 살려 주는 방법: '빨래 꺼내 주기' 두 번 (어둠 속에서 싸운다).

const Art = preload("res://scripts/art/art.gd")

var taken := 0
var spin_dir := 1.0


func _init() -> void:
	id = "washer"
	name = "세탁기"
	max_hp = 44
	hp = 44
	atk = 4
	exp_reward = 12
	bg = Color(0.2, 0.3, 0.4)
	acts = ["살펴보기", "빨래 꺼내 주기", "일시 정지 누르기"]


func intro() -> String:
	return "* 세탁기가 덜컹거리며 다가온다! 문 안에서 양말들이 빙글빙글 돈다."


func flavor(_b) -> String:
	if spareable:
		return "* 세탁기가 '삐-삐-' 하고 종료음을 냈다. 개운해 보인다. (자비를 베풀 수 있다)"
	return ["* 세탁기 안에서 짝 잃은 양말 하나가 돈다.", "* '헹굼... 헹굼... 헹굼...' 세탁기가 같은 단계를 반복한다.", "* 세탁실이 어둡다. 세탁기 표시등만 깜빡인다."][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "삐-삐-\n세탁이\n완료되었습니다."
	return ["누가 넣고 갔어...\n3주째야...\n3주째 돌고 있어...", "탈수!\n탈수 들어간다!", "짝 잃은 양말은\n어디로 가는 걸까..."][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 세탁기 - 공격 4 방어 0", "* 기숙사 세탁실의 2번 세탁기. 주인이 빨래를 잊고 간 뒤로 멈추는 법을 잊었다."])
		1:
			taken += 1
			if taken >= 2:
				spareable = true
				Snd.play("correct")
				await b.say(["* 당신은 남은 빨래를 전부 꺼내 개켜 주었다. 체육복에 '절규'라고 적혀 있다.", "* 세탁기가 드디어 멈췄다. 3주 만의 휴식이다."])
			else:
				await b.say(["* 당신은 문을 열고 빨래 한 아름을 꺼냈다. 아직 반이 남았다."])
		2:
			spin_dir = -spin_dir
			await b.say(["* 당신은 일시 정지 버튼을 눌렀다.", "* 세탁기가 반대 방향으로 돌기 시작했다. ...고장 난 것 같다."])


func begin_attack(b) -> void:
	b.attack_len = 4.5 if spareable else 6.5
	b.dark = 0.0 if spareable else 90.0
	pt = 0.2


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (0.5 if spareable else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	spin += delta * 1.6 * spin_dir * k
	if pt > 0.0:
		return
	if b.turn % 2 == 1:
		# 세탁조: 회전하는 고리에서 탄이 흘러나온다
		pt = 0.14 / k
		var c: Vector2 = box.get_center()
		for j in 2:
			var a: float = spin + PI * j
			b.add(c + Vector2.RIGHT.rotated(a) * 20.0, Vector2.RIGHT.rotated(a + 0.4 * spin_dir) * 90.0 * k, 4.5, Color.from_hsv(fmod(spin * 0.1 + j * 0.5, 1.0), 0.45, 1.0))
	else:
		# 탈수: 잠잠하다가 한꺼번에 튀어나간다
		pt = 1.4 / k
		var c2: Vector2 = box.get_center() + Vector2(randf_range(-50, 50), randf_range(-30, 30))
		for bl in b.ring(c2, 16, 30.0, 5, Color(0.7, 0.9, 1.0), spin):
			bl.accel = 140.0 * k
			bl.delay = 0.45
		Snd.play("warn")


func kill_text() -> Array:
	return ["* 세탁기가 연기를 뿜으며 멈췄다. 안에서 양말 한 짝이 굴러 나왔다."]


func spare_text() -> Array:
	return ["* 세탁기가 문을 활짝 열고 조용해졌다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_washer(ci, pos + Vector2(0, 8), t, 0.95, fl, alpha, spareable)
