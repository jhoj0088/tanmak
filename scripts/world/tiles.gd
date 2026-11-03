extends RefCounted
## 타일 그림과 충돌. 맵은 글자로 그리고(data/rooms_*.gd), 글자 하나가 32x32 타일 하나다.
##
## [학교 테마 "school"]
##  #  바깥(막힘)      .  바닥           =  벽             w  창문(벽)
##  b  게시판(벽)      L  사물함         B  칠판(벽)       T  교탁
##  d  학생 책상       c  컴퓨터 책상    k  책장           p  화분
##  t  망원경          m  3D 프린터      e  이젤           o  둥근 탁자
##  h  침대           v  자판기         W  세탁기         A  상장 진열장
##  S  소파           q  노래방 기계    P  피아노         x  붉은 카펫(지나갈 수 있음)
##  _  그늘진 바닥 (지나갈 수 있음. 순찰의 눈을 피해 숨는 곳)
##  N  포스터 벽      F  소화기 함(벽)   E  비상구 유도등(벽)   C  CCTV(벽)
##  Q  정수기         I  신발장         i  아이맥 책상     Z  레이저 커팅기   j  화이트보드(벽)
##  G  축구 골대     y  나무           z  벤치           K  정문 표지석     ~  연못
##  O  분수           H  온실 유리벽    V  텃밭
##  J  노란 기둥      n  유리 난간       a  아래로 뚫린 중앙 홀   ^  마름모 바닥 무늬(지나감)
##  g  당구대        f  곰 인형과 우체통
##  r  옥상 난간       Y  별자리판       u  천문대 돔 벽    M  큰 굴절 망원경    X  보이지 않는 벽(큰 물건 둘레)
##  (바닥 "roof" 이면 # 은 그리지 않아서 뒤의 밤하늘이 보인다)
##  (바닥 종류 "floor": terrazzo / wood / dark / tile / grass)
##  *  세이브 포인트
##
## [숲 테마 "forest" = 1장 '집합과 명제의 방': 끝없이 넓어진 교실, 칠판 벽, 벤 다이어그램 나무]
##  #  울창한 숲(막힘)  .  풀밭          ,  흙길           ^  벤 다이어그램 나무
##  ~  물               r  바위          f  꽃(지나갈 수 있음)   g  표지판
##  u  그루터기         *  세이브 포인트
##
## [생명 테마 "bio"]  (세포 속)
##  #  세포막(막힘)   .  세포질          ,  통로            o  미토콘드리아
##  n  핵 조각        v  액포(물방울)    ~  배양액          f  섬모(지나갈 수 있음)
##  g  표본 라벨      *  세이브 포인트
##
## [광학 테마 "optics"]  (암실)
##  #  벽(막힘)       .  광학 테이블     ,  통로            m  거울
##  l  렌즈           e  레이저 발진기   s  스크린          b / B  바닥의 광선(가로/세로, 지나갈 수 있음)
##  g  단말기         *  세이브 포인트
##
## [서버 테마 "server"]
##  #  벽(막힘)       .  바닥            R  서버 랙         K  코어 기둥
##  c  케이블(지나갈 수 있음)   g  단말기   *  세이브 포인트
##
## 문/계단/출구는 방 데이터의 "doors"에 적힌 글자를 쓴다.
const P = preload("res://scripts/art/palette.gd")

const SOLID := {
	"school": "#=wbLBTdckptmeo*hvWASqPNFECQIiZjGyzK~OHVrYuMXJnagf",
	"forest": "#^~rgu*",
	"bio": "#onv~g*",
	"optics": "#mlesg*",
	"server": "#RKg*",
}


static func is_solid(theme: String, c: String) -> bool:
	var set: String = SOLID.get(theme, SOLID["school"])
	return set.contains(c)


## 테마에 맞는 타일 그리기
static func draw(ci: CanvasItem, theme: String, c: String, r: Rect2, tx: int, ty: int, style: String, t: float) -> void:
	match theme:
		"forest":
			draw_forest(ci, c, r, tx, ty, t)
		"bio":
			draw_bio(ci, c, r, tx, ty, t)
		"optics":
			draw_optics(ci, c, r, tx, ty, t)
		"server":
			draw_server(ci, c, r, tx, ty, t)
		_:
			draw_school(ci, c, r, tx, ty, style, t)


## 학교가 아닌 테마의 출구(다음 구역으로 가는 칸)
static func draw_exit(ci: CanvasItem, theme: String, r: Rect2, tx: int, ty: int, t: float) -> void:
	draw(ci, theme, ",", r, tx, ty, "", t)
	var a := 0.3 + 0.3 * sin(t * 3.0)
	ci.draw_rect(r, Color(1, 1, 0.7, a * 0.4))


static func _h(tx: int, ty: int, k: int) -> int:
	return absi(tx * 73856093 ^ ty * 19349663 ^ k * 83492791) % 1000


# ================================================================ 학교
## 바닥: terrazzo(복도, 광택 있는 인조석) / wood(교실 마루) / dark(컴퓨터실·천문대) / tile(급식실·화장실 타일) / grass(운동장)
static func school_floor(ci: CanvasItem, r: Rect2, tx: int, ty: int, style: String) -> void:
	var p := r.position
	match style:
		"roof":
			# 옥상: 녹색 방수 페인트 바닥, 이음매와 배수 줄
			var v := float(_h(tx, ty, 1) % 8) / 200.0
			ci.draw_rect(r, P.BENCH_700.lightened(v))
			ci.draw_rect(Rect2(p, Vector2(32, 1)), P.BENCH_700.darkened(0.2))
			ci.draw_rect(Rect2(p, Vector2(1, 32)), P.BENCH_700.darkened(0.2))
			if _h(tx, ty, 2) % 9 == 0:
				ci.draw_circle(p + Vector2(10 + _h(tx, ty, 3) % 12, 18), 4, Color(P.SKY_300, 0.5))
		"wood":
			var base := P.WOOD_500 if (ty % 2 == 0) else P.WOOD_500.darkened(0.05)
			ci.draw_rect(r, base)
			for i in 4:
				var y := p.y + i * 8
				ci.draw_line(Vector2(p.x, y), Vector2(r.end.x, y), P.WOOD_700, 1)
				var seam := p.x + float((tx * 13 + ty * 7 + i * 11) % 4) * 8.0 + 4.0
				ci.draw_line(Vector2(seam, y), Vector2(seam, y + 8), P.WOOD_700, 1)
				# 나뭇결
				var gx := p.x + float(_h(tx, ty, i) % 26) + 3.0
				ci.draw_line(Vector2(gx, y + 3), Vector2(gx + 5, y + 3), P.WOOD_300, 1)
		"dark":
			ci.draw_rect(r, P.INLAY_900 if (tx + ty) % 2 == 0 else P.INLAY_900.darkened(0.1))
			ci.draw_rect(r, P.NIGHT_950, false, 1)
			if _h(tx, ty, 4) % 7 == 0:
				ci.draw_line(p + Vector2(4, 16), p + Vector2(28, 16), P.INLAY_900.lightened(0.12), 1)
		"tile":
			ci.draw_rect(r, P.WALL_100)
			ci.draw_rect(Rect2(p, Vector2(16, 16)), P.WALL_100.darkened(0.05))
			ci.draw_rect(Rect2(p + Vector2(16, 16), Vector2(16, 16)), P.WALL_100.darkened(0.05))
			ci.draw_rect(r, P.WALL_300, false, 1)
		"grass":
			var v := float(_h(tx, ty, 0) % 8) / 100.0
			# 운동장 천연 잔디: 깎은 결이 줄무늬로 남는다
			ci.draw_rect(r, P.LIME_700.lightened(v) if (tx / 2) % 2 == 0 else P.LIME_700.lightened(v).darkened(0.08))
			for i in 3:
				var hsh := _h(tx, ty, i + 1)
				var q := p + Vector2(hsh % 28 + 2, (hsh / 31) % 26 + 4)
				ci.draw_line(q, q + Vector2(1, -3), P.LIME_500, 1)
		_:
			# 복도 인조석: 체크 + 박힌 돌 조각 + 광택 줄
			var base2 := P.GRANITE_300 if (tx + ty) % 2 == 0 else P.GRANITE_300.darkened(0.05)
			ci.draw_rect(r, base2)
			ci.draw_rect(r, P.GRANITE_500, false, 1)
			for i in 4:
				var hsh2 := _h(tx, ty, i)
				var col: Color = [P.GRANITE_700, P.GRANITE_100, P.WOOD_700, P.INLAY_900][i]
				ci.draw_rect(Rect2(p + Vector2(hsh2 % 28 + 2, (hsh2 / 29) % 28 + 2), Vector2(2, 2 if i % 2 == 0 else 1)), col)
			ci.draw_line(p + Vector2(2, 6), p + Vector2(10, 6), Color(P.PAPER, 0.12), 1)


