extends RefCounted
## 모든 적의 부모. 새 적을 만들 때는 이 파일을 상속해서 필요한 함수만 덮어쓴다.
## (scripts/battle/enemies/ 안의 파일들을 예시로 볼 것)
##
## b = 전투 화면(battle.gd). 자주 쓰는 것:
##   b.add(위치, 속도, 반지름, 색, 모양)      탄 하나 추가 (Bullet 을 돌려준다)
##   b.ring(중심, 개수, 속력, 반지름, 색, 시작각)  원형으로 퍼지는 탄
##   b.aim(위치)                              그 위치에서 하트를 향하는 각도
##   b.burst(탄, 개수, 속력, 반지름, 색)       그 탄을 터뜨려 여러 조각으로 (분열)
##   b.laser(시작점, 각도, 예고 시간, 발사 시간, 굵기, 색)   레이저
##   b.hurt()                                 하트에게 피해 (안전 구역 밖에 있을 때 등)
##   b.dark = 70.0                            이번 공격은 어둠 속 (숫자 = 보이는 반지름)
##   b.beat_hit / b.beat_i                    박자가 바뀐 순간 true / 몇 번째 박자인지 (bpm 을 정한 적만)
##   b.box / b.soul / b.turn / b.attack_t     전투 상자 / 하트 위치 / 몇 번째 턴 / 이번 공격이 시작된 뒤 흐른 시간
##   await b.say([...])                       아래 상자에 문장 출력
##   var i = await b.choose([...])            선택지

var id := ""
var name := "???"
var max_hp := 20
var hp := 20
var atk := 3
var def := 0
var exp_reward := 3
var boss := false
var music := "battle"
var can_flee := true
var spareable := false          # true 가 되면 '자비 > 살려 주기'가 통한다
var acts: Array = ["살펴보기"]
var bg := Color(0.35, 0.1, 0.3)  # 배경 모눈 색
var bpm := 0.0                   # 0 보다 크면 음악 박자에 맞춘 전투 (b.beat_hit, b.beat_i 사용)
var pt := 0.0                    # 패턴용 타이머
var spin := 0.0


## enemies.gd 에서 같은 스크립트를 여러 id 로 쓸 때 (예: 과목별 시험지)
func setup(_enemy_id: String) -> void:
	pass


func intro() -> String:
	return "* %s이(가) 나타났다!" % name


func flavor(_b) -> String:
	return "* %s이(가) 이쪽을 보고 있다." % name


## 공격 직전에 말풍선으로 하는 말. "" 이면 말풍선 없이 바로 공격.
func bubble(_b) -> String:
	return ""


## '행동'에서 i번째를 골랐을 때. 안에서 await b.say([...]) 를 쓴다.
func on_act(b, _i: int) -> void:
	await b.say(["* 아무 일도 일어나지 않았다."])


func on_hurt(_b, _dmg: int) -> void:
	pass


func on_graze(_b) -> void:
	pass


## 공격 시작. b.attack_len(초), b.attack_box, b.note 를 바꿀 수 있다.
func begin_attack(_b) -> void:
	pass


## 공격 중 매 프레임. 여기서 탄을 만든다.
func update_attack(_b, _delta: float) -> void:
	pass


func end_attack(_b) -> void:
	pass


## 공격 중 상자 위에 덧그릴 것 (안전 구역, 렌즈 등). ci 는 전투 화면.
func draw_attack(_b) -> void:
	pass


func not_yet_text() -> Array:
	return ["* 살려 주려 했다.", "* 하지만 %s은(는) 아직 물러설 마음이 없다." % name]


func spare_text() -> Array:
	return ["* %s을(를) 살려 주었다." % name]


func kill_text() -> Array:
	return ["* %s은(는) 흩어져 사라졌다..." % name]


func draw(_ci: CanvasItem, _pos: Vector2, _t: float, _flash: float, _alpha: float) -> void:
	pass
