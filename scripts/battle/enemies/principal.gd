extends "res://scripts/battle/enemy_base.gd"
## 교장 — 최종 보스. "아무도 틀리지 않는 학교"를 바랐던 사람. 실존 인물과 무관한 가상의 캐릭터.
##
## 공격 4종:
##   1) 상장 수여      '賞' 탄이 부채꼴로 날아온다
##   2) 훈화 말씀      문장이 한 글자씩 줄지어 지나간다. 띄어쓰기가 유일한 틈
##   3) 전교 1등       하트를 쫓아오는 왕관 탄
##   4) 완벽한 학교    이중 나선. 테두리가 사라진다
## 살려 주는 방법: '틀린 답안지 보여 주기' 두 번 → '괜찮다고 말해 주기'.

const Art = preload("res://scripts/art/art.gd")
const SPEECH := [
	"에... 마지막으로 한 말씀만 더 하겠습니다",
	"우리 학교 학생은 틀려서는 안 됩니다",
	"끝으로 정말 끝으로 한 가지만 더",
	"완벽이란 무엇인가 생각해 봅시다",
	"졸지 마세요 거의 다 끝났습니다",
]

var papers := 0
var angry := false
var hurt := false
var pattern := 0
var wave := 0
var sub := 0.0
var feed: Array = []       # 훈화 말씀: 아직 내보내지 않은 글자들
var feed_t := 0.0
var feed_lane := 0
var feed_dir := 1


func _init() -> void:
	id = "principal"
	name = "교장"
	max_hp = 210
	hp = 210
	atk = 5
	def = 1
	exp_reward = 60
	boss = true
	music = "final"
	can_flee = false
	bg = Color(0.4, 0.3, 0.12)
	acts = ["살펴보기", "틀린 답안지 보여 주기", "괜찮다고 말해 주기"]


func intro() -> String:
	return "* 교장이 상장을 내려놓고 일어섰다. 이것이 마지막 수업이다."


func flavor(_b) -> String:
	if spareable:
		return "* 교장이 안경을 벗고 눈가를 훔친다. (자비를 베풀 수 있다)"
	if hp < max_hp / 3:
		return "* 교장의 넥타이가 풀어졌다. 훈화가 자꾸 끊긴다."
	return ["* 교장실 벽의 상장들이 일제히 번쩍인다.", "* 교장이 헛기침을 했다. 훈화가 길어질 조짐이다.", "* 보여 준 답안지: %d / 2" % papers,
			"* 진열장 속 트로피에 당신의 얼굴이 일그러져 비친다."][randi() % 4]


func bubble(b) -> String:
	pattern = (b.turn - 1) % 4
	if spareable:
		return "...틀리고,\n다시 풀었군.\n나는 그걸 잊고 있었네."
	var head := ""
	if angry:
		head = "괜찮지 않네!\n"
	elif hurt:
		head = "교권 침해일세!\n"
	hurt = false
	match pattern:
		0:
			return head + "완벽한 학생에게는\n상을 주어야지.\n받게!"
		1:
			return head + "에... 훈화 말씀이\n있겠습니다.\n경청하도록."
		2:
			return head + "전교 1등의 왕관은\n늘 자네를\n쫓아다닐 걸세."
		_:
			return head + "아무도 틀리지 않는\n학교... 그게 그리\n잘못된 꿈인가!"


func on_hurt(_b, _dmg: int) -> void:
	hurt = true


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 교장 - 공격 5 방어 1", "* 누구도 뒤처지지 않는 학교를 바랐다. 그 바람을 코어에게 맡긴 것이 잘못이었다.",
				"* 틀린 답안지를 두 번 보여 주고, 괜찮다고 말해 주자."])
		1:
			papers += 1
			if papers == 1:
				await b.say(["* 당신은 빨간 줄투성이 답안지를 내밀었다.", "교장: ...이게 뭔가. 틀린 것투성이군. 부끄럽지도 않나?"])
			elif papers == 2:
				Snd.play("correct")
				await b.say(["* 당신은 답안지를 뒤집었다. 뒷면에 다시 푼 흔적이 빼곡하다.", "교장: ......틀리고, 지우고, 다시 풀었군."])
			else:
				await b.say(["* 교장은 답안지를 오래 들여다보고 있다."])
		2:
			if papers >= 2:
				spareable = true
				Snd.play("correct")
				await b.say(["* 당신은 '틀려도 괜찮아요'라고 말했다.", "교장: ...나도 학생 때는 많이 틀렸지. 그때가 제일 많이 배웠고.", "* 교장의 어깨에서 힘이 빠졌다!"])
			else:
				angry = true
				await b.say(["* 당신은 '틀려도 괜찮아요'라고 말했다.", "교장: 말뿐이군! 증거를 가져오게! (틀린 답안지를 먼저 보여 주자)"])


