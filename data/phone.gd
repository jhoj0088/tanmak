extends RefCounted
## 휴대폰 메시지. 이야기 중에 phone("아이디") 로 받는다. 메뉴(C) → 휴대폰 탭에서 다시 읽을 수 있다.

const ORDER := ["mom1", "jk1", "mom2", "teacher1", "jk2", "sis1", "mom3", "jk3", "room1", "mom4", "core1", "all1"]

const MSG := {
	"mom1": {"from": "엄마", "time": "21:03", "text": "야자 끝나면 바로 들어가. 저녁 꼭 챙겨 먹고. 매점 빵 말고 밥."},
	"jk1": {"from": "절규", "time": "23:31", "text": "야 혹시 내 필통 봤냐ㅠㅠ 하늘색 곰 달린 거"},
	"mom2": {"from": "엄마", "time": "23:52", "text": "자니? 이번 주말에 반찬 보낼게. 너 좋아하는 멸치볶음."},
	"teacher1": {"from": "담임 선생님", "time": "00:14", "text": "R&E 중간 발표 자료 내일까지. 완벽하지 않아도 되니까 낸다는 게 중요하다."},
	"jk2": {"from": "절규", "time": "00:37", "text": "나 지금 학교 안인데 뭔가 이상해. 복도에 벌레가 사람만 해. 너 어디야?"},
	"sis1": {"from": "동생", "time": "01:02", "text": "언제 와? 이번에 오면 저번에 약속한 거 하자. 까먹지 마."},
	"mom3": {"from": "엄마", "time": "01:40", "text": "거기 오늘 밤 하늘 맑대. 공부하다 힘들면 창밖 한 번 봐. 별은 점수 안 매겨."},
	"jk3": {"from": "절규", "time": "02:15", "text": "점호 걸리면 내 이름 대ㅋㅋ 나 이미 벌점 많아서 하나 더 받아도 티 안 남"},
	"room1": {"from": "기숙사 공지", "time": "02:30", "text": "[자동 발송] 304호 점호 미응답 2명. 사감실로 연락 바랍니다."},
	"mom4": {"from": "엄마", "time": "03:58", "text": "갑자기 깼는데 네 생각이 나서. 힘들면 힘들다고 해도 돼. 엄마는 항상 네 편."},
	"core1": {"from": "(알 수 없음)", "time": "04:44", "text": "[ 코어 ] 너의 메시지함에도 오차가 많다. 오타, 미완성 문장, 보내지 못한 답장. 왜 지우지 않지?"},
	"all1": {"from": "2학년 단톡방", "time": "07:02", "text": "다들 일어났냐 / 오늘 1교시 수학 / 절규 또 필통 잃어버림ㅋㅋ / 아니 이번엔 찾았거든!!"},
}


static func get_msg(id: String) -> Dictionary:
	return MSG.get(id, {"from": "?", "time": "", "text": ""})


static func received() -> Array:
	var out: Array = []
	for id in ORDER:
		if Game.flag("msg_" + id):
			out.append(id)
	return out
