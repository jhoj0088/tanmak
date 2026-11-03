extends Node2D
## 전투 화면: 언더테일식 턴 메뉴 + 동방식 탄막 회피.
## 적마다 다른 부분(대사, 행동, 탄막)은 scripts/battle/enemies/*.gd 에 있다.
##
## 한 턴의 흐름:  메뉴(싸운다/행동/아이템/자비) → 적의 말풍선 → 탄막 피하기 → 다시 메뉴
const P = preload("res://scripts/art/palette.gd")

signal finished(result: String)     # "spared" / "killed" / "fled"
signal step(value)

const Art = preload("res://scripts/art/art.gd")
const Bullet = preload("res://scripts/battle/bullet.gd")
const Laser = preload("res://scripts/battle/laser.gd")
const Items = preload("res://data/items.gd")
const Enemies = preload("res://scripts/battle/enemies.gd")

const MENU_BOX := Rect2(32, 250, 576, 140)
const DEFAULT_ATTACK_BOX := Rect2(180, 215, 280, 175)
const BUTTONS := ["싸운다", "행동", "아이템", "자비"]
const SOUL_SPEED := 165.0
const SOUL_FOCUS_SPEED := 65.0    # Shift 를 누르고 있을 때
const SOUL_R := 2.5               # 실제 피격 판정 (하트 그림보다 훨씬 작다)
const GRAZE_GAIN := 4.0           # 스칠 때마다 차는 집중 게이지
const BOMB_COST := 50.0           # 폭탄에 드는 게이지

var main: Node
var enemy_id := ""
var enemy

var mode := ""
var mode_t := 0.0
var input_frame := 0
var t := 0.0
var turn := 0

var box := MENU_BOX
var attack_box := DEFAULT_ATTACK_BOX
var enemy_pos := Vector2(320, 135)
var shake := 0.0
var flash := 0.0
var enemy_alpha := 1.0
var screen_shake := 0.0
var particles: Array = []
var bubble := ""

var btn := 0
var flavor := ""
var flavor_shown := 0.0

var list_opts: Array = []
var list_yellow: Array = []
var list_sel := 0
var list_cancel := true

var text_lines: Array = []
var text_idx := 0
var text_cur := ""
var text_shown := 0.0

var fight_x := 0.0
var fight_done_t := -1.0
var dmg_label := ""
var dmg_timer := 0.0

var soul := Vector2(320, 300)
var soul_moving := false
var invuln := 0.0
var gauge := 0.0
var graze_total := 0
var bullets: Array = []
var attack_t := 0.0
var attack_len := 7.0
var note := ""
var bomb_flash := 0.0
var items_backup: Array = []
var lasers: Array = []
var pending: Array = []        # 탄 목록을 도는 중에 새로 생긴 탄
var iterating := false
var dark := 0.0                # 0 보다 크면 어둠 속 전투 (보이는 반지름)
var look_dir := Vector2.UP     # 손전등 방향 (마지막으로 움직인 방향)
var beat_clock := 0.0
var beat_i := 0
var beat_hit := false
var beat_frac := 0.0
var force_end := ""            # 적 스크립트가 "spared" 를 넣으면 전투가 그 결과로 끝난다
var ui_hide := {}              # 최종전 연출: "hp", "gauge", "border" 를 넣으면 그 UI 가 사라진다
var hits_this_attack := 0
var ally_queue: Array = []      # 최종전에서 도와주러 오는 동료들 (Game.allies 에서 복사)
var ally_shield := 0            # 동료가 막아 주는 피격 횟수


func _ready() -> void:
	items_backup = Game.items.duplicate()
	ally_queue = Game.allies.duplicate(true)
	enemy = Enemies.create(enemy_id)
	run.call_deferred()


# ================================================================ 전투 진행 (코루틴)
func run() -> void:
	while true:
		Snd.play_music(enemy.music)
		turn = 0
		gauge = 0.0
		graze_total = 0
		enemy_alpha = 1.0
		box = MENU_BOX
		bullets.clear()
		lasers.clear()
		force_end = ""
		ui_hide = {}
		dark = 0.0
		beat_clock = 0.0
		flavor = enemy.intro()
		var result: String = await _battle_loop()
		if result != "retry":
			mode = "done"
			finished.emit(result)
			return
		# 다시 도전: 체력과 아이템을 전투 시작 때로 되돌린다
		Game.hp = Game.max_hp
		Game.items = items_backup.duplicate()
		ally_queue = Game.allies.duplicate(true)
		ally_shield = 0
		enemy = Enemies.create(enemy_id)


func _battle_loop() -> String:
	while true:
		var r: String = await _player_turn()
		if r != "":
			return r
		await _enemy_turn()
		if Game.hp <= 0:
			await _game_over()
			return "retry"
	return ""


