# App Store 심사 상세 점검 · 2026-10-18

## 현재 상태와 확인 범위

2026-10-18 17:32 KST Apple API 및 App Store Connect의 App Review 화면에서 TAP Work(6819216931), iOS 1.0.0 빌드 21의 `VALID / WAITING_FOR_REVIEW / AFTER_APPROVAL`을 확인했다. 현재 제출은 2026-10-13 22:33:30 KST, 조회 시 약 115시간 경과했다. 현재 제출 화면에 반려 사유나 Apple 메시지는 없었다. 과거 10개 완료 제출은 화면에서 `Removed`로 표시된다. 이것을 Apple 승인 또는 반복 반려로 해석하지 않는다.

심사 대기는 Apple이 아직 검토를 시작하지 않은 상태다. 내부 지연 사유는 확인하지 못했다. 과거 개발자 취소·재제출과 이번에 재현한 결함은 구분한다. [상태 정의](https://developer.apple.com/help/app-store-connect/reference/app-information/app-and-submission-statuses/), [취소하면 재제출 심사가 다시 시작됨](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/remove-a-submission-from-review).

기존 큰 미커밋 작업 트리를 보존하고 이번 관련 파일만 수정했다. 비공개 증거는 `.local/apple-review-audit-20261018/`에 있으며, 심사 계정·비밀번호·키는 이 문서에 포함하지 않는다.

## 발견 사항과 조치

| 우선순위 | 확인한 문제 | 조치와 적용 범위 |
|---|---|---|
| 높음 | 심사 메모가 권하는 비로그인 샘플에서 네이티브 `Uri.base`가 `file://…/review-data/owner.json`으로 해석됨. 빌드 21의 보관 소스에도 같은 코드가 있음 | `HttpOperationsRepository`에 플랫폼별 `sampleBase`를 도입. iOS/Android는 공개 HTTPS, 웹은 현재 하위 호스팅 경로. 수정 전 실패와 수정 후 통과, iPhone 시뮬레이터에서 실제 HTTPS 로딩·로그인 화면 버튼·웰컴·네 목적지 이동 확인. 기존 제출본 반영에는 새 빌드 교체 필요 |
| 높음 | 제출 IPA의 GoogleSignIn 개인정보 manifest에 있는 Coarse Location, Device ID, Other Usage Data, Other Data Types 및 User ID의 Analytics 목적이 App Privacy에 빠져 있음 | App Store Connect 신고를 10종→14종으로 보완하고 목적·식별 연결·추적 여부를 manifest와 대조. 기존 사진 신고는 이미 존재했으므로 누락이라고 판단하지 않음 |
| 중간 | 번들/웹 개인정보 방침에 실제 매뉴얼·장소·이상 보고 사진 처리 설명 없음 | 기기 JPEG 최적화·EXIF/GPS 제거·비공개 Storage·권한 있는 열람·매장 삭제 후 재시도 정리 설명과 Google SDK 처리 안내를 추가. `privacy.json` 단일 원본에서 웹 정책/삭제 페이지 재생성. 공개 웹 반영 여부는 아래 배포 결과 참조 |
| 중간 | 스토어 한국어·영어 설명이 한국어 중심/일부 인쇄 번역만 지원한다고 안내 | 실제 빌드 21부터 제공하는 8언어 주요 흐름·공용 사전 번역·매장 원문/직접 번역으로 수정. 두 locale API 저장 및 재조회 일치 |
| 중간 | iOS Info.plist에 Flutter의 8개 지원 언어 선언 없음 | `CFBundleLocalizations`: ko/en/vi/zh-Hans/ja/th/ne/id 추가. 새 빌드부터 적용 |
| 중간 | 심사 메모에 빌드 11·109 매뉴얼·크루 초대 미구현 등 과거 안내가 남아 있고 Google 자격증명을 미검증이라고 표시 | 등록된 Google 계정의 실제 비밀번호 로그인 성공, 선택적 패스키 생성은 건너뜀. Google 웹 로그인 성공은 네이티브 OAuth·앱 권한·저장·계정 삭제 성공과 다름. 빌드 22용 심사 메모를 별도 준비 |
| 중간 | iPhone/iPad 각 4장 스크린샷이 오래된 UI와 사전 준비 수량 블록을 표시 | 기존 이미지 다운로드·확인. 현재 Flutter 화면으로 교체 후보를 생성하는 도구 추가. 심사 대기 중 기존 스크린샷 교체는 아직 수행하지 않음 |

[Apple 심사 지침](https://developer.apple.com/app-store/review/guidelines/)은 작동하는 앱, 정확한 정보, 계정 기반 기능에 대한 충분한 접근을 요구한다. 읽기 전용 샘플을 모든 저장 기능을 검토하는 완전한 데모 모드라고 표현하지 않는다. 심사용 Google 로그인과 새 샘플 매장 생성 경로가 별도로 필요하다.

Google SDK 관련 판단은 제출 IPA 안의 `GoogleSignIn.bundle/PrivacyInfo.xcprivacy`와 [Google 공식 개인정보 안내](https://developers.google.com/identity/sign-in/ios/app-privacy)를 근거로 했다. SDK 신고와 앱 자체 GPS/광고 추적 기능을 혼동하지 않는다. [Apple App Privacy 작성 기준](https://developer.apple.com/app-store/app-privacy-details/)은 포함 SDK의 수집도 고려하도록 한다.

## 그 밖의 점검

- 기존 IPA: Apple 로그인 entitlement, Google callback, 네 공개 인증 설정 및 각 SDK privacy manifest 존재를 확인했다. 처리 상태 VALID는 실제 로그인 기능 검증을 대신하지 않는다.
- 홈페이지·개인정보·계정 삭제 안내·공개 owner 샘플 모두 HTTP 200. 공개 샘플은 실제 운영 계정과 분리된 데이터다.
- App Store 개인정보/삭제 URL 등록, 심사 연락처/계정 필드 존재, iPhone/iPad 자산 처리 COMPLETE, 비면제 암호화 false 확인.
- 연령 등급은 4+, Kids category 없음. [Apple의 UGC 연령 설문 정의](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)는 광범위한 사용자 콘텐츠 배포를 설명한다. 현재 매장 구성원 사이의 비공개 문서를 공개 소셜 피드로 간주해 등급을 임의 변경하지 않았다. 콘텐츠 범위가 확대되면 다시 검토한다.
- Apple/Google 인증 구현·취소 처리, 계정 삭제 범위 확인·Apple revoke·서버 본인 확인 코드를 점검하고 관련 자동 검사를 실행했다. 운영 계정이나 매장을 삭제하는 실험은 하지 않았다.

## 검증 결과

- 수정 전 회귀: 네이티브 sample URL 기대값 HTTPS, 실제 file URI로 실패.
- 수정 후 Flutter 관련 21개 통과: repository, cloud login, native token exchange mock, account, startup/sheets.
- 실제 iPhone 17 Pro / iOS 26.5 시뮬레이터: 공개 HTTPS 요청, 로그인 화면 샘플 버튼, 웰컴을 지나 네 목적지 이동 통합 검사 1개 통과.
- Flutter 분석 오류 0, Node account/cloud 관련 19개 통과, `npm run check` 및 UI 관계 87개 통과, Info.plist 구문 통과.
- iOS 1.0.0 빌드 22의 서명 Archive·App Store IPA 생성 완료, `codesign --verify --deep --strict` 통과. IPA의 8언어·공개 인증 설정 4개·새 정책 버전·SDK privacy manifest 15개를 직접 확인했다. SHA256: `20a970e29ffcb5710020e74b511981eb9f2bae6a053bdbb134b6143ebfd0e33d`.
- iPhone 1284×2778 / iPad 2064×2752의 현재 네 목적지 캡처 후보 8장 생성, 최종 렌더링 검사 통과. 첫 도구 실행은 위젯 테스트의 실제 HTTP 차단(400)으로 실패해 공개 샘플을 먼저 파일로 내려받도록 수정했다. Cupertino 폰트의 패키지 이름 누락·로고 사전 로딩과 테스트의 iOS 플랫폼 override 복원 누락도 고쳐 재생성했다. 실제 앱의 아이콘 결함으로 판단하지 않는다.
- 빌드는 기본 LaunchImage placeholder 경고 1건을 남겼다. Archive/IPA 생성은 성공했으며 이 경고가 Apple 심사 대기 원인이라는 증거는 없다. 이번 기능 수정과 별개의 시작 화면 정리는 후속 항목이다.
- 초기 Flutter 검사는 Mac 내부 임시 공간 부족(ENOSPC)으로 중단되어 외장 TMPDIR로 재실행했다. 첫 통합 검사 두 번은 테스트의 구형 NavigationBar 선택자 및 웰컴 처리 누락으로 실패했고, 실제 FloatingMenu/웰컴 흐름으로 교정한 최종 검사가 통과했다.
- 배포 CI 전체 Flutter 628개 통과·브라우저 전용 3개 skip, Node 서버 394개 통과, analysis 오류 0, UI87·Edge·격리 SQL 5개·번역 검사·웹 빌드·Pages 배포 모두 성공했다.
- 실기기 Apple/Google OAuth, 실제 계정 삭제, 카메라/HEIC, iPad 네이티브 설치·조작은 이번 검증에 포함하지 않았다.

## 재현 명령

`app/`에서:

```sh
flutter test test/operations_repository_test.dart test/cloud_workspace_test.dart test/native_auth_test.dart test/account_test.dart test/startup_and_sheet_test.dart
flutter test integration_test/public_preview_test.dart -d <iOS-or-Android-device-id>
mkdir -p ../.local/app-store-screenshots
curl --fail --output ../.local/app-store-screenshots/owner.json https://tap2.work/review-data/owner.json
flutter test tool/app_store_screenshots.dart
flutter analyze
```

캡처 명령은 `.local/app-store-screenshots/`에 iPhone/iPad 크기의 실제 Flutter 위젯 렌더링을 만든다. 실기기 촬영이라고 보고하지 않는다. 공개 샘플 GET 외 운영 서버 쓰기와 로그인은 하지 않는다.

## 배포와 남은 항목

App Store Connect 소개와 App Privacy 수정은 직접 반영했다. 새로고침 후 14개 유형, 사용자 연결, 광고 추적 없음이 유지되는 것을 확인했다. 기존 빌드 21의 제출 취소·새 빌드 연결·재제출, Apple 지원 메시지 전송은 하지 않았다. 빌드 22 IPA, 캡처 후보 8장, `docs/app-store/review-notes-build22.txt`를 준비했고 이전 스크린샷 8장도 별도 보존했다. Apple 승인 여부는 여전히 미확인이다.

빌드 22의 첫 altool 업로드는 Mac 내부 ENOSPC로 실패했다. 기존 사용자 파일/캐시를 삭제하거나 이동하지 않고 [Apple 공식 Build Upload API](https://developer.apple.com/documentation/appstoreconnectapi/post-v1-builduploads)를 이용해 같은 IPA를 업로드했다. API 체크섬 입력에서 SHA_256 지원 및 multipart 조합 순서·청크 크기 규칙의 409 오류를 교정했고, 전송한 10개 청크 각각의 ETag가 원본 MD5와 일치함을 확인한 후 commit이 COMPLETE가 됐다. 18:04 KST 서버 PROCESSING 확인. 이 상태는 심사 승인과 다르다. altool의 iOS 15 최소 지원 경고는 2027년 4월 적용 안내였으며 현재 업로드 실패 원인은 로컬 저장 공간이었다.

선택한 18개 관련 파일만 격리 작업 트리에서 `7f18f49`로 커밋하여 main에 반영했다. [Pages 실행 39113779070](https://github.com/ljae/tap2work/actions/runs/39113779070)의 검증·배포 성공 후 공개 개인정보 방침·삭제 안내·앱 번들 정책 JSON 모두 HTTP 200 및 로컬 원본 SHA256 일치를 확인했다. 원래 작업 트리의 미커밋 변경은 그대로 보존했다.

최종 Apple 결과: **1.0.0 빌드 22 VALID**, 업로드 COMPLETE, 비면제 암호화 없음. 기존 제출은 **빌드 21 WAITING_FOR_REVIEW / AFTER_APPROVAL**로 유지했다. 새 빌드는 아직 심사에 연결하거나 내부 테스트 그룹에 배포하지 않았다. 새 스크린샷과 안내문도 교체 전 준비 상태다. 알려진 샘플 오류를 반영한 빌드 22 재제출을 권고했으며, 기존 약 5일의 심사 대기가 초기화되는 영향을 설명하고 교체 여부를 사용자에게 확인 요청했다. 응답 전에는 기존 제출을 취소하지 않는다.
