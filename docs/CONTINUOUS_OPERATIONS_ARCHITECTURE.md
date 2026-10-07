# 지속 운영·매뉴얼/체크리스트 아키텍처 검토

작성: 2026-10-07. 상태: **DB 발행·서버 연결·에이전트 팀 구현. 후속 제안은 아래 범위 표 참조**.

실제 구현/운영 절차: [DB 카탈로그 운영](DB_CATALOG_OPERATIONS.md), [에이전트 팀](CONTENT_AGENT_TEAM.md). 제안한 모든 테이블/후속 기능을 완료한 것은 아니다.
기준: 현재 로컬 소스, D-073/TAP 단일 운영 설정, D-081/공용 자동 갱신·개인화, D-095/복수 매장.

## 1. 사용자 목표와 이번 설계의 범위

매뉴얼과 체크리스트를 실제 업무 수행에 연결하여 사장님이 부재한 시간에도 일관된 서비스 품질을 유지하도록 지원한다. 외부 조사와 현장 피드백을 체크리스트/매뉴얼 개선으로 연결하고, 콘텐츠는 DB에서 발행하여 앱 재배포 없이 갱신한다. 모든 사업장을 장기 대상으로 하되 초기 작은 식음료 매장의 업무 흐름을 출발점으로 한다. 사용자의 후속 지시에 따라 별도 교육 과정·교육 과제·진도·평가 모듈은 만들지 않는다. 업무 중 필요한 방법은 매뉴얼에서 바로 확인한다. 채용 공고·지원자 수집·자동 채용 결정까지 이번 요청의 확정 기능으로 확대하지 않는다.

**확정 방향**은 위 사용자 목표다. 아래 테이블명, 역할 분리, 발행 단계, 검토 주기, 지표은 구현 가능한 **제안(proposed)**이다. 에이전트 팀은 5역할 prompt/산출물 스키마·실행 큐/CLI로 구성했다. 주기 실행은 아직 활성화하지 않았다.

구현 범위는 공용 발행 DB/검토 API·operations 연결·기존 카탈로그 seed·팀 실행 도구다. 관리자 웹 CMS, 별도 source/advisory/현장 피드백/예외 UI는 후속이며 제안 계약을 아래에 보존한다.

## 2. 현재 구현에서 재사용할 것과 공백

| 확인한 실제 코드 | 현재 제공하는 것 | 개선이 필요한 경계 |
|---|---|---|
| `developer/manual_market.mjs` 첫 import, `scripts/build-manual-market.mjs` | SOURCE.md → 검증 JSON → 해시 기반 불변 release | 원본이 `current.json` 정적 import. 콘텐츠 변경마다 operations Edge 재배포 필요 |
| `syncManualCatalog`, `catalogView`, `mutateManualMarket` | 연결 양식 자동 갱신, 개인화 분리, 가져오기 idempotency | sync만 catalog 주입 가능. 조회/가져오기/업종 구성도 동일 요청의 같은 발행본을 사용하도록 의존성 통일 필요 |
| `developer/manual_catalog_schema.mjs` | 안정적 source/Task ID, 콘텐츠 필드 allowlist, 출처/적용 대상 | taxonomy도 정적 import. 업종 추가를 DB 콘텐츠 발행으로 처리하려면 검증 taxonomy도 발행본에서 받아야 함 |
| `syncManualCatalog`의 contentHash 비교 | 내용이 같은 양식은 불필요한 재작성 방지 | 출처·검토일만 바뀌면 link.releaseId는 이전 값에 남을 수 있음. 콘텐츠 버전과 검토 메타데이터 버전을 구분해야 함 |
| `supabase_backend.mjs`의 early unchanged, `tap2work_read_workspace` | 매장 revision/직책/분 단위 window로 조건부 응답 | 공용 catalog revision이 조건에 없음. 중앙 발행 변경을 즉시 판별할 수 없고 분 경계까지 지연 가능 |
| `catalogLinks/catalogHistory`, 체크리스트 실행 복사본 | 개인화·운영 설정과 기존 업무 기록 보존 | 중앙 발행 전체 감사/철회·업무에 적용된 콘텐츠 버전 추적 보강 필요 |
| `manual_catalog_schema.mjs`의 references/basis/reviewedAt | 출처 정보를 표현할 수 있음 | 날짜 문자열·도메인 검사만으로 실제 조사/전문 검토 완료를 증명하지 못함 |
| 매장별 membership, section 저장, revision CAS | 매장 분리·역할별 조회/저장·충돌 거절 | 공용 콘텐츠 편집자/발행자는 매장 사장 권한과 별도 역할이어야 함 |

