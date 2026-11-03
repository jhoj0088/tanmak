extends RefCounted
## SASA 교정 팔레트: 우리 학교 사진 21장(1층·2층·옥상)에서 잰 색.
## 디자인 시스템 페이지와 docs/sasa_school.gpl (Aseprite 팔레트) 이 같은 값을 쓴다.
## 쓰는 법:  const P = preload("res://scripts/art/palette.gd")  →  P.PILLAR_300
## 한 타일은 -300(빛) / -500(기본) / -700(그늘) 세 단계로 칠한다.
## 바로 옆 칸과 살짝만 다르게 하고 싶으면 새 색을 만들지 말고 .darkened(0.05) 를 쓴다.

# ---------------------------------------------------------------- 재질 (게임 속 물체)
## 화강석 복도 바닥
const GRANITE_100 := Color("d5d9db")
const GRANITE_300 := Color("a4a5a6")
const GRANITE_500 := Color("8d8c8b")
const GRANITE_700 := Color("737270")
## 바닥의 검은 타일·인레이, 기계류의 짙은 몸체
const INLAY_900 := Color("34343a")
## 흰 벽·천장 (살짝 푸른 기)
const WALL_100 := Color("d8dee4")
const WALL_300 := Color("b5bcc5")
const WALL_500 := Color("9a9ea3")
## 교실 문·창틀·목재 패널
const WOOD_300 := Color("c69a72")
const WOOD_500 := Color("a68062")
const WOOD_700 := Color("86654b")
const WOOD_900 := Color("533822")
## 중앙 홀의 노란 원기둥 (대표 강조색)
const PILLAR_300 := Color("dfc05c")
const PILLAR_500 := Color("ba9739")
const PILLAR_700 := Color("876a19")
## 포인트 벽: 라임(휴게 공간) / 보라(급수대·복도 끝) / 살구(계단실)
const LIME_300 := Color("a3b957")
const LIME_500 := Color("889852")
const LIME_700 := Color("586236")
const VIOLET_300 := Color("6f65aa")
const VIOLET_500 := Color("463e69")
const VIOLET_700 := Color("2b2338")
const PEACH_300 := Color("deb487")
const PEACH_500 := Color("cf9f77")
## 초록 소파·벤치, 나무와 화분 잎
const BENCH_500 := Color("4b8c6c")
const BENCH_700 := Color("304439")
## 옥상 하늘
const SKY_100 := Color("aac0de")
const SKY_300 := Color("8196b1")
const BLUE_500 := Color("6083bd")
const NIGHT_900 := Color("142139")
const NIGHT_950 := Color("06080e")
## 종이·흰 물건, 탄환 테두리
const PAPER := Color("fbfaf6")
## 위험 신호 (소화전·표지판의 빨강). 넓은 면적에 쓰지 않는다.
const SIGNAL := Color("bd2d43")

# ---------------------------------------------------------------- 화면 UI (밤 테마)
const UI_BG := Color("111a2b")        ## 대화창·메뉴 바탕
const UI_INK_DAY := Color("2b2622")   ## 밝은 바탕(명패, 종이) 위 글자
const UI_PANEL := Color("1b2639")     ## 바탕 위 한 단계 뜬 면
const UI_INK := Color("ece7dc")       ## 본문 글자, 창 테두리
const UI_MUTED := Color("a9b1bf")     ## 보조 글자, 안내 문구
const UI_LINE := Color("5a6a88")      ## 테두리, 구분선
const UI_ACCENT := Color("dfc05c")    ## 선택된 항목 (= 노란 기둥)
const UI_ACCENT_2 := Color("9e95d6")  ## 보조 강조 (보라 벽을 밤에 맞게 밝힌 값)
const UI_SIGNAL := Color("e0566a")    ## 위험·HP 경고, 영혼 하트

# ---------------------------------------------------------------- 섞어 쓰는 묶음
## 책등, 스티커, 자판기 음료처럼 여러 색이 섞여야 하는 작은 물건. 무지개(from_hsv) 대신 이 중에서 고른다.
const ACCENTS := [PILLAR_300, LIME_300, VIOLET_300, PEACH_300, BLUE_500, SIGNAL, BENCH_500, WOOD_300]
