# tap2work

한국 소규모 F&B 매장의 직원·할 일·재고·발주를 한곳에서 다루는 Flutter 앱입니다. 기존의 ‘첫 한 시간 후 버디와 함께 근무’ 흐름을 유지하면서, 2026-09-19 사용자 요청으로 일상 매장 운영까지 체험 범위를 확장했습니다.

## 공개 개발 리뷰와 CEO 피드백

개발 저장소는 https://github.com/ljae/tap2work 이며 사용자 등록 도메인은 `tap2.work` (Namecheap)입니다. GitHub Pages 배포는 `.github/workflows/pages.yml`에서 `main` 변경마다 분석·테스트 후 실행합니다. 도메인의 실제 연결 상태는 GitHub Pages 설정과 DNS로 확인하세요.

- 공개 페이지: `site/`의 개발 방향 질문, 단계, 결정 기록과 피드백 링크.
- CEO는 방향 질문 / 새 기능 / 기존 기능 개선을 GitHub 이슈 양식으로 직접 제출합니다. GitHub 로그인이 필요하며 의견은 공개됩니다. 제출이 제품 방향의 자동 확정은 아닙니다.
- 공개 Flutter는 `PUBLIC_REVIEW=true`로 별도 빌드합니다. 샘플 화면과 발주함을 살펴볼 수 있지만 공유 운영 기록은 저장하지 않습니다. 첫 출근 연습은 브라우저에만 남습니다.
- `scripts/build-site.mjs`는 코드에서 새 샘플을 생성하며 `.local/operations-demo.json`을 복사하지 않습니다. 모든 공개 역할 파일은 누구나 읽을 수 있는 예시입니다.
- 로컬 개발자 콘솔의 결정 편집·공유 API는 계속 localhost 전용입니다.

```sh
npm run build:site
python3 -m http.server 3180 --directory _site --bind 127.0.0.1
```

http://127.0.0.1:3180 에서 공개용 산출물을 확인합니다. 이 빌드는 `app/build/review-web`과 `_site`를 사용하므로 로컬 API용 `app/build/web`과 분리됩니다. 배포 산출물의 상대 경로로 GitHub 프로젝트 URL과 사용자 도메인에서 동일하게 동작합니다.

## 로컬 개발자 웹 열기

Node.js 18+와 Flutter SDK가 필요합니다. 현재 확인한 환경은 Node.js 22.21.1, Flutter 3.41.2 / Dart 3.11.0입니다.

```sh
npm run build:app
npm start
```

http://localhost:3100 에서 프로젝트 현황, 결정사항, 개발 이력, Flutter 앱 미리보기를 봅니다. 결정 카드에서 내용과 변경 이유를 저장하면 파일에 바로 반영됩니다. 프런트엔드 의존성 설치는 필요 없습니다. Flutter 패키지는 `app/pubspec.lock`으로 고정합니다.

`npm run dev:console`도 같은 서버를 실행합니다. 포트를 바꾸려면 `DEV_CONSOLE_PORT=3101 npm start`를 사용합니다. 서버는 로컬 컴퓨터의 `127.0.0.1`에만 연결됩니다.

## 기록의 기준

- [`docs/project-state.json`](docs/project-state.json): 제품 요약, 확정·논의·보류 결정, 개발 단계, 변경 이력의 기준 파일
- [`docs/DECISIONS.md`](docs/DECISIONS.md): 기록 규칙과 웹 편집 사용법
- [`AGENTS.md`](AGENTS.md): 다음 개발 세션이 이어받아야 할 작업 원칙
- [`PRODUCT.md`](PRODUCT.md): 제품 구조와 첫 한 시간 흐름
- [`RESEARCH.md`](RESEARCH.md): Aside CLI로 살펴본 급구·워키도키 공개 자료와 UX 원칙

웹 편집은 현재 파일 버전을 확인하고, 변경 전·후 값과 이유를 이력에 추가한 뒤 원자적으로 저장합니다. 이전 파일은 `docs/history-backups/`에 보관됩니다. 다른 창의 저장과 충돌하면 새로 읽어 비교해야 합니다. 실제 운영 직원 데이터는 기록 파일에 넣지 않습니다.

## 코드 구조

```text
app/                         Flutter 앱 (Android / iOS / web)
  lib/domain/                교육 단계와 샘플 콘텐츠
  lib/state/                 첫 출근 기기 저장 + 매장 공유 API 컨트롤러
  lib/ui/                    앱 화면과 공통 구성요소
  test/                      학습 상태와 화면 흐름 테스트
developer/                   로컬 개발자 웹
  server.mjs                 정적 화면, Flutter 빌드, 기록 API
  store.mjs                  파일 저장, 충돌 방지, 복구 사본
  operations.mjs             공유 업무·재고·발주·직원 상태 데모 API
  dashboard.js               현황·결정·이력·미리보기
  test/                      저장 및 API 테스트
docs/project-state.json      지속적으로 갱신하는 기준 기록
.local/operations-demo.json  서버가 생성하는 공유 샘플 매장 상태 (Git 제외)
index.html / app.js           최초 HTML 참고 프로토타입
```

