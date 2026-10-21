# Google Play 및 AdMob 등록 기록

2026-10-21에 사용자가 전용 Edge 로그인을 완료한 뒤 실제 Console을 읽고 등록했다. 공개 출시, 업로드와 심사는 아직 하지 않았다.

## 계정과 앱

Google Play의 실제 로그인은 지정된 legacy 계정과 일치했다. 개발자는 Seolee Apps, 개인 계정, ID5547060480954653351이다. 새 앱 기본 계정과 다른 이번 선택은 사용자가 승인한 출시 계획의 Seolee Apps 지정을 따랐다. 계정과 권한, 다른 앱은 변경하지 않았다.

생성 전 실제 앱 목록9개에 Crowd Gate Duel은 없었고 생성 화면에서 com.seoleeapps.crowdgateduel의 사용 가능 표시를 확인했다. Crowd Gate Duel, 영어 미국 기본 언어, 무료 게임으로 생성했다. 생성 후 목록의 제품명과 패키지, 앱 대시보드를 다시 읽었다. Play 앱 ID는4972940845333469610이며 현재 임시 앱이다. 최초 생성 요청 뒤 화면 전환이 지연되어 앱 목록을 따로 읽었고 생성 요청을 다시 보내지 않았다.

## 광고

AdMob 실제 로그인은 같은 지정 계정이다. 게시자는 pub-9932778305312246, 계정 상태는 운영중이며 판매자 도메인은 seorilabs.com 확인됨이다. 기존 목록에서 Crowd Gate Duel을 검색해 결과가 없는 것을 확인하고 Android의 아직 공개되지 않은 앱으로 만들었다.

| 항목 | 확인한 값 |
|---|---|
| 앱 이름 | Crowd Gate Duel |
| 앱 ID | ca-app-pub-9932778305312246~3123388099 |
| 전면광고 이름 | normal_result_interstitial |
| 전면광고 ID | ca-app-pub-9932778305312246/5621733939 |
| 게재빈도 | 광고 단위와 앱 수준 모두 제한 없음 |
| 앱 승인 | 검토 필요, 공개 스토어 연결 대기 |

생성 완료와 광고 단위 목록을 다시 읽었다. 운영 ID는 game/config/android.json과 앱 전용 로컬 카탈로그에 등록했다. 앱의 저장 우선, 결과당1회와 닫힘 뒤45초 조건은 코드가 적용한다. AdMob 등록은 실제 광고가 송출됐다는 증거가 아니다.

https://www.seorilabs.com/app-ads.txt의 실제 응답에서 현재 게시자의 DIRECT 항목을 확인했다. 다른 게시자의 기존 항목은 수정하지 않았다. UMP 메시지 설정은 진행 중이다.

## 업로드 서명

앱 전용 활성 키가 없음을 확인했다. 기존 자격증명을 먼저 백업하고 로컬 및 BeeStation 각각의 임시 복원 검사를 통과한 뒤 RSA4096 PKCS12 업로드 키를 새로 만들었다. 앱별 identity와 키, 공개 광고 식별자는 로컬 카탈로그에 등록했다. 공유 Play Publisher는 기존 identity를 재사용하며 consumer에 이 앱만 추가했다.

논리 ID는 app/crowd-gate-duel/google-play/upload-key, alias는 crowd-gate-duel-upload다. 공개 인증서 SHA256은36:AE:5A:36:20:C7:5D:C2:E2:E9:0B:52:D6:05:96:0C:E9:56:35:2D:3F:78:08:A3:00:6C:30:7A:19:3C:72:51이다. 실제 개인키 항목과 인증서 export 해시를 확인했다. 비밀값과 키 파일은 저장소에 넣지 않았다.

새 키 포함 백업 SHA256은 bf58ee44b3d5abf778382fa7482c7c6f29b7190da94f229cc8654c3e54bbf914다. 로컬과 BeeStation에서5963개 파일의 체크섬 및 복원을 각각 통과했다. 원본 기록은 저장소 밖 recovery/crowd-gate-duel-20261021/signing에 보존한다.

GitHub의 google-play-release 환경을 새로 만들고 v*.*.* 태그만 허용했다. 이 앱의 키, 비밀번호와 alias를 환경 Secret4개에 동기화했으며 공개 인증서 해시를 환경 변수에 등록했다. 이름과 환경 정책을 다시 읽었다. Secret 값은 읽어낼 수 없으므로 실행 시 인증서 검사를 추가로 통과해야 한다. 출시 태그와 AAB 빌드는 아직 실행하지 않았다.

## Play 신고와 콘텐츠 등급

개인정보처리방침 URL, 제한된 접근 없음, 광고 포함, 정부 앱 아님, 금융 및 건강 기능 없음, 대상 연령13~15세,16~17세와18세 이상을 저장하고 완료 응답을 다시 읽었다. 대상 연령은13세 이상으로 유지한다.

IARC는 판타지 인물의 멀리서 짧게 묘사되는 비현실적인 충돌과 유혈 없음을 신고했다. 실제 결과는 한국 전체이용가, 북미10세 이상, PEGI7, 대만12세 이상 등이다. 2026-10-21 오전9:53 제출 뒤 Console의 IARC 상태는 완료됨이다. 인증 ID는 이후 재조회에도 `-`이므로 발급된 ID를 확인했다고 기록하지 않는다. 데이터 안전, 카테고리와 연락처, 영어 및 한국어 스토어 등록과 지역 요건은 진행 중이다.

지역별 콘텐츠 등급에 맞춰 네이티브 SDK의 광고 콘텐츠 상한을 T에서G로 낮춘다. 근거는 [Google Play 광고 정책](https://support.google.com/googleplay/android-developer/answer/9857753?hl=en)과 [AdMob 상한 적용 기준](https://support.google.com/admob/answer/10477886?hl=en)이다. 이 변경은 아래 독립 검수 이후에 작성했으므로 해당 검수에서 실행했다고 주장하지 않는다. Java 컴파일과 lint는 새 후보 CI에서 확인한다. AdMob 앱별 콘솔 상한도 별도로 확인한다.

## 개발 검수와 남은 단계

후보0e70326b0ef541dd52f84096c0d9c76adfb68eb0의 Godot CI39522362402와 Android CI39522362584는 통과했다. 단위275개, 코스10000개와 headless 및4개 렌더링 여정 각각279검사를 포함한다. CI checkout은 PR merge ref이며 미래 출시 태그 SHA와 구분한다. 원본은 build/ci-0e70326과 build/ci-android-0e70326에 보관한다.

사용자가 추가 승인한 [다섯 번째 계획](design/2026-10-21-offline-play-launch/iteration-5-plan.md)에 따라 같은 후보의 독립 검수는 기능과UX 모두 통과했다. 단위275개, headless와 영어 짧은 화면, 한국어 긴 화면 및 태블릿의7기능4시나리오 각각279검사를 완료했다. [실행 보고서](design/2026-10-21-offline-play-launch/iteration-5-result.md)는 원래1~4회차 실패와 이번 해결 근거를 연결한다. 실제 UMP와 광고, Android 공유창, 사람의 이해도와 이탈률은 이 통과 범위에 포함하지 않는다.

같은 출시 후보의 중앙 검사, UMP 메시지, 데이터 안전 및 지역 요건, 서명 AAB, 내부 업로드, 별도 승인한 필수 네이티브 실행, 심사와 공개가 남아 있다. 기기는 조회하지 않았다.
