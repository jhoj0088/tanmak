extends "res://scripts/core/story_base.gd"
## Chapter 1 「집합과 명제의 방」
## 프롤로그 → 5층 복도 → 방(공집합, 돌문, 벤 쌍둥이, 세 갈래 길, 수열 다리) → 외계인 BJ KIM → 계단


# ================================================================ 프롤로그
func ev_prologue(_a) -> void:
	Snd.stop_music()
	await main.fade_to(0.0, 0.1)        # 아직 방이 없어서 화면은 검다
	await say([
		"세종시의 어느 과학예술영재학교.",
		"밤 11시 20분. A동 5층 멀티디자인실(A507).",
		"과제 마감은 자정. 남은 문제는 네 개.",
		"...눈꺼풀이 무겁다.",
	])
	sfx("warn")
	await say([
		"[ 융합 프로토콜 v6.0 을 실행합니다. ]",
		"[ 목표 : 오차 0%. 낭비 0%. 불완전 요소 0%. ]",
		"[ 전 과목을 하나로 융합합니다... ]",
		"[ ...오류. 오류. 오류. ]",
	])
	await main.fade_to(1.0, 0.1)
	main._load_room("s5_multimedia", "start")
	await main.fade_to(0.0, 1.2)
	await say([
		"* ...깜빡 잠들었다.",
		"* 모니터가 전부 같은 화면을 띄우고 있다.",
		"* (패드로 이동, Z 버튼으로 조사, C 버튼으로 메뉴를 연다.)" if Touch.enabled else "* (방향키로 이동, Z로 조사, C로 메뉴를 열 수 있다.)",
	])
	objective("멀티디자인실을 나가자.")
	save()
	phone("mom1")


# ================================================================ 5층 복도
func ev_f5_hall_enter(_a) -> void:
	if Game.flag("met_namoji"):
		return
	Game.set_flag("met_namoji")
	await wait(0.3)
	await say([
		"???: 우왓, 사람이다! 아직 안 지워진 사람!",
		"???: 아, 놀랐어? 미안. 난 '나머지'야.",
		"나머지: 메인 서버 〈코어〉가 학교를 '완벽하게' 다시 계산했거든.",
		"나머지: 근데 난 나누어떨어지지 않아서... 버려졌어. 그래서 나머지.",
		"나머지: 지금 학교는 과목들이 뒤섞여서 살아 움직여. 코어는 그걸 '융합'이라고 불러.",
		"나머지: 계단은 셔터로 막혔어. 층마다 '과목 인증'을 받아야 열린대.",
		"나머지: 5층의 과목은 수학! 초록빛이 새는 'S512 수학 강의실'로 가 보자.",
		"나머지: 여긴 A동이야. 이 비스듬한 복도를 따라 중앙 홀까지 내려가서, S동 복도를 서쪽 끝까지 쭉 가면 돼.",
		"나머지: 길을 모르겠으면 오른쪽 위 지도를 봐. 빨간 점이 너야.",
		"* 나머지는 당신의 명찰 뒤로 쏙 숨었다.",
	])
	main.world.refresh_actors()
	objective("A동 → 중앙 홀 → S동 서쪽 끝, S512 수학 강의실에 들어가자.")


func ev_enter_math(_a) -> void:
	sfx("door")
	if Game.flag("cert_math"):
		await goto("s5_math_class", "from_hall")
		return
	if Game.flag("ch1_started"):
		await goto("forest_1", "from_hall")
		return
	Game.set_flag("ch1_started")
	await say([
		"* 문을 열자 분필 냄새와 풀 냄새가 같이 났다.",
		"* ...교실이 끝없이 넓어져 있다. 책상 사이로 벤 다이어그램 나무가 자라고, 천장이 보이지 않는다.",
	])
	await card("집합과 명제의 방", "Chapter 1")
	main._load_room("forest_1", "from_hall")
	await main.fade_to(0.0, 0.5)
	await main.run_event("ch1_forest1_enter")


