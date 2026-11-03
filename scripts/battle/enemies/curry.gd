extends "res://scripts/battle/enemy_base.gd"
## 카레 냄비 — 2층 급식실의 숨은 보스. "월요일 카레, 화요일 카레, 수요일 카레"의 화신.
## 살려 주는 방법: '맛있다고 말하기' 두 번. '목요일 짜장 이야기'는 금기.

const Art = preload("res://scripts/art/art.gd")

var praised := 0
var angry := false
var pattern := 0


func _init() -> void:
	id = "curry"
	name = "카레 냄비"
	max_hp = 90
	hp = 90
	atk = 4
	def = 1
	exp_reward = 18
	boss = false
	music = "battle"
	bg = Color(0.5, 0.35, 0.1)
	acts = ["살펴보기", "맛있다고 말하기", "목요일 짜장 이야기"]


func intro() -> String:
	return "* 카레 냄비가 부글부글 끓어올랐다! 급식실 전체에 카레 향이 진동한다."


func flavor(_b) -> String:
	if spareable:
		return "* 카레 냄비가 뿌듯하게 김을 뿜는다. (자비를 베풀 수 있다)"
	return ["* 카레 냄비 속에서 감자가 헤엄친다.", "* '이번 주 급식표를 봤나? 월 카레, 화 카레, 수 카레...'", "* 카레 냄새가 갓 지은 밥 냄새와 섞였다. 배가 고프다.",
			"* 맛있다고 한 횟수: %d / 2" % praised][randi() % 4]


func bubble(b) -> String:
	pattern = (b.turn - 1) % 2
	if spareable:
		return "맛있다고...?\n3년 동안 처음\n들어 보는군."
	if angry:
		return "짜장이라니!!\n짜장 얘기는\n하지 마라!!"
	return ["한 그릇 더!\n남기면 벌점!", "카레는\n사흘째가 제일\n맛있는 법이다.", "급식 판이\n비어 있군!\n채워 주마!"][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 카레 냄비 - 공격 4 방어 1", "* 3년째 매주 사흘씩 급식에 나온다. 학생들이 '또 카레야'라고 할 때마다 조금씩 상처받았다."])
		1:
			praised += 1
			if praised >= 2:
				spareable = true
				Snd.play("correct")
				await b.say(["* 당신은 '사실 급식 카레가 제일 맛있어요'라고 진심으로 말했다.", "* 카레 냄비가 끓는 걸 멈추고 조용히 떨었다. ...감동한 것 같다."])
			else:
				await b.say(["* 당신은 '카레 냄새 좋네요'라고 말했다.", "* 카레 냄비의 거품이 조금 잦아들었다."])
		2:
			angry = true
			await b.say(["* 당신은 '목요일 짜장이 기대돼요'라고 말했다.", "* 카레 냄비가 폭발할 듯 끓어오른다! (다음 공격이 거세진다)"])


func begin_attack(b) -> void:
	b.attack_len = 4.5 if spareable else 7.0
	pt = 0.3


func end_attack(_b) -> void:
	angry = false


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (1.3 if angry else 1.0) * (0.5 if spareable else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	if pt > 0.0:
		return
	if pattern == 0:
		# 밥알 비 + 카레 방울이 떨어져 튄다
		pt = 0.11 / k
		var x := randf_range(box.position.x, box.end.x)
		if randi() % 5 == 0:
			var drop = b.add(Vector2(x, box.position.y - 14), Vector2(0, 90.0 * k), 7, Color(0.95, 0.6, 0.1), 5)
			drop.data["y"] = randf_range(box.position.y + 50, box.end.y - 20)
			drop.fn = func(q, _d):
				if q.pos.y >= q.data["y"]:
					b.burst(q, 6, 80.0 * k, 4, Color(0.95, 0.6, 0.1), 0.5)
		else:
			b.add(Vector2(x, box.position.y - 10), Vector2(randf_range(-10, 10), 140.0 * k), 3, Color(1, 1, 0.95), 1)
	else:
		# 국자질: 냄비에서 포물선으로 퍼지는 카레
		pt = 0.65 / k
		var src: Vector2 = b.enemy_pos + Vector2(0, 30)
		for j in 7:
			var bl = b.add(src, Vector2(randf_range(-150, 150), randf_range(-160, -60)) * k, 6, Color(0.95, 0.6, 0.1), 5)
			bl.gravity = 260.0 * k


func kill_text() -> Array:
	return ["* 카레 냄비가 바닥을 드러냈다. 내일부터 급식은... 짜장일지도 모른다."]


func spare_text() -> Array:
	return ["* 카레 냄비가 '다 먹고 가라'며 한 국자를 퍼 주었다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_curry(ci, pos + Vector2(0, 10), t, 1.05, fl, alpha, spareable)
