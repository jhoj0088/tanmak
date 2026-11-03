extends Node
## 이야기 스크립트의 부모. story/*.gd 는 이걸 상속해서 `func ev_이름(_a):` 형태의 이벤트를 만든다.
##
## 쓸 수 있는 명령 (전부 앞에 await 를 붙인다):
##   await say(["대사1", "대사2"])                 대화창
##   var i = await choose("질문", ["가", "나"])    선택지 (고른 번호가 0부터 나온다)
##   var r = await battle("적 id")                 전투. r 은 "spared" / "killed" / "fled"
##   await goto("방 id", "스폰 이름")              방 이동
##   await card("큰 글씨", "작은 글씨")            챕터 카드
##   await wait(1.0)                               잠깐 멈춤
## await 없이 쓰는 것:
##   Game.set_flag("이름") / Game.flag("이름")     이야기 진행 기록
##   give("아이템") / objective("목표 문장") / sfx("효과음") / save()
##   await solved("퍼즐 이름")                      퍼즐 정답 보상 (논리 +1, 한 번만)
##   phone("메시지 id")                             휴대폰 메시지 도착 (data/phone.gd)
##   await memory(["..."])                          화면이 어두워지며 '기억' 장면

var main: Node


func say(lines: Array) -> void:
	await main.say(lines)


func choose(prompt: String, options: Array) -> int:
	return await main.choose(prompt, options)


func battle(enemy_id: String) -> String:
	return await main.battle(enemy_id)


func goto(room: String, spawn: String) -> void:
	await main.goto_room(room, spawn)


func card(big: String, small: String, sec := 2.6) -> void:
	await main.show_card(big, small, sec)


func wait(sec: float) -> void:
	await main.wait(sec)


func give(item: String) -> void:
	Game.items.append(item)


func objective(text: String) -> void:
	Game.objective = text
	main.toast("목표: " + text)


func sfx(n: String) -> void:
	Snd.play(n)


func save() -> void:
	main.save_here()


## 퍼즐을 풀었을 때 부른다. 처음 한 번만 논리가 1 오른다.
func solved(puzzle_id: String) -> void:
	if Game.flag("solved_" + puzzle_id):
		return
	Game.set_flag("solved_" + puzzle_id)
	Game.logic += 1
	await say(["* 문제를 풀었다. 논리가 1 올랐다."])


## 휴대폰 메시지 도착 (한 번만)
func phone(msg_id: String) -> void:
	if Game.flag("msg_" + msg_id):
		return
	Game.set_flag("msg_" + msg_id)
	sfx("blip")
	main.toast("휴대폰이 진동한다. (C 메뉴 → 휴대폰)")


## 보스를 살려 준 뒤 보이는 '기억' 장면
func memory(lines: Array) -> void:
	await main.show_memory(lines)
