extends "res://scripts/battle/enemy_base.gd"
## 유성우 — 5장 옥상 잡몹. 빛이 꼬리를 끌며 대각선으로 쏟아진다.
## '소원 빌기'를 두 번 하면 살려 줄 수 있다.

const Art = preload("res://scripts/art/art.gd")
var wishes := 0


func _init() -> void:
	id = "meteor"
	name = "유성우"
	max_hp = 32
	hp = 32
	atk = 4
	exp_reward = 10
	bg = Color(0.08, 0.1, 0.3)
	acts = ["살펴보기", "소원 빌기", "개수 세기"]


func intro() -> String:
	return "* 하늘에서 유성우가 쏟아져 내렸다! 다들 소원을 빌 틈도 없이 바쁘다."


func flavor(_b) -> String:
	if spareable:
		return "* 유성우가 천천히 떨어진다. 소원을 다 들은 것 같다. (자비를 베풀 수 있다)"
	return ["* 유성 하나가 '나 좀 봐 줘!' 하고 지나갔다.", "* 코어가 '불규칙한 빛'이라며 유성을 지우려 한다.", "* 꼬리가 길수록 빠르다. 소원을 빌 시간은 짧다."][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "들었어!\n네 소원, 꼭\n가져갈게!"
	return ["아무도 날\n안 봐!\n다들 고개 숙여!", "1초면 끝나!\n빨리 빌어!", "지워지기 전에\n누군가 봐 줘!"][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 유성우 - 공격 4 방어 0", "* 우주 먼지가 대기에 부딪쳐 타는 빛. 1초도 안 되는 시간 동안 누군가 봐 주기를 기다린다."])
		1:
			wishes += 1
			Snd.play("correct")
			if wishes >= 2:
				spareable = true
				await b.say(["* 당신은 한 번 더 소원을 빌었다. '...다 같이 무사히 아침을 맞게 해 주세요.'", "* 유성우가 반짝 웃었다!"])
			else:
				await b.say(["* 당신은 눈을 감고 소원을 빌었다. '과제 다 하게 해 주세요.'", "* 유성 하나가 '그건 네가 해야지' 하고 지나갔다."])
		2:
			await b.say(["* 하나, 둘, 셋... 세다가 놓쳤다.", "* 유성우는 세어 주는 것보다 봐 주는 걸 더 좋아하는 것 같다."])


func begin_attack(b) -> void:
	b.attack_len = 4.5 if spareable else 7.0
	pt = 0.3


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (0.5 if spareable else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	if pt > 0.0:
		return
	pt = 0.22 / k
	# 오른쪽 위에서 왼쪽 아래로: 머리 하나 + 꼬리 셋
	var start := Vector2(randf_range(box.position.x + 20, box.end.x + 120), box.position.y - 20)
	var v := Vector2(-150, 210).normalized() * randf_range(190, 250) * k
	var head = b.add(start, v, 6, Color(1.0, 0.95, 0.7), 0)
	for j in 3:
		var tail = b.add(start - v.normalized() * (10 + j * 9), v, 4 - j, Color(0.6, 0.75, 1.0, 0.8 - j * 0.2), 0)
		tail.delay = 0.0


func kill_text() -> Array:
	return ["* 유성우가 그쳤다. 하늘이 조금 덜 반짝인다."]


func spare_text() -> Array:
	return ["* 유성우는 천천히 하늘로 흩어졌다. 마지막 하나가 손을 흔들었다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_meteor(ci, pos + Vector2(0, 10), t, 1.0, fl, alpha)
