extends RefCounted
## 방 찾기. 방 데이터 파일을 새로 만들면 FILES 에 추가한다.
## 방 데이터는 tools/world.py 가 만든다 (python3 tools/world.py). 그 파일을 고친 뒤 다시 돌리면 된다.
##
## 방 하나의 형식 (자세한 예시는 rooms_f5.gd):
##   "name"    화면 왼쪽 위에 뜨는 이름
##   "theme"   "school" 또는 "forest"  (글자 뜻은 scripts/world/tiles.gd 맨 위 참고)
##   "floor"   학교 바닥 종류: "terrazzo"(복도) / "wood"(교실) / "dark"
##   "music"   assets/music/ 안의 파일 이름
##   "map"     글자 하나 = 타일 하나. 모든 줄의 길이가 같아야 한다.
##   "spawns"  {"이름": [x, y, 방향]}   방향: 0 아래, 1 위, 2 왼쪽, 3 오른쪽
##   "doors"   {"글자": {...}}
##                to / spawn        이동할 방과 스폰 이름
##                event             (to 대신) 밟으면 실행할 이벤트 이름
##                label             문 위 명패
##                locked: true      항상 잠김 / need_flag: "플래그"  그 플래그가 켜져야 열림
##                text              잠겨 있을 때 조사하면 나오는 대사
##                style             "door"(기본) / "stairs" / "open"
##   "signs"     {"글자": [대사...]}       그 글자의 타일을 조사했을 때
##   "signs_at"  {"x,y": [대사...] 또는 {"event": "이름"}}   특정 칸만 다르게
##   "actors"    [{id, look, pos:[x,y], lines:[...] 또는 event:"이름", if_flag, unless_flag, solid}]
##   "triggers"  [{rect:[x,y,w,h], event:"이름", once:"플래그"}]   밟으면 발동
##   "on_enter"  방에 들어올 때마다 실행할 이벤트
##   "where"     미니맵 위치 {"floor": "1F"~"5F" / "R"(옥상) / "DORM" / "OUT", "x": 0~1, "hall": 복도면 true}
##   "plates"    [[x, y, "글자"]] 바닥 위 작은 명패
##   "sky"       true 면 밤하늘 배경 (옥상)

const FILES := [
	"res://data/rooms_halls.gd",
	"res://data/rooms_f5.gd",
	"res://data/rooms_ch1.gd",
	"res://data/rooms_f4.gd",
	"res://data/rooms_ch2.gd",
	"res://data/rooms_lower.gd",
	"res://data/rooms_ch3.gd",
	"res://data/rooms_ch4.gd",
	"res://data/rooms_ch5.gd",
	"res://data/rooms_ch56.gd",
	"res://data/rooms_extra.gd",
]


static func get_room(id: String) -> Dictionary:
	for path in FILES:
		var rooms: Dictionary = load(path).ROOMS
		if rooms.has(id):
			return rooms[id]
	push_error("없는 방: " + id)
	return {}


static func all_rooms() -> Dictionary:
	var out := {}
	for path in FILES:
		out.merge(load(path).ROOMS)
	return out