기존 배포 앱은 서버가 반환한 매뉴얼 데이터를 이미 표시한다. 따라서 현재 콘텐츠 스키마를 그대로 유지하는 P1 이관은 서버와 DB를 한 번 전환한 뒤 **기존 앱에서도 콘텐츠 수정에 앱 재배포가 필요 없게** 만들 수 있다. 새로운 입력 위젯·업무 실행 방식를 추가하면 앱 변경이 필요하다. ‘앱 배포 없이 모든 기능을 바꿀 수 있다’는 목표로 확장하지 않는다.

## 3. 목표 구조

```mermaid
flowchart LR
  R[외부 근거 조사] --> D[콘텐츠 초안 DB]
  F[매장 피드백·관리 공백] --> D
  D --> V[근거·현장 적용 검토]
  V --> P[버전 발행 API]
  P --> C[불변 발행본 DB와 채널 포인터]
  C --> O[operations: 요청당 동일 발행본]
  O --> W[매장 양식·개인화·운영 설정]
  W --> A[Flutter 업무·매뉴얼]
  A --> E[수행·예외 기록]
  E --> F
```

세 영역을 분리한다.

- **공용 지식**: 업종 공통 절차, 출처, 적용 조건, 체크 기준, 검토 이력, 발행 버전. 크루 개인정보를 포함하지 않는다.
- **매장 운영**: 도입한 TAP, 파트/시간/담당, 장비·장소, 개인화 내용, 해당 매장의 수행/예외 기록. workspace 경계를 따른다.
- **직원 관계**: 계정·매장 소속·직책·고용 상태와 배정. 지원자/채용 자료는 필요 시 별도 모델로 추가하며 공용 지식과 섞지 않는다.

## 4. DB 계약 제안

| 저장소 | 주요 필드/키 | 책임·불변 조건 |
|---|---|---|
| `content_sources` | id, canonicalUrl, publisher, retrievedAt, effectiveFrom/To, jurisdiction, evidenceHash, licenseNote | 근거 원문 위치/요약·유효 기간. 검색한 날짜와 근거가 적용되는 날짜 구분 |
| `content_drafts` | id, sourceId, draftRevision, baseVersionId, payload, sourceRefs, applicability, changeSummary, riskClass | 에이전트/편집 초안. 수정은 draftRevision CAS. 원문 전체 무단 복제 대신 필요한 근거/자체 작성 요약 |
| `content_reviews` | draftId, draftRevision, payloadHash, reviewerId, reviewType, outcome, reason, at | 검토 결과가 특정 내용 해시에 결합. 수정되면 이전 승인 재사용 금지 |
| `content_versions` | versionId, sourceId, contentHash, metadataHash, schemaVersion, payload, publishedAt | 검토를 통과한 불변 콘텐츠. 편집·물리 삭제 대신 새 버전 |
| `catalog_releases` / `catalog_release_items` | releaseId, taxonomyVersion, schemaVersion, manifestHash; releaseId+sourceId → versionId | 완전한 한 발행본의 manifest. 동일 sourceId의 중복 버전 금지 |
| `catalog_channels` | channelId, revision, activeReleaseId, updatedAt | 활성 발행본의 작은 포인터. 잠금/CAS로 원자 전환. rollback도 새 revision으로 기록 |
| `content_publication_events` | operationId, actorId, fromReleaseId, toReleaseId, reason, at | 발행·철회·롤백 감사. idempotency는 동일 actor+요청 해시에만 적용 |
| `content_advisories` | id, affectedVersionIds, severity, reason, replacementVersionId, status | 잘못된 내용의 경고·철회 정보. 실행 기록 원문을 바꾸지 않음 |
| 기존 `catalogLinks` 확장 | templateId, sourceId, appliedVersionId, evaluatedReleaseId, mode, contentHash | 실제 적용 내용과 최신 검토한 발행본 구분. 기존 releaseId 읽기 호환 유지 |
| `operational_exceptions` | workspaceId, taskExecutionId, contentVersionId, reasonCode, ownerId, status, dueAt, resolution | 할 수 없는 업무·누락·사고 위험을 담당자에게 넘기고 해결까지 추적 |
| `content_feedback` | id, sourceId/versionId, sanitizedContext, category, evidenceRefs, status | 공용 개선용으로 정제한 현장 의견. 개인/매장 원본 기록의 복제 금지 |

