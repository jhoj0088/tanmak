extends "res://scripts/battle/enemy_base.gd"
## 주T — 4챕터 리틀 보스. 기숙사 사감. 엄하지만 속정이 깊다.
##
## 공격 4종:
##   1) 천자문      어둠 속에서 네 글자씩 줄지어 지나가는 한자
##   2) CCTV 확인   파란 시야가 상자를 훑는다. 시야 안에서는 멈춰야 한다 (움직이면 발각)
##   3) 점호        부른 번호의 칸에 서 있어야 한다
##   4) 손전등 수색 아주 어두운 상자 + 한자 고리
## 살려 주는 방법: 점호에 바르게 대답하고, 사유서를 솔직하게 쓰고, 벌점을 받아들인다 (순서 무관).

const Art = preload("res://scripts/art/art.gd")
const CHARS := "天地玄黃宇宙洪荒日月盈昃辰宿列張寒來暑往秋收冬藏"

var answered := false
var wrote := false
var accepted := false
var angry := false
var hurt := false
var pattern := 0
var wave := 0
var char_i := 0
var call_t := 0.0
var call_n := -1
var check_t := 0.0
var check_flash := 0.0
var aim_t := 0.0


func _init() -> void:
	id = "jut"
	name = "주T"
	max_hp = 170
	hp = 170
	atk = 4
	def = 1
	exp_reward = 38
	boss = true
	music = "boss"
	can_flee = false
	bg = Color(0.2, 0.2, 0.45)
	acts = ["살펴보기", "점호에 대답하기", "사유서 쓰기", "벌점 받기"]


func intro() -> String:
	return "* 주T가 호루라기를 물었다! 점호가 시작된다."


func _progress() -> int:
	return int(answered) + int(wrote) + int(accepted)


func _check_spare() -> void:
	if _progress() >= 3 and not spareable:
		spareable = true
		Snd.play("correct")


func flavor(_b) -> String:
	if spareable:
		return "* 주T가 벌점 수첩을 덮었다. (자비를 베풀 수 있다)"
	if hp < max_hp / 3:
		return "* 주T의 호루라기 소리가 갈라진다."
	return ["* 주T가 손전등으로 구석구석을 비춘다.", "* 복도 끝 CCTV의 빨간 불이 깜빡인다.", "* 주T가 벌점 수첩을 넘긴다. 당신 이름이 벌써 적혀 있다.",
			"* 한 일: %d / 3  (대답 · 사유서 · 벌점)" % _progress()][randi() % 4]


func bubble(b) -> String:
	pattern = (b.turn - 1) % 4
	if spareable:
		return "...됐다.\n다음부턴 야자 끝나면\n바로 들어와라. 이상."
	var head := ""
	if angry:
		head = "거짓말은 벌점 두 배!\n"
	elif hurt:
		head = "사감한테 대드나!\n"
	hurt = false
	match pattern:
		0:
			return head + "잠이 안 오면\n천자문을 외워라.\n하늘 천, 땅 지!"
		1:
			return head + "CCTV 확인한다.\n파란 불빛 안에서는\n꼼짝 마라!"
		2:
			return head + "점호!\n부르는 번호 칸에\n똑바로 선다. 실시!"
		_:
			return head + "소등!\n손전등 수색이다."


func on_hurt(_b, _dmg: int) -> void:
	hurt = true


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 주T - 공격 4 방어 1", "* 기숙사 사감. 밤마다 304호 앞에서 발소리를 죽인다. 깨우지 않으려고.",
				"* 점호에 대답하고, 사유서를 솔직히 쓰고, 벌점을 받아들이면 물러난다."])
		1:
			if answered:
				await b.say(["* 이미 대답했다. 주T가 고개를 끄덕인다."])
				return
			await b.say(["주T: 번호! 자네는 몇 호 학생인가?"])
			var k: int = await b.choose(["403호입니다", "304호입니다", "340호입니다"])
			if k == 1:
				answered = true
				Game.logic += 1
				Snd.play("correct")
				await b.say(["* '304호, 이상 없습니다!'", "주T: ...목소리는 좋군. (논리 +1)"])
			else:
				angry = true
				Snd.play("wrong")
				await b.say(["주T: 자기 방 번호도 모르나! 문에 적혀 있었을 텐데!", "* (다음 공격이 거세진다)"])
		2:
			if wrote:
				await b.say(["* 사유서는 이미 냈다. 주T가 주머니에 고이 접어 넣었다."])
				return
			await b.say(["주T: 사유서를 써라. 점호 시간에 왜 방에 없었나?"])
			var k2: int = await b.choose(["야자하다 깜빡 잠들었습니다", "도서관에서 공부했습니다", "원래 있었는데 못 보신 겁니다"])
			if k2 == 0:
				wrote = true
				Snd.play("correct")
				await b.say(["* 당신은 있는 그대로 적었다.", "주T: ...솔직하군. 변명보다 낫다."])
			else:
				angry = true
				Snd.play("wrong")
				await b.say(["주T: CCTV에 다 찍혔다! 거짓말은 벌점 두 배!", "* (다음 공격이 거세진다)"])
		3:
			if accepted:
				await b.say(["* 벌점은 이미 받았다. 1점."])
				return
			accepted = true
			await b.say(["* 당신은 '벌점 주세요'라고 말했다.", "주T: ...받겠다는 학생은 처음이군. 1점만 준다."])
	_check_spare()


