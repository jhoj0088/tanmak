extends "res://scripts/battle/enemy_base.gd"
## 광해 가로등 — 5장 옥상 잡몹. 너무 밝아서 별을 가린다.
## '갓 씌워 주기'로 빛이 아래로만 가게 한 뒤 '밝기 줄여 주기'를 하면 살려 줄 수 있다.

const Art = preload("res://scripts/art/art.gd")
var shaded := false
var angry := false


func _init() -> void:
	id = "lamp"
	name = "광해 가로등"
	max_hp = 40
	hp = 40
	atk = 4
	exp_reward = 12
	bg = Color(0.25, 0.22, 0.08)
	acts = ["살펴보기", "갓 씌워 주기", "밝기 줄여 주기", "불 꺼 버리기"]


func intro() -> String:
	return "* 옥상 가장자리의 가로등이 눈부시게 빛났다! 별이 하나도 안 보인다."


func flavor(_b) -> String:
	if spareable:
		return "* 가로등이 땅만 은은하게 비춘다. 하늘에 별이 돌아왔다. (자비를 베풀 수 있다)"
	if shaded:
		return "* 갓을 쓴 가로등이 아직 조금 눈부시다."
	return ["* 가로등의 빛이 사방으로 번진다. 하늘까지.", "* 눈이 부셔서 탄이 잘 안 보인다.", "* 가로등: '밝으면 안전하잖아! 밝은 게 좋은 거잖아!'"][randi() % 3]


func bubble(_b) -> String:
	if angry:
		angry = false
		return "끄면 안 돼!\n어두우면\n누가 넘어진다고!"
	if spareable:
		return "아래만 비추니까\n별도 보이고\n길도 보이네..."
	return ["더 밝게!\n더 밝게!", "어둠은\n오류야!", "다 비춰 줄게!\n하늘까지!"][randi() % 3]


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 광해 가로등 - 공격 4 방어 1", "* 사람들이 넘어지지 않게 밤새 켜져 있다. 그런데 빛이 위로도 새어서 별을 지운다."])
		1:
			shaded = true
			Snd.play("correct")
			await b.say(["* 당신은 가로등 머리에 갓을 씌웠다. 빛이 아래로만 떨어진다.", "* 하늘 한쪽에 별이 몇 개 돌아왔다."])
		2:
			if shaded:
				spareable = true
				Snd.play("correct")
				await b.say(["* 당신은 밝기를 한 칸 줄였다. 길은 그대로 보이고, 하늘은 깜깜해졌다.", "* 은하수가 희미하게 떠올랐다!"])
			else:
				await b.say(["* 밝기를 줄여도 빛이 여전히 사방으로 번진다. 먼저 빛의 방향을 잡아야 할 것 같다."])
		3:
			angry = true
			await b.say(["* 당신은 스위치를 내리려 했다.", "* 가로등이 기겁을 하며 더 밝아졌다! (다음 공격이 거세진다)"])


func begin_attack(b) -> void:
	b.attack_len = 4.5 if spareable else 7.0
	pt = 0.4
	spin = randf() * TAU


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (0.5 if spareable else (0.85 if shaded else 1.0))
	var box: Rect2 = b.box
	pt -= delta
	if pt > 0.0:
		return
	pt = 0.55 / k
	spin += 0.33
	var top := Vector2(box.get_center().x, box.position.y - 30)
	if shaded:
		# 갓을 쓰면 아래쪽 부채꼴로만 퍼진다
		for j in 7:
			var ang := PI / 2.0 + (j - 3) * 0.22 + sin(spin) * 0.15
			b.add(top, Vector2.RIGHT.rotated(ang) * 150.0 * k, 5, Color(1.0, 0.9, 0.5))
	else:
		for bl in b.ring(top, 14, 130.0 * k, 5, Color(1.0, 0.95, 0.6), spin):
			pass
		if randi() % 3 == 0:
			b.laser(top, b.aim(top), 0.6, 0.3, 10, Color(1.0, 0.95, 0.6))


func kill_text() -> Array:
	return ["* 가로등이 꺼졌다. 별은 돌아왔지만, 옥상 계단이 캄캄해졌다."]


func spare_text() -> Array:
	return ["* 가로등은 갓을 쓴 채 발밑만 조용히 비춘다. 하늘이 넓어졌다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_lamp(ci, pos + Vector2(0, 20), t, 1.0, fl, alpha, spareable)
