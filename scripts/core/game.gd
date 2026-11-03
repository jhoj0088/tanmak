extends Node
## 전역 상태 (자동 로드 "Game")
## 플레이어 스탯, 아이템, 이야기 플래그, 세이브/로드, 폰트, 키 설정.

const SAVE_PATH := "user://save.json"
const FS := 12    # 작은 글씨 (픽셀 폰트는 12의 배수일 때 또렷하다)
const FL := 24    # 큰 글씨

var player_name := "나"
var lv := 1
var exp_points := 0
var max_hp := 20
var hp := 20
var logic := 0        # 논리: 싸워서 이기면 오른다
var emotion := 0      # 감성: 자비를 베풀면 오른다
var items: Array = []
var flags := {}
var chapter := 1
var objective := ""

# 세이브 위치
var room := ""
var pos_x := 0.0
var pos_y := 0.0
var facing := 0

var font: Font
var allies: Array = []  # 최종전 동료 (이야기 스크립트가 전투 직전에 채우고, 끝나면 비운다)
var easy := false      # 쉬움: 받는 피해가 절반 (타이틀 화면에서 바꾼다. 새 게임을 해도 유지된다)
# 개발자 모드 (타이틀의 '개발자 모드' 또는 실행 인자 -- dev). 켜면 필드에서 F1(또는 `)로 개발자 메뉴가 열린다.
var dev := false
var dev_god := false     # 무적: 전투에서 피해를 받지 않는다
var dev_fast := false    # 빠르게 걷기 (2.5배)
var dev_noclip := false  # 벽 통과
var dev_info := false    # 화면 왼쪽 아래에 방 이름·칸 좌표·플래그 수 표시


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_font()
	_setup_input()
	easy = clears().get("_easy", false)
	dev = clears().get("_dev", false) or OS.get_cmdline_user_args().has("dev")
	new_game()


func new_game() -> void:
	lv = 1
	exp_points = 0
	max_hp = 20
	hp = 20
	logic = 0
	emotion = 0
	items = ["매점 빵", "매점 빵"]
	flags = {}
	chapter = 1
	objective = ""
	room = ""


# ---------------------------------------------------------------- 플래그
func flag(n: String) -> bool:
	return flags.get(n, false)


func set_flag(n: String, value := true) -> void:
	flags[n] = value


func count(n: String) -> int:
	return int(flags.get(n, 0))


func add_count(n: String, by := 1) -> int:
	flags[n] = count(n) + by
	return flags[n]


# ---------------------------------------------------------------- 성장
func exp_needed(level: int) -> int:
	return 10 * level * (level + 1) / 2     # LV2: 10, LV3: 30, LV4: 60 ...


func add_exp(n: int) -> bool:
	exp_points += n
	var leveled := false
	while exp_points >= exp_needed(lv):
		lv += 1
		max_hp += 4
		hp = min(max_hp, hp + 4)
		leveled = true
	return leveled


func attack_power() -> int:
	return 10 + lv * 2


func heal(n: int) -> void:
	hp = min(max_hp, hp + n)


# ---------------------------------------------------------------- 세이브
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(room_id: String, p: Vector2, face: int) -> void:
	room = room_id
	pos_x = p.x
	pos_y = p.y
	facing = face
	var d := {
		"version": 1, "lv": lv, "exp": exp_points, "max_hp": max_hp, "hp": hp,
		"logic": logic, "emotion": emotion, "items": items, "flags": flags,
		"chapter": chapter, "objective": objective,
		"room": room, "x": pos_x, "y": pos_y, "facing": facing,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return false
	lv = int(d.get("lv", 1))
	exp_points = int(d.get("exp", 0))
	max_hp = int(d.get("max_hp", 20))
	hp = int(d.get("hp", max_hp))
	logic = int(d.get("logic", 0))
	emotion = int(d.get("emotion", 0))
	items = d.get("items", [])
	flags = d.get("flags", {})
	chapter = int(d.get("chapter", 1))
	objective = d.get("objective", "")
	room = d.get("room", "")
	pos_x = float(d.get("x", 0))
	pos_y = float(d.get("y", 0))
	facing = int(d.get("facing", 0))
	return room != ""


## 본 엔딩 기록 (세이브와 별개로 남는다). 타이틀 화면에 표시된다.
const CLEAR_PATH := "user://clear.json"


func clears() -> Dictionary:
	if not FileAccess.file_exists(CLEAR_PATH):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(CLEAR_PATH))
	return d if typeof(d) == TYPE_DICTIONARY else {}


