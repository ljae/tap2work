# TAP Work 로그인·개인정보·계정 삭제 설정

2026-10-05. 운영자 **OpenEdu**, 문의 **esther.runstrict@gmail.com**. Aside CLI로 실제 콘솔을 확인하고 Google/Apple provider, Apple 키, 서버 secrets, callback 설정을 완료했다. 삭제 SQL과 account/operations/public-login 함수·tap2.work 웹 배포를 완료했다. iOS 1.0.0 빌드 5 서명 IPA가 Apple 처리 VALID를 통과하고 iOS 제출 준비 버전에 연결되었다. 실기기 로그인은 별도다. 참고 앱 runner와 같은 네이티브 SDK → ID token → Supabase 구조이며 TAP Work 전용 OAuth 값을 사용한다.

## 실제 설정 확인 결과

| 항목 | 확인·적용 값 |
| --- | --- |
| Supabase 프로젝트 | `sgpmhqtaylgqymeqciin` |
| Google Cloud 프로젝트 | `tap-work-510711` |
| Google iOS client | `897277058675-kl58mdebu68nhdvpn7tpihu046v3gkqm.apps.googleusercontent.com` |
| Google Web/server client | `897277058675-b7tb4kci1hcmumq57ghpvfkv4l6881u7.apps.googleusercontent.com` |
| Apple Team | `RQZACLWJ7M` |
| Apple primary App ID | `com.tap2work.tap2work` — Sign in with Apple 활성화 확인 |
| App Store 숫자 ID | `6819216931` — Google iOS client 등록 값 |
| Apple Services ID | `com.tap2work.tap2work.web` — 위 primary App ID 연결 |
| Apple Key ID | `BY6QCTR4RP` — TAP Work 전용 키 발급 |
| Apple OAuth JWT 만료 | **2027-04-03 12:52:11 UTC (한국 21:52:11)** — 만료 전에 교체 필요 |

Google 웹 클라이언트에 새 secret을 추가해 Supabase에 설정했다. 기존 secret은 다른 사용처를 끊지 않도록 유지했으며 실제 로그인 검증 후 정리할 수 있다. Apple provider 초안에 들어 있던 Google secret은 Apple 서명 JWT로 교체했다. Google nonce 검사 우회와 이메일 없는 가입 허용은 켜지 않았다.

Google Audience는 **External / 프로덕션 단계**로 전환했다. 전환 전에는 테스트 사용자 1명으로 제한되어 있었다. Branding 이름을 `TAP work`에서 **TAP Work**로 저장했다. 홈페이지·개인정보 링크와 개발자 연락처 `esther.runstrict@gmail.com`은 등록되어 있다. 사용자 지원 이메일은 현재 로그인 계정 `ljae.m10@gmail.com`만 선택 가능해 유지했다. 지정한 문의 이메일로 바꾸려면 해당 계정으로 프로젝트에 접근해 선택 가능한지 확인해야 한다. Google 동의 화면의 브랜드 로고 업로드·별도 브랜드 검증은 미완료다.

Apple `.p8` 다운로드 파일은 `~/Downloads/AuthKey_BY6QCTR4RP.p8`에 있다. 재다운로드할 수 없으므로 별도 안전한 보관소에 백업한다. 작업용 사본과 CLI secrets 파일은 Git 제외된 `.local/private-auth/`에 권한 600으로 보관했다. `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SERVICE_ID`, `APPLE_PRIVATE_KEY` 네 서버 secrets 저장 및 등록 이름을 확인했다. 키 원문은 앱·문서에 포함하지 않는다.

Google/Apple authorize 요청은 각각 `accounts.google.com`/`appleid.apple.com`으로 HTTP 302이며 TAP Work의 web client/Services ID를 사용한다. 이는 로그인 시작 검증이며 사용자 동의·토큰 교환·실제 계정 삭제 성공을 의미하지 않는다. 로컬 `.env`, 공개 define, Google callback xcconfig도 갱신했다. Xcode 팀은 기존 `7ZSUCG54Q4`에서 실제 App ID 소유 팀 `RQZACLWJ7M`으로 수정했다. 서명 인증서·프로파일·실기기 빌드는 별도 검증 대상이다.

