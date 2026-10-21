# 독립 기능 및 화면 검수 4회 결과

후보 `ca982a89b148f9d0e0dc88b62cfbc04defbe890a`는 이번 4회차에서 기능과 UX 모두 실패다. 단위 267건, headless, 영어 1080x1620, 한국어 1080x2520은 통과했다. 마지막 영어 태블릿 실행은 일반 대국 복원 뒤 군중과 길이 화면 밖으로 나가고 결과 및 공유 장면이 비었으며 재학습을 완료하지 못했다. 원본과 미완료 상태를 보존했고 임의 반복 실행과 다섯 번째 회차는 시작하지 않았다.

## 승인, 후보와 환경

실행 전 계획은 [iteration-4-plan.md](iteration-4-plan.md)다. 계획에 기록된 사용자 승인 관찰 시각은 `2026-10-21T00:08:54Z`, 계획 작성 시각은 `2026-10-21T00:09:51Z`이며 이번 실행은 그 뒤에 시작했다. 검수자 `/root/ui_review`는 구현자 `/root`와 다르다. 시작과 마지막 명령 종료 뒤 실제 HEAD는 `ca982a89b148f9d0e0dc88b62cfbc04defbe890a`이고 `git status --porcelain`은 비어 있었다. 코드와 자산은 수정하지 않았다.

2026-10-21 09:10:52 KST에 단위를 시작해 마지막 태블릿은 09:15 KST에 종료 1을 확인했다. 원본 PNG와 공유 파일 열람은 09:16 KST까지 했다. macOS Apple M3, Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility와 OpenGL 4.1 Metal 환경이다. 중앙 계약도 로컬과 원격 main이 같은 `e7f433c071cf5d3ad4434c02ddf6a12164749489`임을 확인하고 읽었다.

모든 명령에 `GITHUB_SHA=ca982a89b148f9d0e0dc88b62cfbc04defbe890a`를 전달했다. smoke 저장과 공유는 `user://e2e/review-4-headless/`, `review-4-en-short/`, `review-4-ko-long/`, `review-4-en-tablet/`로 격리했다. 단위 테스트는 지정된 `scripts/test.sh`가 관리하는 전용 테스트 파일을 썼다. 사용자 진행 저장, Android 및 iOS 기기, 다른 작업 프로세스에는 접근하지 않았고 산출물을 외부로 전송하지 않았다. 이전 1~3회차 파일을 덮어쓰지 않았다.

## 실제 실행

Godot import와 실행이 겹치지 않도록 아래 순서로 한 번씩 실행했다. 공용 스크립트의 종료 상태와 `SCRIPT ERROR`, `ERROR:`, `Parse Error`, `ALL GREEN` 검사를 적용했다.

| 실행 | 명령 환경 | 원본 근거 | 결과 |
|---|---|---|---|
| 전체 단위 | `scripts/test.sh` | `build/review-4/test.log` | 종료 0, 267 passed, 0 failed. 출시 계약 15건과 광고 22건 포함 |
| headless | `E2E_RUN_ID=review-4-headless E2E_OUT=$PWD/build/review-4/headless scripts/smoke.sh` | `build/review-4/headless.log`, `headless/{import.log,run.log,journey.json}` | 종료 0, 4시나리오 279검사, 기능 7개 통과 |
| 영어 짧은 화면 | `E2E_CAPTURE=1 E2E_LOCALE=en E2E_SIZE=1080x1620 E2E_RUN_ID=review-4-en-short E2E_OUT=$PWD/build/review-4/en-short scripts/smoke.sh` | `build/review-4/en-short.log`, `en-short/{import.log,run.log,journey.json}` | 종료 0, 4시나리오 279검사 통과, PNG 27개 |
| 한국어 긴 화면 | `E2E_CAPTURE=1 E2E_LOCALE=ko E2E_SIZE=1080x2520 E2E_RUN_ID=review-4-ko-long E2E_OUT=$PWD/build/review-4/ko-long scripts/smoke.sh` | `build/review-4/ko-long.log`, `ko-long/{import.log,run.log,journey.json}` | 종료 0, 4시나리오 279검사 통과, PNG 27개 |
| 영어 태블릿 | `E2E_CAPTURE=1 E2E_LOCALE=en E2E_SIZE=1620x2160 E2E_RUN_ID=review-4-en-tablet E2E_OUT=$PWD/build/review-4/en-tablet scripts/smoke.sh` | `build/review-4/en-tablet.log`, `en-tablet/{import.log,run.log,journey.json}` | 종료 1, 완료되지 않은 checkpoint JSON, PNG 13개. 아래 R4-01 실패 |

