extends "res://scripts/battle/enemy_base.gd"
## 광자 — 박자에 맞춰 공격하는 첫 적. 입자(레이저)이면서 파동(물결 탄)이다.
## '관측하기'와 '파동이라고 불러 주기'를 둘 다 해 주면 살려 줄 수 있다.

const Art = preload("res://scripts/art/art.gd")

var observed := false
var waved := false
var form := 0        # 이번 턴의 모습: 0 번갈아, 1 입자만, 2 파동만


func _init() -> void:
	id = "photon"
	name = "광자"
	max_hp = 32
	hp = 32
	atk = 3
	exp_reward = 9
	bpm = 120.0
	music = "optics"
	bg = Color(0.4, 0.4, 0.15)
	acts = ["살펴보기", "관측하기", "파동이라고 불러 주기"]


func intro() -> String:
	return "* 광자가 나타났다! 음악의 박자에 맞춰 깜빡인다."


func flavor(_b) -> String:
	if spareable:
		return "* 광자는 입자인 채로, 파동인 채로 편안해 보인다. (자비를 베풀 수 있다)"
	return ["* 광자가 어디에 있는지 정확히 말할 수 없다.", "* 광자가 박자에 맞춰 넘실거린다.", "* 광자는 자기가 점인지 물결인지 고민하고 있다."][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "둘 다여도...\n되는 거였구나."
	if form == 1:
		return "보지 마!\n굳어 버리잖아!"
	if form == 2:
		return "넘실넘실~\n어디에나 있지~"
	return ["난 입자야!\n...아니, 파동인가?", "하나만 고르래.\n다들 그래.", "쿵, 쿵, 쿵, 쿵.\n박자를 놓치지 마."][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 광자 - 공격 3 방어 0", "* 빛 알갱이. 입자이면서 파동이다. 박자마다 공격한다. 어느 한쪽으로만 불리는 걸 싫어한다."])
			return
		1:
			observed = true
			form = 1
			await b.say(["* 당신은 광자를 뚫어지게 쳐다보았다.", "* 관측당한 광자가 점 하나로 굳었다! (이번 턴은 레이저만 쏜다)"])
		2:
			waved = true
			form = 2
			await b.say(["* 당신은 '넌 파동이야'라고 말해 주었다.", "* 광자가 넘실거리기 시작했다! (이번 턴은 물결 탄만 쏜다)"])
	if observed and waved and not spareable:
		spareable = true
		Snd.play("correct")
		await b.say(["* 광자는 입자라고도, 파동이라고도 불려 보았다.", "* 하나만 고르지 않아도 된다는 걸 알았다!"])


func begin_attack(b) -> void:
	b.attack_len = 7.0
	if b.turn == 1:
		b.note = "(상자 테두리가 빛날 때가 박자다)"


func end_attack(_b) -> void:
	form = 0


func update_attack(b, _delta: float) -> void:
	if not b.beat_hit:
		return
	var box: Rect2 = b.box
	var mode: int = form
	if mode == 0:
		mode = 1 if (b.beat_i / 4) % 2 == 1 else 2
	if spareable:
		if b.beat_i % 2 == 0:
			_wave(b, 3, 90.0)
		return
	if mode == 1:
		# 입자: 두 박자마다 하트를 지나는 레이저 (한 박자 예고)
		if b.beat_i % 2 == 0:
			if (b.beat_i / 2) % 2 == 0:
				b.laser(Vector2(box.position.x - 30, b.soul.y), 0.0, b.beat_len(), 0.2, 10, Color(1.0, 0.95, 0.5))
			else:
				b.laser(Vector2(b.soul.x, box.position.y - 30), PI / 2.0, b.beat_len(), 0.2, 10, Color(1.0, 0.95, 0.5))
			Snd.play("warn")
	else:
		_wave(b, 4, 112.0)


## 파동: 물결치며 지나가는 탄 줄
func _wave(b, n: int, speed: float) -> void:
	var box: Rect2 = b.box
	var from_left: bool = b.beat_i % 2 == 0
	var y0 := randf_range(box.position.y + 30, box.end.y - 30)
	for j in n:
		var x: float = (box.position.x - 14 - j * 20) if from_left else (box.end.x + 14 + j * 20)
		var bl = b.add(Vector2(x, y0), Vector2(speed * (1 if from_left else -1), 0), 5, Color(0.6, 1.0, 0.9))
		bl.data["y0"] = y0
		bl.data["ph"] = j * 0.7
		bl.fn = func(q, _d): q.pos.y = q.data["y0"] + sin(q.age * 7.0 + q.data["ph"]) * 18.0


func kill_text() -> Array:
	return ["* 광자는 어딘가에 흡수되어 사라졌다."]


func spare_text() -> Array:
	return ["* 광자는 초속 30만 킬로미터로 인사하고 떠났다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_photon(ci, pos, t, 1.0, fl, alpha, form)
