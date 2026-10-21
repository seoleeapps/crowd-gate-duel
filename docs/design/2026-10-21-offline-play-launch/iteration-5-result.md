# 독립 기능 및 화면 검수 5회 결과

후보 `0e70326b0ef541dd52f84096c0d9c76adfb68eb0`의 지정된 개발 환경 검수는 기능 통과, UX 통과다. 전체 단위 275건과 headless, 영어 짧은 화면, 한국어 긴 화면, 영어 태블릿의 각 4시나리오 279검사를 한 번씩 순차 실행해 모두 통과했다. 원본 PNG와 실제 공유 PNG를 직접 열었으며 4회차 R4-01의 태블릿 화면 이탈과 빈 결과 및 공유 장면, 재학습 미완료가 이번 실행에서 해소됐다. 새 결함은 관찰하지 않았다.

## 승인과 실행 범위

실행 전 [iteration-5-plan.md](iteration-5-plan.md)를 읽었다. 승인 원문은 `추가 1회 승인`, 승인 관찰은 `2026-10-21T00:36:35Z`, 계획 기록은 `2026-10-21T00:43:05Z`다. 구현자 `/root`와 다른 `/root/ui_review`가 반복 사용자 및 저장 복구 검수자 관점으로 실제 실행했다. 계획과 원래 1~4회차 판정을 소급 변경하지 않았다.

