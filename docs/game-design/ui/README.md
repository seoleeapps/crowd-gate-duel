# UI 작업 산출물

`game-ui-design` 스킬의 방향 기록·기준 이미지·실행 비교 증거를 여기 둔다.
화면 계약은 `../03-ui-ux-spec.md`, 시각 기준은 `../04-art-audio-bible.md` 가 소유하고
이 폴더는 그 두 문서가 참조하는 산출물을 보관한다.

## 파일

| 파일 | 내용 | 상태 |
| --- | --- | --- |
| `duel-screen-layout-options.html` | 대국 화면(SCR-002) 공간 구성 3안. 브라우저로 바로 열 수 있다 | **B안 선택 (A-0 통과)** |
| `duel-screen-layout-options.png` | 위 문서의 라이트 테마 렌더링 | |
| `duel-screen-layout-options-dark.png` | 다크 테마 렌더링 | |
| `duel-screen-style-options.html` | B안 배치 위의 시각 방향 3안(A-1). 동수·봇 상대 보조 장면 포함 | **1안 "한낮 장터" 선택 (A-1 통과)** |
| `duel-screen-style-options.png` | 위 문서의 라이트 테마 렌더링 | |
| `duel-style-a.png` `duel-style-b.png` `duel-style-c.png` | 방향별 대국 화면 단독 렌더링, 1080×2340. **`duel-style-a.png` 가 기준 시안이다** | |
| `runtime/` | Godot 실행 화면 캡처. 아래 "실행 비교" 참조 | |

## 배치안이 푸는 문제

겹침 규칙이 대칭 반감에서 **뒤처진 쪽 우선권**으로 바뀌면서(DEC-012) 화면에 요구가 하나 늘었다.

앞서 있으면 상대가 고를 칸을 **피해야** 하고 뒤처져 있으면 **노려야** 한다. 매 구간 정답이
순위에 따라 뒤집히는데 확약 시간이 3초뿐이다. 그래서 화면은 **수치를 비교하기 전에** 순위를
알려줘야 한다. 세 안의 진짜 차이는 그 정보를 어디에 싣느냐다.

| 안 | 순위를 읽는 방법 | 핵심 트레이드오프 |
| --- | --- | --- |
| A 나란한 두 레인 | 무리 크기 차이 | 대칭이라 공정해 보이지만 격차가 작으면 3초 안에 판단이 어렵다 |
| B 하나의 언덕길 | 트랙 위 위치 | 숫자 전에 순위를 안다. 판타지와 일치. 로그 스케일 매핑이 필요하다 |
| C 내 무리 중심 | 전용 저울 | 오해가 없고 성장 쾌감이 크다. 상대가 작아 대전 실감이 약하다 |

세 안 모두 같은 순간(4구간, 내 44 대 상대 31, 확약 2.1초)을 그렸고 수치와 문구는 실제 규칙에서
가져왔다. 색은 진영 구분에만 쓰고 게이트 종류는 모양으로 구분한다.

## 선택 기록

| 게이트 | 선택 | 날짜 | 근거 |
| --- | --- | --- | --- |
| A-0 배치 | **B안 하나의 언덕길** | 2026-09-29 | 사용자 선택. 순위를 숫자보다 먼저 높이로 읽히게 하는 것이 대국 화면의 첫 요구이고, 정상을 향한 행렬이라는 판타지와 결승 충돌 장면이 같은 공간에서 이어진다 |
| A-1 시각 방향 | **1안 한낮 장터** (`duel-style-a.png`) | 2026-09-29 | 사용자 선택. 아트 바이블의 축제 행렬·플랫 카툰·얇은 외곽선에 가장 가깝고, 무리 높이마다 그은 점선이 격차가 작을 때의 순위 판단을 돕는다. 결과 카드와 스토어 이미지가 밝게 나온다 |

### 선택한 방향의 규칙

- 색: 진영색 둘(나 `#ec7a2c` / 표식 `#a84a0c`, 상대 `#1e9c90` / 표식 `#0c6b62`)과 베이지 중립색. 토큰은 `game/src/presentation/theme/palette.gd`
- 서체: 숫자는 Fredoka, 글은 Noto Sans KR. 둘 다 OFL 1.1 이며 `game/assets/fonts` 에 라이선스 원문을 둔다
- 형태: 인형·깃발·게이트 아이콘은 시안의 SVG 도형을 그대로 옮긴 벡터 에셋(`game/assets/art/*.svg`)이다. 이미지 생성기를 쓰지 않았다. 생성 이미지는 시안과 모양이 어긋날 수 있어서다
- 재질: 캐릭터와 UI 는 단색과 얇은 잉크 외곽선. 그라디언트는 하늘에만 쓴다
- 순위 보조: 무리 발끝 높이마다 진영색 가로 점선. 동수면 회색 점선 하나와 "= 동수" 중립 표식
- 모션: 게이트 띠가 위에서 내려오고, 확약하면 칸에 자물쇠, 공개하면 칸이 뒤집히며 나·상대 표식이 붙는다

