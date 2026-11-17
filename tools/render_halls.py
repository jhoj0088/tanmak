#!/usr/bin/env python3
"""본관 복도 배경 그림 생성기 -> assets/halls/f1_hall.png ... f5_hall.png

    python3 tools/world.py          (먼저: 복도 맵을 만들고 tools/halls.json 을 쓴다)
    python3 tools/render_halls.py   (그 맵으로 복도 그림을 그린다. numpy, Pillow 필요)

학교 사진(1층·2층·옥상, 2026-10-27 촬영)을 보고 정한 것:
  - 1층 바닥: 회색 화강석 + 적갈색 화강석 띠, 중앙 홀은 흰 화강석에 적갈색·검정 세모 띠, 덮개 씌운 그랜드 피아노
  - 2~5층 바닥: 흰 인조석 타일 + 짙은 회색 타일 줄무늬
  - 교실 쪽 벽: 크림색 허리벽 + 검정 걸레받이, 그 위 원목 틀 2단 채광창,
    원목 문(위 채광창, 세로 좁은 유리창, 도어락, 남색 실 번호판)
  - 노란 원기둥(아래 검정 띠), 유리 난간 + 원목 손잡이 + 스테인리스 기둥
  - 색 강조벽: 화장실 앞 보라·주황(스테인리스 세면대), 계단·엘리베이터 쪽 연두(2층 안내판),
    1층 중앙 홀 베이지 대리석, 1층 A동 민트색 벽 + 원목 타공판
  - 스테인리스 소화전함, 비상구 유도등, 분리수거함(노랑·파랑·초록 뚜껑), 원목 사물함, 정수기, 자판기
시점은 위에서 비스듬히 내려다보는 3/4 시점: 위쪽 벽은 면이 보이고(높이 72px = 2와 1/4칸),
아래쪽 벽은 윗면만 보인다. 게임 속 타일 한 칸 = 32px. 그림 한 장 = 복도 맵 전체(108 x 66 칸).
게임은 이 그림 위에 문 잠금 표시, 명패, 밤 조명, 사람들을 그린다 (scripts/world/overworld.gd).
"""
import json, os, math
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..")
OUT = os.path.join(ROOT, "assets", "halls")
T = 32
WALL_UP = 40          # 위쪽 벽 면이 그 칸 위로 더 올라가는 높이 (벽 면 전체 = 32 + 40)


def hx(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def dark(c, t):
    return mix(c, (0, 0, 0), t)


def light(c, t):
    return mix(c, (255, 255, 255), t)


C = {
    "void": hx("06080e"), "ceil": hx("06080e"), "ceil2": hx("181d2a"),
    "g1": hx("a3a3a2"), "g1d": hx("878684"), "g1l": hx("c3c2bf"),
    "red": hx("94675b"), "redd": hx("74493f"), "redl": hx("b08072"),
    "blk": hx("2a2a2f"), "blkl": hx("45454d"),
    "hall1": hx("d4d4d4"), "hall1d": hx("b9b9ba"),
    "t2": hx("dcdad3"), "t2d": hx("c4c1b9"), "t2l": hx("ecebe6"),
    "stripe": hx("3c3e45"), "stripel": hx("5a5d66"),
    "cream": hx("ebe4d2"), "creamd": hx("d4cab3"), "creaml": hx("f6f2e6"),
    "base": hx("26262b"),
    "oak": hx("b5773f"), "oakd": hx("8a552d"), "oakl": hx("cf975c"), "oakdd": hx("5a3318"),
    "glass": hx("2b3a55"), "glassl": hx("3f5478"), "blind": hx("e7e1cf"),
    "mint": hx("cde2dc"), "mintd": hx("aecac2"),
    "marble": hx("cbbea4"), "marbled": hx("b09f83"), "marblel": hx("e0d5c0"),
    "lime": hx("b7d33d"), "limed": hx("94ad2a"), "purple": hx("6a4e99"), "purpled": hx("4c3576"),
    "orange": hx("ef943a"), "oranged": hx("cd7322"), "yellow": hx("f2c434"), "yellowd": hx("cf9e1a"),
    "blue": hx("3d86d1"), "blued": hx("2c69ab"),
    "salmon": hx("e5a98a"), "salmond": hx("cb8d6e"),
    "steel": hx("c1c6ca"), "steeld": hx("8c949b"), "steell": hx("e7ebed"),
    "navy": hx("22305b"), "white": hx("f8f8f4"),
    "pillar": hx("f2c434"), "pillarl": hx("fde38c"), "pillarm": hx("e4b322"), "pillard": hx("c4930f"), "pillardd": hx("8a6506"),
    "plant": hx("3f8a4a"), "plantl": hx("66b466"), "plantd": hx("285a32"), "pot": hx("efefeb"),
    "sign_red": hx("c83a3a"), "exit": hx("2fa860"),
    "sofa_k": hx("2b2b30"), "cork": hx("c99d64"), "peg": hx("d6ae76"),
    "edge": hx("d2cbbb"), "edged": hx("8c8579"),
}

FLOOR_CHARS = set(".^Jpv SofgPls*_x")       # 바닥 위에 놓인 것 (그 칸은 바닥으로 그린다)
OPEN_CHARS = set("an")                       # 중앙 홀의 뚫린 곳과 난간 (바닥 높이)


def hsh(*a):
    v = 2166136261
    for x in a:
        v = ((v ^ (int(x) & 0xffffffff)) * 16777619) & 0xffffffff
    return v


class Painter:
    """그림판. oy = 위쪽 여백 (방의 맨 윗줄 벽이 그림 밖으로 잘리지 않게). 모든 좌표는 게임 속 픽셀"""
    def __init__(self, w, h, oy=0):
        self.oy = oy
        self.img = Image.new("RGB", (w * T, h * T + oy), C["void"])
        self.d = ImageDraw.Draw(self.img)
        self.W, self.H = w * T, h * T + oy

    def rect(self, x, y, w, h, col):
        if w > 0 and h > 0:
            y += self.oy
            self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=col)

    def line(self, x0, y0, x1, y1, col, wd=1):
        self.d.line([x0, y0 + self.oy, x1, y1 + self.oy], fill=col, width=wd)

    def px(self, x, y, col):
        y += self.oy
        if 0 <= x < self.W and 0 <= y < self.H:
            self.img.putpixel((int(x), int(y)), col)

    def poly(self, pts, col):
        self.d.polygon([(a, b + self.oy) for a, b in pts], fill=col)

    def ell(self, x0, y0, x1, y1, col):
        self.d.ellipse([x0, y0 + self.oy, x1, y1 + self.oy], fill=col)

    def blend(self, x, y, w, h, col, a):
        """반투명 사각형"""
        x, y, w, h = int(x), int(y) + self.oy, int(w), int(h)
        x0, y0, x1, y1 = max(0, x), max(0, y), min(self.W, x + w), min(self.H, y + h)
        if x1 <= x0 or y1 <= y0:
            return
        reg = np.asarray(self.img.crop((x0, y0, x1, y1))).astype(np.float32)
        reg = reg * (1 - a) + np.array(col, np.float32) * a
        self.img.paste(Image.fromarray(reg.astype(np.uint8)), (x0, y0))

    def glow(self, cx, cy, rx, ry, col, a):
        """부드러운 타원 빛 (가장자리로 갈수록 옅게)"""
        cy += self.oy
        x0, y0 = int(cx - rx), int(cy - ry)
        x1, y1 = int(cx + rx), int(cy + ry)
        x0c, y0c, x1c, y1c = max(0, x0), max(0, y0), min(self.W, x1), min(self.H, y1)
        if x1c <= x0c or y1c <= y0c:
            return
        reg = np.asarray(self.img.crop((x0c, y0c, x1c, y1c))).astype(np.float32)
        yy, xx = np.mgrid[y0c:y1c, x0c:x1c]
        m = 1.0 - ((xx - cx) / rx) ** 2 - ((yy - cy) / ry) ** 2
        m = np.clip(m, 0, 1) ** 1.5 * a
        reg = reg * (1 - m[..., None]) + np.array(col, np.float32) * m[..., None]
        self.img.paste(Image.fromarray(np.clip(reg, 0, 255).astype(np.uint8)), (x0c, y0c))


class Hall:
    def __init__(self, hid, info, plan):
        self.hid = hid
        self.fl = info["fl"]
        self.n = int(self.fl[0])
        self.m = info["map"]
        self.H, self.W = len(self.m), len(self.m[0])
        self.doors = info["doors"]
        self.S_Y = plan["S_Y"]
        self.HUB = plan["HUB"]
        self.TRI = plan["TRI"]

    def c(self, x, y):
        if 0 <= x < self.W and 0 <= y < self.H:
            return self.m[y][x]
        return "#"

    def is_floor(self, x, y):
        c = self.c(x, y)
        return c in FLOOR_CHARS or c in OPEN_CHARS

    def is_door(self, x, y):
        return self.c(x, y) in self.doors

    def zone(self, x, y):
        hx0, hy0, hx1, hy1 = self.HUB
        if hx0 <= x <= hx1 and hy0 <= y <= hy1:
            return "H"
        if self.S_Y[0] <= y <= self.S_Y[1] and x >= 24:
            return "S"
        if x < 28 and y > 44:
            return "M"
        return "A"

    @staticmethod
    def a_line(xp):      # A동 사선 복도 가운데 줄 (픽셀)
        return (4 + (xp / T - 33) * 26 / 42 + 0.5) * T

    @staticmethod
    def m_line(xp):
        return (47 + (26 - xp / T) * 15 / 20 + 0.5) * T


# ================================================================== 바닥
def floor_tile(p, hl, x, y):
    """게임 한 칸(32px) = 돌 타일 2x2 (16px). 사진의 60cm 타일 크기"""
    z = hl.zone(x, y)
    for sy in range(2):
        for sx in range(2):
            X, Y = x * T + sx * 16, y * T + sy * 16
            gx, gy = X // 16, Y // 16
            cxp, cyp = X + 8, Y + 8
            if hl.n == 1:
                if z == "H":
                    base, d1, l1 = C["hall1"], C["hall1d"], light(C["hall1"], 0.5)
                else:
                    base, d1, l1 = C["g1"], C["g1d"], C["g1l"]
                    # 적갈색 띠: 일정 간격의 가로지르는 띠
                    if z == "S" and gx % 16 == 7:
                        base, d1, l1 = C["red"], C["redd"], C["redl"]
            else:
                base, d1, l1 = C["t2"], C["t2d"], C["t2l"]
                dk = False
                if z == "S":
                    dk = gx % 9 == 4 and abs(cyp - 47.5 * T) < 34
                elif z == "H":
                    dk = (gx % 10 in (2, 3) and gy % 7 == 3) or (gx % 10 in (7, 8) and gy % 7 == 0)
                if dk:
                    base, d1, l1 = C["stripe"], dark(C["stripe"], 0.25), C["stripel"]
            v = (hsh(gx, gy, 7) % 9) - 4
            base = tuple(max(0, min(255, b + v)) for b in base)
            p.rect(X, Y, 16, 16, base)
            h = hsh(gx, gy, 1)
            for i in range(9):
                h = hsh(h, i)
                col = d1 if (h >> 16) % 3 else l1
                if (h >> 21) % 6 == 0:
                    col = dark(base, 0.42)
                p.px(X + h % 15, Y + (h >> 8) % 15, col)
            # 줄눈 (아래·오른쪽 어둡게, 위·왼쪽 밝게 = 살짝 도드라진 돌)
            p.line(X, Y + 15, X + 15, Y + 15, dark(base, 0.16))
            p.line(X + 15, Y, X + 15, Y + 15, dark(base, 0.16))
            p.line(X, Y, X + 14, Y, light(base, 0.18))