## 벽: 위는 미색 페인트, 아래는 초록 징두리판, 맨 아래 걸레받이
static func school_wall(ci: CanvasItem, r: Rect2) -> void:
	var p := r.position
	ci.draw_rect(r, P.WALL_100)
	ci.draw_line(p + Vector2(0, 1), p + Vector2(32, 1), P.WALL_100.lightened(0.3), 1)
	ci.draw_line(p + Vector2(31, 0), p + Vector2(31, 18), P.WALL_300, 1)
	ci.draw_rect(Rect2(p + Vector2(0, 17), Vector2(32, 2)), P.WOOD_500)
	ci.draw_rect(Rect2(p + Vector2(0, 19), Vector2(32, 10)), P.WALL_300)
	ci.draw_line(p + Vector2(0, 24), p + Vector2(32, 24), P.WALL_500, 1)
	ci.draw_rect(Rect2(p + Vector2(0, 29), Vector2(32, 3)), P.INLAY_900)


static func draw_school(ci: CanvasItem, c: String, r: Rect2, tx: int, ty: int, style: String, t: float) -> void:
	var p := r.position
	match c:
		"#":
			if style != "roof":
				ci.draw_rect(r, P.NIGHT_950)
		"r":
			# 옥상 난간: 낮은 콘크리트 턱 + 쇠 난간
			ci.draw_rect(Rect2(p + Vector2(0, 14), Vector2(32, 18)), P.GRANITE_700)
			ci.draw_rect(Rect2(p + Vector2(0, 14), Vector2(32, 3)), P.GRANITE_500)
			ci.draw_line(p + Vector2(0, 2), p + Vector2(32, 2), P.WALL_300, 2)
			for i in 3:
				ci.draw_line(p + Vector2(4 + i * 11, 2), p + Vector2(4 + i * 11, 14), P.WALL_500, 2)
		"Y":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(14, 14), Vector2(4, 18)), P.INLAY_900)
			ci.draw_rect(Rect2(p + Vector2(1, -10), Vector2(30, 26)), P.NIGHT_900)
			ci.draw_rect(Rect2(p + Vector2(1, -10), Vector2(30, 26)), P.SKY_300, false, 1.5)
			var hy := _h(tx, ty, 5)
			var pts := PackedVector2Array()
			for i in 4:
				var q := p + Vector2(5 + (hy * (i + 3)) % 22, -6 + (hy * (i + 7)) % 18)
				pts.append(q)
				ci.draw_circle(q, 1.6, Color(P.PAPER, 0.7 + 0.3 * sin(t * 3.0 + i)))
			ci.draw_polyline(pts, Color(P.SKY_100, 0.5), 1)
		"u":
			# 천문대 돔 벽 (흰 반원 지붕의 일부)
			ci.draw_rect(r, P.GRANITE_100)
			ci.draw_line(p + Vector2(0, 8 + (tx % 2) * 8), p + Vector2(32, 8 + (tx % 2) * 8), P.GRANITE_300, 2)
			ci.draw_line(p + Vector2(16, 0), p + Vector2(16, 32), P.WALL_300, 1)
		"X":
			school_floor(ci, r, tx, ty, style)
		"J":
			# 중앙 홀의 노란 둥근 기둥
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(4, -26), Vector2(24, 56)), P.PILLAR_300)
			ci.draw_rect(Rect2(p + Vector2(4, -26), Vector2(6, 56)), P.PILLAR_300.lightened(0.3))
			ci.draw_rect(Rect2(p + Vector2(22, -26), Vector2(6, 56)), P.PILLAR_500)
			ci.draw_rect(Rect2(p + Vector2(2, 26), Vector2(28, 5)), P.INLAY_900)
		"n":
			# 유리 난간: 아래로 뚫린 중앙 홀이 비쳐 보인다
			ci.draw_rect(r, P.INLAY_900)
			ci.draw_rect(Rect2(p + Vector2(0, 6), Vector2(32, 22)), Color(P.SKY_100, 0.35))
			ci.draw_line(p + Vector2(0, 5), p + Vector2(32, 5), P.WALL_100, 2)
			ci.draw_line(p + Vector2(4, 26), p + Vector2(28, 10), Color(P.PAPER, 0.25), 1)
			ci.draw_rect(Rect2(p + Vector2(15, 5), Vector2(2, 24)), P.WALL_300)
		"a":
			# 아트리움 아래층 (어둡게 내려다보이는 1층 바닥)
			ci.draw_rect(r, P.INLAY_900 if (tx + ty) % 2 == 0 else P.INLAY_900)
			if (tx * 7 + ty * 3) % 11 == 0:
				ci.draw_rect(Rect2(p + Vector2(10, 8), Vector2(10, 14)), Color(P.PILLAR_700, 0.6))
			ci.draw_rect(r, Color(P.NIGHT_950, 0.25))
		"^":
			# 바닥의 마름모 무늬
			school_floor(ci, r, tx, ty, style)
			var cxy := p + Vector2(16, 16)
			ci.draw_colored_polygon(PackedVector2Array([cxy + Vector2(0, -15), cxy + Vector2(15, 0), cxy + Vector2(0, 15), cxy + Vector2(-15, 0)]), P.INLAY_900)
			ci.draw_colored_polygon(PackedVector2Array([cxy + Vector2(0, -9), cxy + Vector2(9, 0), cxy + Vector2(0, 9), cxy + Vector2(-9, 0)]), P.WALL_300)
		"g":
			# 작은 당구대 (ATOZ)
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(0, 8), Vector2(32, 16)), P.WOOD_900)
			ci.draw_rect(Rect2(p + Vector2(2, 10), Vector2(28, 12)), P.BENCH_500)
			ci.draw_circle(p + Vector2(10, 15), 2, P.PAPER)
			ci.draw_circle(p + Vector2(20, 17), 2, P.SIGNAL)
			ci.draw_rect(Rect2(p + Vector2(3, 24), Vector2(3, 7)), P.INLAY_900)
			ci.draw_rect(Rect2(p + Vector2(26, 24), Vector2(3, 7)), P.INLAY_900)
		"f":
			# 분홍 스웨터 곰 인형 + 빨간 우체통
			school_floor(ci, r, tx, ty, style)
			var bc := P.PILLAR_500
			ci.draw_circle(p + Vector2(14, 4), 8, bc)
			ci.draw_circle(p + Vector2(8, -3), 3, bc)
			ci.draw_circle(p + Vector2(20, -3), 3, bc)
			ci.draw_circle(p + Vector2(14, 7), 3, P.PEACH_300)
			ci.draw_circle(p + Vector2(11, 2), 1, P.NIGHT_950)
			ci.draw_circle(p + Vector2(17, 2), 1, P.NIGHT_950)
			ci.draw_rect(Rect2(p + Vector2(6, 11), Vector2(16, 14)), P.PEACH_300)
			ci.draw_circle(p + Vector2(8, 28), 4, bc)
			ci.draw_circle(p + Vector2(20, 28), 4, bc)
			ci.draw_rect(Rect2(p + Vector2(24, 12), Vector2(7, 12)), P.SIGNAL)
			ci.draw_rect(Rect2(p + Vector2(26, 24), Vector2(3, 8)), P.SIGNAL)
		"M":
			# 큰 굴절 망원경 (한 칸에 그리고, 둘레는 X 로 막는다)
			school_floor(ci, r, tx, ty, style)
			ci.draw_circle(p + Vector2(16, 30), 22, P.INLAY_900)
			ci.draw_rect(Rect2(p + Vector2(8, 4), Vector2(16, 28)), P.INLAY_900)
			var tip := p + Vector2(60, -52 + sin(t * 0.3) * 2.0)
			ci.draw_line(p + Vector2(-20, 34), tip, P.WALL_100, 18)
			ci.draw_line(p + Vector2(-20, 34), p + Vector2(-6, 22), P.INLAY_900, 18)
			ci.draw_circle(tip, 10, P.NIGHT_900)
			ci.draw_circle(tip, 5, Color(P.SKY_100, 0.6 + 0.3 * sin(t * 2.0)))
		".":
			school_floor(ci, r, tx, ty, style)
		"=":
			school_wall(ci, r)
			# 가끔 콘센트나 작은 안내문
			match _h(tx, ty, 7) % 9:
				0:
					ci.draw_rect(Rect2(p + Vector2(12, 21), Vector2(8, 6)), P.WALL_100)
					ci.draw_rect(Rect2(p + Vector2(14, 23), Vector2(1, 2)), P.INLAY_900)
					ci.draw_rect(Rect2(p + Vector2(17, 23), Vector2(1, 2)), P.INLAY_900)
				1:
					ci.draw_rect(Rect2(p + Vector2(9, 5), Vector2(14, 9)), P.PAPER)
					ci.draw_line(p + Vector2(11, 8), p + Vector2(21, 8), P.GRANITE_500, 1)
					ci.draw_line(p + Vector2(11, 11), p + Vector2(18, 11), P.GRANITE_500, 1)
		"w":
			school_wall(ci, r)
			ci.draw_rect(Rect2(p + Vector2(2, 1), Vector2(28, 20)), P.WALL_500)
			ci.draw_rect(Rect2(p + Vector2(4, 3), Vector2(24, 16)), P.NIGHT_900)
			# 밤하늘: 달과 별
			if tx % 5 == 0:
				ci.draw_circle(p + Vector2(22, 8), 3, P.PAPER)
				ci.draw_circle(p + Vector2(23, 7), 3, P.NIGHT_900)
			for i in 2:
				var sx := 6 + (_h(tx, ty, i) % 18)
				var sy := 5 + (_h(tx, i, ty) % 10)
				if sin(t * 2.0 + tx + i * 3) > -0.2:
					ci.draw_rect(Rect2(p + Vector2(sx, sy), Vector2(1, 1)), P.PAPER)
			ci.draw_line(p + Vector2(16, 3), p + Vector2(16, 19), P.WALL_500, 2)
			ci.draw_line(p + Vector2(5, 4), p + Vector2(9, 4), Color(P.BLUE_500, 0.5), 1)
		"b":
			school_wall(ci, r)
			ci.draw_rect(Rect2(p + Vector2(1, 1), Vector2(30, 17)), P.WOOD_700)
			ci.draw_rect(Rect2(p + Vector2(2, 2), Vector2(28, 15)), P.WOOD_300)
			var k := _h(tx, ty, 2) % 3
			ci.draw_rect(Rect2(p + Vector2(4, 4), Vector2(9, 11)), P.PAPER)
			ci.draw_line(p + Vector2(5, 7), p + Vector2(12, 7), P.GRANITE_700, 1)
			ci.draw_line(p + Vector2(5, 10), p + Vector2(11, 10), P.GRANITE_700, 1)
			ci.draw_rect(Rect2(p + Vector2(15, 4), Vector2(12, 8)), [P.PILLAR_300, P.SKY_100, P.PEACH_300][k])
			ci.draw_rect(Rect2(p + Vector2(17, 13), Vector2(8, 3)), P.PAPER)
			ci.draw_circle(p + Vector2(8, 4), 1.5, P.SIGNAL)
			ci.draw_circle(p + Vector2(21, 4), 1.5, P.BLUE_500)
		"N":
			# 포스터 벽: R&E 발표회, 동아리 모집, 융합 축제
			school_wall(ci, r)
			var kind := _h(tx, ty, 3) % 3
			var col2: Color = [P.VIOLET_500, P.PEACH_500, P.BENCH_500][kind]
			ci.draw_rect(Rect2(p + Vector2(6, 1), Vector2(20, 17)), P.PAPER)
			ci.draw_rect(Rect2(p + Vector2(7, 2), Vector2(18, 7)), col2)
			ci.draw_line(p + Vector2(9, 5), p + Vector2(23, 5), Color(P.PAPER, 0.9), 2)
			if kind == 0:
				ci.draw_circle(p + Vector2(20, 12), 3, P.VIOLET_500)
			elif kind == 1:
				ci.draw_rect(Rect2(p + Vector2(18, 10), Vector2(5, 5)), P.PEACH_500)
			ci.draw_line(p + Vector2(9, 12), p + Vector2(23, 12), P.GRANITE_700, 1)
			ci.draw_line(p + Vector2(9, 15), p + Vector2(20, 15), P.GRANITE_700, 1)
		"F":
			# 소화기 함
			school_wall(ci, r)
			ci.draw_rect(Rect2(p + Vector2(8, 2), Vector2(16, 26)), P.WALL_300)
			ci.draw_rect(Rect2(p + Vector2(9, 3), Vector2(14, 24)), Color(P.SIGNAL, 0.25))
			ci.draw_rect(Rect2(p + Vector2(12, 9), Vector2(8, 16)), P.SIGNAL)
			ci.draw_rect(Rect2(p + Vector2(13, 6), Vector2(6, 4)), P.INLAY_900)
			ci.draw_line(p + Vector2(19, 8), p + Vector2(22, 14), P.INLAY_900, 1)
		"E":
			# 비상구 유도등 (초록 불빛)
			school_wall(ci, r)
			var g := 0.8 + 0.2 * sin(t * 1.5)
			ci.draw_rect(Rect2(p + Vector2(4, 3), Vector2(24, 11)), P.BENCH_500.darkened(1.0 - g))
			ci.draw_rect(Rect2(p + Vector2(4, 3), Vector2(24, 11)), P.WALL_100, false, 1)
			# 달리는 사람 + 문
			ci.draw_rect(Rect2(p + Vector2(20, 5), Vector2(5, 7)), P.PAPER)
			ci.draw_circle(p + Vector2(12, 6), 1.5, P.PAPER)
			ci.draw_line(p + Vector2(12, 7), p + Vector2(11, 10), P.PAPER, 1.5)
			ci.draw_line(p + Vector2(11, 10), p + Vector2(9, 13), P.PAPER, 1)
			ci.draw_line(p + Vector2(11, 10), p + Vector2(14, 12), P.PAPER, 1)
			ci.draw_line(p + Vector2(11, 8), p + Vector2(15, 7), P.PAPER, 1)
		"C":
			# CCTV
			school_wall(ci, r)
			ci.draw_rect(Rect2(p + Vector2(14, 2), Vector2(4, 4)), P.INLAY_900)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(8, 5), p + Vector2(22, 5), p + Vector2(24, 12), p + Vector2(10, 12)]), P.WALL_100)
			ci.draw_circle(p + Vector2(11, 10), 2, P.NIGHT_950)
			if sin(t * 3.0) > 0.0:
				ci.draw_circle(p + Vector2(21, 7), 1.2, P.SIGNAL)
		"Q":
			# 정수기
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(7, -14), Vector2(18, 42)), P.PAPER)
			ci.draw_rect(Rect2(p + Vector2(7, -14), Vector2(18, 42)), P.WALL_300, false, 1)
			ci.draw_rect(Rect2(p + Vector2(10, -8), Vector2(12, 8)), P.SKY_100)
			ci.draw_circle(p + Vector2(12, 4), 2, P.BLUE_500)
			ci.draw_circle(p + Vector2(20, 4), 2, P.SIGNAL)
			ci.draw_rect(Rect2(p + Vector2(10, 10), Vector2(12, 3)), P.GRANITE_500)
			ci.draw_rect(Rect2(p + Vector2(10, -12), Vector2(3, 2)), P.LIME_300 if sin(t * 2.0) > -0.5 else P.BENCH_700)
		"I":
			# 신발장
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(0, -12), Vector2(32, 42)), P.WOOD_700)
			for row in 4:
				for col3 in 2:
					var cell := Rect2(p + Vector2(2 + col3 * 15, -10 + row * 10), Vector2(13, 8))
					ci.draw_rect(cell, P.WOOD_900)
					if _h(tx + col3, ty, row) % 3 != 0:
						ci.draw_rect(Rect2(cell.position + Vector2(2, 4), Vector2(9, 4)), P.PAPER)
						ci.draw_line(cell.position + Vector2(3, 5), cell.position + Vector2(9, 5), P.BLUE_500, 1)
		"i":
			# 아이맥 책상 (맥실)
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(0, 10), Vector2(32, 6)), P.WALL_100)
			ci.draw_rect(Rect2(p + Vector2(0, 16), Vector2(32, 10)), P.WALL_500)
			ci.draw_rect(Rect2(p + Vector2(5, -10), Vector2(22, 17)), P.GRANITE_100)
			ci.draw_rect(Rect2(p + Vector2(6, -9), Vector2(20, 12)), P.ACCENTS[int(t * 0.3 + tx) % P.ACCENTS.size()].lightened(0.2))
			ci.draw_rect(Rect2(p + Vector2(6, 3), Vector2(20, 3)), P.WALL_100)
			ci.draw_rect(Rect2(p + Vector2(14, 6), Vector2(4, 4)), P.WALL_300)
		"Z":
			# 레이저 커팅기
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(0, -10), Vector2(32, 38)), P.INLAY_900)
			ci.draw_rect(Rect2(p + Vector2(3, -7), Vector2(26, 14)), Color(P.PEACH_500, 0.55))
			var lx := 6.0 + 20.0 * (0.5 + 0.5 * sin(t * 2.3 + tx))
			ci.draw_line(p + Vector2(lx, -7), p + Vector2(lx, 6), P.SIGNAL, 1)
			ci.draw_circle(p + Vector2(lx, 5), 1.5, P.PILLAR_300)
			ci.draw_rect(Rect2(p + Vector2(4, 14), Vector2(10, 4)), P.INLAY_900)
			ci.draw_circle(p + Vector2(25, 16), 2, P.SIGNAL)
		"j":
			# 화이트보드
			school_wall(ci, r)
			ci.draw_rect(Rect2(p + Vector2(0, 2), Vector2(32, 20)), P.PAPER)
			ci.draw_rect(Rect2(p + Vector2(0, 21), Vector2(32, 2)), P.WALL_300)
			var k2 := _h(tx, ty, 5) % 4
			if k2 == 0:
				ci.draw_arc(p + Vector2(12, 11), 5, 0, TAU, 10, P.VIOLET_300, 1)
				ci.draw_line(p + Vector2(18, 8), p + Vector2(28, 14), P.SIGNAL, 1)
			elif k2 == 1:
				ci.draw_line(p + Vector2(4, 8), p + Vector2(26, 8), P.NIGHT_950, 1)
				ci.draw_line(p + Vector2(4, 13), p + Vector2(20, 13), P.NIGHT_950, 1)
		"L":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(1, -10), Vector2(30, 40)), P.SKY_300)
			ci.draw_rect(Rect2(p + Vector2(1, -10), Vector2(30, 40)), P.VIOLET_500, false, 2)
			ci.draw_rect(Rect2(p + Vector2(1, -10), Vector2(30, 4)), P.SKY_300)
			for i in 3:
				ci.draw_line(p + Vector2(8, -2 + i * 3), p + Vector2(24, -2 + i * 3), P.VIOLET_500, 1)
			# 이름표
			ci.draw_rect(Rect2(p + Vector2(6, 8), Vector2(12, 5)), P.PAPER)
			ci.draw_line(p + Vector2(7, 10), p + Vector2(7 + _h(tx, ty, 1) % 9, 10), P.INLAY_900, 1)
			ci.draw_rect(Rect2(p + Vector2(23, 12), Vector2(3, 7)), P.GRANITE_100)
			# 스티커 (가끔)
			if _h(tx, ty, 6) % 5 == 0:
				ci.draw_circle(p + Vector2(10, 20), 3, P.ACCENTS[_h(tx, ty, 8) % P.ACCENTS.size()])
		"B":
			school_wall(ci, r)
			ci.draw_rect(Rect2(p + Vector2(0, 2), Vector2(32, 22)), P.BENCH_700)
			ci.draw_rect(Rect2(p + Vector2(0, 1), Vector2(32, 2)), P.WOOD_700)
			ci.draw_rect(Rect2(p + Vector2(0, 24), Vector2(32, 3)), P.WOOD_700)
			# 분필 자국과 분필
			ci.draw_line(p + Vector2(3, 18), p + Vector2(10 + _h(tx, ty, 2) % 15, 17), Color(P.GRANITE_300, 0.5), 1)
			if _h(tx, ty, 3) % 4 == 0:
				ci.draw_rect(Rect2(p + Vector2(8, 25), Vector2(5, 1)), P.PAPER)
				ci.draw_rect(Rect2(p + Vector2(16, 25), Vector2(4, 1)), P.PILLAR_300)
		"T":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(0, -4), Vector2(32, 30)), P.WOOD_900)
			ci.draw_rect(Rect2(p + Vector2(0, -4), Vector2(32, 12)), P.WOOD_700)
			ci.draw_line(p + Vector2(0, 8), p + Vector2(32, 8), P.WOOD_900, 1)
			if _h(tx, ty, 1) % 3 == 0:
				ci.draw_rect(Rect2(p + Vector2(6, -2), Vector2(12, 8)), P.PAPER)
				ci.draw_rect(Rect2(p + Vector2(21, -3), Vector2(6, 7)), P.GRANITE_100)
		"d":
			school_floor(ci, r, tx, ty, style)
			# 의자 (책상 아래쪽)
			ci.draw_rect(Rect2(p + Vector2(9, 22), Vector2(14, 6)), P.WOOD_900)
			ci.draw_line(p + Vector2(10, 28), p + Vector2(10, 31), P.INLAY_900, 1)
			ci.draw_line(p + Vector2(22, 28), p + Vector2(22, 31), P.INLAY_900, 1)
			ci.draw_rect(Rect2(p + Vector2(2, 4), Vector2(28, 14)), P.PEACH_500)
			ci.draw_line(p + Vector2(2, 4), p + Vector2(30, 4), P.PEACH_300, 1)
			ci.draw_rect(Rect2(p + Vector2(2, 18), Vector2(28, 4)), P.WOOD_700)
			ci.draw_line(p + Vector2(4, 22), p + Vector2(4, 30), P.INLAY_900, 2)
			ci.draw_line(p + Vector2(28, 22), p + Vector2(28, 30), P.INLAY_900, 2)
			# 책상 위 물건
			match _h(tx, ty, 9) % 5:
				0:
					ci.draw_rect(Rect2(p + Vector2(6, 7), Vector2(10, 7)), P.PAPER)
					ci.draw_line(p + Vector2(7, 9), p + Vector2(14, 9), P.GRANITE_500, 1)
				1:
					ci.draw_rect(Rect2(p + Vector2(18, 7), Vector2(9, 6)), P.BLUE_500)
				2:
					ci.draw_line(p + Vector2(8, 10), p + Vector2(20, 8), P.PILLAR_300, 2)
		"c":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(1, 8), Vector2(30, 12)), P.WALL_300)
			ci.draw_rect(Rect2(p + Vector2(1, 20), Vector2(30, 6)), P.GRANITE_500)
			ci.draw_rect(Rect2(p + Vector2(6, -8), Vector2(20, 16)), P.INLAY_900)
			var glow := 0.75 + 0.25 * sin(t * 5.0 + tx * 1.7 + ty)
			ci.draw_rect(Rect2(p + Vector2(8, -6), Vector2(16, 12)), P.BENCH_500.lightened(0.25).darkened(1.0 - glow))
			ci.draw_rect(Rect2(p + Vector2(10, -3 + int(fmod(t * 6.0 + tx, 8.0))), Vector2(12, 1)), P.BENCH_700)
			ci.draw_rect(Rect2(p + Vector2(14, 8), Vector2(4, 3)), P.INLAY_900)
			ci.draw_rect(Rect2(p + Vector2(8, 13), Vector2(16, 4)), P.INLAY_900)
			ci.draw_rect(Rect2(p + Vector2(25, 13), Vector2(3, 5)), P.GRANITE_100)
		"G":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(0, -6), Vector2(32, 3)), P.WALL_100)
			ci.draw_rect(Rect2(p + Vector2(0, -6), Vector2(3, 30)), P.WALL_100)
			ci.draw_rect(Rect2(p + Vector2(29, -6), Vector2(3, 30)), P.WALL_100)
			for i in 4:
				ci.draw_line(p + Vector2(3 + i * 8, -3), p + Vector2(3 + i * 8, 22), Color(P.PAPER, 0.25), 1)
			for i in 3:
				ci.draw_line(p + Vector2(3, 2 + i * 7), p + Vector2(29, 2 + i * 7), Color(P.PAPER, 0.25), 1)
		"y":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(13, 8), Vector2(6, 22)), P.WOOD_900)
			ci.draw_circle(p + Vector2(16, 0), 15, P.LIME_700)
			ci.draw_circle(p + Vector2(9, 6), 10, P.LIME_700)
			ci.draw_circle(p + Vector2(23, 5), 10, P.BENCH_700)
			ci.draw_circle(p + Vector2(13, -5), 4, Color(P.BENCH_500, 0.6))
		"z":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(1, 10), Vector2(30, 6)), P.WOOD_700)
			ci.draw_rect(Rect2(p + Vector2(1, 3), Vector2(30, 4)), P.WOOD_700)
			ci.draw_rect(Rect2(p + Vector2(3, 16), Vector2(3, 10)), P.INLAY_900)
			ci.draw_rect(Rect2(p + Vector2(26, 16), Vector2(3, 10)), P.INLAY_900)
		"K":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(-2, -8), Vector2(36, 36)), P.GRANITE_700)
			ci.draw_rect(Rect2(p + Vector2(-2, -8), Vector2(36, 5)), P.WALL_500)
			for i in 3:
				ci.draw_line(p + Vector2(4, 4 + i * 6), p + Vector2(28, 4 + i * 6), P.PEACH_300, 2)
		"~":
			var wave := 0.5 + 0.5 * sin(t * 1.5 + tx * 0.7 + ty)
			ci.draw_rect(r, P.NIGHT_900)
			ci.draw_line(p + Vector2(4, 10 + wave * 2), p + Vector2(14, 10 + wave * 2), Color(P.BLUE_500, 0.6), 1)
			ci.draw_line(p + Vector2(16, 22 - wave * 2), p + Vector2(28, 22 - wave * 2), Color(P.BLUE_500, 0.6), 1)
			# 물에 비친 별
			if _h(tx, ty, 4) % 4 == 0:
				ci.draw_rect(Rect2(p + Vector2(_h(tx, ty, 5) % 24 + 4, _h(tx, ty, 6) % 24 + 4), Vector2(1, 1)), Color(P.PAPER, 0.5 + 0.5 * wave))
		"O":
			ci.draw_rect(r, P.NIGHT_900)
			ci.draw_circle(p + Vector2(16, 18), 13, P.WALL_500)
			ci.draw_circle(p + Vector2(16, 18), 10, P.VIOLET_500)
			for i in 5:
				var a := -PI / 2.0 + (i - 2) * 0.35
				var h2 := 14.0 + sin(t * 4.0 + i) * 3.0
				ci.draw_line(p + Vector2(16, 14), p + Vector2(16, 14) + Vector2(cos(a), sin(a)) * h2, Color(P.SKY_100, 0.7), 1)
		"H":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(0, -10), Vector2(32, 40)), Color(P.SKY_100, 0.35))
			ci.draw_rect(Rect2(p + Vector2(0, -10), Vector2(32, 40)), P.WALL_100, false, 1)
			ci.draw_line(p + Vector2(16, -10), p + Vector2(16, 30), P.WALL_100, 1)
			ci.draw_line(p + Vector2(0, 8), p + Vector2(32, 8), P.WALL_100, 1)
			ci.draw_circle(p + Vector2(8, 20), 5, Color(P.BENCH_500, 0.8))
			ci.draw_circle(p + Vector2(24, 18), 6, Color(P.BENCH_500, 0.8))
		"V":
			ci.draw_rect(r, P.WOOD_900)
			for i in 3:
				ci.draw_rect(Rect2(p + Vector2(0, 4 + i * 10), Vector2(32, 4)), P.WOOD_900)
				for j in 3:
					ci.draw_circle(p + Vector2(6 + j * 10, 4 + i * 10), 3, P.LIME_500)
		"k":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(0, -14), Vector2(32, 44)), P.WOOD_900)
			for row in 3:
				ci.draw_rect(Rect2(p + Vector2(2, -12 + row * 14), Vector2(28, 11)), P.WOOD_900)
				for i in 6:
					var hh := 6 + _h(tx + i, ty, row) % 4
					var col: Color = P.ACCENTS[_h(tx, i, row) % P.ACCENTS.size()]
					ci.draw_rect(Rect2(p + Vector2(3 + i * 4.5, -1 + row * 14 - hh), Vector2(3.5, hh)), col)
		"p":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(9, 16), Vector2(14, 12)), P.WOOD_700)
			ci.draw_circle(p + Vector2(16, 8), 10, P.BENCH_500)
			ci.draw_circle(p + Vector2(10, 12), 6, P.BENCH_500)
			ci.draw_circle(p + Vector2(22, 11), 6, P.BENCH_500)
		"t":
			school_floor(ci, r, tx, ty, style)
			ci.draw_line(p + Vector2(16, 12), p + Vector2(6, 30), P.INLAY_900, 2)
			ci.draw_line(p + Vector2(16, 12), p + Vector2(26, 30), P.INLAY_900, 2)
			ci.draw_line(p + Vector2(16, 12), p + Vector2(16, 30), P.INLAY_900, 2)
			ci.draw_line(p + Vector2(2, 16), p + Vector2(28, -8), P.WALL_100, 9)
			ci.draw_line(p + Vector2(2, 16), p + Vector2(8, 10), P.INLAY_900, 9)
			ci.draw_circle(p + Vector2(28, -8), 4, P.BLUE_500)
		"m":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(2, -6), Vector2(28, 34)), P.INLAY_900)
			ci.draw_rect(Rect2(p + Vector2(5, -2), Vector2(22, 20)), P.NIGHT_950)
			var hx := 8.0 + 14.0 * (0.5 + 0.5 * sin(t * 3.0 + tx))
			ci.draw_rect(Rect2(p + Vector2(hx, 0), Vector2(4, 5)), P.PILLAR_500)
			ci.draw_rect(Rect2(p + Vector2(10, 12), Vector2(12, 6)), P.SKY_100)
			ci.draw_rect(Rect2(p + Vector2(6, 21), Vector2(6, 3)), P.LIME_300)
		"e":
			school_floor(ci, r, tx, ty, style)
			ci.draw_line(p + Vector2(8, 30), p + Vector2(14, -6), P.WOOD_700, 2)
			ci.draw_line(p + Vector2(24, 30), p + Vector2(18, -6), P.WOOD_700, 2)
			ci.draw_rect(Rect2(p + Vector2(5, -4), Vector2(22, 22)), P.PAPER)
			ci.draw_circle(p + Vector2(13, 5), 5, Color(P.SIGNAL, 0.7))
			ci.draw_circle(p + Vector2(19, 9), 5, Color(P.VIOLET_300, 0.7))
		"o":
			school_floor(ci, r, tx, ty, style)
			ci.draw_circle(p + Vector2(16, 14), 14, P.WOOD_700)
			ci.draw_circle(p + Vector2(16, 12), 14, P.PEACH_500)
		"h":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(2, -8), Vector2(28, 38)), P.WOOD_700)
			ci.draw_rect(Rect2(p + Vector2(4, -2), Vector2(24, 30)), P.SKY_100)
			ci.draw_rect(Rect2(p + Vector2(6, -5), Vector2(20, 8)), P.PAPER)
			ci.draw_rect(Rect2(p + Vector2(4, 12), Vector2(24, 16)), P.BLUE_500)
		"v":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(2, -14), Vector2(28, 44)), P.SIGNAL)
			ci.draw_rect(Rect2(p + Vector2(5, -10), Vector2(16, 22)), Color(P.SKY_100, 0.5 + 0.3 * sin(t * 2.0)))
			for i in 6:
				ci.draw_rect(Rect2(p + Vector2(6 + (i % 3) * 5, -8 + (i / 3) * 10), Vector2(3, 7)), P.ACCENTS[i % P.ACCENTS.size()])
			ci.draw_rect(Rect2(p + Vector2(24, -6), Vector2(4, 10)), P.INLAY_900)
			ci.draw_rect(Rect2(p + Vector2(6, 18), Vector2(20, 7)), P.INLAY_900)
		"W":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(2, -6), Vector2(28, 36)), P.WALL_100)
			ci.draw_rect(Rect2(p + Vector2(2, -6), Vector2(28, 7)), P.WALL_300)
			ci.draw_circle(p + Vector2(16, 14), 10, P.VIOLET_500)
			ci.draw_arc(p + Vector2(16, 14), 7, t * 5.0, t * 5.0 + 4.0, 10, P.SKY_100, 2)
		"A":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(0, -14), Vector2(32, 44)), P.WOOD_900)
			for row in 2:
				ci.draw_rect(Rect2(p + Vector2(2, -12 + row * 20), Vector2(28, 17)), Color(P.SKY_100, 0.35))
				for i in 2:
					var q := p + Vector2(9 + i * 14, -1 + row * 20)
					ci.draw_rect(Rect2(q + Vector2(-3, -6), Vector2(6, 5)), P.PILLAR_300)
					ci.draw_rect(Rect2(q + Vector2(-1, -1), Vector2(2, 3)), P.PILLAR_300)
					ci.draw_rect(Rect2(q + Vector2(-3, 2), Vector2(6, 2)), P.PILLAR_700)
		"S":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(1, 2), Vector2(30, 12)), P.VIOLET_500)
			ci.draw_rect(Rect2(p + Vector2(1, 12), Vector2(30, 14)), P.VIOLET_300)
			ci.draw_line(p + Vector2(16, 12), p + Vector2(16, 26), P.VIOLET_500, 1)
		"q":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(3, -12), Vector2(26, 40)), P.INLAY_900)
			ci.draw_rect(Rect2(p + Vector2(6, -8), Vector2(20, 14)), P.ACCENTS[int(t * 2.0) % P.ACCENTS.size()])
			ci.draw_circle(p + Vector2(16, 17), 6, P.INLAY_900)
			ci.draw_circle(p + Vector2(16, 17), 2 + sin(t * 8.0), P.WALL_500)
		"P":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(Rect2(p + Vector2(0, -8), Vector2(32, 26)), P.NIGHT_950)
			ci.draw_rect(Rect2(p + Vector2(1, 10), Vector2(30, 8)), P.PAPER)
			for i in 7:
				ci.draw_rect(Rect2(p + Vector2(4 + i * 4, 10), Vector2(2, 5)), P.NIGHT_950)
		"x":
			ci.draw_rect(r, P.SIGNAL.darkened(0.45))
			ci.draw_rect(Rect2(p + Vector2(0, 0), Vector2(32, 2)), P.PILLAR_500 if ty % 3 == 0 else P.SIGNAL.darkened(0.45))
		"_":
			school_floor(ci, r, tx, ty, style)
			ci.draw_rect(r, Color(P.NIGHT_900, 0.45))
		"*":
			school_floor(ci, r, tx, ty, style)
			star(ci, p + Vector2(16, 16), 8.0 + sin(t * 4.0) * 1.5, P.PILLAR_300, t)
		_:
			school_floor(ci, r, tx, ty, style)