func _player_turn() -> String:
	while true:
		var b: int = await _pick_button()
		match b:
			0:
				# 공격 막대가 움직이는 동안 X 를 누르면 공격을 취소하고 메뉴로 돌아간다 (자비 등으로 바꿀 수 있다)
				if not await _fight():
					continue
				if enemy.hp <= 0:
					await _kill()
					return "killed"
				return ""
			1:
				var i: int = await pick(enemy.acts)
				if i < 0:
					continue
				await enemy.on_act(self, i)
				if force_end == "spared":
					await _spare()
				if force_end != "":
					return force_end
				return ""
			2:
				if Game.items.is_empty():
					await say(["* 가방이 텅 비었다."])
					continue
				var k: int = await pick(Game.items.slice(0, 6))
				if k < 0:
					continue
				await _use_item(k)
				return ""
			3:
				var m: int = await pick(["살려 주기", "도망치기"], [0] if enemy.spareable else [])
				if m < 0:
					continue
				if m == 0:
					if enemy.spareable:
						await _spare()
						return "spared"
					await say(enemy.not_yet_text())
					return ""
				if not enemy.can_flee:
					await say(["* 도망칠 수 없다!"])
					return ""
				if randf() < 0.6:
					await say(["* 슬금슬금 뒷걸음질 쳐서 도망쳤다..."])
					return "fled"
				await say(["* 도망치려 했지만 길이 막혔다!"])
				return ""
	return ""


func _enemy_turn() -> void:
	turn += 1
	bubble = Game.wrap(enemy.bubble(self), 190, Game.FS)
	if bubble != "":
		_set_mode("talk")
		await step
	attack_box = DEFAULT_ATTACK_BOX
	attack_len = 7.0
	note = ""
	dark = 0.0
	hits_this_attack = 0
	enemy.pt = 0.0
	enemy.begin_attack(self)
	var tw := create_tween()
	tw.tween_property(self, "box", attack_box, 0.25)
	soul = attack_box.get_center() + Vector2(0, attack_box.size.y * 0.25)
	bullets.clear()
	attack_t = -0.5
	_set_mode("attack")
	await step
	bullets.clear()
	lasers.clear()
	dark = 0.0
	var tw2 := create_tween()
	tw2.tween_property(self, "box", MENU_BOX, 0.25)
	enemy.end_attack(self)
	flavor = enemy.flavor(self)
	_ally_help()


## 살려 준 이들이 도와주러 온다 (두 턴에 한 명씩)
func _ally_help() -> void:
	if ally_queue.is_empty() or turn % 2 == 0:
		return
	var a: Dictionary = ally_queue.pop_front()
	match a.get("effect", "heal"):
		"gauge":
			gauge = 100.0
		"shield":
			ally_shield += 1
		_:
			Game.heal(int(a.get("amount", 15)))
	Snd.play("heal")
	flavor = a.get("line", "* 누군가 도와주러 왔다.")


## 공격하면 true, X 로 취소하면 false
func _fight() -> bool:
	fight_x = 0.0
	fight_done_t = -1.0
	_set_mode("fight")
	var v: int = await step
	return v >= 0


func _use_item(i: int) -> void:
	var item: String = Game.items[i]
	Game.items.remove_at(i)
	var d: Dictionary = Items.get_item(item)
	Game.heal(d["heal"])
	Snd.play("heal")
	var extra := "* HP가 가득 찼다." if Game.hp == Game.max_hp else "* HP를 %d 회복했다." % d["heal"]
	await say([d["text"], extra])


func _spare() -> void:
	enemy_alpha = 0.45
	Snd.play("correct")
	var gain := 3 if enemy.boss else 1
	Game.emotion += gain
	var lines: Array = enemy.spare_text()
	lines.append("* 싸움이 끝났다! EXP %d, 감성 +%d." % [enemy.exp_reward, gain])
	if Game.add_exp(enemy.exp_reward):
		lines.append("* LV가 %d(으)로 올랐다! 최대 HP가 늘었다." % Game.lv)
	await say(lines)


func _kill() -> void:
	for i in 80:
		particles.append({
			"pos": enemy_pos + Vector2(randf_range(-40, 40), randf_range(-80, 60)),
			"vel": Vector2(randf_range(-30, 30), randf_range(-60, -10)),
			"a": randf_range(0.8, 1.4),
		})
	_set_mode("dying")
	await main.wait(1.6)
	var gain := 3 if enemy.boss else 1
	Game.logic += gain
	var lines: Array = enemy.kill_text()
	lines.append("* 이겼다. EXP %d, 논리 +%d." % [enemy.exp_reward, gain])
	if Game.add_exp(enemy.exp_reward):
		lines.append("* LV가 %d(으)로 올랐다! 최대 HP가 늘었다." % Game.lv)
	await say(lines)


func _game_over() -> void:
	bullets.clear()
	Snd.stop_music()
	_set_mode("gameover")
	await step


