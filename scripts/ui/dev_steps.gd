extends RefCounted
## 개발자 모드: 이야기 진행 단계표.
##
## 한 단계 = 지금 해야 할 일 하나 (방 이동, 퍼즐, 보스 등).
##   "n"    메뉴에 보이는 이름
##   "ch"   그 단계를 하는 동안의 챕터 번호
##   "keys" 그 단계를 끝내면 켜지는 플래그 (이 플래그들이 다 켜져 있으면 '끝난 단계')
##   "at"   단계 시작 위치: [방 id, 스폰 이름] 또는 [방 id, [칸 x, 칸 y]]. "event" 가 있으면 그 이벤트를 대신 실행
##   "obj"  그 단계의 목표 문장 (메뉴 C 의 '목표')
##
## 개발자 메뉴 '진행 단계'에서 아무 단계로 가면: 그 앞 단계의 keys 는 모두 켜고, 그 단계부터 뒤의 keys 는 모두 끈다.
## 필드에서 F4 = 다음 단계, F5 = 이전 단계. 이야기 중에는 F4 = 남은 대사 건너뛰기, 전투 중에는 F4 = 바로 끝내기(살려 줌).
## 이야기를 고쳐서 플래그 이름이 바뀌면 여기도 같이 고친다.

const STEPS := [
	# ---------------------------------------------------------------- 1장
	{"n": "1장 · 프롤로그와 5층 복도", "ch": 1, "keys": ["met_namoji"], "at": [], "event": "prologue",
		"obj": "멀티디자인실을 나가자."},
	{"n": "1장 · S512 수학 강의실로", "ch": 1, "keys": ["ch1_started"], "at": ["f5_hall", "from_math"],
		"obj": "A동 → 중앙 홀 → S동 서쪽 끝, S512 수학 강의실에 들어가자."},
	{"n": "1장 · 집합의 방 입구 (공집합)", "ch": 1, "keys": ["forest_intro", "met_empty"], "at": ["forest_1", "from_hall"],
		"obj": "방 깊은 곳에서 방의 주인을 찾자."},
	{"n": "1장 · 돌문 퍼즐", "ch": 1, "keys": ["gate1_open", "solved_gate1"], "at": ["forest_1", [11, 5]],
		"obj": "방 깊은 곳에서 방의 주인을 찾자."},
	{"n": "1장 · 세 갈래 길 (벤 쌍둥이)", "ch": 1, "keys": ["met_venn", "solved_fork"], "at": ["forest_2", "from_forest1"],
		"obj": "방 깊은 곳에서 방의 주인을 찾자."},
	{"n": "1장 · 수열의 징검다리", "ch": 1, "keys": ["forest4_intro", "seq_open_0", "seq_open_1", "seq_open_2"], "at": ["forest_4", "from_forest2"],
		"obj": "징검다리의 빈칸을 채워 방 깊은 곳으로 건너가자."},
	{"n": "1장 · 보스: 외계인 BJ KIM", "ch": 1, "keys": ["owl_done", "cert_math", "owl_spared"], "at": ["forest_3", "from_forest2"],
		"obj": "방 깊은 곳에서 방의 주인을 찾자."},
	{"n": "1장 끝 · 중앙 홀 계단으로", "ch": 1, "keys": ["ch1_clear"], "at": ["f5_hall", "from_math"],
		"obj": "중앙 홀 계단으로 4층에 내려가자."},
	# ---------------------------------------------------------------- 2장
	{"n": "2장 · 4층 복도", "ch": 2, "keys": ["f4_intro"], "at": ["f4_hall", "from_up"],
		"obj": "분홍빛이 새는 생명과학 실험실로 가자."},
	{"n": "2장 · 세포 바깥쪽 (파리 떼)", "ch": 2, "keys": ["ch2_started", "bio_intro", "met_flies"], "at": ["bio_1", "from_hall"],
		"obj": "세포 깊은 곳, 핵을 찾아가자."},
	{"n": "2장 · 첫 번째 막 퍼즐", "ch": 2, "keys": ["bio_gate1_open", "solved_bio_gate1"], "at": ["bio_1", [11, 5]],
		"obj": "세포 깊은 곳, 핵을 찾아가자."},
	{"n": "2장 · 세포질 깊은 곳 (두 번째 막)", "ch": 2, "keys": ["met_butterfly", "bio_gate2_open", "solved_bio_gate2"], "at": ["bio_2", "from_bio1"],
		"obj": "세포 깊은 곳, 핵을 찾아가자."},
	{"n": "2장 · 세포 소기관 거리", "ch": 2, "keys": ["bio4_intro", "met_enzyme", "bio4_gate"], "at": ["bio_4", "from_bio2"],
		"obj": "세포 깊은 곳, 핵을 찾아가자."},
	{"n": "2장 · 보스: 핵 속의 파지", "ch": 2, "keys": ["phage_done", "cert_bio", "phage_spared"], "at": ["bio_3", "from_bio2"],
		"obj": "세포 깊은 곳, 핵을 찾아가자."},
	{"n": "2장 끝 · 중앙 홀 계단으로", "ch": 2, "keys": ["ch2_clear"], "at": ["f4_hall", "from_bio"],
		"obj": "중앙 홀 계단으로 3층에 내려가자."},
	# ---------------------------------------------------------------- 3장
	{"n": "3장 · 3층 복도", "ch": 3, "keys": ["f3_intro"], "at": ["f3_hall", "from_up"],
		"obj": "계단으로 2층에 내려가자. (도서관에 들러도 좋다)"},
	{"n": "3장 · 2층 복도", "ch": 3, "keys": ["f2_intro"], "at": ["f2_hall", "from_down"],
		"obj": "파란빛이 새는 단일광자 실험실로 가자."},
	{"n": "3장 · 암실 입구 (광자)", "ch": 3, "keys": ["ch3_started", "optics_intro", "met_photon"], "at": ["optics_1", "from_hall"],
		"obj": "암실 안쪽에서 이 층의 주인을 찾자."},
	{"n": "3장 · 암실 문 퍼즐", "ch": 3, "keys": ["optics_gate_open"], "at": ["optics_1", [11, 5]],
		"obj": "암실 안쪽에서 이 층의 주인을 찾자."},
	{"n": "3장 · 프리즘", "ch": 3, "keys": ["prism_done"], "at": ["optics_1", [17, 9]],
		"obj": "암실 안쪽에서 이 층의 주인을 찾자."},
	{"n": "3장 · 편광 복도", "ch": 3, "keys": ["optics3_intro", "met_photon2", "optics3_gate"], "at": ["optics_3", "from_optics1"],
		"obj": "암실 안쪽에서 이 층의 주인을 찾자."},
	{"n": "3장 · 보스: 렌즈", "ch": 3, "keys": ["lens_done", "cert_phys", "lens_spared"], "at": ["optics_2", "from_optics1"],
		"obj": "암실 안쪽에서 이 층의 주인을 찾자."},
	# ---------------------------------------------------------------- 4장
	{"n": "4장 · 기숙사 연결 데크로", "ch": 4, "keys": ["ch4_started"], "at": ["f2_hall", "from_phys"],
		"obj": "복도의 '기숙사 연결 데크' 문으로 가자."},
	{"n": "4장 · 점호 5분 전 기숙사 복도", "ch": 4, "keys": ["dorm_intro", "met_alarm"], "at": ["dorm_hall", "start"],
		"obj": "주T의 불빛을 피해 304호로 들어가자. (벽의 그늘에 숨을 수 있다)"},
	{"n": "4장 · 304호", "ch": 4, "keys": ["room_intro"], "at": ["dorm_room", "from_hall"],
		"obj": "오른쪽 위 내 침대에 눕자."},
	{"n": "4장 · 보스: 주T", "ch": 4, "keys": ["jut_done", "cert_dorm", "jut_spared"], "at": ["dorm_room", [9, 3]],
		"obj": "오른쪽 위 내 침대에 눕자."},
	# ---------------------------------------------------------------- 5장
	{"n": "5장 · 5층 옥상 계단으로", "ch": 5, "keys": ["ch5_started"], "at": ["f5_hall", "from_stairs"],
		"obj": "계단으로 5층까지 올라가, 중앙 홀의 옥상 계단으로 가자."},
	{"n": "5장 · 옥상", "ch": 5, "keys": ["roof_intro", "met_meteor"], "at": ["roof", "from_hall"],
		"obj": "옥상의 별자리판 세 개를 풀고 천문대 돔으로 들어가자."},
	{"n": "5장 · 별자리판 세 개", "ch": 5, "keys": ["board_0", "board_1", "board_2", "roof_open"], "at": ["roof", [12, 5]],
		"obj": "옥상의 별자리판 세 개를 풀고 천문대 돔으로 들어가자."},
	{"n": "5장 · 천문대 돔", "ch": 5, "keys": ["dome_intro"], "at": ["roof_dome", "from_roof"],
		"obj": "천문대 돔으로 들어가자."},
	{"n": "5장 · 보스: 천문 선생", "ch": 5, "keys": ["astro_done", "cert_astro", "astro_spared"], "at": ["roof_dome", [11, 8]],
		"obj": "천문대 돔으로 들어가자."},
	# ---------------------------------------------------------------- 6장
	{"n": "6장 · 2층 서버실로", "ch": 6, "keys": ["ch6_started"], "at": ["f2_hall", "from_up"],
		"obj": "계단으로 내려가 2층 서버실로 가자."},
	{"n": "6장 · 서버실 코어", "ch": 6, "keys": ["server_intro", "core_done", "core_spared"], "at": ["a2_server", "from_hall"],
		"obj": "서버실 가운데의 코어와 마주하자."},
	{"n": "6장 · 1층 복도", "ch": 6, "keys": ["f1_intro"], "at": ["f1_hall", "from_up"],
		"obj": "교장실로 들어가자. (들어가기 전에 별에서 저장해 두자)"},
	{"n": "6장 · 최종전: 교장실", "ch": 6, "keys": ["principal_done"], "at": ["a1_principal", "from_hall"],
		"obj": "교장실로 들어가자. (들어가기 전에 별에서 저장해 두자)"},
]


static func is_done(i: int) -> bool:
	for f in STEPS[i]["keys"]:
		if not Game.flag(f):
			return false
	return true


## 지금 단계 = 끝나지 않은 첫 단계
static func current() -> int:
	for i in STEPS.size():
		if not is_done(i):
			return i
	return STEPS.size() - 1


## i 번째 단계로 맞춘다: 앞 단계는 끝난 것으로, 그 단계부터는 안 한 것으로
static func apply(i: int) -> void:
	for k in STEPS.size():
		for f in STEPS[k]["keys"]:
			if k < i:
				Game.set_flag(f)
			else:
				Game.flags.erase(f)
	# 보스를 살려 줬다는 기록이 남아 있으면 그 반대(쓰러뜨림) 기록은 지운다
	for b in ["owl", "phage", "lens", "jut", "astro", "core"]:
		if Game.flag(b + "_spared"):
			Game.flags.erase(b + "_killed")
	Game.chapter = STEPS[i]["ch"]
	Game.objective = STEPS[i]["obj"]
	Game.hp = Game.max_hp
