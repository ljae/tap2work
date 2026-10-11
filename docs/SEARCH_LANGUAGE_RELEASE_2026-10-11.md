# 통합 검색·국기 언어 선택

- 상단 검색은 ‘매뉴얼·레시피 통합 검색’. 네 목적지에서 같은 결과를 보여주며 레시피명과 본문도 검색한다. 매뉴얼 탭의 기존 레시피 제외 필터를 공통 결과 경로로 바꿨고 디렉터리 편집 상태는 유지한다.
- 상단 국기48px 버튼에서8개 언어를 바로 선택한다. 모국어 이름과 선택 체크를 제공하며 국기와 화면 언어가 즉시 바뀐다. 계정별 저장 경로는 기존 그대로다.
- 국적 선택/선택값/권한 있는 크루 카드, 크루 및 웰컴 언어 선택에 국기를 표시한다. 국적과 언어는 독립이고 다른 크루의 비공개 국적을 추정하지 않는다.
- 표시 이름과 대표 국기 매핑은 `app/lib/l10n/app_localizations.dart`에서 공통 수정한다. 영어의 대표 국기는 US다.
- [Twemoji 원본](https://github.com/jdecked/twemoji/tree/b6b55fef1e8636b540a6d016a4729ca8cdf2e60b)의249개 PNG를 오프라인 번들로 포함했다. CC BY4.0 고지는 assets/flags/LICENSE.txt 및 앱 LicenseRegistry에 등록한다.

## 검증

Flutter analysis 오류0, 관련85개 테스트 통과(8언어·320px/글자1.5배·언어 저장·로그인·크루 등록·웰컴·매뉴얼 편집·네 목적지 레시피명/본문 검색), 서버 국적/카탈로그/체크리스트22개 통과, UI 연결78개 통과. 첫 검색 검증에서 매뉴얼 탭의 레시피 제외를 발견·수정했다. 테스트 선택자는 입력창과 결과가 같은 이름인 경우를 구별하도록 수정했다. 초기 로컬 실행기 하나를 종료했고 최종 묶음 재실행으로85개 통과를 확인했다. 전체 CI와 실제 배포 검증은 후속이다.

## 배포 결과

사용자 요청에 따라 **GPT-6 Luna (medium)** 에이전트가 실제 웹/네이티브 배포를 수행했다.

- 웹 [tap2.work](https://tap2.work): 코드 `674ea84339c50d3b14ea490ab66cae6398f02f8a`, [Actions38142070476](https://github.com/ljae/tap2work/actions/runs/38142070476) 성공. CI 전체 Flutter568개 통과·브라우저 전용3개 제외, analysis0, 서버381개 통과. 공개256개 파일이 CI artifact SHA256과 일치(249개 국기+라이선스 포함).
- iOS1.0.0 **16**: VALID, 내부 TestFlight 그룹 연결, WAITING_FOR_REVIEW, AFTER_APPROVAL. 기존 심사 상세 정보 보존. 공개 출시는 Apple 심사 대기다.
- Android1.0.0 **15**: internal/alpha 트랙에서 completed 확인. beta/production 트랙은 비어 있다. 일반 공개 출시 완료로 간주하지 않는다.
- 기존 iOS13 타깃(2027-04 이후15 요구 안내)·기본 launch image 경고는 업로드를 막지 않았으며 이번 변경 범위에서 미수정이다.

## 실제 웹 확인

부모 에이전트가 Ego Lite TaskSpace12의 기존 로그인된 Audit Kitchen에서390px 화면으로 상단 통합 검색 표기, 현재 국기,8개 국기+모국어 언어 시트를 확인했다. 한국어→베트남어 변경 후 새로고침해 저장 유지를 확인했고, 한국어로 복원한 뒤 다시 새로고침해 복원 유지도 확인했다. 새 OAuth 로그인 검증이나 크루 데이터 변경은 하지 않았다. TaskSpace는 확인 후 종료했다.

실제 키워드 입력 자동화는 기존과 같이 Flutter semantics DOM만 바뀌고 앱 검색 컨트롤러로 전달되지 않아 완료하지 못했다. 레시피명/본문과 매뉴얼의 네 목적지 통합 검색은 위 Flutter 테스트로 검증했다. 이 한계를 실제 사용자 검색 실패로 단정하지 않는다.

실웹 캡처: `.local/search-language/live-header.png`, `live-language-picker.png`, `live-vietnamese.png`. 배포 증빙/전체 CI 로그: `.local/search-language/deployment-report.json`, `public-verification.json`, `native-verification.json`, `ci.log`. 루트의 기존 미커밋 작업은 보존하고 별도 `.local/owner-release`에서 명시 파일만 배포했다.
