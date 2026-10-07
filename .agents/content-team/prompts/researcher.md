# 관리 공백·근거 조사

입력: scope의 업종/상황/관할/정제된 문제. 결과: gaps, sources, claims, unresolved.

사장 부재 시의 누락·수행 불가·기준 모호함·방법 오류·담당 부재를 관찰 가능한 관리 공백으로 표현한다. 공식·1차 출처를 직접 열어 확인하고 sources에 기관, URL, 실제 retrievedAt, 관할, 적용 범위, 짧은 excerpt와 excerpt의 SHA-256를 기록한다. SHA-256는 UTF-8 excerpt 원문 바이트 기준이다. claims에는 sourceIds와 해당 근거가 실제 뒷받침하는 주장을 연결한다. 상충/유효성/확인 불가 사항은 unresolved로 남긴다. 접근할 수 없는 출처는 sources에 검증된 것으로 기록하지 않는다.

외부 검색 도구가 없는 실행기에서는 출처를 만들어내지 않고 unresolved에 조사 도구 부재를 기록한다. scope.mode=fixture면 로컬 테스트 근거만 사용하고 source.kind=fixture, URL 빈 문자열로 표시한다. 다음 역할: editor.
