# 학교 전체 방 데이터 생성기 -> data/rooms_*.gd
#
#   python3 tools/world.py
#
# tools/rooms_base.json (예전 방 데이터) 를 읽어서
#   - 본관 복도 5개를 'A자 단면'에 맞춰 다시 만든다 (1층이 가장 넓고 위로 갈수록 좁다, 꼭대기는 옥상 천문대)
#   - 교실들을 더 넓은 실제 교실 배치로 다시 그린다
#   - 5장 「천문대」 방(옥상, 천문대 돔)을 더한다
#   - 모든 방에 미니맵용 "where" (층, 가로 위치)를 붙인다
#   - 맵 줄 길이, 문 연결, 스폰/액터 위치를 검사한 뒤 GDScript 로 쓴다
# 생성된 data/rooms_*.gd 를 직접 고쳐도 되지만, 이 스크립트를 다시 돌리면 덮어쓴다.
import json, os, sys, copy

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
BASE = json.load(open(os.path.join(HERE, "rooms_base.json")))
R = {k: copy.deepcopy(v["data"]) for k, v in BASE.items()}
FILE_OF = {k: os.path.basename(v["file"]) for k, v in BASE.items()}

SOLID = {
    "school": "#=wbLBTdckptmeo*hvWASqPNFECQIiZjGyzK~OHVrYuMXJnagf",
    "forest": "#^~rgu*",
    "bio": "#onv~g*",
    "optics": "#mlesg*",
    "server": "#RKg*",
}


class C:
    def __init__(self, *v):
        self.v = v


def col(r, g, b, a=1.0):
    return C(r, g, b, a)


# ------------------------------------------------------------------ 글자 바꾸기 (이번 수정 사항)
TEXT = [
    ("집합과 명제의 숲", "집합과 명제의 방"),
    ("이 숲의 징검다리", "이 방의 징검다리"),
    ("반 친구: 수학쌤 오늘 부엉이 인형 들고 오셨더라. 왜인지 물어봤더니", "반 친구: 수학쌤 책상에 초록색 분필이 생겼더라. 어디서 났냐고 물어봤더니"),
    ("'증명할 필요 없는 것도 있단다' 이러시던데. 무슨 뜻이지?", "'공집합도 하나의 경우란다' 이러시던데. 무슨 뜻이지?"),
    ("이준규", "절규"),
    ("준규", "절규"),
    ("빨간펜 선생", "GIL"),
    ("'공집합도 하나의 경우란다' 이러시던데. 무슨 뜻이지?", "'대칭은 눈으로 보는 게 아니란다' 이러시던데. 무슨 뜻이지?"),
    ("* 맨 끝에 초록 분필로 'Q.E.D. - X-30'. 글씨가 사람 글씨 같지 않다.", "* 맨 끝에 초록 분필로 'Q.E.D. - BJ KIM'. 글씨가 좌우로 똑같이 반듯하다. 눈으로 쓴 글씨 같지 않다."),
    ("X-30", "BJ KIM"),
    ("S동 5층 멀티미디어실", "A동 5층 멀티디자인실(A507)"),
    ("멀티미디어실", "멀티디자인실"),
    ("수학과 강의실", "수학 강의실"),
    ("수학과 교무실", "수학 교원연구실"),
]


def fix_text(v):
    if isinstance(v, str):
        for a, b in TEXT:
            v = v.replace(a, b)
        return v
    if isinstance(v, list):
        return [fix_text(x) for x in v]
    if isinstance(v, dict):
        return {k: fix_text(x) for k, x in v.items()}
    return v


for k in list(R):
    R[k] = fix_text(R[k])


def un_color(v):
    if isinstance(v, dict):
        if "__color" in v:
            return C(*v["__color"])
        return {k: un_color(x) for k, x in v.items()}
    if isinstance(v, list):
        return [un_color(x) for x in v]
    return v


for k in list(R):
    R[k] = un_color(R[k])


# ------------------------------------------------------------------ 본관 복도 (5층 시설 안내도의 평면 배치)
# 기준: 학교 5층 시설 안내도 (저장소 docs/reference/school-5f.png).
#   - S동: 아래쪽의 긴 가로 복도. 서쪽 끝에서 왼쪽 아래로 꺾여 내려가는 수학 강의실 구역(S512~S517).
#   - A동: 동쪽 중앙 홀에서 왼쪽 위로 비스듬히 뻗는 복도(A501~A509).
#   - 두 동이 만나는 동쪽에 세모난 중앙 홀(아트리움)과 계단.
# 5층은 안내도의 실 번호와 용도를 그대로 쓴다. 1~4층은 안내도를 아직 못 받아서 같은 모양에
# 층 번호만 바꾸고, 알려진 시설(나무위키 시설 목록, 1·2층 사진)만 이름을 붙였다. 나머지 문은 번호만 보인다.
# 사선 복도는 32px 칸에 맞춘 계단꼴이고, 방 사이 간격·계단 위치는 걷기 좋게 조정했다. 실측 도면은 아니다.
FLOORS = [("1F", "f1_hall"), ("2F", "f2_hall"), ("3F", "f3_hall"), ("4F", "f4_hall"), ("5F", "f5_hall")]
HW, HH = 108, 66                       # 복도 맵 크기 (칸)
S_Y = (46, 48)                         # S동 가로 복도 (행 범위)
S_X = (24, 103)
HUB_COL = (74, 76)                     # A동 아래 끝과 S동을 잇는 세로 통로
HUB = (77, 32, 103, 45)                # 중앙 홀 바닥 (x0, y0, x1, y1)
TRI = ((79, 33), (79, 44), (97, 44))   # 세모난 아트리움 (꼭짓점)


def a_cy(x):   # A동 사선 복도의 가운데 행
    return 4 + round((x - 33) * 26 / 42)


def m_cy(x):   # 수학 구역 사선 복도의 가운데 행
    return 47 + round((26 - x) * 15 / 20)


def in_tri(x, y):
    (x0, y0), _, (x2, y2) = TRI
    return x >= x0 and y <= y2 and y >= y0 and (x - x0) * (y2 - y0) <= (y - y0) * (x2 - x0)


# 문 자리: (자리 이름, 열 x, 어느 복도, 위/아래)  위(N) = 복도 위쪽 벽, 아래(S) = 복도 아래쪽 벽
SLOTS = [
    ("S01", 77, "S", "S"), ("S02", 71, "S", "S"), ("S03", 65, "S", "S"), ("S04", 59, "S", "S"),
    ("S05", 53, "S", "S"), ("S06", 47, "S", "S"), ("S07", 41, "S", "S"), ("S08", 46, "S", "N"),
    ("S09", 35, "S", "S"), ("S10", 37, "S", "N"), ("S11", 28, "S", "S"), ("S12", 27, "S", "N"),
    ("S13", 21, "M", "N"), ("S14", 23, "M", "S"), ("S15", 16, "M", "S"), ("S16", 14, "M", "N"), ("S17", 7, "M", "N"),
    ("A01", 95, "H", "N"), ("A02", 63, "A", "S"), ("A02-1", 70, "A", "S"), ("A03", 66, "A", "N"), ("A04", 59, "A", "N"),
    ("A05", 56, "A", "S"), ("A06", 49, "A", "S"), ("A07", 51, "A", "N"), ("A08", 40, "A", "S"), ("A09", 37, "A", "N"),
    ("A-END", 33, "A", "S"), ("ENTRY", 88, "S", "S"),
]
SLOT = {s[0]: s for s in SLOTS}

