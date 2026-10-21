# Crowd Gate Duel

같은 게이트를 고르면 뒤처진 쪽이 효과를 온전히 가져가는 세로 2D 봇 대전입니다. 제품 한국어명은 갈림길 군중 대전입니다.

Google Play에 무료 게임으로 먼저 출시하며 대상은 13세 이상, 언어는 영어와 한국어입니다. 게임은 오프라인으로 완결하고 계정, Firebase, 원격 기록과 인앱결제는 사용하지 않습니다. 일반 대국 결과 뒤에 준비된 AdMob 전면광고를 한 번 시도하며 닫힘 후 45초 간격을 둡니다. 공개 등록과 실제 SDK 검수 완료는 아직 별도입니다.

첫 실행은 시간제한 없는 필수 체험입니다. 직접 고르기, 서로 다른 칸, 두 방향의 겹침을 경험하고 두 이해 확인 문제를 풀어야 일반 대국을 시작합니다. 틀린 문제만 재시도하고 성공 단계는 저장합니다. 설정에서 다시 배울 수 있습니다.

기획 원장은 [docs/game-design](docs/game-design)이며 현재 제품 결정은 [DEC-018~020](docs/game-design/decision-log.md)입니다. 이번 구현과 출시 범위는 [승인 설계](docs/design/2026-10-21-offline-play-launch/design.md), 실행 상태는 [출시 기록](docs/google-play-release.md)을 따릅니다. 과거 Firebase와 원격 대전 문서는 해당 시점의 기록이며 현재 결정과 충돌하면 위 결정이 우선합니다.

```bash
scripts/test.sh                          # 정수 규칙, 저장, 튜토리얼과 광고 상태
scripts/validate_courses.sh --seeds 10000 # 생성 코스 전수 검증
scripts/lint.sh                          # import 및 컴파일, 오류 로그 검사
scripts/smoke.sh                         # 실제 시작 장면과 좌표 입력, 격리 저장
E2E_CAPTURE=1 scripts/smoke.sh            # 같은 여정 렌더링과 PNG
```

Godot은 build.env에서 버전을 읽습니다. 도메인 판정은 정수 연산과 Pcg32를 유지하고 상대 선택의 재생은 같은 판정 경로를 사용합니다. 테스트 도구는 기기를 조회하거나 조작하지 않습니다. 실제 UMP, AdMob과 Android 공유창 검수에는 후보와 최소 범위를 특정한 별도 기기 승인이 필요합니다.
