extends Node
## 게임 전체 흐름: 타이틀, 방 이동, 전투, 이벤트 실행, 화면 페이드.
## 이야기(story/*.gd)의 이벤트 함수들은 여기 있는 say / choose / battle / goto_room 을 쓴다.

const OverworldScript = preload("res://scripts/world/overworld.gd")
const BattleScript = preload("res://scripts/battle/battle.gd")
const DialogueScript = preload("res://scripts/ui/dialogue_box.gd")
const MenuScript = preload("res://scripts/ui/menu.gd")
const TitleScript = preload("res://scripts/ui/title.gd")
const CardScript = preload("res://scripts/ui/card.gd")
const MinimapScript = preload("res://scripts/ui/minimap.gd")
const DevMenuScript = preload("res://scripts/ui/dev_menu.gd")
const Rooms = preload("res://data/rooms.gd")

## 이야기 스크립트 목록. 새 챕터 파일을 만들면 여기에 추가한다.
const STORY_SCRIPTS := [
	"res://story/common.gd",
	"res://story/ch1.gd",
	"res://story/ch2.gd",
	"res://story/ch3.gd",
	"res://story/ch4.gd",
	"res://story/ch5.gd",
	"res://story/ch6.gd",
	"res://story/junkyu.gd",
	"res://story/extra.gd",
]

var world: Node2D = null
var battle_node: Node = null
var title: Node = null
var dialogue: Node2D
var menu: Node2D
var card: Node2D
var minimap: Node2D
var dev_menu: Node2D
var fade: ColorRect
var battle_layer: CanvasLayer
var ui_layer: CanvasLayer
var stories: Array = []
var busy := 0


func _ready() -> void:
	battle_layer = CanvasLayer.new()
	battle_layer.layer = 20
	add_child(battle_layer)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 30
	add_child(ui_layer)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.size = Vector2(640, 480)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade)

	minimap = MinimapScript.new()
	minimap.main = self
	ui_layer.add_child(minimap)
	card = CardScript.new()
	ui_layer.add_child(card)
	dialogue = DialogueScript.new()
	dialogue.main = self
	ui_layer.add_child(dialogue)
	menu = MenuScript.new()
	menu.main = self
	ui_layer.add_child(menu)
	dev_menu = DevMenuScript.new()
	dev_menu.main = self
	ui_layer.add_child(dev_menu)

	for path in STORY_SCRIPTS:
		var s: Node = load(path).new()
		s.main = self
		add_child(s)
		stories.append(s)

	# 개발용 실행 인자:  -- room=forest_2  /  -- room=f5_hall@from_math  /  -- battle=owl  /  -- dev (개발자 모드)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("room="):
			# room=f5_hall 또는 room=f5_hall@from_math (스폰 이름까지)
			var parts := a.substr(5).split("@")
			_load_room(parts[0], parts[1] if parts.size() > 1 else "")
			fade_to(0.0, 0.3)
			return
		if a.begins_with("battle="):
			_load_room("f5_hall", "start")
			_dev_battle(a.substr(7))
			return
	show_title()


func _dev_battle(id: String) -> void:
	var r: String = await battle(id)
	print("전투 결과: ", r)


func is_busy() -> bool:
	return busy > 0 or battle_node != null or title != null


