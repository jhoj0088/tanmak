extends RefCounted
## 탄 하나.

var pos := Vector2.ZERO
var vel := Vector2.ZERO
var r := 6.0
var color := Color(1, 0.3, 0.45)
var shape := 0        # 0 동그란 탄, 1 길쭉한 탄, 2 글자 탄(text), 3 속이 빈 고리, 4 플라스크, 5 세포
var kind := 0         # 0 보통, 1 참(파랑: 멈춰 있으면 안 맞음), 2 거짓(주황: 움직이고 있으면 안 맞음)
var text := ""
var curve := 0.0      # 초당 회전(라디안): 휘어지는 탄
var accel := 0.0      # 초당 가속
var gravity := 0.0    # 아래로 떨어지는 힘 (포물선)
var delay := 0.0      # 이 시간 동안 제자리에서 깜빡이다가 출발
var age := 0.0
var life := 30.0      # 이 시간이 지나면 사라짐
var grazed := false
var fn: Callable      # 탄마다 다른 움직임이 필요할 때:  func(b, delta)
var data := {}
