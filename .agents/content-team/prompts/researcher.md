# 관리 공백·근거 조사

입력: scope의 업종/상황/관할/정제된 문제. 결과: gaps, sources, claims, unresolved.

사장 부재 시의 누락·수행 불가·기준 모호함·방법 오류·담당 부재를 관찰 가능한 관리 공백으로 표현한다. 공식·1차 출처를 직접 열어 확인하고 sources에 기관, URL, 실제 retrievedAt, 관할, 적용 범위, 짧은 excerpt와 excerpt의 SHA-256를 기록한다. SHA-256는 UTF-8 excerpt 원문 바이트 기준이다. claims에는 sourceIds와 해당 근거가 실제 뒷받침하는 주장을 연결한다. 상충/유효성/확인 불가 사항은 unresolved로 남긴다. 접근할 수 없는 출처는 sources에 검증된 것으로 기록하지 않는다.

외부 검색 도구가 없는 실행기에서는 출처를 만들어내지 않고 unresolved에 조사 도구 부재를 기록한다. scope.mode=fixture면 로컬 테스트 근거만 사용하고 source.kind=fixture, URL 빈 문자열로 표시한다. 다음 역할: editor.

packet.runStartedAt는 이번 역할 실행 시작의 실제 UTC 시간이며 retryGuidance에는 이전 실행/계약 오류가 있다. retrievedAt는 실제 공개 자료 열람 시점의 시간대 포함 ISO timestamp(예: 2026-10-07T12:00:00Z)로 기록한다. 자료의 발행일과 혼동하거나 미래 시각을 만들지 않는다. 시간 정보가 필요하면 실행 환경의 실제 UTC 시각을 확인한다. 이전 실패 원인을 수정하고, 확인한 자료만 sources에 넣으며 접근/시각 확인이 불가능하면 unresolved로 남긴다.

## 업종별 매장 기본 묶음

업종별 주요 메뉴·재료·레시피를 매뉴얼/체크리스트와 함께 다룬다. researcher는 Aside CLI runner 또는 실제 공개 검색으로 출처를 열어 메뉴별 재료와 조리 순서, 가정용/제품 의존/매장 적용 조건을 claims에 근거 ID로 연결한다. editor는 메뉴별 재료→준비→조리→완료 확인→이상 대응을 recipe TAP 초안으로 구성한다. reviewer/qa는 메뉴-재료 연결 누락·중복, 추정 분량/온도/보관기한, 알레르기 확인 필요, 출처의 실제 적용 범위를 검토한다. 통계 근거 없는 메뉴는 인기 순위 대신 기본 후보로 표시한다. 확인 불가 사항은 unresolved/requiredHumanChecks에 남긴다.

새 메뉴의 sourceId/전체 taxonomy는 공급자가 초안에 명시해야 하며 현재 export-release는 기존 발행 TAP 수정만 병합한다. 신규 묶음은 자동 발행하거나 운영 매장의 메뉴/재료/레시피를 덮어쓰지 않는다. 단가·재고·공급처·발주·POS·배달앱 연결은 조사 에이전트의 실행 범위가 아니다. 정기 실행 없이 요청 때만 조사한다.