## Flutter 개발

```sh
cd app
flutter pub get
flutter run -d <iOS시뮬레이터ID> --dart-define=OPS_API_BASE=http://localhost:3100
```

연결된 Android/iOS 기기로 실행할 때는 `flutter devices`로 확인한 장치를 선택합니다. 개발자 웹의 `/app/` 미리보기는 **마지막으로 빌드한 버전**입니다. 새 코드를 반영하려면 루트에서 `npm run build:app` 후 미리보기 새로고침을 누릅니다. `flutter run`의 핫 리로드 세션과 구분합니다.

현재 공유 API는 개발자 웹과 같은 로컬 서버에서 실행됩니다. **웹은 `http://localhost:3100/app/`에서 확인하세요.** 별도 포트의 `flutter run -d chrome`은 같은 출처 API가 없으므로 그대로 연결되지 않습니다. 웹 개발 프록시는 아직 구성하지 않았습니다. iOS 시뮬레이터는 위 API 주소를 사용합니다. 실기기는 로컬호스트가 다르고 서버도 루프백 전용이므로 접근할 수 없습니다. 실기기 연동에는 별도의 인증된 개발 서버와 HTTPS 구성이 필요합니다. 임의로 서버를 외부 공개하지 마세요.

```sh
cd app
flutter build ios --simulator --debug --no-codesign
flutter build apk --debug
```

네이티브 빌드는 각 플랫폼 SDK와 라이선스 등 환경 준비가 필요합니다. iOS 시뮬레이터 빌드는 App Store 배포용 빌드가 아닙니다. 초기 번들 ID와 앱 아이콘은 개발용 값이며 출시 전 결정해야 합니다.

## 검증

```sh
npm run check
npm run test:console
cd app
flutter analyze
flutter test
```

실제 실행한 검증 및 빌드 결과는 개발자 웹의 개발 이력과 `docs/project-state.json`에 기록합니다.

## 현재 범위

Flutter 앱의 다섯 메뉴는 오늘 · 할 일 · 재고/발주 · 우리 팀 · 매장 지도입니다.

- 시간대·직급별 반복 업무, 재고 수량 확인, 누가·언제 완료했는지 표시
- 부족한 재료 모아 담기, 공급처별 수량 검토, 한 번에 **데모** 발주, 별도 입고 확인
- 마지막 발주에서 설정한 며칠 뒤 재고 확인 업무 생성 (중간 수량 확인으로 예정일이 밀리지 않음)
- 공유 근무표·휴가 공석·대체 가능 신청·관리자 확정, 사장님 전용 예시 정보
- 냉장고·창고·조리기구 위치와 예시 동선, 장소 안내 편집
- 오늘 화면에서 기존 첫 출근 가이드 진입: 연습과 버디 확인은 계속 구분

같은 로컬 서버를 보는 브라우저 창끼리 매장 상태를 공유하며 약 5초마다 갱신합니다. 서버는 `.local/operations-demo.json`에 기록하고 버전 충돌을 검사합니다. 하루 반복 업무는 한국 날짜 기준입니다. 재고 확인은 마지막 발주 시각에서 설정한 일수(24시간 단위) 뒤 한 번 생성하며, 중간 수량 확인·입고는 예정일을 미루지 않습니다. 완료 후에는 다음 발주 전까지 반복하지 않습니다. 새 발주는 이전 미완료 확인 업무를 대체하지만 기록을 삭제하지 않습니다. 기한 업무는 API 조회 때 생성되며 백그라운드 푸시 알림은 아닙니다. 발주는 재고를 늘리지 않고 입고 확인만 한 번 반영합니다.

사장님·매니저·조리 담당·크루 선택은 **데모 신원 전환**입니다. 응답 데이터의 예시 비공개 정보와 동작 제한을 역할별로 분리했지만 실제 인증·매장 소속 확인이 아니므로 운영 데이터에 사용할 수 없습니다. 실제 공급처 전송·결제·급여 계산·전자계약·근태 기록·교육 영상·푸시는 미구현입니다. 근무표와 지도는 샘플이며 실제 도면 편집·주간 스케줄러는 후속 범위입니다.

첫 출근 진행은 기존처럼 기기 내 저장입니다. 공유 업무 완료와 개인별 교육 이수는 서로 다른 기록이며 교육 완료를 공유 체크리스트로 대체하지 않습니다.

Flutter 체험 기록과 최초 HTML 프로토타입의 브라우저 기록은 별개입니다. 자동 마이그레이션하지 않습니다. 참고용 HTML 프로토타입은 `npm run dev:prototype`으로 http://localhost:3000 에서 열 수 있습니다.

프로젝트 표시 이름과 Dart 패키지는 `tap2work`입니다. 기존 설치와 연습 기록을 유지하기 위해 Android/iOS 번들 식별자 `com.tab2work.tab2work` 및 브라우저 저장 키는 이전 값을 유지합니다. 로컬 작업 폴더 경로는 `/Volumes/ORICO/tab2work`입니다.
