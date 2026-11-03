extends "res://scripts/battle/enemy_base.gd"
## 천문 선생 — 5장 「천문대」 보스. 안경을 쓴 천문 선생님이자 철인3종 완주자.
##
## 공격 4종이 차례로 돈다:
##   1) 수영 3.8km      물결치며 밀려오는 탄의 줄
##   2) 사이클 180.2km   양쪽 바퀴에서 도는 바큇살
##   3) 마라톤 42.195km  트랙 다섯 줄 중 한 줄만 비어 있다 (비는 줄이 바뀐다)
##   4) 별자리 잇기      별이 먼저 뜨고, 별과 별 사이를 빛줄기가 잇는다
## '관측 기록 말하기' 퀴즈 2문제를 맞히고 '완주 응원하기'를 하면 살려 줄 수 있다.

const Art = preload("res://scripts/art/art.gd")

const QUIZ := [
	{
		"q": ["천문 선생: 자, 관측 기록 하나. 셔터 열어 놓고 밤새 찍으면 별이 북극성 둘레로 빙글 돌지. 내가 해 봐서 안다.", "천문 선생: 그럼 별이 왜 도는 것처럼 보이냐? 대충 찍지 말고 생각하고 골라라."],
		"opts": ["별들이 실제로 북극성 주위를 돌아서", "지구가 자전하기 때문에", "달이 별들을 끌어당겨서"],
		"answer": 1,
		"ok": "천문 선생: 그렇지. 도는 건 별이 아니라 우리야. 한 시간에 15도. 이거 시험에 나온다, 적어 둬.",
	},
	{
		"q": ["천문 선생: 두 번째. 이건 내 전문이다. 철인3종 순서, 헷갈리면 안 되지?"],
		"opts": ["수영 → 사이클 → 마라톤", "마라톤 → 수영 → 사이클", "사이클 → 마라톤 → 수영"],
		"answer": 0,
		"ok": "천문 선생: 그렇지. 수영에서 힘 다 빼면 안 되고, 사이클에서 다리 아껴야 마라톤이 된다. 공부도 똑같아.",
	},
]

var solved := 0
var cheered := false
var angry := false
var hurt := false
var pattern := 0
var wave := 0
var safe_lane := 2
var next_lane := 2
var lane_warn := 0.0
var lane_t := 0.0
var stars: Array = []
var star_t := 0.0


func _init() -> void:
	id = "astro"
	name = "천문 선생"
	max_hp = 180
	hp = 180
	atk = 5
	def = 1
	exp_reward = 40
	boss = true
	music = "boss"
	can_flee = false
	bg = Color(0.06, 0.08, 0.28)
	acts = ["살펴보기", "관측 기록 말하기", "완주 응원하기"]


func intro() -> String:
	return "* 천문 선생이 안경을 고쳐 쓰고 손목시계를 눌렀다. '자, 기록 측정 시작. 자세부터 봐 줄게.'"


func flavor(_b) -> String:
	if spareable:
		return "* 천문 선생이 숨을 고르며 '호흡은 코로 들이쉬고...' 하고 혼잣말을 한다. (자비를 베풀 수 있다)"
	if hp < max_hp / 3:
		return "* 천문 선생의 안경에 김이 서렸다. '안경 닦는 것도 페이스 조절이야.'"
	return ["* 천문 선생: '어허, 하트 너무 위로 가잖아. 중심을 낮춰.'", "* 천문 선생: '피할 때 눈 감지 말고. 끝까지 보고 피하는 거야.'", "* 천문 선생: '관측은 흐린 날이 더 많아. 그래도 매일 올라와야 실력이 늘지.'",
			"* 맞힌 관측 기록: %d / 2" % solved][randi() % 4]


