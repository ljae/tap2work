# 다음 작업: 직원교육·매장 루틴 중심 매뉴얼과 마켓 UI

> 2026-10-10 후속: [업무 내비게이션 상세 작업 계획](MANUAL_NAVIGATION_WORK_PLAN_2026-10-10.md)이 이 TODO를 인수한다. 사용자 답변 C01–C12와 단계별 에이전트·산출물·통과 기준을 먼저 확인한다. 아래 미완료 체크를 완료로 바꾸지 않았다. 84개 단계 ID는 `{sid}` 임시값이므로 대조표부터 작성한다. 공용 개선은 사장님의 TAP별 선택 적용으로 방향이 확정됐으며 현재 자동 갱신 코드의 이관은 남아 있다.

작성: 2026-10-10. 사용자가 자리를 비우며 투두 MD 작성을 요청해 구현을 중단하고 인계했다.
**현재 상태: 일부 코드 수정 + 상세 콘텐츠 초안. 테스트·콘텐츠 적용·배포 미완료.**

## 1. 확정된 사용자 요구

- 창업·사업장 최초 개설에 필요한 업무는 매뉴얼 중심 범위에서 제외한다.
- 이미 운영 중인 매장의 직원교육과 일상 루틴을 위한 세세한 체크리스트·매뉴얼을 중심으로 구성한다.
- 매장 유지를 위한 정기 주요 업무도 포함한다.
- 매장 특성에 맞게 수정해 바로 사용할 수 있을 만큼 구체적으로 작성한다.
- 분류 구조와 UI를 다시 검증한다. 마켓의 분류 버튼이 직관적이지 않고 복잡하다는 문제를 해결한다.
- **매일 영업 전 오픈 준비는 유지한다.** 창업 준비 제외와 혼동하지 않는다. 새 크루 교육도 제외 대상이 아니다.

## 2. 먼저 읽을 문서와 작업 위치

- 작업 루트: `/Volumes/ORICO/tap2work`
- `AGENTS.md`, `docs/AI_HANDOFF.md`, 최신 `docs/project-state.json`, `PRODUCT.md`, `docs/ARCHITECTURE.md`
- `docs/UI_UX_GUIDELINES.md`, `docs/TOSS_UI_PROMPT_TEMPLATE.md`, `docs/UI_SETTINGS_RELATIONSHIP_MAP.md`
- `docs/market/README.md`, `docs/DB_CATALOG_OPERATIONS.md`
- [상세 콘텐츠 초안](MANUAL_ROUTINE_CONTENT_DRAFT_2026-10-10.md)
- 기존 루트에는 많은 수정·미추적 파일이 있다. 전체 reset/clean/stage를 하지 않는다.
- 기존 배포용 worktree: `.local/store-setup-web-release`. 이번 변경은 **루트에만** 있다. 배포용 worktree에는 아직 복사하지 않았다.

## 3. 이번에 수행한 내용

- [x] 현재 109개 카탈로그와 기존 마켓 UI/설정 연결을 조사했다.
- [x] 기존 마켓에 적용 범위 칩 + 업종 선택 + 법적/운영 칩이 겹치는 문제를 확인했다.
- [x] 외식 공통 매뉴얼 다수가 2~3개 짧은 단계여서 교육용 세부 절차가 부족함을 확인했다.
- [x] 외식 공통 **18개 매뉴얼·84개 절차**의 수행 방법·완료 기준·이상 대응 초안을 작성했다.
- [x] 다음 5개 파일에 구현 초안을 작성했다. **분석·포맷·테스트는 아직 실행하지 않았다.**

| 파일 | 현재 수정 초안 |
|---|---|
| `app/lib/domain/manual_market_catalog.dart` | `knowledge.useCase` 해석, startup/대체된 항목 제외, 용도·업무 목적 검색 |
| `app/lib/ui/manual_market_screen.dart` | 전체/직원교육/매장 루틴/정기관리, 업무·업종 좁혀보기 시트, 목적별 그룹, 초기화, 업무 연결 문구 |
| `developer/knowledge_work.mjs` | 선택적 `useCase` 검증·보존: training/routine/periodic/startup |
| `developer/manual_market.mjs` | startup을 카탈로그 응답에서 제외, 교육·정기·startup의 일괄 매일 활성화 차단 |
| `developer/store_setup.mjs` | 신규 매장 추천에서 startup 제외 |

이 UI/메타데이터 구조는 사용자 요구를 구현하는 **현재 작업안**이다. 별도의 사용자 확정 디자인이라고 기록하지 않는다. 기존 scope/kind 도메인 검색 호환은 남겨 두었다.