# ---------------------------------------------------------------- 적 스크립트가 쓰는 함수
## 아래 상자에 문장을 차례로 보여 준다.
func say(lines: Array) -> void:
	if lines.is_empty():
		return
	# 3줄을 넘는 문장은 여러 쪽으로 나눈다 (창을 넘지 않게)
	text_lines = []
	for one in lines:
		text_lines.append_array(Game.pages(str(one), MENU_BOX.size.x - 48, Game.FL))
	text_idx = 0
	_set_text()
	_set_mode("text")
	await step


## 목록에서 하나 고른다. 취소하면 -1.
func pick(opts: Array, yellow: Array = [], cancellable := true) -> int:
	list_opts = opts
	list_yellow = yellow
	list_sel = 0
	list_cancel = cancellable
	_set_mode("list")
	var v: int = await step
	return v


## 취소할 수 없는 선택지 (퀴즈 등)
func choose(opts: Array) -> int:
	return await pick(opts, [], false)


func add(pos: Vector2, vel: Vector2, r: float, col: Color, shape := 0):
	var b = Bullet.new()
	b.pos = pos
	b.vel = vel
	b.r = r
	b.color = col
	b.shape = shape
	if iterating:
		pending.append(b)
	else:
		bullets.append(b)
	return b


## 탄 하나를 터뜨려 n 개의 조각으로 만든다. random 이 클수록 방향·속력이 제멋대로.
func burst(bl, n: int, speed: float, r: float, col: Color, random := 0.0, shape := 0) -> Array:
	bl.life = 0.0
	var out: Array = []
	var base := randf() * TAU
	for i in n:
		var ang := base + TAU * i / n + randf_range(-random, random)
		var sp := speed * randf_range(1.0 - random * 0.4, 1.0 + random * 0.4)
		out.append(add(bl.pos, Vector2.RIGHT.rotated(ang) * sp, r, col, shape))
	for i in 5:
		particles.append({"pos": bl.pos, "vel": Vector2(randf_range(-60, 60), randf_range(-60, 60)), "a": 0.6})
	return out


func laser(from: Vector2, angle: float, warn: float, active: float, width: float, col: Color):
	var l = Laser.new()
	l.from = from
	l.angle = angle
	l.warn = warn
	l.active = active
	l.width = width
	l.color = col
	lasers.append(l)
	return l


## 개발자 모드: F2 = 지금 바로 살려 줄 수 있게, F3 = 적 HP 를 1로
func _dev_keys() -> void:
	if not Game.dev or enemy == null:
		return
	if Input.is_action_just_pressed("dev_spare"):
		enemy.spareable = true
		Snd.play("correct")
	elif Input.is_action_just_pressed("dev_win"):
		enemy.hp = mini(enemy.hp, 1)
		Snd.play("correct")


## 하트에게 피해를 준다 (무적 시간 중이면 무시)
func hurt() -> void:
	if invuln <= 0.0 and mode == "attack":
		_player_hit()


## 박자 하나의 길이(초)
func beat_len() -> float:
	return 60.0 / enemy.bpm if enemy.bpm > 0.0 else 0.5


func ring(center: Vector2, n: int, speed: float, r: float, col: Color, offset := 0.0, shape := 0) -> Array:
	var out: Array = []
	for i in n:
		out.append(add(center, Vector2.RIGHT.rotated(offset + TAU * i / n) * speed, r, col, shape))
	return out


func aim(from: Vector2) -> float:
	return (soul - from).angle()


## 턴이 지날수록 조금씩 빨라지는 배율
func hard() -> float:
	return 1.0 + minf(turn, 8) * 0.03


# ---------------------------------------------------------------- 내부
func _pick_button() -> int:
	flavor_shown = 0.0
	_set_mode("menu")
	var v: int = await step
	return v


func _set_mode(m: String) -> void:
	mode = m
	mode_t = 0.0
	input_frame = Engine.get_process_frames()


func _set_text() -> void:
	text_cur = Game.wrap(str(text_lines[text_idx]), MENU_BOX.size.x - 48, Game.FL)
	text_shown = 0.0


func _ok() -> bool:
	return Engine.get_process_frames() != input_frame and Input.is_action_just_pressed("confirm")


func _back() -> bool:
	return Engine.get_process_frames() != input_frame and Input.is_action_just_pressed("cancel")


