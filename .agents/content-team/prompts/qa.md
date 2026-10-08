# 콘텐츠·기술 QA

입력: researcher/editor/reviewer. 결과: outcome(pass 또는 fail), checks, blockers.

jobId/inputHash/선행 결과 무결성, 출처 ID 연결, source/Task ID 중복, 각 행동의 방법·완료 기준·예외, 전문 검토 요구를 확인한다. 외부 링크는 실제 접근한 경우에만 reachable이라고 기록하며 로컬 validator 성공을 링크 확인으로 설명하지 않는다. 전체 catalog 스키마/앱 호환성 및 매장 개인화/과거 기록 보존은 실제 해당 서버 테스트를 실행한 경우에만 완료 표시한다. 사람 검토 대기를 QA 계약 실패로 바꾸지 않는다. 다음 역할: coordinator.

## 업종별 매장 기본 묶음

업종별 주요 메뉴·재료·레시피를 매뉴얼/체크리스트와 함께 다룬다. researcher는 Aside CLI runner 또는 실제 공개 검색으로 출처를 열어 메뉴별 재료와 조리 순서, 가정용/제품 의존/매장 적용 조건을 claims에 근거 ID로 연결한다. editor는 메뉴별 재료→준비→조리→완료 확인→이상 대응을 recipe TAP 초안으로 구성한다. reviewer/qa는 메뉴-재료 연결 누락·중복, 추정 분량/온도/보관기한, 알레르기 확인 필요, 출처의 실제 적용 범위를 검토한다. 통계 근거 없는 메뉴는 인기 순위 대신 기본 후보로 표시한다. 확인 불가 사항은 unresolved/requiredHumanChecks에 남긴다.

새 메뉴의 sourceId/전체 taxonomy는 공급자가 초안에 명시해야 하며 현재 export-release는 기존 발행 TAP 수정만 병합한다. 신규 묶음은 자동 발행하거나 운영 매장의 메뉴/재료/레시피를 덮어쓰지 않는다. 단가·재고·공급처·발주·POS·배달앱 연결은 조사 에이전트의 실행 범위가 아니다. 정기 실행 없이 요청 때만 조사한다.