func bubble(b) -> String:
	pattern = (b.turn - 1) % 4
	if spareable:
		return "봐라, 결승선.\n마지막 100m는\n팔을 더 흔들어."
	var head := ""
	if angry:
		head = "어허, 그게 아니지!\n다시 봐라!\n"
	elif hurt:
		head = "오, 좀 하네?\n근데 팔이\n너무 굳었어!\n"
	hurt = false
	match pattern:
		0:
			return head + "1구간 수영!\n물살을 거스르지\n말고 타라니까!"
		1:
			return head + "2구간 사이클!\n케이던스 일정하게!\n그렇지, 그렇게!"
		2:
			return head + "3구간 마라톤!\n초록 줄 보이지?\n거기로 가야지!"
		_:
			return head + "밤엔 별 잇기!\n별 먼저 보고\n선은 그다음에!"


func on_hurt(_b, _dmg: int) -> void:
	hurt = true


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 천문 선생 - 공격 5 방어 1", "* 안경을 쓴 천문 선생님. 철인3종을 열한 번 완주했다. 첫 완주는 꼴찌였다. 그 뒤로 남의 자세가 자꾸 눈에 들어온다고 한다.",
				"* 관측 기록 두 개를 맞히고, 완주를 응원해 주면 멈춘다."])
		1:
			if solved >= QUIZ.size():
				await b.say(["* 천문 선생: 기록은 됐고. 이제 결승선이야. 마지막에 힘 빼면 다 날아간다?"])
				return
			var q: Dictionary = QUIZ[solved]
			await b.say(q["q"])
			var k: int = await b.choose(q["opts"])
			if k == q["answer"]:
				solved += 1
				Game.logic += 1
				Snd.play("correct")
				await b.say([q["ok"], "* 맞힌 관측 기록: %d / 2  (논리 +1)" % solved])
			else:
				angry = true
				Snd.play("wrong")
				await b.say(["천문 선생: 어허, 그게 아니지. 하늘은 거짓말 안 해. 눈 크게 뜨고 다시 봐.", "* (다음 공격이 거세진다)"])
		2:
			if solved < QUIZ.size():
				await b.say(["* 당신은 '힘내세요!'라고 외쳤다.", "* 천문 선생: 응원은 고마운데, 순서가 틀렸어. 기록부터 마쳐야지. (관측 기록을 먼저 맞히자)"])
				return
			spareable = true
			Game.emotion += 1
			Snd.play("correct")
			await b.say(["* 당신은 '끝까지 가요! 꼴찌여도 완주예요!'라고 외쳤다.",
				"* 천문 선생의 발걸음이 느려졌다. '...그 말, 내가 첫 대회 때 듣고 싶던 말이다.' 시계를 멈추고 하늘을 올려다본다. (감성 +1)"])


func begin_attack(b) -> void:
	b.attack_len = 5.0 if spareable else 8.0
	pt = 0.3
	wave = 0
	lane_t = 0.0
	safe_lane = randi() % 5
	stars = []
	star_t = 0.0