전체 카탈로그/연구 기록을 매장 section JSON 안에 반복 복제하지 않는다. 기존 운영 실행 snapshot은 재현을 위해 보존한다. 중앙의 큰 자료·버전 이력은 별도 테이블, 이미지/영상은 버전 지정 Storage 경로와 검증된 미디어 타입으로 관리한다. 이관 초기의 매장 catalogHistory 보존과 향후 장기 기록 분리 정책은 별도 명시한다.

## 5. 발행·권한·장애 계약

제안 상태 흐름: `draft → in_review → approved → published`; `rejected`는 수정 후 새 draft revision, 발행 후 오류는 advisory/새 버전으로 정정한다. 에이전트 산출물은 draft이며 reviewedAt를 조사 완료 증거처럼 임의 갱신하지 않는다.

발행 API는 다음을 한 트랜잭션에서 검증한다: 인증된 제공자 역할, 요청 draftRevision/해시, 필요한 검토 결과, 스키마 호환성, 안정적 ID, 출처/적용 조건, 예상 channel revision. 불변 버전과 release를 기록하고 channel 포인터를 바꾸며 publication event/outbox를 남긴다. 경쟁 발행은 409, 동일 operationId 재시도는 같은 결과. 중간 실패 시 포인터만 바뀌는 상태를 만들지 않는다.

권한 제안: 조사자=근거/초안, 편집자=초안 수정, 검토자=검토 결과, 발행자=승인본 승격. 매장 사장/매니저는 자기 매장 도입·개인화만 수행한다. service key는 서버에만 두고 연구 에이전트에는 제공하지 않는다. 에이전트용 API에서 scope를 검증하며 발행 경로는 별도 권한으로 제한한다. RLS뿐 아니라 service 권한을 쓰는 서버의 인증/대상 검증도 필요하다.

전문 판단이 필요한 항목의 검토자 자격, 작성자/검토자 분리, 자동 발행 허용 범위와 주기는 **proposed**다. 우선은 검토된 초안의 명시적 발행으로 설계한다. 이번 문서 자체가 정기 자동 조사/게시 권한을 생성하지 않는다.

장애 시 이미 검증된 같은 채널의 마지막 정상 발행본을 제한된 시간 재사용하고 stale 상태/실패를 기록한다. 이관 후 번들 JSON을 무조건 fallback하면 오래된 내용을 재적용할 수 있으므로 번들은 최초 seed/격리 샘플 전용으로 제한한다. 정상 캐시가 없는 최초 로드 실패는 재시도 가능한 오류로 반환하며 ‘최신’으로 표시하지 않는다. 캐시 허용 시간/SLO는 구현 전 부하 측정으로 확정한다.

## 6. 서버·앱 연결 변경

