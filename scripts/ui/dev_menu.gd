extends Node2D
## 개발자 메뉴 (개발자 모드에서 필드에 있을 때 F1 또는 ` 키, 휴대폰은 '개발' 버튼)
##   - 방으로 이동 / 챕터로 건너뛰기 / 아무 적과 전투
##   - 무적 · 빠르게 걷기 · 벽 통과 · 정보 표시 (켜고 끄기)
##   - HP 가득 + 레벨 업, 논리·감성 +5, 모든 인증, 여기서 저장
## 전투 중에는 F2 = 지금 바로 살려 줄 수 있게, F3 = 적 HP 1 (battle.gd 의 _dev_keys)
## 개발자 모드 자체는 타이틀 화면의 '개발자 모드' 또는 실행 인자 `-- dev` 로 켠다.
const P = preload("res://scripts/art/palette.gd")
const Rooms = preload("res://data/rooms.gd")
const Enemies = preload("res://scripts/battle/enemies.gd")

## 챕터로 건너뛰기: [이름, 챕터 번호, 켜 둘 플래그(앞 챕터 것까지 누적), 방, 스폰]
const CHAPTERS := [
	["1장 집합과 명제의 방 (5층)", 1, [], "f5_hall", "start"],
	["2장 생명 실험실 (4층)", 2, ["met_namoji", "cert_math", "owl_done"], "f4_hall", "from_up"],
	["3장 단일광자 실험실 (3·2층)", 3, ["f4_intro", "cert_bio", "phage_done"], "f3_hall", "from_up"],
	["4장 기숙사 점호 (2층 데크)", 4, ["f3_intro", "f2_intro", "cert_phys", "lens_done"], "f2_hall", "from_phys"],
	["5장 천문대 (5층 옥상 계단)", 5, ["cert_dorm", "jut_done"], "f5_hall", "from_stairs"],
	["6장 서버실 · 교장실 (2층)", 6, ["ch5_started", "roof_intro", "cert_astro", "astro_done"], "f2_hall", "from_up"],
]

var main: Node
var open := false
var page := "main"
var sel := 0
var top := 0
var note := ""
var open_frame := 0
var list: Array = []      # [[보이는 글자, 할 일], ...]

const ROWS := 13


func _ready() -> void:
	# 실행 인자 `-- room=f5_hall dev devmenu` 로 시작하면 개발자 메뉴가 열린 채로 시작한다 (화면 확인용)
	if Game.dev and OS.get_cmdline_user_args().has("devmenu"):
		await get_tree().create_timer(0.6).timeout
		Game.dev_info = true
		_open()


func _process(_delta: float) -> void:
	queue_redraw()
	if not open:
		if Game.dev and Input.is_action_just_pressed("dev") and main.world and not main.is_busy() \
				and not main.dialogue.active and not main.menu.open:
			_open()
		return
	if Engine.get_process_frames() == open_frame:
		return
	if Input.is_action_just_pressed("dev"):
		_close()
		return
	if Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("menu"):
		if page == "main":
			_close()
		else:
			_show("main")
		return
	var n := list.size()
	if Input.is_action_just_pressed("move_up"):
		sel = (sel - 1 + n) % n
		Snd.play("move")
	elif Input.is_action_just_pressed("move_down"):
		sel = (sel + 1) % n
		Snd.play("move")
	elif Input.is_action_just_pressed("move_left"):
		sel = maxi(0, sel - ROWS)
	elif Input.is_action_just_pressed("move_right"):
		sel = mini(n - 1, sel + ROWS)
	elif Input.is_action_just_pressed("confirm"):
		_pick(list[sel][1])
	top = clampi(top, sel - ROWS + 1, sel)


func _open() -> void:
	open = true
	open_frame = Engine.get_process_frames()
	note = ""
	_show("main")
	Snd.play("select")


func _close() -> void:
	open = false
	if main.world:
		main.world.cooldown = 0.2


func _onoff(v: bool) -> String:
	return "켜짐" if v else "꺼짐"


func _show(p: String) -> void:
	page = p
	sel = 0
	top = 0
	list = []
	match p:
		"main":
			list = [
				["방으로 이동...", "page:rooms"], ["챕터로 건너뛰기...", "page:chapters"], ["전투 시작...", "page:battles"],
				["무적: " + _onoff(Game.dev_god), "god"], ["빠르게 걷기: " + _onoff(Game.dev_fast), "fast"],
				["벽 통과: " + _onoff(Game.dev_noclip), "noclip"], ["정보 표시: " + _onoff(Game.dev_info), "info"],
				["HP 가득 + 레벨 업", "heal"], ["논리 +5", "logic"], ["감성 +5", "emotion"],
				["모든 과목 인증 받기", "certs"], ["여기서 저장", "save"], ["닫기", "close"],
			]
		"rooms":
			var all: Dictionary = Rooms.all_rooms()
			var ids: Array = all.keys()
			ids.sort()
			for id in ids:
				list.append(["%s  %s" % [id, all[id].get("name", "")], "room:" + id])
		"chapters":
			for i in CHAPTERS.size():
				list.append([CHAPTERS[i][0], "chapter:%d" % i])
		"battles":
			var ids2: Array = Enemies.LIST.keys()
			ids2.sort()
			for id in ids2:
				list.append([id, "battle:" + id])


