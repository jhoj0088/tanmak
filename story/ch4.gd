extends "res://scripts/core/story_base.gd"
## Chapter 4 「기숙사 점호 시간의 악몽」
## 데크 → 어두운 기숙사 복도(순찰 피하기, 알람 시계) → 304호 → 주T


func ev_enter_deck(_a) -> void:
	sfx("door")
	if Game.flag("cert_dorm"):
		await say(["* 데크 문에 '점호 완료' 도장이 찍혀 있다.", "* 점호가 끝난 기숙사는 고요하다. 이제 숨어 다닐 필요는 없다."])
		await goto("dorm_hall", "start")
		return
	if Game.flag("ch4_started"):
		await goto("dorm_hall", "start")
		return
	Game.set_flag("ch4_started")
	await say([
		"* '현재 사용 불가' 팻말이 저절로 떨어졌다.",
		"* 데크 너머, 불 꺼진 기숙사가 보인다.",
	])
	await card("기숙사 점호 시간의 악몽", "Chapter 4")
	main._load_room("dorm_hall", "start")
	await main.fade_to(0.0, 0.5)
	await main.run_event("dorm_hall_enter")


func ev_dorm_hall_enter(_a) -> void:
	if Game.flag("dorm_intro"):
		return
	Game.set_flag("dorm_intro")
	await say([
		"* 기숙사 3층. 소등 시간이 지나 캄캄하다.",
		"나머지: (속삭임) 저기 손전등 불빛 보여? 사감 선생님, 주T야.",
		"나머지: (속삭임) 파란 불빛에 닿으면 걸려. 벽의 그늘에 숨으면 못 봐.",
		"나머지: (속삭임) 네 방은 304호. 점호 전에 침대에 누워 있기만 하면 돼!",
		"나머지: (속삭임) 왼쪽 끝은 정독실, 오른쪽 끝은 세탁실이야. ...세탁실에서 무슨 소리 나는데?",
	])
	phone("jk3")
	objective("주T의 불빛을 피해 304호로 들어가자. (벽의 그늘에 숨을 수 있다)")


func ev_dorm_caught(_a) -> void:
	sfx("warn")
	var n := Game.add_count("dorm_caught")
	await say(["주T: 거기! 소등 후 이동 금지!", "* 들켰다! 복도 입구로 끌려 나왔다. (벌점 %d점)" % n])
	phone("room1")
	await goto("dorm_hall", "start")
	if n == 2:
		await say(["나머지: (속삭임) 주T가 등을 돌리고 멀어질 때 뛰어!", "나머지: (속삭임) 돌아올 땐 그늘에 쏙. 그늘 안에서는 코앞을 지나가도 못 봐."])


func ev_ch4_alarm(_a) -> void:
	await say([
		"* 따르르르릉! 누군가의 알람 시계가 복도로 뛰쳐나왔다!",
		"나머지: (속삭임) 하필 지금! 주T가 오기 전에 조용히 시켜!",
		"나머지: (속삭임) 어두워서 탄이 잘 안 보일 거야. 움직인 쪽으로 손전등이 비쳐.",
	])
	var r: String = await battle("alarm")
	if r == "spared":
		await say(["나머지: (속삭임) 휴... 주인 대신 꺼 줬네. 착하다."])


func ev_dorm_vending(_a) -> void:
	if Game.flag("got_dorm_coffee"):
		await say(["* 자판기다. '품절' 불이 전부 켜져 있다."])
		return
	Game.set_flag("got_dorm_coffee")
	give("자판기 캔커피")
	sfx("heal")
	await say(["* 자판기다. 거스름돈 칸에 손을 넣어 보았다.", "* 동전은 없고 캔커피가 하나 끼어 있다. '자판기 캔커피'를 얻었다."])


func ev_dorm_303(_a) -> void:
	if Game.flag("got_ramen"):
		await say(["* 303호. 후루룩 소리가 멈췄다. 숨죽이고 있는 것 같다."])
		return
	await say(["* 303호. 컵라면 냄새가 솔솔 난다. 야식은 금지인데."])
	var i: int = await choose("* 어떻게 할까?", ["똑똑. '주T 온다!'", "모르는 척 지나간다"])
	if i == 1:
		return
	Game.set_flag("got_ramen")
	Game.emotion += 1
	give("야식 컵라면")
	sfx("heal")
	await say([
		"* 안에서 우당탕 소리가 나더니 문이 한 뼘 열렸다.",
		"* 손 하나가 나와 컵라면을 쥐여 주고 사라졌다. '고맙다. 입 다물어 줘.'",
		"* '야식 컵라면'을 얻었다. 의리를 지켰다. 감성이 1 올랐다.",
	])