1. `CatalogRepository.getPublished(channel)`에서 `{release, channelRevision}`을 읽는다. 작은 포인터는 짧은 캐시, 불변 release는 ID 기반 캐시, 동시 요청은 single-flight로 합친다. 채널/버전/스키마별 캐시를 분리한다.
2. `createCloudHandler`가 **요청당 한 번** 발행본을 고정해 `OperationsStore`에 주입한다. ensureDueTasks/sync, catalogView, import/configure가 모두 그 동일 객체를 사용한다. mutable 전역 catalog는 두 요청/매장 간 오염 위험이 있어 사용하지 않는다.
3. `validateCatalog(entries, taxonomy)`처럼 taxonomy 의존성도 명시한다. DB 등록 검증과 운영 읽기 검증이 동일 계약을 사용한다. 임의 JS/SQL/HTML 실행 지시를 콘텐츠로 받아들이지 않는다.
4. 조건부 읽기에 `catalogRevision`을 추가한다. 매장 revision이 같아도 catalogRevision이 다르면 unchanged를 반환하지 않는다. 기존 앱이 필드를 보내지 않으면 기존 분 단위 full refresh로 호환하고, 신규 앱은 발행본 갱신을 명시적으로 확인한다. 즉시 강제 푸시를 보장하지 않는다.
5. 가져오기/업종 구성의 releaseId가 요청에 고정된 발행본과 다르면 기존 409 재조회 경로를 사용한다. DB 전환 중 조회는 B, 가져오기는 번들 A를 쓰는 혼합 경로를 금지한다.
6. 중앙 발행은 모든 매장에 동기 쓰기하지 않는다. 첫 읽기에 연결 양식을 갱신하고 기존 workspace revision CAS로 저장한다. 작업 중 충돌은 재조회로 처리하며 사용자 저장을 조용히 덮어쓰지 않는다. outbox 배치 갱신은 규모가 커진 뒤 추가하고 같은 멱등 적용 로직을 사용한다.
7. `contentHash`는 방법/문구, `metadataHash`는 출처/적용 조건을 구분한다. 내용이 같아도 evaluatedReleaseId와 메타데이터는 갱신하고, 내용 버전 증가와 변경 요약은 실제 변경 기준으로 분리한다.
8. P1은 기존 `manualCatalog`/`manualSearch` 응답 모양을 유지한다. 카탈로그 전체 반복 전송은 후속 `GET /catalog/manifest`와 페이지/검색 API, release별 ETag 캐시로 분리한다. 크루에게 제공자 초안/매장 편집 이력을 내려주지 않는다.

새 계약 예시(필드명은 proposed):

```json
{
  "catalogRevision": 42,
  "catalogReleaseId": "sha256-of-manifest",
  "catalogStatus": "current",
  "schemaVersion": 2
}
```

schemaVersion 2가 지원하는 문구·Task·이미지 링크·출처/업종 데이터 변경은 앱 재배포 없이 처리한다. 새로운 스키마/렌더러가 필요한 발행본은 호환성 검사를 통과한 채널에만 올리며, 오래된 앱은 마지막 호환 발행본과 업데이트 안내를 사용한다. 신규 앱 지원 전 비호환 발행을 일반 채널에 강제하지 않는다.

## 7. 매장 반영과 체크리스트·서비스 품질

D-081을 유지한다: `linked` 양식은 공용 내용 자동 갱신, `personalized`는 자동 덮어쓰기 금지. 폴더·파트·시간대·필요 인원·완료 규칙은 매장 운영 설정이다. 중앙 조사자가 배정/권한/급여 설정을 변경하지 않는다. 기존 생성 실행은 완료 여부와 무관하게 당시 snapshot을 보존하고 이후 생성 업무부터 새 양식을 사용한다.

중대한 변경 때문에 이미 생성된 업무도 알아야 하는 경우, 원문을 변경하는 대신 버전 연결 advisory를 해당 업무/매뉴얼에 표시하는 방식을 제안한다. 언제 실행 중지를 요구할지, 개인화 매장에도 어떤 경고를 보여줄지는 검토가 필요한 제품 정책이다. 긴급 발행을 과거 업무/개인화 덮어쓰기의 우회로로 사용하지 않는다.

매뉴얼과 체크리스트는 같은 Task 콘텐츠의 두 표현이다. 체크리스트는 **무엇을 확인/실행할지**, 매뉴얼은 **어떻게 하고 무엇을 정상으로 판단할지**를 제공한다. Task를 누르면 해당 실행 버전의 방법을 바로 확인한다. 최신 공용 내용과 당시 실행 내용은 버전으로 구별하고, 별도 교육 화면이나 진도를 만들지 않는다.

