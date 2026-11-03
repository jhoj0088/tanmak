extends Node2D
## 필드. 방 데이터(data/rooms_*.gd)를 읽어서 그리고, 충돌/문/조사/이벤트 발동을 처리한다.

const TILE := 32
const Rooms = preload("res://data/rooms.gd")
const Tiles = preload("res://scripts/world/tiles.gd")
const P = preload("res://scripts/art/palette.gd")
const PlayerScript = preload("res://scripts/world/player.gd")
const ActorScript = preload("res://scripts/world/actor.gd")
const OverheadScript = preload("res://scripts/world/overhead.gd")

var main: Node
var room_id := ""
var spawn_name := ""
var spawn_pos = null        # Vector2 가 들어오면 spawn_name 대신 이 위치에 등장 (세이브 불러오기)
var spawn_facing := 0

var data: Dictionary
var grid: Array = []
var w := 0
var h := 0
var theme := "school"
var floor_style := "terrazzo"
var doors: Dictionary = {}
var player: Node2D
var entities: Node2D
var actors: Array = []
var cam: Camera2D
var cooldown := 0.0
var t := 0.0
var inside := {}


func _ready() -> void:
	data = Rooms.get_room(room_id)
	grid = data["map"]
	h = grid.size()
	w = grid[0].length()
	for row in grid:
		if row.length() != w:
			push_error("[%s] 맵의 줄 길이가 서로 다릅니다: %s" % [room_id, row])
	theme = data.get("theme", "school")
	floor_style = data.get("floor", "terrazzo")
	doors = data.get("doors", {})

	entities = Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)

	player = PlayerScript.new()
	player.ow = self
	if spawn_pos != null:
		player.position = spawn_pos
		player.facing = spawn_facing
	else:
		var spawns: Dictionary = data.get("spawns", {})
		var s: Array = spawns.get(spawn_name, spawns.values()[0])
		player.position = feet_of(s[0], s[1])
		player.facing = s[2] if s.size() > 2 else 0
	player.last_safe = player.position
	entities.add_child(player)

	refresh_actors()

	var oh := OverheadScript.new()
	oh.ow = self
	oh.z_index = 10
	add_child(oh)

	# 카메라: 방이 화면보다 작으면 가운데 정렬
	cam = Camera2D.new()
	player.add_child(cam)
	var room_px := Vector2(w, h) * TILE
	var view := Vector2(640, 480)
	var pad := ((view - room_px) / 2.0).max(Vector2.ZERO)
	cam.limit_left = int(-pad.x)
	cam.limit_right = int(room_px.x + pad.x)
	cam.limit_top = int(-pad.y)
	cam.limit_bottom = int(room_px.y + pad.y)
	cam.make_current()


## 플래그가 바뀐 뒤 부르면, 조건(if_flag / unless_flag)에 맞게 인물을 다시 배치한다.
func refresh_actors() -> void:
	for a in actors:
		a.queue_free()
	actors.clear()
	for n in data.get("actors", []):
		if not _cond(n):
			continue
		var a = ActorScript.new()
		a.info = n
		a.ow = self
		a.position = feet_of(n["pos"][0], n["pos"][1])
		entities.add_child(a)
		actors.append(a)


func _cond(d: Dictionary) -> bool:
	if d.has("chapter"):
		var ch: Array = d["chapter"]
		if Game.chapter < ch[0] or Game.chapter > ch[1]:
			return false
	if d.has("if_flag") and not Game.flag(d["if_flag"]):
		return false
	if d.has("unless_flag") and Game.flag(d["unless_flag"]):
		return false
	return true


func _process(delta: float) -> void:
	t += delta
	cooldown = maxf(0.0, cooldown - delta)
	_check_patrols()
	queue_redraw()


# ---------------------------------------------------------------- 좌표/충돌
func feet_of(tx: float, ty: float) -> Vector2:
	return Vector2(tx * TILE + TILE / 2.0, ty * TILE + 26)


func tile_at(tx: int, ty: int) -> String:
	if tx < 0 or ty < 0 or tx >= w or ty >= h:
		return "#"
	return grid[ty][tx]


func tile_at_point(p: Vector2) -> String:
	return tile_at(int(floor(p.x / TILE)), int(floor(p.y / TILE)))


func door_blocked(d: Dictionary) -> bool:
	if d.get("locked", false):
		return true
	return d.has("need_flag") and not Game.flag(d["need_flag"])


func is_solid_char(c: String) -> bool:
	if doors.has(c):
		return door_blocked(doors[c])
	return Tiles.is_solid(theme, c)