func begin_attack(b) -> void:
	b.attack_len = 5.0 if spareable else 8.5
	pt = 0.4
	sub = 0.8
	wave = 0
	feed.clear()
	feed_t = 0.0
	b.ui_hide = {}
	if pattern == 3 and not spareable:
		b.ui_hide["border"] = true


func end_attack(b) -> void:
	angry = false
	b.ui_hide = {}


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (1.2 if angry else 1.0) * (1.1 if hp < max_hp / 3 else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	sub -= delta
	if spareable:
		if pt <= 0.0:
			pt = 0.9
			var g = b.add(Vector2(randf_range(box.position.x, box.end.x), box.position.y - 12), Vector2(0, 60), 9, Color(1.0, 0.9, 0.6), 2)
			g.text = "賞"
		return
	match pattern:
		0:
			# 상장 수여
			if pt <= 0.0:
				pt = 0.85 / k
				var src: Vector2 = b.enemy_pos + Vector2(50, 20)
				var base: float = b.aim(src)
				for j in range(-2, 3):
					var g2 = b.add(src, Vector2.RIGHT.rotated(base + j * 0.24) * 128.0 * k, 9, Color(1.0, 0.85, 0.3), 2)
					g2.text = "賞"
			if sub <= 0.0:
				sub = 0.5 / k
				b.add(Vector2(randf_range(box.position.x, box.end.x), box.position.y - 10), Vector2(0, 75.0 * k), 4, Color(1.0, 0.95, 0.7))
		1:
			# 훈화 말씀: 한 글자씩. 띄어쓰기 자리에는 탄이 없다
			feed_t -= delta
			if feed.is_empty() and pt <= 0.0:
				var line: String = SPEECH[wave % SPEECH.size()]
				wave += 1
				for ch in line:
					feed.append(ch)
				feed_lane = (feed_lane + 2 + randi() % 2) % 5
				feed_dir = -feed_dir
				pt = 0.25
			if not feed.is_empty() and feed_t <= 0.0:
				feed_t = 0.2 / k
				var ch2: String = feed.pop_front()
				if ch2 != " ":
					var y := box.position.y + 18 + feed_lane * (box.size.y - 36) / 4.0
					var x: float = box.position.x - 16 if feed_dir > 0 else box.end.x + 16
					var g3 = b.add(Vector2(x, y), Vector2(118.0 * k * feed_dir, 0), 9, Color(1.0, 0.95, 0.85), 2)
					g3.text = ch2
			if sub <= 0.0:
				sub = 1.3 / k
				var src2: Vector2 = b.enemy_pos + Vector2(0, 50)
				b.add(src2, Vector2.RIGHT.rotated(b.aim(src2)) * 95.0 * k, 5, Color(1.0, 0.6, 0.3))
		2:
			# 전교 1등: 쫓아오는 왕관
			if pt <= 0.0:
				pt = 1.35 / k
				var src3: Vector2 = b.enemy_pos + Vector2(randf_range(-80, 80), 30)
				var crown = b.add(src3, Vector2.RIGHT.rotated(b.aim(src3)) * 105.0 * k, 9, Color(1.0, 0.85, 0.2), 2)
				crown.text = "①"
				crown.life = 4.2
				crown.fn = func(q, d):
					var want: float = (b.soul - q.pos).angle()
					q.vel = q.vel.rotated(clampf(angle_difference(q.vel.angle(), want), -1.5 * d, 1.5 * d))
			if sub <= 0.0:
				sub = 1.9 / k
				spin += 0.3
				b.ring(b.enemy_pos + Vector2(0, 50), 10, 70.0 * k, 5, Color(1.0, 0.95, 0.7), spin)
		_:
			# 완벽한 학교: 이중 나선
			if pt <= 0.0:
				pt = 0.11 / k
				var src4: Vector2 = b.enemy_pos + Vector2(0, 40)
				for j in 2:
					var bl = b.add(src4, Vector2.RIGHT.rotated(spin + PI * j) * 98.0 * k, 5, Color(1.0, 0.85, 0.3) if j == 0 else Color(0.4, 0.95, 1.0))
					bl.curve = 0.3 if j == 0 else -0.3
				spin += 0.29


func not_yet_text() -> Array:
	return ["* 살려 주려 했다.", "교장: '동정은 필요 없네!' (틀린 답안지를 두 번 보여 주고, 괜찮다고 말해 주자)"]


func kill_text() -> Array:
	return ["* 교장은 의자에 주저앉았다. 벽의 상장들이 한 장씩 떨어져 내린다."]


func spare_text() -> Array:
	return ["* 교장이 상장 한 장을 꺼내 무언가를 고쳐 쓰기 시작했다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_principal(ci, pos, t, 0.8, fl, alpha, 1 if spareable else 0, 0.0 if spareable else 0.6)