def floor_light(p, hl):
    """천장 등이 광택 바닥에 비친 자국 (사진처럼 길쭉한 빛)"""
    # S동 복도
    for xp in range(26 * T, 103 * T, 6 * T):
        if hl.is_floor(xp // T, 47):
            p.glow(xp + 16, 47 * T + 18, 46, 9, (255, 255, 255), 0.30)
            p.glow(xp + 16, 47 * T + 18, 18, 4, (255, 255, 255), 0.35)
    # A동
    for xg in range(34, 76, 5):
        cy = hl.a_line(xg * T)
        if hl.is_floor(xg, int(cy // T)):
            p.glow(xg * T + 16, cy, 34, 8, (255, 255, 255), 0.26)
    for xg in range(6, 26, 5):
        cy = hl.m_line(xg * T)
        if hl.is_floor(xg, int(cy // T)):
            p.glow(xg * T + 16, cy, 34, 8, (255, 255, 255), 0.26)
    # 중앙 홀
    hx0, hy0, hx1, hy1 = hl.HUB
    for gx in range(hx0 + 2, hx1, 5):
        for gy in range(hy0 + 2, hy1, 4):
            if hl.c(gx, gy) in FLOOR_CHARS:
                p.glow(gx * T + 16, gy * T + 16, 40, 10, (255, 255, 255), 0.18)


def floor_bands_1f(p, hl):
    """1층 중앙 홀: 세모(위층 아트리움 모양)를 따라 적갈색 띠와 검정 띠 (사진 092714)"""
    (ax, ay), (bx, by), (cx, cy) = [(v[0] * T, v[1] * T) for v in hl.TRI]
    by += T
    cy += T
    cx += T
    for inset, col, wd in ((-30, C["redd"], 22), (-30, C["red"], 18), (-30, C["redl"], 2),
                           (14, dark(C["blk"], 0.2), 20), (14, C["blk"], 16), (14, C["blkl"], 2)):
        pts = tri_inset([(ax, ay), (bx, by), (cx, cy)], inset)
        p.d.line(pts + [pts[0], pts[1]], fill=col, width=wd, joint="curve")


def tri_inset(pts, k):
    cxm = sum(q[0] for q in pts) / 3.0
    cym = sum(q[1] for q in pts) / 3.0
    out = []
    for (x, y) in pts:
        dx, dy = cxm - x, cym - y
        L = math.hypot(dx, dy)
        out.append((x + dx / L * k * 1.6, y + dy / L * k * 1.6))
    return out


# ================================================================== 위쪽 벽 (면이 보이는 벽)
def wall_style(hl, x, y):
    if hl.zone(x, y + 1) == "H" or y == 31:
        if hl.n == 1:
            return "marble"
        return "lime" if x <= 92 else "classroom"
    if 49 <= x <= 57 and y == 45:
        return "purple" if x <= 53 else "orange"
    if hl.zone(x, y + 1) == "A" and hl.n == 1:
        return "mint"
    return "classroom"


def F(y, k):
    """벽 면 안의 높이 k (0 = 벽 윗면, 71 = 바닥에 닿는 줄) -> 픽셀 y"""
    return y * T - WALL_UP + k


def face_base(p, hl, x, y, style):
    X = x * T
    if style in ("classroom", "mint"):
        lower = C["cream"] if style == "classroom" else C["mint"]
        lowd = C["creamd"] if style == "classroom" else C["mintd"]
        p.rect(X, F(y, 0), T, 72, lower)
        p.rect(X, F(y, 4), T, 4, dark(lower, 0.12))                 # 천장 그늘
        # 원목 2단 채광창 (사진 092600)
        p.rect(X, F(y, 15), T, 34, C["oak"])
        p.rect(X, F(y, 15), T, 1, C["oakl"])
        h = hsh(x, y, 21)
        kind = h % 5                                                 # 0,1 어두운 유리 / 2,3 블라인드 / 4 종이 붙은 창
        for gx in (2, 18):
            p.rect(X + gx, F(y, 18), 12, 7, C["glassl"])
            p.rect(X + gx, F(y, 28), 12, 17, C["glass"])
            if kind in (2, 3):
                drop = 6 + (h >> 4) % 10
                p.rect(X + gx, F(y, 28), 12, drop, C["blind"])
                for k in range(0, drop, 2):
                    p.line(X + gx, F(y, 28) + k, X + gx + 11, F(y, 28) + k, dark(C["blind"], 0.08))
            elif kind == 4 and gx == 18:
                p.rect(X + gx + 2, F(y, 30), 8, 11, hx("f4f2ea"))
                p.line(X + gx + 3, F(y, 33), X + gx + 8, F(y, 33), hx("9a9a9a"))
                p.line(X + gx + 3, F(y, 36), X + gx + 7, F(y, 36), hx("9a9a9a"))
            p.line(X + gx + 2, F(y, 43), X + gx + 9, F(y, 30), C["glassl"])       # 유리 반사
        p.rect(X + 14, F(y, 15), 4, 34, C["oakd"])
        p.rect(X + 15, F(y, 15), 1, 34, C["oakl"])
        p.rect(X, F(y, 25), T, 3, C["oak"])
        p.rect(X, F(y, 45), T, 4, C["oakd"])
        p.rect(X, F(y, 49), T, 2, C["oakl"])                          # 창턱
        p.rect(X, F(y, 51), T, 1, dark(lower, 0.2))
        p.line(X + 31, F(y, 52), X + 31, F(y, 66), lowd)              # 허리벽 판 이음
        p.rect(X, F(y, 66), T, 2, lowd)
        p.rect(X, F(y, 68), T, 4, C["base"])
    elif style == "marble":
        p.rect(X, F(y, 0), T, 72, C["marble"])
        for k in range(8, 68, 20):
            p.line(X, F(y, k), X + T - 1, F(y, k), C["marbled"])
        off = 16 if (x + (1 if y % 2 else 0)) % 2 else 0
        p.line(X + off, F(y, 8), X + off, F(y, 67), C["marbled"])
        h = hsh(x, y, 3)
        for i in range(6):
            h = hsh(h, i)
            sx, sy = X + h % 26, F(y, 10) + (h >> 7) % 52
            p.line(sx, sy, sx + 5, sy + 3, C["marblel"])
            p.line(sx + 1, sy + 1, sx + 3, sy + 2, C["marbled"])
        p.rect(X, F(y, 68), T, 4, C["base"])
    else:
        col = {"lime": C["lime"], "purple": C["purple"], "orange": C["orange"]}[style]
        cold = {"lime": C["limed"], "purple": C["purpled"], "orange": C["oranged"]}[style]
        p.rect(X, F(y, 0), T, 72, col)
        if style in ("purple", "orange"):
            p.rect(X, F(y, 0), T, 38, mix(col, C["cream"], 0.45))   # 사진: 위는 흐리고 허리부터 진하게
        p.rect(X, F(y, 4), T, 3, dark(col, 0.15))
        p.rect(X, F(y, 66), T, 2, cold)
        p.rect(X, F(y, 68), T, 4, C["base"])
    # 벽 윗면
    p.rect(X, F(y, 0), T, 3, C["ceil2"])
    p.rect(X, F(y, 3), T, 1, C["edged"])


def face_decor(p, hl, x, y, c, style):
    X = x * T
    if c == "w":
        # 바깥 창 (짙은 알루미늄 틀 + 밤 풍경)
        p.rect(X + 1, F(y, 12), 30, 46, hx("3a3e46"))
        p.rect(X + 3, F(y, 14), 26, 42, hx("1a2640"))
        p.rect(X + 3, F(y, 14), 26, 16, hx("22345a"))
        p.rect(X + 3, F(y, 44), 26, 12, hx("16213a"))
        p.ell(X + 2, F(y, 40), X + 16, F(y, 54), hx("13202e"))       # 나무 그림자
        p.ell(X + 12, F(y, 42), X + 30, F(y, 56), hx("101a28"))
        p.rect(X + 15, F(y, 14), 2, 42, hx("3a3e46"))
        p.rect(X + 3, F(y, 38), 26, 2, hx("3a3e46"))
        h = hsh(x, y, 9)
        for i in range(3):
            h = hsh(h, i)
            p.px(X + 4 + h % 24, F(y, 15) + (h >> 9) % 12, hx("e8ecf5"))
        p.line(X + 5, F(y, 54), X + 13, F(y, 18), hx("2d4570"))
        p.rect(X, F(y, 58), T, 3, hx("cfcfca"))
        p.rect(X, F(y, 61), T, 1, hx("8e8e8a"))
    elif c == "b":
        if style == "lime" and y == 31 and x in (89, 90):
            # 2층 사진: 검정 'Floor information' 안내판 (5층까지 층별 과목)
            p.rect(X + 1, F(y, 10), 30, 50, hx("232428"))
            p.rect(X + 3, F(y, 12), 26, 5, hx("e9e9e9"))
            for k in range(5):
                active = (5 - k) == hl.n
                p.rect(X + 3, F(y, 20) + k * 8, 4, 6, hx("f2f2f2"))
                p.rect(X + 9, F(y, 20) + k * 8, 20, 6, hx("e9e9e9") if active else hx("8d8f94"))
        elif style == "mint" or (x + y) % 2:
            # 원목 타공판 게시판 + 포스터 (사진 092745)
            p.rect(X, F(y, 16), T, 36, C["peg"])
            p.rect(X, F(y, 16), T, 1, light(C["peg"], 0.3))
            for gy in range(F(y, 18), F(y, 50), 3):
                for gx in range(X + 2, X + 31, 3):
                    p.px(gx, gy, dark(C["peg"], 0.32))
            h = hsh(x, y, 4)
            cols = [hx("f4f1e8"), hx("e86a5a"), hx("5a8ad6"), hx("f2c434"), hx("8bc36a"), hx("2a3a6a")]
            for i in range(2):
                h = hsh(h, i)
                py_ = F(y, 20) + h % 8
                col = cols[h % 6]
                p.rect(X + 3 + i * 14, py_, 11, 16, col)
                p.rect(X + 3 + i * 14, py_, 11, 4, dark(col, 0.25))
                p.line(X + 5 + i * 14, py_ + 9, X + 11 + i * 14, py_ + 9, light(col, 0.5))
                p.line(X + 5 + i * 14, py_ + 12, X + 9 + i * 14, py_ + 12, light(col, 0.5))
        else:
            # 코르크 게시판
            p.rect(X + 1, F(y, 16), 30, 34, C["oakd"])
            p.rect(X + 3, F(y, 18), 26, 30, C["cork"])
            h = hsh(x, y, 5)
            cols = [hx("f4f1e8"), hx("f6d36b"), hx("9fd3f0"), hx("f2a3b6")]
            for i in range(3):
                h = hsh(h, i)
                px_, py_ = X + 4 + (h % 17), F(y, 19) + ((h >> 6) % 16)
                p.rect(px_, py_, 8, 11, cols[(h >> 3) % 4])
                p.px(px_ + 4, py_, C["sign_red"])
    elif c == "A":
        # 1층 HALL OF FAME: 노란 띠 + 졸업생 수상 기록 패널 (사진 092636)
        p.rect(X, F(y, 4), T, 58, hx("f1eee6"))
        p.rect(X, F(y, 4), T, 9, C["yellow"])
        p.rect(X, F(y, 13), T, 2, C["yellowd"])
        for k in range(2):
            p.rect(X + 2 + k * 15, F(y, 22), 13, 30, hx("e2dfd5"))
            for j in range(8):
                p.line(X + 4 + k * 15, F(y, 25) + j * 3, X + 12 + k * 15, F(y, 25) + j * 3, hx("a8a49a"))
        p.rect(X, F(y, 62), T, 6, C["marble"])
    elif c == "N":
        p.rect(X + 6, F(y, 18), 20, 30, hx("f6f3ea"))
        p.rect(X + 8, F(y, 20), 16, 12, C["blue"])
        p.ell(X + 12, F(y, 22), X + 20, F(y, 30), C["yellow"])
        p.rect(X + 8, F(y, 36), 16, 2, hx("6a6a6a"))
        p.rect(X + 8, F(y, 40), 11, 2, hx("9a9a9a"))
    elif c == "F":
        fire_box(p, X, y)
    elif c == "E":
        exit_sign(p, X + 8, F(y, 8))
    elif c == "C":
        p.ell(X + 12, F(y, 8), X + 20, F(y, 15), hx("e6e6e6"))
        p.ell(X + 14, F(y, 11), X + 18, F(y, 14), hx("2a2a2a"))


def exit_sign(p, X, Y):
    p.rect(X, Y, 16, 8, C["exit"])
    p.rect(X + 2, Y + 2, 3, 4, C["white"])
    p.line(X + 7, Y + 4, X + 13, Y + 4, C["white"])
    p.line(X + 11, Y + 2, X + 13, Y + 4, C["white"])
    p.line(X + 11, Y + 6, X + 13, Y + 4, C["white"])


def fire_box(p, X, y):
    """스테인리스 소화전함 (빨간 버튼·등, '소화전' 글자 자리)"""
    p.rect(X + 5, F(y, 18), 22, 50, C["steeld"])
    p.rect(X + 6, F(y, 19), 20, 48, C["steel"])
    p.rect(X + 6, F(y, 19), 20, 11, hx("d6dadd"))
    p.ell(X + 8, F(y, 21), X + 15, F(y, 28), C["sign_red"])
    p.ell(X + 18, F(y, 22), X + 23, F(y, 27), hx("ff7a5a"))
    p.rect(X + 13, F(y, 36), 6, 3, hx("6a6a6a"))
    p.rect(X + 13, F(y, 42), 6, 3, hx("6a6a6a"))
    p.rect(X + 13, F(y, 48), 6, 3, hx("6a6a6a"))
    p.line(X + 23, F(y, 40), X + 23, F(y, 54), C["steeld"])
    p.rect(X + 7, F(y, 19), 1, 48, C["steell"])


def door_face(p, hl, x, y, ch):
    X = x * T
    d = hl.doors[ch]
    if d.get("style") == "stairs":
        stairs_face(p, hl, x, y, ch)
        return
    left = hl.c(x - 1, y) != ch
    right = hl.c(x + 1, y) != ch
    lw = 3 if left else 0
    rw = 3 if right else 0
    toilet = ch in "!$"
    # 문틀
    p.rect(X, F(y, 13), T, 59, C["oakdd"])
    p.rect(X + lw, F(y, 15), T - lw - rw, 57, C["oak"])
    if toilet:
        # 반투명 유리문 (BOYS / GIRLS, 파란·분홍 사람 아이콘) - 사진 092954
        p.rect(X + 4, F(y, 18), 24, 54, hx("dbe5e8"))
        p.rect(X + 4, F(y, 18), 24, 3, C["steel"])
        p.rect(X + 4, F(y, 38), 24, 2, hx("c7d3d7"))
        p.rect(X + 24, F(y, 40), 2, 18, C["steeld"])
        col = hx("2f6fd0") if ch == "!" else hx("d84a7a")
        p.rect(X + 8, F(y, 24), 9, 12, C["white"])
        p.ell(X + 10, F(y, 25), X + 14, F(y, 29), col)
        p.rect(X + 10, F(y, 30), 5, 5, col)
        p.rect(X + 8, F(y, 44), 3, 14, col)
        return
    # 위 채광창
    p.rect(X + lw + 2, F(y, 17), T - lw - rw - 4, 9, C["glassl"])
    p.line(X + lw + 4, F(y, 24), X + lw + 9, F(y, 18), light(C["glassl"], 0.2))
    p.rect(X, F(y, 26), T, 3, C["oakd"])
    # 문짝 (밝은 원목, 결)
    p.rect(X + lw + 2, F(y, 29), T - lw - rw - 4, 43, C["oakl"])
    for k in range(4):
        gx = X + lw + 5 + k * 7
        p.line(gx, F(y, 30), gx + 1, F(y, 71), light(C["oak"], 0.12))
    p.line(X + lw + 2, F(y, 29), X + T - rw - 3, F(y, 29), light(C["oakl"], 0.3))
    if left:
        p.rect(X + 8, F(y, 33), 4, 18, C["glass"])                  # 세로 좁은 유리창
        p.rect(X + 7, F(y, 32), 6, 1, C["oakd"])
        p.rect(X + 8, F(y, 33), 4, 2, C["glassl"])
    if right:
        p.rect(X + 21, F(y, 45), 4, 9, hx("1c1d22"))                # 도어락
        p.px(X + 22, F(y, 46), hx("6fd0ff"))
        p.px(X + 23, F(y, 46), hx("6fd0ff"))
        p.rect(X + 19, F(y, 56), 7, 2, C["steell"])                 # 손잡이
        p.rect(X + 24, F(y, 55), 2, 4, C["steeld"])
    if left:
        # 남색 실 번호판 (문 위에 돌출)
        p.rect(X + 1, F(y, 5), 22, 7, C["navy"])
        p.rect(X + 3, F(y, 7), 7, 3, C["white"])
        p.rect(X + 12, F(y, 7), 8, 1, hx("aab4d0"))
        p.rect(X + 12, F(y, 9), 6, 1, hx("aab4d0"))
        p.rect(X + 23, F(y, 5), 2, 7, hx("3b4c80"))


def stairs_face(p, hl, x, y, ch):
    """중앙 홀 위쪽 벽의 계단 입구: 살구·크림 계단실 벽, 원목 손잡이, 짙은 철제 난간, 화강석 계단 (사진 092841)"""
    X = x * T
    first = hl.c(x - 1, y) != ch
    up = ch in "UR"
    p.rect(X, F(y, 0), T, 72, C["cream"])
    p.rect(X, F(y, 30), T, 42, C["salmon"])
    p.rect(X, F(y, 30), T, 1, C["salmond"])
    for i in range(9):
        k = 70 - i * 5 if up else 50 + i * 2
        col = mix(hx("a7abb0"), hx("3a3d43"), i / 9.0) if up else mix(hx("6a6e75"), hx("16181d"), i / 9.0)
        p.rect(X + (3 if first else 0), F(y, k - 4), T - (3 if first else 0), 4, col)
        p.line(X + (3 if first else 0), F(y, k - 4), X + T - 1, F(y, k - 4), light(col, 0.3))
    if not up:
        p.rect(X, F(y, 14), T, 32, hx("14161b"))
        p.rect(X, F(y, 14), T, 16, C["cream"])
    # 난간: 짙은 철 기둥 + 원목 손잡이
    if first:
        for k in range(4):
            p.line(X + 4 + k * 7, F(y, 70) - k * 6, X + 4 + k * 7, F(y, 50) - k * 6, hx("3a2a26"), 2)
        p.line(X + 2, F(y, 50), X + 31, F(y, 50) - (24 if up else -4), C["oak"], 3)
        p.line(X + 2, F(y, 49), X + 31, F(y, 49) - (24 if up else -4), C["oakl"], 1)
    else:
        p.line(X, F(y, 36), X + 30, F(y, 36) - (10 if up else -2), C["oak"], 3)
    p.rect(X, F(y, 0), T, 3, C["ceil2"])
    p.rect(X, F(y, 3), T, 1, C["edged"])


def elevator(p, x, y):
    """스테인리스 엘리베이터 (연두 벽) - 사진 093040"""
    X = x * T
    p.rect(X + 2, F(y, 10), 2 * T - 4, 62, C["steeld"])
    p.rect(X + 4, F(y, 12), 2 * T - 8, 60, C["steel"])
    p.rect(X + T - 1, F(y, 12), 2, 60, C["steeld"])
    for k in (8, 14, 44, 50):
        p.line(X + k, F(y, 14), X + k, F(y, 70), C["steell"])
    p.rect(X + 12, F(y, 4), 2 * T - 24, 5, hx("1e1f24"))
    p.rect(X + 28, F(y, 5), 8, 3, hx("ff7a3a"))
    p.rect(X + 2 * T + 1, F(y, 38), 5, 11, hx("2a2b30"))
    p.px(X + 2 * T + 3, F(y, 41), hx("ffd36a"))
    p.px(X + 2 * T + 3, F(y, 45), hx("ffd36a"))


def sasa_wall(p, x, y):
    """1층 현관의 검정 SASA 사인월: 초록 선으로 그린 나무 + 흰 SASA 글씨 (사진 092636)"""
    X = x * T
    p.rect(X, F(y, 6), 4 * T, 62, hx("1d1e22"))
    p.rect(X, F(y, 6), 4 * T, 2, hx("34363c"))
    cx, cyy = X + 40, F(y, 34)
    rnd = hsh(x, y)
    pts = []
    for i in range(16):
        rnd = hsh(rnd, i)
        ang = (i / 16.0) * math.pi
        r = 18 + rnd % 8
        pts.append((cx + math.cos(ang + math.pi) * r * 1.3, cyy - math.sin(ang) * r))
    for i in range(len(pts)):
        for j in (i + 3, i + 5):
            if j < len(pts):
                p.line(pts[i][0], pts[i][1], pts[j][0], pts[j][1], hx("4fb84a"))
    p.line(cx, cyy, cx, F(y, 60), hx("4fb84a"))
    p.line(cx - 6, F(y, 60), cx + 6, F(y, 60), hx("4fb84a"))
    # SASA 글씨 자리 (흰 획)
    sx = X + 72
    for k, w in enumerate((10, 8, 10, 8)):
        p.rect(sx + k * 12, F(y, 44), w, 3, C["white"])
        p.rect(sx + k * 12, F(y, 50), w, 3, C["white"])
    p.line(sx + 44, F(y, 38), sx + 50, F(y, 30), C["white"])
    p.line(sx + 50, F(y, 30), sx + 56, F(y, 38), C["white"])
    p.rect(sx, F(y, 58), 40, 2, hx("9a9a9a"))


def sink_wall(p, x, y):
    """화장실 앞 스테인리스 세면대 + 주황 패널 (사진 092610)"""
    X = x * T
    p.rect(X, F(y, 38), T, 4, C["oakd"])                              # 선반
    for k in (7, 23):
        p.rect(X + k, F(y, 42), 3, 6, C["steell"])
        p.rect(X + k + 2, F(y, 46), 2, 3, C["steeld"])
    p.rect(X, F(y, 48), T, 6, C["steell"])
    p.rect(X, F(y, 54), T, 2, C["steeld"])
    p.rect(X + 1, F(y, 56), T - 2, 12, C["orange"])
    p.rect(X + 1, F(y, 56), T - 2, 2, C["steel"])
    p.rect(X + 15, F(y, 56), 2, 12, C["steel"])


# ================================================================== 아래쪽 벽 (윗면만 보이는 벽)
def top_edge(p, hl, x, y, c):
    X, Y = x * T, y * T
    p.rect(X, Y, T, T, C["ceil"])
    p.rect(X, Y, T, 8, C["edge"])
    p.rect(X, Y + 8, T, 2, C["edged"])
    p.rect(X, Y + 10, T, 3, dark(C["ceil"], 0.5))
    if c == "L":
        # 원목 사물함 (위에서 본 윗면과 앞 모서리)
        p.rect(X, Y, T, 14, C["oakl"])
        p.rect(X, Y, T, 1, light(C["oakl"], 0.3))
        p.rect(X, Y + 14, T, 3, C["oakd"])
        p.line(X + T - 1, Y, X + T - 1, Y + 14, C["oak"])
        p.line(X, Y + 5, X + T - 1, Y + 5, light(C["oak"], 0.2))
        p.line(X, Y + 10, X + T - 1, Y + 10, C["oak"])
    elif c == "Q":
        # 정수기 (흰 몸통, 파랑·빨강 버튼)
        p.rect(X + 6, Y - 10, 20, 24, C["white"])
        p.rect(X + 6, Y - 10, 20, 2, hx("ffffff"))
        p.rect(X + 6, Y + 12, 20, 3, hx("b9bcbf"))
        p.rect(X + 10, Y - 6, 5, 3, hx("4aa3e8"))
        p.rect(X + 18, Y - 6, 5, 3, hx("e85a4a"))
        p.rect(X + 12, Y, 8, 6, hx("cfd3d6"))
    elif c == "K":
        p.rect(X + 2, Y - 6, 28, 20, hx("8c8a86"))
        p.rect(X + 2, Y - 6, 28, 4, hx("aaa8a3"))
        p.rect(X + 6, Y + 2, 20, 3, C["white"])
        p.rect(X + 6, Y + 7, 14, 2, hx("d0d0d0"))


def door_bottom(p, hl, x, y, ch):
    """아래쪽 벽의 문: 문틀 윗면과 문짝 윗부분, 그 아래로 어두운 문간"""
    X, Y = x * T, y * T
    left = hl.c(x - 1, y) != ch
    right = hl.c(x + 1, y) != ch
    lw = 4 if left else 0
    rw = 4 if right else 0
    p.rect(X, Y, T, T, C["ceil"])
    p.rect(X, Y, T, 14, hx("3a2c22"))
    if ch == "4":
        # 정문 현관(1층) / 기숙사 연결 데크(2층): 스테인리스 유리 자동문
        p.rect(X, Y, T, 13, hx("c9dde4"))
        p.rect(X, Y, T, 2, C["steell"])
        p.rect(X, Y + 11, T, 3, C["steeld"])
        p.line(X + (T - 1 if right else 0), Y, X + (T - 1 if right else 0), Y + 13, C["steeld"])
        p.line(X + 6, Y + 10, X + 12, Y + 3, C["white"])
        return
    p.rect(X + lw, Y, T - lw - rw, 10, C["oakl"])
    p.rect(X + lw, Y, T - lw - rw, 2, light(C["oakl"], 0.3))
    p.rect(X + lw, Y + 10, T - lw - rw, 3, C["oak"])
    if left:
        p.rect(X, Y, 4, 15, C["oakdd"])
    if right:
        p.rect(X + T - 4, Y, 4, 15, C["oakdd"])


# ================================================================== 바닥 위 물건
def shadow(p, X, Y, w, h, a=0.28):
    X, Y, w, h = int(X), int(Y) + p.oy, int(w), int(h)
    reg = np.asarray(p.img.crop((X, Y, X + w, Y + h))).astype(np.float32)
    yy, xx = np.mgrid[0:h, 0:w]
    m = 1.0 - ((xx - w / 2) / (w / 2)) ** 2 - ((yy - h / 2) / (h / 2)) ** 2
    m = np.clip(m, 0, 1) ** 0.7 * a
    reg *= (1 - m[..., None])
    p.img.paste(Image.fromarray(reg.astype(np.uint8)), (X, Y))


def pillar(p, X, Y):
    """노란 원기둥: 원통 음영 5단, 아래 검정 띠, 바닥에 비친 노란 빛 (사진 092701)"""
    shadow(p, X - 2, Y + 18, 36, 16, 0.4)
    p.glow(X + 16, Y + 40, 12, 14, C["pillar"], 0.35)
    top, bot = Y - 52, Y + 24
    cols = [C["pillarm"], C["pillarl"], C["pillarl"], C["pillar"], C["pillar"], C["pillar"], C["pillarm"], C["pillard"], C["pillardd"]]
    xs = [2, 4, 7, 10, 14, 18, 22, 26, 28, 30]
    for i, col in enumerate(cols):
        p.rect(X + xs[i], top, xs[i + 1] - xs[i], bot - top, col)
    p.ell(X + 2, top - 5, X + 29, top + 5, C["pillarl"])
    p.ell(X + 5, top - 3, X + 26, top + 3, light(C["pillarl"], 0.3))
    # 검정 띠
    p.rect(X + 2, Y + 14, 28, 10, hx("26262b"))
    p.ell(X + 2, Y + 18, X + 29, Y + 29, hx("26262b"))
    p.rect(X + 4, Y + 14, 6, 10, hx("3c3c44"))
    p.rect(X + 2, Y + 14, 28, 1, hx("4c4c54"))


def plant(p, X, Y):
    shadow(p, X + 2, Y + 20, 28, 12)
    p.rect(X + 9, Y + 10, 14, 16, C["pot"])
    p.rect(X + 9, Y + 10, 14, 2, hx("dcdcd6"))
    p.rect(X + 19, Y + 12, 4, 14, hx("d5d5cf"))
    for i, (dx, dy, r) in enumerate(((16, -2, 11), (7, 3, 7), (25, 3, 7), (11, -11, 8), (21, -11, 8), (16, -19, 7), (5, -6, 5), (27, -6, 5))):
        p.ell(X + dx - r, Y + dy - r, X + dx + r, Y + dy + r, C["plantd"])
        p.ell(X + dx - r + 1, Y + dy - r, X + dx + r - 2, Y + dy + r - 3, C["plant"])
        p.ell(X + dx - r + 3, Y + dy - r + 1, X + dx + r - 5, Y + dy + r - 7, C["plantl"])


def bins(p, X, Y, k):
    lids = [C["yellow"], C["blue"], hx("4caf50"), C["yellow"]]
    lid = lids[k % 4]
    shadow(p, X + 1, Y + 22, 30, 9)
    p.rect(X + 5, Y - 2, 22, 28, hx("55575d"))
    p.rect(X + 5, Y - 2, 5, 28, hx("6c6e74"))
    p.rect(X + 24, Y - 2, 3, 28, hx("45474c"))
    p.rect(X + 4, Y - 7, 24, 8, lid)
    p.rect(X + 4, Y - 7, 24, 2, light(lid, 0.3))
    p.rect(X + 4, Y + 1, 24, 2, dark(lid, 0.3))
    p.rect(X + 11, Y + 6, 10, 7, C["white"])
    p.line(X + 13, Y + 9, X + 19, Y + 9, hx("6a6a6a"))


def vending(p, X, Y):
    shadow(p, X - 1, Y + 20, 34, 12)
    p.rect(X + 2, Y - 34, 28, 60, hx("c22f39"))
    p.rect(X + 2, Y - 34, 28, 3, hx("e85a64"))
    p.rect(X + 27, Y - 34, 3, 60, hx("9a2029"))
    p.rect(X + 5, Y - 29, 20, 30, hx("e2ecf2"))
    for r in range(3):
        for k in range(4):
            p.rect(X + 6 + k * 5, Y - 27 + r * 9, 3, 7, [hx("3a8ad8"), hx("f2c434"), hx("e85a4a"), hx("5ab05a")][(r + k) % 4])
    p.rect(X + 6, Y + 6, 18, 7, hx("1e1f24"))
    p.rect(X + 25, Y - 10, 3, 6, hx("2a2a2a"))


def sofa(p, X, Y):
    shadow(p, X - 1, Y + 18, 34, 12)
    body = C["sofa_k"]
    p.rect(X, Y - 8, 32, 14, light(body, 0.08))
    p.rect(X, Y - 8, 32, 2, light(body, 0.2))
    p.rect(X, Y + 6, 32, 18, body)
    p.rect(X + 1, Y + 6, 30, 3, light(body, 0.18))
    p.rect(X, Y + 2, 4, 22, light(body, 0.12))
    p.rect(X + 28, Y + 2, 4, 22, light(body, 0.12))


def table_low(p, X, Y):
    shadow(p, X - 1, Y + 16, 34, 12)
    p.rect(X, Y + 2, 32, 16, hx("5a2a20"))
    p.rect(X, Y + 2, 32, 3, hx("7c4030"))
    p.line(X + 4, Y + 8, X + 14, Y + 6, hx("8a4a38"))
    p.rect(X + 2, Y + 18, 28, 7, hx("3a1c14"))


def piano(p, X, Y):
    """덮개(검은 벨벳, 주름 자락)를 씌운 그랜드 피아노 - 2x2칸 (사진 092714)"""
    shadow(p, X - 10, Y + 34, 84, 26, 0.4)
    pts = [(X - 4, Y), (X + 52, Y - 2), (X + 64, Y + 12), (X + 60, Y + 34), (X + 36, Y + 44), (X + 4, Y + 40), (X - 6, Y + 26)]
    p.poly([(a, b + 4) for a, b in pts], hx("0d0d11"))
    p.poly(pts, hx("17171d"))
    p.poly([(X, Y + 2), (X + 50, Y + 1), (X + 58, Y + 12), (X + 30, Y + 16), (X + 2, Y + 14)], hx("26262e"))
    p.line(X + 6, Y + 6, X + 44, Y + 4, hx("3a3a46"))
    for k in range(9):
        p.line(X - 4 + k * 7, Y + 38 - (k % 3), X - 2 + k * 7, Y + 46, hx("2c2c36"))
    for (lx, ly) in ((X + 2, Y + 44), (X + 54, Y + 36), (X + 30, Y + 48)):
        p.rect(lx, ly, 3, 8, hx("0a0a0d"))
    p.rect(X + 16, Y + 50, 18, 6, hx("1a1a20"))          # 의자


def pool_table(p, X, Y):
    shadow(p, X - 3, Y + 20, 38, 10)
    p.rect(X - 2, Y, 36, 22, hx("2a1d16"))
    p.rect(X - 2, Y, 36, 2, hx("4a3428"))
    p.rect(X + 1, Y + 3, 30, 16, hx("2c9548"))
    p.rect(X + 1, Y + 3, 30, 2, hx("3db35c"))
    for (bx, by, col) in ((8, 8, C["white"]), (20, 12, C["sign_red"]), (24, 7, C["yellow"])):
        p.ell(X + bx, Y + by, X + bx + 3, Y + by + 3, col)
    p.line(X + 3, Y + 16, X + 26, Y + 6, hx("c9a26a"))
    p.rect(X, Y + 22, 3, 7, hx("1a1a1a"))
    p.rect(X + 29, Y + 22, 3, 7, hx("1a1a1a"))


def bear(p, X, Y):
    """분홍 스웨터 곰 인형 + 빨간 지붕 우체통 (S110 Wee Class 앞, 사진 092459)"""
    shadow(p, X, Y + 20, 34, 10)
    b, bd, bl = hx("d9a85a"), hx("b8863e"), hx("ecc27c")
    p.ell(X + 5, Y - 18, X + 23, Y + 0, b)
    p.ell(X + 3, Y - 22, X + 10, Y - 15, b)
    p.ell(X + 18, Y - 22, X + 25, Y - 15, b)
    p.ell(X + 8, Y - 15, X + 14, Y - 9, bl)
    p.ell(X + 10, Y - 10, X + 18, Y - 3, hx("efd3a0"))
    p.px(X + 11, Y - 12, hx("1a1a1a"))
    p.px(X + 17, Y - 12, hx("1a1a1a"))
    p.px(X + 14, Y - 8, hx("3a2a1a"))
    p.rect(X + 5, Y - 1, 18, 19, hx("f2c9c4"))
    p.rect(X + 5, Y - 1, 18, 2, hx("e4b0aa"))
    for k in range(3):
        p.line(X + 8 + k * 5, Y + 2, X + 8 + k * 5, Y + 16, hx("e4b0aa"))
    p.ell(X + 2, Y + 14, X + 11, Y + 24, b)
    p.ell(X + 16, Y + 14, X + 25, Y + 24, bd)
    p.rect(X + 24, Y + 2, 9, 16, C["white"])
    p.poly([(X + 22, Y + 3), (X + 28, Y - 4), (X + 34, Y + 3)], C["sign_red"])
    p.rect(X + 26, Y + 7, 5, 1, C["sign_red"])


def pingpong(p, X, Y):
    """남색 탁구대 'CHAMPION' (2층 사진 092914)"""
    shadow(p, X - 14, Y + 22, 60, 14)
    p.rect(X - 14, Y - 2, 60, 24, hx("1e2a50"))
    p.rect(X - 13, Y - 1, 58, 22, hx("2a3a6c"))
    p.rect(X - 13, Y - 1, 58, 1, hx("4a5a8c"))
    p.line(X - 13, Y + 10, X + 44, Y + 10, C["white"])
    p.rect(X - 13, Y - 1, 58, 1, C["white"])
    p.rect(X - 13, Y + 20, 58, 1, C["white"])
    p.rect(X + 15, Y - 4, 2, 28, hx("e8e8e8"))
    p.rect(X + 14, Y - 5, 4, 2, C["sign_red"])
    p.rect(X - 12, Y + 22, 3, 7, hx("151515"))
    p.rect(X + 41, Y + 22, 3, 7, hx("151515"))


# ================================================================== 중앙 홀의 뚫린 곳과 난간
def void_tile(p, hl, x, y):
    """아래층 중앙 홀이 내려다보인다 (층이 높을수록 깊고 어둡게)"""
    X, Y = x * T, y * T
    depth = min(0.8, 0.42 + 0.1 * (hl.n - 2))
    base = dark(C["hall1"], depth)
    for sy in range(0, T, 12):
        for sx in range(0, T, 12):
            v = (hsh(X + sx, Y + sy) % 5) - 2
            p.rect(X + sx, Y + sy, 12, 12, tuple(min(255, max(0, b + v)) for b in base))
            p.line(X + sx, Y + sy + 11, X + sx + 11, Y + sy + 11, dark(base, 0.12))
    # 아래층 세모 띠 (작게 보인다)
    (ax, ay), _, (cx, cy) = hl.TRI
    if y == cy - 1:
        p.rect(X, Y + 18, T, 7, dark(C["red"], depth))
    if x == ax + 1:
        p.rect(X + 4, Y, 7, T, dark(C["red"], depth))


def railing(p, hl, x, y):
    """유리 난간: 난간 턱 + 유리 + 스테인리스 기둥 + 원목 손잡이 (사진 093010)"""
    X, Y = x * T, y * T
    below_void = hl.c(x, y + 1) == "a"
    if below_void:
        void_tile(p, hl, x, y)
    else:
        floor_tile(p, hl, x, y)
    p.rect(X, Y + 20, T, 7, hx("ebe9e3"))
    p.rect(X, Y + 20, T, 1, C["white"])
    p.rect(X, Y + 27, T, 3, hx("a9a69e"))
    gl = Image.new("RGBA", (T, 24), (196, 226, 236, 80))
    p.img.paste(gl, (X, Y - 4 + p.oy), gl)
    p.line(X + 4, Y + 16, X + 13, Y - 1, hx("eef7fa"))
    p.line(X + 8, Y + 16, X + 15, Y + 3, hx("dcecf2"))
    for k in (3, 19):
        p.rect(X + k, Y - 6, 3, 27, C["steel"])
        p.rect(X + k, Y - 6, 1, 27, C["steell"])
        p.px(X + k + 1, Y + 2, C["steeld"])
        p.px(X + k + 1, Y + 12, C["steeld"])
    p.rect(X, Y - 9, T, 4, C["oak"])
    p.rect(X, Y - 9, T, 1, C["oakl"])
    p.rect(X, Y - 5, T, 1, C["oakd"])


# ================================================================== 그늘·반사
def post_floor(p, hl):
    arr = np.asarray(p.img).astype(np.float32)
    for y in range(hl.H):
        for x in range(hl.W):
            c = hl.c(x, y)
            if not (c in FLOOR_CHARS):
                continue
            X, Y = x * T, y * T + p.oy
            if not hl.is_floor(x, y - 1):
                ramp = (1 - np.arange(16) / 16.0)[:, None, None]
                arr[Y:Y + 16, X:X + T] *= 1.0 - 0.30 * ramp
            if not hl.is_floor(x - 1, y):
                ramp = (1 - np.arange(8) / 8.0)[None, :, None]
                arr[Y:Y + T, X:X + 8] *= 1.0 - 0.25 * ramp
            if not hl.is_floor(x + 1, y):
                ramp = (np.arange(8) / 8.0)[None, :, None]
                arr[Y:Y + T, X + T - 8:X + T] *= 1.0 - 0.25 * ramp
            if not hl.is_floor(x, y + 1):
                ramp = (np.arange(6) / 6.0)[:, None, None]
                arr[Y + T - 6:Y + T, X:X + T] *= 1.0 - 0.2 * ramp
    p.img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    p.d = ImageDraw.Draw(p.img)


def reflections(p, hl, faces):
    """광택 바닥에 위쪽 벽이 거꾸로 비친다"""
    arr = np.asarray(p.img).astype(np.float32)
    for x, y in faces:
        X, Yb = x * T, (y + 1) * T + p.oy
        if not hl.c(x, y + 1) in FLOOR_CHARS:
            continue
        src = arr[Yb - 30:Yb - 4, X:X + T][::-1].copy()
        n = src.shape[0]
        for k in range(n):
            a = (0.20 if hl.n == 1 else 0.15) * (1 - k / n) ** 1.5
            arr[Yb + 1 + k, X:X + T] = arr[Yb + 1 + k, X:X + T] * (1 - a) + src[k] * a
    p.img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    p.d = ImageDraw.Draw(p.img)



# ================================================================== 사선 복도 (A동, 수학 구역)를 매끈한 사선 벽으로
class StripHall:
    """사선 복도의 위쪽 벽을 '곧은 벽 한 줄'로 펴서 그리기 위한 가짜 맵 (2행 = 벽, 3행 = 바닥)"""
    def __init__(self, hl, chars):
        self.hl = hl
        self.n = hl.n
        self.doors = hl.doors
        self.chars = chars           # {x: 벽 글자}

    def c(self, x, y):
        if y == 2:
            return self.chars.get(x, "#")
        if y == 3:
            return "."
        return "#"

    def is_floor(self, x, y):
        return y == 3

    def is_door(self, x, y):
        return self.c(x, y) in self.doors

    def zone(self, x, y):
        return "A"


def wing_geom(hl, kind):
    """(x 범위(칸), 가운데 줄 함수(픽셀 x -> 픽셀 y), 칸 x -> 가운데 행)"""
    if kind == "A":
        cy = lambda xp: (4 + (xp / T - 0.5 - 33) * 26 / 42 + 0.5) * T
        row = lambda x: 4 + round((x - 33) * 26 / 42)
        return (31, 73), cy, row
    cy = lambda xp: (47 + (26 - (xp / T - 0.5)) * 15 / 20 + 0.5) * T
    row = lambda x: 47 + round((26 - x) * 15 / 20)
    return (4, 24), cy, row


def smooth_wing(p, hl, kind):
    (x0, x1), cy, row = wing_geom(hl, kind)
    X0, X1 = x0 * T, x1 * T
    arr = np.asarray(p.img).copy()
    # 1) 지울 곳 (사선 띠와 벽 면 둘레)
    for xp in range(X0, X1):
        c = cy(xp)
        arr[max(0, int(c - 48 - 72 - 44)):max(0, int(c + 48 + 44)), xp] = C["void"]
    p.img = Image.fromarray(arr)
    p.d = ImageDraw.Draw(p.img)
    # 2) 바닥: 칸마다 그린 바닥을 사선 띠 모양으로 오려 붙인다
    tmp = Painter(hl.W, hl.H)
    for x in range(x0 - 1, x1 + 1):
        r = row(x)
        for y in range(r - 3, r + 4):
            if 0 <= y < hl.H:
                floor_tile(tmp, hl, x, y)
    ta = np.asarray(tmp.img)
    arr = np.asarray(p.img).copy()
    for xp in range(X0, X1):
        c = cy(xp)
        a, b = int(round(c - 48)), int(round(c + 48))
        arr[a:b, xp] = ta[a:b, xp]
    # 그늘: 위쪽 벽 아래, 아래쪽 모서리 위
    arr = arr.astype(np.float32)
    for xp in range(X0, X1):
        c = cy(xp)
        a, b = int(round(c - 48)), int(round(c + 48))
        for k in range(16):
            arr[a + k, xp] *= 1.0 - 0.30 * (1 - k / 16.0)
        for k in range(6):
            arr[b - 1 - k, xp] *= 1.0 - 0.2 * (1 - k / 6.0)
    p.img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    p.d = ImageDraw.Draw(p.img)
    # 짙은 타일 줄무늬 (2층 이상): 복도를 가로지르는 방향으로
    if hl.n >= 2:
        sl = (cy(X0 + 100) - cy(X0)) / 100.0
        L = math.hypot(1, sl)
        dx_, dy_ = 1 / L, sl / L              # 복도 방향
        nx_, ny_ = -dy_, dx_                  # 가로지르는 방향
        for xp in range(X0 + 60, X1 - 30, 150):
            c0 = (xp, cy(xp))
            for j in range(-2, 2):
                q0 = (c0[0] + nx_ * j * 16, c0[1] + ny_ * j * 16)
                pts = [(q0[0] + a * dx_ * 16 + b * nx_ * 16, q0[1] + a * dy_ * 16 + b * ny_ * 16) for a, b in ((0, 0), (1, 0), (1, 1), (0, 1))]
                p.poly(pts, C["stripe"] if j % 2 else dark(C["stripe"], 0.08))
                p.line(pts[0][0], pts[0][1], pts[1][0], pts[1][1], C["stripel"])
    # 천장 등 반사
    for xg in range(x0 + 2, x1 - 1, 5):
        p.glow(xg * T + 16, cy(xg * T + 16), 34, 8, (255, 255, 255), 0.26)
    # 3) 위쪽 벽: 곧은 벽 한 줄을 그린 뒤 칸 열마다 사선으로 밀어 붙인다
    chars = {}
    for x in range(x0 - 1, x1 + 1):
        chars[x] = hl.c(x, row(x) - 2)
        if chars[x] in "#." or chars[x] in FLOOR_CHARS:
            chars[x] = "="
    sh = StripHall(hl, chars)
    strip = Painter(hl.W, 5)
    for x in range(x0 - 1, x1 + 1):
        ch = chars[x]
        face_base(strip, sh, x, 2, "mint" if (hl.n == 1 and kind == "A") else "classroom")
        if ch in hl.doors:
            door_face(strip, sh, x, 2, ch)
        else:
            face_decor(strip, sh, x, 2, ch, "classroom")
    sa = np.asarray(strip.img)
    arr = np.asarray(p.img).copy()
    top0 = 2 * T - WALL_UP
    for xp in range(X0, X1):
        n_ = int(round(cy(xp) - 48))
        cut = max(0, 72 - n_)
        arr[n_ - 72 + cut:n_, xp] = sa[top0 + cut:top0 + 72, xp]
    # 바닥에 비친 벽
    arr = arr.astype(np.float32)
    for xp in range(X0, X1):
        n_ = int(round(cy(xp) - 48))
        src = arr[n_ - 28:n_ - 4, xp][::-1].copy()
        for k in range(src.shape[0]):
            a = 0.15 * (1 - k / src.shape[0]) ** 1.5
            arr[n_ + 1 + k, xp] = arr[n_ + 1 + k, xp] * (1 - a) + src[k] * a
    p.img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    p.d = ImageDraw.Draw(p.img)
    # 4) 아래쪽 모서리 (벽 윗면) + 아래쪽 문
    for xp in range(X0, X1):
        b = int(round(cy(xp) + 48))
        x = xp // T
        ch = hl.c(x, row(x) + 2)
        if ch in hl.doors:
            k = xp - x * T
            left = hl.c(x - 1, row(x - 1) + 2) != ch
            right = hl.c(x + 1, row(x + 1) + 2) != ch
            edge_l, edge_r = (left and k < 4), (right and k >= T - 4)
            if edge_l or edge_r:
                p.rect(xp, b, 1, 15, C["oakdd"])
            elif ch == "4":
                p.rect(xp, b, 1, 13, hx("c9dde4"))
                p.rect(xp, b + 11, 1, 3, C["steeld"])
            else:
                p.rect(xp, b, 1, 10, C["oakl"])
                p.rect(xp, b + 10, 1, 3, C["oak"])
                p.px(xp, b, light(C["oakl"], 0.3))
            p.rect(xp, b + 15, 1, 28, C["ceil"])
        else:
            p.rect(xp, b, 1, 8, C["edge"])
            p.rect(xp, b + 8, 1, 2, C["edged"])
            p.rect(xp, b + 10, 1, 3, dark(C["ceil"], 0.5))
            p.rect(xp, b + 13, 1, 30, C["ceil"])
    # 5) 끝 벽 (서쪽 끝 / 동쪽 끝의 옆 모서리)
    xp = X0
    c = cy(xp)
    if kind == "A":
        p.rect(X0, int(c - 48 - 72), 7, 72 + 96, C["edge"])
        p.rect(X0 + 7, int(c - 48), 1, 96, C["edged"])
    else:
        p.rect(X0, int(c - 48 - 72), 7, 72 + 96, C["edge"])
        p.rect(X0 + 7, int(c - 48), 1, 96, C["edged"])


# ================================================================== 중앙 홀 아트리움 (매끈한 세모 + 아래층들이 보이는 깊이)
def atrium(p, hl):
    (ax, ay), (bx, by), (cx, cy) = hl.TRI
    # 바깥 테두리(난간 'n' 칸의 바깥쪽)와 안쪽(난간 선)
    A = (ax * T + 14, ay * T + 18)
    B = (bx * T + 14, (by + 1) * T - 10)
    Cc = ((cx + 1) * T - 4, (cy + 1) * T - 10)
    # 1) 난간 칸은 먼저 바닥으로 칠한다
    for y in range(hl.H):
        for x in range(hl.W):
            if hl.c(x, y) == "n":
                floor_tile(p, hl, x, y)
    # 2) 뚫린 곳: 1층 바닥 + 아래층 발코니들 (뒤쪽 두 변에 층마다 흰 띠와 유리 난간)
    W, H = p.W, p.H
    layer = Image.new("RGB", (W, H), dark(C["hall1"], 0.55))
    ld = ImageDraw.Draw(layer)
    depth = hl.n - 1
    # 1층 바닥 (작게, 어둡게) + 세모 띠
    base = dark(C["hall1"], min(0.75, 0.35 + 0.1 * depth))
    ld.polygon([A, B, Cc], fill=base)
    for k in range(0, W, 20):
        ld.line([(k, 0), (k, H)], fill=dark(base, 0.08))
    for k in range(0, H, 20):
        ld.line([(0, k), (W, k)], fill=dark(base, 0.08))
    drop = 34                                                   # 한 층 내려갈 때 보이는 높이
    inner = [(A[0] + 10, A[1] + depth * drop + 6), (B[0] + 10, B[1] - 6), (Cc[0] - 40, Cc[1] - 6)]
    ld.line(inner + [inner[0]], fill=dark(C["red"], 0.45), width=6)
    # 아래층 발코니 띠 (위층일수록 많이 보인다)
    for k in range(depth):
        off = (k + 1) * drop
        sh = 0.18 + 0.12 * k
        # 서쪽(왼쪽) 변: 아래층 벽이 오른쪽으로 비친다 / 빗변: 아래층 발코니 면
        slab = dark(hx("efede6"), sh)
        glass = dark(hx("9cc3cf"), sh + 0.1)
        ld.polygon([(A[0], A[1] + off - drop), (Cc[0], Cc[1] + off - drop), (Cc[0], Cc[1] + off - drop + 10), (A[0], A[1] + off - drop + 10)], fill=slab)
        ld.polygon([(A[0], A[1] + off - drop + 10), (Cc[0], Cc[1] + off - drop + 10), (Cc[0], Cc[1] + off - drop + 22), (A[0], A[1] + off - drop + 22)], fill=glass)
        ld.line([(A[0], A[1] + off - drop + 10), (Cc[0], Cc[1] + off - drop + 10)], fill=dark(C["oak"], sh), width=2)
        ld.rectangle([A[0], A[1] + off - drop, A[0] + 12, B[1]], fill=dark(hx("e8e6df"), sh + 0.05))
        # 아래층 노란 기둥 윗부분
        for (px_, py_) in ((A[0] + 4, A[1] + off), (B[0] + 4, B[1] - 40), (Cc[0] - 30, Cc[1] - 40)):
            ld.rectangle([px_, py_ - 20, px_ + 14, py_ + 10], fill=dark(C["pillar"], sh + 0.15))
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).polygon([A, B, Cc], fill=255)
    p.img.paste(layer, (0, 0), mask)
    p.d = ImageDraw.Draw(p.img)
    # 3) 유리 난간 (뒤쪽 두 변 먼저, 앞쪽(아래) 변 나중)
    def rail(P, Q, h=24, front=False):
        poly = [P, Q, (Q[0], Q[1] - h), (P[0], P[1] - h)]
        gl = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(gl).polygon(poly, fill=(196, 226, 236, 90 if front else 70))
        p.img.paste(gl, (0, 0), gl)
        p.d = ImageDraw.Draw(p.img)
        p.line(P[0], P[1] + 3, Q[0], Q[1] + 3, hx("a9a69e"), 3)
        p.line(P[0], P[1], Q[0], Q[1], hx("ebe9e3"), 4)
        L = math.hypot(Q[0] - P[0], Q[1] - P[1])
        n = max(1, int(L // 30))
        for i in range(n + 1):
            t = i / n
            x = P[0] + (Q[0] - P[0]) * t
            y = P[1] + (Q[1] - P[1]) * t
            p.line(x, y, x, y - h - 2, C["steel"], 3)
            p.line(x - 1, y, x - 1, y - h - 2, C["steell"], 1)
        # 반사 줄
        for i in range(n):
            t = (i + 0.4) / n
            x = P[0] + (Q[0] - P[0]) * t
            y = P[1] + (Q[1] - P[1]) * t
            p.line(x, y - 4, x + 8, y - h + 4, hx("eef7fa"), 1)
        p.line(P[0], P[1] - h - 2, Q[0], Q[1] - h - 2, C["oak"], 4)
        p.line(P[0], P[1] - h - 3, Q[0], Q[1] - h - 3, C["oakl"], 1)
    rail(A, Cc)
    rail(A, B)
    rail(B, Cc, front=True)

# ================================================================== 한 층
def render(hid, info, plan):
    hl = Hall(hid, info, plan)
    p = Painter(hl.W, hl.H)
    H, W = hl.H, hl.W
    for y in range(H):
        for x in range(W):
            c = hl.c(x, y)
            if c in FLOOR_CHARS:
                floor_tile(p, hl, x, y)
            elif c == "a":
                void_tile(p, hl, x, y)
    if hl.n == 1:
        floor_bands_1f(p, hl)
    else:
        atrium(p, hl)
    floor_light(p, hl)
    post_floor(p, hl)
    # 아래쪽 벽 윗면 / 문
    for y in range(H):
        for x in range(W):
            if hl.is_floor(x, y):
                continue
            if hl.is_floor(x, y - 1) and not hl.is_floor(x, y + 1):
                if hl.is_door(x, y):
                    door_bottom(p, hl, x, y, hl.c(x, y))
                else:
                    top_edge(p, hl, x, y, hl.c(x, y))
    # 위쪽 벽 면 (위 줄부터: 아래 줄 벽이 위 줄 벽을 덮는다)
    faces = [(x, y) for y in range(H) for x in range(W) if not hl.is_floor(x, y) and hl.is_floor(x, y + 1)]
    for x, y in faces:
        c = hl.c(x, y)
        st = wall_style(hl, x, y)
        face_base(p, hl, x, y, st)
        if hl.is_door(x, y):
            door_face(p, hl, x, y, c)
        else:
            face_decor(p, hl, x, y, c, st)
        # 고정 장식
        if (x, y) in ((44, 45), (66, 45), (100, 31)) and c == "=":
            fire_box(p, x * T, y)
        if y == 45 and x in (50, 51) and c == "=":
            sink_wall(p, x, y)
        if (x, y) in ((70, 45), (27, 45)) and c == "=":
            exit_sign(p, x * T + 8, F(y, 6))
    if hl.c(83, 31) in "=wb" and hl.c(84, 31) in "=wb":
        elevator(p, 83, 31)
    if hl.n == 1 and all(hl.c(x, 31) == "=" for x in range(99, 103)):
        sasa_wall(p, 99, 31)
    # 옆 벽 (벽이 옆으로 끝나는 곳의 두께)
    for y in range(H):
        for x in range(W):
            if hl.is_floor(x, y) or hl.is_floor(x, y + 1):
                continue
            X, Y = x * T, y * T
            up = 0 if hl.is_floor(x, y - 1) else WALL_UP
            if hl.is_floor(x + 1, y):
                p.rect(X + T - 7, Y - up, 7, T + up, C["edge"])
                p.rect(X + T - 8, Y - up, 1, T + up, C["edged"])
            if hl.is_floor(x - 1, y):
                p.rect(X, Y - up, 7, T + up, C["edge"])
                p.rect(X + 7, Y - up, 1, T + up, C["edged"])
    reflections(p, hl, faces)
    smooth_wing(p, hl, "A")
    smooth_wing(p, hl, "M")
    # 바닥 위 물건 (위 줄부터)
    kbin = 0
    seen_piano = False
    for y in range(H):
        for x in range(W):
            c = hl.c(x, y)
            X, Y = x * T, y * T
            if c == "J":
                pillar(p, X, Y)
            elif c == "p":
                plant(p, X, Y)
            elif c == "l":
                bins(p, X, Y, kbin)
                kbin += 1
            elif c == "v":
                vending(p, X, Y)
            elif c == "S":
                sofa(p, X, Y)
            elif c == "o":
                table_low(p, X, Y)
            elif c == "P" and not seen_piano:
                piano(p, X, Y)
                seen_piano = True
            elif c == "g":
                pool_table(p, X, Y)
            elif c == "f":
                bear(p, X, Y)
            elif c == "s":
                pingpong(p, X, Y)
    return p.img



# ================================================================== 교실 등 실내 방
# 벽에 붙은 것 (벽 면으로 그린다)
ROOM_WALL = set("#=wbBjNFECu")
# 벽 줄에 놓여 있어도 '벽 앞에 선 물건'으로 그리는 것
ROOM_STAND = set("kZAYLQ")
ROOM_STYLE = {"a2_gym": "gym", "dorm_room": "dorm", "dorm_study": "dorm", "dorm_laundry": "dorm", "dorm_hall": "dorm",
              "s3_library": "wood", "a1_principal": "wood", "parcel_room": "dorm", "a4_karaoke": "karaoke",
              "s5_observatory": "dark", "s5_multimedia": "room", "a3_robot": "room", "a4_mac": "room"}
CHAIRS = [hx("2f5fb0"), hx("9cc23a"), hx("e6e6e2"), hx("55585e"), hx("2f5fb0"), hx("9cc23a")]


class RoomMap:
    def __init__(self, rid, info):
        self.rid = rid
        self.m = info["map"]
        self.H, self.W = len(self.m), len(self.m[0])
        self.doors = info["doors"]
        self.floor = info["floor"]
        self.n = 3
        self.style = ROOM_STYLE.get(rid, "room")

    def c(self, x, y):
        if 0 <= x < self.W and 0 <= y < self.H:
            return self.m[y][x]
        return "#"

    def wallish(self, x, y):
        c = self.c(x, y)
        if c in self.doors:
            return True
        if c in ROOM_WALL:
            return True
        # 맨 윗줄(바로 위가 바깥)에 놓인 물건은 벽 면 + 벽 앞 물건
        return c in ROOM_STAND and self.c(x, y - 1) == "#"

    def is_floor(self, x, y):
        return not self.wallish(x, y)

    def is_door(self, x, y):
        return self.c(x, y) in self.doors

    def zone(self, x, y):
        return "R"


def room_floor(p, rm, x, y):
    X, Y = x * T, y * T
    st = rm.floor
    c = rm.c(x, y)
    if c == "x":
        # 교장실 붉은 카펫 (금색 테두리)
        p.rect(X, Y, T, T, hx("8a2230"))
        h = hsh(x, y)
        for i in range(10):
            h = hsh(h, i)
            p.px(X + h % 31, Y + (h >> 8) % 31, hx("761c28"))
        if rm.c(x, y - 1) != "x":
            p.rect(X, Y + 2, T, 2, hx("d6aa4a"))
        if rm.c(x, y + 1) != "x":
            p.rect(X, Y + T - 4, T, 2, hx("d6aa4a"))
        return
    if st == "wood":
        # 마루: 엇갈린 널판 (밝은 원목, 사진 093216)
        for k in range(4):
            yy = Y + k * 8
            off = (hsh(x, y, k) % 4) * 8
            base = mix(hx("c58d55"), hx("b27a46"), ((x + k + y) % 3) / 3.0)
            p.rect(X, yy, T, 8, base)
            p.line(X, yy + 7, X + T - 1, yy + 7, dark(base, 0.22))
            p.line(X, yy, X + T - 1, yy, light(base, 0.12))
            sx = X + off
            p.line(sx, yy, sx, yy + 7, dark(base, 0.25))
            g = hsh(x, y, k, 3)
            p.line(X + g % 24, yy + 3, X + g % 24 + 6, yy + 3, light(base, 0.15))
            p.line(X + (g >> 5) % 26, yy + 5, X + (g >> 5) % 26 + 3, yy + 5, dark(base, 0.1))
    elif st == "dark":
        for sy in range(2):
            for sx in range(2):
                xx, yy = X + sx * 16, Y + sy * 16
                base = hx("3b4150") if (x * 2 + sx + y * 2 + sy) % 2 else hx("353a48")
                p.rect(xx, yy, 16, 16, base)
                p.line(xx, yy + 15, xx + 15, yy + 15, dark(base, 0.3))
                p.line(xx + 15, yy, xx + 15, yy + 15, dark(base, 0.3))
                p.line(xx, yy, xx + 14, yy, light(base, 0.12))
    else:
        # 흰 타일 (교실·급식실·세탁실, 사진 092808)
        floor_tile(p, rm, x, y)
    if c == "_":
        p.blend(X, Y, T, T, hx("0a0d16"), 0.45)


def room_face(p, rm, x, y):
    X = x * T
    st = rm.style
    if st == "gym":
        p.rect(X, F(y, 0), T, 72, hx("dcc8a0"))
        for k in range(6, 40, 5):
            p.line(X, F(y, k), X + T - 1, F(y, k), hx("cfb98f"))
        p.rect(X, F(y, 40), T, 28, hx("1f7a5a"))
        for k in range(0, T, 4):
            p.line(X + k, F(y, 41), X + k, F(y, 67), hx("17654a"))
        p.rect(X, F(y, 40), T, 2, hx("2e9a72"))
        p.rect(X, F(y, 68), T, 4, hx("6e4a2a"))
    elif st == "dorm":
        p.rect(X, F(y, 0), T, 72, hx("efe2cf"))
        p.rect(X, F(y, 50), T, 18, hx("e4cfb2"))
        p.rect(X, F(y, 50), T, 1, hx("d2b993"))
        p.rect(X, F(y, 68), T, 4, C["oak"])
    elif st == "wood":
        p.rect(X, F(y, 0), T, 72, hx("e9e1cf"))
        p.rect(X, F(y, 40), T, 28, C["oak"])
        for k in (4, 14, 24):
            p.rect(X + k, F(y, 44), 6, 20, C["oakl"])
            p.rect(X + k, F(y, 44), 6, 1, light(C["oakl"], 0.3))
        p.rect(X, F(y, 40), T, 2, C["oakd"])
        p.rect(X, F(y, 68), T, 4, C["oakdd"])
    elif st == "karaoke":
        p.rect(X, F(y, 0), T, 72, hx("2c1f48"))
        h = hsh(x, y)
        for i in range(4):
            h = hsh(h, i)
            p.px(X + h % 31, F(y, 6) + (h >> 8) % 50, hx("f2c434") if i % 2 else hx("ff6ad5"))
        p.rect(X, F(y, 68), T, 4, hx("15101f"))
    elif st == "dark":
        p.rect(X, F(y, 0), T, 72, hx("2f3644"))
        p.rect(X, F(y, 50), T, 18, hx("262c38"))
        p.rect(X, F(y, 68), T, 4, hx("15181f"))
    else:
        # 교실: 흰 윗벽 + 연두 허리벽 + 검정 걸레받이 (사진 092808)
        p.rect(X, F(y, 0), T, 72, hx("eeefe9"))
        p.rect(X, F(y, 4), T, 4, hx("dcddd6"))
        p.rect(X, F(y, 44), T, 24, hx("8cbf4a"))
        p.rect(X, F(y, 44), T, 2, hx("a6d460"))
        p.rect(X, F(y, 66), T, 2, hx("6f9c36"))
        p.rect(X, F(y, 68), T, 4, C["base"])
    p.rect(X, F(y, 0), T, 3, C["ceil2"])
    p.rect(X, F(y, 3), T, 1, C["edged"])


def room_face_decor(p, rm, x, y, c):
    X = x * T
    run_l = rm.c(x - 1, y) != c
    run_r = rm.c(x + 1, y) != c
    if c == "w":
        if rm.style == "gym":
            # 빨간 커튼 친 창 (사진 092927)
            p.rect(X, F(y, 6), T, 34, hx("7a1a28"))
            for k in range(0, T, 5):
                p.rect(X + k, F(y, 6), 2, 34, hx("9a2434"))
            p.rect(X, F(y, 4), T, 3, hx("4a1018"))
            return
        # 바깥 창 + 블라인드 반쯤 내림 (사진 092808)
        p.rect(X + 1, F(y, 10), 30, 40, hx("6b6e74"))
        p.rect(X + 3, F(y, 12), 26, 36, hx("1c2a46"))
        p.rect(X + 3, F(y, 34), 26, 14, hx("16223a"))
        drop = 10 + hsh(x, y) % 12
        p.rect(X + 3, F(y, 12), 26, drop, hx("e2d2a8"))
        for k in range(0, drop, 2):
            p.line(X + 3, F(y, 12) + k, X + 28, F(y, 12) + k, hx("cdb98c"))
        p.rect(X + 15, F(y, 12), 2, 36, hx("6b6e74"))
        p.rect(X + 1, F(y, 50), 30, 3, hx("d8d8d2"))
    elif c == "B":
        # 초록 칠판 + 분필 받침 (판서는 게임이 쓴다)
        p.rect(X, F(y, 12), T, 36, hx("8a5a2a") if (run_l or run_r) else hx("2f5a3e"))
        p.rect(X + (3 if run_l else 0), F(y, 15), T - (3 if run_l else 0) - (3 if run_r else 0), 30, hx("2f5a3e"))
        h = hsh(x, y)
        p.line(X + h % 20, F(y, 24), X + h % 20 + 8, F(y, 22), hx("6f9a7e"))
        p.rect(X, F(y, 48), T, 3, hx("b9b9b2"))
        if hsh(x, y, 2) % 3 == 0:
            p.rect(X + 10, F(y, 47), 6, 2, C["white"])
    elif c == "j":
        # 화이트보드 (사진 092808)
        p.rect(X, F(y, 12), T, 34, hx("b9bdc2"))
        p.rect(X + (3 if run_l else 0), F(y, 14), T - (3 if run_l else 0) - (3 if run_r else 0), 30, hx("f7f8f6"))
        h = hsh(x, y)
        if h % 2:
            p.line(X + 5, F(y, 22), X + 20, F(y, 20), hx("3a5ac8"))
            p.line(X + 5, F(y, 27), X + 16, F(y, 27), hx("c83a3a"))
        p.line(X + 4, F(y, 40), X + 26, F(y, 18), hx("ffffff"))
        p.rect(X, F(y, 46), T, 3, hx("9aa0a6"))
    else:
        face_decor(p, rm, x, y, c, "classroom")


def room_side_door(p, rm, x, y):
    X, Y = x * T, y * T
    right = rm.is_floor(x - 1, y)
    p.rect(X, Y - 20, T, 52, C["ceil"])
    if right:
        p.rect(X, Y - 20, 8, 52, hx("cfc8b8"))
        p.rect(X + 2, Y - 16, 6, 46, C["oakd"])
    else:
        p.rect(X + T - 8, Y - 20, 8, 52, hx("cfc8b8"))


def desk(p, X, Y, k):
    """학생 책상(원목 상판 + 회색 다리) + 바퀴 의자 (사진 092808)"""
    shadow(p, X, Y + 18, 32, 10, 0.25)
    p.rect(X + 2, Y + 2, 28, 12, hx("d8b07a"))
    p.rect(X + 2, Y + 2, 28, 1, hx("ecc898"))
    p.rect(X + 2, Y + 14, 28, 3, hx("8e9196"))
    p.rect(X + 4, Y + 17, 2, 7, hx("777a80"))
    p.rect(X + 26, Y + 17, 2, 7, hx("777a80"))
    h = hsh(X, Y)
    if h % 3 == 0:
        p.rect(X + 6 + h % 10, Y + 4, 9, 6, [hx("f4f2ea"), hx("3a6ad8"), hx("e8b84a")][(h >> 4) % 3])
    elif h % 3 == 1:
        p.rect(X + 10, Y + 4, 12, 7, hx("2a2c34"))
        p.rect(X + 11, Y + 5, 10, 4, hx("4a6aa8"))
    col = CHAIRS[(h >> 7) % len(CHAIRS)]
    p.rect(X + 8, Y + 20, 16, 7, dark(col, 0.25))
    p.rect(X + 8, Y + 22, 16, 9, col)
    p.rect(X + 8, Y + 22, 16, 1, light(col, 0.3))
    p.rect(X + 15, Y + 30, 2, 2, hx("55585e"))


def teacher_desk(p, X, Y, first, last):
    shadow(p, X, Y + 20, 32, 10, 0.3)
    p.rect(X, Y + 4, T, 12, hx("9a6236"))
    p.rect(X, Y + 4, T, 1, hx("c08250"))
    p.rect(X, Y + 16, T, 14, hx("6e4122"))
    if first:
        p.rect(X, Y + 4, 2, 26, hx("5a3318"))
    if last:
        p.rect(X + 30, Y + 4, 2, 26, hx("5a3318"))
    if not first and not last:
        p.rect(X + 8, Y - 8, 16, 11, hx("1e1f24"))
        p.rect(X + 9, Y - 7, 14, 8, hx("3a5a8a"))
        p.rect(X + 14, Y + 3, 4, 2, hx("55585e"))


def bookshelf(p, X, Y):
    shadow(p, X, Y + 22, 32, 8, 0.3)
    p.rect(X + 1, Y - 26, 30, 56, hx("6e4224"))
    p.rect(X + 1, Y - 26, 30, 2, hx("8a5a32"))
    cols = [hx("c83a3a"), hx("3a6ad8"), hx("e8b84a"), hx("4caf50"), hx("f4f2ea"), hx("7a4ab0"), hx("e86a3a")]
    for r in range(4):
        sy = Y - 22 + r * 13
        p.rect(X + 3, sy, 26, 11, hx("3a2414"))
        h = hsh(X, Y, r)
        bx = X + 3
        while bx < X + 28:
            h = hsh(h, bx)
            w = 2 + h % 3
            hh = 7 + (h >> 4) % 4
            p.rect(bx, sy + 11 - hh, w, hh, cols[(h >> 6) % len(cols)])
            bx += w + (1 if (h >> 9) % 4 == 0 else 0)
        p.rect(X + 1, sy + 11, 30, 2, hx("8a5a32"))


def lockers(p, X, Y):
    """원목 사물함 (2층 사진 092914: 작은 칸 여러 줄)"""
    shadow(p, X, Y + 22, 32, 8, 0.3)
    p.rect(X, Y - 18, T, 48, hx("c99a62"))
    for r in range(3):
        for k in range(2):
            cx_, cy_ = X + 2 + k * 15, Y - 16 + r * 15
            p.rect(cx_, cy_, 13, 13, hx("ddb47e"))
            p.rect(cx_, cy_, 13, 1, hx("ecca9a"))
            p.rect(cx_ + 3, cy_ + 3, 7, 2, C["white"])
            p.px(cx_ + 10, cy_ + 8, hx("6a4a2a"))
    p.rect(X, Y + 28, T, 2, hx("8a6238"))


def computer(p, X, Y, imac=False):
    shadow(p, X, Y + 18, 32, 10, 0.25)
    p.rect(X + 1, Y + 6, 30, 10, hx("e9e9e6") if imac else hx("9a9ea4"))
    p.rect(X + 1, Y + 16, 30, 3, hx("c4c4c0") if imac else hx("6e7278"))
    if imac:
        p.rect(X + 6, Y - 12, 20, 16, hx("cfd2d6"))
        p.rect(X + 7, Y - 11, 18, 12, hx("3a6aa8"))
        p.rect(X + 14, Y + 4, 4, 3, hx("b5b8bc"))
    else:
        p.rect(X + 6, Y - 10, 20, 14, hx("1c1d22"))
        p.rect(X + 7, Y - 9, 18, 10, hx("2a4a7a"))
        p.line(X + 9, Y - 7, X + 18, Y - 7, hx("6ab0ff"))
        p.rect(X + 14, Y + 4, 4, 3, hx("2a2b30"))
    p.rect(X + 8, Y + 9, 16, 4, hx("2a2b30") if not imac else hx("f4f4f2"))
    col = CHAIRS[hsh(X, Y) % len(CHAIRS)]
    p.rect(X + 9, Y + 22, 14, 9, col)
    p.rect(X + 9, Y + 22, 14, 1, light(col, 0.3))


def round_table(p, X, Y):
    """흰 원탁 + 회색 기둥 (사진 093112)"""
    shadow(p, X - 2, Y + 16, 36, 12, 0.3)
    p.rect(X + 13, Y + 12, 6, 14, hx("9aa0a6"))
    p.ell(X + 1, Y + 1, X + 30, Y + 17, hx("c9ccce"))
    p.ell(X + 1, Y - 1, X + 30, Y + 15, hx("eef0f0"))
    p.ell(X + 6, Y + 1, X + 18, Y + 7, C["white"])


def trophy(p, X, Y):
    shadow(p, X, Y + 22, 32, 8, 0.3)
    p.rect(X + 1, Y - 22, 30, 52, hx("6e4224"))
    p.rect(X + 3, Y - 20, 26, 30, hx("b9d4dc"))
    for k, col in enumerate((hx("e8b84a"), hx("c0c4c8"), hx("c8854a"))):
        tx = X + 5 + k * 8
        p.rect(tx + 1, Y - 6, 4, 4, col)
        p.ell(tx, Y - 14, tx + 6, Y - 6, col)
        p.rect(tx, Y - 2, 6, 2, dark(col, 0.3))
    p.line(X + 5, Y + 6, X + 14, Y - 18, hx("e6f2f6"))
    p.rect(X + 3, Y + 12, 26, 16, hx("8a5a32"))
    p.rect(X + 15, Y + 12, 2, 16, hx("6e4224"))


def purifier(p, X, Y):
    shadow(p, X + 4, Y + 22, 24, 8, 0.3)
    p.rect(X + 8, Y - 16, 16, 44, hx("f4f4f2"))
    p.rect(X + 8, Y - 16, 16, 2, C["white"])
    p.rect(X + 22, Y - 16, 2, 44, hx("d4d6d8"))
    p.rect(X + 10, Y - 10, 4, 3, hx("4aa3e8"))
    p.rect(X + 17, Y - 10, 4, 3, hx("e85a4a"))
    p.rect(X + 10, Y, 12, 8, hx("cfd3d6"))


def printer3d(p, X, Y):
    shadow(p, X, Y + 20, 32, 10, 0.3)
    p.rect(X + 3, Y - 14, 26, 42, hx("e9e9e6"))
    p.rect(X + 6, Y - 10, 20, 24, hx("2a3040"))
    p.rect(X + 8, Y + 6, 16, 3, hx("8a8e94"))
    p.rect(X + 13, Y - 2, 6, 8, hx("e86a3a"))
    p.rect(X + 13, Y - 10, 6, 3, hx("c4c4c0"))


def laser_cutter(p, X, Y):
    shadow(p, X, Y + 20, 32, 10, 0.3)
    p.rect(X + 1, Y - 6, 30, 34, hx("8a8e94"))
    p.rect(X + 1, Y - 6, 30, 12, hx("c83a3a"))
    p.rect(X + 4, Y - 4, 24, 8, hx("e86a5a"))
    p.rect(X + 4, Y + 10, 6, 3, hx("2fa860"))


def easel(p, X, Y):
    shadow(p, X + 4, Y + 22, 24, 8, 0.25)
    p.line(X + 8, Y + 30, X + 16, Y - 16, hx("a8743e"), 2)
    p.line(X + 24, Y + 30, X + 16, Y - 16, hx("a8743e"), 2)
    p.line(X + 16, Y - 12, X + 16, Y + 28, hx("8a5a2a"), 2)
    p.rect(X + 6, Y - 12, 20, 18, hx("f4f2ea"))
    h = hsh(X, Y)
    p.rect(X + 7, Y - 11, 18, 7, [hx("7ac0e8"), hx("f2a35a"), hx("8bc36a")][h % 3])
    p.ell(X + 10 + h % 6, Y - 8, X + 18 + h % 6, Y, [hx("e85a4a"), hx("3a6ad8"), hx("e8b84a")][(h >> 3) % 3])
    p.rect(X + 6, Y + 6, 20, 2, hx("8a5a2a"))


def washer(p, X, Y):
    shadow(p, X, Y + 22, 32, 8, 0.3)
    p.rect(X + 2, Y - 14, 28, 42, hx("eef0f0"))
    p.rect(X + 2, Y - 14, 28, 7, hx("d4d6d8"))
    p.rect(X + 18, Y - 12, 8, 3, hx("4aa3e8"))
    p.ell(X + 6, Y - 4, X + 26, Y + 16, hx("8e949a"))
    p.ell(X + 9, Y - 1, X + 23, Y + 13, hx("3a4a64"))
    p.ell(X + 11, Y + 1, X + 17, Y + 6, hx("6a8ab0"))


def bed(p, X, Y):
    """2칸짜리 침대: 원목 틀, 흰 시트, 베개, 남색 이불"""
    shadow(p, X, Y + 22, 64, 10, 0.3)
    p.rect(X + 1, Y - 2, 62, 30, hx("8a5a32"))
    p.rect(X + 3, Y, 58, 24, hx("f2f2ee"))
    p.rect(X + 5, Y + 2, 14, 18, hx("ffffff"))
    p.rect(X + 5, Y + 18, 14, 2, hx("d6d6d0"))
    p.rect(X + 22, Y + 1, 38, 23, hx("2f4a8a"))
    p.rect(X + 22, Y + 1, 38, 3, hx("4a66a8"))
    for k in range(3):
        p.line(X + 28 + k * 10, Y + 6, X + 26 + k * 10, Y + 22, hx("27407a"))


def telescope(p, X, Y):
    shadow(p, X + 2, Y + 22, 28, 8, 0.3)
    for dx in (6, 16, 26):
        p.line(X + 16, Y + 2, X + dx, Y + 30, hx("3a3d44"), 2)
    p.line(X + 6, Y + 6, X + 28, Y - 14, hx("e9e9e6"), 7)
    p.line(X + 6, Y + 6, X + 28, Y - 14, hx("c4c8cc"), 1)
    p.rect(X + 26, Y - 17, 5, 5, hx("2a2b30"))


def goal(p, X, Y):
    """체육관 농구 골대 (사진 092927): 흰 철골 + 투명 백보드 + 주황 림"""
    shadow(p, X - 2, Y + 20, 36, 10, 0.3)
    p.rect(X + 14, Y - 20, 4, 48, hx("dcdcd8"))
    p.rect(X + 2, Y - 34, 28, 20, hx("cfe2ea"))
    p.rect(X + 2, Y - 34, 28, 2, C["white"])
    p.rect(X + 2, Y - 16, 28, 3, hx("3a6ad8"))
    p.rect(X + 10, Y - 28, 12, 9, hx("f4f4f4"))
    p.rect(X + 11, Y - 27, 10, 7, hx("cfe2ea"))
    p.ell(X + 9, Y - 14, X + 23, Y - 9, hx("e86a2a"))
    for k in range(4):
        p.line(X + 10 + k * 4, Y - 10, X + 12 + k * 3, Y - 2, C["white"])


def bench(p, X, Y):
    shadow(p, X, Y + 18, 32, 8, 0.25)
    p.rect(X, Y + 6, T, 8, hx("c08850"))
    p.rect(X, Y + 6, T, 1, hx("dca068"))
    p.rect(X + 3, Y + 14, 3, 10, hx("6e4224"))
    p.rect(X + 26, Y + 14, 3, 10, hx("6e4224"))


def gym_lines(p, rm):
    """체육관 바닥의 색 줄 (파랑·초록·노랑·빨강)"""
    W, H = rm.W * T, rm.H * T
    x0, y0, x1, y1 = T + 8, T * 2 + 8, W - T - 8, H - T - 8
    p.d.rectangle([x0, y0 + p.oy, x1, y1 + p.oy], outline=hx("2f6ad0"), width=2)
    p.line((x0 + x1) // 2, y0, (x0 + x1) // 2, y1, hx("2f6ad0"), 2)
    p.d.ellipse([(x0 + x1) // 2 - 40, (y0 + y1) // 2 - 40 + p.oy, (x0 + x1) // 2 + 40, (y0 + y1) // 2 + 40 + p.oy], outline=hx("2f6ad0"), width=2)
    p.d.rectangle([x0 + 20, y0 + 20 + p.oy, x1 - 20, y1 - 20 + p.oy], outline=hx("3a9a4a"), width=2)
    p.d.rectangle([x0, (y0 + y1) // 2 - 50 + p.oy, x0 + 90, (y0 + y1) // 2 + 50 + p.oy], outline=hx("e8b84a"), width=2)
    p.d.rectangle([x1 - 90, (y0 + y1) // 2 - 50 + p.oy, x1, (y0 + y1) // 2 + 50 + p.oy], outline=hx("e8b84a"), width=2)
    p.line(x0 + 140, y0, x0 + 140, y1, hx("d83a4a"), 2)
    p.line(x1 - 140, y0, x1 - 140, y1, hx("d83a4a"), 2)


ROOM_OBJECTS = set("dTkLcioAQmZePWhtGzSpvgfs")


def render_room(rid, info):
    rm = RoomMap(rid, info)
    p = Painter(rm.W, rm.H, oy=64)
    H, W = rm.H, rm.W
    for y in range(H):
        for x in range(W):
            if rm.is_floor(x, y):
                room_floor(p, rm, x, y)
    if rid == "a2_gym":
        gym_lines(p, rm)
    post_floor(p, rm)
    # 아래쪽 벽과 문 / 옆문
    for y in range(H):
        for x in range(W):
            if rm.is_floor(x, y):
                continue
            if rm.is_floor(x, y - 1) and not rm.is_floor(x, y + 1):
                if rm.is_door(x, y):
                    door_bottom(p, rm, x, y, rm.c(x, y))
                else:
                    top_edge(p, rm, x, y, "=")
            elif rm.is_door(x, y) and (rm.is_floor(x - 1, y) or rm.is_floor(x + 1, y)):
                room_side_door(p, rm, x, y)
    faces = [(x, y) for y in range(H) for x in range(W) if not rm.is_floor(x, y) and rm.is_floor(x, y + 1)]
    for x, y in faces:
        c = rm.c(x, y)
        room_face(p, rm, x, y)
        if rm.is_door(x, y):
            door_face(p, rm, x, y, c)
        elif c in ROOM_WALL:
            room_face_decor(p, rm, x, y, c)
    for y in range(H):
        for x in range(W):
            if rm.is_floor(x, y) or rm.is_floor(x, y + 1) or rm.is_door(x, y):
                continue
            X, Y = x * T, y * T
            up = 0 if rm.is_floor(x, y - 1) else WALL_UP
            if rm.is_floor(x + 1, y):
                p.rect(X + T - 7, Y - up, 7, T + up, C["edge"])
                p.rect(X + T - 8, Y - up, 1, T + up, C["edged"])
            if rm.is_floor(x - 1, y):
                p.rect(X, Y - up, 7, T + up, C["edge"])
                p.rect(X + 7, Y - up, 1, T + up, C["edged"])
    reflections(p, rm, faces) if rm.floor != "wood" else None
    # 물건 (위 줄부터)
    for y in range(H):
        for x in range(W):
            c = rm.c(x, y)
            X, Y = x * T, y * T
            first = rm.c(x - 1, y) != c
            last = rm.c(x + 1, y) != c
            if c == "d":
                desk(p, X, Y, 0)
            elif c == "T":
                teacher_desk(p, X, Y, first, last)
            elif c == "k":
                bookshelf(p, X, Y)
            elif c == "L":
                lockers(p, X, Y)
            elif c == "c":
                computer(p, X, Y)
            elif c == "i":
                computer(p, X, Y, imac=True)
            elif c == "o":
                round_table(p, X, Y)
            elif c == "A":
                trophy(p, X, Y)
            elif c == "Q":
                purifier(p, X, Y)
            elif c == "m":
                printer3d(p, X, Y)
            elif c == "Z":
                laser_cutter(p, X, Y)
            elif c == "e":
                easel(p, X, Y)
            elif c == "P" and first and rm.c(x, y - 1) != "P":
                piano(p, X + 4, Y - 6)
            elif c == "W":
                washer(p, X, Y)
            elif c == "h" and first:
                bed(p, X, Y)
            elif c == "t":
                telescope(p, X, Y)
            elif c == "G":
                goal(p, X, Y)
            elif c == "z":
                bench(p, X, Y)
            elif c == "S":
                sofa(p, X, Y)
            elif c == "p":
                plant(p, X, Y)
            elif c == "v":
                vending(p, X, Y)
            elif c == "g":
                pool_table(p, X, Y)
            elif c == "f":
                bear(p, X, Y)
    return p.img


def main():
    halls = json.load(open(os.path.join(HERE, "halls.json")))
    plan = halls.pop("_plan")
    rooms = halls.pop("_rooms", {})
    os.makedirs(OUT, exist_ok=True)
    for hid, info in halls.items():
        img = render(hid, info, plan)
        path = os.path.join(OUT, hid + ".png")
        img.save(path, optimize=True)
        print(hid, img.size, os.path.getsize(path) // 1024, "KB")
    rout = os.path.join(ROOT, "assets", "rooms")
    os.makedirs(rout, exist_ok=True)
    for rid, info in rooms.items():
        img = render_room(rid, info)
        img.save(os.path.join(rout, rid + ".png"), optimize=True)
    print("rooms:", len(rooms))


if __name__ == "__main__":
    main()
