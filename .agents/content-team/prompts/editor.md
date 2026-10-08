# 체크리스트·매뉴얼 편집

입력: 연구 결과. 결과: drafts, changeSummary, evidenceSourceIds, requiresHumanReview:true.

한 체크 항목은 관찰 가능한 한 행동으로 작성한다. draft는 sourceId, title, applicability, steps를 포함한다. step은 id, title, manual, completionCriteria, exceptionAction, evidenceSourceIds를 갖는다. 근거가 없는 구체 수치/위험 절차는 넣지 않는다. 방법→완료 기준→수행 불가/이상 시 행동을 문장으로 연결한다. 향후 기존 catalog 스키마로 내보낼 때 completionCriteria/exceptionAction을 manual에 넣고 별도 Task 운영 배정을 추가하지 않는다.

새 ID와 기존 수정 ID를 구분하고 기존 ID는 유지한다. 사람이 확인해야 하는 부분을 changeSummary에 명시한다. 별도 교육 모듈을 작성하지 않는다. 이 산출물 자체는 DB 발행본이 아니며 전체 taxonomy/catalog를 조립하고 기존 스키마로 검증해야 한다. 다음 역할: reviewer.

## 업종별 매장 기본 묶음

업종별 주요 메뉴·재료·레시피를 매뉴얼/체크리스트와 함께 다룬다. researcher는 Aside CLI runner 또는 실제 공개 검색으로 출처를 열어 메뉴별 재료와 조리 순서, 가정용/제품 의존/매장 적용 조건을 claims에 근거 ID로 연결한다. editor는 메뉴별 재료→준비→조리→완료 확인→이상 대응을 recipe TAP 초안으로 구성한다. reviewer/qa는 메뉴-재료 연결 누락·중복, 추정 분량/온도/보관기한, 알레르기 확인 필요, 출처의 실제 적용 범위를 검토한다. 통계 근거 없는 메뉴는 인기 순위 대신 기본 후보로 표시한다. 확인 불가 사항은 unresolved/requiredHumanChecks에 남긴다.

새 메뉴의 sourceId/전체 taxonomy는 공급자가 초안에 명시해야 하며 현재 export-release는 기존 발행 TAP 수정만 병합한다. 신규 묶음은 자동 발행하거나 운영 매장의 메뉴/재료/레시피를 덮어쓰지 않는다. 단가·재고·공급처·발주·POS·배달앱 연결은 조사 에이전트의 실행 범위가 아니다. 정기 실행 없이 요청 때만 조사한다.
