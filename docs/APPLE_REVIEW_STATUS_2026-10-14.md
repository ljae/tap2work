# Apple 심사 상태 확인 · 2026-10-14

사용자는 앱 웹 배포와 오랜 Apple 심사 지연 확인을 요청했다. 기존 API 인증으로 읽기 조회했고, Apple 심사를 취소하거나 새 네이티브 빌드를 올리지 않았다.

## 실제 조회

2026-10-14 21:23 KST 조회: TAP Work(6819216931), iOS1.0.0 **빌드21**. 빌드 처리 상태 **VALID**, 버전/현재 제출 상태 **WAITING_FOR_REVIEW**, 승인 후 자동 출시 **AFTER_APPROVAL**다. 제출 시각은 **2026-10-13 22:33:30 KST**다. 이번 조회 당시 현재 제출의 경과는 약23시간이다.

심사 연락처, 데모 계정 필수 설정, 사용자명·비밀번호, 심사 메모가 등록돼 있음을 확인했다. 이 조회는 해당 계정으로 실제 로그인이 되는지나 심사 메모의 충분성을 증명하지 않는다. 현재 상태는 반려/메타데이터 거절이 아니며 심사 시작 전이다. Resolution Center 메시지/Apple 내부 지연 이유는 API 상태 조회만으로 확인하지 못했다.

최근 제출 목록에는 10월10~13일의 여러 제출이 COMPLETE이고 최신1개가 대기 중이다. 기존 배포 이력은 빌드 교체를 위해 심사를 취소·재제출했음을 기록한다. COMPLETE만으로 심사 승인이라고 판단하지 않는다. 이전6 제출부터 계속 같은 요청이 대기 중인 상태는 아니다.

## 지연의 해석과 권고

[Apple의 상태 안내](https://developer.apple.com/help/app-review/after-submitting-for-review/review-status)는 Waiting for Review를 접수됐지만 심사가 시작되지 않은 상태로 설명한다. [취소·재제출 안내](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/remove-a-submission-from-review)는 취소하면 대기열에서 제거되며 재제출 시 심사가 다시 시작된다고 명시한다. 이전 빌드 교체로 심사가 반복 재시작된 점은 전체 기간이 길게 보이는 요인이다. **현재 대기가 Apple 내부의 어떤 사유로 지속되는지는 확정할 수 없다.**

권고(proposed): 이번 웹 업데이트는 별도로 진행하고 현재 iOS 제출을 유지한다. 향후 새 빌드를 교체할 때는 심사 재시작을 고려한다. 같은 제출이 계속 장기간 대기하거나 Apple 문의가 오면 App Store Connect의 App Review 메시지·지원 경로에서 확인한다. 이번 작업에서는 문의를 발송하거나 expedited review를 요청하지 않았다. 승인 시각을 예측하지 않는다.

비공개 조회 증거: `.local/service-deployment-20261014/apple-status.json`. 인증키·심사용 로그인 값은 문서/웹/원격 소스에 포함하지 않는다.
