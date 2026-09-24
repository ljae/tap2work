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

## 이용 흐름

- 비로그인: 가상 매장 체험. Tap 체크·이동은 메모리에서만 공유되고 새로고침하면 초기화된다. 배치 편집은 저장되지 않는다.
- 상단 계정 아이콘: 이메일 가입/로그인. 가입 확인 메일의 링크는 `https://tap2.work/`로 돌아온다.
- 첫 로그인: 계정별 매장을 생성하고 새 가상 메뉴·주문·직원 샘플을 넣는다. 로컬 `.local/` 데이터는 복사하지 않는다.
- 로그인 후: 체크리스트·주문 상태·직원 명부/근무/계산 기록·배치를 Supabase에 저장한다. 로그인 계정의 사장 Tapper가 자신의 출퇴근을 기록할 수 있다.
- Supabase Auth 사용자와 `tap2work_members`의 매장/역할을 서버에서 확인한다. 체험 역할 선택 헤더는 클라우드 권한에 영향을 주지 않는다.

## 데이터 모델과 제한

`tap2work_workspaces`, `tap2work_members`, `tap2work_state`에 RLS를 적용한다. 직원/급여를 포함할 수 있는 원본 state JSON은 인증된 클라이언트에도 직접 공개하지 않는다. Edge Function이 서버 역할별 화면 데이터를 반환하고 수정 권한을 확인한다. 전체 운영 state는 매장별 JSONB에 저장하며 revision 비교 RPC로 동시 수정을 차단한다. 일반 사용자에게 원본 테이블 수정 권한과 bootstrap/save RPC 실행 권한이 없다.

현재 계정당 하나의 매장, 가입자는 자신의 새 매장 사장 역할이다. **다른 계정을 기존 매장에 초대·연결하는 UI와 다중 매장 전환은 아직 없다.** Team의 명부 등록 자체가 로그인 계정을 생성하거나 초대하지 않는다. 주문은 합성 데이터이며 POS·실제 공급업체 발주·실제 급여 지급과 연결되지 않는다. 법정 수당·공제·급여 확정 정책은 D-032의 미확정 범위다.

## 확인한 항목

- Management API SQL 적용 및 Edge Function 배포 성공.
- 임시 Auth 사용자 2명으로 로그인, 별도 매장 생성과 상호 데이터 분리 확인.
- 주문 Tap 완료가 홈 대기열에서 제거되고 저장되는 것 확인.
- 낡은 revision 수정은 409, 비로그인 함수 호출은 401.
- 공개 키/일반 사용자 토큰으로 원본 state 조회는 거부됨.
- 임시 사용자와 그 소유 매장 데이터 삭제 완료.
- Node 테스트는 위조 역할 헤더 무시, 직원의 배치 수정 거부, CAS 충돌을 별도로 검증한다.

가입 메일의 실제 수신과 네이티브 앱 링크는 아직 검증하지 않았다. 배포된 웹 로그인·저장과 네이티브 출시 검증을 구분한다.
