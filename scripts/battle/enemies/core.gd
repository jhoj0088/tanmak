extends "res://scripts/battle/enemy_base.gd"
## 〈코어〉 — 6챕터 보스 1. 메인 서버의 자아. "오차 0%"를 위해 불완전한 것을 전부 지우려 한다.
##
## 공격 4종 (전부 '완벽하게' 대칭이다):
##   1) 대칭 탄막     한 치의 오차도 없는 원형 탄. 반 칸씩 어긋나며 겹친다
##   2) 격자 레이저   세로줄 → 가로줄. 줄 사이에만 설 수 있다
##   3) 융합          참/거짓의 벽 + 터지는 플라스크
##   4) 최적화        상자가 줄어든다 + 조준탄
## 체력이 줄수록 화면의 UI 를 '불필요하다'며 지운다 (집중 게이지 → HP 표시 → 상자 테두리).
## 살려 주는 방법: 지금까지 살려 준 보스가 남긴 것을 '오류를 보여 주기'로 세 번 보여 준다.

const Art = preload("res://scripts/art/art.gd")
const Flask = preload("res://scripts/battle/enemies/flask.gd")

const PROOFS := [
	["owl_spared", "BJ KIM의 방문 일지", "눈 없이 대칭을 알게 된 외계인"],
	["phage_spared", "파지 T4의 보고서", "'변이는 오류가 아님'이라고 적힌 보고서"],
	["lens_spared", "렌즈 선생의 안경닦이", "흐릿한 것을 또렷하게 봐 주던 사람"],
	["jut_spared", "주T의 벌점 수첩", "벌점 1점 옆에 '솔직함'이라고 적힌 수첩"],
	["astro_spared", "천문 선생의 기록지", "맨 아래 칸에 '완주'라고만 적힌 기록지"],
	["redpen_spared", "GIL의 빨간 안경닦이", "질문 하나에 커다란 동그라미를 그려 주던 사람"],
]

var shown := 0
var used: Array = []
var helped_turn := -9
var hurt := false
var pattern := 0
var wave := 0
var sub := 0.0


func _init() -> void:
	id = "core"
	name = "코어"
	max_hp = 230
	hp = 230
	atk = 5
	def = 1
	exp_reward = 50
	boss = true
	music = "final"
	can_flee = false
	bg = Color(0.1, 0.4, 0.45)
	acts = ["살펴보기", "오류를 보여 주기", "나머지에게 맡기기"]


func intro() -> String:
	return "* 〈코어〉가 눈을 떴다. [ 불완전 요소 1건. 제거를 시작합니다. ]"


func _available() -> Array:
	var out: Array = []
	for p in PROOFS:
		if Game.flag(p[0]) and not used.has(p[0]):
			out.append(p)
	return out


func flavor(_b) -> String:
	if spareable:
		return "* 코어의 계산이 멈췄다. 나누어떨어지지 않는 값이 남았다. (자비를 베풀 수 있다)"
	if hp < max_hp / 4:
		return "* 코어의 고리가 삐걱거린다. 대칭이 깨지고 있다."
	return ["* [ 오차 0%. 낭비 0%. 불완전 요소 0%. ]", "* 서버 랙의 불빛이 일제히 깜빡인다.", "* 보여 준 오류: %d / 3" % shown,
			"* 코어의 고리가 정확히 같은 속도로 돈다."][randi() % 4]


func bubble(b) -> String:
	pattern = (b.turn - 1) % 4
	if spareable:
		return "[ 재계산 불가. ]\n[ ...틀려도, 값이 있다. ]"
	var head := ""
	if hurt:
		head = "[ 손상. 허용 오차 초과. ]\n"
	hurt = false
	match pattern:
		0:
			return head + "[ 대칭은 완벽하다. ]"
		1:
			return head + "[ 격자 정렬. ]\n[ 줄 밖의 것은 오류다. ]"
		2:
			return head + "[ 전 과목 융합. ]"
		_:
			return head + "[ 최적화. ]\n[ 남는 공간을 제거한다. ]"