콘텐츠 작성 단위 제안:

| 항목 | 작성 기준 | 기존 구조와 연결 |
|---|---|---|
| 실행 제목 | 관찰 가능한 한 행동, 짧은 동사형 | Task.title |
| 수행 방법 | 순서·필요 도구·매장별 조건 | Task.manual, tip, imageUrl/videoUrl |
| 완료 기준 | 사용자가 결과를 확인할 수 있는 기준; 임의 숫자/기준 생성 금지 | 현재 manual 본문에 포함. 별도 구조 필드는 호환 스키마 확장 시 검토 |
| 예외 대응 | 못 했을 때의 조치·보고 대상·다음 행동 | manual에 포함, 후속 운영 예외 모델과 연결 |
| 적용 범위 | 업종·설비·제품·관할·전제 조건 | catalog applicability/references, 매장 도입 시 확인 |
| 수행 시점/담당 | 매장에서 TAP 단위로 설정 | 기존 TAP settings/파트·시간대. Task별 배정 재도입 금지 |

예: ‘마감 시 냉장 설비 상태 확인’이라는 체크 항목에는 매장 기준 확인 방법, 이상 상태 판단, 이상 발견 시 담당자에게 넘길 절차가 함께 있어야 한다. 구체 온도/법적 기준은 업종·제품·장비에 맞는 근거를 검토해 작성하며 이번 설계에서 임의 지정하지 않는다.

관리 공백은 누락·수행 불가·기준 모호함·방법 오류·담당 부재로 구분해 정제된 피드백을 남긴다. 단순 완료율만으로 품질을 판단하지 않고 반복 누락, 미해결 예외/해결 시간, 매뉴얼 수정 뒤 동일 문제 재발을 본다. 대리 책임자·응답 기한·교대 인계는 체크리스트 운영을 보완하는 제안이며 별도 교육 기능과 연결하지 않는다. 증빙은 필요한 업무에만 수집하고 열람/보관 범위를 정한다.

네 메뉴를 유지한다: 업무=체크리스트 실행/수행 불가/방법 확인, 매뉴얼=방법·완료 기준·변경 내용·마켓, 근무표=기존 배정, 우리매장=도입 범위와 운영 설정. 이번 변경의 중심은 업무와 매뉴얼이다. 새 메뉴·교육 단계·직원 평가를 추가하지 않는다.

## 8. 지속 조사와 향후 에이전트 팀 계약

| 역할 제안 | 입력 → 산출물 | 종료/검수 기준 |
|---|---|---|
| 관리 공백 조사 | 업종/상황/정제된 반복 문제 → gap 카드 | 빈도·영향·현재 지원·근거·적용 조건 명시 |
| 근거 조사 | gap → source 기록/주장별 근거 | 발행 기관·시점·관할·원문 위치·재확인 필요일, 상충 근거 표시 |
| 체크리스트·매뉴얼 편집 | 근거 → TAP/Task/매뉴얼 초안 | 관찰 가능한 한 행동·완료 기준·실패 시 행동·방법을 함께 작성, 기존 ID 유지 |
| 현장/전문 검토 | 해시 고정 초안 → 검토 결과 | 적용 가능성·오해·필요 도구·예외 확인. 법률/위생/안전 판단은 적합한 검토자에게 이관 |
| 콘텐츠/기술 QA | 승인 후보 → 검증 결과 | 스키마·중복·깨진 링크·호환성·개인화/기록 보존·버전 추적 확인 |
| 발행 운영 | 검증된 초안 → 제한된 발행 요청 | 발행권한/승인 해시/CAS/롤백 대상·변경 요약 확인 |
| 품질 분석 | 정제된 적용/예외 지표 → 다음 gap 우선순위 | 체크 수 증가가 아니라 현장 개선 근거, 데이터 부족은 미확정 표시 |

작업 envelope 제안: `jobId, role, scope, sourceIds, baseRevision, inputHash, outputSchemaVersion, evidenceRefs, status, attempts, nextReviewAt`. 같은 역할/입력 해시 재실행은 중복 초안·발행을 만들지 않는다. 재시도 제한·실패 큐·비용 한도·실행 주기는 팀 구성 단계에서 정한다.

