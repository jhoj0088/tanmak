extends "res://scripts/battle/enemy_base.gd"
## 휴지통 — 6챕터 백업 저장소. 코어가 '불필요'로 분류한 것들을 모아 두었다.
## '복원하기' 세 번: 지워졌던 것이 하나씩 되살아난다. 그러면 살려 줄 수 있다.

const Art = preload("res://scripts/art/art.gd")

const FILES := [
	["2학년_단체사진.jpg", "* 복원된 사진 속에서, 절반은 눈을 감고 절반은 웃고 있다. 삭제 사유: '구도 불량'."],
	["보내지_못한_문자.txt", "* '엄마 미안. 오늘 시험 망쳤어. 근데 괜찮아.' 삭제 사유: '전송되지 않음'."],
	["낙서_수학노트_마지막장.png", "* 공식 사이에 그려진 작은 고양이. 삭제 사유: '학습과 무관'."],
]

var restored := 0


func _init() -> void:
	id = "trash"
	name = "휴지통"
	max_hp = 50
	hp = 50
	atk = 5
	exp_reward = 14
	bg = Color(0.15, 0.3, 0.4)
	acts = ["살펴보기", "복원하기", "영구 삭제"]


func intro() -> String:
	return "* 휴지통이 뚜껑을 덜컥거린다! 안에서 지워진 파일들이 웅성거린다."


func flavor(_b) -> String:
	if spareable:
		return "* 휴지통이 텅 비었다. 홀가분해 보인다. (자비를 베풀 수 있다)"
	return ["* 휴지통 속 파일들이 '아직 여기 있어'라고 속삭인다.", "* [ 휴지통 비우기까지 0초... 0초... ] 카운트가 멈춰 있다.", "* 복원한 파일: %d / 3" % restored][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "다들...\n돌아갔어.\n원래 자리로."
	return ["불필요.\n불필요.\n전부 불필요.", "지운 건\n없던 거야.\n...그렇지?", "나는 비워지기 위해\n존재해."][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 휴지통 - 공격 5 방어 0", "* 코어가 지운 것들을 차마 완전히 버리지 못하고 모아 둔 곳. 어쩌면 코어의 미련."])
		1:
			if restored >= FILES.size():
				await b.say(["* 더 복원할 파일이 없다."])
				return
			var f: Array = FILES[restored]
			restored += 1
			Snd.play("heal")
			await b.say(["* '%s'을(를) 복원했다." % f[0], f[1]])
			if restored >= FILES.size():
				spareable = true
				Snd.play("correct")
				await b.say(["* 휴지통이 조용해졌다. 지워졌던 것들이 제자리로 돌아갔다."])
		2:
			await b.say(["* 당신은 '영구 삭제' 버튼 위에서 손을 멈췄다.", "* ...누군가에게는 소중했을 파일들이다."])


func begin_attack(b) -> void:
	b.attack_len = 4.5 if spareable else 7.0
	pt = 0.3


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (0.5 if spareable else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	if pt > 0.0:
		return
	if b.turn % 2 == 1:
		# 파일 조각이 던져졌다가 '복원'되어 되돌아온다
		pt = 1.1 / k
		var src: Vector2 = b.enemy_pos + Vector2(0, 40)
		spin += 0.5
		for bl in b.ring(src, 12, 120.0 * k, 6, Color(0.95, 0.95, 0.9), spin, 1):
			bl.life = 4.0
			bl.fn = func(q, _d):
				if not q.data.has("rev") and q.age > 1.3:
					q.data["rev"] = true
					q.vel = -q.vel * 0.9
					q.color = Color(0.5, 0.85, 1.0)
	else:
		# 삭제 줄: 위에서 아래로 훑는 줄. 한 칸만 비어 있다
		pt = 1.0 / k
		var gap := randi() % 8
		for j in 8:
			if j == gap:
				continue
			var x := box.position.x + 17 + j * (box.size.x - 34) / 7.0
			var bl2 = b.add(Vector2(x, box.position.y - 14), Vector2(0, 150.0 * k), 6, Color(1.0, 0.4, 0.4), 2)
			bl2.text = "×"


func kill_text() -> Array:
	return ["* 휴지통이 비워졌다. 영원히. 안에 있던 것들도 함께."]


func spare_text() -> Array:
	return ["* 휴지통이 뚜껑을 닫고 조용히 구석으로 돌아갔다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_trash(ci, pos + Vector2(0, 8), t, 1.0, fl, alpha, spareable)
