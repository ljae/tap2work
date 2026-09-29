# 설정 저장과 웹 성능 · 2026-09-29

## 저장 모델

작은 매장 운영의 현재 규모에서는 매장 단위 CAS를 유지하고 **변경된 도메인 문서만 저장**한다. 매번 전체 JSON을 다시 쓰거나 아직 쓰지 않는 검색 인덱스/별도 서버를 늘리지 않는다.

| 테이블 | 키·내용 | 조회/보안 |
| --- | --- | --- |
| `tap2work_workspaces` | 매장 ID, 이름, 만든 계정 | 소속 사용자만 기본정보 조회 |
| `tap2work_members` | workspace_id + user_id, 직책, 표시 이름 | user_id unique 인덱스로 소속 조회; 클라이언트 변경 금지 |
| `tap2work_state` | workspace_id, revision, updated_at, 이전 payload | 현재 revision의 잠금 행. payload는 이관 시점의 복구 사본이며 **현재값 조회에 사용하지 않음** |
| `tap2work_documents` | workspace_id + section, value JSONB, size_bytes, updated_at | 현재값의 원본. 복합 PK로 매장/영역 조회; 서비스 역할만 접근, 원문 RLS 차단 |

`tap2work_read_workspace(user_id, revision?, window?, role?, workspace_id?)`는 검증된 계정의 소속과 현재 문서를 한 RPC로 읽는다. 같은 매장·직책·revision·UTC 1분 구간이면 본문 없이 unchanged를 반환한다. 시간 구간이 바뀌면 전체 검증을 거쳐 한국 날짜 경계·예약 업무·주문 경과시간을 재계산한다. JWT 확인은 매 요청 계속 수행한다.

`tap2work_patch_state(workspace_id, expected_revision, changes, removed)`는 매장 revision 행을 잠근 뒤 충돌 시 false를 반환한다. 변경된 영역만 upsert하고 명시적으로 제거된 키만 삭제한다. 신규 값·전체 크기 한도 8MiB를 검사하며 크기 합계는 저장된 size_bytes로 계산한다. 다른 영역의 JSONB와 updated_at은 다시 쓰지 않는다. 앱의 기존 액션별 서버 검증·권한·이력은 유지한다.

처음 매장을 만들면 INSERT trigger가 문서를 생성한다. 이관은 문서가 없는 매장만 채워 반복 실행으로 최신값을 덮어쓰지 않는다. 기존 payload는 자동 삭제하지 않는다. 백엔드를 예전 payload reader로 단순 롤백하면 낡은 값이 보일 수 있으므로, 롤백 시 최신 문서를 합성하는 reader를 유지하거나 검증된 복구 마이그레이션을 먼저 수행한다.

## 화면별 저장 영역

| 화면 / 설정 | 저장 문서 section | 저장 경로 |
| --- | --- | --- |
| 매장 이름·업종·주소·안내·영업 기본시간·POS·배달·인력 | store | save_store_profile |
| 파트·요일 시간대·직책 권한 | workplace | save_workplace_parts/day/permissions |
| 주문처리 보드 사용 | store | save_order_system |
| 매장 정산 정책·정책 이력 | payrollSettings, payrollSettingsHistory | save_payroll_settings |
| 크루 정보·파트·선호시간·시급 | tappers | save_tapper / save_staff_profile |
| 근무 계획·반복·특정 날짜 시간 | staffShifts, shiftPatterns, rosterOverrides | 배정·슬롯 저장 액션 |
| 보드·TAP·Task·매뉴얼·시간/수량 규칙 | checklistFolders, taskTemplates, tasks | save_checklists / save_tap_settings / save_task_step / save_step_manual |
| 원재료·최소량·가격·발주 후 점검일 | items | save_inventory_item; 실사·발주·입고는 별도 액션 |
| 메뉴·가격 | sales | save_menu |
| 준비품·메뉴별 사용량 | preparedItems | save_prepared_item |
| 배치 크기·기기·테이블·정원 | layout, zones | save_layout |
| 채용 초안·인건비 검토 | hiringDrafts, laborReviews | save_hiring_draft / save_labor_review |
| 실제 실행 기록 | attendance, payments, payAdjustments, orders 등 | 기존 액션·이력 보존 |

각 필드의 타입/범위와 상속은 [설정 관계도](UI_SETTINGS_RELATIONSHIP_MAP.md) 및 서버 도메인 검증을 따른다. 새로운 section도 같은 트랜잭션에 포함되므로 필드 추가를 누락해서 저장하지 못하는 상황을 막는다. 무제한 JSON 쓰기 API를 클라이언트에 노출하지 않는다.

**설정 저장과 외부 기능 가동은 다르다.** 위치/Wi-Fi 출퇴근 인증, 보건증 업로드, 실계정 초대, POS·공급사 연동은 현재 읽기 안내/미연동 항목이며 실제 기능 활성화로 표시하지 않는다. 이들은 데이터만 저장한다고 완성되지 않는다. 향후 인증·파일보관·외부연동을 구현할 때 전용 보안 계약을 추가한다. 첫 근무 학습 진도는 기존 기기 로컬 저장이다.

