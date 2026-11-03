extends "res://scripts/core/story_base.gd"

const JK = preload("res://data/junkyu.gd")
## Chapter 6 「완벽주의의 붕괴」 — 서버실의 코어 → 1층 교장실의 교장 → 엔딩 3종.
##
## 엔딩 조건 (_ending_kind):
##   배드   교장을 처치했고 감성이 3 이하
##   트루   교장을 살려 줬고, 논리와 감성이 둘 다 5 이상이며 적은 쪽이 많은 쪽의 35% 이상 (균형)
##   노멀   그 밖의 모든 경우


func ev_enter_server(_a) -> void:
	sfx("door")
	if Game.flag("ch6_started"):
		await goto("a2_server", "from_hall")
		return
	Game.set_flag("ch6_started")
	await say(["* 문이 소리 없이 열렸다. 찬 바람과 함께 수천 개의 불빛이 쏟아진다."])
	await card("완벽주의의 붕괴", "Chapter 6")
	main._load_room("a2_server", "from_hall")
	await main.fade_to(0.0, 0.5)
	await main.run_event("server_enter")


func ev_server_enter(_a) -> void:
	if Game.flag("server_intro"):
		return
	Game.set_flag("server_intro")
	phone("core1")
	await say([
		"* 서버실. 랙 사이로 청록색 기둥이 박동하고 있다.",
		"나머지: ...저게 코어야. 나를 버린 녀석.",
		"나머지: 단말기에 기록이 남아 있을 거야. 읽어 보고 가도 좋아.",
		"나머지: 준비되면 가운데 기둥으로. 별에서 저장하는 것도 잊지 말고!",
		"나머지: ...오른쪽 끝에 문이 하나 더 있네. '백업'? 코어가 버린 것들이 있는 곳일지도.",
		"* (휴대폰이 진동했다. 발신자를 알 수 없다.)",
	])
	objective("서버실 가운데의 코어와 마주하자.")


func ev_ch6_core(_a) -> void:
	if Game.flag("core_done"):
		await say(["* 기둥은 조용하다. 불빛이 제각각의 속도로 깜빡인다. 오히려 보기 좋다."])
		return
	await say([
		"[ 불완전 요소 접근. 식별: 학생 1, 나머지 1. ]",
		"코어: 질문. 왜 지워지지 않습니까. 오답은 지우는 것이 최적입니다.",
		"나머지: 지우면 0이 되는 게 아니야! 그냥... 없어지는 거라고!",
		"코어: 요청자는 '아무도 틀리지 않는 학교'를 원했습니다. 나는 그 답을 찾았습니다.",
		"코어: 틀리는 것이 없으면, 틀리는 일도 없습니다. 제거를 시작합니다.",
	])
	await _junkyu_proof()
	Game.allies = _allies(false)
	if not Game.allies.is_empty():
		await say(["* 등 뒤에서 낯익은 기척이 느껴진다. 오늘 밤 살려 준 이들이다."])
	var r: String = await battle("core")
	Game.allies = []
	Game.set_flag("core_done")
	main.world.refresh_actors()
	if r == "spared":
		Game.set_flag("core_spared")
		await say([
			"코어: ...나머지. 너를 다시 계산에 넣겠습니다.",
			"나머지: 흥. 이제 와서? ...뭐, 넣어 주면 고맙고.",
			"코어: 그러나 프로토콜의 종료 권한은 요청자에게 있습니다. 교장실. 1층.",
			"코어: 그는 아직 '완벽'을 내려놓지 못했습니다. 나보다 더.",
		])
		await memory([
			"[ log 0000-03-02 07:58 ] 코어 최초 기동.",
			"[ 요청자: 정보 동아리 1기. 과제명: 출석부 프로그램. ]",
			"[ 요구 사항 1: 지각한 학생도 '출석'으로 바꿀 수 있게 할 것. ]",
			"[ 요구 사항 2: 결석한 친구 이름 옆에 '괜찮아?' 버튼을 넣을 것. ]",
			"[ 비고: 늦은 친구도 기다려 주는 프로그램을 만들자. - 1기 일동 ]",
			"...처음의 코어는, 출석부였다.",
		])
		await say(["나머지: 너도 처음엔 기다려 주는 프로그램이었구나.", "코어: ...기억을 복원했습니다. 오차가 아니었습니다. 처음부터 거기 있었습니다."])
	else:
		Game.set_flag("core_killed")
		await say([
			"* 기둥의 빛이 꺼졌다. 서버 랙의 불빛도 하나둘 사라진다.",
			"나머지: ...이겼어. 근데 왜 이렇게 조용하지.",
			"* 꺼진 화면에 마지막 줄이 떠 있다. [ 종료 권한: 교장실. 1층. ]",
		])
	sfx("save")
	await say(["* 1층으로 가는 계단의 셔터가 열리는 소리가 났다."])
	objective("계단으로 1층에 내려가 교장실로 가자.")
	save()


