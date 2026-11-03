extends "res://scripts/battle/enemy_base.gd"
## 효소 가위 — 2챕터 '소포체 미로'의 잡몹. 무엇이든 자르고 싶어 한다.
## 살려 주는 방법: '기질 건네주기'(맞는 기질을 고른다) 또는 '체온 맞춰 주기' 두 번.

const Art = preload("res://scripts/art/art.gd")

var fed := false
var warm := 0
var angry := false


func _init() -> void:
	id = "enzyme"
	name = "효소 가위"
	max_hp = 34
	hp = 34
	atk = 3
	exp_reward = 8
	bg = Color(0.4, 0.25, 0.15)
	acts = ["살펴보기", "기질 건네주기", "체온 맞춰 주기"]


func intro() -> String:
	return "* 효소 가위가 철컥거리며 다가왔다! 자를 것을 찾고 있다."


func flavor(_b) -> String:
	if spareable:
		return "* 효소 가위가 딱 맞는 기질을 꼭 쥐고 있다. (자비를 베풀 수 있다)"
	return ["* 효소 가위가 허공을 싹둑 잘랐다.", "* '나는 아무거나 안 잘라. 딱 맞는 것만 잘라.' 효소가 투덜댄다.", "* 효소 가위의 날이 체온보다 조금 차갑다."][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "딱 맞아...\n자물쇠와 열쇠처럼."
	if angry:
		return "그건 내 기질이\n아니야! 싹둑!"
	return ["자를 거야!\n뭐든! ...아니,\n맞는 것만!", "싹둑. 싹둑.\n탄도 잘라 줄게.", "온도가 안 맞아...\n기운이 없어..."][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 효소 가위 - 공격 3 방어 0", "* 생명체의 화학 반응을 돕는 단백질. 딱 맞는 상대(기질)에만 작용한다. 체온에서 가장 기운이 난다."])
		1:
			await b.say(["* 무엇을 건네줄까?"])
			var k: int = await b.choose(["녹말 (아밀레이스에게)", "아무거나 집히는 것", "탄막 조각"])
			if k == 0:
				fed = true
				Game.logic += 1
				Snd.play("correct")
				await b.say(["* 효소 가위가 녹말을 받아 들고 눈을 반짝였다. 딱 맞는 기질이다! (논리 +1)"])
			else:
				angry = true
				Snd.play("wrong")
				await b.say(["* 효소 가위가 화를 냈다! 맞지 않는 건 자르지 않는다! (다음 공격이 거세진다)"])
		2:
			warm += 1
			if warm >= 2:
				fed = true
				await b.say(["* 당신은 두 손으로 효소를 감싸 체온(약 37°C)으로 데워 주었다.", "* 효소 가위의 날이 따뜻해졌다. 기운이 난다!"])
			else:
				await b.say(["* 당신은 효소 가위에 입김을 불어 주었다. 조금 따뜻해졌다. 한 번 더?"])
	if fed and not spareable:
		spareable = true
		Snd.play("correct")


func begin_attack(b) -> void:
	b.attack_len = 6.0
	pt = 0.4


func end_attack(_b) -> void:
	angry = false


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (1.25 if angry else 1.0) * (0.6 if spareable else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	if pt > 0.0:
		return
	if b.turn % 2 == 1:
		# 가위질: 가로 레이저가 지나간 자리의 탄이 두 조각으로 갈라진다
		pt = 1.1 / k
		var y := randf_range(box.position.y + 20, box.end.y - 20)
		b.laser(Vector2(box.position.x - 30, y), 0.0, 0.7, 0.2, 8, Color(1.0, 0.6, 0.3))
		for j in 6:
			var bl = b.add(Vector2(box.position.x + 20 + j * 45, box.position.y - 10), Vector2(0, 80.0 * k), 6, Color(1.0, 0.75, 0.45), 5)
			bl.data["y"] = y
			bl.fn = func(q, _d):
				if q.pos.y >= q.data["y"] and not q.data.has("cut"):
					q.data["cut"] = true
					b.burst(q, 2, 90.0 * k, 4, Color(1.0, 0.75, 0.45), 0.2)
		Snd.play("warn")
	else:
		# 철컥: 양쪽에서 가위 날처럼 닫히는 탄
		pt = 0.9 / k
		for side in [-1.0, 1.0]:
			var x: float = box.position.x - 10 if side < 0 else box.end.x + 10
			for j in 5:
				var a: float = (0.5 - j * 0.25) * side
				b.add(Vector2(x, box.get_center().y), Vector2(-side * 110.0 * k, 0).rotated(a), 5, Color(0.95, 0.55, 0.3), 1)


func kill_text() -> Array:
	return ["* 효소 가위가 변성되어 굳어 버렸다. 다시는 무엇도 자르지 못한다."]


func spare_text() -> Array:
	return ["* 효소 가위는 녹말을 안고 소포체 속으로 사라졌다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_enzyme(ci, pos + Vector2(20, 0), t, 1.0, fl, alpha, spareable)