# ================================================================ 매 프레임
func _process(delta: float) -> void:
	t += delta
	mode_t += delta
	shake = maxf(0.0, shake - delta)
	flash = maxf(0.0, flash - delta)
	invuln = maxf(0.0, invuln - delta)
	screen_shake = maxf(0.0, screen_shake - delta)
	dmg_timer = maxf(0.0, dmg_timer - delta)
	bomb_flash = maxf(0.0, bomb_flash - delta)
	position = Vector2(randf_range(-4, 4), randf_range(-4, 4)) if screen_shake > 0.0 else Vector2.ZERO
	for p in particles:
		p["pos"] += p["vel"] * delta
		p["a"] -= delta * 0.7
	particles = particles.filter(func(p): return p["a"] > 0.0)
	queue_redraw()
	_dev_keys()
	_update_beat(delta)

	match mode:
		"menu":
			flavor_shown = minf(flavor_shown + delta * 45.0, flavor.length())
			if Input.is_action_just_pressed("move_left"):
				btn = (btn + 3) % 4
				Snd.play("move")
			elif Input.is_action_just_pressed("move_right"):
				btn = (btn + 1) % 4
				Snd.play("move")
			elif _ok():
				Snd.play("select")
				step.emit(btn)
		"list":
			var n := list_opts.size()
			if n == 0:
				step.emit(-1)
			elif Input.is_action_just_pressed("move_up"):
				list_sel = (list_sel - 1 + n) % n
				Snd.play("move")
			elif Input.is_action_just_pressed("move_down"):
				list_sel = (list_sel + 1) % n
				Snd.play("move")
			elif _ok():
				Snd.play("select")
				step.emit(list_sel)
			elif list_cancel and _back():
				step.emit(-1)
		"text":
			var before := int(text_shown)
			text_shown = minf(text_shown + delta * 45.0, text_cur.length())
			var now := int(text_shown)
			if now != before and now % 2 == 0 and now > 0 and text_cur[now - 1] != " ":
				Snd.play("blip")
			if _ok():
				if text_shown < text_cur.length():
					text_shown = text_cur.length()
				else:
					text_idx += 1
					if text_idx >= text_lines.size():
						step.emit(0)
					else:
						_set_text()
			elif _back():
				text_shown = text_cur.length()
		"fight":
			_process_fight()
		"talk":
			if _ok() or mode_t > 5.0:
				step.emit(0)
		"attack":
			_process_attack(delta)
		"dying":
			enemy_alpha = maxf(0.0, 1.0 - mode_t / 1.2)
		"gameover":
			if mode_t > 1.8 and _ok():
				step.emit(0)


func _update_beat(delta: float) -> void:
	beat_hit = false
	if enemy == null or enemy.bpm <= 0.0:
		return
	beat_clock += delta
	var mt := Snd.music_time()
	if mt >= 0.0 and absf(fposmod(mt - beat_clock + 30.0, 60.0) - 30.0) > 0.06:
		beat_clock = mt        # 음악과 어긋나면 음악에 맞춘다
	var bp: float = beat_clock * enemy.bpm / 60.0
	var bi := int(floor(bp))
	beat_frac = bp - bi
	if bi != beat_i:
		beat_i = bi
		beat_hit = true


func _process_fight() -> void:
	if fight_done_t < 0.0:
		fight_x = mode_t / 1.1
		if _back():
			Snd.play("move")
			step.emit(-1)
			return
		if _ok():
			fight_done_t = mode_t
			var acc := 1.0 - absf(fight_x - 0.5) * 2.0      # 1 = 정중앙
			var power := Game.attack_power() * (1.0 + gauge / 200.0)
			var dmg := int(round(power * (0.35 + 0.9 * acc))) - int(enemy.def)
			dmg = maxi(dmg, 1)
			enemy.hp = maxi(0, enemy.hp - dmg)
			enemy.on_hurt(self, dmg)
			dmg_label = str(dmg)
			dmg_timer = 1.2
			shake = 0.5
			flash = 0.15
			Snd.play("hit")
		elif fight_x >= 1.0:
			fight_done_t = mode_t
			dmg_label = "MISS"
			dmg_timer = 1.0
	elif mode_t - fight_done_t > 1.0:
		step.emit(0)


