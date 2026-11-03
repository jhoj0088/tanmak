extends "res://scripts/battle/enemy_base.gd"
## 알람 시계 — 4챕터 잡몹. 어둠 속 전투를 처음 가르친다.
## '끄기 버튼 누르기'를 두 번 하면 조용해진다. '5분만 더'는 더 시끄럽게 만든다.

const Art = preload("res://scripts/art/art.gd")

var pressed := 0
var snoozed := false


func _init() -> void:
	id = "alarm"
	name = "알람 시계"
	max_hp = 36
	hp = 36
	atk = 4
	exp_reward = 10
	bg = Color(0.4, 0.2, 0.15)
	acts = ["살펴보기", "끄기 버튼 누르기", "5분만 더..."]


func intro() -> String:
	return "* 알람 시계가 울부짖는다! 누군가 새벽 6시에 맞춰 놓고 그대로 잠든 모양이다."


func flavor(_b) -> String:
	if spareable:
		return "* 알람 시계가 조용해졌다. 째깍째깍 소리만 난다. (자비를 베풀 수 있다)"
	return ["* 따르르르르릉!", "* 알람 시계가 침대 주인을 찾아 두리번거린다.", "* 어둠 속에서는 하트 주변과 바라보는 방향만 보인다."][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "...일어난 거 맞지?\n믿는다."
	if snoozed:
		return "5분?!\n5분이 50분 된다!!"
	return ["일어나!!\n일어나라고!!", "따르릉!\n지각이야 지각!", "점호 시간에\n누가 자래!"][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 알람 시계 - 공격 4 방어 0", "* 주인이 일어날 때까지 절대 멈추지 않는다. 버튼을 두 번 눌러야 꺼진다."])
		1:
			pressed += 1
			if pressed >= 2:
				spareable = true
				Snd.play("correct")
				await b.say(["* 당신은 버튼을 한 번 더 꾹 눌렀다.", "* 알람이 멈췄다. 기숙사가 다시 조용해졌다."])
			else:
				await b.say(["* 당신은 끄기 버튼을 눌렀다.", "* 소리가 조금 작아졌다. 한 번 더 눌러야 할 것 같다."])
		2:
			snoozed = true
			await b.say(["* 당신은 '5분만 더...'라고 중얼거렸다.", "* 알람 시계가 격분했다! (다음 공격이 거세진다)"])


func begin_attack(b) -> void:
	b.attack_len = 6.0
	b.dark = 78.0
	b.note = "(어둡다. 움직인 방향으로 손전등이 비친다)" if b.turn == 1 else ""
	pt = 0.5


func end_attack(_b) -> void:
	snoozed = false


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (1.35 if snoozed else 1.0) * (0.6 if spareable else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	if pt > 0.0:
		return
	if b.turn % 2 == 1:
		# 따르릉: 상자 귀퉁이에서 번갈아 퍼지는 소리
		pt = 0.8 / k
		spin += 1.0
		var corners := [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]
		var c: Vector2 = corners[int(spin) % 4]
		b.ring(c, 14, 78.0 * k, 5, Color(1.0, 0.8, 0.3), spin * 0.2, 3)
	else:
		# 시곗바늘: 위에서 떨어지는 초침
		pt = 0.3 / k
		var x := randf_range(box.position.x + 6, box.end.x - 6)
		b.add(Vector2(x, box.position.y - 12), Vector2(0, 135.0 * k), 4.5, Color(1.0, 0.4, 0.4), 1)


func kill_text() -> Array:
	return ["* 알람 시계는 태엽을 쏟으며 멈췄다. 누군가는 내일 지각할 것이다."]


func spare_text() -> Array:
	return ["* 알람 시계는 침대 머리맡으로 돌아갔다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_alarm(ci, pos + Vector2(0, 5), t, 1.1, fl, alpha, not spareable)
