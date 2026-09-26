# Supabase 연결과 저장 범위

2026-09-24 구현. `.env`는 Git에서 제외되며 비밀값을 문서·공개 앱에 복사하지 않는다.

| 환경변수 | 사용 위치 |
| --- | --- |
| `SUPABASE_URL` | 앱과 서버의 프로젝트 주소 |
| `SUPABASE_PUBLISHABLE_KEY` | Flutter 빌드와 Auth 로그인에 사용하는 공개 키 |
| `SUPABASE_SECRET_KEY` / 기존 `SUPABASE_API`의 service key | 관리 작업용 서버 키. Flutter에는 전달하지 않음 |
| `SUPABASE_ACCESS_TOKEN` | Management API 마이그레이션과 Edge Function 배포 |
| `SUPABASE_PROJECT_REF` | 배포 대상 프로젝트 |
| `DATABASE_URL` | 직접 Postgres 연결이 필요할 때만 사용. 현재 REST/RPC 구성에는 불필요 |

`npm run backend:deploy`는 버전 관리된 SQL을 적용하고 `operations` Edge Function을 배포한다. 함수는 Supabase 내장 `SUPABASE_SERVICE_ROLE_KEY`를 사용한다. 공개 GitHub Pages 빌드에는 저장소 Variables의 `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`만 제공한다. 빌드 스크립트는 service/secret 키를 공개 키로 전달하면 실패한다.

## tap2work 전용 Codex MCP 세션

전역 `~/.codex/config.toml`의 `supabase` 서버는 다른 프로젝트의 runner를 사용한다. 해당 설정을 바꾸지 않고 이 저장소에서만 tap2work 프로젝트로 실행하려면 `sh scripts/codex-tap2work.sh`를 사용한다. 이 명령은 Codex의 세션별 `-c` 설정으로 같은 `supabase` 서버를 이 저장소의 `scripts/launch-supabase-mcp.mjs`로 덮어쓴다. 실행기는 Git 제외 `.env`에서 Management API 토큰을 읽고 프로젝트 참조값이 `sgpmhqtaylgqymeqciin`인지 확인한다. 토큰은 명령 인자나 저장소 파일에 복사하지 않는다. 기존 Codex 세션의 MCP 연결은 바뀌지 않으므로 새 세션에서 사용한다.

Codex 앱에서 디렉터리별로 자동 적용하려면 신뢰된 저장소의 `.codex/config.toml`에 다음 로컬 설정을 둘 수 있다. 이 파일은 `.gitignore`에 포함한다.

```toml
[mcp_servers.supabase]
command = "node"
args = ["/Volumes/ORICO/tap2work/scripts/launch-supabase-mcp.mjs"]
cwd = "/Volumes/ORICO/tap2work"

[mcp_servers.supabase.tools.execute_sql]
approval_mode = "approve"
```

현재 작업 샌드박스는 `.codex/` 생성을 거부해 위 앱 설정 파일은 작성하지 않았다. 새 CLI 세션의 설정 선택은 `sh scripts/codex-tap2work.sh mcp get supabase`로 확인했다. 실제 Supabase 조회는 네트워크 DNS와 새 세션에서 별도 확인해야 한다.

## 이용 흐름

- 비로그인: 가상 매장 체험. Tap 체크·이동은 메모리에서만 공유되고 새로고침하면 초기화된다. 배치 편집은 저장되지 않는다.
- 상단 계정 아이콘: 이메일 가입/로그인. 가입 확인 메일의 링크는 `https://tap2.work/`로 돌아온다.
- 첫 로그인: **빈 매장** 또는 **샘플 매장**을 명시적으로 선택한다. 빈 매장에는 가상 주문·직원·재고·업무가 생성되지 않는다. 사장 계정만 먼저 만들고, 매장 이름·메뉴·재료·지도·체크리스트를 직접 설정한다. 로컬 `.local/` 데이터는 복사하지 않는다.
- 기존 샘플 계정: 매장 설정에서 샘플을 서버 내부에 보관한 뒤 빈 매장으로 시작할 수 있다. 자동으로 바꾸지 않는다. 이 보관본은 일반 응답에 노출되지 않으며 현재 앱에는 복원 UI가 없다.
- 로그인 후: 체크리스트·주문 상태·직원 명부/근무/계산 기록·배치를 Supabase에 저장한다. 로그인 계정의 사장 Tapper가 자신의 출퇴근을 기록할 수 있다.
- 매장 설정: 사장님은 매장 이름과 안내를 수정한다. 사장님·매니저 권한은 재료와 메뉴를 추가·수정·보관할 수 있다. 새 재료 수량은 0으로 시작하고 실물 수량은 별도 확인한다. 메뉴 변경은 이전 주문 항목의 이름·가격 기록을 바꾸지 않는다. 입고 대기 재료와 미완료 재고 업무, 진행 중 주문 또는 준비품에 연결된 메뉴는 보관할 수 없다. 편집은 열 때의 revision으로 저장하며 충돌 시 입력을 유지하고 최신 내용을 확인하도록 한다.
- Supabase Auth 사용자와 `tap2work_members`의 매장/역할을 서버에서 확인한다. 체험 역할 선택 헤더는 클라우드 권한에 영향을 주지 않는다.

## 데이터 모델과 제한

`tap2work_workspaces`, `tap2work_members`, `tap2work_state`에 RLS를 적용한다. 직원/급여를 포함할 수 있는 원본 state JSON은 인증된 클라이언트에도 직접 공개하지 않는다. Edge Function이 서버 역할별 화면 데이터를 반환하고 수정 권한을 확인한다. 전체 운영 state는 매장별 JSONB에 저장하며 revision 비교 RPC로 동시 수정을 차단한다. 일반 사용자에게 원본 테이블 수정 권한과 bootstrap/save RPC 실행 권한이 없다.

현재 계정당 하나의 매장, 가입자는 자신의 새 매장 사장 역할이다. **다른 계정을 기존 매장에 초대·연결하는 UI와 다중 매장 전환은 아직 없다.** Team의 명부 등록 자체가 로그인 계정을 생성하거나 초대하지 않는다. 새 빈 매장에는 주문이 없으며 POS 주문을 입력하거나 가져오는 기능도 없다. 샘플 매장의 주문은 합성 데이터다. 기존 공급업체로 실제 주문을 전송하거나 실제 급여를 지급하지 않는다. 법정 수당·공제·급여 확정 정책은 D-032의 미확정 범위다.

`npm run backend:deploy`는 `supabase/migrations/`의 SQL을 파일명 순으로 적용한 뒤 Edge Function을 배포한다. 2026-09-26 추가 마이그레이션은 workspace 표기 이름을 저장된 매장 이름과 맞춘다. 기존 계정은 다음 저장 시 이름이 동기화된다.

## 확인한 항목

- Management API SQL 적용 및 Edge Function 배포 성공.
- 임시 Auth 사용자 2명으로 로그인, 별도 매장 생성과 상호 데이터 분리 확인.
- 주문 Tap 완료가 홈 대기열에서 제거되고 저장되는 것 확인.
- 낡은 revision 수정은 409, 비로그인 함수 호출은 401.
- 공개 키/일반 사용자 토큰으로 원본 state 조회는 거부됨.
- 임시 사용자와 그 소유 매장 데이터 삭제 완료.
- Node 테스트는 위조 역할 헤더 무시, 직원의 배치 수정 거부, CAS 충돌을 별도로 검증한다.

가입 메일의 실제 수신과 네이티브 앱 링크는 아직 검증하지 않았다. 배포된 웹 로그인·저장과 네이티브 출시 검증을 구분한다.
