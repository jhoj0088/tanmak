extends Node2D
## C 키 메뉴: 스탯 / 지금 할 일 / 가방·소지품·휴대폰 (←→ 로 탭 전환)
const P = preload("res://scripts/art/palette.gd")

const Items = preload("res://data/items.gd")
const JK = preload("res://data/junkyu.gd")
const Phone = preload("res://data/phone.gd")
const TABS := ["가방", "소지품", "휴대폰"]

var main: Node
var open := false
var tab := 0
var sel := 0
var note := ""
var open_frame := 0


func _list() -> Array:
	match tab:
		0:
			return Game.items
		1:
			return JK.carried()
		_:
			var r: Array = Phone.received()
			r.reverse()
			return r


func _process(_delta: float) -> void:
	if not open:
		if Input.is_action_just_pressed("menu") and not main.is_busy() and not main.dialogue.active and main.world:
			open = true
			sel = 0
			note = ""
			open_frame = Engine.get_process_frames()
			Snd.play("select")
			queue_redraw()
		return
	queue_redraw()
	if Engine.get_process_frames() == open_frame:
		return
	if Input.is_action_just_pressed("menu") or Input.is_action_just_pressed("cancel"):
		open = false
		if main.world:
			main.world.cooldown = 0.2
		return
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		tab = (tab + (1 if Input.is_action_just_pressed("move_right") else 2)) % 3
		sel = 0
		note = ""
		Snd.play("move")
		return
	var list := _list()
	var n := list.size()
	if n == 0:
		return
	if Input.is_action_just_pressed("move_up"):
		sel = (sel - 1 + n) % n
		note = ""
		Snd.play("move")
	elif Input.is_action_just_pressed("move_down"):
		sel = (sel + 1) % n
		note = ""
		Snd.play("move")
	elif Input.is_action_just_pressed("confirm") and tab == 0:
		var item: String = Game.items[sel]
		var d: Dictionary = Items.get_item(item)
		if Game.hp >= Game.max_hp:
			note = "HP가 이미 가득 차 있다."
			Snd.play("wrong")
		else:
			Game.items.remove_at(sel)
			Game.heal(d["heal"])
			Snd.play("heal")
			note = "%s 사용! HP %d / %d" % [item, Game.hp, Game.max_hp]
			sel = clampi(sel, 0, maxi(0, Game.items.size() - 1))


func _draw() -> void:
	if not open:
		return
	var f: Font = Game.font
	draw_rect(Rect2(0, 0, 640, 480), Color(P.UI_BG, 0.55))
	var a := Rect2(32, 32, 230, 262)
	var b := Rect2(276, 32, 332, 262)
	var c := Rect2(32, 306, 576, 148)
	for r in [a, b, c]:
		draw_rect(r, P.UI_BG)
		draw_rect(r, P.UI_INK, false, 4)
	# 스탯
	draw_string(f, a.position + Vector2(18, 38), Game.player_name, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, P.UI_INK)
	draw_string(f, a.position + Vector2(18, 72), "LV  %d" % Game.lv, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, P.UI_INK)
	draw_string(f, a.position + Vector2(18, 100), "HP  %d / %d" % [Game.hp, Game.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, P.UI_INK)
	draw_string(f, a.position + Vector2(18, 128), "EXP %d / %d" % [Game.exp_points, Game.exp_needed(Game.lv)], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, P.UI_INK)
	draw_string(f, a.position + Vector2(18, 164), "논리  %d" % Game.logic, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, P.SKY_100)
	draw_string(f, a.position + Vector2(18, 192), "감성  %d" % Game.emotion, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, P.PEACH_300)
	var certs := ""
	for pair in [["cert_math", "수"], ["cert_bio", "생"], ["cert_phys", "물"], ["cert_dorm", "점"], ["cert_astro", "천"]]:
		if Game.flag(pair[0]):
			certs += pair[1]
	draw_string(f, a.position + Vector2(18, 222), "인증: " + (certs if certs != "" else "없음"), HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_MUTED)
	if Game.flag("met_junkyu"):
		draw_string(f, a.position + Vector2(18, 242), "절규에게 돌려준 물건: %d / 11" % JK.returned_count(), HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_ACCENT)
	# 탭
	for i in 3:
		var tx := b.position.x + 14 + i * 100
		var on := i == tab
		draw_string(f, Vector2(tx, b.position.y + 26), ("[%s]" % TABS[i]) if on else TABS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_ACCENT if on else P.UI_MUTED)
	draw_string(f, Vector2(b.end.x - 64, b.position.y + 26), "← →", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_MUTED.darkened(0.3))
	var list := _list()
	if list.is_empty():
		draw_string(f, b.position + Vector2(40, 70), ["(비어 있음)", "(찾은 물건 없음)", "(메시지 없음)"][tab], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, P.UI_MUTED.darkened(0.3))
	var start := clampi(sel - 5, 0, maxi(0, list.size() - 7))
	for k in mini(list.size() - start, 7):
		var i := start + k
		var label := ""
		match tab:
			0:
				label = str(list[i])
			1:
				label = JK.item(list[i])["name"]
			_:
				var m: Dictionary = Phone.get_msg(list[i])
				label = "%s  %s" % [m["time"], m["from"]]
		var col := P.UI_ACCENT if i == sel else P.UI_INK
		var size := Game.FL if tab == 0 else Game.FS
		var y := b.position.y + 62 + k * (28 if tab == 0 else 26)
		draw_string(f, Vector2(b.position.x + 40, y), label, HORIZONTAL_ALIGNMENT_LEFT, b.size.x - 52, size, col)
		if i == sel:
			draw_string(f, Vector2(b.position.x + 16, y), "▶", HORIZONTAL_ALIGNMENT_LEFT, -1, size, P.UI_SIGNAL)
	# 아래 칸: 지금 할 일 / 설명 / 메시지 내용
	if tab == 2 and not list.is_empty():
		var m2: Dictionary = Phone.get_msg(list[sel])
		draw_string(f, c.position + Vector2(20, 28), "%s  (%s)" % [m2["from"], m2["time"]], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.SKY_100)
		var mt: Array = Game.fit(m2["text"], 536, 3)
		draw_multiline_string(f, c.position + Vector2(20, 60 if mt[1] == Game.FL else 50), mt[0], HORIZONTAL_ALIGNMENT_LEFT, -1, mt[1], -1, P.UI_INK)
	else:
		draw_string(f, c.position + Vector2(20, 28), "지금 할 일", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_MUTED)
		var obj := Game.objective if Game.objective != "" else "..."
		var ot: Array = Game.fit(obj, 536, 2)
		draw_multiline_string(f, c.position + Vector2(20, 60 if ot[1] == Game.FL else 52), ot[0], HORIZONTAL_ALIGNMENT_LEFT, -1, ot[1], 4, P.UI_INK)
		var foot := note
		if foot == "" and not list.is_empty():
			if tab == 0:
				foot = Items.get_item(list[sel])["desc"]
			elif tab == 1:
				foot = JK.item(list[sel])["desc"]
		var fw := Game.wrap(foot, 540, Game.FS)
		draw_multiline_string(f, c.position + Vector2(20, 134 - 16 * mini(fw.count("\n"), 1)), fw, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, 2, P.SKY_100)
	draw_string(f, Vector2(32, 472), "Z: 사용   ← →: 탭   X / C: 닫기", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_MUTED)