func rect_blocked(r: Rect2) -> bool:
	var x0 := int(floor(r.position.x / TILE))
	var x1 := int(floor((r.end.x - 0.01) / TILE))
	var y0 := int(floor(r.position.y / TILE))
	var y1 := int(floor((r.end.y - 0.01) / TILE))
	for ty in range(y0, y1 + 1):
		for tx in range(x0, x1 + 1):
			if is_solid_char(tile_at(tx, ty)):
				return true
	for a in actors:
		if a.is_solid() and a.get_rect().intersects(r):
			return true
	return false


func can_move() -> bool:
	return not main.is_busy() and not main.dialogue.active and not main.menu.open and not main.dev_menu.open


# ---------------------------------------------------------------- 문 / 발동 구역
## 문 타일을 밟았으면 true
func check_door(feet: Vector2) -> bool:
	var c := tile_at_point(feet - Vector2(0, 4))
	if not doors.has(c):
		return false
	var d: Dictionary = doors[c]
	if d.has("event"):
		player.position = player.last_safe
		main.run_event(d["event"], d)
	else:
		Snd.play("door")
		main.goto_room(d["to"], d["spawn"])
	return true


func check_triggers(feet: Vector2) -> void:
	var list: Array = data.get("triggers", [])
	for i in list.size():
		var tr: Dictionary = list[i]
		var rc: Array = tr["rect"]
		var r := Rect2(rc[0] * TILE, rc[1] * TILE, rc[2] * TILE, rc[3] * TILE)
		var now_in := r.has_point(feet - Vector2(0, 4))
		var was_in: bool = inside.get(i, false)
		inside[i] = now_in
		if not now_in or was_in or not _cond(tr):
			continue
		if tr.has("once"):
			if Game.flag(tr["once"]):
				continue
			Game.set_flag(tr["once"])
		main.run_event(tr["event"], tr)
		return


