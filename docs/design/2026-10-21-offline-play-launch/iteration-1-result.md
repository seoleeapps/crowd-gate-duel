# 독립 기능 및 화면 검수 1회 결과

실행한 단위 테스트와 headless, 한국어 긴 화면 여정은 통과했다. 화면 결함 3건과 캡처 근거 부족 1건이 남아 UI 완료로 판정하지 않는다. 영어 짧은 화면은 첫 화면의 일시정지 상태에서 진행하지 못해 미완료로 보존했다. 같은 회차 안에서 반복 실행하거나 코드를 고치지 않았다.

## 실행과 근거

- 계획: [iteration-1.md](iteration-1.md), [design.md](design.md), [test-plan.json](test-plan.json).
- 후보: `1077635b5a69f0e9669ff958ecb983adc71dec79`. 구현자 root와 다른 검수 에이전트 `/root/ui_review`가 실행했다.
- 시각: 2026-10-21 00:51:28부터 00:56 KST까지. 실행 환경은 macOS, Apple M3, Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility, OpenGL 4.1 Metal이다.
- 저장: `user://e2e/review-1-headless/`, `user://e2e/review-1-ko/`, `user://e2e/review-1-en/`만 사용했다. 일반 사용자 저장을 읽거나 초기화하지 않았다.
- 시작 시 `game/default_bus_layout.tres`는 이미 수정 상태였다. 실행 중 작성자가 바꾼 Android 빌드 설정과 네이티브 파일은 이 검수에서 실행하지 않았다. 검수자는 게임 코드, 테스트, 자산을 수정하지 않았다.
- 중앙 정본은 `seorilabs/.github` 원격 main `37447a7ed225d957b75ceb24cc8f2331f236a0d8`과 일치하는 로컬 계약 및 실행 문서를 읽었다. 대상 저장소의 원격 기본 브랜치도 읽기 전용으로 확인했다.

모든 E2E 명령에 `GITHUB_SHA=1077635b5a69f0e9669ff958ecb983adc71dec79`를 전달했다. 아래 경로는 저장소 루트 기준이다.

| 실행 | 명령과 raw 근거 | 결과 |
|---|---|---|
| 전체 단위 테스트 | `scripts/test.sh`, `build/review-1/test.log` | 253 passed, 0 failed, ALL GREEN. 광고 17건, 저장 58건, 대국 44건 포함 |
| headless 실제 입력 여정 | `E2E_RUN_ID=review-1-headless E2E_OUT=$PWD/build/review-1/headless scripts/smoke.sh`, `build/review-1/headless.log`, `build/review-1/headless/{import.log,run.log,journey.json}` | 시나리오 3개, 단계 50개, 기능 ID 7개 통과. sourceSha 일치 |
| 한국어 1080×2340 렌더링 | `E2E_CAPTURE=1 E2E_LOCALE=ko E2E_SIZE=1080x2340 E2E_RUN_ID=review-1-ko E2E_OUT=$PWD/build/review-1/ko scripts/smoke.sh`, `build/review-1/ko.log`, `build/review-1/ko/{import.log,run.log,journey.json}` | 시나리오 3개와 50개 단계 통과. PNG 11개를 원본으로 직접 열람. sourceSha 일치 |
| 영어 1080×1620 렌더링 | `E2E_CAPTURE=1 E2E_LOCALE=en E2E_SIZE=1080x1620 E2E_RUN_ID=review-1-en E2E_OUT=$PWD/build/review-1/en scripts/smoke.sh`, `build/review-1/en.log`, `build/review-1/en/{import.log,run.log,journey.json,01-tutorial-pick.png}` | 미완료. `mandatory-tutorial` running, 무입력 확인 2개 단계만 기록. 작성자 지시에 따라 이 실행의 Godot PID 42331만 경로 대조 후 종료, exit 143 |

진행 중인 영어 `journey.json`에는 완료 sourceSha가 없으며 통과 근거로 쓰지 않는다. 지정 스크립트의 Godot 오류 로그 검사와 커버리지 검사 결과를 확인했다. 이전 계획에 적힌 258건이 아닌 현재 테스트 집계 253건을 그대로 기록했다.