## 실행 비교

`game/tools/capture_screens.gd` 가 실제 렌더러(Compatibility, Apple M3)로 화면을 그려 `runtime/<크기>-<언어>/` 에 남긴다.
대국 장면은 고정 픽스처다. 시안과 같은 순간(4/7, 나 44 대 상대 31, 확약 2.1초)을 실제 판정으로 만든다.
viewport 캡처이며 실기기 확인이 아니다.

| 화면·상태 | 목표 시안 | 실행 캡처 | 발견한 차이와 수정 | 판정 |
| --- | --- | --- | --- | --- |
| 대국 4/7 · 44:31 | `duel-style-a.png` | `runtime/1080x2340-ko/duel-commit.png` | 깃발이 인형 뒤에 가려짐 → 깃발을 인형 위 층으로 옮김 | 통과 |
| 동수 12:12 | 시안 보조 장면(동수) | `runtime/1080x2340-ko/duel-tie.png` | 두 무리가 길 방향으로 벌어져 높이가 달라 보이고 표식이 겹침 → 수평으로 벌려 같은 높이에 나란히 세움 | 통과 |
| 봇 상대 | 시안 보조 장면(봇) | `runtime/1080x2340-ko/duel-bot.png`, `runtime/1080x2340-en/duel-bot.png` | 차이 없음. 무채색 막대 깃발과 로봇 아이콘·"봇" 배지 | 통과 |
| 온보딩 1구간 손 안내 | 시안 없음(같은 방향 파생) | `runtime/1080x2340-ko/onboarding-hand.png` | 손이 수치 "+4" 를 가림 → 칸 오른쪽 아래로 옮김 | 통과 |
| 온보딩 2구간 양보 사건 | 시안 없음(같은 방향 파생) | `runtime/1080x2340-ko/onboarding-yield.png` | 차이 없음. 한 칸에 나(오르막 표식)·연습 표식이 나란히 붙는다 | 통과 |
| 결과 | 시안 없음(같은 방향 파생) | `runtime/1080x2340-ko/result.png`, `runtime/1080x2340-en/result.png` | 충돌 장면이 뭉개지고 리본이 함께 찍힘 → 정상 아래에서 좌우로 만나게 하고 리본을 잘라 냄 | 통과 |
| 홈 | 시안 없음(같은 방향 파생) | `runtime/1080x2340-ko/home.png`, `runtime/1080x2340-en/home.png` | 차이 없음 | 통과 |
| 짧은 화면 1080×1620 | 같은 기준 | `runtime/1080x1620-ko/duel-commit.png`, `runtime/1080x1620-ko/result.png` | 결승선이 리본과 겹침 → 언덕길을 리본 아래에서 시작. 결과 버튼이 화면 밖으로 밀림 → 장면이 남는 공간만 쓰게 함. 선두 무리 표식이 결승선 깃발과 일부 겹치는 것은 남아 있다 | 부분 통과 |
| 꾸미기 적용 대국(별 깃발·산호색) + 색각 보조 무늬 | `duel-style-a.png` | `runtime/1080x2340-ko/duel-styled.png` | 차이 없음. 게이트 칸 바탕에 종류별 무늬(사선·점·가로줄·격자)가 더해진다 | 통과 |
| 꾸미기(SCR-005) | 시안 없음(같은 방향 파생) | `runtime/1080x2340-ko/profile.png`, `runtime/1080x2340-en/profile.png` | 잠긴 항목은 흐린 미리보기와 깃털 가격, 장착 중은 굵은 진영색 테두리 | 통과 |
| 설정(SCR-006) | 시안 없음(같은 방향 파생) | `runtime/1080x2340-ko/settings.png`, `runtime/1080x2340-en/settings.png` | 기본 스위치가 방향과 달라 같은 문법의 스위치를 그림. 켜짐은 색 + 체크 + 손잡이 위치로 구분 | 통과 |
| 태블릿 1620×2160 (3:4) | 같은 기준 | `runtime/1620x2160-ko/duel-commit.png`, `runtime/1620x2160-ko/home.png` | 폭을 9:16 으로 제한하고 좌우를 배경색으로 채움. 게이트 칸은 커지지 않는다 | 통과 |
| 색각 시뮬레이션 3종(A-3) | 같은 기준 | `runtime/colorblind/duel-commit.png`, `runtime/colorblind/duel-styled.png` (원본·적색맹·녹색맹·청색맹) | 두 진영은 밝기 차이와 깃발 무늬·"나/상대" 글자로, 게이트 4종은 아이콘 모양으로 구분된다. 보조 무늬를 켜면 칸 바탕 무늬가 더해진다 | 통과(시뮬레이션) |
| 긴 화면 1080×2520 | 같은 기준 | `runtime/1080x2520-ko/duel-commit.png` | 차이 없음. 언덕길만 늘고 게이트 띠 높이는 같다 | 통과 |

