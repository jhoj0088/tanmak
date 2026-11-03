extends "res://scripts/core/story_base.gd"
## 3층(쉬어 가는 층) + Chapter 3 「단일광자 실험실」
## 3층 도서관·정보과학실 → 2층 → 암실(광자, 거울 문, 프리즘) → 렌즈 선생


# ================================================================ 3층
func ev_f3_hall_enter(_a) -> void:
	if Game.flag("f3_intro"):
		return
	Game.set_flag("f3_intro")
	await say([
		"* 3층. 책 냄새가 난다. 이 층은 이상하리만치 조용하다.",
		"나머지: 여긴 셔터가 없네? 쉬어 가는 층인가 봐.",
		"나머지: 도서관에 들렀다 가도 좋고, 바로 2층으로 내려가도 돼.",
	])
	phone("sis1")
	objective("계단으로 2층에 내려가자. (도서관에 들러도 좋다)")


func ev_bookworm(_a) -> void:
	if Game.flag("bookworm_done"):
		await say(["책벌레: 쉿. ...좋은 답이었어. 조용히 읽다 가."])
		return
	await say([
		"책벌레: 쉿. 도서관에서는 조용히.",
		"책벌레: 코어는 이 도서관을 지우지 못했어. 책에는 정답이 하나가 아니거든.",
		"책벌레: 심심하던 참이야. 문제 하나 낼게.",
		"책벌레: 여기 문장이 하나 있어. '이 문장은 거짓이다.'",
	])
	var i: int = await choose("책벌레: 이 문장은 참일까, 거짓일까?", ["참이다", "거짓이다", "참도 거짓도 아니다"])
	if i == 2:
		sfx("correct")
		Game.set_flag("bookworm_done")
		give("책갈피 초콜릿")
		await say([
			"책벌레: 그렇지. 참이라 하면 거짓이 되고, 거짓이라 하면 참이 돼.",
			"책벌레: 세상에는 참·거짓으로 나눌 수 없는 것도 있어. 코어가 제일 싫어하는 종류지.",
			"* '책갈피 초콜릿'을 얻었다.",
		])
		await solved("bookworm")
	else:
		sfx("wrong")
		await say(["책벌레: 그럼 그 말대로라면... 반대가 되어 버리는데?", "책벌레: 천천히 다시 생각해 봐. 책은 도망가지 않아."])


func ev_robot(_a) -> void:
	if Game.flag("robot_done"):
		await say(["로봇: 지금은. 쉬는. 중입니다.", "* 로봇의 눈이 느긋하게 깜빡인다."])
		return
	await say([
		"로봇: 질문. 저는 1,204시간째 같은 선을 따라 돌고 있습니다.",
		"로봇: 오차는 0.0%입니다. 그런데 바퀴가 아픕니다.",
	])
	var i: int = await choose("로봇: 쉬어도 됩니까?", ["쉬어도 돼", "오차가 생기면 안 되지"])
	Game.set_flag("robot_done")
	if i == 0:
		Game.emotion += 1
		sfx("heal")
		await say(["로봇: 허가. 감사합니다. 처음 듣는 명령입니다.", "* 로봇이 선 밖으로 한 뼘 나와서 멈췄다. 감성이 1 올랐다."])
	else:
		Game.logic += 1
		await say(["로봇: 알겠습니다. 계속 돕니다.", "* 로봇은 다시 선을 따라간다. 정확하다. 논리가 1 올랐다."])


# ================================================================ 2층
func ev_f2_hall_enter(_a) -> void:
	if Game.flag("f2_intro"):
		return
	Game.set_flag("f2_intro")
	await say([
		"* 2층. 바닥이 쿵, 쿵, 쿵, 쿵 일정하게 울린다.",
		"나머지: 서버실이 이 층에 있어. 코어가 바로 저 안에...",
		"나머지: 하지만 인증이 모자라. 우선 파란빛이 새는 '단일광자 실험실'부터!",
	])
	objective("파란빛이 새는 단일광자 실험실로 가자.")


