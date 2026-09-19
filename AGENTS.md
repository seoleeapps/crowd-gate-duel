# crowd-gate-duel — 에이전트 작업 규칙

갈림길 군중 대전. Godot 4.7 + Firebase, 세로 2D, 멀티마켓(Google Play / App Store / AppsInToss).

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
```

Godot 헤드리스는 **스크립트 오류가 있어도 종료 코드 0 을 낼 수 있다.** 위 진입점은 로그의
`SCRIPT ERROR` 와 `ERROR:` 를 함께 검사한다. 직접 `godot` 을 호출해 결과를 판단하지 않는다.

코스 생성 검증 기준은 "전략 균등"이 아니라 **읽기의 보상·선택의 의미·겹침 발동**이다(DEC-014).
전략 승률 행렬은 참고 지표이며 합격 판정에 쓰지 않는다.

## CI

- 워크플로 `Godot Compile`, job 이름도 `Godot Compile`, `runs-on: seorilabs-x64`
- 버전은 `build.env` 가 유일한 선언이다. 엔진을 올릴 때 이 파일만 바꾼다
- 러너·액션 버전 작업은 `seorilabs-arc-runners` 스킬과
  `/Users/syous/Workspace/kubectl/github-actions-runners/global-versions.yaml` 을 따른다
- **push 는 SSH remote 를 쓴다.** HTTPS OAuth 토큰에는 `workflow` 스코프가 없어
  워크플로 파일 변경이 거부된다

## 멈춰야 하는 지점

- 마켓 등록, 스토어 제출, 프로덕션 배포는 별도 배포 승인이 필요하다
- 열린 결정(DEC-001 수익화, DEC-002 제품명, DEC-005 연령 등급)을 대신 정하지 않는다
- 제품명은 아직 없다. `crowd-gate-duel` 과 "갈림길 군중 대전"은 작업명이며 스토어 표시명이 아니다

## 현재 범위

제작 계획 1~2주차(규칙 코어, 생성기·검증기)까지 구현됐다. 다음은 3주차 대국 화면이며,
UI 작업은 `game-ui-design` 스킬의 시안 선택(A-1)을 먼저 통과해야 한다.
