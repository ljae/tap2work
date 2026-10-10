2026-10-10 최신 구현 중: D-119~123에 따라 사장님·크루 공통 웰컴/업무/매뉴얼과 공유 진행 기록, 8개 안내 언어를 적용한다. 신규 크루는 국적 필수·안내 언어 별도 선택이며 본인 언어 설정이 우선한다. 최신 사용자 선택은 기존 공용 매뉴얼 사전 번역 + 수정 항목만 번역 필요 표시 + 직접 등록/JSON 가져오기다. Google 실시간 유료 번역은 비활성화한다. 웹·iOS·Android 배포는 Sol low 담당으로 승인되어 있으며 실제 결과는 프로젝트 이력/SHARED_PARTNER_LANGUAGE_RELEASE_2026-10-10.md를 확인한다. 원어민 검수 및 배포 완료로 미리 표시하지 않는다.

2026-10-10 후속 구현: [역할별 에이전트 실행](docs/MANUAL_NAVIGATION_AGENT_DELIVERY_2026-10-10.md). 실제 Flutter 업무에서 행동·설명·사진·체크 통합 슬라이드를 사용하고, 저장 성공 뒤 다음 행동으로 이동한다. 촬영/앨범 사진은 자동 축소·방향 보정·JPEG 변환 후 등록한다. 운영 저장소 활성화·실기기 촬영은 별도 검증이며 이번 소스 구현만으로 배포 완료가 아니다. 사용자는 설거지의 시작 준비·교대·마감 체크/영업 중 필요 시 안내, 다른 매장 복원 시 본문 유지·사진 재등록을 확정했다. 시간 연결·웰컴·버디·원본 선택 적용·리마인드·네이티브 안내의 전체 후속 일정은 기존 계획을 유지한다.

## 2026-10-10 최신 방향: 신입 크루 업무 내비게이션 (계획, 미구현)

사진 후속 확정: 바로 촬영해 등록하는 흐름을 우선하고 업로드 전에 적정 화질·크기로 자동 변환한다. 고화질 원본 저장을 기본으로 하지 않는다. 1280px/목표150KB·최대250KB JPEG는 초기 검토용 기술안이다. 독립 시안의 변환은 동작하며 실제 카메라/운영 Storage 연결은 아직이다.

최신 후속: 핵심 행동과 자세한 설명·사진 링크/첨부·수행 체크를 한 화면에 담고, 좌우 슬라이드로 다음 핵심 행동을 보는 통합 매뉴얼/체크리스트 방향을 사용자가 요청했다. 반납대/건조대의 식기 종류, 잔반 배출 장소, 세척용 싱크대 막힘 예방 순서를 사진과 함께 구체화한다. [통합 시안](docs/prototypes/manual-action-slides-review.html)은 가상 위치 도식·임시 사진 첨부로 검토하며 실제 앱/사진 저장 기능은 아직이다. 완료 체크는 다음 행동으로 자동 이동하고, 체크 없이도 좌우 탐색할 수 있다. 실제 앱에서는 저장 성공 후 이동한다.

후속 사용자 선택(D-112): 주요 내용을 작은 시안으로 하나씩 검증한다. 첫 근무·중요 변경의 웰컴은 **별도 화면**으로 선택했으며 평소 다시보기·업무 진입 허용은 유지한다. [검토 순서와 체험 결과](docs/MANUAL_NAVIGATION_REVIEW_SEQUENCE_2026-10-10.md). 독립 HTML 시안 검증이며 실제 Flutter 적용은 아직이다.

사용자는 외식 공통·설거지/주방 보조의 첫 본보기부터 웰컴 → 영업 전 선택형 모션 리마인드 → 시간별 체크 → 상세 방법을 연결하도록 요청했다. 업무 ON은 크루가 직접 켜며 출퇴근과 별도다. 일반 업무는 본인 체크, 지정 핵심 업무는 버디 확인이고 버디 부재 시 본인이 사유를 적어 최종 완료할 수 있다. 본인 예외 완료와 버디 확인은 구별한다. 사장님이 공통·파트별 리마인드 묶음을 고르고 크루는 한 번에 확인한다. 매뉴얼은 사장님·권한 있는 매니저가 매장 공통본을 수정한다.

웰컴은 첫 근무·중요 변경 시 보여주며 사장님이 중요 변경을 지정한다. 재확인을 요청하되 업무 진입은 허용한다. 공용 개선은 **사장님이 내용을 보고 TAP별로 선택 적용**하며 매장 수정 충돌은 확인 후 교체한다. 이는 기존 미수정 연결본 자동 갱신을 대체하는 확정 목표이고 아직 구현되지 않았다. 모든 기존 생성 실행·개인화·이력은 보존한다. 매뉴얼·시간별 체크를 먼저 구현하고 Android PIP/iPhone Live Activities 및 명시적으로 켠 이어폰 듣기·반복·일시정지는 병렬 실험한다.

[상세 작업·에이전트 협업·질의 계획](docs/MANUAL_NAVIGATION_WORK_PLAN_2026-10-10.md). 10월10일 5개 코드 초안·18개84절차의 기존 미완료 항목을 인수하며 이번 작업은 계획·문서만 변경했다. 통합 운영 범위와 네 주요 메뉴를 유지하고 별도 LMS를 추가하지 않는다. 아래 과거 ‘새 업데이트 정책 미정’ 설명은 이번 선택으로 대체한다.

2026-10-10 이전 발행 완료: 웹 c8c96a9 / Actions37948946797 성공, operations·catalog-admin 배포 및 운영 stable109개(revision2) 발행. 사용자가 추가 동의 없이 반영을 명시하여 이번 발행은 DB 관리자 직접 작업으로 기록했다. 독립 검토 계정을 가장하거나 승인 이력을 생성하지 않았다. 당시 새 원본 업데이트 정책은 미정이었다.

2026-10-09 사용자 요청 적용: 외식업 공통+업종 특화 초기 구성, 셀프바/테이블 화구 조건과 공통 장소 연결, 코랄 아이콘·텍스트 수정 구분, 장소 목록·층/사진/찾는 방법·선택 배치도를 구현했다. 공용109개 후보의 DB 발행은 독립 검토 대기이며 운영86개를 임의 교체하지 않았다. 상세는 docs/MANUAL_SPACE_RELEASE_2026-10-09.md. 새 원본 업데이트 정책은 계속 미정이다.

## 업종 중심 등록 후속 · 2026-10-08 (최신)

표준 주소 검색 결과 선택과 상세 주소를 분리하고 기존 매장 정보에도 같은 컨트롤을 사용한다. 파트를 직접 추가할 수 있고 필요 인원은 화면당 최대 3파트로 나눈다. POS 연결·배달앱/주문처리는 확장 범위이므로 초기 설정에서 제외한다. 과거 설정/API는 보존한다.

업종을 선택하면 공용 매뉴얼/체크리스트와 기본 메뉴·주요 재료·레시피 초안이 따라온다. 13개 구체 업종에 각 2개 기본 메뉴 후보, 기타 업종은 직접 추가. storeSetupCatalog.bundles/bundleVersion을 서버가 제공하며 setup.menuIds를 검증해 같은 원자 생성에 포함한다. 메뉴의 ingredientIds는 중복 제거한 items를 가리키고 menuManualId는 기존 메뉴·레시피 폴더의 편집 가능한 TAP을 연결한다. 초기 재고/가격은 0, 공급처/단위/발주 기준은 확인 대상으로 표시하고 실 주문/재고 증가는 만들지 않는다. 메뉴·재료는 기존 CatalogEditor에서, 레시피는 매뉴얼에서 수정한다. 업종 변경/공용 콘텐츠 갱신은 매장 편집본을 자동 덮어쓰지 않는다.

customParts 임시 ID는 save_workplace_parts가 발급한 안정 ID로 headcounts까지 변환한다. 주소는 공식 Kakao Postcode embed로 선택하고 profile.addressSelection에 도로명/지번/우편번호를, addressDetail에 층·호수를 저장한다. 웹 iframe 메시지는 origin/source를 모두 검증한다. 네이티브 검색은 이번 웹 범위에 포함하지 않는다.

콘텐츠 팀 researcher에 Aside CLI runner를 추가하고 메뉴·재료·레시피/매뉴얼/체크리스트의 근거·적용 조건 검토를 공유 prompt에 통합했다. 사용자 요청 때 조사하며 자동 발행은 없다. 기본 메뉴 후보는 인기 통계나 전문 검토를 주장하지 않는다.

## 새 매장 등록과 설정 통일 · 2026-10-08