직접 본 한국어 원본은 `build/review-1/ko/01-tutorial-pick.png`, `02-quiz-mistake.png`, `03-tutorial-result.png`, `04-home.png`, `05-normal-result.png`, `06-cosmetics.png`, `07-settings.png`, `normal-gate-1.png`부터 `normal-gate-4.png`까지다. 승인 기준 `docs/game-design/ui/duel-style-a.png`도 열어 색, 서체, 군중과 게이트 모양을 비교했다. 한낮 장터 방향은 유지돼 있다.

공유 버튼 입력 뒤 `/Users/syous/Library/Application Support/Godot/app_userdata/Crowd Gate Duel/e2e/review-1-ko/share/result-1792511530.png`가 실제 저장됐으며 원본을 직접 열었다. 이것은 개발 환경의 로컬 PNG 저장 근거다. Android 공유창 실행 근거가 아니다.

## 기능과 화면 관찰

| 항목 | 실제 관찰과 근거 | 기능 및 UX 판정 |
|---|---|---|
| 필수 튜토리얼 | 무입력 뒤 선택 0건, 완료 false. 단계 2 저장 뒤 장면 재생성 시 2에서 복원. 5단계 오답 뒤 저장 단계 4 유지. 두 이해 확인 정답 입력 뒤 완료 | 실행한 기능 통과. 오답 이유와 숫자의 화면 근거는 아래 R1-04로 부족 |
| 완료 보상 | 최초 완료 깃털 30, 튜토리얼 전적 0판. 설정에서 재학습 뒤 깃털 33 유지 | 보상 중복 방지 통과. 구버전 완료 기록 마이그레이션은 단위 테스트 범위이며 별도 UI fixture는 없음 |
| 일반 봇 대국 | 실제 좌표 입력, 봇 배지, 선택 1건 저장 후 같은 seed와 선택 수 복원, 완료 전적 1판, 진행 저장 제거 | 실행한 입문 난이도 흐름 통과. 고난도 해금과 각 난이도 화면은 이번 여정에서 미검수 |
| 광고 | 17개 단위 테스트에서 동의, 첫 일반 판, 중복 시도, 중복 닫힘 및 실패, 미준비, 늦은 로드와 44,999ms/45,000ms 경계 통과. 실제 화면 여정에서는 개발 광고 포트가 미준비이므로 결과 버튼이 다시 활성화됨 | 정책 단위 테스트와 미준비 결과 복귀 통과. 실제 광고 표시 및 닫힘, UMP와 개인정보 선택 창은 미실행 |
| 꾸미기 | 해금된 다이아 깃발을 실제 카드 탭으로 장착, 저장 값 `flag_diamond` 확인. 잠긴 항목 가격과 장착 상태가 읽힘 | 실행한 장착 기능 통과. 목록을 끝까지 드래그하거나 깃털로 해금하는 확인창을 검수하지는 않음 |
| 설정 | 효과음 스위치 입력이 런타임에 반영. 규칙 다시 배우기 입력과 완료 후 홈 복원 통과. 한국어 긴 화면의 버튼과 설명은 읽힘 | 실행한 기능 통과. 오프라인 전용과 맞지 않는 설명 R1-03 존재 |
| 결과와 공유 | 실제 승패, 보상, 결과 저장, 홈 복귀. headless는 공유 실패 후 복귀, 렌더링은 실제 PNG 저장 후 복귀 | 실행한 경계 기능 통과. 결과 장면 및 공유 이미지 잘림 R1-02 존재 |
| 홈과 일반 대국 가독성 | 한국어 긴 화면에서 홈 버튼, 꾸미기와 설정, 수치, 게이트, 봇 표시, 타이머가 읽힘. 버튼과 자막이 겹친 증거는 없음 | 열람한 상태에 한해 통과. 영어 및 짧은 화면 전체, 태블릿은 통과로 확대하지 않음 |
| 첫 빼앗기와 방패 안내 | 여정의 band 1 코스에는 특수 게이트가 등장하지 않음. `special-gate-lesson.png`도 생성되지 않음 | 타이머 정지, 예시와 확인 후 재개는 미검수. 기능 ID 커버리지 통과로 대체하지 않음 |

## 발견한 문제