static func draw_school_door(ci: CanvasItem, d: Dictionary, r: Rect2, tx: int, ty: int, style: String, blocked: bool, t: float) -> void:
	var p := r.position
	match d.get("style", "door"):
		"stairs":
			ci.draw_rect(r, P.GRANITE_700)
			for i in 5:
				ci.draw_rect(Rect2(p + Vector2(0, i * 6 + 2), Vector2(32, 3)), P.GRANITE_700)
			ci.draw_rect(Rect2(p, Vector2(32, 3)), P.PILLAR_300)
			if blocked:
				# 셔터
				ci.draw_rect(r, P.GRANITE_700)
				for i in 6:
					ci.draw_line(p + Vector2(0, i * 5.5 + 2), p + Vector2(32, i * 5.5 + 2), P.INLAY_900, 1)
				var blink := 0.5 + 0.5 * sin(t * 4.0)
				ci.draw_rect(Rect2(p + Vector2(13, 12), Vector2(6, 6)), Color(P.SIGNAL, 0.4 + 0.6 * blink))
		"open":
			school_floor(ci, r, tx, ty, style)
		_:
			school_wall(ci, r)
			ci.draw_rect(Rect2(p + Vector2(2, 0), Vector2(28, 32)), P.WOOD_700)
			ci.draw_rect(Rect2(p + Vector2(2, 0), Vector2(28, 32)), P.WOOD_900, false, 2)
			var glass := P.NIGHT_900
			if d.has("glow"):
				var gcol: Color = d["glow"]
				glass = gcol.lerp(P.NIGHT_900, 0.3 + 0.3 * sin(t * 3.0))
			ci.draw_rect(Rect2(p + Vector2(7, 5), Vector2(9, 10)), glass)
			ci.draw_rect(Rect2(p + Vector2(22, 14), Vector2(3, 6)), P.GRANITE_100)