# 5층: 시설 안내도 그대로
PLAN5 = {
    "S01": "교원연구실", "S02": "강의실", "S03": "지구과학실험실1", "S04": "준비실", "S05": "지구과학실험실2",
    "S06": "박편제작실", "S07": "화석전시실", "S08": "기구보관실", "S09": "강의실", "S10": "교원연구실(지구과학)",
    "S11": "강의실", "S12": "강의실(수학)", "S13": "강의실(수학)", "S14": "강의실(수학)", "S15": "강의실(수학)",
    "S16": "교원연구실(수학)", "S17": "교원연구실(수학)",
    "A01": "정보과학실3", "A02": "미술실1", "A02-1": "교원연구실(미술)", "A03": "창의설계실(1)", "A04": "창의설계실(2)",
    "A05": "준비실", "A06": "미술실2", "A07": "멀티디자인실", "A08": "융합창작실1", "A09": "융합창작실2",
}
PLAN5_TEXT = {
    "S01": ["* S501 교원연구실 (창의융합부 / 대외협력부). 잠겨 있다.", "* 문에 '외부 손님 안내 - 1층 행정실'이라고 붙어 있다."],
    "S04": ["* S504 준비실은 잠겨 있다.", "* 문틈으로 암석 표본 상자들이 보인다. 이름표: '현무암 - 제주도 수학여행 때 주움'."],
    "S05": ["* S505 지구과학실험실2는 잠겨 있다.", "* 창문 너머 실험대에 지구본 일곱 개가 나란히 있다. 전부 기울기가 23.5도다."],
    "S06": ["* S506 박편제작실은 잠겨 있다.", "* 연마기 옆에 종이처럼 얇게 간 돌 조각들이 말라 가고 있다. 빛에 비추면 무지개가 든다고 한다."],
    "S07": ["* S507 화석전시실은 잠겨 있다.", "* 유리장 안에서 암모나이트가 이쪽을 보고 있다. 3억 년째 같은 자세다."],
    "S08": ["* S508 기구보관실은 잠겨 있다.", "* 문 앞에 '망원경 대여 장부 - 반납 꼭!' 장부가 걸려 있다. 반납란이 거의 비어 있다."],
    "S10": ["* S510 교원연구실(지구과학)은 잠겨 있다.", "* 문에 오늘 밤 월령표가 붙어 있다. '상현. 관측하기 좋음.'"],
    "S13": ["* S513 강의실(수학)은 잠겨 있다.", "* 칠판에 지우다 만 그래프가 남아 있다. y = sin x 의 꼬리만 보인다."],
    "S17": ["* S517 교원연구실(수학)은 잠겨 있다.", "* 문 아래로 빨간 펜 뚜껑 하나가 굴러 나와 있다."],
    "A03": ["* A503 창의설계실(1)은 잠겨 있다.", "* 유리창에 포스트잇 아이디어가 빼곡하다. '날아다니는 책상', '자동 급식 대기 줄'."],
    "A04": ["* A504 창의설계실(2)는 잠겨 있다.", "* 안쪽에서 3D 펜으로 만든 작은 다리가 무게를 견디고 있다. 위에 동전 열두 개."],
    "A05": ["* A505 준비실은 잠겨 있다.", "* 물감 냄새가 문틈으로 샌다. 선반 위 석고상들이 이쪽을 보는 것 같다."],
    "A06": ["* A506 미술실2는 잠겨 있다.", "* 이젤마다 같은 사과를 그린 그림이 걸려 있다. 하나도 같은 사과가 없다."],
    "A09": ["* A509 융합창작실2는 잠겨 있다.", "* 레이저 커팅기의 냉각수가 조용히 돌고 있다."],
}

# 1~4층: 같은 자리에 층 번호만 바꾼다. 이름은 알려진 시설만 (나무위키 시설 목록, 사진)
NAMES_LOW = {
    "4F": {"S02": "생명과학 강의실", "S03": "생명과학 실험실", "S04": "생명과학 준비실", "S09": "시청각실",
           "S10": "생명과학 교원연구실", "S11": "정보과학세미나실", "S12": "강의실(수학, 3학년)",
           "A01": "정보과학실(맥실)", "A02": "음악실", "A03": "악기연습실", "A05": "상담실", "A06": "노래방"},
    "3F": {"S03": "도서관", "S04": "화학 준비실", "S05": "도서관 활용교실", "S06": "화학과 실험실", "S09": "화학과 강의실",
           "S11": "사회과 강의실", "A01": "정보과학실(로봇)", "A02": "영어과 강의실", "A03": "어학실",
           "A04": "영어과 교원연구실", "A05": "학생회실"},
    "2F": {"S03": "단일광자 실험실", "S04": "물리 준비실", "S05": "물리과 강의실", "S09": "국어과 강의실",
           "A01": "서버실", "A02": "본교무실", "A03": "대강의실", "A04": "체육관(대강당)", "A06": "방송실", "A-END": "기숙사 연결 데크"},
    "1F": {"S01": "학교지킴이실", "S03": "융합실험실", "S06": "현미경실", "S09": "첨단기기실",
           "A01": "보건실", "A02": "교장실", "A03": "행정실", "A04": "국제세미나실", "A05": "2학년부 교무실", "ENTRY": "정문 현관"},
}
LOW_TEXT = {
    ("4F", "S04"): ["* 생명과학 준비실은 잠겨 있다.", "* 냉장고 문에 '시약 보관 - 음식 넣지 마시오 (특히 요구르트)'라고 붙어 있다."],
    ("4F", "A05"): ["* 상담실은 잠겨 있다.", "* 문에 '언제든 노크하세요. 고민의 크기는 상관없습니다.'라고 적혀 있다."],
    ("3F", "S04"): ["* 화학 준비실은 잠겨 있다.", "* 문에 MSDS 목록이 빽빽하다. 맨 아래 손글씨: '라면 국물은 산성인가요?'"],
    ("3F", "A05"): ["* 학생회실은 잠겨 있다.", "* 화이트보드에 '축제 부스 신청 마감 D-3'. 그 옆에 '코어한테 예산 받기 (실패)'."],
    ("2F", "S04"): ["* 물리 준비실은 잠겨 있다.", "* 문틈으로 오실로스코프 화면이 깜빡인다. 사인파가 조금씩 찌그러져 있다."],
    ("2F", "A06"): ["* 방송실은 잠겨 있다. 'ON AIR' 불이 꺼져 있다.", "* 문에 '점심 신청곡 받습니다 - 단, 같은 노래 3일 연속 금지'라고 붙어 있다."],
    ("1F", "S01"): ["* 학교지킴이실은 불이 꺼져 있다.", "* 책상에 식은 믹스커피와 '오늘도 무사히'라고 적힌 근무 일지가 있다.",
                    "* 일지 맨 아래: '5층 멀티디자인실 불 켜짐 - 학생 자고 있음. 깨우지 않음. 담요 덮어 줌.'"],
}
# 게임 속 문(옛 문 글자) -> 자리
GAME_SLOTS = {
    "5F": {"1": "A07", "2": "S12", "3": "S16", "4": "S05", "5": "S03", "6": "A02", "7": "A03", "8": "A04", "9": "A08"},
    "4F": {"1": "S09", "2": "S11", "3": "S02", "4": "S03", "5": "S10", "6": "S12", "7": "A01", "8": "A02", "9": "A06"},
    "3F": {"1": "S03", "2": "S05", "3": "S06", "4": "S09", "5": "S11", "6": "A02", "7": "A03", "8": "A01", "9": "A04"},
    "2F": {"1": "S03", "2": "S05", "3": "S09", "4": "A-END", "5": "A02", "6": "A06", "7": "A01", "8": "A03", "9": "A04"},
    "1F": {"1": "S03", "2": "S06", "3": "S09", "4": "ENTRY", "5": "A01", "6": "A03", "7": "A04", "8": "A02", "9": "A05"},
}
# 잠긴 문에 쓸 글자 (타일 글자와 겹치지 않는 것)
LOCK_CHARS = list("0&()[]{}<>?+/|:;'`-가나다라마바사아자차카타파하")
TOILET_X = (52, 54)   # S동 복도 위쪽: 남자 / 여자 화장실 (안내도의 화장실 자리)
STAIRS = {"U": (81, 31), "D": (85, 31)}   # 중앙 홀 위쪽 벽 (2칸짜리)