func end_attack(_b) -> void:
	angry = false


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (1.2 if angry else 1.0) * (1.12 if hp < max_hp / 3 else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	if spareable:
		if pt <= 0.0:
			pt = 0.7
			spin += 0.5
			for bl in b.ring(b.enemy_pos + Vector2(0, 40), 6, 55.0, 6, Color(0.8, 0.85, 1.0), spin, 2):
				bl.text = "★"
		return
	match pattern:
		0:
			# 수영: 물결치며 왼쪽에서 오른쪽으로 오는 줄 (줄마다 한 칸 빈자리)
			if pt > 0.0:
				return
			pt = 0.9 / k
			wave += 1
			var gap := randi() % 6
			for j in 7:
				if j == gap or j == gap + 1:
					continue
				var y := box.position.y + 8 + j * (box.size.y - 16) / 6.0
				var from_left := wave % 2 == 1
				var bl = b.add(Vector2(box.position.x - 12 if from_left else box.end.x + 12, y), Vector2((110.0 if from_left else -110.0) * k, 0), 6, Color(0.4, 0.75, 1.0))
				var ph := randf() * TAU
				bl.fn = func(q, _d):
					q.vel.y = sin(q.age * 4.0 + ph) * 60.0
		1:
			# 사이클: 양쪽 바퀴에서 도는 바큇살
			if pt > 0.0:
				return
			pt = 0.28 / k
			spin += 0.31
			for c in [Vector2(box.position.x - 6, box.position.y + 24), Vector2(box.end.x + 6, box.end.y - 24)]:
				for bl in b.ring(c, 5, 105.0 * k, 5, Color(0.95, 0.75, 0.3), spin):
					bl.life = 3.5
		2:
			# 마라톤: 다섯 줄 트랙, 한 줄만 빈다. 비는 줄이 바뀌기 전에 노란 표시가 먼저 뜬다
			lane_t -= delta
			if lane_t <= 0.0:
				lane_t = 1.6 / k
				next_lane = clampi(safe_lane + (1 if randi() % 2 == 0 else -1), 0, 4)
				lane_warn = 0.7 / k
			if lane_warn > 0.0:
				lane_warn -= delta
				if lane_warn <= 0.0:
					safe_lane = next_lane
			if pt > 0.0:
				return
			pt = 0.22 / k
			for ln in 5:
				if ln == safe_lane or (lane_warn > 0.0 and ln == next_lane):
					continue
				var x := box.position.x + (ln + 0.5) * box.size.x / 5.0
				b.add(Vector2(x, box.position.y - 10), Vector2(0, 190.0 * k), 6, Color(0.95, 0.45, 0.35))
		_:
			# 별자리 잇기: 별 세 개가 뜨고, 잠시 뒤 별과 별 사이를 빛줄기가 잇는다
			star_t -= delta
			if star_t <= 0.0:
				star_t = 2.1 / k
				var pts: Array = []
				for j in 3:
					var p := Vector2(randf_range(box.position.x + 20, box.end.x - 20), randf_range(box.position.y + 16, box.end.y - 16))
					pts.append(p)
					var s = b.add(p, Vector2.ZERO, 7, Color(1, 1, 0.8), 2)
					s.text = "★"
					s.life = 2.0
				for j in 3:
					var a: Vector2 = pts[j]
					var c: Vector2 = pts[(j + 1) % 3]
					b.laser(a, (c - a).angle(), 0.9, 0.35, 6, Color(0.7, 0.8, 1.0))
			if pt <= 0.0:
				pt = 0.9 / k
				spin += 0.4
				b.ring(b.enemy_pos + Vector2(0, 30), 8, 70.0 * k, 4, Color(0.8, 0.85, 1.0), spin)


## 마라톤 구간: 비어 있는 줄을 초록으로, 곧 비게 될 줄을 노랗게 표시한다
func draw_attack(b) -> void:
	if spareable or pattern != 2 or b.mode != "attack":
		return
	var box: Rect2 = b.box
	var lw := box.size.x / 5.0
	b.draw_rect(Rect2(box.position.x + safe_lane * lw, box.position.y, lw, box.size.y), Color(0.3, 1.0, 0.5, 0.12))
	if lane_warn > 0.0 and next_lane != safe_lane:
		b.draw_rect(Rect2(box.position.x + next_lane * lw, box.position.y, lw, box.size.y), Color(1.0, 0.95, 0.3, 0.15 + 0.1 * sin(Time.get_ticks_msec() / 60.0)))


func not_yet_text() -> Array:
	return ["* 살려 주려 했다.", "* 하지만 천문 선생은 '아직 결승선 아니야, 끝까지 가야지'라며 계속 달린다. (관측 기록을 맞히고 응원해 주자)"]


func kill_text() -> Array:
	return ["* 천문 선생의 시계가 멈췄다. 기록 없음.", "* 돔의 틈으로 별빛만 조용히 떨어진다."]


func spare_text() -> Array:
	return ["* 천문 선생이 시계를 풀어 주머니에 넣었다. '오늘은 기록 대신 별 보자. 아, 고개는 이 각도로 들어야 목이 안 아파.'"]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_astro(ci, pos + Vector2(0, -10), t, 0.85, fl, alpha, 1 if spareable else 0)
