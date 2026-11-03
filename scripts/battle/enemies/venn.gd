extends "res://scripts/battle/enemy_base.gd"
## 벤 쌍둥이 A, B — 그레이즈를 가르치는 적.
## 탄을 10번 스치거나, '공통점 찾아 주기'를 두 번 하면 살려 줄 수 있다.

const Art = preload("res://scripts/art/art.gd")
const PINK := Color(1.0, 0.45, 0.6)
const GREEN := Color(0.4, 1.0, 0.65)

var common := 0
var angry := false
var impressed := false
var grazes := 0
var side := 0


func _init() -> void:
	id = "venn"
	name = "벤 쌍둥이"
	max_hp = 40
	hp = 40
	atk = 3
	def = 1
	exp_reward = 6
	bg = Color(0.35, 0.15, 0.3)
	acts = ["살펴보기", "공통점 찾아 주기", "떼어 놓기"]


func intro() -> String:
	return "* 벤 쌍둥이 A와 B가 굴러왔다! 겹친 부분이 누구 것인지 다투고 있다."


func flavor(_b) -> String:
	if impressed:
		impressed = false
		return "* 아슬아슬하게 스치는 당신을 보고 쌍둥이가 감탄했다! (자비를 베풀 수 있다)"
	if spareable:
		return "* 쌍둥이는 교집합을 사이좋게 나눠 쓰고 있다."
	return ["* A가 B를 밀고, B가 A를 민다.", "* 교집합에서 불꽃이 튄다.", "* 쌍둥이가 서로 '네가 여집합으로 가!'라고 외친다."][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "A: 겹친 곳은...\nB: 우리 둘 다의 것!"
	if angry:
		return "A: 서로소는 싫어!\nB: 싫어!!"
	return ["A: 교집합은 내 거야!\nB: 아니, 내 거야!", "A: 내가 먼저 그려졌어!\nB: 내가 더 동그래!"][randi() % 2]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 벤 쌍둥이 - 공격 3 방어 1", "* A∩B 를 두고 늘 다툰다. 스칠 듯 가까이 다가오는 상대를 좋아한다."])
		1:
			common += 1
			if common == 1:
				await b.say(["* 당신은 둘 다 '동그랗다'는 공통점을 찾아 주었다.", "* 쌍둥이가 조금 누그러졌다. 한 번만 더 하면...?"])
			else:
				spareable = true
				Snd.play("correct")
				await b.say(["* 당신은 '겹친 부분은 둘 모두에 속한다'고 말해 주었다.", "* 쌍둥이는 교집합을 사이좋게 나눠 갖기로 했다!"])
		2:
			angry = true
			await b.say(["* 당신은 둘을 떼어 놓으려 했다.", "* 서로소가 되는 건 싫다며 둘 다 화를 냈다! (다음 공격이 거세진다)"])


func on_graze(_b) -> void:
	grazes += 1
	if grazes == 10 and not spareable:
		spareable = true
		impressed = true
		Snd.play("correct")


func begin_attack(b) -> void:
	b.attack_len = 6.5
	side = 0
	pt = 0.3


func end_attack(_b) -> void:
	angry = false


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (1.3 if angry else 1.0) * (0.7 if spareable else 1.0)
	pt -= delta
	if pt > 0.0:
		return
	if b.turn % 2 == 1:
		# A와 B가 번갈아 원형 탄을 퍼뜨린다
		pt = 0.62 / k
		side = 1 - side
		var c: Vector2 = b.enemy_pos + Vector2(-70 if side == 0 else 70, 30)
		spin += 0.21
		b.ring(c, 11, 82.0 * k, 6, PINK if side == 0 else GREEN, spin)
	else:
		# 위에서 쏟아지는 줄. 교집합(빈틈)에만 설 수 있다
		pt = 0.85 / k
		var gap := randf_range(b.box.position.x + 30, b.box.end.x - 30)
		var x: float = b.box.position.x - 12
		while x < b.box.end.x + 12:
			if absf(x - gap) > 30.0:
				b.add(Vector2(x, 176), Vector2(0, 118.0 * k), 6, PINK if x < gap else GREEN)
			x += 21.0


func kill_text() -> Array:
	return ["* 두 원은 서로소가 되어 흩어졌다..."]


func spare_text() -> Array:
	return ["* 쌍둥이는 나란히 굴러서 방 구석으로 돌아갔다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_venn(ci, pos, t, 1.15, fl, alpha, 1 if spareable else 0)
