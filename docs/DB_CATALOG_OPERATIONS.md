# DB 공용 매뉴얼·체크리스트 운영

2026-10-07 구현. 공용 콘텐츠는 Postgres의 불변 발행본과 `stable` 채널로 공급한다. 이후 내용 변경에는 앱/operations 재배포가 필요 없다. 새 렌더러/스키마·기능은 코드 배포가 필요하다. 별도 교육 기능은 없다.

## 저장 구조와 현재 범위

- `tap2work_catalog_roles`: 기존 Auth 계정의 공급자 권한. 매장 직책과 독립.
- `tap2work_catalog_drafts`: 전체 v2 카탈로그 초안, 작성/기여 계정, revision, 해시, 요약, 상태.
- `tap2work_catalog_reviews`: 특정 draft revision/hash에 대한 독립 검토. 모든 기여자는 자기 초안을 승인할 수 없다.
- `tap2work_catalog_releases`: taxonomy/출처/매뉴얼을 포함하는 불변 JSONB 발행본.
- `tap2work_catalog_channels`: 현재 release와 증가하는 revision. 초기값0, 발행/rollback마다 증가.
- `tap2work_catalog_publication_events`: 요청 ID·행위·대상·이유의 불변 이력.

근거는 현재 entries.references에, 조사 산출물은 에이전트 job 파일에 보존한다. 제안 설계의 독립 source/advisory/feedback/exception 테이블은 아직 구현하지 않았다. 관리자 웹 CMS 대신 인증된 API와 CLI를 제공한다. 에이전트는 초안 후보만 만들고 실제 공급자 검토/발행 권한은 가지지 않는다.

## 최초 이관

`20261007010000_content_catalog.sql`을 한 번 적용한다. PostgREST가 새 RPC를 찾지 못하면 DB 관리 권한으로 `notify pgrst, 'reload schema';` 후 재시도한다. 기존 workspace 테이블/완료 기록을 이관하거나 삭제하지 않는다.

```sh
npm run catalog:seed
```

이 명령은 `.env`의 서버 키로 **기존 checked-in release와 ID 그대로** stable의 빈 채널만 초기화한다. 이미 같은 발행본이면 쓰지 않고 종료하고, 다른 발행본이면 실패한다. 일반 발행/업데이트를 seed로 우회할 수 없다. 운영 이관은 기존 86 TAP 그대로 수행했다.

## 공급자 계정 등록

실제 공급자 Auth 계정을 지정해 관리자가 명시적으로 등록한다. 계정을 임의 생성하거나 기존 매장 사장에게 자동 권한을 주지 않는다.

```sh
npm run catalog:grant-role -- --user AUTH_UUID --role editor --execute
npm run catalog:grant-role -- --user OTHER_AUTH_UUID --role reviewer --execute
npm run catalog:grant-role -- --user PUBLISHER_AUTH_UUID --role publisher --execute
```

공급자 등록은 관리자의 `SUPABASE_ACCESS_TOKEN` 경계다. 조사 에이전트에는 이 토큰/서버 키를 전달하지 않는다. 운영 계정의 구체 UUID는 버전 관리 문서에 기록하지 않는다. 사용자가 지정한 기존 계정에 editor/reviewer/publisher 역할을 등록했다. 같은 계정이 작성한 초안을 승인할 수 없으므로 해당 초안의 독립 검토에는 다른 등록 계정이 필요하다.

## 콘텐츠 발행

`CATALOG_ACCESS_TOKEN`에는 호출자의 Supabase 사용자 JWT, `SUPABASE_URL`/publishable key는 기존 설정을 사용한다. 서비스 키로 앱/에이전트에서 제공자 신원을 가장하지 않는다.

1. `save_draft`: `{release,summary,revision:0}`. 서버가 taxonomy·콘텐츠·해시를 검증해 draftId/revision/payloadHash를 반환한다. 편집은 draftId와 기존 revision을 포함한다.
2. `read_draft`: `{draftId}`. 등록된 제공자가 정확한 초안/review를 확인한다.
3. `review`: `{draftId,revision,payloadHash,outcome:"approved"|"rejected",reason}`. 작성/수정 기여자와 다른 reviewer로 호출한다. 수정 시 기존 승인은 무효이며 새 revision을 다시 검토한다.
4. `publish`: `{draftId,revision,payloadHash,channelRevision,requestId,reason,channel:"stable"}`. publisher만 가능. expected channel revision이 다르면409. requestId는 UUID이고 동일 요청 재시도에서 유지한다.
5. `rollback`: `{releaseId,channelRevision,requestId,reason,channel:"stable"}`. 같은 채널에 과거 발행됐던 버전만 복원한다. revision은 증가하며 과거 실행/개인화는 그대로 둔다.