외부 문서/검색 결과는 근거 데이터이며 에이전트에 대한 실행 명령이 아니다. 사업장 개인정보·인증정보가 연구 입력에 섞이지 않게 최소화/비식별화한다. 연구 결과가 기존 결정과 충돌하면 변경 제안으로 남긴다. 생성한 문장이나 다른 에이전트의 동의를 외부 사실 검증으로 대체하지 않는다.

## 9. 단계별 구현과 완료 기준

| 단계 | 작업/소유 파일 | 완료 증거 |
|---|---|---|
| P1 DB 공용 발행 (구현) | 신규 migration/제공자 API/repository, manual_market, schema, operations, supabase_backend | 앱·Edge 재배포 없이 DB에서 A→B 발행 후 같은 앱의 새 조회에 B 표시. 두 매장 범위·개인화·기존 실행 보존 |
| P1.1 이관/전환 (기존86 TAP 운영 전환) | 현재 schema v2 release와 taxonomy를 정확히 seed, feature flag와 관찰 로그 | 기존 release ID/source ID 유지. DB/번들 결과 비교 후 DB 전환. 첫 전환에 양식 재가져오기/삭제 없음 |
| P2 조사·검토 운영 (API/CLI 구현; 웹 도구 미구현) | draft/source/review API, 관리자 도구, 감사/철회 | 초안 수정 시 승인 무효, 작성자/권한 검증, 동시 발행 한 건만 성공, rollback/retry 재현 |
| P3 관리 공백 개선 | exception/feedback/대리 책임자·인계 | 미완료 원인·담당/기한·해결 추적. 샘플 매장 운영에서 반복 문제 감소를 관찰 |
| P4 에이전트 팀 (5역할 큐/CLI 구현; 정기 실행 미활성) | 위 계약 기반 격리 역할/잡 큐·정기 실행 | 초안 전용 최소 권한, 중복/재시도/실패 큐·비용 관찰, 검토되지 않은 자동 발행 차단 |

순서는 제안이며, P1/P2의 콘텐츠 공급 경계를 먼저 안정화한다. 모집 기능이나 에이전트 수 확대가 DB 발행 전환의 선행 조건은 아니다.

P1 필수 회귀: 일반 크루/매장 owner의 중앙 쓰기 거절; authenticated/anon 직접 테이블 쓰기 거절; 발행 해시 불일치; stale channel CAS; 동시 발행/멱등 재시도; 요청 중 채널 전환; source/Task ID 보존; taxonomy만 변경; 출처만 변경; 기존 실행·개인화 보존; read unchanged 무효화; DB 장애/최초 로드/캐시 만료; rollback 시 개인화 보존; 비호환 스키마; DB 이관 전후 결과 동등성. 서버 테스트와 격리 SQL 검증 후 단계적으로 운영 전환한다.

운영 성공 기준은 단순 CI 성공이 아니라 **동일 설치 앱 + 동일 Edge 배포 ID**에서 DB 콘텐츠 A→B→이전 발행본 복귀를 테스트 매장으로 확인하는 것이다. 실운영 매장에 시험 매뉴얼을 자동 발행하지 않는다.

## 10. 공식 기술 근거와 검토 범위

- [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security): service 권한의 우회 특성 때문에 서버·제공자 권한 경계를 별도로 설계했다.
- [Supabase 데이터 보호](https://supabase.com/docs/guides/database/secure-data): secret/service key는 앱/에이전트에 배포하지 않고 서버 경계에 둔다.
- [PostgreSQL SELECT](https://www.postgresql.org/docs/current/sql-select.html): 발행 채널 행 잠금과 트랜잭션을 이용한 경쟁 발행 제어의 근거. CAS 구현은 신규 SQL에서 검증할 예정이다.

2026-10-07 공식 문서 확인. 이번 검토는 코드 구조/기술 설계이며 개별 업종의 최신 법률·안전 매뉴얼 내용 조사나 현장 품질 보증을 수행한 것이 아니다.
