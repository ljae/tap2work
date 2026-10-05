# App Store 출시·매장 구독 준비

작성: 2026-10-05. 준비 상태 점검과 출시 계획이며 App Store 제출·승인 기록이 아니다.

## 확정 사항

- 앱 표시 이름 **TAP Work**, 사용자 선택 `TapWater_logo.png` 로고. 이전 로고 소스/보관본 삭제.

- iOS App Store에서 무료로 다운로드한다.
- 향후 추가 기능을 구독으로 제공한다. 사장님이 매장 단위로 결제하고 소속 크루가 함께 이용한다.
- 사용자는 Apple Developer Program에 이미 가입되어 있다. 가입 명의, App Store Connect 앱 생성 여부, 인증서·프로파일 상태는 아직 확인하지 않았다.
- 구독 가격·기간·무료/유료 기능 경계·체험 기간은 미정이다. 기존 기능을 임의로 유료화하지 않는다.

## 현재 소스에서 확인한 상태

| 항목 | 확인 결과 | 제출 전 작업 |
|---|---|---|
| Flutter iOS 프로젝트 | `app/ios` 존재, 버전 `0.3.0+3` | 출시 버전·빌드 번호 설정 |
| Bundle ID | `com.tap2work.tap2work` | 사용자 요청으로 iOS 앱 및 RunnerTests의 Debug/Profile/Release 설정 변경. Apple Developer에 새 Explicit App ID 등록 및 서명 연결 필요 |
| 서명 | Xcode 프로젝트에 팀 설정 존재 | 가입 팀·배포 인증서·프로파일·App Store archive 확인 |
| 빌드 환경 | 로컬 Xcode 26.6 확인 | 제출 시점의 Apple SDK 요구사항 확인 및 실제 iOS archive |
| 로그인 | Apple/Google 네이티브 개인 로그인 및 웹 OAuth 로컬 구현. 공용 진입 제거 | OAuth client/provider/Apple 키 설정, 서버 배포 및 실기기 왕복. 실제 크루 초대 가입은 별도 |
| 구독 | pubspec과 앱/서버 소스 검색에서 IAP 연동을 찾지 못함 | 구독 도입 시 StoreKit 기반 구매·복원·서버 검증 구현 |
| 개인정보·삭제 | OpenEdu 방침 앱/웹, 삭제 범위 확인, Apple revoke와 원자 DB 삭제 구현·테스트 | 운영 보존/위탁 조건 확인, migration/함수/공개 페이지 배포, 테스트 계정 실기기 삭제 |

소스 검색은 전체 개인정보 감사나 네이티브 동작 검증이 아니다. 후속 작업에서 iOS 시뮬레이터 debug/no-codesign 빌드와 웹 빌드, Flutter 분석/관련 테스트 및 서버·격리 SQL 검증을 통과했다. 서명 Archive, 실기기 OAuth·삭제, TestFlight 업로드는 수행하지 않았다. [Google·Apple 설정 순서](NATIVE_AUTH_SETUP.md).

## 무료 출시 순서 · 제안

1. App Store Connect 기존 앱과 Bundle ID, 등록 명의·서명 팀을 확인한다. 새 앱이 필요하면 iOS 앱을 만들고 앱 가격을 무료로 설정한다.
2. 임시 공용 로그인을 출시용 개인별 인증으로 전환하고 매장 생성·초대·크루 소속과 직책 검증을 완성한다. 로그인 없이 제공하는 샘플은 실매장과 분리한다. 소셜 로그인 도입 시 심사 지침 4.8 적용 여부를 확인한다.
3. 개인정보처리방침·지원 URL·연락처·계정 삭제를 준비한다. 매장 공동 업무 기록의 보존/익명화와 개인 계정 삭제 범위를 정의한다. 계정 삭제와 Apple 구독 취소는 별개로 안내한다.
4. iPhone/iPad 지원 범위, PDF 저장·인쇄·파일 선택·로그인 복귀·실제 HTTPS 서버 연결을 기기에서 확인한다. Release 빌드에 Supabase 공개 설정을 명시하고 데모/localhost로의 잘못된 진입을 검사한다. 비밀 키는 앱에 포함하지 않는다.
5. Flutter 분석·관련 테스트·iOS archive를 검증하고 TestFlight에서 설치·재실행·권한·충돌·계정 삭제를 확인한다. 웹 빌드 성공을 네이티브 검증으로 대체하지 않는다.
6. 한국어 앱 설명·스크린샷·아이콘·연령 등급·App Privacy·암호화 신고·심사용 계정/사용 방법을 제출한다. 실계정·자격증명은 저장소나 결정 이력에 쓰지 않는다. 심사 중 서버와 테스트 매장을 유지한다.

무료 버전을 먼저 출시하고 구독 기능은 후속 업데이트로 심사받는 순서를 제안한다. 무료 출시의 완료 시점과 구독 동시 출시 여부는 아직 확정하지 않았다.

## 매장 구독 구조 · 구현 전 제안