func _process_attack(delta: float) -> void:
	attack_t += delta
	var dir := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	soul_moving = dir != Vector2.ZERO
	if soul_moving:
		look_dir = dir.normalized()
	var spd := SOUL_FOCUS_SPEED if Input.is_action_pressed("focus") else SOUL_SPEED
	soul += dir.normalized() * spd * delta
	var inner := box.grow(-9)
	soul = soul.clamp(inner.position, inner.end)

	# 폭탄: 게이지를 써서 화면의 탄을 전부 지운다
	if Input.is_action_just_pressed("cancel") and gauge >= BOMB_COST and attack_t > 0.0:
		gauge -= BOMB_COST
		for b in bullets:
			particles.append({"pos": b.pos, "vel": Vector2(randf_range(-40, 40), randf_range(-40, 40)), "a": 0.8})
		bullets.clear()
		lasers.clear()
		invuln = 1.0
		bomb_flash = 0.4
		Snd.play("bomb")

	if attack_t >= 0.0 and attack_t < attack_len:
		enemy.update_attack(self, delta)

	var alive: Array = []
	iterating = true
	for b in bullets:
		b.age += delta
		if b.age > b.life:
			continue
		if b.delay > 0.0:
			b.delay -= delta
			alive.append(b)
			continue
		if b.fn.is_valid():
			b.fn.call(b, delta)
		if b.curve != 0.0:
			b.vel = b.vel.rotated(b.curve * delta)
		if b.accel != 0.0:
			b.vel += b.vel.normalized() * b.accel * delta
		if b.gravity != 0.0:
			b.vel.y += b.gravity * delta
		b.pos += b.vel * delta
		if b.pos.x < -60 or b.pos.x > 700 or b.pos.y < -60 or b.pos.y > 540:
			continue
		var d: float = b.pos.distance_to(soul)
		var dangerous := true
		if b.kind == 1:
			dangerous = soul_moving
		elif b.kind == 2:
			dangerous = not soul_moving
		if invuln <= 0.0 and dangerous and d < b.r * 0.6 + SOUL_R:
			_player_hit()
			if Game.hp <= 0:
				iterating = false
				pending.clear()
				step.emit(0)
				return
			continue
		if not b.grazed and d < b.r + 14.0:
			b.grazed = true
			graze_total += 1
			gauge = minf(100.0, gauge + GRAZE_GAIN)
			enemy.on_graze(self)
			Snd.play("graze")
		alive.append(b)
	iterating = false
	alive.append_array(pending)
	pending.clear()
	bullets = alive

	# 레이저
	var live_lasers: Array = []
	for l in lasers:
		l.age += delta
		if l.fn.is_valid():
			l.fn.call(l, delta)
		if l.age >= l.warn + l.active:
			continue
		live_lasers.append(l)
		if not l.is_firing() or invuln > 0.0:
			continue
		if (l.kind == 1 and not soul_moving) or (l.kind == 2 and soul_moving):
			continue
		if l.dist_to(soul) < l.width * 0.5 + SOUL_R:
			_player_hit()
			if Game.hp <= 0:
				step.emit(0)
				return
	lasers = live_lasers

	if Game.hp <= 0:
		step.emit(0)
		return
	if attack_t >= attack_len + 0.5:
		step.emit(0)


func _player_hit() -> void:
	if ally_shield > 0:
		ally_shield -= 1
		invuln = 1.2
		Snd.play("graze")
		return
	if Game.dev_god:
		invuln = 0.4
		Snd.play("graze")
		return
	var dmg := int(enemy.atk)
	if Game.easy:
		dmg = maxi(1, (dmg + 1) / 2)
	Game.hp = maxi(0, Game.hp - dmg)
	hits_this_attack += 1
	invuln = 1.2
	screen_shake = 0.3
	Snd.play("hurt")


