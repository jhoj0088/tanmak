extends RefCounted
## 2챕터 공통: 시약 플라스크. 포물선으로 날아와서 터지며 제멋대로 갈라진다.
## 적 스크립트에서  Flask.toss(b, 색)  으로 던진다.


static func toss(b, col: Color, pieces := 7, speed := 105.0) -> void:
	var box: Rect2 = b.box
	var from_left := randf() < 0.5
	var start := Vector2(box.position.x - 20 if from_left else box.end.x + 20, box.position.y - 10)
	var vx := randf_range(60.0, 150.0) * (1.0 if from_left else -1.0)
	var bl = b.add(start, Vector2(vx, randf_range(-150.0, -90.0)), 9, col, 4)
	bl.gravity = 260.0
	bl.data["pop_y"] = randf_range(box.position.y + 40.0, box.end.y - 30.0)
	bl.fn = func(q, _d):
		if q.vel.y > 0.0 and q.pos.y >= q.data["pop_y"]:
			b.burst(q, pieces, speed, 4.5, col, 0.7)
			Snd.play("warn")
