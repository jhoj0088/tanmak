extends "res://scripts/battle/enemy_base.gd"
## 공집합 Ø — 튜토리얼 적. 원소가 없어서 첫 공격은 아무것도 날아오지 않는다.

const Art = preload("res://scripts/art/art.gd")


func _init() -> void:
	id = "empty_set"
	name = "공집합"
	max_hp = 18
	hp = 18
	atk = 2
	exp_reward = 4
	bg = Color(0.15, 0.3, 0.4)
	acts = ["살펴보기", "원소 넣어 주기", "집합이라고 말해 주기"]


func intro() -> String:
	return "* 공집합이 나타났다! ...아무것도 없는 것 같은데."


func flavor(b) -> String:
	if spareable:
		return "* 공집합은 처음으로 채워진 기분이다. (이름이 노랗게 빛난다: 자비를 베풀 수 있다)"
	return ["* 공집합이 허전한 표정으로 서 있다.", "* 바람이 공집합을 그대로 통과했다.", "* 공집합은 자기 원소를 세어 보고 있다. 0개."][b.turn % 3]


func bubble(b) -> String:
	if spareable:
		return "나도...\n집합이구나."
	return [".......", "나는... 아무것도\n아니야...", "원소가...\n하나도 없어..."][b.turn % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 공집합 Ø - 공격 2 방어 0", "* 원소가 하나도 없는 집합. 모든 집합의 부분집합이지만 정작 본인은 모른다."])
		1:
			await b.say(["* 당신은 주머니 속 지우개를 넣어 주려 했다.", "* 원소가 생기면 더는 공집합이 아니게 된다며 정중히 거절당했다."])
		2:
			spareable = true
			Snd.play("correct")
			await b.say(["* 당신은 '공집합도 엄연한 집합이야'라고 말해 주었다.", "* 공집합은 처음으로 존재를 인정받았다!"])


func begin_attack(b) -> void:
	if b.turn == 1:
		b.attack_len = 2.6
		b.note = "(원소가 없어서 아무것도 날아오지 않는다)"
	else:
		b.attack_len = 5.5


func update_attack(b, delta: float) -> void:
	if b.turn == 1:
		return
	pt -= delta
	if pt <= 0.0:
		pt = 0.75 if spareable else 0.42
		var x := randf_range(b.box.position.x + 8, b.box.end.x - 8)
		var bl = b.add(Vector2(x, b.box.position.y - 30), Vector2(0, randf_range(70, 105)), 9, Color(0.8, 0.95, 1.0), 3)
		bl.data["x0"] = x
		bl.data["ph"] = randf() * TAU
		bl.fn = func(q, _d): q.pos.x = q.data["x0"] + sin(q.age * 3.0 + q.data["ph"]) * 18.0


func kill_text() -> Array:
	return ["* 공집합은 정말로 아무것도 남기지 않고 사라졌다."]


func spare_text() -> Array:
	return ["* 공집합은 꾸벅 인사하고 방 구석으로 돌아갔다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_empty_set(ci, pos, t, 1.25, fl, alpha)