# ---------------------------------------------------------------- 조사 (Z)
func interact(feet: Vector2, facing: int) -> void:
	var dirs := [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
	# 가까운 곳부터 차례로 더듬어 본다 (위쪽은 발 기준이라 조금 더 멀리)
	var reaches := [12.0, 22.0, 30.0] if facing == 1 else [12.0, 22.0]
	for reach in reaches:
		var p: Vector2 = feet + dirs[facing] * reach + Vector2(0, -4)
		for a in actors:
			if a.get_rect().grow(6).has_point(p):
				_run_entry(a.info, a.info)
				return
		if _interact_tile(int(floor(p.x / TILE)), int(floor(p.y / TILE))):
			return


func _interact_tile(tx: int, ty: int) -> bool:
	var at: Dictionary = data.get("signs_at", {})
	var key := "%d,%d" % [tx, ty]
	if at.has(key):
		_run_entry(at[key], at[key] if at[key] is Dictionary else null)
		return true
	var c := tile_at(tx, ty)
	if c == "*":
		main.run_event("save_point")
		return true
	if doors.has(c):
		var d: Dictionary = doors[c]
		if door_blocked(d) and d.has("text"):
			main.say(d["text"])
			return true
		return false
	var signs: Dictionary = data.get("signs", {})
	if signs.has(c):
		_run_entry(signs[c], signs[c] if signs[c] is Dictionary else null)
		return true
	if theme == "school" and DEFAULT_SIGNS.has(c):
		var lines: Array = DEFAULT_SIGNS[c]
		main.say([lines[(tx * 7 + ty * 3) % lines.size()]] if c in ["N", "="] else lines)
		return true
	return false


## 방마다 따로 적지 않아도 되는 학교 소품의 조사 대사
const DEFAULT_SIGNS := {
	"N": [
		"* 'SASA R&E 중간발표회 - 질문은 발표자를 키웁니다'라는 포스터다.",
		"* '천문 동아리 신입 모집: 600mm 망원경, 직접 만져 볼 수 있음!'",
		"* '융합 축제 부스 신청 마감 D-3.' 누군가 3을 지우고 '-1'로 고쳐 놓았다.",
		"* '창의설계실 3D 프린터 예약표.' 이번 주는 전부 '절규(필라멘트 찾는 중)'으로 차 있다.",
		"* '기숙사 택배 수령 안내: 급식실 앞 택배실. 이름표 확인 필수.'",
		"* '수학 경시 대비반 - 틀린 문제를 가져오세요. 그게 제일 좋은 교재입니다.'",
	],
	"F": ["* 소화기다. 점검표에 매달 같은 서명이 있다. '학교지킴이 - 이상 없음.'"],
	"E": ["* 비상구 유도등이다. 초록색 사람이 영원히 문을 향해 달리고 있다.", "* 이 학교에서 가장 성실한 존재일지도 모른다."],
	"C": ["* CCTV다. 빨간 불이 깜빡인다.", "* ...렌즈 너머에서 코어가 보고 있는 것 같다."],
	"Q": ["* 정수기다. 물을 한 모금 마셨다. 차갑다.", "* 컵 놓는 자리에 누군가의 텀블러가 두고 가져가지 않은 채 남아 있다."],
	"I": ["* 신발장이다. 실내화마다 이름이 매직으로 적혀 있다.", "* 한 칸은 이름 대신 '찾으면 연락 주세요 - 절규'라고 적혀 있다."],
	"i": ["* 아이맥이다. 화면 보호기에 '오늘 할 일: 1. 과제 2. 과제 3. 잠'이 떠 있다."],
	"Z": ["* 레이저 커팅기다. '트로텍'이라고 적힌 기계가 아크릴판에 무언가를 새기고 있다."],
	"j": ["* 화이트보드다. 반쯤 지워진 수식이 남아 있다. 지운 사람도 끝까지 못 푼 모양이다."],
	"=": [
		"* 벽이다. 누군가 연필로 작게 '여기서 졸면 안 됨'이라고 적어 놓았다.",
		"* 벽에 붙은 시간표다. 7교시 다음 칸에 '야자', 그 다음 칸에 '야자', 그 다음 칸에 '잠'.",
		"* 미색 페인트가 군데군데 벗겨져 있다. 개교 이후 몇 번이나 덧칠했을까.",
	],
}


func _run_entry(entry, arg) -> void:
	if entry is Array:
		main.say(entry)
	elif entry is Dictionary:
		if entry.has("event"):
			main.run_event(entry["event"], arg)
		elif entry.has("lines"):
			main.say(entry["lines"])


# ---------------------------------------------------------------- 그리기
## 지금 화면에 보이는 칸 범위 (큰 복도 맵에서 보이는 곳만 그린다)
func _vis() -> Rect2i:
	var center: Vector2 = cam.get_screen_center_position() if cam else Vector2(w, h) * TILE / 2.0
	var half: Vector2 = get_viewport_rect().size / (cam.zoom if cam else Vector2.ONE) / 2.0
	var x0 := clampi(int((center.x - half.x) / TILE) - 3, 0, w)
	var y0 := clampi(int((center.y - half.y) / TILE) - 3, 0, h)
	var x1 := clampi(int((center.x + half.x) / TILE) + 4, 0, w)
	var y1 := clampi(int((center.y + half.y) / TILE) + 4, 0, h)
	return Rect2i(x0, y0, x1 - x0, y1 - y0)


func _draw() -> void:
	var bg_cols := {"forest": Color(0.02, 0.05, 0.05), "bio": Color(0.05, 0.01, 0.06), "optics": Color(0.0, 0.0, 0.02), "server": Color(0.01, 0.02, 0.03)}
	draw_rect(Rect2(-1000, -1000, w * TILE + 2000, h * TILE + 2000), bg_cols.get(theme, P.NIGHT_950))
	if data.get("sky", false):
		_draw_sky()
	var vr := _vis()
	for ty in range(vr.position.y, vr.end.y):
		var row: String = grid[ty]
		for tx in range(vr.position.x, vr.end.x):
			var c := row[tx]
			var r := Rect2(tx * TILE, ty * TILE, TILE, TILE)
			if doors.has(c):
				var d: Dictionary = doors[c]
				if theme == "school":
					Tiles.draw_school_door(self, d, r, tx, ty, floor_style, door_blocked(d), t)
				else:
					Tiles.draw_exit(self, theme, r, tx, ty, t)
			else:
				Tiles.draw(self, theme, c, r, tx, ty, floor_style, t)
	if theme == "school":
		_draw_labels()
	_draw_plates()


## 옥상의 밤하늘 (방 데이터 "sky": true)
func _draw_sky() -> void:
	var r := Rect2(-1000, -1000, w * TILE + 2000, h * TILE + 2000)
	draw_rect(r, P.NIGHT_900)
	for i in 420:
		var x := float((i * 7919) % int(r.size.x)) + r.position.x
		var y := float((i * 104729) % int(r.size.y)) + r.position.y
		var tw := 0.45 + 0.4 * sin(t * (1.0 + float(i % 7) * 0.3) + i)
		var sz := 2.0 if i % 11 == 0 else 1.0
		draw_rect(Rect2(x, y, sz, sz), Color(P.PAPER, tw))
	# 은하수 띠
	for k in 60:
		var cxk := -200.0 + k * 28.0
		draw_circle(Vector2(cxk, -120.0 + k * 9.0), 46, Color(P.SKY_100, 0.025))
	draw_circle(Vector2(w * TILE - 120, -160), 26, P.PAPER)
	draw_circle(Vector2(w * TILE - 110, -166), 23, P.NIGHT_900)


## 방 데이터 "plates": [[x, y, "글자"], ...]  타일 위에 작은 명패 (S동 / A동 구분 등)
func _draw_plates() -> void:
	var f: Font = Game.font
	for pl in data.get("plates", []):
		var label: String = pl[2]
		var tw := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x + 10
		var pr := Rect2(pl[0] * TILE + TILE / 2.0 - tw / 2.0, pl[1] * TILE + 4, tw, 17)
		draw_rect(pr, P.BLUE_500.darkened(0.5))
		draw_rect(pr, P.SKY_100, false, 1)
		draw_string(f, pr.position + Vector2(5, 13), label, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_INK)


func _draw_labels() -> void:
	var f: Font = Game.font
	var seen := {}
	var vr := _vis()
	for ty in range(vr.position.y, vr.end.y):
		var row: String = grid[ty]
		for tx in range(maxi(0, vr.position.x - 4), vr.end.x):
			var c := row[tx]
			if doors.has(c) and doors[c].has("label") and not seen.has(c):
				seen[c] = true
				var label: String = doors[c]["label"]
				var run := 1
				while tx + run < w and row[tx + run] == c:
					run += 1
				var tw := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS).x + 8
				var cx := tx * TILE + run * TILE / 2.0
				var above: bool = doors[c].get("label_below", false) == false
				var py := ty * TILE - 15.0 if above else ty * TILE + TILE + 1.0
				var pr := Rect2(cx - tw / 2.0, py, tw, 15)
				draw_rect(pr, P.PAPER)
				draw_rect(pr, P.INLAY_900, false, 1)
				draw_string(f, pr.position + Vector2(4, 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_INK_DAY)
	# 칠판 글씨
	var board: String = data.get("board_text", "")
	if board != "":
		for ty in h:
			var row2: String = grid[ty]
			var start := row2.find("B")
			if start >= 0:
				var end := row2.rfind("B")
				draw_string(f, Vector2(start * TILE, ty * TILE + 19), board, HORIZONTAL_ALIGNMENT_CENTER, (end - start + 1) * TILE, Game.FS, P.PAPER)


func draw_overhead(ci: CanvasItem) -> void:
	var f: Font = Game.font
	if theme == "forest":
		for ty in h:
			var row: String = grid[ty]
			for tx in w:
				Tiles.draw_forest_overhead(ci, row[tx], Rect2(tx * TILE, ty * TILE, TILE, TILE), tx, ty, t)
	# 공중에 떠다니는 것들
	var syms: Array = {"forest": ["∈", "⊂", "∩", "∪", "∴", "⇒", "∀", "∃"], "bio": ["A", "T", "G", "C", "○", "·"], "server": ["0", "1"]}.get(theme, [])
	for i in (14 if not syms.is_empty() else 0):
		var bx := float((i * 211) % (w * TILE))
		var by := float((i * 137) % (h * TILE))
		var p := Vector2(bx + sin(t * 0.4 + i) * 20.0, fposmod(by - t * (6.0 + i % 4), h * TILE))
		var a := 0.18 + 0.12 * sin(t * 1.5 + i * 2.0)
		ci.draw_string(f, p, syms[i % syms.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, Color(0.7, 1.0, 0.85, a))
	_draw_night(ci)
	_draw_darkness(ci)
	# 순찰의 시야
	for a2 in actors:
		if a2.info.has("patrol"):
			var eye: Vector2 = a2.position + Vector2(0, -12)
			var pts := PackedVector2Array([eye])
			var vis: float = a2.info["patrol"].get("vision", 120.0)
			for i in 9:
				pts.append(eye + a2.dir.rotated(-VISION_HALF + i * VISION_HALF / 4.0) * vis)
			ci.draw_colored_polygon(pts, Color(P.SKY_100, 0.2 + 0.06 * sin(t * 6.0)))


## 밤의 조명: 화면을 푸르스름하게 가라앉히고, 창문의 달빛·비상구·자판기·모니터 불빛을 얹는다.
## 방 데이터 "light": "night"(학교 기본) / "day"(아침) / "none"
func _draw_night(ci: CanvasItem) -> void:
	var mode: String = data.get("light", "night" if theme == "school" else "none")
	if mode == "none" or data.get("dark", 0.0) > 0.0:
		return
	var center: Vector2 = cam.get_screen_center_position()
	var view := Rect2(center - Vector2(330, 250), Vector2(660, 500))
	if mode == "day":
		ci.draw_rect(view, Color(P.PEACH_300, 0.08))
		var vd := _vis()
		for ty in range(vd.position.y, vd.end.y):
			var row: String = grid[ty]
			for tx in range(vd.position.x, vd.end.x):
				if row[tx] == "w":
					var o := Vector2(tx * TILE, ty * TILE + 20)
					ci.draw_colored_polygon(PackedVector2Array([o + Vector2(4, 0), o + Vector2(28, 0), o + Vector2(52, 70), o + Vector2(20, 70)]), Color(P.PILLAR_300.lightened(0.4), 0.13))
		return
	ci.draw_rect(view, Color(P.NIGHT_900, 0.35))
	var x0 := maxi(0, int(view.position.x / TILE) - 2)
	var x1 := mini(w, int(view.end.x / TILE) + 2)
	var vn := _vis()
	for ty in range(vn.position.y, vn.end.y):
		var row2: String = grid[ty]
		for tx in range(x0, x1):
			var c := row2[tx]
			var o2 := Vector2(tx * TILE, ty * TILE)
			match c:
				"w":
					ci.draw_colored_polygon(PackedVector2Array([o2 + Vector2(4, 20), o2 + Vector2(28, 20), o2 + Vector2(44, 84), o2 + Vector2(16, 84)]), Color(P.SKY_100, 0.07))
				"E":
					ci.draw_circle(o2 + Vector2(16, 10), 34, Color(P.BENCH_500.lightened(0.3), 0.06))
					ci.draw_circle(o2 + Vector2(16, 10), 16, Color(P.BENCH_500.lightened(0.3), 0.07))
				"v":
					ci.draw_circle(o2 + Vector2(16, 6), 40, Color(P.PEACH_300, 0.07))
				"c", "i":
					ci.draw_circle(o2 + Vector2(16, 0), 22, Color(P.SKY_100, 0.05))
				"*":
					ci.draw_circle(o2 + Vector2(16, 16), 26 + sin(t * 3.0) * 3.0, Color(P.PILLAR_300, 0.07))
				"Q":
					ci.draw_circle(o2 + Vector2(12, 4), 10, Color(P.BLUE_500, 0.08))
			if doors.has(c) and doors[c].has("glow"):
				var gc: Color = doors[c]["glow"]
				gc.a = 0.08 + 0.04 * sin(t * 3.0)
				ci.draw_circle(o2 + Vector2(16, 30), 30, gc)


## 어두운 방("dark": 반지름): 주인공 주변과 손전등 방향만 보인다
func _draw_darkness(ci: CanvasItem) -> void:
	var radius: float = data.get("dark", 0.0)
	if radius <= 0.0:
		return
	var center: Vector2 = cam.get_screen_center_position()
	var origin := (center - Vector2(320, 240)).snapped(Vector2(16, 16)) - Vector2(16, 16)
	var eye: Vector2 = player.position + Vector2(0, -16)
	var fdir: Vector2 = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT][player.facing]
	for gy in 33:
		for gx in 43:
			var cell := origin + Vector2(gx * 16, gy * 16)
			var d := (cell + Vector2(8, 8)) - eye
			var dist := d.length()
			var reach := radius
			if absf(angle_difference(fdir.angle(), d.angle())) < 0.55:
				reach = radius * 2.6
			var a := clampf((dist - reach) / 48.0, 0.0, 0.93)
			if a > 0.02:
				ci.draw_rect(Rect2(cell, Vector2(16, 16)), Color(P.NIGHT_950, a))


const VISION_HALF := 0.5


## 순찰(patrol)이 주인공을 봤는가
func _check_patrols() -> void:
	if not can_move():
		return
	var c := tile_at_point(player.position - Vector2(0, 4))
	if c == "_":
		return        # 그늘에 숨어 있다
	for a in actors:
		if not a.info.has("patrol"):
			continue
		var eye: Vector2 = a.position + Vector2(0, -12)
		var d: Vector2 = (player.position + Vector2(0, -12)) - eye
		var vis: float = a.info["patrol"].get("vision", 120.0)
		if d.length() < vis and absf(angle_difference(a.dir.angle(), d.angle())) < VISION_HALF:
			main.run_event(a.info["patrol"].get("caught", "caught"), a.info)
			return