통과한 세 JSON은 후보 전체 SHA와 일치하고 `focus=fixed-foreground`, `commitClock=16ms-per-frame`, `audio=Dummy`가 남았다. 시나리오별 검사는 47, 50, 75, 107개다. 태블릿 JSON은 finish 전 checkpoint여서 sourceSha와 해당 완료 메타데이터가 없으며 이를 통과 근거로 쓰지 않는다. 태블릿은 mandatory-tutorial 47개 통과, normal-bot-and-restore 50개 중 8개 실패, cosmetics-settings-and-replay 49개 중 1개 실패에서 중단됐다. special-gates-and-progress-recovery는 시작하지 못했다.

## 기능 관찰과 판정

| 항목 | 실제 관찰과 근거 | 기능 및 UX 문제와 사용자 영향 | 수정 제안 | 판정 |
|---|---|---|---|---|
| tutorial | 세 완주 환경의 무입력 선택 0, 미완료, 단계 2 복원, 오답 단계 4 유지, 두 quiz 예고와 직접 선택, 완료 보상 30과 재학습 미중복. 태블릿 최초 체험은 통과했으나 재학습은 완료 못함 | 태블릿 재학습의 자막 입력을 완료하지 못하는 R4-01 | R4-01 참조 | 세 환경 통과, 태블릿 실패 |
| duel | 세 완주 환경의 봇 표시, 실제 좌표 입력, 선택 수와 seed 복원, 일반 전적 1회, 고난도 9구간. 태블릿도 일반 전적 1과 seed 및 선택 수 복원 자체는 통과 | 복원 뒤 길, 군중과 진행 리본이 화면 밖. 플레이어가 수치를 보며 선택할 수 없음 | R4-01 참조 | 태블릿 기능 및 UX 실패 |
| progress | 세 완주 환경에서 진행 완료 저장, 보상 보존, 손상 primary의 backup 복구와 깃털 310 및 앱 복귀 | 태블릿의 손상 사본 복구 시나리오는 미실행 | 추가 실행 없이 미실행 보존 | 세 환경 통과, 태블릿 일부 미실행 |
| cosmetics | 세 완주 환경에서 보상 깃발 장착, 실제 목록 드래그, 취소 후 310 보존, 해금 120 차감 후 190, palette_amber 장착. 태블릿은 보상 깃발 장착까지 통과 | 태블릿 구매와 취소는 네 번째 시나리오에 도달하지 못해 미실행 | 미실행 보존 | 세 환경 통과, 태블릿 일부 미실행 |
| settings | 세 완주 환경에서 소리 토글 반영, 개인정보 선택 버튼이 fake 경계에 1회 전달, 재학습과 저장 복원. 태블릿도 토글과 개인정보 경계 호출은 통과 | 태블릿 재학습을 완료하지 못함 | R4-01 참조 | 태블릿 일부 실패 |
| ads | 모든 실행에서 첫 일반 결과 show 1, 저장이 먼저 디스크에 반영됨과 고정 foreground를 관찰. 완주 세 환경은 재학습 후 show 누적 1 유지. fake의 중복 실패 뒤 결과 버튼 사용 | 실제 SDK와 송출은 이 검수의 근거가 아님. 태블릿 재학습 후 미노출 최종 검사는 미실행 | 네이티브 상태와 분리 기록 | 실행한 경계 통과, 태블릿 일부 미실행 |
| share | headless는 실패 피드백 후 복귀, 영어 짧은 화면과 한국어는 실제 PNG 저장 후 결과와 홈 사용. 태블릿도 PNG 저장과 피드백은 통과 | 태블릿 공유 파일의 군중 장면이 비어 있음 | R4-01 참조 | 태블릿 UX 실패 |
| 실제 기본 포커스와 시간 | App의 respect_platform_focus 기본 true, 빈 commit_clock은 실제 delta 경로, AppRoot가 둘을 DuelScreen에 전달함을 읽음. 단위 15개에 포함된 focus 대체 및 기본 상실/복귀 3검사 통과 | 개발 E2E가 OS focus와 캡처 지연 영향을 격리한다. 이것이 실제 앱의 자동 선택 시간을 실측한 증거는 아님 | 검수 경계와 제품 기본값 구분 유지 | 지정 경계 통과 |
| 광고 간격과 legacy 저장 | 광고 22단위에서 재생성 1,000ms 및 44,999ms 차단, 45,000ms 허용. 출시 계약 단위에서 복원 가능한 legacy RECORD 진행 제거, 승수 15와 재화 120 보존, 보상 미중복 | 실제 Android 프로세스 재시작을 수행한 근거는 아님 | 단위 실행과 App Unix ms 및 cooldown 파일 연결 확인으로 한정 | 개발 경계 통과 |

