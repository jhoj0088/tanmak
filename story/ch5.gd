extends "res://scripts/core/story_base.gd"
## Chapter 5 「천문대」 (옥상)
## 4장이 끝나면 코어가 '하늘의 오차'를 지우겠다고 방송한다.
## 5층 중앙 홀의 옥상 계단 → 옥상(별자리판 3개, 유성우, 광해 가로등, 절규) → 천문대 돔의 천문 선생 → 천문 인증


func ev_stairs_roof(_a) -> void:
	sfx("door")
	if Game.flag("ch5_started"):
		await goto("roof", "from_hall")
		return
	Game.set_flag("ch5_started")
	await say([
		"* 철문의 자물쇠가 저절로 풀려 있다. 계단 위에서 찬 바람이 내려온다.",
		"* 한 칸 오를 때마다 별 냄새가 난다. 그런 냄새가 있다면.",
	])
	await card("천문대", "Chapter 5")
	main._load_room("roof", "from_hall")
	await main.fade_to(0.0, 0.5)
	await main.run_event("roof_enter")


func ev_roof_enter(_a) -> void:
	if Game.flag("roof_intro"):
		return
	Game.set_flag("roof_intro")
	phone("mom3")
	await say([
		"* 옥상이다. 머리 위로 하늘이 통째로 열려 있다.",
		"* 그런데 별이 한쪽부터 하나씩 꺼지고 있다. 누가 지우개로 지우는 것처럼.",
		"[ 코어 : 하늘의 오차를 정리합니다. 불규칙하게 깜빡이는 별, 제자리를 벗어나는 유성, 흐린 은하수. ]",
		"[ 코어 : 완벽한 하늘에는 북극성 하나면 충분합니다. ]",
		"나머지: 말도 안 돼. 별이 깜빡이는 건 대기 때문이고, 유성은 원래 떨어지는 거잖아!",
		"나머지: 저기 흰 돔이 천문대야. 문에 별자리판 세 개가 그려져 있어. 옥상의 판을 다 풀면 열릴 거야.",
		"* (휴대폰이 진동했다.)",
	])
	objective("옥상의 별자리판 세 개를 풀고 천문대 돔으로 들어가자.")


const BOARDS := [
	{
		"intro": ["* 별자리판 1. 여름 밤하늘 사진 위에 밝은 별 세 개가 삼각형으로 이어져 있다.", "* '여름철 대삼각형을 이루는 세 별은?'"],
		"opts": ["베가 · 데네브 · 알타이르", "시리우스 · 프로키온 · 베텔게우스", "북극성 · 두베 · 메라크"],
		"answer": 0,
		"ok": ["* 별자리판의 세 별이 동시에 반짝였다.", "나머지: 거문고자리 베가, 백조자리 데네브, 독수리자리 알타이르! 견우랑 직녀도 저 안에 있대."],
		"hint": ["나머지: 시리우스, 프로키온, 베텔게우스는 '겨울철' 대삼각형이야.", "나머지: 여름 하늘 한가운데 은하수를 사이에 두고 마주 보는 별이 있잖아. 견우(알타이르)랑 직녀(베가)."],
	},
	{
		"intro": ["* 별자리판 2. 북두칠성 국자 끝의 두 별에 화살표가 그려져 있다.", "* '국자 끝 두 별 사이 거리를 그 방향으로 몇 배쯤 늘리면 북극성에 닿을까?'"],
		"opts": ["약 2배", "약 5배", "약 10배"],
		"answer": 1,
		"ok": ["* 화살표가 쭉 늘어나더니 북극성에 콕 박혔다.", "나머지: 메라크에서 두베 쪽으로 다섯 배! 길을 잃으면 이렇게 북쪽을 찾는 거래."],
		"hint": ["나머지: 국자 끝 두 별(메라크, 두베)을 잇고, 그 거리를 손가락으로 재서 다섯 번쯤 옮겨 봐.", "나머지: 북극성은 생각보다 어두워. 그래서 이 방법이 필요해."],
	},
	{
		"intro": ["* 별자리판 3. 별 옆에 1, 2, 3, 4, 5, 6 숫자가 적혀 있다. 숫자가 작을수록 밝다.", "* '1등성은 6등성보다 몇 배쯤 밝을까?'"],
		"opts": ["약 6배", "약 100배", "약 1000배"],
		"answer": 1,
		"ok": ["* 6등성 하나가 '그래도 나도 보이지?' 하고 웃었다.", "나머지: 5등급 차이가 정확히 100배야. 한 등급마다 약 2.5배씩."],
		"hint": ["나머지: 등급이 5 차이 나면 밝기는 100배 차이야.", "나머지: 1등성과 6등성은 몇 등급 차이일까?"],
	},
]