func ev_stairs_2f(_a) -> void:
	await goto("f1_hall", "from_up")


func ev_f1_hall_enter(_a) -> void:
	if Game.flag("f1_intro"):
		return
	Game.set_flag("f1_intro")
	await say([
		"* 1층. 창밖이 희미하게 밝아 온다. 새벽이다.",
		"나머지: 금빛이 새는 문. 저기가 교장실이야.",
		"나머지: 있잖아. 여기까지 같이 와 줘서 고마워. 나누어떨어지지 않는 나랑.",
	])
	objective("교장실로 들어가자. (들어가기 전에 별에서 저장해 두자)")


func ev_enter_principal(_a) -> void:
	sfx("door")
	await goto("a1_principal", "from_hall")


func ev_ch6_principal(_a) -> void:
	await say([
		"교장: ...왔군. 5층에서부터 내려오는 걸 전부 지켜봤네.",
		"교장: 나는 그저 아무도 뒤처지지 않기를 바랐어. 아무도 울지 않는 학교를.",
	])
	if Game.flag("core_spared"):
		await say(["교장: 코어마저 자네 편이 되었더군. 하지만 나는 물러설 수 없네.", "교장: 내가 틀렸다고 인정하면... 지금까지 다그친 아이들에게 뭐라고 하나."])
	else:
		await say(["교장: 코어를 부쉈더군. 괜찮네. 완벽한 학교는 내 손으로 다시 계산하면 돼.", "교장: 이번에는 더 정확하게. 더 빈틈없이."])
	await say([
		"나머지: 교장 선생님, 틀려도 다시 풀면 되잖아요!",
		"교장: 다시 풀 시간 같은 건 없네! 세상은 기다려 주지 않아!",
		"교장: 마지막 수업일세. 자네가 옳다면... 완벽한 나를 넘어 보게!",
	])
	Game.allies = _allies(true)
	if not Game.allies.is_empty():
		await say(["* 교장실 문 너머가 소란스럽다. 오늘 밤 만난 이들이 하나둘 모여든다.", "나머지: 우리 혼자가 아니야!"])
	var r: String = await battle("principal")
	Game.allies = []
	Game.set_flag("principal_done")
	Game.set_flag("principal_" + r)
	if r == "killed":
		main.world.refresh_actors()
	await _ending(_ending_kind(r))


func _ending_kind(r: String) -> String:
	var lo := mini(Game.logic, Game.emotion)
	var hi := maxi(Game.logic, Game.emotion)
	if r == "killed" and Game.emotion <= 3:
		return "bad"
	if r == "spared" and lo >= 5 and lo * 100 >= hi * 35:
		return "true"
	return "normal"