func ev_f2_coffee(_a) -> void:
	if Game.flag("got_f2_coffee"):
		await say(["* 캔커피가 있던 사물함이다. 지금은 비어 있다."])
		return
	Game.set_flag("got_f2_coffee")
	give("자판기 캔커피")
	await say(["* 이 사물함만 문이 덜 닫혀 있다.", "* '시험 기간 비상식량'이라고 적힌 캔커피가 있다. ...'자판기 캔커피'를 얻었다."])


func ev_enter_phys(_a) -> void:
	sfx("door")
	if Game.flag("cert_phys"):
		await say(["* 암실은 조용하다. 스크린에 간섭무늬만 은은하게 남아 있다."])
		return
	if Game.flag("ch3_started"):
		await goto("optics_1", "from_hall")
		return
	Game.set_flag("ch3_started")
	await say(["* 문을 열자 캄캄하다. 붉은 광선이 박자에 맞춰 깜빡인다."])
	await card("단일광자 실험실", "Chapter 3")
	main._load_room("optics_1", "from_hall")
	await main.fade_to(0.0, 0.5)
	await main.run_event("ch3_optics_enter")


func ev_ch3_optics_enter(_a) -> void:
	if Game.flag("optics_intro"):
		return
	Game.set_flag("optics_intro")
	await say([
		"나머지: 여긴 빛을 다루는 암실이야. 음악 들려? 쿵, 쿵, 쿵, 쿵.",
		"나머지: 이 방의 탄막은 전부 그 박자에 맞춰 날아와.",
		"나머지: 싸울 때 상자 테두리가 번쩍이는 순간이 박자야. 몸으로 외워 봐!",
	])
	objective("암실 안쪽에서 이 층의 주인을 찾자.")


func ev_ch3_photon(_a) -> void:
	await say([
		"* 눈앞에서 무언가 반짝였다. 점인가? 물결인가?",
		"나머지: 광자다! 조심해, 레이저는 예고선이 먼저 보여.",
		"나머지: 예고선이 깜빡이면 한 박자 뒤에 진짜가 나가. 선에서 비켜서!",
	])
	var r: String = await battle("photon")
	if r == "spared":
		await say(["나머지: 입자이면서 파동이라... 하나로 안 정해져도 괜찮구나."])
	elif r == "killed":
		await say(["나머지: 꺼져 버렸네. 빛도 꺼질 수 있구나."])


## 거울 문: SPDC(자발적 매개 하향 변환)에 대해 틀린 것 고르기
func ev_ch3_gate(_a) -> void:
	await say([
		"* 거울로 된 문이 길을 막고 있다. 문 안쪽에 비선형 결정(BBO) 하나가 박혀 있다.",
		"* 보라색 펌프 레이저가 결정을 지나자, 빛이 원뿔 모양으로 둘로 갈라진다.",
		"* 'SPDC(자발적 매개 하향 변환)에 대한 설명 중 틀린 것을 고르시오.'",
	])
	var i: int = await choose("* 틀린 설명은?", [
		"BBO 결정에서 405 nm 펌프 광자 하나가 시그널·아이들러 두 광자로 나뉜다",
		"만들어진 두 광자는 펌프 광자보다 파장이 짧다",
		"Type-I 에서 두 광자의 편광은 서로 나란하고, 펌프 편광과는 수직이다",
	])
	if i == 1:
		sfx("correct")
		Game.set_flag("optics_gate_open")
		main.world.refresh_actors()
		await say([
			"* 거울 문이 두 갈래 빛을 정확히 되돌려 보내며 열렸다.",
			"나머지: 맞아. 에너지를 나눠 가지니까 각 광자는 에너지가 작아져. 그럼 파장은 더 길어지지.",
			"나머지: 405 nm 펌프면, 둘이 똑같이 나눌 때 810 nm 짜리 둘이 나와. 수업 실험이랑 똑같아. 펌프에서 3° 벌어진 원뿔로.",
			"나머지: 그리고 Type-I 이니까 두 광자 편광은 서로 나란하고 펌프와는 수직. 그건 맞는 설명이었어.",
		])
		await solved("optics_gate")
		return
	sfx("wrong")
	await say(["* 빛이 엉뚱한 곳으로 튕겨 나갔다! 튕긴 빛이 뭉쳐서...!"])
	await battle("photon")
	await say([
		"나머지: SPDC 에서는 광자 하나가 둘로 '쪼개져'. 에너지 보존! E펌프 = E시그널 + E아이들러.",
		"나머지: 에너지가 작아지면 파장은 어떻게 될까? E = hc/λ 를 떠올려 봐.",
		"나머지: 수업 때 405 nm 보라색 레이저를 넣었는데 검출기는 몇 nm 에 맞춰 놨었더라...?",
	])


