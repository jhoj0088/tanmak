extends RefCounted
## 적 목록. 새 적 파일을 만들면 여기에 한 줄 추가한다.

const LIST := {
	"empty_set": "res://scripts/battle/enemies/empty_set.gd",
	"venn": "res://scripts/battle/enemies/venn.gd",
	"swan": "res://scripts/battle/enemies/swan.gd",
	"owl": "res://scripts/battle/enemies/owl.gd",
	"redpen": "res://scripts/battle/enemies/redpen.gd",
	# 2챕터
	"flies": "res://scripts/battle/enemies/flies.gd",
	"butterfly": "res://scripts/battle/enemies/butterfly.gd",
	"virus": "res://scripts/battle/enemies/virus.gd",
	"phage": "res://scripts/battle/enemies/phage.gd",
	# 3챕터
	"photon": "res://scripts/battle/enemies/photon.gd",
	"prism": "res://scripts/battle/enemies/prism.gd",
	"lens": "res://scripts/battle/enemies/lens.gd",
	# 4챕터
	"alarm": "res://scripts/battle/enemies/alarm.gd",
	"jut": "res://scripts/battle/enemies/jut.gd",
	# 5챕터: 같은 스크립트를 과목별로
	"exam_math": "res://scripts/battle/enemies/exam.gd",
	"exam_bio": "res://scripts/battle/enemies/exam.gd",
	"exam_phys": "res://scripts/battle/enemies/exam.gd",
	"exam_hanja": "res://scripts/battle/enemies/exam.gd",
	# 6챕터
	"core": "res://scripts/battle/enemies/core.gd",
	"principal": "res://scripts/battle/enemies/principal.gd",
	# 확장판 잡몹
	"infinity": "res://scripts/battle/enemies/infinity.gd",
	"enzyme": "res://scripts/battle/enemies/enzyme.gd",
	"curry": "res://scripts/battle/enemies/curry.gd",
	"mirror": "res://scripts/battle/enemies/mirror.gd",
	"washer": "res://scripts/battle/enemies/washer.gd",
	"trash": "res://scripts/battle/enemies/trash.gd",
	"frog": "res://scripts/battle/enemies/frog.gd",
	# 5챕터 「천문대」
	"meteor": "res://scripts/battle/enemies/meteor.gd",
	"lamp": "res://scripts/battle/enemies/lamp.gd",
	"astro": "res://scripts/battle/enemies/astro.gd",
}


static func create(id: String):
	if not LIST.has(id):
		push_error("없는 적: " + id)
		return null
	var e = load(LIST[id]).new()
	e.setup(id)
	return e