# ================================================================ 그리기
func _draw() -> void:
	var f: Font = Game.font
	draw_rect(Rect2(-20, -20, 680, 520), P.UI_BG)
	if mode == "gameover":
		_draw_gameover(f)
		return

	# 배경: 흐르는 모눈
	var grid_col: Color = enemy.bg
	grid_col.a = 0.35
	var gy := fmod(t * 12.0, 40.0)
	for i in 14:
		draw_line(Vector2(0, i * 40 + gy - 40), Vector2(640, i * 40 + gy - 40), grid_col, 1)
	for i in 17:
		draw_line(Vector2(i * 40, 0), Vector2(i * 40, 480), grid_col, 1)

	# 적
	var ep := enemy_pos
	if shake > 0.0:
		ep.x += sin(t * 60.0) * 8.0 * shake
	if enemy_alpha > 0.0:
		enemy.draw(self, ep, t, flash, enemy_alpha)
	for p in particles:
		draw_rect(Rect2(p["pos"], Vector2(3, 3)), Color(P.PAPER, clampf(p["a"], 0.0, 1.0)))

	if dmg_timer > 0.0:
		var bar := Rect2(enemy_pos.x - 60, 10, 120, 10)
		draw_rect(bar, P.INLAY_900)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * enemy.hp / enemy.max_hp, bar.size.y)), P.LIME_300)
		var col := P.UI_MUTED if dmg_label == "MISS" else P.UI_SIGNAL
		draw_string(f, Vector2(enemy_pos.x - 80, 50 - (1.2 - dmg_timer) * 12.0), dmg_label, HORIZONTAL_ALIGNMENT_CENTER, 160, Game.FL, col)

	if mode == "talk":
		_draw_bubble(f)

	# 상자
	draw_rect(box, P.UI_BG)
	if not ui_hide.has("border"):
		var border := P.UI_INK
		if enemy.bpm > 0.0 and mode == "attack":
			border = P.UI_INK.lerp(P.SKY_100, clampf(1.0 - beat_frac * 2.5, 0.0, 1.0))
		draw_rect(box, border, false, 4)
	if mode == "attack":
		if dark > 0.0:
			_draw_light()
		enemy.draw_attack(self)
	var tp := box.position + Vector2(24, 40)
	match mode:
		"menu":
			var ft: Array = Game.fit(flavor, MENU_BOX.size.x - 48, 3)
			draw_multiline_string(f, tp - Vector2(0, 0 if ft[1] == Game.FL else 10), ft[0].substr(0, int(flavor_shown)), HORIZONTAL_ALIGNMENT_LEFT, -1, ft[1])
		"text":
			draw_multiline_string(f, tp, text_cur.substr(0, int(text_shown)), HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL)
		"list":
			_draw_list(f)
		"fight":
			_draw_fight_bar()

	if mode == "list" and list_cancel:
		draw_string(f, Vector2(box.position.x, box.position.y - 8), "X: 뒤로", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_MUTED)
	if mode == "menu" or mode == "list":
		var name_col := P.UI_ACCENT if enemy.spareable else P.UI_INK
		draw_string(f, Vector2(box.end.x - 300, box.position.y - 8), "* " + enemy.name, HORIZONTAL_ALIGNMENT_RIGHT, 296, Game.FS, name_col)

	# 하트 + 탄
	if mode == "attack":
		if note != "":
			draw_multiline_string(f, box.position + Vector2(10, 24), Game.wrap(note, box.size.x - 20, Game.FS), HORIZONTAL_ALIGNMENT_CENTER, box.size.x - 20, Game.FS, -1, P.UI_MUTED)
		if invuln <= 0.0 or int(t * 15.0) % 2 == 0:
			Art.draw_heart(self, soul, 8.0, P.UI_SIGNAL)
		if Input.is_action_pressed("focus"):
			draw_arc(soul, 10, t * 3.0, t * 3.0 + TAU * 0.8, 24, Color(P.UI_INK, 0.6), 1.5)
			draw_circle(soul, SOUL_R + 0.5, P.UI_INK)
		draw_string(f, Vector2(box.end.x - 120, box.position.y - 8), "GRAZE %d" % graze_total, HORIZONTAL_ALIGNMENT_RIGHT, 118, Game.FS, P.SKY_100)
		if gauge >= BOMB_COST and int(t * 4.0) % 2 == 0:
			draw_string(f, Vector2(box.position.x, box.position.y - 8), "X: 폭탄", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_ACCENT)
	for l in lasers:
		_draw_laser(l)
	for b in bullets:
		if dark <= 0.0 or b.delay > 0.0 or _lit(b.pos):
			_draw_bullet(f, b)
	if bomb_flash > 0.0:
		draw_rect(Rect2(0, 0, 640, 480), Color(P.UI_INK, bomb_flash * 1.5))

	_draw_hud(f)