func ev_stairs_5f(_a) -> void:
	if not Game.flag("ch1_clear"):
		Game.set_flag("ch1_clear")
		await say(["* 셔터가 올라가 있다.", "* 아래층에서 벌레 우는 소리가 올라온다..."])
		await card("Chapter 1 클리어", "집합과 명제의 방")
		Game.chapter = 2
		main._load_room("f4_hall", "from_up")
		await main.fade_to(0.0, 0.5)
		await say(["[ 코어 : 수학 인증 확인. 불완전 요소 1건이 4층으로 이동 중. ]", "나머지: ...들켰네. 그래도 가야지!"])
		phone("mom2")
		await main.run_event("f4_hall_enter")
		save()
		return
	await goto("f4_hall", "from_up")


# ================================================================ 방 입구
func ev_ch1_forest1_enter(_a) -> void:
	if Game.flag("forest_intro"):
		return
	Game.set_flag("forest_intro")
	await say([
		"나머지: 우와... 수학 강의실이 끝이 없어졌어.",
		"나머지: 저 나무들 봐. 잎이 전부 벤 다이어그램이야.",
		"나머지: 이 방의 주인한테 '수학 인증'을 받으면 계단이 열릴 거야.",
	])
	objective("방 깊은 곳에서 방의 주인을 찾자.")


## 첫 전투 (튜토리얼): 공집합
func ev_ch1_empty(_a) -> void:
	await say([
		"* 텅 빈 무언가가 길을 막았다!",
		"나머지: 잠깐! 싸움이 시작되면 네 마음은 빨간 하트가 돼.",
		"나머지: 탄이 날아오면 방향키로 피해. Shift(S 버튼)를 누르면 천천히, 정밀하게 움직여.",
		"나머지: 그리고... 꼭 때려야 하는 건 아니야.",
		"나머지: '행동'으로 말을 걸다 보면 이름이 노랗게 변해. 그때 '자비'를 고르면 돼!",
	])
	var r: String = await battle("empty_set")
	match r:
		"spared":
			await say(["나머지: 봤지? 싸우지 않아도 끝낼 수 있어.", "나머지: 자비를 베풀면 '감성'이 올라. C 키 메뉴에서 볼 수 있어."])
		"killed":
			await say(["나머지: ...이겼네. 싸워서 이기면 '논리'가 올라.", "나머지: 틀린 방법은 아니야. 그냥, 조금 쓸쓸해서."])
		_:
			await say(["나머지: 도망도 훌륭한 전략이지! 살아남는 게 먼저야."])


## 돌문: 이산수학 집합 문제 (S = {1..30} 의 부분집합 X 세기)
## 정답 42,698,076 = 2^30 개의 부분집합을 모두 확인해서 센 값 (공집합 포함). 1번 보기.
func ev_ch1_gate1(_a) -> void:
	await say([
		"* 돌문 가득 문제가 새겨져 있다. 맨 위에 '이산수학 - 2025' 라는 낙서.",
		"* 'S = {x | x 는 30 이하의 자연수} 에 대하여, S 의 부분집합 X 가'",
		"* 'X = {x | x ∈ X 이면 x + 1 ∈ X 또는 x - 1 ∈ X 또는 2x ∈ X}'",
		"* '를 만족시킨다. 이러한 집합 X 의 개수는?'",
	])
	var i: int = await choose("* 정답은?", ["1개", "42,698,076개", "2의 30제곱 개 (1,073,741,824개)"])
	if i == 0:
		sfx("correct")
		Game.set_flag("gate1_open")
		main.world.refresh_actors()
		await say([
			"* 돌문이 '참!' 하고 외치더니 스르르 사라졌다.",
			"나머지: 어떻게 알았어? ...아, 조건이 'x ∈ X 이면 ...' 꼴이구나.",
			"나머지: 어떤 x 가 X 에 없다고 해 봐. 그럼 'x ∈ X 이면 ...'은 가정이 거짓이니까 무조건 참이야.",
			"나머지: 조건을 만족했으니 x 는 X 에 들어가야 해. 그런데 없다고 했잖아. 모순!",
			"나머지: 그러니까 S 의 원소는 전부 X 에 있어. X = S 하나뿐. 30 옆에도 29 가 있으니 S 는 조건을 진짜로 지키고.",
		])
		await solved("gate1")
		return
	sfx("wrong")
	Game.add_count("gate1_wrong")
	await say(["* 돌문이 '거짓!' 하고 외쳤다.", "* 그때 책상 사이 어둠 속에서 크고 동그란 빨간 안경이 번쩍였다."])
	await say([
		"GIL: 틀렸네요. 채점하기 딱 좋은 답이에요.",
		"GIL: 힌트 하나만 줄게요. X 를 '조건제시법'으로 적었죠? 그럼 X 는 그 조건을 만족하는 원소를 '전부' 모은 집합이에요.",
	])
	if i == 1:
		await say(["GIL: 그 숫자는 '원소마다 x ± 1 이나 2x 가 같이 들어 있는 부분집합'을 센 거예요. 그것도 공들인 답이지만, 문제는 그게 아니에요.",
			"GIL: X 에 없는 원소 x 를 하나 골라 봐요. 'x ∈ X 이면 ...' 은 그 x 에 대해 참일까요, 거짓일까요?"])
	else:
		await say(["GIL: 2의 30제곱은 부분집합 전부예요. 그 집합들이 다 'X = {x | ...}' 를 만족할까요?",
			"GIL: 가정이 거짓인 '이면' 명제는... 늘 참이었죠. 그걸 X 밖의 원소에 적용해 봐요."])
	await say(["* GIL은 빨간펜으로 허공에 동그라미 반쪽을 그리고 어둠 속으로 사라졌다.", "나머지: ...방금 그 선생님, 5층 교무실에서 본 것 같은데."])