# ================================================================ 숲
static func forest_grass(ci: CanvasItem, r: Rect2, tx: int, ty: int) -> void:
	# '집합과 명제의 방': 끝없이 넓어진 교실 바닥 (초록빛이 도는 마룻바닥, 사이사이 풀)
	var v := float(_h(tx, ty, 0) % 10) / 120.0
	ci.draw_rect(r, Color(0.2 + v, 0.27 + v, 0.2 + v * 0.5))
	ci.draw_line(r.position + Vector2(0, 31), r.position + Vector2(32, 31), Color(0.12, 0.18, 0.13), 1)
	if (tx + ty) % 2 == 0:
		ci.draw_line(r.position + Vector2(_h(tx, ty, 4) % 32, 0), r.position + Vector2(_h(tx, ty, 4) % 32, 31), Color(0.14, 0.2, 0.15), 1)
	for i in 2:
		var hsh := _h(tx, ty, i + 1)
		var q := r.position + Vector2(hsh % 28 + 2, (hsh / 31) % 26 + 4)
		ci.draw_line(q, q + Vector2(0, -3), Color(0.3, 0.52, 0.32), 1)


static func draw_forest(ci: CanvasItem, c: String, r: Rect2, tx: int, ty: int, t: float) -> void:
	var p := r.position
	match c:
		"#":
			# 끝없는 칠판 벽: 분필 자국이 희미하게 남아 있다
			ci.draw_rect(r, Color(0.05, 0.13, 0.1))
			ci.draw_rect(Rect2(p + Vector2(0, 0), Vector2(32, 2)), Color(0.12, 0.09, 0.06))
			var hh := _h(tx, ty, 2)
			if hh % 4 == 0:
				ci.draw_line(p + Vector2(4, 10 + hh % 12), p + Vector2(20 + hh % 10, 8 + hh % 14), Color(0.8, 0.9, 0.85, 0.18), 1)
			if hh % 7 == 1:
				ci.draw_arc(p + Vector2(16, 18), 6, 0, TAU, 10, Color(0.8, 0.9, 0.85, 0.15), 1)
		",":
			ci.draw_rect(r, Color(0.44, 0.36, 0.26))
			for i in 3:
				var hsh := _h(tx, ty, i)
				ci.draw_rect(Rect2(p + Vector2(hsh % 28 + 2, (hsh / 29) % 28 + 2), Vector2(3, 2)), Color(0.34, 0.28, 0.2))
		"~":
			ci.draw_rect(r, Color(0.1, 0.25, 0.45))
			for i in 2:
				var x := fmod(t * 10.0 + _h(tx, ty, i) % 32, 32.0)
				ci.draw_line(p + Vector2(x, 8 + i * 14), p + Vector2(minf(x + 8, 32), 8 + i * 14), Color(0.5, 0.75, 0.95, 0.7), 1)
		"^":
			forest_grass(ci, r, tx, ty)
			ci.draw_rect(Rect2(p + Vector2(12, 6), Vector2(8, 24)), Color(0.36, 0.24, 0.15))
			ci.draw_rect(Rect2(p + Vector2(12, 6), Vector2(3, 24)), Color(0.28, 0.18, 0.11))
		"r":
			forest_grass(ci, r, tx, ty)
			ci.draw_circle(p + Vector2(16, 20), 11, Color(0.38, 0.4, 0.42))
			ci.draw_circle(p + Vector2(13, 16), 7, Color(0.5, 0.52, 0.54))
		"f":
			forest_grass(ci, r, tx, ty)
			for i in 3:
				var hsh := _h(tx, ty, i + 5)
				var q := p + Vector2(hsh % 24 + 4, (hsh / 27) % 22 + 6)
				ci.draw_circle(q, 2.5, Color.from_hsv(float(hsh % 100) / 100.0, 0.5, 1.0))
				ci.draw_circle(q, 1.0, Color(1, 1, 0.6))
		"g":
			forest_grass(ci, r, tx, ty)
			ci.draw_rect(Rect2(p + Vector2(14, 12), Vector2(4, 18)), Color(0.4, 0.28, 0.16))
			ci.draw_rect(Rect2(p + Vector2(3, -2), Vector2(26, 16)), Color(0.7, 0.55, 0.35))
			ci.draw_rect(Rect2(p + Vector2(3, -2), Vector2(26, 16)), Color(0.4, 0.28, 0.16), false, 2)
			for i in 3:
				ci.draw_line(p + Vector2(7, 2 + i * 4), p + Vector2(25, 2 + i * 4), Color(0.3, 0.2, 0.12), 1)
		"u":
			forest_grass(ci, r, tx, ty)
			ci.draw_rect(Rect2(p + Vector2(5, 10), Vector2(22, 18)), Color(0.36, 0.24, 0.15))
			ci.draw_circle(p + Vector2(16, 10), 11, Color(0.7, 0.55, 0.36))
			ci.draw_arc(p + Vector2(16, 10), 6, 0, TAU, 12, Color(0.5, 0.38, 0.24), 1)
			ci.draw_arc(p + Vector2(16, 10), 3, 0, TAU, 8, Color(0.5, 0.38, 0.24), 1)
		"*":
			forest_grass(ci, r, tx, ty)
			star(ci, p + Vector2(16, 16), 8.0 + sin(t * 4.0) * 1.5, Color(1, 0.9, 0.2), t)
		_:
			forest_grass(ci, r, tx, ty)


