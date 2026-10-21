# 독립 기능 및 화면 검수 2회 결과

단위 테스트 253건과 headless, 영어 짧은 화면, 한국어 긴 화면, 영어 태블릿의 실제 입력 여정이 모두 통과했다. 1회차 중복 표식과 설정 설명, 캡처 부족은 수정 확인했다. 결과 장면의 수치 칩 겹침과 짧은 화면의 자막, 홈, 꾸미기 배치가 남아 UI 완료로 판정하지 않는다. [1회차 원래 판정](iteration-1-result.md)은 변경하지 않았다.

## 실행과 근거

- 사전 계획: [iteration-2.md](iteration-2.md). 승인 범위와 테스트 등급은 [design.md](design.md), [test-plan.json](test-plan.json)을 따랐다.
- 후보: `44ff4de8ecea86c7f5e1b7c1a7b31f4ea1db7795`. 구현자 root와 다른 검수자 `/root/ui_review`가 실행했다.
- 실행 시각: 2026-10-21 01:01부터 01:05 KST까지. macOS, Apple M3, Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility, OpenGL 4.1 Metal.
- 격리 데이터: `user://e2e/review-2-headless/`, `review-2-en-short/`, `review-2-ko-long/`, `review-2-en-tablet/`. 기본 사용자 저장과 기기에는 접근하지 않았다.
- 검수자는 코드, 테스트와 자산을 수정하지 않았다. 시작 시 `game/default_bus_layout.tres`가 이미 수정 상태였고 작성자가 준비 중인 출시 파일도 untracked였다. 이번 실행에서 네이티브 빌드와 출시 스크립트는 실행하지 않았다.
- 첫 단위 테스트 import와 headless import 시작이 잠시 겹쳤으나 오류 없이 각각 종료됐다. 이후 렌더링 3종은 순차 실행했다. 이 프로젝트의 다른 Godot 프로세스나 다른 작업을 조작하지 않았다. 회차 내 반복 실행은 하지 않았다.

아래 경로는 저장소 루트 기준이다. 모든 smoke 명령에 `GITHUB_SHA=44ff4de8ecea86c7f5e1b7c1a7b31f4ea1db7795`를 전달했고, 완료된 `journey.json` 네 개의 sourceSha가 일치했다.

| 실행 | 명령의 환경 변수 | raw 근거와 결과 |
|---|---|---|
| `scripts/test.sh` | 별도 설정 없음 | `build/review-2/test.log`, 253 passed, 0 failed, ALL GREEN |
| `scripts/smoke.sh` | `E2E_RUN_ID=review-2-headless E2E_OUT=$PWD/build/review-2/headless` | `build/review-2/headless.log`, `headless/import.log`, `headless/run.log`, `headless/journey.json`. 4개 시나리오, 69개 단계, 기능 ID 7개 통과 |
| `scripts/smoke.sh` | `E2E_CAPTURE=1 E2E_LOCALE=en E2E_SIZE=1080x1620 E2E_RUN_ID=review-2-en-short E2E_OUT=$PWD/build/review-2/en-short` | `build/review-2/en-short.log`, `en-short/{import.log,run.log,journey.json}`. 4개 시나리오와 69개 단계 통과, PNG 20개 생성 |
| `scripts/smoke.sh` | `E2E_CAPTURE=1 E2E_LOCALE=ko E2E_SIZE=1080x2520 E2E_RUN_ID=review-2-ko-long E2E_OUT=$PWD/build/review-2/ko-long` | `build/review-2/ko-long.log`, `ko-long/{import.log,run.log,journey.json}`. 4개 시나리오와 69개 단계 통과, PNG 20개 생성 |
| `scripts/smoke.sh` | `E2E_CAPTURE=1 E2E_LOCALE=en E2E_SIZE=1620x2160 E2E_RUN_ID=review-2-en-tablet E2E_OUT=$PWD/build/review-2/en-tablet` | `build/review-2/en-tablet.log`, `en-tablet/{import.log,run.log,journey.json}`. 4개 시나리오와 69개 단계 통과, PNG 20개 생성 |

실제 열람한 주요 원본은 세 렌더링 폴더의 `quiz-preview-4.png`, `quiz-preview-5.png`, `02-quiz-mistake.png`, `03-tutorial-result.png`, `04-home.png`, `05-normal-result.png`, `06-cosmetics.png`, `07-settings.png`, `lesson-steal.png`, `lesson-shield.png`다. 추가로 영어 짧은 화면의 `01-tutorial-pick.png`, `normal-gate-0.png`, `normal-gate-4.png`, `normal-gate-8.png`, 한국어 긴 화면의 `normal-gate-0.png`, `normal-gate-4.png`, `normal-gate-8.png`, 태블릿의 `normal-gate-8.png`를 직접 열었다. 생성된 파일 수를 모두 열람한 것으로 표현하지 않는다.