## 읽기·비용 최적화

- 활성 앱의 정기 읽기: 5초 → 30초. 시간당 720회 → 120회, 요청 수 약 83% 감소. 저장 결과는 즉시 반영하고 앱 복귀·당겨 새로고침은 즉시 조회한다. 다른 기기의 변경은 최대 약 30초 뒤 표시될 수 있다.
- 숨겨진 탭/백그라운드에서는 정기 읽기를 중단한다. 응답이 unchanged면 기존 화면 상태를 보존한다.
- 일반 클라우드 GET은 Auth 검증 + 소속/데이터 RPC의 두 요청. 불변 화면을 확인하는 같은 분의 요청은 DB에서 JSON 합성 및 Edge 투영을 건너뛴다.
- 저장은 변경 문서만 DB로 전송한다. 정산 설정을 바꿔도 업무/근태 이력을 다시 쓰지 않는다. 원문 전용 RLS, JWT와 CAS를 비용 절감을 이유로 생략하지 않는다.
- 전체 JSONB에 GIN 인덱스를 만들지 않는다. 현재 API는 매장/영역의 PK만 조회한다. 대규모 이력 검색이 실제 필요해지면 attendance/tasks를 날짜별 별도 테이블로 분리하고 쿼리 근거로 인덱스를 추가한다.
- 8MiB 한도를 유지한다. 초과 시 조용히 이력을 지우지 않고 저장을 실패시킨다. 장기 이력 분할은 후속 설계다.

## 첫 로딩

4개 정적 Pretendard 대신 공식 원본 가변 글꼴 1개를 사용한다. 한글/기존 글리프를 삭제하지 않는다. gzip 기준 글꼴 전송 약 4.24MB → 2.95MB (약 30% 감소). TTF 원본 파일 크기는 오히려 크므로 원본 크기를 전송량으로 보고하지 않는다.

HTML에서 main.dart.js와 글꼴을 먼저 요청하고 Chromium의 CanvasKit wasm도 JS 해석과 병렬 다운로드한다. 실제 첫 프레임 이벤트에서만 로딩 화면을 제거한다. 임의 지연이나 가짜 진행률은 없다.

브라우저 실측은 빈 캐시·390×844·80ms 지연·다운로드 10Mbps·CPU 4배 감속 Chrome에서 3회 수행한다. 실제 휴대폰이나 모든 지역의 보장 속도가 아니며 로그인 화면 진입과 매장 데이터 준비 시간도 구별한다.

## 근거

- [Flutter 초기화](https://docs.flutter.dev/platform-integration/web/initialization)
- [Flutter 글꼴 형식](https://docs.flutter.dev/cookbook/design/fonts)
- [Pretendard 원본과 라이선스](https://github.com/orioncactus/pretendard)
- [Supabase 인덱스](https://supabase.com/docs/guides/database/postgres/indexes)
- [Supabase JSONB](https://supabase.com/docs/guides/database/json)

## 임시 공용 로그인 운영

사용자가 기존 계정 매장 공유를 승인했다. `public-login`은 서버 환경의 고정 이메일만 사용하고 기존 Auth 계정 확인 후 이메일 발송 없이 일회용 링크를 생성·검증한다. 응답은 no-store이며 Flutter가 세션을 저장한다. 방문자가 보낸 이메일/비밀번호는 사용하지 않는다. 모든 방문자가 계정 권한을 공유하므로 개인별 작업자를 식별할 수 없다.

`TAP2WORK_PUBLIC_LOGIN_ENABLED=false`는 신규 공용 로그인만 차단한다. SSO 전환 시 이미 발급된 공유 계정 세션을 별도로 폐기하고 사용자별 멤버십을 구성한다. Google OAuth ID/secret, Apple Services ID/Team ID/Key ID 및 서명 키는 Supabase 관리 화면에 설정한다. callback은 프로젝트의 `/auth/v1/callback`. SSO 버튼은 `ENABLE_SSO` 플래그로 숨긴다.

## 배포 실측

2026-09-29 소스 `9566197` 배포 후 동일한 빈 캐시 Chrome 조건에서 각각 3회 측정했다. 첫 프레임 중앙값 6,889 → 5,893ms (14.5% 단축), 초기 리소스 전송 중앙값 7,820,328 → 6,543,884 bytes (16.3% 감소). 첫 프레임은 로그인/매장 데이터 준비 완료와 다르다. 별도 일반 연결에서 로그인 클릭 → 매장 응답 1,086ms, 새로고침 후 추가 공용 로그인 없이 매장 복원을 확인했다. 실제 청구 금액과 네이티브 성능은 측정하지 않았다.

사전 Flutter 143개·Node 101개 테스트, SQL rollback 통합 검증과 CI 배포 검증을 통과했다. 공유 계정 로그아웃은 `SignOutScope.local`로 다른 방문자의 세션을 유지한다.