## 원본 화면과 공유 파일 직접 검토

영어 짧은 화면의 quiz-preview-4와 quiz-preview-5, 오답, 튜토리얼 결과, 홈, 일반 결과, 꾸미기, 설정, lesson-steal, lesson-shield, unlock-confirm, 마지막 normal-gate-8 원본을 열었다. 한국어에서는 두 quiz 예고, 오답과 튜토리얼 결과, 두 특수 안내, 해금 확인창과 설정 원본을 열었다. 모두 `build/review-4/<환경>/` 아래 시나리오 prefix의 PNG다.

짧은 화면에서도 자막과 두 수치가 분리되어 읽힌다. 홈의 Play와 Customize 및 Settings 버튼은 겹치지 않는다. 꾸미기는 두 열로 들어가고 해금 질문과 취소 및 해금 버튼이 화면 안에 있다. 흰 훅과 방패는 어두운 카드에서 보이며 실제 25%와 10% 수식 및 변화 전후 수치가 읽힌다. 첫 안내에서는 remaining_ms 2,500이 유지됐고 확인 뒤 판을 마쳤다. 일반 결과 PNG의 버튼이 흐린 것은 광고 전 busy 시점의 캡처이며 이어진 실제 Share와 Home 입력 통과와 구분했다.

태블릿에서는 최초 두 quiz 예고, 오답과 튜토리얼 결과, 홈, normal-gate-1, normal-gate-2, normal-gate-4, 일반 결과, 꾸미기와 설정 원본을 열었다. 최초 체험과 홈 및 꾸미기와 설정은 읽힌다. 일반 대국 복원 뒤 normal-gate 원본은 상단이 빈 배경이고 게이트와 타이머만 보인다. 일반 결과의 장면 프레임도 비었다. 두 특수 게이트 안내와 해금 확인창 PNG는 생성되지 않아 해당 태블릿 시각 항목은 미검수다.

실제 공유 파일 세 개를 직접 열었다. 기준 경로는 `/Users/syous/Library/Application Support/Godot/app_userdata/Crowd Gate Duel/e2e/`다.

| 파일 | 직접 관찰 | 판정 |
|---|---|---|
| `review-4-en-short/share/result-1792541506.png` | 군중과 Me 91, Bot 84, 91:84 및 Crowd Gate Duel이 읽힘. 프레임 안 contain 배치 | 통과 |
| `review-4-ko-long/share/result-1792541538.png` | 군중과 나 91, 봇 84, 91:84 및 한국어 게임명이 읽힘. 긴 화면 비율의 여백은 있지만 잘림 없음 | 통과 |
| `review-4-en-tablet/share/result-1792541578.png` | 91:84와 게임명은 있지만 상단 장면 전체가 빈칸 | R4-01 UX 실패 |

## R4-01, 태블릿 복원 뒤 길과 군중 이탈, 장면 캡처 실패

심각도 P1. 재현은 이번 지정 후보의 마지막 태블릿 1회 실행이다. 최초 mandatory-tutorial과 홈은 정상이다. normal-bot-and-restore에서 한 번 선택한 일반 대국을 저장하고 main을 다시 붙여 복원한 뒤 각 normal-gate-1부터 normal-gate-4 원본에 길과 군중 및 리본이 사라진다. 로그의 stage 범위는 `(201.5, -1.0), size (1217, 2162)`인데 군중 칩 y는 2454, 높이는 105다. 두 칩 경계 검사 8개가 실패한다.

이후 `game/src/presentation/duel/duel_screen.gd:289`의 장면 get_region에서 `The Image height specified (-924 pixels) must be greater than 0 pixels.`와 `Condition "dsize == 0" is true.`가 발생했다. 결과와 공유의 장면은 실제로 비어 있다. 재학습은 `tutorial input completes`가 실패한 뒤 완료하지 못했고, 명령은 자체 제한 안에서 종료 1로 끝났다. 마지막 JSON은 세 번째 시나리오까지의 checkpoint이며 네 번째 시나리오는 없다. run.log에는 geometry 8개, 이미지 2개, 재학습 1개로 ERROR 11개가 남았다.