## 플레이어보다 위에 그려지는 부분 (나무의 잎)
static func draw_forest_overhead(ci: CanvasItem, c: String, r: Rect2, tx: int, ty: int, t: float) -> void:
	if c != "^":
		return
	var p := r.position
	var sway := sin(t * 1.2 + tx * 0.7 + ty) * 1.0
	var hue := float(_h(tx, ty, 9) % 30) / 100.0
	var a := Color.from_hsv(0.36 + hue * 0.3, 0.55, 0.62, 0.9)
	var b := Color.from_hsv(0.46 + hue * 0.3, 0.6, 0.6, 0.9)
	ci.draw_circle(p + Vector2(9 + sway, -4), 14, a)
	ci.draw_circle(p + Vector2(23 + sway, -4), 14, b)
	ci.draw_arc(p + Vector2(9 + sway, -4), 14, 0, TAU, 20, Color(0.85, 1.0, 0.9, 0.55), 1)
	ci.draw_arc(p + Vector2(23 + sway, -4), 14, 0, TAU, 20, Color(0.85, 1.0, 0.9, 0.55), 1)


# ================================================================ 생명 (세포 속)
static func draw_bio(ci: CanvasItem, c: String, r: Rect2, tx: int, ty: int, t: float) -> void:
	var p := r.position
	var v := float(_h(tx, ty, 0) % 10) / 150.0
	var base := Color(0.17 + v, 0.09 + v, 0.2 + v)
	if c == ",":
		base = Color(0.32, 0.17, 0.3)
	if c == "#":
		ci.draw_rect(r, Color(0.07, 0.02, 0.09))
		for i in 4:
			ci.draw_circle(p + Vector2(4 + i * 8, 6 + sin(t * 1.5 + tx + i) * 1.5), 3.5, Color(0.5, 0.15, 0.4))
			ci.draw_circle(p + Vector2(4 + i * 8, 26 + sin(t * 1.5 + ty + i) * 1.5), 3.5, Color(0.5, 0.15, 0.4))
			ci.draw_line(p + Vector2(4 + i * 8, 9), p + Vector2(4 + i * 8, 23), Color(0.3, 0.08, 0.25), 1)
		return
	ci.draw_rect(r, base)
	for i in 2:
		var hsh := _h(tx, ty, i + 1)
		ci.draw_arc(p + Vector2(hsh % 26 + 3, (hsh / 29) % 26 + 3), 2.0, 0, TAU, 6, Color(0.5, 0.3, 0.5, 0.5), 1)
	match c:
		"o":
			_oval(ci, p + Vector2(16, 16), 14, 9, Color(0.95, 0.55, 0.2))
			_oval(ci, p + Vector2(16, 16), 11, 6, Color(0.6, 0.25, 0.1))
			var pts := PackedVector2Array()
			for i in 9:
				pts.append(p + Vector2(7 + i * 2.3, 16 + (4 if i % 2 == 0 else -4)))
			ci.draw_polyline(pts, Color(1.0, 0.75, 0.4), 1.5)
		"n":
			ci.draw_circle(p + Vector2(16, 16), 15, Color(0.4, 0.25, 0.7))
			ci.draw_circle(p + Vector2(16, 16), 11, Color(0.55, 0.38, 0.85))
			ci.draw_circle(p + Vector2(12 + sin(t) * 2.0, 14), 4, Color(0.3, 0.15, 0.5))
		"v":
			var bob := sin(t * 2.0 + tx) * 2.0
			ci.draw_circle(p + Vector2(16, 16 + bob), 12, Color(0.4, 0.75, 1.0, 0.35))
			ci.draw_arc(p + Vector2(16, 16 + bob), 12, 0, TAU, 16, Color(0.7, 0.9, 1.0, 0.8), 1.5)
			ci.draw_circle(p + Vector2(12, 11 + bob), 2.5, Color(1, 1, 1, 0.7))
		"~":
			ci.draw_rect(r, Color(0.12, 0.3, 0.24))
			for i in 2:
				var x := fmod(t * 8.0 + _h(tx, ty, i) % 32, 32.0)
				ci.draw_circle(p + Vector2(x, 10 + i * 12), 2, Color(0.5, 0.85, 0.6, 0.6))
		"f":
			for i in 4:
				var bx := 5.0 + i * 7.0
				ci.draw_line(p + Vector2(bx, 28), p + Vector2(bx + sin(t * 3.0 + i + tx) * 4.0, 12), Color(0.9, 0.6, 0.8), 1.5)
		"g":
			ci.draw_rect(Rect2(p + Vector2(14, 14), Vector2(3, 16)), Color(0.7, 0.7, 0.75))
			ci.draw_rect(Rect2(p + Vector2(3, -2), Vector2(26, 16)), Color(0.95, 0.95, 0.9))
			for i in 3:
				ci.draw_line(p + Vector2(6, 2 + i * 4), p + Vector2(26 - i * 4, 2 + i * 4), Color(0.2, 0.2, 0.3), 1)
		"*":
			star(ci, p + Vector2(16, 16), 8.0 + sin(t * 4.0) * 1.5, Color(1, 0.9, 0.2), t)


