extends Node2D
## 주인공보다 위에 그려지는 층 (나무 잎, 떠다니는 기호)

var ow


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	ow.draw_overhead(self)
