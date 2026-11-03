extends SceneTree
## 대사 길이 검사.  사용법:  godot --headless -s tools/check_text.gd
## 대화창(3줄)에 안 들어가는 문장과, 줄 길이가 안 맞는 맵을 찾아 준다.

func _init() -> void:
	var font: FontFile = load("res://assets/fonts/Galmuri11.ttf")
	var bad := 0
	var total := 0
	var re := RegEx.new()
	re.compile("\"((?:[^\"\\\\]|\\\\.)*)\"")
	for dir in ["res://story", "res://data", "res://scripts/battle/enemies"]:
		for file in DirAccess.get_files_at(dir):
			if not file.ends_with(".gd"):
				continue
			var src := FileAccess.get_file_as_string(dir + "/" + file)
			var in_map := false
			for line in src.split("\n"):
				if line.contains("\"map\""):
					in_map = true
				elif in_map and line.strip_edges().begins_with("]"):
					in_map = false
				if in_map or line.strip_edges().begins_with("#"):
					continue
				for m in re.search_all(line):
					var s: String = m.get_string(1).replace("\\n", "\n").replace("\\\"", "\"")
					for ch in s:
						if ch != "\n" and ch != "\t" and not font.has_char(ch.unicode_at(0)):
							bad += 1
							print("[글자 없음] %s: '%s' (%s)" % [file, ch, s])
					if s.length() < 16 or s.begins_with("res://") or s.contains("\n"):
						continue
					total += 1
					if _lines(font, s, 528.0, 24) > 3:
						bad += 1
						print("[길다] %s: %s" % [file, s])
	# 맵 검사
	var rooms: Dictionary = load("res://data/rooms.gd").all_rooms()
	for id in rooms:
		var room: Dictionary = rooms[id]
		var w: int = room["map"][0].length()
		for row in room["map"]:
			if row.length() != w:
				bad += 1
				print("[맵] %s: 줄 길이가 다름: %s" % [id, row])
		for key in room.get("spawns", {}):
			var sp: Array = room["spawns"][key]
			var c: String = room["map"][sp[1]][sp[0]]
			if load("res://scripts/world/tiles.gd").is_solid(room.get("theme", "school"), c):
				bad += 1
				print("[맵] %s: 스폰 '%s' 가 막힌 칸(%s) 위에 있음" % [id, key, c])
		for ch in room.get("doors", {}):
			var d: Dictionary = room["doors"][ch]
			if d.has("to"):
				if not rooms.has(d["to"]):
					bad += 1
					print("[맵] %s: 문 '%s' 가 없는 방 %s 로 이어짐" % [id, ch, d["to"]])
				elif not rooms[d["to"]].get("spawns", {}).has(d["spawn"]):
					bad += 1
					print("[맵] %s: 문 '%s' 의 스폰 %s 가 %s 에 없음" % [id, ch, d["spawn"], d["to"]])
	print("문장 %d개, 방 %d개 검사. 문제 %d건." % [total, rooms.size(), bad])
	quit()


func _lines(font: Font, text: String, width: float, size: int) -> int:
	var n := 1
	var line := ""
	for word in text.split(" "):
		var trial: String = word if line == "" else line + " " + word
		if font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width:
			line = trial
		else:
			n += 1
			line = word
	return n
