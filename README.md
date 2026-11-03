# 탄막 RPG: 융합 프로토콜

밤의 영재학교를 배경으로 한 탄막 RPG. 언더테일식 이야기·전투 메뉴 + 동방식 탄막.
Godot 4.3 이상. **Chapter 1~6과 엔딩 3종(노멀/배드/트루)** 까지 처음부터 끝까지 플레이할 수 있다.

## 고치려면 (처음 받은 사람용)

1. [Godot 4.3](https://godotengine.org/download/archive/4.3-stable/) 표준판을 받는다. (이 게임은 4.3에서 만들고 시험했다.)
2. Godot → **가져오기(Import)** → 저장소 맨 위의 `project.godot` → 편집 → **F5**로 실행.
3. 자주 고치는 곳
   - 대사·퀴즈: `story/ch1.gd` ~ `story/ch6.gd`, `story/extra.gd` (`say([...])`, `choose(...)` 안의 문장)
   - 보스 대사·탄막·퀴즈: `scripts/battle/enemies/*.gd` (예: BJ KIM은 `owl.gd`, 천문 선생은 `astro.gd`)
   - 맵: `tools/world.py` 를 고치고 `python3 tools/world.py` 를 실행하면 `data/rooms_*.gd` 가 다시 만들어진다. (`data/rooms_*.gd` 를 직접 고치면 다음 생성 때 덮어써진다.)
   - 대사가 너무 길거나 맵 줄이 안 맞는지 검사: `godot --headless -s tools/check_text.gd`
   - 색: `scripts/art/palette.gd` (우리 학교 사진에서 잰 'SASA 교정 팔레트'). 학교 타일·조명·화면 UI가 여기 색을 쓴다. 새 색을 직접 적지 말고 `P.이름`으로 쓴다. 다른 세계(숲·세포·암실·서버)와 캐릭터·탄막 색은 따로 정해져 있다.
4. 게임 진행 공략: [docs/WALKTHROUGH.md](docs/WALKTHROUGH.md) / 기획: [docs/GDD.md](docs/GDD.md) / 사진 촬영 가이드: [docs/PHOTO_GUIDE.md](docs/PHOTO_GUIDE.md)

## 실행

> Windows: `PLAY.cmd` 를 두 번 누르면 Godot 4.3 을 찾아(없으면 받아서) 게임을 연다. 고치려면 `EDIT.cmd`.

- **Windows: `PLAY.cmd` 더블클릭.** 컴퓨터에서 Godot 4.3 을 찾아 바로 게임을 띄운다. 없으면 공식 Godot 4.3(약 60MB)을 받을지 묻고, 받은 것은 `%LOCALAPPDATA%\TanmakRPG\godot` 에 두고 다음부터 다시 쓴다. 처음 한 번은 리소스를 불러오느라 몇 초 더 걸린다. 편집기로 열려면 `EDIT.cmd`.
- 직접 열기: Godot 실행 → **가져오기(Import)** → 이 폴더의 `project.godot` → **F5**

## 조작

| 키 | 기능 |
|---|---|
| 방향키 / WASD | 이동, 메뉴 선택 |
| Z / Enter / Space | 조사·대화·확인 |
| X / Backspace | 취소, 대사 빨리 넘기기, **전투 중 폭탄**(집중 게이지 절반 소모) |
| C / Esc | 메뉴 (스탯, 가방, 지금 할 일) |
| Shift (전투 중) | 저속 정밀 이동 + 피격 판정 표시 |

타이틀 화면의 **난이도**에서 '쉬움'(받는 피해 절반)을 고를 수 있다.

## 폴더 구조

```
docs/WALKTHROUGH.md    진행 공략 (챕터별 순서, 퀴즈 정답, 엔딩 조건)
docs/GDD.md            기획 문서 (세계관, 시스템, 챕터·보스·엔딩 조건, 이스터에그 목록)
docs/PHOTO_GUIDE.md    학교 사진 촬영 가이드
data/
  rooms.gd             방 데이터 형식 설명 + 방 파일 목록
  rooms_halls.gd       1~5층 복도 (tools/world.py 가 만든다. 직접 고치지 말 것)
  rooms_f5.gd / rooms_f4.gd / rooms_lower.gd     5층 / 4층 / 3·2·1층 교실
  rooms_ch1.gd ~ rooms_ch56.gd                   챕터별 던전 맵 (방, 세포, 암실, 기숙사, 옥상 천문대, 서버실, 교장실)
  section.gd           미니맵용 학교 평면 (5층 시설 안내도의 S동 · 수학 구역 · A동 · 중앙 홀)
  rooms_extra.gd       ★ 확장판 방 14개 (미술실, 음악실, 체육관, 급식실, 세탁실, 정독실, 운동장, 정원, 택배실, 아침 복도...)
  junkyu.gd            ★ 절규가 잃어버린 물건 12개 (이름, 찾았을 때·돌려줄 때 대사)
  phone.gd             ★ 휴대폰 메시지 12통 (엄마, 절규, 동생, 담임...)
  items.gd             아이템
story/
  common.gd            세이브 포인트, 5층 이스터에그
  ch1.gd ~ ch6.gd      ★ 챕터별 이벤트 (대사, 퍼즐, 전투 순서). ch6.gd 에 엔딩 조건과 최종전 동료 목록이 있다
  junkyu.gd            절규 (만남, 물건 돌려주기, 챕터별 대사)
  extra.gd             확장판 방들의 이벤트, 트루 엔딩 에필로그
scripts/
  core/                game(전역 상태·세이브), snd(소리), main(흐름), story_base(이벤트 명령)
  world/               overworld(필드·어둠·순찰), tiles(타일 그림·충돌), player, actor
  battle/              battle(전투 엔진), bullet, laser, enemy_base, enemies(적 목록)
  battle/enemies/      ★ 적 하나당 파일 하나 (대사, 행동, 탄막 패턴)
  ui/                  대화창, 메뉴, 타이틀, 챕터 카드, 미니맵(오른쪽 위 학교 평면), 개발자 메뉴(dev_menu.gd)
  art/art.gd           캐릭터 그림 (코드로 그림)
  mobile/              휴대폰 터치 조작 (패드, 버튼, 화면 배치)
assets/                폰트, 음악
tools/                 world.py(★ 모든 맵 생성: 5층 시설 안내도 모양의 복도·교실·옥상, 미니맵 평면), make_music.py(음악 생성), check_text.gd(대사·맵 검사)
```

## 고치는 법

**대사를 바꾸고 싶다** → `story/ch1.gd` 의 `say([...])` 안 문장, 조사 대사는 `data/rooms_*.gd` 의 `signs`.
한 문장은 대화창 3줄(약 60자)까지. 넘으면 실행 중에 경고가 뜬다.

**맵을 바꾸고 싶다** → `tools/world.py` 를 고치고 `python3 tools/world.py` (data/rooms_*.gd 를 다시 쓴다. 줄 길이·문 연결·스폰 위치도 검사한다).
글자 하나가 타일 하나이고 뜻은 `scripts/world/tiles.gd` 맨 위에 있다. 방마다 `"where"` 가 오른쪽 위 미니맵의 위치를 정한다.

**새 이벤트** → `story/` 의 파일에 함수를 추가한다.

```gdscript
func ev_vending(_a) -> void:
	await say(["* 자판기다.", "* 동전을 넣을까?"])
	var i: int = await choose("* 500원을 넣는다?", ["넣는다", "참는다"])
	if i == 0:
		give("바나나우유")
		await say(["* '바나나우유'를 얻었다."])
```

그리고 방 데이터에서 `"signs_at": {"12,1": {"event": "vending"}}` 처럼 칸 좌표에 이름으로 연결한다.

**새 적** → `scripts/battle/enemies/` 의 파일 하나를 복사해서 고치고, `scripts/battle/enemies.gd` 에 한 줄 추가.
탄 하나는 `b.add(위치, 속도, 반지름, 색, 모양)`. 이벤트에서 `await battle("적id")` 로 부른다.

**휴대폰 메시지 / 기억 장면** → 이벤트 안에서 `phone("mom1")` (내용은 `data/phone.gd`),
`await memory(["...", "..."])` 는 화면이 어두워지며 회색 글씨로 지나가는 '기억' 장면.

**절규의 물건을 더 놓고 싶다** → `data/junkyu.gd` 의 `ORDER` 와 `ITEMS` 에 추가하고, 방의 `actors` 에
`{"id": "jk_이름", "look": "lost", "pos": [x, y], "solid": false, "unless_flag": "jk_found_이름", "event": "jk_item", "item": "이름"}`.
NPC를 특정 챕터에만 세우려면 actor에 `"chapter": [최소, 최대]`.

**난이도** → 각 적 파일의 `atk`, `max_hp`, 패턴 안의 숫자(간격 `pt`, 속력). 전체 공통은 `battle.gd` 위쪽 상수.

## 휴대폰판

- 터치 화면이면 자동으로 **휴대폰 모드**가 켜진다 (`scripts/mobile/touch.gd`, 자동 로드 `Touch`).
  게임 화면은 그대로 두고, 남는 자리에 방향 패드와 Z(확인)·X(취소·폭탄)·C(메뉴)·S(정밀 이동) 버튼을 그린다.
  가로 화면은 양옆, 세로 화면은 아래. 버튼이 키보드와 같은 입력을 누르기 때문에 게임 코드는 그대로다.
- PC에서 시험: 실행 인자 `-- mobile` (마우스로 버튼을 누를 수 있다).
- **안드로이드 APK 만들기**: Godot 에디터 → 프로젝트 → 내보내기 → "Android" 프리셋 (`export_presets.cfg` 에 들어 있음).
  처음 한 번은 에디터 설정에 Android SDK 경로와 디버그 키스토어가 필요하다 (Godot 문서 '안드로이드로 내보내기').
- **웹(휴대폰 브라우저)으로 내보내기**: "Web" 프리셋. 스레드 지원은 꺼 두었다 (특별한 서버 설정 없이 돌아가게).

## 개발용 기능

- **개발자 모드**: 타이틀의 '개발자 모드'를 켜거나 `-- dev` 로 실행하면, 필드에서 F1(또는 `)로 개발자 메뉴가 열린다.
  방 이동, 챕터 건너뛰기, 아무 적과 전투, 무적·빠르게 걷기·벽 통과·정보 표시, 논리·감성 올리기, 모든 인증, 저장.
  **자유 이동**(기본 켜짐): 모든 층·옥상 계단과 인증으로 잠긴 문이 열리고, 계단은 이야기 없이 바로 위/아래층으로 간다.
  전투 중 F2 = 바로 살려 줄 수 있게, F3 = 적 HP 1. (scripts/ui/dev_menu.gd)

- 실행 인자 `-- room=forest_2` (또는 `room=f5_hall@from_math` 로 스폰까지) : 그 방에서 바로 시작 / `-- battle=owl` : 그 적과 바로 전투
  방 이름은 `data/rooms_*.gd`, 적 이름은 `scripts/battle/enemies.gd` 에 있다 (예: `battle=jut`, `battle=core`, `room=dorm_hall`)
  (에디터: 프로젝트 설정 → 에디터 → 실행 → 메인 실행 인자)
- `godot --headless -s tools/check_text.gd` : 너무 긴 대사, 줄 길이가 안 맞는 맵, 끊어진 문 연결 검사
- `python3 tools/make_music.py` : 음악 다시 생성 (numpy, ffmpeg 필요)
- 세이브 파일: Godot의 `user://save.json` (프로젝트 → 사용자 데이터 폴더 열기)

## 라이선스 / 출처

- 폰트 Galmuri11 © Lee Minseo — SIL Open Font License 1.1 (`assets/fonts/Galmuri-LICENSE-OFL.md`)
- 음악·효과음·그림은 이 프로젝트에서 코드로 만든 것
