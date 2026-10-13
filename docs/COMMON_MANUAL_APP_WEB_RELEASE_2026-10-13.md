# 공통 매뉴얼·레시피 앱/웹 배포 · 2026-10-13

웹, 운영 공용 카탈로그와 새 모바일 빌드의 제출을 완료했다. iOS 운영 심사는 대기 중이며 Android는 기존 내부·비공개 테스트 트랙에 게시했다.

- 웹 소스 `254663cc90e7e2d7178f98373b200360bb303691`, [GitHub Pages38404612330](https://github.com/ljae/tap2work/actions/runs/38404612330) build/deploy 성공. [tap2.work](https://tap2.work/)의267파일이 실제 CI 산출물 SHA256과 모두 일치했다.7개 번역 사전도 선택 소스와 바이트 일치한다.
- 기존 로컬616 Flutter 통과/브라우저 전용3skip, 서버391·analysis0·UI84·번역 검사를 CI에서 다시 실행해 전체 성공했다. Deno Edge와 격리 SQL5종도 통과했다.
- iOS1.0.0 빌드21 IPA 서명 빌드·업로드 완료, 처리 상태 VALID. 기존 TAP Work Internal 그룹 연결 완료. 기존20의 심사 요청을 취소한 뒤21로 새 심사를 제출했다. 최종 WAITING_FOR_REVIEW/AFTER_APPROVAL을 직접 조회했다. 기존 심사 연락처·접근 정보 등 review detail이 동일함을 확인했다.
- Android1.0.0 버전20 AAB 빌드·업로드·edit 검증/commit 완료. 내부 internal 및 비공개 alpha가20/completed임을 재조회했다. production/beta는 이번에 게시하지 않았다. 기존 테스터·국가·스토어 정보·업로드 인증서를 사용했다.
- iOS의 실제 AOT 공개 인증 값·Google callback·Bundle ID/21을 검사했다. Android AOT에는 해당 플랫폼에서 사용하는 Supabase와 Google Web client 설정을 검사했다. 두 산출물의 번역7종과 개인정보 JSON은 선택 소스와 정확히 일치한다. Android 업로드 SHA256도 로컬 AAB와 일치한다.

## 운영 공용 원본

사용자가 “별도 검토자 계정은 skip하고 모두 배포해주세요”라고 명시했다. 기존 제공자 API의 일반 검토 정책은 변경하지 않고 **이번 발행만 관리자 DB 경계에서 처리**했다.

- 이전 stable109/revision2/`08a4e057…` →147/revision3/`394a7e42f8a61c6df34cebdcadd352b582114df996b0718a3a3187a4f20d1013`.
- 사전 준비한 정확한 원본, 기존 채널 revision, 고정 request UUID와 검토 생략 사유를 사용했다. 불변 발행 사건의 actor=null은 DB 관리자 작업이며, 별도 검토 승인을 만들거나 공급자/검토자 계정으로 가장하지 않았다.
- PGlite에서 기존 운영 원본과 revision2를 재현한 뒤147 발행·같은 요청 재시도·revision3·명시적 생략 이력을 확인했다. 실제 발행 후 RPC의 전체 JSON을 선택 원본과 canonical 비교해 일치를 확인했다.
- 사용자에게서 기존 계정은 모두 테스트 계정이고 삭제/새 구성 사용이 허용된다는 지시도 받았다. 이 발행에 계정 삭제가 필요하지 않아 실제 삭제는0건이다. 기존 매장 사본·생성 실행·개인화는 기존 비교·선택 적용 계약을 따른다.

## 브라우저와 한계

실제 익명 Chrome390px에서 새 웹의 로그인·저장 없는 샘플·매장 안내·매뉴얼·마켓 진입을 확인했다. 새 ‘공통 업무’ 분류와 개업 전 검색 결과, 개업 전 영업 조건 상세 화면을 실제 렌더로 확인했다. Flutter의 aria-label로 합쳐진 텍스트에 대한 자동화 locator를 조정했다. 구체적인 최종 화면 증거는 `.local/common-operations-deployment/public-*.png`다.

Apple 심사 승인/실제 운영 출시, Android production 출시, 실기기 설치·실계정 네이티브 로그인·원어민/현장 전문가 검수는 이번에 확인하지 않았다. 기존 iOS13 대상에 대한2027년4월 이후 iOS15 필요 경고가 있었으나 이번 업로드는 성공했다. 번역은 기존 ai-draft 상태이며 BYOK는 미구현이다.

원래 작업 트리는 변경 이력을 보존했다. 선택41파일만 격리 `.local/common-operations-release`에 복사해 배포했다. 비공개 인증 파일·기존 키는 저장소/웹 산출물에 포함하지 않았다. 배포 증거와 관리자 발행 요청/SQL·결과는 `.local/common-operations-deployment/`에 있다.
