extends "res://scripts/battle/enemy_base.gd"
## 거울 속의 나 — 3챕터 편광 실험실의 잡몹. 내가 나에게 하는 말을 그대로 돌려준다.
## 탄은 하트의 '거울 위치'에서 생겨난다. '그래도 괜찮다고 말하기' 세 번으로 살려 줄 수 있다.

const Art = preload("res://scripts/art/art.gd")

const SAYS := [
	"또 틀렸네.\n넌 늘 그래.",
	"다들 너보다\n잘해.",
	"이번에도\n중간만 하겠지.",
	"넌 왜\n이것밖에 안 돼?",
]

var kind := 0
var hurt := false


func _init() -> void:
	id = "mirror"
	name = "거울 속의 나"
	max_hp = 40
	hp = 40
	atk = 3
	exp_reward = 10
	bg = Color(0.2, 0.3, 0.45)
	acts = ["살펴보기", "그래도 괜찮다고 말하기", "거울 깨기"]


func intro() -> String:
	return "* 거울 속의 내가 나를 노려본다. 입 모양이... 나와 다르다."


func flavor(_b) -> String:
	if spareable:
		return "* 거울 속의 내가 처음으로 웃었다. (자비를 베풀 수 있다)"
	return ["* 거울 속의 내가 내 실수를 하나씩 세고 있다.", "* 거울에 비친 얼굴이 너무 익숙해서 오히려 낯설다.", "* 괜찮다고 말한 횟수: %d / 3" % kind][randi() % 3]


func bubble(b) -> String:
	if spareable:
		return "...그래.\n그래도 괜찮아.\n우리."
	if hurt:
		hurt = false
		return "때리면\n너도 아프잖아."
	return SAYS[(b.turn - 1) % SAYS.size()]


func on_hurt(_b, _dmg: int) -> void:
	hurt = true


func on_act(b, i: int) -> void:
	match i:
		0:
			await b.say(["* 거울 속의 나 - 공격 3 방어 0", "* 늘 나에게 가장 가혹한 말을 하는 사람. 그 말은 언제나 내 목소리였다."])
		1:
			kind += 1
			var lines := [
				["* 당신은 거울을 보며 말했다. '틀렸지. 그래도 다시 풀었잖아.'", "* 거울 속의 내가 잠깐 말을 멈췄다."],
				["* '다들 잘하는 것 같아도, 다들 무서워해. 나만 그런 거 아니야.'", "* 거울 속의 내 어깨가 조금 내려갔다."],
				["* '중간이어도 괜찮아. 여기까지 온 것도 나야.'", "* 거울에 김이 서렸다. 그 너머의 내가... 울고 있었다."],
			]
			await b.say(lines[mini(kind - 1, 2)])
			if kind >= 3:
				spareable = true
				Game.emotion += 1
				Snd.play("correct")
				await b.say(["* 거울 속의 내가 고개를 끄덕였다. (감성 +1)"])
		2:
			await b.say(["* 당신은 주먹을 쥐었다가... 내려놓았다.", "* 거울을 깨도 그 목소리는 사라지지 않는다는 걸, 당신은 알고 있다."])


func begin_attack(b) -> void:
	b.attack_len = 4.5 if spareable else 6.5
	pt = 0.4


func update_attack(b, delta: float) -> void:
	var k: float = b.hard() * (0.55 if spareable else 1.0)
	var box: Rect2 = b.box
	pt -= delta
	if pt > 0.0:
		return
	pt = 0.6 / k
	# 하트의 좌우 거울 위치에서 탄이 생겨 하트를 노린다
	var mirror_pos := Vector2(box.position.x + box.end.x - b.soul.x, b.soul.y)
	var bl = b.add(mirror_pos, (b.soul - mirror_pos).normalized() * 130.0 * k, 6, Color(0.7, 0.85, 1.0), 1)
	bl.delay = 0.4
	if b.turn % 2 == 0:
		var mp2 := Vector2(b.soul.x, box.position.y + box.end.y - b.soul.y)
		var bl2 = b.add(mp2, (b.soul - mp2).normalized() * 120.0 * k, 6, Color(0.7, 0.85, 1.0), 1)
		bl2.delay = 0.4
	Snd.play("warn")


func draw_attack(b) -> void:
	var box: Rect2 = b.box
	var cx := box.get_center().x
	b.draw_line(Vector2(cx, box.position.y + 4), Vector2(cx, box.end.y - 4), Color(0.6, 0.8, 1.0, 0.15), 2)


func kill_text() -> Array:
	return ["* 거울이 산산이 깨졌다. 조각마다 내 얼굴이 비친다. 목소리는... 아직 들린다."]


func spare_text() -> Array:
	return ["* 거울 속의 내가 손을 흔들었다. 나도 손을 흔들었다. 이번엔 같은 손이었다."]


func draw(ci: CanvasItem, pos: Vector2, t: float, fl: float, alpha: float) -> void:
	Art.draw_mirror(ci, pos + Vector2(0, 8), t, 0.95, fl, alpha, spareable)