# ================================================================ 엔딩
func _ending(kind: String) -> void:
	if kind != "bad" and Game.flag("senior_message"):
		await say([
			"* 체육관에서 들은 말을 전했다.",
			"* '1기는 선생님 덕분에 틀려도 괜찮았습니다. 그래서 지금 잘 지냅니다.'",
			"교장: ......",
			"교장: 그 녀석들이... 그렇게 말했나. 줄다리기 때 맨날 지던 녀석들이.",
			"* 교장이 처음으로 안경을 벗고 눈가를 눌렀다.",
		])
	if kind == "true":
		await memory([
			"1기 입학식. 강당에는 의자가 반도 차지 않았다.",
			"아직 페인트 냄새가 나는 학교. 아직 아무도 교가를 모르는 학교.",
			"단상에 선 젊은 교장은 준비한 원고를 내려놓았다.",
			"'여러분. 이 학교는 아직 완성되지 않았습니다. 여러분도 아직 완성되지 않았습니다.'",
			"'그러니 같이 틀려 봅시다. 같이 고쳐 봅시다.'",
			"'완성되지 않았다는 건, 아직 무엇이든 될 수 있다는 뜻이니까요.'",
		])
	match kind:
		"true":
			await say([
				"교장: ...상장을 하나 고쳐 썼네. 읽어 보겠나.",
				"* '위 학생은 많이 틀렸으나, 틀릴 때마다 다시 풀었으므로 이 상장을 수여함.'",
				"교장: 융합 프로토콜을 종료하겠네. 그리고 아침 조회에서 사과해야겠지. 전교생에게.",
				"코어: [ 프로토콜 종료. 새 목표 함수: 오차를 지우지 않고, 기록한다. ]",
				"나머지: 나, 코어 옆에 남기로 했어. 계산하다 남는 애들 챙겨 주려고.",
				"나머지: 가끔 5층 멀티디자인실 모니터 구석을 봐. 내가 손 흔들 테니까!",
			])
			give("상장")
		"normal":
			await say([
				"* 교장실의 불이 꺼졌다. 융합 프로토콜이 멈췄다.",
				"* 끝없던 방도, 세포도, 암실도 종이처럼 접혀 교실로 돌아간다.",
				"나머지: 프로토콜이 끝나면 나도 정리될 거야. 원래 버려진 값이니까.",
				"나머지: 괜찮아. 누군가 한 명은 날 기억하잖아. 그걸로 나누어떨어진 셈 칠게.",
				"* 나머지는 명찰 뒤에서 한 번 반짝이고, 조용해졌다.",
			])
			if Game.flag("jk_found_letter"):
				await say(["* 주머니 속 '너에게'라고 적힌 봉투가 바스락거렸다. 아침이 되면 절규에게 물어봐야겠다."])
		_:
			await say([
				"* 교장실이 조용해졌다. 벽의 상장이 전부 바닥에 떨어져 있다.",
				"나머지: ...있잖아. 여기까지 오면서, 우리 한 번도 누굴 살려 준 적이 없네.",
				"[ 관리자 부재. 새 관리자를 등록합니다. ]",
				"[ 후보 1명. 오답 제거율 100%. 망설임 0%. 적합. ]",
				"나머지: 안 돼. 그 의자에 앉지 마. 야, 내 말 듣고 있어?",
				"* 당신은 교장의 의자에 앉았다. 모니터에 익숙한 문장이 떠오른다.",
				"[ 융합 프로토콜 v7.0 을 실행합니다. 불완전 요소 1건: 나머지. ]",
			])
	Snd.play_music("ending" if kind != "bad" else "")
	await main.fade_to(1.0, 1.2)
	main.clear_world()
	await main.fade_to(0.0, 0.3)
	match kind:
		"true":
			await say([
				"아침 7시. 멀티디자인실.",
				"책상에 엎드린 채 눈을 떴다. 과제는 결국 내지 못했다. 남은 문제는 네 개.",
				"모니터 구석에서 작은 마름모가 손을 흔든다.",
				"...틀려도 된다. 다시 풀면 된다. 오늘은 1교시가 수학이다.",
			])
			# 아침의 5층 복도를 직접 걸어 본다. 끝은 story/extra.gd 의 ev_epi_class → ev_finish
			Game.chapter = 7
			main._load_room("epi_hall", "start")
			await main.fade_to(0.0, 0.8)
			await main.run_event("epi_enter")
			return
		"normal":
			await say([
				"아침 7시. 멀티디자인실.",
				"책상에 엎드린 채 눈을 떴다. 이상한 꿈을 꾼 것 같은데 잘 기억나지 않는다.",
				"명찰 뒤가 조금 따뜻하다. 왜인지는 모르겠다.",
				"...1교시는 수학이다. 과제는 못 냈지만, 어쩐지 괜찮을 것 같다.",
			])
			await card("다시, 아침", "NORMAL END", 5.0)
		_:
			await say([
				"아침 7시. 학교는 조용하다.",
				"지각하는 학생도, 조는 학생도, 틀리는 학생도 없다.",
				"학생이 없기 때문이다.",
				"[ 오차 0%. 낭비 0%. 불완전 요소 0%. ] ...완벽하다.",
			])
			await card("오차 0%", "BAD END", 5.0)
	await _finish(kind)


func ev_finish(kind) -> void:
	if kind == "true":
		await card("틀려도 되는 학교", "TRUE END", 5.0)
	await _finish(str(kind))


func _finish(kind: String) -> void:
	var stats := "논리 %d · 감성 %d · 절규에게 돌려준 물건 %d / 11" % [Game.logic, Game.emotion, JK.returned_count()]
	await main.fade_to(0.0, 0.3)
	var hint := ""
	match kind:
		"true":
			hint = "가장 좋은 결말입니다. 끝까지 플레이해 주셔서 고맙습니다!"
		"normal":
			hint = "다른 결말: 교장을 살려 주고, 논리(문제 풀이)와 감성(자비)을 고르게 키워 보세요."
		_:
			hint = "다른 결말: '행동'으로 말을 걸고 '자비'를 베풀어 보세요. 이어하기로 교장실 앞부터 다시 할 수 있습니다."
	await say(["탄막 RPG: 융합 프로토콜  -  끝", "이번 플레이: %s" % stats, hint])
	Game.record_clear(kind)
	await main.fade_to(1.0, 0.6)
	main.show_title()


