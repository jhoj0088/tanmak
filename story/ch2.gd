extends "res://scripts/core/story_base.gd"
## Chapter 2 「생명 실험실」
## 4층 복도 → 현미경 속으로 → 초파리 떼, DNA 문, 표본 나비, 완두콩 문 → 파지 T4 → 3층


func ev_f4_hall_enter(_a) -> void:
	if Game.flag("f4_intro"):
		return
	Game.set_flag("f4_intro")
	await say([
		"* 4층. 복도 가득 윙윙거리는 소리가 난다.",
		"나머지: 으, 벌레 소리... 생명과학 실험실 쪽이야.",
		"나머지: 4층의 과목은 생명과학! 분홍빛이 새는 문을 찾아 봐.",
	])
	phone("teacher1")
	objective("분홍빛이 새는 생명과학 실험실로 가자.")


func ev_enter_bio(_a) -> void:
	sfx("door")
	if Game.flag("cert_bio"):
		await say(["* 실험실은 조용하다. 현미경만 덩그러니 놓여 있다.", "* 접안렌즈 너머에서 작은 육각형이 손(다리?)을 흔든 것 같다."])
		return
	if Game.flag("ch2_started"):
		await goto("bio_1", "from_hall")
		return
	Game.set_flag("ch2_started")
	await say([
		"* 실험대 위의 현미경이 혼자 켜져 있다.",
		"* 접안렌즈를 들여다보자...",
		"* 몸이 렌즈 속으로 빨려 들어간다!",
	])
	await card("생명 실험실", "Chapter 2")
	main._load_room("bio_1", "from_hall")
	await main.fade_to(0.0, 0.5)
	await main.run_event("ch2_bio1_enter")


func ev_stairs_4f(_a) -> void:
	if not Game.flag("ch2_clear"):
		Game.set_flag("ch2_clear")
		await card("Chapter 2 클리어", "생명 실험실")
		Game.chapter = 3
		phone("jk2")
	await goto("f3_hall", "from_up")
	save()


# ================================================================ 세포 속
func ev_ch2_bio1_enter(_a) -> void:
	if Game.flag("bio_intro"):
		return
	Game.set_flag("bio_intro")
	await say([
		"나머지: 우리가 작아진 걸까, 세상이 커진 걸까?",
		"나머지: 여긴 세포 속이야. 저 주황색 콩은 미토콘드리아!",
		"나머지: 이 층의 주인은 핵 근처에 있을 거야. 안쪽으로 가 보자.",
	])
	objective("세포 깊은 곳, 핵을 찾아가자.")


func ev_ch2_flies(_a) -> void:
	await say([
		"* 윙윙거리는 소리가 가까워진다!",
		"나머지: 조심해! 이 층에서는 실험실 시약이 날아다녀.",
		"나머지: 플라스크는 터지면서 여러 조각으로 갈라져. 어디로 튈지 몰라!",
		"나머지: 터지기 전에 멀리 떨어지는 게 제일이야.",
	])
	var r: String = await battle("flies")
	if r == "spared":
		await say(["나머지: 초파리는 과일 향만 있으면 얌전해지는구나."])
	elif r == "killed":
		await say(["나머지: ...3세대째 살았다던데."])


func ev_ch2_gate1(_a) -> void:
	await say([
		"* 세포벽의 구멍을 사다리 모양 문이 막고 있다.",
		"* 'DNA의 염기는 짝이 정해져 있다. A는 T와 짝을 이룬다.'",
	])
	var i: int = await choose("* 그렇다면 G의 짝은?", ["U (유라실)", "A (아데닌)", "C (사이토신)"])
	if i == 2:
		sfx("correct")
		Game.set_flag("bio_gate1_open")
		main.world.refresh_actors()
		await say(["* 사다리가 지퍼처럼 풀리며 길이 열렸다."])
		await solved("bio_gate1")
		return
	sfx("wrong")
	await say(["* 짝이 맞지 않는다! 잘못 끼워진 염기에서 무언가 태어난다..."])
	await battle("virus")
	await say(["나머지: A는 T랑, G는 C랑! 유라실(U)은 RNA에서만 쓰여.", "나머지: '아(A)티(T), 지(G)씨(C)'로 외워 봐."])


func ev_ch2_butterfly(_a) -> void:
	await say(["* 유리 상자 하나가 파닥거리며 길을 막았다!"])
	var r: String = await battle("butterfly")
	if r == "spared":
		await say(["나머지: 완벽한 표본보다 삐뚤빼뚤 나는 나비가 훨씬 예쁘다. 그치?"])


func ev_ch2_atp(_a) -> void:
	Game.set_flag("got_atp")
	main.world.refresh_actors()
	give("ATP 젤리")
	sfx("heal")
	await say(["* 미토콘드리아 옆에 떨어진 반짝이는 덩어리를 주웠다.", "* 'ATP 젤리'를 얻었다."])


func ev_ch2_virus_opt(_a) -> void:
	await say(["* 바이러스 한 마리가 세포벽에 붙어 졸고 있다."])
	var i: int = await choose("* 어떻게 할까?", ["깨운다", "내버려 둔다"])
	if i == 1:
		return
	var r: String = await battle("virus")
	if r == "fled":
		return
	Game.set_flag("virus_nap_done")
	main.world.refresh_actors()
	if r == "spared":
		give("요구르트")
		await say(["* 바이러스가 떠난 자리에 '요구르트'가 남아 있다. 얻었다.", "* (착한 세균과는 사이가 나쁜 모양이다.)"])


