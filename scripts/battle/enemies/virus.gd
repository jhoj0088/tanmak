extends "res://scripts/battle/enemy_base.gd"
## 바이러스 — 턴마다 수가 늘어난다(1 → 2 → 4). 탄도 날아가다 둘로 갈라진다. 손을 씻으면 줄어든다.

const Art = preload("res://scripts/art/art.gd")
const Flask = preload("res://scripts/battle/enemies/flask.gd")

var copies := 1
var washed := 0
var masked := false
var flask_t := 0.0


func _init() -> void:
	id = "virus"
	name = "바이러스"
	max_hp = 28
	hp = 28
	atk = 3
	exp_reward = 8
	bg = Color(0.35, 0.15, 0.45)
	acts = ["살펴보기", "손 씻기", "마스크 쓰기"]


func intro() -> String:
	return "* 바이러스가 나타났다! 혼자서는 살 수 없는 주제에 기세가 대단하다."


func flavor(_b) -> String:
	if spareable:
		return "* 바이러스는 비누 거품 속에서 얌전해졌다. (자비를 베풀 수 있다)"
	if copies >= 4:
		return "* 바이러스가 4개로 불어났다! 손을 씻어야 한다."
	return ["* 바이러스가 숙주를 찾아 두리번거린다.", "* 바이러스가 스스로를 복제하고 있다. 다음 턴엔 두 배다.", "* '나는 생물일까?' 바이러스가 잠깐 고민했다."][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "깨끗한 손은...\n못 이기겠네."
	if masked:
		return "마스크라니!\n치사하게!"
	return ["복제! 복제!\n또 복제!", "네 세포 좀\n빌려 쓸게.", "나는 생물과 무생물\n사이의 무언가야."][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 바이러스 - 공격 3 방어 0", "* 숙주 없이는 증식하지 못한다. 턴마다 두 배로 늘어난다. 비누에 약하다."])
		1:
			washed += 1
			copies = 1
			if washed >= 2:
				spareable = true
				Snd.play("correct")
				await b.say(["* 당신은 30초 동안 손가락 사이까지 꼼꼼히 씻었다.", "* 바이러스가 붙을 곳을 잃었다!"])
			else:
				await b.say(["* 당신은 비누로 손을 씻었다.", "* 불어났던 바이러스가 하나로 줄었다. 한 번 더 씻으면...?"])
		2:
			masked = true
			await b.say(["* 당신은 마스크를 썼다.", "* 이번 턴은 바이러스의 탄이 느려진다."])


func begin_attack(b) -> void:
	b.attack_len = 6.5
	pt = 0.4
	flask_t = 2.0


func end_attack(_b) -> void:
	masked = false
	if not spareable:
		copies = mini(copies * 2, 4)


func _copy_pos(b, i: int) -> Vector2:
	if copies == 1:
		return b.enemy_pos
	var box: Rect2 = b.box
	return Vector2(box.position.x + box.size.x * (i + 0.5) / copies, b.enemy_pos.y + 10 + (i % 2) * 24)


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (0.55 if masked else 1.0) * (0.6 if spareable else 1.0)
	pt -= delta
	flask_t -= delta
	if pt <= 0.0:
		pt = (0.9 + copies * 0.35) / k
		for i in copies:
			var src := _copy_pos(b, i)
			spin += 0.5
			# 돌기 탄: 날아가다가 한 번 둘로 갈라진다 (증식)
			for bl in b.ring(src, 6, 78.0 * k, 5, Color(0.5, 1.0, 0.65), spin, 1):
				bl.fn = func(q, _d):
					if not q.data.has("split") and q.age > 1.1:
						q.data["split"] = true
						var ang: float = q.vel.angle()
						var sp: float = q.vel.length()
						q.life = 0.0
						for s in [-0.35, 0.35]:
							var c = b.add(q.pos, Vector2.RIGHT.rotated(ang + s) * sp, 4, Color(0.8, 1.0, 0.5), 1)
							c.data["split"] = true
	if flask_t <= 0.0 and copies >= 2:
		flask_t = 2.2
		Flask.toss(b, Color(0.8, 0.5, 1.0), 6)


func kill_text() -> Array:
	return ["* 바이러스는 단백질 껍질만 남기고 부서졌다."]


func spare_text() -> Array:
	return ["* 바이러스는 '다음엔 손 안 씻은 애를 찾을 거야'라며 떠났다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	if copies == 1:
		Art.draw_virus(ci, pos, t, 1.25, fl, alpha, spareable)
	else:
		for i in copies:
			var x := 320.0 + (i - (copies - 1) / 2.0) * (300.0 / copies)
			Art.draw_virus(ci, Vector2(x, pos.y + 10 + (i % 2) * 24), t + i, 0.75 if copies == 2 else 0.6, fl, alpha, spareable)
