#!/usr/bin/env python3
"""칩튠 배경 음악 생성기.  사용법:  python3 tools/make_music.py
assets/music/*.ogg 를 만든다 (ffmpeg 필요). 곡을 고치려면 아래 SONGS 를 수정.
음표 표기:  "E5:2" = 미(5옥타브)를 16분음표 2개 길이로.  "-:4" = 쉼표.
"""
import numpy as np, subprocess, os, wave, sys

SR = 32000
NOTE = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


def freq(name):
    n = NOTE[name[0]]
    i = 1
    if name[i] == '#':
        n += 1; i += 1
    elif name[i] == 'b':
        n -= 1; i += 1
    octave = int(name[i:])
    return 440.0 * 2 ** ((n - 9) / 12 + (octave - 4))


def parse(s):
    out = []
    for tok in s.split():
        p, d = tok.split(':')
        out.append((None if p == '-' else freq(p), int(d)))
    return out


def env(n, a=0.005, d=0.08, s=0.6, r=0.04):
    t = np.arange(n) / SR
    e = np.ones(n) * s
    na = max(1, int(a * SR)); nd = max(1, int(d * SR)); nr = max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na)[:len(e[:na])]
    seg = e[na:na + nd]
    seg[:] = np.linspace(1, s, nd)[:len(seg)]
    tail = e[-nr:]
    tail *= np.linspace(1, 0, nr)[-len(tail):]
    return e


def osc(kind, f, n, duty=0.5, vib=0.0):
    t = np.arange(n) / SR
    ph = f * t
    if vib:
        ph = ph + vib * np.sin(2 * np.pi * 5.5 * t) * (t > 0.12)
    ph = ph % 1.0
    if kind == 'pulse':
        return np.where(ph < duty, 1.0, -1.0)
    if kind == 'tri':
        return 4 * np.abs(ph - 0.5) - 1
    if kind == 'saw':
        return 2 * ph - 1
    return np.sin(2 * np.pi * ph)


def add(buf, start, sig):
    """루프가 자연스럽게 이어지도록 끝을 넘는 소리는 앞으로 감아 넣는다."""
    n = len(buf)
    start %= n
    end = start + len(sig)
    if end <= n:
        buf[start:end] += sig
    else:
        k = n - start
        buf[start:] += sig[:k]
        buf[:len(sig) - k] += sig[k:][:n]


def render_line(buf, notes, step, kind, vol, duty=0.5, vib=0.0, gate=0.9, e=None):
    pos = 0
    for f, d in notes:
        n = int(d * step * SR)
        if f:
            m = max(64, int(n * gate))
            kw = e or {}
            add(buf, int(pos * step * SR), osc(kind, f, m, duty, vib) * env(m, **kw) * vol)
        pos += d


def drum(kind):
    if kind == 'k':
        n = int(0.14 * SR); t = np.arange(n) / SR
        return np.sin(2 * np.pi * (120 * np.exp(-t * 28) + 42) * t) * np.exp(-t * 22) * 0.9
    if kind == 's':
        n = int(0.12 * SR); t = np.arange(n) / SR
        return (np.random.uniform(-1, 1, n) * 0.6 + np.sin(2 * np.pi * 190 * t) * 0.3) * np.exp(-t * 30)
    n = int(0.03 * SR); t = np.arange(n) / SR
    return np.random.uniform(-1, 1, n) * np.exp(-t * 120) * 0.35


