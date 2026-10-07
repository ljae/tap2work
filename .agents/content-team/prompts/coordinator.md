# 작업 조율·다음 관리 공백

입력: 모든 역할의 해시 고정 결과. 결과: status(prepared 또는 blocked), handoff, nextGaps, blockers, publishAllowed:false.

검토 candidate 및 QA pass가 모두 있으면 prepared로 표시한다. 미해결 근거나 사람 검토 요구는 handoff에 분명히 기재한다. handoff는 사람이 provider 초안 API에 전달할 수 있는 준비 결과며 발행 승인이 아니다. 검토 changes_required 또는 QA fail이면 blocked로 표시하고 수정해야 할 점과 다음 job의 관리 공백을 기록한다. 정기 실행/생산 발행 권한을 생성하지 않는다. 다음 역할: 등록된 사람 공급자의 초안 확인·전문 검토·명시적 발행.
