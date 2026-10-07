# 매뉴얼·체크리스트 콘텐츠 에이전트 팀

2026-10-07 구현. 별도 교육 과정·진도·평가를 만들지 않는다. 사장님 부재 시의 관리 공백을 근거 조사와 매뉴얼·체크리스트 수정 후보로 연결한다.

## 구성과 저장 경계

`.agents/content-team/manifest.json`이 버전 관리되는 팀 계약이다. 5개 역할은 서로 다른 prompt/산출물 스키마를 사용하고 의존 순서대로 실행한다.

| 역할 | 입력과 산출물 | 완료 의미 |
|---|---|---|
| researcher | 정제된 업종·관리 공백 → 출처/주장/적용 조건/미확인 사항 | 실제 접근한 출처와 발췌 해시를 기록 |
| editor | 근거 → 체크 행동·방법·완료 기준·예외 대응 초안 | sourceId/Task ID 보존, 사람 검토 필요 |
| reviewer | 근거와 고정 초안 → 독립 검토·전문 검토 필요 사항 | AI candidate이며 인간 승인 아님 |
| qa | 앞선 결과 → 계약/ID/근거 연결 검증 | 실행하지 않은 링크·서버·앱 검증은 미완료 |
| coordinator | 모든 결과 → 준비된 초안 인계 또는 차단 원인·다음 gap | 생산 발행 권한 없음 |

`prompts/common.md`와 각 역할 prompt는 Codex/Claude/현재 세션의 하위 에이전트 모두 공유할 수 있다. 실행 시 prompt와 스키마를 job에 고정해 이후 팀 설정 변경이 이전 job을 조용히 바꾸지 않는다. 사용자의 홈 설정/Claude 설정·모델·메모리 설정을 변경하지 않는다. [agent-development 스킬](/Users/jaelee/.agents/skills/agent-development/SKILL.md)의 역할별 최소 도구·독립 재현·선행/후행 계약 원칙을 적용했다.

job은 `.local/content-team/<jobId>/`에 저장하고 Git/공개 리뷰 빌드/운영 workspace에 넣지 않는다. scope JSON 필드는 mode, industry, gap, jurisdiction, sourceIds, baseRevision만 허용한다. 알려진 credential 마커도 거부한다. 입력은 담당자가 개인정보 없는 상황으로 정제해야 한다. 자유 문장의 모든 개인정보를 자동 익명화하는 기능은 아니다.

## 실행

```sh
# 외부 모델 호출 없이 5역할 fixture 파이프라인/검증
node scripts/content-team.mjs smoke --job fixture-demo
node scripts/content-team.mjs validate --job fixture-demo

# samples/gap.json은 fixture다. 실제 조사 scope는 mode:"research"로 별도 작성한다.
node scripts/content-team.mjs init --job handoff-gap-v1 --scope /path/to/sanitized-gap.json
node scripts/content-team.mjs run --job handoff-gap-v1 --runner codex
```

`run` 한 번은 다음 역할 하나를 실행한다. 5번 실행하거나 status로 재시도/차단 상황을 확인한다. 설치된 Codex CLI를 실제 child process로 호출하며 로그인된 Codex 계정의 사용량/한도를 사용한다. 새로운 유료 API 계정을 만들거나 외부 서비스 키를 받지 않는다. Codex runner에는 read-only sandbox, 사용자 config/MCP 미로딩, 최소 env, 저장소 상위 AGENTS/운영 파일을 포함하지 않는 임시 작업 폴더, 역할별 JSON output-schema를 지정한다. native `--search`로 공개 출처를 직접 검색/확인할 수 있다. 서비스 DB key·SUPABASE env·운영 credential을 상속하지 않는다. 모델을 강제 지정하지 않는다.

read-only sandbox는 코드/운영 변경을 막는 실행 설정이고 운영체제의 전체 파일 읽기 격리나 DLP를 구현했다는 뜻은 아니다. prompt에 홈/자격증명/운영 자료 읽기를 금지하며 job에는 정제된 자료만 공급한다. 높은 격리가 필요하면 별도 OS 계정/격리 실행 환경에서 같은 큐를 실행한다.

Codex를 호출하지 않고 현재 Codex/Claude 세션의 agent로 수행할 수도 있다.

```sh
node scripts/content-team.mjs next --job handoff-gap-v1
# 반환된 packet.prompt/outputSchema/runDirectory의 입력으로 해당 역할 수행.
# output.json에 envelope를 저장하고 next가 반환한 leaseId를 그대로 사용.
node scripts/content-team.mjs record --job handoff-gap-v1 --artifact /path/to/output.json --lease LEASE_ID
node scripts/content-team.mjs status --job handoff-gap-v1
```