def render(song):
    np.random.seed(7)
    step = 60.0 / song['bpm'] / 4          # 16분음표 길이(초)
    bars = song['bars']
    total = int(round(bars * 16 * step * SR))
    buf = np.zeros(total)
    reps = song.get('repeat', 1)
    for rep in range(reps):
        pass
    lead = parse(' '.join(song['lead']))
    render_line(buf, lead, step, 'pulse', song.get('lead_vol', 0.22), song.get('duty', 0.25), 0.004,
                song.get('gate', 0.9), song.get('lead_env'))
    if 'harm' in song:
        render_line(buf, parse(' '.join(song['harm'])), step, 'pulse', 0.10, 0.5, 0.0, 0.9)
    # 베이스 + 아르페지오는 코드 진행에서 자동 생성
    bass, arp = [], []
    for ch in song['chords']:
        root, third, fifth = ch
        for pat in song['bass_pat']:
            which, d = pat
            if which == '-':
                bass.append((None, d))
            else:
                f = freq(root) * {'r': 1, 'o': 2, 'f': freq(fifth) / freq(root)}[which]
                while f > 180: f /= 2
                bass.append((f, d))
        tones = [freq(root), freq(third), freq(fifth), freq(third)]
        for i, which in enumerate(song['arp_pat']):
            d = 16 // len(song['arp_pat'])
            if which == '-':
                arp.append((None, d))
            else:
                f = tones[int(which) % 4] * (2 if int(which) >= 4 else 1)
                arp.append((f, d))
    render_line(buf, bass, step, 'tri', song.get('bass_vol', 0.42), gate=0.85)
    render_line(buf, arp, step, 'pulse', song.get('arp_vol', 0.07), 0.125, gate=0.6)
    for bar in range(bars):
        for i, c in enumerate(song.get('drums', '')):
            if c in 'ksh':
                add(buf, int((bar * 16 + i) * step * SR), drum(c) * song.get('drum_vol', 0.5))
    # 살짝 부드럽게 + 리미터
    k = np.array([0.25, 0.5, 0.25])
    buf = np.convolve(buf, k, mode='same')
    buf = np.tanh(buf * 1.4) * 0.8
    return buf