func _pick(what: String) -> void:
	Snd.play("select")
	if what.begins_with("page:"):
		_show(what.substr(5))
		return
	if what.begins_with("room:"):
		_close()
		main.goto_room(what.substr(5), "")
		return
	if what.begins_with("chapter:"):
		_close()
		_jump(int(what.substr(8)))
		return
	if what.begins_with("battle:"):
		_close()
		main.battle(what.substr(7))
		return
	match what:
		"god":
			Game.dev_god = not Game.dev_god
		"fast":
			Game.dev_fast = not Game.dev_fast
		"noclip":
			Game.dev_noclip = not Game.dev_noclip
		"info":
			Game.dev_info = not Game.dev_info
		"heal":
			Game.lv += 1
			Game.max_hp += 4
			Game.hp = Game.max_hp
			note = "LV %d, HP %d / %d" % [Game.lv, Game.hp, Game.max_hp]
		"logic":
			Game.logic += 5
			note = "논리 %d" % Game.logic
		"emotion":
			Game.emotion += 5
			note = "감성 %d" % Game.emotion
		"certs":
			for f in ["cert_math", "cert_bio", "cert_phys", "cert_dorm", "cert_astro"]:
				Game.set_flag(f)
			if main.world:
				main.world.refresh_actors()
			note = "수학 · 생명 · 물리 · 점호 · 천문 인증을 받았다."
		"save":
			main.save_here()
			note = "저장했다: " + main.world.room_id
		"close":
			_close()
			return
	var keep := sel
	_show("main")
	sel = keep


## 챕터 시작 지점으로: 앞 챕터의 인증·보스 플래그를 켜고 그 층 복도로 간다
func _jump(i: int) -> void:
	for k in i + 1:
		for f in CHAPTERS[k][2]:
			Game.set_flag(f)
	Game.chapter = CHAPTERS[i][1]
	Game.hp = Game.max_hp
	main.goto_room(CHAPTERS[i][3], CHAPTERS[i][4])


func _draw() -> void:
	if Game.dev and Game.dev_info and main.world and main.world.player and main.battle_node == null:
		_draw_info()
	if not open:
		return
	var f: Font = Game.font
	draw_rect(Rect2(0, 0, 640, 480), Color(P.UI_BG, 0.6))
	var r := Rect2(70, 36, 500, 408)
	draw_rect(r, P.UI_BG)
	draw_rect(r, P.UI_ACCENT_2, false, 3)
	var heading: String = {"main": "개발자 메뉴", "rooms": "방으로 이동", "chapters": "챕터로 건너뛰기", "battles": "전투 시작"}[page]
	draw_string(f, Vector2(r.position.x + 16, r.position.y + 28), heading, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FL, P.UI_ACCENT_2)
	draw_string(f, Vector2(r.position.x + 16, r.position.y + 28), "F1 닫기  X 뒤로", HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 32, Game.FS, P.UI_MUTED)
	for i in range(top, mini(list.size(), top + ROWS)):
		var y := r.position.y + 62 + (i - top) * 26
		var me := i == sel
		if me:
			draw_rect(Rect2(r.position.x + 10, y - 18, r.size.x - 20, 24), Color(P.UI_ACCENT, 0.15))
			draw_string(f, Vector2(r.position.x + 16, y), "♥", HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_SIGNAL)
		draw_string(f, Vector2(r.position.x + 36, y), list[i][0], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 50, Game.FS, P.UI_ACCENT if me else P.UI_INK)
	if list.size() > ROWS:
		draw_string(f, Vector2(r.position.x + 16, r.end.y - 30), "%d / %d   ←→ 한 쪽씩" % [sel + 1, list.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, Game.FS, P.UI_MUTED)
	if note != "":
		draw_string(f, Vector2(r.position.x + 16, r.end.y - 12), note, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 32, Game.FS, P.UI_ACCENT)


func _draw_info() -> void:
	var f: Font = Game.font
	var w: Node2D = main.world
	var p: Vector2 = w.player.position
	var lines := [
		"%s  (%s)" % [w.room_id, w.data.get("name", "")],
		"칸 %d, %d   픽셀 %d, %d" % [int(p.x / 32), int(p.y / 32), int(p.x), int(p.y)],
		"%d장  LV %d  HP %d/%d  논리 %d  감성 %d  플래그 %d개" % [Game.chapter, Game.lv, Game.hp, Game.max_hp, Game.logic, Game.emotion, Game.flags.size()],
		"%s%s%s  FPS %d" % ["무적 " if Game.dev_god else "", "빠름 " if Game.dev_fast else "", "벽통과 " if Game.dev_noclip else "", Engine.get_frames_per_second()],
	]
	var box := Rect2(4, 480 - 18 * lines.size() - 8, 400, 18 * lines.size() + 4)
	draw_rect(box, Color(P.NIGHT_950, 0.7))
	for i in lines.size():
		draw_string(f, Vector2(8, box.position.y + 15 + i * 18), lines[i], HORIZONTAL_ALIGNMENT_LEFT, 392, Game.FS, P.UI_INK)
