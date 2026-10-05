# TAP Work 로고

2026-10-05 사용자가 최종 선택한 이미지: `~/Downloads/TapWater_logo.png`. 수도꼭지·물방울·컵의 원래 도안을 사용한다. 앱 이름은 **TAP Work**다. 이전 로고 원본, route/check 로고 보관본과 과거 생성 스크립트는 사용자 요청으로 삭제했다.

`TapWater_logo.png`는 원본의 중앙 정사각형 구도로 만든 1024px RGB 배포 마스터다. 가로 원본의 좌우 바깥 여백만 동일하게 줄이고 도안의 비율·색은 유지했다. 큰 원본의 중복 저장을 피하며 원본 파일은 Downloads에 남아 있다.

`python3 app/assets/branding/generate_brand.py`는 이 마스터에서 256px 루트/Flutter 로고, 웹 favicon/PWA, Android launcher, iOS AppIcon 크기를 생성한다. 모두 최적화된 PNG이며 iOS에는 alpha가 없다. PWA maskable은 safe circle에 전체 구도가 들어가도록 여백을 둔다. `scripts/sync-branding.mjs`는 루트와 Flutter 로고를 동기화한다. 플랫폼 필수 크기는 유지하고 이전 디자인 파일은 배포하지 않는다.

공통 헤더/로그인은 48px 이미지와 `TAP Work` 워드마크를 사용한다. iOS/Android 표시 이름과 웹/PWA/개인정보 페이지도 동일하다. Bundle ID는 `com.tap2work.tap2work`이며 내부 저장 키·패키지 이름·도메인과 별개다. App Store용은 `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`이다.