| ID와 우선순위 | 위치와 재현 근거 | 사용자 영향 | 수정 제안과 판정 |
|---|---|---|---|
| R1-01, P2 | `build/review-1/ko/02-quiz-mistake.png`의 5/6 오답 결과에서 왼쪽 ×1.5 칸에 ‘연습’ 표식이 두 개 붙음. `game/src/presentation/duel/gate_band.gd:133`의 preview_opponent와 `game/src/presentation/duel/gate_cell.gd:108`의 reveal이 같은 marker 컨테이너에 누적 | 상대 선택 하나가 두 표식으로 보이고, 겹침 결과를 가르치는 장면의 뜻이 흐려짐 | 예고 표식을 결과 표식으로 교체하거나 reveal 전에 기존 표식을 제거. 예고는 상대 하나, 해소는 플레이어당 하나임을 확인. UX 실패 |
| R1-02, P2 | `ko/03-tutorial-result.png`의 상단 장면에서 상대 수치와 군중이 오른쪽으로 잘림. `ko/05-normal-result.png`에는 pause 버튼 테두리 일부가 남음. 실제 저장한 공유 PNG도 상단 ‘나 87’, ‘봇 114’ 칩의 윗부분이 잘림. `game/src/presentation/result/result_screen.gd:81`과 `:100`, `game/src/presentation/result/share_card.gd`의 장면 자르기와 KEEP_ASPECT_COVERED 경로 | 승패의 근거 장면을 일부 읽지 못하고 공유 이미지에도 잘린 UI가 들어감. 별도 최종 점수 행은 읽힘 | HUD를 제외한 충돌 장면을 별도 캡처하거나 장면 프레임 비율을 유지해 두 군중과 수치가 모두 들어오게 배치. 긴 화면 튜토리얼 결과와 정사각 공유 원본을 함께 재확인. UX 실패 |
| R1-03, P2 | `ko/07-settings.png`의 고르는 시간 1.5배 설명 ‘켜면 같은 설정으로 둔 기록과 맞붙어요.’. `game/i18n/ko.po:169`, `game/i18n/en.po:169`의 SET_COMMIT_EXT_DESC에 기록 매칭 설명 유지 | 오프라인 봇 전용 제품에서 원격 이용자 기록과 매칭하는 것으로 오해할 수 있음 | 실제 봇 대국의 시간 연장 동작을 설명하는 문구로 영어와 한국어 모두 교체. UX 실패 |
| R1-04, 검수 근거 부족 | `ko/02-quiz-mistake.png`는 `_captions._waiting` 직후 fade-in 중 캡처돼 설명과 전후 숫자가 거의 투명함. `game/tools/e2e/journey.gd`의 오답 캡처가 애니메이션 완료를 기다리지 않음. 이해 확인 두 문제의 선택 전 예고 화면과 첫 4단계의 결과 화면도 원본 PNG에 없음 | 실제로 설명이 안 보이는 제품 결함인지 단정할 수 없고, 요구한 예고와 오답 이유·실제 전후 숫자의 가독성을 이 증거만으로 검수할 수 없음 | 다음 회차에는 실제 입력을 유지하면서 자막 fade 완료 뒤 캡처하고 5/6 및 6/6 선택 전 예고, 오답 결과, 같은 문제 재시도 화면을 남김. 해당 UX 인수조건 미확인 |

영어 짧은 화면의 첫 PNG는 `Paused`와 `Resume`이 떠 있는 상태다. 단일 시작 장면 안에서 현재 여정이 `pause_when_backgrounded=false`를 지정하기 전에 포커스 이탈 알림이 들어와 일시정지했을 가능성이 있다. 같은 데스크톱에서 다른 저장소의 Godot 렌더링이 실행 중인 것도 관찰했으나 정확한 포커스 전환 이벤트를 수집하지 않았으므로 원인은 추정이다. 다른 작업 프로세스나 창을 조작하지 않았다. 이 실행만 종료했고 재시도하지 않았다. 다음 회차에서는 장면을 붙이기 전에 테스트용 OS 포커스 경계를 주입해 재검수할 필요가 있다.

## 남은 확인

이번 회차는 사람의 이해도나 이탈률 검증이 아니다. Android와 iOS 기기의 조회, 설치, 실행, 화면 또는 로그 수집은 전혀 하지 않았다. 네이티브 UMP, 실제 광고 표시와 닫힘, Android 공유창은 미실행이다. 영어 짧은 화면 전체, 태블릿, 첫 특수 게이트 안내, 안정된 튜토리얼 예고 및 오답 결과 캡처가 남아 있다. 코드 수정과 다음 회차 재확인 결과는 이 원래 판정을 덮어쓰지 않고 별도 회차 기록에 남겨야 한다.
