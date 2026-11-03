extends Node2D
## 오른쪽 위 미니맵: 학교 평면(5층 시설 안내도의 모양)에 지금 있는 층과 위치를 점으로 보여 준다.
##   아래쪽 긴 가로 복도 = S동, 서쪽 끝에서 비스듬히 내려가는 곳 = 수학 강의실 구역,
##   동쪽 세모 = 중앙 홀(아트리움), 중앙 홀에서 왼쪽 위로 뻗는 사선 = A동.
## 복도에서는 걷는 위치가 그대로 점이 되고, 교실 안에서는 그 교실 문 자리에 점이 찍힌다 ("where" 의 pos).
## 옥상·기숙사·운동장은 평면 대신 이름과 작은 그림으로 보여 준다.
const P = preload("res://scripts/art/palette.gd")
const Section = preload("res://data/section.gd")

var main: Node
var t := 0.0

const PANEL := Rect2(504, 6, 130, 100)
const MAP_AREA := Rect2(510, 22, 118, 64)   # 평면을 그리는 칸 (패널 안)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _visible_now() -> bool:
	if main == null or main.world == null or main.title != null or main.battle_node != null:
		return false
	if not main.world.visible:
		return false
	return true


func _scale() -> float:
	var pl: Dictionary = Section.PLAN
	return minf(MAP_AREA.size.x / float(pl["w"] - 2), MAP_AREA.size.y / float(pl["h"] - 2))


## 복도 맵의 칸 좌표 -> 미니맵 화면 좌표
func _to_mini(tile: Vector2) -> Vector2:
	var s := _scale()
	var pl: Dictionary = Section.PLAN
	var off := MAP_AREA.position + (MAP_AREA.size - Vector2(pl["w"], pl["h"]) * s) / 2.0
	return off + tile * s


func _draw() -> void:
	if not _visible_now():
		return
	var sp: Vector2 = main.world.player.get_global_transform_with_canvas().origin if main.world.player else Vector2.ZERO
	modulate.a = 0.3 if PANEL.grow(24).has_point(sp) else 1.0
	var f: Font = Game.font
	var wd: Dictionary = main.world.data.get("where", {})
	var fl_id: String = wd.get("floor", "?")
	draw_rect(PANEL, Color(P.NIGHT_950, 0.75))
	draw_rect(PANEL, Color(P.UI_LINE, 0.6), false, 1.0)
	var tile := Vector2(-1, -1)
	if wd.get("hall", false) and main.world.player:
		tile = main.world.player.position / 32.0
	elif wd.has("pos"):
		tile = Vector2(wd["pos"][0] + 0.5, wd["pos"][1] + 0.5)
	var on_plan := fl_id.ends_with("F")
	_draw_plan(on_plan)
	# 층 표시 (1F~5F 다섯 칸, 지금 층이 노랗게)
	for i in Section.FLOORS.size():
		var id: String = Section.FLOORS[i]["id"]
		var r := Rect2(PANEL.position.x + 4 + i * 15, PANEL.position.y + 3, 14, 14)
		var me := id == fl_id
		draw_rect(r, Color(P.UI_ACCENT, 0.85) if me else Color(P.UI_LINE, 0.35))
		draw_string(f, r.position + Vector2(1, 12), id[0], HORIZONTAL_ALIGNMENT_CENTER, 12, Game.FS, P.UI_BG if me else P.UI_MUTED)
	# 옥상 · 기숙사 · 바깥 표시
	var extra := {"R": "옥상", "DORM": "기숙사", "OUT": "바깥"}
	var ex_x := PANEL.position.x + 82
	for k in ["R", "DORM", "OUT"]:
		var me2: bool = fl_id == k
		var w2 := 14.0 if k == "R" else 14.0
		var r2 := Rect2(ex_x, PANEL.position.y + 3, w2, 14)
		draw_rect(r2, Color(P.UI_ACCENT, 0.85) if me2 else Color(P.UI_LINE, 0.35))
		draw_string(f, r2.position + Vector2(1, 12), extra[k].substr(0, 1), HORIZONTAL_ALIGNMENT_CENTER, 12, Game.FS, P.UI_BG if me2 else P.UI_MUTED)
		ex_x += 15
	# 현재 위치 점
	var blink := 0.6 + 0.4 * sin(t * 6.0)
	var dot := Vector2.ZERO
	if on_plan and tile.x >= 0:
		dot = _to_mini(tile)
	elif fl_id == "R":
		dot = _to_mini(Vector2(82, 31))       # 중앙 홀 위 옥상 계단 자리
	elif fl_id == "DORM":
		dot = _to_mini(Vector2(30, 4))        # A동 끝의 기숙사 연결 데크 너머
	elif fl_id == "OUT":
		dot = _to_mini(Vector2(89, 52))       # 정문 현관 바깥
	if dot != Vector2.ZERO:
		draw_circle(dot, 3.5, Color(P.UI_SIGNAL, blink))
		draw_circle(dot, 1.5, P.UI_INK)
	draw_string(f, Vector2(PANEL.position.x + 4, PANEL.end.y - 3), _where_text(fl_id, tile, wd.get("hall", false)), HORIZONTAL_ALIGNMENT_LEFT, PANEL.size.x - 8, Game.FS, P.UI_INK)


func _draw_plan(active: bool) -> void:
	var pl: Dictionary = Section.PLAN
	var s := _scale()
	var c := Color(P.WALL_100, 0.85) if active else Color(P.UI_LINE, 0.5)
	for rc in pl["rects"]:
		var a := _to_mini(Vector2(rc[0], rc[1]))
		draw_rect(Rect2(a, Vector2(rc[2], rc[3]) * s), c)
	for key in ["a_wing", "m_wing"]:
		var ln: Array = pl[key]
		draw_line(_to_mini(Vector2(ln[0][0], ln[0][1])), _to_mini(Vector2(ln[1][0], ln[1][1])), c, 3.0 * s + 0.5)
	var tri := PackedVector2Array()
	for p in pl["tri"]:
		tri.append(_to_mini(Vector2(p[0], p[1])))
	draw_colored_polygon(tri, Color(P.PILLAR_500, 0.75) if active else Color(P.UI_LINE, 0.3))


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
	return "%s %s%s" % [fl_id, part, "" if hall else " (안)"]
