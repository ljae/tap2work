# tap2work Flutter app

프로젝트의 제품 결정과 개발 이력은 상위 [`docs/project-state.json`](../docs/project-state.json)을 기준으로 합니다. 전체 실행 방법은 상위 [README](../README.md)를 확인하세요.

```sh
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
```

개발자 웹에 표시할 빌드는 루트에서 `npm run build:app`으로 만듭니다. `/app/` 경로를 사용하므로 빌드 폴더를 임의로 다른 루트에 옮겨 서비스하지 않습니다.

앱은 샘플 데이터를 사용합니다. `WorkController`의 역할 구분은 데모 화면을 위한 것으로 실제 인증이 아닙니다. `ProgressStore` 인터페이스를 통해 기기 저장과 테스트 저장소를 분리했습니다. 서버 연동을 추가할 때는 매장·사용자별 소속과 권한을 별도로 검증해야 합니다.

한글 표시를 위해 [Google Fonts의 Noto Sans KR](https://github.com/google/fonts/tree/main/ofl/notosanskr)을 앱에 포함했습니다. 라이선스는 `assets/fonts/OFL.txt`에 함께 보관합니다. 브라우저의 외부 한글 폰트 로딩에 의존하지 않습니다.