초안 원본은 `.local/manual-routine-20261010/content.txt`에도 있다. `@sourceId` 다음 각 줄은 `stepId|title|수행|완료 기준|이상 대응` 형식이다. 위 5개 파일의 현재 사본은 같은 디렉터리의 `work-in-progress/`에 보관했다. 정식 소스는 루트이며 사본으로 최신 파일을 덮어쓰지 않는다.

## 4. 다음에 이어서 할 일 — 콘텐츠

- [ ] 현재 109개 항목을 전수 분류한다: 직원교육 / 일상 루틴 / 정기 유지관리 / 최초 개설 전용.
- [ ] `legal/permits`, `legal/academy` 등 최초 등록 중심 항목의 신규 탐색·추천 제외를 검토한다. 기존 설치본·이력·ID는 삭제하지 않는다.
- [ ] CCTV·개인정보·노무·위생교육은 최초 설치와 운영 중 점검을 구별한다. 기존 항목을 전부 정기관리라고 간주하지 않는다.
- [ ] 직원교육을 새로 작성한다: 손 씻기·교차오염, 도구/장비 안전, 주문·고객 응대, 세척·설거지, 인수인계·이상 보고, 버디 실습·재교육. 시범 → 크루 실습 → 버디 확인을 구분한다.
- [ ] 정기관리 상세를 작성한다: 냉장·냉동고/온도계, 후드·필터·배수, 방충·방서, 소모품·시설, 교육 재확인. 제조사/매장별 주기를 명시하고 임의의 법정 주기·수치를 만들지 않는다.
- [ ] 18개 상세 초안을 검토해 `docs/market/SOURCE.md`의 같은 sourceId에 적용한다. 기존 step ID를 보존하고 새 단계에만 새 ID를 쓴다.
- [ ] 기존 셀프바·테이블 화구 조건 ID를 보존한다. `developer/manual_setup.mjs`의 `food/hall-open.selfbar`, `food/hall-close.selfbar/burner`를 특히 확인한다.
- [ ] `food/service-reset`, 기존 common/process 및 업종별 레시피/업무도 세부 절차와 완료·이상 기준을 보강한다. 이번 18개 초안에 포함되지 않았다.
- [ ] 뼈찜 콘텐츠의 고정 영업시간·특정 매장 문구·후기 조사 표현을 매장 설정/승인 레시피 참조로 정리한다. 정량·온도·기한은 지어내지 않는다.
- [ ] 각 매뉴얼에 실제 조정할 매장 값(위치, 도구, 제품, 수량, 담당, 주기 등)을 짧게 안내한다. 가져온 매뉴얼에도 남도록 tip/manual에 보존하며 매 단계에 불필요한 설정 체크를 반복하지 않는다.
- [ ] 기존 법적/안전 출처는 필요 부분을 다시 확인하고 `reviewedAt`/reference 확인일을 정직하게 기록한다. 영국 자료를 한국 법적 기준으로 제시하지 않는다.
- [ ] taxonomy에 교육·정기관리 목적 추가/명칭 조정을 검토한다. 기존 폴더와 개인화 콘텐츠가 자동 삭제·재분류되지 않게 한다.
- [ ] `npm run market:build`로 새 current와 불변 release를 생성한다. 이전 releases는 수정하지 않는다.

## 5. 다음에 이어서 할 일 — UI·서버

- [ ] 현재 마켓 초안을 분석·포맷하고 직접 사용성을 점검한다. 검색·4개 용도·단일 좁혀보기 버튼이 명확한지 확인한다.
- [ ] 필터 시트는 임시 선택 → 적용, 닫기는 기존 선택 보존. 초기화·검색 무결과·담은 항목 유지·읽기 전용 상태를 검증한다.
- [ ] 현재 카탈로그에는 아직 `useCase`가 없다. 코드만으로 직원교육 목록은 채워지지 않는다. 콘텐츠 분류와 함께 완성한다.
- [ ] `useCase`는 탐색 용도이고 `suggestedUse`/settings.usage는 실행 방식이다. 교육·정기관리의 잘못된 일일 생성이 없는지 서버에서 검증한다.
- [ ] 신규 매장과 기존 기본 매뉴얼 구성에서 교육·정기관리 가져오기/미활성화가 동일하게 동작하는지 확인한다.
- [ ] 기존 daily settings와 이미 생성된 업무 기록은 소급 변경하지 않는다. 정기관리의 실제 반복 설정은 매장별 기존 설정으로 연결한다.
- [ ] startup의 오래된 클라이언트 직접 가져오기 요청을 허용할지 서버 계약을 점검한다. UI에서 숨긴 것과 API 제한을 혼동하지 않는다.
- [ ] 새 메타데이터가 스키마·DB validateRelease·공용 동기화·백업을 통과하는지 확인한다. 구 발행본에 필드가 없을 때 해시가 달라지지 않아야 한다.
- [ ] 마켓 카드와 교육 상세의 가독성, 320/390/1200px·글자 1.5배·긴 이름·시트 마지막 항목/고정 footer·접근성 선택 상태를 검증한다.

