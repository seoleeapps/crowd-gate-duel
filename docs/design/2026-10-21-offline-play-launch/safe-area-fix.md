# 태블릿 화면 이탈 수정과 작성자 확인

네 번째 독립 검수의 후보 ca982a89는 태블릿 저장 복원 뒤 군중과 진행 리본이 화면 밖으로 나갔고 결과 및 공유 장면이 비었다. 재학습도 완료하지 못했다. [원래 실패 보고서](iteration-4-result.md)와 build/review-4의 원본은 보존했다.

DuelScreen은 get_display_safe_area의 y를 모든 플랫폼에서 화면 안 여백으로 환산했다. Godot의 데스크톱 fallback은 모니터 작업 영역이며 모바일 노치 여백과 다르다. [공식 DisplayServer 문서](https://docs.godotengine.org/en/stable/classes/class_displayserver.html#class-displayserver-method-get-display-safe-area)를 확인하고 Android와 iOS에만 노치 여백을 적용했다. 데스크톱 창은 0을 적용한다. 도메인 규칙, 저장과 광고 조건은 바꾸지 않았다.

기존 계산을 추출한 상태에서 데스크톱 원점 y=2160, 화면 높이1440, 컨트롤 높이2160을 주면 여백3240이 나오는 실패를 재현했다. 회귀 검사는 수정 전271통과4실패, 수정 후275통과0실패다. 음수 모니터 원점, Android와 iOS의 노치 비율, 화면 정보가 없는 경우도 포함한다. 원본은 build/qa/safe-area/red.log와 green.log다.

작성자가 영어1620x2160 실제 렌더링 여정을 한 번 실행했고 tutorial, duel, progress, cosmetics, settings, ads, share의4시나리오279검사를 통과했다. 군중과 수치, 결과 장면, 실제 공유 PNG를 직접 열어 확인했다. 원본은 build/qa/safe-area/en-tablet과 user://e2e/safe-area-author-tablet/share다. 이 실행은 커밋 전 작성자 확인이며 최종 후보 SHA의 독립 검수나 출시 근거로 쓰지 않는다.

이전 태블릿 실행 당시 OS safe rect 값은 로그에 없으므로 당시 값 자체를 확인한 것으로 표현하지 않는다. 코드의 잘못된 좌표 해석은 재현했고 해당 경로를 수정했다. 네 번째 독립 검수 판정은 실패로 유지하며 추가 독립 검수는 별도 승인 전 시작하지 않는다. 기기 사용과 실제 Android SDK 동작은 미실행이다.