새 매장은 이름·업종·운영 형태·주소·영업일/시간·교대/브레이크·파트/인원·POS/배달·기본 매뉴얼을 한 화면당 1~3개씩 선택하고 마지막에 확인해 등록한다. 첫 매장과 추가 매장은 같은 흐름이다. 치킨·한식·돈까스 등 14개 구분으로 외식 공통과 해당 업종의 기본 TAP/Task를 제안하며 제외·방법 확인·영업일 업무 사용을 선택한다. 돈까스는 기존 튀김 공통 콘텐츠로 시작한다. 이후 우리매장의 매장 정보/POS/배달 플랫폼/기본 매뉴얼 구성과 영업시간/파트/인원 배치에서 같은 저장값을 수정한다. 중복된 선언 크루 수/채용 인원 UI와 프로필 내부 운영·주문 연결 진입을 제거했다. 실제 크루·메뉴·재료·배치도·정산·권한은 등록 후 설정한다. [점검 결과](docs/STORE_SETUP_AUDIT_2026-10-08.md).

## 지속 매뉴얼·체크리스트 방향 · 2026-10-07

사장님 부재 시에도 일관된 서비스 품질을 지원하도록 매뉴얼과 체크리스트를 지속 개선한다. 매뉴얼은 수행 방법·정상 기준·예외 대응을 안내하고 체크리스트는 해야 할 일과 실제 수행을 연결한다. 사용자의 후속 지시에 따라 별도 교육 과정·과제·진도·평가 기능은 설계 범위에서 제외한다.

공용 콘텐츠는 DB 발행으로 갱신하고 외부 조사·현장 관리 공백을 개선으로 연결한다. 2026-10-07 공용 원본을 DB 발행으로 전환했다. 내용 갱신은 앱/operations 재배포 없이 가능하며 새 기능·스키마는 코드 변경이 필요하다. [지속 운영 설계](docs/CONTINUOUS_OPERATIONS_ARCHITECTURE.md)는 이를 DB로 분리하는 계약·이관·수용 기준과 향후 에이전트 역할을 정리한다. DB 발행·검토 API/CLI와 5역할 팀은 구현했고 CMS는 미구현이고 정기 실행은 사용자 선택으로 해제했으며 세부 검토·발행 정책/조사 주기는 proposed다. 채용 기능 확대는 이번 매뉴얼·체크리스트 개선의 선행 조건이 아니다.

## 매뉴얼 편집 일관성 · 2026-10-06

길게 누르기로 시작하는 편집 모드는 디렉토리와 Task 목록에 공통 적용하고 휴대폰 화면 전환 중에도 유지한다. 이동 아이콘을 누르거나 끌어서 위치를 바꾸고, 완료 버튼으로 편집을 종료한다. 일부 영역만 편집되거나 일반 설정 버튼만 남는 이전 동작을 대체한다.

## 복수 매장 관리 · 2026-10-06

하나의 개인 계정으로 여러 매장에 소속될 수 있다. 내 계정 아이콘 왼쪽의 매장 이름 드롭다운에서 매장을 선택하고 이름을 입력해 새 빈 매장을 추가한다. 추가한 계정은 새 매장의 사장님이며 기존 매장의 크루·업무·매뉴얼·근무표·재고를 복제하지 않는다. 마지막 선택은 계정별로 이 기기에 기억한다.

업무·매뉴얼·근무표·우리매장 네 목적지와 모든 설정·기록은 선택한 매장에 한정된다. 직책은 매장별 소속에서 검증한다. 전체 매장 합산 대시보드, 기존 매장 초대·이관·복제, 매장별 과금은 이번 범위에 포함하지 않으며 향후 선택 사항이다. 계정 삭제는 선택 중인 매장만이 아니라 모든 소속 매장을 검토하고, 유일 사장님인 매장만 함께 삭제한다.

## 기본 근무표 지속 적용 · 2026-10-06

저장한 영업시간과 인원 배치는 90일 만료 없이 향후 근무표에 계속 적용한다. 재저장은 영향 요일의 기존 미래 미세 조정·개별 배정·삭제를 초기화하며, 저장 이후 날짜별 별도 설정은 해당 날짜에 우선한다. 실제·과거·승인·대기 기록은 보존한다. 운영 배포 완료 여부는 최신 project-state history를 확인한다.

## 차기 매뉴얼 구조 재설계 · 2026-10-09

사용자는 실사용 유저가 없는 단계에서 업종별 완성본 구조에 얽매이지 않고 공통 업무와 맞춤이 필요한 업무를 외식업 전반 기준으로 다시 설계하도록 요청했다. Ego Lite 조사와 질의로 구성하며, 크루 화면에서는 ‘홀 마감’ 하나에 필요한 절차를 묶어 보여준다. 공통 원본 복사/연결·수정 범위·업데이트 방식은 상세 비교 후 결정한다. [조사·비교표](docs/MANUAL_STRUCTURE_RESEARCH_2026-10-09.md)의 내부 모듈 조합은 proposed이고 현재 앱/DB/공용 콘텐츠에 적용하지 않았다. 아래 기존 구현 정책은 새 설계 승인 전까지 현재 동작 설명으로 유지한다.

## 개인 로그인·개인정보·계정 삭제 · 2026-10-05

최신 사용자 요청으로 임시 공용 로그인 진입을 Apple·Google 개인 로그인으로 교체한다. iOS는 두 제공자의 네이티브 SDK, Android는 Google SDK와 Apple 웹 OAuth, 웹은 OAuth를 사용한다. 아래 과거 공용 로그인 설명은 이전 이력이다. 기존 공용 매장을 새 계정에 자동 이전하지 않는다.

운영자 OpenEdu, 개인정보 문의 tap2work.dev@gmail.com. 로그인 전과 내 계정에서 개인정보처리방침을 열고, 내 계정에서 삭제 범위를 조회·확인한 뒤 영구 삭제한다. 유일한 사장님은 매장 데이터와 전 크루의 해당 매장 접근도 함께 삭제하며 다른 크루의 로그인 계정은 보존한다. 다른 사장님이 남으면 공유 매장을 유지한다. Apple/Google provider·서버 키 설정과 tap2.work 웹·계정 삭제/운영 서버 배포를 완료했다. iOS App Store Connect 1.0.0 빌드 5는 처리 VALID를 통과해 제출 준비 버전에 연결되었다. 한국어·영어 메타데이터, 무료·전 지역 출시 설정과 심사 정보를 저장했다. 실기기 로그인·삭제 검증과 심사 제출은 남아 있다. [설정 안내](docs/NATIVE_AUTH_SETUP.md).

## TAP 배정 단일화·중앙 Task/매뉴얼 개선 · 2026-10-04 · 구현 예정

최신 사용자 요구는 시간대·파트 매칭과 주요 운영 제약을 TAP에서만 설정하고 Task별 배분을 허용하지 않는 것이다. Task는 행동·방법·자료를 함께 업데이트하는 콘텐츠 단위이며 실제 체크 기록은 유지한다. 중앙 시스템의 주간 고도화는 Task와 매뉴얼을 함께 검수·발행하고 매장이 선택 적용하는 방향이다. 기존 Task 배정 예외는 이관 계획과 과거 실행 호환으로 다루며 조용히 삭제하지 않는다. 아래 과거 Task별 설정 설명보다 이 목표가 우선한다. 현재 런타임은 아직 구 구조이며 [상세 구현안](docs/CHECKLIST_PLATFORM_IMPLEMENTATION_PLAN_2026-10-04.md)의 P0.5부터 Sol 구현을 시작할 수 있도록 정리했다.

## 임시 공용 로그인·저장 최적화 · 2026-09-29

사용자 승인으로 지정한 기존 계정의 매장을 모든 방문자가 함께 조회·수정한다. 고정 아이디와 마스킹 필드는 서버 세션 발급 진입점이며 실제 비밀번호를 배포하지 않는다. 로그인 버튼 후 Supabase 세션을 유지해 재방문 자동 로그인한다. SSO는 앱 등록 시 적용한다. 이전 D-051 무로그인 샘플 자동 진입을 대체하며 별도 샘플 둘러보기만 읽기 전용이다.

설정은 영역별 문서와 매장 revision으로 저장한다. 활성 화면에서 30초 간격 변경 확인, 동일 revision/권한/매장/시간창에서는 전체 상태를 전송하지 않는다. [데이터 계약·한계](docs/DATABASE_AND_PERFORMANCE.md).

# Product working brief

## UI/UX 우선 참조 · 2026-09-30

앞으로 신규 화면과 UI/UX 개선은 [tap2work 맞춤 UI/UX 가이드라인](docs/UI_UX_GUIDELINES.md)을 먼저 읽고 적용한다. Toss 공식 UX 원칙은 참고하되 현재 확정한 다크 테마·네 메뉴·권한 기반 편집·저장 계약을 유지한다. 기존 Toss 프롬프트 템플릿은 요약 지침으로 사용한다.

## 공통 가독성·시작 로딩 · 2026-09-28

매뉴얼·시급 정산을 포함한 편집 UI는 줄바꿈 제목, 읽기 폭 제한, 섹션 카드, 명확한 입력 라벨과 하단 저장 동작을 공통화한다. 개선 패턴은 기존 화면에도 적용한다. 앱 다운로드·초기화·매장 읽기 동안 일관된 로딩과 실패 재시도를 제공한다. 현재는 D-051에 따라 로그인 없이 샘플로 자동 진입하며 아래의 인증 진입 정책은 임시 플래그 해제 시 적용된다. [구현·검증 기준](docs/UI_READABILITY_2026-09-28.md).