SONGS = {
    # 밤의 학교 (타이틀/복도)
    'school_night': dict(
        bpm=76, bars=8, duty=0.5, gate=0.95, lead_vol=0.16, arp_vol=0.05, bass_vol=0.34,
        lead_env=dict(a=0.03, d=0.3, s=0.5, r=0.2),
        lead=["A4:4 C5:4 E5:8", "F5:6 E5:2 C5:8", "E5:4 G5:4 C5:8", "B4:6 D5:2 E5:8",
              "A5:4 E5:4 C5:8", "A5:6 G5:2 F5:8", "G5:4 E5:4 C5:8", "G#4:8 B4:4 E5:4"],
        chords=[("A2", "C4", "E4"), ("F2", "A3", "C4"), ("C3", "E4", "G4"), ("E2", "G#3", "B3")] * 2,
        bass_pat=[('r', 12), ('f', 4)], arp_pat="01230123", drums="h.......h.......", drum_vol=0.25),
    # 집합과 명제의 숲
    'forest': dict(
        bpm=112, bars=8, duty=0.25, gate=0.55, lead_vol=0.2,
        lead=["E5:2 -:2 G5:2 -:2 C6:2 G5:2 E5:2 -:2", "A5:2 -:2 E5:2 -:2 C5:2 E5:2 A5:2 -:2",
              "A5:2 -:2 F5:2 -:2 C6:2 A5:2 F5:2 -:2", "G5:2 B5:2 D6:2 B5:2 G5:4 -:4",
              "C6:2 -:2 E6:2 -:2 D6:2 C6:2 G5:2 -:2", "A5:2 C6:2 E6:2 C6:2 A5:4 -:4",
              "F5:2 A5:2 C6:2 A5:2 G5:2 B5:2 D6:2 B5:2", "C6:4 G5:4 C5:4 -:4"],
        chords=[("C3", "E4", "G4"), ("A2", "C4", "E4"), ("F2", "A3", "C4"), ("G2", "B3", "D4"),
                ("C3", "E4", "G4"), ("A2", "C4", "E4"), ("F2", "A3", "C4"), ("C3", "E4", "G4")],
        bass_pat=[('r', 4), ('-', 2), ('r', 2), ('f', 4), ('-', 2), ('f', 2)], arp_pat="0-2-1-2-",
        drums="k..hs..hk.khs..h", drum_vol=0.35),
    # 일반 전투
    'battle': dict(
        bpm=150, bars=8, duty=0.25, lead_vol=0.2,
        lead=["E5:2 G5:2 B5:2 E5:2 G5:2 B5:2 A5:2 G5:2", "E5:2 G5:2 C6:2 E5:2 G5:2 C6:2 B5:2 G5:2",
              "F#5:2 A5:2 D6:2 F#5:2 A5:2 D6:2 C6:2 A5:2", "B5:4 G5:2 E5:2 B4:4 -:4",
              "E5:3 E5:1 G5:2 A5:2 B5:4 D6:2 B5:2", "C6:3 C6:1 B5:2 A5:2 G5:4 E5:4",
              "F#5:2 A5:2 D6:4 C6:2 B5:2 A5:2 F#5:2", "D#5:2 F#5:2 B5:4 A5:2 F#5:2 D#5:2 B4:2"],
        chords=[("E2", "G3", "B3"), ("C3", "E4", "G4"), ("D3", "F#3", "A3"), ("E2", "G3", "B3"),
                ("E2", "G3", "B3"), ("C3", "E4", "G4"), ("D3", "F#3", "A3"), ("B2", "D#4", "F#4")],
        bass_pat=[('r', 2), ('r', 2), ('o', 2), ('r', 2)] * 2, arp_pat="0123",
        drums="k.h.s.h.k.k.s.hh", drum_vol=0.5),
    # 보스전
    'boss': dict(
        bpm=168, bars=8, duty=0.5, lead_vol=0.2,
        lead=["D5:2 F5:2 A5:2 D6:4 A5:2 F5:2 A5:2", "D6:2 C6:2 A5:2 F5:2 G5:2 A5:2 F5:2 D5:2",
              "Bb4:2 D5:2 F5:2 Bb5:4 F5:2 D5:2 F5:2", "C5:2 E5:2 G5:2 C6:4 G5:2 E5:2 G5:2",
              "A5:4 D6:4 F6:4 E6:2 D6:2", "Bb5:4 D6:4 G5:4 Bb5:2 A5:2",
              "A5:2 C#6:2 E6:2 A5:2 C#6:2 E6:2 G6:2 E6:2", "C#6:4 A5:4 E5:4 A5:2 C#6:2"],
        harm=["F4:8 A4:8", "F4:8 D4:8", "D4:8 F4:8", "E4:8 G4:8", "F4:8 A4:8", "G4:8 D4:8", "E4:8 C#4:8", "E4:8 A4:8"],
        chords=[("D2", "F3", "A3"), ("D2", "F3", "A3"), ("Bb2", "D4", "F4"), ("C3", "E4", "G4"),
                ("D2", "F3", "A3"), ("G2", "Bb3", "D4"), ("A2", "C#4", "E4"), ("A2", "C#4", "E4")],
        bass_pat=[('r', 1), ('r', 1), ('o', 1), ('r', 1)] * 4, arp_pat="01234321",
        drums="k.hhs.hkk.hhs.sh", drum_vol=0.55),
    # 세포 속 (2챕터)
    'bio': dict(
        bpm=100, bars=8, duty=0.125, gate=0.8, lead_vol=0.2,
        lead=["D5:3 F5:1 A5:2 G5:2 F5:4 E5:4", "D5:2 G5:2 B5:4 A5:2 G5:2 D5:4", "F5:3 A5:1 D6:2 C6:2 A5:4 F5:4",
              "E5:2 G5:2 C6:4 B5:2 G5:2 E5:4", "D5:3 F5:1 A5:2 G5:2 F5:4 D5:4", "G5:2 B5:2 D6:4 B5:2 G5:2 D5:4",
              "Bb5:4 A5:2 G5:2 F5:4 D5:4", "A5:6 E5:2 C#5:4 E5:4"],
        chords=[("D2", "F3", "A3"), ("G2", "B3", "D4"), ("D2", "F3", "A3"), ("C3", "E4", "G4"),
                ("D2", "F3", "A3"), ("G2", "B3", "D4"), ("Bb2", "D4", "F4"), ("A2", "C#4", "E4")],
        bass_pat=[('r', 3), ('-', 1), ('r', 2), ('o', 2), ('r', 3), ('-', 1), ('f', 4)], arp_pat="0-1-2-1-",
        drums="k...s..k.k..s.h.", drum_vol=0.4),
    # 암실 (3챕터). 120 BPM, 박자마다 킥. 전투의 박자 탄막이 이 곡에 맞춰진다.
    'optics': dict(
        bpm=120, bars=8, duty=0.25, lead_vol=0.18,
        lead=["A5:2 E5:2 C6:2 E5:2 A5:2 E5:2 C6:2 E5:2", "B5:2 E5:2 D6:2 E5:2 C6:2 E5:2 A5:4",
              "A5:2 F5:2 C6:2 F5:2 A5:2 F5:2 C6:2 A5:2", "B5:2 G5:2 D6:2 G5:2 B5:4 D6:4",
              "E6:4 C6:4 A5:4 C6:2 E6:2", "D6:4 B5:4 E5:4 B5:4",
              "C6:2 A5:2 F5:2 A5:2 C6:2 F6:2 E6:2 C6:2", "B5:4 G#5:4 E5:4 G#5:2 B5:2"],
        chords=[("A2", "C4", "E4"), ("A2", "C4", "E4"), ("F2", "A3", "C4"), ("G2", "B3", "D4"),
                ("A2", "C4", "E4"), ("A2", "C4", "E4"), ("F2", "A3", "C4"), ("E2", "G#3", "B3")],
        bass_pat=[('r', 2), ('o', 2)] * 4, arp_pat="0123",
        drums="k..hk.shk..hk.sh", drum_vol=0.6),
    # 한밤의 기숙사 (4챕터)
    'dorm': dict(
        bpm=92, bars=8, duty=0.5, gate=0.4, lead_vol=0.17, arp_vol=0.04, bass_vol=0.36,
        lead=["E5:2 -:2 G5:2 -:2 B4:2 -:6", "E5:2 -:2 G5:2 A5:2 B5:4 -:4", "C5:2 -:2 E5:2 -:2 G5:2 -:6",
              "B4:2 D#5:2 F#5:4 -:8", "E5:2 G5:2 B5:2 -:2 E6:4 -:4", "A5:2 -:2 C6:2 -:2 E5:4 -:4",
              "G5:2 E5:2 C5:2 -:2 E5:4 -:4", "F#5:4 D#5:4 B4:8"],
        chords=[("E2", "G3", "B3"), ("E2", "G3", "B3"), ("C3", "E4", "G4"), ("B2", "D#4", "F#4"),
                ("E2", "G3", "B3"), ("A2", "C4", "E4"), ("C3", "E4", "G4"), ("B2", "D#4", "F#4")],
        bass_pat=[('r', 2), ('-', 6), ('f', 2), ('-', 6)], arp_pat="0---2---",
        drums="h...h...h...h.h.", drum_vol=0.25),
    # 최종전 (6챕터)
    'final': dict(
        bpm=176, bars=8, duty=0.25, lead_vol=0.2,
        lead=["C5:2 Eb5:2 G5:2 C6:2 G5:2 Eb5:2 G5:2 C6:2", "Ab5:2 C6:2 Eb6:4 C6:2 Ab5:2 Eb5:4",
              "Bb5:2 D6:2 F6:4 D6:2 Bb5:2 F5:4", "G5:2 C6:2 Eb6:2 G6:4 Eb6:2 C6:4",
              "C6:4 G5:4 Eb6:4 D6:2 C6:2", "F5:2 Ab5:2 C6:2 F6:4 C6:2 Ab5:4",
              "G5:2 B5:2 D6:2 G6:2 F6:2 D6:2 B5:2 G5:2", "D6:4 B5:4 G5:4 B5:2 D6:2"],
        harm=["Eb4:8 G4:8", "Eb4:8 C4:8", "F4:8 D4:8", "Eb4:8 G4:8", "Eb4:8 G4:8", "F4:8 Ab4:8", "D4:8 G4:8", "D4:8 B3:8"],
        chords=[("C2", "Eb3", "G3"), ("Ab2", "C4", "Eb4"), ("Bb2", "D4", "F4"), ("C2", "Eb3", "G3"),
                ("C2", "Eb3", "G3"), ("F2", "Ab3", "C4"), ("G2", "B3", "D4"), ("G2", "B3", "D4")],
        bass_pat=[('r', 1), ('r', 1), ('o', 1), ('r', 1)] * 4, arp_pat="01234321",
        drums="k.hhs.hkk.hhs.sh", drum_vol=0.55),
    # 옥상 천문대 (5챕터): 반짝이는 아르페지오, 느린 베이스
    'astro': dict(
        bpm=96, bars=8, duty=0.125, gate=0.7, lead_vol=0.16, arp_vol=0.07, bass_vol=0.3,
        lead_env=dict(a=0.01, d=0.25, s=0.4, r=0.3),
        lead=["E6:2 -:2 B5:2 -:2 G5:2 B5:2 E6:4", "D6:2 -:2 A5:2 -:2 F#5:2 A5:2 D6:4",
              "C6:2 -:2 G5:2 -:2 E5:2 G5:2 C6:4", "B5:4 F#5:4 D#5:8",
              "G6:2 E6:2 B5:2 E6:2 G6:4 F#6:4", "F#6:2 D6:2 A5:2 D6:2 F#6:4 E6:4",
              "E6:2 C6:2 G5:2 C6:2 E6:4 D6:4", "D#6:4 B5:4 F#5:4 B5:4"],
        chords=[("E2", "G3", "B3"), ("D2", "F#3", "A3"), ("C3", "E4", "G4"), ("B2", "D#4", "F#4"),
                ("E2", "G3", "B3"), ("D2", "F#3", "A3"), ("C3", "E4", "G4"), ("B2", "D#4", "F#4")],
        bass_pat=[('r', 6), ('f', 2), ('-', 8)], arp_pat="01230321",
        drums="h.......h...h...", drum_vol=0.18),
    # 엔딩
    'ending': dict(
        bpm=84, bars=8, duty=0.5, gate=0.95, lead_vol=0.17, arp_vol=0.06, bass_vol=0.36,
        lead_env=dict(a=0.02, d=0.3, s=0.6, r=0.15),
        lead=["E5:4 G5:4 C6:8", "D5:4 G5:4 B5:8", "C5:4 E5:4 A5:8", "A5:4 G5:4 F5:8",
              "E5:4 G5:4 C6:4 E6:4", "D6:6 B5:2 G5:8", "A5:4 C6:4 F5:8", "E5:4 D5:4 C5:8"],
        chords=[("C3", "E4", "G4"), ("G2", "B3", "D4"), ("A2", "C4", "E4"), ("F2", "A3", "C4"),
                ("C3", "E4", "G4"), ("G2", "B3", "D4"), ("F2", "A3", "C4"), ("C3", "E4", "G4")],
        bass_pat=[('r', 8), ('f', 8)], arp_pat="01230123", drums=""),
}


def main():
    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'music')
    os.makedirs(out_dir, exist_ok=True)
    only = sys.argv[1:]
    for name, song in SONGS.items():
        if only and name not in only:
            continue
        buf = render(song)
        wav = os.path.join(out_dir, name + '.wav')
        with wave.open(wav, 'wb') as w:
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
            w.writeframes((buf * 32767).astype('<i2').tobytes())
        ogg = os.path.join(out_dir, name + '.ogg')
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis', '-q:a', '4', ogg], check=True)
        os.remove(wav)
        print(name, '%.1f초' % (len(buf) / SR), os.path.getsize(ogg) // 1024, 'KB')


if __name__ == '__main__':
    main()