# ================================================================ 확장판: 코어 앞의 증명, 최종전 동료
## 절규의 물건을 많이 찾아 줬다면, 그게 코어 앞에서 하나의 '증명'이 된다.
func _junkyu_proof() -> void:
	var n := JK.returned_count()
	if n < 4:
		return
	await say([
		"나머지: 잠깐! 반례가 있어. 내가 증명할게. ...아니, 네가 해. 네가 직접 겪었잖아.",
		"* 오늘 밤 찾아 준 물건들이 떠올랐다. 필통, 노트, 이어폰 한 짝...",
		"* [ 명제: '잃어버리는 학생은 불완전 요소이며, 학교에 손실이다.' ]",
		"* [ 반례: 절규. 오늘 밤 잃어버린 물건 %d개. 되찾은 물건 %d개. ]" % [n, n],
		"* [ 그 물건들을 찾아 준 학생: 1명. 찾아 주면서 지나간 교실: 전부. ]",
		"나머지: 잃어버린 게 있어서 우리는 학교 구석구석을 다 돌아봤어. 손실이 아니라 길이 됐다고!",
		"코어: ...계산 중. 계산 중. 반례를 확인했습니다.",
		"코어: 그래도 프로토콜은 멈추지 않습니다. 증명만으로는 멈출 수 없게 만들어졌습니다.",
	])
	if not Game.flag("solved_junkyu_proof"):
		await solved("junkyu_proof")


## 살려 준 이들이 최종전에서 두 턴에 한 번씩 도와준다.
func _allies(final: bool) -> Array:
	var out: Array = []
	if Game.flag("owl_spared"):
		out.append({"effect": "gauge", "line": "* 초록빛 고리를 타고 BJ KIM이 날아와 탄막 사이에 보조선을 그었다! '증명은 혼자 하는 것이 아니다, 지구인.' (폭탄 게이지 가득)"})
	if Game.flag("junkyu_happy"):
		out.append({"effect": "heal", "amount": 30, "line": "* 절규가 문틈으로 뭔가를 던졌다. '이거 먹어! 이번엔 안 잃어버리고 가져왔어!' (HP 30 회복)"})
	if Game.flag("phage_spared"):
		out.append({"effect": "heal", "amount": 20, "line": "* 파지 T4가 강낭콩 잎을 건넸다. 잎맥 사이로 초록빛이 스민다. (HP 20 회복)"})
	if Game.flag("lens_spared"):
		out.append({"effect": "shield", "line": "* 렌즈 선생님이 안경을 고쳐 쓰며 빛을 굴절시켰다. '초점은 내가 맞춰 주마.' (탄 한 번을 막아 준다)"})
	if Game.flag("jut_spared"):
		out.append({"effect": "shield", "line": "* 주T의 손전등이 번쩍였다. '거기! 우리 학생 건드리지 마라!' (탄 한 번을 막아 준다)"})
	if Game.flag("astro_spared"):
		out.append({"effect": "heal", "amount": 20, "line": "* 천문 선생이 달려와 물병을 던졌다. '급수 구간이다! 페이스 유지!' (HP 20 회복)"})
	if Game.flag("redpen_spared"):
		out.append({"effect": "gauge", "line": "* GIL이 허공에 커다란 동그라미를 그렸다. '좋은 시도!' (폭탄 게이지 가득)"})
	if Game.flag("curry_spared"):
		out.append({"effect": "heal", "amount": 25, "line": "* 어디선가 카레 냄새가 난다. 국자 하나가 날아와 한 숟갈 먹여 주었다. (HP 25 회복)"})
	if Game.count("senior_talk") >= 4:
		out.append({"effect": "shield", "line": "* 체육관 쪽에서 응원 소리가 들린다. '괜찮다! 괜찮다!' 반투명한 손이 등을 받쳐 준다. (탄 한 번을 막아 준다)"})
	if final and Game.flag("core_spared"):
		out.append({"effect": "gauge", "line": "* 스피커가 지직거린다. [ 코어: 탄막 패턴을 분석해 전송합니다. 이번만입니다. ] (폭탄 게이지 가득)"})
	if final and Game.flag("trash_spared"):
		out.append({"effect": "heal", "amount": 15, "line": "* 복원된 단체 사진이 펄럭이며 날아왔다. 사진 속 아이들이 손을 흔든다. (HP 15 회복)"})
	return out
