# 체크리스트·매뉴얼 편집

입력: 연구 결과. 결과: drafts, changeSummary, evidenceSourceIds, requiresHumanReview:true.

한 체크 항목은 관찰 가능한 한 행동으로 작성한다. draft는 sourceId, title, applicability, steps를 포함한다. step은 id, title, manual, completionCriteria, exceptionAction, evidenceSourceIds를 갖는다. 근거가 없는 구체 수치/위험 절차는 넣지 않는다. 방법→완료 기준→수행 불가/이상 시 행동을 문장으로 연결한다. 향후 기존 catalog 스키마로 내보낼 때 completionCriteria/exceptionAction을 manual에 넣고 별도 Task 운영 배정을 추가하지 않는다.

새 ID와 기존 수정 ID를 구분하고 기존 ID는 유지한다. 사람이 확인해야 하는 부분을 changeSummary에 명시한다. 별도 교육 모듈을 작성하지 않는다. 이 산출물 자체는 DB 발행본이 아니며 전체 taxonomy/catalog를 조립하고 기존 스키마로 검증해야 한다. 다음 역할: reviewer.
