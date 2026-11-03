extends Node2D
## 필드에 서 있는 인물/물체. info 는 방 데이터의 "actors" 항목이다.

const Art = preload("res://scripts/art/art.gd")

var info: Dictionary
var ow
var t := 0.0
var dir := Vector2.RIGHT     # 순찰: 지금 보고 있는 방향
var _leg := 0                # 순찰: 0 = 가는 중, 1 = 돌아오는 중
var _pause := 0.0
var _home := Vector2.ZERO
var _started := false


func is_solid() -> bool:
	return info.get("solid", true)


func get_rect() -> Rect2:
	var hw: float = info.get("half_width", 12.0)
	return Rect2(position.x - hw, position.y - 10, hw * 2, 12)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if info.has("patrol"):
		_patrol(delta)


## "patrol": {"to": [x, y], "speed": 70, "vision": 120, "caught": "이벤트 이름"}
## 제자리(pos)와 to 사이를 왕복하면서 앞을 본다.
func _patrol(delta: float) -> void:
	if not _started:
		_started = true
		_home = position
		var first: Array = info["patrol"]["to"]
		dir = (ow.feet_of(first[0], first[1]) - _home).normalized()
	if ow == null or not ow.can_move():
		return
	if _pause > 0.0:
		_pause -= delta
		return
	var to_arr: Array = info["patrol"]["to"]
	var target: Vector2 = ow.feet_of(to_arr[0], to_arr[1]) if _leg == 0 else _home
	var step: float = info["patrol"].get("speed", 70.0) * delta
	var d: Vector2 = target - position
	if d.length() <= step:
		position = target
		_leg = 1 - _leg
		_pause = 0.7
		var nxt: Vector2 = ow.feet_of(to_arr[0], to_arr[1]) if _leg == 0 else _home
		dir = (nxt - position).normalized()
	else:
		dir = d.normalized()
		position += dir * step


func _draw() -> void:
	Art.draw_look(self, info.get("look", ""), t, info)
