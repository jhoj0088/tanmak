extends Node2D
## 필드에서 조작하는 주인공. position = 발 위치.

const Art = preload("res://scripts/art/art.gd")
const SPEED := 120.0

var ow
var facing := 0      # 0 아래, 1 위, 2 왼쪽, 3 오른쪽
var moving := false
var anim := 0.0
var last_safe := Vector2.ZERO


func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if ow.can_move():
		dir = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	moving = dir != Vector2.ZERO
	if moving:
		if absf(dir.x) > absf(dir.y):
			facing = 2 if dir.x < 0 else 3
		else:
			facing = 1 if dir.y < 0 else 0
		var v := dir.normalized() * SPEED * delta * (2.5 if Game.dev_fast else 1.0)
		# 가로/세로를 따로 움직여서 벽에 비비며 미끄러지게
		var np := position + Vector2(v.x, 0)
		if Game.dev_noclip or not ow.rect_blocked(hitbox(np)):
			position = np
		np = position + Vector2(0, v.y)
		if Game.dev_noclip or not ow.rect_blocked(hitbox(np)):
			position = np
		anim += delta * 8.0
		if not ow.check_door(position):
			last_safe = position
		ow.check_triggers(position)
	else:
		anim = 0.0

	if ow.can_move() and ow.cooldown <= 0.0 and Input.is_action_just_pressed("confirm"):
		ow.interact(position, facing)
	queue_redraw()


func hitbox(p: Vector2) -> Rect2:
	return Rect2(p.x - 8, p.y - 8, 16, 8)


func _draw() -> void:
	Art.draw_student(self, facing, int(anim) % 4, moving)
