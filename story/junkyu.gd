extends "res://scripts/core/story_base.gd"
## 절규 — 맨날 물건을 잃어버리는 친구. 층마다 나타나고, 찾아 준 물건을 돌려받는다.
## 물건 데이터는 data/junkyu.gd.

const JK = preload("res://data/junkyu.gd")

## 챕터별 평소 대사 (돌려줄 물건이 없을 때)
const IDLE := {
	1: [
		["절규: 필통... 필통... 하늘색에 곰 달린 거. 보이면 꼭 알려 줘."],
		["절규: 아까 계단 셔터 봤어? 무슨 인증이 필요하대. 우리 학교 언제 이렇게 첨단이 됐지?"],
		["절규: 나 사실 수학 강의실 들어가 봤는데, 끝이 안 보이길래 바로 나왔어. 무서워서."],
	],
	2: [
		["절규: 4층은 벌레 소리가 너무 커. 나 벌레 진짜 싫어하는데..."],
		["절규: 맥실 아이맥들이 다 눈동자 화면이야. 나만 따라 보는 것 같아."],
		["절규: 노래방 기계가 켜져 있더라. 나 거기서 이어폰 잃어버렸을지도."],
	],
	3: [
		["절규: (책장 앞에서) 쉿. 도서관에선 조용히... 근데 너 내 대출증 못 봤어?"],
		["절규: 2층 체육관에서 공 소리 들려. 급식실은 그 옆이지? 배고프다..."],
		["절규: 암실 들어가 봤어? 레이저가 노래에 맞춰 춤춰. 멋있는데 무서워."],
	],
	4: [
		["절규: (속삭임) 주T 지나갔어? 나 여기 숨어 있었어. 세탁기 소리에 묻혀서."],
		["절규: (속삭임) 우리 방 열쇠를 잃어버려서 못 들어가고 있었거든..."],
	],
	5: [
		["절규: 옥상 바람 진짜 차다. 너 손 안 시려? 나는 장갑을... 아니다, 원래 없었다."],
		["절규: 별이 이렇게 많았나. 맨날 고개 숙이고 다녀서 몰랐어."],
		["절규: 저기 저 밝은 거 목성이래. 천문 동아리 애가 그랬어. 나 그 말 3년째 기억해."],
	],
	6: [
		["절규: 교장실은 저쪽이야. ...같이 갈까? 아니다, 나는 여기서 기다릴게. 짐 될 것 같아."],
		["절규: 운동장 가 봤어? 정문 현관으로 나가면 돼. 새벽 잔디 냄새 좋더라."],
		["절규: 나 잃어버린 것 중에 하나, 진짜 중요한 게 있었는데... 뭐였는지 기억이 안 나."],
	],
}


func ev_junkyu(_a) -> void:
	if not Game.flag("met_junkyu"):
		Game.set_flag("met_junkyu")
		await say([
			"???: 으아아 어디 갔지... 어? 너!",
			"절규: 너도 갇혔어? 나 야자 끝나고 필통 찾으러 왔다가 문이 다 잠겨서...",
			"절규: 근데 복도가 이상해. 아까 화분이 나한테 인사했어. 진짜로.",
			"나머지: (명찰 뒤에서) ...저 애한테는 내가 안 보이나 봐.",
			"절규: 혹시 돌아다니다가 내 물건 보이면 좀 챙겨 줘. 나 맨날 뭘 잃어버리거든.",
			"절규: 필통, 우산, 열쇠, 이어폰 한 짝... 하하. 나는 여기서 좀 더 찾아볼게. 조심해!",
		])
		phone("jk1")
		if JK.carried().is_empty():
			return
	var carried := JK.carried()
	var given := 0
	for id in carried:
		if id == "letter":
			continue
		var d: Dictionary = JK.item(id)
		await say(["* '%s'을(를) 돌려주었다." % d["name"]])
		await say(d["return"])
		Game.set_flag("jk_back_" + id)
		Game.emotion += 1
		given += 1
		if d.has("gift"):
			give(d["gift"])
			await say(["* '%s'을(를) 받았다." % d["gift"]])
	if given > 0:
		sfx("heal")
		Game.heal(10)
		var n := JK.returned_count()
		await say(["* 절규가 환하게 웃었다. 감성이 %d 올랐다. (돌려준 물건 %d / 11)" % [given, n]])
		if n >= 11 and not Game.flag("junkyu_happy"):
			Game.set_flag("junkyu_happy")
			await say([
				"절규: ...어? 이상하다. 이제 잃어버린 게 하나도 없어.",
				"절규: 이런 적 처음이야. 가방이 무거운데, 기분은 가벼워.",
				"절규: 다 네 덕분이야. 진짜로.",
			])
		return
	var pool: Array = IDLE.get(Game.chapter, IDLE[1])
	var k := Game.add_count("jk_idle") % pool.size()
	await say(pool[k])


## 잃어버린 물건 줍기
func ev_jk_item(a) -> void:
	var id: String = a["item"]
	var d: Dictionary = JK.item(id)
	Game.set_flag("jk_found_" + id)
	main.world.refresh_actors()
	sfx("save")
	await say(d["found"])
	if id == "letter":
		await say(["* '%s'을(를) 소지품에 넣었다." % d["name"]])
	else:
		await say(["* '%s'을(를) 챙겼다. 절규를 만나면 돌려주자." % d["name"]])