로컬 공유 PNG도 각 실행의 지정 E2E 저장 폴더에서 직접 열었다. 경로 기준은 `/Users/syous/Library/Application Support/Godot/app_userdata/Crowd Gate Duel/e2e/`이며 파일은 `review-2-en-short/share/result-1792512139.png`, `review-2-ko-long/share/result-1792512169.png`, `review-2-en-tablet/share/result-1792512211.png`다. 외부 공유와 Android 공유창은 실행하지 않았다.

## 기능과 이전 지적 재확인

| 항목 | 관찰 | 판정 |
|---|---|---|
| 무입력, 오답과 이해 확인 | 무입력 선택 0건과 미완료, 단계 2 저장 후 재시작, 오답 후 단계 4 유지, 두 정답 직접 입력과 완료 | 실행한 기능 통과 |
| 보상과 전적 | 최초 튜토리얼 보상 30, 튜토리얼 전적 0, 일반 대국 1판만 집계. 재학습 전후 깃털 60 유지 | 실행한 기능 통과 |
| 일반 대국과 저장 | 봇 표시, 입력한 선택과 같은 seed 복원, 판 완료 후 진행 저장 제거, 결과와 홈 복귀 | 실행한 기능 통과 |
| 고난도와 첫 특수 게이트 | 격리 저장에 band 5와 80승을 사전 주입한 뒤 실제 홈의 Play 입력으로 9구간 진행. 두 안내에서 remaining_ms가 2,500에서 그대로 유지, 탭 후 판이 진행되고 두 lesson_seen이 true | 안내 중 시계 정지와 확인 후 진행 통과. 낮은 난이도부터 실제 승리해 band 5를 해금한 실행은 아님 |
| 손상 저장 사본 복구 | 전용 E2E 주 저장 파일만 손상시킨 뒤 normal read에서 loaded_from=`backup`, 깃털 60 복원, 정상 앱 화면 진입 | 실행한 복구 통과 |
| 광고 | 단위 테스트 17건으로 동의, 중복 콜백과 판당 1회, 미준비, 늦은 로드, 44,999ms와 45,000ms 경계 통과. 여정은 미준비 개발 포트와 결과 버튼 복귀를 확인 | 개발 범위 통과. 실제 광고와 UMP는 미실행 |
| 꾸미기와 설정 | 실제 카드 입력으로 보상 깃발 장착과 저장, 효과음 스위치 반영, 재학습 진입과 홈 복귀. 짧은 화면은 재학습 버튼을 보이게 하기 위한 스크롤 입력도 완료 | 실행한 기능 통과. 꾸미기 목록 전체 드래그, 깃털 해금 확인창은 여전히 미검수 |
| 공유 | headless 공유 실패와 결과 복귀, 렌더링의 실제 로컬 PNG 저장과 복귀 | 개발 경계 통과. 이미지 배치 문제는 아래에 남김 |
| R1-01 중복 상대 표식 | 세 크기 오답 원본의 ×1.5 칸에 Practice 또는 연습 표식 하나만 존재 | 수정 확인 |
| R1-02 결과와 공유 잘림 | pause 버튼 자투리는 제거됨. 짧은 화면의 장면 원본에는 수치 상단 및 상대 오른쪽 잘림이 남고, 긴 화면과 태블릿은 내 칩이 상대 이름을 덮음 | 부분 개선, 미해결. R2-02로 구체화 |
| R1-03 기록 매칭 설명 | 한국어 ‘게이트를 고르는 시간이 1.5배로 늘어나요.’, 영어 ‘Gives you 50% more time to choose a gate.’ 확인 | 수정 확인 |
| R1-04 캡처 부족 | 오답 자막 fade 후 실제 설명, 44→68과 47→70, 계속 안내가 보임. 5/6, 6/6의 상대 선택 예고 원본도 생성·열람 | 근거 부족은 해소. 짧은 화면 자막 잘림 R2-01은 별도 결함 |
| 1회차 영어 진행 중단 | 이번 영어 짧은 화면은 일시정지에 걸리지 않고 4개 여정 완료 | 테스트 포커스 경계 수정 확인. 제품 기본 포커스 일시정지는 별도 실행하지 않음 |

## 남은 화면 문제

