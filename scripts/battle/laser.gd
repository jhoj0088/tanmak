extends RefCounted
## 레이저(직선 광선). 예고선이 warn 초 동안 깜빡인 뒤 active 초 동안 실제로 쏜다.

var from := Vector2.ZERO
var angle := 0.0
var length := 900.0
var width := 10.0
var warn := 0.6
var active := 0.3
var age := 0.0
var color := Color(1, 0.3, 0.3)
var kind := 0         # 0 보통, 1 참(파랑: 멈춰 있으면 안 맞음), 2 거짓(주황: 움직이면 안 맞음)
var fn: Callable      # 움직이는 레이저:  func(l, delta)
var data := {}


func is_firing() -> bool:
	return age >= warn and age < warn + active


func dist_to(p: Vector2) -> float:
	var d := Vector2.RIGHT.rotated(angle)
	var k := clampf((p - from).dot(d), 0.0, length)
	return p.distance_to(from + d * k)