# ---------------------------------------------------------------- 화면
func fade_to(alpha: float, dur: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", alpha, dur)
	await tw.finished


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func show_title() -> void:
	if world:
		world.queue_free()
		world = null
	title = TitleScript.new()
	title.main = self
	ui_layer.add_child(title)
	Snd.play_music("school_night")
	fade_to(0.0, 0.6)


func start_new_game() -> void:
	busy += 1
	await fade_to(1.0, 0.4)
	title.queue_free()
	title = null
	Game.new_game()
	await run_event("prologue")
	busy -= 1


func continue_game() -> void:
	busy += 1
	await fade_to(1.0, 0.4)
	title.queue_free()
	title = null
	if Game.load_game():
		_load_room(Game.room, "", Vector2(Game.pos_x, Game.pos_y), Game.facing)
	else:
		Game.new_game()
		_load_room("s5_multimedia", "start")
	await fade_to(0.0, 0.4)
	busy -= 1


# ---------------------------------------------------------------- 방
func _load_room(id: String, spawn: String, pos = null, face := 0) -> void:
	if world:
		remove_child(world)
		world.queue_free()
	world = OverworldScript.new()
	world.main = self
	world.room_id = id
	world.spawn_name = spawn
	world.spawn_pos = pos
	world.spawn_facing = face
	add_child(world)
	move_child(world, 0)
	Snd.play_music(world.data.get("music", "school_night"))
	dialogue.show_title(world.data.get("name", ""))


func goto_room(id: String, spawn: String) -> void:
	busy += 1
	await fade_to(1.0, 0.22)
	_load_room(id, spawn)
	await fade_to(0.0, 0.22)
	var ev: String = world.data.get("on_enter", "")
	if ev != "":
		await run_event(ev)
	busy -= 1


## 방을 치우고 검은 화면만 남긴다 (엔딩용)
func clear_world() -> void:
	if world:
		remove_child(world)
		world.queue_free()
		world = null


func save_here() -> void:
	if world:
		Game.save_game(world.room_id, world.player.position, world.player.facing)


# ---------------------------------------------------------------- 이야기
func run_event(event_name: String, arg = null) -> void:
	for s in stories:
		if s.has_method("ev_" + event_name):
			busy += 1
			await s.call("ev_" + event_name, arg)
			busy -= 1
			return
	push_error("이벤트를 찾을 수 없음: ev_" + event_name)


func say(lines: Array) -> void:
	busy += 1
	await dialogue.run(lines)
	busy -= 1


func choose(prompt: String, options: Array) -> int:
	busy += 1
	var i: int = await dialogue.choose(prompt, options)
	busy -= 1
	return i


func toast(text: String) -> void:
	dialogue.show_title(text)


## 기억 장면: 화면이 검게 가라앉고, 회색 글씨로 짧은 회상이 흐른다.
func show_memory(lines: Array) -> void:
	busy += 1
	await fade_to(1.0, 0.6)
	var was_visible := world != null and world.visible
	if world:
		world.visible = false
	card.start("", "- 기억 -", 999.0)
	card.backdrop_only = true
	await fade_to(0.0, 0.5)
	dialogue.memory_mode = true
	await dialogue.run(lines)
	dialogue.memory_mode = false
	await fade_to(1.0, 0.6)
	card.backdrop_only = false
	card.stop()
	if world and was_visible:
		world.visible = true
	await fade_to(0.0, 0.5)
	busy -= 1


## 챕터 카드. 끝나면 화면이 검은 상태로 남으므로, 부른 쪽에서 fade_to(0.0, ...) 로 밝혀야 한다.
func show_card(big: String, small: String, sec := 2.6) -> void:
	busy += 1
	await fade_to(1.0, 0.3)
	card.start(big, small, sec)
	await fade_to(0.0, 0.3)
	await card.done
	await fade_to(1.0, 0.3)
	card.stop()
	busy -= 1


func battle(enemy_id: String) -> String:
	busy += 1
	var prev_music := Snd.music_name()
	Snd.stop_music()
	Snd.play("encounter")
	for i in 3:
		fade.modulate.a = 1.0
		await wait(0.06)
		fade.modulate.a = 0.0
		await wait(0.06)
	await fade_to(1.0, 0.15)
	if world:
		world.visible = false
		world.process_mode = Node.PROCESS_MODE_DISABLED
	battle_node = BattleScript.new()
	battle_node.main = self
	battle_node.enemy_id = enemy_id
	battle_layer.add_child(battle_node)
	await fade_to(0.0, 0.2)
	var result: String = await battle_node.finished
	await fade_to(1.0, 0.35)
	battle_node.queue_free()
	battle_node = null
	if world:
		world.visible = true
		world.process_mode = Node.PROCESS_MODE_INHERIT
	Snd.play_music(prev_music)
	await fade_to(0.0, 0.35)
	busy -= 1
	return result
