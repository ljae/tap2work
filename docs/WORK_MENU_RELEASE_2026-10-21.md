# 업무·매뉴얼 보기 개편 웹·앱 배포 · 2026-10-21

사용자의 “웹 앱 배포해주세요” 요청에 따라 D-140 구현을 기존 웹·모바일 배포 채널에 반영했다. 원래 작업 트리의 미커밋 변경은 보존하고 `origin/main` 기준 `.local/work-menu-release`에 이번 변경 21개 파일만 복사했다. 코드 커밋은 `4b0f8576817b3b0973dfcf3473ba402490228d2d`다. 백엔드/DB/공용 카탈로그 발행은 필요하지 않아 변경하지 않았다.

## 실제 반영 상태

| 대상 | 결과 |
|---|---|
| 웹 | [tap2.work](https://tap2.work/) 공개 반영. [Actions 39613122967](https://github.com/ljae/tap2work/actions/runs/39613122967)의 build/deploy 두 job 모두 success. 공개267파일이 CI Pages artifact와 SHA256 전부 일치 |
| iOS | 1.0.0(23) VALID. 내부 TestFlight 기존 그룹 연결. 새 제출 `17c1437e-cc5c-4c9c-93e5-7306155280a3`가 2026-10-21 23:14:09 KST 접수, 버전/제출 모두 WAITING_FOR_REVIEW·AFTER_APPROVAL. App Store 승인 전 |
| Android | 1.0.0(22), 기존 internal/alpha 채널 모두 versionCode22·completed 재조회 확인. production/beta release 없음 |

iOS는 빌드23 준비·VALID를 확인한 뒤 기존22 제출의 취소 COMPLETE를 확인하고 새 빌드·안내·스크린샷을 연결했다. 이번 새 제출부터 심사 대기가 다시 시작된다. 심사 계정·연락처는 메모 수정 전후 그대로 일치했다. 이전 iPhone/iPad 스크린샷8장은 비공개 증거 폴더에 보존한 뒤 현재 화면8장으로 교체했고, 각 COMPLETE·원본 MD5·네 목적지 순서를 확인했다. 캡처는 공개 가상 샘플의 실제 Flutter 렌더링이며 실기기 촬영이 아니다.

GitHub는 두 job 성공과 공개 반영 후에도 23:18 KST 조회에서 run 집계 상태가 in_progress로 늦게 표시됐다. 개별 build/deploy job은 모두 completed/success이고 실제267파일 일치·브라우저 검증으로 배포를 확인했다. 이 집계 표시를 추가 테스트 성공으로 해석하지 않는다.

## 검증

- CI Flutter635개 통과/브라우저 전용3개 skip, analysis0, Node394개 통과. JS/UI89·Edge·격리SQL5개·7언어 번역·웹 빌드 통과.
- 실제 Chrome390px 공개 로그인 → 샘플 → 업무: 할일/완료, TAP 아래 할일, 해당 방법·체크 펼침 확인. 매뉴얼/레시피 전환과 메인 분류 버튼 제거 확인. pageerror0·operations POST0. 공개 실행 읽기만 수행했다.
- iOS 서명 Archive/IPA 생성 및 `codesign --verify --deep --strict` 통과. 버전23·bundle ID·8언어·공개 인증 define4개 확인. IPA SHA256 `5fc984ba236119f5e30b166111193337c99c092282355dc9887d0742c85c48fa`.
- Android signed AAB·jar signature 확인. 기존 업로드 keystore 재사용, Android에 필요한 공개 설정3개·번들 번역7개 원본 일치 확인. Play 업로드 응답 versionCode22·SHA256 일치. SHA256 `5dfa6b73a91bc10751dea7a8ce30ab9dac13e97eee4e1beb65124a672a90bcc3`.
- 실제 기기 OAuth·카메라·계정 삭제, 이번 빌드의 네이티브 설치/실행, 원어민·현장 효과 검증은 수행하지 않았다. App Store 승인·Google production 출시로 보고하지 않는다.

## 초기 실패와 복구

- 캡처 준비의 작업 디렉토리 오류를 수정한 뒤 스크린샷 생성 검사1개가 통과했다.
- Apple 직접 IPA 전송의 multipart checksum 순서409를 offset 오름차순으로 재계산해 같은 업로드를 COMPLETE로 복구했다. 재전송/새 빌드 번호 중복 업로드 없음.
- 새 빌드의 내부 그룹 연결은 초기404 뒤 재조회·재시도로 성공했다. 기존 제출 취소 후 단건 GET404는 목록 API의 COMPLETE·버전 DEVELOPER_REJECTED로 확인하고 이어 진행했다.
- iPad 자산 처리 대기 timeout과 일시적 재조회 불일치는 새 자산을 다시 만들지 않고 기존8개 checksum/COMPLETE 재확인 후 순서 확정으로 복구했다.
- 웹 자동 검수의 즉시 조회/정확한 accessible name 가정을 Flutter 렌더 대기와 실제 복합 접근성 이름에 맞게 수정했다. 최종 실제 브라우저 검증은 모두 통과했다. 앱 코드를 검수 선택자에 맞춰 바꾸지 않았다.
- 네이티브 빌드의 기존 launch placeholder/Java source8, Apple 업로드의 향후 minimum iOS 안내는 실패 원인이 아니었다. 사용자 파일·캐시·운영 데이터 삭제 없음.

실제 API 응답·업로드/서명/CI 로그·공개 파일 해시·브라우저 캡처는 Git 제외 `.local/work-menu-deployment-20261021/`에 보존한다.
