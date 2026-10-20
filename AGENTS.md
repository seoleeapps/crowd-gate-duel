# crowd-gate-duel — 에이전트 작업 규칙

갈림길 군중 대전. Godot 4.7, 오프라인 봇 대전, 세로 2D, 멀티마켓(Google Play / App Store / AppsInToss).

## 반드시 먼저 읽을 것

1. 상위 `~/.claude/CLAUDE.md` 또는 `~/.codex/AGENTS.md` 의 공통 규칙
2. `docs/game-design/` — **기획 원장이다.** 구현은 이 계약을 따른다
3. `docs/game-design/decision-log.md` — 닫힌 결정을 되돌리지 않는다. 특히 DEC-012~014

## 깨뜨리면 안 되는 계약

이 네 가지는 제품의 성립 조건이다. 바꾸려면 `decision-log.md` 에 근거와 함께 새 DEC 를 올린다.

- **`game/src/domain` 은 순수하다.** Godot 노드, 플랫폼 SDK, Firebase, 광고 SDK 를 import 하지
  않는다. 대국 진행과 리플레이 재생이 같은 판정 코드를 쓰기 때문이며, 갈라지면 재현이 깨진다
- **판정에 부동소수점을 쓰지 않는다.** 전부 정수 연산이다
- **난수는 `Pcg32` 뿐이다.** 외부 시드는 반드시 해싱해서 넣는다(DEC-006).
  `randi()`, `randf()`, Godot 기본 `RandomNumberGenerator` 를 규칙 경로에 쓰지 않는다
- **상대 기록에 결과를 저장하지 않는다.** 선택 시퀀스만 담고 결과는 재생 시 다시 계산한다(DEC-009)

## 겹침 규칙을 바꾸려 할 때

같은 게이트를 고르면 **뒤처진 쪽이 온전히 가져간다.** 이것을 "양쪽 반감"으로 되돌리려는
시도가 있다면 멈춰야 한다. 대칭 반감은 겹쳐도 격차를 바꾸지 않아 "늘 가장 센 칸"이 수학적
지배 전략이 되고, 실측에서 그 전략의 승률이 87~93% 였다. 근거는 DEC-012 에 있다.

## 검증

```bash
scripts/test.sh                          # 도메인 테스트 전부
scripts/validate_courses.sh --seeds 10000  # 생성기 전수 검증 (AC-002)
scripts/strategy_matrix.sh --courses 40    # 전략 승률 참고 지표
scripts/lint.sh                          # 임포트 + 컴파일
scripts/smoke.sh                         # 앱 흐름 스모크 (사용자 저장과 분리된 경로)
```

Godot 헤드리스는 **스크립트 오류가 있어도 종료 코드 0 을 낼 수 있다.** 위 진입점은 로그의
`SCRIPT ERROR` 와 `ERROR:` 를 함께 검사한다. 직접 `godot` 을 호출해 결과를 판단하지 않는다.

코스 생성 검증 기준은 "전략 균등"이 아니라 **읽기의 보상·선택의 의미·겹침 발동**이다(DEC-014).
전략 승률 행렬은 참고 지표이며 합격 판정에 쓰지 않는다.

## CI

- 워크플로 `Godot Compile`, job 이름도 `Godot Compile`, 공개 저장소의 `runs-on: ubuntu-latest`
- 버전은 `build.env` 가 유일한 선언이다. 엔진을 올릴 때 이 파일만 바꾼다
- 러너·액션 버전 작업은 `seorilabs-arc-runners` 스킬과
  `/Users/syous/Workspace/kubectl/github-actions-runners/global-versions.yaml` 을 따른다
- **push 는 SSH remote 를 쓴다.** HTTPS OAuth 토큰에는 `workflow` 스코프가 없어
  워크플로 파일 변경이 거부된다

## 출시 기준

2026-10-21 승인된 DEC-018~020이 과거 열린 제품 결정과 원격 대전 계약보다 우선한다. 제품명과 13세 이상, 무료 전면광고, Google Play 공개가 확정됐다. 계정과 기기 검수, 심사 및 공개는 각각 실제 근거로 확인한다.

## 멈춰야 하는 지점

- 마켓 등록, 스토어 제출, 프로덕션 배포는 별도 배포 승인이 필요하다
- 승인된 DEC-018~020 밖의 수익화, 마켓 확장과 제품 결정을 대신 정하지 않는다
- 제품명은 `Crowd Gate Duel`, 한국어명은 "갈림길 군중 대전"이다

## 현재 범위

제작 계획 1~5주차(규칙 코어, 생성기·검증기, 대국 화면, 기록·재생, 온보딩·결과·홈)가 구현됐다.
A-0 은 B안 "하나의 언덕길", A-1 은 1안 "한낮 장터"로 통과했다(`docs/game-design/ui/README.md`).
새 화면과 구성요소는 이 방향과 `presentation/theme` 토큰을 재사용한다.
꾸미기(SCR-005)·설정(SCR-006)·소리·햅틱과 6주차 다듬기(태블릿 폭 제한, 터치 대상·명암비 자동 검사,
성능 측정, 색각 시뮬레이션)까지 들어갔다. Google Play 첫 출시는 오프라인 봇과 전면광고로 완결한다. Firebase와 결제는 포함하지 않는다. 네이티브 검수는 별도 승인 뒤에 수행한다.
효과음은 `scripts/make_sfx.py` 로 만들고, 음악 생성 원본(`game/assets/audio/raw/`)은 커밋하지 않는다.