func ev_ch3_prism(_a) -> void:
	await say(["* 유리 덩어리 하나가 구석에 웅크리고 있다. 프리즘이다.", "* 어두워서 아무 색도 내지 못하고 있다."])
	var i: int = await choose("* 어떻게 할까?", ["말을 건다", "내버려 둔다"])
	if i == 1:
		return
	var r: String = await battle("prism")
	if r == "fled":
		return
	Game.set_flag("prism_done")
	main.world.refresh_actors()
	if r == "spared":
		give("바나나우유")
		await say(["* 프리즘이 떠난 자리에 무지개가 잠깐 걸렸다. 그 밑에 '바나나우유'가 있다. 얻었다."])


func ev_ch3_lens(_a) -> void:
	await say([
		"???: 초점이 안 맞아. 전부 흐릿해. 다시, 다시!",
		"렌즈 선생: ...음? 학생인가. 나는 광학 담당일세. 다들 렌즈 선생이라 부르지.",
		"렌즈 선생: 코어가 그러더군. '흐릿한 것은 오류다. 또렷한 것만 남겨라.'",
		"렌즈 선생: 자네도 흐릿하군. 꿈도, 성적도, 눈빛도. 내가 초점을 맞춰 주지!",
		"나머지: 이 선생님 공격은 전부 박자에 딱딱 맞아. 박자를 타!",
		"나머지: 거의 안 맞고(한 번까지는 괜찮아) 넘기면 '초점 맞춰 주기'가 통할 거야.",
	])
	var r: String = await battle("lens")
	Game.set_flag("lens_done")
	Game.set_flag("cert_phys")
	main.world.refresh_actors()
	if r == "spared":
		Game.set_flag("lens_spared")
		await say([
			"렌즈 선생: 흐릿한 건 자네가 아니었군. 내 안경에 코어의 지문이 묻어 있었어.",
			"렌즈 선생: 멀리 있는 건 원래 흐릿하게 보이는 법이지. 꿈처럼 말이야.",
			"렌즈 선생: 가까이 가면 또렷해지네. 받게, 물리 인증일세.",
		])
		await memory([
			"새벽 3시의 암실. 대학원생 시절의 렌즈 선생이 스크린 앞에 앉아 있다.",
			"광자를 하나씩, 하나씩 쏜다. 몇 시간째 화면엔 아무 무늬도 없다. 점, 점, 점.",
			"포기하고 불을 켜려던 순간, 쌓인 점들이 희미한 줄무늬를 그리고 있었다.",
			"처음 찍은 간섭무늬 사진은 초점이 하나도 안 맞았다. 흐릿했다.",
			"그래도 그 사진은 지금도 선생님 지갑 속에 있다.",
			"'처음은 원래 흐릿한 거다. 그래도 거기 무늬가 있다는 건 알 수 있지.'",
		])
	else:
		Game.set_flag("lens_killed")
		await say(["* 암실에 깨진 안경만 남았다.", "* 렌즈 조각 사이에서 무언가 빛을 반사한다."])
	sfx("save")
	await say(["* '물리 인증'을 얻었다!"])
	Game.chapter = 4
	await goto("f2_hall", "from_phys")
	await say([
		"나머지: 눈이 아직도 번쩍번쩍해...",
		"나머지: 인증이 생겼으니 '기숙사 연결 데크'가 열렸을 거야.",
		"나머지: 근데 지금 몇 시지? ...점호 시간이잖아!",
	])
	objective("복도의 '기숙사 연결 데크' 문으로 가자.")
	save()
