extends "res://scripts/battle/enemy_base.gd"
## 중간고사 시험지 — 5챕터. 같은 스크립트를 과목별 id 로 네 번 쓴다 (enemies.gd 참고).
## 홀수 턴에는 자기 과목의 탄막, 짝수 턴에는 앞 과목과 섞인 '융합' 탄막이 나온다.
## '문제 풀기'로 두 문제를 맞히면 살려 줄 수 있다 (= 답안 제출).

const Art = preload("res://scripts/art/art.gd")
const Flask = preload("res://scripts/battle/enemies/flask.gd")

const SUBJECTS := {
	"exam_math": {
		"n": 0, "name": "수학 시험지", "label": "수학", "bg": Color(0.15, 0.3, 0.2),
		"quiz": [
			{"q": "1번. 집합 A = {1, 2, 3} 의 부분집합은 모두 몇 개인가?", "opts": ["6개", "8개", "9개"], "answer": 1},
			{"q": "2번. 'p 이면 q 이다'가 참일 때 반드시 참인 것은?", "opts": ["역", "이", "대우"], "answer": 2},
		],
	},
	"exam_bio": {
		"n": 1, "name": "생명과학 시험지", "label": "생명", "bg": Color(0.1, 0.35, 0.35),
		"quiz": [
			{"q": "1번. DNA에서 아데닌(A)과 짝을 이루는 염기는?", "opts": ["타이민(T)", "구아닌(G)", "사이토신(C)"], "answer": 0},
			{"q": "2번. 세포에서 ATP를 만드는 발전소는?", "opts": ["리보솜", "액포", "미토콘드리아"], "answer": 2},
		],
	},
	"exam_phys": {
		"n": 2, "name": "물리 시험지", "label": "물리", "bg": Color(0.15, 0.3, 0.5),
		"quiz": [
			{"q": "1번. 빛이 거울에 입사각 30°로 들어갔다. 반사각은?", "opts": ["60°", "30°", "90°"], "answer": 1},
			{"q": "2번. 이중 슬릿을 지난 빛이 스크린에 만드는 것은?", "opts": ["간섭무늬", "그림자 하나", "무지개"], "answer": 0},
		],
	},
	"exam_hanja": {
		"n": 3, "name": "한문 시험지", "label": "한문", "bg": Color(0.3, 0.25, 0.4),
		"quiz": [
			{"q": "1번. 천자문의 첫 구절 '天地玄黃'에서 '天'의 뜻은?", "opts": ["땅", "하늘", "누렇다"], "answer": 1},
			{"q": "2번. 점호 때 사감 선생님께 드리는 올바른 대답은?", "opts": ["'이상 없습니다!'", "'5분만 더요...'", "(자는 척한다)"], "answer": 0},
		],
	},
}

var subj := 0
var label := ""
var quiz: Array = []
var solved := 0
var angry := false
var wave := 0
var sub := 0.0
var sub2 := 0.0
var mix := false


func setup(enemy_id: String) -> void:
	var d: Dictionary = SUBJECTS.get(enemy_id, SUBJECTS["exam_math"])
	id = enemy_id
	subj = d["n"]
	name = d["name"]
	label = d["label"]
	bg = d["bg"]
	quiz = d["quiz"]
	max_hp = 60 + subj * 8
	hp = max_hp
	atk = 4
	exp_reward = 14
	music = "boss"
	can_flee = false
	acts = ["살펴보기", "문제 풀기", "찍기"]


func intro() -> String:
	return "* %s가 펄럭이며 날아올랐다! 제한 시간은 없다. 대신 탄막이 있다." % name


func flavor(_b) -> String:
	if spareable:
		return "* %s에 답이 전부 채워졌다. (자비 = 답안 제출)" % name
	return ["* 시험지가 OMR 칸을 깜빡인다.", "* 푼 문제: %d / 2" % solved, "* 대강의실에 시계 초침 소리만 울린다.", "* 시험지가 '서술형 감점'이라고 속삭였다."][randi() % 4]


