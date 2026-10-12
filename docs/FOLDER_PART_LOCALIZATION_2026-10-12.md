# 폴더·파트 이름 번역 보완 배포

기본30이름을 지원8언어에 연결하고 업무·매뉴얼·근무표·크루·배정 표시와 폴더 검색을 보완했다. 사용자 지정 이름 번역은 폴더 편집 ⋯ 메뉴와 저장된 파트의 번역 아이콘에서 등록한다. 이름 입력·저장 원문·연결 ID는 유지하며 이름 변경 시 이전 번역을 사용하지 않는다. AI 검토 초안이며 원어민 검수는 미수행이다.

## 실제 배포

- 웹 `0126782574413d874cdb5d3876fd6a9c00431c1b`, [Actions38255526952](https://github.com/ljae/tap2work/actions/runs/38255526952) 성공. 공개262파일 SHA256 일치.
- iOS1.0.0(20) VALID·내부 TestFlight·WAITING_FOR_REVIEW·AFTER_APPROVAL. 심사 상세 정보 유지.
- Android1.0.0(19) internal/alpha completed. beta/production 비어 있음. 기존 업로드 서명 일치.
- operations Edge 배포 완료. 기존 JSON section에 folders/parts 번역 저장·공유·원문 변경 무효화 추가. SQL 스키마 변경 없음.

## 검증과 한계

CI Flutter591통과/브라우저 전용3건 건너뜀, analysis0, Node383통과, UI79·JS·Edge·5SQL·7언어×1357개 사전 검사 통과. 새 회귀는 기본 이름8언어, ID/원문 일치, 이름 수정 폼의 원문 보존, 번역 저장 opening revision, 권한과 삭제된 항목 제외를 확인한다.

익명390px Chrome의 태국어 업무·매뉴얼에서 파트·폴더 표시를 확인했다. 공개 샘플 열람만 수행했다. native 번역 자산7개는 소스와 byte 일치하며 실제 AOT에 플랫폼에 필요한 기존 공개 로그인 설정을 확인했다. iOS callback scheme과 Android 서명을 확인했다. Android 미사용 iOS client define은 최적화에서 제거돼 Android에 필요한 web client/URL/public key를 따로 검사했다.

추가 테스트의 최초 fixture는 필수 query와 테스트 전용 동작 줄이기 설정 누락으로 실패해 보완했다. root 첫 전체 실행은 새 테스트 컴파일1건 실패/기존587통과였으며 보완 후4회귀 통과. 같은 작업 폴더의 병렬 native/전체 검사 진행이 멈춰 중단하고 native를 순서대로 재빌드했다. 최종 전체 검증은 CI591통과 결과다. iOS20 제출 증빙의 이전 build19 상수는 실제 version/build API의20 확인 뒤 정정했다.

실기기·원어민·native 실계정 로그인 검수는 미수행이다. 기존 미커밋 작업과 실제 운영 기록을 유지했다. 비공개 증빙은 `.local/entity-name-localization/`이다.

사용자 후속 요청의 분류·가상 매장 본보기·구조/전환 재설계는 [별도 구현 문서](MANUAL_OPERATING_MODEL_REDESIGN_2026-10-12.md)의 진행 중 작업이다.
