# 근무 준비·인계·CS 앱 웹 배포 · 2026-10-14

사용자의 앱·웹 배포 및 Apple 심사 확인 요청에 따라 웹·운영 API와 기존 Android 테스트 트랙을 업데이트했다. iOS는 현재 심사를 유지했다. 기존 작업 트리는 보존하고 지난 배포에서 분리한 `.local/service-web-release`의 선택47파일로 배포했다.

## 실제 배포 결과

- 웹: 소스 `2ff4711c41b21f078dda092c9b77108048e50200`, [GitHub Actions38563676323](https://github.com/ljae/tap2work/actions/runs/38563676323) build/deploy 성공. [tap2.work](https://tap2.work/)267파일이 실제 CI artifact SHA256과 모두 일치한다.
- CI: Flutter626 passed / 브라우저 전용3 skipped, analysis0, Node394 passed, UI/settings87, Deno Edge, 격리SQL5종, 번역검사와 공개웹build 통과. 분리한 로컬 소스에서도 Node394·analysis0·웹build를 확인했다. 공용147개/394a7e42 카탈로그는 변경하지 않았다.
- 운영 API: Supabase `operations` 버전66 ACTIVE. 신규 서비스 기록/권한/멱등 API와 주문 기능 종료를 배포했다. 미인증401과 배포 메타데이터를 확인했다. 실제 인증된 사용자 기록 저장 왕복은 이번 배포에서 수행하지 않았다. SQL migration/카탈로그 발행은 없다.
- Android:1.0.0 빌드21 서명AAB 생성·업로드 완료. 실제 산출물의 기존 upload 인증서 일치·Google/Supabase 공개 설정·번역7사전 바이트 일치를 확인했다. SHA256 `a9a43f76c0fd199fe5c7fa53ed2de1f35f2e9c3b13adca1454e87ad2ebf78899`. 기존 `internal`, `alpha` 두 테스트 트랙에서21/completed를 재조회했다. production/beta 배포는 없다. 앱 설치·실기기 로그인은 미검증이다.
- iOS: 기존1.0.0 빌드21 VALID / WAITING_FOR_REVIEW / AFTER_APPROVAL / 기존 내부TestFlight그룹 연결을 재확인했다. 취소·새 IPA·교체 제출은 하지 않았다. [Apple 심사 확인](APPLE_REVIEW_STATUS_2026-10-14.md)을 따른다.

## 공개 웹 확인

실제 익명 Chrome390×900에서 로그인 화면 → 저장 없는 샘플 → 업무 → 근무 준비·인계 → 시작/교대·마감/CS를 열었다. 시작 안내 빈 상태, 남은 인계 빈 상태, 검토용 CS 안내5개 펼침, 비활성 기록/등록 조작과 새 배치를 확인했다. 브라우저 pageerror는0이다. 초기 ChoiceChip의 text locator가 잡히지 않아 실제 화면의 선택 위치로 클릭했고, 각 선택된 화면을 이미지/본문으로 직접 확인했다.

사용자 데이터 입력이나 주문/발주·직원·급여 변경은 수행하지 않았다. 공개 샘플은 별도 합성 자료이며 실제 근무 시각이나 생산 identity가 아니다. 실제2계정 버디 확인, 원어민/현장 효과와 native 설치 검증은 후속이다.

## Apple 심사 지연

10월14일21:23 KST 조회에서 현재 접수는 **10월13일22:33 KST**, 약23시간 경과다. 과거 빌드 교체마다 심사가 취소·재제출되어 같은 요청이 첫 제출부터 계속 대기한 상황은 아니다. Apple 공식 문서는 취소 후 재제출 시 심사가 다시 시작된다고 설명한다. 현재 내부 지연 사유나 Resolution Center 메시지는 API 상태만으로 확정하지 못했다. 연락처/데모 계정 입력/메모 존재는 확인했지만 실제 계정 로그인을 증명하지 않는다. 지원 문의나 expedited 요청은 발송하지 않았다.

## 증거

`.local/service-deployment-20261014/`: `selected-files.json`, `ci.log`, `public-verification.json`, `backend-verification.json`, `browser-verification.json`, `public-*.png`, `android21-artifact.json`, `android21-submission.json`, `native-verification.json`, `apple-status.json`. 인증값·운영 데이터는 원격소스/웹에 포함하지 않았다.