func ev_star_board(a) -> void:
	var q: int = int(a.get("q", 0))
	if Game.flag("board_%d" % q):
		await say(["* 풀어 놓은 별자리판이다. 별들이 은은하게 이어져 있다."])
		return
	var d: Dictionary = BOARDS[q]
	await say(d["intro"])
	var i: int = await choose("* 답은?", d["opts"])
	if i != d["answer"]:
		sfx("wrong")
		await say(["* 판의 별들이 흩어졌다! 빛 부스러기가 떨어진다...!"])
		await battle("meteor")
		await say(d["hint"])
		return
	sfx("correct")
	Game.set_flag("board_%d" % q)
	await say(d["ok"])
	await solved("star_%d" % q)
	if Game.flag("board_0") and Game.flag("board_1") and Game.flag("board_2"):
		Game.set_flag("roof_open")
		sfx("save")
		await say(["* 쿵. 천문대 돔 쪽에서 무거운 문이 열리는 소리가 났다.", "나머지: 열렸다! 돔 안에서 누가 시계 소리를 내고 있어. 삑, 삑..."])
		objective("천문대 돔으로 들어가자.")


func ev_roof_meteor(_a) -> void:
	await say([
		"* 하늘에서 빛줄기 여러 개가 한꺼번에 떨어졌다!",
		"나머지: 유성우다! 코어가 지우기 전에 다들 마지막으로 떨어지는 거야.",
		"나머지: 별똥별이 떨어질 땐 뭐 해야 하는지 알지?",
	])
	var r: String = await battle("meteor")
	if r == "spared":
		await say(["나머지: 무슨 소원 빌었어? ...말 안 해도 돼. 나도 빌었거든."])


func ev_roof_lamp(_a) -> void:
	await say([
		"* 옥상 가장자리의 가로등이 눈부시게 빛나고 있다. 그 둘레만 하늘에 별이 하나도 없다.",
		"가로등: 밝아야 안전해! 밝아야 아무도 안 넘어져! 하늘까지 다 비춰 줄게!",
		"나머지: 저게 광해야. 빛이 너무 많으면 별이 안 보여.",
	])
	var r: String = await battle("lamp")
	if r == "fled":
		return
	Game.set_flag("lamp_done")
	main.world.refresh_actors()
	if r == "spared":
		Game.set_flag("lamp_spared")
		Game.emotion += 1
		await say([
			"* 가로등이 갓을 쓴 채 발밑만 비춘다. 그 위로 은하수가 희미하게 떠올랐다.",
			"나머지: 와... 저게 은하수야? 진짜 강처럼 흐르네.",
			"* 감성이 1 올랐다.",
		])
	else:
		await say(["* 가로등이 꺼졌다. 별은 돌아왔지만, 계단 쪽이 캄캄하다."])


## 옥상의 절규: 처음 만나면 바람막이 이야기, 그다음부터는 평소처럼 물건 돌려받기
func ev_jk_roof(a) -> void:
	if Game.flag("jk_roof_scene"):
		await main.run_event("junkyu", a)
		return
	Game.set_flag("jk_roof_scene")
	if not Game.flag("met_junkyu"):
		Game.set_flag("met_junkyu")
	await say([
		"절규: 어, 너도 왔구나! 나 방송 듣고 그냥 올라왔어. 별 지운다길래, 지워지기 전에 보고 싶어서.",
		"* 절규는 반팔 체육복 차림이다. 이가 딱딱 부딪친다.",
		"절규: 바람막이를... 잃어버렸거든. 하하. 당연하지.",
	])
	var i: int = await choose("* 어떻게 할까?", ["내 겉옷을 벗어 준다", "같이 실외기 앞에서 손을 녹인다"])
	Game.emotion += 1
	if i == 0:
		await say([
			"* 겉옷을 벗어 절규 어깨에 걸쳐 주었다. 바람이 차다. 그래도 괜찮다.",
			"절규: ...따뜻하다. 너 안 추워? 이거 잃어버리면 안 되는데. 내가 들고 있으면 위험한데.",
			"절규: 아니다. 이번엔 안 잃어버릴게. 진짜로.",
		])
	else:
		await say([
			"* 둘이서 실외기 앞에 쪼그려 앉았다. 따뜻한 바람이 나온다.",
			"절규: 옥상 실외기 앞이 명당이었네. 3년 동안 몰랐어.",
		])
	await say([
		"절규: 있잖아. 나 맨날 땅만 보고 다녔어. 뭐 떨어뜨렸나 싶어서.",
		"절규: 별이 이렇게 많은 줄 몰랐어. 위를 볼 일이 없었으니까.",
		"* 감성이 1 올랐다.",
	])
	await main.run_event("junkyu", a)


