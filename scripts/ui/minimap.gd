extends Node2D
## 미니맵 (오른쪽 위) + 큰 지도 (M 또는 Tab).
## 학교 평면은 5층 시설 안내도의 모양이다 (data/section.gd, tools/world.py 가 만든다):
##   아래쪽 긴 가로 복도 = S동, 서쪽 끝에서 비스듬히 내려가는 곳 = 수학 구역,
##   동쪽 네모 = 중앙 홀(가운데 세모가 아트리움), 중앙 홀에서 왼쪽 위로 뻗는 사선 = A동.
## 복도에서는 걷는 위치가 그대로 화살표가 되고(바라보는 방향), 교실 안에서는 그 교실 문 자리에 표시된다 ("where" 의 pos).
## 문 표시: 회색 = 잠긴 교실, 흰색 = 들어갈 수 있는 곳, 금색으로 깜빡임 = 불이 새는 곳(이야기 목적지), 화살표 = 계단.
## 옥상·기숙사·운동장은 평면 대신 왼쪽 층 버튼으로 보여 준다.
const P = preload("res://scripts/art/palette.gd")
const Section = preload("res://data/section.gd")
const Rooms = preload("res://data/rooms.gd")

var main: Node
var t := 0.0
var big := false            # 큰 지도가 열려 있나
var big_floor := ""         # 큰 지도에서 보고 있는 층
var open_frame := 0
var _cache := {}            # 층 id -> 문 목록
var _auto_done := false

const PANEL := Rect2(482, 6, 152, 118)
const MINI_AREA := Rect2(508, 24, 122, 80)     # 평면을 그리는 칸
const BIG_PANEL := Rect2(36, 30, 568, 420)
const BIG_AREA := Rect2(52, 84, 500, 330)

const COL_FLOOR := Color("dfe6ee")
const COL_FLOOR_DIM := Color("5a6a88")
const COL_EDGE := Color("8ea0bc")
const COL_TRI := Color("f2c434")
const COL_GOLD := Color("ffd45a")


func _ready() -> void:
	if not InputMap.has_action("map"):
		InputMap.add_action("map")
		for k in [KEY_M, KEY_TAB]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event("map", ev)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if big:
		if Engine.get_process_frames() == open_frame:
			return
		if Input.is_action_just_pressed("map") or Input.is_action_just_pressed("cancel"):
			big = false
			Snd.play("select")
		elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_right"):
			_step_floor(1)
		elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_left"):
			_step_floor(-1)
		return
	var want: bool = Input.is_action_just_pressed("map")
	if not _auto_done and t > 1.0 and OS.get_cmdline_user_args().has("bigmap"):
		_auto_done = true      # 실행 인자 `bigmap`: 큰 지도가 열린 채 시작 (화면 확인용)
		want = true
	if _visible_now() and want and not main.is_busy() \
			and not main.dialogue.active and not main.menu.open and not main.dev_menu.open:
		big = true
		open_frame = Engine.get_process_frames()
		var fl: String = _where().get("floor", "?")
		big_floor = fl if fl.ends_with("F") else "1F"
		Snd.play("select")


func _step_floor(d: int) -> void:
	var n := int(big_floor[0]) + d
	if n >= 1 and n <= Section.FLOORS.size():
		big_floor = "%dF" % n
		Snd.play("move")


func _visible_now() -> bool:
	if main == null or main.world == null or main.title != null or main.battle_node != null:
		return false
	return main.world.visible


func _where() -> Dictionary:
	return main.world.data.get("where", {}) if main.world else {}


# ---------------------------------------------------------------- 좌표
func _fit(area: Rect2) -> Array:
	var pl: Dictionary = Section.PLAN
	var s := minf(area.size.x / float(pl["w"] - 6), area.size.y / float(pl["h"] - 4))
	var off := area.position + (area.size - Vector2(pl["w"], pl["h"]) * s) / 2.0
	return [s, off]


func _map(tile: Vector2, fit: Array) -> Vector2:
	return fit[1] + tile * fit[0]


func _hall_of(fl: String) -> String:
	for f in Section.FLOORS:
		if f["id"] == fl:
			return f["hall"]
	return ""