## 앱 전체 모션 · 2026-09-28

버튼·선택 컨트롤·메뉴 전환·시트·확인창·진행률에 공통 모션을 적용한다. 토스 UX 가이드의 예측 가능한 흐름을 참조하며 구체적인 시간과 곡선은 자체 토큰으로 관리한다. 동작 줄이기를 지원하고 서버 저장 성공 전에 완료 효과를 보여주지 않는다. [적용 범위와 스킬 출처](docs/MOTION_GUIDE.md).

## 정산 설정과 Supabase 저장 · 2026-09-28

IMG_6093의 지급 주기(월급/주급), 정산 시작일, 시간 반올림, 사업장 규모, 주휴수당 포함을 매장 공통 설정으로 적용한다. 기존 크루별 지급 주기와 주간별 사업장 규모 선택을 대체한다. 주휴 OFF는 발생 주수를 유지하고 예상 합계에서 금액을 제외한다. 과거 출퇴근 원본·지급 기록을 바꾸지 않는다. 고정 월급 계약 계산과 실제 급여 이체는 별도다.

배포 앱은 로그인부터 시작한다. 인증된 매장의 구현된 설정은 Supabase operations 함수와 revision 검증 RPC를 거쳐 저장하며 재접속 시 불러온다. 비로그인 미리보기를 기본 화면으로 제공하지 않는다. 계정 생성 후 빈 매장 또는 샘플 매장을 선택한다. 외부 POS·위치 인증·보건증 보관은 아직 미연동이다. 로고의 앱/웹 PNG 외곽은 투명하다.

## 파트 중심 운영·근무표 · 2026-09-28

[지속 관리 아키텍처](docs/ARCHITECTURE.md)를 구현과 UI/UX 변경의 기준으로 사용한다. 직원 메뉴는 달력 아이콘의 **근무표**로 바꾸고, 사람의 제품 용어는 **크루**로 통일한다. 기존 직무 분류는 **파트 관리**로 대체한다. 주간표는 왼쪽 시간축, 요일별 파트 세부열, 충분한 열 폭과 가로 스크롤을 제공한다. 영업시간대에서 슬롯이 생성되며 클릭해 해당 날짜의 시간·크루를 조정한다. 기존 배정은 영업시간 수정으로 덮어쓰지 않는다.

업무 메뉴에서 TAP그룹 필터를 제거한다. 주문처리 시스템 연결 설정은 우리매장에 있고 기본 OFF이며 ON일 때만 주문 보드를 표시한다. 외부 시스템은 미연결로 명시한다. 선택 컨트롤은 파트 필터와 같은 pill 방식으로 통일한다. 저장 API의 과거 크루 키/ID는 기록 호환을 위해 유지하되 사용자 화면에 노출하지 않는다.

## 스크린샷 기반 다크 UI · 2026-09-28

사용자가 제공한 IMG_6081–6096의 화면과 기능을 참조해 Flutter 앱을 재설계했다. 현재 UI는 차콜 배경·짙은 카드·밝은 글자·pill 선택·청록 버튼과 초록/코랄 상태색을 사용한다. 앞선 흰 카드 팔레트를 대체하며 Pretendard, 공통 간격·시트·motion, 업무·매뉴얼·근무표·우리매장 4개 메뉴를 유지한다.

우리매장에 실제 상태 기반 준비 목록·본인 출퇴근 카드·파트 관리·요일별 시간대·직책별 제한 설정을 추가했다. 직원은 간결한 목록에서 정보·근태·일정·파트/시간대 시트로 열린다. 파트 ID로 업무·크루·근무를 직접 연결하며 직책 권한과 구분한다. 설정은 기존 revision 검증을 사용하고 실패 시 초안을 보존한다. 기존 인건비 계산과 첫 근무 연습·버디 확인은 유지한다.

초대 코드·QR은 명시적인 체험 기능이다. 실제 계정 가입, 보건증 보안 저장, GPS/Wi-Fi 출퇴근 검증은 미연동으로 표시한다. 임의 밴드 수, 개별 권한 override, 새 소식/요청 결재, 자동퇴근 정책은 아직 구현하지 않았다. 전체 참조 기능 rollout은 진행 중이다. [화면별 구현·제한·검증](docs/REFERENCE_REDESIGN_2026-09-28.md).

## 주간 배정과 인건비 · 2026-09-27

직원 기본 화면은 월–일과 직무별 필요 시간 슬롯의 주간 배정표다. 요일별 슬롯 설정, 교대 분할 충족률·미배정 시간, 날짜별 상세 시트를 제공한다. 매뉴얼과 우리매장 운영 현황·재고와 발주·직원·인건비·배치도 상세도 바텀 시트로 연다.

사용자가 대한민국 기준 주휴·연장·야간·휴일 수당 및 앱 내 주간 확인 목록을 선택했다. 사장님이 확인한 주간 계약 조건을 기준으로 시급제 인건비 예상과 근태 기준 계산을 구분한다. 미확인 조건이나 지원 범위 밖 연속근무는 합계를 보류한다. 이 기능은 표준 성인·고정 근로시간·시급제의 예상액이며 확정 급여/이체가 아니다. 고정 월급·특례 계약·세금/보험은 별도다. [계산 기준·공식 출처·범위](docs/WEEKLY_LABOR_2026-09-27.md).

## 공통 UI 규칙 · 2026-09-27

사용자가 요청한 토스 스타일 규칙을 적용한다. Pretendard 제목 24/Bold, 본문 16/Medium, 설명 13/Regular, 기본 글자 #191F28, 화면 좌우 24px, 세로 섹션 32px를 사용한다. 배경은 #F2F4F6, 기본 카드는 흰색·16px 모서리·4% 그림자로 구분한다. 강조색은 사용자 답변에 따라 기존 초록·코랄을 유지한다. 설정·편집·상세는 상단 모서리 24px와 회색 핸들이 있는 바텀 시트로 열고 네 주요 메뉴는 유지한다. 편집 시트의 외부 탭·드래그 닫기는 비활성화해 기존 취소 확인을 보존한다. 최초 로딩은 shimmer 스켈레톤, 일반 버튼은 0.95배 눌림과 복원, 주요 화면 이동은 Cupertino 전환을 사용하며 동작 줄이기를 따른다. 새 화면 개발의 고정 가이드는 [Toss UI 프롬프트 템플릿](docs/TOSS_UI_PROMPT_TEMPLATE.md)이다.

## 매뉴얼 디렉토리와 명칭 · 2026-09-27

앱의 구조와 명칭은 **TAP그룹 → TAP → Task**다. 기존 BIG TAP은 TAP그룹, Small TAP은 Task로 변경했다. 매뉴얼은 Task에 연결된다. 과거 변경 이력과 저장용 필드/API 이름은 호환성을 위해 그대로 보존한다.

매뉴얼 메뉴는 넓은 화면에서 왼쪽 디렉토리 트리와 오른쪽 Task 목록을 보여준다. 휴대폰은 같은 트리와 목록을 전환하고, 매뉴얼 본문은 모든 화면에서 바텀 시트로 연다. 상단 공통 검색은 그룹명·TAP명·Task명·매뉴얼·연관어를 검색하며 선택한 디렉토리 안으로 범위를 좁힐 수 있다. 사장님/매니저는 구조 편집 모드에서 TAP그룹/TAP/Task의 순서 또는 소속을 드래그와 이동 메뉴로 바꿀 수 있다. 기준 Task의 매뉴얼·설정은 함께 이동하고 오늘 업무의 저장된 매뉴얼·완료 기록은 보존한다. 공개 미리보기의 이동은 화면 내 체험이며 서버에 저장하지 않는다. [구현·검증 기록](docs/MANUAL_DIRECTORY_2026-09-27.md).

주문처리 매뉴얼은 주문 건수나 수량별로 복제하지 않는다. 메뉴 카탈로그의 활성 메뉴마다 대표 TAP 하나와 같은 이름의 Task 하나를 두고 해당 메뉴의 매뉴얼을 연결한다. 기존 실주문 TAP과 그 완료 기록은 그대로 유지한다. 대표 매뉴얼은 자동으로 오늘 업무가 되지 않는다. Task 예상 소요시간은 매장 관리자가 설정하며, 미설정 값은 추측하지 않는다. 매뉴얼 Task 카드에는 소요시간만 보조 표시하고, TAP 트리와 업무 TAP 카드에는 설정된 Task 시간의 합을 표시한다. 일부만 설정됐으면 `+`로 부분 합계임을 나타낸다.

## 공통 메뉴 구성과 완료 전환 수정 · 2026-09-27