| ID와 우선순위 | 재현 근거와 위치 | 영향과 수정 제안 | 판정 |
|---|---|---|---|
| R2-01, P2 | `en-short/quiz-preview-4.png`, `quiz-preview-5.png`, `02-quiz-mistake.png`, `lesson-steal.png`, `lesson-shield.png`. 자막 카드 양 끝과 왼쪽 아이콘이 stage에 잘림. 긴 자막은 군중 수치 칩도 덮음. `game/src/presentation/duel/caption_layer.gd`의 고정 최소 텍스트 폭 290dp에 아이콘과 여백이 더해짐 | 짧은 화면의 실제 stage 폭은 303.75dp인데 아이콘이 있는 카드 최소 폭은 약 352dp다. 사용 가능한 stage 폭으로 카드와 텍스트를 제한하고, 군중 수치가 가려지지 않는 공간 또는 설명 전용 배치를 사용. 한국어 긴 화면과 태블릿에서도 6/6 및 오답 때 칩 일부가 자막 뒤로 가는 것은 함께 확인 필요 | UX 실패 |
| R2-02, P2, R1-02 계속 | `en-short/03-tutorial-result.png`, `05-normal-result.png`와 실제 영어 짧은 화면 공유 PNG에서 수치 상단과 상대 오른쪽 잘림. `en-short/normal-gate-8.png`의 Bot 225 칩도 상단과 오른쪽이 잘림. 긴 화면과 태블릿 결과에서는 내 칩이 Practice 또는 Bot 이름을 덮음. `game/src/presentation/duel/world_view.gd`, `duel_screen.gd`의 world 캡처 경로 | contain 배치 전에 world 원본부터 이미 잘리거나 겹친다. 칩의 실제 크기를 고려해 world 안으로 제한하고 두 칩을 분리 배치. 결과용 군중 장면도 두 진영이 모두 프레임에 들어오는지 확인. 최종 점수의 별도 행은 읽힘 | UX 실패 |
| R2-03, P2 | `en-short/04-home.png`에서 Customize와 Settings 버튼이 Play 하단을 덮음. `game/src/presentation/home/home_screen.gd`의 0.74 높이 기준 고정 시작 버튼과 고정 하단 버튼 영역 | 짧은 화면에서 시작 버튼과 탐색이 시각적으로 겹친다. 세 버튼을 같은 하단 세로 레이아웃에 배치하거나 가용 높이로 분리. 한국어 긴 화면과 태블릿에서는 이 겹침이 없음 | UX 실패 |
| R2-04, P2 | `en-short/06-cosmetics.png`에서 깃털 잔액, 세 번째 카드 오른쪽과 설명 끝이 stage 밖으로 잘림. `game/src/presentation/profile/profile_screen.gd`, `cosmetic_card.gd`의 고정 3열, 카드 최소 폭 100dp | 카드 3개와 간격, 화면 여백의 최소 폭 약 348dp가 짧은 화면 stage 폭을 초과한다. 가용 폭으로 2열 또는 카드 폭을 결정하고 헤더 최소 폭도 확인. 태블릿과 한국어 긴 화면에서는 세 열 전체가 읽힘 | UX 실패 |
| R2-05, P2 | 세 크기의 `lesson-steal.png`, `lesson-shield.png`에서 자막 왼쪽 게이트 아이콘을 식별하기 어려움. `caption_layer.gd`가 `game/assets/art/gate_steal.svg`, `gate_shield.svg`를 그대로 쓰며 stroke `#2b2622`는 자막의 어두운 바탕과 같음 | 아이콘으로 설명하는 요구를 충족하지 못한다. 자막 전용 밝은 아이콘이나 밝은 아이콘 바탕을 사용하고 PNG에서 확인 | UX 실패 |
| R2-06, P2 | 세 크기 `lesson-steal.png`의 실제 게이트는 25%인데 예시는 12→16, 20→20. `game/src/application/gate_lessons.gd`는 별도 20% 빼앗기와 상대 +4를 계산해 상대의 -4와 +4가 상쇄됨. 예시의 게이트와 양쪽 선택은 표시하지 않음 | 예시가 화면의 25% 계산으로 보일 수 있고 빼앗긴 상대가 줄어드는 모습도 드러나지 않는다. 예시의 게이트 수치와 선택을 함께 표시하거나 현재 게이트에 맞는 정수 판정을 사용. 상대 감소가 직접 드러나는 예시를 선택. 도메인 판정 오류라는 뜻은 아님 | UX 실패 |

## 근거의 한계와 다음 확인

`quiz-preview-4/5.png`는 재학습 때 같은 파일명으로 다시 저장된다. `normal-gate-N.png`도 고난도 여정이 입문 대국의 같은 이름을 덮어쓴다. 여정의 기능 assertion과 JSON 단계는 남지만, 원래 구간의 화면 원본은 분리 보관되지 않는다. 다음 회차에는 시나리오 이름을 캡처명에 포함하면 각 화면을 독립적으로 추적할 수 있다.

꾸미기 목록 끝까지 드래그, 해금 확인창, 개인정보 고지와 초기화 확인창, 언어 변경 후 복원은 이번 여정의 실행 항목에 없다. 계획에 적힌 꾸미기 드래그를 수행한 것으로 계산하지 않는다. 소리와 진동을 끈 격리 실행이므로 실제 청취와 햅틱도 검수하지 않았다.

기기 조회와 실행, UMP, 실제 광고 표시와 닫기, Android 공유창은 모두 미실행이다. 이 검수는 사람의 이해도나 이탈률을 입증하지 않는다. 3회차 전에 남은 배치 문제를 수정하고 짧은 화면과 공유 원본, 특수 게이트 예시를 재확인해야 한다. 3회차 뒤 미해결이면 중앙 정책의 추가 회차 사전 승인 조건을 따른다.