func ev_ch2_gate2(_a) -> void:
	await say([
		"* 핵으로 가는 길을 완두콩 무늬 문이 막고 있다.",
		"* '둥근 완두(Rr)끼리 교배했다. R은 둥근 모양(우성), r은 주름진 모양(열성).'",
	])
	var i: int = await choose("* 주름진 완두(rr)가 나올 확률은?", ["1/2", "1/4", "3/4"])
	if i == 1:
		sfx("correct")
		Game.set_flag("bio_gate2_open")
		main.world.refresh_actors()
		await say(["* 문이 콩깍지처럼 톡 하고 열렸다."])
		await solved("bio_gate2")
		return
	sfx("wrong")
	await say(["* 문이 꿈쩍도 하지 않는다. 대신 틈새로 무언가 기어 나왔다...!"])
	await battle("virus")
	await say(["나머지: Rr × Rr 이면 RR, Rr, Rr, rr 네 가지가 나와.", "나머지: 그중에 주름진 건 rr 하나뿐이야!"])


# ================================================================ 보스
func ev_ch2_phage(_a) -> void:
	await say([
		"???: 스캔 완료. 미등록 개체 1. 불완전 요소 1.",
		"파지 T4: 나는 박테리오파지 T4. 코어의 교정 담당입니다.",
		"파지 T4: 코어는 말했습니다. '오류 없는 유전자만이 완벽한 학생을 만든다.'",
		"파지 T4: 당신의 유전자에서 오차를 발견했습니다. 지금부터 교정합니다.",
		"나머지: 교정이라니, 지우겠다는 소리잖아!",
		"나머지: 다리가 내리꽂히기 전에 예고선이 보여. 선 위에 있으면 안 돼!",
	])
	var r: String = await battle("phage")
	Game.set_flag("phage_done")
	Game.set_flag("cert_bio")
	main.world.refresh_actors()
	if r == "spared":
		Game.set_flag("phage_spared")
		await say([
			"파지 T4: 코어에게 보고합니다. '변이는 오류가 아님.'",
			"파지 T4: ...보고가 거부되었습니다. 코어는 듣지 않습니다.",
			"파지 T4: 그렇다면 당신이 직접 전해 주십시오. 생명 인증을 발급합니다.",
		])
		await memory([
			"생명과학 강의실 창가. 1학년 첫 실험, 강낭콩 키우기.",
			"다른 화분은 다 싹이 났는데 한 화분만 2주째 조용했다.",
			"'실패네. 버리자.' 누군가 말했을 때, 화분 주인은 고개를 저었다.",
			"매일 아침 물을 주고 관찰 일지에 '변화 없음'이라고 썼다. 열네 번.",
			"열다섯 번째 아침, 흙이 살짝 갈라져 있었다.",
			"관찰 일지의 마지막 줄: '늦게 나와도 싹은 싹이다.'",
		])
	else:
		Game.set_flag("phage_killed")
		await say(["* 세포 속이 고요해졌다.", "* 육각형 조각들 사이에 무언가 떨어져 있다."])
	sfx("save")
	await say(["* '생명 인증'을 얻었다!"])
	await goto("f4_hall", "from_bio")
	await say([
		"* 현미경에서 눈을 떼자, 원래 크기로 돌아와 있었다.",
		"나머지: 휴... 다시는 작아지고 싶지 않아.",
		"나머지: 다음은 3층. 도서관이 있는 층이야.",
	])
	objective("중앙 홀 계단으로 3층에 내려가자.")
	save()


# ================================================================ 4층 이스터에그
func ev_f4_yogurt(_a) -> void:
	if Game.flag("got_f4_yogurt"):
		await say(["* 요구르트가 있던 사물함이다. 유산균 냄새만 남았다."])
		return
	Game.set_flag("got_f4_yogurt")
	give("요구르트")
	await say(["* 이 사물함은 살짝 열려 있다. 안에 요구르트가 줄 맞춰 서 있다.", "* '생명과학 발효 실험용. 손대지 마시오.'", "* ...'요구르트'를 얻었다. 실험에 협조한 것이다."])


func ev_mac_log(_a) -> void:
	await say([
		"* 이 아이맥만 화면 보호기가 꺼져 있다. 터미널 창이 열려 있다.",
		"[ log 03-02 ] 요청자: 교장.  '완벽한 학교를 계산해 줘.'",
		"[ log 03-02 ] 코어: '완벽'의 정의를 입력하십시오.",
		"[ log 03-02 ] 요청자: '아무도 뒤처지지 않는 것. 아무도 틀리지 않는 것.'",
		"[ log 10-06 ] 코어: 계산 완료. 틀리는 것을 전부 제거하면 됩니다.",
		"* 로그는 여기서 끊겨 있다.",
	])
	if not Game.flag("read_mac_log"):
		Game.set_flag("read_mac_log")
		Game.logic += 1
		await say(["* 사건의 실마리를 읽었다. 논리가 1 올랐다."])


func ev_karaoke(_a) -> void:
	await say(["* 노래방 기계가 켜져 있다. 화면에 '아무 번호나 누르세요'라고 떠 있다."])
	var i: int = await choose("* 한 곡 부를까?", ["교가를 부른다", "아무거나 열창한다", "참는다"])
	if i == 2:
		return
	sfx("heal")
	Game.hp = Game.max_hp
	if i == 0:
		await say(["* 당신은 교가를 4절까지 불렀다.", "* 점수: 61점. '음정은 틀렸지만 애교심이 느껴집니다.'", "* 속이 후련하다. HP가 모두 회복되었다."])
	else:
		await say(["* 당신은 목이 터져라 불렀다.", "* 점수: 37점. '완벽과는 거리가 멉니다. 그런데 신나네요.'", "* 속이 후련하다. HP가 모두 회복되었다."])
	if not Game.flag("sang_once"):
		Game.set_flag("sang_once")
		Game.emotion += 1
		await say(["* 완벽하지 않아도 즐거웠다. 감성이 1 올랐다."])