func _draw_hud(f: Font) -> void:
	draw_rect(Rect2(0, 394, 640, 90), P.UI_BG)
	draw_string(f, Vector2(32, 420), "%s  LV %d" % [Game.player_name, Game.lv], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, P.UI_INK)
	if not ui_hide.has("hp"):
		draw_string(f, Vector2(176, 417), "HP", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_INK)
		var hp_w := clampf(Game.max_hp * 2.0, 40.0, 110.0)
		var hp_bar := Rect2(198, 402, hp_w, 20)
		draw_rect(hp_bar, P.UI_SIGNAL.darkened(0.5))
		draw_rect(Rect2(hp_bar.position, Vector2(hp_w * Game.hp / Game.max_hp, 20)), P.UI_ACCENT)
		draw_string(f, Vector2(hp_bar.end.x + 8, 420), "%d/%d" % [Game.hp, Game.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, P.UI_INK)
	# 집중 게이지
	if not ui_hide.has("gauge"):
		draw_string(f, Vector2(462, 417), "집중", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.SKY_100)
		var g_bar := Rect2(494, 402, 114, 20)
		draw_rect(g_bar, P.NIGHT_900)
		var g_col := P.SKY_100 if gauge < BOMB_COST else P.UI_ACCENT
		draw_rect(Rect2(g_bar.position, Vector2(g_bar.size.x * gauge / 100.0, 20)), g_col)
		draw_line(g_bar.position + Vector2(57, 0), g_bar.position + Vector2(57, 20), Color(P.UI_INK, 0.6), 1)
		draw_rect(g_bar, P.SKY_300, false, 1)

	for i in 4:
		var r := Rect2(32 + i * 150, 432, 126, 38)
		var selected := i == btn and mode in ["menu", "list", "fight"]
		var col := P.UI_ACCENT if selected else P.PEACH_300
		draw_rect(r, col, false, 2)
		draw_string(f, Vector2(r.position.x + 12, r.position.y + 28), BUTTONS[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 12, Game.FL, col)
		if selected and mode == "menu":
			Art.draw_heart(self, r.position + Vector2(16, 19), 7.0, P.UI_SIGNAL)


## 선택지 그리기. 짧으면 두 칸 x 세 줄, 길면 한 칸으로 줄을 바꾸고, 그래도 넘치면 작은 글씨.
func _draw_list(f: Font) -> void:
	var n := list_opts.size()
	var short := n <= 6
	for o in list_opts:
		if f.get_string_size("* " + str(o), HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL).x > 250:
			short = false
	if short:
		for i in n:
			var p := box.position + Vector2(60 + (i / 3) * 270, 40 + (i % 3) * 34)
			var c := P.UI_ACCENT if i in list_yellow else P.UI_INK
			draw_string(f, p, "* " + str(list_opts[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, c)
			if i == list_sel:
				Art.draw_heart(self, p + Vector2(-22, -9), 7.0, P.UI_SIGNAL)
		return
	var width := box.size.x - 90
	var size := Game.FL
	var lh := 28.0
	var texts: Array = []
	var total := 0
	for o in list_opts:
		var w := Game.wrap("* " + str(o), width, Game.FL)
		texts.append(w)
		total += w.count("\n") + 1
	if total > 4:
		size = Game.FS
		lh = 17.0
		texts.clear()
		for o in list_opts:
			texts.append(Game.wrap("* " + str(o), width, Game.FS))
	var y := box.position.y + (40.0 if size == Game.FL else 26.0)
	for i in n:
		var c2 := P.UI_ACCENT if i in list_yellow else P.UI_INK
		if i == list_sel:
			c2 = P.UI_ACCENT
			Art.draw_heart(self, Vector2(box.position.x + 38, y - (9.0 if size == Game.FL else 5.0)), 6.0 if size == Game.FS else 7.0, P.UI_SIGNAL)
		draw_multiline_string(f, Vector2(box.position.x + 60, y), texts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, -1, c2)
		y += lh * (texts[i].count("\n") + 1) + (4.0 if size == Game.FS else 2.0)


func _draw_fight_bar() -> void:
	var inner := box.grow(-12)
	var cx := inner.get_center().x
	for i in 12:
		var k := float(i) / 12.0
		var half := inner.size.x * 0.5 * (1.0 - k)
		var c := P.BENCH_700.lerp(P.LIME_300, k)
		draw_rect(Rect2(cx - half, inner.position.y + 10 + k * 20, half * 2, inner.size.y - 20 - k * 40), c)
	draw_line(Vector2(cx, inner.position.y), Vector2(cx, inner.end.y), Color(P.UI_INK, 0.8), 2)
	if fight_done_t < 0.0:
		draw_string(Game.font, Vector2(box.position.x, box.position.y - 8), "Z: 공격   X: 취소", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_MUTED)
	var x := inner.position.x + clampf(fight_x, 0.0, 1.0) * inner.size.x
	var blink := fight_done_t >= 0.0 and int(t * 12.0) % 2 == 0
	draw_rect(Rect2(x - 4, inner.position.y - 4, 8, inner.size.y + 8), P.UI_BG if blink else P.UI_INK)
	draw_rect(Rect2(x - 4, inner.position.y - 4, 8, inner.size.y + 8), P.UI_BG, false, 2)
	if fight_done_t >= 0.0 and dmg_label != "MISS" and mode_t - fight_done_t < 0.4:
		var k2 := (mode_t - fight_done_t) / 0.4
		draw_line(enemy_pos + Vector2(-50, -60), enemy_pos + Vector2(-50, -60).lerp(Vector2(50, 40), k2), P.UI_SIGNAL, 5)


func _draw_bubble(f: Font) -> void:
	var lines := bubble.count("\n") + 1
	var r := Rect2(enemy_pos + Vector2(86, -70), Vector2(214, 22 + lines * 16))
	draw_rect(r, P.UI_INK)
	draw_colored_polygon(PackedVector2Array([r.position + Vector2(0, 20), r.position + Vector2(-18, 30), r.position + Vector2(0, 38)]), P.UI_INK)
	draw_multiline_string(f, r.position + Vector2(12, 22), bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, -1, P.UI_BG)


func _draw_bullet(f: Font, b) -> void:
	var col: Color = b.color
	if b.kind == 1:
		col = Color(0.25, 0.7, 1.0)
	elif b.kind == 2:
		col = Color(1.0, 0.6, 0.1)
	if b.delay > 0.0:
		col.a = 0.35 + 0.4 * absf(sin(b.age * 14.0))
	match b.shape:
		1:
			draw_set_transform(b.pos, b.vel.angle(), Vector2(1.9, 0.75))
			draw_circle(Vector2.ZERO, b.r + 1.5, col.darkened(0.3))
			draw_circle(Vector2.ZERO, b.r, col)
			draw_circle(Vector2.ZERO, b.r * 0.45, Color(1, 1, 1, col.a))
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		2:
			draw_circle(b.pos, b.r + 3.0, Color(col, 0.25 * col.a))
			draw_string(f, b.pos + Vector2(-12, 8), b.text, HORIZONTAL_ALIGNMENT_CENTER, 24, Game.FL, col)
		3:
			draw_arc(b.pos, b.r, 0, TAU, 14, col, 2.5)
		4:
			# 플라스크: 곧 터진다
			var k: float = b.r / 8.0
			var wob: float = sin(b.age * 20.0) * 0.15
			draw_set_transform(b.pos, wob, Vector2(k, k))
			draw_colored_polygon(PackedVector2Array([Vector2(-3, -11), Vector2(3, -11), Vector2(3, -4), Vector2(9, 8), Vector2(-9, 8), Vector2(-3, -4)]), Color(0.85, 0.95, 1.0, 0.9 * col.a))
			draw_colored_polygon(PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(8, 7), Vector2(-8, 7)]), col)
			draw_rect(Rect2(-4, -13, 8, 2), Color(0.6, 0.4, 0.2, col.a))
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		5:
			# 세포: 말랑한 덩어리
			var wob2: float = 1.0 + sin(b.age * 6.0) * 0.08
			draw_circle(b.pos, b.r * wob2, Color(col, 0.45 * col.a))
			draw_arc(b.pos, b.r * wob2, 0, TAU, 18, col, 2.0)
			draw_circle(b.pos + Vector2(b.r * 0.2, -b.r * 0.15), b.r * 0.35, col.darkened(0.3))
		_:
			draw_circle(b.pos, b.r + 2.0, Color(col, 0.35 * col.a))
			draw_circle(b.pos, b.r, col)
			if b.kind == 0:
				draw_circle(b.pos, b.r * 0.5, Color(1, 1, 1, col.a))


func _draw_laser(l) -> void:
	var col: Color = l.color
	if l.kind == 1:
		col = Color(0.25, 0.7, 1.0)
	elif l.kind == 2:
		col = Color(1.0, 0.6, 0.1)
	var to: Vector2 = l.from + Vector2.RIGHT.rotated(l.angle) * l.length
	if l.age < l.warn:
		var a: float = 0.4 + 0.5 * absf(sin(l.age * 16.0))
		draw_line(l.from, to, Color(col, a), 2.0)
		if l.kind != 0:
			draw_line(l.from, to, Color(col, 0.08), l.width)
	else:
		var k: float = 1.0 - (l.age - l.warn) / l.active
		var wdt: float = l.width * (0.6 + 0.4 * k)
		draw_line(l.from, to, Color(col, 0.55 if l.kind != 0 else 0.9), wdt)
		if l.kind == 0:
			draw_line(l.from, to, Color(1, 1, 1, 0.9), wdt * 0.35)


## 어둠 속 전투: 그 위치가 하트 주변이나 손전등 불빛 안에 있는가
func _lit(p: Vector2) -> bool:
	var d := p.distance_to(soul)
	if d < dark:
		return true
	return d < dark * 2.8 and absf(angle_difference(look_dir.angle(), (p - soul).angle())) < 0.5


func _draw_light() -> void:
	draw_circle(soul, dark, Color(P.PAPER, 0.06))
	var pts := PackedVector2Array([soul])
	for i in 9:
		pts.append(soul + look_dir.rotated(-0.5 + i * 0.125) * dark * 2.8)
	draw_colored_polygon(pts, Color(P.PAPER, 0.07))


func _draw_gameover(f: Font) -> void:
	var pts := Art.heart_points(10.0)
	if mode_t < 0.7:
		Art.draw_heart(self, soul, 10.0, P.UI_SIGNAL)
	elif mode_t < 1.6:
		var spread := (mode_t - 0.7) * 25.0
		var right := PackedVector2Array()
		var left := PackedVector2Array()
		for p in pts:
			if p.x >= 0.0:
				right.append(p + soul + Vector2(spread, 0))
			else:
				left.append(p + soul - Vector2(spread, 0))
		if right.size() >= 3:
			draw_colored_polygon(right, P.UI_SIGNAL)
		if left.size() >= 3:
			draw_colored_polygon(left, P.UI_SIGNAL)
	var a := clampf((mode_t - 1.2) / 0.8, 0.0, 1.0)
	draw_string(f, Vector2(0, 180), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, 640, 60, Color(P.UI_INK, a))
	if mode_t > 1.8:
		draw_string(f, Vector2(0, 280), "* 포기하지 마...", HORIZONTAL_ALIGNMENT_CENTER, 640, Game.FL, P.UI_INK)
		draw_string(f, Vector2(0, 316), "* 아직 증명은 끝나지 않았어!", HORIZONTAL_ALIGNMENT_CENTER, 640, Game.FL, P.UI_INK)
		draw_string(f, Vector2(0, 410), "Z: 다시 도전", HORIZONTAL_ALIGNMENT_CENTER, 640, Game.FS, P.UI_MUTED)
