extends "res://scripts/battle/enemy_base.gd"
## GIL — 수학 교원연구실의 숨은 보스. 네모난 얼굴에 크고 동그란 빨간 안경 (이스터에그).

const Art = preload("res://scripts/art/art.gd")

var talk := 0
var angry := false
var last_talk := false
var hurt := false
var ring_t := 0.0
var pattern := 0


func _init() -> void:
	id = "redpen"
	name = "GIL"
	max_hp = 80
	hp = 80
	atk = 4
	def = 1
	exp_reward = 12
	bg = Color(0.4, 0.1, 0.15)
	acts = ["살펴보기", "질문하기", "답안지 내밀기"]


func intro() -> String:
	return "* GIL이 앞을 가로막았다! 채점할 답안지를 찾고 있다."


func flavor(b) -> String:
	if spareable:
		return "* GIL은 더 이상 싸울 마음이 없어 보인다."
	if hp < max_hp / 3:
		return "* GIL의 잉크가 거의 바닥났다."
	return ["* GIL이 잉크를 뚝뚝 흘린다.", "* 교무실에 잉크 냄새가 가득하다.", "* GIL이 허공에 동그라미를 그린다."][b.turn % 3]


func bubble(b) -> String:
	var s := ""
	if angry:
		s = "채점 시간이다아아!"
	elif spareable:
		s = "...좋은 질문이네요.\n요즘 학생들은\n질문을 안 하거든요."
	elif last_talk:
		s = "질문...?\n지금 질문한 거예요?"
	elif hurt:
		s = "아야!\n선생님한테 무슨 짓이에요!"
	else:
		s = ["답안지를\n제출하세요.", "틀렸어요. 틀렸어.\n전부 틀렸어!", "빨간 줄...\n빨간 줄이 필요해..."][b.turn % 3]
	hurt = false
	last_talk = false
	return s


func on_hurt(_b, _dmg: int) -> void:
	hurt = true


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* GIL - 공격 4 방어 1", "* 크고 동그란 빨간 안경 너머로 답안을 본다. 틀린 곳에 빨간 줄을 긋지 않으면 잠을 못 잔다."])
		1:
			talk += 1
			last_talk = true
			if talk == 1:
				await b.say(["* 당신은 수업 시간에 이해 못 했던 부분을 질문했다.", "* GIL의 펜 끝이 살짝 떨렸다."])
			else:
				spareable = true
				Snd.play("correct")
				await b.say(["* 당신은 한 번 더, 진지하게 질문했다.", "* GIL은 누군가 질문해 준 게 아주 오랜만인 것 같다."])
		2:
			angry = true
			await b.say(["* 당신은 구겨진 답안지를 내밀었다.", "* GIL이 신나서 채점하기 시작했다! (다음 공격이 거세진다)"])


func begin_attack(b) -> void:
	b.attack_len = 5.0 if spareable else 7.0
	pattern = 4 if (spareable and not angry) else (b.turn - 1) % 4
	ring_t = 0.8
	spin = randf() * TAU


func end_attack(_b) -> void:
	angry = false


func update_attack(b, delta: float) -> void:
	pt -= delta
	ring_t -= delta
	var k: float = b.hard() + (0.35 if angry else 0.0)
	var src: Vector2 = b.enemy_pos + Vector2(0, 40)
	var box: Rect2 = b.box
	match pattern:
		0:  # 동그라미 채점
			if pt <= 0.0:
				pt = 0.42 / k
				b.ring(src, 14, 80.0 * k, 6, Color(1, 0.3, 0.45), spin)
				spin += 0.19
		1:  # 빨간 줄 긋기
			if pt <= 0.0:
				pt = 0.7 / k
				var base: float = b.aim(src)
				for j in range(-2, 3):
					b.add(src, Vector2.RIGHT.rotated(base + j * 0.2) * 150.0 * k, 5, Color(0.95, 0.1, 0.15), 1)
				for j in 3:
					b.add(src, Vector2.RIGHT.rotated(randf_range(0.3, PI - 0.3)) * randf_range(60, 100), 4, Color(0.75, 0.35, 1.0))
		2:  # 채점 소용돌이
			if pt <= 0.0:
				pt = 0.09 / k
				for j in 2:
					var bl = b.add(src, Vector2.RIGHT.rotated(spin + PI * j) * 95.0 * k, 5, Color(1, 0.55, 0.2) if j == 0 else Color(1, 0.9, 0.3), 1)
					bl.curve = 0.35 if j == 0 else -0.35
				spin += 0.33
		3:  # 0점 소나기
			if pt <= 0.0:
				pt = 0.075 / k
				var x := randf_range(box.position.x - 20, box.end.x + 20)
				b.add(Vector2(x, 165), Vector2(randf_range(-15, 15), randf_range(110, 170) * k), 4, Color(0.8, 0.6, 1.0), 1)
			if ring_t <= 0.0:
				ring_t = 1.6 / k
				var c := Vector2(randf_range(box.position.x + 40, box.end.x - 40), 160)
				for j in 12:
					var a := TAU * j / 12.0
					var bl2 = b.add(c + Vector2.RIGHT.rotated(a) * 10, Vector2.RIGHT.rotated(a) * 30 + Vector2(0, 55), 7, Color(1, 0.25, 0.3))
					bl2.accel = 10.0
		_:
			if pt <= 0.0:
				pt = 0.55
				b.ring(src, 8, 60.0, 6, Color(1, 0.7, 0.8), spin)
				spin += 0.3


func kill_text() -> Array:
	return ["* GIL은 잉크 얼룩이 되어 흩어졌다..."]


func spare_text() -> Array:
	return ["* GIL은 조용히 채점하던 자리로 돌아갔다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_redpen(ci, pos, t, 1.25, fl, alpha)