네 기본 메뉴는 같은 상단 구조를 사용한다: 하단 메뉴명과 동일한 제목(업무·매뉴얼·근무표·우리매장), 매뉴얼 검색, 본문. 모든 메뉴에서 검색할 수 있고 검색 결과도 같은 최대 폭을 사용한다. 메뉴 제목의 장식 라벨·설명 문구, 반복 안내와 Task의 중복 방법 보기 문구를 제거했다. 오류·저장 상태·권한·실제 업무 매뉴얼 내용은 유지한다.

완료한 TAP은 원래 열에서 글줄이 내려가 사라지는 동안 위치를 유지하고 전환 후 완료 열로 이동한다. 별도 텍스트 오버레이를 제거해 중복 표시를 막았다. TAP 열기는 새 본문만 아래에서 나타나며 서로 다른 높이의 보드가 겹치지 않는다. 동작 줄이기는 즉시 결과를 보여주고 컨트롤러 생성·해제도 검증했다. 선택 버튼에도 Pretendard를 명시 적용했다.

## TAP 전환과 한국어 서체 보완 · 2026-09-27

공개 미리보기에서도 성공한 TAP/Task 완료에 짧은 아래 방향 글줄 전환을 보여 준다. 완료 TAP이 보드의 다른 열로 이동할 때는 출발 카드 위치에서 글줄이 내려가며 사라지고, 완료 열에는 완료 상태가 남는다. TAP을 열면 제목과 Task 본문이 펼쳐진다. 동작 줄이기 설정에서는 전환을 생략한다. 기본 한국어 서체는 무료 OFL 라이선스의 Pretendard로 교체했다. 이 동작은 Flutter 위젯 프레임 테스트로 검증했으며 네이티브 실기기 검증은 별도다.

## 업무·매뉴얼·근무표·우리매장 개선 · 2026-09-27

The main Flutter app now uses **업무 / 매뉴얼 / 직원 / 우리매장**. Work retains the TAP → Task hierarchy, TAP그룹 filters and the existing order/todo/done board. Manuals have a dedicated destination; Staff contains schedules, training and owner-only hiring drafts; Our Store contains settings, layout and access to sales, stock and procurement.

Initial registration requires only store name and industry. Optional POS, delivery platform and staffing details use toggles and pickers and can be changed later. POS/delivery scope covers configuration and relevant task template suggestions; live order integration is separate. Task configuration starts from work-type templates and supports TAP role/place/repeat/time bucket/bulk completion and Task manual/quantity/unit/estimated time/order rules. Photo evidence, manager approval and running timers are later work.

The visual direction emphasizes readable Korean type, restrained color/transparency and compact default content. Opening a TAP should reveal its Task structure; a successful completion should briefly move the text row down and fade into a readable completed state, preserving records, permitted undo and reduced-motion support. Hiring scope is required headcount, roles and job-post drafts; external publishing and applicant management remain later work.

See the [detailed improvement method](docs/APP_IMPROVEMENT_METHOD_2026-09-27.md) and [Sol implementation handoff](docs/SOL_IMPLEMENTATION_HANDOFF_2026-09-27.md). Field names and implementation defaults proposed in those documents are distinguished from the explicit user decisions. The current implementation stores optional profile sections, validates TAP/Task completion rules on the server and keeps existing task snapshots when templates change. External hiring publication, applicant management, POS order synchronization, photo evidence, administrator approval and running timers remain later work.

## UX and integration groundwork · 2026-09-27

The user selected task/manual UX improvements and order integration groundwork, preserving the existing order/todo/done lanes and TAP → Task hierarchy. Card drag, completion and detail controls now have minimum 48 logical pixel targets. Large text uses a compact detail arrow; a tooltip exposes the full title. Manuals show their parent TAP and a separate tip surface.

OperationsRepository now separates HTTP, JSON and authentication headers from controller state. JSON snapshots and some presentation rules remain; this is an incremental boundary extraction, not a completed Clean Architecture migration. Timers, offline writes, state management package replacement and live POS integration remain future proposals. See the [report review and architecture proposals](docs/UX_ARCHITECTURE_REVIEW_2026-09-27.md).

## Purpose

Help a small Korean food and beverage business coordinate people, daily work, stock, and procurement in one approachable phone app. The user explicitly expanded the initial onboarding-only scope on 2026-09-19. The first hour still prepares a new person to participate alongside a buddy: an approximate learning plan, not a countdown or a guarantee of readiness.

Kitchen prep and dishwashing remain the starting jobs. Each worker needs their own learning progress and confirmations; tomorrow's new hire reuses the same workplace materials without inheriting someone else's completion status. Shared operational tasks are different: one coworker's inventory check is visible to the whole team and should not be duplicated.

The [restaurant operations scenario review](docs/RESTAURANT_SCENARIOS_2026-09-25.md) walks through 22 opening, service, stock, staffing, closing and failure scenarios, with implemented behavior, tests and remaining gaps. Its three reproduced defects and a public-preview parity issue received focused fixes; the review does not turn the remaining proposed workflows into confirmed decisions.

## Brand artwork

The current `tap2work.png` is a new route-shaped 2 mark: a cream path and coral endpoints on deep green. `app/assets/branding/generate_brand.py` generates the app asset, repository-root logo, web favicon/PWA icons and Android/iOS launcher images from the same geometry. The Flutter header pairs the icon with a live text wordmark. The earlier user-supplied circle and raster wordmark remain in Git history; the menu artwork remains bundled separately. Native icon builds have not been verified.

The previous 2026-09-27 visual direction used pale gray surfaces, white cards with light shadows, #191F28 text, green navigation and coral primary actions, following the 2026-09-27 UI prompt template. The earlier warm paper surfaces and default card borders are superseded. Functional navigation and task cards use Cupertino glyphs rather than colorful emoji; actual dish art remains where it identifies a menu item. The public domain root serves the Flutter app directly. The public build excludes the development journal and project decision/history files; the local developer console remains a development tool.

The [2026-09-25 UI design system](docs/UI_DESIGN_SYSTEM_2026-09-25.md) refines this direction with a darker, more legible coral action color, shared heading and card treatments, labeled controls, and text-plus-icon status. On phones, Status places immediate work and shortages before shortcuts and reports; the prepared-inventory detail starts collapsed. Calendar gives each half-hour row a larger touch area, Place separates table/seat/equipment totals, and login makes password visibility and submission progress explicit. The visual revision does not change demo permissions, inventory rules, staffing records or first-shift confirmations.

