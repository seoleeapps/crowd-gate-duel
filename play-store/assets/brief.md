# 등록 이미지 제작 기준

Crowd Gate Duel은 게이트를 고르고 상대 봇의 선택을 읽어 군중을 키우는 13세 이상 캐주얼 게임이다. 기존 한낮 장터의 주황, 청록, 모래색, 군중과 깃발 아트를 그대로 사용한다.

아이콘은 게임의 기존 SVG를 단색 배경에 512x512로 변환한다. 대표 이미지는 실제 1080x1920 실행 화면과 제품명만 1024x500에 배치한다. 스크린샷은 필수 체험, 일반 봇 대국, 결과와 꾸미기의 실제 렌더링이다. 기기 스크린샷이나 광고 SDK 실행 근거로 표현하지 않는다. 원본 전체 화면은 PNG로 보존하고 UI를 자르거나 홍보 테두리를 붙이지 않는다.

현재 파일은 macOS Godot Compatibility 렌더러의 개발 화면이다. phone은 1080x1920, tablet은 1440x2560이며 7인치와 10인치 슬롯은 같은 태블릿 viewport의 원본을 쓴다. 실제 기기 촬영을 했다는 뜻은 아니다. 영어 기본 이미지와 한국어 phone-ko 이미지를 따로 보관한다.

재생성은 영어와 한국어 1080x1920 여정을 build/listing/en 및 ko로, 태블릿 여정을 build/listing/tablet로 캡처한 뒤 scripts/make_store_assets.py를 실행한다. 이어 registration-assets/scripts/genimg.py와 validate.py에 play-store/assets-manifest.json을 전달한다. 아이콘 master는 기존 SVG를 sips로 PNG로 변환한 원본이다. 새로운 아트를 생성하거나 이미지 API를 호출하지 않았다.