- 일반적인 앱 내 추가 기능 구매는 Apple 자동 갱신 인앱구독을 기준으로 설계한다. 사업장 앱이라는 이유만으로 기업 판매 예외가 자동 적용되는 것은 아니다. 웹 결제나 한국 대체결제를 채택한다면 해당 조건·권한·계약을 별도 확인한다.
- 사장님의 앱 계정·매장 ID와 Apple 거래를 서버에서 연결한다. 크루는 같은 매장의 이용권을 소비하며 개인 구매를 요구하지 않는다. Apple 가족 공유를 매장 공유 모델로 취급하지 않는다.
- 서버가 검증한 거래와 갱신·만료·환불 이벤트로 매장 이용권을 관리한다. 앱의 결제 성공 표시나 기기 로컬 플래그만으로 유료 API를 허용하지 않는다.
- 유료 기능 사용에는 매장 이용권과 기존 직책 권한을 모두 검사한다. 구독은 크루에게 사장님의 급여·연락처·편집 권한을 부여하지 않는다.
- 구매 복원, 새 기기 로그인, 중복 거래/알림, 결제 실패·유예·만료·환불, 샌드박스와 운영 분리를 검증한다. 만료 시 기존 매장 기록을 삭제하지 않도록 정책을 준비한다.
- 다매장 구매, 사장 변경·퇴사, Apple 계정과 앱 계정 불일치, 거래의 다른 매장 재연결 정책은 미정이다. 한 거래를 여러 매장에 중복 귀속시키지 않도록 서버 정책이 필요하다.
- 구매 화면에는 실제 상품의 가격·기간·자동 갱신 조건·제공 기능·이용약관·개인정보처리방침을 표시하고 복원·구독 관리 동선을 제공한다.
- 구독 판매 전 Account Holder가 유료 앱 계약을 체결하고 세금·은행 정보를 등록한다. 첫 구독 상품은 Apple 제출 절차에 따라 앱 버전과 함께 심사받는다.

식자재 등 실제 물품 구매와 앱의 디지털 기능 구독은 별도 결제다. 실제 거래처 주문·결제 연동은 이 계획으로 승인된 것으로 취급하지 않는다.

## 비용과 정책 참고

- 앱 다운로드 가격은 무료로 설정할 수 있다. 일반적인 Developer Program 회원비는 연 US$99이며 지역별 실제 청구액은 가입 화면 기준이다. 사용자는 이미 가입했으므로 현재 회원 자격·갱신만 확인하면 된다.
- Apple의 일반 자동 갱신 구독 조건은 첫 유료 서비스 1년 수익 배분 70%, 이후 85%이며 세금이 별도로 반영된다. Small Business Program 가입 시 일반적으로 처음부터 85%다. 승인 여부와 적용 계약을 확인하고 가격을 결정한다.

Apple 공식 문서 확인: 2026-10-05. 제출 시점에 다시 확인한다.

- [개발자 가입·등록 명의·회원비](https://developer.apple.com/programs/enroll/)
- [자동 갱신 구독·설정·수익 배분](https://developer.apple.com/app-store/subscriptions/)
- [심사 지침: 3.1 결제, 4.8 로그인, 5.1 개인정보](https://developer.apple.com/app-store/review/guidelines/)
- [유료 앱 계약](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/)
- [앱 내 계정 삭제](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
- [제출 시 요구사항](https://developer.apple.com/news/upcoming-requirements/)

## 이번 검증 범위

실시: 프로젝트 결정·제품·아키텍처와 iOS 설정/의존성/인증 소스 읽기, 관련 소스 검색, Xcode 버전 확인, Apple 공식 정책 확인, 문서·결정 JSON 검증.

미실시: Flutter 분석/테스트, 서버 테스트, iOS 빌드/서명 검증, 실제 기기 실행, App Store Connect 접근, 상품 생성, 결제 테스트, 제출·외부 배포. 앱·API 코드는 변경하지 않았다.

## Bundle ID 철자 변경 · 2026-10-05

사용자 요청으로 iOS Bundle ID를 `com.tab2work.tab2work`에서 `com.tap2work.tap2work`로 변경했다. RunnerTests는 `com.tap2work.tap2work.RunnerTests`다. Apple Developer의 기존 App ID는 직접 변경하지 않고 새 Explicit App ID를 등록한다. App Store Connect에 아직 빌드를 업로드하지 않았다면 앱 정보에서 새 Bundle ID를 선택할 수 있지만, 이미 업로드했다면 해당 앱 레코드의 Bundle ID는 변경할 수 없어 새 앱 등록이 필요하다. Apple 계정의 등록/업로드 상태는 확인 전이며 외부 등록·삭제를 수행하지 않았다.

[Apple Bundle ID 변경 안내](https://developer.apple.com/documentation/xcode/changing-the-bundle-identifier)

Bundle ID 변경 검증: Xcode/Info.plist 구문 검사와 6개 구성 식별자 검사, Flutter 분석, 시작/시트 관련 테스트 7개 통과. 네이티브 빌드·서명·Apple 계정 등록은 미실시.