```sh
npm run catalog:admin -- save_draft /path/to/draft-request.json
npm run catalog:admin -- read_draft /path/to/draft-id.json
npm run catalog:admin -- review /path/to/review-request.json
npm run catalog:admin -- read_published /path/to/channel.json
npm run catalog:admin -- publish /path/to/publish-request.json
```

등록되지 않은 매장 owner/크루는 중앙 초안·검토·발행을 할 수 없다. RPC는 service 전용이며 `catalog-admin`은 JWT를 검증한 user.id만 전달한다. 고객 입력 actorId/role을 신뢰하지 않는다. 직접 테이블 writes는 RLS/grant로 막는다. 중앙 제공자 권한은 별도 등록 계정만 갖는다.

## 런타임 갱신과 동시성

operations 요청은 DB에서 한 발행본을 고정한 뒤 그 객체를 조회/자동 동기화/가져오기/업종 구성에 모두 전달한다. taxonomy도 해당 발행본으로 검증한다. 메타데이터만 바뀌어도 링크의 확인 발행본은 갱신하되 매뉴얼 내용 버전/실행을 다시 쓰지 않는다.

매장 내부 `catalogSync`는 적용한 channel revision/release를 저장한다. 늦은 이전 요청이 더 최신 적용본을 만났으면409로 거절해 내용이 뒤로 돌아가지 않는다. rollback은 더 높은 channel revision으로 이전 내용을 적용한다. 상태는 클라이언트 역할 투영에서 숨긴다.

새 앱은 `catalogRevision`을 조건부 조회에 포함한다. 중앙 발행이 바뀌면 workspace revision/window가 같아도 full read를 한다. 기존 앱은 catalogRevision을 보내지 않으므로 full read로 호환한다. 기존 30초 활성 폴링에서 반영하며 비활성 앱에는 다음 조회에서 반영된다. 푸시 알림/백그라운드 보장을 추가하지 않았다.

공용 연결 양식만 갱신하고 생성된 실행 snapshot·운영 설정·개인화는 보존한다. DB가 없거나 검증되지 않은 발행본이면 오류로 종료한다. 이관 이후 오래된 번들로 조용히 돌아가지 않는다. 현재는 요청마다 DB 발행본을 읽으며 카탈로그 전체 DB read 캐시/페이지 API는 후속 비용 최적화다.

`SOURCE.md/current.json`은 최초 seed·로컬 데모/공개 샘플 및 테스트용이다. DB 발행 이후 이 파일을 편집/재배포해 운영 공용 콘텐츠를 갱신하지 않는다. 새 빈 매장에도 같은 DB 발행본이 공급된다. 공개 정적 샘플은 기존 번들이므로 DB 운영 최신성과 구별한다.

## 검증과 운영 한계

Node API/도메인 검증, PGlite 격리 SQL, Flutter HTTP cache·기존 마켓 회귀를 수행했다. SQL은 역할/정확한 승인/기여자 제한/불변 이력/멱등/채널 CAS/rollback/기존86 TAP의 정확한 seed/read를 검증한다. 기존 SQL 테스트의 발행 충돌은 순차 CAS이며 별도 실제 DB 다중 세션 부하 검증은 미실시다.

```sh
# 외부 설치 모듈 경로를 선택해 격리 PostgreSQL 실행
node scripts/test-content-catalog-sql.mjs --pglite-module=/absolute/node_modules/@electric-sql/pglite/dist/index.js
npm run test:console
npm run check
```

지정된 공급자 계정 등록은 완료했다. 별도 독립 검토 계정 지정과 실제 콘텐츠 검토/발행은 다음 운영 단계다. 이번 운영 초기화는 기존 발행본 보존이며 시험 콘텐츠를 stable에 발행하지 않았다. 별도 source 자료 관리/철회 표시/현장 피드백 UI 및 정기 에이전트 스케줄은 후속 구현이다.