## 6. 테스트·문서·완료 기록

- [ ] 기존 `app/test/manual_market_discovery_test.dart`는 옛 업종 버튼/법적 칩/정확히109개를 기대한다. 실제 새 동작에 맞게 갱신하고 담기·충돌·재시도 회귀를 유지한다.
- [ ] `developer/test/manual_market.test.mjs`의 원본 contentHash 불변 테스트는 콘텐츠 편집과 충돌한다. 원본/단계 ID 유지와 과거 실행·개인화 보호를 검증하도록 의도에 맞게 변경한다.
- [ ] 교육·정기관리 일괄 daily 활성화 차단, 창업 준비 추천 제외, 조건별 단계 보존, 소스 업데이트와 개인화 보호 회귀를 추가한다.
- [ ] Flutter: `flutter analyze` 및 마켓·업종 구성·매뉴얼·조건 구성 관련 테스트. 화면 캡처 도구 `app/tool/market_discovery_review.dart`도 새 UI에 맞춰 실행한다.
- [ ] Node: `npm run test:console`, `npm run market:check`, `npm run check`, `npm run check:ui-links`.
- [ ] DB 발행 전 `npm run test:catalog-sql`, 변경된 Edge 런타임 관련 검사도 수행한다.
- [ ] `PRODUCT.md`, `docs/ARCHITECTURE.md`, `docs/UI_UX_GUIDELINES.md`와 관계표 S45/S47/S55/S64를 갱신한다.
- [ ] `docs/project-state.json`을 최신 상태로 다시 읽고 revision/history를 추가한다. 미실시·실패 검사와 배포 여부를 구분한다.

## 7. 배포 경계와 지금의 상태

이번 수정은 **커밋·웹 배포·API 배포·DB 발행·네이티브 빌드/업로드 모두 미실시**다. 기존 서비스는 이 작업 이전 상태다.

- 실제 운영 카탈로그는 Postgres stable에서 공급한다. SOURCE/current 수정이나 웹 배포만으로 DB 공용 목록이 갱신되지 않는다.
- 콘텐츠가 준비되면 기존 인증된 초안·검토·발행 절차를 확인한다. 이전 D-108 관리자 직접 발행 예외는 그때의109개에만 적용됐으며 이번 새 발행의 독립 검토를 가장하지 않는다.
- 사용자 재개 시 우선 구현·검증을 마쳐 구체적으로 검토 가능한 결과를 만든다. 자동으로 심사 중 네이티브 빌드를 취소하지 않는다.
- 이전 완료 기준: 웹 code `a35827b`, 문서 `9253331`, Android9 내부 사용 가능/Alpha 심사 중, iOS10 심사 대기. 이 상태는 이전 턴 확인값이며 다음에 콘솔 최신 상태를 확인한다.

## 8. 이번에 확인한 참고 자료

직원교육/청소 주기 구조를 참고하는 용도다. 개별 매장의 수치·국내 법적 충족을 보장하는 근거가 아니다.

- [FSA/영국 정부 직원교육·위생 안내](https://www.gov.uk/running-food-business/staff-training-illness-hygiene)
- [SFBB 음식점 자료와 교육 기록 양식 목록](https://www.gov.uk/government/publications/safer-food-better-business-for-caterers)
- [FSA 청소 일정 작성 안내](https://www.food.gov.uk/sites/default/files/media/document/sfbb-cleaning-04-your-cleaning-schedule-fix_1.pdf)
- [식품안전나라 뷔페 위생관리 자료](https://www.foodsafetykorea.go.kr/portal/board/boardDetail.do?bbs_no=bbs001&menu_no=3120&ntctxt_no=1075047)

다음 요청 예: **“docs/MANUAL_ROUTINE_TODO_2026-10-10.md를 읽고 남은 작업을 계속해 주세요.”**