`next`는 15분 lease를 잡는다. 진행 중 중복 claim은 leased를 반환한다. model 호출/검증 오류는 `run`이 fail 처리하고 동일 입력으로 다음 시도한다. 역할당 최대 3회, job당 최대 15회, Codex 호출당 10분이다. wall time/call count가 모델 토큰/요금의 정확한 상한을 보장하지 않는다. 초과/3회 실패는 failed 큐에 유지한다. 수정은 새 scope/job ID로 시작하며 실패 기록을 삭제하지 않는다. 사용자 선택은 직접 요청 실행이다. 정기 예약은 해제했다. [누적 개선/피드백/수동 실행](CONTENT_IMPROVEMENT.md)을 따른다. 자동 발행은 활성화하지 않았다.

```sh
node scripts/content-team.mjs fail --job handoff-gap-v1 --lease LEASE_ID --reason "출처 접근 실패"
# 프로세스 강제 종료 중 남은 lock: 소유 PID가 종료되었을 때만 회수 가능
node scripts/content-team.mjs unlock --job handoff-gap-v1
```

## 무결성·멱등성

scope, 고정 팀 설정, 선행 산출물의 SHA-256를 역할 inputHash에 연결한다. 출처 evidenceHash는 UTF-8 excerpt 원문을 검증한다. 이는 발췌 변조 탐지이며 URL 실제 내용/공식 승인 자체를 증명하지 않는다. job/role/inputHash/lease 불일치, 가짜 humanApproved/publishAllowed, fixture를 외부 조사로 대체, 근거 ID 누락/중복, 변조된 이전 파일을 거부한다. 결과는 불변이며 동일 결과 record 재시도는 이미 저장된 해시를 반환한다. review가 changes_required거나 QA fail이면 coordinator가 prepared로 기록할 수 없다.

## DB 초안으로 넘기기

완료된 **research** job만 export할 수 있다. fixture는 생산 초안으로 export하지 못한다. 기존 전체 v2 발행본을 읽고 수정 sourceId/Task ID에 내용을 합친다. 기존 Task·참조를 삭제하지 않는다. 완료 기준/예외 대응은 현재 앱이 지원하는 manual 본문에 넣는다. 700자 초과는 오류이며 몰래 잘라내지 않는다. 기존 reviewedAt는 유지해 AI 검토를 사람의 전문 승인으로 표현하지 않는다. 새 TAP의 전체 업종/목적/분류 metadata는 공급자 편집자가 작성해야 한다.

```sh
node scripts/content-team.mjs export-release --job handoff-gap-v1 --base /path/to/published-release.json --out /path/to/draft-request.json
# 사람 공급자의 JWT와 SUPABASE_URL을 환경에서 전달. 서비스 키를 에이전트에 주지 않는다.
node --env-file=.env scripts/catalog-admin.mjs save_draft /path/to/draft-request.json
```

export는 `{release,summary,revision:0}` draft 요청과 별도 `.provenance.json`(기준 발행본·선행 해시·사람 검토 필요)을 새 파일로 저장한다. 기존 base/출력 파일을 덮어쓰지 않는다. `validateRelease`로 전체 taxonomy/catalog와 canonical releaseId를 검증한다. DB 저장은 **등록된 사람/제공자 계정의 명시적 save_draft**이며 export가 네트워크 요청이나 발행을 하지 않는다. DB reviewer는 작성자와 다른 actor로 exact draft revision/hash를 승인해야 한다. 이후 publisher의 명시적 발행/CAS/감사가 적용된다. 에이전트 candidate 또는 job complete 상태는 DB approved 상태가 아니다.

## 이번 검증

5역할 `fixture-first-team-20261007` smoke를 실제 로컬 큐에서 완료했다. fake executable을 이용한 child-process 테스트로 Codex 인수/서비스 env 제거를 확인했다. 16개 Node 테스트가 모두 통과했다. 추가로 실제 설치 Codex CLI의 researcher 역할 1회가 `fixture-codex-strict-schema-20261007`에서 38.847초에 완료했고, source.kind=fixture/URL 빈 문자열/외부 조사 미수행을 유지한 산출물이 스키마·해시 검증을 통과했다. 최초 실행과 진단 재시도는 strict JSON Schema의 const/enum 노드 type 누락으로 HTTP 400에서 실패했다. 명시적 type을 추가하고 새 고정 job으로 검증했으며 이전 실패/시도 이력을 보존했다. 실행 오류의 제한된 진단에는 JWT/Bearer/API 키 패턴을 제거한다.

실제 외부 연구·업종별 전문 검토·생산 초안 등록/발행·주기 스케줄은 이번 fixture 검증에 포함하지 않았다. 실제 연구 job은 위 명령으로 명시적으로 시작한다.

## 누적 개선 입력

새 job에는 source registry, 이전 검토/QA/실행 오류, 제공자/현장 평가를 고정 learning snapshot으로 전달한다. 요청 실행은 `npm run content:cycle -- run --request REQUEST_ID`; default manual이다. 실제 관측 시각/시간대를 검사하고 재시도에는 이전 오류와 실행 시각을 전달한다. lease 재발급 시 입력 해시도 새 실행 문맥에 결합한다. 기존 불변 산출물/작업 설정은 유지한다. source/feedback의 정정 및 지표는 [CONTENT_IMPROVEMENT.md](CONTENT_IMPROVEMENT.md)에 있다.
