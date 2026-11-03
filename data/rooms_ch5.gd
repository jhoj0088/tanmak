extends RefCounted
## Chapter 5 「천문대」 — 옥상과 천문대 돔.
## (tools/world.py 가 만든 파일. 직접 고쳐도 되지만 world.py 를 다시 돌리면 덮어쓴다)

const ROOMS := {
	"roof": {
		"name": "옥상 - 별이 가장 가까운 곳",
		"theme": "school",
		"floor": "roof",
		"music": "astro",
		"light": "none",
		"sky": true,
		"map": [
			"############################################",
			"#rrrrrrrrrrrrrrrrruuuuuuuurrrrrrrrrrrrrrrrr#",
			"#r................uuu22uuu................r#",
			"#r........................................r#",
			"#r..Y.......Y.......Y..........t.......t..r#",
			"#r........................................r#",
			"#r....oo..........................oo......r#",
			"#r....oo..........................oo......r#",
			"#r........................................r#",
			"#r..zz.......t...........*...........zz...r#",
			"#r........................................r#",
			"#r........................................r#",
			"#rrrrr11rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr#",
			"############################################",
		],
		"spawns": {
			"from_hall": [6, 11, 1],
			"from_dome": [21, 3, 0],
		},
		"doors": {
			"1": {
				"to": "f5_hall",
				"spawn": "from_roof",
				"style": "stairs",
				"label": "↓ 5층",
			},
			"2": {
				"event": "enter_dome",
				"label": "천문대 돔",
				"need_flag": "roof_open",
				"glow": Color(0.6, 0.7, 1.0, 1.0),
				"text": [
					"* 천문대 돔의 문이다. 문에 별자리판 세 개가 그려져 있다.",
					"* [ 옥상의 별자리판 세 개를 모두 풀면 열립니다 ]",
				],
			},
		},
		"signs": {
			"r": [
				"* 옥상 난간이다. 아래로 운동장과 기숙사, 그 너머 세종시 불빛이 보인다.",
				"* 불빛이 너무 밝아서 별이 반쯤 지워져 있다.",
			],
			"o": ["* 실외기다. 윙윙 돈다. 따뜻한 바람이 나온다. 손을 녹였다."],
			"t": ["* 관측회 때 쓰는 작은 망원경이다. 렌즈 뚜껑에 '쓰고 나서 꼭 닫기!!'"],
			"z": ["* 벤치다. 별 보다가 잠든 사람이 많았는지, 담요 하나가 개어져 있다."],
			"u": ["* 천문대 돔의 흰 벽이다. 차갑다. 안에서 모터 소리가 난다."],
			"Y": ["* 별자리판이다."],
		},
		"signs_at": {
			"4,4": {
				"event": "star_board",
				"q": 0,
			},
			"12,4": {
				"event": "star_board",
				"q": 1,
			},
			"20,4": {
				"event": "star_board",
				"q": 2,
			},
		},
		"actors": [
			{
				"id": "junkyu",
				"look": "junkyu",
				"pos": [36, 9],
				"event": "jk_roof",
				"chapter": [5, 5],
			},
			{
				"id": "jk_studentid",
				"look": "lost",
				"pos": [28, 10],
				"solid": false,
				"unless_flag": "jk_found_studentid",
				"event": "jk_item",
				"item": "studentid",
			},
			{
				"id": "lamp",
				"look": "lamp",
				"pos": [40, 6],
				"half_width": 12.0,
				"unless_flag": "lamp_done",
				"event": "roof_lamp",
			},
		],
		"triggers": [
			{
				"rect": [2, 7, 40, 2],
				"event": "roof_meteor",
				"once": "met_meteor",
			},
		],
		"on_enter": "roof_enter",
		"where": {
			"floor": "R",
		},
	},

	"roof_dome": {
		"name": "옥상 천문대 돔",
		"theme": "school",
		"floor": "dark",
		"music": "astro",
		"light": "none",
		"map": [
			"########################",
			"#######uuuuuuuuuu#######",
			"####uuu..........uuu####",
			"###u......XX........u###",
			"##u......XMXX........u##",
			"##u..................u##",
			"#u.....k........A.....u#",
			"#u....................u#",
			"#u......*.............u#",
			"##u..................u##",
			"###uuuuuuuu11uuuuuuuu###",
			"########################",
		],
		"spawns": {
			"from_roof": [11, 9, 1],
		},
		"doors": {
			"1": {
				"to": "roof",
				"spawn": "from_dome",
			},
		},
		"signs": {
			"M": {
				"event": "telescope",
			},
			"k": [
				"* 관측 기록장이 꽂힌 책장이다. 표지마다 날짜와 '맑음/흐림'이 적혀 있다.",
				"* 흐림이 훨씬 많다. 그래도 매일 적혀 있다.",
			],
			"A": [
				"* 메달 진열장이다. 철인3종 완주 메달이 줄줄이 걸려 있다.",
				"* '수영 3.8km · 사이클 180.2km · 마라톤 42.195km'",
				"* 맨 앞 메달 리본에 작게: '꼴찌 완주. 그래도 완주.'",
			],
			"u": ["* 돔 안쪽 벽이다. 별 스티커가 몇 개 붙어 있다. 누가 붙였을까."],
		},
		"actors": [
			{
				"id": "astro",
				"look": "astro",
				"pos": [11.5, 6],
				"half_width": 18.0,
				"unless_flag": "astro_done",
				"event": "ch5_astro",
			},
		],
		"on_enter": "dome_enter",
		"where": {
			"floor": "R",
		},
	},

}