Design references reviewed through Aside CLI on 2026-09-25: [Trello navigation](https://support.atlassian.com/trello/docs/navigation-in-trello/) for its floating desktop navigation and aligned cards; [Trello mobile Planner](https://support.atlassian.com/trello/docs/use-trello-planner-on-mobile/) for persistent labeled phone destinations; [Asana board view](https://help.asana.com/s/article/board-view?language=en_US) for card rhythm; and [7shifts task lists](https://kb.7shifts.com/hc/en-us/articles/32201612821139-View-overdue-task-lists) for compact restaurant task rows. The floating phone pill is our design choice; the inspected Trello phone reference uses a fixed bottom bar.

## Phone experience

| Person | Primary action | Supporting actions |
| --- | --- | --- |
| New worker | Open the next small task | See shift and buddy; ask for help |
| Buddy | Demonstrate and observe practice | Confirm a step; respond to help |
| Owner/manager | Prepare a reusable role template | Invite workers; assign buddies and shifts |

The app has four destinations in this order: 업무, 매뉴얼, 직원, 우리매장. A floating bottom menu shows these Korean labels alongside icons; selection remains visible and each target fills an equal-width slot. 우리매장 provides inventory, procurement, layout and operating overview entry points. The existing first-shift guide (오늘, 일하는 법, 근무표, 도움) remains accessible through 직원 > 교육. Administrative actions are separate from worker actions. Use short Korean text and large touch targets. First-shift guide media remains deferred in D-007; operational Task manuals now support external video/photo links.

The current hierarchy remains TAP / Task. Parts are the sole work-board filter. Folder IDs remain for manuals and template organization. The order-processing lane is opt-in through store settings; OFF hides order cards without deleting history. Existing order-wide progress, independent card actions and stock rules remain.

The schedule now uses a fixed time axis with weekday groups and part subcolumns. Business-hour templates, dated slot adjustments and crew assignments are separate. Clicking a slot edits times or assigns crew; assignments support editing, removal and 4/12-week weekday repetition. Server validation includes membership and overnight overlap. Owner-only labor and payment records remain separate. See [current architecture](docs/ARCHITECTURE.md); earlier calendar and folder-filter descriptions are superseded.

The latest user request brings staff operations and procurement into the prototype now. Recruiting remains a later phase; do not introduce a job marketplace as a prerequisite.

## Menu TAPs, lightweight manuals and staffing calendar · 2026-09-24

Customer tickets create one TAP per menu line (quantity remains on that TAP), each with Task for order work only. These menu TAPs appear together under the order number and drag together between folders, positions and states. Individual menu completion does not complete the ticket until all menus finish. Existing whole-order TAPs are archived during migration, preserving prior evidence. Unfinished orders keep all menu members visible across Korean midnight. Recipe examples are proposals: owners must fill in approved quantities, timing and temperatures.

Task manuals have text, one HTTPS video link and one HTTPS image/album link. Managers can edit directly from a manual popup or in the existing checklist editor using plain text and links from tools such as YouTube or Drive. Media is opened externally, not uploaded or bundled in the app. A linked recipe edit updates its template for future orders; current/completed snapshots are retained, and saves use the opening revision. The entire five-minute planning feature and its scheduling endpoint are removed; independent grid routing remains.

Calendar provides a weekly date strip with a selected-day timeline and a monthly overview. Daily required staffing defaults to three configurable role/time slots (a demo starting point, not a confirmed requirement for every store). Existing extra shifts remain visible. Register crew through HR Pool → crew management, drag a person into an empty slot, or drag an assigned shift to move it. Touch uses long press and empty-slot tapping provides an alternative. Server checks role qualification, occupied slots, overlapping shifts, permissions and revisions. Slot configuration preserves existing shifts rather than deleting them. Suggestions list qualified crew without an overlapping planned shift; availability still needs direct confirmation. The Albamon external link is explicitly labeled HR integration under construction. No invitations, recruiting applications or messages are sent.

Calendar references: [crew calendar design review](docs/CALENDAR_DESIGN_REFERENCES_2026-09-25.md) records official Homebase, When I Work, 7shifts and Deputy phone and desktop patterns reviewed through Aside CLI. The selected-day timeline supports dragging; the monthly overview retains its existing slot interactions. A required `빈 슬롯` is an unassigned place in the plan, not a published offer. Public previews cannot save staffing assignments.

## Prepared output and order usage · 2026-09-24

The order TAP now contains only order verification, finishing/plating from ready portions and handoff. The previous duplication of bone/noodle advance preparation Task is removed from unfinished orders with the old step evidence archived; completed order history stays intact. Stable menu IDs, rather than name matching, connect menus to configurable prepared items. Each prepared item has a unit, current balance, shortage point, target, usual batch quantity, short method, folder/place and per-menu use. One prepared item can serve many menus, and one menu can use many prepared items. This structure fits sauces, dough, portioned vegetables and other restaurant preparations as well as 뼈찜.

Starting menu cooking uses its configured ready portions once. A shortage creates one preparation TAP; completing it asks for the actual finished amount and adds that once. If the amount is still short, another TAP is created. Physical count corrections record who and why. The signed balance can show a shortage without pretending that unmade portions are available. Open preparation TAPs carry across Korean midnight. Existing active orders are not retroactively deducted when a store upgrades to this count model. Supplier-purchased raw inventory and its D-017 order-based review deadline are separate. See [Prepared workflow](docs/PREPARED_WORKFLOW.md) for event, migration and limits.

The demo's 뼈찜 sample begins with an illustrative count and sample menu usage; the store must confirm actual portions, yields, storage and recipes before using these as operational facts. Current sales orders are synthetic, with no POS or automatic supplier order integration.

The operations and first-shift screens share a 72 px warm neutral header with a fine bottom border. The new 44 px mark and live tap2work wordmark scale together on narrow phones. A single 44 px account action opens a contextual menu. Their content uses matching 20 px phone gutters, readable supporting text and the same floating bottom menu. In a preview with Auth available, that menu offers login and clearly labeled demo roles; local preview offers demo roles. Once authenticated, it shows the account and server-provided role without a demo role selector. The account dialog retains login/logout, and role or email text stays inside the menu to prevent duplicate profile controls on phones.

The four operations destinations now share a 1240 px maximum content width with 20 px side gutters. Page titles use one eyebrow/title/supporting-text rhythm, and section headings use a smaller shared scale. Choice controls use white outlined idle states and deep green selected states; choices in a group take equal widths and wrap on narrow phones. Labeled pickers use the same bordered surface and rounded menu. Coral remains the primary action color. Weekly/monthly calendar views are exclusive choices. The selected-day staffing timeline is always visible in the weekly view; personal-assignment filters remain independent controls where shown.

## Integrated operations prototype

| Destination | Main question | Implemented sample interaction |
| --- | --- | --- |
| 오늘 | How is the restaurant doing? | Menu sales/order dashboard, period/channel filters, active kitchen queue, stock/tasks/shifts, first-shift guide |
| 할 일 | What should we check, and who has done it? | Group cards with tap-to-check activities and manuals, time-bucket tabs, undo, drag-and-drop editor, industry library, actor/time per activity |
| 재고/발주 | What do we have and what should we order? | Physical count, minimum threshold, review interval, grouped supplier cart, demo order, separate receipt |
| 우리 팀 | Who is working and where is there a gap? | Shared sample shifts, leave status changes, coverage requests and manager acceptance |
| 매장 지도 | How many tables/seats do we have, and where is each device? | Whole-restaurant grid, table/seat/equipment counts, configurable tables/equipment/storage/entrances/areas, shared layout save |

Inventory flow: **check actual stock → collect needed items → review quantities grouped by supplier → one demo order → acknowledge receipt → later inventory check**. An order never increases on-hand quantity; receipt applies exactly once. An open order blocks duplicate orders for the same item. Partial deliveries, cancellations, price/tax validation and real supplier integration are not implemented.

The user selected a fixed delay after ordering (D-017). Each material retains a configurable N-day delay and minimum quantity. One review is due N days after the latest order; an intermediate physical count or receipt does not postpone it. Completing that review does not start another repeating review; the next order starts a new schedule. The current implementation uses elapsed 24-hour days from the order timestamp. A new order supersedes unfinished reviews from older orders without deleting their records. Changing N recalculates unfinished review dates from the same order. Exact default delays per material still need owner input.

API reads materialize due tasks; polling is not a production scheduler or push service. Checks store actual quantity, actor and timestamp. Daily routine templates still generate new tasks at Korean date boundaries. Initial time buckets are labels, not configurable clock ranges. Managers can define templates by bucket, rank and place. Exact time ranges, exception days, individual assignees and overdue escalation need further design.

Shared information includes names, roles, shift hours, leave status, coverage status, work completion, and stock counts. Private leave reasons are not collected in the shared demo. Owner-only sample labor estimate and memo are stripped from non-owner API responses; purchasing prices are available to owner/manager, not crew/cook. This is an initial permission proposal, not approved production policy. Demo actor selection is intentionally impersonable and therefore **not security for real employee information**.

The layout is a configurable schematic, not a measured architectural plan. It now shows the whole restaurant with table count, total configured seats and major equipment count. Owners/managers can set a layout name and grid (8–30 columns/rows), add up to 80 tables/equipment/storage/entrances/areas, change names/notes/position/size and table capacity (1–20), drag an object with integer grid snapping, resize it with the selected corner handle, or move it by tapping an empty cell or using arrow buttons, and delete unlinked objects. Overview supports pinch zoom and a full-size item list. Existing example routes remain available only when every referenced place still exists. Their display now uses four-way A* over open schematic cells, treating other tables/equipment/storage as blocked; an unreachable segment is not drawn. They are not measured walking distances or validated safety/emergency guidance.

Editing uses a separate draft and the opening revision; polling cannot replace the draft, cancellation discards it, and stale saves fail with an explicit reload option. The server validates permissions, unique IDs/table names, integer geometry, bounds, seats and overlap. Areas may overlap as backgrounds; other objects may not. Places linked by inventory or current/historical tasks cannot be deleted or reclassified. The old kitchen sketch upgrades once while preserving IDs, names and notes, adding six sample dining tables (24 seats). Table count and capacity reflect configuration, not live occupancy or a POS table assignment. Public reviewers can experiment with a disposable draft but cannot save or call write APIs. Floorplan image uploads, real measurements, walls/multiple floors, configurable route authoring, native identity integration and live occupancy remain unimplemented.

## Checklist groups, activities and short manuals

The user requested **folder → task → multiple actions → short manual** on 2026-09-20, then asked for intuitive drag and drop, tap-to-check and more specific 뼈찜 restaurant checklists. The 2026-09-26 clarification makes the working structure **TAP → Task**: a TAP is one job, each Task is an action with its manual and tip, and TAP그룹 groups jobs on the board. Existing `folderId`, task and step IDs remain stable.

Worker/CEO Todo view: customer orders, ordinary prework and finished work occupy the fixed 주문처리중 / 할일 / 완료 columns. Internal processing state remains for the one-time prepared-item debit and is independent of the visible order column. TAP그룹 chips name and filter groups without creating a hierarchy step. TAP cards explicitly open their Task actions; the detail path returns directly to the preserved TAP board. Task stay in one list; phones open the manual in a bottom-sheet popup and wider screens show it beside the list. TAP completion checks all remaining Task in one server mutation; stock checks keep their separate physical quantity input. Read-only public preview changes remain on the device and send no POST request. The order-work examples and preparation manuals are proposals grounded in [the 산뼈찜 source review](docs/SAN_BONEJJIM_TAP_RESEARCH_2026-09-24.md); public visitor reports are not a confirmed restaurant recipe or service rule.

The global manual search stays below the app header while the page scrolls and remains available in Status, Todo, Calendar and Place, including inside a TAP. It searches all visible Task manuals independently of the current TAP그룹 group and board status. Results identify the Task and its parent TAP, show a short excerpt and #related terms, and open the manual without changing completion. Owners and managers can edit related terms on each Task; spelling normalization helps with common queries such as 결재/결제 and 메뉴얼/매뉴얼. A blank real store has no invented operational manuals. The seeded demo uses an OKPOS sample guide with text instructions and official links; see [POS manual sources](docs/POS_MANUAL_REFERENCES_2026-09-26.md). A store must confirm its OKPOS device version and its own cancellation, rider, recipe and storage procedures before using those instructions for work.

Editor (체크리스트 편집, owner/manager): groups reorder with a drag handle, and a long press on a group drops it on a folder chip; activities reorder with their own handle, and a long press drops an activity on another group's header. Every drag has a menu or button equivalent. Group info (icon, name, time bucket, rank, place) is a bottom sheet; an activity opens a full-screen manual editor with discard protection. Saving validates the entire draft first and names the group and activity that still needs text, both inline and as a snackbar. Drafts stay isolated until a revision-checked save; public reviewers can experiment but not save.

The demo store is now a 뼈찜·뼈곰탕 sample restaurant (우리뼈찜 · 서정리, fictional). A fresh demo starts with the 뼈찜 collection: 11 groups and 52 activities from 출근·개인 위생 and 홀·셀프바 오픈 through 등뼈 전처리 (핏물·초벌·헹굼·소분), 육수와 기본 뼈곰탕 국물, 양념·사리·특제소스, peak kitchen and hall service, 포장·배달, 브레이크타임, and 주방·홀 마감. Group place and rank hints from the library are applied when the store has that place. Existing demo files keep their own lists and can import the collection. Sample menus and ingredient names follow the 뼈찜 store, with stable item IDs and illustrative prices.

The built-in library now contains **뼈찜·감자탕 전문점 plus 25 industries and a shared F&B collection, 64 groups and 211 activities** with 24 references. The 뼈찜 content is grounded in the visit report (menu, self-bar, 기본 국물, 특제소스 rule, business hours and break time), 식품안전나라 operator obligations, 생활법령정보 health-check rules, the 식약처 delivery packaging guidance as quoted by 배민외식업광장, and one community answer on bone preparation that is explicitly marked unofficial. Times, temperatures, portion weights and recipes are written as “매장 기준” placeholders for the owner to confirm; the content remains a proposal (D-026), not an approved procedure.

[Checklist wiki](docs/wiki/CHECKLISTS.md) and the app use `docs/wiki/checklist-library.json`; run `npm run build:wiki` after editing it. The Aside exec agent returned 402 insufficient credits again on 2026-09-20; the blog was read as public web text and the five other sources were read with Aside REPL direct browser snapshots. The 배달음식점 self-inspection PDF attachment was not opened.

## Restaurant overview and sales prototype

The user requested menu-level revenue, menu orders, and restaurant-wide status together on 2026-09-19. 오늘 now opens 매장 한눈에: net sales, order count, average paid order, active order count, all-menu sales/order ranking (including zero-order menus), search/category/sort, hourly chart, current kitchen queue, and inventory/procurement/tasks/staff summaries. Wide screens use two columns; phones keep the same information in one scrollable page. The first-shift guide, map, shared activity and owner memo remain accessible.

Sales are synthetic samples, not imported POS data. `developer/sales.mjs` seeds 7 days of restaurant tickets once, independently of supplier purchase orders. Existing demo state is upgraded without replacing stock/orders/history or resetting sample tickets each day. Snapshots aggregate today or the last 7 Korean calendar days, by all/dine-in/takeout/delivery. Net sales use paid non-cancelled lines at their recorded unit price, less line discounts and refunds; unpaid orders still count as orders. Average is net sales divided by paid non-cancelled ticket count (including refunded tickets). Revenue and refunds are attributed to the original order's Korean date/hour; this is not a payment-settlement or accounting report. Tax, platform fees, partial payment, refund event dates, and real POS ingestion are not implemented. No menu sale automatically consumes ingredients without recipes and validated integration.

The active queue retains unfinished orders from earlier days, independent of period/channel reporting filters, and supports status filtering. Its age is since order acceptance, not a promised prep time or SLA. The sample is read-only for restaurant orders. Staff summaries indicate scheduled shifts, not measured attendance. Financial dashboard fields and raw priced tickets are stripped server-side for non-owner demo roles; exact production visibility is still proposed. Public review builds always generate fresh synthetic samples and block writes. POS/delivery integrations, exact accounting definitions and production authorization remain proposed pending actual store requirements.

## Current storage and integration boundaries

### Public app and local development workspace

The user selected `https://github.com/ljae/tap2work` for development and registered `tap2.work` through Namecheap. The user will share the site with a specific CEO, who can ask direction questions, request new features, and suggest improvements to the work experience. Do not impersonate the CEO or treat AI recommendations as their feedback.

The public domain root serves the read-only Flutter app with synthetic samples. It does not publish the development journal, decision history, or project status. The local developer console remains available for development; any product feedback or future CEO direction must still be explicitly provided by the user and recorded as a decision only after confirmation.

GitHub Pages hosts a separate static Flutter review build with fresh code-generated role samples. Operational writes are blocked in this build, and there is no shared public operations API. Onboarding practice remains browser-local. The localhost console and its editable canonical decisions stay local. Public hosting is a development preview, not production deployment of staff operations.

- `developer/operations.mjs`: local shared state, serialized mutations, atomic JSON persistence, revision conflicts, role projections and demo action guards.
- `.local/operations-demo.json`: generated sample state, separate from development decisions; no production employee data.
- Flutter `OperationsController`: same-origin HTTP web API, 5-second refresh, explicit error/conflict state, no offline success simulation.
- Existing `WorkController`: device-local individual onboarding demo. It is not yet connected to authenticated personal assignments.
- `docs/project-state.json`: canonical product decisions and append-only change history, visible in the developer console.

No supplier messages, real orders/payments, accounts, push notifications, payroll calculations, timekeeping, contracts, or production deployment have been connected. The local server binds loopback only. For CEO demos the user chose (2026-09-20) a tunnel from their Mac: `npm run dev:shared` allows the tap2.work origins to call only `/api/operations` through a cloudflared quick tunnel, and the public app connects when opened with `?api=<tunnel>` (remembered in that browser, cleared with `?api=off`). Members then share one demo state and see each other's checks within the 5-second refresh. Console pages and decision APIs stay loopback-only; demo roles remain impersonable and anyone with the link can change the sample state, so no real employee data belongs there. The user confirmed support for BOTH existing-supplier messaging/email workflows and food-supply platforms (D-016). Specific suppliers/platforms, delivery mechanisms, production backend and authentication remain undecided.

## Confirmed procurement direction and next design proposal

Support both traditional suppliers and food-supply platforms without forcing the owner to change all purchasing relationships. The choice confirms channel coverage, not any specific vendor, API availability, or permission to transmit real orders.

Proposed UX: keep one common cart and history, group lines by supplier, and show each group's delivery method and progress separately. A prepared message, opening another app, or a share-sheet action must not be labeled as a successfully received order. Distinguish draft/prepared, delivery unverified, sent, supplier accepted, and received where evidence supports those states; manually recorded confirmations should name the recorder. Mixed-channel actions may partially succeed, so retries must target only the failed groups and avoid duplicate orders. These states and integrations are not implemented yet.

Next input needed: names of actual suppliers/platforms and how orders are currently placed. Check supported integration mechanisms before promising automatic sending or payment. Preserve the current demo-only boundary until a real integration is implemented and explicitly used.

## First hour

| Approximate duration | Activity | Evidence before confirmation |
| --- | --- | --- |
| 5 minutes | Meet buddy and tour kitchen | Worker identifies their work area and who to ask |
| 10 minutes | Workplace hygiene and safety introduction | Buddy observes the workplace's actual preparation procedure |
| 15 minutes | One dishwashing cycle | Worker completes a supervised cycle using workplace procedures |
| 15 minutes | One simple prep task | Buddy checks the result and permitted task scope |
| 10 minutes | Practice communication | Worker can report completion and ask for help |
| 5 minutes | Check-in and next steps | Both understand the next supported task and shift |

The workplace must validate actual content and procedures before use. Orientation completion must not automatically authorize independent use of equipment or imply that statutory training, eligibility, or documentation requirements have been met. Country-specific employment, privacy, and food-safety requirements remain a research task before production use.

## Learning state

`Not started → Worker practiced → Buddy observed and confirmed`

Allow repeated practice and additional support without penalizing the worker. A production record should include worker, buddy, workplace, step version, and timestamp. Editing a template must not silently rewrite past records. Define when changed content requires renewed practice.

## Proposed production data structure

| Entity | Purpose |
| --- | --- |
| Workplace | Team, location, timezone (Asia/Seoul initially) |
| Membership | Person's workplace role and access scope |
| Job template | Reusable prep/dishwashing orientation |
| Lesson version | Demonstration, captions, practice instructions, observation criteria |
| Onboarding assignment | A specific worker's copy of a versioned learning plan |
| Practice and sign-off | Separate worker and buddy actions with timestamps |
| Buddy assignment | Named support person for each shift or orientation |
| Shift | Start/end, workplace, worker, buddy, acknowledgement |
| Help request | Requester, recipient, status, acknowledgement; no promise of urgent response |
| Team notice | Store-wide operational information |

Add InventoryItem, StockCheck, Supplier, PurchaseOrder/Line/Receipt, TaskTemplate/Occurrence/Completion, CoverageRequest, Zone/Equipment/Route and AuditEvent to the production model. The operations demo implements a simplified JSON subset, not this production database. Production access must be scoped by workplace and authenticated role. A self-selected demo role must never become the production authorization model.

## Access and communication proposal

The user selected Flutter on 2026-09-19. The primary app lives in `app/` and targets Android and iOS; the same Flutter app is served from `https://tap2.work/`. The original root HTML prototype remains a reference. The canonical decisions and history live in `docs/project-state.json`; `developer/` provides the local web workspace for reviewing and recording decisions.

A worker could start from a manager invitation. Joining, deep links, authentication, invitation expiry, shared phones, app installation, and account recovery need decisions before implementation. Do not put private employee data behind a publicly reusable store QR code. The exact invitation and installation experience is still proposed, not confirmed.

Prefer task-specific help and clear shift notices before introducing a general chat channel. During urgent situations, communicate directly on site. Real notifications require a delivery and acknowledgement strategy; the prototype only simulates the request state on one device.

## Delivery sequence to discuss

1. Validate this first-hour flow with one owner, one buddy, and a new kitchen worker.
2. Capture the actual workplace's short demonstrations and observation criteria.
3. Implement invitations, authenticated memberships, persistent assignments, and buddy records.
4. Validate integrated tasks, stock, ordering and coverage with the owner's actual suppliers, role policy and restaurant plan; then implement authenticated shift assignment and operational communication.
5. Extend into recruiting, employment documents, attendance, and payroll only after their requirements are agreed.

## Pilot questions

- Can a new worker join and find the next step without assistance?
- Does the buddy have enough uninterrupted time to demonstrate and observe?
- Which instructions still need verbal explanation or translation?
- Does the worker know when to stop and ask for help?
- Can the owner prepare tomorrow's onboarding without rebuilding today's plan?

Track time to supported participation, requests for help, repeated steps, and buddy effort. Faster completion alone is not a success metric.

## Supabase workspaces (2026-09-24)

The public app supports email signup/login through Supabase Auth. Signed-in accounts receive a separate cloud workspace seeded with synthetic examples; operation saves use an Edge Function with verified membership and role projection, RLS-protected JSONB state and revision compare-and-swap. Service keys stay server-side. Anonymous use remains an unsaved public preview. The existing local actor-switchable demo is separate. See [Supabase setup and limitations](docs/SUPABASE.md).

Active synthetic Home tickets now create order-linked Taps with the same number, channel, table and menu quantities. Completing an order Tap completes all its Task and removes the ticket from Home's active queue; reopening returns it to that queue. Preparation groups remain reusable templates. Public preview changes are shared across Home and Todo in memory.

Updated 2026-10-06: cloud accounts can belong to multiple independent workspaces and create additional blank stores. The header selector scopes all operations and permissions to the chosen membership. Team registration stores a roster; invitations connecting other Auth users to an existing store remain unimplemented. Attendance and wage estimates are persisted, but legal pay rules remain proposed and no actual payments/orders are sent.

### Owner setup and real store catalogs (2026-09-26 implementation)

A first authenticated login now asks the owner to choose an empty store or a synthetic sample. GET alone no longer creates a sample store. An empty store starts with no fictional staff, tickets, stock, checklists, prepared stock or mapped places, and later reads do not seed them. The owner can edit the store name and note; the store catalog editor adds, edits and archives ingredients and menus. New ingredient quantity starts at zero and a physical count remains a separate recorded action. Ingredient settings include unit, supplier, price, minimum, usual order quantity, post-order review days and optional mapped place. Menu settings include name, category and listed price. IDs remain stable through edits, and archiving hides a current catalog entry while keeping prior order/receipt and sales-line snapshots. Pending receipts and stock tasks block ingredient archiving; active tickets and prepared-item usage block menu archiving. These writes use authenticated membership and revision checks.

Existing sample workspaces keep their current data until the owner explicitly chooses to store that state and open an empty store. The stored sample backup is kept server-side and omitted from all app views; the current app does not provide a restore control. Restaurant layouts and checklist editors remain available for an empty store, but the owner must add mapped places before assigning a place to work. The inventory order control still records an internal order/receipt only; it does not contact a supplier. A blank store has no POS tickets or real sales ingest. Auth invitations, shared editing by additional real accounts, live supplier orders and production payroll remain outside this owner setup implementation.

## 길게 눌러 편집 · 2026-09-29

업무·근무표·매뉴얼은 권한이 있을 때 항목을 길게 눌러 흔들림 편집에 진입한다. 이동·이름·휴지통을 해당 항목에서 제공하며 편집 완료로 종료한다. 기존 보드/구조 편집 버튼을 대체하고 상세 규칙·본문·배정 입력은 문맥 안에 유지한다. 완료/출퇴근 원본은 보존하고 삭제 전 대상을 확인한다. 동작 줄이기는 정지 표시다.


## 근무 배정 3단계 · 2026-10-04 최신 변경

영업시간·필요 인원 → 크루별 기본 배정 → 날짜별 근무표 조정으로 진행한다. 크루를 교대×파트의 필요 슬롯에 drag/tap으로 배정하고 미배정을 이 화면에 모은다. 근무표는 파트 가로/시간 세로의 배정 결과와 세부 시간 조정만 제공한다. 별도 시간표·파트 필터는 제거하고 직원은 본인 배정만 본다. 앞 설정 변경은 기존 근무표를 자동 덮어쓰지 않으며 기간을 정해 적용한 뒤 세부 시간을 조정한다. 월간은 정기 영업일에 추가 휴무/업무일을 지정한다. 브레이크는 전체 영업시간 바의 주황색 참고 표시이며 교대·필요 인원 시간을 차감하지 않는다.


### TAP 단일 정책 첫 구현 · 2026-10-04

신규 양식은 `assignmentScopeVersion:2`로 생성하며 TAP의 `settings.assignment`, `completionPolicy`, `estimatedMinutes`, 기존 파트/직급/장소·반복·순서·일괄 완료를 공유한다. Task는 행동과 매뉴얼·팁·태그·자료 및 `contentRevision`만 편집한다. 매뉴얼의 설정 링크도 부모 TAP을 연다. 시간대마다 전체 Task를 생성하며 dateOverrides의 휴무/추가 영업과 활성 파트·필요 인원 판정을 반영한다. 실제 담당은 근무 배정 projection을 따른다.

기존 v1 실행/예외는 읽기 호환한다. 양식 통합은 기존 예외 확인·명시적 확인 후 원본을 비공개 tapPolicyHistory에 보관한다. 일반 TAP의 Task별 분리는 각 예외를 별도 TAP 정책으로 옮겨 다음 영업일부터 생성하고 오늘/과거 실행을 보존한다. 메뉴·주문·준비 특수 TAP과 절차 순서가 연결된 TAP의 자동 분리는 거절한다. API revision/operationId로 충돌·중복을 차단한다. TAP 수량은 모든 Task 체크 후 최종 완료 시 한 번 저장하며 재고를 증가시키지 않는다.

위의 “런타임 구현 전/구조 재현 미수정” 설명은 설계 작성 시점 기록이다. 이번 첫 구현이 해당 부분을 대체한다. 중앙 콘텐츠 주간 검수·발행/선택 업데이트·3-way 비교와 로컬 초안/내보내기 백업·복원은 계속 계획 단계다. 중앙 발행 없이 매장 콘텐츠 편집의 공동 버전 기반만 구현했다.

### 인원 배치 통합 · 2026-10-04 최신 변경

인원 배치에서 필요 인원과 등록 크루를 함께 선택하고 앞으로의 기본 근무로 저장한다. 별도 크루별 근무 배정 화면과 명시적 기간 적용 동선은 제거한다. 근무표에는 날짜별 조회·직접 시간 조정과 달력 아래 영업시간·인원 진입만 유지하며 내부 크루/인건비/교육/채용 준비 탭을 제거한다. 날짜별 수정 및 출퇴근·승인 기록은 기본 배정 갱신으로 덮어쓰지 않는다. 서버는 향후 90일 범위를 저장하고 조회 시 계속 연장한다.

### 인원 배치 테이블·녹색 공통 검색·시간축 눈금 · 2026-10-04 후속

인원 배치는 교대 행×파트 열 테이블이다. 각 셀에 배정/필요 인원수와 선택한 크루 이름을 표시하고 셀 클릭으로 인원 카운터와 자리별 크루 드롭다운을 함께 편집한다. 취소는 초안을 유지하고 적용은 선택 요일의 폼 초안에만 반영하며 최종 저장은 기존 save_workplace_hours/defaultAssignmentsEnabled 계약을 따른다.

기존 내 매장/클라우드 저장/샘플 주문 녹색 상태 띠는 제거하고 그 자리에 녹색 매뉴얼 검색창 한 개를 둔다. 네 목적지에서 같은 상단 위치와 기존 검색·지우기 동작을 사용하며 중복 검색창을 두지 않는다. 근무표의 날짜/파트 머리글은 배경·테두리 없이 표시하고, 시간 영역도 투명하게 유지한다. 왼쪽 52px 시간축에만 30분 간격 시각과 짧은 눈금을 표시한다.

## 지난 근무 이력과 크루 등록 · 2026-10-04

근무표는 한국 날짜 기준 오늘 이전에 실제 출퇴근 이력을, 오늘·이후에는 계획을 표시한다. 예정 근무를 출퇴근 기록으로 변환하지 않는다. 크루 등록은 신원·직급·고용 정보만 받고 파트·시간대는 크루 정보 → 크루 배정 → 공통 인원 배치에서 정한다. 자동 출근은 위치 또는 Wi-Fi 중 선택하는 방향이 확정되었다. 현재 선택 저장만 구현하며 자동 감지·기기 검증은 미연결이다. 이탈 감지 후 본인 확인으로 퇴근 확정하는 흐름은 제안이며 미승인·미구현이다.

## 인원 배정 재반영·휴무일 표시 · 2026-10-04 최신

저장한 인원 배정은 선택·변경한 요일의 오늘부터 90일 계획에 재반영한다. 미세 조정·개별 계획·배정 삭제를 초기화하며 실제 출퇴근 이력, 과거 날짜, 승인·대기 변경 신청은 유지한다. 저장 전에 초기화 범위를 안내한다. 휴무일의 주간 본문은 휴무일 표시만 하고 시간축·파트 표를 표시하지 않는다.

## 매뉴얼 마켓·개인화 백업 · 2026-10-04

매뉴얼 안에서 공용 TAP을 골라 가져오고 TAP과 Task의 상세 내용을 편집한다. 우리매장 할일 준비에서도 마켓에 진입한다. 공용 연결 TAP은 제공자가 새 버전을 발행하면 내용·Task·매뉴얼을 자동 업데이트하며, 이미 생성된 업무 기록과 매장별 운영 설정은 보존한다. 직접 내용을 수정한 TAP은 개인화로 분리하고 기기/JSON 파일 백업·추가 복원으로 관리한다. 공용 연결을 유지한 개인화 사본 추가와 자체 TAP 생성도 지원한다. 가져오기·복원은 사용 OFF로 시작해 TAP 단위 파트·시간대 설정을 확인한다. [운영 절차와 구현 한계](docs/market/README.md).

## 전체 업종 매뉴얼 마켓 · 2026-10-05

마켓은 초기 외식 사용자 범위를 넘어 다양한 비즈니스가 필요한 업무를 찾아 담는 공용 라이브러리다. 공통+12개 산업 영역, 법적 기준/운영 업무 구분, 검색·선택 유지·최종 업무별 자동 분류로 설정 부담을 줄인다. 기존 64 TAP/211 Task를 보존하고 22개 TAP을 추가했다. 법적 기준은 공식 출처와 적용 범위를 표시하는 확인 항목이며 법적 충족 판정이나 전문 분야 전체 SOP를 뜻하지 않는다.

## 사장님의 사업장 매뉴얼 구성 · 2026-10-05

매뉴얼은 마켓에서 선택한 운영 매뉴얼과 사업장 전용 메뉴·레시피로 구분한다. 업종·사업장 특성을 고른 뒤 공통 기본 운영 또는 필요한 항목만 담아 목적별로 구성한다. 새 구성으로 교체할 때 진행·완료 기록과 메뉴·레시피는 보존한다. 현재 사업장의 맥락은 고기집·뼈찜이며 레시피의 재료·분량·조리 기준은 매장별 커스터마이징이다. 법적 기준은 적용 여부 확인용으로 자동 업무 활성화에서 제외한다.

## 매뉴얼 작성과 업무 실행 분리 · 2026-10-05

매뉴얼에서 폴더·TAP·Task를 추가·수정·이동·삭제한다. 업무 메뉴는 진행과 방법 조회에 집중하며 우선순위 손잡이 드래그만 남긴다. 내용 편집·추가·삭제·TAP 규칙 편집은 업무에서 제공하지 않는다. 기존 실행과 완료 이력은 보존한다.

## 매뉴얼 인쇄·PDF와 5개 언어 · 2026-10-05

매뉴얼에서 운영 체크리스트와 메뉴·레시피를 골라 장소·파트·폴더별 인쇄본을 만든다. A4/A5, 체크리스트/상세 매뉴얼/둘 다, 한국어·영어·베트남어·중국어(간체)·일본어와 한국어 병기를 제공한다. 체크칸·날짜·담당자·메모를 포함하며 종이 체크는 앱의 완료 기록을 바꾸지 않는다. 번역은 매장 편집자가 등록·검토한다. 미등록 또는 원문이 변경된 번역은 사용하지 않고 원문과 번역 필요 표시를 출력한다. 자동 번역 공급자·전송 연동은 미구현이다.
# App Store 무료 출시·추가 기능 구독 · 2026-10-05

iOS App Store에서 무료 다운로드를 제공하고 향후 추가 기능에 구독료를 받는다. 사장님이 매장 단위로 결제하고 크루가 함께 이용한다. 사용자는 Apple Developer Program에 이미 가입했다. 가격·기간·유료 기능 범위는 미정이며 기존 기능을 임의로 유료화하지 않는다. 출시 준비 상태와 제안 단계는 [App Store 출시 계획](docs/APP_STORE_RELEASE_PLAN.md)에 기록한다.
## TAP Work 표시 이름과 사용자 제공 로고 · 2026-10-05

사용자가 최종 선택한 `~/Downloads/TapWater_logo.png`를 앱 로고와 런처 아이콘으로 사용한다. 앱 헤더·로그인·설치 이름·웹 제목은 TAP Work로 표시한다. 기존 tap2work 기술 식별자와 tap2.work 도메인은 유지한다. 이전 로고 원본과 보관본을 삭제하고 수도꼭지·물방울·컵 도안만 사용한다.

## 콘텐츠의 누적 개선 · 2026-10-07

직접 조사 요청을 받을 때 이전 출처·검토 오류·현장 피드백을 활용한다. 재검색 횟수를 정확도로 취급하지 않고, 오래된/분쟁 근거를 재확인하며 관측 가능한 체크리스트 개선을 우선한다. 정확성·유용성은 제공자/현장 평가가 있는 작업만 집계한다. [실행·피드백 운영](docs/CONTENT_IMPROVEMENT.md). 자동 정기 조사는 사용자 선택에 따라 비활성이다.


## 2026-10-08 매뉴얼·실행 지식 확장

사용자 요청: 업종에 무관한 브레이크 운영과 메뉴 전용 절차를 분리하고, 매뉴얼을 업무와 연결할 때 크루의 반복 체크·설정 피로를 줄인다. 기본 레시피와 준비·보관·품질·실패 대응의 노하우까지 근거와 함께 축적한다. 상세 분류·참고용/정기/작업사건 연결·이관 방안은 [설계안](docs/MANUAL_KNOWLEDGE_TASK_DESIGN_2026-10-08.md)의 proposed 상태이며 아직 신규 UI/실행 엔진은 구현하지 않았다.


## 2026-10-09 매뉴얼 구성 후속 요구

일반 식당이 업무 영역을 새로 만들지 않아도 되도록 소스를 충분히 조사하고 매장 조정은 허용한다. 매뉴얼 조건과 기존 매장 설정을 연결해 재입력을 줄인다. 매장 수정 매뉴얼/업무는 색·아이콘·문구로 구별한다. [범위·설정·표시 설계](docs/MANUAL_COVERAGE_AND_SETTINGS_2026-10-09.md)의 14영역과 구체 계약/색상은 proposed. 원본 관계·업데이트 정책은 미정. 조사·독립 시안 단계이며 실제 앱 구현/발행 완료를 뜻하지 않는다.


2026-10-10 웹 선행 출시: 통합 행동 슬라이드와 최적화 비공개 사진 등록을 웹에서 먼저 제공한다(D-118). 네이티브 호환은 다음 업데이트이며 구버전의 새 사진 표시·관련 편집 제한을 사용자에게 설명하고 웹 우선 선택을 받았다. 전체 신입 내비게이션 로드맵을 이번 출시 완료로 취급하지 않는다.