# 복도의 옛 스폰 이름 -> 문 글자 (그 문 앞에 선다)
SPAWN_DOOR = {
    "f5_hall": {"from_multimedia": "1", "from_math": "2", "from_office": "3", "from_obs": "5", "from_art": "6", "from_club": "9", "from_stairs": "D", "from_roof": "R"},
    "f4_hall": {"from_bio": "4", "from_mac": "7", "from_music": "8", "from_karaoke": "9", "from_up": "U", "from_down": "D"},
    "f3_hall": {"from_library": "1", "from_robot": "8", "from_up": "U", "from_down": "D"},
    "f2_hall": {"from_phys": "1", "from_deck": "4", "from_server": "7", "from_exam": "8", "from_gym": "9", "from_up": "U", "from_down": "D"},
    "f1_hall": {"from_yard": "4", "from_principal": "8", "from_up": "U"},
}


def room_no(fl, key):
    if key in ("A-END", "ENTRY"):
        return ""
    n = int(fl[0])
    head, num = key[0], key[1:]
    if num.endswith("-1"):
        return "%s%d%02d-1" % (head, n, int(num[:-2]))
    return "%s%d%02d" % (head, n, int(num))


def floor_grid(fl):
    g = [["#"] * HW for _ in range(HH)]

    def fl_(x, y):
        if 0 < x < HW - 1 and 0 < y < HH - 1:
            g[y][x] = "."
    for x in range(S_X[0], S_X[1] + 1):
        for y in range(S_Y[0], S_Y[1] + 1):
            fl_(x, y)
    for x in range(HUB_COL[0], HUB_COL[1] + 1):
        for y in range(a_cy(75) - 1, S_Y[0]):
            fl_(x, y)
    for x in range(HUB[0], HUB[2] + 1):
        for y in range(HUB[1], HUB[3] + 1):
            fl_(x, y)
    for x in range(31, 77):
        c = a_cy(x)
        for y in (c - 1, c, c + 1):
            fl_(x, y)
    for x in range(4, 27):
        c = m_cy(x)
        for y in (c - 1, c, c + 1):
            fl_(x, y)
    # 아트리움: 1층은 바닥(홀), 2~5층은 아래로 뚫린 구멍과 유리 난간
    tri = [(x, y) for y in range(HH) for x in range(HW) if in_tri(x, y)]
    if fl != "1F":
        for x, y in tri:
            g[y][x] = "a"
        for x, y in tri:
            if any(not in_tri(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                g[y][x] = "n"
    return g


def wall_cell(g, x, ref_y, side):
    y = ref_y
    step = -1 if side == "N" else 1
    while g[y][x] in ".an":
        y += step
    return y


def build_hall(hid, fl):
    old = R[hid]
    g = floor_grid(fl)
    is_floor = lambda x, y: 0 <= y < HH and 0 <= x < HW and g[y][x] == "."
    # 벽: 바로 아래가 바닥이면 보이는 벽(=), 바로 위가 바닥이면 사물함(L, 곧은 복도만)
    for y in range(HH):
        for x in range(HW):
            if g[y][x] != "#":
                continue
            if is_floor(x, y + 1):
                g[y][x] = "="
    for x in range(S_X[0] + 2, S_X[1]):
        if g[S_Y[1] + 1][x] == "#":
            g[S_Y[1] + 1][x] = "L"
    pos, doors, names = {}, {}, {}
    oldd = old["doors"]
    game = {v: k for k, v in GAME_SLOTS[fl].items()}
    lock_i = 0

    def ref_y(seg, x):
        return {"S": S_Y[0] + 1, "H": HUB[1], "A": a_cy(x), "M": m_cy(x)}[seg]
    for key, x, seg, side in SLOTS:
        if key == "ENTRY" and fl != "1F":
            continue
        if key == "A-END" and fl != "2F":
            continue
        name = PLAN5.get(key) if fl == "5F" else NAMES_LOW[fl].get(key, "")
        no = room_no(fl, key)
        label = (no + " " + name).strip() if name else no
        y = wall_cell(g, x, ref_y(seg, x), side)
        if key in game:
            ch = game[key]
            d = dict(oldd[ch])
            d["label"] = label
        else:
            ch = LOCK_CHARS[lock_i]
            lock_i += 1
            txt = (PLAN5_TEXT.get(key) if fl == "5F" else LOW_TEXT.get((fl, key))) or [
                "* %s%s. 문이 잠겨 있다." % (no, (" " + name) if name else ""),
                "* (이 층 안내도 사진을 받으면 이름과 용도를 채울 자리다.)" if not name and fl != "5F" else "* 불 꺼진 창문 너머로 의자들이 책상 위에 올려져 있다."]
            d = {"locked": True, "label": label, "text": txt}
        if side == "S":
            d["label_below"] = True
        if d.get("locked") and "text" not in d:
            d["text"] = (PLAN5_TEXT.get(key) if fl == "5F" else LOW_TEXT.get((fl, key))) or ["* %s. 문이 잠겨 있다." % label]
        w = 2 if key in ("S03", "ENTRY") or (key == "A04" and fl == "2F") else 1
        for k in range(w):
            g[y][x + k] = ch
        pos[ch] = (x, y, side)
        doors[ch] = d
        names[ch] = label
    # 화장실
    for ch, x, who in (("!", TOILET_X[0], "남자"), ("$", TOILET_X[1], "여자")):
        y = wall_cell(g, x, S_Y[0] + 1, "N")
        g[y][x] = ch
        pos[ch] = (x, y, "N")
        doors[ch] = {"locked": True, "label": who + " 화장실", "text": TOILET_TEXT[fl][who]}
    # 계단: 중앙 홀 위쪽 벽. 5층의 '올라가는 계단'은 옥상 계단이다.
    for ch, (x, y) in STAIRS.items():
        real = "R" if (ch == "U" and fl == "5F") else ch
        if real == "R" or real in oldd:
            g[y][x] = g[y][x + 1] = real
            pos[real] = (x, y, "N")
    for c, d in oldd.items():
        if c in "UD":
            doors[c] = dict(d)
    if fl == "5F":
        doors["R"] = {"event": "stairs_roof", "style": "stairs", "need_flag": "cert_dorm", "label": "↑ 옥상", "text": [
            "* 옥상으로 가는 계단이다. 철문에 자물쇠가 걸려 있다.", "* [ 옥상 천문대 - 야간 관측 시에만 개방 ]"]}
    if fl == "2F":
        doors["7"] = dict(doors["7"], need_flag="cert_astro", text=["* 서버실이다. 문이 얼음처럼 차갑다.", "* [ 융합 프로토콜 : 최종 인증 필요 - 천문 0/1 ]"])
        doors["8"] = {"locked": True, "label": names["8"], "text": [
            "* 대강의실은 잠겨 있다.", "* 창문 너머로 빈 책상들이 줄지어 있다. 칠판에 '중간고사 - 연기됨 (사유: 별 보러 감)'."]}
    # 장식: 위쪽 벽에 창문과 게시판, 사물함 사이 정수기
    for y in range(HH):
        for x in range(HW):
            if g[y][x] == "=" and (x * 3 + y) % 7 == 0:
                g[y][x] = "w"
            elif g[y][x] == "=" and (x + y * 5) % 11 == 0:
                g[y][x] = "b"
    for x in (S_X[0] + 6, 62, 91):
        if g[S_Y[1] + 1][x] == "L":
            g[S_Y[1] + 1][x] = "Q"
    # 안내도 (중앙 홀 위쪽 벽, 계단 옆)
    g[31][89] = g[31][90] = "b"
    g[HUB[1]][HUB[2]] = "v"     # 자판기
    for x, y in ((HUB_COL[0], S_Y[0] - 1), (HUB[2], HUB[3]), (S_X[0], S_Y[1])):
        if g[y][x] == ".":
            g[y][x] = "p"
    # 중앙 홀 꾸미기
    sg = dict(old.get("signs", {}))
    plates = [[72, S_Y[0], "← S동"], [74, 31, "A동 ↖"], [24, 49, "수학 강의실 ↙"]]
    if fl == "1F":
        for x, y in ((80, 35), (80, 43), (88, 43), (94, 43)):
            g[y][x] = "J"
        for x in (85, 86):
            for y in (40, 41):
                g[y][x] = "^"
        g[38][90] = "P"
        for x in range(91, 94):
            if g[31][x] in "=wb":
                g[31][x] = "A"
        g[S_Y[1] + 1][95] = g[S_Y[1] + 1][96] = "K"
        plates.append([92, 32, "HALL OF FAME"])
        # S110 앞 라운지 (사진): 검은 소파, 낮은 탁자, 곰 인형과 우체통, 당구대
        for x, c in ((39, "S"), (40, "S"), (41, "o"), (35, "f"), (31, "g")):
            if g[S_Y[0]][x] == ".":
                g[S_Y[0]][x] = c
        sg.update({
            "J": ["* 노랗게 칠한 둥근 기둥이다. 3층 천장까지 곧게 올라간다.", "* 기둥 아래에 누가 붙여 놓은 포스트잇: '여기서 만나 - 7시'."],
            "^": ["* 바닥에 짙은 돌로 박아 넣은 마름모 무늬다.", "* 신입생 때 다들 이 위에 서서 사진을 찍었다."],
            "A": ["* 'HALL OF FAME'. 졸업생들의 수상 기록이 벽 한가득 걸려 있다.", "* 'Pioneering · Creative · Versatile · Humane'.", "* 그 아래 작게: '드높은 이상, 드넓은 창발'."],
            "K": ["* SASA 로고가 새겨진 낮은 돌이다. 'Sejong Academy of Science and Arts'."],
            "f": ["* 분홍 스웨터를 입은 커다란 곰 인형이다. 옆에 빨간 우체통이 있다. 'POST'.", "* 곰이 S110 앞을 지키고 있다. 밤에도 퇴근하지 않는 것 같다."],
            "g": ["* 작은 당구대다. 'ATOZ'라고 적혀 있다.", "* 큐대는 한 자루뿐이고, 공은 세 개가 모자란다."],
        })
    else:
        for x, y in ((78, 33), (78, 45), (98, 45)):
            if g[y][x] == ".":
                g[y][x] = "J"
        sg.update({
            "n": ["* 유리 난간 너머로 아래층 중앙 홀이 내려다보인다.", "* 노란 기둥들, 마름모 무늬, 덮개를 씌운 피아노가 까마득히 작다."],
            "a": ["* 아래는 중앙 홀이다. 떨어지면 안 된다."],
            "J": ["* 노란 기둥이다. 1층부터 이어져 올라왔다."],
        })
        if fl == "2F":
            plates.append([82, 32, "3 도서관 ↑"])
            plates.append([86, 32, "2 대강당·방송실"])
    rows = ["".join(r) for r in g]
    # 스폰: 문 바로 앞
    sp = {}
    for name, c in SPAWN_DOOR[hid].items():
        if c not in pos:
            continue
        x, y, side = pos[c]
        sp[name] = [x, y + 1, 0] if side == "N" else [x, y - 1, 1]
    if hid == "f5_hall":
        x, y, side = pos["1"]
        sp["start"] = [x, y + 1, 0]
    # 조사 칸: 안내도, 사물함 이벤트
    at = {}
    old_at = old.get("signs_at", {})
    doodle = [v for k, v in old_at.items() if k in ("30,1", "31,1") and "낙서" in str(v)]
    at["89,31"] = GUIDE[fl]
    if doodle:
        at["90,31"] = doodle[0]
    lockers = [x for x in range(HW) if rows[S_Y[1] + 1][x] == "L"]
    want = [60, 44, 30, 70]
    for k, v in old_at.items():
        x, y = map(int, k.split(","))
        if y == 6:
            tx = want.pop(0)
            nx = min(lockers, key=lambda lx: abs(lx - tx))
            at["%d,%d" % (nx, S_Y[1] + 1)] = v
        elif y == 1 and k not in ("30,1", "31,1"):
            bx = SLOT["S12"][1] + 2
            g2 = list(rows[S_Y[0] - 1]); g2[bx] = "b"; rows[S_Y[0] - 1] = "".join(g2)
            at["%d,%d" % (bx, S_Y[0] - 1)] = v
    # 액터
    actors = []
    for a in old.get("actors", []):
        a = dict(a)
        if a["id"] == "namoji":
            x, y, _ = pos["1"]
            a["pos"] = [x + 2, a_cy(x + 2)]
        elif a["id"] == "junkyu":
            a["pos"] = [44, S_Y[0] + 1]
        actors.append(a)
    new = dict(old)
    new.update({"map": rows, "doors": doors, "spawns": sp, "signs_at": at, "actors": actors, "plates": plates, "signs": sg})
    return new


TOILET_TEXT = {
    "5F": {"남자": ["* 남자 화장실이다. 세면대 거울에 김이 서려 있다.", "* 누군가 손가락으로 '내일은 잘하자'라고 써 놓았다."],
           "여자": ["* 여자 화장실이다. 불이 꺼져 있다.", "* 문에 '휴지 아껴 쓰기 - 학생회'라는 손글씨가 붙어 있다."]},
    "4F": {"남자": ["* 남자 화장실이다. 창문이 조금 열려 있어서 바람 소리가 난다."],
           "여자": ["* 여자 화장실이다. 거울 위에 '오늘도 수고했어'라는 스티커가 붙어 있다."]},
    "3F": {"남자": ["* 남자 화장실이다. 청소 당번표에 같은 이름이 세 번 연속 적혀 있다."],
           "여자": ["* 여자 화장실이다. 칸막이마다 영어 단어가 한 장씩 붙어 있다. 'perseverance'."]},
    "2F": {"남자": ["* 남자 화장실이다. 바닥이 쿵, 쿵 박자에 맞춰 울린다. 여기도."],
           "여자": ["* 여자 화장실이다. 조용하다."]},
    "1F": {"남자": ["* 남자 화장실이다. 새벽빛이 작은 창으로 들어온다."],
           "여자": ["* 여자 화장실이다. 비누 냄새가 난다."]},
}
GUIDE = {
    "5F": ["* 5층 시설 안내도다.", "* 아래쪽 긴 복도가 S동, 서쪽 끝에서 비스듬히 내려가는 곳이 수학 강의실(S512~S517).",
           "* 중앙 홀에서 왼쪽 위로 비스듬히 뻗은 복도가 A동(A501~A509).", "* 계단 옆에 작은 글씨: '옥상 천문대 - 야간 관측 시 개방'."],
    "4F": ["* 4층 안내도다.", "* 'S동 : 생명과학 실험실 · 생명과학 강의실 · 시청각실 · 정보과학세미나실'", "* 'A동 : 정보과학실(맥실) · 음악실 · 악기연습실 · 노래방'"],
    "3F": ["* 3층 안내도다.", "* 'S동 : 도서관 · 화학과 · 사회과'", "* 'A동 : 정보과학실(로봇) · 영어과 · 어학실 · 학생회실'"],
    "2F": ["* 2층 안내도다.", "* 'S동 : 단일광자 실험실 · 물리과 · 국어과'", "* 'A동 : 서버실 · 본교무실 · 대강의실 · 체육관(대강당) · 방송실 · 기숙사 연결 데크'"],
    "1F": ["* 1층 안내도다.", "* 'S동 : 융합실험실 · 현미경실 · 첨단기기실 · 학교지킴이실'", "* 'A동 : 보건실 · 행정실 · 교장실 · 국제세미나실 · 2학년부 교무실'"],
}

for fl, hid in FLOORS:
    R[hid] = build_hall(hid, fl)
    FILE_OF[hid] = "rooms_halls.gd"
R["f5_hall"]["signs"]["b"] = ["* 게시판이다.", "* '이번 주 급식: 월 카레, 화 카레, 수 카레... 목 짜장.'", "* 목요일이 기다려진다."]

# ------------------------------------------------------------------ 교실들 (더 넓게)
def room(name, mp, **kw):
    d = {"name": name, "theme": "school", "music": "school_night", "map": mp}
    d.update(kw)
    return d


def keep(old, **upd):
    d = dict(old)
    d.update(upd)
    return d


# 멀티미디어실: 컴퓨터 6줄, 앞 화이트보드, 뒷문
R["s5_multimedia"] = keep(R["s5_multimedia"], map=[
    "##########################",
    "#==w===jjjjjjjj===w===w==#",
    "#........................#",
    "#..........TTT...........#",
    "#........................#",
    "#.cc.cc.cc...cc.cc.cc....#",
    "#........................#",
    "#.cc.cc.cc...cc.cc.cc....#",
    "#........................#",
    "#.cc.cc.cc...cc.cc.cc...p#",
    "#........................#",
    "#LLLLLLLL........LLLLLLLL#",
    "#........................#",
    "###########1##############",
], spawns={"from_hall": [11, 12, 1], "start": [12, 8, 0]},
    signs_at={"13,7": R["s5_multimedia"]["signs_at"]["9,3"]},
    actors=[dict(R["s5_multimedia"]["actors"][0], pos=[4, 10])])
R["s5_multimedia"]["signs"]["j"] = ["* 화이트보드에 '과제 제출 마감: 오늘 자정'이라고 적혀 있다. 밑줄이 세 개다."]
R["s5_multimedia"]["signs"]["L"] = ["* 사물함이다. 한 칸에 '과제 끝나면 열기 - 컵라면'이라고 붙어 있다."]
R["s5_multimedia"]["signs"]["T"] = ["* 교탁 위에 출석부가 펼쳐져 있다. 오늘 날짜 칸이 아직 비어 있다."]

# 수학과 강의실: 넓은 칠판, 교탁, 책상 4줄
R["s5_math_class"] = keep(R["s5_math_class"], map=[
    "############################",
    "#===w===BBBBBBBBBBBB===w===#",
    "#..........................#",
    "#...........TTT............#",
    "#..........................#",
    "#..dd..dd..dd....dd..dd..dd#",
    "#..........................#",
    "#..dd..dd..dd....dd..dd..dd#",
    "#..........................#",
    "#..dd..dd..dd....dd..dd..dd#",
    "#..........................#",
    "#..dd..dd..dd....dd..dd..p.#",
    "#..........................#",
    "#LLLLLLLLLL......LLLLLLLLLL#",
    "#..........................#",
    "#############1##############",
], spawns={"from_hall": [13, 14, 1], "after_boss": [13, 8, 0]})

# 수학과 교무실: 선생님 책상 섬 두 개, 책장, GIL 자리
R["s5_math_office"] = keep(R["s5_math_office"], map=[
    "########################",
    "#==kkkk==b==w==kkkk=w==#",
    "#......................#",
    "#.dddd.dddd.....dddd...#",
    "#.dddd.dddd.....dddd...#",
    "#......................#",
    "#.dddd.dddd.....oo..p..#",
    "#.dddd.dddd.....oo.....#",
    "#......................#",
    "#..........Q...........#",
    "#########1##############",
], spawns={"from_hall": [9, 9, 1]},
    actors=[dict(a, pos=[19, 5]) for a in R["s5_math_office"]["actors"]])
R["s5_math_office"]["signs"]["d"] = ["* 선생님 책상이다. 채점하다 만 답안지 더미 위에 크고 동그란 빨간 안경 케이스가 놓여 있다."]

# 지구과학실험실1 (예전 '천문대'): 5층에서 옥상 천문대로 올라가기 전 방
obs = R["s5_observatory"]
R["s5_observatory"] = keep(obs, name="S동 5층 지구과학실험실1", map=[
    "####################",
    "#==w==kkkk==w==Y===#",
    "#..................#",
    "#..tt..........oo..#",
    "#..................#",
    "#..kk....*.....oo..#",
    "#..................#",
    "#..................#",
    "#########1##########",
], spawns={"from_hall": [9, 7, 1]})
R["s5_observatory"]["signs"] = {
    "t": {"event": "telescope"},
    "k": ["* 천문 동아리 관측 일지가 꽂혀 있다. '오늘의 시상: 3/5. 구름 많음. 그래도 목성 봤음!!'"],
    "o": ["* 둥근 탁자 위에 성도(별자리 지도)가 펼쳐져 있다. 여름철 대삼각형에 동그라미가 쳐 있다."],
    "Y": ["* 별자리판이다. '이달의 천체: 거문고자리 베가'.", "* 그 밑에 '옥상 관측회 - 천문 선생님 동행'이라는 공지가 붙어 있다."],
    "w": ["* 창밖으로 옥상의 흰 돔이 조금 보인다. 돔의 틈이 닫혀 있다."],
}

# 융합창작실1 (예전 동아리실)
R["a5_club"] = keep(R["a5_club"], name="A동 5층 융합창작실1 A509", map=[
    "######################",
    "#==b==w==w==w==w==b==#",
    "#....................#",
    "#.mm..mm..mm..mm..mm.#",
    "#....................#",
    "#.cc..cc..oo..cc..cc.#",
    "#....................#",
    "#.....kk......Q....p.#",
    "#....................#",
    "##########1###########",
], spawns={"from_hall": [10, 8, 1]})
R["a5_club"]["signs"]["m"] = {"event": "printer3d"}
R["a5_club"]["signs"]["k"] = ["* 필라멘트 상자가 색깔별로 쌓여 있다. '빨강 - 품절. (GIL 선생님 안경 출력용?)'"]

# 정보과학실(맥실)
R["a4_mac"] = keep(R["a4_mac"], map=[
    "########################",
    "#==w==b==jjjjjj==w==w==#",
    "#......................#",
    "#.ii.ii.ii....ii.ii.ii.#",
    "#......................#",
    "#.ii.ii.ii....ii.ii.ii.#",
    "#......................#",
    "#.ii.ii.ii....ii.ii.ii.#",
    "#....................p.#",
    "###########1############",
], spawns={"from_hall": [11, 8, 1]}, signs_at={"2,3": R["a4_mac"]["signs_at"]["2,3"]})

# 음악실
R["a4_music"] = keep(R["a4_music"], map=[
    "########################",
    "#==w==jjjjjjjj==w===N==#",
    "#......................#",
    "#...PP.................#",
    "#......................#",
    "#..dd.dd.dd....dd.dd...#",
    "#......................#",
    "#..dd.dd.dd....dd.dd..p#",
    "#......................#",
    "#AAAA..............AAAA#",
    "###########1############",
], spawns={"from_hall": [11, 9, 1]})
R["a4_music"]["signs"]["A"] = ["* 악기장이다. 바이올린, 칼림바, 우쿨렐레... 트라이앵글만 열두 개다."]

# 미술실
R["a5_art"] = keep(R["a5_art"], map=[
    "########################",
    "#==w==NN===w====j=w==Z=#",
    "#....................Z.#",
    "#.e..e..e..e...........#",
    "#......................#",
    "#.oo..oo..oo..oo.......#",
    "#......................#",
    "#.e..e..e..e......p....#",
    "#......................#",
    "#kkkk..............kkkk#",
    "##########1#############",
], spawns={"from_hall": [10, 9, 1]},
    signs_at={"6,1": R["a5_art"]["signs_at"]["6,1"], "7,1": R["a5_art"]["signs_at"]["7,1"]},
    actors=[dict(R["a5_art"]["actors"][0], pos=[17, 7])])
R["a5_art"]["signs"]["k"] = ["* 학생 작품 보관함이다. 포트폴리오 파일마다 이름이 적혀 있다."]

# 정보과학실(로봇)
R["a3_robot"] = keep(R["a3_robot"], map=[
    "########################",
    "#==b==w==jjjjjj==w==b==#",
    "#......................#",
    "#.cc..cc..oo..cc..cc...#",
    "#......................#",
    "#.dd..dd..oo..dd..dd..p#",
    "#......................#",
    "#......................#",
    "#mm..................kk#",
    "###########1############",
], spawns={"from_hall": [11, 8, 1]},
    actors=[dict(R["a3_robot"]["actors"][0], pos=[17, 7])])
R["a3_robot"]["signs"].setdefault("m", ["* 3D 프린터가 로봇 부품을 뽑다 멈춰 있다."])
R["a3_robot"]["signs"]["j"] = ["* 화이트보드에 라인트레이서 경로가 그려져 있다. 같은 원을 수십 번 덧그렸다."]
R["a3_robot"]["signs"].setdefault("k", ["* 부품 서랍장이다. '저항 - 색깔 띠 읽을 줄 아는 사람만'."])

# 도서관: 넓은 열람실 + 서가
lib = R["s3_library"]
R["s3_library"] = keep(lib, map=[
    "##############################",
    "#==kkkkkk==w===w===w==kkkkkk=#",
    "#............................#",
    "#.kk..kk..kk..kk....oo..oo...#",
    "#.kk..kk..kk..kk....oo..oo...#",
    "#............................#",
    "#.kk..kk..kk..kk....oo..oo...#",
    "#.kk..kk..kk..kk....oo..oo...#",
    "#............................#",
    "#..o.....*.........TTT.....p.#",
    "#............................#",
    "##############1###############",
], spawns={"from_hall": [14, 10, 1]},
    signs_at={"15,3": lib["signs_at"]["14,3"]},
    actors=[dict(a, pos={"bookworm": [18, 6], "junkyu": [4, 8], "jk_librarycard": [9, 5]}[a["id"]]) for a in lib["actors"]])
R["s3_library"]["signs"]["T"] = ["* 대출 데스크다. 반납함이 넘쳐서 책이 탑처럼 쌓여 있다.", "* 맨 위 책 제목: '틀려도 괜찮아'."]

# 체육관: 실제 크기에 가깝게 넓힌다 (농구 코트 하나)
gym = R["a2_gym"]
R["a2_gym"] = keep(gym, map=[
    "######################################",
    "#===w=====NN======w======NN=====w====#",
    "#....................................#",
    "#.G................................G.#",
    "#....................................#",
    "#....................................#",
    "#....................................2",
    "#....................................#",
    "#....................................#",
    "#..zzzz........................zzzz..#",
    "#....................................#",
    "#AAA..............................AAA#",
    "##################1###################",
], spawns={"from_hall": [18, 11, 1], "from_cafe": [36, 6, 2]},
    signs_at={"10,1": gym["signs_at"]["7,1"]},
    actors=[dict(gym["actors"][0], pos=[18, 6])])
R["a2_gym"]["signs"]["A"] = ["* 체육 창고 선반이다. 배구공, 피구공, 줄넘기... 바람 빠진 농구공 하나에 '3반 우승 기원'이라고 적혀 있다."]

# 급식실
caf = R["a2_cafeteria"]
R["a2_cafeteria"] = keep(caf, map=[
    "##############################",
    "#=N====w====w====w====w===bb=#",
    "#............................#",
    "#.TTTTTTTTTT.................#",
    "1............................#",
    "#..oo..oo..oo..oo..oo..oo....#",
    "#............................#",
    "#..oo..oo..oo..oo..oo..oo....#",
    "#............................#",
    "#..oo..oo..oo..oo..oo..oo....#",
    "#............................#",
    "#..*.........Q.............p.#",
    "##############################",
], spawns={"from_gym": [1, 4, 3]},
    actors=[dict(a, pos={"curry": [14, 2], "jk_umbrella": [26, 9]}[a["id"]]) for a in caf["actors"]])

# 대강의실은 이제 잠긴 방 (5장이 천문대로 바뀌었다)
for k in ["a2_lecture"]:
    R.pop(k, None)
    FILE_OF.pop(k, None)

# ------------------------------------------------------------------ 5장 「천문대」: 옥상, 천문대 돔
def build_roof():
    W, H = 44, 14
    g = [["#"] * W for _ in range(H)]
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            g[y][x] = "r" if y in (1, H - 2) or x in (1, W - 2) else "."
    for x in range(18, 26):
        g[1][x] = "u"
    for x in (18, 19, 20, 23, 24, 25):
        g[2][x] = "u"
    g[2][21] = g[2][22] = "2"
    for x, y in ((4, 4), (12, 4), (20, 4)):
        g[y][x] = "Y"
    for x, y in ((31, 4), (39, 4), (13, 9)):
        g[y][x] = "t"
    for x0 in (6, 34):
        for dx in (0, 1):
            for y in (6, 7):
                g[y][x0 + dx] = "o"
    for x in (4, 5, 37, 38):
        g[9][x] = "z"
    g[9][25] = "*"
    g[H - 2][6] = g[H - 2][7] = "1"
    return ["".join(r) for r in g]


ROOF_MAP = build_roof()
R["roof"] = {
    "name": "옥상 - 별이 가장 가까운 곳",
    "theme": "school", "floor": "roof", "music": "astro", "light": "none", "sky": True,
    "map": ROOF_MAP,
    "spawns": {"from_hall": [6, 11, 1], "from_dome": [21, 3, 0]},
    "doors": {
        "1": {"to": "f5_hall", "spawn": "from_roof", "style": "stairs", "label": "↓ 5층"},
        "2": {"event": "enter_dome", "label": "천문대 돔", "need_flag": "roof_open", "glow": col(0.6, 0.7, 1.0), "text": [
            "* 천문대 돔의 문이다. 문에 별자리판 세 개가 그려져 있다.",
            "* [ 옥상의 별자리판 세 개를 모두 풀면 열립니다 ]",
        ]},
    },
    "signs": {
        "r": ["* 옥상 난간이다. 아래로 운동장과 기숙사, 그 너머 세종시 불빛이 보인다.", "* 불빛이 너무 밝아서 별이 반쯤 지워져 있다."],
        "o": ["* 실외기다. 윙윙 돈다. 따뜻한 바람이 나온다. 손을 녹였다."],
        "t": ["* 관측회 때 쓰는 작은 망원경이다. 렌즈 뚜껑에 '쓰고 나서 꼭 닫기!!'"],
        "z": ["* 벤치다. 별 보다가 잠든 사람이 많았는지, 담요 하나가 개어져 있다."],
        "u": ["* 천문대 돔의 흰 벽이다. 차갑다. 안에서 모터 소리가 난다."],
        "Y": ["* 별자리판이다."],
    },
    "signs_at": {
        "4,4": {"event": "star_board", "q": 0},
        "12,4": {"event": "star_board", "q": 1},
        "20,4": {"event": "star_board", "q": 2},
    },
    "actors": [
        {"id": "junkyu", "look": "junkyu", "pos": [36, 9], "event": "jk_roof", "chapter": [5, 5]},
        {"id": "jk_studentid", "look": "lost", "pos": [28, 10], "solid": False, "unless_flag": "jk_found_studentid", "event": "jk_item", "item": "studentid"},
        {"id": "lamp", "look": "lamp", "pos": [40, 6], "half_width": 12.0, "unless_flag": "lamp_done", "event": "roof_lamp"},
    ],
    "triggers": [
        {"rect": [2, 7, 40, 2], "event": "roof_meteor", "once": "met_meteor"},
    ],
    "on_enter": "roof_enter",
}
R["roof_dome"] = {
    "name": "옥상 천문대 돔",
    "theme": "school", "floor": "dark", "music": "astro", "light": "none",
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
    "spawns": {"from_roof": [11, 9, 1]},
    "doors": {"1": {"to": "roof", "spawn": "from_dome"}},
    "signs": {
        "M": {"event": "telescope"},
        "k": ["* 관측 기록장이 꽂힌 책장이다. 표지마다 날짜와 '맑음/흐림'이 적혀 있다.", "* 흐림이 훨씬 많다. 그래도 매일 적혀 있다."],
        "A": ["* 메달 진열장이다. 철인3종 완주 메달이 줄줄이 걸려 있다.", "* '수영 3.8km · 사이클 180.2km · 마라톤 42.195km'", "* 맨 앞 메달 리본에 작게: '꼴찌 완주. 그래도 완주.'"],
        "u": ["* 돔 안쪽 벽이다. 별 스티커가 몇 개 붙어 있다. 누가 붙였을까."],
    },
    "actors": [
        {"id": "astro", "look": "astro", "pos": [11.5, 6], "half_width": 18.0, "unless_flag": "astro_done", "event": "ch5_astro"},
    ],
    "on_enter": "dome_enter",
}
FILE_OF["roof"] = "rooms_ch5.gd"
FILE_OF["roof_dome"] = "rooms_ch5.gd"

# 트루 엔딩의 아침 5층 복도: 새 5층 복도와 같은 모양
epi = R["epi_hall"]
f5 = R["f5_hall"]
epi["map"] = [row.replace("*", ".") for row in f5["map"]]
nd = {}
for c, d in f5["doors"].items():
    if c in epi["doors"]:
        nd[c] = dict(epi["doors"][c], label=d.get("label", ""))
        if d.get("label_below"):
            nd[c]["label_below"] = True
    elif d.get("locked"):
        nd[c] = d
nd["R"] = {"locked": True, "style": "stairs", "label": "↑ 옥상", "text": ["* 옥상 계단이다. 철문에 새 안내문이 붙어 있다.", "* '이번 주 금요일 밤 - 천문 선생님과 함께하는 별 관측회. 누구나 환영. 꼴찌도 환영.'"]}
epi["doors"] = nd
epi["spawns"] = {"start": list(f5["spawns"]["from_multimedia"])}
# 반 친구들: 멀티디자인실(A507)에서 수학 강의실(S512)까지 가는 길목에 선다
spots = {"kid1": [57, a_cy(57)], "kid2": [66, a_cy(66) + 1], "kid3": [75, 40], "kid4": [70, 47],
         "kid5": [58, 46], "kid6": [49, 48], "kid7": [39, 47], "junkyu": [31, 47]}
for a in epi["actors"]:
    a["pos"] = spots.get(a["id"], a["pos"])
epi["actors"].append({"id": "kid9", "if_flag": "astro_spared", "look": "kid", "pos": [83, 34],
    "lines": ["반 친구: 너 옥상 천문대 가 봤어? 천문 선생님이 아침부터 돔 문 열어 놓고 계시더라.",
              "반 친구: 이번 주 관측회 공지에 '꼴찌도 환영'이래. 선생님 철인3종 메달 걸고 계셨어."],
    "style": {"coat": col(0.3, 0.3, 0.55), "hair": col(0.15, 0.1, 0.08), "glasses": True}})
epi["signs_at"] = {"89,31": ["* 5층 시설 안내도다. 어젯밤 그대로다.", "* 구석의 낙서도 그대로 있다. 그 밑에 한 줄이 늘었다.", "* '완벽한 학교는 없다. 그래서 다행이다.'"]}
epi["plates"] = f5["plates"]

# 1장: 돌문 라벨
for a in R["forest_1"].get("actors", []):
    if a.get("id") == "gate1":
        a["label"] = "X?"
for a in R["forest_4"]["actors"]:
    if a["id"].startswith("seq_"):
        a["label"] = {"seq_0": "5,?", "seq_1": "10,?", "seq_2": "11,?"}[a["id"]]
R["forest_1"]["signs"]["g"] = ["* '집합과 명제의 방에 오신 것을 환영합니다.'", "* '이 방의 모든 것은 참이거나 거짓입니다. 애매한 것은 반입 금지.'"]
for a in R["optics_3"]["actors"]:
    if a["id"] == "gate_polar":
        a["label"] = "PA·g²"

# 기숙사 데크로 다시 갈 수 있으니 2층 체육관 쪽 연결 그대로
# ------------------------------------------------------------------ 교실 이름 = 복도 문 명패 (실 번호 + 용도)
LINK = {"s5_multimedia": ("f5_hall", "1"), "s5_math_class": ("f5_hall", "2"), "s5_math_office": ("f5_hall", "3"),
        "s5_observatory": ("f5_hall", "5"), "a5_art": ("f5_hall", "6"), "a5_club": ("f5_hall", "9"),
        "a4_mac": ("f4_hall", "7"), "a4_music": ("f4_hall", "8"), "a4_karaoke": ("f4_hall", "9"),
        "s3_library": ("f3_hall", "1"), "a3_robot": ("f3_hall", "8"), "a2_gym": ("f2_hall", "9"),
        "a2_server": ("f2_hall", "7"), "a1_principal": ("f1_hall", "8")}
for rid, (hid, c) in LINK.items():
    label = R[hid]["doors"][c]["label"]
    tail = R[rid]["name"].split(" - ", 1)
    R[rid]["name"] = "%s동 %s층 %s%s" % (label[0], hid[1], label, (" - " + tail[1]) if len(tail) > 1 else "")

# ------------------------------------------------------------------ 미니맵용 위치 ("where")
# 복도: {"floor": "5F", "hall": true}  → 걸어 다니는 위치가 그대로 미니맵의 점이 된다
# 교실·던전: {"floor": "5F", "pos": [x, y]}  → 그 방으로 들어가는 복도 문의 칸
FLOOR_OF = {hid: fl for fl, hid in FLOORS}


def door_pos(hid, c):
    for y, row in enumerate(R[hid]["map"]):
        x = row.find(c)
        if x >= 0:
            return [x, y]
    return [HW // 2, HH // 2]


ROOTS = {
    "forest_1": ("f5_hall", "2"), "bio_1": ("f4_hall", "4"), "optics_1": ("f2_hall", "1"),
    "a2_server": ("f2_hall", "7"), "a1_principal": ("f1_hall", "8"), "dorm_hall": ("f2_hall", "4"),
}
where = {}
for fl, hid in FLOORS:
    where[hid] = {"floor": fl, "hall": True}
for root, (hid, c) in ROOTS.items():
    where[root] = {"floor": FLOOR_OF[hid], "pos": door_pos(hid, c)}
where["dorm_hall"] = {"floor": "DORM"}
where["roof"] = {"floor": "R"}
where["epi_hall"] = {"floor": "5F", "hall": True}
for k in ["yard", "garden", "parcel_room"]:
    where[k] = {"floor": "OUT"}
changed = True
while changed:
    changed = False
    for rid, r in R.items():
        if rid in where:
            continue
        for c, d in r.get("doors", {}).items():
            to = d.get("to")
            if to in where:
                src = where[to]
                if src.get("hall"):
                    p = [HW // 2, HH // 2]
                    for cc, dd in R[to]["doors"].items():
                        if dd.get("to") == rid:
                            p = door_pos(to, cc)
                    where[rid] = {"floor": src["floor"], "pos": p}
                else:
                    where[rid] = dict(src)
                changed = True
                break
for rid in R:
    R[rid]["where"] = where.get(rid, {"floor": "?"})

# ------------------------------------------------------------------ 검사
ok = True
for rid, r in R.items():
    m = r["map"]
    w = len(m[0])
    if any(len(row) != w for row in m):
        print("WIDTH", rid, [len(x) for x in m]); ok = False
    solid = SOLID[r.get("theme", "school")]
    dchars = set(r.get("doors", {}).keys())

    def bad(x, y):
        x, y = int(x), int(y)
        if not (0 <= y < len(m) and 0 <= x < w):
            return "out"
        c = m[y][x]
        if c in dchars:
            return None
        return c if c in solid else None
    for k, s in r["spawns"].items():
        b = bad(s[0], s[1])
        if b:
            print("SPAWN", rid, k, s, repr(b)); ok = False
    for a in r.get("actors", []):
        b = bad(a["pos"][0], a["pos"][1])
        if b:
            print("ACTOR", rid, a["id"], a["pos"], repr(b)); ok = False
    for ch in dchars:
        if not any(ch in row for row in m):
            print("DOOR missing", rid, ch); ok = False
    for ch, d in r.get("doors", {}).items():
        if "to" in d:
            if d["to"] not in R:
                print("NO ROOM", rid, ch, d["to"]); ok = False
            elif d["spawn"] not in R[d["to"]]["spawns"]:
                print("NO SPAWN", rid, "->", d["to"], d["spawn"]); ok = False
    for k in r.get("signs_at", {}):
        x, y = map(int, k.split(","))
        if not (0 <= y < len(m) and 0 <= x < w):
            print("SIGN_AT out", rid, k); ok = False
if not ok:
    sys.exit("FIX")


# ------------------------------------------------------------------ 쓰기
def gd(v, ind=1):
    t = "\t" * ind
    if isinstance(v, C):
        return "Color(%s)" % ", ".join(repr(float(x)) for x in v.v)
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=False)
    if isinstance(v, list):
        if all(isinstance(x, (int, float)) and not isinstance(x, bool) for x in v) or len(json.dumps(v, ensure_ascii=False, default=str)) < 70:
            return "[" + ", ".join(gd(x, ind) for x in v) + "]"
        return "[\n" + "".join(t + "\t" + gd(x, ind + 1) + ",\n" for x in v) + t + "]"
    if isinstance(v, dict):
        if not v:
            return "{}"
        return "{\n" + "".join(t + "\t" + json.dumps(k, ensure_ascii=False) + ": " + gd(x, ind + 1) + ",\n" for k, x in v.items()) + t + "}"
    raise TypeError(v)


HEAD = {
    "rooms_halls.gd": "본관 복도 1~5층. 5층 시설 안내도의 평면 배치: 아래쪽 S동 가로 복도, 서쪽 끝의 수학 구역, 동쪽 중앙 홀, 왼쪽 위로 뻗는 A동 사선 복도.",
    "rooms_f5.gd": "5층 교실들.", "rooms_f4.gd": "4층 교실들.", "rooms_lower.gd": "3층 · 2층 · 1층 교실들.",
    "rooms_ch1.gd": "Chapter 1 「집합과 명제의 방」.", "rooms_ch2.gd": "Chapter 2 「생명 실험실」.",
    "rooms_ch3.gd": "Chapter 3 「단일광자 실험실」.", "rooms_ch4.gd": "Chapter 4 「기숙사 점호 시간의 악몽」.",
    "rooms_ch5.gd": "Chapter 5 「천문대」 — 옥상과 천문대 돔.", "rooms_ch56.gd": "Chapter 6 서버실과 교장실.",
    "rooms_extra.gd": "확장판 방들.",
}
files = {}
for rid, f in FILE_OF.items():
    files.setdefault(f, []).append(rid)
order = []
for f, ids in files.items():
    out = ["extends RefCounted", "## " + HEAD.get(f, ""), "## (tools/world.py 가 만든 파일. 직접 고쳐도 되지만 world.py 를 다시 돌리면 덮어쓴다)", "", "const ROOMS := {"]
    for rid in ids:
        out.append("\t" + json.dumps(rid) + ": " + gd(R[rid], 1) + ",")
        out.append("")
    out.append("}")
    open(os.path.join(ROOT, "data", f), "w").write("\n".join(out) + "\n")
    order.append(f)
# 미니맵용 평면 (복도 맵 칸 좌표)
plan = {
    "w": HW, "h": HH,
    "rects": [[S_X[0], S_Y[0], S_X[1] - S_X[0] + 1, S_Y[1] - S_Y[0] + 1],
              [HUB_COL[0], a_cy(75) - 1, HUB_COL[1] - HUB_COL[0] + 1, S_Y[0] - a_cy(75) + 1],
              [HUB[0], HUB[1], HUB[2] - HUB[0] + 1, HUB[3] - HUB[1] + 1]],
    "a_wing": [[31, a_cy(31)], [76, a_cy(76)]],
    "m_wing": [[4, m_cy(4)], [26, m_cy(26)]],
    "tri": [list(p) for p in TRI],
    "labels": [["S동", 50, S_Y[1] + 5], ["A동", 46, a_cy(46) - 6], ["수학", 8, m_cy(14) - 4]],
}
sec = ["extends RefCounted", "## 미니맵용 학교 평면: 5층 시설 안내도의 S동·A동·수학 구역·중앙 홀 모양. tools/world.py 가 만든다.", "",
       "const FLOORS := " + gd([{"id": fl, "hall": hid} for fl, hid in FLOORS], 0),
       "const PLAN := " + gd(plan, 0), ""]
open(os.path.join(ROOT, "data", "section.gd"), "w").write("\n".join(sec) + "\n")
print("files:", order)
print("rooms:", len(R))
json.dump({"files": order}, open(os.path.join(HERE, "world_files.json"), "w"))
