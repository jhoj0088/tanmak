extends Node
## 휴대폰 · 태블릿용 터치 조작 (자동 로드 "Touch").
##
## 터치 화면이면(휴대폰 앱, 휴대폰 브라우저) 게임 화면(640×480)을 SubViewport 안에 넣고,
## 남는 자리에 방향 패드와 버튼을 그린다. 버튼은 키보드와 같은 입력 동작(move_*, confirm, cancel,
## menu, focus)을 누르기 때문에 게임 코드는 하나도 바꿀 필요가 없다.
##   가로 화면: 왼쪽에 패드, 오른쪽에 버튼 (자리가 좁으면 게임 위에 반투명하게)
##   세로 화면: 위에 게임, 아래에 패드와 버튼
## PC에서 시험해 보려면 실행 인자에 `-- mobile` 을 준다 (마우스로 누를 수 있다).

const GAME := Vector2(640, 480)

var enabled := false
var main: Node = null          # 게임 본체 (SubViewport 안으로 옮긴 뒤에도 여기서 찾을 수 있다)
var container: SubViewportContainer
var sub: SubViewport
var pad_node: Node2D

# 배치 (루트 화면 좌표)
var game_rect := Rect2(Vector2.ZERO, GAME)
var pad_c := Vector2(100, 380)
var pad_r := 60.0
var buttons := {}            # 이름 -> {"pos", "r", "action", "label", "sub"}
var overlay := false         # 자리가 없어서 게임 위에 겹쳐 그리는 중

# 상태
var touches := {}            # 손가락 번호 -> "pad" 또는 버튼 이름
var pad_dir := Vector2.ZERO
var pressed := {}            # 버튼 이름 -> true
var focus_on := false
var mouse_down := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	enabled = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") \
		or DisplayServer.is_touchscreen_available() or args.has("mobile")
	if not enabled:
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	_wrap.call_deferred()


## 메인 장면을 SubViewport 안으로 옮긴다
func _wrap() -> void:
	var root := get_tree().root
	var main_scene := get_tree().current_scene
	if main_scene == null:
		_wrap.call_deferred()
		return
	var bg := CanvasLayer.new()
	bg.layer = -10
	var bg_draw := Node2D.new()
	bg_draw.set_script(preload("res://scripts/mobile/touch_bg.gd"))
	bg_draw.set("touch", self)
	bg.add_child(bg_draw)
	root.add_child(bg)

	container = SubViewportContainer.new()
	container.stretch = false
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(container)
	sub = SubViewport.new()
	sub.size = Vector2i(GAME)
	sub.handle_input_locally = false
	sub.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	sub.audio_listener_enable_2d = true
	container.add_child(sub)
	main_scene.get_parent().remove_child(main_scene)
	sub.add_child(main_scene)
	main = main_scene

	var layer := CanvasLayer.new()
	layer.layer = 200
	pad_node = Node2D.new()
	pad_node.set_script(preload("res://scripts/mobile/touch_draw.gd"))
	pad_node.set("touch", self)
	layer.add_child(pad_node)
	root.add_child(layer)

	root.size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var vr := get_tree().root.get_visible_rect().size
	buttons.clear()
	overlay = false
	if vr.x >= vr.y:
		# 가로
		var side := (vr.x - GAME.x) / 2.0
		game_rect = Rect2(Vector2(side, (vr.y - GAME.y) / 2.0), GAME)
		if side >= 96.0:
			var cx := side / 2.0
			pad_r = minf(side * 0.4, 70.0)
			pad_c = Vector2(cx, vr.y * 0.66)
			var bx := vr.x - side / 2.0
			var br := minf(side * 0.27, 40.0)
			_btn("confirm", Vector2(bx, vr.y * 0.74), br, "confirm", "Z", "확인")
			_btn("cancel", Vector2(bx, vr.y * 0.74 - br * 2.6), br * 0.85, "cancel", "X", "취소·폭탄")
			_btn("menu", Vector2(bx, vr.y * 0.16), br * 0.65, "menu", "C", "메뉴")
			_btn("focus", Vector2(cx, vr.y * 0.24), br * 0.65, "focus", "S", "정밀")
			if Game.dev:
				_btn("dev", Vector2(cx, vr.y * 0.08), br * 0.5, "dev", "F1", "개발")
		else:
			overlay = true
			pad_r = 54.0
			pad_c = game_rect.position + Vector2(84, 380)
			var b := game_rect.position
			_btn("confirm", b + Vector2(580, 400), 32, "confirm", "Z", "확인")
			_btn("cancel", b + Vector2(510, 430), 26, "cancel", "X", "취소")
			_btn("menu", b + Vector2(612, 152), 20, "menu", "C", "메뉴")
			_btn("focus", b + Vector2(28, 300), 20, "focus", "S", "정밀")
			if Game.dev:
				_btn("dev", b + Vector2(612, 206), 18, "dev", "F1", "개발")
	else:
		# 세로
		var free := vr.y - GAME.y
		var gy := clampf(free * 0.12, 0.0, 70.0)
		game_rect = Rect2(Vector2((vr.x - GAME.x) / 2.0, gy), GAME)
		var top := gy + GAME.y
		var h := vr.y - top
		if h < 150.0:
			game_rect.position.y = 0.0
			top = GAME.y
			h = vr.y - top
		pad_r = clampf(h * 0.3, 50.0, 115.0)
		pad_c = Vector2(game_rect.position.x + pad_r + 40.0, top + h * 0.48)
		var br := clampf(pad_r * 0.55, 30.0, 62.0)
		var bx := game_rect.position.x + GAME.x - br - 40.0
		_btn("confirm", Vector2(bx, top + h * 0.56), br, "confirm", "Z", "확인")
		_btn("cancel", Vector2(bx - br * 2.3, top + h * 0.56 - br * 1.2), br * 0.85, "cancel", "X", "취소·폭탄")
		_btn("menu", Vector2(bx, top + h * 0.13), br * 0.6, "menu", "C", "메뉴")
		_btn("focus", Vector2(bx - br * 2.3, top + h * 0.13), br * 0.6, "focus", "S", "정밀")
		if Game.dev:
			_btn("dev", Vector2(bx - br * 4.4, top + h * 0.13), br * 0.5, "dev", "F1", "개발")
	if container:
		container.position = game_rect.position
		container.size = game_rect.size
		# 화면이 크면 SubViewport 를 실제 픽셀 크기로 키워서 글씨가 뭉개지지 않게 한다
		var scale := float(get_tree().root.size.y) / vr.y
		scale = clampf(roundf(scale), 1.0, 4.0)
		sub.size_2d_override_stretch = true
		sub.size_2d_override = Vector2i(GAME)
		sub.size = Vector2i(GAME * scale)
		container.scale = Vector2.ONE / scale
		container.size = game_rect.size * scale
	if pad_node:
		pad_node.queue_redraw()