## 그 층 복도의 문들: [{pos, label, kind}] kind = locked / open / stairs / glow
func _doors(fl: String) -> Array:
	if _cache.has(fl):
		return _cache[fl]
	var out := []
	var hid := _hall_of(fl)
	if hid != "":
		var d: Dictionary = Rooms.get_room(hid)
		var mp: Array = d["map"]
		var seen := {}
		for y in mp.size():
			var row: String = mp[y]
			for x in row.length():
				var c := row[x]
				if d["doors"].has(c) and not seen.has(c):
					seen[c] = true
					var dd: Dictionary = d["doors"][c]
					var run := 1
					while x + run < row.length() and row[x + run] == c:
						run += 1
					var kind := "open"
					if dd.get("style", "") == "stairs":
						kind = "stairs"
					elif dd.get("locked", false):
						kind = "locked"
					elif dd.has("glow"):
						kind = "glow"
					var below_floor: bool = y + 1 < mp.size() and String(mp[y + 1])[x] in ".an"
					out.append({"pos": Vector2(x + run / 2.0, y + (1.1 if below_floor else -0.1)), "label": dd.get("label", ""), "kind": kind,
						"need": dd.get("need_flag", ""), "up": c in "UR", "north": below_floor})
	_cache[fl] = out
	return out


# ---------------------------------------------------------------- 그리기
func _draw() -> void:
	if not _visible_now():
		big = false
		return
	if big:
		_draw_big()
		return
	var sp: Vector2 = main.world.player.get_global_transform_with_canvas().origin if main.world.player else Vector2.ZERO
	modulate.a = 0.35 if PANEL.grow(26).has_point(sp) else 1.0
	var wd := _where()
	var fl_id: String = wd.get("floor", "?")
	_panel(PANEL)
	_floor_buttons(Rect2(PANEL.position + Vector2(5, 6), Vector2(18, PANEL.size.y - 12)), fl_id)
	var on_plan := fl_id.ends_with("F")
	var fit := _fit(MINI_AREA)
	_draw_plan(fit, on_plan, fl_id, false)
	_draw_me(fit, wd, fl_id, 1.0)
	# 아래 이름표
	var f: Font = Game.font
	var cap := Rect2(PANEL.position.x + 26, PANEL.end.y - 17, PANEL.size.x - 30, 13)
	draw_rect(cap, Color(P.NIGHT_950, 0.55))
	draw_string(f, cap.position + Vector2(4, 11), _where_text(fl_id, _tile(wd), wd.get("hall", false)), HORIZONTAL_ALIGNMENT_LEFT, cap.size.x - 6, Game.FS, P.UI_INK)
	draw_string(f, Vector2(PANEL.end.x - 30, PANEL.position.y + 15), "M", HORIZONTAL_ALIGNMENT_RIGHT, 24, Game.FS, Color(P.UI_MUTED, 0.6))