static func _oval(ci: CanvasItem, center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)


# ================================================================ 광학 (암실)
static func draw_optics(ci: CanvasItem, c: String, r: Rect2, tx: int, ty: int, t: float) -> void:
	var p := r.position
	if c == "#":
		ci.draw_rect(r, Color(0.01, 0.01, 0.03))
		return
	ci.draw_rect(r, Color(0.07, 0.08, 0.13) if c != "," else Color(0.11, 0.12, 0.2))
	for i in 4:
		ci.draw_rect(Rect2(p + Vector2(7 + (i % 2) * 16, 7 + (i / 2) * 16), Vector2(2, 2)), Color(0.02, 0.02, 0.05))
	var beam := Color(1.0, 0.15, 0.2, 0.75 + 0.25 * sin(t * 20.0 + tx))
	match c:
		"b":
			ci.draw_line(p + Vector2(0, 16), p + Vector2(32, 16), Color(1.0, 0.2, 0.2, 0.25), 7)
			ci.draw_line(p + Vector2(0, 16), p + Vector2(32, 16), beam, 2)
		"B":
			ci.draw_line(p + Vector2(16, 0), p + Vector2(16, 32), Color(1.0, 0.2, 0.2, 0.25), 7)
			ci.draw_line(p + Vector2(16, 0), p + Vector2(16, 32), beam, 2)
		"m":
			ci.draw_rect(Rect2(p + Vector2(14, 16), Vector2(4, 14)), Color(0.3, 0.3, 0.35))
			ci.draw_line(p + Vector2(4, 22), p + Vector2(28, -2), Color(0.4, 0.42, 0.5), 6)
			ci.draw_line(p + Vector2(5, 20), p + Vector2(27, -2), Color(0.85, 0.92, 1.0), 3)
		"l":
			ci.draw_rect(Rect2(p + Vector2(14, 18), Vector2(4, 12)), Color(0.3, 0.3, 0.35))
			_oval(ci, p + Vector2(16, 6), 6, 15, Color(0.5, 0.8, 1.0, 0.55))
			ci.draw_arc(p + Vector2(16, 6), 10, -0.9, 0.9, 8, Color(0.85, 0.95, 1.0), 1.5)
		"e":
			ci.draw_rect(Rect2(p + Vector2(2, 6), Vector2(28, 20)), Color(0.2, 0.2, 0.25))
			ci.draw_rect(Rect2(p + Vector2(2, 6), Vector2(28, 5)), Color(0.32, 0.32, 0.4))
			ci.draw_circle(p + Vector2(26, 17), 3, Color(1.0, 0.2, 0.2))
			ci.draw_rect(Rect2(p + Vector2(6, 15), Vector2(4, 4)), Color(0.2, 1.0, 0.3) if sin(t * 6.0) > 0 else Color(0.1, 0.3, 0.1))
		"s":
			ci.draw_rect(Rect2(p + Vector2(2, -10), Vector2(28, 36)), Color(0.9, 0.9, 0.95))
			for i in 7:
				var a := 0.2 + 0.8 * pow(cos((i - 3) * 0.9), 2.0)
				ci.draw_rect(Rect2(p + Vector2(4 + i * 3.5, -8), Vector2(2.5, 32)), Color(1.0, 0.2, 0.25, a))
		"g":
			ci.draw_rect(Rect2(p + Vector2(4, -4), Vector2(24, 20)), Color(0.15, 0.15, 0.2))
			ci.draw_rect(Rect2(p + Vector2(6, -2), Vector2(20, 14)), Color(0.1, 0.6, 0.9, 0.7 + 0.3 * sin(t * 4.0)))
			ci.draw_rect(Rect2(p + Vector2(12, 16), Vector2(8, 12)), Color(0.25, 0.25, 0.3))
		"*":
			star(ci, p + Vector2(16, 16), 8.0 + sin(t * 4.0) * 1.5, Color(1, 0.9, 0.2), t)