func ev_ch1_acorn(_a) -> void:
	Game.set_flag("got_acorn")
	main.world.refresh_actors()
	give("논리")
	sfx("heal")
	await say(["* 벤 다이어그램 나무 밑에서 ⇒ 모양으로 반짝이는 것을 주웠다.", "* '논리'를 얻었다."])


# ================================================================ 세 갈래 길
## 두 번째 전투: 벤 쌍둥이 (그레이즈와 폭탄)
func ev_ch1_venn(_a) -> void:
	await say([
		"* 겹쳐진 두 개의 원이 굴러왔다!",
		"나머지: 이번엔 '그레이즈'를 알려 줄게.",
		"나머지: 탄을 아슬아슬하게 스치면 '집중' 게이지가 차올라.",
		"나머지: 게이지가 절반을 넘으면 X 키로 '폭탄'! 화면의 탄이 전부 사라져.",
		"나머지: 게이지가 높을수록 '싸운다'의 위력도 세져. 겁내지 말고 탄 가까이 붙어 봐!",
	])
	var r: String = await battle("venn")
	if r == "spared":
		await say(["나머지: 저 둘, 스치듯 다가오는 걸 좋아하더라. 교집합 같은 애들이야."])
	elif r == "killed":
		await say(["나머지: 서로소가 되어 버렸네..."])


func ev_ch1_swan_pond(_a) -> void:
	await say(["* 연못가에서 검은 백조가 이쪽을 노려본다.", "* '모든 백조는 희다'고 말하면 큰일 날 것 같다."])
	var i: int = await choose("* 어떻게 할까?", ["\"모든 백조는 희다!\"", "조용히 지나간다"])
	if i == 1:
		return
	var r: String = await battle("swan")
	if r == "fled":
		return
	Game.set_flag("pond_swan_done")
	main.world.refresh_actors()
	if r == "spared":
		give("바나나우유")
		await say(["* 반례가 떠난 자리에 '바나나우유'가 떠 있다. 얻었다.", "* (백조가 왜 이걸 갖고 있었는지는 증명되지 않았다.)"])


## 세 갈래 길: 참인 표지판은 하나뿐
func ev_ch1_fork(d) -> void:
	var which: int = d["which"]
	if which == 2:
		sfx("correct")
		await say(["* 표지판들이 일제히 '참!' 하고 외쳤다.", "* 길이 방 깊은 곳으로 이어진다."])
		await solved("fork")
		await goto("forest_4", "from_forest2")
		return
	sfx("wrong")
	var n := Game.add_count("fork_wrong")
	await say(["* 한참을 걸었는데...", "* 길이 빙글 돌아 제자리로 돌아왔다. 이 길은 거짓이었다."])
	await goto("forest_2", "fork_back")
	if n == 1:
		await say(["* 틀린 길에서 무언가가 따라왔다...!"])
		await battle("swan")
	if n >= 2:
		await say([
			"나머지: 힌트! 길 하나를 '진짜'라고 가정해 봐.",
			"나머지: 그때 참이 되는 표지판이 딱 하나인지 세어 보는 거야.",
			"나머지: 둘이 참이 되면? 그 가정은 틀린 거지.",
		])


