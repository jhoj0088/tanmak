extends Node2D
## 대화창 (타자기 효과) + 선택지 + 화면 왼쪽 위 알림
const P = preload("res://scripts/art/palette.gd")

signal done
signal chosen(index: int)

const SPEED := 38.0    # 초당 글자 수
const BOX_W := 592.0

var main: Node
var active := false
var lines: Array = []
var idx := 0
var shown := 0.0
var text := ""
var open_frame := 0

var choosing := false
var prompt := ""
var options: Array = []
var opt_text: Array = []     # 줄바꿈한 선택지
var opt_size := 24
var opt_lh := 30.0
var sel := 0

var title := ""
var title_t := 0.0
var memory_mode := false      # 기억 장면: 테두리 없이 회색 글씨


func run(l: Array) -> void:
	if l.is_empty():
		return
	# 3줄을 넘는 문장은 여러 쪽으로 나눠서 보여 준다 (창을 넘지 않게)
	lines = []
	for one in l:
		lines.append_array(Game.pages(str(one), BOX_W - 44, Game.FL))
	idx = 0
	_set_line()
	choosing = false
	active = true
	open_frame = Engine.get_process_frames()
	await done


func choose(p: String, opts: Array) -> int:
	prompt = Game.wrap(p, BOX_W - 44, Game.FL)
	options = opts
	# 긴 선택지는 줄을 바꾸고, 그래도 화면에 안 들어가면 작은 글씨로
	opt_size = Game.FL
	opt_lh = 30.0
	opt_text = []
	for o in opts:
		opt_text.append(Game.wrap(str(o), BOX_W - 80, Game.FL))
	var n_lines := prompt.count("\n") + 1
	for o in opt_text:
		n_lines += o.count("\n") + 1
	if 30.0 * n_lines + 30.0 > 448.0:
		opt_size = Game.FS
		opt_lh = 18.0
		for i in opt_text.size():
			opt_text[i] = Game.wrap(str(opts[i]), BOX_W - 80, Game.FS)
	sel = 0
	choosing = true
	active = true
	open_frame = Engine.get_process_frames()
	var i: int = await chosen
	return i


func show_title(s: String) -> void:
	title = s
	title_t = 3.5


func _set_line() -> void:
	text = Game.wrap(str(lines[idx]), BOX_W - 44, Game.FL)
	shown = 0.0
	if text.count("\n") > 2:
		push_warning("대사가 3줄을 넘습니다: " + str(lines[idx]))


func _process(delta: float) -> void:
	title_t = maxf(0.0, title_t - delta)
	queue_redraw()
	if not active or Engine.get_process_frames() == open_frame:
		return
	if choosing:
		if Input.is_action_just_pressed("move_up"):
			sel = (sel - 1 + options.size()) % options.size()
			Snd.play("move")
		elif Input.is_action_just_pressed("move_down"):
			sel = (sel + 1) % options.size()
			Snd.play("move")
		elif Input.is_action_just_pressed("confirm"):
			Snd.play("select")
			active = false
			choosing = false
			_cooldown()
			chosen.emit(sel)
		return
	var before := int(shown)
	shown = minf(shown + delta * SPEED, text.length())
	var now := int(shown)
	if now != before and now % 2 == 0 and now > 0 and text[now - 1] != " ":
		Snd.play("blip")
	if Input.is_action_just_pressed("confirm"):
		if shown < text.length():
			shown = text.length()
		else:
			idx += 1
			if idx >= lines.size():
				active = false
				_cooldown()
				done.emit()
			else:
				_set_line()
	elif Input.is_action_just_pressed("cancel"):
		shown = text.length()


func _cooldown() -> void:
	if main.world:
		main.world.cooldown = 0.2


func _box_y(height: float) -> float:
	# 주인공이 화면 아래쪽에 있으면 대화창을 위로 올린다.
	if main.world and main.world.visible and main.world.player:
		var py: float = main.world.player.get_global_transform_with_canvas().origin.y
		if py > 300.0:
			return 16.0
	return 480.0 - 16.0 - height


func _draw() -> void:
	var f: Font = Game.font
	if title_t > 0.0 and title != "" and not active:
		var a := clampf(title_t, 0.0, 1.0)
		var tw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x
		draw_rect(Rect2(0, 10, tw + 28, 24), Color(P.UI_BG, 0.65 * a))
		draw_string(f, Vector2(14, 27), title, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(P.UI_INK, a))
	if not active:
		return
	if choosing:
		var n_prompt := prompt.count("\n") + 1 if prompt != "" else 0
		var opt_h := 0.0
		for o in opt_text:
			opt_h += opt_lh * (o.count("\n") + 1) + (30.0 - opt_lh)
		var hgt := 30.0 * n_prompt + opt_h + 30.0
		var r := Rect2(24, _box_y(hgt), BOX_W, hgt)
		draw_rect(r, P.UI_BG)
		draw_rect(r, P.UI_INK, false, 4)
		var y := r.position.y + 38.0
		if prompt != "":
			draw_multiline_string(f, Vector2(r.position.x + 22, y), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, -1, P.UI_INK)
			y += 30.0 * n_prompt
		for i in opt_text.size():
			var col := P.UI_ACCENT if i == sel else P.UI_INK
			var y0 := y if opt_size == Game.FL else y - 6.0
			draw_multiline_string(f, Vector2(r.position.x + 58, y0), opt_text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, opt_size, -1, col)
			if i == sel:
				_heart(Vector2(r.position.x + 36, y - 9))
			y += opt_lh * (opt_text[i].count("\n") + 1) + (30.0 - opt_lh)
		return
	if memory_mode:
		var rm := Rect2(24, 180, BOX_W, 134)
		draw_multiline_string(f, rm.position + Vector2(22, 40), text.substr(0, int(shown)), HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, -1, P.UI_MUTED)
		return
	var r2 := Rect2(24, _box_y(134), BOX_W, 134)
	draw_rect(r2, P.UI_BG)
	draw_rect(r2, P.UI_INK, false, 4)
	draw_multiline_string(f, r2.position + Vector2(22, 40), text.substr(0, int(shown)), HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, -1, P.UI_INK)
	if shown >= text.length() and int(Time.get_ticks_msec() / 350) % 2 == 0:
		var c := r2.end - Vector2(22, 16)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -6), c + Vector2(6, -6), c + Vector2(0, 2)]), P.UI_INK)


func _heart(p: Vector2) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var x := 16.0 * pow(sin(a), 3)
		var y := -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))
		pts.append(p + Vector2(x, y - 2.5) * 0.5)
	draw_colored_polygon(pts, P.UI_SIGNAL)