func ev_dorm_304(_a) -> void:
	sfx("door")
	await goto("dorm_room", "from_hall")
	if not Game.flag("room_intro") and not Game.flag("jut_done"):
		Game.set_flag("room_intro")
		await say(["나머지: 도착! 문에 304호라고 적혀 있었지? 기억해 둬.", "나머지: 오른쪽 위가 네 침대야. 얼른 누워!"])
		objective("오른쪽 위 내 침대에 눕자.")


func ev_dorm_leave(_a) -> void:
	if Game.flag("jut_done"):
		await goto("f2_hall", "from_deck")
		return
	var i: int = await choose("* 본관으로 돌아갈까? (점호는 아직이다)", ["돌아간다", "남는다"])
	if i == 0:
		await goto("f2_hall", "from_deck")


func ev_dorm_bed(_a) -> void:
	if Game.flag("jut_done"):
		await say(["* 내 침대다. 눕고 싶지만... 아직 할 일이 남았다."])
		return
	await say([
		"* 내 침대다. 이불 속으로 파고들었다.",
		"* ......",
		"* 쾅! 문이 열리고 손전등 불빛이 얼굴에 꽂혔다.",
		"주T: 304호! 점호 시간에 복도를 뛰어다닌 학생이 자네로군.",
		"주T: CCTV에 다 찍혔다. 교복 차림으로 이불 속이라니, 성의가 없어.",
		"주T: 코어의 지시다. '규칙을 어긴 학생은 불완전 요소.' 점호를 실시한다!",
		"나머지: (속삭임) 파란 불빛 안에서는 멈춰! 움직이면 걸려!",
	])
	var r: String = await battle("jut")
	Game.set_flag("jut_done")
	Game.set_flag("cert_dorm")
	if r == "spared":
		Game.set_flag("jut_spared")
		await say([
			"주T: ...사실 말이다. 벌점은 지우라고 있는 거다.",
			"주T: 한 번 어겼다고 끝이면, 이 수첩에 지우개가 왜 달려 있겠나.",
			"주T: 코어는 그걸 몰라. 가서 알려 줘라. 점호 인증이다. 이상.",
			"* 주T는 문을 닫으며 작게 덧붙였다. '...잘 때 이불은 꼭 덮고.'",
		])
		await memory([
			"사감실 책상 서랍 속, 손때 묻은 벌점 수첩.",
			"앞쪽은 빽빽하다. '소등 후 이동', '야식', '점호 불참'...",
			"그런데 줄마다 지우개 자국이 있다. 지우고, 또 지우고.",
			"맨 뒷장에는 벌점 대신 다른 것이 적혀 있다. 졸업한 학생들의 이름. 그리고 한 줄씩.",
			"'303호 김OO - 야식 대장. 요리사 된다더라.' '305호 박OO - 맨날 잠. 그래도 끝까지 다님.'",
			"마지막 줄: '다들 잘 지내라. 이불은 꼭 덮고.'",
		])
	else:
		Game.set_flag("jut_killed")
		await say(["* 304호가 조용해졌다.", "* 바닥에 벌점 수첩이 펼쳐진 채 떨어져 있다. 당신 이름 옆 칸은 비어 있다."])
	sfx("save")
	await say(["* '점호 인증'을 얻었다!"])
	phone("mom4")
	Game.chapter = 5
	await goto("f2_hall", "from_deck")
	await say([
		"나머지: 본관으로 돌아왔어. 이제 남은 건...",
		"* 스피커가 지직거린다.",
		"[ 코어 : 전교생에게 알립니다. 지금부터 옥상 천문대에서 하늘의 오차를 정리합니다. ]",
		"[ 코어 : 불규칙하게 깜빡이는 별은 모두 지웁니다. ]",
		"[ 코어 : 응시하지 않는 학생은 0점 처리 후 삭제됩니다. ]",
		"나머지: ...별을 지운다고? 별은 원래 깜빡이는 건데!",
		"나머지: 옥상 계단은 5층 중앙 홀에 있어. 위로 올라가자. 꼭대기까지!",
	])
	objective("계단으로 5층까지 올라가, 중앙 홀의 옥상 계단으로 가자.")
	save()