root가 같은 후보의 Godot CI 39522362402와 Android CI 39522362584 성공을 확인한 뒤 이 검수를 요청했다. 이번 검수자도 [Godot CI](https://github.com/seoleeapps/crowd-gate-duel/actions/runs/39522362402)의 `headSha=0e70326b0ef541dd52f84096c0d9c76adfb68eb0`, completed와 success, 00:43:58Z 완료를 직접 읽었다. 같은 로그의 `scripts/validate_courses.sh --seeds 10000`, 00:41:02Z의 `통과 10000 / 10000`도 읽었다. 코스 10,000개를 로컬에서 추가 반복 실행한 것은 아니다. Android CI 성공은 빌드 상태이며 이번 개발 대역 실행으로 실제 광고 SDK 통과를 주장하지 않는다.

실행 시작과 마지막 명령 종료 뒤 HEAD는 위 전체 SHA이고 `git status --porcelain`은 비어 있었다. 소스와 자산은 수정하지 않았다. macOS Apple M3, Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility와 OpenGL 4.1 Metal에서 2026-10-21 09:44:50 KST부터 09:47:16 KST까지 명령을 실행했다. 실제 화면 및 공유 파일 열람은 09:49 KST까지 진행했다.

진행과 공유는 각 `user://e2e/review-5-headless/`, `review-5-en-short/`, `review-5-ko-long/`, `review-5-en-tablet/` 경로로 격리했다. 지정된 단위 runner는 기존 전용 테스트 파일을 사용한다. 사용자 저장과 기기, 다른 작업 프로세스에 접근하지 않았고 산출물은 외부로 전송하지 않았다. 이전 회차의 로그 및 PNG를 덮어쓰지 않았다.

## 실제 실행 근거

다섯 명령 모두 `GITHUB_SHA=0e70326b0ef541dd52f84096c0d9c76adfb68eb0`를 전달했다. import가 겹치지 않도록 순차 실행했고 각 명령은 종료 0이었다. 공용 wrapper가 검사하는 `SCRIPT ERROR`, `ERROR:`, `Parse Error`와 완료 표시를 확인했고 각 환경의 import.log 및 run.log에서도 오류 0을 확인했다.

| 실행 | 명령 환경 | 원본 근거 | 결과 |
|---|---|---|---|
| 전체 단위 | `scripts/test.sh` | `build/review-5/test.log` | 275 passed, 0 failed. 출시 계약 23건과 광고 22건 포함 |
| headless | `E2E_RUN_ID=review-5-headless E2E_OUT=$PWD/build/review-5/headless scripts/smoke.sh` | `build/review-5/headless.log`, `headless/{import.log,run.log,journey.json}` | 4시나리오 279검사, 기능 7개 통과 |
| 영어 1080x1620 | `E2E_CAPTURE=1 E2E_LOCALE=en E2E_SIZE=1080x1620 E2E_RUN_ID=review-5-en-short E2E_OUT=$PWD/build/review-5/en-short scripts/smoke.sh` | `build/review-5/en-short.log`, `en-short/{import.log,run.log,journey.json}` | 4시나리오 279검사 통과, PNG 27개 |
| 한국어 1080x2520 | `E2E_CAPTURE=1 E2E_LOCALE=ko E2E_SIZE=1080x2520 E2E_RUN_ID=review-5-ko-long E2E_OUT=$PWD/build/review-5/ko-long scripts/smoke.sh` | `build/review-5/ko-long.log`, `ko-long/{import.log,run.log,journey.json}` | 4시나리오 279검사 통과, PNG 27개 |
| 영어 1620x2160 | `E2E_CAPTURE=1 E2E_LOCALE=en E2E_SIZE=1620x2160 E2E_RUN_ID=review-5-en-tablet E2E_OUT=$PWD/build/review-5/en-tablet scripts/smoke.sh` | `build/review-5/en-tablet.log`, `en-tablet/{import.log,run.log,journey.json}` | 4시나리오 279검사 통과, PNG 27개 |

네 journey.json은 완료 파일이고 모든 시나리오가 passed이며 sourceSha가 위 후보와 일치한다. 시나리오별 검사 수는 mandatory-tutorial 47, normal-bot-and-restore 50, cosmetics-settings-and-replay 75, special-gates-and-progress-recovery 107이다. 이 숫자는 입력 및 상태와 경계 검사의 합이며 독립 제품 기능 279개를 뜻하지 않는다. 각 JSON에 `focus=fixed-foreground`, `commitClock=16ms-per-frame`, `audio=Dummy`, `safeArea=mobile-cutout-only`가 기록됐다.

## 기능과 UX 관찰

| 기능 | 실제 관찰과 근거 | 기능 판정 | UX 판정 |
|---|---|---|---|
| tutorial | 네 환경의 무입력 선택 0과 미완료, 단계 2 저장 복원, 오답 후 단계 4 유지와 해당 문제 재시도, 두 상대 선택 예고와 실제 정답 입력, 완료 보상 30과 일반 전적 제외, 재학습 보상 미중복. 원본 quiz 및 오답의 한 문장 이유와 44→68 및 47→70이 읽힘 | 통과 | 통과 |
| duel | 네 환경의 봇 표시, 실제 화면 좌표 입력, 저장 뒤 같은 seed와 선택 수 복원, 일반 전적 1회, 9구간 고난도 fixture 완료. 태블릿 복원 뒤 길과 군중 및 리본이 정상 표시됨 | 통과 | 통과 |
| progress | 결과와 보상 저장 후 진행 종료, 재실행 후 전적 1 보존, 전용 primary 손상 뒤 backup에서 깃털 310 복구와 앱 복귀. 실제 legacy RECORD 진행 제거 및 승수 15와 재화 120, 완료 보상 미중복은 전체 단위에서 통과 | 통과 | 실행한 복구와 복귀 흐름 통과 |
| cosmetics | 보상 깃발 장착, 실제 목록 드래그, 해금창 취소 뒤 310 보존, 해금 120 차감 후 190과 palette_amber 장착. 짧은 화면은 두 열, 긴 화면 및 태블릿은 세 열로 폭 안에 들어가며 확인창이 읽힘 | 통과 | 통과 |
| settings | 소리 토글이 runtime에 반영, 개인정보 선택 필요 상태 뒤 실제 버튼 입력이 fake 포트에 1회 전달, 재학습 완료와 홈 복귀 및 재실행. 시간 연장 문구는 실제 선택 시간 증가를 설명함 | 지정 여정 통과 | 통과 |
| ads | 네 환경 모두 첫 일반 결과 show actual 1, 고정 foreground true, 디스크 보상 및 진행 종료가 show 전에 반영됨. 첫 fake가 failed를 두 번 보내도 결과에서 공유와 홈 사용, 재학습 뒤 show 누적 1 유지. 이후 중복 closed 흐름과 단위 22건의 동의, 미준비, 늦은 로드, 중복 콜백, 44,999/45,000ms 및 파일 복구 경계 통과 | 개발 경계 통과 | 결과와 버튼 사용 흐름 통과 |
| share | headless는 공유 실패 피드백 뒤 복귀, 세 렌더링은 실제 1080x1080 PNG 저장 피드백과 복귀. 실제 공유 세 파일의 장면과 점수 및 게임명을 직접 읽음 | 개발 공유 경계 통과 | 통과 |

고난도 첫 안내는 band 5와 승수 80 fixture로 접근했다. 이를 입문 난이도부터 수십 판 플레이해 해금하는 실제 사용자 여정으로 표현하지 않는다. 설정 초기화, 모든 언어 전환 조합, 실제 청취 및 햅틱을 실행했다고 확대하지 않는다.

## 직접 열어 확인한 원본

기준 경로는 `build/review-5/`다. en-short에서 두 quiz 예고, 오답, 튜토리얼 결과, 홈, 일반 결과, 꾸미기, 설정, 두 특수 안내와 해금창을 열었다. ko-long에서는 같은 주요 화면을 모두 열었다. en-tablet에서는 quiz 예고와 오답, 재학습 quiz-preview-5, 홈, 꾸미기와 설정, 복원 뒤 normal-gate-1 및 normal-gate-4, 일반 결과, 두 특수 안내와 해금창을 열었다.

주요 원본 파일명은 `mandatory-tutorial--quiz-preview-4.png`, `mandatory-tutorial--quiz-preview-5.png`, `mandatory-tutorial--02-quiz-mistake.png`, `mandatory-tutorial--03-tutorial-result.png`, `normal-bot-and-restore--04-home.png`, `normal-bot-and-restore--05-normal-result.png`, `cosmetics-settings-and-replay--06-cosmetics.png`, `cosmetics-settings-and-replay--07-settings.png`, `special-gates-and-progress-recovery--lesson-steal.png`, `special-gates-and-progress-recovery--lesson-shield.png`, `special-gates-and-progress-recovery--unlock-confirm.png`다. 태블릿 재학습 예고는 `cosmetics-settings-and-replay--quiz-preview-5.png`다.

세 크기에서 자막과 수치 칩은 분리되어 화면 안에서 읽힌다. 각 플레이어 선택 표식도 중복되지 않는다. 짧은 홈 버튼은 서로 떨어져 있고 꾸미기 설명과 열 폭이 잘리지 않는다. 해금 질문과 Cancel 및 Unlock, 취소와 해금 버튼이 모두 화면 안에 보인다. 현재 25% 훅과 10% 방패는 흰색으로 어두운 카드에서 보인다. 25% × 40 = 10, 12→22와 40→30, 10% × 40 = 4, 12→16과 40→36이 읽히며, 각 안내 중 remaining_ms 2,500 유지 후 실제 확인으로 진행했다.

일반 결과의 PNG는 광고 전 busy 시점이라 버튼이 흐리다. 이 상태는 예상된 대기이며 이후 실제 Share와 Home 입력이 성공하고 네 여정을 모두 마쳤음을 함께 확인했다. 결과 및 공유는 world 영역을 contain 배치해 화면 비율에 따른 여백이 있고, 점수나 군중의 잘림 또는 pause 잔여 조각은 보이지 않는다.

실제 공유 파일 기준 경로는 `/Users/syous/Library/Application Support/Godot/app_userdata/Crowd Gate Duel/e2e/`다. 아래 세 원본을 직접 열었다.

| 파일 | 실제 화면 관찰 | 판정 |
|---|---|---|
| `review-5-en-short/share/result-1792543554.png` | Me 91, Bot 84와 군중 장면, 91:84 및 Crowd Gate Duel이 읽힘 | 통과 |
| `review-5-ko-long/share/result-1792543588.png` | 나 91, 봇 84와 군중 장면, 91:84 및 한국어명이 읽힘 | 통과 |
| `review-5-en-tablet/share/result-1792543627.png` | 군중 장면과 두 수치가 있어 4회차의 빈 장면이 해소됨 | 통과 |

## R4-01 해결 확인

원래 실패 후보는 `ca982a89b148f9d0e0dc88b62cfbc04defbe890a`다. 원래 [4회차 보고서](iteration-4-result.md)와 [ignored 원본](../../../release-artifacts/qa/iteration-4-result.md), `build/review-4/en-tablet/`를 보존한다. 당시 기능 실패 및 UX 실패 판정과 미실행을 수정하지 않았다.

이번 후보의 `DuelScreen._safe_top()`은 실제 `safe_top_inset(OS.get_name(), safe, screen, size.y)`를 호출한다. helper는 Android와 iOS에서만 노치 여백을 변환하고 데스크톱은 0을 반환한다. 테스트 8개는 macOS, Windows, Linux 및 Web의 양수 모니터 원점과 음수 원점, Android 및 iOS 변환, 정보 없는 경계를 검사한다. 이번 275단위의 실제 실행에서 통과했다. 작성자가 제공한 `build/qa/safe-area/red.log`도 읽었으며 예전 경로의 네 플랫폼 expected 0, actual 3240 실패가 남아 있다. 작성자의 green 및 태블릿 실행을 이번 독립 통과로 합산하지 않았다.

이번 `build/review-5/en-tablet/journey.json`의 복원 뒤 첫 두 군중 칩은 stage `(201.5,-1), size(1217,2162)` 안의 y 약785.73과781.39, 높이105로 검사 통과했다. 4회차의 y2454 이탈이 재발하지 않았다. 실제 `normal-bot-and-restore--normal-gate-1.png`와 `normal-gate-4.png`에서 길, 리본과 두 군중 및 수치를 직접 확인했다.

같은 실행의 `normal-bot-and-restore--05-normal-result.png`와 실제 태블릿 공유 파일에도 군중 장면이 있다. 장면 캡처의 음수 높이 및 빈 image Godot ERROR가 없고 재학습 75검사와 다음 고난도, 해금, 사본 복구 107검사까지 완료했다. R4-01의 해결 근거는 이 최종 후보의 로그, 완료 JSON과 직접 열람한 원본이며 판정은 해결 확인이다. Android 및 iOS 노치 단위 통과는 실제 기기 화면 검수와 구분한다.

## 과거 지적의 resolutionEvidence

[1회 보고서](iteration-1-result.md), [2회 보고서](iteration-2-result.md), [3회 보고서](../../../release-artifacts/qa/iteration-3-result.md), [4회 보고서](iteration-4-result.md)의 원래 SHA와 실패 및 차단은 보존한다.

| 원래 항목 | 이번 해결 근거 | 이번 판정 |
|---|---|---|
| R1 표식, crop, 설정 문구와 quiz 관찰 | 세 렌더링의 quiz, 오답 및 결과, 설정, 공유 원본 | 수정 유지 |
| R2 자막 폭과 숫자 겹침, 홈 버튼, 꾸미기 폭 | 각 완료 JSON의 geometry 검사와 직접 연 주요 화면 | 수정 유지 |
| R2-05 흰 아이콘 및 R2-06 현재 수치 | 세 렌더링의 두 특수 안내 원본과 2,500ms 정지 검사 | 수정 유지 |
| R3-01 광고 서비스 재생성 간격 | 이번 광고 단위 22건의 실제 실행 및 App Unix ms와 cooldown 파일 연결 확인 | 개발 경계 수정 유지 |
| R3-02 legacy RECORD 진행 | 이번 출시 계약 단위 23건 중 유효 legacy fixture, 진행 제거, 승수 15와 재화 120 보존 검사 | 수정 유지 |
| R3-03 검수 focus와 한국어 show 0 | ko-long 완료 JSON의 show 1, foreground true, 저장 순서와 재학습 show 누적 1 | 수정 유지 |
| R4-01 태블릿 이탈 및 빈 장면, 재학습 미완료 | 위 R4-01 해결 절의 같은 후보 단위, 태블릿 완료 JSON, 복원 후 화면과 실제 공유 원본 | 해결 확인 |

## 실행 종료와 남은 범위

이번 승인 범위에서 기능과 UX를 각각 통과로 판정한다. 검수자가 시작한 단위 및 네 Godot 여정 명령은 전부 종료했다. 코드 수정, 임의 재실행과 여섯 번째 회차를 시작하지 않았다.

실제 UMP, 실제 광고 표시 및 닫힘, Android 공유창, Android 및 iOS 기기, 실제 청취와 햅틱, 사람의 이해도와 이탈률은 미실행이다. 개발 경계는 fake 광고와 로컬 공유 저장이며 운영 AdMob ID가 반영됐다는 이유로 광고 승인이나 송출을 확인했다고 표현하지 않는다. 이 보고서는 개발 검수 결과이며 빌드 업로드, 심사, 승인 또는 공개를 뜻하지 않는다.