# ================================================================ 서버실
static func draw_server(ci: CanvasItem, c: String, r: Rect2, tx: int, ty: int, t: float) -> void:
	var p := r.position
	if c == "#":
		ci.draw_rect(r, Color(0.02, 0.03, 0.05))
		return
	ci.draw_rect(r, Color(0.06, 0.08, 0.11))
	ci.draw_rect(r, Color(0.1, 0.25, 0.3, 0.5), false, 1)
	var pulse := 0.5 + 0.5 * sin(t * 2.0 - (tx + ty) * 0.6)
	ci.draw_rect(Rect2(p + Vector2(15, 0), Vector2(2, 32)), Color(0.1, 0.8, 0.9, 0.12 * pulse))
	match c:
		"R":
			ci.draw_rect(Rect2(p + Vector2(2, -16), Vector2(28, 46)), Color(0.05, 0.05, 0.07))
			ci.draw_rect(Rect2(p + Vector2(2, -16), Vector2(28, 46)), Color(0.2, 0.22, 0.26), false, 1)
			for row in 6:
				for i in 4:
					var on := sin(t * (3.0 + (_h(tx + i, ty, row) % 7)) + _h(tx, ty + row, i)) > 0.0
					var col := Color(0.2, 1.0, 0.5) if (_h(tx, row, i) % 5) != 0 else Color(1.0, 0.3, 0.2)
					ci.draw_rect(Rect2(p + Vector2(6 + i * 6, -12 + row * 7), Vector2(3, 2)), col if on else Color(0.1, 0.15, 0.12))
		"K":
			ci.draw_rect(Rect2(p + Vector2(4, -20), Vector2(24, 50)), Color(0.08, 0.1, 0.14))
			var g := 0.6 + 0.4 * sin(t * 3.0)
			ci.draw_rect(Rect2(p + Vector2(8, -16), Vector2(16, 42)), Color(0.2, 0.9 * g, 1.0 * g))
			ci.draw_rect(Rect2(p + Vector2(8, -16 + fmod(t * 30.0, 40.0)), Vector2(16, 2)), Color(1, 1, 1, 0.8))
		"c":
			for i in 3:
				var pts := PackedVector2Array()
				for k in 9:
					pts.append(p + Vector2(k * 4.0, 10 + i * 6 + sin(k * 0.9 + i + tx) * 3.0))
				ci.draw_polyline(pts, [Color(0.8, 0.2, 0.2), Color(0.2, 0.5, 0.9), Color(0.9, 0.8, 0.2)][i], 2)
		"g":
			ci.draw_rect(Rect2(p + Vector2(4, -4), Vector2(24, 20)), Color(0.15, 0.15, 0.2))
			ci.draw_rect(Rect2(p + Vector2(6, -2), Vector2(20, 14)), Color(0.1, 0.9, 0.6, 0.7 + 0.3 * sin(t * 4.0)))
			ci.draw_rect(Rect2(p + Vector2(12, 16), Vector2(8, 12)), Color(0.25, 0.25, 0.3))
		"*":
			star(ci, p + Vector2(16, 16), 8.0 + sin(t * 4.0) * 1.5, Color(1, 0.9, 0.2), t)


static func star(ci: CanvasItem, center: Vector2, radius: float, col: Color, t: float) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0 + t * 0.8
		var rr := radius if i % 2 == 0 else radius * 0.45
		pts.append(center + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, col)