func ev_enter_dome(_a) -> void:
	sfx("door")
	await goto("roof_dome", "from_roof")


func ev_dome_enter(_a) -> void:
	if Game.flag("dome_intro"):
		return
	Game.set_flag("dome_intro")
	await say([
		"* 천문대 돔 안. 둥근 천장이 천천히 돌아간다. 가운데에 거대한 망원경이 하늘을 겨누고 있다.",
		"* 그 앞에서 누군가 제자리 뛰기를 하고 있다. 삑, 삑. 손목시계 소리. '무릎은 높이, 착지는 부드럽게...'",
	])


func ev_ch5_astro(_a) -> void:
	if Game.flag("astro_done"):
		return
	await say([
		"???: 1구간 3분 12초. 음, 턴이 늦었어. ...어? 학생이네. 거기 서 있지 말고 이리 와 봐.",
		"천문 선생: 나는 천문 선생이다. 안경 너머로 별 보고, 주말엔 철인3종 뛴다. 둘 다 내가 좀 하지.",
		"천문 선생: 코어가 나한테 기록을 맡겼어. '흔들리는 별과 느린 학생을 하늘에서 지워라.' 뭐, 효율은 중요하지.",
		"천문 선생: 기록은 정확해야 돼. 흐린 날은 지우고, 늦은 완주도 지우고... 내 말 틀린 거 있냐?",
		"천문 선생: ...근데 나도 첫 완주는 꼴찌였거든. 그 기록은... 음, 그건 나중에 얘기하고.",
		"천문 선생: 자, 네 페이스 한번 보자. 어깨 힘 빼고. 시작부터 전력 질주하면 안 된다? 측정 시작!",
		"나머지: 이 선생님 공격은 수영, 사이클, 마라톤 순서야! 마라톤 땐 초록 줄로 달려!",
	])
	var r: String = await battle("astro")
	Game.set_flag("astro_done")
	Game.set_flag("cert_astro")
	main.world.refresh_actors()
	if r == "spared":
		Game.set_flag("astro_spared")
		await say([
			"천문 선생: ...시계 멈춘 거 오랜만이네. 이것도 훈련이야. 쉬는 훈련.",
			"천문 선생: 별은 기록하라고 있는 게 아니라 올려다보라고 있는 거지. 너도 공부만 하지 말고 가끔 위를 봐라.",
			"천문 선생: 받아라, 천문 인증. 그리고... 고맙다, 응원. 다음엔 네가 뛰어라. 내가 옆에서 자세 봐 줄 테니까.",
		])
		await memory([
			"십몇 년 전, 첫 철인3종 대회. 마지막 주자가 결승선에 들어온 건 밤 11시였다.",
			"관중은 다 돌아갔다. 기록계원은 시계를 보며 하품을 했다.",
			"꼴찌로 들어온 젊은 선생은 바닥에 누워 하늘을 보았다. 별이 쏟아질 듯했다.",
			"그때 누군가 망원경을 들고 다가왔다. 대회장 옆에서 관측회를 하던 꼬마였다.",
			"'아저씨, 저기 토성이요. 고리 보여요!' 꼬마는 꼴찌한테 망원경을 먼저 양보했다.",
			"그날 기록지 맨 아래 칸에는 '완주'라고만 적혀 있었다. 그는 그 두 글자를 지금도 가장 좋아한다.",
		])
	else:
		Game.set_flag("astro_killed")
		await say(["* 돔 안이 조용해졌다. 망원경만 하늘을 향해 있다.", "* 바닥에 멈춘 손목시계가 떨어져 있다. 마지막 기록은 비어 있다."])
	sfx("save")
	await say(["* '천문 인증'을 얻었다!"])
	Game.chapter = 6
	await say([
		"* 돔이 크게 열렸다. 하늘의 별들이 하나도 빠짐없이 돌아와 있다. 깜빡이는 별도, 흐린 별도.",
		"[ 코어 : ...오차 정리 실패. 지운 별이 다시 떠올랐습니다. 계산에 없는 결과입니다. ]",
		"[ 코어 : 서버실로 오십시오. 직접 제거하겠습니다. ]",
		"나머지: 드디어 불렀네. 2층 서버실. 끝내러 가자.",
	])
	objective("계단으로 내려가 2층 서버실로 가자.")
	save()