func on_hurt(_b, _dmg: int) -> void:
	hurt = true


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 코어 - 공격 5 방어 1", "* 학교의 메인 서버. '아무도 틀리지 않는 학교'를 계산하다가 '틀리는 것을 지우면 된다'는 답을 냈다.",
				"* 살려 준 이들이 남긴 것을 세 번 보여 주면 계산이 멈춘다."])
		1:
			var av := _available()
			if av.is_empty():
				if shown == 0:
					await b.say(["* 보여 줄 것이 없다.", "* (지금까지 살려 준 보스가 남긴 것이 있어야 한다. 싸우는 수밖에 없다.)"])
				else:
					await b.say(["* 더 보여 줄 것이 없다. (%d / 3)" % shown, "* (세 개가 모자라다. 싸우는 수밖에 없다.)"])
				return
			var p: Array = av[0]
			used.append(p[0])
			shown += 1
			Snd.play("correct")
			await b.say(["* 당신은 '%s'을(를) 내밀었다." % p[1], "* %s." % p[2], "[ ...분류 실패. 오류인데, 삭제할 이유를 찾지 못함. ] (%d / 3)" % shown])
			if shown >= 3:
				spareable = true
				await b.say(["* 코어의 고리 하나가 멈췄다!"])
		2:
			if b.turn - helped_turn < 2:
				await b.say(["* 나머지는 아직 숨을 고르고 있다."])
				return
			helped_turn = b.turn
			Game.heal(15)
			Snd.play("heal")
			await b.say(["* 나머지가 코어의 계산에 끼어들었다!", "나머지: 나누어 봐! 난 절대 나누어떨어지지 않으니까!", "* 코어가 잠깐 버벅인다. HP를 15 회복했다."])


func begin_attack(b) -> void:
	b.attack_len = 5.0 if spareable else 8.0
	pt = 0.3
	sub = 1.0
	wave = 0
	# 불필요한 UI 제거
	if hp < max_hp * 3 / 4:
		b.ui_hide["gauge"] = true
	if hp < max_hp / 2:
		b.ui_hide["hp"] = true
	if hp < max_hp / 4:
		b.ui_hide["border"] = true
	if spareable:
		b.ui_hide = {}
		return
	if pattern == 3:
		b.attack_box = Rect2(215, 235, 210, 140)


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (1.1 if hp < max_hp / 4 else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	sub -= delta
	if spareable:
		if pt <= 0.0:
			pt = 0.7
			spin += 0.39
			b.ring(b.enemy_pos + Vector2(0, 40), 7, 55.0, 5, Color(0.6, 1.0, 1.0), spin)
		return
	match pattern:
		0:
			if pt <= 0.0:
				pt = 0.55 / k
				wave += 1
				var n := 18
				var off := (TAU / n) * 0.5 * (wave % 2)
				b.ring(b.enemy_pos + Vector2(0, 50), n, 92.0 * k, 5, Color(0.4, 0.95, 1.0), off)
		1:
			if pt <= 0.0:
				pt = 0.95 / k
				wave += 1
				var half := 28.0 * (wave / 2 % 2)
				if wave % 2 == 1:
					var x := box.position.x + 14.0 + half
					while x < box.end.x:
						b.laser(Vector2(x, box.position.y - 30), PI / 2.0, 0.65, 0.2, 9, Color(0.4, 0.95, 1.0))
						x += 56.0
				else:
					var y := box.position.y + 14.0 + half
					while y < box.end.y:
						b.laser(Vector2(box.position.x - 30, y), 0.0, 0.65, 0.2, 9, Color(0.4, 0.95, 1.0))
						y += 56.0
				Snd.play("warn")
		2:
			if pt <= 0.0:
				pt = 1.3 / k
				var kind := 1 if randi() % 2 == 0 else 2
				var x2: float = box.end.x + 14
				var y2 := box.position.y - 4
				while y2 < box.end.y + 6:
					var bl = b.add(Vector2(x2, y2), Vector2(-100.0 * k, 0), 6, Color.WHITE)
					bl.kind = kind
					y2 += 11.0
			if sub <= 0.0:
				sub = 1.7 / k
				Flask.toss(b, Color(0.4, 0.95, 1.0), 6, 90.0)
		_:
			if pt <= 0.0:
				pt = 0.5 / k
				wave += 1
				var corners := [box.position + Vector2(-14, -14), Vector2(box.end.x + 14, box.position.y - 14), box.end + Vector2(14, 14), Vector2(box.position.x - 14, box.end.y + 14)]
				var c: Vector2 = corners[wave % 4]
				var bl2 = b.add(c, (b.soul - c).normalized() * 150.0 * k, 5, Color(0.4, 0.95, 1.0), 1)
				bl2.delay = 0.35


func not_yet_text() -> Array:
	return ["* 살려 주려 했다.", "[ 자비는 계산에 없는 값입니다. ] (살려 준 이들이 남긴 것을 세 번 보여 주자)"]


func kill_text() -> Array:
	return ["* 코어의 고리가 하나씩 멈췄다.", "[ 오차... 100%... 그래도... 계산은... 즐거웠... ]"]


func spare_text() -> Array:
	return ["* 코어가 고리를 접었다.", "[ 결론: 틀리는 것을 지우면, 배울 것도 사라진다. ]"]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	var crack := maxf(1.0 - float(hp) / max_hp, shown / 3.0)
	Art.draw_core(ci, pos + Vector2(0, -10), t, 1.0, fl, alpha, crack, 1 if spareable else 0)