### 실기기 확인

| 기기 | 빌드 | 확인한 것 | 증거 |
| --- | --- | --- | --- |
| Seeker (Android, 1200×2670) | `scripts/build.sh --debug` 디버그 APK, 2026-09-29 | 설치·실행, 온보딩 1구간 손 안내, 2구간 양보 사건(나 32 : 연습 18, 한 칸에 두 표식), 3구간 진행. adb 탭으로 조작 | `device/seeker-onboarding-1.png`, `device/seeker-onboarding-2-yield.png`, `device/seeker-onboarding-3.png` |

실기기에서 찾은 차이: 증가 입자가 무리가 옮겨 가기 전 자리에서 튀어 상대 무리 근처에 보였다 → 입자를 무리에 붙여 함께 움직이게 고쳤다.
실기기에서 아직 보지 않은 것: 손가락 직접 조작 감각, 햅틱 세기, 소리 크기, 프레임 측정, 일반 대국 전체.

자동 검사: 터치 대상 48dp·게이트 칸 96dp(`scripts/smoke.sh` 가 지나가는 모든 화면), 글자 명암비 4.5:1(`tests/test_contrast.gd`).

음악·효과음 청취 확인(A-5): 2026-09-30 사용자 통과.

미검증: 실기기 터치·햅틱, 스크린리더 낭독. 색각은 시뮬레이션이며 실사용자 확인이 아니다.

## 재생성

```bash
# PNG 갱신 (공용 Playwright 사용)
~/.local/share/seorilabs/playwright/venv/bin/python - <<'PY'
from playwright.sync_api import sync_playwright
import pathlib
src = pathlib.Path("docs/game-design/ui/duel-screen-layout-options.html").resolve()
with sync_playwright() as pw:
    b = pw.chromium.launch()
    for scheme, name in (("light", "duel-screen-layout-options.png"),
                         ("dark", "duel-screen-layout-options-dark.png")):
        pg = b.new_page(viewport={"width": 1240, "height": 900},
                        device_scale_factor=2, color_scheme=scheme)
        pg.goto(src.as_uri()); pg.wait_for_timeout(1200)
        pg.screenshot(path=str(pathlib.Path("docs/game-design/ui") / name), full_page=True)
        pg.close()
    b.close()
PY
```

시각 방향 시안은 `?solo=a` 처럼 열면 해당 방향의 폰 화면만 보인다. 단독 PNG 는 이 화면을 찍는다.

```bash
~/.local/share/seorilabs/playwright/venv/bin/python - <<'PY'
from playwright.sync_api import sync_playwright
import pathlib
root = pathlib.Path("docs/game-design/ui")
src = (root / "duel-screen-style-options.html").resolve()
with sync_playwright() as pw:
    b = pw.chromium.launch()
    pg = b.new_page(viewport={"width": 1240, "height": 900}, device_scale_factor=2, color_scheme="light")
    pg.goto(src.as_uri()); pg.wait_for_timeout(1500)
    pg.screenshot(path=str(root / "duel-screen-style-options.png"), full_page=True)
    pg.close()
    for k in "abc":
        pg = b.new_page(viewport={"width": 360, "height": 780}, device_scale_factor=3)
        pg.goto(src.as_uri() + "?solo=" + k); pg.wait_for_timeout(1200)
        pg.locator(f'.screen[data-dir="{k}"]').screenshot(path=str(root / f"duel-style-{k}.png"))
        pg.close()
    b.close()
PY
```
