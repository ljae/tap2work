# Apple 등록·심사 점검과 ITMS-90068 수정 · 2026-10-23

## 현재 제출

사용자가 지정한 Ego Lite(`ego-browser`, task space 7)로 App Store Connect 화면을 확인하고 Apple API 결과와 대조했다. TAP Work / `com.tap2work.tap2work` / app 6819216931의 iOS 1.0.0 빌드 23은 `VALID`, 현재 버전·제출은 `WAITING_FOR_REVIEW`, 출시 방식은 `AFTER_APPROVAL`이다. 제출 `17c1437e-cc5c-4c9c-93e5-7306155280a3`의 접수 시각은 **2026-10-21 23:14:09 KST**이며 10/23 15시대 기준 약 40시간이다.

현재 제출 상세에는 Apple 메시지나 보완 요청이 없다. 화면에 표시되는 이전 10개 제출은 `Removed`이며 API의 `COMPLETE`를 승인이나 반려로 해석하지 않는다. 여러 차례 취소·재제출하면서 대기가 새로 시작된 이력이 있다. Apple 내부의 실제 지연 사유나 심사 시작 시각은 확인할 수 없다. [상태 설명](https://developer.apple.com/help/app-review/after-submitting-for-review/review-status), [취소·재제출 시 심사 재시작](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/remove-a-submission-from-review).

**기존 빌드 23의 심사 제출은 유지한다.** 이번 최소 OS 수정은 새 빌드를 업로드해 검증하며, 진행 중인 제출을 취소하거나 빌드를 바꾸지 않는다. Apple 지원 메시지나 심사 촉진 요청은 보내지 않았다.

## ITMS-90068 원인과 수정

실제 빌드 23의 업로드 응답에서 `errors=[]`, `warnings[0].code=90068`을 확인했다. 내용은 iOS 13.0 대상 앱에 대한 2027년 4월부터 iOS 15.0 이상 요구 안내다. 빌드 23은 이후 처리 VALID와 심사 접수를 통과했으므로 이 경고를 현재 심사 차단 오류로 판단하지 않는다. [Apple 제출 요구사항](https://developer.apple.com/app-store/submitting/).

Runner Debug/Profile/Release의 `IPHONEOS_DEPLOYMENT_TARGET` 및 Podfile 플랫폼을 **13.0 → 15.0**으로 통일하고 Podfile.lock 체크섬을 갱신했다. 앱 식별자·서명 팀·인증 설정·데이터 계약은 유지한다. iOS 13/14는 새 빌드의 지원 범위에서 제외된다. 외부 SDK/Flutter framework의 하위 최소 OS는 앱의 15.0보다 높지 않아 그대로 유지한다.

격리 작업 트리 `.local/apple-target-release`는 공개 main `8b8377b`에서 생성했다. 원래 작업 트리의 기존 미커밋 작업을 보존했다. 빌드 24는 최신 공개 UI(검색 범위·접힘·너비 수정 포함)를 기반으로 하므로, 나중에 심사 빌드를 교체한다면 빌드 23용 현재 스크린샷·심사 메모도 함께 갱신해야 한다.

## 등록 항목 점검

| 항목 | 실제 확인 결과 |
|---|---|
| 제출·빌드 | 1.0.0(23), VALID / WAITING_FOR_REVIEW, 승인 후 자동 출시 |
| 심사 접근 | 로그인 필수, 심사용 계정·암호·안내문 및 이름·이메일·전화 연락처 모두 존재. 이번에는 실제 로그인 왕복을 재검증하지 않음 |
| 스크린샷 | 기본 en-US의 iPhone 1284×2778 4장, iPad 2064×2752 4장 모두 COMPLETE·오류 없음. ko는 별도 이미지 없음; 기본 언어 이미지 사용 |
| 스토어 소개 | ko/en-US 이름·부제·소개·지원/마케팅 URL 등록. 앱 내 8개 언어와 스토어 소개 번역 수는 별개 |
| 개인정보 | 14종 신고 Published. 식별 연결·앱 기능/분석 목적 표시, 광고 추적 신고 없음. 기존 Google SDK 관련 보완 유지 |
| 정책·삭제·지원 | 개인정보 URL 및 Privacy Choices URL 등록. Ego Lite로 두 공개 페이지 본문과 문의 이메일 표시 확인. 지원 URL은 개인정보 페이지를 사용하며 연락처가 있음 |
| 분류·연령 | Business, 기본 4+ 및 지역별 등급, Kids category 없음. 콘텐츠 권리 확인 및 표준 EULA |
| 수출 규정 | 제출 중인 빌드 23의 `usesNonExemptEncryption=false`. 새 빌드 24도 같은 표준 통신 사용을 근거로 false 저장·재조회 |
| 가격·지역 | 무료(기준 가격 USD 0), 175개 지역 선택, 새 지역 자동 포함. 아직 출시 전이라 API 지역 상태는 CANNOT_SELL / AVAILABLE_FOR_SALE_UNRELEASED_APP |
| 계약 | Free Apps Agreement 및 Paid Apps Agreement 모두 Active |
| 정산·세금 | 등록 은행 상태 Active, 한국 세금 양식·미국 외국인 수익자 증명·W-8BEN 모두 Active. 개인정보·계좌 상세는 기록하지 않음 |
| 규제 | 계정 DSA 및 Korea e-Commerce Act Active, 앱은 trader로 식별됨. 중국 ICP 번호 미등록; 관련 허가가 필요한 경우의 지역 배포 제약은 별도 확인 대상 |
| TestFlight | 빌드 23 내부 테스트 그룹 연결/IN_BETA_TESTING. 외부 베타는 READY_FOR_BETA_SUBMISSION이며 App Store 심사 대기와 별개. 예전 미사용 빌드 18에는 Missing Compliance 표시가 있으나 현재 제출 빌드 23의 차단 사유가 아님 |
| Mac/Vision | 호환 기기 배포 설정이 보이지만 실제 호환성 실행 검증은 하지 않음. 임의로 검증 완료를 선언하지 않음 |

이번 점검 범위에서 등록 누락 때문에 현재 제출이 보완 대기 또는 반려 상태라는 증거는 없다. `WAITING_FOR_REVIEW`는 승인이나 실제 심사 시작이 아니다.

## 검증·새 업로드 결과

- Xcode 26.6 서명 Archive 및 App Store IPA 생성 성공. IPA의 `MinimumOSVersion=15.0`, 버전 1.0.0, 빌드 24 및 Bundle ID 확인. Archive와 export IPA 각각 `codesign --verify --deep --strict` 통과, 배포 서명·Apple Sign In entitlement·get-task-allow=false 확인. 포함 실행 번들의 최소 OS가 모두 앱의 15.0 이하다.
- IPA SHA256: `8d3eed9bc1757fb38f54e610fcb84e10a970a49d956c8f901ab5ade54e349039`.
- 기존 공개 인증 설정 4개(Supabase URL/publishable key, Google iOS/Web client)와 callback 포함, 8언어 선언 유지. SDK 개인정보 manifest 15개는 빌드 23과 모두 동일하다.
- Flutter 분석 오류 0, 인증·계정·클라우드 진입·repository 관련 12개 테스트 통과. 전체 Flutter UI 테스트는 이번에 다시 실행하지 않았으며 동일 Dart 소스의 기존 공개 배포 CI 결과는 649개 통과/브라우저 전용 3개 skip이다.
- Ruby Podfile 구문·Xcode project plist·git diff 공백 및 `npm run check`(UI 관계 92개 포함) 검사 통과.
- Apple 공식 업로드 API로 10개 청크 전송, 각 응답 ETag/MD5 검증 및 바이트 순서 multipart 체크섬 확정. 파일 전송 및 Apple 업로드 처리 COMPLETE, 오류 0·경고 0. **2026-10-23 15:29 KST 빌드 24 VALID / minOS 15.0 확인**, ITMS-90068이 새 업로드에서 사라졌다. 이 결과는 심사 승인이 아니다. 빌드 24의 수출 규정 답변 false를 저장·재조회했고 READY_FOR_BETA_TESTING / READY_FOR_BETA_SUBMISSION이다. 별도 내부 그룹 배포·초대·알림을 실행하지 않았다.
- iPhone 17 Pro / iOS 26.5 시뮬레이터에서 공개 HTTPS 샘플 로딩→로그인 화면 샘플 버튼→웰컴→네 목적지 이동 통합 검사 1개 통과. 이는 별도 테스트용 비영속 인증 클라이언트를 사용하며 실계정 OAuth 검증은 아니다.
- iOS 15 런타임이 설치되어 있지 않아 최소 버전 실제 실행은 미검증. 실기기 OAuth·계정 삭제·카메라·iPad/Mac/Vision 실행과 원어민 검수는 미수행이다.
- Flutter의 기존 기본 LaunchImage placeholder 경고는 남아 있다. 빌드/업로드 차단이나 심사 지연 원인이라는 증거가 없으며 이번 최소 OS 수정과 구분한다.

최종 재조회: 빌드 24 VALID / iOS 15.0 / 경고 0, Ego Lite TestFlight 화면 Ready to Submit. 기존 버전·제출은 빌드 23 / WAITING_FOR_REVIEW / AFTER_APPROVAL / 접수 시각 유지. 웹·Android·운영 DB 변경 및 새 심사 제출은 하지 않았다.

비공개 증거: `.local/apple-status-20261023/`. 심사 자격증명·API 키·은행/사업자 상세는 저장소와 공개 문서에 포함하지 않는다.
