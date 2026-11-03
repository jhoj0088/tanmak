extends "res://scripts/battle/enemy_base.gd"
## 초파리 떼 — 제멋대로 날아다니는 탄 + 터지는 플라스크(2챕터의 새 기믹)를 처음 보여 준다.

const Art = preload("res://scripts/art/art.gd")
const Flask = preload("res://scripts/battle/enemies/flask.gd")

var lured := 0
var angry := false
var flask_t := 0.0


func _init() -> void:
	id = "flies"
	name = "초파리 떼"
	max_hp = 30
	hp = 30
	atk = 3
	exp_reward = 7
	bg = Color(0.4, 0.3, 0.1)
	acts = ["살펴보기", "과일 향 풍기기", "손 휘젓기"]


func intro() -> String:
	return "* 초파리 떼가 몰려왔다! 빨간 눈 수백 개가 이쪽을 본다."


func flavor(_b) -> String:
	if spareable:
		return "* 초파리들이 바나나 향에 취해 얌전해졌다. (자비를 베풀 수 있다)"
	return ["* 초파리들이 8자를 그리며 난다.", "* 한 마리가 당신의 귓가에서 유전 법칙을 속삭였다.", "* 실험실 어딘가에서 플라스크가 달그락거린다."][randi() % 3]


func bubble(_b) -> String:
	if spareable:
		return "(평화로운 윙윙 소리)"
	if angry:
		return "윙윙윙윙!!\n(몹시 화가 났다)"
	return ["윙윙. 우리는\n3세대째 여기 살아.", "윙. 빨간 눈은\n우성이야.", "윙윙. 과일...\n과일 없어?"][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 초파리 떼 - 공격 3 방어 0", "* 학명 Drosophila. 유전학 실험의 단골. 과일 냄새에 사족을 못 쓴다."])
		1:
			lured += 1
			if lured == 1:
				await b.say(["* 당신은 바나나 향 지우개를 꺼내 흔들었다.", "* 초파리 절반이 지우개 쪽으로 몰려갔다. 한 번 더 하면...?"])
			else:
				spareable = true
				Snd.play("correct")
				await b.say(["* 당신은 지우개를 실험대 위에 올려 두었다.", "* 초파리들이 전부 그쪽에 내려앉았다!"])
		2:
			angry = true
			await b.say(["* 당신은 손을 마구 휘저었다.", "* 한 마리도 맞지 않았다. 떼가 더 흥분했다! (다음 공격이 거세진다)"])


func begin_attack(b) -> void:
	b.attack_len = 6.5
	pt = 0.2
	flask_t = 1.0
	if b.turn == 1:
		b.note = "(플라스크는 터지면서 갈라진다!)"


func end_attack(_b) -> void:
	angry = false


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (1.3 if angry else 1.0) * (0.6 if spareable else 1.0)
	pt -= delta
	flask_t -= delta
	if pt <= 0.0:
		pt = 0.55 / k
		# 초파리: 구불구불 날다가 하트 쪽으로 슬쩍 방향을 튼다
		var src: Vector2 = b.enemy_pos + Vector2(randf_range(-80, 80), randf_range(-20, 40))
		var bl = b.add(src, Vector2.RIGHT.rotated(b.aim(src) + randf_range(-0.6, 0.6)) * 85.0 * k, 4, Color(0.95, 0.35, 0.3))
		bl.data["ph"] = randf() * TAU
		bl.life = 5.0
		bl.fn = func(q, d):
			q.vel = q.vel.rotated(sin(q.age * 7.0 + q.data["ph"]) * 2.4 * d)
	if flask_t <= 0.0 and not spareable:
		flask_t = 1.5 / k
		Flask.toss(b, Color(0.5, 1.0, 0.4))


func kill_text() -> Array:
	return ["* 초파리 떼가 뿔뿔이 흩어졌다."]


func spare_text() -> Array:
	return ["* 초파리들은 지우개를 들고(?) 환풍구로 날아갔다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_flies(ci, pos, t, 1.2, fl, alpha, spareable)
