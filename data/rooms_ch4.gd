extends RefCounted
## Chapter 4 「기숙사 점호 시간의 악몽」.
## (tools/world.py 가 만든 파일. 직접 고쳐도 되지만 world.py 를 다시 돌리면 덮어쓴다)

const ROOMS := {
	"dorm_hall": {
		"actors": [
			{
				"id": "jut_patrol",
				"look": "jut",
				"patrol": {
					"caught": "dorm_caught",
					"speed": 62,
					"to": [7, 3],
					"vision": 135,
				},
				"pos": [35, 3],
				"solid": false,
				"unless_flag": "jut_done",
			},
			{
				"event": "jk_item",
				"id": "jk_key",
				"item": "key",
				"look": "lost",
				"pos": [16, 6],
				"solid": false,
				"unless_flag": "jk_found_key",
			},
		],
		"dark": 85,
		"doors": {
			"1": {
				"label": "정독실",
				"spawn": "from_hall",
				"to": "dorm_study",
			},
			"2": {
				"label": "302",
				"locked": true,
				"text": ["* 302호. 문틈으로 휴대폰 불빛이 샌다. 점호 전에 끄는 게 좋을 텐데."],
			},
			"3": {
				"label": "303",
				"locked": true,
				"text": ["* 303호. 컵라면 냄새가 솔솔 난다."],
			},
			"4": {
				"event": "dorm_304",
				"label": "304",
			},
			"5": {
				"label": "305",
				"locked": true,
				"text": ["* 305호. '공부 중. 깨우지 마시오.' 안에서는 코 고는 소리가 난다."],
			},
			"6": {
				"label": "세탁실",
				"spawn": "from_hall",
				"to": "dorm_laundry",
			},
			"D": {
				"event": "dorm_leave",
				"label": "데크",
				"style": "open",
			},
		},
		"floor": "dark",
		"map": [
			"########################################",
			"#=v==1==b==2==w==3==b==4==w==5==w==6===#",
			"#......................................#",
			"#......................................#",
			"#......................................#",
			"#......................................#",
			"#DD=====__=====__====__====__==========#",
			"########################################",
		],
		"music": "dorm",
		"name": "기숙사 3층 복도 - 점호 5분 전",
		"on_enter": "dorm_hall_enter",
		"signs": {
			"=": ["* 벽이다. 군데군데 움푹 들어간 그늘이 있다. 숨기 좋아 보인다."],
			"b": [
				"* '기숙사 생활 수칙: 점호 시간 엄수. 소등 후 이동 금지. 야식 금지.'",
				"* 세 번째 줄에만 유독 손때가 묻어 있다.",
			],
			"v": {
				"event": "dorm_vending",
			},
			"w": ["* 창밖으로 본관이 보인다. 5층 멀티디자인실에 아직 불이 켜져 있다."],
		},
		"signs_at": {
			"17,1": {
				"event": "dorm_303",
			},
		},
		"spawns": {
			"from_laundry": [35, 2, 0],
			"from_room": [23, 2, 0],
			"from_study": [5, 2, 0],
			"start": [2, 4, 3],
		},
		"theme": "school",
		"triggers": [
			{
				"event": "ch4_alarm",
				"once": "met_alarm",
				"rect": [18, 2, 2, 4],
				"unless_flag": "jut_done",
			},
		],
		"where": {
			"floor": "DORM",
		},
	},

	"dorm_room": {
		"doors": {
			"1": {
				"spawn": "from_room",
				"to": "dorm_hall",
			},
		},
		"floor": "wood",
		"map": [
			"############",
			"#==w====w==#",
			"#hh......hh#",
			"#..........#",
			"#dd......dd#",
			"#..........#",
			"#hh...*....#",
			"#..........#",
			"#####1######",
		],
		"music": "dorm",
		"name": "기숙사 304호",
		"signs": {
			"d": ["* 책상이다. '기상 6:30'이라고 적힌 포스트잇이 열 장쯤 붙어 있다."],
			"h": ["* 룸메이트의 침대다. 이불이 사람 모양으로 불룩하다.", "* 들춰 보니 베개 세 개다. 본인은 어디 갔을까."],
			"w": ["* 창밖으로 본관이 보인다."],
		},
		"signs_at": {
			"10,2": {
				"event": "dorm_bed",
			},
			"9,2": {
				"event": "dorm_bed",
			},
		},
		"spawns": {
			"from_hall": [5, 7, 1],
		},
		"theme": "school",
		"where": {
			"floor": "DORM",
		},
	},

}