func _btn(n: String, pos: Vector2, r: float, action: String, key: String, label: String) -> void:
	buttons[n] = {"pos": pos, "r": r, "action": action, "key": key, "label": label}


# ---------------------------------------------------------------- 입력
func _input(e: InputEvent) -> void:
	if not enabled or pad_node == null:
		return
	if e is InputEventScreenTouch:
		_touch(e.index, e.position, e.pressed)
	elif e is InputEventScreenDrag:
		if touches.get(e.index, "") == "pad":
			_set_pad(e.position)
	# PC 시험용: 마우스로도 누를 수 있게 (실제 터치 화면은 위의 터치 이벤트만 쓴다)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.device != InputEvent.DEVICE_ID_EMULATION:
		_touch(99, e.position, e.pressed)
	elif e is InputEventMouseMotion and e.device != InputEvent.DEVICE_ID_EMULATION and touches.get(99, "") == "pad":
		_set_pad(e.position)


func _touch(idx: int, pos: Vector2, down: bool) -> void:
	if down:
		var what := _hit(pos)
		if what == "":
			return
		touches[idx] = what
		if what == "pad":
			_set_pad(pos)
		elif what == "focus":
			focus_on = not focus_on
			if focus_on:
				Input.action_press("focus")
			else:
				Input.action_release("focus")
			pressed[what] = true
		else:
			Input.action_press(buttons[what]["action"])
			pressed[what] = true
		get_viewport().set_input_as_handled()
	elif touches.has(idx):
		var what: String = touches[idx]
		touches.erase(idx)
		if what == "pad":
			_set_pad(pad_c)
		elif what != "focus":
			Input.action_release(buttons[what]["action"])
		pressed.erase(what)
	pad_node.queue_redraw()


func _hit(pos: Vector2) -> String:
	for n in buttons:
		var b: Dictionary = buttons[n]
		if pos.distance_to(b["pos"]) <= b["r"] * 1.25:
			return n
	if pos.distance_to(pad_c) <= pad_r * (1.3 if overlay else 1.7):
		return "pad"
	return ""


## 패드 중심에서 손가락까지의 방향으로 8방향 입력
func _set_pad(pos: Vector2) -> void:
	var v := pos - pad_c
	var nd := Vector2.ZERO
	if v.length() > pad_r * 0.22:
		var a := v.angle()
		nd.x = 1.0 if cos(a) > 0.38 else (-1.0 if cos(a) < -0.38 else 0.0)
		nd.y = 1.0 if sin(a) > 0.38 else (-1.0 if sin(a) < -0.38 else 0.0)
	pad_knob = pad_c + v.limit_length(pad_r * 0.6)
	if nd == pad_dir:
		pad_node.queue_redraw()
		return
	_axis("move_left", "move_right", pad_dir.x, nd.x)
	_axis("move_up", "move_down", pad_dir.y, nd.y)
	pad_dir = nd
	pad_node.queue_redraw()


var pad_knob := Vector2.ZERO


func _axis(neg: String, pos_a: String, old: float, now: float) -> void:
	if old == now:
		return
	if old < 0:
		Input.action_release(neg)
	elif old > 0:
		Input.action_release(pos_a)
	if now < 0:
		Input.action_press(neg)
	elif now > 0:
		Input.action_press(pos_a)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and enabled:
		for a in ["move_left", "move_right", "move_up", "move_down", "confirm", "cancel", "menu"]:
			Input.action_release(a)
		touches.clear()
		pressed.clear()
		pad_dir = Vector2.ZERO