func begin_attack(b) -> void:
	b.attack_len = 5.0 if spareable else 8.0
	pt = 0.4
	wave = 0
	call_t = 0.8
	call_n = -1
	check_t = 0.0
	aim_t = 1.0
	if spareable:
		return
	match pattern:
		0:
			b.dark = 85.0
		1:
			var box: Rect2 = b.attack_box
			for side in 2:
				var from := Vector2(box.position.x - 6, box.position.y - 6) if side == 0 else Vector2(box.end.x + 6, box.position.y - 6)
				var base := PI * 0.25 if side == 0 else PI * 0.75
				var l = b.laser(from, base, 1.0, b.attack_len, 44, Color(0.3, 0.7, 1.0))
				l.kind = 1
				l.length = 380.0
				l.data["base"] = base
				l.data["ph"] = side * 1.7
				l.fn = func(q, _d): q.angle = q.data["base"] + sin(q.age * 1.15 + q.data["ph"]) * 0.62
		3:
			b.dark = 60.0


func end_attack(_b) -> void:
	angry = false


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (1.25 if angry else 1.0) * (1.1 if hp < max_hp / 3 else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	check_flash = maxf(0.0, check_flash - delta)
	if spareable:
		if pt <= 0.0:
			pt = 0.9
			_glyph(b, Vector2(box.position.x - 14, randf_range(box.position.y + 20, box.end.y - 20)), Vector2(70, 0))
		return
	match pattern:
		0:
			# 천자문: 네 글자 한 묶음
			if pt <= 0.0:
				pt = 0.72 / k
				wave += 1
				var lane := randi() % 5
				var y := box.position.y + 18 + lane * (box.size.y - 36) / 4.0
				var ltr := wave % 2 == 0
				for j in 4:
					var x: float = (box.position.x - 16 - j * 27) if ltr else (box.end.x + 16 + j * 27)
					_glyph(b, Vector2(x, y), Vector2(125.0 * k * (1 if ltr else -1), 0))
		1:
			# CCTV: 시야(레이저)는 begin_attack 에서 켰다. 여기서는 가만히 못 있게 느린 탄을 쏜다.
			if pt <= 0.0:
				pt = 1.25 / k
				var src: Vector2 = b.enemy_pos + Vector2(0, 50)
				b.add(src, Vector2.RIGHT.rotated(b.aim(src)) * 72.0 * k, 6, Color(1.0, 0.85, 0.4))
		2:
			# 점호: 번호를 부르고, 잠시 뒤 다른 칸을 전부 친다
			call_t -= delta
			if call_n < 0 and call_t <= 0.0:
				call_n = randi() % 3
				check_t = 1.15 / k
				b.note = "%d번!" % (call_n + 1)
				Snd.play("warn")
			elif call_n >= 0:
				check_t -= delta
				if check_t <= 0.0:
					var col := clampi(int((b.soul.x - box.position.x) / (box.size.x / 3.0)), 0, 2)
					if col != call_n:
						b.hurt()
					else:
						Snd.play("graze")
						b.gauge = minf(100.0, b.gauge + 6.0)
					check_flash = 0.25
					call_n = -1
					call_t = 0.55 / k
					b.note = ""
		_:
			# 손전등 수색: 한자 고리 + 조준탄
			if pt <= 0.0:
				pt = 1.5 / k
				spin += 0.4
				var c: Vector2 = b.enemy_pos + Vector2(randf_range(-60, 60), 60)
				for j in 9:
					_glyph(b, c, Vector2.RIGHT.rotated(spin + TAU * j / 9.0) * 72.0 * k)
			aim_t -= delta
			if aim_t <= 0.0:
				aim_t = 0.9 / k
				var src2: Vector2 = b.enemy_pos + Vector2(40, 30)
				b.add(src2, Vector2.RIGHT.rotated(b.aim(src2)) * 140.0 * k, 4.5, Color(1.0, 1.0, 0.7), 1)


func _glyph(b, pos: Vector2, vel: Vector2) -> void:
	var bl = b.add(pos, vel, 9, Color(1.0, 0.92, 0.7), 2)
	bl.text = CHARS[char_i % CHARS.length()]
	char_i += 1


func draw_attack(b) -> void:
	if spareable or pattern != 2:
		return
	var box: Rect2 = b.box
	var w3 := box.size.x / 3.0
	for i in 3:
		var r := Rect2(box.position.x + i * w3 + 3, box.position.y + 3, w3 - 6, box.size.y - 6)
		var col := Color(1, 1, 1, 0.05)
		if call_n >= 0:
			col = Color(0.3, 1.0, 0.5, 0.2) if i == call_n else Color(1.0, 0.2, 0.2, 0.08 + 0.1 * absf(sin(b.t * 14.0)))
		elif check_flash > 0.0:
			col = Color(1, 1, 1, check_flash)
		b.draw_rect(r, col)
		b.draw_string(Game.font, Vector2(r.position.x, box.end.y - 10), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, Game.FL, Color(1, 1, 1, 0.5))


func not_yet_text() -> Array:
	return ["* 살려 주려 했다.", "* 주T: '점호가 안 끝났다!' (대답하고, 사유서를 쓰고, 벌점을 받아 보자)"]


func kill_text() -> Array:
	return ["* 주T는 쓰러지면서도 호루라기를 놓지 않았다. 손전등이 굴러가 304호 문패를 비춘다."]


func spare_text() -> Array:
	return ["* 주T가 손전등을 끄고 한숨을 쉬었다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_jut(ci, pos, t, 0.8, fl, alpha, 1 if spareable else 0)