## 1. Google Cloud 설정 절차

[Google Cloud Console](https://console.cloud.google.com/)에서 TAP Work용 프로젝트를 선택하거나 생성한다. **Google Auth Platform** 메뉴를 연다(이전 UI는 APIs & Services → OAuth consent screen/Credentials).

1. **Branding**: 앱 이름 `TAP Work`, 지원/개발자 이메일 `esther.runstrict@gmail.com`. 홈페이지 `https://tap2.work/`, 개인정보처리방침 `https://tap2.work/privacy/`를 입력한다. 방침 URL은 이번 웹 변경을 배포한 뒤 실제 열리는지 확인해야 한다. 도메인 소유 확인이 요구되면 `tap2.work`를 확인한다.
2. **Audience**: 일반 고객용은 External. 테스트 단계에는 본인/테스터 Google 이메일을 Test users에 추가한다. 출시 전 Publishing status와 요청되는 브랜드 검증을 완료한다.
3. **Data Access**: `openid`, 이메일, 기본 프로필만 사용한다. Gmail·Drive 권한은 필요하지 않다.
4. **Clients → Create client → iOS**:
   - 이름: `TAP Work iOS`
   - Bundle ID: **`com.tap2work.tap2work`**
   - Apple Team ID: **`RQZACLWJ7M`**.
   - App Store ID는 발급받은 숫자 ID가 있을 때 입력한다. SKU나 Bundle ID가 아니다.
   - 생성된 Client ID를 `GOOGLE_IOS_CLIENT_ID`로 사용한다.
5. **Clients → Create client → Web application**:
   - 이름: `TAP Work Web and Server`
   - Authorized JavaScript origins: `https://tap2.work`, `https://www.tap2.work`
   - Authorized redirect URI: **`https://sgpmhqtaylgqymeqciin.supabase.co/auth/v1/callback`**
   - Client ID를 `GOOGLE_WEB_CLIENT_ID`로 사용한다. **Client secret은 Supabase 서버 설정에만 입력**한다.
6. Supabase 프로젝트 → **Authentication → Sign In / Providers → Google**을 활성화한다. Client IDs는 **웹 ID를 첫 번째**, iOS ID를 추가한다(쉼표 구분 목록). Client secret에는 위 웹 클라이언트의 secret을 입력한다. 기본 이메일 로그인은 출시 설정에서 비활성화한다.

현재 iOS 네이티브 로그인은 Google SDK의 ID token을 Supabase가 검증하는 방식이다. 앱에 웹 Client ID가 필요한 것은 server audience를 지정하기 위해서다. 비밀번호나 Client secret을 앱에 넣지 않는다.

Android도 출시하려면 별도의 Android OAuth client가 필요하다. 현재 소스의 applicationId는 **`com.tab2work.tab2work`**이며 iOS의 새 Bundle ID와 다르다. Android 앱 ID 변경 여부를 먼저 확정한 뒤 해당 ID + debug/release/Play App Signing SHA-1에 맞게 클라이언트를 등록한다. Android ID는 이번 작업에서 임의 변경하지 않았다.

공식 근거: [Supabase Google 설정](https://supabase.com/docs/guides/auth/social-login/auth-google), [Flutter Google iOS SDK 설정](https://pub.dev/packages/google_sign_in_ios).

## 2. Apple Developer·Supabase 설정

- Certificates, Identifiers & Profiles → Identifiers → App ID **`com.tap2work.tap2work`** → **Sign in with Apple** 활성화. 변경된 entitlement를 포함한 프로비저닝 프로파일을 갱신한다. Xcode Runner에는 이미 해당 entitlement를 연결했다.
- 웹/Android Apple 로그인용 Services ID `com.tap2work.tap2work.web`를 만들었다. Sign in with Apple 설정에서 위 App ID를 연결하고 도메인 `sgpmhqtaylgqymeqciin.supabase.co`, Return URL `https://sgpmhqtaylgqymeqciin.supabase.co/auth/v1/callback`을 등록했다.
- Keys → Sign in with Apple 키를 만들고 위 primary App ID에 연결한다. Key ID, Team ID, 내려받은 `.p8`를 안전한 로컬 위치에 보관한다.
- Supabase Apple provider의 허용 Client IDs에 네이티브 Bundle ID와 웹 Services ID를 등록한다. 브라우저 OAuth용 secret은 Apple 개인키로 만든 만료일이 있는 JWT이다. Supabase 공식 안내에 따라 생성·입력하고 만료 전에 교체한다. `.p8` 원문 자체를 OAuth secret 칸에 넣지 않는다.
- 계정 삭제용 `account` Edge Function에는 아래 **서버 secrets**를 별도로 설정한다. 함수가 짧은 수명의 client secret을 요청마다 생성하고 Apple 토큰을 해제한다.

| 서버 secret | 값 |
| --- | --- |
| `APPLE_TEAM_ID` | Apple 팀 ID |
| `APPLE_KEY_ID` | Sign in with Apple 키 ID |
| `APPLE_PRIVATE_KEY` | `.p8` 전체 PEM 내용. 줄바꿈 또는 `\n` 지원 |
| `APPLE_SERVICE_ID` | 실제 만든 웹 Services ID |

`.p8`, Google Client secret, Supabase 서비스 키를 채팅·소스·Flutter define에 넣지 않는다. Supabase Dashboard의 Edge Function Secrets에 직접 입력하거나, Git에 포함하지 않는 제한된 로컬 secrets 파일로 CLI에 전달한다.

Supabase **URL Configuration**: Site URL `https://tap2.work/`. Redirect URLs에 `https://tap2.work/`, `https://www.tap2.work/`, `com.tap2work.tap2work://login-callback`을 등록한다. 개발 주소는 필요한 주소만 별도 추가한다. 계정 API는 기본적으로 tap2.work와 www.tap2.work Origin만 허용한다.

공식 근거: [Supabase Apple 설정](https://supabase.com/docs/guides/auth/social-login/auth-apple), [Apple 계정 삭제 안내](https://developer.apple.com/support/offering-account-deletion-in-your-app/).

## 3. 로컬 네이티브 설정

Git에서 제외되는 루트 `.env`에 기존 Supabase 공개 설정과 아래 공개 Client ID 두 개를 추가한다. 실제 secret은 이 스크립트가 읽거나 내보내지 않는다.

```dotenv
GOOGLE_IOS_CLIENT_ID=발급받은-iOS-ID.apps.googleusercontent.com
GOOGLE_WEB_CLIENT_ID=발급받은-web-ID.apps.googleusercontent.com
```

루트에서:

```sh
node --env-file=.env scripts/configure-native-auth.mjs
```

생성물: `.local/native-auth.json`(허용된 공개 define만), `app/ios/Flutter/Auth.xcconfig`(Google 역순 URL scheme). 둘 다 Git 제외다. 샘플 ID로는 실제 로그인이 되지 않는다.

`app/`에서:

```sh
flutter run --dart-define-from-file=../.local/native-auth.json
flutter build ipa --dart-define-from-file=../.local/native-auth.json
```

Google iOS callback은 Client ID를 점 단위로 뒤집은 값(`com.googleusercontent.apps.…`)으로 자동 생성된다. 이 설정 없이 Google 버튼을 실제 기기에서 사용하지 않는다. iOS Archive는 Developer 팀·인증서·프로파일 설정이 필요하다.

## 4. 배포 순서와 삭제 계약

1. OAuth provider, Apple 서버 secrets, URL 설정은 완료했다. Google Audience 공개 전환은 완료했으며 필요한 브랜드/도메인 검증은 별도로 확인한다. 이전 계정 복구 경로를 임의로 끊지 않도록 이메일 provider 자체는 유지한다. 새 앱 진입과 operations는 Apple/Google identity를 요구하고 공용 로그인 발급 함수는 비활성화했다.
2. `20261005010000_account_deletion.sql`을 기존 workspace/section migrations가 설치된 서버에 적용한다. 이번 파일은 원본 매장 데이터를 즉시 삭제하지 않고 service-only 삭제 함수를 추가한다. 기존 `backend:deploy`는 모든 과거 migration을 재실행하므로 이번 변경만 확인 없이 적용하는 용도로 쓰지 않는다.
3. `account`, `operations`, `public-login` 세 Edge Function을 배포한다. `account`와 `operations`는 handler가 직접 bearer token을 검증한다. `operations`는 Apple/Google identity 없는 기존 공용 세션의 접근을 거절하고 `public-login`은 새 세션 발급을 중단한다. 구 공용 매장은 자동 삭제/이전하지 않는다.
4. 웹 앱과 정적 `/privacy/`, `/delete-account/` 페이지를 함께 배포한다. `npm run build:site`가 공개 리뷰용 전체 산출물을 만들며 `.local`은 공개하지 않는다. 두 URL을 실제 열어 확인한 뒤 스토어에 등록한다.
5. 테스트 전용 계정/매장으로 로그인 → 재실행 → 취소 → 로그아웃 → 재로그인 → 계정 삭제를 검증한다. Apple/Google, iOS 실기기, 웹, Android는 각각 검증한다. 유일 사장님/다른 사장님 존재/크루/매장 없는 계정과 타 기기 세션도 포함한다. 운영 계정을 검증용으로 삭제하지 않는다.

삭제 preview는 서버가 검증한 본인 계정·매장·소속 전체·revision의 fingerprint를 반환한다. 최종 확인 당시 상태가 바뀌면 409로 재확인을 요구한다. Apple 계정은 토큰 교환으로 같은 Apple subject임을 확인한 뒤 revoke한다. 이어 DB 트랜잭션에서 개인 기록과 기존 recovery payload를 정리하고 Auth identity/session을 cascade 삭제한다. 유일 사장님이면 매장과 소속을 함께 삭제한다. 다른 사장님이 남으면 원 생성자 FK를 남은 사장님으로 넘겨 매장 cascade를 막는다. Apple 외부 revoke와 PostgreSQL은 하나의 분산 트랜잭션이 아니므로 revoke 후 DB 실패 시 다시 본인 확인/삭제 범위 조회가 필요하다.

현재 크루 초대·실제 계정 소속 연결은 별도 미구현 범위다. 이 변경이 초대 QR을 실제 가입 경로로 바꾸지는 않는다. 삭제는 서버에 실제 연결된 membership와 actorId를 기준으로 처리한다. 임의로 입력된 다른 사람의 자유 텍스트는 문의 채널로 추가 삭제할 수 있다.

## 5. 공개 전 운영 확인

개인정보처리방침은 현재 코드·확인된 DB 리전과 사용자 답변을 반영했다. 공급자 보안 로그의 정확한 보존 기간, 국외 처리·하위 처리자 계약, 개인정보 담당자의 운영 절차는 OpenEdu가 확인하고 공개 전에 문서를 보완해야 한다. 자동 법률 적합성 판정을 제공하지 않는다. 향후 결제/위치/파일 업로드/백업을 켜면 처리 항목과 기간도 갱신한다.

App Store 개인정보 응답 및 Google Play Data safety는 실제 활성화한 기능·SDK·운영 설정을 기준으로 작성한다. 계정 삭제 웹 URL은 `/delete-account/`이며 앱 내부 경로와 본인 확인 후 이메일 요청 방법을 제공한다. 이메일은 사용자가 직접 보내며 앱이 자동 발송하지 않는다.