func _panel(r: Rect2) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(P.UI_BG, 0.96 if big else 0.88)
	sb.border_color = Color(P.UI_LINE, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 4
	draw_style_box(sb, r)
	# 안쪽 윗줄 빛
	draw_line(r.position + Vector2(6, 3), Vector2(r.end.x - 6, r.position.y + 3), Color(1, 1, 1, 0.08), 1)


## 엘리베이터 버튼처럼 세로로: 옥 5 4 3 2 1, 아래에 기숙사·바깥
func _floor_buttons(area: Rect2, fl_id: String) -> void:
	var f: Font = Game.font
	var items := ["R", "5F", "4F", "3F", "2F", "1F"]
	var names := {"R": "옥", "DORM": "기", "OUT": "밖"}
	var hgt := area.size.y / items.size()
	for i in items.size():
		var id: String = items[i]
		var r := Rect2(area.position.x, area.position.y + i * hgt + 1, area.size.x, hgt - 2)
		var me := id == fl_id
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(3)
		sb.bg_color = Color(P.UI_ACCENT, 0.92) if me else Color(P.UI_PANEL, 0.9)
		sb.border_color = Color(P.UI_ACCENT, 1.0) if me else Color(P.UI_LINE, 0.5)
		sb.set_border_width_all(1)
		draw_style_box(sb, r)
		var label: String = names.get(id, id.substr(0, 1))
		draw_string(f, Vector2(r.position.x, r.position.y + r.size.y / 2.0 + 5), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, Game.FS, P.UI_BG if me else P.UI_MUTED)
		if me:
			var blink := 0.5 + 0.5 * sin(t * 5.0)
			draw_circle(Vector2(r.end.x + 3, r.position.y + r.size.y / 2.0), 1.6, Color(P.UI_SIGNAL, blink))


## 학교 평면: 복도는 밝은 면 + 테두리, A동·수학 구역은 사선 띠, 중앙 홀 가운데 세모
func _draw_plan(fit: Array, active: bool, fl_id: String, labels: bool) -> void:
	var pl: Dictionary = Section.PLAN
	var s: float = fit[0]
	var fill := COL_FLOOR if active else COL_FLOOR_DIM
	var edge := COL_EDGE if active else Color(COL_FLOOR_DIM, 0.6)
	var shapes := []
	for rc in pl["rects"]:
		var a := _map(Vector2(rc[0], rc[1]), fit)
		var b := _map(Vector2(rc[0] + rc[2], rc[1] + rc[3]), fit)
		shapes.append(PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]))
	for key in ["a_wing", "m_wing"]:
		var ln: Array = pl[key]
		var p0 := Vector2(ln[0][0], ln[0][1] + 0.5)
		var p1 := Vector2(ln[1][0] + 1, ln[1][1] + 0.5)
		shapes.append(PackedVector2Array([_map(p0 + Vector2(0, -1.5), fit), _map(p1 + Vector2(0, -1.5), fit),
			_map(p1 + Vector2(0, 1.5), fit), _map(p0 + Vector2(0, 1.5), fit)]))
	# 그림자 → 테두리 → 면 (테두리가 겹친 곳에서 끊기지 않게)
	for sh in shapes:
		var so := PackedVector2Array()
		for q in sh:
			so.append(q + Vector2(1.5, 2))
		draw_colored_polygon(so, Color(0, 0, 0, 0.35))
	for sh in shapes:
		var big_sh := _grow(sh, 1.2)
		draw_colored_polygon(big_sh, edge)
	for sh in shapes:
		draw_colored_polygon(sh, fill)
	# 아트리움 세모
	var tri := PackedVector2Array()
	for q in pl["tri"]:
		tri.append(_map(Vector2(q[0], q[1]) + Vector2(0.5, 0.5), fit))
	draw_colored_polygon(tri, Color(P.NIGHT_900, 0.9) if active else Color(P.NIGHT_900, 0.5))
	draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color(COL_TRI, 0.95 if active else 0.4), 1.2 if not labels else 2.0)
	if not active:
		return
	# 문
	var f: Font = Game.font
	var placed: Array = []
	for d in _doors(fl_id):
		var q := _map(d["pos"], fit)
		match d["kind"]:
			"stairs":
				var up: bool = d["up"]
				var tip := q + Vector2(0, -3.5 if up else 3.5) * (2.0 if labels else 1.0)
				var bl := q + Vector2(-2.5, 1.5 if up else -1.5) * (2.0 if labels else 1.0)
				var br := q + Vector2(2.5, 1.5 if up else -1.5) * (2.0 if labels else 1.0)
				draw_colored_polygon(PackedVector2Array([tip, br, bl]), Color("7fd0ff"))
			"locked":
				draw_rect(Rect2(q - Vector2(1, 1) * (1.5 if labels else 0.8), Vector2(2, 2) * (1.5 if labels else 0.8)), Color(P.UI_LINE, 0.95))
			"glow":
				var g := 0.5 + 0.5 * sin(t * 5.0)
				draw_circle(q, (4.5 if labels else 2.6) + g, Color(COL_GOLD, 0.25 + 0.2 * g))
				draw_circle(q, 2.4 if labels else 1.4, COL_GOLD)
			_:
				var ok: bool = d["need"] == "" or Game.flag(d["need"]) or (Game.dev and Game.dev_open)
				draw_circle(q, 2.4 if labels else 1.3, P.PAPER if ok else Color(P.UI_SIGNAL, 0.9))
		if labels and d["kind"] in ["open", "glow"] and d["label"] != "":
			var tw := f.get_string_size(d["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x
			var lp := q + Vector2(-tw / 2.0, -7 if d["north"] else 19)
			var lr := Rect2(lp + Vector2(-3, -11), Vector2(tw + 6, 14))
			var hit := false
			for o in placed:
				if o.intersects(lr):
					hit = true
			if hit:
				lp = q + Vector2(-tw / 2.0, 19 if d["north"] else -7)
				lr = Rect2(lp + Vector2(-3, -11), Vector2(tw + 6, 14))
				hit = false
				for o in placed:
					if o.intersects(lr):
						hit = true
			if not hit:
				placed.append(lr)
				draw_rect(lr, Color(P.UI_BG, 0.85))
				draw_string(f, lp, d["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, COL_GOLD if d["kind"] == "glow" else P.UI_INK)
	if labels:
		for lb in pl["labels"]:
			draw_string(f, _map(Vector2(lb[1], lb[2]), fit), lb[0], HORIZONTAL_ALIGNMENT_CENTER, 60, Game.FL, Color(P.UI_MUTED, 0.5))


func _grow(poly: PackedVector2Array, k: float) -> PackedVector2Array:
	var c := Vector2.ZERO
	for q in poly:
		c += q
	c /= poly.size()
	var out := PackedVector2Array()
	for q in poly:
		var dv := q - c
		out.append(q + dv.normalized() * k * 1.42)
	return out


func _tile(wd: Dictionary) -> Vector2:
	if wd.get("hall", false) and main.world.player:
		return main.world.player.position / 32.0
	if wd.has("pos"):
		return Vector2(wd["pos"][0] + 0.5, wd["pos"][1] + 0.5)
	return Vector2(-1, -1)


## 지금 위치: 바라보는 방향의 화살표 + 퍼지는 고리
func _draw_me(fit: Array, wd: Dictionary, fl_id: String, scale_k: float) -> void:
	var tile := _tile(wd)
	var dot := Vector2(-1, -1)
	if fl_id.ends_with("F") and tile.x >= 0:
		dot = _map(tile, fit)
	elif fl_id == "R":
		dot = _map(Vector2(82, 31), fit)
	elif fl_id == "DORM":
		dot = _map(Vector2(30, 4), fit)
	elif fl_id == "OUT":
		dot = _map(Vector2(89, 51), fit)
	if dot.x < 0:
		return
	var ph := fmod(t, 1.4) / 1.4
	draw_arc(dot, (3.0 + ph * 7.0) * scale_k, 0, TAU, 20, Color(P.UI_SIGNAL, 0.8 * (1.0 - ph)), 1.5)
	var dirs := [Vector2(0, 1), Vector2(0, -1), Vector2(-1, 0), Vector2(1, 0)]
	var face: int = main.world.player.facing if (wd.get("hall", false) and main.world.player) else 1
	var dv: Vector2 = dirs[face]
	var k := 4.2 * scale_k
	var tip := dot + dv * k
	var l := dot - dv * k * 0.6 + dv.orthogonal() * k * 0.75
	var r := dot - dv * k * 0.6 - dv.orthogonal() * k * 0.75
	var back := dot - dv * k * 0.25
	draw_colored_polygon(PackedVector2Array([tip + dv, l + (l - dot).normalized(), back - dv, r + (r - dot).normalized()]), P.NIGHT_950)
	draw_colored_polygon(PackedVector2Array([tip, l, back, r]), P.UI_SIGNAL)
	draw_colored_polygon(PackedVector2Array([tip, l, back]), Color("ff8a9a"))


func _draw_big() -> void:
	var f: Font = Game.font
	draw_rect(Rect2(0, 0, 640, 480), Color(P.NIGHT_950, 0.72))
	_panel(BIG_PANEL)
	var wd := _where()
	var here: String = wd.get("floor", "?")
	var title := "본관 %s층 안내도" % big_floor[0]
	draw_string(f, BIG_PANEL.position + Vector2(18, 32), title, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, P.UI_ACCENT)
	var sub := "지금: " + _where_text(here, _tile(wd), wd.get("hall", false))
	draw_string(f, BIG_PANEL.position + Vector2(18, 50), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_MUTED)
	_floor_buttons(Rect2(BIG_PANEL.end.x - 36, BIG_PANEL.position.y + 70, 22, 220), big_floor)
	var fit := _fit(BIG_AREA)
	_draw_plan(fit, true, big_floor, true)
	if big_floor == here:
		_draw_me(fit, wd, here, 2.0)
	# 범례
	var ly := BIG_PANEL.end.y - 16
	var lx := BIG_PANEL.position.x + 18
	for item in [["glow", "불이 새는 곳"], ["open", "들어갈 수 있음"], ["locked", "잠김"], ["stairs", "계단"]]:
		var c: Color = {"glow": COL_GOLD, "open": P.PAPER, "locked": P.UI_LINE, "stairs": Color("7fd0ff")}[item[0]]
		draw_circle(Vector2(lx + 4, ly - 4), 3.5, c)
		draw_string(f, Vector2(lx + 12, ly), item[1], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_INK)
		lx += 18 + f.get_string_size(item[1], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x + 14
	draw_string(f, Vector2(BIG_PANEL.end.x - 220, ly), "↑↓ 다른 층   M 닫기", HORIZONTAL_ALIGNMENT_RIGHT, 200, Game.FS, P.UI_MUTED)


func _where_text(fl_id: String, tile: Vector2, hall: bool) -> String:
	match fl_id:
		"R":
			return "옥상 · 천문대"
		"DORM":
			return "기숙사"
		"OUT":
			return "운동장 · 바깥"
		"?":
			return ""
	var part := "S동"
	if tile.x >= 74 and tile.y <= 46:
		part = "중앙 홀"
	elif tile.y < 45:
		part = "A동"
	elif tile.x < 27 and tile.y > 48:
		part = "수학 구역"
	if not hall and main.world:
		var nm: String = main.world.data.get("name", "")
		var short := nm.split(" - ")[0]
		return "%s %s · %s" % [fl_id, part, short.get_slice(" ", short.get_slice_count(" ") - 1)]
	return "%s %s" % [fl_id, part]