원본 근거는 `build/review-4/en-tablet/run.log`, `journey.json`, `normal-bot-and-restore--normal-gate-1.png`, `normal-bot-and-restore--05-normal-result.png`와 위 실제 tablet 공유 파일이다. 수치와 판 상황을 읽을 수 없고, 재학습을 끝내지 못하며 공유 카드에 장면이 없는 영향이다. 첫 발견 직후 root에 전달했다.

원인 후보는 `DuelScreen._safe_top()` 137~142행이다. `DisplayServer.get_display_safe_area().position.y`를 화면 원점 차감 없이 화면 높이 비율로 곱해 리본과 세계의 top에 넣는다. 데스크톱의 절대 디스플레이 좌표가 inset으로 들어가면 world_bottom보다 큰 top과 음수 캡처 높이를 만들 수 있다. 당시 OS safe area 값이 로그에 없으므로 이 원인은 코드와 관찰에서 얻은 추정이다. 임의로 실행 환경을 바꾸거나 추가 재현은 하지 않았다.

수정 제안은 safe area를 앱 viewport의 상대 inset으로 바꾸고 유효 범위를 제한하는 것, 개발 여정의 safe-area 경계도 고정 및 기록하는 것, 장면 캡처 rect가 화면 안의 양수 영역인지 확인하는 것이다. 검수자는 코드를 수정하지 않았다. 같은 후보의 Linux CI 성공이라는 전달 내용으로 이 실제 실패를 대체하지 않는다.

## 이전 실패 보존과 해결 근거

[1회 원래 보고서](iteration-1-result.md), [2회 원래 보고서](iteration-2-result.md), [3회 원래 보고서](../../../release-artifacts/qa/iteration-3-result.md)의 SHA와 실패 판정은 보존한다. 이번 근거를 resolutionEvidence로 연결하며 과거 원본을 통과로 다시 쓰지 않는다.

| 이전 항목 | 이번 resolutionEvidence | 판정 |
|---|---|---|
| R1 표식 중복, 결과 및 공유 crop, 설정 문구, quiz 관찰 부족 | en-short 및 ko-long의 두 quiz 예고와 오답, 결과 및 설정 원본, 실제 공유 PNG | 두 완주 렌더링에서 수정 유지. 태블릿 장면은 R4-01로 별도 실패 |
| R2 자막 폭과 숫자 겹침, 홈 버튼과 꾸미기 폭 | 두 완주 렌더링 원본 및 geometry 검사, 태블릿 최초 체험과 홈 및 꾸미기 원본 | 기존 문제 수정 유지. 복원 뒤 태블릿은 새 R4-01 |
| R2-05 아이콘 대비와 R2-06 현재 예시 | 두 완주 렌더링 lesson-steal 및 lesson-shield 원본, 시간 정지 검사 | 영어 짧은 화면과 한국어 수정 확인. 이번 태블릿은 미검수 |
| R3-01 서비스 재생성 간격 | `build/review-4/test.log` 광고 22건, App의 Unix ms 및 cooldown 파일 연결 코드 | 개발 경계 수정 유지 |
| R3-02 legacy RECORD 진행 | `build/review-4/test.log` 출시 계약 15건 중 실제 legacy fixture 실행 | 수정 유지 |
| R3-03 한국어 show 0과 검수 focus 경계 | `build/review-4/ko-long/journey.json` 첫 show actual 1, 고정 foreground true, reward disk true, 재학습 show 누적 1, 전체 279검사 | 이번 한국어 여정에서 해결 확인 |
| 캡처 중 선택 시간 경과 영향 | 세 완주 JSON의 commitClock=16ms-per-frame, 각 normal 입력 완료. 실제 제품 clock은 빈 기본값 | 세 환경 검수 경계 유지. 태블릿 전체 완주 실패를 면제하지 않음 |

## 남은 상태

승인된 한 회차의 다섯 명령을 모두 종료했다. 태블릿 R4-01과 뒤따른 미실행 범위 때문에 전체 기능 및 UX 통과를 선언하지 않는다. 실패 원본을 보존하고 root에 전달했으며 추가 수정 실행과 새 회차는 시작하지 않았다.

실제 UMP, 광고 송출 및 닫힘, Android 공유창, 기기, 청취와 햅틱은 미실행이다. 사람의 이해도와 유지율도 검증하지 않았다. 빌드, 업로드, 심사와 공개 상태를 이번 개발 검수로 주장하지 않는다.