# ================================================================ 보스
func ev_ch1_owl(_a) -> void:
	await say([
		"* 칠판 앞에 초록빛 고리가 떠 있다. 그 위에 정장을 입은 무언가가 서 있다. 얼굴에... 눈이 없다.",
		"???: 지구인. 발소리로 알았다. 여기까지 온 학생은 오랜만이다.",
		"BJ KIM: 나는 BJ KIM. 안드로메다 237번 행성에서 왔다. 나에게는 시각이 없다.",
		"BJ KIM: 지구에 와서 집합을 배웠고, 함수를 배웠고, 일대일 대응을 배웠다. 모두 눈 없이 이해할 수 있었다.",
		"BJ KIM: 그런데 하나가 남았다. 지구인들이 '대칭'이라 부르는 것. 내 방문 일지의 마지막 빈칸이다.",
		"BJ KIM: 코어는 말했다. '증명되지 않은 것은 통과시키지 말라.' 너의 명제를 보여 줘라. 그리고... 나에게 대칭을 알려 줘라.",
		"나머지: 조심해! 파란 탄은 '참'이야. 가만히 멈춰 있으면 통과해.",
		"나머지: 주황 탄은 '거짓'. 움직이고 있으면 통과해! 헷갈리면 X로 폭탄!",
	])
	var r: String = await battle("owl")
	Game.set_flag("owl_done")
	Game.set_flag("cert_math")
	main.world.refresh_actors()
	if r == "spared":
		Game.set_flag("owl_spared")
		await say([
			"BJ KIM: ...대우도, 충분조건도, 부정도 흠잡을 데가 없다. 그리고 대칭까지.",
			"BJ KIM: 코어는 '완벽한 것만이 가치 있다'고 한다. 하지만 나는 눈이 없어도 대칭을 알게 되었다.",
			"BJ KIM: 없는 것이 있어도, 다른 길로 닿을 수 있다. 그 명제의 반례가 바로 너와 나다.",
			"BJ KIM: 받아라. 수학 인증이다. 증명 끝. Q.E.D.",
		])
		await memory([
			"서기 2025년 어느 날. BJ KIM 의 '지구 방문 일지'.",
			"'지구인들은 자꾸 무언가를 보고 대칭이라 한다. 나비, 눈송이, 얼굴. 나는 볼 수 없다.'",
			"'나는 집합을 안다. 함수를 안다. 일대일 대응을 안다. 그것으로 대칭을 알 수 있을까.'",
			"그날 시험지 한 장에 적힌 답. '대칭이란, 대상을 자기 자신에게 보내는 일대일 대응 중에서 그 대상을 바꾸지 않는 것.'",
			"BJ KIM 은 그 문장을 더듬이로 천천히 읽었다. 세 번, 네 번.",
			"일지의 빈칸 옆에 처음으로 이렇게 적혔다. '보지 않아도 된다. 옮겨 보고, 그대로인지 세어 보면 된다.'",
		])
	else:
		Game.set_flag("owl_killed")
		await say([
			"* 방이 조용해졌다.",
			"* 흩어진 초록빛 점들 사이에서 무언가 빛나고 있다.",
			"나머지: ......가자.",
		])
	sfx("save")
	await say(["* '수학 인증'을 얻었다!"])
	await goto("s5_math_class", "after_boss")
	await say([
		"* 끝없던 방이 종이처럼 접히더니, 익숙한 교실이 돌아왔다.",
		"나머지: 해냈다! 이제 계단 셔터가 열렸을 거야.",
		"나머지: 다음은 4층... 생명과학 실험실 쪽이 소란스러워.",
	])
	objective("중앙 홀 계단으로 4층에 내려가자.")
	save()
