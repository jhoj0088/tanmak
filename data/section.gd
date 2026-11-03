extends RefCounted
## 미니맵용 학교 평면: 5층 시설 안내도의 S동·A동·수학 구역·중앙 홀 모양. tools/world.py 가 만든다.

const FLOORS := [
	{
		"id": "1F",
		"hall": "f1_hall",
	},
	{
		"id": "2F",
		"hall": "f2_hall",
	},
	{
		"id": "3F",
		"hall": "f3_hall",
	},
	{
		"id": "4F",
		"hall": "f4_hall",
	},
	{
		"id": "5F",
		"hall": "f5_hall",
	},
]
const PLAN := {
	"w": 108,
	"h": 66,
	"rects": [[24, 46, 80, 3], [74, 29, 3, 17], [77, 32, 27, 14]],
	"a_wing": [[31, 3], [76, 31]],
	"m_wing": [[4, 63], [26, 47]],
	"tri": [[79, 33], [79, 44], [97, 44]],
	"labels": [["S동", 50, 53], ["A동", 46, 6], ["수학", 8, 52]],
}

