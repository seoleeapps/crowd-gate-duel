# UI 작업 산출물

`game-ui-design` 스킬의 방향 기록·기준 이미지·실행 비교 증거를 여기 둔다.
화면 계약은 `../03-ui-ux-spec.md`, 시각 기준은 `../04-art-audio-bible.md` 가 소유하고
이 폴더는 그 두 문서가 참조하는 산출물을 보관한다.

## 파일

| 파일 | 내용 | 상태 |
| --- | --- | --- |
| `duel-screen-layout-options.html` | 대국 화면(SCR-002) 공간 구성 3안. 브라우저로 바로 열 수 있다 | **사람 선택 전** |
| `duel-screen-layout-options.png` | 위 문서의 라이트 테마 렌더링 | |
| `duel-screen-layout-options-dark.png` | 다크 테마 렌더링 | |

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

## 다음 단계

1. 사람이 한 방향을 고른다. 선택과 근거를 이 문서에 기록한다
2. 선택한 안으로 `../03-ui-ux-spec.md` 의 SCR-002 레이아웃 구역을 다시 쓴다
3. 시각 방향(색·재질·서체) 시안으로 넘어가 `04` 의 A-1 게이트를 통과시킨다
4. Godot 구현 후 `runtime-review` 절차로 시안과 실행 화면을 비교한 증거를 여기 남긴다

아직 `04` 의 A-1(스타일 확정)은 통과하지 않았다. 이 폴더의 배치안은 **공간 구성만** 다루며
시각 방향은 정해지지 않았다.

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
