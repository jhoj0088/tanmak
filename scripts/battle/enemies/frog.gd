extends "res://scripts/battle/enemy_base.gd"
## 탈출한 개구리 #7 — 1층 정원 비오톱. 4층 '해부 실습용 개구리 탈출' 공지의 그 개구리.
## '못 본 척하기' 또는 '연못 가리켜 주기'로 살려 줄 수 있다.

const Art = preload("res://scripts/art/art.gd")


func _init() -> void:
	id = "frog"
	name = "개구리 #7"
	max_hp = 30
	hp = 30
	atk = 4
	exp_reward = 10
	bg = Color(0.15, 0.4, 0.2)
	acts = ["살펴보기", "연못 가리켜 주기", "못 본 척하기"]


func intro() -> String:
	return "* 개구리 #7이 펄쩍 뛰어올랐다! 목에 실험실 이름표가 달려 있다."


func flavor(_b) -> String:
	if spareable:
		return "* 개구리 #7이 연못 쪽을 보고 있다. (자비를 베풀 수 있다)"
	return ["* 개구리 #7이 '개굴'하고 울었다. 겁에 질린 것 같다.", "* 4층 공지문이 생각난다. '해부 실습용 개구리 탈출. 발견 시 연락 바람.'", "* 개구리 #7의 다리가 떨린다."][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "개굴...\n(고마워)"
	return ["개굴! 개굴!\n(실험실은 싫어!)", "개굴...\n(다들 날 찾고 있어)", "개구울!\n(뛰어서라도 갈 거야)"][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 개구리 #7 - 공격 4 방어 0", "* 4층 생명과학 실험실에서 탈출했다. 정원 연못까지 3층을 뛰어 내려왔다."])
		1:
			spareable = true
			Snd.play("correct")
			await b.say(["* 당신은 비오톱 연못을 가리켰다. 거기엔 개구리 친구들이 산다.", "* 개구리 #7의 눈이 반짝였다."])
		2:
			spareable = true
			Game.emotion += 1
			await b.say(["* 당신은 고개를 돌리고 휘파람을 불었다. 아무것도 못 봤다.", "* 개구리 #7이 고마운 듯 '개굴' 했다. (감성 +1)"])


func begin_attack(b) -> void:
	b.attack_len = 4.5 if spareable else 6.0
	pt = 0.4


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (0.5 if spareable else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	if pt > 0.0:
		return
	# 펄쩍: 포물선으로 튀어 오르는 물방울
	pt = 0.32 / k
	var from_left := randf() < 0.5
	var x: float = box.position.x - 10 if from_left else box.end.x + 10
	var bl = b.add(Vector2(x, box.end.y - 10), Vector2(randf_range(60, 150) * (1 if from_left else -1), randf_range(-260, -170)) * k, 6, Color(0.5, 0.9, 0.6), 5)
	bl.gravity = 300.0 * k


func kill_text() -> Array:
	return ["* 개구리 #7은 다시 움직이지 않았다. 연못이 바로 저기였는데."]


func spare_text() -> Array:
	return ["* 개구리 #7은 연못으로 뛰어들었다. 첨벙. 개굴개굴 대합창이 시작됐다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_frog(ci, pos + Vector2(0, 20), t, 1.0, fl, alpha, spareable)