func set_easy(v: bool) -> void:
	easy = v
	var d := clears()
	d["_easy"] = v
	var f := FileAccess.open(CLEAR_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func set_dev(v: bool) -> void:
	dev = v
	if not v:
		dev_god = false
		dev_fast = false
		dev_noclip = false
		dev_info = false
	var tc := get_node_or_null("/root/Touch")
	if tc and tc.enabled:
		tc._layout()
	var d := clears()
	d["_dev"] = v
	var f := FileAccess.open(CLEAR_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func record_clear(kind: String) -> void:
	var d := clears()
	d[kind] = true
	var f := FileAccess.open(CLEAR_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


# ---------------------------------------------------------------- 폰트
func _setup_font() -> void:
	# Galmuri11 (SIL OFL). 다른 폰트를 쓰려면 이 경로만 바꾸면 된다.
	var f = load("res://assets/fonts/Galmuri11.ttf")
	if f is FontFile:
		f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		f.hinting = TextServer.HINTING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		font = f
	else:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(["Malgun Gothic", "Apple SD Gothic Neo", "Noto Sans CJK KR", "sans-serif"])
		font = sf
	ThemeDB.fallback_font = font


## 글자가 찍히는 도중에 줄이 바뀌어 덜컹거리지 않도록 미리 줄바꿈을 넣는다.
## 긴 문장을 창 크기에 맞게 여러 쪽으로 나눈다 (한 쪽 = max_lines 줄). 대화창·전투 글이 창을 넘지 않게 한다.
func pages(text: String, width: float, size: int, max_lines := 3) -> Array:
	var ls: PackedStringArray = self.wrap(text, width, size).split("\n")
	var out: Array = []
	var i := 0
	while i < ls.size():
		out.append("\n".join(ls.slice(i, i + max_lines)))
		i += max_lines
	return out


## 글자를 칸에 맞춘다: 큰 글씨(FL)로 max_lines 줄 안에 들어가면 그대로, 아니면 작은 글씨(FS)로 줄을 바꾼다.
## [줄바꿈된 글, 글씨 크기, 줄 간격] 을 돌려준다.
func fit(text: String, width: float, max_lines: int) -> Array:
	var big: String = self.wrap(text, width, FL)
	if big.count("\n") + 1 <= max_lines:
		return [big, FL, 28]
	return [self.wrap(text, width, FS), FS, 16]


func wrap(text: String, width: float, size: int) -> String:
	var out := ""
	for para in text.split("\n"):
		var line := ""
		for word in para.split(" "):
			var trial: String = word if line == "" else line + " " + word
			if font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width:
				line = trial
			else:
				if line != "":
					out += line + "\n"
				line = word
				while font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and line.length() > 1:
					var k := line.length() - 1
					while k > 1 and font.get_string_size(line.substr(0, k), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
						k -= 1
					out += line.substr(0, k) + "\n"
					line = line.substr(k)
		out += line + "\n"
	return out.trim_suffix("\n")


# ---------------------------------------------------------------- 입력
func _setup_input() -> void:
	_add_keys("move_up", [KEY_UP, KEY_W])
	_add_keys("move_down", [KEY_DOWN, KEY_S])
	_add_keys("move_left", [KEY_LEFT, KEY_A])
	_add_keys("move_right", [KEY_RIGHT, KEY_D])
	_add_keys("confirm", [KEY_Z, KEY_ENTER, KEY_SPACE])
	_add_keys("cancel", [KEY_X, KEY_BACKSPACE])
	_add_keys("focus", [KEY_SHIFT])
	_add_keys("menu", [KEY_C, KEY_ESCAPE])
	# 개발자 모드 전용 (Game.dev 가 켜져 있을 때만 쓰인다)
	_add_keys("dev", [KEY_F1, KEY_QUOTELEFT])
	_add_keys("dev_spare", [KEY_F2])
	_add_keys("dev_win", [KEY_F3])


func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