func bubble(b) -> String:
	mix = b.turn % 2 == 0 and subj > 0
	if spareable:
		return "다 풀었네.\n제출해도 좋아."
	if angry:
		return "오답!\n감점! 감점!"
	if mix:
		return "융합 문제!\n앞 과목도\n같이 나온다!"
	return ["%s 문제다.\n배운 대로 피해 봐!" % label, "틀리면 탄막,\n맞히면 통과!", "서술형은\n부분 점수 없음!"][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* %s - 공격 4 방어 0" % name, "* 코어가 출제한 '완벽한' 시험. 지금까지 지나온 과목의 탄막이 섞여 나온다.", "* 두 문제를 맞히고 '자비'로 제출하면 통과."])
		1:
			if solved >= quiz.size():
				await b.say(["* 문제를 다 풀었다. '자비'를 골라 제출하자."])
				return
			await _ask(b)
		2:
			if solved >= quiz.size():
				await b.say(["* 다 풀었는데 굳이 찍을 필요는 없다."])
				return
			await b.say(["* 당신은 연필을 굴렸다. 데구루루..."])
			if randf() < 0.34:
				solved += 1
				Snd.play("correct")
				await b.say(["* 맞았다! 운도 실력이다. (푼 문제 %d / 2)" % solved])
			else:
				angry = true
				Snd.play("wrong")
				await b.say(["* 틀렸다. 연필이 책상 밑으로 굴러갔다. (다음 공격이 거세진다)"])
	if solved >= quiz.size() and not spareable:
		spareable = true


func _ask(b) -> void:
	var q: Dictionary = quiz[solved]
	await b.say(["* " + q["q"]])
	var k: int = await b.choose(q["opts"])
	if k == q["answer"]:
		solved += 1
		Game.logic += 1
		Snd.play("correct")
		await b.say(["* 정답! 동그라미가 그려졌다. (푼 문제 %d / 2, 논리 +1)" % solved])
	else:
		angry = true
		Snd.play("wrong")
		await b.say(["* 오답! 빨간 줄이 그어졌다. (다음 공격이 거세진다)"])


func begin_attack(b) -> void:
	b.attack_len = 4.5 if spareable else 7.0
	pt = 0.4
	sub = 0.6
	sub2 = 0.8
	wave = 0
	if not spareable and (subj == 3 and not mix):
		b.dark = 88.0


func end_attack(_b) -> void:
	angry = false


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (1.25 if angry else 1.0)
	pt -= delta
	sub -= delta
	sub2 -= delta
	if spareable:
		if pt <= 0.0:
			pt = 0.8
			b.add(Vector2(randf_range(b.box.position.x, b.box.end.x), b.box.position.y - 10), Vector2(0, 65), 5, Color(1, 1, 1))
		return
	if mix:
		# 융합: 자기 과목은 조금 느리게, 앞 과목을 얹는다
		_pattern(b, subj, k * 0.75, 0)
		_pattern(b, subj - 1, k * 0.6, 1)
	else:
		_pattern(b, subj, k, 0)


## which: 과목 번호.  slot: 0 = pt 타이머, 1 = sub 타이머
func _pattern(b, which: int, k: float, slot: int) -> void:
	var box: Rect2 = b.box
	var ready: bool = pt <= 0.0 if slot == 0 else sub <= 0.0
	if not ready:
		return
	var wait := 1.0
	match which:
		0:
			# 수학: 참/거짓의 벽
			wait = 1.25 / k
			wave += 1
			var kind := 1 if randi() % 2 == 0 else 2
			var from_left: bool = b.turn % 4 < 2
			var x: float = box.position.x - 14 if from_left else box.end.x + 14
			var y := box.position.y - 4
			while y < box.end.y + 6:
				var bl = b.add(Vector2(x, y), Vector2(100.0 * k * (1 if from_left else -1), 0), 6, Color.WHITE)
				bl.kind = kind
				y += 11.0
		1:
			# 생명: 터지는 플라스크
			wait = 0.95 / k
			Flask.toss(b, Color(0.5, 1.0, 0.7), 6, 95.0 * k)
		2:
			# 물리: 예고 뒤에 쏘는 레이저 십자
			wait = 0.85 / k
			wave += 1
			if wave % 2 == 0:
				b.laser(Vector2(box.position.x - 30, b.soul.y), 0.0, 0.6, 0.2, 10, Color(1.0, 0.3, 0.35))
			else:
				b.laser(Vector2(b.soul.x, box.position.y - 30), PI / 2.0, 0.6, 0.2, 10, Color(1.0, 0.3, 0.35))
			b.laser(Vector2(randf_range(box.position.x + 10, box.end.x - 10), box.position.y - 30), PI / 2.0, 0.6, 0.2, 10, Color(1.0, 0.6, 0.9))
			Snd.play("warn")
		_:
			# 한문: 줄지어 지나가는 한자
			wait = 0.8 / k
			wave += 1
			var chars := "中間考査合格滿點"
			var lane := randi() % 5
			var y2 := box.position.y + 18 + lane * (box.size.y - 36) / 4.0
			var ltr := wave % 2 == 0
			for j in 4:
				var x2: float = (box.position.x - 16 - j * 27) if ltr else (box.end.x + 16 + j * 27)
				var g = b.add(Vector2(x2, y2), Vector2(120.0 * k * (1 if ltr else -1), 0), 9, Color(1.0, 0.92, 0.7), 2)
				g.text = chars[(wave * 4 + j) % chars.length()]
	if slot == 0:
		pt = wait
	else:
		sub = wait


func not_yet_text() -> Array:
	return ["* 제출하려 했다.", "* 하지만 답안지가 비어 있다! ('문제 풀기'로 두 문제를 맞히자)"]


func kill_text() -> Array:
	return ["* %s는 갈기갈기 찢어졌다. 풀지 않고도 지나갈 수는 있다." % name]


func spare_text() -> Array:
	return ["* 답안지를 제출했다. 시험지가 얌전히 접혔다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_exam(ci, pos, t, 1.05, fl, alpha, label, 1 if spareable else 0)
